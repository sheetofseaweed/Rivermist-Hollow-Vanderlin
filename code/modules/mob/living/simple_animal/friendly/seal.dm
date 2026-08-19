/mob/living/simple_animal/pet/seal
	name = "seal"
	desc = "A sleek lake seal with big, curious eyes and broad flippers made for deep water."
	icon = 'icons/roguetown/mob/monster/seal.dmi'
	icon_state = "seathing"
	icon_living = "seathing"
	icon_dead = "seathing_sad"
	speak = list("Arf!", "Ork!", "Awr!", "Ough!", "Oughhhh!")
	speak_emote = list("barks", "chuffs")
	emote_hear = list("barks softly.", "chuffs.")
	emote_see = list("claps its flippers.", "rolls onto its side.", "galumphs around.")
	speak_chance = 1
	health = 50
	maxHealth = 50
	see_in_dark = 4
	pass_flags = PASSMOB
	food_type = list(/obj/item/reagent_containers/food/snacks/fish)
	tame_chance = 25
	bonus_tame_chance = 10
	base_strength = 3
	base_endurance = 5
	base_speed = 3
	base_constitution = 5
	gold_core_spawnable = FRIENDLY_SPAWN
	ai_controller = /datum/ai_controller/seal

/mob/living/simple_animal/pet/seal/Initialize()
	. = ..()
	ADD_TRAIT(src, TRAIT_WATER_BREATHING, INNATE_TRAIT)
	ADD_TRAIT(src, TRAIT_GOOD_SWIM, INNATE_TRAIT)
