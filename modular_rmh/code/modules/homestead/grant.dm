/datum/action/cooldown/spell/undirected/list_target/grant_resident
	name = "Grant Residency"
	desc = "Offer someone residency."
	button_icon_state = "recruit_bog"

	var/grant_message = "You may reside here, %TARGET."
	var/accept_message = "I accept."
	var/refuse_message = "I refuse."
	var/quirk_path = /datum/quirk/resident

/datum/action/cooldown/spell/undirected/list_target/grant_resident/get_list_targets(atom/center, conversion_radius = 7)
	var/list/things = list()

	if(conversion_radius)
		for(var/mob/living/carbon/human/nearby in get_hearers_in_LOS(conversion_radius, center) - center)
			if(!can_grant(nearby))
				continue
			things += nearby

	return things

/datum/action/cooldown/spell/undirected/list_target/grant_resident/proc/can_grant(mob/living/carbon/human/target)

	if(QDELETED(target))
		return FALSE

	if(!target.mind)
		return FALSE

	if(quirk_path && target.has_quirk(quirk_path))
		return FALSE

	if(!target.get_face_name(null))
		return FALSE

	return TRUE


/datum/action/cooldown/spell/undirected/list_target/grant_resident/cast(mob/living/carbon/human/target)

	if(QDELETED(target))
		return

	if(quirk_path && target.has_quirk(quirk_path))
		to_chat(owner, span_warning("[target] is already a resident."))
		return

	if(!target.get_face_name(null))
		to_chat(owner, span_warning("You need to see [target]'s face."))
		return

	. = ..()

	on_grant(target)

/datum/action/cooldown/spell/undirected/list_target/grant_resident/proc/on_grant(mob/living/carbon/human/target)

	SHOULD_CALL_PARENT(TRUE)

	if(quirk_path && !target.has_quirk(quirk_path))
		new quirk_path(target, TRUE)

/datum/job/burgmeister/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()

	if(!spawned || QDELETED(spawned))
		return

	spawned.add_spell(/datum/action/cooldown/spell/undirected/list_target/grant_resident, source = src)


/datum/job/councilor/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()

	if(!spawned || QDELETED(spawned))
		return

	spawned.add_spell(/datum/action/cooldown/spell/undirected/list_target/grant_resident, source = src)








