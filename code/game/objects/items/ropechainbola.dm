
/obj/item/rope
	item_weight = 300 GRAMS
	name = "rope"
	desc = "A series of threads intertwined to create a firm rope for binding, hanging and other jobs."
	gender = PLURAL
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state = "rope"
	grid_width = 32
	grid_height = 32
	slot_flags = ITEM_SLOT_HIP|ITEM_SLOT_WRISTS|ITEM_SLOT_NECK|ITEM_SLOT_BELT
	throwforce = 3
	w_class = WEIGHT_CLASS_SMALL
	throw_speed = 1
	throw_range = 5
	breakouttime = 10 SECONDS
	slipouttime = 30 SECONDS
	possible_item_intents = list(/datum/intent/tie)
	firefuel = 5 MINUTES
	drop_sound = 'sound/foley/dropsound/cloth_drop.ogg'

	var/legcuff_multiplicative_slowdown = 3
	var/cuffing_time = 6 SECONDS

/obj/item/rope/spider_silk
	name = "spider silk"
	desc = "A tacky coil of fresh spider silk, spun thick enough to bind wrists."
	icon = 'icons/roguetown/misc/webbing.dmi'
	icon_state = "stickyweb3"
	breakouttime = 12 SECONDS
	slipouttime = 36 SECONDS

/obj/item/rope/mob_can_equip(mob/living/M, mob/living/equipper, slot, disable_warning, bypass_equip_delay_self)
	. = ..()
	if(.)
		if((slot & ITEM_SLOT_BELT) && !equipper)
			if(!do_after(M, 1.5 SECONDS, src))
				return FALSE

/obj/item/rope/equipped(mob/living/carbon/human/user, slot)
	. = ..()
	if(slot & ITEM_SLOT_BELT)
		user.temporarilyRemoveItemFromInventory(src)
		user.equip_to_slot_if_possible(new /obj/item/storage/belt/leather/rope(get_turf(user)), ITEM_SLOT_BELT)
		qdel(src)

/datum/intent/tie
	name = "tie"
	icon_state = "intie"
	chargetime = 0
	noaa = TRUE
	candodge = FALSE
	canparry = FALSE
	misscost = 0

/obj/item/rope/Destroy()
	if(iscarbon(loc))
		var/mob/living/carbon/M = loc
		if(M.handcuffed == src)
			M.set_handcuffed(null)
			M.update_handcuffed()
			if(M.buckled && M.buckled.buckle_requires_restraints)
				M.buckled.unbuckle_mob(M)
		if(M.legcuffed == src)
			M.legcuffed = null
			M.update_inv_legcuffed()
			M.remove_movespeed_modifier(MOVESPEED_ID_LEGCUFF_SLOWDOWN, TRUE)
	return ..()

/obj/item/rope/attack(mob/living/carbon/C, mob/living/user, list/modifiers)
	if(user.used_intent.type != /datum/intent/tie)
		..()
		return

	if(!istype(C))
		return

	var/surrender_mod = 1
	if(C.surrendering || HAS_TRAIT(C, TRAIT_BAGGED))
		surrender_mod = 0.5

	if(user.aimheight >= 5)
		if(!C.handcuffed)
			if(C.num_hands)
				C.visible_message(span_warning("[user] is trying to tie [C]'s arms with [src.name]!"), span_danger("[user] is trying to tie my arms with [src.name]!"))

				if(do_after(user, cuffing_time * surrender_mod, C) && C.num_hands)
					if(apply_cuffs(C, user, leg = FALSE))
						C.visible_message(span_warning("[user] ties [C]' arms with [src.name]."), span_danger("[user] ties my arms up with [src.name]."))
						SSblackbox.record_feedback("tally", "handcuffs", 1, type)
						user.adjust_experience(/datum/attribute/skill/craft/traps, GET_MOB_ATTRIBUTE_VALUE(C, STAT_INTELLIGENCE), FALSE)
						log_combat(user, C, "handcuffed")
				else
					to_chat(user, span_warning("I fail to tie up [C]'s arms!"))
			else
				to_chat(user, span_warning("[C] is missing two or one arms."))
	else
		if(!C.legcuffed)
			if(C.num_legs)
				C.visible_message(span_warning("[user] is trying to tie [C]'s legs with [src.name]!"), span_danger("[user] is trying to tie my legs with [src.name]!"))

				if(do_after(user, cuffing_time * (C.surrendering ? 0.5 : 1), C) && C.num_legs)
					if(apply_cuffs(C, user, leg = TRUE))
						C.visible_message(span_warning("[user] ties [C]' legs with [src.name]."), span_danger("[user] ties my legs up with [src.name]."))
						SSblackbox.record_feedback("tally", "legcuffs", 1, type)
						user.adjust_experience(/datum/attribute/skill/craft/traps, GET_MOB_ATTRIBUTE_VALUE(C, STAT_INTELLIGENCE), FALSE)
						log_combat(user, C, "legcuffed")
				else
					to_chat(user, span_warning("I fail to tie up [C]'s legs!"))
			else
				to_chat(user, span_warning("[C] is missing two or one legs."))

