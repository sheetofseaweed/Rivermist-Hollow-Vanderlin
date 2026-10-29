// One-shot spell scrolls: reading casts the spell once for free, and wizards may scribe it into a grimoire.

/// Longest a released scroll spell keeps its hidden copy alive for lingering effects.
#define SCROLL_EFFECT_MAX_TIME (5 MINUTES)
/// Shortest wait after release before the hidden copy may be cleaned up.
#define SCROLL_EFFECT_MIN_TIME (3 SECONDS)
/// How often a scroll being read, or a released spell, is checked.
#define SCROLL_CHECK_INTERVAL (1 SECONDS)
/// A cast that began its effect but never finished is treated as released after this long.
#define SCROLL_CAST_TIMEOUT (1 MINUTES)

/obj/item/spell_scroll
	name = "spell scroll"
	desc = "Parchment dense with arcyne script, written to be spoken once."
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state = "scroll"
	w_class = WEIGHT_CLASS_SMALL
	dropshrink = 0.6
	resistance_flags = FLAMMABLE
	drop_sound = 'sound/foley/dropsound/paper_drop.ogg'
	pickup_sound = 'sound/blank.ogg'
	sellprice = 10
	/// The spell cast once by reading, or learned by scribing into a grimoire.
	var/datum/action/cooldown/spell/spell_type
	/// How long copying the scroll into a grimoire takes.
	var/scribe_time = 5 SECONDS
	/// Temporary copy granted to the reader; never learned and never shown in the catalogue.
	var/datum/action/cooldown/spell/reading_spell
	var/datum/weakref/reader_ref
	/// Lets our own Trigger call through the copy's trigger signal once.
	var/triggering = FALSE
	/// The copy's effect began, so the read can no longer be cancelled.
	var/committed = FALSE
	var/committed_at = 0
	/// The spell left the scroll; it waits in nullspace for lingering effects, then deletes itself.
	var/spent = FALSE
	var/released_at = 0
	var/check_timer

/obj/item/spell_scroll/Initialize(mapload, datum/action/cooldown/spell/new_spell_type)
	. = ..()
	set_spell(new_spell_type || spell_type)

/obj/item/spell_scroll/Destroy()
	end_reading()
	return ..()

/// Sets the held spell, and the name and price that follow from it.
/obj/item/spell_scroll/proc/set_spell(datum/action/cooldown/spell/new_spell_type)
	spell_type = ispath(new_spell_type, /datum/action/cooldown/spell) ? new_spell_type : null
	if(!spell_type)
		name = initial(name)
		sellprice = initial(sellprice)
		return
	name = "scroll of [initial(spell_type.name)]"
	var/level = initial(spell_type.slot_level)
	sellprice = 10 + 15 * (level > 0 ? level : 0)

/// Level and form as players read them, such as ": level 1, Fire form".
/obj/item/spell_scroll/proc/get_level_text()
	var/list/parts = list()
	var/level = initial(spell_type.slot_level)
	if(!isnull(level))
		parts += level > 0 ? "level [level]" : "cantrip"
	var/form = initial(spell_type.required_form)
	if(form)
		parts += "[form] form"
	return length(parts) ? ": [jointext(parts, ", ")]" : ""

/obj/item/spell_scroll/examine(mob/user)
	. = ..()
	if(!spell_type)
		. += span_warning("Its runes have faded to nothing.")
		return
	. += span_notice("It holds [initial(spell_type.name)][get_level_text()].")
	if(initial(spell_type.heretical_spell))
		. += span_warning("Its script is forbidden magic.")
	if(reading_spell)
		. += span_notice("Its runes glow with a spell waiting to be released.")
	. += span_info("Reading it releases the spell once, without slots or mana. A wizard could scribe it into a bound grimoire instead.")

/// First use reads the scroll aloud; a second use lowers it before the spell is released.
/obj/item/spell_scroll/attack_self(mob/user, list/modifiers)
	. = ..()
	if(. || spent || !isliving(user))
		return
	if(reading_spell)
		cancel_reading(reading_spell, span_notice("I lower [src]; the spell fades unspoken."))
		return TRUE
	start_reading(user)
	return TRUE

/obj/item/spell_scroll/dropped(mob/user, silent)
	. = ..()
	if(reading_spell && !spent && !committed)
		addtimer(CALLBACK(src, PROC_REF(cancel_reading), reading_spell, span_notice("The runes on [src] dim as it leaves my hand.")), 0)

