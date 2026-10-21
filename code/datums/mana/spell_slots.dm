/// Slot counts for levels 1 to 5 per arcane rank. Row index is rank + 1.
GLOBAL_LIST_INIT(spell_slot_ladders, list(
	CASTER_FULL = list(
		list(1, 0, 0, 0, 0),
		list(2, 0, 0, 0, 0),
		list(3, 2, 0, 0, 0),
		list(4, 3, 2, 0, 0),
		list(4, 3, 3, 1, 0),
		list(4, 3, 3, 2, 1),
		list(4, 3, 3, 3, 2),
	),
	CASTER_HALF = list(
		list(0, 0, 0, 0, 0),
		list(1, 0, 0, 0, 0),
		list(2, 0, 0, 0, 0),
		list(3, 1, 0, 0, 0),
		list(4, 2, 0, 0, 0),
		list(4, 3, 1, 0, 0),
		list(4, 3, 2, 0, 0),
	),
	CASTER_THIRD = list(
		list(0, 0, 0, 0, 0),
		list(1, 0, 0, 0, 0),
		list(1, 0, 0, 0, 0),
		list(2, 0, 0, 0, 0),
		list(3, 1, 0, 0, 0),
		list(3, 2, 0, 0, 0),
		list(4, 2, 1, 0, 0),
	),
))

/// Pact slots per arcane rank as list(count, level). Row index is rank + 1.
GLOBAL_LIST_INIT(pact_slot_ladder, list(
	list(2, 1),
	list(2, 1),
	list(3, 1),
	list(3, 2),
	list(3, 3),
	list(3, 4),
	list(4, 5),
))

#define FEATURE_CURRENT 1
#define FEATURE_MAX 2
#define FEATURE_REST 3

/datum/mind
	/// Slot, rest, feature and concentration state of a caster. Null for everyone else.
	var/datum/spell_slots/spell_slots

/// Creates the caster state, or re-archetypes an existing one.
/datum/mind/proc/setup_spell_slots(archetype = CASTER_FULL, rank_skill)
	RETURN_TYPE(/datum/spell_slots)
	if(!spell_slots)
		spell_slots = new(src, archetype, rank_skill)
		return spell_slots
	spell_slots.archetype = archetype
	if(rank_skill)
		spell_slots.rank_skill = rank_skill
	spell_slots.sync_to_rank(TRUE)
	return spell_slots

/// Creates slots from the assigned job's archetype when a slot spell arrives before the job did.
/mob/living/proc/ensure_spell_slots_for_job()
	if(!mind || mind.spell_slots)
		return mind?.spell_slots
	var/datum/job/role = mind.assigned_role
	if(!role?.caster_archetype)
		return null
	return mind.setup_spell_slots(role.caster_archetype, role.caster_rank_skill)

/datum/spell_slots
	var/datum/mind/mind
	var/archetype = CASTER_FULL
	/// Skill whose rank drives the ladder.
	var/rank_skill = /datum/attribute/skill/magic/arcane
	/// Level 1 to 5 maxima that replace the ladder; debug grants and tests use this.
	var/list/fixed_slots
	var/list/slots_max = list()
	var/list/slots_current = list()
	var/last_rank = -1
	var/selected_level = SPELL_SLOT_MIN
	var/short_rest_max = SHORT_REST_BASE_CHARGES
	var/short_rest_current = SHORT_REST_BASE_CHARGES
	var/extra_short_rest_unlocked = FALSE
	/// World time at which the next long rest may complete.
	var/next_long_rest = 0
	/// Feature id to list(current, max, rest flags).
	var/list/features = list()
	/// Metamagic id armed for the next eligible cast; null when none.
	var/armed_metamagic
	var/datum/weakref/concentration_ref
	var/hud_collapsed = FALSE
	var/datum/weakref/body_ref
	var/tmp/rest_in_progress = FALSE
	var/tmp/rest_interrupted = FALSE
	var/tmp/rest_last_health
	var/tmp/rest_started_at

/datum/spell_slots/New(datum/mind/owner, caster_archetype, skill)
	. = ..()
	mind = owner
	if(caster_archetype)
		archetype = caster_archetype
	if(skill)
		rank_skill = skill
	for(var/level in SPELL_SLOT_MIN to SPELL_SLOT_MAX)
		slots_max[num2text(level)] = 0
		slots_current[num2text(level)] = 0
	attach_body(mind?.current)
	sync_to_rank()

