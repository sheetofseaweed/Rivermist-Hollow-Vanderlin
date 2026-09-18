// RMH the branding iron. Heat it in a flame, then press it onto a
// helpless or restrained target to burn permanent text into a body zone.
// Sprite reuses surgery.dmi "cauteryiron" - Twilight Axis has no branding iron
// asset, its /obj/item/branding_iron references are dangling.

/obj/item/brandingiron
	name = "branding iron"
	desc = "A crude iron rod ending in a flat plate stamped with jagged lettering. Useless until heated red hot in a flame."
	icon = 'icons/roguetown/items/surgery.dmi'
	icon_state = "cauteryiron"
	item_state = "cauteryiron"
	force = DAMAGE_MACE - 4
	throwforce = DAMAGE_MACE - 4
	w_class = WEIGHT_CLASS_NORMAL
	wbalance = EASY_TO_DODGE
	possible_item_intents = list(INTENT_USE, MACE_STRIKE)
	slot_flags = ITEM_SLOT_HIP
	sharpness = IS_BLUNT

	var/heated = FALSE
	var/cool_timer
	/// Minimum get_temperature() of a heat source needed to heat this, in Kelvin.
	var/heat_source_threshold = 100 + T0C
	var/heat_duration = 30 SECONDS
	var/brand_time = 4 SECONDS
	var/brand_damage = 8
	var/max_brand_length = 20

/obj/item/brandingiron/Destroy()
	if(cool_timer)
		deltimer(cool_timer)
		cool_timer = null
	return ..()

/obj/item/brandingiron/examine(mob/user)
	. = ..()
	if(heated)
		. += span_warning("The plate glows a dull, angry red. It's ready to use.")
	else
		. += span_notice("The plate is cold. Heat it in a flame before it will brand anything.")

/obj/item/brandingiron/update_icon_state()
	. = ..()
	icon_state = "[initial(icon_state)][heated ? "_hot" : ""]"

/obj/item/brandingiron/get_temperature()
	if(heated)
		return 150 + T0C
	return ..()

/obj/item/brandingiron/proc/heat_up()
	if(!heated)
		playsound(src, 'sound/items/firelight.ogg', 60, TRUE)
	heated = TRUE
	if(cool_timer)
		deltimer(cool_timer)
	cool_timer = addtimer(CALLBACK(src, PROC_REF(cool_down)), heat_duration, TIMER_STOPPABLE)
	update_appearance(UPDATE_ICON_STATE)

/obj/item/brandingiron/proc/cool_down()
	heated = FALSE
	cool_timer = null
	update_appearance(UPDATE_ICON_STATE)

/// Heat it in a lit forge, campfire or brazier.
/obj/item/brandingiron/pre_attack(atom/target, mob/living/user, list/modifiers)
	if(istype(user.a_intent, INTENT_USE) && istype(target, /obj/machinery/light/fueled))
		var/obj/machinery/light/fueled/flame = target
		if(flame.on)
			user.visible_message(span_info("[user] heats [src] in [flame]."))
			heat_up()
			return TRUE
	return ..()

/// Heat it with any sufficiently hot item held in hand.
/obj/item/brandingiron/attacked_by(obj/item/attacking_item, mob/living/user)
	if(attacking_item.get_temperature() >= heat_source_threshold)
		user.visible_message(span_info("[user] heats [src] with [attacking_item]."))
		heat_up()
		return TRUE
	return ..()

/obj/item/brandingiron/attack(mob/living/target, mob/living/user, list/modifiers)
	if(!iscarbon(target))
		return ..()

	if(!heated)
		to_chat(user, span_warning("[src] is cold. It needs to be heated before it will leave a mark."))
		return

	var/mob/living/carbon/patient = target

	if(!(patient.stat >= UNCONSCIOUS || patient.handcuffed || patient.buckled))
		to_chat(user, span_warning("[patient] would need to be restrained or helpless to hold still for this."))
		return

	var/target_zone = user.zone_selected
	var/obj/item/bodypart/target_limb = patient.get_bodypart(check_zone(target_zone))
	if(!target_limb)
		to_chat(user, span_warning("[patient] is missing that limb."))
		return
	if(target_limb.brand_text)
		to_chat(user, span_warning("[patient] is already branded there."))
		return

	var/chosen_text = stripped_input(user, "Что выжечь на [parse_zone(target_zone)]?", "Клеймо", "", max_length = max_brand_length)
	if(!chosen_text || !length(chosen_text))
		return
	if(!heated)
		to_chat(user, span_warning("[src] has gone cold."))
		return
	if(QDELETED(patient) || QDELETED(target_limb) || target_limb != patient.get_bodypart(target_limb.body_zone))
		return

	patient.visible_message(span_danger("[user] presses [src] against [patient]'s [parse_zone(target_zone)]!"), \
		span_userdanger("[user] presses [src] against your [parse_zone(target_zone)]!"))
	playsound(patient, 'sound/foley/burning_sacrifice.ogg', 40, TRUE)

	if(!do_after(user, brand_time, patient))
		return
	if(!heated || QDELETED(patient) || QDELETED(target_limb) || target_limb != patient.get_bodypart(target_limb.body_zone))
		to_chat(user, span_warning("The branding is interrupted."))
		return

	target_limb.brand_text = chosen_text
	target_limb.brand_zone = target_zone
	patient.apply_damage(brand_damage, BURN, target_limb.body_zone)
	patient.visible_message(span_danger("[patient]'s [parse_zone(target_zone)] sizzles as [user] brands it!"), \
		span_userdanger("Your [parse_zone(target_zone)] sizzles as [user] brands it! The mark will stay with you forever."))
	cool_down()
