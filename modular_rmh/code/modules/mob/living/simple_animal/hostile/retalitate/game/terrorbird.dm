/mob/living/simple_animal/hostile/retaliate/saiga/terrorbird
	icon = 'modular_rmh/icons/mob/monster/terrorbird.dmi'
	name = "terrorbird"
	desc = "A flightless giant bred in the southern reaches for the saddle. Faster than any horse over open ground, and it eats what the horse would flee from."
	icon_state = "terrorbird_yellow"
	icon_living = "terrorbird_yellow"
	icon_dead = "terrorbird_yellow_dead"
	icon_gib = "terrorbird_yellow_dead"
	SET_BASE_PIXEL(-8, 0)

	animal_species = null
	faction = list("terrorbird")
	footstep_type = FOOTSTEP_MOB_CLAW
	emote_see = list("ruffles its plumes.", "scratches at the dirt.", "cranes its neck.")
	move_to_delay = 6.5

	botched_butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/poultry = 1,
						/obj/item/alch/bone = 1)
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/poultry = 3,
						/obj/item/reagent_containers/food/snacks/fat = 1,
						/obj/item/natural/hide = 1,
						/obj/item/alch/sinew = 2,
						/obj/item/alch/bone = 1)
	perfect_butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/poultry = 4,
						/obj/item/reagent_containers/food/snacks/fat = 1,
						/obj/item/natural/hide = 2,
						/obj/item/alch/sinew = 3,
						/obj/item/alch/bone = 2)
	head_butcher = null

	health = TERRORBIRD_HEALTH
	maxHealth = TERRORBIRD_HEALTH
	food_type = list(/obj/item/reagent_containers/food/snacks/meat)
	tame_chance = 20
	bonus_tame_chance = 15

	base_intents = list(/datum/intent/simple/claw, /datum/intent/simple/peck)
	attack_sound = list('sound/vo/mobs/bird/CROW_01.ogg', 'sound/vo/mobs/bird/CROW_02.ogg', 'sound/vo/mobs/bird/CROW_03.ogg')
	attack_verb_continuous = "claws"
	attack_verb_simple = "claw"
	melee_damage_lower = 18
	melee_damage_upper = 26
	retreat_distance = 10
	minimum_distance = 10
	base_speed = 20
	base_constitution = 9
	base_strength = 12
	can_buckle = TRUE
	buckle_lying = FALSE
	can_saddle = TRUE
	// terrorbird.dmi carries saiga's unisex saddle rather than the split male/female pair.
	saddle_overlay_state = "saddle"
	riding_component_type = /datum/component/riding/terrorbird
	aggressive = TRUE
	remains_type = /obj/effect/decal/remains/terrorbird

	ai_controller = /datum/ai_controller/saiga/terrorbird

	// The saiga coat genes paint themselves onto _reg1/_reg2 region states this sheet has no equivalent for.
	// Plumage colour does that job instead.
	genetics = null
	generate_genetics = FALSE

	// Saiga's tamed() would hand us saiga calves, so we opt out of its breeding and register our own below.
	can_breed = FALSE

	/// Plumage colour. Rolled on spawn unless a subtype or a mapper pins it.
	var/bird_color
	/// Icon state prefix, so chicks reuse the colouring code with their own sprites.
	var/plumage_prefix = "terrorbird"
	/// Whether plumage shifts combat stats. Off for chicks, whose numbers are too small to shift.
	var/plumage_stats = TRUE
	/// Whether taming this bird makes it breedable. Chicks have to grow up first.
	var/breeds_when_tamed = TRUE

/mob/living/simple_animal/hostile/retaliate/saiga/terrorbird/Initialize()
	if(!bird_color)
		bird_color = pick(TERRORBIRD_COLORS)
	gender = pick(MALE, FEMALE)
	apply_plumage()
	return ..()

/// Points the icon states at the current plumage and applies its stat spread.
/mob/living/simple_animal/hostile/retaliate/saiga/terrorbird/proc/apply_plumage()
	icon_state = "[plumage_prefix]_[bird_color]"
	icon_living = icon_state
	icon_dead = "[icon_state]_dead"
	icon_gib = icon_dead

	if(!plumage_stats)
		return

	switch(bird_color)
		if("black")
			maxHealth += 25
			base_speed -= 1
		if("red")
			melee_damage_lower += 4
			melee_damage_upper += 4
			maxHealth -= 15
		if("white")
			tame_chance += 20
			melee_damage_lower -= 2
			melee_damage_upper -= 2
	health = maxHealth