/// Grants a free temporary copy of the spell and starts its normal cast.
/obj/item/spell_scroll/proc/start_reading(mob/living/user)
	if(!spell_type)
		to_chat(user, span_warning("The runes on [src] have faded to nothing."))
		return FALSE
	// Feature pools and essence costs belong to the caster's own kit, not to parchment.
	if(initial(spell_type.feature_id) || initial(spell_type.spell_type) == SPELL_ESSENCE)
		to_chat(user, span_warning("The power in [src] cannot be released by reading."))
		return FALSE
	if(!user.can_read(src))
		return FALSE
	var/datum/action/cooldown/spell/spell = new spell_type(src)
	if(QDELETED(spell))
		return FALSE
	spell.spell_flags |= SPELL_TEMPORARY
	spell.experience_modifier = 0
	spell.spell_cost = 0
	spell.charge_drain = 0
	spell.retrigger_after_cooldown = FALSE
	spell.shared_cooldown = null
	spell.background_icon_state = "spelltemp"
	spell.base_background_icon_state = "spelltemp0"
	spell.active_background_icon_state = "spelltemp1"
	arm_free_cast(spell)
	reading_spell = spell
	reader_ref = WEAKREF(user)
	committed = FALSE
	RegisterSignal(src, COMSIG_PARENT_PREQDELETED, PROC_REF(on_scroll_predelete))
	RegisterSignal(spell, COMSIG_PARENT_QDELETING, PROC_REF(on_spell_deleted))
	RegisterSignal(spell, COMSIG_ACTION_TRIGGER, PROC_REF(on_spell_trigger))
	RegisterSignal(spell, COMSIG_SPELL_BEFORE_CAST, PROC_REF(on_spell_before_cast))
	RegisterSignal(spell, COMSIG_SPELL_CAST, PROC_REF(on_spell_cast))
	RegisterSignal(spell, COMSIG_SPELL_AFTER_CAST, PROC_REF(on_spell_released))
	spell.Grant(user)
	if(QDELETED(spell) || spell.owner != user)
		to_chat(user, span_warning("The magic of [src] finds no purchase in me."))
		end_reading()
		return FALSE
	RegisterSignal(user, COMSIG_MOB_DEATH, PROC_REF(on_reader_death))
	RegisterSignal(user, COMSIG_MOB_SPELL_ACTIVATED, PROC_REF(on_reader_spell_activated))
	if(!spell.can_cast_spell(feedback = TRUE))
		end_reading()
		return FALSE
	if(!user.mind?.is_slot_caster() && !pass_aim_roll(user))
		return FALSE
	user.visible_message(span_notice("[user] unrolls [src]."), span_notice("I unroll [src] and the runes of [spell.name] rise from the page."))
	check_timer = addtimer(CALLBACK(src, PROC_REF(check_reading)), SCROLL_CHECK_INTERVAL, TIMER_STOPPABLE)
	if(!spell.click_to_activate)
		INVOKE_ASYNC(src, PROC_REF(cast_undirected), spell)
		return TRUE
	triggering = TRUE
	var/armed = spell.Trigger()
	triggering = FALSE
	if(!armed && spell == reading_spell)
		end_reading()
		return FALSE
	return TRUE

/// Readers without a slot ladder roll 3d6 under intelligence plus arcane rank, or the scroll fizzles.
/obj/item/spell_scroll/proc/pass_aim_roll(mob/living/user)
	var/rank = clamp(round(user.get_skill_level(/datum/attribute/skill/magic/arcane)), SKILL_RANK_NONE, SKILL_RANK_LEGENDARY)
	var/result = user.diceroll(user.get_stat(STAT_INTELLIGENCE) + rank, context = DICE_CONTEXT_MENTAL)
	if(result == DICE_SUCCESS || result == DICE_CRIT_SUCCESS)
		to_chat(user, span_notice("I wrestle the unfamiliar script into shape."))
		return TRUE
	user.visible_message(span_warning("[user] stumbles over the runes of [src], and it crumbles to ash."), span_warning("The script twists on my tongue and [src] crumbles to ash."))
	qdel(src)
	return FALSE

// A free cast pays nothing (no slot, mana, drain, metamagic or XP) and runs at the spell's own level.
/obj/item/spell_scroll/proc/arm_free_cast(datum/action/cooldown/spell/spell)
	if(QDELETED(spell))
		return
	spell.free_cast = TRUE
	spell.free_cast_level = spell.slot_level > 0 ? spell.slot_level : null

/// Non-click spells charge inside Trigger; a spell that did not go off leaves the scroll whole.
/obj/item/spell_scroll/proc/cast_undirected(datum/action/cooldown/spell/spell)
	triggering = TRUE
	spell.Trigger()
	triggering = FALSE
	if(!QDELETED(src) && spell == reading_spell && !spent)
		end_reading(span_notice("The spell slips away before its release; [src] stays unspent."))

