/* * * * * * * * * * * **
 *						*
 *		 NeuFood		*
 *		 (Meats)		*
 *						*
 * * * * * * * * * * * **/


/*-------------------\
| Raw meats and cuts |
\-------------------*/

// Template
/obj/item/reagent_containers/food/snacks/meat
	item_weight = 200 GRAMS
	eat_effect = /datum/status_effect/debuff/uncookedfood
	name = "bugged meat"
	icon_state = "bad_mapper"
	slice_batch = TRUE // so it takes more time, changed from FALSE
	filling_color = "#8f433a"
	bitesize = 3
	rotprocess = SHELFLIFE_SHORT
	chopping_sound = TRUE
	drop_sound = 'sound/foley/dropsound/gen_drop.ogg'
	become_rot_type = /obj/item/reagent_containers/food/snacks/rotten/meat
	nutrition = RAWMEAT_NUTRITION
	foodtype = RAW | MEAT
	faretype = FARE_IMPOVERISHED
	var/cannibalism = FALSE
	var/list/cannibalism_for = list()
	tastes = list("meat" = 1)
	gender = PLURAL
	slice_skill = /datum/attribute/skill/craft/cooking/preparation

/obj/item/reagent_containers/food/snacks/meat/on_consume(mob/living/eater)
	var/reset_eat_effect = FALSE
	if(cannibalism && iscarbon(eater))
		if(HAS_TRAIT(eater, TRAIT_ORGAN_EATER) && eat_effect != /datum/status_effect/debuff/rotfood)
			eat_effect = /datum/status_effect/buff/foodbuff
			reset_eat_effect = TRUE
		if(bitecount >= bitesize)
			record_featured_stat(FEATURED_STATS_CRIMINALS, eater)
			record_round_statistic(STATS_ORGANS_EATEN)
	..()
	if(reset_eat_effect)
		eat_effect = initial(eat_effect)

/*	.............   Raw meat   ................ */
/obj/item/reagent_containers/food/snacks/meat/steak
	item_weight = 400 GRAMS
	ingredient_size = 2
	name = "raw meat"
	icon_state = "meat"
	slices_num = 2
	slice_path = /obj/item/reagent_containers/food/snacks/meat/mince/beef
	slice_bclass = BCLASS_CHOP

/*	.............   Pigflesh, strange meat, birdmeat   ................ */
/obj/item/reagent_containers/food/snacks/meat/fatty
	item_weight = 150 GRAMS
	name = "raw pigflesh"
	icon_state = "pigflesh"
	slices_num = 2
	slice_path = /obj/item/reagent_containers/food/snacks/meat/mince/beef
	chopping_sound = TRUE
	tastes = list("meat" = 1, "fat" = 1)

/obj/item/reagent_containers/food/snacks/meat/strange // Low-nutrient, kind of gross. Survival food.
	item_weight = 150 GRAMS
	name = "strange meat"
	icon_state = "strange_meat"
	slice_path = null
	slices_num = 0

/obj/item/reagent_containers/food/snacks/meat/poultry
	item_weight = 800 GRAMS
	name = "plucked bird"
	icon_state = "poultry"
	slice_path = /obj/item/reagent_containers/food/snacks/meat/poultry/cutlet
	nutrition = RAWMEAT_NUTRITION * 2
	slices_num = 2
	slice_sound = TRUE
	ingredient_size = 4
	become_rot_type = /obj/item/reagent_containers/food/snacks/rotten/poultry

/obj/item/reagent_containers/food/snacks/meat/poultry/cutlet
	item_weight = 200 GRAMS
	name = "bird meat"
	icon_state = "chickencutlet"
	ingredient_size = 2
	slices_num = 2
	slice_bclass = BCLASS_CHOP
	nutrition = RAWMEAT_NUTRITION
	slice_path = /obj/item/reagent_containers/food/snacks/meat/mince/poultry
	become_rot_type = /obj/item/reagent_containers/food/snacks/rotten/chickenleg

/*	........   Fish sounds   ................ */
/obj/item/reagent_containers/food/snacks/fish
	item_weight = 300 GRAMS
	chopping_sound = TRUE
	slices_num = 2
	faretype = FARE_POOR
	var/rare = FALSE
	/// Number representing how rare the fish is, 0 is the lowest common fish
	var/rarity_rank = 0

/obj/item/reagent_containers/food/snacks/fish/dead
	abstract_type = /obj/item/reagent_containers/food/snacks/fish/dead
	status = FISH_DEAD
	fish_id = "dead"