/datum/spell_slots/Destroy(force)
	detach_body()
	concentration_ref = null
	mind = null
	return ..()

/datum/spell_slots/proc/get_body()
	RETURN_TYPE(/mob/living)
	return mind?.current

/// Follows the mind into a new body: signals, rank sync and HUD.
/datum/spell_slots/proc/attach_body(mob/living/body)
	detach_body()
	if(!istype(body))
		return
	body_ref = WEAKREF(body)
	RegisterSignal(body, COMSIG_SKILL_RANK_CHANGE, PROC_REF(on_rank_change))
	RegisterSignal(body, COMSIG_LIVING_WOUND_GAINED, PROC_REF(on_wound))
	RegisterSignal(body, COMSIG_MOB_DEATH, PROC_REF(on_death))
	sync_to_rank()
	update_hud()

/datum/spell_slots/proc/detach_body()
	var/mob/living/old_body = body_ref?.resolve()
	body_ref = null
	rest_interrupted = TRUE
	if(!old_body)
		return
	UnregisterSignal(old_body, list(COMSIG_SKILL_RANK_CHANGE, COMSIG_LIVING_WOUND_GAINED, COMSIG_MOB_DEATH))
	if(ishuman(old_body))
		var/mob/living/carbon/human/human_body = old_body
		human_body.remove_spell_slot_hud()

/// Rank names as the ladder tables use them, index rank + 1.
/proc/get_caster_rank_name(rank)
	var/static/list/names
	names ||= list("Untrained", "Novice", "Apprentice", "Journeyman", "Expert", "Master", "Legendary")
	return names[clamp(round(rank), SKILL_RANK_NONE, SKILL_RANK_LEGENDARY) + 1]

/proc/get_caster_archetype_label(archetype)
	switch(archetype)
		if(CASTER_FULL)
			return "Full caster"
		if(CASTER_HALF)
			return "Half caster"
		if(CASTER_THIRD)
			return "Third caster"
		if(CASTER_PACT)
			return "Pact caster"
		if(CASTER_NONE)
			return "No spell slots"
	return "Caster"

/// Pact casters rest as often as they like; their slots are few and all come back at once.
/datum/spell_slots/proc/has_unlimited_short_rests()
	return archetype == CASTER_PACT

/// CASTER_NONE datums only hold feature pools; their owners cast slot spells the legacy way.
/datum/spell_slots/proc/has_slot_ladder()
	return archetype != CASTER_NONE

/datum/mind/proc/is_slot_caster()
	return !isnull(spell_slots) && spell_slots.has_slot_ladder()

/datum/spell_slots/proc/get_rank()
	var/mob/living/body = get_body()
	if(!body)
		return max(last_rank, 0)
	return clamp(round(body.get_skill_level(rank_skill)), SKILL_RANK_NONE, SKILL_RANK_LEGENDARY)

/datum/spell_slots/proc/on_rank_change(datum/source, skill_type, new_rank, old_rank)
	SIGNAL_HANDLER
	if(skill_type != rank_skill)
		return
	sync_to_rank()
	// Ladder casters earn mastery points per rank gained; a lost rank keeps them.
	if(has_slot_ladder() && new_rank > old_rank)
		mind?.spell_mastery?.pay_rank_points(new_rank, old_rank)

/// Level 1 to 5 maxima for a rank. Pact rows put every slot on one level.
/datum/spell_slots/proc/get_ladder_row(rank)
	var/list/row = list(0, 0, 0, 0, 0)
	if(fixed_slots)
		for(var/i in 1 to min(length(fixed_slots), SPELL_SLOT_MAX))
			row[i] = max(round(fixed_slots[i]), 0)
		return row
	rank = clamp(rank, SKILL_RANK_NONE, SKILL_RANK_LEGENDARY)
	if(archetype == CASTER_PACT)
		var/list/pact = GLOB.pact_slot_ladder[rank + 1]
		row[pact[2]] = pact[1]
		return row
	var/list/ladder = GLOB.spell_slot_ladders[archetype]
	if(!ladder)
		return row
	var/list/ladder_row = ladder[rank + 1]
	return ladder_row.Copy()

