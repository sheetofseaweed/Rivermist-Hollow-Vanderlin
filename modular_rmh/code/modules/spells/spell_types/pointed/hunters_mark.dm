// Ranger Hunter's Mark on the class feature pools: free marks per short rest, slots as the fallback.

/datum/action/cooldown/spell/status/hunters_mark
	name = "Hunter's Mark"
	desc = "Mark a quarry you can see for a minute; every blow you land on it bites five deeper. A charge pays for a plain mark, and a higher slot tier spends the slot for a longer one. Concentration, one quarry at a time."
	button_icon_state = "dream_mark"
	sound = 'sound/vo/smokedrag.ogg'
	self_cast_possible = FALSE
	has_visual_effects = FALSE
	antimagic_flags = NONE
	invocation_type = INVOCATION_NONE
	charge_required = FALSE
	cooldown_time = 5 SECONDS
	spell_cost = 0
	associated_skill = /datum/attribute/skill/misc/tracking
	associated_stat = STAT_PERCEPTION

	slot_level = 1
	slot_only = TRUE
	concentration = TRUE
	learnable = FALSE
	slot_label = "Hunter's Mark"
	feature_id = FEATURE_HUNTERS_MARK
	feature_rest = REST_SHORT
	twinnable = FALSE

	status_effect = /datum/status_effect/hunters_mark
	duration = HUNTERS_MARK_DURATION

/// The quarry must be alive and in the hunter's sight.
/datum/action/cooldown/spell/status/hunters_mark/is_valid_target(atom/cast_on)
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/quarry = cast_on
	if(quarry.stat == DEAD)
		owner.balloon_alert(owner, "already dead!")
		return FALSE
	if(!(quarry in view(get_cast_range(), owner)))
		owner.balloon_alert(owner, "my quarry is out of sight!")
		return FALSE
	return TRUE

/// A charge covers a plain mark. An empty pool, or a higher tier picked, leaves the slot to pay.
/datum/action/cooldown/spell/status/hunters_mark/get_feature_cost()
	var/datum/spell_slots/slots = register_feature()
	if(!slots || slots.get_feature_charges(feature_id) <= 0)
		return 0
	var/level = get_cast_level()
	if(!isnull(level) && level > SPELL_SLOT_MIN)
		return 0
	return 1

/// Slots are the fallback, so an empty pool never blocks the cast on its own.
/datum/action/cooldown/spell/status/hunters_mark/feature_ready(feedback = TRUE)
	register_feature()
	return TRUE

/// A charge in the pool stands in for the slot a plain mark would need.
/datum/action/cooldown/spell/status/hunters_mark/slot_can_cast(feedback = TRUE)
	if(get_feature_cost() > 0)
		return TRUE
	return ..()

/// A spent charge makes this cast free of its slot, mana and casting experience.
/datum/action/cooldown/spell/status/hunters_mark/spend_feature(amount = 1)
	. = ..()
	if(.)
		free_cast = TRUE
		owner.balloon_alert(owner, "[get_slot_label()]: charge")

/datum/action/cooldown/spell/status/hunters_mark/clear_slot_cast()
	free_cast = FALSE
	return ..()

/datum/action/cooldown/spell/status/hunters_mark/cast(mob/living/cast_on)
	extra_args = list(owner)
	. = ..()
	owner.visible_message(span_warning("[owner] fixes a hunter's stare on [cast_on]."), span_notice("I mark [cast_on] as my quarry."), vision_distance = COMBAT_MESSAGE_RANGE)

/// A second mark or a broken concentration lifts the old mark without the generic unravel text.
/datum/action/cooldown/spell/status/hunters_mark/on_concentration_broken(reason)
	var/datum/status_effect/mark = concentration_effect_ref?.resolve()
	concentration_target_ref = null
	concentration_effect_ref = null
	if(QDELETED(mark))
		return
	var/mob/living/quarry = mark.owner
	qdel(mark)
	if(owner && quarry)
		to_chat(owner, span_warning("My mark on [quarry] fades."))

/datum/status_effect/hunters_mark
	id = "hunters_mark"
	status_type = STATUS_EFFECT_MULTIPLE
	duration = HUNTERS_MARK_DURATION
	tick_interval = STATUS_EFFECT_NO_TICK
	alert_type = /atom/movable/screen/alert/status_effect/debuff/hunters_mark
	on_remove_on_mob_delete = TRUE
	/// The ranger whose blows the mark sharpens.
	var/datum/weakref/hunter_ref
	var/bonus_damage = HUNTERS_MARK_BONUS_DAMAGE
	/// Guards the bonus against feeding its own damage signal.
	var/tmp/applying_bonus = FALSE

/atom/movable/screen/alert/status_effect/debuff/hunters_mark
	name = "Hunter's Mark"
	desc = "A hunter has marked me as prey; their blows bite deeper."
	// The alert sheet has no curse state; it does carry the same mark the spell button uses.
	icon_state = "dream_mark"

/datum/status_effect/hunters_mark/on_creation(mob/living/new_owner, duration_override, mob/living/hunter)
	if(istype(hunter))
		hunter_ref = WEAKREF(hunter)
	return ..()

/// No hunter, no mark.
/datum/status_effect/hunters_mark/on_apply()
	. = ..()
	if(!. || !hunter_ref?.resolve())
		return FALSE
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_owner_damaged))
	return TRUE

/datum/status_effect/hunters_mark/on_remove()
	UnregisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE)
	return ..()

/datum/status_effect/hunters_mark/Destroy()
	hunter_ref = null
	return ..()

/// Brute or burn attributed to the hunter adds the mark's bite; anyone else's blows stay ordinary.
/datum/status_effect/hunters_mark/proc/on_owner_damaged(datum/source, damage, damagetype, def_zone)
	SIGNAL_HANDLER
	if(applying_bonus || damage <= 0 || (damagetype != BRUTE && damagetype != BURN))
		return
	var/mob/living/hunter = hunter_ref?.resolve()
	if(!hunter || owner.get_damage_attack_context() != hunter)
		return
	applying_bonus = TRUE
	owner.adjustBruteLoss(bonus_damage)
	applying_bonus = FALSE
	owner.visible_message(span_warning("[hunter]'s blow finds the mark on [owner]!"), span_danger("[hunter]'s blow finds the mark on me!"), vision_distance = COMBAT_MESSAGE_RANGE)
