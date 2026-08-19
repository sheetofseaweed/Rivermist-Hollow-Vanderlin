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
	var/obj/structure/bandit_camp_entrance/destination = pick(GLOB.bandit_player_insertions)
	if(QDELETED(destination))
		return FALSE
	user.recent_travel = world.time
	movable_travel_z_level(user, get_turf(destination))
	return TRUE

// The overworld mouth of the camp. Deliberately not a travel tile: it opens the pocket
// dimension directly and owns no portal pairing, so nothing else can route mobs onto it.
/obj/structure/bandit_camp_entrance
	name = "hidden trail"
	desc = "Trampled brush and a bent branch, set the way the free company marks its ways."
	icon = 'icons/turf/floors.dmi'
	icon_state = "travel"
	layer = ABOVE_OPEN_TURF_LAYER
	density = FALSE
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE
	/// How long a bandit follows the trail before the camp takes them.
	var/entry_time = 5 SECONDS

/obj/structure/bandit_camp_entrance/Initialize()
	. = ..()
	GLOB.bandit_player_insertions += src
	// Invisible to everyone; the alt appearance shows it back to trait holders only.
	invisibility = INVISIBILITY_OBSERVER
	var/image/trail_marks = image(icon = icon, icon_state = icon_state, layer = layer, loc = src)
	add_alt_appearance(/datum/atom_hud/alternate_appearance/basic/traveltile, TRAIT_BANDITCAMP, trail_marks)

/obj/structure/bandit_camp_entrance/Destroy()
	GLOB.bandit_player_insertions -= src
	return ..()

/obj/structure/bandit_camp_entrance/proc/reveal_to(mob/living/user)
	var/datum/atom_hud/alternate_appearance/trail_hud = LAZYACCESS(alternate_appearances, TRAIT_BANDITCAMP)
	trail_hud?.add_hud_to(user)

// Mob Initialize/Login only catch trait holders that already exist, so recruits need this on gain.
/proc/reveal_bandit_camp_entrances(mob/living/user)
	if(!istype(user))
		return
	for(var/obj/structure/bandit_camp_entrance/entrance as anything in GLOB.bandit_player_insertions)
		entrance.reveal_to(user)

/obj/structure/bandit_camp_entrance/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(isliving(user))
		INVOKE_ASYNC(src, PROC_REF(try_enter_camp), user)

/obj/structure/bandit_camp_entrance/Crossed(atom/movable/AM, oldloc)
	. = ..()
	if(!isliving(AM))
		return
	var/mob/living/walker = AM
	if(walker.stat != CONSCIOUS || walker.incapacitated(IGNORE_GRAB))
		return
	// Deferred a tick: entering in the crossing chain drops whatever the bandit is pulling.
	addtimer(CALLBACK(src, PROC_REF(try_enter_camp), walker), 1)

/obj/structure/bandit_camp_entrance/proc/can_enter(mob/living/user)
	if(!isbandit(user))
		return FALSE
	if(user.pulledby)
		return FALSE
	// Shares the teleport cooldown with the camp exit, so the trail can't be ridden both ways.
	if(user.recent_travel && world.time < user.recent_travel + 15 SECONDS)
		return FALSE
	return TRUE

/obj/structure/bandit_camp_entrance/proc/try_enter_camp(mob/living/user)
	if(!istype(user) || !can_enter(user))
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
	if(!do_after(user, entry_time, src, IGNORE_HELD_ITEM))
		return
	if(QDELETED(src) || QDELETED(user) || !Adjacent(user) || !can_enter(user))
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
