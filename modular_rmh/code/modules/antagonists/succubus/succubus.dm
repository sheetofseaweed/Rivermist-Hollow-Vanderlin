// Succubus antagonist core

/datum/antagonist/succubus
	name = "Succubus"
	roundend_category = "Other Villains"
	antagpanel_category = "Villain"
	job_rank = ROLE_SUCCUBUS
	innate_traits = list(
		TRAIT_IDENTITY_SHIFTING,
		TRAIT_LUSTFUL_STAMINA
	)
	var/essence = 0
	var/essence_cap = SUCCUBUS_ESSENCE_CAP_BASE
	/// mind -> climaxes harvested (novelty decay input)
	var/list/partner_harvests = list()
	/// Same-tick dedupe: the climax pipeline fires once per producing organ
	var/datum/mind/last_harvest_mind
	var/last_harvest_time = -1
	/// mind -> fluid units absorbed (per-originator decay input)
	var/list/reagent_units_absorbed = list()

/datum/antagonist/succubus/greet()
	to_chat(owner.current, span_userdanger("I hunger, and this town is a banquet. I must feed on their lust — carefully, sweetly, unseen."))
	owner.announce_objectives()
	return ..()

/datum/antagonist/succubus/on_gain()
	forge_succubus_objectives()
	. = ..()
	grant_succubus_powers()

/datum/antagonist/succubus/on_removal()
	// Administrative removal cleans the Rift before reverting so the Open-state
	// tether cannot turn a cleanup path into a dramatic banishment.
	discard_active_rift()
	if(true_form_active)
		leave_true_form(force = TRUE)
	remove_succubus_powers()
	return ..()

/datum/antagonist/succubus/Destroy()
	discard_active_rift(refresh_objective = FALSE)
	for(var/datum/mind/imp_mind as anything in summoned_imp_minds)
		var/datum/antagonist/succubus_imp/imp_datum = imp_mind?.has_antag_datum(/datum/antagonist/succubus_imp)
		if(imp_datum?.mistress_mind == owner)
			imp_datum.mistress_mind = null
	summoned_imp_minds = null
	succubus_imp_offer_pending = FALSE
	QDEL_LIST(summoned_lusthounds)
	summoned_lusthounds = null
	QDEL_LIST(infernal_snares)
	infernal_snares = null
	QDEL_NULL(base_form)
	QDEL_LIST_ASSOC_VAL(stolen_forms)
	partner_harvests = null
	last_harvest_mind = null
	reagent_units_absorbed = null
	// Team persists for roundend/thralls; just drop our reference
	harem = null
	return ..()

// grant_succubus_powers()/remove_succubus_powers() live in succubus_camouflage.dm

/datum/antagonist/succubus/proc/adjust_essence(amount)
	essence = clamp(essence + amount, 0, essence_cap)

/// COMSIG_MOB_GET_STATUS_TAB_ITEMS handler: essence readout in the Status tab
/datum/antagonist/succubus/proc/on_status_tab(datum/source, list/items)
	SIGNAL_HANDLER
	items += "Essence: [essence] / [essence_cap]"
	items += "Infernal Favor: Tier [get_succubus_contract_tier()]"

