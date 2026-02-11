/datum/job/town_performer
	title = "Town Performer"
	tutorial = "You earn your keep through performance — song, humor, wit, or spectacle. \
	In Rivermist Hollow, entertainers are welcomed in the tavern, festivals, and the town hall alike. \
	Your talent brings joy, distraction, and sometimes insight, \
	and the town knows your face even if it forgets your name."
	department_flag = TOWN
	faction = FACTION_TOWN
	total_positions = 5
	spawn_positions = 5
	job_flags = (JOB_ANNOUNCE_ARRIVAL | JOB_SHOW_IN_CREDITS | JOB_EQUIP_RANK | JOB_NEW_PLAYER_JOINABLE)
	display_order = JDO_FARMER

	allowed_ages = list(AGE_ADULT, AGE_MIDDLEAGED, AGE_OLD, AGE_IMMORTAL)
	allowed_races = ALL_RACES_LIST

	selection_color = JCOLOR_TOWN
	advclass_cat_rolls = list(CAT_PERFORMER = 20)

	job_subclasses = list(
		/datum/job/advclass/performer/bard,
		/datum/job/advclass/performer/jester
	)

//SUBCLASSES

/datum/job/advclass/performer/bard
	title = "Bard"
	tutorial = "You are a keeper of stories and song. \
	Through music and word, you turn lives into legends and moments into memory. \
	Your performances inspire, mock, and uplift in equal measure."

	outfit = /datum/outfit/performer/bard
	category_tags = list(CAT_PERFORMER)
	give_bank_account = 20

	exp_types_granted = list(EXP_TYPE_BARD)

	spells = list(
		/datum/action/cooldown/spell/vicious_mockery,
		/datum/action/cooldown/spell/bardic_inspiration
	)

	jobstats = list(
		STATKEY_PER = 1,
		STATKEY_SPD = 2,
		STATKEY_STR = -1
	)

	skills = list(
		/datum/skill/combat/knives = 1,
		/datum/skill/combat/unarmed = 2,
		/datum/skill/craft/crafting = 1,
		/datum/skill/misc/swimming = 2,
		/datum/skill/misc/climbing = 2,
		/datum/skill/misc/riding = 3,
		/datum/skill/misc/sewing = 1,
		/datum/skill/misc/reading = 3,
		/datum/skill/craft/cooking = 1,
		/datum/skill/misc/sneaking = 3,
		/datum/skill/misc/stealing = 1,
		/datum/skill/misc/lockpicking = 1,
		/datum/skill/misc/music = 4,
		/datum/skill/misc/athletics = 3
	)

	traits = list(
		TRAIT_DODGEEXPERT,
		TRAIT_BARDIC_TRAINING
	)

/datum/job/advclass/performer/bard/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()
	spawned.select_equippable(player_client, list(
		"Harp" = /obj/item/instrument/harp,
		"Lute" = /obj/item/instrument/lute,
		"Accordion" = /obj/item/instrument/accord,
		"Guitar" = /obj/item/instrument/guitar,
		"Flute" = /obj/item/instrument/flute,
		"Drum" = /obj/item/instrument/drum,
		"Hurdy-Gurdy" = /obj/item/instrument/hurdygurdy,
		"Viola" = /obj/item/instrument/viola
	),
	message = "Choose your instrument.",
	title = "BARD"
	)

	var/datum/inspiration/I = new /datum/inspiration(spawned)
	I.grant_inspiration(spawned, bard_tier = BARD_T3)
	spawned.clamped_adjust_skillrank(/datum/skill/misc/music, 4, 4, TRUE)

/datum/outfit/performer/bard
	name = "Bard"
	head = /obj/item/clothing/head/bardhat
	mask = null
	neck = /obj/item/storage/belt/pouch/coins/poor
	cloak = /obj/item/clothing/cloak/raincloak/colored/blue
	armor = /obj/item/clothing/armor/leather/vest
	shirt = /obj/item/clothing/shirt/tunic/noblecoat
	wrists = null
	gloves = null
	pants = /obj/item/clothing/pants/tights/colored/random
	shoes = /obj/item/clothing/shoes/boots
	backr = null
	backl = /obj/item/storage/backpack/satchel
	belt = /obj/item/storage/belt/leather
	beltl = /obj/item/storage/belt/pouch/coins/poor
	beltr = /obj/item/weapon/knife/dagger/steel/special
	ring = null
	l_hand = null
	r_hand = null

	backpack_contents = list(/obj/item/flint)
	scabbards = list(/obj/item/weapon/scabbard/knife)

/datum/outfit/performer/bard/pre_equip(mob/living/carbon/human/H)
	. = ..()
	if(prob(50))
		cloak = /obj/item/clothing/cloak/raincloak/colored/red
	if(prob(30))
		gloves = /obj/item/clothing/gloves/fingerless