/obj/item/rope/proc/apply_cuffs(mob/living/carbon/target, mob/user, leg = FALSE)
	if(!leg)
		if(target.handcuffed)
			return

		if(user && !user.temporarilyRemoveItemFromInventory(src) )
			return

		var/obj/item/cuffs = src

		cuffs.forceMove(target)
		target.set_handcuffed(cuffs)

		target.update_handcuffed()
		return TRUE
	else
		if(target.legcuffed)
			return FALSE

		if(user && !user.temporarilyRemoveItemFromInventory(src))
			return

	var/obj/item/cuffs = src

	cuffs.forceMove(target)
	if(leg)
		target.legcuffed = cuffs
		target.add_movespeed_modifier(MOVESPEED_ID_LEGCUFF_SLOWDOWN, multiplicative_slowdown = legcuff_multiplicative_slowdown)
		target.update_inv_legcuffed()
		return TRUE

/obj/item/rope/chain
	item_weight = 1.2 KILOGRAMS
	name = "chain"
	desc = "Metal chains designed to interlock and apply the harshest confinement on the villainous."
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state = "chain"
	grid_width = 32
	grid_height = 32
	slot_flags = ITEM_SLOT_HIP|ITEM_SLOT_WRISTS
	force = DAMAGE_WHIP - 10
	throwforce = DAMAGE_WHIP - 15
	wdefense = MEDIOCRE_PARRY
	possible_item_intents = list(/datum/intent/tie, WHIP_LASH)
	blade_dulling = DULLING_BASHCHOP
	slot_flags = ITEM_SLOT_HIP|ITEM_SLOT_WRISTS
	parrysound = list('sound/combat/parry/parrygen.ogg')
	swingsound = WHIPWOOSH
	w_class = WEIGHT_CLASS_SMALL
	associated_skill = /datum/attribute/skill/combat/whipsflails
	throw_speed = 1
	throw_range = 3
	breakouttime = 30 SECONDS
	slipouttime = 1 MINUTES
	melting_material = /datum/material/iron
	melt_amount = 40
	firefuel = null
	drop_sound = 'sound/foley/dropsound/chain_drop.ogg'
	cuffing_time = 7 SECONDS

/obj/item/rope/chain/steel
	item_weight = 1.1 KILOGRAMS
	name = "Steel chain"
	desc = "Metal chains designed to interlock and apply the harshest confinement on the villainous."
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state = "steelchain"
	grid_width = 32
	grid_height = 32
	slot_flags = ITEM_SLOT_HIP|ITEM_SLOT_WRISTS
	force = DAMAGE_WHIP - 25
	throwforce = DAMAGE_WHIP - 20
	wdefense = MEDIOCRE_PARRY
	possible_item_intents = list(/datum/intent/tie, WHIP_LASH)
	blade_dulling = DULLING_BASHCHOP
	slot_flags = ITEM_SLOT_HIP|ITEM_SLOT_WRISTS
	parrysound = list('sound/combat/parry/parrygen.ogg')
	swingsound = WHIPWOOSH
	w_class = WEIGHT_CLASS_SMALL
	associated_skill = /datum/attribute/skill/combat/whipsflails
	throw_speed = 1
	throw_range = 3
	breakouttime = 50 SECONDS
	slipouttime = 1 MINUTES
	melting_material = /datum/material/steel
	melt_amount = 40
	firefuel = null
	drop_sound = 'sound/foley/dropsound/chain_drop.ogg'
	cuffing_time = 8 SECONDS

