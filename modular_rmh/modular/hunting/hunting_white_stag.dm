// Hunting & Tracking pack - the White Stag, the hunt's legend.
//
// A carbon, not a simple animal: a humanoid mob wearing a custom species. Species mobs are
// declared directly here (race = /datum/species/X, as goblins and orcs do), so no core file is
// touched.
//
// Its durability is meant to come from its stats, its hide and NOBLOOD rather than from a pile of
// immunity flags, and its damage from a flat sweep rather than from a blade's force.

/// Speed modifier id for the wounded-rush buff.
#define MOVESPEED_ID_WHITE_RUSH "white_rush"
/// Flat damage per tile of the antler sweep. The greatsword swing it inherits from scales off the
/// blade, which off the antlers' force of 45 would land noticeably weaker.
#define STAG_SWEEP_DAMAGE 80

/datum/species/white_stag
	name = "White Stag"
	id = "white_stag"
	species_traits = list(NO_UNDERWEAR, NO_ORGAN_FEATURES, NO_BODYPART_FEATURES)
	inherent_traits = list(
		TRAIT_DODGEEXPERT,
		TRAIT_STEELHEARTED,
		TRAIT_HARDDISMEMBER,
		TRAIT_LONGSTRIDER,
		TRAIT_LEECHIMMUNE,
		TRAIT_NOSTAMINA,
		TRAIT_NOPAINSTUN,
		TRAIT_NOPAIN,
		TRAIT_BLOODLOSS_IMMUNE,
		TRAIT_KNEESTINGER_IMMUNITY,
		TRAIT_NOBREATH,
	)
	no_equip = list(ITEM_SLOT_SHIRT, ITEM_SLOT_HEAD, ITEM_SLOT_ARMOR, ITEM_SLOT_MASK, ITEM_SLOT_GLOVES, ITEM_SLOT_SHOES, ITEM_SLOT_PANTS, ITEM_SLOT_CLOAK, ITEM_SLOT_BELT)
	nojumpsuit = TRUE
	sexes = 1

/// Returning TRUE is the documented way to opt out: update_damage_overlays_real() bails before it
/// paints the human wound sprites, which otherwise show up smeared over a stag.
/datum/species/white_stag/update_damage_overlays(mob/living/carbon/human/target)
	return TRUE

/datum/species/white_stag/regenerate_icons(mob/living/carbon/human/target)
	target.icon = 'modular_rmh/icons/mob/monster/white_stag.dmi'
	target.icon_state = "stag"
	target.pixel_x = -24
	return TRUE

/mob/living/carbon/human/species/white_stag
	name = "The White Stag"
	race = /datum/species/white_stag
	ai_controller = /datum/ai_controller/human_npc
	d_intent = INTENT_PARRY
	dodgetime = 10
	pixel_x = -16
	faction = list("white_stag")
	icon = 'modular_rmh/icons/mob/monster/white_stag.dmi'
	icon_state = "stag"

/mob/living/carbon/human/species/white_stag/Initialize(mapload)
	. = ..()
	// Deferred a tick: species setup and bodypart generation have to finish before its stats,
	// skills and antlers can be applied on top.
	addtimer(CALLBACK(src, PROC_REF(become_the_stag)), 1 SECONDS)

