// Chastity play: sex actions done to or with a worn chastity device rather than the organ it locks away.

#define CHASTITY_PART_ANY "any"
#define CHASTITY_PART_COCK "cock"
#define CHASTITY_PART_PUSSY "pussy"
#define CHASTITY_PART_REAR "rear"

/datum/sex_action/chastity
	abstract_type = /datum/sex_action/chastity
	user_menu_zone_mask = SEX_UI_ZONE_GENITALS
	target_menu_zone_mask = SEX_UI_ZONE_GENITALS
	/// Which locked part the action works; see CHASTITY_PART_*.
	var/device_part = CHASTITY_PART_ANY
	/// TRUE when the action user wears the device, FALSE when the target does.
	var/device_on_user = FALSE
	/// TRUE for actions done on oneself, FALSE for actions done on a partner.
	var/self_only = FALSE

/datum/sex_action/chastity/proc/get_device_wearer(mob/living/user, mob/living/target)
	return device_on_user ? user : target

/// The device [wearer] has on that locks away this action's part, or null.
/datum/sex_action/chastity/proc/get_device(mob/living/wearer, part)
	RETURN_TYPE(/obj/item/clothing/undies/chastity)
	if(!part)
		part = device_part
	var/mob/living/carbon/human/human_wearer = wearer
	if(!istype(human_wearer))
		return null
	var/obj/item/clothing/undies/chastity/device = human_wearer.underwear
	if(!istype(device))
		return null
	switch(part)
		if(CHASTITY_PART_COCK)
			return device.cages_cock() ? device : null
		if(CHASTITY_PART_PUSSY)
			return device.seals_pussy() ? device : null
		if(CHASTITY_PART_REAR)
			return device.blocks_organ_use(ORGAN_SLOT_ANUS) ? device : null
	return (device.get_front_anatomy() || device.blocks_organ_use(ORGAN_SLOT_ANUS)) ? device : null

/// The sex lock slot that keeps two actions off the same locked part.
/datum/sex_action/chastity/proc/get_part_lock_slot()
	switch(device_part)
		if(CHASTITY_PART_COCK)
			return ORGAN_SLOT_PENIS
		if(CHASTITY_PART_PUSSY)
			return ORGAN_SLOT_VAGINA
		if(CHASTITY_PART_REAR)
			return ORGAN_SLOT_ANUS
	return BODY_ZONE_PRECISE_GROIN

/datum/sex_action/chastity/proc/is_right_pairing(mob/living/user, mob/living/target)
	return self_only == (user == target)

/datum/sex_action/chastity/shows_on_menu(mob/living/user, mob/living/target)
	if(!is_right_pairing(user, target))
		return FALSE
	if(!user.allows_chastity_play() || !target.allows_chastity_play())
		return FALSE
	return !!get_device(get_device_wearer(user, target))

/datum/sex_action/chastity/can_perform(mob/living/user, mob/living/target)
	. = ..()
	if(!.)
		return FALSE
	if(!is_right_pairing(user, target))
		return FALSE
	if(!user.allows_chastity_play() || !target.allows_chastity_play())
		return FALSE
	var/mob/living/wearer = get_device_wearer(user, target)
	if(!get_device(wearer))
		return FALSE
	if(check_sex_lock(wearer, get_part_lock_slot()))
		return FALSE
	return check_location_accessible(user, wearer, BODY_ZONE_PRECISE_GROIN, TRUE)

/datum/sex_action/chastity/lock_sex_object(mob/living/user, mob/living/target)
	add_sex_lock(get_device_wearer(user, target), get_part_lock_slot(), null, FALSE)

/// Now and then the device rattles under firmer handling.
/datum/sex_action/chastity/proc/rattle_device(mob/living/wearer)
	if(force >= SEX_FORCE_MID && prob(20 + speed * 10))
		playsound(wearer, SFX_JINGLE_BELLS, 20 + force * 5, TRUE, -2, ignore_walls = FALSE)

/datum/sex_action/chastity/proc/device_name(mob/living/wearer)
	return get_device(wearer, CHASTITY_PART_ANY)?.name || "chastity device"

// ---- Hands ----

/datum/sex_action/chastity/hands
	abstract_type = /datum/sex_action/chastity/hands
	requires_free_hands = TRUE
	user_menu_zone_mask = SEX_UI_ZONE_ARMS