/// Applies the ladder for the current rank. New slots arrive filled; spent ones stay spent.
/datum/spell_slots/proc/sync_to_rank(force = FALSE)
	var/rank = get_rank()
	if(!force && rank == last_rank)
		return FALSE
	last_rank = rank
	var/list/row = get_ladder_row(rank)
	for(var/level in SPELL_SLOT_MIN to SPELL_SLOT_MAX)
		var/key = num2text(level)
		var/old_max = slots_max[key] || 0
		var/new_max = row[level]
		var/current = slots_current[key] || 0
		if(new_max > old_max)
			current += new_max - old_max
		slots_max[key] = new_max
		slots_current[key] = clamp(current, 0, new_max)
	// A numbered pact selection follows the pact level; a MIN selection stays.
	var/pact_level = get_pact_level()
	if(pact_level && get_selected_level() != SPELL_SLOT_MINOR)
		selected_level = pact_level
	update_hud()
	return TRUE

/// Level every pact slot shares; zero for other archetypes.
/datum/spell_slots/proc/get_pact_level()
	if(archetype != CASTER_PACT)
		return 0
	for(var/level in SPELL_SLOT_MAX to SPELL_SLOT_MIN step -1)
		if(get_max(level) > 0)
			return level
	return 0

/datum/spell_slots/proc/set_fixed_slots(list/maxima, refill = TRUE)
	fixed_slots = maxima?.Copy()
	sync_to_rank(TRUE)
	if(refill)
		restore_all_slots()

/datum/spell_slots/proc/get_max(level)
	return slots_max[num2text(round(level))] || 0

/datum/spell_slots/proc/get_current(level)
	return slots_current[num2text(round(level))] || 0

/datum/spell_slots/proc/get_selected_level()
	if(!isnum(selected_level))
		selected_level = SPELL_SLOT_MIN
	return clamp(round(selected_level), SPELL_SLOT_MINOR, SPELL_SLOT_MAX)

/datum/spell_slots/proc/has_any_slots()
	for(var/level in SPELL_SLOT_MIN to SPELL_SLOT_MAX)
		if(get_max(level) > 0)
			return TRUE
	return FALSE

/datum/spell_slots/proc/can_spend(level, feedback = TRUE)
	level = round(level)
	if(level < SPELL_SLOT_MIN || level > SPELL_SLOT_MAX)
		return FALSE
	var/mob/living/body = get_body()
	if(get_max(level) <= 0)
		if(feedback && body)
			to_chat(body, span_warning("I have no level [level] spell slots."))
			body.balloon_alert(body, "no level [level] slots!")
		return FALSE
	if(get_current(level) <= 0)
		if(feedback && body)
			to_chat(body, span_warning("My level [level] spell slots are spent."))
			body.balloon_alert(body, "level [level] slots spent!")
		return FALSE
	return TRUE

/datum/spell_slots/proc/spend(level)
	if(!can_spend(level, FALSE))
		return FALSE
	var/key = num2text(round(level))
	slots_current[key] = max(get_current(level) - 1, 0)
	update_hud()
	return TRUE

/// Restores up to amount slots of one level. Returns how many came back.
/datum/spell_slots/proc/restore(level, amount = 1)
	var/key = num2text(round(level))
	var/missing = get_max(level) - get_current(level)
	var/restored = clamp(round(amount), 0, missing)
	if(!restored)
		return 0
	slots_current[key] = get_current(level) + restored
	update_hud()
	return restored

/datum/spell_slots/proc/restore_all_slots()
	for(var/level in SPELL_SLOT_MIN to SPELL_SLOT_MAX)
		slots_current[num2text(level)] = get_max(level)
	update_hud()

/datum/spell_slots/proc/select_level(level)
	level = clamp(round(level), SPELL_SLOT_MINOR, SPELL_SLOT_MAX)
	if(level != SPELL_SLOT_MINOR && !can_spend(level, TRUE))
		return FALSE
	selected_level = level
	var/mob/living/body = get_body()
	if(body)
		if(level == SPELL_SLOT_MINOR)
			to_chat(body, span_notice("Minor casting selected. Supported spells use mana; slot-only spells cannot be cast."))
		else
			to_chat(body, span_notice("Selected level [level] spell slot. Charges: [get_current(level)]/[get_max(level)]."))
			body.balloon_alert(body, "level [level] selected")
	update_hud()
	return TRUE

