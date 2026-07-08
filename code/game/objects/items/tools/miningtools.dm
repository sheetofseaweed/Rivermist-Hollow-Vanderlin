/datum/intent/tunneldown
	name = "tunnel down"
	icon_state = "inpick"
	chargetime = 0
	noaa = TRUE
	candodge = FALSE
	misscost = 10
	no_attack = TRUE
	item_damage_type = "blunt"

/datum/intent/tunnelup
	name = "tunnel up"
	icon_state = "inpick"
	chargetime = 0
	noaa = TRUE
	candodge = FALSE
	misscost = 10
	no_attack = TRUE
	item_damage_type = "blunt"

/obj/item/weapon/pick
	item_weight = 1.74 KILOGRAMS
	force = DAMAGE_PICK
	possible_item_intents = list(PICK_INTENT, PICK_TUNNEL_DOWN, PICK_TUNNEL_UP)
	name = "pick"
	desc = ""
	icon_state = "pick"
	icon = 'icons/roguetown/weapons/tools.dmi'
	mob_overlay_icon = 'icons/roguetown/onmob/onmob.dmi'
	experimental_onhip = FALSE
	experimental_onback = FALSE
	sharpness = IS_BLUNT
	wlength = 10
	slot_flags = ITEM_SLOT_HIP
	toolspeed = 2
	associated_skill = /datum/attribute/skill/labor/mining
	melting_material = /datum/material/iron
	melt_amount = 75
	pickmult = 1 // Multiplier of how much extra picking force we do to rocks.

/obj/item/weapon/pick/getonmobprop(tag)
	. = ..()
	if(tag)
		switch(tag)
			if("gen")
				return list("shrink" = 0.7,"sx" = -10,"sy" = 0,"nx" = 11,"ny" = 0,"wx" = -8,"wy" = 1,"ex" = 4,"ey" = 0,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0,"nturn" = 0,"sturn" = 0,"wturn" = 0,"eturn" = 0,"nflip" = 0,"sflip" = 8,"wflip" = 8,"eflip" = 0)
			if("onbelt")
				return list("shrink" = 0.3,"sx" = -2,"sy" = -5,"nx" = 4,"ny" = -5,"wx" = 0,"wy" = -5,"ex" = 2,"ey" = -5,"nturn" = 0,"sturn" = 0,"wturn" = 0,"eturn" = 0,"nflip" = 0,"sflip" = 0,"wflip" = 0,"eflip" = 0,"northabove" = 0,"southabove" = 1,"eastabove" = 1,"westabove" = 0)

/proc/is_excavatable_floor(turf/T)
	return istype(T, /turf/open/floor/naturalstone) || istype(T, /turf/open/floor/dirt)

/obj/item/weapon/pick/attack_atom(atom/attacked_atom, mob/living/user)
	if(user.used_intent.type == PICK_TUNNEL_DOWN)
		user.changeNext_move(CLICK_CD_MELEE)
		if(isturf(attacked_atom))
			try_dig_down(attacked_atom, user)
		return TRUE
	if(user.used_intent.type == PICK_TUNNEL_UP)
		user.changeNext_move(CLICK_CD_MELEE)
		try_dig_up(user)
		return TRUE
	return ..()

/obj/item/weapon/pick/proc/can_dig_down(turf/target, mob/living/user)
	if(!is_excavatable_floor(target))
		to_chat(user, span_warning("I can't tunnel through that."))
		return FALSE
	if(locate(/obj/structure/closet/dirthole) in target)
		to_chat(user, span_warning("There's a hole in the way already."))
		return FALSE
	var/turf/below = GET_TURF_BELOW(target)
	if(!below)
		to_chat(user, span_warning("The ground below is solid beyond digging."))
		return FALSE
	if(istype(below, /turf/closed/mineral/bedrock))
		to_chat(user, span_warning("Whatever lies beneath is far too sturdy to break."))
		return FALSE
	var/area/below_area = get_area(below)
	if(below_area?.ceiling_protected)
		to_chat(user, span_warning("I think that's deep enough."))
		return FALSE
	if(isclosedturf(below) && !ismineralturf(below))
		to_chat(user, span_warning("There's worked stone beneath — too sturdy to break through."))
		return FALSE
	return TRUE

