// Spell mastery: form and technique tracks, learned spells and the prepared set. Owned by the mind.

/datum/mind
	/// Forms, techniques, learned and prepared spells. Null until a caster needs it.
	var/datum/spell_mastery/spell_mastery

/datum/mind/proc/get_spell_mastery()
	RETURN_TYPE(/datum/spell_mastery)
	if(!spell_mastery)
		spell_mastery = new(src)
	return spell_mastery

/datum/spell_mastery
	var/datum/mind/owner
	/// Technique define to points invested.
	var/list/technique_levels = list()
	/// Form define to points invested.
	var/list/form_levels = list()
	/// Free points, spendable only on form tracks.
	var/unspent_form_points = 0
	/// Free points, spendable only on technique tracks.
	var/unspent_technique_points = 0
	var/initial_form_points = 0
	var/initial_technique_points = 0
	/// Track define to points left for buying spells under it.
	var/list/spendable_form_points = list()
	var/list/spendable_technique_points = list()
	var/total_form_points_earned = 0
	var/total_technique_points_earned = 0
	/// Learned spell typepaths.
	var/list/unlocked_spells = list()
	/// Spell typepath to its persistent action, so cooldowns survive un-preparing.
	var/list/granted_actions = list()
	/// Wizards prepare slot spells from a grimoire; innate casters cast everything they know.
	var/uses_preparation = FALSE
	/// Forms this craft may study, set by the job; null leaves every form open, as for wizards.
	var/list/allowed_forms
	/// Job spawn points land once, whichever of the job and its advanced class runs first.
	var/job_points_granted = FALSE
	var/list/prepared_spells = list()
	/// The grimoire preparing needs at hand; a long rest recalls it.
	var/datum/weakref/bound_book_ref
	/// Set when a bound grimoire was destroyed, so the next long rest replaces it.
	var/bound_book_lost = FALSE
	var/datum/weakref/body_ref
	/// The one spellbook window for this mastery; reopening updates it instead of stacking windows.
	var/datum/spellbook/ui

/datum/spell_mastery/New(datum/mind/mind)
	. = ..()
	owner = mind
	RegisterSignal(owner, COMSIG_MIND_SPELL_REST, PROC_REF(on_rest))
	on_body_changed(owner?.current)

/datum/spell_mastery/Destroy(force)
	QDEL_NULL(ui)
	remove_granted_spells()
	for(var/spell_path in granted_actions)
		qdel(granted_actions[spell_path])
	granted_actions = null
	unlocked_spells = null
	prepared_spells = null
	technique_levels = null
	form_levels = null
	spendable_form_points = null
	spendable_technique_points = null
	if(owner)
		UnregisterSignal(owner, COMSIG_MIND_SPELL_REST)
	owner = null
	bound_book_ref = null
	body_ref = null
	return ..()

/datum/spell_mastery/proc/get_body()
	RETURN_TYPE(/mob/living)
	return owner?.current

/datum/spell_mastery/proc/get_mastery_user()
	return get_body()

/// Opens or refreshes the single spellbook window for user.
/datum/spell_mastery/proc/open_ui(mob/living/user)
	if(!user)
		return
	if(!ui)
		ui = new(user, src)
	ui.owner = user
	ui.ui_interact(user)

/// Moves the granted actions from the old body to the new one.
/datum/spell_mastery/proc/on_body_changed(mob/living/body)
	remove_granted_spells()
	body_ref = istype(body) ? WEAKREF(body) : null
	sync_granted()

/datum/spell_mastery/proc/remove_granted_spells()
	for(var/spell_path in granted_actions)
		var/datum/action/cooldown/spell/spell = granted_actions[spell_path]
		if(spell?.owner)
			spell.Remove(spell.owner)

/datum/spell_mastery/proc/get_rank()
	var/mob/living/body = get_body()
	if(!body)
		return 0
	return clamp(round(body.get_skill_level(/datum/attribute/skill/magic/arcane)), SKILL_RANK_NONE, SKILL_RANK_LEGENDARY)

// Points

