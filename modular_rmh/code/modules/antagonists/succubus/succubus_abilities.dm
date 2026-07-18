// Succubus antagonist core — T1/T2 abilities: Detect Desire, Lust, Allure, Aphrodisiac Kiss (Task 5)
// See docs/superpowers/plans/2026-07-17-succubus-core.md
//
// Base API pinned from code/modules/antagonists/villain/werewolf/werewolf_spells.dm and
// code/modules/spells/spell.dm (read before writing this file, per the plan's Task 4/5 recon
// requirement): /datum/action/cooldown/spell is the cast chain (before_cast -> spell_feedback ->
// cast -> StartCooldown -> after_cast); pointed spells (Detect Desire, Lust) use the base type
// directly the way code/modules/spells/spell_types/pointed/woundlick.dm and the modular lewd spells
// enrapture.dm/forced_orgasm.dm do (self_cast_possible = FALSE, cast_range, is_valid_target
// override, cast(mob/living/carbon/human/cast_on)); self-cast abilities (Allure, Aphrodisiac Kiss)
// use /datum/action/cooldown/spell/undirected (click_to_activate = FALSE), same as werewolf's
// howl/claws. Granted/removed via mob/living/proc/add_spell(path, source = owner) /
// remove_spell(path) - exact mirror of grant_werewolf_powers()/remove_werewolf_powers().
//
// None of these set spell_cost/spell_type: the base engine's cost system (mana/stamina/blood/rage)
// is for the CASTER's own resource pools and is not succubus essence. Essence is charged entirely
// by hand against the antag datum (IS_SUCCUBUS(owner).essence), so spell_cost is left at its
// default of 0, which makes the base check_cost() a no-op and avoids double-charging anything.

/// The diegetic "am I allowed to affect this person with lust magic" gate (spec §8, §12). Every
/// ability that can touch another mob's body/mind funnels through this one proc so the pref check
/// can never drift out of sync between abilities - and so Task 7's tests can assert against it
/// directly by name.
/datum/antagonist/succubus/proc/can_target_lewd(mob/living/target)
	if(!ishuman(target))
		return FALSE
	return target.has_erp_pref(/datum/erp_preference/boolean/lust_magic_targetable)

// --- Detect Desire: pointed, no cost, short cooldown --------------------------------------------

/datum/action/cooldown/spell/succubus_detect_desire
	name = "Detect Desire"
	desc = "Gaze into a soul to learn what desires and wards lie within."
	has_visual_effects = FALSE
	antimagic_flags = NONE
	spell_flags = SPELL_IGNORE_SPELLBLOCK
	associated_skill = null
	self_cast_possible = FALSE
	cast_range = 5
	charge_required = FALSE
	cooldown_time = 6 SECONDS

/datum/action/cooldown/spell/succubus_detect_desire/is_valid_target(atom/cast_on)
	. = ..()
	if(!.)
		return FALSE
	return ishuman(cast_on)

// The diegetic pref reader (spec §8) is gated in before_cast, not cast(): a SPELL_CANCEL_CAST
// return here skips spell_feedback() (the base class's casting sound/invocation) entirely, so a
// warded target never picks up so much as the ambient sound of a doomed cast - NO effect, message,
// or sound ever reaches them, only the caster gets the warded-soul line.
/datum/action/cooldown/spell/succubus_detect_desire/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	var/mob/living/carbon/human/target = cast_on
	if(!istype(target))
		return
	var/datum/antagonist/succubus/succubus_antag = IS_SUCCUBUS(owner)
	if(succubus_antag && !succubus_antag.can_target_lewd(target))
		to_chat(owner, span_notice("I gaze into [target.real_name]... and meet a wall of white flame. This soul is warded against me."))
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/succubus_detect_desire/cast(mob/living/carbon/human/cast_on)
	. = ..()
	if(!istype(cast_on))
		return
	var/datum/antagonist/succubus/succubus_antag = IS_SUCCUBUS(owner)
	if(!succubus_antag)
		return

	// can_target_lewd() already passed in before_cast (otherwise SPELL_CANCEL_CAST would have
	// stopped the chain before cast() was ever reached), so no need to re-check it here.
	var/list/lines = list()
	lines += "This soul lies open to my arts."
	lines += cast_on.has_erp_pref(/datum/erp_preference/boolean/enthrallable) ? "Their will could be bound to mine, in time." : "Their will is anchored; thralldom is beyond reach."
	lines += cast_on.has_erp_pref(/datum/erp_preference/boolean/dream_visitable) ? "Their dreams lie unlatched." : "Their dreams are barred."
	lines += cast_on.has_erp_pref(/datum/erp_preference/boolean/fatal_drain_ok) ? "I could drink this one to the very dregs..." : "Something guards their lifespark; I may sip, never drain."
	to_chat(owner, span_love(lines.Join("<br>")))

