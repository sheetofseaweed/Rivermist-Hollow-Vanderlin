/datum/component/rot
	var/amount = 0
	var/rot_amount_per_process = 10 //1 second
	var/last_process = 0
	//RMH EDITED START - no flies sound; bodies nobody keeps wither away
	/// Rot amount past which a body nobody keeps crumbles to dust. Null keeps the body forever.
	var/wither_time
	//RMH EDITED END

/datum/component/rot/Initialize(new_amount)
	..()
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE

	if(new_amount)
		amount = new_amount

	START_PROCESSING(SSroguerot, src)

/datum/component/rot/process()
	if(HAS_TRAIT(parent, TRAIT_STASIS) || HAS_TRAIT(parent, TRAIT_NO_ROT))
		return
	var/amt2add = rot_amount_per_process
	if(last_process)
		amt2add = ((world.time - last_process)/10) * amt2add
	last_process = world.time
	amount += amt2add
	return

//RMH EDITED START
/// Crumbles the body to dust once rot passes wither_time. Player characters, and bodies that are carried, hung, buried or stored, are kept.
/datum/component/rot/proc/try_wither()
	if(isnull(wither_time) || amount <= wither_time)
		return FALSE
	var/mob/living/body = parent
	if(!istype(body) || !isturf(body.loc) || body.buckled || body.pulledby || body.is_player_character())
		return FALSE
	qdel(src)
	body.dust(drop_items = TRUE)
	return TRUE
//RMH EDITED END

/datum/component/rot/corpse
	wither_time = 60 MINUTES //RMH EDITED - NPC remains, after skeletonize_time

/datum/component/rot/corpse/Initialize()
	if(!iscarbon(parent))
		return COMPONENT_INCOMPATIBLE
	. = ..()

/datum/component/rot/corpse/process()
	if(HAS_TRAIT(parent, TRAIT_STASIS) || HAS_TRAIT(parent, TRAIT_NO_ROT))
		return
	var/time_elapsed = last_process ? (world.time - last_process)/10 : 1
	..()
	if(has_world_trait(/datum/world_trait/pestra_mercy))
		amount -= (is_ascendant(PESTRA) ? 2.5 : 5) * time_elapsed

	var/mob/living/carbon/C = parent
	var/is_zombie
	if(C.mind)
		if(C.mind.has_antag_datum(/datum/antagonist/zombie))
			is_zombie = TRUE
	if(!is_zombie)
		if(C.stat != DEAD)
			qdel(src)
			return
	if(!(C.mob_biotypes & (MOB_ORGANIC|MOB_UNDEAD)))
		qdel(src)
		return
	if(!is_zombie && try_wither()) //RMH EDITED
		return
	var/player_body = C.is_player_character()
	var/limb_rot_time = player_body ? 90 MINUTES : 25 MINUTES
	var/skeletonize_time = player_body ? 180 MINUTES : 45 MINUTES
	if(amount > 2 MINUTES)
		if(is_zombie)
			var/datum/antagonist/zombie/Z = C.mind.has_antag_datum(/datum/antagonist/zombie)
			if(Z && !Z.has_turned && !Z.revived && C.stat == DEAD)
				if(istype(C.loc, /obj/structure/closet/dirthole) || istype(C.loc, /obj/structure/closet/crate/coffin))
					if(amount > 3 MINUTES)
						Z.wake_zombie()
				else
					Z.wake_zombie()

	var/findonerotten = FALSE
	var/shouldupdate = FALSE
	for(var/obj/item/bodypart/B in C.bodyparts)
		if(!B.skeletonized && B.is_organic_limb())
			if(!HAS_TRAIT(B, TRAIT_ROTTEN))
				if(amount > limb_rot_time)
					B.kill_limb()
					findonerotten = TRUE
					shouldupdate = TRUE
					C.change_stat(STAT_CONSTITUTION, -8)
			else
				if(amount > skeletonize_time)
					if(!is_zombie)
						B.skeletonize()
						if(C.dna && C.dna.species)
							C.dna.species.species_traits |= NOBLOOD
						C.change_stat(STAT_CONSTITUTION, -99)
						shouldupdate = TRUE
				else
					findonerotten = TRUE
	if(findonerotten)
		var/turf/open/T = C.loc
		var/is_matthios = FALSE
		if(C.has_faction(FACTION_MATTHIOS))
			is_matthios = TRUE
		if(istype(T) && amount < 16 MINUTES && !is_matthios)
			T.pollute_turf(/datum/pollutant/rot, 9)
	if(shouldupdate)
		if(findonerotten)
			if(ishuman(C))
				var/mob/living/carbon/human/H = C
				H.skin_tone = "878f79" //elf ears
		C.update_body()

/datum/component/rot/simple
	rot_amount_per_process = 5
	wither_time = 20 MINUTES //RMH EDITED

/datum/component/rot/simple/process()
	if(HAS_TRAIT(parent, TRAIT_STASIS) || HAS_TRAIT(parent, TRAIT_NO_ROT))
		return
	..()
	var/mob/living/L = parent
	var/datum/component/rot/R = src
	if(L.stat != DEAD)
		qdel(R)
		return
	if(amount > 10 MINUTES)
		var/turf/open/T = get_turf(L)
		var/is_matthios = FALSE
		if(L.has_faction(FACTION_MATTHIOS))
			is_matthios = TRUE
		if(istype(T)  && amount < 16 MINUTES && !is_matthios)
			T.pollute_turf(/datum/pollutant/rot, 9)
	try_wither() //RMH EDITED

/datum/component/rot/gibs
	amount = 0.005

/datum/component/rot/stinky_person
	var/static/list/clean_moodlets = list(/datum/stress_event/clean, /datum/stress_event/clean_plus)

/datum/component/rot/stinky_person/process()
	if(HAS_TRAIT(parent, TRAIT_STASIS) || HAS_TRAIT(parent, TRAIT_NO_ROT))
		return
	..()
	var/mob/living/L = parent
	var/turf/open/T = L.loc
	if(istype(T))
		if(iscarbon(L))
			var/mob/living/carbon/stinky = L
			for(clean_moodlets in stinky.get_positive_stressors())
				return
		T.pollute_turf(/datum/pollutant/rot, 0.25)