/datum/spell_mastery/proc/adjust_technique_points(amount)
	initial_technique_points += amount
	unspent_technique_points += amount

/datum/spell_mastery/proc/adjust_form_points(amount)
	initial_form_points += amount
	unspent_form_points += amount

/datum/spell_mastery/proc/get_technique_level(technique)
	if(!technique)
		return 0
	return technique_levels[technique] || 0

/datum/spell_mastery/proc/get_form_level(form)
	if(!form)
		return 0
	return form_levels[form] || 0

/datum/spell_mastery/proc/get_technique_rank_name(technique)
	return get_rank_name_for_level(get_technique_level(technique))

/datum/spell_mastery/proc/get_form_rank_name(form)
	return get_rank_name_for_level(get_form_level(form))

/datum/spell_mastery/proc/get_rank_name_for_level(level)
	var/best_name = "Untrained"
	var/best_threshold = -1
	for(var/threshold_text in GLOB.mastery_rank_names)
		var/threshold = text2num(threshold_text)
		if(level >= threshold && threshold > best_threshold)
			best_threshold = threshold
			best_name = GLOB.mastery_rank_names[threshold_text]
	return best_name

/// Recomputes unspent pools from lifetime totals minus investments and known spells.
/datum/spell_mastery/proc/recalculate_unspent_points()
	total_form_points_earned = initial_form_points
	total_technique_points_earned = initial_technique_points

	var/spent_on_forms = 0
	var/spent_on_techniques = 0

	spendable_form_points.Cut()
	spendable_technique_points.Cut()

	for(var/form in form_levels)
		var/lvl = form_levels[form]
		spent_on_forms += lvl
		spendable_form_points[form] = lvl

	for(var/technique in technique_levels)
		var/lvl = technique_levels[technique]
		spent_on_techniques += lvl
		spendable_technique_points[technique] = lvl

	for(var/datum/action/cooldown/spell/spell_path as anything in unlocked_spells)
		var/req_form = initial(spell_path.required_form)
		if(req_form)
			spendable_form_points[req_form] -= 1
		var/req_technique = initial(spell_path.required_technique)
		if(req_technique)
			spendable_technique_points[req_technique] -= 1

	unspent_form_points = max(0, total_form_points_earned - spent_on_forms)
	unspent_technique_points = max(0, total_technique_points_earned - spent_on_techniques)

/datum/spell_mastery/proc/invest_technique(technique, amount = 1)
	if(!technique || amount <= 0)
		return FALSE
	if(amount > unspent_technique_points)
		return FALSE
	unspent_technique_points -= amount
	technique_levels[technique] = get_technique_level(technique) + amount
	spendable_technique_points[technique] = (spendable_technique_points[technique] || 0) + amount
	return TRUE

/// Whether this craft reaches a form; an unset list opens every form, and formless spells always pass.
/datum/spell_mastery/proc/form_allowed(form)
	return !form || !allowed_forms || (form in allowed_forms)

/datum/spell_mastery/proc/invest_form(form, amount = 1)
	if(!form || amount <= 0 || !form_allowed(form))
		return FALSE
	if(amount > unspent_form_points)
		return FALSE
	unspent_form_points -= amount
	form_levels[form] = get_form_level(form) + amount
	spendable_form_points[form] = (spendable_form_points[form] || 0) + amount
	return TRUE

/// Returns list(form points, technique points) needed to learn spell_path.
/datum/spell_mastery/proc/get_spell_cost(datum/action/cooldown/spell/spell_path)
	var/form_cost = initial(spell_path.required_form) ? 1 : 0
	var/technique_cost = initial(spell_path.required_technique) ? 1 : 0
	return list(form_cost, technique_cost)

/// initial() is null for list vars, so prerequisites come from a throwaway instance, cached per type.
/proc/get_spell_prerequisites(datum/action/cooldown/spell/spell_path)
	var/static/list/cache
	cache ||= list()
	var/list/prereqs = cache[spell_path]
	if(isnull(prereqs))
		var/datum/action/cooldown/spell/probe = new spell_path()
		prereqs = probe.prerequisite_spells?.Copy() || list()
		qdel(probe)
		cache[spell_path] = prereqs
	return prereqs