// --- Lust: pointed, essence cost, hard pref gate -------------------------------------------------

/datum/action/cooldown/spell/succubus_lust
	name = "Lust"
	desc = "Kindle unbidden desire in a target's heart."
	has_visual_effects = FALSE
	antimagic_flags = NONE
	spell_flags = SPELL_IGNORE_SPELLBLOCK
	associated_skill = null
	self_cast_possible = FALSE
	cast_range = 5
	charge_required = FALSE
	cooldown_time = 4 SECONDS

/datum/action/cooldown/spell/succubus_lust/is_valid_target(atom/cast_on)
	. = ..()
	if(!.)
		return FALSE
	return ishuman(cast_on)

// Gated hard in before_cast, same reasoning as Detect Desire: an opted-out target must never
// receive any effect, message, or sound, and a SPELL_CANCEL_CAST return here means spell_feedback()
// (casting sound/invocation) never runs, on top of no essence being spent and no cooldown starting.
// The pref check runs before the essence check so the caster always gets the warded-soul message
// regardless of how much essence is on hand.
/datum/action/cooldown/spell/succubus_lust/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	var/mob/living/carbon/human/target = cast_on
	if(!istype(target))
		return
	var/datum/antagonist/succubus/succubus_antag = IS_SUCCUBUS(owner)
	if(!succubus_antag)
		return . | SPELL_CANCEL_CAST
	if(!succubus_antag.can_target_lewd(target))
		to_chat(owner, span_notice("I reach for [target.real_name]'s heart... and meet a wall of white flame. This soul is warded against me."))
		return . | SPELL_CANCEL_CAST
	if(succubus_antag.essence < SUCCUBUS_COST_LUST)
		to_chat(owner, span_warning("I don't have the essence to kindle their desire."))
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/succubus_lust/cast(mob/living/carbon/human/cast_on)
	. = ..()
	if(!istype(cast_on))
		return
	var/datum/antagonist/succubus/succubus_antag = IS_SUCCUBUS(owner)
	if(!succubus_antag)
		return

	// can_target_lewd() and the essence check already passed in before_cast.
	succubus_antag.adjust_essence(-SUCCUBUS_COST_LUST)
	// Arousal increase goes through the signal the arousal component itself listens for
	// (code/datums/components/arousal.dm RegisterWithParent -> COMSIG_SEX_ADJUST_AROUSAL ->
	// adjust_arousal()), same as the modular lewd spells enrapture.dm/forced_orgasm.dm - this
	// respects arousal_frozen internally, so no separate check is needed here.
	SEND_SIGNAL(cast_on, COMSIG_SEX_ADJUST_AROUSAL, 15)
	to_chat(cast_on, span_love("A wave of unbidden heat rolls through me..."))
	to_chat(owner, span_love("Desire kindles within [cast_on.real_name]."))

// --- Allure: toggled aura, no cost, slow pulse ----------------------------------------------------
// /datum/action/cooldown/spell has no built-in "toggle + periodic tick while active" shape of its
// own (its only process() is the charge-up mechanic, not applicable here - charge_required is
// FALSE on every succubus ability). The closest supported shape already used in this codebase for
// a self-buff spell is: the spell's cast() toggles state and applies/removes a status effect, and
// the status effect itself does the periodic tick via its own tick_interval (see
// code/modules/spells/spell_types/undirected/bloodrage.dm applying /datum/status_effect/buff/bloodrage,
// and code/datums/status_effects/buffs.dm's duration=-1/tick_interval pattern, e.g. sword_spin). That
// shape is mirrored here instead of inventing new action-level processing.

/datum/action/cooldown/spell/undirected/succubus_allure
	name = "Allure"
	desc = "Radiate a subtle, toggled aura of desire."
	has_visual_effects = FALSE
	antimagic_flags = NONE
	spell_flags = SPELL_IGNORE_SPELLBLOCK
	associated_skill = null
	charge_required = FALSE
	cooldown_time = 2 SECONDS
	var/aura_active = FALSE

