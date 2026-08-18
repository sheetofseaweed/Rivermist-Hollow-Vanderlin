/datum/container_craft/cooking/drugs
	abstract_type = /datum/container_craft/cooking/drugs
	category = "Boiling"

/datum/container_craft/cooking/arcyne
	abstract_type = /datum/container_craft/cooking/arcyne
	category = "Boiling"

/datum/container_craft/cooking/salt
	name = "Salt"
	category = "Boiling"
	output = /obj/item/reagent_containers/powder/salt
	reagent_requirements = list(
		/datum/reagent/water/salty = 25,
	)
	required_chem_temp = 300
	crafting_time = 30 SECONDS
	complete_message = "The last of the water boils away, leaving salt behind."

/datum/container_craft/cooking/salt/extra_html()
	return "1 pile of salt<br>"

/datum/container_craft/cooking/sugar
	name = "Sugar"
	category = "Boiling"
	created_reagent = /datum/reagent/consumable/sugar
	requirements = list(/obj/item/reagent_containers/food/snacks/sugar = 1)
	max_optionals = 0
	finished_smell = /datum/pollutant/food/sugar
	crafting_time = 10 SECONDS
	required_chem_temp = 300 // it's sugar water

/datum/container_craft/cooking/drugs/drukqs
	name = "Drukqs"
	created_reagent = /datum/reagent/druqks
	requirements = list(/obj/item/reagent_containers/powder/spice = 1)
	max_optionals = 0
	finished_smell = /datum/pollutant/food/druqks
	crafting_time = 50 SECONDS
	pollute_amount = 100
	water_conversion = 0.45

/datum/container_craft/cooking/drugs/drukqs/after_craft(atom/created_output, obj/item/crafter, mob/initiator, list/found_optional_requirements, list/found_optional_wildcards, list/found_optional_reagents, list/removing_items)
	. = ..()
	var/remaining_water = crafter.reagents.get_reagent_amount(/datum/reagent/water) - CEILING(crafter.reagents.get_reagent_amount(/datum/reagent/water) * water_conversion, 1)
	crafter.reagents.add_reagent(/datum/reagent/water/spicy, remaining_water)

/datum/container_craft/cooking/drugs/ozium
	name = "Ozium"
	created_reagent = /datum/reagent/ozium
	requirements = list(/obj/item/reagent_containers/powder/ozium = 1)
	max_optionals = 0
	finished_smell = /datum/pollutant/food/druqks
	crafting_time = 50 SECONDS
	pollute_amount = 100
	water_conversion = 0.45

/datum/container_craft/cooking/drugs/ozium/after_craft(atom/created_output, obj/item/crafter, mob/initiator, list/found_optional_requirements, list/found_optional_wildcards, list/found_optional_reagents, list/removing_items)
	. = ..()
	var/remaining_water = crafter.reagents.get_reagent_amount(/datum/reagent/water) - CEILING(crafter.reagents.get_reagent_amount(/datum/reagent/water) * water_conversion, 1)
	crafter.reagents.add_reagent(/datum/reagent/water/spicy, remaining_water)

/datum/container_craft/cooking/drugs/moondust
	name = "Moondust"
	created_reagent = /datum/reagent/moondust
	requirements = list(/obj/item/reagent_containers/powder/moondust = 1)
	max_optionals = 0
	finished_smell = /datum/pollutant/food/druqks
	crafting_time = 50 SECONDS
	pollute_amount = 100
	water_conversion = 0.45

/datum/container_craft/cooking/drugs/moondust/after_craft(atom/created_output, obj/item/crafter, mob/initiator, list/found_optional_requirements, list/found_optional_wildcards, list/found_optional_reagents, list/removing_items)
	. = ..()
	var/remaining_water = crafter.reagents.get_reagent_amount(/datum/reagent/water) - CEILING(crafter.reagents.get_reagent_amount(/datum/reagent/water) * water_conversion, 1)
	crafter.reagents.add_reagent(/datum/reagent/water/spicy, remaining_water)

/datum/container_craft/cooking/drugs/moondust_purest
	name = "Pure Moondust"
	created_reagent = /datum/reagent/moondust_purest
	requirements = list(/obj/item/reagent_containers/powder/moondust_purest = 1)
	max_optionals = 0
	finished_smell = /datum/pollutant/food/druqks
	crafting_time = 50 SECONDS
	pollute_amount = 100
	water_conversion = 0.45

