/**
 * Food examine readout.
 *
 * One gold pipe-separated line of state - fare tier, how filling, shelf life,
 * current condition - plus a collapsible list of preparation methods that names
 * the actual verb (slice, mill, fry, bake, boil) rather than a vague "cook".
 *
 * Recipes come from reverse indexes over all three crafting systems, built once
 * on first use in the style of GLOB.snack_slice_reverse:
 *  - container_craft   (pan / oven / cooking pot)
 *  - repeatable_crafting_recipe and orderless_slapcraft (worked by hand)
 * Slapcraft indexes resolve subtypes_allowed and blacklisted_paths up front, so
 * e.g. raw potato does not advertise recipes that only accept a roasted one.
 */

#define FOOD_INFO_COLOUR "#d4af37"

/// ingredient typepath -> list of container_craft singletons taking it directly.
GLOBAL_LIST_INIT(craft_recipes_by_ingredient, build_craft_ingredient_index())
/// wildcard ingredient typepath -> singletons, matched with ispath at lookup.
GLOBAL_LIST_INIT(craft_recipes_by_wildcard, build_craft_wildcard_index())
/// concrete ingredient typepath -> list of hand-worked recipe results.
GLOBAL_LIST_INIT(handcraft_results_by_ingredient, build_handcraft_index())

/proc/build_craft_ingredient_index()
	var/list/index = list()
	for(var/datum/container_craft/recipe_type as anything in GLOB.container_craft_to_singleton)
		var/datum/container_craft/recipe = GLOB.container_craft_to_singleton[recipe_type]
		if(!recipe || IS_ABSTRACT(recipe_type))
			continue
		for(var/ingredient in recipe.requirements)
			LAZYADDASSOCLIST(index, ingredient, recipe)
		for(var/ingredient in recipe.optional_requirements)
			LAZYADDASSOCLIST(index, ingredient, recipe)
	return index

/proc/build_craft_wildcard_index()
	var/list/index = list()
	for(var/datum/container_craft/recipe_type as anything in GLOB.container_craft_to_singleton)
		var/datum/container_craft/recipe = GLOB.container_craft_to_singleton[recipe_type]
		if(!recipe || IS_ABSTRACT(recipe_type))
			continue
		for(var/ingredient in recipe.wildcard_requirements)
			LAZYADDASSOCLIST(index, ingredient, recipe)
		for(var/ingredient in recipe.optional_wildcard_requirements)
			LAZYADDASSOCLIST(index, ingredient, recipe)
	return index

/proc/build_handcraft_index()
	var/list/index = list()

	for(var/starting_path in GLOB.repeatable_crafting_recipes)
		for(var/datum/repeatable_crafting_recipe/recipe as anything in GLOB.repeatable_crafting_recipes[starting_path])
			if(recipe.hides_from_books || !recipe.output)
				continue
			var/atom/result = recipe.output
			var/result_name = initial(result.name)
			// Resolve which concrete paths this recipe will actually accept,
			// honouring subtypes_allowed and the blacklist.
			var/list/candidates = recipe.subtypes_allowed ? typesof(starting_path) : list(starting_path)
			for(var/candidate in candidates)
				if(!recipe.check_matches_requirement(candidate, starting_path))
					continue
				LAZYADDASSOCLIST(index, candidate, result_name)

	for(var/starting_path in GLOB.orderless_slapcraft_recipes)
		for(var/datum/orderless_slapcraft/recipe as anything in GLOB.orderless_slapcraft_recipes[starting_path])
			if(!recipe.output_item)
				continue
			var/atom/result = recipe.output_item
			LAZYADDASSOCLIST(index, starting_path, initial(result.name))

	return index

/// The verb a player performs to run this recipe, from its required container.
/datum/container_craft/proc/get_craft_verb()
	return "cook"

/datum/container_craft/cooking/get_craft_verb()
	return "boil"

/datum/container_craft/pan/get_craft_verb()
	return "fry"

/datum/container_craft/oven/get_craft_verb()
	return "bake"

/// What the finished recipe hands you.
/datum/container_craft/proc/get_result_name()
	if(output)
		var/atom/result = output
		return initial(result.name)
	return name

/datum/container_craft/cooking/get_result_name()
	if(created_reagent)
		var/datum/reagent/result = created_reagent
		return initial(result.name)
	return ..()

/**
 * Preparation methods this item feeds into, grouped by verb. Shared by food,
 * herbs and powders.
 */
