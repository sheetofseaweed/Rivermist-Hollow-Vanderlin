// try_repeatable_craft() matches only these two atoms; a recipe missing either is dead in game.
/datum/unit_test/repeatable_recipes_have_start_items/Run()
	var/list/broken = list()
	for(var/datum/repeatable_crafting_recipe/recipe_type as anything in subtypesof(/datum/repeatable_crafting_recipe))
		if(IS_ABSTRACT(recipe_type))
			continue
		if(!initial(recipe_type.starting_atom) || !initial(recipe_type.attacked_atom))
			broken += recipe_type
	if(length(broken))
		TEST_FAIL("These repeatable recipes lack a starting_atom or attacked_atom and can never start: [broken.Join(", ")]")

/datum/unit_test/lewd_recipes_can_start/Run()
	var/mob/living/carbon/human/crafter = allocate(/mob/living/carbon/human)
	// Recipe = list(held item, clicked item, other ingredients...).
	var/list/cases = list(
		/datum/repeatable_crafting_recipe/leather/bdsm_gear/black_muzzle = list(/obj/item/needle, /obj/item/natural/hide/cured, /obj/item/natural/fibers),
		/datum/repeatable_crafting_recipe/leather/bdsm_gear/brown_muzzle = list(/obj/item/needle, /obj/item/natural/hide/cured, /obj/item/natural/fibers),
		/datum/repeatable_crafting_recipe/leather/bdsm_gear/black_ballgag = list(/obj/item/needle, /obj/item/natural/hide/cured, /obj/item/natural/cloth, /obj/item/natural/fibers),
		/datum/repeatable_crafting_recipe/leather/bdsm_gear/brown_ballgag = list(/obj/item/needle, /obj/item/natural/hide/cured, /obj/item/natural/cloth, /obj/item/natural/fibers),
		/datum/repeatable_crafting_recipe/leather/bdsm_gear/black_ringgag = list(/obj/item/needle, /obj/item/natural/hide/cured, /obj/item/ingot/iron),
		/datum/repeatable_crafting_recipe/leather/bdsm_gear/brown_ringgag = list(/obj/item/needle, /obj/item/natural/hide/cured, /obj/item/ingot/iron),
		/datum/repeatable_crafting_recipe/leather/bdsm_gear/black_harnessgag = list(/obj/item/needle, /obj/item/natural/hide/cured, /obj/item/natural/hide/cured, /obj/item/natural/fibers),
		/datum/repeatable_crafting_recipe/leather/bdsm_gear/brown_harnessgag = list(/obj/item/needle, /obj/item/natural/hide/cured, /obj/item/natural/hide/cured, /obj/item/natural/fibers),
		/datum/repeatable_crafting_recipe/leather/bdsm_gear/black_collar = list(/obj/item/needle, /obj/item/natural/hide/cured, /obj/item/natural/hide/cured, /obj/item/ingot/iron),
		/datum/repeatable_crafting_recipe/leather/bdsm_gear/brown_collar = list(/obj/item/needle, /obj/item/natural/hide/cured, /obj/item/natural/hide/cured, /obj/item/ingot/iron),
		/datum/repeatable_crafting_recipe/leather/bdsm_gear/black_chain_leash = list(/obj/item/needle, /obj/item/natural/hide/cured, /obj/item/rope/chain),
		/datum/repeatable_crafting_recipe/leather/bdsm_gear/brown_chain_leash = list(/obj/item/needle, /obj/item/natural/hide/cured, /obj/item/rope/chain),
		/datum/repeatable_crafting_recipe/leather/bdsm_gear/black_shackles = list(/obj/item/needle, /obj/item/natural/hide/cured, /obj/item/natural/hide/cured, /obj/item/ingot/iron),
		/datum/repeatable_crafting_recipe/leather/bdsm_gear/brown_shackles = list(/obj/item/needle, /obj/item/natural/hide/cured, /obj/item/natural/hide/cured, /obj/item/ingot/iron),
		/datum/repeatable_crafting_recipe/leather/bdsm_gear/leatherhalfsuit = list(/obj/item/needle, /obj/item/natural/hide/cured, /obj/item/natural/hide/cured, /obj/item/natural/hide/cured, /obj/item/natural/fibers, /obj/item/natural/fibers),
		/datum/repeatable_crafting_recipe/leather/bdsm_gear/leatherstockings = list(/obj/item/needle, /obj/item/natural/hide/cured, /obj/item/natural/hide/cured, /obj/item/natural/fibers, /obj/item/natural/fibers),
		/datum/repeatable_crafting_recipe/leather/bdsm_gear/leathergloves = list(/obj/item/needle, /obj/item/natural/hide/cured, /obj/item/natural/fibers),
		/datum/repeatable_crafting_recipe/sewing/bdsm_nundorei = list(/obj/item/needle, /obj/item/natural/cloth, /obj/item/natural/cloth, /obj/item/natural/cloth, /obj/item/natural/hide/cured),
		/datum/repeatable_crafting_recipe/crafting/wood_dildo = list(/obj/item/weapon/knife/hunting, /obj/item/grown/log/tree/small),
		/datum/repeatable_crafting_recipe/crafting/wood_plug = list(/obj/item/weapon/knife/hunting, /obj/item/grown/log/tree/small),
		/datum/repeatable_crafting_recipe/crafting/stone_plug = list(/obj/item/weapon/knife/hunting, /obj/item/natural/stone),
		/datum/repeatable_crafting_recipe/crafting/fluid_pump/breast_pump = list(/obj/item/ingot/bronze, /obj/item/reagent_containers/glass/bottle, /obj/item/natural/hide/cured),
		/datum/repeatable_crafting_recipe/crafting/fluid_pump/cock_milker = list(/obj/item/ingot/bronze, /obj/item/reagent_containers/glass/bottle, /obj/item/natural/hide/cured),
		/datum/repeatable_crafting_recipe/crafting/fluid_pump/nectar_pump = list(/obj/item/ingot/bronze, /obj/item/reagent_containers/glass/bottle, /obj/item/natural/hide/cured),
		/datum/repeatable_crafting_recipe/crafting/seed_sachet = list(/obj/item/neuFarm/seed/wheat, /obj/item/natural/cloth, /obj/item/neuFarm/seed/oat),
		/datum/repeatable_crafting_recipe/survival/ration_wrapper = list(/obj/item/reagent_containers/food/snacks/tallow, /obj/item/paper, /obj/item/natural/fibers),
	)
	for(var/recipe_type in cases)
		var/list/items = list()
		for(var/item_type in cases[recipe_type])
			items += allocate(item_type)
		var/obj/item/held = items[1]
		var/obj/item/clicked = items[2]
		crafter.put_in_active_hand(held)
		var/found = FALSE
		for(var/datum/repeatable_crafting_recipe/recipe as anything in crafter.try_repeatable_craft(clicked, held))
			if(recipe.type == recipe_type)
				found = TRUE
		TEST_ASSERT(found, "[recipe_type] should start from [held] used on [clicked].")
		for(var/obj/item/item as anything in items)
			qdel(item)

