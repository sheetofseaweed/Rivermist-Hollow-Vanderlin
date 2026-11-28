/obj/structure/anti_magic_field/stationary
	name = "stationary anti-magic field generator"
	desc = "A heavy field generator. It can be toggled, locked, and repaired like an iron door."
	max_integrity = 200
	// The repairable component needs a non-zero break threshold for the door-style lifecycle.
	integrity_failure = 0.01
	field_width = ANTI_MAGIC_FIELD_STATIONARY_WIDTH
	field_height = ANTI_MAGIC_FIELD_STATIONARY_HEIGHT
	field_z_coverage = 1
	icon_state_broken = "antimagicstationarybroken"
	var/list/repair_thresholds = list(/obj/item/ingot/iron = 1)
	var/obj/item/broken_repair = /obj/item/ingot/iron
	var/repair_skill = /datum/attribute/skill/craft/blacksmithing

/obj/structure/anti_magic_field/stationary/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/repairable, repair_thresholds, broken_repair, 'sound/misc/wood_saw.ogg', repair_skill)
	activate_field()

/obj/structure/anti_magic_field/stationary/attack_hand(mob/user)
	. = ..()
	if(. || !user)
		return
	if(obj_broken)
		to_chat(user, span_warning("The generator is broken and must be repaired first."))
		return ITEM_INTERACT_SUCCESS
	// Reuse the existing datum/lock and key/lockpick workflows. Do not block key or pick item interactions.
	if(locked())
		lock_failed(user, FALSE, "The generator is locked.")
		return ITEM_INTERACT_SUCCESS
	if(is_active)
		deactivate_field()
		playsound(src, 'sound/foley/lever.ogg', 50, TRUE)
		user.visible_message(span_notice("[user] switches [src] OFF."), span_notice("I switch [src] OFF."))
		return ITEM_INTERACT_SUCCESS
	if(activate_field(user))
		playsound(src, 'sound/foley/lever.ogg', 50, TRUE)
		user.visible_message(span_notice("[user] switches [src] ON."), span_notice("I switch [src] ON."))
	return ITEM_INTERACT_SUCCESS

/obj/structure/anti_magic_field/stationary/attack_paw(mob/user)
	return attack_hand(user)

/obj/structure/anti_magic_field/stationary/atom_break(damage_flag, silent)
	. = ..()
	deactivate_field()
	update_appearance(UPDATE_ICON_STATE)

/// Preserve the broken structure for the existing repairable-component workflow.
/obj/structure/anti_magic_field/stationary/atom_destruction(damage_flag)
	if(!obj_broken)
		return ..()
	update_integrity(1, FALSE, damage_flag)
	deactivate_field()
	update_appearance(UPDATE_ICON_STATE)

/obj/structure/anti_magic_field/stationary/atom_fix()
	. = ..()
	// Repair does not automatically reactivate the device.
	deactivate_field()
	update_appearance(UPDATE_ICON_STATE)

/obj/structure/anti_magic_field/stationary/OnCrafted(dirin, mob/user)
	. = ..()
	if(user && !is_active && !obj_broken && !GLOB.anti_magic_field_manager.has_available_slot())
		to_chat(user, span_warning("The generator is built, but remains OFF because the configured active-field limit is occupied."))
