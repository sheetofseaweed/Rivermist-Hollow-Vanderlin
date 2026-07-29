// Camouflage: wardrobe, form state, integrity breaks, disguise actions.

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
	if(true_form_active)
		to_chat(body, span_warning("This shape wears no masks."))
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

// --- Camouflage integrity: heavy damage, KO, or death rips the disguise --------------------------
// All body-homed succubus signals (integrity + status tab) share this register/unregister pair,
// so grant/remove/body-transfer each re-home them in one call. Health uses HEALTH_UPDATE (fires
// after the recalc) rather than APPLY_DAMAGE (fires before), so the threshold check is accurate.
/datum/antagonist/succubus/proc/register_camouflage_integrity_signals(mob/living/body)
	body = body || owner?.current
	if(!body)
		return
	RegisterSignal(body, COMSIG_LIVING_DEATH, PROC_REF(on_camouflage_death))
	RegisterSignal(body, COMSIG_LIVING_HEALTH_UPDATE, PROC_REF(on_camouflage_health_update))
	RegisterSignal(body, COMSIG_MOB_STATCHANGE, PROC_REF(on_camouflage_stat_change))
	RegisterSignal(body, COMSIG_MOB_GET_STATUS_TAB_ITEMS, PROC_REF(on_status_tab))

/datum/antagonist/succubus/proc/unregister_camouflage_integrity_signals(mob/living/body)
	body = body || owner?.current
	if(!body)
		return
	UnregisterSignal(body, list(COMSIG_LIVING_DEATH, COMSIG_LIVING_HEALTH_UPDATE, COMSIG_MOB_STATCHANGE, COMSIG_MOB_GET_STATUS_TAB_ITEMS))

// Hand-registered listeners must follow mind transfers (spells with a mind source re-home themselves)
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

/// COMSIG_MOB_STATCHANGE (new_stat, old_stat): a knocked-out succubus can't hold the weave.
/// DEAD excluded to avoid double-firing with COMSIG_LIVING_DEATH above.
/datum/antagonist/succubus/proc/on_camouflage_stat_change(datum/source, new_stat, old_stat)
	SIGNAL_HANDLER
	if(isnull(current_form_key))
		return
	if(new_stat < UNCONSCIOUS || new_stat == DEAD)
		return
	revert_form(forced = TRUE)

// --- Player-facing camouflage actions ----------------------------------------------------------

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

	// Deduplicated display-name -> mind map; the picker echoes our own string keys back,
	// so the mind is looked up locally rather than relying on its internal keying.
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
// Camouflage actions + integrity signals here; the ability kit composes in via
// grant_succubus_abilities()/remove_succubus_abilities() (succubus_abilities.dm).

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
