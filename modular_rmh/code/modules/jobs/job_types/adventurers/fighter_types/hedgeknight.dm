/datum/job/advclass/combat/adventurer_fighter/hedgeknight
	title = "Hedge Knight"
	tutorial = "A wandering hedge knight, mastering the sword and upholding the code of honor across Faerûn."

	outfit = /datum/outfit/adventurer_fighter/hedgeknight
	category_tags = list(CAT_ADVENTURER_FIGHTER)

	skills = list(
		/datum/skill/combat/wrestling = 2,
		/datum/skill/combat/unarmed = 3,
		/datum/skill/combat/swords = 4,
		/datum/skill/misc/climbing = 1,
		/datum/skill/misc/athletics = 3,
		/datum/skill/misc/reading = 2,
	)

	jobstats = list(
		STATKEY_STR = 2,
		STATKEY_END = 2,
		STATKEY_CON = 2,
		STATKEY_SPD = -1,
	)

	traits = list(
		TRAIT_HEAVYARMOR,
		TRAIT_STEELHEARTED,
	)

/datum/job/advclass/combat/adventurer_fighter/hedgeknight/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()
	var/prev_real_name = spawned.real_name
	var/prev_name = spawned.name
	var/honorary = "Ritter"
	if(spawned.pronouns == SHE_HER)
		honorary = "Ritterin"
	spawned.real_name = "[honorary] [prev_real_name]"
	spawned.name = "[honorary] [prev_name]"

	var/datum/species/species = spawned.dna?.species
	if(species && species.id == SPEC_ID_HUMEN)
		species.soundpack_m = new /datum/voicepack/male/knight()

/datum/outfit/adventurer_fighter/hedgeknight
	name = "Hedge Knight (Folkhero)"
	head = /obj/item/clothing/head/rare/grenzelplate
	mask = null
	neck = /obj/item/clothing/neck/chaincoif
	cloak = null
	armor = /obj/item/clothing/armor/rare/grenzelplate
	shirt = /obj/item/clothing/armor/gambeson
	wrists = /obj/item/clothing/wrists/bracers
	gloves = /obj/item/clothing/gloves/rare/grenzelplate
	pants = /obj/item/clothing/pants/tights/colored/black
	shoes = /obj/item/clothing/shoes/boots/rare/grenzelplate
	backr = /obj/item/weapon/sword/long/greatsword/flamberge
	backl = /obj/item/storage/backpack/satchel
	belt = /obj/item/storage/belt/leather
	beltl = /obj/item/storage/belt/pouch/coins/mid
	beltr = null
	ring = null
	l_hand = null
	r_hand = null
