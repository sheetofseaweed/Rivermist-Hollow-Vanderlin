// Hedge-witch brews: herbal pot recipes for the fluid draughts and contraceptives, a smaller yield than the cauldron.

/// Twenty measures of water give ten of draught; the cauldron gives twenty-five.
#define FLUID_HERBAL_BREW_CONVERSION 0.5

/datum/container_craft/cooking/herbal_tea/fluid_brew
	abstract_type = /datum/container_craft/cooking/herbal_tea/fluid_brew
	water_conversion = FLUID_HERBAL_BREW_CONVERSION
	crafting_time = 12 SECONDS
	finished_smell = /datum/pollutant/food/herb

/// Blessed thistle and nettle, old milk-bringers, with chamomile.
/datum/container_craft/cooking/herbal_tea/fluid_brew/surge
	name = "Brimming Draught (herbal)"
	created_reagent = /datum/reagent/fluid_potion/surge
	requirements = list(
		/obj/item/alch/herb/benedictus = 1,
		/obj/item/alch/herb/urtica = 1,
		/obj/item/alch/herb/matricaria = 1,
	)
	complete_message = "The brew thickens and smells of warm milk."

/// Sage is the classic herb for drying up milk; lavender cools it.
/datum/container_craft/cooking/herbal_tea/fluid_brew/ebb
	name = "Ebbing Draught (herbal)"
	created_reagent = /datum/reagent/fluid_potion/ebb
	requirements = list(
		/obj/item/alch/herb/salvia = 1,
		/obj/item/alch/herb/lavender = 1,
	)
	complete_message = "The brew clears and smells of wet stone."

/// Sage, a drying spurge and dandelion.
/datum/container_craft/cooking/herbal_tea/fluid_brew/drought
	name = "Drying Draught (herbal)"
	created_reagent = /datum/reagent/fluid_potion/drought
	requirements = list(
		/obj/item/alch/herb/salvia = 1,
		/obj/item/alch/herb/euphorbia = 1,
		/obj/item/alch/herb/taraxacum = 1,
	)
	finished_smell = /datum/pollutant/food/bitter
	complete_message = "The brew turns dusty and bitter."

/// Blessed thistle with marigold and rose.
/datum/container_craft/cooking/herbal_tea/fluid_brew/lactation_inducer
	name = "Lactation Inducer (herbal)"
	created_reagent = /datum/reagent/consumable/lactation_inducer
	requirements = list(
		/obj/item/alch/herb/benedictus = 1,
		/obj/item/alch/herb/calendula = 1,
		/obj/item/alch/herb/rosa = 1,
	)
	finished_smell = /datum/pollutant/food/flower
	complete_message = "The brew turns creamy and smells of flowers."

/// Mugwort and pennyroyal, both old contraceptive herbs.
/datum/container_craft/cooking/herbal_tea/fluid_brew/moon_tea
	name = "Moon Tea (herbal)"
	created_reagent = /datum/reagent/fluid_potion/contraceptive/moon_tea
	requirements = list(
		/obj/item/alch/herb/artemisia = 1,
		/obj/item/alch/herb/mentha = 1,
	)
	finished_smell = /datum/pollutant/food/mint
	complete_message = "The tea turns cloudy and green."

/// Calming herbs that cool desire.
/datum/container_craft/cooking/herbal_tea/fluid_brew/cold_seed
	name = "Cold Seed Draught (herbal)"
	created_reagent = /datum/reagent/fluid_potion/contraceptive/cold_seed
	requirements = list(
		/obj/item/alch/herb/lavender = 1,
		/obj/item/alch/herb/valeriana = 1,
	)
	complete_message = "The brew goes pale and chilly."

#undef FLUID_HERBAL_BREW_CONVERSION
