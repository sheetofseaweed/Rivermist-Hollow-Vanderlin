/datum/job/roguetown/gnoll
	title = "Gnoll"
	flag = GNOLL
	department_flag = ANTAGONIST
	faction = "Station"
	total_positions = 1
	spawn_positions = 1
	allowed_races = RACES_NO_CONSTRUCT
	tutorial = "You have proven yourself worthy to Graggar, and he's granted you his blessing most divine. Now you hunt for worthy opponents, seeking out those strong enough to make you bleed."
	outfit = null
	outfit_female = null
	display_order = JDO_GNOLL
	show_in_credits = TRUE
	min_pq = 10
	max_pq = null
	allowed_patrons = list(/datum/patron/inhumen/graggar)

	obsfuscated_job = TRUE

	advclass_cat_rolls = list(CTAG_GNOLL = 20)
	PQ_boost_divider = 10
	round_contrib_points = 2

	announce_latejoin = FALSE
	wanderer_examine = TRUE
	advjob_examine = TRUE
	always_show_on_latechoices = TRUE
	job_reopens_slots_on_death = FALSE
	same_job_respawn_delay = 1 MINUTES
	virtue_restrictions = list(/datum/virtue/utility/noble) //Are you for real?
	job_subclasses = list(
		/datum/advclass/gnoll/berserker,
		/datum/advclass/gnoll/knight,
		/datum/advclass/gnoll/templar,
		/datum/advclass/gnoll/shaman,
	)

/datum/job/roguetown/gnoll/after_spawn(mob/living/L, mob/M, latejoin = TRUE)
	..()
	if(L)
		var/mob/living/carbon/human/H = L
		// Assign wretch antagonist datum so wretches appear in antag list
		if(H.mind && !H.mind.has_antag_datum(/datum/antagonist/gnoll))
			var/datum/antagonist/new_antag = new /datum/antagonist/gnoll()
			H.mind.add_antag_datum(new_antag)
			H.verbs |= /mob/living/carbon/human/proc/gnoll_inspect_skin

/datum/outfit/job/roguetown/gnoll/proc/don_pelt(mob/living/carbon/human/H)
	if(H.mind)
		var/pelts = list("firepelt", "rotpelt", "whitepelt", "bloodpelt", "nightpelt", "darkpelt")
		var/pelt_choice = input(H, "Choose your pelt.", "SPILL THEIR ENTRAILS.") as anything in pelts
		H.set_blindness(0)
		H.icon_state = "[pelt_choice]"
		H.dna?.species?.custom_base_icon = "[pelt_choice]"
		H.regenerate_icons()
		H.AddSpell(new /obj/effect/proc_holder/spell/self/claws/gnoll)
		H.AddSpell(new /obj/effect/proc_holder/spell/self/howl/gnoll)
		H.AddComponent(/datum/component/gnoll_combat_tracker)

		var/obj/effect/proc_holder/spell/invoked/gnoll_sniff/F = new()
		var/obj/effect/proc_holder/spell/invoked/invisibility/gnoll/I = new()
		I.sniff_spell = F // Link them

		var/obj/effect/proc_holder/spell/invoked/abduct/S = new /obj/effect/proc_holder/spell/invoked/abduct()
		S.destination_turf = get_turf(H) // Set the anchor to where they spawn/don the outfit
		H.AddSpell(S)
		H.AddSpell(F)
		H.AddSpell(I)

		var/mode = get_gnoll_scaling()
		if(mode == GNOLL_SCALING_DYNAMIC)
			to_chat(H, span_bignotice("I can expect to be joined by my pack this week. I should wait for them and group up."))
		else
			to_chat(H, span_bignotice("Isolated from my pack, I am likely a lone soul this week. I should especially avoid getting killed, and look for my pack next week."))
		to_chat(H, span_bignotice("Graggar is patient, and values good strategy. I mustn't be hasty, especially if my marks prove difficult to isolate.\n Perhaps there is merit in forging alliances, or setting up camp."))
		spawn(50)
			var/name_choice = alert(H, "What name do you want?", "MY NAME IS [H.real_name]", "Pick New Name", "Random Gnoll Name", "Keep Current Name")
			switch(name_choice)
				if("Pick New Name")
					H.choose_name_popup("GNOLL")
					to_chat(H, span_notice("Your name is now [H.real_name]."))
				if("Random Gnoll Name")
					H.real_name = "[pick(GLOB.wolf_prefixes)] [pick(GLOB.wolf_suffixes)]"
					to_chat(H, span_notice("Your name is now [H.real_name]."))
				if("Keep Current Name")
					to_chat(H, span_notice("You keep your name as [H.real_name]."))