// Named become_the_stag, not after_creation: /mob/living/carbon/human already has a proc by
// that name in code/modules/mob/dead/new_player/new_player.dm.
/mob/living/carbon/human/species/white_stag/proc/become_the_stag()
	if(QDELETED(src))
		return
	AddComponent(/datum/component/ai_aggro_system)

	// Legendary stats. Set through change_stat() because STASTR and friends are final vars here,
	// computed from the attribute system rather than assigned directly.
	change_stat(STAT_STRENGTH, 6)
	change_stat(STAT_SPEED, 8)
	change_stat(STAT_CONSTITUTION, 10)
	change_stat(STAT_PERCEPTION, 8)
	change_stat(STAT_ENDURANCE, 5)
	change_stat(STAT_INTELLIGENCE, 5)
	change_stat(STAT_FORTUNE, 4)

	adjust_skillrank(/datum/attribute/skill/combat/unarmed, 6, TRUE)
	adjust_skillrank(/datum/attribute/skill/combat/wrestling, 6, TRUE)
	adjust_skillrank(/datum/attribute/skill/misc/athletics, 6, TRUE)

	// Two of them, so it has no free hand to pick up anything a hunter drops.
	for(var/i in 1 to 2)
		var/obj/item/weapon/stag_antlers/antlers = new(src)
		if(!put_in_hands(antlers, TRUE))
			qdel(antlers)

	skin_armor = new /obj/item/clothing/armor/skin_armor/stag_hide(src)

	var/static/list/stag_titles = list(
		"The White Spectre", "Lord Of The Woods", "The Ivory Wraith", "The Pale Sovereign",
		"The White Scourge", "The Pale Vengeance", "The Bleak Tyrant", "The Alabaster Monarch",
		"The Winter Herald", "The Ivory Giant", "The Forest Patriarch", "The Mist-Walker",
		"The Ghost of the Peak", "King's Fever", "Lord Of The Hunt", "The Wild Hunter",
		"The Bleached Terror", "Terror Of The Woods", "Night Stalker", "The Silent Witness",
		"The Hunter's Ruin", "The Ivory Reaper", "The Uncatchable", "Winter's Wrath",
		"The Great White Calamity", "The Beast Of Old", "Snow Wraith", "Heart Of Ice",
		"Bone Stalker",
	)
	real_name = pick(stag_titles)
	name = real_name

	AddComponent(/datum/component/white_stag_tracker)
	// Practically the only way to put it down for good is to take the head off.
	if(dna?.species)
		dna.species.species_traits |= NOBLOOD

/datum/armor/skin/stag_hide
	blunt = 90
	slash = 90
	stab = 90
	piercing = DBLOCK_NONE
	fire = DR_NONE
	acid = DR_NONE

/obj/item/clothing/armor/skin_armor/stag_hide
	slot_flags = null
	name = "white stag skin"
	desc = "A pelt like frost over iron."
	icon_state = null
	body_parts_covered = FULL_BODY
	armor_type = /datum/armor/skin/stag_hide
	prevent_crits = list(BCLASS_CUT, BCLASS_STAB, BCLASS_BLUNT, BCLASS_TWIST)
	blocksound = SOFTHIT
	blade_dulling = DULLING_BASHCHOP
	resistance_flags = INDESTRUCTIBLE
	item_flags = DROPDEL

/datum/intent/simple/stag_gore
	name = "gore"
	clickcd = CLICK_CD_FAST
	// The intent sheet calls this sprite "instab".
	icon_state = "instab"
	blade_class = BCLASS_STAB
	attack_verb = list("gores", "rams", "skewers")
	animname = "stab"
	// Declared as a list here and read through pick(), so a bare file reference would not do.
	hitsound = list('sound/combat/rend_hit.ogg')
	penfactor = PEN_BSTEEL
	candodge = TRUE
	canparry = TRUE
	miss_text = "thrusts its antlers wildly!"
	miss_sound = "bladewooshmed"

/// Its own special: the stag wheels on the spot and rakes everything around it. Inherits the
/// greatsword ring pattern, since that is exactly the shape of the move, but hits for a flat
/// amount with a stab rather than scaling off a blade.
/datum/special_intent/greatsword_swing/white_stag
	name = "Antler Sweep"
	desc = "Wheel on the spot and rake everything within reach."
	cooldown = 25 SECONDS
	stamina_cost = 0
	post_sound = 'sound/combat/rend_hit.ogg'

/datum/special_intent/greatsword_swing/white_stag/apply_hit(mob/living/user, obj/item/parent, turf/target)
	for(var/mob/living/victim in target)
		if(victim == user || victim.body_position == LYING_DOWN)
			continue
		apply_generic_weapon_damage(user, parent, victim, STAG_SWEEP_DAMAGE, PIERCE, BODY_ZONE_CHEST, BCLASS_STAB)