/// Whether spell_path is purchasable now; known spells return FALSE. level_grace lowers the form rank needed.
/datum/spell_mastery/proc/can_learn_spell(datum/action/cooldown/spell/spell_path, level_grace = 0)
	if(!ispath(spell_path, /datum/action/cooldown/spell))
		return FALSE
	if(spell_path in unlocked_spells)
		return FALSE

	var/technique = initial(spell_path.required_technique)
	var/form = initial(spell_path.required_form)
	var/level_req = initial(spell_path.required_level)

	if(!form_allowed(form))
		return FALSE
	if(form && (spendable_form_points[form] || 0) < 1)
		return FALSE
	if(technique && (spendable_technique_points[technique] || 0) < 1)
		return FALSE

	if(level_req > 0)
		if(form && get_form_level(form) < max(0, level_req - level_grace))
			return FALSE

	var/list/prereqs = get_spell_prerequisites(spell_path)
	if(length(prereqs))
		for(var/prereq_path in prereqs)
			if(!(prereq_path in unlocked_spells))
				return FALSE

	return TRUE

/datum/spell_mastery/proc/try_learn_spell(datum/action/cooldown/spell/spell_path, level_grace = 0)
	if(!can_learn_spell(spell_path, level_grace))
		return FALSE

	var/technique = initial(spell_path.required_technique)
	var/form = initial(spell_path.required_form)
	if(form)
		spendable_form_points[form] -= 1
	if(technique)
		spendable_technique_points[technique] -= 1

	unlocked_spells += spell_path
	if(uses_preparation && needs_preparation(spell_path) && length(prepared_spells) < get_max_prepared())
		prepared_spells += spell_path
	sync_granted()
	return TRUE

/datum/spell_mastery/proc/try_unlearn_spell(datum/action/cooldown/spell/spell_path)
	if(!can_unlearn_spell(spell_path))
		return FALSE

	var/technique = initial(spell_path.required_technique)
	var/form = initial(spell_path.required_form)
	if(form)
		spendable_form_points[form] += 1
	if(technique)
		spendable_technique_points[technique] += 1

	unlocked_spells -= spell_path
	prepared_spells -= spell_path
	forget_action(spell_path)
	return TRUE

/datum/spell_mastery/proc/can_unlearn_spell(spell_path)
	return (spell_path in unlocked_spells)

/datum/spell_mastery/proc/forget_action(spell_path)
	var/datum/action/cooldown/spell/spell = granted_actions[spell_path]
	if(!spell)
		return
	if(spell.owner)
		spell.Remove(spell.owner)
	granted_actions -= spell_path
	qdel(spell)

/**
 * Grants a spell directly, bypassing the spendable-point check.
 * Use this for innate or bonus spells rather than editing the lists.
 */
/datum/spell_mastery/proc/grant_bonus_spell(datum/action/cooldown/spell/spell, mob/living/user)
	if(!istype(spell) || !user)
		return FALSE
	var/spell_path = spell.type
	if(spell_path in unlocked_spells)
		return FALSE

	unlocked_spells += spell_path
	granted_actions[spell_path] = spell
	if(needs_preparation(spell_path))
		prepared_spells |= spell_path

	// Bump the track and lifetime totals so the recalculation never charges for a free spell.
	var/req_form = spell.required_form
	var/req_technique = spell.required_technique
	if(req_form)
		form_levels[req_form] = get_form_level(req_form) + 1
		initial_form_points += 1
	if(req_technique)
		technique_levels[req_technique] = get_technique_level(req_technique) + 1
		initial_technique_points += 1

	recalculate_unspent_points()
	return TRUE

// Preparation

/// Slot spells need preparing; cantrips and legacy mana spells are always ready.
/datum/spell_mastery/proc/needs_preparation(datum/action/cooldown/spell/spell_path)
	var/level = initial(spell_path.slot_level)
	return !isnull(level) && level >= 1

// CHARISMA_LATER: innate casters should add a Charisma bonus to this cap once the stat exists.
/datum/spell_mastery/proc/get_max_prepared()
	return MAX_PREPARED_SPELLS(get_rank())