/mob/living/carbon/human/proc/gnoll_inspect_skin()
	set name = "Inspect Pelt"
	set category = "Gnoll"
	set desc = "Examine your gnoll skin armor"
	if(!istype(skin_armor, /obj/item/clothing/suit/roguetown/armor/regenerating/skin/gnoll_armor))
		to_chat(src, span_warning("You don't have any gnoll skin armor to inspect!"))
		return
	var/obj/item/clothing/suit/roguetown/armor/regenerating/skin/gnoll_armor/GA = skin_armor
	GA.Topic(null, list("inspect" = "1"), src)


/mob/living/carbon/human/species/gnoll
	race = /datum/species/gnoll
	footstep_type = FOOTSTEP_MOB_HEAVY

/mob/living/carbon/human/species/gnoll/updatehealth()
	..()

	remove_movespeed_modifier(MOVESPEED_ID_DAMAGE_SLOWDOWN)
	remove_movespeed_modifier(MOVESPEED_ID_DAMAGE_SLOWDOWN_FLYING)

/mob/living/carbon/human/species/gnoll/male
	gender = MALE

/mob/living/carbon/human/species/gnoll/female
	gender = FEMALE

/datum/species/gnoll
	name = "gnoll"
	id = "gnoll"
	custom_rotation_icon = TRUE
	custom_base_icon = "firepelt"
	species_traits = list(NO_UNDERWEAR, NO_ORGAN_FEATURES, NO_BODYPART_FEATURES)
	inherent_traits = list(
		TRAIT_LONGSTRIDER,
		TRAIT_IGNORESLOWDOWN,
		TRAIT_IGNOREDAMAGESLOWDOWN,
		TRAIT_CRITICAL_RESISTANCE,
		TRAIT_NOFALLDAMAGE1,
		TRAIT_STRENGTH_UNCAPPED,
		TRAIT_PIERCEIMMUNE,
		TRAIT_HARDDISMEMBER,
		TRAIT_NOSTINK,
		TRAIT_NASTY_EATER,
		TRAIT_ORGAN_EATER,
		TRAIT_BREADY,
		TRAIT_STEELHEARTED,
		TRAIT_BASHDOORS,
		TRAIT_ZJUMP,
		TRAIT_STRONGBITE,
		TRAIT_GNARLYDIGITS,
		TRAIT_NUDIST,
		TRAIT_HERESIARCH, //Just because I'm putting their spawns here, that's all.
		TRAIT_ZURCH,
	)
	inherent_biotypes = MOB_HUMANOID
	armor = 30
	no_equip = list(SLOT_SHIRT, SLOT_HEAD, SLOT_WEAR_MASK, SLOT_ARMOR, SLOT_GLOVES, SLOT_SHOES, SLOT_PANTS, SLOT_CLOAK, SLOT_BELT, SLOT_BACK_R, SLOT_BACK_L, SLOT_S_STORE)
	nojumpsuit = 1
	sexes = 1
	offset_features = list(OFFSET_HANDS = list(0,2), OFFSET_HANDS_F = list(0,2))
	soundpack_m = /datum/voicepack/gnoll
	soundpack_f = /datum/voicepack/gnoll
	enflamed_icon = "widefire"
	organs = list(
		ORGAN_SLOT_BRAIN = /obj/item/organ/brain,
		ORGAN_SLOT_HEART = /obj/item/organ/heart,
		ORGAN_SLOT_LUNGS = /obj/item/organ/lungs,
		ORGAN_SLOT_EYES = /obj/item/organ/eyes/night_vision/werewolf,
		ORGAN_SLOT_EARS = /obj/item/organ/ears,
		ORGAN_SLOT_TONGUE = /obj/item/organ/tongue/wild_tongue,
		ORGAN_SLOT_LIVER = /obj/item/organ/liver,
		ORGAN_SLOT_STOMACH = /obj/item/organ/stomach,
		ORGAN_SLOT_APPENDIX = /obj/item/organ/appendix,
		)
	languages = list(
		/datum/language/common,
		/datum/language/gronnic,
		/datum/language/beast,
	)
	var/gnoll_armor_icon = "beserker"