/// Priority level first, then levels 1 to 5. Each restored slot costs its level from the budget.
/datum/spell_slots/proc/get_recovery(priority_level, budget = SHORT_REST_BUDGET)
	var/list/recovery = list()
	if(archetype == CASTER_PACT)
		for(var/level in SPELL_SLOT_MIN to SPELL_SLOT_MAX)
			var/missing = get_max(level) - get_current(level)
			if(missing > 0)
				recovery[num2text(level)] = missing
		return recovery
	var/list/levels = list(1, 2, 3, 4, 5)
	if(priority_level in levels)
		levels.Remove(priority_level)
		levels.Insert(1, priority_level)
	for(var/level in levels)
		var/missing = get_max(level) - get_current(level)
		var/amount = min(missing, round(budget / level))
		if(amount <= 0)
			continue
		recovery[num2text(level)] = amount
		budget -= amount * level
	return recovery

/datum/spell_slots/proc/apply_recovery(list/recovery)
	var/total = 0
	for(var/key in recovery)
		total += restore(text2num(key), recovery[key])
	return total

/datum/spell_slots/proc/get_short_rest_max()
	if(!isnum(short_rest_max))
		short_rest_max = SHORT_REST_BASE_CHARGES
	return clamp(round(short_rest_max), 0, SHORT_REST_ADVANCED_CHARGES)

/datum/spell_slots/proc/get_short_rest_current()
	if(!isnum(short_rest_current))
		short_rest_current = get_short_rest_max()
	return clamp(round(short_rest_current), 0, get_short_rest_max())

/// Adds one charge and raises the cap; never refills spent charges and cannot be farmed.
/datum/spell_slots/proc/unlock_extra_short_rest()
	if(extra_short_rest_unlocked)
		return FALSE
	extra_short_rest_unlocked = TRUE
	short_rest_max = SHORT_REST_ADVANCED_CHARGES
	short_rest_current = min(get_short_rest_current() + 1, short_rest_max)
	update_hud()
	return TRUE

/datum/spell_slots/proc/long_rest_ready_in()
	return max(next_long_rest - world.time, 0)

// Class feature charges

/datum/spell_slots/proc/add_feature(id, max_charges, rest_type = REST_LONG)
	var/list/feature = features[id]
	if(!feature)
		features[id] = list(max_charges, max_charges, rest_type)
		update_hud()
		return
	var/delta = max_charges - feature[FEATURE_MAX]
	feature[FEATURE_MAX] = max_charges
	feature[FEATURE_CURRENT] = clamp(feature[FEATURE_CURRENT] + max(delta, 0), 0, max_charges)
	feature[FEATURE_REST] = rest_type
	update_hud()

/datum/spell_slots/proc/has_feature(id)
	return !isnull(features[id])

/datum/spell_slots/proc/get_feature_charges(id)
	var/list/feature = features[id]
	return feature ? feature[FEATURE_CURRENT] : 0

/datum/spell_slots/proc/get_feature_max(id)
	var/list/feature = features[id]
	return feature ? feature[FEATURE_MAX] : 0

/datum/spell_slots/proc/get_feature_rest(id)
	var/list/feature = features[id]
	return feature ? feature[FEATURE_REST] : NONE

/datum/spell_slots/proc/use_feature(id, amount = 1)
	var/list/feature = features[id]
	if(!feature || amount <= 0 || feature[FEATURE_CURRENT] < amount)
		return FALSE
	feature[FEATURE_CURRENT] -= amount
	update_hud()
	return TRUE

/// Returns charges to a pool, capped at its size. Returns how many came back.
/datum/spell_slots/proc/restore_feature(id, amount = 1)
	var/list/feature = features[id]
	if(!feature || amount <= 0)
		return 0
	var/restored = min(round(amount), feature[FEATURE_MAX] - feature[FEATURE_CURRENT])
	if(restored <= 0)
		return 0
	feature[FEATURE_CURRENT] += restored
	update_hud()
	return restored

/datum/spell_slots/proc/refill_features(rest_type)
	for(var/id in features)
		var/list/feature = features[id]
		if(feature[FEATURE_REST] & rest_type)
			feature[FEATURE_CURRENT] = feature[FEATURE_MAX]

/datum/spell_slots/proc/features_need_refill(rest_type)
	for(var/id in features)
		var/list/feature = features[id]
		if((feature[FEATURE_REST] & rest_type) && feature[FEATURE_CURRENT] < feature[FEATURE_MAX])
			return TRUE
	return FALSE

// Metamagic

/// Arms one metamagic for the next cast it fits; null disarms.
/datum/spell_slots/proc/arm_metamagic(id)
	armed_metamagic = id
	update_hud()