/datum/sex_action/chastity/hands/can_perform(mob/living/user, mob/living/target)
	. = ..()
	if(!.)
		return FALSE
	return !!find_available_hand(user)

/datum/sex_action/chastity/hands/lock_sex_object(mob/living/user, mob/living/target)
	. = ..()
	var/hand = get_hand_lock_slot(user)
	if(hand)
		add_sex_lock(user, hand)

/datum/sex_action/chastity/hands/self_cock
	name = "Stroke your caged cock"
	description = "Work your caged cock through the bars."
	device_part = CHASTITY_PART_COCK
	device_on_user = TRUE
	self_only = TRUE

/datum/sex_action/chastity/hands/self_cock/on_start(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] wraps [user.p_their()] hand around [user.p_their()] [device_name(user)] and starts working it slowly, knuckles pressing into the bars."))

/datum/sex_action/chastity/hands/self_cock/on_perform(mob/living/user, mob/living/target)
	. = ..()
	if(can_show_action_message(user, target))
		user.visible_message(spanify_force("[user] [get_generic_force_adjective()] drags [user.p_their()] palm along [user.p_their()] [device_name(user)], cock straining into the bars with every pass..."))
	playsound(user, 'sound/misc/mat/fingering.ogg', 25, TRUE, -2, ignore_walls = FALSE)
	rattle_device(user)
	perform_sex_action(user, user, 1.5, 0, 0.8)
	handle_passive_ejaculation()

/datum/sex_action/chastity/hands/self_cock/on_finish(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] drops [user.p_their()] hand from [user.p_their()] [device_name(user)], breathless and no further along."))

/datum/sex_action/chastity/hands/self_pussy
	name = "Rub your locked slit"
	description = "Rub at the front plate of your belt."
	device_part = CHASTITY_PART_PUSSY
	device_on_user = TRUE
	self_only = TRUE

/datum/sex_action/chastity/hands/self_pussy/on_start(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] presses [user.p_their()] fingers flat against [user.p_their()] [device_name(user)], searching for a gap in the front plate."))

/datum/sex_action/chastity/hands/self_pussy/on_perform(mob/living/user, mob/living/target)
	. = ..()
	if(can_show_action_message(user, target))
		user.visible_message(spanify_force("[user] [get_generic_force_adjective()] rubs circles over the front of [user.p_their()] [device_name(user)], fingers pressing where it matters, barely..."))
	playsound(user, 'sound/misc/mat/fingering.ogg', 25, TRUE, -2, ignore_walls = FALSE)
	perform_sex_action(user, user, 1.5, 0, 0.8)
	handle_passive_ejaculation()

/datum/sex_action/chastity/hands/self_pussy/on_finish(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] pulls [user.p_their()] hand away from [user.p_their()] [device_name(user)], no closer to relief."))

/datum/sex_action/chastity/hands/self_rear
	name = "Rub your anal shield"
	description = "Press at the rear plate of your device."
	device_part = CHASTITY_PART_REAR
	device_on_user = TRUE
	self_only = TRUE

/datum/sex_action/chastity/hands/self_rear/on_start(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] reaches back to press [user.p_their()] fingers against the rear shield of [user.p_their()] [device_name(user)]."))

/datum/sex_action/chastity/hands/self_rear/on_perform(mob/living/user, mob/living/target)
	. = ..()
	if(can_show_action_message(user, target))
		user.visible_message(spanify_force("[user] [get_generic_force_adjective()] works [user.p_their()] fingers against the rear plate, pressing where the shield rides closest to skin..."))
	playsound(user, 'sound/misc/mat/fingering.ogg', 20, TRUE, -2, ignore_walls = FALSE)
	perform_sex_action(user, user, 1.2, 0, 0.6)
	handle_passive_ejaculation()

/datum/sex_action/chastity/hands/self_rear/on_finish(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] withdraws [user.p_their()] hand from [user.p_their()] rear shield."))

/datum/sex_action/chastity/hands/fondle
	name = "Fondle their chastity device"
	description = "Feel the weight of their device in your hands."

/datum/sex_action/chastity/hands/fondle/on_start(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] wraps [user.p_their()] fingers around [target]'s [device_name(target)], feeling the weight of it."))

