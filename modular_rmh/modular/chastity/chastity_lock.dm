// Chastity locks and their keys; hard mode trusts only the device's own key.

/datum/lock/key/chastity
	difficulty = 4
	requires_turning = FALSE

/datum/lock/key/chastity/check_access(obj/item/I)
	var/obj/item/clothing/undies/chastity/device = holder
	if(istype(device) && device.is_hardmode_active())
		return device.is_generated_key(I)
	return ..()

/datum/lock/key/chastity/try_toggle(mob/living/user, obj/item/tool, is_right)
	if(lock_broken)
		to_chat(user, span_warning("The lock is broken and no longer closes."))
		return
	return ..()

/obj/item/key/chastity
	name = "chastity key"
	desc = "A small iron key with a puzzle-cut bit, made for one chastity device."
	icon_state = "mazekey"
	resistance_flags = INDESTRUCTIBLE
	/// The device this key was made for.
	var/datum/weakref/device_ref

/obj/item/key/chastity/Destroy()
	device_ref = null
	return ..()

/obj/item/key/chastity/examine(mob/user)
	. = ..()
	var/obj/item/clothing/undies/chastity/device = device_ref?.resolve()
	if(!device)
		. += span_notice("Whatever it once opened is gone.")
		return
	if(device.is_hardmode_active())
		. += span_warning("It is the only thing that will ever open [device.wearer]'s [device.name].")
		return
	. += span_notice("It opens \a [device].")
	. += span_notice("With fierce intent, I could shatter it for good.")

/obj/item/key/chastity/attack_self(mob/user, list/modifiers)
	if(!user.cmode)
		return ..()
	var/choice = tgui_alert(user, "Shatter this key? The device it was made for will never open with it again.", "Shatter the key", list("Shatter it", "Keep it"))
	if(choice != "Shatter it" || QDELETED(src) || !user.is_holding(src))
		return
	user.visible_message(span_warning("[user] twists [src] until it shatters."), span_warning("I twist [src] until it shatters."))
	playsound(user, 'sound/foley/lockrattlemetal.ogg', 60, TRUE)
	qdel(src)