/// Called from the climax pipeline when someone climaxes with the succubus as partner.
/datum/antagonist/succubus/proc/harvest_from_climax(mob/living/carbon/human/partner, was_virgin_at_action_start = FALSE)
	if(!istype(partner) || !partner.mind || partner == owner?.current)
		return
	if(last_harvest_mind == partner.mind && last_harvest_time == world.time)
		return
	last_harvest_mind = partner.mind
	last_harvest_time = world.time
	var/mob/living/current_body = owner?.current
	if(is_succubus_consecrated(partner) || is_succubus_consecrated(current_body))
		if(current_body)
			to_chat(current_body, span_userdanger("The refuge's ward catches their release and burns it away before I can feed!"))
			revert_form(forced = TRUE)
		to_chat(partner, span_boldnotice("A clean warmth answers from the ward, leaving nothing hungry behind."))
		return
	var/harvest_count = partner_harvests[partner.mind] || 0
	var/novelty = max(SUCCUBUS_NOVELTY_FLOOR, SUCCUBUS_NOVELTY_DECAY ** harvest_count)
	var/arousal_mult = 1
	var/partner_arousal = 0
	var/datum/component/arousal/arousal_comp = partner.GetComponent(/datum/component/arousal)
	if(arousal_comp)
		partner_arousal = arousal_comp.arousal
		arousal_mult += min(partner_arousal / SUCCUBUS_AROUSAL_BONUS_DIVISOR, SUCCUBUS_AROUSAL_BONUS_MAX)
	var/corruption_mult = get_corruption_multiplier(partner, was_virgin_at_action_start)
	var/gained = round(SUCCUBUS_ESSENCE_BASE_HARVEST * novelty * arousal_mult * corruption_mult)
	partner_harvests[partner.mind] = harvest_count + 1
	adjust_essence(gained)
	partner.apply_succubus_harvest_depletion()
	if(owner?.current)
		to_chat(owner.current, span_love("Their release feeds me. (+[gained] essence, [essence]/[essence_cap])"))
	store_partner_form(partner)
	if(!partner.mind.key)
		return
	record_contract_progress(/datum/contract_goal/succubus/infernal_tithe, gained)
	if(current_contract)
		for(var/datum/contract_goal/succubus/varied_appetite/variety_goal in current_contract.goals)
			variety_goal.record_partner(partner.mind.key)
	if(partner_arousal >= SUCCUBUS_CONTRACT_HIGH_AROUSAL)
		record_contract_progress(/datum/contract_goal/succubus/heightened_desire)
	if(!isnull(current_form_key))
		record_contract_progress(/datum/contract_goal/succubus/masked_feast)
	if(corruption_mult > 1)
		record_contract_progress(/datum/contract_goal/succubus/sacred_corruption)
	if(true_form_active)
		record_contract_progress(/datum/contract_goal/succubus/unmasked_hunger)

/// Trickle essence from absorbed cum/femcum; decay compounds per originator so
/// one donor can't be farmed as a bottomless keg.
/datum/antagonist/succubus/proc/harvest_from_reagent(datum/mind/donor, volume)
	if(volume <= 0)
		return
	var/decay = SUCCUBUS_NOVELTY_FLOOR // untraceable fluid is stale fluid
	if(donor)
		var/absorbed = reagent_units_absorbed[donor] || 0
		decay = max(SUCCUBUS_NOVELTY_FLOOR, SUCCUBUS_REAGENT_DECAY ** (absorbed / SUCCUBUS_REAGENT_DECAY_UNIT))
		reagent_units_absorbed[donor] = absorbed + volume
	adjust_essence(round(SUCCUBUS_ESSENCE_PER_REAGENT_UNIT * volume * decay, 0.1))

/datum/antagonist/succubus/proc/get_corruption_multiplier(mob/living/carbon/human/partner, was_virgin_at_action_start = FALSE)
	var/corruption_multiplier = 1
	if(partner.IsWedded())
		corruption_multiplier = max(corruption_multiplier, SUCCUBUS_CORRUPTION_MARRIED)
	if(was_virgin_at_action_start)
		corruption_multiplier = max(corruption_multiplier, SUCCUBUS_CORRUPTION_VIRGIN)
	if(partner.mind?.assigned_role?.title in GLOB.succubus_clergy_roles)
		corruption_multiplier = max(corruption_multiplier, SUCCUBUS_CORRUPTION_CLERGY)
	return corruption_multiplier

GLOBAL_LIST_INIT(succubus_clergy_roles, list(
	"Chapel Acolyte",
	"Moon Priest",
	"Heart Priest",
	"Adventurer Cleric",
	"Adventurer Monk",
))