/datum/spell_slots/proc/get_armed_metamagic()
	return armed_metamagic

/// Short-rest budget plus allies' bonuses, such as a bard's Song of Rest.
/datum/spell_slots/proc/get_short_rest_budget(mob/living/body)
	return SHORT_REST_BUDGET + (body ? body.get_rest_budget_bonus() : 0)

/// Extra short-rest budget levels from nearby effects; class files override this.
/mob/living/proc/get_rest_budget_bonus()
	return 0

// Concentration

/datum/spell_slots/proc/get_concentration()
	RETURN_TYPE(/datum/action/cooldown/spell)
	return concentration_ref?.resolve()

/// Starting a second concentration effect ends the first.
/datum/spell_slots/proc/start_concentration(datum/action/cooldown/spell/spell)
	var/datum/action/cooldown/spell/current = get_concentration()
	if(current && current != spell)
		current.break_concentration(CONCENTRATION_REPLACED)
	concentration_ref = WEAKREF(spell)

/// Drops tracking without ending the effect; spells call this when their effect ends on its own.
/datum/spell_slots/proc/clear_concentration(datum/action/cooldown/spell/spell)
	if(spell && get_concentration() != spell)
		return
	concentration_ref = null

/datum/spell_slots/proc/break_concentration(reason)
	var/datum/action/cooldown/spell/current = get_concentration()
	concentration_ref = null
	current?.break_concentration(reason)

/// A wound breaks concentration unless a constitution roll holds it.
/datum/spell_slots/proc/on_wound(datum/source, datum/wound/wound)
	SIGNAL_HANDLER
	var/datum/action/cooldown/spell/current = get_concentration()
	if(!current)
		return
	var/mob/living/body = get_body()
	if(!body)
		return
	var/result = body.diceroll(body.get_stat(STAT_CONSTITUTION), context = DICE_CONTEXT_MENTAL)
	if(result == DICE_SUCCESS || result == DICE_CRIT_SUCCESS)
		to_chat(body, span_notice("I hold my concentration on [current.name] through the pain."))
		return
	to_chat(body, span_warning("The wound breaks my concentration on [current.name]!"))
	break_concentration(CONCENTRATION_WOUNDED)

/datum/spell_slots/proc/on_death(datum/source)
	SIGNAL_HANDLER
	break_concentration(CONCENTRATION_DEATH)

// Rests

/datum/spell_slots/proc/rest_is_valid(mob/living/body, long_rest)
	if(rest_interrupted || QDELETED(body) || body.health <= 0 || body.stat == DEAD || body.next_move > rest_started_at)
		return FALSE
	if(long_rest)
		if(!body.IsSleeping())
			return FALSE
	else if(!body.resting || body.incapacitated())
		return FALSE
	for(var/datum/action/cooldown/spell/spell in body.actions)
		if(spell.currently_charging)
			return FALSE
	return TRUE

/datum/spell_slots/proc/interrupt_rest(datum/source)
	SIGNAL_HANDLER
	rest_interrupted = TRUE

/datum/spell_slots/proc/rest_damage(datum/source, damage)
	SIGNAL_HANDLER
	if(damage > 0)
		rest_interrupted = TRUE

/datum/spell_slots/proc/rest_health_changed(datum/source)
	SIGNAL_HANDLER
	var/mob/living/body = source
	if(body.health < rest_last_health)
		rest_interrupted = TRUE
	rest_last_health = body.health

