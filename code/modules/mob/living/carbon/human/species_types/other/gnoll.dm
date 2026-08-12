/mob/living/carbon/human/species/gnoll
	race = /datum/species/gnoll
	footstep_type = FOOTSTEP_MOB_HEAVY

/mob/living/carbon/human/species/gnoll/male
	gender = MALE

/mob/living/carbon/human/species/gnoll/female
	gender = FEMALE

/datum/species/gnoll
	name = "Werewolf"
	id = "gnoll"

	species_traits = list(
		NO_UNDERWEAR,
		NO_ORGAN_FEATURES,
		NO_BODYPART_FEATURES,
	)

	inherent_traits = list(
		TRAIT_LONGSTRIDER,
		TRAIT_IGNORESLOWDOWN,
		TRAIT_IGNOREDAMAGESLOWDOWN,
		TRAIT_CRITICAL_RESISTANCE,
		TRAIT_NOFALLDAMAGE1,
		TRAIT_PIERCEIMMUNE,
		TRAIT_HARDDISMEMBER,
		TRAIT_NASTY_EATER,
		TRAIT_ORGAN_EATER,
		TRAIT_BREADY,
		TRAIT_STEELHEARTED,
		TRAIT_BASHDOORS,
		TRAIT_ZJUMP,
		TRAIT_STRONGBITE,
		TRAIT_NUDIST,
	)

	inherent_biotypes = MOB_HUMANOID | MOB_BEAST

	sexes = TRUE

	soundpack_m = /datum/voicepack/gnoll
	soundpack_f = /datum/voicepack/gnoll

	enflamed_icon = "widefire"

	organs = list(
		ORGAN_SLOT_BRAIN = /obj/item/organ/brain,
		ORGAN_SLOT_HEART = /obj/item/organ/heart,
		ORGAN_SLOT_LUNGS = /obj/item/organ/lungs,
		ORGAN_SLOT_EYES = /obj/item/organ/eyes/night_vision/werewolf,
		ORGAN_SLOT_EARS = /obj/item/organ/ears,
		ORGAN_SLOT_TONGUE = /obj/item/organ/tongue,
		ORGAN_SLOT_LIVER = /obj/item/organ/liver,
		ORGAN_SLOT_STOMACH = /obj/item/organ/stomach,
	)

/datum/species/gnoll/check_roundstart_eligible()
	return TRUE

/datum/species/gnoll/on_species_gain(
	mob/living/carbon/C,
	datum/species/old_species,
	datum/preferences/pref_load,
)
	. = ..()

	RegisterSignal(C, COMSIG_MOB_SAY, PROC_REF(handle_speech))

	C.grant_language(/datum/language/common)
	C.grant_language(/datum/language/beast)

	if(ishuman(C))
		var/mob/living/carbon/human/H = C
		H.icon = 'icons/roguetown/mob/monster/gnoll.dmi'
		H.icon_state = "firepelt"
		H.base_pixel_x = -8
		H.pixel_x = -8
		H.base_pixel_y = -4
		H.pixel_y = -4

		var/datum/action/cooldown/spell/undirected/howl/howl_action = new(H)
		howl_action.use_language = TRUE
		howl_action.Grant(H)

	regenerate_icons()

/datum/species/gnoll/on_species_loss(mob/living/carbon/C)
	. = ..()

	UnregisterSignal(C, COMSIG_MOB_SAY)

	C.remove_language(/datum/language/common)
	C.remove_language(/datum/language/beast)

	var/datum/action/cooldown/spell/undirected/howl/howl_action = locate() in C.actions
	if(howl_action)
		qdel(howl_action)

/datum/species/gnoll/send_voice(mob/living/carbon/human/H)
	playsound(
		get_turf(H),
		pick(
			'sound/vo/mobs/wwolf/wolftalk1.ogg',
			'sound/vo/mobs/wwolf/wolftalk2.ogg',
		),
		100,
		TRUE,
		-1,
	)

/datum/species/gnoll/regenerate_icons(mob/living/carbon/human/H)
	H.icon = 'icons/roguetown/mob/monster/gnoll.dmi'

	if(!H.icon_state)
		H.icon_state = "firepelt"

	H.update_damage_overlays()

	return TRUE

