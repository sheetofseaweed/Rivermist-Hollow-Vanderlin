// Core DND spell slot system.
// Required by DND spell helpers, debug grants, and life.dm restore calls.
// Load this file in the .dme before/alongside the DND spell helper files.
// The old debug_grant_dnd_fireball() verb was intentionally removed here; use dnd_spell_grant_debug.dm instead.

#define DND_SPELL_SLOT_MIN 1
#define DND_SPELL_SLOT_MAX 5
#define DND_SPELL_SLOT_ICON_MAX 4

/mob/living/carbon/human
	var/selected_dnd_spell_slot_level = DND_SPELL_SLOT_MIN
	var/list/dnd_spell_slots_max
	var/list/dnd_spell_slots_current
	var/list/dnd_spell_slot_hud_buttons
	var/dnd_short_rest_max = DND_SHORT_REST_BASE_CHARGES
	var/dnd_short_rest_current = DND_SHORT_REST_BASE_CHARGES
	var/dnd_extra_short_rest_unlocked = FALSE
	var/tmp/dnd_rest_in_progress = FALSE
	var/tmp/dnd_rest_interrupted = FALSE
	var/tmp/dnd_rest_last_health
	var/tmp/dnd_rest_started_at
	var/dnd_spell_slots_collapsed = FALSE
	var/atom/movable/screen/dnd_short_rest_hud/dnd_short_rest_hud_button
	var/atom/movable/screen/dnd_spell_slots_toggle_hud/dnd_spell_slots_toggle_hud_button

/mob/living/carbon/human/proc/setup_dnd_spell_slots(list/slot_table)
	if(!slot_table)
		return FALSE

	dnd_spell_slots_max = list()
	dnd_spell_slots_current = list()

	for(var/level_key in slot_table)
		var/slot_level = text2num("[level_key]")
		if(!slot_level)
			continue

		slot_level = clamp(round(slot_level), DND_SPELL_SLOT_MIN, DND_SPELL_SLOT_MAX)

		var/amount = slot_table[level_key]
		if(!isnum(amount))
			continue

		amount = max(round(amount), 0)

		var/key = num2text(slot_level)
		dnd_spell_slots_max[key] = amount
		dnd_spell_slots_current[key] = amount

	update_dnd_spell_slot_hud()
	return TRUE

/mob/living/carbon/human/proc/setup_default_dnd_spell_slots()
	var/list/default_slots = list()
	default_slots["1"] = 4
	default_slots["2"] = 3
	default_slots["3"] = 3
	default_slots["4"] = 2
	default_slots["5"] = 1

	setup_dnd_spell_slots(default_slots)
	dnd_short_rest_max = dnd_extra_short_rest_unlocked ? DND_SHORT_REST_ADVANCED_CHARGES : DND_SHORT_REST_BASE_CHARGES
	dnd_short_rest_current = dnd_short_rest_max
	update_dnd_short_rest_hud()
	update_dnd_spell_slots_toggle_hud()
	return TRUE

/mob/living/carbon/human/proc/restore_all_dnd_spell_slots()
	if(!dnd_spell_slots_max)
		return FALSE

	if(!dnd_spell_slots_current)
		dnd_spell_slots_current = list()

	for(var/key in dnd_spell_slots_max)
		dnd_spell_slots_current[key] = dnd_spell_slots_max[key]

	dnd_short_rest_current = dnd_short_rest_max

	update_dnd_spell_slot_hud()
	update_dnd_short_rest_hud()
	update_dnd_spell_slots_toggle_hud()
	return TRUE

/mob/living/carbon/human/proc/get_selected_dnd_spell_slot_level()
	if(!isnum(selected_dnd_spell_slot_level))
		selected_dnd_spell_slot_level = DND_SPELL_SLOT_MIN

	return clamp(round(selected_dnd_spell_slot_level), DND_MINOR_TIER, DND_SPELL_SLOT_MAX)

/mob/living/carbon/human/proc/get_dnd_spell_slots_current(level)
	if(!dnd_spell_slots_current)
		return 0

	var/key = num2text(round(level))
	var/amount = dnd_spell_slots_current[key]

	if(!isnum(amount))
		return 0

	return max(round(amount), 0)

/mob/living/carbon/human/proc/get_dnd_spell_slots_max(level)
	if(!dnd_spell_slots_max)
		return 0

	var/key = num2text(round(level))
	var/amount = dnd_spell_slots_max[key]

	if(!isnum(amount))
		return 0

	return max(round(amount), 0)

