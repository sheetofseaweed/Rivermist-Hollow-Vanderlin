#define PLAYER_BANDIT_CAMP_KEY "player_bandit_camp"

/area/pocket_dimension/bandit_camp
	name = "Bandit Free Company Camp"

/datum/map_template/pocket/bandit_camp
	name = "Bandit Free Company Camp"
	id = PLAYER_BANDIT_CAMP_KEY
	mappath = "_maps/templates/pockets/player_bandit_camp.dmm"
	exit_structure_type = /obj/structure/pocket_dimension_exit/bandit_camp
	lifecycle_policy = POCKET_LIFECYCLE_KEEP_LOADED
	persistence_mode = POCKET_PERSISTENCE_MOVABLES

/proc/get_player_bandit_camp()
	return SSpocket_dimensions?.get_or_create_instance(PLAYER_BANDIT_CAMP_KEY, /datum/map_template/pocket/bandit_camp, POCKET_LIFECYCLE_KEEP_LOADED)

/obj/effect/landmark/start/bandit_player
	name = ROLE_BANDIT
	icon_state = "arrow"
	jobspawn_override = list(ROLE_BANDIT)
	delete_after_roundstart = FALSE

/obj/effect/landmark/pocket_dimension/exit/bandit_camp
	name = "bandit camp trail marker"
	exit_structure_type = /obj/structure/pocket_dimension_exit/bandit_camp

/obj/structure/pocket_dimension_exit/bandit_camp
	name = "hidden forest trail"
	desc = "A narrow trail concealed behind brush. It leads back toward the town's outskirts."
	icon = 'icons/turf/floors.dmi'
	icon_state = "travel"
	density = FALSE

/obj/structure/pocket_dimension_exit/bandit_camp/use_exit(mob/user)
	INVOKE_ASYNC(src, PROC_REF(try_leave_camp), user)

/obj/structure/pocket_dimension_exit/bandit_camp/proc/try_leave_camp(mob/living/user)
	if(!istype(user) || !length(GLOB.bandit_player_insertions))
		to_chat(user, span_warning("The trail has no safe route out right now."))
		return FALSE
	if(leashed_by_other(user))
		to_chat(user, span_warning("I cannot take the trail while someone holds my leash."))
		return FALSE
	if(user.pulling)
		to_chat(user, span_warning("I need to take the concealed trail alone."))
		return FALSE
	to_chat(user, span_notice("I follow the concealed trail toward the outskirts..."))
	if(!do_after(user, 5 SECONDS, src, IGNORE_HELD_ITEM))
		return FALSE
	if(QDELETED(src) || QDELETED(user) || !Adjacent(user) || user.pulling || !length(GLOB.bandit_player_insertions))
		return FALSE
	var/obj/structure/fluff/traveltile/bandit/destination = pick(GLOB.bandit_player_insertions)
	if(QDELETED(destination))
		return FALSE
	user.recent_travel = world.time
	movable_travel_z_level(user, get_turf(destination))
	return TRUE

// The old overworld Bandit travel tile remains the map-facing trail mouth, but
// now enters this player-only camp rather than the legacy shared CentCom space.
/obj/structure/fluff/traveltile/bandit/Initialize()
	. = ..()
	GLOB.bandit_player_insertions += src

/obj/structure/fluff/traveltile/bandit/Destroy()
	GLOB.bandit_player_insertions -= src
	return ..()

/obj/structure/fluff/traveltile/bandit/user_try_travel(mob/living/user)
	if(!isbandit(user) || !can_go(user))
		return
	if(leashed_by_other(user))
		to_chat(user, span_warning("I cannot enter the hidden trail while someone holds my leash."))
		return
	var/mob/living/pulled_victim
	if(user.pulling)
		pulled_victim = user.pulling
		if(!istype(pulled_victim))
			to_chat(user, span_warning("The hidden trail is too narrow to bring [user.pulling] inside."))
			return
	to_chat(user, span_notice("I follow the signs known only to the free company..."))
	if(!do_after(user, 5 SECONDS, src, IGNORE_HELD_ITEM))
		return
	if(QDELETED(src) || QDELETED(user) || !Adjacent(user) || !isbandit(user) || !can_go(user))
		return
	if(pulled_victim && (QDELETED(pulled_victim) || user.pulling != pulled_victim || !user.Adjacent(pulled_victim)))
		return
	var/datum/pocket_dimension/camp = get_player_bandit_camp()
	if(!camp)
		to_chat(user, span_warning("The hidden trail is impassable right now."))
		return
	var/turf/entrance_turf = get_turf(src)
	if(pulled_victim)
		var/turf/camp_entry_turf = camp.get_entry_turf()
		if(!camp_entry_turf || !camp.send_movable_inside(pulled_victim, entrance_turf, camp_entry_turf, src))
			to_chat(user, span_warning("[pulled_victim] cannot be dragged through the hidden trail."))
			return
		user.stop_pulling()
		log_combat(user, pulled_victim, "dragged into the bandit camp")
		user.visible_message(
			span_warning("[user] drags [pulled_victim] into the hidden trail!"),
			span_notice("I drag [pulled_victim] into the hidden trail."),
		)
		to_chat(pulled_victim, span_warning("[user] drags me through the hidden trail!"))
	if(!camp.enter_mob(user, entrance_turf, src))
		to_chat(user, span_warning("The hidden trail closes before I can enter."))
		return
	user.recent_travel = world.time

#undef PLAYER_BANDIT_CAMP_KEY
