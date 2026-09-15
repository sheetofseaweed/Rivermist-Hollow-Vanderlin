/datum/quest/custom/assassinate
	issue_label = "Player assassination"
	commission_type = "Assassination"
	requires_steward_validation = FALSE
	var/target_player_name = ""
	var/target_player_ckey = ""
	var/datum/weakref/target_player_ref

/datum/quest/custom/assassinate/get_title()
	return title ? title : (target_player_name ? "Eliminate [target_player_name]" : "Assassination Contract")

/datum/quest/custom/assassinate/get_objective_text()
	return "Find and eliminate [target_player_name ? target_player_name : "the named target"]."

/datum/quest/custom/assassinate/get_location_text()
	return "Locate [target_player_name ? target_player_name : "the target"] yourself."

/datum/quest/custom/assassinate/get_target_location(turf/reference_turf, atom/movable/preferred_target = null)
	return get_turf(target_player_ref?.resolve())

/datum/quest/custom/assassinate/can_claim(mob/user)
	var/mob/living/target = target_player_ref?.resolve()
	return target && target != user && user?.ckey != target_player_ckey && target.stat != DEAD

/datum/quest/custom/assassinate/build_from_user(mob/user)
	if(!fill_common_fields(user))
		return FALSE
	var/list/player_choices = list()
	for(var/mob/living/carbon/human/player in GLOB.player_list)
		if(player == user || player.stat == DEAD || !player.real_name)
			continue
		player_choices["[length(player_choices) + 1]. [player.real_name] — [player.job ? player.job : "Unknown role"]"] = player
	if(!length(player_choices))
		to_chat(user, span_warning("There are no valid assassination targets."))
		return FALSE
	var/target_choice = tgui_input_list(user, "Select the assassination target:", "Commission Target", player_choices)
	var/mob/living/carbon/human/target_player = player_choices[target_choice]
	if(!target_player)
		return FALSE
	target_player_name = target_player.real_name
	target_player_ckey = target_player.ckey
	title = tgui_input_text(user, "Give the commission a title (leave blank for an automatic title):", "Commission Title", "", 80)
	if(!title)
		title = get_title()
	return TRUE

/datum/quest/custom/assassinate/build_from_pledge(obj/item/paper/scroll/quest/pledge/pledge, mob/steward)
	if(!..())
		return FALSE
	target_player_name = pledge.pledge_assassin_target
	target_player_ckey = pledge.pledge_assassin_target_ckey
	return !!target_player_name

/datum/quest/custom/assassinate/build_pledge(obj/item/paper/scroll/quest/pledge/pledge)
	..()
	pledge.pledge_assassin_target = target_player_name
	pledge.pledge_assassin_target_ckey = target_player_ckey

/datum/quest/custom/assassinate/generate(obj/effect/landmark/quest_spawner/landmark)
	. = ..()
	progress_required = 1
	for(var/mob/living/carbon/human/player in GLOB.player_list)
		if(target_player_ckey ? player.ckey != target_player_ckey : player.real_name != target_player_name)
			continue
		RegisterSignal(player, COMSIG_LIVING_DEATH, PROC_REF(on_target_death))
		target_player_ref = WEAKREF(player)
		break

/datum/quest/custom/assassinate/validate(mob/steward, turf/input_point, obj/structure/fake_machine/contractledger/ledger)
	to_chat(steward, span_warning("Assassination commissions are verified automatically when the assigned contractor kills the target."))
	return FALSE

/datum/quest/custom/assassinate/proc/on_target_death(mob/living/dead_mob, gibbed)
	SIGNAL_HANDLER
	if(complete)
		return
	var/mob/receiver = quest_receiver_reference?.resolve()
	if(!receiver || dead_mob.lastattacker_weakref?.resolve() != receiver)
		return
	progress_current = progress_required
	mark_complete()

/datum/quest/custom/assassinate/Destroy()
	var/mob/living/target = target_player_ref?.resolve()
	if(target)
		UnregisterSignal(target, COMSIG_LIVING_DEATH)
	target_player_ref = null
	return ..()