/obj/item/proc/get_preparation_lines()
	. = list()
	var/list/by_verb = list()

	for(var/datum/container_craft/recipe as anything in GLOB.craft_recipes_by_ingredient[type])
		LAZYADDASSOCLIST(by_verb, recipe.get_craft_verb(), recipe.get_result_name())
	for(var/wildcard in GLOB.craft_recipes_by_wildcard)
		if(!ispath(type, wildcard))
			continue
		for(var/datum/container_craft/recipe as anything in GLOB.craft_recipes_by_wildcard[wildcard])
			LAZYADDASSOCLIST(by_verb, recipe.get_craft_verb(), recipe.get_result_name())

	for(var/craft_verb in list("fry", "bake", "boil", "cook"))
		var/list/results = by_verb[craft_verb]
		if(!length(results))
			continue
		. += "[capitalize(craft_verb)] into: [english_list(unique_list(results))]."

	var/list/worked = GLOB.handcraft_results_by_ingredient[type]
	if(length(worked))
		. += "Work by hand into: [english_list(unique_list(worked))]."

/// Wraps preparation lines in a collapsible block.
/obj/item/proc/get_preparation_block()
	var/list/lines = get_preparation_lines()
	if(!length(lines))
		return null
	var/list/rendered = list()
	for(var/line in lines)
		rendered += span_smallnotice(" - [line]")
	return "<details><summary>[span_smallnotice("Preparation")]</summary>[rendered.Join("<br>")]</details>"

/obj/item/reagent_containers/food/snacks/proc/get_food_info(mob/user)
	. = list()
	var/list/state = list()

	switch(faretype)
		if(FARE_IMPOVERISHED)
			state += "Beggar's fare"
		if(FARE_POOR)
			state += "Poor fare"
		if(FARE_NEUTRAL)
			state += "Common fare"
		if(FARE_FINE)
			state += "Fine fare"
		if(FARE_LAVISH)
			state += "Lavish fare"

	if(nutrition)
		switch(nutrition)
			if(-INFINITY to 2)
				state += "Morsel"
			if(2 to 4)
				state += "Snack"
			if(4 to 8)
				state += "Light meal"
			if(8 to 14)
				state += "Half meal"
			if(14 to 22)
				state += "Full meal"
			if(22 to 32)
				state += "Hearty meal"
			else
				state += "Feast"

	if(!rotprocess)
		state += "Never spoils"
		state += "None"
	else
		switch(rotprocess)
			if(-INFINITY to SHELFLIFE_MINISCULE)
				state += "Spoils fast"
			if(SHELFLIFE_MINISCULE to SHELFLIFE_SHORT)
				state += "Short shelf life"
			if(SHELFLIFE_SHORT to SHELFLIFE_DECENT)
				state += "Keeps a while"
			if(SHELFLIFE_DECENT to SHELFLIFE_LONG)
				state += "Keeps well"
			else
				state += "Keeps for ages"

		var/remaining = rotprocess + warming
		if(remaining <= 0)
			state += "Spoiled"
		else
			switch(remaining / rotprocess)
				if(0.75 to INFINITY)
					state += "Fresh"
				if(0.4 to 0.75)
					state += "Still good"
				if(0.15 to 0.4)
					state += "Turning"
				else
					state += "Nearly spoiled"

	if(length(state))
		. += "<font color='[FOOD_INFO_COLOUR]'>[state.Join(" | ")]</font>"

	var/list/prep = list()

	if(slice_path && slices_num > 0)
		var/atom/sliced = slice_path
		prep += "Slice into: [initial(sliced.name)]."

	if(mill_result)
		var/atom/milled = mill_result
		prep += "Mill into: [initial(milled.name)]."

	prep += get_preparation_lines()

	if(length(prep))
		var/list/rendered = list()
		for(var/line in prep)
			rendered += span_smallnotice(" - [line]")
		. += "<details><summary>[span_smallnotice("Preparation")]</summary>[rendered.Join("<br>")]</details>"

/obj/item/alch/herb/examine(mob/user)
	. = ..()
	var/block = get_preparation_block()
	if(block)
		. += block

/obj/item/reagent_containers/powder/examine(mob/user)
	. = ..()
	var/block = get_preparation_block()
	if(block)
		. += block

/obj/item/reagent_containers/powder/flour/examine(mob/user)
	. = ..()
	if(water_added)
		. += span_smallnotice("Knead by hand into: dough.")
	else
		. += span_smallnotice("Add water on a table to work it into dough.")

#undef FOOD_INFO_COLOUR