/datum/sex_action/chastity/hands/fondle/on_perform(mob/living/user, mob/living/target)
	. = ..()
	if(can_show_action_message(user, target))
		user.visible_message(spanify_force("[user] [get_generic_force_adjective()] squeezes and rolls [target]'s [device_name(target)] in [user.p_their()] palm, working the metal deliberately..."))
	rattle_device(target)
	perform_sex_action(target, user, 0.6, 0, 0.3)
	handle_passive_ejaculation(target)

/datum/sex_action/chastity/hands/fondle/on_finish(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] releases [target]'s [device_name(target)] and pulls [user.p_their()] hands away."))

/datum/sex_action/chastity/hands/stroke_cock
	name = "Stroke their caged cock"
	description = "Stroke their cock through the bars of the cage."
	device_part = CHASTITY_PART_COCK

/datum/sex_action/chastity/hands/stroke_cock/on_start(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] closes [user.p_their()] fingers around [target]'s [device_name(target)] and starts a slow, deliberate stroke."))

/datum/sex_action/chastity/hands/stroke_cock/on_perform(mob/living/user, mob/living/target)
	. = ..()
	if(can_show_action_message(user, target))
		user.visible_message(spanify_force("[user] [get_generic_force_adjective()] works [target]'s [device_name(target)] with a measured grip, [target.p_their()] cock pressing uselessly into the bars with every pull..."))
	playsound(user, 'sound/misc/mat/fingering.ogg', 25, TRUE, -2, ignore_walls = FALSE)
	rattle_device(target)
	perform_sex_action(target, user, 1.8, 0, 1)
	handle_passive_ejaculation(target)

/datum/sex_action/chastity/hands/stroke_cock/on_finish(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] lets go of [target]'s [device_name(target)]."))

/datum/sex_action/chastity/hands/rub_pussy
	name = "Rub their locked slit"
	description = "Work your fingers along the front of their belt."
	device_part = CHASTITY_PART_PUSSY

/datum/sex_action/chastity/hands/rub_pussy/on_start(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] traces two fingers over the front plate of [target]'s [device_name(target)], finding the slot."))

/datum/sex_action/chastity/hands/rub_pussy/on_perform(mob/living/user, mob/living/target)
	. = ..()
	if(can_show_action_message(user, target))
		user.visible_message(spanify_force("[user] [get_generic_force_adjective()] works [user.p_their()] fingers along the gap in [target]'s [device_name(target)], feeling the heat of locked skin through the slit..."))
	playsound(user, 'sound/misc/mat/fingering.ogg', 25, TRUE, -2, ignore_walls = FALSE)
	perform_sex_action(target, user, 1.8, 0, 1)
	handle_passive_ejaculation(target)

/datum/sex_action/chastity/hands/rub_pussy/on_finish(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] slides [user.p_their()] fingers away from [target]'s [device_name(target)]."))

/datum/sex_action/chastity/hands/tease_rear
	name = "Tease their anal shield"
	description = "Press along the seam of their rear shield."
	device_part = CHASTITY_PART_REAR

/datum/sex_action/chastity/hands/tease_rear/on_start(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] slides [user.p_their()] hand behind [target] to find the edge of [target.p_their()] rear shield."))

/datum/sex_action/chastity/hands/tease_rear/on_perform(mob/living/user, mob/living/target)
	. = ..()
	if(can_show_action_message(user, target))
		user.visible_message(spanify_force("[user] [get_generic_force_adjective()] works [user.p_their()] fingers along the seam of [target]'s rear shield, pressing inward where the plate meets skin..."))
	playsound(user, 'sound/misc/mat/fingering.ogg', 20, TRUE, -2, ignore_walls = FALSE)
	perform_sex_action(target, user, 1.4, 0, 0.8)
	handle_passive_ejaculation(target)

/datum/sex_action/chastity/hands/tease_rear/on_finish(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] draws [user.p_their()] hand back from [target]'s rear shield."))

// ---- Mouth ----

/datum/sex_action/chastity/lick_belt
	name = "Lick through their belt"
	description = "Work your tongue through the front slits of their belt."
	device_part = CHASTITY_PART_PUSSY
	user_menu_zone_mask = SEX_UI_ZONE_MOUTH
	gags_user = TRUE

