// Horny NPCs can jerk off over someone, aiming at a spot so their spurts paint down the body.

/datum/sex_action/npc/npc_jerk_over
	name = "NPC Jerk over them"

/datum/sex_action/npc/npc_jerk_over/shows_on_menu(mob/living/user, mob/living/target)
	return FALSE

/datum/sex_action/npc/npc_jerk_over/can_perform(mob/living/user, mob/living/target)
	. = ..()
	if(!. || user == target)
		return FALSE
	if(!user.getorganslot(ORGAN_SLOT_PENIS) || check_sex_lock(user, ORGAN_SLOT_PENIS))
		return FALSE
	return check_location_accessible(user, user, BODY_ZONE_PRECISE_GROIN, TRUE)

/// The NPC strokes its own cock, so the aim on it steers the climax.
/datum/sex_action/npc/npc_jerk_over/get_grip_owner(mob/living/user, mob/living/target)
	return user

/datum/sex_action/npc/npc_jerk_over/on_start(mob/living/user, mob/living/target)
	. = ..()
	if(!.)
		return
	aim_at_target(user, target)
	user.visible_message(span_warning("[user] grips [user.p_their()] cock and points it at [target]..."))

/// Picks a spot on the target, mostly high on the body, so later spurts drift down it.
/datum/sex_action/npc/npc_jerk_over/proc/aim_at_target(mob/living/user, mob/living/target)
	var/obj/item/organ/genitals/penis/penis = user.getorganslot(ORGAN_SLOT_PENIS)
	if(!penis)
		return
	var/list/zone_weights = list(FLUID_COAT_FACE = 4, FLUID_COAT_CHEST = 3, FLUID_COAT_BELLY = 2)
	if(target.mouth_is_free())
		zone_weights[PENIS_AIM_MOUTH] = 1
	penis.get_climax_aim().set_target(target, pickweight(zone_weights), user)

/datum/sex_action/npc/npc_jerk_over/on_perform(mob/living/user, mob/living/target)
	. = ..()
	if(can_show_action_message(user, target))
		user.visible_message(spanify_force("[user] [get_generic_force_adjective()] jerks [user.p_their()] cock over [target]..."))
	playsound(user, 'sound/misc/mat/fingering.ogg', 30, TRUE, -2, ignore_walls = FALSE)
	perform_sex_action(user, user, 2, 0, 2)
	handle_passive_ejaculation()

/datum/sex_action/npc/npc_jerk_over/on_finish(mob/living/user, mob/living/target)
	. = ..()
	var/obj/item/organ/genitals/penis/penis = user.getorganslot(ORGAN_SLOT_PENIS)
	if(penis?.climax_aim?.aimer == user)
		penis.climax_aim.clear()
	user.visible_message(span_warning("[user] stops jerking off."))

/datum/sex_action/npc/npc_jerk_over/handle_climax_message(mob/living/user, mob/living/target, must_flip)
	user.visible_message(span_love("[user] cums over [target]!"))
	return ORGASM_LOCATION_ONTO

/datum/sex_action/npc/npc_jerk_over/lock_sex_object(mob/living/user, mob/living/target)
	add_sex_lock(user, ORGAN_SLOT_PENIS)