/// Cancels a read whose effect has not begun; the scroll stays whole.
/obj/item/spell_scroll/proc/cancel_reading(datum/action/cooldown/spell/spell, message)
	if(!spell || spell != reading_spell || spent || committed)
		return
	end_reading(message)

/// Removes and deletes the temporary copy.
/obj/item/spell_scroll/proc/end_reading(message)
	var/datum/action/cooldown/spell/spell = reading_spell
	var/mob/living/reader = reader_ref?.resolve()
	reading_spell = null
	committed = FALSE
	triggering = FALSE
	unregister_reader()
	UnregisterSignal(src, COMSIG_PARENT_PREQDELETED)
	if(check_timer)
		deltimer(check_timer)
		check_timer = null
	if(!spell)
		return
	UnregisterSignal(spell, list(COMSIG_PARENT_QDELETING, COMSIG_ACTION_TRIGGER, COMSIG_SPELL_BEFORE_CAST, COMSIG_SPELL_CAST, COMSIG_SPELL_AFTER_CAST))
	if(message && reader)
		to_chat(reader, message)
	stop_copy_charge(spell)
	if(!QDELETED(spell))
		qdel(spell)

/// Stops a charging copy while it still has an owner; the spell's own Destroy skips this.
/obj/item/spell_scroll/proc/stop_copy_charge(datum/action/cooldown/spell/spell)
	if(!QDELETED(spell) && spell.currently_charging && spell.owner)
		spell.cancel_casting()

/// Deleting the scroll deletes its copy, so a running charge must stop first.
/obj/item/spell_scroll/proc/on_scroll_predelete(datum/source, force)
	SIGNAL_HANDLER
	stop_copy_charge(reading_spell)

/obj/item/spell_scroll/proc/unregister_reader()
	var/mob/living/reader = reader_ref?.resolve()
	reader_ref = null
	if(reader)
		UnregisterSignal(reader, list(COMSIG_MOB_DEATH, COMSIG_MOB_SPELL_ACTIVATED))

/// Our own trigger passes; the reader's button press lowers the scroll, and a released copy stays shut.
/obj/item/spell_scroll/proc/on_spell_trigger(datum/action/source)
	SIGNAL_HANDLER
	if(triggering)
		triggering = FALSE
		return NONE
	if(!spent && !committed)
		addtimer(CALLBACK(src, PROC_REF(cancel_reading), source, span_notice("I lower [src]; the spell fades unspoken.")), 0)
	return COMPONENT_ACTION_BLOCK_TRIGGER

/obj/item/spell_scroll/proc/on_spell_before_cast(datum/action/cooldown/spell/source, atom/cast_on)
	SIGNAL_HANDLER
	addtimer(CALLBACK(src, PROC_REF(rearm_after_attempt), source), 0)

/// A refused attempt clears the paid flags; restoring them lets the reader aim again.
/obj/item/spell_scroll/proc/rearm_after_attempt(datum/action/cooldown/spell/spell)
	if(spell != reading_spell || spent || committed)
		return
	arm_free_cast(spell)

/obj/item/spell_scroll/proc/on_spell_cast(datum/action/cooldown/spell/source, atom/cast_on)
	SIGNAL_HANDLER
	if(source != reading_spell)
		return
	committed = TRUE
	committed_at = world.time

/obj/item/spell_scroll/proc/on_spell_released(datum/action/cooldown/spell/source, atom/cast_on)
	SIGNAL_HANDLER
	if(source != reading_spell || spent)
		return
	if(istype(source, /datum/action/cooldown/spell/undirected/touch))
		var/datum/action/cooldown/spell/undirected/touch/touch_spell = source
		if(QDELETED(touch_spell.attached_hand))
			addtimer(CALLBACK(src, PROC_REF(end_reading), span_warning("I could not draw [source.name] into my hand; [src] stays unspent.")), 0)
			return
		// Activate clears the paid flags after this signal; the drawn hand needs them for its hits.
		addtimer(CALLBACK(src, PROC_REF(arm_free_cast), source), 0)
	release(source)

