
/datum/container_craft/cooking/herbal_oil
	abstract_type = /datum/container_craft/cooking/herbal_oil
	category = "Aromatic Infusions"
	crafting_time = 25 SECONDS
	reagent_requirements = list(
		/datum/reagent/consumable/ethanol = 30
	)
	subtype_reagents_allowed = TRUE
	craft_verb = "infusing "
	required_chem_temp = T0C + 80
	pollute_amount = 100
	wording_choice = "petals and leaves of"
	complete_message = "The aromatic infusion is ready for the alembic."
	used_skill = /datum/attribute/skill/craft/alchemy
	quality_modifier = 1.0

// Rosa Oil (perfume/cosmetic)
/datum/container_craft/cooking/herbal_oil/rosa_oil
	name = "Crude Rosa Infusion"
	created_reagent = /datum/reagent/herbal_infusion/rosa
	water_conversion = 1
	requirements = list(
		/obj/item/alch/herb/rosa = 3
	)
	output_amount = 1
	finished_smell = /datum/pollutant/food/flower

// Mentha Cooling Oil (muscle relief)
/datum/container_craft/cooking/herbal_oil/mentha_oil
	name = "Crude Mentha Infusion"
	created_reagent = /datum/reagent/herbal_infusion/mentha
	water_conversion = 1
	requirements = list(
		/obj/item/alch/herb/mentha = 2,
		/obj/item/alch/herb/euphrasia = 1
	)
	output_amount = 1
	finished_smell = /datum/pollutant/food/mint

// Lavender Oil (herbal preparation enhancer)
/datum/container_craft/cooking/herbal_oil/lavender_oil
	name = "Crude Lavender Infusion"
	created_reagent = /datum/reagent/herbal_infusion/lavender
	water_conversion = 1
	requirements = list(
		/obj/item/alch/herb/lavender = 3
	)
	output_amount = 1
	finished_smell = /datum/pollutant/fragrance/lavender

// Salvia Oil (herbal preparation enhancer)
/datum/container_craft/cooking/herbal_oil/salvia_oil
	name = "Crude Salvia Infusion"
	created_reagent = /datum/reagent/herbal_infusion/salvia
	water_conversion = 1
	requirements = list(
		/obj/item/alch/herb/salvia = 3
	)
	output_amount = 1
	finished_smell = /datum/pollutant/food/herb