/datum/species/gnoll/update_damage_overlays(mob/living/carbon/human/H)
	H.remove_overlay(DAMAGE_LAYER)

	var/list/hands = list()
	var/mutable_appearance/inhand_overlay = mutable_appearance(
		"[H.icon_state]-dam",
		layer = -DAMAGE_LAYER,
	)

	var/burnhead = 0
	var/brutehead = 0
	var/burnch = 0
	var/brutech = 0

	var/obj/item/bodypart/affecting = H.get_bodypart(BODY_ZONE_HEAD)

	if(affecting)
		burnhead = affecting.burn_dam / affecting.max_damage
		brutehead = affecting.brute_dam / affecting.max_damage

	affecting = H.get_bodypart(BODY_ZONE_CHEST)

	if(affecting)
		burnch = affecting.burn_dam / affecting.max_damage
		brutech = affecting.brute_dam / affecting.max_damage

	var/usedloss = 0

	if(burnhead > usedloss)
		usedloss = burnhead

	if(brutehead > usedloss)
		usedloss = brutehead

	if(burnch > usedloss)
		usedloss = burnch

	if(brutech > usedloss)
		usedloss = brutech

	inhand_overlay.alpha = 255 * usedloss

	hands += inhand_overlay
	H.overlays_standing[DAMAGE_LAYER] = hands
	H.apply_overlay(DAMAGE_LAYER)

	return TRUE

/datum/species/gnoll/random_name(gender, unique, lastname)
	return "[pick(strings("werewolf_names.json", "wolf_prefixes"))] [pick(strings("werewolf_names.json", "wolf_suffixes"))]"

/datum/voicepack/gnoll/get_sound(soundin, modifiers)
	var/used

	switch(soundin)
		if("aggro")
			used = 'sound/vo/mobs/wwolf/roar.ogg'

		if("rage")
			used = 'sound/vo/mobs/wwolf/roar.ogg'

		if("deathgurgle")
			used = 'sound/vo/mobs/wwolf/death.ogg'

		if("firescream")
			used = 'sound/vo/mobs/wwolf/painscream.ogg'

		if("painscream")
			used = 'sound/vo/mobs/wwolf/painscream.ogg'

		if("agony")
			used = 'sound/vo/mobs/wwolf/painscream.ogg'

		if("jump")
			used = pick(
				'sound/vo/mobs/wwolf/jump (1).ogg',
				'sound/vo/mobs/wwolf/jump (2).ogg',
				'sound/vo/mobs/wwolf/jump (3).ogg',
			)

		if("leap")
			used = pick(
				'sound/vo/mobs/wwolf/jump (1).ogg',
				'sound/vo/mobs/wwolf/jump (2).ogg',
				'sound/vo/mobs/wwolf/jump (3).ogg',
			)

		if("pain")
			used = pick(
				'sound/vo/mobs/wwolf/pain (1).ogg',
				'sound/vo/mobs/wwolf/pain (2).ogg',
				'sound/vo/mobs/wwolf/pain (3).ogg',
			)

		if("paincrit")
			used = pick(
				'sound/vo/mobs/wwolf/pain (1).ogg',
				'sound/vo/mobs/wwolf/pain (2).ogg',
				'sound/vo/mobs/wwolf/pain (3).ogg',
			)

		if("scream")
			used = 'sound/vo/mobs/wwolf/roar.ogg'

		if("howl")
			used = pick(
				'sound/vo/mobs/wwolf/howl (1).ogg',
				'sound/vo/mobs/wwolf/howl (2).ogg',
			)

		if("idle")
			used = pick(
				'sound/vo/mobs/wwolf/idle (1).ogg',
				'sound/vo/mobs/wwolf/idle (2).ogg',
				'sound/vo/mobs/wwolf/sniff.ogg',
			)

		if("cackle")
			used = 'sound/vo/mobs/wwolf/roar.ogg'

		if("chuckle")
			used = 'sound/vo/mobs/wwolf/idle (1).ogg'

		if("laugh")
			used = 'sound/vo/mobs/wwolf/idle (2).ogg'

		if("whimper")
			used = 'sound/vo/mobs/wwolf/pain (1).ogg'

	return used

/datum/species/gnoll/on_species_gain(
	mob/living/carbon/C,
	datum/species/old_species,
	datum/preferences/pref_load,
)
	. = ..()

	RegisterSignal(C, COMSIG_MOB_SAY, PROC_REF(handle_speech))

	C.grant_language(/datum/language/common)
	C.grant_language(/datum/language/beast)

	C.add_spell(/datum/action/cooldown/spell/undirected/howl)
	C.add_spell(/datum/action/cooldown/spell/undirected/claws)
	C.add_spell(/datum/action/cooldown/spell/woundlick)

	if(ishuman(C))
		var/mob/living/carbon/human/H = C
		H.icon = 'icons/roguetown/mob/monster/gnoll.dmi'
		H.icon_state = "firepelt"
		H.base_pixel_x = -8
		H.pixel_x = -8
		H.base_pixel_y = -4
		H.pixel_y = -4
		regenerate_icons(H)

/datum/species/gnoll/on_species_loss(mob/living/carbon/C)
	. = ..()

	UnregisterSignal(C, COMSIG_MOB_SAY)

	C.remove_language(/datum/language/common)
	C.remove_language(/datum/language/beast)

	C.remove_spell(/datum/action/cooldown/spell/undirected/howl)
	C.remove_spell(/datum/action/cooldown/spell/undirected/claws)
	C.remove_spell(/datum/action/cooldown/spell/woundlick)
