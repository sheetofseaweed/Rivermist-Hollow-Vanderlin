// Chastity preferences; turning chastity play off frees the wearer at once.

/datum/erp_preference/boolean/allow_chastity_play
	name = "Chastity Play"
	description = "If chastity devices can be fitted on you, and if chastity play actions include you"
	default_value = TRUE
	category = "General"

/datum/erp_preference/boolean/allow_chastity_play/set_value(datum/preferences/prefs, value)
	. = ..()
	if(value)
		return
	var/mob/living/carbon/human/body = prefs?.parent?.mob
	if(istype(body))
		body.release_chastity_device()

/datum/erp_preference/boolean/chastity_hardmode
	name = "Chastity Hard Mode"
	description = "A device locked on you opens only for its own key: no master key, no lockpick, no chisel"
	default_value = FALSE
	category = "General"

/// Chastity pref value, falling back to its default for NPCs and fresh saves.
/mob/living/proc/get_chastity_pref(pref_type)
	var/datum/erp_preference/pref = new pref_type()
	if(client?.prefs)
		return pref.get_value(client.prefs)
	return pref.get_value_from_list(cached_erp_preferences || mind?.cached_erp_preferences)

/mob/living/proc/allows_chastity_play()
	return !!get_chastity_pref(/datum/erp_preference/boolean/allow_chastity_play)

/// Drops a worn chastity device, lock or not.
/mob/living/carbon/human/proc/release_chastity_device()
	var/obj/item/clothing/undies/chastity/device = underwear
	if(!istype(device))
		return FALSE
	if(!dropItemToGround(device, force = TRUE))
		return FALSE
	device.lock?.unlock()
	visible_message(span_notice("\The [device] slips free of [src]'s loins."))
	return TRUE