/mob/living/simple_animal/hostile/retaliate/saiga/terrorbird/tamed(mob/user)
	. = ..()
	deaggroprob = 30
	retreat_distance = 0
	minimum_distance = 0
	if(breeds_when_tamed)
		AddComponent(\
			/datum/component/breed,\
			list(/mob/living/simple_animal/hostile/retaliate/saiga/terrorbird),\
			3 MINUTES,\
			list(/mob/living/simple_animal/hostile/retaliate/saiga/terrorbird/chick = 100),\
			CALLBACK(src, PROC_REF(after_birth)),\
		)

/mob/living/simple_animal/hostile/retaliate/saiga/terrorbird/after_birth(mob/living/simple_animal/baby, mob/living/partner)
	. = ..()
	var/mob/living/simple_animal/hostile/retaliate/saiga/terrorbird/hatchling = baby
	if(!istype(hatchling))
		return
	var/mob/living/simple_animal/hostile/retaliate/saiga/terrorbird/sire = partner
	hatchling.bird_color = (istype(sire) && prob(50)) ? sire.bird_color : bird_color
	hatchling.apply_plumage()
	hatchling.update_appearance()

/mob/living/simple_animal/hostile/retaliate/saiga/terrorbird/get_sound(input)
	switch(input)
		if("aggro")
			return pick('sound/vo/mobs/bird/CROW_01.ogg', 'sound/vo/mobs/bird/CROW_02.ogg', 'sound/vo/mobs/bird/CROW_03.ogg')
		if("pain")
			return pick('sound/vo/mobs/chikn/pain (1).ogg', 'sound/vo/mobs/chikn/pain (2).ogg', 'sound/vo/mobs/chikn/pain (3).ogg')
		if("death")
			return 'sound/vo/mobs/chikn/death.ogg'
		if("idle")
			return pick('sound/vo/mobs/chikn/idle (1).ogg', 'sound/vo/mobs/chikn/idle (2).ogg', 'sound/vo/mobs/chikn/idle (3).ogg', 'sound/vo/mobs/chikn/idle (4).ogg', 'sound/vo/mobs/chikn/idle (5).ogg', 'sound/vo/mobs/chikn/idle (6).ogg')

/mob/living/simple_animal/hostile/retaliate/saiga/terrorbird/simple_limb_hit(zone)
	switch(zone)
		if(BODY_ZONE_PRECISE_NOSE, BODY_ZONE_PRECISE_MOUTH)
			return "beak"
		if(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
			return "wing"
	return ..()

/obj/effect/decal/remains/terrorbird
	name = "remains"
	gender = PLURAL
	icon = 'modular_rmh/icons/mob/monster/terrorbird.dmi'
	icon_state = "skele"

/mob/living/simple_animal/hostile/retaliate/saiga/terrorbird/chick
	name = "terrorchick"
	desc = "A knee-high ball of down on stilts. It has already worked out that fingers are meat."
	icon_state = "chick_yellow"
	icon_living = "chick_yellow"
	icon_dead = "chick_yellow_dead"
	icon_gib = "chick_yellow_dead"
	SET_BASE_PIXEL(-8, 0)

	emote_see = list("peeps.", "nips at nothing.")
	pass_flags = PASSMOB
	mob_size = MOB_SIZE_SMALL

	botched_butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/poultry/cutlet = 1)
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/poultry = 1)
	perfect_butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/poultry = 1,
								/obj/item/natural/hide = 1)

	health = TERRORBIRD_CHICK_HEALTH
	maxHealth = TERRORBIRD_CHICK_HEALTH

	melee_damage_lower = 2
	melee_damage_upper = 7
	base_constitution = 5
	base_strength = 5
	base_speed = 12
	defprob = 50

	can_buckle = FALSE
	can_saddle = FALSE
	tame = TRUE
	adult_growth = /mob/living/simple_animal/hostile/retaliate/saiga/terrorbird

	ai_controller = /datum/ai_controller/saiga_kid/terrorbird

	plumage_prefix = "chick"
	plumage_stats = FALSE
	breeds_when_tamed = FALSE

//COLORS
/mob/living/simple_animal/hostile/retaliate/saiga/terrorbird/yellow
	bird_color = "yellow"

/mob/living/simple_animal/hostile/retaliate/saiga/terrorbird/white
	bird_color = "white"

/mob/living/simple_animal/hostile/retaliate/saiga/terrorbird/black
	bird_color = "black"

/mob/living/simple_animal/hostile/retaliate/saiga/terrorbird/red
	bird_color = "red"

//TAMED
/mob/living/simple_animal/hostile/retaliate/saiga/terrorbird/tame
	tame = TRUE

/mob/living/simple_animal/hostile/retaliate/saiga/terrorbird/tame/saddled/Initialize()
	. = ..()
	var/obj/item/natural/saddle/S = new(src)
	ssaddle = S
	update_appearance(UPDATE_OVERLAYS)
