/mob/living/simple_animal/hostile/retaliate/wolf/dire
	name = "direwolf"
	desc = "A large snarling beast of mangy fur and yellowed teeth. Direvolves often hail from mountainous areas and attack hapless travelers in the deep forests when prey is scarce."
	icon = 'modular_rmh/icons/mob/monster/direvolf.dmi'
	icon_state = "direvolf_brown"
	icon_living = "direvolf_brown"
	icon_dead = "direvolf_brown_dead"
	icon_state_prefix = "direvolf"
	eye_icon_state = null
	pixel_x = -8
	health = 500
	maxHealth = 500
	melee_damage_lower = 50
	melee_damage_upper = 60
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	base_constitution = 12
	base_strength = 13
	base_speed = 9
	food_type = list(
		/obj/item/reagent_containers/food/snacks,
		/obj/item/bodypart,
		/obj/item/organ,
		/obj/item/alch/bone,
		/obj/item/natural/hide,
	)
	botched_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/steak = 2,
		/obj/item/alch/viscera = 2,
		/obj/item/alch/sinew = 1,
		/obj/item/alch/bone = 2,
	)
	butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/steak = 3,
		/obj/item/reagent_containers/food/snacks/fat = 1,
		/obj/item/natural/hide = 2,
		/obj/item/alch/sinew = 2,
		/obj/item/alch/bone = 4,
		/obj/item/alch/viscera = 3,
		/obj/item/natural/fur/volf = 2,
	)
	perfect_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/steak = 4,
		/obj/item/reagent_containers/food/snacks/fat = 2,
		/obj/item/natural/hide = 3,
		/obj/item/alch/sinew = 2,
		/obj/item/alch/bone = 6,
		/obj/item/alch/viscera = 4,
		/obj/item/natural/fur/volf = 3,
	)
	remains_type = /obj/effect/decal/remains/direwolf
	ai_controller = /datum/ai_controller/direvolf

/obj/effect/decal/remains/direwolf
	name = "remains"
	desc = "Whether by starvation, disease, inter-pack conflict, or an unlucky kick from a saiga, this direvolf has died."
	gender = PLURAL
	icon = 'modular_rmh/icons/mob/monster/direvolf.dmi'
	icon_state = "bones"
	pixel_x = -8

/datum/ai_controller/direvolf
	movement_delay = 0.3 SECONDS
	ai_movement = /datum/ai_movement/hybrid_pathing
	idle_behavior = /datum/idle_behavior/idle_random_walk
	blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic(),
		BB_PET_TARGETING_DATUM = new /datum/targetting_datum/basic/not_friends(),
	)
	planning_subtrees = list(
		/datum/ai_planning_subtree/pet_planning,
		/datum/ai_planning_subtree/flee_target,

		/datum/ai_planning_subtree/simple_find_horny,
		/datum/ai_planning_subtree/horny,

		/datum/ai_planning_subtree/aggro_find_target,
		/datum/ai_planning_subtree/basic_melee_attack_subtree/agile,
	)

/datum/ambush_config/direvolf_pack
	mob_types = list(
		/mob/living/simple_animal/hostile/retaliate/wolf/dire = 2,
		/mob/living/simple_animal/hostile/retaliate/wolf = 4,
	)