/// Runs a short or long rest on the body. Silent rests come from the sleep hook and skip chatter.
/datum/spell_slots/proc/use_rest(long_rest = FALSE, silent = FALSE)
	var/mob/living/body = get_body()
	if(!body)
		return FALSE
	if(rest_in_progress)
		if(!silent)
			to_chat(body, span_warning("I am already resting."))
		return FALSE
	if(!has_any_slots() && !length(features))
		return FALSE
	var/priority_level = get_selected_level()
	var/list/recovery = get_recovery(priority_level, get_short_rest_budget(body))
	if(long_rest)
		if(world.time < next_long_rest)
			if(!silent)
				to_chat(body, span_warning("I am not weary enough for a true long rest. It will be ready in [DisplayTimeText(long_rest_ready_in())]."))
			return FALSE
		if(!length(recovery) && get_short_rest_current() >= get_short_rest_max() && !features_need_refill(REST_SHORT | REST_LONG))
			return FALSE
	else
		if(!has_unlimited_short_rests() && get_short_rest_current() <= 0)
			if(!silent)
				to_chat(body, span_warning("I have no short rests left. Sleep for five uninterrupted minutes to recover."))
			return FALSE
		if(!length(recovery) && !features_need_refill(REST_SHORT))
			if(!silent)
				to_chat(body, span_notice("My spell slots are already full."))
			return FALSE

	rest_started_at = world.time
	rest_interrupted = FALSE
	if(long_rest && !body.IsSleeping())
		if(!rest_is_valid(body, FALSE))
			if(!silent)
				to_chat(body, span_warning("I must lie down and stop fighting or casting before sleeping."))
			return FALSE
		// The Sleep verb only naps. Grant enough sleep for the whole rest.
		body.Sleeping(LONG_REST_DURATION + 5 SECONDS)
	if(!rest_is_valid(body, long_rest))
		if(!long_rest && !silent)
			to_chat(body, span_warning("I must lie down and stop fighting or casting before resting."))
		return FALSE

	rest_in_progress = TRUE
	rest_last_health = body.health
	var/static/list/interrupt_signals = list(
		COMSIG_MOVABLE_MOVED,
		COMSIG_MOB_ITEM_ATTACK,
		COMSIG_MOB_ITEM_AFTERATTACK,
		COMSIG_HUMAN_EARLY_UNARMED_ATTACK,
		COMSIG_MOB_ATTACK_RANGED,
		COMSIG_MOB_BEFORE_SPELL_CAST,
		COMSIG_LIVING_SET_RESTING,
	)
	RegisterSignal(body, interrupt_signals, PROC_REF(interrupt_rest))
	RegisterSignal(body, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(rest_damage))
	RegisterSignal(body, COMSIG_LIVING_HEALTH_UPDATE, PROC_REF(rest_health_changed))
	var/rest_duration = long_rest ? LONG_REST_DURATION : SHORT_REST_DURATION
	// Getting up leaves a do_after key behind for two seconds; it must not block a rest.
	var/rest_flags = IGNORE_SLOWDOWNS | IGNORE_HELD_ITEM | IGNORE_USER_DIR_CHANGE | IGNORE_USER_DOING
	if(long_rest)
		rest_flags |= IGNORE_INCAPACITATED
		if(!silent)
			to_chat(body, span_notice("I settle into a five-minute long rest. Waking, movement, damage or combat will interrupt recovery."))
	else if(archetype == CASTER_PACT)
		to_chat(body, span_notice("I begin a one-minute short rest that refills all my pact slots. Movement, damage or combat will interrupt it."))
	else if(archetype == CASTER_NONE)
		to_chat(body, span_notice("I begin a one-minute short rest to recover my powers. Movement, damage or combat will interrupt it."))
	else
		to_chat(body, span_notice("I begin a one-minute short rest. My selected tier takes priority, then lower tiers. Movement, damage or combat will interrupt it."))
	update_hud()
	// A sleeper gets no progress bar or cog over their head; the short rest keeps its bar.
	var/completed = do_after(body, rest_duration, target = body, timed_action_flags = rest_flags, progress = !long_rest, extra_checks = CALLBACK(src, PROC_REF(rest_is_valid), body, long_rest), interaction_key = "spell_rest", hidden = long_rest)
	if(QDELETED(src) || QDELETED(body))
		return FALSE
	UnregisterSignal(body, interrupt_signals)
	UnregisterSignal(body, list(COMSIG_MOB_APPLY_DAMAGE, COMSIG_LIVING_HEALTH_UPDATE))
	completed = completed && rest_is_valid(body, long_rest)
	rest_in_progress = FALSE
	update_hud()
	if(!completed)
		if(!silent)
			to_chat(body, span_warning("My rest was interrupted. No recovery was spent."))
		return FALSE
	if(long_rest)
		return finish_long_rest(body)
	return finish_short_rest(body, priority_level)

