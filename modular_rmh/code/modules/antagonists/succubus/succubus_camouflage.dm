// Succubus antagonist core — camouflage wardrobe, form state, integrity breaks (Task 4)
// See docs/superpowers/plans/2026-07-17-succubus-core.md

// Camouflage wardrobe + form state, on the antag datum
/datum/antagonist/succubus
	/// mind -> /datum/identity_snapshot of sampled partners (capped)
	var/list/stolen_forms = list()
	/// Snapshot of the succubus's own base identity, captured on first camouflage
	var/datum/identity_snapshot/base_form
	/// Currently worn stolen form's key (null = own form)
	var/current_form_key

/datum/antagonist/succubus/proc/store_partner_form(mob/living/carbon/human/partner)
	if(!istype(partner) || !partner.mind)
		return
	if(stolen_forms[partner.mind])
		return
	if(length(stolen_forms) >= SUCCUBUS_WARDROBE_CAP)
		if(owner?.current)
			to_chat(owner.current, span_warning("My wardrobe of faces is full; this one slips away unmemorized."))
		return
	var/datum/identity_snapshot/snap = new
	snap.capture(partner)
	stolen_forms[partner.mind] = snap
	if(owner?.current)
		to_chat(owner.current, span_love("I memorize [partner.real_name]'s face for my own use."))

/datum/antagonist/succubus/proc/wear_form(datum/identity_snapshot/snap, form_key)
	var/mob/living/carbon/human/body = owner?.current
	if(!ishuman(body) || !snap)
		return FALSE
	if(essence < SUCCUBUS_COST_CAMOUFLAGE)
		to_chat(body, span_warning("I lack the essence to reshape my flesh."))
		return FALSE
	if(!base_form)
		base_form = new
		base_form.capture(body)
	if(!snap.apply(body))
		return FALSE
	adjust_essence(-SUCCUBUS_COST_CAMOUFLAGE)
	current_form_key = form_key
	body.visible_message(span_warning("[body]'s features ripple for a heartbeat."), span_love("My flesh flows into the borrowed shape."))
	return TRUE

/datum/antagonist/succubus/proc/revert_form(forced = FALSE)
	var/mob/living/carbon/human/body = owner?.current
	if(!ishuman(body) || !base_form || isnull(current_form_key))
		return FALSE
	base_form.apply(body)
	current_form_key = null
	if(forced)
		body.visible_message(span_boldwarning("[body]'s borrowed face TEARS away — for a moment, something with a tail and wings shows through!"), span_userdanger("My mask shatters!"))
	return TRUE

// --- Camouflage integrity: heavy damage or death rips the disguise (spec §3) -----------------
// Signals are registered in grant_succubus_powers() / unregistered in remove_succubus_powers()
// (below), directly on owner.current — mirrors code/modules/antagonists/villain/lich/lich.dm's
// on_gain/on_removal COMSIG_LIVING_DEATH registration pattern.
//
// COMSIG_MOB_APPLY_DAMAGE fires at the TOP of /mob/living/proc/apply_damage(), before the health
// pools are actually adjusted (code/modules/mob/living/damage_procs.dm:111) — so it can't answer
// "is health below X% right now". COMSIG_LIVING_HEALTH_UPDATE fires from carbon/human's own
// updatehealth() *after* the health value is recalculated, and code/datums/components/defeat_monitor.dm
// is a real, in-repo listener that already reacts to post-update health/threshold state the same
// way this needs to — so that signal is mirrored here instead, per the plan's own allowance to use
// "a different health-change signal" if the codebase's real precedent points there.

/datum/antagonist/succubus/proc/register_camouflage_integrity_signals(mob/living/body)
	body = body || owner?.current
	if(!body)
		return
	RegisterSignal(body, COMSIG_LIVING_DEATH, PROC_REF(on_camouflage_death))
	RegisterSignal(body, COMSIG_LIVING_HEALTH_UPDATE, PROC_REF(on_camouflage_health_update))

/datum/antagonist/succubus/proc/unregister_camouflage_integrity_signals(mob/living/body)
	body = body || owner?.current
	if(!body)
		return
	UnregisterSignal(body, list(COMSIG_LIVING_DEATH, COMSIG_LIVING_HEALTH_UPDATE))

// Integrity listeners are hand-registered on the body, so they must follow mind
// transfers; spells granted with the mind as source already re-home themselves.
/datum/antagonist/succubus/on_body_transfer(mob/living/old_body, mob/living/new_body)
	if(old_body)
		unregister_camouflage_integrity_signals(old_body)
		old_body.remove_status_effect(/datum/status_effect/succubus_allure_aura)
	. = ..()
	register_camouflage_integrity_signals(new_body)

/// called via COMSIG_LIVING_DEATH
/datum/antagonist/succubus/proc/on_camouflage_death(datum/source)
	SIGNAL_HANDLER
	revert_form(forced = TRUE)

/// called via COMSIG_LIVING_HEALTH_UPDATE
/datum/antagonist/succubus/proc/on_camouflage_health_update(datum/source, ...)
	SIGNAL_HANDLER
	if(isnull(current_form_key))
		return
	var/mob/living/carbon/human/body = owner?.current
	if(!istype(body))
		return
	if(body.health < body.maxHealth * SUCCUBUS_FORM_BREAK_HEALTH_FRACTION)
		revert_form(forced = TRUE)