/datum/action/cooldown/spell/undirected/succubus_allure/cast(mob/living/cast_on)
	. = ..()
	if(aura_active)
		deactivate_aura()
	else
		activate_aura()

/datum/action/cooldown/spell/undirected/succubus_allure/proc/activate_aura()
	aura_active = TRUE
	var/mob/living/current_owner = owner
	current_owner?.apply_status_effect(/datum/status_effect/succubus_allure_aura)
	to_chat(owner, span_love("I let my allure show..."))

/datum/action/cooldown/spell/undirected/succubus_allure/proc/deactivate_aura()
	aura_active = FALSE
	var/mob/living/current_owner = owner
	current_owner?.remove_status_effect(/datum/status_effect/succubus_allure_aura)
	to_chat(owner, span_notice("I rein my allure back in."))

/datum/action/cooldown/spell/undirected/succubus_allure/is_action_active(atom/movable/screen/movable/action_button/current_button)
	return aura_active

/datum/action/cooldown/spell/undirected/succubus_allure/Remove(mob/living/remove_from)
	if(aura_active && remove_from)
		remove_from.remove_status_effect(/datum/status_effect/succubus_allure_aura)
	aura_active = FALSE
	return ..()

/datum/status_effect/succubus_allure_aura
	id = "succubus_allure_aura"
	duration = -1
	tick_interval = 4 SECONDS
	alert_type = null

/// Nearby (range 3) humans who pass the lust-magic pref get a small arousal tick. Opted-out
/// humans are silently skipped - can_target_lewd() is the same gate every other ability uses.
/datum/status_effect/succubus_allure_aura/tick()
	var/datum/antagonist/succubus/succubus_antag = IS_SUCCUBUS(owner)
	if(!succubus_antag)
		return
	for(var/mob/living/carbon/human/target in range(3, owner))
		if(target == owner)
			continue
		if(!succubus_antag.can_target_lewd(target))
			continue
		SEND_SIGNAL(target, COMSIG_SEX_ADJUST_AROUSAL, 2)

// --- Aphrodisiac Kiss: self-buff, essence cost, delivered on the next kiss -----------------------
// Delivery ladder per the plan: (1) a dedicated kissing-action hook - kissing.dm
// (code/datums/sex/actions/oral/kissing.dm) exposes none, it just calls
// datum/sex_session/proc/perform_sex_action() like every other sex action; (2) COMSIG_SEX_RECEIVE_ACTION
// - this IS a clean hook: perform_sex_action sends it once per participant
// (code/datums/sex/sex_session.dm ~line 577: SEND_SIGNAL(pleasure_receiver, COMSIG_SEX_RECEIVE_ACTION,
// sex_act, pleasure_receiver, partner, ...)), so filtering by istype(s_action, /datum/sex_action/kissing)
// on a listener registered on the succubus's own mob identifies the kiss partner via the
// action_target arg. Landed on rung 2 - no touch-based downgrade needed.

/datum/action/cooldown/spell/undirected/succubus_aphrodisiac_kiss
	name = "Aphrodisiac Kiss"
	desc = "Lace your next kiss with a lingering aphrodisiac venom."
	has_visual_effects = FALSE
	antimagic_flags = NONE
	spell_flags = SPELL_IGNORE_SPELLBLOCK
	associated_skill = null
	charge_required = FALSE
	cooldown_time = 10 SECONDS
	/// Timer for the venom expiring unused
	var/venom_timer