/obj/item/rope/chain/gold
	item_weight = 1.6 KILOGRAMS
	name = "Gold chain"
	desc = "Metal chains designed to interlock and apply the harshest confinement on the villainous."
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state = "goldchain"
	grid_width = 32
	grid_height = 32
	slot_flags = ITEM_SLOT_HIP|ITEM_SLOT_WRISTS
	force = DAMAGE_WHIP - 25
	throwforce = DAMAGE_WHIP - 20
	wdefense = MEDIOCRE_PARRY
	possible_item_intents = list(/datum/intent/tie, WHIP_LASH)
	blade_dulling = DULLING_BASHCHOP
	slot_flags = ITEM_SLOT_HIP|ITEM_SLOT_WRISTS
	parrysound = list('sound/combat/parry/parrygen.ogg')
	swingsound = WHIPWOOSH
	w_class = WEIGHT_CLASS_SMALL
	associated_skill = /datum/attribute/skill/combat/whipsflails
	throw_speed = 1
	throw_range = 3
	breakouttime = 25 SECONDS
	slipouttime = 45 SECONDS
	melting_material = /datum/material/gold
	melt_amount = 40
	firefuel = null
	drop_sound = 'sound/foley/dropsound/chain_drop.ogg'
	cuffing_time = 5 SECONDS

/obj/item/rope/chain/silver
	item_weight = 1.1 KILOGRAMS
	name = "Silver chain"
	desc = "A heavy chain forged from silver. Those afflicted by silver's bane weaken merely from being restrained by it."
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state = "silverchain"

	force = DAMAGE_WHIP - 10
	throwforce = DAMAGE_WHIP - 15
	wdefense = MEDIOCRE_PARRY
	possible_item_intents = list(/datum/intent/tie, WHIP_LASH)
	blade_dulling = DULLING_BASHCHOP
	parrysound = list('sound/combat/parry/parrygen.ogg')
	swingsound = WHIPWOOSH
	w_class = WEIGHT_CLASS_SMALL
	associated_skill = /datum/attribute/skill/combat/whipsflails
	throw_speed = 1
	throw_range = 3
	breakouttime = 40 SECONDS
	slipouttime = 1 MINUTES
	cuffing_time = 9 SECONDS
	melting_material = /datum/material/silver
	melt_amount = 40
	firefuel = null
	drop_sound = 'sound/foley/dropsound/chain_drop.ogg'

/obj/item/rope/chain/silver/proc/get_silver_bane_modifier_id()
	return "silver_chain_[REF(src)]"

/obj/item/rope/chain/silver/proc/apply_silver_bane(mob/living/carbon/target)
	if(!target)
		return

	// Silver itself carries the silver_bane material trait.
	if(!(/datum/material_trait/silver_bane in initial(melting_material.traits)))
		return

	target.set_stat_modifier(
		get_silver_bane_modifier_id(),
		list(
			STAT_STRENGTH = -2,
			STAT_PERCEPTION = -2,
			STAT_ENDURANCE = -2,
			STAT_SPEED = -2,
		))

/obj/item/rope/chain/silver/proc/remove_silver_bane(mob/living/carbon/target)
	if(!target)
		return

	target.remove_stat_modifier(get_silver_bane_modifier_id())

/obj/item/rope/chain/silver/apply_cuffs(mob/living/carbon/target, mob/user, leg = FALSE)
	. = ..()

	if(.)
		apply_silver_bane(target)

/obj/item/rope/chain/silver/dropped(mob/user, silent = FALSE)
	var/mob/living/carbon/target

	if(iscarbon(loc))
		target = loc
	else if(iscarbon(user))
		target = user

	if(target)
		remove_silver_bane(target)

	return ..()

/obj/item/rope/chain/silver/Destroy()
	if(iscarbon(loc))
		var/mob/living/carbon/target = loc
		remove_silver_bane(target)

	return ..()