/datum/spell_mastery/proc/is_prepared(spell_path)
	return !uses_preparation || !needs_preparation(spell_path) || (spell_path in prepared_spells)

/datum/spell_mastery/proc/is_book_at_hand()
	var/obj/item/spellbook/book = bound_book_ref?.resolve()
	var/mob/living/body = get_body()
	return book && body && (book.loc == body)

/// Preparing happens outside combat mode, with the grimoire at hand.
/datum/spell_mastery/proc/can_prepare(feedback = TRUE)
	var/mob/living/body = get_body()
	if(!uses_preparation || !body)
		return FALSE
	if(body.cmode)
		if(feedback)
			to_chat(body, span_warning("I cannot prepare spells while ready for combat."))
		return FALSE
	if(!is_book_at_hand())
		if(feedback)
			to_chat(body, span_warning("I need my grimoire at hand to prepare spells."))
		return FALSE
	return TRUE

/datum/spell_mastery/proc/set_prepared(datum/action/cooldown/spell/spell_path, state)
	if(!(spell_path in unlocked_spells) || !needs_preparation(spell_path))
		return FALSE
	if(!can_prepare())
		return FALSE
	if(state)
		if(spell_path in prepared_spells)
			return TRUE
		if(length(prepared_spells) >= get_max_prepared())
			to_chat(get_body(), span_warning("I cannot hold more spells in mind. [get_max_prepared()] is my limit."))
			return FALSE
		prepared_spells += spell_path
	else
		prepared_spells -= spell_path
	sync_granted()
	return TRUE

/// Grants prepared spells to the body and removes the rest; actions persist so cooldowns do.
/datum/spell_mastery/proc/sync_granted()
	var/mob/living/body = get_body()
	for(var/spell_path in unlocked_spells)
		var/datum/action/cooldown/spell/spell = granted_actions[spell_path]
		var/wanted = body && is_prepared(spell_path)
		if(wanted)
			if(!spell)
				spell = new spell_path()
				granted_actions[spell_path] = spell
			if(spell.owner != body)
				spell.Grant(body)
		else if(spell?.owner)
			spell.Remove(spell.owner)

// Grimoire binding

/datum/spell_mastery/proc/bind_book(obj/item/spellbook/book)
	var/obj/item/spellbook/old_book = bound_book_ref?.resolve()
	if(old_book && old_book != book)
		UnregisterSignal(old_book, COMSIG_PARENT_QDELETING)
	bound_book_ref = WEAKREF(book)
	bound_book_lost = FALSE
	RegisterSignal(book, COMSIG_PARENT_QDELETING, PROC_REF(on_book_deleted), override = TRUE)

/datum/spell_mastery/proc/on_book_deleted(datum/source)
	SIGNAL_HANDLER
	bound_book_ref = null
	bound_book_lost = TRUE

/datum/spell_mastery/proc/on_rest(datum/source, rest_type)
	SIGNAL_HANDLER
	if(rest_type & REST_LONG)
		recall_bound_book()

/// A long rest brings a lost grimoire back, or replaces a destroyed one with a plain copy.
/datum/spell_mastery/proc/recall_bound_book()
	var/mob/living/body = get_body()
	if(!body || !uses_preparation)
		return
	var/obj/item/spellbook/book = bound_book_ref?.resolve()
	if(book)
		if(book.loc == body)
			return
		book.forceMove(get_turf(body))
		body.put_in_hands(book)
		to_chat(body, span_notice("My grimoire finds its way back to me."))
		return
	if(!bound_book_lost)
		return
	book = new /obj/item/spellbook(get_turf(body))
	book.bind_owner(owner)
	body.put_in_hands(book)
	to_chat(body, span_notice("A plain grimoire takes shape in my hands, bound to me as the old one was."))

// Point adjustment helpers