/mob/living/carbon/human/proc/get_dnd_short_rest_current()
	if(!isnum(dnd_short_rest_current))
		dnd_short_rest_current = get_dnd_short_rest_max()

	return clamp(round(dnd_short_rest_current), 0, get_dnd_short_rest_max())

/mob/living/carbon/human/proc/get_dnd_short_rest_max()
	if(!isnum(dnd_short_rest_max))
		dnd_short_rest_max = DND_SHORT_REST_BASE_CHARGES

	return clamp(round(dnd_short_rest_max), 0, DND_SHORT_REST_ADVANCED_CHARGES)

/mob/living/carbon/human/proc/can_spend_dnd_spell_slot(level, feedback = TRUE)
	level = clamp(round(level), DND_SPELL_SLOT_MIN, DND_SPELL_SLOT_MAX)

	if(!dnd_spell_slots_max || !dnd_spell_slots_current)
		return FALSE

	if(get_dnd_spell_slots_max(level) <= 0)
		if(feedback)
			to_chat(src, span_warning("I have no level [level] spell slots."))
			balloon_alert(src, "no level [level] slots!")
		return FALSE

	if(get_dnd_spell_slots_current(level) <= 0)
		if(feedback)
			to_chat(src, span_warning("My level [level] spell slots are spent."))
			balloon_alert(src, "level [level] slots spent!")
		return FALSE

	return TRUE

/mob/living/carbon/human/proc/spend_dnd_spell_slot(level)
	level = clamp(round(level), DND_SPELL_SLOT_MIN, DND_SPELL_SLOT_MAX)

	if(!can_spend_dnd_spell_slot(level, FALSE))
		return FALSE

	var/key = num2text(level)
	dnd_spell_slots_current[key] = max(get_dnd_spell_slots_current(level) - 1, 0)

	update_dnd_spell_slot_hud()
	return TRUE

/mob/living/carbon/human/proc/select_dnd_spell_slot(level)
	level = clamp(round(level), DND_MINOR_TIER, DND_SPELL_SLOT_MAX)

	if(!dnd_spell_slots_max || !dnd_spell_slots_current)
		return FALSE

	if(level != DND_MINOR_TIER && !can_spend_dnd_spell_slot(level, TRUE))
		return FALSE

	selected_dnd_spell_slot_level = level
	if(level == DND_MINOR_TIER)
		to_chat(src, span_notice("Minor casting selected. Supported spells use mana; slot-only spells cannot be cast."))
		update_dnd_spell_slot_hud()
		return TRUE

	var/current = get_dnd_spell_slots_current(level)
	var/maximum = get_dnd_spell_slots_max(level)

	to_chat(src, span_notice("Selected level [level] spell slot. Charges: [current]/[maximum]."))
	balloon_alert(src, "level [level] selected")

	update_dnd_spell_slot_hud()
	return TRUE

/mob/living/carbon/human/proc/unlock_dnd_extra_short_rest()
	if(dnd_extra_short_rest_unlocked)
		return
	dnd_extra_short_rest_unlocked = TRUE
	dnd_short_rest_max = DND_SHORT_REST_ADVANCED_CHARGES
	dnd_short_rest_current = min(dnd_short_rest_current + 1, dnd_short_rest_max)
	update_dnd_short_rest_hud()

/// Prioritize the chosen tier, then recover cheaper slots with the remaining budget.
/mob/living/carbon/human/proc/get_dnd_short_rest_recovery(priority_level)
	var/list/recovery = list()
	var/list/levels = list(1, 2, 3, 4, 5)
	if(priority_level in levels)
		levels.Remove(priority_level)
		levels.Insert(1, priority_level)
	var/budget = DND_SHORT_REST_BUDGET
	for(var/level in levels)
		var/missing = get_dnd_spell_slots_max(level) - get_dnd_spell_slots_current(level)
		var/amount = min(missing, round(budget / level))
		if(amount <= 0)
			continue
		recovery[num2text(level)] = amount
		budget -= amount * level
	return recovery

/mob/living/carbon/human/proc/dnd_rest_is_valid(long_rest)
	if(dnd_rest_interrupted || health <= 0 || stat == DEAD || next_move > dnd_rest_started_at)
		return FALSE
	if(long_rest)
		if(!IsSleeping())
			return FALSE
	else if(!resting || incapacitated())
		return FALSE
	for(var/datum/action/cooldown/spell/spell in actions)
		if(spell.currently_charging)
			return FALSE
	return TRUE

