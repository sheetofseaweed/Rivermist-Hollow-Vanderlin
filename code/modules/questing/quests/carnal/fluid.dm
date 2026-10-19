/// Bring a creature's own seed or nectar back to the ledger.
/datum/quest/kill/carnal/fluid
	quest_type = QUEST_FLUID_HARVEST
	mob_types_to_spawn = QUEST_CARNAL_FLUID_LIST
	count_min = 1
	count_max = 2
	minimum_tier = QUEST_TIER_ROUTINE
	maximum_tier = QUEST_TIER_DEADLY
	/// QUEST_FLUID_SEED or QUEST_FLUID_NECTAR.
	var/fluid_kind
	var/datum/reagent/required_fluid_type
	var/units_required = 0

/datum/quest/kill/carnal/fluid/build_title()
	if(!target_mob_type)
		return "Harvest a creature's fluids"
	return "Harvest [initial(target_mob_type.name)] [fluid_kind == QUEST_FLUID_NECTAR ? "nectar" : "seed"]"

/datum/quest/kill/carnal/fluid/get_objective_text()
	var/fluid_name = required_fluid_type ? initial(required_fluid_type.name) : "creature fluid"
	var/source_hint = fluid_kind == QUEST_FLUID_NECTAR ? "Bring her to climax over a container" : "Milk him into a container, or take his load and expel it into a bottle"
	return "Bring [units_required] units of [fluid_name] to the marked area beside the contract ledger, then turn the contract in. [source_hint]."

/datum/quest/kill/carnal/fluid/prepare_for_issuer(mob/living/carbon/human/issuer)
	..()
	fluid_kind = pick_fluid_kind()

/datum/quest/kill/carnal/fluid/is_visible_to(mob/living/carbon/human/viewer)
	if(!..())
		return FALSE
	var/needed_tag = fluid_kind == QUEST_FLUID_NECTAR ? HORNY_MOBS_TAG_FEMALES : HORNY_MOBS_TAG_MALES
	return !!(viewer.get_cached_horny_mob_pref_flags() & needed_tag)

/datum/quest/kill/carnal/fluid/proc/pick_fluid_kind()
	var/list/kinds = list()
	if(isnull(allowed_gender_tags) || (allowed_gender_tags & HORNY_MOBS_TAG_MALES))
		kinds += QUEST_FLUID_SEED
	if(isnull(allowed_gender_tags) || (allowed_gender_tags & HORNY_MOBS_TAG_FEMALES))
		kinds += QUEST_FLUID_NECTAR
	return length(kinds) ? pick(kinds) : QUEST_FLUID_SEED

/datum/quest/kill/carnal/fluid/generate(obj/effect/landmark/quest_spawner/landmark)
	if(!fluid_kind)
		fluid_kind = pick_fluid_kind()
	return ..()

/datum/quest/kill/carnal/fluid/pick_spawn_gender()
	return fluid_kind == QUEST_FLUID_NECTAR ? FEMALE : MALE

/datum/quest/kill/carnal/fluid/on_targets_spawned()
	required_fluid_type = get_creature_fluid_type(target_mob_type, fluid_kind)
	if(!required_fluid_type)
		return FALSE
	units_required = get_units_for_tier(requested_tier)
	progress_required = 1
	return TRUE

/// Sized so one creature's starting load covers the contract; refills only speed it up.
/datum/quest/kill/carnal/fluid/proc/get_units_for_tier(tier)
	switch(tier)
		if(QUEST_TIER_ROUTINE)
			return 6
		if(QUEST_TIER_RISKY)
			return 10
		if(QUEST_TIER_DANGEROUS)
			return 14
	return 18

/datum/quest/kill/carnal/fluid/get_reward_multiplier()
	return QUEST_FLUID_REWARD_MULTIPLIER

/datum/quest/kill/carnal/fluid/get_task_reward_bonus()
	return units_required * QUEST_FLUID_REWARD_PER_UNIT

/datum/quest/kill/carnal/fluid/proc/get_turn_in_containers(turf/input_point)
	. = list()
	if(!required_fluid_type)
		return
	for(var/obj/item/reagent_containers/container in input_point)
		if(container.reagents?.get_reagent_amount(required_fluid_type) > 0)
			. += container

/datum/quest/kill/carnal/fluid/proc/count_units(list/containers)
	. = 0
	for(var/obj/item/reagent_containers/container as anything in containers)
		. += container.reagents.get_reagent_amount(required_fluid_type)

/datum/quest/kill/carnal/fluid/has_turn_in_goods(turf/input_point)
	return count_units(get_turn_in_containers(input_point)) >= units_required

/datum/quest/kill/carnal/fluid/try_collect_turn_in_goods(turf/input_point, mob/user)
	var/list/containers = get_turn_in_containers(input_point)
	if(count_units(containers) < units_required)
		return FALSE
	var/units_left = units_required
	for(var/obj/item/reagent_containers/container as anything in containers)
		var/taken = min(units_left, container.reagents.get_reagent_amount(required_fluid_type))
		container.reagents.remove_reagent(required_fluid_type, taken)
		units_left -= taken
		if(units_left <= 0)
			break
	progress_current = progress_required
	mark_complete()
	return TRUE

/// The seed or nectar reagent a creature type makes, or null if it has no creature fluid.
/proc/get_creature_fluid_type(mob_type, fluid_kind)
	var/mob/living/mob_path = mob_type
	var/fluid_type = fluid_kind == QUEST_FLUID_NECTAR ? initial(mob_path.femcum) : initial(mob_path.cum)
	if(ispath(fluid_type, /datum/reagent/consumable/cum/creature) || ispath(fluid_type, /datum/reagent/consumable/femcum/creature))
		return fluid_type
	return null