/obj/item/rope/net
	item_weight = 500 GRAMS
	name = "rope net"
	desc = "A rope mesh of designed to slow a person down."
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state = "net"
	slot_flags = ITEM_SLOT_HIP|ITEM_SLOT_WRISTS
	w_class = WEIGHT_CLASS_SMALL
	grid_width = 64
	grid_height = 64
	icon_state = "net"
	throw_speed = 0.5
	breakouttime = 3.5 SECONDS //easy to apply, easy to break out of
	gender = NEUTER
	var/knockdown = 2 SECONDS
	legcuff_multiplicative_slowdown = 2

/obj/item/rope/net/throw_at(atom/target, range, speed, mob/thrower, spin=1, diagonals_first = 0, datum/callback/callback, force, gentle = FALSE)
	. = ..()
	if(.)
		playsound(src,'sound/combat/wooshes/flail_swing.ogg', 75, TRUE)

/obj/item/rope/net/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(..() || !iscarbon(hit_atom))//if it gets caught or the target can't be cuffed,
		return//abort
	var/mob/thrower = throwingdatum?.get_thrower()
	var/trapping_skill = istype(thrower) ? GET_MOB_SKILL_VALUE_OLD(thrower, /datum/attribute/skill/craft/traps) : 0
	if(prob(100 * (trapping_skill || 1) / 3))
		ensnare(hit_atom)

/obj/item/rope/net/proc/ensnare(mob/living/carbon/C)
	if(C.num_legs >= 2 && apply_cuffs(C, leg = TRUE))
		C.visible_message(span_danger("[src] ensnares [C]!"), span_userdanger("[src] entraps you!!"))
		SSblackbox.record_feedback("tally", "handcuffs", 1, type)
		C.apply_status_effect(/datum/status_effect/debuff/netted)
		playsound(src, 'sound/combat/hits/nodmg (2).ogg', 100, TRUE)
		if((C.m_intent = MOVE_INTENT_RUN || HAS_TRAIT(C, TRAIT_STUMBLE)) && C.body_position == STANDING_UP && C.sprinted_tiles > 0)
			C.Knockdown(knockdown)

// Failsafe in case the item somehow ends up being destroyed
/obj/item/rope/net/Destroy()
	if(iscarbon(loc))
		var/mob/living/carbon/M = loc
		if(M.legcuffed == src)
			M.remove_status_effect(/datum/status_effect/debuff/netted)
	return ..()

/obj/item/rope/net/bola
	item_weight = 800 GRAMS
	name = "bola"
	desc = "A clever but simple bundle of rope and stones used to catch criminals"
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state = "bola"
	grid_width = 64
	grid_height = 64
	throw_range = 10
	throw_speed = 1.5
	breakouttime = 6 SECONDS
	knockdown = 3 SECONDS
	legcuff_multiplicative_slowdown = 2.5


/obj/item/rope/net/bola/proc/on_bola_impact(mob/living/carbon/C, datum/thrownthing/throwingdatum)
	// Base bola has no special impact effect.
	return


/obj/item/rope/net/bola/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()

	// Anything that isn't a carbon mob is a miss.
	if(!iscarbon(hit_atom))
		qdel(src)
		return

	var/mob/living/carbon/C = hit_atom

	// Impact effects happen on actual contact, regardless of whether
	// the normal bola trapping roll succeeds.
	on_bola_impact(C, throwingdatum)

	// The bola successfully attached as a legcuff.
	if(C.legcuffed == src)
		return

	// It hit a mob, but failed to trap them.
	qdel(src)

/obj/item/rope/net/bola/electro
	name = "Shock bola"
	desc = "A reinforced bola charged with stored electricity. It releases its charge once when it strikes a living target."
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state = "shockbola"

	var/electrocuted = FALSE
	var/electrocute_damage = 20


/obj/item/rope/net/bola/electro/on_bola_impact(mob/living/carbon/C, datum/thrownthing/throwingdatum)
	if(electrocuted)
		return

	electrocuted = TRUE

	if(C.electrocute_act(electrocute_damage, src))
		C.emote("painscream")
		C.update_sneak_invis(TRUE)
		C.consider_ambush(always = TRUE)

		if(C.throwing)
			C.throwing.finalize(FALSE)