/datum/sex_action/chastity/lick_belt/can_perform(mob/living/user, mob/living/target)
	. = ..()
	if(!.)
		return FALSE
	if(check_sex_lock(user, BODY_ZONE_PRECISE_MOUTH))
		return FALSE
	return check_location_accessible(target, user, BODY_ZONE_PRECISE_MOUTH)

/datum/sex_action/chastity/lick_belt/lock_sex_object(mob/living/user, mob/living/target)
	. = ..()
	add_sex_lock(user, BODY_ZONE_PRECISE_MOUTH)

/datum/sex_action/chastity/lick_belt/on_start(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] kneels and brings [user.p_their()] mouth level with [target]'s [device_name(target)]."))

/datum/sex_action/chastity/lick_belt/on_perform(mob/living/user, mob/living/target)
	. = ..()
	if(can_show_action_message(user, target))
		user.visible_message(spanify_force("[user] [get_generic_force_adjective()] works [user.p_their()] tongue through the front slits of [target]'s [device_name(target)], finding what little skin it can reach..."))
	user.make_sucking_noise()
	perform_sex_action(target, user, 1.8, 0, 1)
	handle_passive_ejaculation(target)

/datum/sex_action/chastity/lick_belt/on_finish(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] pulls back from [target]'s [device_name(target)], lips wet."))

/datum/sex_action/chastity/nuzzle_cage
	name = "Make them nuzzle your cage"
	description = "Hold their face against your caged cock."
	device_part = CHASTITY_PART_COCK
	device_on_user = TRUE
	target_menu_zone_mask = SEX_UI_ZONE_MOUTH

/datum/sex_action/chastity/nuzzle_cage/can_perform(mob/living/user, mob/living/target)
	. = ..()
	if(!.)
		return FALSE
	if(check_sex_lock(target, BODY_ZONE_PRECISE_MOUTH))
		return FALSE
	return check_location_accessible(user, target, BODY_ZONE_PRECISE_MOUTH)

/datum/sex_action/chastity/nuzzle_cage/lock_sex_object(mob/living/user, mob/living/target)
	. = ..()
	add_sex_lock(target, BODY_ZONE_PRECISE_MOUTH)

/datum/sex_action/chastity/nuzzle_cage/on_start(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] takes hold of [target]'s head and guides it into [user.p_their()] [device_name(user)]."))

/datum/sex_action/chastity/nuzzle_cage/on_perform(mob/living/user, mob/living/target)
	. = ..()
	if(can_show_action_message(user, target))
		user.visible_message(spanify_force("[user] [get_generic_force_adjective()] holds [target]'s face against [user.p_their()] [device_name(user)], nose and cheek pressed into the metal..."))
	rattle_device(user)
	perform_sex_action(user, target, 1, 0, 0.5)
	perform_sex_action(target, user, 0.3, 0, 0)
	handle_passive_ejaculation()

/datum/sex_action/chastity/nuzzle_cage/on_finish(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] loosens [user.p_their()] grip and lets [target] pull back from [user.p_their()] [device_name(user)]."))

// ---- Bodies ----

/datum/sex_action/chastity/frot_device
	name = "Frot against their device"
	description = "Slide your cock along their locked cage."
	device_part = CHASTITY_PART_COCK
	uses_user_organs = list(ORGAN_SLOT_PENIS)

/datum/sex_action/chastity/frot_device/shows_on_menu(mob/living/user, mob/living/target)
	return ..() && user.getorganslot(ORGAN_SLOT_PENIS)

/datum/sex_action/chastity/frot_device/can_perform(mob/living/user, mob/living/target)
	. = ..()
	if(!.)
		return FALSE
	if(!user.getorganslot(ORGAN_SLOT_PENIS) || check_sex_lock(user, ORGAN_SLOT_PENIS))
		return FALSE
	return check_location_accessible(user, user, BODY_ZONE_PRECISE_GROIN, TRUE)

/datum/sex_action/chastity/frot_device/lock_sex_object(mob/living/user, mob/living/target)
	. = ..()
	add_sex_lock(user, ORGAN_SLOT_PENIS)

/datum/sex_action/chastity/frot_device/on_start(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] presses [user.p_their()] cock flush against [target]'s [device_name(target)]."))

