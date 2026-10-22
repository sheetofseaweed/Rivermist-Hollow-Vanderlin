/datum/action/cooldown/spell/projectile/falcon_disrupt
	name = "Wings of Silvanus"
	desc = "Summons a falcon that could deliver small items and act as a distraction. The minor form sends one light swoop."
	button_icon_state = "verd"
	sound = 'sound/vo/mobs/bird/birdfly.ogg'
	invocation = "The Treefather commands thee, TO FLY!"
	invocation_type = INVOCATION_SHOUT
	spell_type = SPELL_MIRACLE
	antimagic_flags = MAGIC_RESISTANCE_HOLY
	associated_skill = /datum/attribute/skill/magic/holy
	charge_time = 1 SECONDS
	charge_drain = 1
	charge_slowdown = 0.7
	cooldown_time = 50 SECONDS
	spell_cost = 20

	required_form = FORM_LIFE
	required_technique = TECHNIQUE_DESTRUCTION
	slot_level = 1
	minor_cost = SPELL_MINOR_COST_DEFAULT
	projectile_type = /obj/projectile/magic/falcon_dive

/// Minor sends one swoop at cantrip strength; slot casts keep the full raking dive.
/datum/action/cooldown/spell/projectile/falcon_disrupt/ready_projectile(obj/projectile/to_fire, atom/target, mob/user, iteration)
	. = ..()
	var/obj/projectile/magic/falcon_dive/dive = to_fire
	if(!istype(dive))
		return
	if(is_minor_cast())
		dive.swoop_cycles = 1
		dive.strike_damage = round(5 * get_cantrip_multiplier())

/datum/action/cooldown/spell/projectile/falcon_disrupt/cast(atom/cast_on)
	var/obj/item/send_item

	if(istype(cast_on, /obj/item))
		var/obj/item/I = cast_on
		if(istype(I, /obj/item/paper) || I.w_class == WEIGHT_CLASS_TINY || I.w_class == WEIGHT_CLASS_SMALL)
			if(get_dist(owner, I) > 1)
				to_chat(owner, span_warning("The falcon reacts, but you are too far away from [I.name]."))
				reset_spell_cooldown()
				return . | SPELL_CANCEL_CAST
			send_item = I

	if(!send_item)
		return ..()

	if(!length(owner.mind?.relations))
		to_chat(owner, span_warning("The falcon is confused... You know no one to send this item to."))
		return FALSE
	var/recipient = browser_input_text(owner, "Whose name shall the falcon seek?", "THE WINGS")
	if(!recipient)
		return FALSE
	var/mob/target
	if(!owner.mind?.do_i_know(name = recipient))
		to_chat(owner, span_warning("The falcon is confused... You know no one by that name."))
		return FALSE
	for(var/client/C in GLOB.clients)
		if(names_match(C.mob?.real_name, recipient))
			target = C.mob
			break
	if(!target)
		to_chat(owner, span_warning("The falcon cannot find [recipient]."))
		return FALSE

	var/turf/T = get_turf(target)
	send_item.forceMove(owner.loc)
	new /obj/effect/falcon_messenger(owner.loc, send_item, T, target)

	to_chat(owner, span_notice("The falcon's wings unfurl, and it takes flight with your [send_item.name]."))
	playsound(owner, 'sound/vo/mobs/bird/birdfly.ogg', 100, TRUE, -1)

/obj/effect/falcon_messenger
	name = "messenger falcon"
	desc = "A falcon sent to deliver an item."
	icon = 'icons/effects/effects.dmi'
	icon_state = "falconing"
	layer = ABOVE_NORMAL_TURF_LAYER

	var/obj/item/send_item
	var/turf/target_turf
	var/mob/living/recipient

/obj/effect/falcon_messenger/Initialize(mapload, obj/item/I, turf/T, mob/living/R)
	. = ..()
	send_item = I
	target_turf = T
	recipient = R
	addtimer(CALLBACK(src, PROC_REF(do_delivery)), 0)

/obj/effect/falcon_messenger/proc/do_delivery()
	if(!target_turf)
		qdel(src)
		return

	forceMove(target_turf)
	pixel_x = -32
	pixel_y = 24
	alpha = 255

	if(recipient && !QDELETED(recipient))
		recipient.Immobilize(1 SECONDS)

	var/matrix/diveTilt = matrix().Turn(40)
	var/matrix/climbTilt = matrix().Turn(-25)

	animate(src, time = 12, pixel_x = 0, pixel_y = -16, transform = diveTilt, easing = CUBIC_EASING | EASE_IN)
	animate(src, time = 18, pixel_x = 32, pixel_y = 24, transform = climbTilt, alpha = 0, easing = CUBIC_EASING | EASE_OUT)

	playsound(src, 'sound/vo/mobs/bird/birdfly.ogg', 30, TRUE, -1)

	addtimer(CALLBACK(src, PROC_REF(drop_item)), 1.2 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(cleanup)), 2 SECONDS)

/obj/effect/falcon_messenger/proc/drop_item()
	if(send_item && !QDELETED(send_item))
		send_item.forceMove(target_turf)
		for(var/mob/M in target_turf)
			to_chat(M, span_nicegreen("A falcon swoops low and drops [send_item.name] before you!"))