/datum/container_craft/cooking/drugs/moondust_purest/after_craft(atom/created_output, obj/item/crafter, mob/initiator, list/found_optional_requirements, list/found_optional_wildcards, list/found_optional_reagents, list/removing_items)
	. = ..()
	var/remaining_water = crafter.reagents.get_reagent_amount(/datum/reagent/water) - CEILING(crafter.reagents.get_reagent_amount(/datum/reagent/water) * water_conversion, 1)
	crafter.reagents.add_reagent(/datum/reagent/water/spicy, remaining_water)

/datum/container_craft/cooking/alchemical_refinement/black_draught
	name = "Black Draught"
	created_reagent = /datum/reagent/medicine/charcoal
	minimum_skill = SKILL_RANK_APPRENTICE
	reagent_requirements = list(
		/datum/reagent/water = 25,
	)
	requirements = list(
		/obj/item/ore/coal/charcoal = 1,
		/obj/item/reagent_containers/powder/salt = 1,
	)
	finished_smell = /datum/pollutant/food/bitter
	complete_message = "The water darkens into a fine black suspension."

/datum/container_craft/cooking/alchemical_refinement/fools_blush
	name = "Blush"
	created_reagent = /datum/reagent/drug/bimb
	minimum_skill = SKILL_RANK_JOURNEYMAN
	reagent_requirements = list(
		/datum/reagent/poison/herbal/weak_atropa = 10,
		/datum/reagent/poison/herbal/matricaria_irritant = 10,
		/datum/reagent/medicine/herbal/simple_rosa = 5,
	)
	required_chem_temp = 320
	finished_smell = /datum/pollutant/food/flower
	complete_message = "The mixture settles into an innocent pink blush."

/datum/container_craft/cooking/alchemical_refinement/grave_dream
	name = "Grave Dream"
	created_reagent = /datum/reagent/drug/madness
	minimum_skill = SKILL_RANK_EXPERT
	subtype_reagents_allowed = TRUE
	reagent_requirements = list(
		/datum/reagent/buff/herbal/salvia_wisdom = 10,
		/datum/reagent/poison/herbal/weak_atropa = 5,
		/datum/reagent/consumable/ethanol = 10,
	)
	requirements = list(
		/obj/item/reagent_containers/food/snacks/produce/mushroom/capillus = 2,
	)
	required_chem_temp = 320
	finished_smell = /datum/pollutant/food/bitter
	complete_message = "The corpse caps dissolve into a wine-dark, unsettling draught."

/datum/container_craft/cooking/alchemical_refinement/moonlily
	name = "Moonlily"
	created_reagent = /datum/reagent/drug/skum
	minimum_skill = SKILL_RANK_EXPERT
	subtype_reagents_allowed = TRUE
	reagent_requirements = list(
		/datum/reagent/ozium = 5,
		/datum/reagent/moondust_purest = 5,
		/datum/reagent/consumable/ethanol = 5,
	)
	required_chem_temp = 330
	finished_smell = /datum/pollutant/food/druqks
	complete_message = "The pale mixture takes on a moonlit sheen."

/datum/container_craft/cooking/alchemical_refinement/nightshade_mercy
	name = "Nightshade Mercy"
	created_reagent = /datum/reagent/medicine/atropine
	minimum_skill = SKILL_RANK_EXPERT
	subtype_reagents_allowed = TRUE
	reagent_requirements = list(
		/datum/reagent/poison/herbal/weak_atropa = 20,
		/datum/reagent/consumable/ethanol = 10,
	)
	requirements = list(
		/obj/item/reagent_containers/powder/salt = 1,
	)
	required_chem_temp = 310
	finished_smell = /datum/pollutant/food/bitter
	complete_message = "The nightshade's poison separates into a measured medicinal tincture."

/datum/container_craft/cooking/arcyne/weak_manapot
	name = "Weak Liquid Mana"
	created_reagent = /datum/reagent/medicine/manapot/weak
	requirements = list(
		/obj/item/reagent_containers/powder/manabloom = 2,
		/obj/item/mana_battery/mana_crystal/small = 1
	)
	max_optionals = 0
	finished_smell = /datum/pollutant/food/druqks
	crafting_time = 50 SECONDS
	pollute_amount = 100
	water_conversion = 0.6
