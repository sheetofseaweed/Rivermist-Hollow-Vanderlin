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
	. = ..()
	grant_succubus_powers()

/datum/antagonist/succubus/on_removal()
	// Revert first so the mind is moved back to the human before the antag detaches
	if(true_form_active)
		leave_true_form()
	remove_succubus_powers()
	return ..()

/datum/antagonist/succubus/Destroy()
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

/// Called from the climax pipeline when someone climaxes with the succubus as partner.
/datum/antagonist/succubus/proc/harvest_from_climax(mob/living/carbon/human/partner)
	if(!istype(partner) || !partner.mind || partner == owner?.current)
		return
	if(last_harvest_mind == partner.mind && last_harvest_time == world.time)
		return
	var/harvest_count = partner_harvests[partner.mind] || 0
	var/novelty = max(SUCCUBUS_NOVELTY_FLOOR, SUCCUBUS_NOVELTY_DECAY ** harvest_count)
	var/arousal_mult = 1
	var/datum/component/arousal/arousal_comp = partner.GetComponent(/datum/component/arousal)
	if(arousal_comp)
		arousal_mult = 1 + (arousal_comp.arousal / 200)
	var/gained = round(SUCCUBUS_ESSENCE_BASE_HARVEST * novelty * arousal_mult * get_corruption_multiplier(partner))
	partner_harvests[partner.mind] = harvest_count + 1
	last_harvest_mind = partner.mind
	last_harvest_time = world.time
	adjust_essence(gained)
	if(owner?.current)
		to_chat(owner.current, span_love("Their release feeds me. (+[gained] essence, [essence]/[essence_cap])"))
	store_partner_form(partner)

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

/datum/antagonist/succubus/proc/get_corruption_multiplier(mob/living/carbon/human/partner)
	if(partner.mind?.assigned_role?.title in GLOB.succubus_clergy_roles)
		return SUCCUBUS_CORRUPTION_CLERGY
	return 1

GLOBAL_LIST_INIT(succubus_clergy_roles, list(
	"Chapel Acolyte",
	"Moon Priest",
	"Heart Priest",
	"Adventurer Cleric",
	"Adventurer Monk",
))
