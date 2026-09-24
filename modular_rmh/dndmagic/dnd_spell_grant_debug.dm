// Debug grant verbs for the DND spell pack.
// These names are intentionally different from existing debug_grant_dnd_fireball() verbs.

/client/proc/debug_grant_dnd_spell_pack()
	set name = "Grant DND Spell Pack"
	set category = "Debug"

	if(!check_rights_for(src, R_DEBUG))
		return

	var/mob/living/carbon/human/caster = mob
	if(!istype(caster))
		to_chat(src, span_warning("I must be controlling a human to grant DND spells."))
		return

	caster.setup_default_dnd_spell_slots()
	caster.grant_dnd_spell_hud()

	var/list/spells_to_grant = list(
		/datum/action/cooldown/spell/conjure/familiar/dnd,
		/datum/action/cooldown/spell/projectile/dnd_fireball,
		/datum/action/cooldown/spell/projectile/dnd_fireball/greater,
		/datum/action/cooldown/spell/projectile/acid_splash/dnd,
		/datum/action/cooldown/spell/projectile/frost_bolt/dnd,
		/datum/action/cooldown/spell/projectile/lightning/dnd,
		/datum/action/cooldown/spell/healing/dnd,
		/datum/action/cooldown/spell/sacred_flame/dnd,
		/datum/action/cooldown/spell/mind_spike/dnd,
	)

	for(var/spell_type in spells_to_grant)
		caster.add_spell(spell_type)

	to_chat(src, span_notice("DND spell pack granted."))

/client/proc/debug_grant_dnd_fireball_v2()
	set name = "Grant DND Fireball V2"
	set category = "Debug"

	if(!check_rights_for(src, R_DEBUG))
		return

	var/mob/living/carbon/human/caster = mob
	if(!istype(caster))
		to_chat(src, span_warning("I must be controlling a human to grant DND spells."))
		return

	caster.setup_default_dnd_spell_slots()
	caster.grant_dnd_spell_hud()

	caster.add_spell(/datum/action/cooldown/spell/projectile/dnd_fireball)

	to_chat(src, span_notice("DND Fireball granted."))
