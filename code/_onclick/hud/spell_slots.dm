// Spell slot HUD: selector row, rest button and collapse toggle. State lives on mind.spell_slots.

#define SPELL_SLOT_ICON_MAX 4

/mob/living/carbon/human
	var/list/spell_slot_hud_buttons
	var/atom/movable/screen/spell_rest_hud/short_rest_hud_button
	var/atom/movable/screen/spell_slots_toggle_hud/spell_slots_toggle_hud_button

/mob/living/carbon/human/proc/get_spell_slots()
	RETURN_TYPE(/datum/spell_slots)
	return mind?.spell_slots

/// Rest entry point for the HUD button and the sleep hook.
/mob/living/carbon/human/proc/use_spell_rest(long_rest = FALSE, silent = FALSE)
	var/datum/spell_slots/slots = get_spell_slots()
	if(!slots)
		return FALSE
	return slots.use_rest(long_rest, silent)

/mob/living/carbon/human/proc/grant_spell_slot_hud()
	if(!client || !get_spell_slots())
		return FALSE
	grant_spell_slots_toggle_hud()
	grant_spell_rest_hud()
	grant_spell_slot_buttons()
	apply_spell_slot_hud_visibility()
	return TRUE

/mob/living/carbon/human/proc/grant_spell_slot_buttons()
	if(!client)
		return FALSE
	if(!spell_slot_hud_buttons)
		spell_slot_hud_buttons = list()
	for(var/level in SPELL_SLOT_MINOR to SPELL_SLOT_MAX)
		var/already_has_button = FALSE
		for(var/atom/movable/screen/spell_slot_hud/existing_button in spell_slot_hud_buttons)
			if(existing_button.slot_level == level)
				already_has_button = TRUE
				break
		if(already_has_button)
			continue
		var/atom/movable/screen/spell_slot_hud/button = new
		button.owner_mob = src
		button.slot_level = level
		button.screen_loc = get_spell_slot_screen_loc(level)
		spell_slot_hud_buttons += button
		client.screen += button
	update_spell_slot_hud()
	return TRUE

/mob/living/carbon/human/proc/grant_spell_rest_hud()
	if(!client)
		return FALSE
	if(short_rest_hud_button)
		short_rest_hud_button.refresh_rest_hud()
		return short_rest_hud_button
	var/atom/movable/screen/spell_rest_hud/button = new
	button.owner_mob = src
	button.screen_loc = get_spell_rest_screen_loc()
	short_rest_hud_button = button
	client.screen += button
	update_spell_slot_hud()
	return button

/mob/living/carbon/human/proc/grant_spell_slots_toggle_hud()
	if(!client)
		return FALSE
	if(spell_slots_toggle_hud_button)
		spell_slots_toggle_hud_button.refresh_toggle_hud()
		return spell_slots_toggle_hud_button
	var/atom/movable/screen/spell_slots_toggle_hud/button = new
	button.owner_mob = src
	button.screen_loc = get_spell_slots_toggle_screen_loc()
	spell_slots_toggle_hud_button = button
	client.screen += button
	update_spell_slot_hud()
	return button

/mob/living/carbon/human/proc/toggle_spell_slot_hud()
	var/datum/spell_slots/slots = get_spell_slots()
	if(!slots)
		return FALSE
	slots.hud_collapsed = !slots.hud_collapsed
	if(!spell_slots_toggle_hud_button)
		grant_spell_slots_toggle_hud()
	apply_spell_slot_hud_visibility()
	update_spell_slot_hud()
	return TRUE

/mob/living/carbon/human/proc/apply_spell_slot_hud_visibility()
	if(!client)
		return FALSE
	var/datum/spell_slots/slots = get_spell_slots()
	var/hud_hidden = hud_used?.hud_version == HUD_STYLE_NOHUD
	var/collapsed = slots?.hud_collapsed
	if(spell_slot_hud_buttons)
		for(var/atom/movable/screen/spell_slot_hud/button as anything in spell_slot_hud_buttons)
			if(hud_hidden || collapsed)
				client.screen -= button
			else if(!(button in client.screen))
				client.screen += button
	if(short_rest_hud_button)
		if(hud_hidden || collapsed)
			client.screen -= short_rest_hud_button
		else if(!(short_rest_hud_button in client.screen))
			client.screen += short_rest_hud_button
	if(spell_slots_toggle_hud_button)
		if(hud_hidden)
			client.screen -= spell_slots_toggle_hud_button
		else if(!(spell_slots_toggle_hud_button in client.screen))
			client.screen += spell_slots_toggle_hud_button
	return TRUE

