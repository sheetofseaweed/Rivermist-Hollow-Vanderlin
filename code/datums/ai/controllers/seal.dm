/datum/ai_controller/seal
	movement_delay = 0.4 SECONDS
	ai_movement = /datum/ai_movement/hybrid_pathing
	blackboard = list(
		BB_PET_TARGETING_DATUM = new /datum/targetting_datum/basic/not_friends(),
		BB_KEY_SWIMMER_COOLDOWN = 30 SECONDS,
	)
	idle_behavior = /datum/idle_behavior/idle_random_walk
	planning_subtrees = list(
		/datum/ai_planning_subtree/pet_planning,
		/datum/ai_planning_subtree/seal_dive,
		/datum/ai_planning_subtree/go_for_swim,
	)