/datum/sex_action/chastity/frot_device/on_perform(mob/living/user, mob/living/target)
	. = ..()
	if(can_show_action_message(user, target))
		user.visible_message(spanify_force("[user] [get_generic_force_adjective()] slides [user.p_their()] cock along [target]'s [device_name(target)], hips rolling into every pass..."))
	do_thrust_animate(user, target)
	rattle_device(target)
	perform_sex_action(user, target, 1.2, 0, 1)
	handle_passive_ejaculation()
	perform_sex_action(target, user, 1.2, 0, 0.6)
	handle_passive_ejaculation(target)

/datum/sex_action/chastity/frot_device/on_finish(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] rolls [user.p_their()] hips back from [target]'s [device_name(target)]."))

/datum/sex_action/chastity/frot_on_cage
	name = "Let them frot on your cage"
	description = "Work their cock along the bars of your cage."
	device_part = CHASTITY_PART_COCK
	device_on_user = TRUE
	uses_target_organs = list(ORGAN_SLOT_PENIS)

/datum/sex_action/chastity/frot_on_cage/shows_on_menu(mob/living/user, mob/living/target)
	return ..() && target.getorganslot(ORGAN_SLOT_PENIS)

/datum/sex_action/chastity/frot_on_cage/can_perform(mob/living/user, mob/living/target)
	. = ..()
	if(!.)
		return FALSE
	if(!target.getorganslot(ORGAN_SLOT_PENIS) || check_sex_lock(target, ORGAN_SLOT_PENIS))
		return FALSE
	return check_location_accessible(user, target, BODY_ZONE_PRECISE_GROIN, TRUE)

/datum/sex_action/chastity/frot_on_cage/lock_sex_object(mob/living/user, mob/living/target)
	. = ..()
	add_sex_lock(target, ORGAN_SLOT_PENIS)

/datum/sex_action/chastity/frot_on_cage/on_start(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] reaches for [target] and presses [target.p_their()] cock against [user.p_their()] [device_name(user)]."))

/datum/sex_action/chastity/frot_on_cage/on_perform(mob/living/user, mob/living/target)
	. = ..()
	if(can_show_action_message(user, target))
		user.visible_message(spanify_force("[user] [get_generic_force_adjective()] works [target]'s cock along the bars of [user.p_their()] [device_name(user)], each pass earning a faint rasp of metal..."))
	do_thrust_animate(user, target)
	rattle_device(user)
	perform_sex_action(user, target, 1.1, 0, 0.6)
	handle_passive_ejaculation()
	perform_sex_action(target, user, 1.5, 0, 1)
	handle_passive_ejaculation(target)

/datum/sex_action/chastity/frot_on_cage/on_finish(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] lets [target]'s cock slip away from [user.p_their()] [device_name(user)]."))

/datum/sex_action/chastity/cage_to_cage
	name = "Grind cage to cage"
	description = "Grind your caged cock against theirs."
	device_part = CHASTITY_PART_COCK
	device_on_user = TRUE

/datum/sex_action/chastity/cage_to_cage/shows_on_menu(mob/living/user, mob/living/target)
	return ..() && get_device(target)

/datum/sex_action/chastity/cage_to_cage/can_perform(mob/living/user, mob/living/target)
	. = ..()
	if(!.)
		return FALSE
	if(!get_device(target) || check_sex_lock(target, ORGAN_SLOT_PENIS))
		return FALSE
	return check_location_accessible(user, target, BODY_ZONE_PRECISE_GROIN, TRUE)

/datum/sex_action/chastity/cage_to_cage/lock_sex_object(mob/living/user, mob/living/target)
	. = ..()
	add_sex_lock(target, ORGAN_SLOT_PENIS)

/datum/sex_action/chastity/cage_to_cage/on_start(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] closes in until [user.p_their()] [device_name(user)] knocks against [target]'s [device_name(target)]."))

/datum/sex_action/chastity/cage_to_cage/on_perform(mob/living/user, mob/living/target)
	. = ..()
	if(can_show_action_message(user, target))
		user.visible_message(spanify_force("[user] [get_generic_force_adjective()] grinds [user.p_their()] [device_name(user)] against [target]'s [device_name(target)], steel on steel, loud and graceless..."))
	do_thrust_animate(user, target)
	rattle_device(user)
	perform_sex_action(user, target, 1, 0, 0.5)
	handle_passive_ejaculation()
	perform_sex_action(target, user, 1, 0, 0.5)
	handle_passive_ejaculation(target)