/// The spell left the scroll: its copy hides from every button bar and the scroll leaves the hand.
/obj/item/spell_scroll/proc/release(datum/action/cooldown/spell/spell)
	spent = TRUE
	released_at = world.time
	unregister_reader()
	var/mob/living/caster = spell.owner
	for(var/datum/hud/hud as anything in spell.viewers.Copy())
		if(hud?.mymob)
			spell.HideFrom(hud.mymob)
	if(caster)
		spell.HideFrom(caster)
		to_chat(caster, span_notice("[src] crumbles to ash as the spell leaves it."))
	if(ismob(loc))
		var/mob/holder = loc
		holder.temporarilyRemoveItemFromInventory(src, force = TRUE)
	moveToNullspace()

/obj/item/spell_scroll/proc/on_spell_deleted(datum/source)
	SIGNAL_HANDLER
	if(source != reading_spell)
		return
	reading_spell = null
	committed = FALSE
	unregister_reader()
	if(spent && !QDELETED(src))
		QDEL_IN(src, 0)

/obj/item/spell_scroll/proc/on_reader_death(mob/living/source, gibbed)
	SIGNAL_HANDLER
	addtimer(CALLBACK(src, PROC_REF(cancel_reading), reading_spell, null), 0)

/// Arming another spell unsets ours, which ends the read.
/obj/item/spell_scroll/proc/on_reader_spell_activated(mob/living/source, datum/action/cooldown/spell/spell)
	SIGNAL_HANDLER
	if(spell == reading_spell || !reading_spell?.click_to_activate)
		return
	addtimer(CALLBACK(src, PROC_REF(cancel_reading), reading_spell, span_notice("I turn to other magic and [src] goes quiet.")), 0)

/// Ends an abandoned read, and deletes a spent scroll once its spell stops working.
/obj/item/spell_scroll/proc/check_reading()
	check_timer = null
	var/datum/action/cooldown/spell/spell = reading_spell
	if(spent)
		if(!spell_still_working(spell))
			qdel(src)
			return
	else if(QDELETED(spell))
		return
	else if(committed)
		if(world.time > committed_at + SCROLL_CAST_TIMEOUT)
			release(spell)
	else
		var/mob/living/reader = spell.owner
		if(QDELETED(reader) || reader.stat == DEAD || loc != reader)
			end_reading(span_notice("The runes on [src] settle; the spell fades unspoken."))
			return
		if(spell.click_to_activate && reader.click_intercept != spell && !spell.currently_charging)
			end_reading(span_notice("The runes on [src] settle; the spell fades unspoken."))
			return
	check_timer = addtimer(CALLBACK(src, PROC_REF(check_reading)), SCROLL_CHECK_INTERVAL, TIMER_STOPPABLE)

/// Whether a released copy still runs: a drawn hand, held concentration or pending effect timers.
/obj/item/spell_scroll/proc/spell_still_working(datum/action/cooldown/spell/spell)
	if(QDELETED(spell) || QDELETED(spell.owner))
		return FALSE
	var/elapsed = world.time - released_at
	if(elapsed >= SCROLL_EFFECT_MAX_TIME)
		return FALSE
	if(elapsed < SCROLL_EFFECT_MIN_TIME || effect_ends_with_action(spell))
		return TRUE
	if(istype(spell, /datum/action/cooldown/spell/undirected/touch))
		var/datum/action/cooldown/spell/undirected/touch/touch_spell = spell
		if(!QDELETED(touch_spell.attached_hand))
			return TRUE
	var/mob/living/caster = spell.owner
	if(caster.mind?.spell_slots?.get_concentration() == spell)
		return TRUE
	var/list/bookkeeping = list(spell.cooldown_timer, spell.retrigger_timer, spell.auto_cancel_timer, spell.twin_timer)
	for(var/datum/timedevent/timer as anything in spell.active_timers)
		if(!timer.spent && !(timer.id in bookkeeping))
			return TRUE
	return FALSE

/// Spells that undo their effect when their action goes; scroll casts keep them for the full window.
/obj/item/spell_scroll/proc/effect_ends_with_action(datum/action/cooldown/spell/spell)
	return istype(spell, /datum/action/cooldown/spell/mimicry) || istype(spell, /datum/action/cooldown/spell/conjure/phantom_ear)

// Scribing

/obj/item/spell_scroll/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!istype(interacting_with, /obj/item/spellbook))
		return NONE
	return scribe_into(interacting_with, user) ? ITEM_INTERACT_SUCCESS : ITEM_INTERACT_BLOCKING