/*	.............   Cannibalism  / Organs ................ */
/obj/item/reagent_containers/food/snacks/meat/steak/human
	item_weight = 250 GRAMS
	name = "raw manflesh"
	gender = PLURAL
	foodtype = RAW | MEAT | GROSS
	bitesize = 3
	list_reagents = list(/datum/reagent/organpoison/human = 1)
	grind_results = list(/datum/reagent/organpoison/human = 2)
	cannibalism = TRUE
	cannibalism_for = SPECIES_CANNIBAL_MEN

/obj/item/reagent_containers/food/snacks/meat/fatty/dwarf
	item_weight = 300 GRAMS
	name = "fatty manflesh" // porky
	list_reagents = list(/datum/reagent/organpoison/human = 1)
	grind_results = list(/datum/reagent/organpoison/human = 2)
	nutrition = RAWMEAT_NUTRITION
	foodtype = RAW | MEAT | GROSS
	cannibalism = TRUE
	cannibalism_for = SPECIES_CANNIBAL_MEN

/obj/item/reagent_containers/food/snacks/meat/fatty/kobold
	item_weight = 200 GRAMS
	name = "raw wyrmflesh"
	foodtype = RAW | MEAT | GROSS
	list_reagents = list(/datum/reagent/organpoison/kobold = 1)
	grind_results = list(/datum/reagent/organpoison/kobold = 2)
	cannibalism = TRUE
	cannibalism_for = SPECIES_CANNIBALISM_KOBOLD
	tastes = list("gamey meat" = 1, "crunchy bits" = 1, "ash" = 1)
	transfers_tastes = TRUE

/obj/item/reagent_containers/food/snacks/meat/poultry/cutlet/harpy
	item_weight = 200 GRAMS
	name = "harpy cutlet"
	list_reagents = list(/datum/reagent/organpoison/human = 1)
	grind_results = list(/datum/reagent/organpoison/human = 2)
	cannibalism = TRUE
	cannibalism_for = SPECIES_CANNIBAL_MEN

/obj/item/reagent_containers/food/snacks/meat/triton
	item_weight = 200 GRAMS
	name = "deepflesh"
	icon_state = "fishfillet"
	slice_path = /obj/item/reagent_containers/food/snacks/meat/mince/fish
	list_reagents = list(/datum/reagent/organpoison/human = 1)
	grind_results = list(/datum/reagent/organpoison/human = 2)
	slices_num = 2
	become_rot_type = null
	cannibalism = TRUE
	cannibalism_for = SPECIES_CANNIBAL_MEN

/obj/item/reagent_containers/food/snacks/meat/strange/inhumen
	item_weight = 150 GRAMS
	name = "foul manflesh"
	cannibalism = TRUE
	cannibalism_for = SPECIES_CANNIBAL_MEN
	list_reagents = list(/datum/reagent/organpoison/human = 1)
	grind_results = list(/datum/reagent/organpoison/human = 2)


/obj/item/reagent_containers/food/snacks/meat/organ
	item_weight = 150 GRAMS
	name = "organ"
	icon_state = "guts"
	icon = 'icons/obj/surgery.dmi'
	list_reagents = list(/datum/reagent/organpoison = 0.5)
	grind_results = list(/datum/reagent/organpoison = 1)
	gender = NEUTER
	nutrition = MINCE_NUTRITION
	foodtype = RAW | MEAT | GROSS
	rotprocess = SHELFLIFE_TINY
	cannibalism = TRUE
	cannibalism_for = ALL_RACES_LIST
	var/obj/item/organ/organ_inside

/obj/item/reagent_containers/food/snacks/meat/organ/on_consume(mob/living/eater)
	if(bitecount >= bitesize)
		SEND_SIGNAL(eater, COMSIG_ORGAN_CONSUMED, type, organ_inside)
	. = ..()

/obj/item/reagent_containers/food/snacks/meat/organ/Destroy()
	QDEL_NULL(organ_inside)
	return ..()

/obj/item/reagent_containers/food/snacks/meat/organ/heart
	item_weight = 250 GRAMS
	name = "heart"
	icon_state = "heart"
	list_reagents = list(/datum/reagent/organpoison = 1)
	grind_results = list(/datum/reagent/organpoison = 2)
	nutrition = RAWMEAT_NUTRITION

/obj/item/reagent_containers/food/snacks/meat/organ/lungs
	item_weight = 400 GRAMS
	name = "lungs"
	icon_state = "lungs"
	list_reagents = list(/datum/reagent/organpoison = 1)
	grind_results = list(/datum/reagent/organpoison = 2)
	nutrition = RAWMEAT_NUTRITION