// Essence check gated in before_cast, consistent with Lust/Detect Desire and with this codebase's
// convention that before_cast is where cost gating belongs (ai_navigation/spell_signal_map.md).
/datum/action/cooldown/spell/undirected/succubus_aphrodisiac_kiss/before_cast(mob/living/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	if(venom_timer)
		to_chat(owner, span_warning("My lips are already laced with venom."))
		return . | SPELL_CANCEL_CAST
	var/datum/antagonist/succubus/succubus_antag = IS_SUCCUBUS(owner)
	if(!succubus_antag || succubus_antag.essence < SUCCUBUS_COST_APHRODISIAC_KISS)
		to_chat(owner, span_warning("I don't have the essence to lace my lips with venom."))
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/undirected/succubus_aphrodisiac_kiss/cast(mob/living/cast_on)
	. = ..()
	var/datum/antagonist/succubus/succubus_antag = IS_SUCCUBUS(owner)
	if(!succubus_antag)
		return

	succubus_antag.adjust_essence(-SUCCUBUS_COST_APHRODISIAC_KISS)
	RegisterSignal(owner, COMSIG_SEX_RECEIVE_ACTION, PROC_REF(on_kiss_received), override = TRUE)
	if(venom_timer)
		deltimer(venom_timer)
	venom_timer = addtimer(CALLBACK(src, PROC_REF(expire_venom)), 2 MINUTES, TIMER_STOPPABLE)
	to_chat(owner, span_love("My lips grow sweet with venom; the next I kiss will taste it."))

/datum/action/cooldown/spell/undirected/succubus_aphrodisiac_kiss/proc/on_kiss_received(datum/source, datum/sex_action/s_action, mob/living/action_receiver, mob/living/action_partner, arousal_amt, pain_amt, orgasm_prog_amt, giving, applied_force, applied_speed, applied_resist, mob/living/action_performer)
	SIGNAL_HANDLER
	if(!istype(s_action, /datum/sex_action/kissing))
		return
	consume_venom(action_partner)

/datum/action/cooldown/spell/undirected/succubus_aphrodisiac_kiss/proc/consume_venom(mob/living/partner)
	if(venom_timer)
		deltimer(venom_timer)
		venom_timer = null
	if(owner)
		UnregisterSignal(owner, COMSIG_SEX_RECEIVE_ACTION)

	var/datum/antagonist/succubus/succubus_antag = IS_SUCCUBUS(owner)
	if(!succubus_antag || !succubus_antag.can_target_lewd(partner))
		to_chat(owner, span_warning("Their ward sours my venom."))
		return

	var/mob/living/carbon/human/human_partner = partner
	human_partner.reagents?.add_reagent(/datum/reagent/consumable/aphrodisiac, 5)
	to_chat(owner, span_love("My kiss leaves [human_partner] sweetly poisoned."))

/datum/action/cooldown/spell/undirected/succubus_aphrodisiac_kiss/proc/expire_venom()
	venom_timer = null
	if(!owner)
		return
	UnregisterSignal(owner, COMSIG_SEX_RECEIVE_ACTION)
	to_chat(owner, span_notice("The venom on my lips fades, unused."))

/datum/action/cooldown/spell/undirected/succubus_aphrodisiac_kiss/Remove(mob/living/remove_from)
	if(venom_timer)
		deltimer(venom_timer)
		venom_timer = null
	if(remove_from)
		UnregisterSignal(remove_from, COMSIG_SEX_RECEIVE_ACTION)
	return ..()

// --- Grant / remove wiring (composed into succubus_camouflage.dm's grant_succubus_powers/
// remove_succubus_powers, which are the single definitions of those two proc names) --------------

/datum/antagonist/succubus/proc/grant_succubus_abilities()
	var/mob/living/current_mob = owner?.current
	if(!current_mob)
		return
	current_mob.add_spell(/datum/action/cooldown/spell/succubus_detect_desire, source = owner)
	current_mob.add_spell(/datum/action/cooldown/spell/succubus_lust, source = owner)
	current_mob.add_spell(/datum/action/cooldown/spell/undirected/succubus_allure, source = owner)
	current_mob.add_spell(/datum/action/cooldown/spell/undirected/succubus_aphrodisiac_kiss, source = owner)

/datum/antagonist/succubus/proc/remove_succubus_abilities()
	var/mob/living/current_mob = owner?.current
	if(!current_mob)
		return
	current_mob.remove_spell(/datum/action/cooldown/spell/succubus_detect_desire)
	current_mob.remove_spell(/datum/action/cooldown/spell/succubus_lust)
	current_mob.remove_spell(/datum/action/cooldown/spell/undirected/succubus_allure)
	current_mob.remove_spell(/datum/action/cooldown/spell/undirected/succubus_aphrodisiac_kiss)
	// Defensive: Allure's toggle applies a standing aura status effect that outlives the spell
	// action itself (they're separate datums) if the antag is stripped mid-pulse.
	if(current_mob.has_status_effect(/datum/status_effect/succubus_allure_aura))
		current_mob.remove_status_effect(/datum/status_effect/succubus_allure_aura)