/mob/living/carbon/human/proc/remove_spell_slot_hud()
	if(spell_slot_hud_buttons)
		for(var/atom/movable/screen/spell_slot_hud/button as anything in spell_slot_hud_buttons)
			client?.screen -= button
			qdel(button)
		spell_slot_hud_buttons = null
	if(short_rest_hud_button)
		client?.screen -= short_rest_hud_button
		QDEL_NULL(short_rest_hud_button)
	if(spell_slots_toggle_hud_button)
		client?.screen -= spell_slots_toggle_hud_button
		QDEL_NULL(spell_slots_toggle_hud_button)

/mob/living/carbon/human/proc/update_spell_slot_hud()
	for(var/atom/movable/screen/spell_slot_hud/button as anything in spell_slot_hud_buttons)
		button.refresh_slot_hud()
	short_rest_hud_button?.refresh_rest_hud()
	spell_slots_toggle_hud_button?.refresh_toggle_hud()

/proc/get_spell_slot_icon_state(level, charges)
	level = clamp(round(level), SPELL_SLOT_MIN, SPELL_SLOT_MAX)
	charges = clamp(round(charges), 0, SPELL_SLOT_ICON_MAX)
	return "dnd_slot_[level]_[charges]"

/proc/get_spell_rest_icon_state(charges)
	// The sprites stop at two; maptext shows the real count.
	charges = clamp(round(charges), 0, SHORT_REST_BASE_CHARGES)
	return "dnd_short_rest_[charges]"

/proc/get_spell_slot_screen_loc(level)
	switch(level)
		if(SPELL_SLOT_MINOR)
			return "CENTER-4,SOUTH+2"
		if(1)
			return "CENTER-1,SOUTH+2"
		if(2)
			return "CENTER,SOUTH+2"
		if(3)
			return "CENTER+1,SOUTH+2"
		if(4)
			return "CENTER+2,SOUTH+2"
		if(5)
			return "CENTER+3,SOUTH+2"
	return "CENTER+1,SOUTH+2"

/proc/get_spell_rest_screen_loc()
	return "CENTER-2,SOUTH+2"

/proc/get_spell_slots_toggle_screen_loc()
	return "CENTER-3,SOUTH+2"

/atom/movable/screen/spell_slot_hud
	name = "Spell Slot"
	desc = "Selects a spell slot."
	icon = 'icons/mob/actions/dnd_spell_slots.dmi'
	icon_state = "dnd_slot_1_0"
	mouse_opacity = MOUSE_OPACITY_ICON
	var/slot_level = 1
	var/mob/living/carbon/human/owner_mob

/atom/movable/screen/spell_slot_hud/Destroy()
	owner_mob = null
	return ..()

/atom/movable/screen/spell_slot_hud/proc/refresh_slot_hud()
	var/datum/spell_slots/slots = owner_mob?.get_spell_slots()
	if(!slots)
		icon_state = get_spell_slot_icon_state(slot_level, 0)
		return FALSE
	var/selected = slots.get_selected_level() == slot_level
	color = selected ? "#ffe080" : "#ffffff"
	if(slot_level == SPELL_SLOT_MINOR)
		icon_state = "dnd_slot_1_0"
		maptext = "<span class='maptext'>MIN</span>"
		name = "[selected ? "Selected: " : ""]Minor Casting (Mana)"
		desc = "Cast supported minor forms using mana. Healing, summons and other slot-only spells require a numbered tier."
		return TRUE
	var/current = slots.get_current(slot_level)
	var/maximum = slots.get_max(slot_level)
	icon_state = get_spell_slot_icon_state(slot_level, current)
	alpha = maximum > 0 ? 255 : 110
	name = "[selected ? "Selected: " : ""]Level [slot_level] Spell Slot ([current]/[maximum])"
	desc = "Select level [slot_level] spell slot. Charges: [current]/[maximum]."
	return TRUE

