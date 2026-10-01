#define TAUR_GENITAL_ICON_OFFSET_X -14

/datum/sprite_accessory/genitals
	abstract_type = /datum/sprite_accessory/genitals

/datum/sprite_accessory/genitals/proc/is_taur_owner(mob/living/carbon/owner)
	return iscarbon(owner) && owner.get_taur_tail()

/// Largest size with a sprite for this accessory, so a swollen organ never asks for a missing state.
/datum/sprite_accessory/genitals/proc/get_max_size_state(obj/item/organ/organ, mob/living/carbon/owner)
	return get_max_numbered_icon_state(icon, icon_state)

/// Highest N among "[prefix]_N" states in an icon file, or -1; cached per file and prefix.
/proc/get_max_numbered_icon_state(icon_file, prefix)
	var/static/list/max_states = list()
	var/cache_key = "[icon_file]|[prefix]"
	if(!isnull(max_states[cache_key]))
		return max_states[cache_key]
	. = -1
	var/state_prefix = "[prefix]_"
	var/prefix_length = length(state_prefix)
	for(var/state in icon_states(icon_file))
		if(copytext(state, 1, prefix_length + 1) != state_prefix)
			continue
		var/size_text = copytext(state, prefix_length + 1)
		var/suffix_start = findtext(size_text, "_")
		if(suffix_start)
			size_text = copytext(size_text, 1, suffix_start)
		var/size = text2num(size_text)
		if(isnum(size) && size > .)
			. = size
	max_states[cache_key] = .

/datum/sprite_accessory/genitals/proc/shift_for_taur(list/appearance_list)
	for(var/mutable_appearance/appearance as anything in appearance_list)
		appearance.pixel_x += TAUR_GENITAL_ICON_OFFSET_X

#undef TAUR_GENITAL_ICON_OFFSET_X