/mob/living/carbon/human/proc/interrupt_dnd_rest(datum/source)
	SIGNAL_HANDLER
	dnd_rest_interrupted = TRUE

/mob/living/carbon/human/proc/dnd_rest_damage(datum/source, damage)
	SIGNAL_HANDLER
	if(damage > 0)
		dnd_rest_interrupted = TRUE

/mob/living/carbon/human/proc/dnd_rest_health_changed(datum/source)
	SIGNAL_HANDLER
	if(health < dnd_rest_last_health)
		dnd_rest_interrupted = TRUE
	dnd_rest_last_health = health

/mob/living/carbon/human/proc/use_dnd_rest(long_rest = FALSE)
	if(dnd_rest_in_progress || doing() || !dnd_spell_slots_max || !dnd_spell_slots_current)
		return FALSE
	var/priority_level = get_selected_dnd_spell_slot_level()
	var/list/recovery = get_dnd_short_rest_recovery(priority_level)
	if(long_rest)
		if(!length(recovery) && get_dnd_short_rest_current() >= get_dnd_short_rest_max())
			return FALSE
	else
		if(get_dnd_short_rest_current() <= 0)
			to_chat(src, span_warning("I have no short rests left. Sleep for five uninterrupted minutes to recover."))
			return FALSE
		if(!length(recovery))
			to_chat(src, span_notice("My spell slots are already full."))
			return FALSE

	dnd_rest_started_at = world.time
	dnd_rest_interrupted = FALSE
	if(long_rest && !IsSleeping())
		if(!dnd_rest_is_valid(FALSE))
			to_chat(src, span_warning("I must lie down and stop fighting or casting before sleeping."))
			return FALSE
		// The ordinary Sleep verb only provides a short nap. Allow enough time for this rest to finish.
		Sleeping(DND_LONG_REST_DURATION + 5 SECONDS)
	if(!dnd_rest_is_valid(long_rest))
		if(!long_rest)
			to_chat(src, span_warning("I must lie down and stop fighting or casting before resting."))
		return FALSE
	dnd_rest_in_progress = TRUE
	dnd_rest_last_health = health
	var/static/list/interrupt_signals = list(
		COMSIG_MOVABLE_MOVED,
		COMSIG_MOB_ITEM_ATTACK,
		COMSIG_MOB_ITEM_AFTERATTACK,
		COMSIG_HUMAN_EARLY_UNARMED_ATTACK,
		COMSIG_MOB_ATTACK_RANGED,
		COMSIG_MOB_BEFORE_SPELL_CAST,
		COMSIG_LIVING_SET_RESTING,
	)
	RegisterSignal(src, interrupt_signals, PROC_REF(interrupt_dnd_rest))
	RegisterSignal(src, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(dnd_rest_damage))
	RegisterSignal(src, COMSIG_LIVING_HEALTH_UPDATE, PROC_REF(dnd_rest_health_changed))
	var/rest_duration = long_rest ? DND_LONG_REST_DURATION : DND_SHORT_REST_DURATION
	var/rest_flags = IGNORE_SLOWDOWNS | IGNORE_HELD_ITEM | IGNORE_USER_DIR_CHANGE
	if(long_rest)
		rest_flags |= IGNORE_INCAPACITATED
		to_chat(src, span_notice("I settle into a five-minute long rest. Waking, movement, damage or combat will interrupt recovery."))
	else
		to_chat(src, span_notice("I begin a one-minute short rest. My selected tier takes priority, then lower tiers. Movement, damage or combat will interrupt it."))
	update_dnd_short_rest_hud()
	var/completed = do_after(src, rest_duration, target = src, timed_action_flags = rest_flags, extra_checks = CALLBACK(src, PROC_REF(dnd_rest_is_valid), long_rest), interaction_key = "dnd_rest")
	if(QDELETED(src))
		return FALSE
	UnregisterSignal(src, interrupt_signals)
	UnregisterSignal(src, list(COMSIG_MOB_APPLY_DAMAGE, COMSIG_LIVING_HEALTH_UPDATE))
	completed = completed && dnd_rest_is_valid(long_rest)
	dnd_rest_in_progress = FALSE
	update_dnd_short_rest_hud()
	if(!completed)
		to_chat(src, span_warning("My rest was interrupted. No recovery was spent."))
		return FALSE
	if(long_rest)
		restore_all_dnd_spell_slots()
		to_chat(src, span_notice("My sustained sleep restores all spell slots and short rests."))
		return TRUE

	// Recheck reserves after the timed action; never spend a charge for no recovery.
	recovery = get_dnd_short_rest_recovery(priority_level)
	if(!length(recovery) || get_dnd_short_rest_current() <= 0)
		return FALSE
	for(var/key in recovery)
		dnd_spell_slots_current[key] = get_dnd_spell_slots_current(text2num(key)) + recovery[key]
	dnd_short_rest_current--
	update_dnd_spell_slot_hud()
	update_dnd_short_rest_hud()
	to_chat(src, span_notice("My short rest restores spell slots. [get_dnd_short_rest_current()] short rests remain."))
	return TRUE

