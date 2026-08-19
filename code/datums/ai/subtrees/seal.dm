#define SEAL_DIVE_DELAY_MIN 15 SECONDS
#define SEAL_DIVE_DELAY_MAX 30 SECONDS

/// Occasionally moves seals vertically through connected, swimmable water levels.
/datum/ai_planning_subtree/seal_dive

/datum/ai_planning_subtree/seal_dive/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	var/mob/living/simple_animal/pet/seal/seal = controller.pawn
	if(!istype(seal) || seal.stat != CONSCIOUS)
		return

	var/turf/open/water/current_water = get_turf(seal)
	if(!istype(current_water) || !current_water.is_swimmable() || !HAS_TRAIT(seal, TRAIT_MOVE_SWIMMING))
		return

	var/next_dive_time = controller.blackboard[BB_SEAL_NEXT_DIVE]
	if(isnull(next_dive_time))
		controller.set_blackboard_key(BB_SEAL_NEXT_DIVE, world.time + rand(SEAL_DIVE_DELAY_MIN, SEAL_DIVE_DELAY_MAX))
		return
	if(next_dive_time > world.time)
		return

	var/list/possible_directions = list()
	if(current_water.water_height == WATER_HEIGHT_FULL && seal.can_z_move(UP, current_water, z_move_flags = ZMOVE_SWIM_FLAGS))
		possible_directions += UP
	if(seal.can_z_move(DOWN, current_water, z_move_flags = ZMOVE_SWIM_FLAGS))
		possible_directions += DOWN

	controller.set_blackboard_key(BB_SEAL_NEXT_DIVE, world.time + rand(SEAL_DIVE_DELAY_MIN, SEAL_DIVE_DELAY_MAX))
	if(!length(possible_directions))
		return

	controller.queue_behavior(/datum/ai_behavior/seal_dive, pick(possible_directions))
	return SUBTREE_RETURN_FINISH_PLANNING

/datum/ai_behavior/seal_dive/perform(seconds_per_tick, datum/ai_controller/controller, direction)
	. = ..()
	var/mob/living/simple_animal/pet/seal/seal = controller.pawn
	var/turf/open/water/current_water = get_turf(seal)
	if(!istype(seal) || seal.stat != CONSCIOUS || !istype(current_water) || !current_water.is_swimmable() || !HAS_TRAIT(seal, TRAIT_MOVE_SWIMMING))
		finish_action(controller, FALSE)
		return
	if(direction == UP && current_water.water_height != WATER_HEIGHT_FULL)
		finish_action(controller, FALSE)
		return

	var/turf/destination = seal.can_z_move(direction, current_water, z_move_flags = ZMOVE_SWIM_FLAGS)
	if(!destination)
		finish_action(controller, FALSE)
		return

	if(direction == DOWN)
		seal.visible_message(span_notice("[seal] dives beneath the surface."))
	playsound(current_water, 'sound/effects/fish_splash.ogg', 35, TRUE)
	if(!seal.zMove(direction, destination, ZMOVE_SWIM_FLAGS))
		finish_action(controller, FALSE)
		return
	if(direction == UP)
		seal.visible_message(span_notice("[seal] breaks through the surface."))
	finish_action(controller, TRUE)

#undef SEAL_DIVE_DELAY_MIN
#undef SEAL_DIVE_DELAY_MAX
