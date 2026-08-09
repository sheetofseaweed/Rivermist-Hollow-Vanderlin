/datum/ai_controller/saiga/terrorbird
	movement_delay = 0.5 SECONDS
	blackboard = list(
		BB_TARGET_HELD_ITEM = /obj/item/reagent_containers/food/snacks/meat,
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic/allow_items/not_holding_item(),
		BB_PET_TARGETING_DATUM = new /datum/targetting_datum/basic/not_friends(),
		BB_BASIC_MOB_FLEEING = TRUE,
	)

/datum/ai_controller/saiga/terrorbird/on_user_tamed(datum/source, mob/tamer)
	//SIGNAL_HANDLER
	. = ..()
	// Clearing BB_BASIC_MOB_FLEEING in the parent also flips the melee subtree off its
	// hit-and-run behaviour, so a tamed bird commits to the fight.
	movement_delay = 0.2 SECONDS

/datum/ai_controller/saiga_kid/terrorbird
	blackboard = list(
		BB_TARGET_HELD_ITEM = /obj/item/reagent_containers/food/snacks/meat,
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic/allow_items/not_holding_item(),
		BB_PET_TARGETING_DATUM = new /datum/targetting_datum/basic/not_friends(),
		BB_BASIC_MOB_FLEEING = TRUE,
	)