/obj/item/rope/net/bola/chain
	name = "chain bola"
	desc = "A heavy bola fashioned from short lengths of steel chain. The impact is brutal."
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state = "chainbola"
	throwforce = 10

/obj/item/rope/net/bola/chain/on_bola_impact(mob/living/carbon/C, datum/thrownthing/throwingdatum)
	var/damage = rand(20, 30)

	// Direct damage. Armor does not reduce this.
	C.adjustBruteLoss(damage)

	C.visible_message(span_danger("[src] slams violently into [C]!"), span_userdanger("The chain bola slams into me!"))

/obj/item/rope/net/bola/thaum
	name = "thaumaturgic bola"
	desc = "A mystically charged bola that tears arcane energy from whoever it catches."
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state = "thaumicbola"

/obj/item/rope/net/bola/thaum/on_bola_impact(mob/living/carbon/C, datum/thrownthing/throwingdatum)
	for(var/i in 1 to 10)
		addtimer(CALLBACK(C, TYPE_PROC_REF(/mob/living, consume_mana), rand(10, 15)), i SECONDS)

	to_chat(C, span_userdanger("Arcane energy is ripped from me by the thaumaturgic bola!"))

/obj/item/rope/net/bola/silver
	name = "silver bola"
	desc = "A bola fashioned with silver weights, deadly to creatures cursed by the night."
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state = "silverbola"

/obj/item/rope/net/bola/silver/on_bola_impact(mob/living/carbon/C, datum/thrownthing/throwingdatum)
	if(!ishuman(C) || !C.mind)
		return

	var/datum/material_trait/silver_bane/bane = new
	bane.touch_bane(C)
	qdel(bane)

/obj/structure/noose
	name = "noose"
	desc = "Abandon all hope."
	icon = 'icons/roguetown/misc/tallstructure.dmi'
	SET_BASE_PIXEL(0, 10)
	icon_state = "noose"
	can_buckle = 1
	layer = 4.26
	max_integrity = 10
	buckle_lying = FALSE
	buckle_prevents_pull = TRUE
	max_buckled_mobs = 1
	anchored = TRUE
	density = FALSE
	layer = ABOVE_MOB_LAYER
	plane = GAME_PLANE_UPPER
	static_debris = list(/obj/item/rope = 1)
	breakoutextra = 10 MINUTES
	buckleverb = "tie"

/obj/structure/noose/gallows
	name = "gallows"
	desc = "Read through six lines written by the most honest man in the world, and one will find enough in them to hang him."
	icon_state = "gallows"
	SET_BASE_PIXEL(0, 0)
	max_integrity = 100

/obj/structure/noose/Destroy()
	STOP_PROCESSING(SSobj, src)
	if(has_buckled_mobs())
		for(var/mob/living/buckled_mob as anything in buckled_mobs)
			buckled_mob.visible_message("<span class='danger'>[buckled_mob] falls over and hits the ground!</span>")
			to_chat(buckled_mob, "<span class='userdanger'>You fall over and hit the ground!</span>")
			buckled_mob.adjustBruteLoss(10, damage_type = BCLASS_BLUNT)
			buckled_mob.Knockdown(60)
	return ..()

/obj/structure/noose/attackby(obj/item/W, mob/user, list/modifiers)
	if(!W.get_sharpness())
		return ..()

	if(do_after(user, 1 SECONDS, src))
		new /obj/item/rope(loc)
		playsound(src, 'sound/foley/dropsound/cloth_drop.ogg', 50, TRUE)
		if (istype(src, /obj/structure/noose/gallows))
			new /obj/machinery/light/fueled/lanternpost/unfixed(loc)
			user.visible_message(span_notice("[user] cuts the noose down from the gallows."), span_notice("I cut the noose down from the gallows."), span_hear("I hear something snap."))
		else
			user.visible_message(span_notice("[user] cuts down the noose."), span_notice("I cut down the noose."), span_hear("I hear something snap."))
		qdel(src)

