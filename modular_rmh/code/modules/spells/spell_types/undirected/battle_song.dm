/datum/action/cooldown/spell/undirected/battle_song
	name = "Battle Song"
	desc = "Sing a battle song that empowers you and nearby allies."
	button_icon_state = "bcry"
	sound = 'modular_rmh/sound/magic/battle_song.ogg'

	antimagic_flags = NONE

	associated_skill = /datum/skill/combat/unarmed
	associated_stat = STATKEY_STR

	charge_required = FALSE
	has_visual_effects = FALSE
	cooldown_time = 1 MINUTES
	spell_type = SPELL_STAMINA
	spell_cost = 15

/datum/action/cooldown/spell/undirected/battle_song/is_valid_target(atom/cast_on)
	. = ..()
	if(!.)
		return
	return isliving(owner)

/datum/action/cooldown/spell/undirected/battle_song/cast(mob/living/cast_on)
	. = ..()

	for(var/mob/living/L in hearers(5, cast_on))
		if(!L.client)
			continue
		if(!L.can_hear())
			continue
		if(!cast_on.faction_check_mob(L) && L != cast_on)
			continue
		if(L.has_status_effect(/datum/status_effect/buff/battle_song))
			continue

		L.apply_status_effect(/datum/status_effect/buff/battle_song)
		new /obj/effect/temp_visual/songs(get_turf(L))