/atom/movable/screen/spell_slot_hud/Click(location, control, params)
	. = ..()
	if(QDELETED(owner_mob) || usr != owner_mob)
		return
	owner_mob.get_spell_slots()?.select_level(slot_level)

/atom/movable/screen/spell_rest_hud
	name = "Short Rest"
	desc = "Lie down and click for a one-minute short rest, or right-click for five minutes of sleep to fully restore slots and rests."
	icon = 'icons/mob/actions/dnd_spell_slots.dmi'
	icon_state = "dnd_short_rest_2"
	mouse_opacity = MOUSE_OPACITY_ICON
	var/mob/living/carbon/human/owner_mob

/atom/movable/screen/spell_rest_hud/Destroy()
	owner_mob = null
	return ..()

/atom/movable/screen/spell_rest_hud/proc/refresh_rest_hud()
	var/datum/spell_slots/slots = owner_mob?.get_spell_slots()
	if(!slots)
		icon_state = "dnd_short_rest_0"
		return FALSE
	var/current = slots.get_short_rest_current()
	var/maximum = slots.get_short_rest_max()
	icon_state = get_spell_rest_icon_state(current)
	maptext = "<span class='maptext'>[current]/[maximum]</span>"
	name = "[slots.rest_in_progress ? "Resting" : "Short Rest"] ([current]/[maximum])"
	var/gate = slots.long_rest_ready_in()
	var/long_rest_text = gate > 0 ? "A long rest is ready in [DisplayTimeText(gate)]." : "A long rest is ready."
	var/feature_text = ""
	for(var/id in slots.features)
		feature_text += " [capitalize(replacetext(id, "_", " "))]: [slots.get_feature_charges(id)]/[slots.get_feature_max(id)]."
	desc = "Lie down and click to rest for 60 seconds, recovering up to [SHORT_REST_BUDGET] spell levels. The selected tier takes priority, then lower tiers; MIN prioritizes lower tiers. Right-click to sleep for five minutes and restore all slots, rests and powers. Movement, damage and combat interrupt recovery. Charges: [current]/[maximum]. [long_rest_text][feature_text]"
	return TRUE

/atom/movable/screen/spell_rest_hud/Click(location, control, params)
	. = ..()
	if(QDELETED(owner_mob) || usr != owner_mob)
		return
	var/list/modifiers = params2list(params)
	INVOKE_ASYNC(owner_mob, TYPE_PROC_REF(/mob/living/carbon/human, use_spell_rest), !!modifiers[RIGHT_CLICK])

/atom/movable/screen/spell_slots_toggle_hud
	name = "Toggle Spell Slots"
	desc = "Hide or show the spell slot HUD."
	icon = 'icons/mob/actions/dnd_spell_slots.dmi'
	icon_state = "dnd_slots_open"
	mouse_opacity = MOUSE_OPACITY_ICON
	var/mob/living/carbon/human/owner_mob

/atom/movable/screen/spell_slots_toggle_hud/Destroy()
	owner_mob = null
	return ..()

/atom/movable/screen/spell_slots_toggle_hud/proc/refresh_toggle_hud()
	var/datum/spell_slots/slots = owner_mob?.get_spell_slots()
	if(!slots)
		icon_state = "dnd_slots_closed"
		return FALSE
	if(slots.hud_collapsed)
		icon_state = "dnd_slots_closed"
		name = "Show Spell Slots"
		desc = "Show the spell slot HUD."
	else
		icon_state = "dnd_slots_open"
		name = "Hide Spell Slots"
		desc = "Hide the spell slot HUD."
	return TRUE

/atom/movable/screen/spell_slots_toggle_hud/Click(location, control, params)
	. = ..()
	if(QDELETED(owner_mob) || usr != owner_mob)
		return
	owner_mob.toggle_spell_slot_hud()

#undef SPELL_SLOT_ICON_MAX
