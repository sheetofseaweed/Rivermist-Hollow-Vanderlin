// Anvil recipes for chastity devices; each device leaves the anvil with its own key.

/datum/anvil_recipe/chastity
	abstract_type = /datum/anvil_recipe/chastity
	i_type = "Utilities"
	category = "Lewd"
	req_bar = /obj/item/ingot/iron
	craftdiff = 1

/datum/anvil_recipe/chastity/belt
	name = "Chastity belt (iron)"
	recipe_name = "a locking belt that seals the groin"
	created_item = /obj/item/clothing/undies/chastity/belt

/datum/anvil_recipe/chastity/cage
	name = "Chastity cage (iron)"
	recipe_name = "a small locking cage for a cock"
	created_item = /obj/item/clothing/undies/chastity/cage

/datum/anvil_recipe/chastity/insertable
	name = "Insertable chastity belt (iron)"
	recipe_name = "a locking belt with an inward plug"
	created_item = /obj/item/clothing/undies/chastity/insertable

/datum/anvil_recipe/chastity/steel
	abstract_type = /datum/anvil_recipe/chastity/steel
	req_bar = /obj/item/ingot/steel
	craftdiff = 2

/datum/anvil_recipe/chastity/steel/cage_shield
	name = "Chastity cage with anal shield (steel)"
	recipe_name = "a locking cage with a rear plate"
	created_item = /obj/item/clothing/undies/chastity/cage/shield

/datum/anvil_recipe/chastity/steel/flat
	name = "Flat chastity cage (steel)"
	recipe_name = "a flat locking cage"
	created_item = /obj/item/clothing/undies/chastity/cage/flat

/datum/anvil_recipe/chastity/steel/flat_shield
	name = "Flat chastity cage with anal shield (steel)"
	recipe_name = "a flat locking cage with a rear plate"
	created_item = /obj/item/clothing/undies/chastity/cage/flat/shield
	craftdiff = 3

/datum/anvil_recipe/chastity/steel/insertable_shield
	name = "Insertable chastity belt with anal shield (steel)"
	recipe_name = "an insertable locking belt with a rear plate"
	created_item = /obj/item/clothing/undies/chastity/insertable/shield

/datum/anvil_recipe/chastity/steel/intersex
	name = "Intersex chastity device (steel)"
	recipe_name = "a broad locking frame for every opening"
	created_item = /obj/item/clothing/undies/chastity/intersex
	craftdiff = 3