/obj/structure/noose/bullet_act(obj/projectile/P, def_zone, piercing_hit = FALSE)
	. = ..()
	new /obj/item/rope(loc)
	playsound(src, 'sound/foley/dropsound/cloth_drop.ogg', 50, TRUE)
	if(istype(src, /obj/structure/noose/gallows))
		new /obj/machinery/light/fueled/lanternpost/unfixed(loc)
		visible_message(span_danger("The noose is shot down from the gallows!"))
	else
		visible_message(span_danger("The noose is shot down!"))
	qdel(src)

/obj/structure/noose/user_buckle_mob(mob/living/M, mob/user, check_loc)
	if(!in_range(user, src) || user.stat != CONSCIOUS || HAS_TRAIT(user, TRAIT_RESTRAINED) || !iscarbon(M))
		return FALSE

	if (!M.get_bodypart("head"))
		to_chat(user, "<span class='warning'>[M] has no head!</span>")
		return FALSE

	M.visible_message("<span class='danger'>[user] attempts to tie \the [src] over [M]'s neck!</span>")
	if(do_after(user, (user == M ? 0 : 5 SECONDS), M))
		if(buckle_mob(M))
			user.visible_message("<span class='warning'>[user] ties \the [src] over [M]'s neck!</span>")
			if(user == M)
				to_chat(M, "<span class='userdanger'>I tie \the [src] over my neck...</span>")
			else
				to_chat(M, "<span class='userdanger'>[user] ties \the [src] over my neck!</span>")
			playsound(user, 'sound/foley/noosed.ogg', 50, 1, -1)
			return TRUE
	user.visible_message("<span class='warning'>[user] fails to tie \the [src] over [M]'s neck!</span>")
	to_chat(user, "<span class='warning'>I fail to tie \the [src] over [M]'s neck.</span>")
	return FALSE

/obj/structure/noose/post_buckle_mob(mob/living/M)
	if(has_buckled_mobs())
		START_PROCESSING(SSobj, src)
		M.set_mob_offsets("bed_buckle", _x = 0, _y = 10)

/obj/structure/noose/gallows/post_buckle_mob(mob/living/M)
	if(has_buckled_mobs())
		START_PROCESSING(SSobj, src)
		M.set_mob_offsets("bed_buckle", _x = 6, _y = 16)

/obj/structure/noose/post_unbuckle_mob(mob/living/M)
	STOP_PROCESSING(SSobj, src)
	M.reset_offsets("bed_buckle")

/obj/structure/noose/process()
	if(!has_buckled_mobs())
		STOP_PROCESSING(SSobj, src)
		return
	for(var/mob/living/buckled_mob as anything in buckled_mobs)
		if(buckled_mob.get_bodypart("head"))
			if(buckled_mob.stat != DEAD)
				if(locate(/obj/structure/chair) in get_turf(src)) // So you can kick down the chair and make them hang, and stuff.
					return
				if(!HAS_TRAIT(buckled_mob, TRAIT_NOBREATH))
					buckled_mob.adjustOxyLoss(10)
					if(prob(20))
						buckled_mob.emote("gasp")
				if(prob(25))
					var/flavor_text = list("<span class='danger'>[buckled_mob]'s legs flail for anything to stand on.</span>",\
											"<span class='danger'>[buckled_mob]'s hands are desperately clutching the noose.</span>",\
											"<span class='danger'>[buckled_mob]'s limbs sway back and forth with diminishing strength.</span>")
					buckled_mob.visible_message(pick(flavor_text))
				playsound(buckled_mob, 'sound/foley/noose_idle.ogg', 30, 1, -3)
			else
				if(prob(1))
					var/obj/item/bodypart/head/head = buckled_mob.get_bodypart("head")
					if(head.brute_dam >= 50)
						if(head.dismemberable)
							head.dismember()
		else
			buckled_mob.visible_message("<span class='danger'>[buckled_mob] drops from the noose!</span>")
			buckled_mob.Knockdown(60)
			buckled_mob.pixel_y = buckled_mob.base_pixel_y
			buckled_mob.pixel_x = buckled_mob.base_pixel_x
			unbuckle_all_mobs(force=1)