/obj/item/reagent_containers/food/snacks/meat/organ/liver
	item_weight = 300 GRAMS
	name = "liver"
	icon_state = "liver"
	list_reagents = list(/datum/reagent/organpoison = 1)
	grind_results = list(/datum/reagent/organpoison = 2)
	nutrition = RAWMEAT_NUTRITION

/*	........   Cooked food template   ................ */ // No choppping double cooking etc prefixed
/obj/item/reagent_containers/food/snacks/cooked
	item_weight = 200 GRAMS
	name = "cooked meat"
	desc = ""
	icon_state = "frysteak"
	nutrition = COOKED_MEAT_NUTRITION
	rotprocess = SHELFLIFE_DECENT
	filling_color = "#8f433a"
	foodtype = MEAT
	become_rot_type = /obj/item/reagent_containers/food/snacks/rotten/meat

/*-----------------------\
| Mince & Sausage making |
\-----------------------*/

/*	.............   Minced meat & stuffing sausages   ................ */
/obj/item/reagent_containers/food/snacks/meat/mince
	item_weight = 100 GRAMS
	name = "mince template. BUGREPORT"
	icon_state = "meatmince"
	ingredient_size = 2
	bitesize = 1
	slice_path = null
	filling_color = "#8a0000"
	rotprocess = SHELFLIFE_TINY
	become_rot_type = /obj/item/reagent_containers/food/snacks/rotten/mince
	nutrition = MINCE_NUTRITION

/obj/item/reagent_containers/food/snacks/meat/mince/throw_impact(atom/hit_atom, datum/thrownthing/thrownthing)
	new /obj/effect/decal/cleanable/food/mess(get_turf(src))
	playsound(src, 'sound/foley/meatslap.ogg', 100, TRUE, -1)
	..()
	qdel(src)


/obj/item/reagent_containers/food/snacks/meat/mince/beef
	name = "minced meat"
	icon_state = "meatmince"

/obj/item/reagent_containers/food/snacks/meat/mince/beef/cooked
	name = "cooked minced meat"
	eat_effect = null
	foodtype = MEAT
	rotprocess = SHELFLIFE_DECENT
	nutrition = MINCE_NUTRITION * COOK_MOD
	color = "#a0655f"

/obj/item/reagent_containers/food/snacks/meat/mince/fish
	name = "minced fish"
	icon_state = "fishmince"

/obj/item/reagent_containers/food/snacks/meat/mince/fish/cooked
	name = "cooked minced fish"
	eat_effect = null
	foodtype = MEAT
	rotprocess = SHELFLIFE_DECENT
	nutrition = MINCE_NUTRITION * COOK_MOD
	color = "#a0655f"

/obj/item/reagent_containers/food/snacks/meat/mince/poultry
	name = "minced poultry"
	icon_state = "birdmince"

/obj/item/reagent_containers/food/snacks/meat/mince/poultry/cooked
	name = "cooked minced poultry"
	eat_effect = null
	foodtype = MEAT
	rotprocess = SHELFLIFE_DECENT
	nutrition = MINCE_NUTRITION * COOK_MOD
	color = "#a0655f"

/*	..................   METT   ................... */
/obj/item/reagent_containers/food/snacks/meat/mince/beef/mett
	item_weight = 150 GRAMS
	name = "darkhold mett"
	desc = "A popular topping for bread in the north, while simply bizarre to people from Rivermist Hollow."
	icon_state = "mett_minced"
	bitesize = 3
	slice_path = /obj/item/reagent_containers/food/snacks/meat/mince/beef/mett/slice
	nutrition = MINCE_NUTRITION + VEGGIE_NUTRITION
	slices_num = 3
	slice_batch = TRUE
	slice_sound = TRUE
	eat_effect = null
	rotprocess = SHELFLIFE_TINY
	faretype = FARE_POOR

/obj/item/reagent_containers/food/snacks/meat/mince/beef/mett/slice
	item_weight = 50 GRAMS
	name = "darkhold mett"
	icon_state = "mett_slice"
	bitesize = 1
	slices_num = FALSE
	slice_path = FALSE
	nutrition = (MINCE_NUTRITION + VEGGIE_NUTRITION) / 3

/*	..................   Sausage & Wiener   ................... */
/obj/item/reagent_containers/food/snacks/meat/sausage
	item_weight = 100 GRAMS
	name = "raw sausage"
	icon_state = "raw_wiener"
	ingredient_size = 1
	become_rot_type = /obj/item/reagent_containers/food/snacks/rotten/sausage
	nutrition = RAWMEAT_NUTRITION

/obj/item/reagent_containers/food/snacks/meat/sausage/wiener
	item_weight = 120 GRAMS
	name = "raw wiener"
	nutrition = FATTYMEAT_NUTRITION