/// Each slot-skill rank gained pays a form point; Apprentice, Expert and Legendary add a technique point.
/datum/spell_mastery/proc/pay_rank_points(new_rank, old_rank)
	if(QDELETED(src) || new_rank <= old_rank)
		return FALSE
	if(!uses_preparation && !initial_form_points && !initial_technique_points)
		return FALSE
	var/form_gain = new_rank - old_rank
	var/technique_gain = 0
	for(var/rank in old_rank + 1 to new_rank)
		if(rank == SKILL_RANK_APPRENTICE || rank == SKILL_RANK_EXPERT || rank == SKILL_RANK_LEGENDARY)
			technique_gain++
	adjust_form_points(form_gain)
	if(technique_gain)
		adjust_technique_points(technique_gain)
	recalculate_unspent_points()
	var/mob/living/body = get_body()
	if(body)
		var/gained = "[form_gain] form point[form_gain == 1 ? "" : "s"]"
		if(technique_gain)
			gained += " and [technique_gain] technique point[technique_gain == 1 ? "" : "s"]"
		to_chat(body, span_notice("My deeper study grants me [gained]. Spellcraft can spend them."))
	return TRUE

/datum/spell_mastery/proc/adjust_form_mastery_points(points, used_points = FALSE, specific_form = null)
	if(QDELETED(src))
		return
	if(specific_form)
		if(used_points)
			spendable_form_points[specific_form] = max(0, (spendable_form_points[specific_form] || 0) - points)
		else
			form_levels[specific_form] = max(0, get_form_level(specific_form) + points)
			initial_form_points += points
	else
		if(used_points)
			unspent_form_points = max(0, unspent_form_points - points)
		else
			adjust_form_points(points)
	recalculate_unspent_points()

/datum/spell_mastery/proc/adjust_technique_mastery_points(points, used_points = FALSE, specific_technique = null)
	if(QDELETED(src))
		return
	if(specific_technique)
		if(used_points)
			spendable_technique_points[specific_technique] = max(0, (spendable_technique_points[specific_technique] || 0) - points)
		else
			technique_levels[specific_technique] = max(0, get_technique_level(specific_technique) + points)
			initial_technique_points += points
	else
		if(used_points)
			unspent_technique_points = max(0, unspent_technique_points - points)
		else
			adjust_technique_points(points)
	recalculate_unspent_points()

/datum/spell_mastery/proc/reset_form_mastery_points(silent = TRUE)
	if(QDELETED(src))
		return
	initial_form_points = 0
	unspent_form_points = 0
	if(!silent && get_body())
		to_chat(get_body(), span_boldwarning("I lost all my form mastery points!"))
	recalculate_unspent_points()

/datum/spell_mastery/proc/reset_technique_mastery_points(silent = TRUE)
	if(QDELETED(src))
		return
	initial_technique_points = 0
	unspent_technique_points = 0
	if(!silent && get_body())
		to_chat(get_body(), span_boldwarning("I lost all my technique mastery points!"))
	recalculate_unspent_points()

// Mob helpers

/mob/proc/adjust_form_mastery_points(points, used_points = FALSE, specific_form = null)
	return

/mob/proc/adjust_technique_mastery_points(points, used_points = FALSE, specific_technique = null)
	return

/mob/living/adjust_form_mastery_points(points, used_points = FALSE, specific_form = null)
	mind?.get_spell_mastery().adjust_form_mastery_points(points, used_points, specific_form)

/mob/living/adjust_technique_mastery_points(points, used_points = FALSE, specific_technique = null)
	mind?.get_spell_mastery().adjust_technique_mastery_points(points, used_points, specific_technique)

/// Innate casters open their spell list without a grimoire.
/datum/action/innate/open_spellbook
	name = "Innate Spells"
	desc = "Review the forms and techniques of your innate magic."
	button_icon = 'icons/mob/actions/roguespells.dmi'
	button_icon_state = "book1"

/datum/action/innate/open_spellbook/Activate()
	var/mob/living/user = owner
	if(!istype(user) || !user.mind)
		return
	user.mind.get_spell_mastery().open_ui(user)

/// Wizards open the same window; preparing still needs their bound grimoire at hand.
/datum/action/innate/open_spellbook/grimoire
	name = "Spellcraft"
	desc = "Study the forms, techniques and spells of my grimoire."