/datum/sex_action/chastity/cage_to_cage/on_finish(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] steps back, and the two devices part with a last scrape of metal."))

/datum/sex_action/chastity/ride_cage
	name = "Ride their cage"
	description = "Grind your pussy down on their caged cock."
	device_part = CHASTITY_PART_COCK
	uses_user_organs = list(ORGAN_SLOT_VAGINA)

/datum/sex_action/chastity/ride_cage/shows_on_menu(mob/living/user, mob/living/target)
	return ..() && user.getorganslot(ORGAN_SLOT_VAGINA)

/datum/sex_action/chastity/ride_cage/can_perform(mob/living/user, mob/living/target)
	. = ..()
	if(!.)
		return FALSE
	if(!user.getorganslot(ORGAN_SLOT_VAGINA) || check_sex_lock(user, ORGAN_SLOT_VAGINA))
		return FALSE
	return check_location_accessible(user, user, BODY_ZONE_PRECISE_GROIN, TRUE)

/datum/sex_action/chastity/ride_cage/lock_sex_object(mob/living/user, mob/living/target)
	. = ..()
	add_sex_lock(user, ORGAN_SLOT_VAGINA)

/datum/sex_action/chastity/ride_cage/on_start(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] straddles [target] and settles down until [user.p_their()] pussy meets the bars of [target.p_their()] [device_name(target)]."))

/datum/sex_action/chastity/ride_cage/on_perform(mob/living/user, mob/living/target)
	. = ..()
	if(can_show_action_message(user, target))
		user.visible_message(spanify_force("[user] [get_generic_force_adjective()] rolls [user.p_their()] hips along [target]'s [device_name(target)], grinding against bars that have no give..."))
	do_thrust_animate(user, target)
	rattle_device(target)
	perform_sex_action(user, target, 2, 0, 1.5)
	handle_passive_ejaculation()
	perform_sex_action(target, user, 1.3, 0, 0.6)
	handle_passive_ejaculation(target)

/datum/sex_action/chastity/ride_cage/on_finish(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] lifts [user.p_their()] hips off [target]'s [device_name(target)], the metal cold as [user.p_their()] warmth leaves it."))

/datum/sex_action/chastity/scissor_belt
	name = "Scissor against their belt"
	description = "Grind your pussy against the plate of their belt."
	device_part = CHASTITY_PART_PUSSY
	uses_user_organs = list(ORGAN_SLOT_VAGINA)

/datum/sex_action/chastity/scissor_belt/shows_on_menu(mob/living/user, mob/living/target)
	return ..() && user.getorganslot(ORGAN_SLOT_VAGINA)

/datum/sex_action/chastity/scissor_belt/can_perform(mob/living/user, mob/living/target)
	. = ..()
	if(!.)
		return FALSE
	if(!user.getorganslot(ORGAN_SLOT_VAGINA) || check_sex_lock(user, ORGAN_SLOT_VAGINA))
		return FALSE
	return check_location_accessible(user, user, BODY_ZONE_PRECISE_GROIN, TRUE)

/datum/sex_action/chastity/scissor_belt/lock_sex_object(mob/living/user, mob/living/target)
	. = ..()
	add_sex_lock(user, ORGAN_SLOT_VAGINA)

/datum/sex_action/chastity/scissor_belt/on_start(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] presses [user.p_their()] bare pussy flush against the plate of [target]'s [device_name(target)]."))

/datum/sex_action/chastity/scissor_belt/on_perform(mob/living/user, mob/living/target)
	. = ..()
	if(can_show_action_message(user, target))
		user.visible_message(spanify_force("[user] [get_generic_force_adjective()] grinds against the hard plate of [target]'s [device_name(target)], chasing friction the metal refuses to give..."))
	do_thrust_animate(user, target)
	perform_sex_action(user, target, 1.8, 0, 1.2)
	handle_passive_ejaculation()
	perform_sex_action(target, user, 1.5, 0, 0.6)
	handle_passive_ejaculation(target)

/datum/sex_action/chastity/scissor_belt/on_finish(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] rocks back and lifts away from [target]'s [device_name(target)], flushed and unsatisfied."))

#undef CHASTITY_PART_ANY
#undef CHASTITY_PART_COCK
#undef CHASTITY_PART_PUSSY
#undef CHASTITY_PART_REAR
