// Debug grant verbs for the DND spell pack.
// These names are intentionally different from existing debug_grant_dnd_fireball() verbs.

/mob/living/carbon/human/verb/debug_grant_dnd_spell_pack()
	set name = "Grant DND Spell Pack"
	set category = "Debug"
	set hidden = TRUE

	if(usr != src || !check_rights(R_DEBUG))
		return

	setup_default_dnd_spell_slots()
	grant_dnd_spell_hud()

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
		add_spell(spell_type)

	to_chat(src, span_notice("DND spell pack granted."))

/mob/living/carbon/human/verb/debug_grant_dnd_fireball_v2()
	set name = "Grant DND Fireball V2"
	set category = "Debug"
	set hidden = TRUE

	if(usr != src || !check_rights(R_DEBUG))
		return

	setup_default_dnd_spell_slots()
	grant_dnd_spell_hud()

	add_spell(/datum/action/cooldown/spell/projectile/dnd_fireball)

	to_chat(src, span_notice("DND Fireball granted."))