// /obj/item/weapon, not /obj/item/natural: weapon_special is declared on the weapon branch.
/obj/item/weapon/stag_antlers
	name = "ancient antlers"
	desc = "Sharp, calcified points of power."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = null
	force = 45
	wdefense = 10
	associated_skill = /datum/attribute/skill/combat/unarmed
	wlength = WLENGTH_LONG
	can_parry = TRUE
	sharpness = IS_SHARP
	parrysound = list('sound/combat/parry/parrygen.ogg')
	possible_item_intents = list(/datum/intent/simple/stag_gore)
	weapon_special = /datum/special_intent/greatsword_swing/white_stag
	item_flags = DROPDEL
	max_integrity = 8000

/obj/item/weapon/stag_antlers/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, TRAIT_GENERIC)
	ADD_TRAIT(src, TRAIT_NOEMBED, TRAIT_GENERIC)

/// What is left on the ground once the stag falls. A carcass, not a fight - it spawns already dead.
/mob/living/simple_animal/hostile/retaliate/white_stag_corpse
	name = "White Stag"
	desc = "A creature of legend, now slain."
	icon = 'modular_rmh/icons/mob/monster/white_stag.dmi'
	icon_state = "stag"
	icon_living = "stag"
	icon_dead = "stag_dead"
	gender = NEUTER
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	health = 1
	maxHealth = 1
	pixel_x = -24
	head_butcher = /obj/item/natural/head/white_stag
	rot_type = null
	botched_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/steak = 6,
		/obj/item/reagent_containers/food/snacks/fat = 2,
		/obj/item/natural/hide = 4,
		/obj/item/natural/bundle/bone/full = 4,
		/obj/item/alch/sinew = 2,
		/obj/item/alch/viscera = 1,
	)
	butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/steak = 12,
		/obj/item/reagent_containers/food/snacks/fat = 6,
		/obj/item/natural/hide = 10,
		/obj/item/natural/bundle/bone/full = 10,
		/obj/item/alch/sinew = 5,
		/obj/item/alch/viscera = 3,
	)
	perfect_butcher_results = list(
		/obj/item/reagent_containers/food/snacks/meat/steak = 16,
		/obj/item/reagent_containers/food/snacks/fat = 6,
		/obj/item/natural/hide = 12,
		/obj/item/natural/bundle/bone/full = 12,
		/obj/item/alch/sinew = 6,
		/obj/item/alch/viscera = 4,
	)

/obj/item/natural/head/white_stag
	name = "white stag head"
	desc = "The enormous head and rack of the ever elusive white stag, priceless."
	icon = 'modular_rmh/icons/obj/hunting/hunting_heads_big.dmi'
	icon_state = "white_stag"
	layer = 3.1
	pixel_x = -16
	grid_height = 32
	grid_width = 32
	sellprice = 500
	headpricemin = 400
	headpricemax = 600

/// Mounting the head on a wall. Pried back off by hand.
/obj/structure/fluff/walldeco/mounted_stag_head
	name = "mounted white stag head"
	desc = "A grand trophy, looming from the wall with sightless, ivory eyes."
	icon = 'modular_rmh/icons/obj/hunting/hunting_heads_big.dmi'
	icon_state = "white_stag"
	pixel_x = -16
	anchored = TRUE
	density = FALSE
	layer = ABOVE_MOB_LAYER
	var/stolen_item = /obj/item/natural/head/white_stag

/obj/structure/fluff/walldeco/mounted_stag_head/attack_hand(mob/user, list/modifiers)
	if(!do_after(user, 5 SECONDS, target = src)) // Heavier than a painting
		return ..()
	to_chat(user, span_notice("You carefully pry [src] off the wall."))
	var/obj/item/trophy = new stolen_item(user.loc)
	user.put_in_hands(trophy)
	qdel(src)
	return TRUE

