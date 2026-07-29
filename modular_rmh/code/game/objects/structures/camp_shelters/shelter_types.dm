/obj/item/camp_shelter/tent
	name = "tent kit"
	desc = "A rolled canvas tent, its poles lashed alongside. Pitch it on clear ground."
	deployed_type = /obj/structure/camp_shelter/tent
	deploy_time = 5 SECONDS
	item_weight = 8 KILOGRAMS

/obj/structure/camp_shelter/tent
	name = "tent"
	desc = "A canvas ridge tent. The inside is a good deal larger than the outside."
	icon_state = "tent_basic"
	sprite_prefix = "tent"
	folded_type = /obj/item/camp_shelter/tent
	pocket_template_type = /datum/map_template/pocket/camp_tent
	fold_time = 4 SECONDS
	max_integrity = 200

/obj/item/camp_shelter/yurt
	name = "yurt kit"
	desc = "A folded lattice frame wrapped in heavy felt. Heavier than it looks."
	deployed_type = /obj/structure/camp_shelter/yurt
	deploy_time = 8 SECONDS
	item_weight = 14 KILOGRAMS

/obj/structure/camp_shelter/yurt
	name = "yurt"
	desc = "A round felt yurt on a lattice frame. Warm, and impossibly roomy within."
	icon_state = "yurt_basic"
	sprite_prefix = "yurt"
	folded_type = /obj/item/camp_shelter/yurt
	pocket_template_type = /datum/map_template/pocket/camp_yurt
	fold_time = 6 SECONDS
	max_integrity = 300

/obj/item/camp_shelter/pavilion
	name = "pavilion kit"
	desc = "A bundled pavilion, pennants and all. A lordly thing to haul about."
	deployed_type = /obj/structure/camp_shelter/pavilion
	deploy_time = 12 SECONDS
	has_flag_layers = TRUE
	item_weight = 20 KILOGRAMS

/obj/structure/camp_shelter/pavilion
	name = "pavilion"
	desc = "A tall pavilion crowned with pennants. Fit for a commander's camp."
	icon_state = "pavilion_basic"
	sprite_prefix = "pavilion"
	folded_type = /obj/item/camp_shelter/pavilion
	pocket_template_type = /datum/map_template/pocket/camp_pavilion
	fold_time = 8 SECONDS
	has_flag_layers = TRUE
	max_integrity = 350

/obj/structure/camp_shelter/yurt/setDir(newdir)
	return ..(SOUTH)

/obj/structure/camp_shelter/pavilion/setDir(newdir)
	return ..(SOUTH)

///Crafting

/datum/blueprint_recipe/structure/camp_shelter
	abstract_type = /datum/blueprint_recipe/structure/camp_shelter
	category = "Structures"
	construct_tool = /obj/item/weapon/knife
	verbage = "assemble"
	verbage_tp = "assembles"
	requires_learning = FALSE
	craftdiff = 3

/datum/blueprint_recipe/structure/camp_shelter/tent
	name = "Tent Kit"
	desc = "A rolled canvas tent with its poles."
	result_type = /obj/item/camp_shelter/tent
	required_materials = list(
		/obj/item/natural/cloth = 6,
		/obj/item/natural/fibers = 2,
		/obj/item/grown/log/tree/stick = 2,
	)
	build_time = 8 SECONDS

/datum/blueprint_recipe/structure/camp_shelter/yurt
	name = "Yurt Kit"
	desc = "A felt yurt on a folding lattice frame."
	result_type = /obj/item/camp_shelter/yurt
	required_materials = list(
		/obj/item/natural/cloth = 10,
		/obj/item/natural/fibers = 4,
		/obj/item/grown/log/tree/stick = 4,
		/obj/item/grown/log/tree = 1,
	)
	build_time = 12 SECONDS
	craftdiff = 4

/datum/blueprint_recipe/structure/camp_shelter/pavilion
	name = "Pavilion Kit"
	desc = "A tall pavilion with pennants, fit for a commander's camp."
	result_type = /obj/item/camp_shelter/pavilion
	required_materials = list(
		/obj/item/natural/cloth = 14,
		/obj/item/natural/fibers = 6,
		/obj/item/grown/log/tree/stick = 6,
		/obj/item/grown/log/tree = 2,
	)
	build_time = 16 SECONDS
	craftdiff = 5

///Merchant stock

/datum/supply_pack/tools/camp_tent
	name = "Tent Kit"
	cost = 40
	contains = /obj/item/camp_shelter/tent

/datum/supply_pack/tools/camp_yurt
	name = "Yurt Kit"
	cost = 80
	contains = /obj/item/camp_shelter/yurt

/datum/supply_pack/tools/camp_pavilion
	name = "Pavilion Kit"
	cost = 180
	contains = /obj/item/camp_shelter/pavilion
