GLOBAL_LIST_INIT(bum_quotes, world.file2list('strings/rt/bumlines.txt'))
GLOBAL_LIST_INIT(bum_aggro, world.file2list('strings/rt/bumaggrolines.txt'))

/mob/living/carbon/human/species/human/northern/bum
	ai_controller = /datum/ai_controller/human_bum
	faction = list(FACTION_BUMS, FACTION_TOWN)
	ambushable = FALSE
	dodgetime = 30
	flee_in_pain = TRUE
	possible_rmb_intents = list()

	wander = FALSE

/mob/living/carbon/human/species/human/northern/bum/Initialize()
	. = ..()
	AddElement(/datum/element/ai_retaliate)

/mob/living/carbon/human/species/human/northern/bum/ambush
	ai_controller = /datum/ai_controller/human_bum/aggressive
	wander = TRUE

/mob/living/carbon/human/species/human/northern/bum/Initialize()
	. = ..()
	set_species(/datum/species/human/northern)
	AddComponent(/datum/component/ai_aggro_system)
	addtimer(CALLBACK(src, PROC_REF(after_creation)), 1 SECONDS)

/mob/living/carbon/human/species/human/northern/bum/after_creation()
	..()
	job = "Beggar"
	ADD_TRAIT(src, TRAIT_NOMOOD, TRAIT_GENERIC)
	ADD_TRAIT(src, TRAIT_NOHUNGER, TRAIT_GENERIC)
	equipOutfit(new /datum/outfit/vagrant)

/datum/outfit/vagrant
	name = "Beggar"

/datum/outfit/vagrant/pre_equip(mob/living/carbon/human/H)
	. = ..()
	if(prob(20))
		head = /obj/item/clothing/head/knitcap
	if(prob(5))
		beltr = /obj/item/reagent_containers/powder/moondust
	if(prob(10))
		beltl = /obj/item/clothing/face/cigarette/rollie/cannabis
	if(prob(10))
		cloak = /obj/item/clothing/cloak/raincloak/colored/brown
	if(prob(10))
		gloves = /obj/item/clothing/gloves/fingerless
	if(prob(5))
		r_hand = /obj/item/weapon/mace/woodclub

	if(H.gender == FEMALE)
		armor = /obj/item/clothing/shirt/rags
	else
		pants = /obj/item/clothing/pants/tights/colored/vagrant
		shirt = /obj/item/clothing/shirt/undershirt/colored/vagrant
