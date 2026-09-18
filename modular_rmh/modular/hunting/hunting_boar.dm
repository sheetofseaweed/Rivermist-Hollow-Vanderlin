// Hunting & Tracking pack - the bramblesnout, hunting's heavy quarry.
//
// Hit locations go through simple_limb_hit(zone), the same as RMH's other animals. The charge
// ability lives in hunting_boar_charge.dm; this file is the animal itself.

/// Bramblesnouts are meant to be a fight, not a chore. Kept as a define so it is tunable in one place.
#define BOAR_HEALTH 250
/// Deliberately slow swings for how hard they hit.
#define BOAR_ATTACK_SPEED 15

/mob/living/simple_animal/hostile/retaliate/boar
	icon = 'modular_rmh/icons/mob/monster/boar.dmi'
	name = "bramblesnout"
	desc = "The ever terrifying bramblesnout. Not just large, but its many tusks hook into flesh to \
	create grievous wounds. Being charged is a surefire way to perish. It is a hulking mass of muscle, \
	yet still nimble. Oft hunted in pairs, with at least one hunter getting their stomach gouged..."
	icon_state = "boar"
	icon_living = "boar"
	icon_dead = "boar_dead"
	pixel_x = -8
	gender = MALE
	emote_hear = null
	emote_see = null
	speak_chance = 1
	see_in_dark = 6
	move_to_delay = 5
	base_intents = list(/datum/intent/simple/claw/boar)
	faction = list("boars")
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	health = BOAR_HEALTH
	maxHealth = BOAR_HEALTH
	melee_damage_lower = 30
	melee_damage_upper = 40
	vision_range = 7
	aggro_vision_range = 9
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	retreat_distance = 0
	minimum_distance = 0
	footstep_type = FOOTSTEP_MOB_BAREFOOT
	deaggroprob = 0
	defprob = 40
	retreat_health = 0.3
	dodgetime = 30
	aggressive = 1
	remains_type = /obj/effect/decal/remains/mole
	ai_controller = /datum/ai_controller/boar
	attack_sound = list(
		'modular_rmh/sound/hunting/boar_attack.ogg',
		'modular_rmh/sound/hunting/boar_charge.ogg',
	)
	food_type = list(/obj/item/reagent_containers/food/snacks/meat)
	// Like a pig, but some of the meat and fat is traded for hide.
	botched_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/steak = 2,
		/obj/item/alch/sinew = 2,
		/obj/item/alch/bone = 2,
		/obj/item/alch/viscera = 1,
		/obj/item/natural/hide = 1,
	)
	butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/steak = 4,
		/obj/item/reagent_containers/food/snacks/fat = 2,
		/obj/item/natural/bundle/bone/full = 1,
		/obj/item/alch/sinew = 3,
		/obj/item/alch/bone = 1,
		/obj/item/alch/viscera = 2,
		/obj/item/natural/hide = 2,
	)
	perfect_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/steak = 5,
		/obj/item/reagent_containers/food/snacks/fat = 3,
		/obj/item/natural/bundle/bone/full = 1,
		/obj/item/alch/sinew = 4,
		/obj/item/alch/bone = 1,
		/obj/item/alch/viscera = 2,
		/obj/item/natural/hide = 3,
	)
	head_butcher = /obj/item/natural/head/boar

/mob/living/simple_animal/hostile/retaliate/boar/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/ai_aggro_system)
	// STASTR/STASPD are final vars, computed from the attribute system, so they cannot be assigned
	// directly - these adjust off the base of 10 to reach 15 STR / 13 SPD.
	change_stat(STAT_STRENGTH, 5)
	change_stat(STAT_SPEED, 3)
	var/datum/action/cooldown/mob_cooldown/boar_charge/charge = new(src)
	charge.Grant(src)
	ai_controller?.set_blackboard_key(BB_BOAR_CHARGE, charge)
	gender = prob(33) ? FEMALE : MALE
	update_icon()

/mob/living/simple_animal/hostile/retaliate/boar/death(gibbed)
	. = ..()
	update_icon()

// Aggro is handled by the retaliate base and the aggro component; taunted() only voices it here,
// the same as minotaur and mirespider do.
/mob/living/simple_animal/hostile/retaliate/boar/taunted(mob/user)
	emote("aggro")
	return

/mob/living/simple_animal/hostile/retaliate/boar/get_sound(input)
	switch(input)
		if("aggro", "pain")
			return 'modular_rmh/sound/hunting/pighangry.ogg'
		if("death")
			return 'modular_rmh/sound/hunting/piglin.ogg'
		if("idle")
			return pick('modular_rmh/sound/hunting/pig1.ogg', 'modular_rmh/sound/hunting/pig2.ogg')

/// Names the part that got hit, so combat messages read like an animal and not a person.
/mob/living/simple_animal/hostile/retaliate/boar/simple_limb_hit(zone)
	if(!zone)
		return ""
	switch(zone)
		if(BODY_ZONE_PRECISE_R_EYE, BODY_ZONE_PRECISE_L_EYE, BODY_ZONE_PRECISE_SKULL, BODY_ZONE_PRECISE_EARS, BODY_ZONE_HEAD)
			return "head"
		if(BODY_ZONE_PRECISE_NOSE)
			return "snout"
		if(BODY_ZONE_PRECISE_MOUTH)
			return "tusks"
		if(BODY_ZONE_PRECISE_NECK)
			return "neck"
		if(BODY_ZONE_PRECISE_L_HAND, BODY_ZONE_PRECISE_R_HAND, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
			return "foreleg"
		if(BODY_ZONE_PRECISE_L_FOOT, BODY_ZONE_PRECISE_R_FOOT, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
			return "leg"
		if(BODY_ZONE_PRECISE_STOMACH)
			return "stomach"
		if(BODY_ZONE_PRECISE_GROIN)
			return "tail"
	return ..()

/datum/intent/simple/claw/boar
	name = "tusks"
	clickcd = BOAR_ATTACK_SPEED
	attack_verb = list("gores", "impales", "eviscerates")
	penfactor = PEN_HEAVY
	blade_class = BCLASS_STAB

// Target-finding is simple_find_target rather than aggro_find_target: the latter only looks once
// something has already provoked the mob, which left the boar waiting to be hit first.
/datum/ai_controller/boar
	movement_delay = 0.5 SECONDS
	ai_movement = /datum/ai_movement/hybrid_pathing
	idle_behavior = /datum/idle_behavior/idle_random_walk
	blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic/allow_items(),
		BB_PET_TARGETING_DATUM = new /datum/targetting_datum/basic/not_friends(),
	)
	planning_subtrees = list(
		/datum/ai_planning_subtree/simple_find_target,
		// Charge is planned before melee, and on continue_planning so it does not starve it.
		// basic_melee_attack_subtree returns SUBTREE_RETURN_FINISH_PLANNING the moment it has a
		// target, so anything queued after it never gets reached at all.
		/datum/ai_planning_subtree/targeted_mob_ability/continue_planning/boar_charge,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
	)

/obj/item/natural/head/boar
	item_weight = 2 KILOGRAMS
	name = "bramblesnout head"
	desc = "The severed head of a bramblesnout, tusks and all. A hunter's trophy, and proof of a fight survived."
	icon = 'modular_rmh/icons/obj/hunting/hunting_heads.dmi'
	icon_state = "boarhead"
	layer = 3.1
	headpricemin = 40
	headpricemax = 90
	sellprice = 60

#undef BOAR_HEALTH
#undef BOAR_ATTACK_SPEED