/obj/item/weapon/pick/proc/can_dig_up(mob/living/user)
	var/turf/above = GET_TURF_ABOVE(get_turf(user))
	if(!above)
		to_chat(user, span_warning("There's nothing above to dig into."))
		return FALSE
	if(istype(above, /turf/open/openspace))
		to_chat(user, span_warning("The way up is already open."))
		return FALSE
	if(istype(above, /turf/open/water))
		to_chat(user, span_warning("Water seeps through the ceiling. Digging here would drown me."))
		return FALSE
	if(istype(above, /turf/closed/mineral/bedrock))
		to_chat(user, span_warning("The ceiling is far too sturdy to break."))
		return FALSE
	var/area/above_area = get_area(above)
	if(above_area?.ceiling_protected)
		to_chat(user, span_warning("The ceiling here won't give, no matter how hard I swing."))
		return FALSE
	if(ismineralturf(above))
		return TRUE
	if(isclosedturf(above))
		to_chat(user, span_warning("There's worked stone above — too sturdy to break through."))
		return FALSE
	if(!is_excavatable_floor(above))
		to_chat(user, span_warning("I can't tunnel through that."))
		return FALSE
	return TRUE

/obj/item/weapon/pick/proc/try_dig_down(turf/target, mob/living/user)
	if(!can_dig_down(target, user))
		return
	dig_swing(target, user, DOWN)

/obj/item/weapon/pick/proc/try_dig_up(mob/living/user)
	if(!can_dig_up(user))
		return
	dig_swing(GET_TURF_ABOVE(get_turf(user)), user, UP)

/obj/item/weapon/pick/proc/dig_swing(turf/victim, mob/living/user, direction)
	if(!user.check_stamina(15))
		to_chat(user, span_warning("I'm too tired to swing."))
		return
	var/mineskill = GET_MOB_SKILL_VALUE_OLD(user, /datum/attribute/skill/labor/mining)
	var/swing_force = force * (8 + (mineskill * 1.5)) * pickmult
	playsound(victim, pick(list('sound/combat/hits/onrock/onrock (1).ogg', 'sound/combat/hits/onrock/onrock (2).ogg', 'sound/combat/hits/onrock/onrock (3).ogg', 'sound/combat/hits/onrock/onrock (4).ogg')), 100, TRUE)
	user.adjust_stamina(max(30 - (mineskill * 2), 10))
	user.adjust_experience(/datum/attribute/skill/labor/mining, GET_MOB_ATTRIBUTE_VALUE(user, STAT_INTELLIGENCE) * 0.2)
	if(direction == UP)
		if(prob(25))
			new /obj/item/natural/stone(get_turf(user))
		if(prob(10))
			user.apply_damage(rand(4, 8), BRUTE, BODY_ZONE_HEAD, damage_type = BCLASS_BLUNT)
			to_chat(user, span_warning("Debris rains down on my head!"))
	if(victim.get_integrity() <= swing_force)
		if(direction == DOWN)
			breakthrough_down(victim, user)
		else
			breakthrough_up(victim, user)
	else
		victim.take_damage(swing_force, BRUTE, "blunt", FALSE)

/obj/item/weapon/pick/proc/breakthrough_down(turf/target, mob/living/user)
	var/turf/below = GET_TURF_BELOW(target)
	if(ismineralturf(below))
		var/turf/closed/mineral/M = below
		M.gets_drilled(user)
		below = GET_TURF_BELOW(target)
	playsound(target, 'sound/combat/hits/onstone/stonedeath.ogg', 100, TRUE)
	user.visible_message(span_warning("[user] breaks through the ground!"), \
		span_warning("I break through the ground!"))
	if(below && isopenturf(below))
		new /obj/item/natural/stone(below)
	target.ChangeTurf(/turf/open/openspace, flags = CHANGETURF_INHERIT_AIR)
	if(below && isopenturf(below) && !(locate(/obj/structure/climbable_ledge) in below))
		new /obj/structure/climbable_ledge(below)