// --- Player-facing camouflage actions ----------------------------------------------------------
// Base API pinned from code/modules/antagonists/villain/werewolf/werewolf_spells.dm (howl/claws)
// and code/modules/spells/spell.dm: /datum/action/cooldown/spell, undirected subtype for
// self-targeting (click_to_activate = FALSE), before_cast()/cast() cast chain, granted via
// mob/living/proc/add_spell(path, source = owner) and removed via remove_spell(path) — exact
// mirror of werewolf's grant_werewolf_powers()/remove_werewolf_powers().
//
// Weave Disguise needs a "pick one of N stored faces" prompt; before_cast() is where howl.dm
// itself blocks on a player prompt (browser_input_text) before continuing the cast chain, so the
// same shape is used here with tgui_input_list (code/modules/tgui_input/list.dm).

/datum/action/cooldown/spell/undirected/succubus_weave_disguise
	name = "Weave Disguise"
	desc = "Wear a stolen face from memory."
	has_visual_effects = FALSE
	antimagic_flags = NONE
	spell_flags = SPELL_IGNORE_SPELLBLOCK
	associated_skill = null
	charge_required = FALSE
	cooldown_time = 2 SECONDS
	/// Mind key picked in before_cast(), consumed by cast()
	var/datum/mind/chosen_mind

/datum/action/cooldown/spell/undirected/succubus_weave_disguise/before_cast(mob/living/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return

	chosen_mind = null
	var/datum/antagonist/succubus/succubus_antag = IS_SUCCUBUS(owner)
	if(!succubus_antag || !length(succubus_antag.stolen_forms))
		to_chat(owner, span_warning("I have no stolen faces to wear."))
		return . | SPELL_CANCEL_CAST

	// Build a locally-deduplicated display name -> mind map. tgui_input_list() stringifies and
	// echoes back whatever is in the `items` list it's given (code/modules/tgui_input/list.dm) -
	// passing our own pre-built string keys means the value handed back is guaranteed to be one of
	// our keys, so we can look the mind back up ourselves without depending on its internal
	// dedup/keying scheme.
	var/list/name_to_mind = list()
	for(var/datum/mind/stored_mind as anything in succubus_antag.stolen_forms)
		var/datum/identity_snapshot/snap = succubus_antag.stolen_forms[stored_mind]
		var/base_name = snap?.real_name || "Unknown"
		var/display_name = base_name
		var/suffix = 2
		while(display_name in name_to_mind)
			display_name = "[base_name] ([suffix])"
			suffix++
		name_to_mind[display_name] = stored_mind

	var/picked_name = tgui_input_list(owner, "Whose face shall I wear?", "Weave Disguise", name_to_mind)
	if(QDELETED(src) || QDELETED(owner) || !can_cast_spell())
		return . | SPELL_CANCEL_CAST
	if(!picked_name || !(picked_name in name_to_mind))
		reset_spell_cooldown()
		return . | SPELL_CANCEL_CAST
	chosen_mind = name_to_mind[picked_name]

/datum/action/cooldown/spell/undirected/succubus_weave_disguise/cast(mob/living/cast_on)
	. = ..()
	var/datum/antagonist/succubus/succubus_antag = IS_SUCCUBUS(owner)
	if(!succubus_antag || !chosen_mind)
		return
	var/datum/identity_snapshot/snap = succubus_antag.stolen_forms[chosen_mind]
	if(!snap)
		return
	succubus_antag.wear_form(snap, chosen_mind)
	chosen_mind = null

/datum/action/cooldown/spell/undirected/succubus_shed_disguise
	name = "Shed Disguise"
	desc = "Let a stolen face fall away, returning to my own."
	has_visual_effects = FALSE
	antimagic_flags = NONE
	spell_flags = SPELL_IGNORE_SPELLBLOCK
	associated_skill = null
	charge_required = FALSE
	cooldown_time = 2 SECONDS

/datum/action/cooldown/spell/undirected/succubus_shed_disguise/cast(mob/living/cast_on)
	. = ..()
	var/datum/antagonist/succubus/succubus_antag = IS_SUCCUBUS(owner)
	if(!succubus_antag)
		return
	if(!succubus_antag.revert_form(FALSE))
		to_chat(owner, span_warning("I already wear my own face."))

// --- Grant / remove wiring ----------------------------------------------------------------------
// Replaces the Task 3 stubs of the same name (removed from succubus.dm). Camouflage actions +
// integrity signals live here; the T1/T2 ability kit is composed in via
// grant_succubus_abilities()/remove_succubus_abilities() (succubus_abilities.dm, Task 5) so each
// file only defines the procs for its own responsibility slice.

/datum/antagonist/succubus/proc/grant_succubus_powers()
	var/mob/living/current_mob = owner?.current
	if(!current_mob)
		return
	current_mob.add_spell(/datum/action/cooldown/spell/undirected/succubus_weave_disguise, source = owner)
	current_mob.add_spell(/datum/action/cooldown/spell/undirected/succubus_shed_disguise, source = owner)
	register_camouflage_integrity_signals()
	grant_succubus_abilities()

/datum/antagonist/succubus/proc/remove_succubus_powers()
	remove_succubus_abilities()
	unregister_camouflage_integrity_signals()
	var/mob/living/current_mob = owner?.current
	if(!current_mob)
		return
	current_mob.remove_spell(/datum/action/cooldown/spell/undirected/succubus_weave_disguise)
	current_mob.remove_spell(/datum/action/cooldown/spell/undirected/succubus_shed_disguise)