/datum/species/gnoll/send_voice(mob/living/carbon/human/H)
	playsound(get_turf(H), pick('sound/vo/mobs/wwolf/wolftalk1.ogg','sound/vo/mobs/wwolf/wolftalk2.ogg'), 100, TRUE, -1)

/datum/species/gnoll/regenerate_icons(mob/living/carbon/human/H)
	H.icon = 'icons/roguetown/mob/monster/gnoll.dmi'
	H.base_intents = list(INTENT_HELP, INTENT_DISARM, INTENT_GRAB)
	H.update_damage_overlays()
	H.update_inv_armor_special()
	return TRUE

/datum/species/gnoll/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	. = ..()
	RegisterSignal(C, COMSIG_MOB_SAY, PROC_REF(handle_speech))
	C.icon_state = "firepelt"
	C.base_pixel_x = -8
	C.pixel_x = -8
	C.base_pixel_y = -4
	C.pixel_y = -4

/datum/species/gnoll/update_damage_overlays(mob/living/carbon/human/H)
	H.remove_overlay(DAMAGE_LAYER)
	var/list/hands = list()
	var/mutable_appearance/inhand_overlay = mutable_appearance("[H.icon_state]-dam", layer=-DAMAGE_LAYER)
	var/burnhead = 0
	var/brutehead = 0
	var/burnch = 0
	var/brutech = 0
	var/obj/item/bodypart/affecting = H.get_bodypart(BODY_ZONE_HEAD)
	if(affecting)
		burnhead = (affecting.burn_dam / affecting.max_damage)
		brutehead = (affecting.brute_dam / affecting.max_damage)
	affecting = H.get_bodypart(BODY_ZONE_CHEST)
	if(affecting)
		burnch = (affecting.burn_dam / affecting.max_damage)
		brutech = (affecting.brute_dam / affecting.max_damage)
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

/datum/species/gnoll/random_name(gender,unique,lastname)
	return "VEREWOLF"

/datum/voicepack/gnoll/get_sound(soundin, modifiers)
	var/used
	switch(soundin)
		if("aggro")
			used = pick('sound/vo/mobs/wwolf/roar.ogg')
		if("rage")
			used = pick('sound/vo/mobs/wwolf/roar.ogg')
		if("deathgurgle")
			used = pick('sound/vo/mobs/wwolf/death.ogg')
		if("firescream")
			used = pick('sound/vo/mobs/wwolf/painscream.ogg')
		if("painscream")
			used = pick('sound/vo/mobs/wwolf/painscream.ogg')
		if("agony")
			used = pick('sound/vo/mobs/wwolf/painscream.ogg')
		if("jump")
			used = pick('sound/vo/mobs/wwolf/jump (1).ogg','sound/vo/mobs/wwolf/jump (3).ogg','sound/vo/mobs/wwolf/jump (2).ogg')
		if("leap")
			used = pick('sound/vo/mobs/wwolf/jump (1).ogg','sound/vo/mobs/wwolf/jump (3).ogg','sound/vo/mobs/wwolf/jump (2).ogg')
		if("pain")
			used = pick('sound/vo/mobs/wwolf/pain (1).ogg','sound/vo/mobs/wwolf/pain (3).ogg','sound/vo/mobs/wwolf/pain (2).ogg')
		if("paincrit")
			used = pick('sound/vo/mobs/wwolf/pain (1).ogg','sound/vo/mobs/wwolf/pain (3).ogg','sound/vo/mobs/wwolf/pain (2).ogg')
		if("scream")
			used = pick('sound/vo/mobs/hyena/yeen_howl.ogg')
		if("howl")
			used = pick('sound/vo/mobs/hyena/yeen_howl.ogg')
		if("idle")
			used = pick('sound/vo/mobs/wwolf/idle (1).ogg','sound/vo/mobs/wwolf/idle (2).ogg','sound/vo/mobs/wwolf/sniff.ogg')
		if("cackle")
			used = list('sound/vo/mobs/hyena/cackle.ogg')
		if("chuckle")
			used = list('sound/vo/mobs/hyena/cackle.ogg')
		if("laugh")
			used = list('sound/vo/mobs/hyena/laugh.ogg')
		if("whimper")
			used = list('sound/vo/mobs/hyena/groan.ogg')

	return used