/obj/item/weapon/pick/proc/breakthrough_up(turf/victim, mob/living/user)
	if(ismineralturf(victim))
		var/turf/closed/mineral/M = victim
		M.gets_drilled(user)
		playsound(get_turf(user), 'sound/combat/hits/onstone/stonedeath.ogg', 100, TRUE)
		to_chat(user, span_notice("The rock above shatters into a workable layer — the ceiling still holds."))
		return
	playsound(get_turf(user), 'sound/combat/hits/onstone/stonedeath.ogg', 100, TRUE)
	user.visible_message(span_warning("[user] breaks through the ceiling!"), \
		span_warning("I break through the ceiling!"))
	victim.ChangeTurf(/turf/open/openspace, flags = CHANGETURF_INHERIT_AIR)
	var/turf/user_turf = get_turf(user)
	new /obj/item/natural/stone(user_turf)
	if(prob(50))
		new /obj/item/natural/stone(user_turf)
	if(!(locate(/obj/structure/climbable_ledge) in user_turf))
		new /obj/structure/climbable_ledge(user_turf)

/obj/item/weapon/pick/copper
	item_weight = 1.35 KILOGRAMS
	name = "copper pick"
	desc = ""
	icon_state = "cpick"
	icon = 'icons/roguetown/weapons/tools.dmi'
	force = DAMAGE_PICK - 3
	toolspeed = 3
	pickmult = 0.8 // Worse pick
	associated_skill = /datum/attribute/skill/combat/axesmaces
	melting_material = /datum/material/copper
	melt_amount = 75

/obj/item/weapon/pick/steel
	name = "steel pick"
	desc = "With a reinforced handle and sturdy shaft, this is a superior tool for delving in the darkness."
	icon_state = "steelpick"
	force = DAMAGE_PICK + 3
	gripped_intents = list(PICK_INTENT)
	max_integrity = INTEGRITY_STRONGEST + 100
	melting_material = /datum/material/steel
	melt_amount = 75
	pickmult = 1.2

/obj/item/weapon/pick/stone
	item_weight = 1.2 KILOGRAMS
	name = "stone pick"
	desc = "Stone versus sharp stone, who wins?"
	icon_state = "stonepick"
	force = DAMAGE_PICK - 6
	gripped_intents = list(PICK_INTENT)
	max_integrity = INTEGRITY_STANDARD + 50
	anvilrepair = null
	melting_material = null
	pickmult = 0.7 // Worse pick

/obj/item/weapon/pick/drill
	item_weight = 3.29 KILOGRAMS
	name = "clockwork drill"
	desc = "A wonderfully complex work of engineering capable of shredding walls in seconds as opposed to hours."
	force_wielded = DAMAGE_HEAVYCLUB_WIELD
	icon_state = "drill"
	lefthand_file = 'icons/mob/inhands/weapons/hammers_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/hammers_righthand.dmi'
	item_state = "drill"
	possible_item_intents = list(MACE_SMASH, PICK_TUNNEL_DOWN, PICK_TUNNEL_UP)
	gripped_intents = list(/datum/intent/drill)
	experimental_inhand = FALSE
	experimental_onback = FALSE
	slot_flags = ITEM_SLOT_BACK
	gripspriteonmob = TRUE
	melting_material = /datum/material/steel
	melt_amount = 150
	pickmult = 1.5

/obj/item/weapon/pick/drill/Initialize()
	. = ..()
	START_PROCESSING(SSobj, src)
	AddComponent(/datum/component/steam_storage, 300, 0)
	RegisterSignal(src, COMSIG_TWOHANDED_WIELD, PROC_REF(pre_wield_check))

/obj/item/weapon/pick/drill/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/weapon/pick/drill/afterattack(atom/target, mob/living/user, proximity_flag, list/modifiers)
	. = ..()
	SEND_SIGNAL(src, COMSIG_ATOM_STEAM_USE, 5)

/obj/item/weapon/pick/drill/proc/pre_wield_check(datum/source, mob/living/carbon/user)
	if(!SEND_SIGNAL(src, COMSIG_ATOM_STEAM_USE, 1))
		to_chat(user, span_warning("[src] doesn't have enough power to be wielded!"))
		return COMPONENT_TWOHANDED_BLOCK_WIELD

/obj/item/weapon/pick/drill/process()
	if(HAS_TRAIT(src, TRAIT_WIELDED))
		if(!SEND_SIGNAL(src, COMSIG_ATOM_STEAM_USE, 1))
			var/datum/component/two_handed/twohanded = GetComponent(/datum/component/two_handed)
			if(ismob(loc))
				twohanded.unwield(loc)