/// Spends a charge only when something actually came back.
/datum/spell_slots/proc/finish_short_rest(mob/living/body, priority_level)
	var/list/recovery = get_recovery(priority_level, get_short_rest_budget(body))
	if(!has_unlimited_short_rests() && get_short_rest_current() <= 0)
		return FALSE
	if(!length(recovery) && !features_need_refill(REST_SHORT))
		return FALSE
	apply_recovery(recovery)
	refill_features(REST_SHORT)
	if(!has_unlimited_short_rests())
		short_rest_current--
	update_hud()
	var/rest_text = "My short rest restores spell slots."
	if(archetype == CASTER_PACT)
		rest_text = "My short rest refills my pact slots."
	else if(archetype == CASTER_NONE)
		rest_text = "My short rest restores my powers."
	if(has_unlimited_short_rests())
		to_chat(body, span_notice(rest_text))
	else
		to_chat(body, span_notice("[rest_text] [get_short_rest_current()] short rests remain."))
	SEND_SIGNAL(mind, COMSIG_MIND_SPELL_REST, REST_SHORT)
	SEND_SIGNAL(body, COMSIG_LIVING_SPELL_REST, REST_SHORT)
	return TRUE

/datum/spell_slots/proc/finish_long_rest(mob/living/body)
	restore_all_slots()
	short_rest_current = get_short_rest_max()
	refill_features(REST_SHORT | REST_LONG)
	next_long_rest = world.time + LONG_REST_GATE
	update_hud()
	to_chat(body, span_notice("My sustained sleep restores all spell slots, short rests and powers."))
	SEND_SIGNAL(mind, COMSIG_MIND_SPELL_REST, REST_LONG)
	SEND_SIGNAL(body, COMSIG_LIVING_SPELL_REST, REST_LONG)
	return TRUE

/// Instant recovery for potions: one short rest's worth without time or a charge.
/datum/spell_slots/proc/grant_free_short_rest(budget = SHORT_REST_BUDGET)
	var/list/recovery = get_recovery(get_selected_level(), budget)
	var/restored = apply_recovery(recovery)
	refill_features(REST_SHORT)
	update_hud()
	return restored

/// Archetype and skill behind the slots, the ladder now and at the next rank, rests and pools, for any UI.
/datum/spell_slots/proc/get_ui_info()
	var/mob/living/body = get_body()
	var/rank = get_rank()
	var/datum/attribute/skill/skill_path = rank_skill
	var/list/current = list()
	var/list/maximum = list()
	for(var/level in SPELL_SLOT_MIN to SPELL_SLOT_MAX)
		current += get_current(level)
		maximum += get_max(level)
	var/has_next = rank < SKILL_RANK_LEGENDARY
	var/list/pools = list()
	for(var/id in features)
		pools += list(list(
			"name" = capitalize(replacetext(id, "_", " ")),
			"current" = get_feature_charges(id),
			"max" = get_feature_max(id),
			"rest" = (get_feature_rest(id) & REST_SHORT) ? "short rest" : "long rest",
		))
	var/gate = long_rest_ready_in()
	return list(
		"archetype" = get_caster_archetype_label(archetype),
		"hasLadder" = has_slot_ladder(),
		"skillName" = initial(skill_path.name),
		"rank" = rank,
		"rankName" = get_caster_rank_name(rank),
		"skillValue" = body ? round(body.get_skill_level(rank_skill) * 10) : rank * 10,
		"nextRankName" = has_next ? get_caster_rank_name(rank + 1) : null,
		"nextRankValue" = has_next ? (rank + 1) * 10 : null,
		"current" = current,
		"maximum" = maximum,
		"nextMaximum" = has_next ? get_ladder_row(rank + 1) : null,
		"pactLevel" = get_pact_level(),
		"shortRests" = get_short_rest_current(),
		"shortRestsMax" = get_short_rest_max(),
		"unlimitedShortRests" = has_unlimited_short_rests(),
		"longRestIn" = gate > 0 ? DisplayTimeText(gate) : null,
		"pools" = pools,
	)

/datum/spell_slots/proc/update_hud()
	var/mob/living/body = get_body()
	if(!body)
		return
	if(ishuman(body))
		var/mob/living/carbon/human/human_body = body
		human_body.update_spell_slot_hud()
	for(var/datum/action/cooldown/spell/spell in body.actions)
		var/update_flags = NONE
		if(spell.uses_spell_slots())
			update_flags |= UPDATE_BUTTON_STATUS|UPDATE_BUTTON_BACKGROUND
		if(spell.feature_id)
			update_flags |= UPDATE_BUTTON_NAME|UPDATE_BUTTON_STATUS
		if(update_flags)
			spell.build_all_button_icons(update_flags)
	SEND_SIGNAL(body, COMSIG_LIVING_SPELL_SLOTS_UPDATED)

#undef FEATURE_CURRENT
#undef FEATURE_MAX
#undef FEATURE_REST