/datum/unit_test/skirt_conversions_use_matching_trousers/Run()
	var/mob/living/carbon/human/crafter = allocate(/mob/living/carbon/human)
	var/obj/item/weapon/knife/hunting/knife = allocate(/obj/item/weapon/knife/hunting)
	crafter.put_in_active_hand(knife)
	// Clicked item = the only conversion a knife on it may offer; null means none.
	var/list/cases = list(
		/obj/item/clothing/pants/trou/leather = /datum/repeatable_crafting_recipe/conversion/leatherskirtconv,
		/obj/item/clothing/pants/trou/leather/advanced = /datum/repeatable_crafting_recipe/conversion/leatherskirtconvtwo,
		/obj/item/clothing/pants/trou/leather/masterwork = /datum/repeatable_crafting_recipe/conversion/leatherskirtconvthree,
		/obj/item/clothing/pants/trou/leather/skirt = null,
		/obj/item/clothing/pants/trou/leather/masterwork/skirt = null,
	)
	for(var/clicked_type in cases)
		var/obj/item/clicked = allocate(clicked_type)
		var/list/offered = list()
		for(var/datum/repeatable_crafting_recipe/conversion/recipe in crafter.try_repeatable_craft(clicked, knife))
			offered += recipe.type
		var/expected = cases[clicked_type]
		TEST_ASSERT_EQUAL(length(offered), expected ? 1 : 0, "A knife on [clicked] offered: [offered.Join(", ")].")
		if(expected)
			TEST_ASSERT_EQUAL(offered[1], expected, "A knife on [clicked] offered the wrong conversion.")
		qdel(clicked)