/mob/living/carbon/human/proc/grant_dnd_spell_hud()
	if(!client)
		return FALSE

	if(!dnd_spell_slots_max || !dnd_spell_slots_current)
		setup_default_dnd_spell_slots()

	grant_dnd_spell_slots_toggle_hud()
	grant_dnd_short_rest_hud()
	grant_dnd_spell_slot_hud()
	apply_dnd_spell_hud_visibility()
	return TRUE

/mob/living/carbon/human/proc/grant_dnd_spell_slot_hud()
	if(!client)
		return FALSE

	if(!dnd_spell_slots_max || !dnd_spell_slots_current)
		setup_default_dnd_spell_slots()

	if(!dnd_spell_slot_hud_buttons)
		dnd_spell_slot_hud_buttons = list()

	for(var/level in DND_MINOR_TIER to DND_SPELL_SLOT_MAX)
		var/already_has_button = FALSE

		for(var/atom/movable/screen/dnd_spell_slot_hud/existing_button in dnd_spell_slot_hud_buttons)
			if(existing_button && existing_button.slot_level == level)
				already_has_button = TRUE
				break

		if(already_has_button)
			continue

		var/atom/movable/screen/dnd_spell_slot_hud/button = new
		button.owner_mob = src
		button.slot_level = level
		button.screen_loc = get_dnd_spell_slot_screen_loc(level)
		dnd_spell_slot_hud_buttons += button
		client.screen += button

	update_dnd_spell_slot_hud()
	return TRUE

/mob/living/carbon/human/proc/grant_dnd_short_rest_hud()
	if(!client)
		return FALSE

	if(!isnum(dnd_short_rest_current))
		dnd_short_rest_current = get_dnd_short_rest_max()

	if(dnd_short_rest_hud_button)
		dnd_short_rest_hud_button.refresh_dnd_short_rest_hud()
		return dnd_short_rest_hud_button

	var/atom/movable/screen/dnd_short_rest_hud/button = new
	button.owner_mob = src
	button.screen_loc = get_dnd_short_rest_screen_loc()
	dnd_short_rest_hud_button = button
	client.screen += button

	update_dnd_short_rest_hud()
	return button

/mob/living/carbon/human/proc/grant_dnd_spell_slots_toggle_hud()
	if(!client)
		return FALSE

	if(dnd_spell_slots_toggle_hud_button)
		dnd_spell_slots_toggle_hud_button.refresh_dnd_spell_slots_toggle_hud()
		return dnd_spell_slots_toggle_hud_button

	var/atom/movable/screen/dnd_spell_slots_toggle_hud/button = new
	button.owner_mob = src
	button.screen_loc = get_dnd_spell_slots_toggle_screen_loc()
	dnd_spell_slots_toggle_hud_button = button
	client.screen += button

	update_dnd_spell_slots_toggle_hud()
	return button

/mob/living/carbon/human/proc/toggle_dnd_spell_hud()
	dnd_spell_slots_collapsed = !dnd_spell_slots_collapsed

	if(!dnd_spell_slots_toggle_hud_button)
		grant_dnd_spell_slots_toggle_hud()

	apply_dnd_spell_hud_visibility()
	update_dnd_spell_slots_toggle_hud()

	return TRUE