/// Copies the spell into the reader's bound grimoire through mastery, consuming the scroll.
/obj/item/spell_scroll/proc/scribe_into(obj/item/spellbook/book, mob/living/user)
	var/datum/spell_mastery/mastery = user.mind?.spell_mastery
	var/refusal = get_scribe_refusal(book, user, mastery)
	if(refusal)
		to_chat(user, span_warning(refusal))
		return FALSE
	if(!user.can_read(src))
		return FALSE
	var/spell_name = initial(spell_type.name)
	user.visible_message(span_notice("[user] begins copying [src] into [book]."), span_notice("I begin copying [spell_name] into my grimoire."))
	if(!do_after(user, scribe_time, book))
		if(!QDELETED(src))
			to_chat(user, span_warning("I stop copying; [src] stays whole."))
		return FALSE
	if(QDELETED(src) || QDELETED(book))
		return FALSE
	refusal = get_scribe_refusal(book, user, mastery)
	if(refusal)
		to_chat(user, span_warning(refusal))
		return FALSE
	if(!mastery.try_learn_spell(spell_type))
		to_chat(user, span_warning("The runes of [spell_name] refuse to settle into my grimoire."))
		return FALSE
	var/prepared_note = mastery.is_prepared(spell_type) ? "It waits ready in my mind." : "I can prepare it from my grimoire."
	user.visible_message(span_notice("[user] finishes copying [src], and it crumbles to ash."), span_notice("I copy [spell_name] into my grimoire and [src] crumbles to ash. [prepared_note]"))
	qdel(src)
	return TRUE

/// Why scribing would fail right now, or null when the spell can be learned.
/obj/item/spell_scroll/proc/get_scribe_refusal(obj/item/spellbook/book, mob/living/user, datum/spell_mastery/mastery)
	if(!spell_type)
		return "The runes on [src] have faded to nothing."
	if(reading_spell || spent)
		return "I am already reading [src] aloud."
	if(!mastery?.uses_preparation)
		return "Only a wizard can scribe spells into a grimoire."
	var/datum/mind/bound = book.get_bound_mind()
	if(!bound)
		return "[book] is bound to no one; I must claim it first."
	if(bound != user.mind)
		return "[book] is not bound to me."
	var/spell_name = initial(spell_type.name)
	var/form = initial(spell_type.required_form)
	if(!initial(spell_type.learnable) || !form)
		return "[spell_name] is not a spell a grimoire can hold."
	if(spell_type in mastery.unlocked_spells)
		return "I already know [spell_name]."
	if(mastery.can_learn_spell(spell_type))
		return null
	var/level_req = initial(spell_type.required_level)
	if(level_req > 0 && mastery.get_form_level(form) < level_req)
		return "My [form] mastery must reach [mastery.get_rank_name_for_level(level_req)] to scribe [spell_name]."
	if((mastery.spendable_form_points[form] || 0) < 1)
		return "I need a free point of [form] mastery to scribe [spell_name]."
	var/technique = initial(spell_type.required_technique)
	if(technique && (mastery.spendable_technique_points[technique] || 0) < 1)
		return "I need a free point of [technique] mastery to scribe [spell_name]."
	return "I cannot grasp [spell_name] yet; it builds on spells I do not know."

// Random scrolls for admins and loot tables

/// A random arcane catalogue spell whose slot level lies between min_level and max_level.
/proc/get_random_scroll_spell(min_level = SPELL_SLOT_MIN, max_level = SPELL_SLOT_MAX)
	var/static/list/pools
	pools ||= list()
	var/key = "[min_level]-[max_level]"
	var/list/pool = pools[key]
	if(isnull(pool))
		pool = list()
		for(var/datum/action/cooldown/spell/spell_path as anything in subtypesof(/datum/action/cooldown/spell))
			if(IS_ABSTRACT(spell_path) || !initial(spell_path.learnable) || !initial(spell_path.required_form))
				continue
			if(initial(spell_path.spell_type) != SPELL_MANA || initial(spell_path.feature_id))
				continue
			var/level = initial(spell_path.slot_level)
			if(isnull(level) || level < min_level || level > max_level)
				continue
			pool += spell_path
		pools[key] = pool
	return length(pool) ? pick(pool) : null

/obj/item/spell_scroll/random
	var/min_level = SPELL_SLOT_MIN
	var/max_level = SPELL_SLOT_MAX

/obj/item/spell_scroll/random/Initialize(mapload, datum/action/cooldown/spell/new_spell_type)
	return ..(mapload, new_spell_type || get_random_scroll_spell(min_level, max_level))

/obj/item/spell_scroll/random/lesser
	max_level = 2

/obj/item/spell_scroll/random/greater
	min_level = 3

#undef SCROLL_EFFECT_MAX_TIME
#undef SCROLL_EFFECT_MIN_TIME
#undef SCROLL_CHECK_INTERVAL
#undef SCROLL_CAST_TIMEOUT