// ─────────────────────────────

/datum/job/advclass/performer/jester
	title = "Jester"
	tutorial = "You perform with humor, chaos, and audacity. \
	Whether fool, trickster, or clever nuisance, \
	you use laughter as both shield and blade."

	outfit = /datum/outfit/performer/jester
	category_tags = list(CAT_PERFORMER)
	give_bank_account = 20

	jobstats = list(
		STATKEY_PER = 1,
		STATKEY_SPD = 1,
		STATKEY_LCK = 2,
	)

	spells = list(
		/datum/action/cooldown/spell/undirected/joke,
		/datum/action/cooldown/spell/undirected/tragedy,
		/datum/action/cooldown/spell/vicious_mockery,
	)

	skills = list(
		/datum/skill/combat/knives = 3,
		/datum/skill/combat/unarmed = 2,
		/datum/skill/misc/riding = 2,
		/datum/skill/craft/bombs = 2,
		/datum/skill/labor/fishing = 2,
		/datum/skill/combat/wrestling = 2,
		/datum/skill/misc/reading = 3,
		/datum/skill/misc/sneaking = 3,
		/datum/skill/misc/stealing = 3,
		/datum/skill/misc/lockpicking = 3,
		/datum/skill/misc/climbing = 4,
		/datum/skill/misc/athletics = 4,
		/datum/skill/misc/music = 3,
		/datum/skill/craft/cooking = 2,
		/datum/skill/combat/firearms = 1,
	)

	traits = list(
		TRAIT_EMPATH,
		TRAIT_NUTCRACKER,
		TRAIT_ZJUMP,
		TRAIT_SHAKY_SPEECH
	)

/datum/job/advclass/performer/jester/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()
	spawned.verbs |= /mob/living/carbon/human/proc/ventriloquate
	spawned.verbs |= /mob/living/carbon/human/proc/ear_trick

/datum/outfit/performer/jester
	name = "Jester"
	head = /obj/item/clothing/head/jester
	mask = null
	neck = /obj/item/clothing/neck/coif
	cloak = /obj/item/clothing/cloak/raincloak/colored/blue
	armor = /obj/item/clothing/shirt/jester
	shirt = null
	wrists = null
	gloves = null
	pants = /obj/item/clothing/pants/tights
	shoes = /obj/item/clothing/shoes/jester
	backr = null
	backl = null
	belt = /obj/item/storage/belt/leather
	beltl = /obj/item/storage/keyring/jester
	beltr = /obj/item/storage/belt/pouch
	ring = null
	l_hand = null
	r_hand = null

//Ventriloquism! Make things speak!

/mob/living/carbon/human/proc/ventriloquate()
	set name = "Ventriloquism"
	set category = "Japes"

	var/obj/item/grabbing/I = get_active_held_item()
	if(!I)
		to_chat(src, "<span class='warning'>I need to be holding or grabbing something!</span>")
		return
	var/message = input(usr, "What do you want to ventriloquate?", "Ventriloquism!") as text | null
	if(!message)
		return
	I.say(message)
	log_admin("[key_name(usr)] ventriloquated [I] at [AREACOORD(I)] to say \"[message]\"")

// Ear Trick! Pull objects from behind someone's ear by the will of Xylix!

/mob/living/carbon/human/proc/ear_trick()
	set name = "Ear Trick"
	set category = "Japes"

	var/obj/item/grabbing/I = get_active_held_item()
	var/mob/living/carbon/human/H
	var/obj/item/japery_obj
	japery_obj = get_japery()
	var/obj/item/J = new japery_obj(get_turf(H))


	if(!istype(I) || !ishuman(I.grabbed))
		return
	H = I.grabbed
	if(H == src)
		to_chat(src, "<span class='warning'>I know what's behind my own ears!</span>")
		return
	if(!MOBTIMER_FINISHED(src, MT_LASTTRICK, 20 SECONDS))
		to_chat(src, "<span class='warning'>I need a moment before I can do another trick!</span>")
		return
	qdel(I)
	src.put_in_hands(J)
	src.visible_message("<span class='notice'>[src] reaches behind [H]'s ear with a grin, shaking their closed hand for a moment before revealing [J] held in it!</span>")
	MOBTIMER_SET(src, MT_LASTTRICK)

/mob/living/carbon/human/proc/get_japery()
	var/japery_list = list(
		/obj/item/coin/copper,
		/obj/item/natural/dirtclod,
		/obj/item/natural/worms,
		/obj/item/natural/worms/leech,
		/obj/item/natural/thorn,
		/obj/item/natural/stone,
		/obj/item/natural/poo,
		/obj/item/natural/feather,
		/obj/item/reagent_containers/food/snacks/hardtack
		)

	var/japery = pick(japery_list)
	return japery