/mob/living/carbon/human/proc/apply_dnd_spell_hud_visibility()
	if(!client)
		return FALSE

	var/hud_hidden = hud_used?.hud_version == HUD_STYLE_NOHUD

	if(dnd_spell_slot_hud_buttons)
		for(var/atom/movable/screen/dnd_spell_slot_hud/button as anything in dnd_spell_slot_hud_buttons)
			if(!button)
				continue

			if(hud_hidden || dnd_spell_slots_collapsed)
				client.screen -= button
			else
				if(!(button in client.screen))
					client.screen += button

	if(dnd_short_rest_hud_button)
		if(hud_hidden || dnd_spell_slots_collapsed)
			client.screen -= dnd_short_rest_hud_button
		else
			if(!(dnd_short_rest_hud_button in client.screen))
				client.screen += dnd_short_rest_hud_button

	if(dnd_spell_slots_toggle_hud_button)
		if(hud_hidden)
			client.screen -= dnd_spell_slots_toggle_hud_button
		else if(!(dnd_spell_slots_toggle_hud_button in client.screen))
			client.screen += dnd_spell_slots_toggle_hud_button

	return TRUE

/mob/living/carbon/human/proc/remove_dnd_spell_hud()
	remove_dnd_spell_slot_hud()
	remove_dnd_short_rest_hud()
	remove_dnd_spell_slots_toggle_hud()

/mob/living/carbon/human/proc/remove_dnd_spell_slot_hud()
	if(!dnd_spell_slot_hud_buttons)
		return

	for(var/atom/movable/screen/dnd_spell_slot_hud/button as anything in dnd_spell_slot_hud_buttons)
		if(client)
			client.screen -= button
		qdel(button)

	dnd_spell_slot_hud_buttons = null

/mob/living/carbon/human/proc/remove_dnd_short_rest_hud()
	if(!dnd_short_rest_hud_button)
		return

	if(client)
		client.screen -= dnd_short_rest_hud_button

	qdel(dnd_short_rest_hud_button)
	dnd_short_rest_hud_button = null

/mob/living/carbon/human/proc/remove_dnd_spell_slots_toggle_hud()
	if(!dnd_spell_slots_toggle_hud_button)
		return

	if(client)
		client.screen -= dnd_spell_slots_toggle_hud_button

	qdel(dnd_spell_slots_toggle_hud_button)
	dnd_spell_slots_toggle_hud_button = null

/mob/living/carbon/human/proc/update_dnd_spell_slot_hud()
	for(var/atom/movable/screen/dnd_spell_slot_hud/button as anything in dnd_spell_slot_hud_buttons)
		if(button)
			button.refresh_dnd_slot_hud()
	for(var/datum/action/cooldown/spell/spell in actions)
		if(spell.dnd_use_spell_slots)
			spell.build_all_button_icons(UPDATE_BUTTON_STATUS|UPDATE_BUTTON_BACKGROUND)

/mob/living/carbon/human/proc/update_dnd_short_rest_hud()
	if(dnd_short_rest_hud_button)
		dnd_short_rest_hud_button.refresh_dnd_short_rest_hud()

/mob/living/carbon/human/proc/update_dnd_spell_slots_toggle_hud()
	if(dnd_spell_slots_toggle_hud_button)
		dnd_spell_slots_toggle_hud_button.refresh_dnd_spell_slots_toggle_hud()

/proc/get_dnd_spell_slot_icon_state(level, charges)
	level = clamp(round(level), DND_SPELL_SLOT_MIN, DND_SPELL_SLOT_MAX)
	charges = clamp(round(charges), 0, DND_SPELL_SLOT_ICON_MAX)

	return "dnd_slot_[level]_[charges]"

/proc/get_dnd_short_rest_icon_state(charges)
	charges = clamp(round(charges), 0, DND_SHORT_REST_BASE_CHARGES) // The existing sprites stop at two; maptext shows the actual count.

	return "dnd_short_rest_[charges]"

/proc/get_dnd_spell_slot_screen_loc(level)
	switch(level)
		if(DND_MINOR_TIER)
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

/proc/get_dnd_short_rest_screen_loc()
	return "CENTER-2,SOUTH+2"

/proc/get_dnd_spell_slots_toggle_screen_loc()
	return "CENTER-3,SOUTH+2"

/atom/movable/screen/dnd_spell_slot_hud
	name = "Spell Slot"
	desc = "Selects a spell slot."
	icon = 'icons/mob/actions/dnd_spell_slots.dmi'
	icon_state = "dnd_slot_1_0"
	mouse_opacity = MOUSE_OPACITY_ICON

	var/slot_level = 1
	var/mob/living/carbon/human/owner_mob

/atom/movable/screen/dnd_spell_slot_hud/Destroy()
	owner_mob = null
	return ..()

