/obj/structure/anti_magic_field/throwable
	name = "deployed anti-magic field generator"
	desc = "A compact throwable generator that unfolds, activates, and gradually loses its charge."
	icon = 'modular_rmh/icons/obj/structures/antimagicfield.dmi'
	icon_state = "antimagicthrowabletile"
	max_integrity = 100
	integrity_failure = 0
	field_width = ANTI_MAGIC_FIELD_THROWABLE_WIDTH
	field_height = ANTI_MAGIC_FIELD_THROWABLE_HEIGHT
	field_z_coverage = 0
	is_built = FALSE
	icon_state_constructing = "antimagicdeploy"
	icon_state_broken = "clockcrystal_broken"
	break_sound = 'sound/magic/crystal.ogg'

	var/construction_timer
	var/is_constructing = TRUE

/obj/structure/anti_magic_field/throwable/Initialize(mapload)
	. = ..()
	construction_timer = addtimer(CALLBACK(src, PROC_REF(finish_construction)), ANTI_MAGIC_FIELD_THROWABLE_BUILD_TIME, TIMER_STOPPABLE)
	update_appearance(UPDATE_ICON_STATE)

/// Active throwables lose exactly 2 integrity per SSmagic processing tick.
/// Damage therefore accelerates depletion. This intentionally does not use a wall-clock lifetime timer.
/obj/structure/anti_magic_field/throwable/on_field_activated()
	. = ..()
	START_PROCESSING(SSmagic, src)

/obj/structure/anti_magic_field/throwable/on_field_deactivated()
	STOP_PROCESSING(SSmagic, src)
	return ..()

/obj/structure/anti_magic_field/throwable/process(delta_time)
	if(!is_active || is_constructing || !is_built)
		return PROCESS_KILL

	var/remaining_integrity = max(get_integrity() - 2, 0)
	update_integrity(remaining_integrity, FALSE)
	if(!remaining_integrity)
		// Depletion bypasses atom_break() by design; play the configured throwable break sound here.
		atom_destruction("anti_magic_field_depleted")
		return PROCESS_KILL
	return TRUE

/obj/structure/anti_magic_field/throwable/Destroy()
	if(construction_timer)
		deltimer(construction_timer)
		construction_timer = null
	return ..()

/// Any successful damage during deployment destroys the device immediately.
/obj/structure/anti_magic_field/throwable/take_damage(damage_amount, damage_type = BRUTE, damage_flag = "", sound_effect = TRUE, attack_dir, armour_penetration = 0)
	. = ..()
	if(is_constructing && . && !QDELETED(src))
		visible_message(span_warning("[src] is struck during deployment and breaks apart before it can activate!"))
		playsound(src, break_sound, 50, TRUE)
		qdel(src)

/obj/structure/anti_magic_field/throwable/proc/finish_construction()
	construction_timer = null
	if(QDELETED(src))
		return
	is_constructing = FALSE
	is_built = TRUE
	update_integrity(max_integrity, FALSE)
	visible_message(span_notice("[src] finishes unfolding and activates."))
	playsound(src, 'sound/magic/cosmic_expansion.ogg', 50, TRUE)
	if(!activate_field())
		waiting_for_slot = TRUE
		visible_message(span_warning("[src] remains dormant until an anti-magic field slot becomes available."))
	update_appearance(UPDATE_ICON_STATE)

/obj/structure/anti_magic_field/throwable/attack_hand(mob/user)
	if(!user || is_constructing || user.cmode)
		return ..()
	// An active field and a field waiting for a slot are both recoverable.
	if(!is_active && !waiting_for_slot)
		return ..()

	user.visible_message(span_notice("[user] begins recovering [src]."), span_notice("I begin recovering [src]."))
	if(!do_after(user, ANTI_MAGIC_FIELD_RECOVERY_TIME, src))
		return ITEM_INTERACT_SUCCESS
	if(QDELETED(src) || is_constructing || (!is_active && !waiting_for_slot))
		return ITEM_INTERACT_SUCCESS

	var/turf/recovery_turf = get_turf(src)
	if(!recovery_turf)
		return ITEM_INTERACT_SUCCESS
	new /obj/item/rope/net/bola/mantrap/anti_magic_field(recovery_turf)
	playsound(recovery_turf, 'sound/items/pickgood1.ogg', 50, TRUE)
	visible_message(span_notice("[user] folds [src] back into its throwable frame."))
	qdel(src)
	return ITEM_INTERACT_SUCCESS

/obj/structure/anti_magic_field/throwable/atom_destruction(damage_flag)
	if(damage_flag == "anti_magic_field_depleted")
		visible_message(span_warning("[src] sputters, loses its remaining charge, and breaks down completely!"))
		playsound(src, break_sound, 50, TRUE)
	else
		visible_message(span_warning("[src] is destroyed in a burst of sparks!"))
	return ..()
