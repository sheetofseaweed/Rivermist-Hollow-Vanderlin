// Succubus antagonist core

/datum/antagonist/succubus
	name = "Succubus"
	roundend_category = "Other Villains"
	antagpanel_category = "Villain"
	job_rank = ROLE_SUCCUBUS
	var/essence = 0
	var/essence_cap = SUCCUBUS_ESSENCE_CAP_BASE
	/// mind -> number of climaxes harvested from that partner (novelty decay input)
	var/list/partner_harvests = list()
	/// Same-tick harvest dedupe: the climax pipeline runs once per producing organ,
	/// so a multi-organ partner's single climax would otherwise harvest twice
	var/datum/mind/last_harvest_mind
	var/last_harvest_time = -1

/datum/antagonist/succubus/greet()
	to_chat(owner.current, span_userdanger("I hunger, and this town is a banquet. I must feed on their lust — carefully, sweetly, unseen."))
	owner.announce_objectives()
	return ..()

/datum/antagonist/succubus/on_gain()
	. = ..()
	grant_succubus_powers()

/datum/antagonist/succubus/on_removal()
	remove_succubus_powers()
	return ..()

/datum/antagonist/succubus/Destroy()
	QDEL_NULL(base_form)
	QDEL_LIST_ASSOC_VAL(stolen_forms)
	partner_harvests = null
	last_harvest_mind = null
	return ..()

// grant_succubus_powers() / remove_succubus_powers() are defined in succubus_camouflage.dm
// (Task 4), which composes in the T1/T2 ability kit from succubus_abilities.dm (Task 5).

/datum/antagonist/succubus/proc/adjust_essence(amount)
	essence = clamp(essence + amount, 0, essence_cap)

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
	store_partner_form(partner) // defined in succubus_camouflage.dm (Task 4)

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
