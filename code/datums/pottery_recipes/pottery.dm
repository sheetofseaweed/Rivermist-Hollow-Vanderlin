/datum/pottery_recipe/bowl
	name = "Clay Bowl"
	created_item = /obj/item/reagent_containers/glass/bowl/clay

/datum/pottery_recipe/platter
	name = "Clay Platter"
	created_item = /obj/item/plate/clay

/datum/pottery_recipe/cup
	name = "Clay Cup"
	created_item = /obj/item/reagent_containers/glass/cup/clay

/datum/pottery_recipe/fancy_cup
	name = "Fancy Clay Cup"
	created_item = /obj/item/reagent_containers/glass/cup/fancy_clay

/datum/pottery_recipe/mug
	name = "Clay Mug"
	created_item = /obj/item/reagent_containers/glass/cup/clay_mug

/datum/pottery_recipe/teapot
	name = "Clay Teapot"
	created_item = /obj/item/reagent_containers/glass/bottle/teapot

/datum/pottery_recipe/decanter
	name = "Clay Decanter"
	created_item = /obj/item/reagent_containers/glass/bottle/decanter

/datum/pottery_recipe/claybrick
	name = "clay brick"
	created_item = /obj/item/natural/clay/claybrick
	recipe_steps = list(/obj/item/natural/clay)
	difficulty = 0

/* 1 diff */
/datum/pottery_recipe/claybottle
	name = "clay bottle"
	created_item = /obj/item/reagent_containers/glass/bottle/claybottle
	recipe_steps = list(/obj/item/natural/clay)
	difficulty = 0

/* 2 diff */
/datum/pottery_recipe/clayvase
	name = "clay vase"
	created_item = /obj/item/reagent_containers/glass/bottle/clayvase
	recipe_steps = list(/obj/item/natural/clay, /obj/item/natural/clay)
	difficulty = 2

/* 3 diff */
/datum/pottery_recipe/clayfancyvase
	name = "fancy clay vase"
	created_item = /obj/item/reagent_containers/glass/bottle/clayfancyvase
	recipe_steps = list(/obj/item/natural/clay, /obj/item/natural/clay)
	difficulty = 3

/datum/pottery_recipe/teacup
	name = "teacup"
	created_item = /obj/item/reagent_containers/glass/bottle/glazed_teacup
	recipe_steps = list(/obj/item/natural/clay)
	difficulty = 3