/atom/movable/screen/dnd_spell_slot_hud/proc/refresh_dnd_slot_hud()
	if(!owner_mob)
		icon_state = get_dnd_spell_slot_icon_state(slot_level, 0)
		return FALSE

	var/selected = owner_mob.get_selected_dnd_spell_slot_level() == slot_level
	color = selected ? "#ffe080" : "#ffffff"
	if(slot_level == DND_MINOR_TIER)
		icon_state = "dnd_slot_1_0"
		maptext = "<span class='maptext'>MIN</span>"
		name = "[selected ? "Selected: " : ""]Minor Casting (Mana)"
		desc = "Cast supported minor forms using mana. Healing, summons and other slot-only spells require a numbered tier."
		return TRUE

	var/current = owner_mob.get_dnd_spell_slots_current(slot_level)
	var/maximum = owner_mob.get_dnd_spell_slots_max(slot_level)

	icon_state = get_dnd_spell_slot_icon_state(slot_level, current)
	name = "[selected ? "Selected: " : ""]Level [slot_level] Spell Slot ([current]/[maximum])"
	desc = "Select level [slot_level] spell slot. Charges: [current]/[maximum]."
	return TRUE

/atom/movable/screen/dnd_spell_slot_hud/Click(location, control, params)
	. = ..()

	if(QDELETED(owner_mob) || usr != owner_mob)
		return

	owner_mob.select_dnd_spell_slot(slot_level)

/atom/movable/screen/dnd_short_rest_hud
	name = "Short Rest"
	desc = "Lie down and click for a one-minute short rest, or right-click for five minutes of sleep to fully restore slots and rests."
	icon = 'icons/mob/actions/dnd_spell_slots.dmi'
	icon_state = "dnd_short_rest_2"
	mouse_opacity = MOUSE_OPACITY_ICON

	var/mob/living/carbon/human/owner_mob

/atom/movable/screen/dnd_short_rest_hud/Destroy()
	owner_mob = null
	return ..()

/atom/movable/screen/dnd_short_rest_hud/proc/refresh_dnd_short_rest_hud()
	if(!owner_mob)
		icon_state = "dnd_short_rest_0"
		return FALSE

	var/current = owner_mob.get_dnd_short_rest_current()
	var/maximum = owner_mob.get_dnd_short_rest_max()

	icon_state = get_dnd_short_rest_icon_state(current)
	maptext = "<span class='maptext'>[current]/[maximum]</span>"
	name = "[owner_mob.dnd_rest_in_progress ? "Resting" : "Short Rest"] ([current]/[maximum])"
	desc = "Lie down and click to rest for 60 seconds, recovering up to 8 spell levels. The selected tier takes priority, then lower tiers; MIN prioritizes lower tiers. Right-click to sleep for five minutes and restore all slots and rest charges. Movement, damage and combat interrupt recovery. Charges: [current]/[maximum]."
	return TRUE

/atom/movable/screen/dnd_short_rest_hud/Click(location, control, params)
	. = ..()

	if(QDELETED(owner_mob) || usr != owner_mob)
		return

	var/list/modifiers = params2list(params)
	owner_mob.use_dnd_rest(long_rest = modifiers[RIGHT_CLICK])

/atom/movable/screen/dnd_spell_slots_toggle_hud
	name = "Toggle Spell Slots"
	desc = "Hide or show spell slot HUD."
	icon = 'icons/mob/actions/dnd_spell_slots.dmi'
	icon_state = "dnd_slots_open"
	mouse_opacity = MOUSE_OPACITY_ICON

	var/mob/living/carbon/human/owner_mob

/atom/movable/screen/dnd_spell_slots_toggle_hud/Destroy()
	owner_mob = null
	return ..()

/atom/movable/screen/dnd_spell_slots_toggle_hud/proc/refresh_dnd_spell_slots_toggle_hud()
	if(!owner_mob)
		icon_state = "dnd_slots_closed"
		return FALSE

	if(owner_mob.dnd_spell_slots_collapsed)
		icon_state = "dnd_slots_closed"
		name = "Show Spell Slots"
		desc = "Show spell slot HUD."
	else
		icon_state = "dnd_slots_open"
		name = "Hide Spell Slots"
		desc = "Hide spell slot HUD."

	return TRUE

/atom/movable/screen/dnd_spell_slots_toggle_hud/Click(location, control, params)
	. = ..()

	if(QDELETED(owner_mob) || usr != owner_mob)
		return

	owner_mob.toggle_dnd_spell_hud()

#undef DND_SPELL_SLOT_MIN
#undef DND_SPELL_SLOT_MAX
#undef DND_SPELL_SLOT_ICON_MAX