// Mounting goes through afterattack(); there is no attack_turf() to hook here.
/obj/item/natural/head/white_stag/afterattack(atom/target, mob/living/user, proximity_flag, list/modifiers)
	. = ..()
	if(!proximity_flag || !isliving(user))
		return
	var/turf/target_turf = target
	if(!isclosedturf(target_turf))
		return
	var/dir_to_wall = get_dir(user, target_turf)
	if(!(dir_to_wall in GLOB.cardinals))
		return

	to_chat(user, span_notice("You begin mounting [src] to the wall..."))
	if(!do_after(user, 3 SECONDS, target = target_turf))
		return

	var/obj/structure/fluff/walldeco/mounted_stag_head/mounted = new(user.loc)
	switch(dir_to_wall)
		if(NORTH)
			mounted.pixel_y = 32
			mounted.pixel_x = -16
		if(SOUTH)
			mounted.pixel_y = -32
			mounted.pixel_x = -16
		if(WEST)
			mounted.pixel_x = -48
		if(EAST)
			mounted.pixel_x = 16
	to_chat(user, span_notice("You mount [src] firmly."))
	qdel(src)

/// Drives the stag's two signature behaviours: it grows faster and knits itself back together when
/// wounded, and it leaves a carcass rather than a body when it finally goes down.
/datum/component/white_stag_tracker
	var/death_processed = FALSE

/datum/component/white_stag_tracker/Initialize(mapload)
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	RegisterSignal(parent, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_damage))
	RegisterSignal(parent, COMSIG_LIVING_DEATH, PROC_REF(on_death))

/datum/component/white_stag_tracker/proc/on_damage(datum/source, damage, damagetype)
	SIGNAL_HANDLER
	if(damage <= 5)
		return
	var/mob/living/carbon/human/stag = parent
	stag.apply_status_effect(/datum/status_effect/buff/white_rush)

/datum/component/white_stag_tracker/proc/on_death()
	SIGNAL_HANDLER
	if(death_processed)
		return
	death_processed = TRUE
	INVOKE_ASYNC(src, PROC_REF(leave_carcass))

/datum/component/white_stag_tracker/proc/leave_carcass()
	var/mob/living/carbon/human/stag = parent
	if(QDELETED(stag))
		return
	var/turf/resting_place = get_turf(stag)
	if(resting_place)
		var/mob/living/simple_animal/hostile/retaliate/white_stag_corpse/carcass = new(resting_place)
		carcass.name = stag.real_name
		carcass.death()
	stag.visible_message(span_userdanger("[stag] lets out a final, haunting bell as its spirit departs, leaving a heavy carcass behind."))
	qdel(stag)

/datum/status_effect/buff/white_rush
	id = "white_rush"
	duration = 6 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/buff/white_rush
	var/healing_per_tick = 1

/atom/movable/screen/alert/status_effect/buff/white_rush
	name = "Forest Rush"
	desc = "I WILL NOT BE HUNTED."

/datum/status_effect/buff/white_rush/on_apply()
	. = ..()
	if(!ishuman(owner))
		return FALSE
	owner.add_movespeed_modifier(MOVESPEED_ID_WHITE_RUSH, update = TRUE, priority = 15, multiplicative_slowdown = -2)

/datum/status_effect/buff/white_rush/tick()
	var/mob/living/carbon/human/stag = owner
	stag.adjustBruteLoss(-healing_per_tick)
	stag.heal_wounds(healing_per_tick)
	var/obj/effect/temp_visual/heal_rogue/spark = new(get_turf(owner))
	spark.color = "#FF0000"

/datum/status_effect/buff/white_rush/on_remove()
	owner.remove_movespeed_modifier(MOVESPEED_ID_WHITE_RUSH)
	return ..()

#undef MOVESPEED_ID_WHITE_RUSH
#undef STAG_SWEEP_DAMAGE
