// Debug grants for the spell slot system. Registered under the debug admin verbs.

/client/proc/debug_grant_spell_slots()
	set name = "Grant Spell Slots"
	set category = "Debug"

	if(!check_rights_for(src, R_DEBUG))
		return

	var/mob/living/carbon/human/caster = mob
	if(!istype(caster) || !caster.mind)
		to_chat(src, span_warning("I must be controlling a human with a mind to grant spell slots."))
		return

	var/static/list/archetypes = list(CASTER_FULL, CASTER_HALF, CASTER_THIRD, CASTER_PACT)
	var/archetype = tgui_input_list(src, "Caster archetype", "Spell Slots", archetypes, CASTER_FULL)
	if(!archetype)
		return
	var/datum/spell_slots/slots = caster.mind.setup_spell_slots(archetype)
	if(tgui_alert(src, "Use the ladder for the current arcane rank, or force the Master row (4/3/3/2/1)?", "Spell Slots", list("Ladder", "Master row")) == "Master row")
		slots.set_fixed_slots(list(4, 3, 3, 2, 1))
	else
		slots.set_fixed_slots(null)
	slots.restore_all_slots()
	slots.short_rest_current = slots.get_short_rest_max()
	slots.next_long_rest = 0
	caster.grant_spell_slot_hud()
	to_chat(src, span_notice("Spell slots granted: [archetype] caster at rank [slots.get_rank()]."))

/client/proc/debug_grant_slot_spell_pack()
	set name = "Grant Slot Spell Pack"
	set category = "Debug"

	if(!check_rights_for(src, R_DEBUG))
		return

	var/mob/living/carbon/human/caster = mob
	if(!istype(caster) || !caster.mind)
		to_chat(src, span_warning("I must be controlling a human with a mind to grant slot spells."))
		return

	if(!caster.mind.spell_slots)
		caster.mind.setup_spell_slots(CASTER_FULL)
	var/datum/spell_slots/slots = caster.mind.spell_slots
	slots.restore_all_slots()
	slots.short_rest_current = slots.get_short_rest_max()
	slots.next_long_rest = 0

	var/static/list/spells_to_grant = list(
		/datum/action/cooldown/spell/projectile/fireball,
		/datum/action/cooldown/spell/projectile/fireball/greater,
		/datum/action/cooldown/spell/projectile/frost_bolt,
		/datum/action/cooldown/spell/projectile/acid_splash,
		/datum/action/cooldown/spell/projectile/lightning,
		/datum/action/cooldown/spell/conjure/familiar,
		/datum/action/cooldown/spell/healing,
		/datum/action/cooldown/spell/sacred_flame,
		/datum/action/cooldown/spell/mind_spike,
		/datum/action/cooldown/spell/undirected/arcane_recovery,
		/datum/action/cooldown/spell/undirected/touch/prestidigitation,
		/datum/action/cooldown/spell/undirected/conjure_item/light,
	)
	for(var/spell_type in spells_to_grant)
		caster.add_spell(spell_type)

	caster.grant_spell_slot_hud()
	to_chat(src, span_notice("Slot spell pack granted."))