/obj/effect/falcon_messenger/proc/cleanup()
	qdel(src)

/obj/projectile/magic/falcon_dive
	name = "diving falcon"
	desc = "A falcon on its diving formation."
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "falcon_projectile"
	nodamage = TRUE
	range = 8
	speed = 0.5
	/// Swoops and claw damage the strike carries; the Minor form sends one light swoop.
	var/swoop_cycles = 2
	var/strike_damage = 10

/obj/projectile/magic/falcon_dive/on_hit(atom/target, blocked = FALSE)
	if(isliving(target))
		var/mob/living/L = target
		L.apply_status_effect(/datum/status_effect/debuff/falcon_strike, null, swoop_cycles, strike_damage)
	qdel(src)

/obj/effect/falcon_strike_fx
	name = "falcon strike"
	desc = "A falcon swoops in, raking with its claws."
	icon = 'icons/effects/effects.dmi'
	icon_state = "falconing"
	layer = ABOVE_MOB_LAYER
	plane = GAME_PLANE_UPPER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

	var/mob/living/owner_mob
	var/cycle_count = 0
	var/max_cycles = 2
	var/strike_damage = 10

/obj/effect/falcon_strike_fx/Initialize(mapload, mob/living/L, cycles = 2, damage = 10)
	. = ..()
	owner_mob = L
	max_cycles = cycles
	strike_damage = damage
	if(L)
		forceMove(get_turf(L))
		addtimer(CALLBACK(src, PROC_REF(do_swoop)), 0)

/obj/effect/falcon_strike_fx/proc/do_swoop()
	if(QDELETED(src) || !owner_mob)
		return

	var/matrix/tiltLeft = matrix().Turn(-20)
	var/matrix/tiltRight = matrix().Turn(25)
	var/matrix/flipRight = matrix().Scale(-1, 1)
	var/matrix/neutral = matrix()

	if(cycle_count % 2 == 0)
		pixel_x = -12
		pixel_y = 12
		alpha = 255
		animate(src, time = 5, pixel_x = -4, pixel_y = 28, transform = tiltLeft, alpha = 200, easing = CUBIC_EASING | EASE_OUT)
		animate(time = 5, pixel_x = 0, pixel_y = 12, transform = neutral, alpha = 0, easing = CUBIC_EASING | EASE_IN)
	else
		pixel_x = 12
		pixel_y = 12
		alpha = 255
		transform = flipRight
		animate(src, time = 5, pixel_x = 4, pixel_y = -4, transform = tiltRight, alpha = 200, easing = CUBIC_EASING | EASE_IN)
		animate(time = 5, pixel_x = 0, pixel_y = 12, transform = neutral, alpha = 0, easing = CUBIC_EASING | EASE_OUT)

	addtimer(CALLBACK(src, PROC_REF(do_strike)), 0.5 SECONDS)

	cycle_count++
	if(cycle_count < max_cycles * 2)
		addtimer(CALLBACK(src, PROC_REF(do_swoop)), 1 SECONDS)
	else
		qdel(src)

/obj/effect/falcon_strike_fx/proc/do_strike()
	if(!QDELETED(owner_mob))
		if(iscarbon(owner_mob))
			var/mob/living/carbon/carbon = owner_mob
			var/obj/item/bodypart/head = carbon.get_bodypart(BODY_ZONE_HEAD)
			head?.bodypart_attacked_by(BCLASS_CUT, strike_damage)
		else
			owner_mob.adjustBruteLoss(strike_damage, damage_type = BCLASS_CUT)
		owner_mob.adjust_temp_blindness(0.4 SECONDS)
		owner_mob.adjust_jitter(2 SECONDS)
		to_chat(owner_mob, span_danger("the falcon scratches your face!"))
		playsound(src, 'sound/vo/mobs/bird/CROW_02.ogg', 70, TRUE)

/datum/status_effect/debuff/falcon_strike
	id = "falcon_strike"
	duration = 3 SECONDS
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/falcon_strike
	var/obj/effect/falcon_strike_fx/falcon_fx
	var/swoop_cycles = 2
	var/strike_damage = 10

/datum/status_effect/debuff/falcon_strike/on_creation(mob/living/new_owner, duration_override, cycles = 2, damage = 10)
	swoop_cycles = cycles
	strike_damage = damage
	return ..()

/datum/status_effect/debuff/falcon_strike/on_apply()
	. = ..()
	if(!.)
		return
	var/mob/living/L = owner
	if(!L)
		return
	falcon_fx = new /obj/effect/falcon_strike_fx(get_turf(L), L, swoop_cycles, strike_damage)
	L.adjust_eye_blur(swoop_cycles * 4 SECONDS)
	L.Immobilize(swoop_cycles * 1 SECONDS)
	return TRUE

/datum/status_effect/debuff/falcon_strike/on_remove()
	if(QDELETED(falcon_fx))
		qdel(falcon_fx)
	return ..()

/atom/movable/screen/alert/status_effect/falcon_strike
	name = "Falcon Strike"
	desc = ""
	icon_state = "blind"

