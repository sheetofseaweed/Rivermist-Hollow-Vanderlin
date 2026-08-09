// Camouflage: wardrobe, form state, integrity breaks, disguise actions.

/datum/antagonist/succubus
	/// mind -> /datum/identity_snapshot of sampled partners (capped)
	var/list/stolen_forms = list()
	/// The selected preference character, retained as the first mortal disguise
	var/datum/identity_snapshot/starting_form
	/// Complete snapshot of the Succubus's natural Demon identity
	var/datum/identity_snapshot/base_form
	/// Opaque key for the currently worn mortal identity (null = Demon form)
	var/current_form_key

/// Captures the current character, derives a Demon on the same body, and stores both identities.
/datum/antagonist/succubus/proc/initialize_demon_identity()
	var/mob/living/carbon/human/body = owner?.current
	if(!ishuman(body) || !body.dna)
		return FALSE
	if(starting_form && base_form)
		return TRUE

	QDEL_NULL(starting_form)
	QDEL_NULL(base_form)
	starting_form = new
	if(!starting_form.capture(body))
		QDEL_NULL(starting_form)
		return FALSE

	body.set_species(/datum/species/demon, icon_update = FALSE)
	if(!istype(body.dna.species, /datum/species/demon))
		starting_form.apply(body)
		QDEL_NULL(starting_form)
		return FALSE

	// Species gain supplies the infernal skin and fixed anatomy. Reapply only
	// the personal details approved for the derived first-pass Demon identity.
	body.real_name = starting_form.real_name
	body.age = starting_form.age
	body.gender = starting_form.gender
	body.pronouns = starting_form.pronouns
	body.voice_type = starting_form.voice_type
	body.voice_color = starting_form.voice_color
	body.honorary = starting_form.honorary
	body.honorary_suffix = starting_form.honorary_suffix
	body.set_hair_color(starting_form.hair_color, FALSE)
	body.set_hair_style(starting_form.hair_style_type, FALSE)
	body.set_facial_hair_color(starting_form.facial_hair_color, FALSE)
	body.set_facial_hair_style(starting_form.facial_hair_style_type, FALSE)
	body.set_eye_color(starting_form.eye_color_right, starting_form.eye_color_left, FALSE)
	body.dna.real_name = starting_form.dna.real_name
	body.dna.unique_enzymes = starting_form.dna.unique_enzymes
	body.dna.update_ui_block(DNA_GENDER_BLOCK)

	// Preserve the selected genital layout while keeping Demon horns, tail,
	// wings, blood, and all other species-owned anatomy.
	var/static/list/preserved_genital_slots = list(
		ORGAN_SLOT_PENIS,
		ORGAN_SLOT_TESTICLES,
		ORGAN_SLOT_BREASTS,
		ORGAN_SLOT_VAGINA,
		ORGAN_SLOT_ANUS,
		ORGAN_SLOT_BUTT,
		ORGAN_SLOT_BELLY,
		ORGAN_SLOT_PUBIC,
	)
	for(var/stored_slot in preserved_genital_slots)
		var/datum/organ_dna/stored_genital_dna = starting_form.dna.organ_dna[stored_slot]
		if(stored_genital_dna)
			body.dna.organ_dna[stored_slot] = stored_genital_dna
		else
			body.dna.organ_dna -= stored_slot
	body.dna.species.regenerate_organs(body, body.dna.species)
	body.update_organ_colors()

	// Detach the live body's genital DNA from the snapshot-owned datums used
	// during regeneration.
	for(var/current_slot in preserved_genital_slots)
		var/list/current_organs = body.getorganslotlist(current_slot)
		var/datum/organ_dna/current_genital_dna
		for(var/obj/item/organ/current_organ as anything in current_organs)
			if(current_genital_dna)
				current_organ.imprint_organ_dna(current_genital_dna)
			else
				current_genital_dna = current_organ.create_organ_dna()
		if(current_genital_dna)
			body.dna.organ_dna[current_slot] = current_genital_dna
		else
			body.dna.organ_dna -= current_slot

	body.updateappearance(mutcolor_update = TRUE)
	body.update_body_parts(TRUE)
	body.name = body.get_visible_name()
	current_form_key = null

	base_form = new
	if(!base_form.capture(body))
		starting_form.apply(body)
		QDEL_NULL(base_form)
		QDEL_NULL(starting_form)
		return FALSE
	return TRUE

/datum/antagonist/succubus/proc/restore_starting_identity()
	var/mob/living/carbon/human/body = owner?.current
	if(!ishuman(body) || !starting_form)
		return FALSE
	if(!starting_form.apply(body))
		return FALSE
	current_form_key = null
	return TRUE

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
	if(is_succubus_consecrated(body))
		to_chat(body, span_warning("White fire traces the refuge's ward; no borrowed face will hold here."))
		return FALSE
	var/obj/structure/succubus_rift/rift = get_active_rift()
	if(rift?.current_stage == SUCCUBUS_RIFT_STAGE_OPEN)
		to_chat(body, span_userdanger("The open Rift has chained me to my unveiled flesh. No mortal mask will hold until its verdict is decided!"))
		return FALSE
	var/camouflage_cost = SUCCUBUS_COST_CAMOUFLAGE
	if(!has_entered_mortal_world && istype(get_area(body), /area/indoors/succubus_lair))
		camouflage_cost = 0
	if(essence < camouflage_cost)
		to_chat(body, span_warning("I lack the essence to reshape my flesh."))
		return FALSE
	if(!base_form)
		base_form = new
		base_form.capture(body)
	if(!snap.apply(body))
		return FALSE
	if(camouflage_cost)
		adjust_essence(-camouflage_cost)
	current_form_key = form_key
	refresh_succubus_form_actions()
	body.visible_message(span_warning("[body]'s features ripple for a heartbeat."), span_love("My flesh flows into the borrowed shape."))
	return TRUE

/datum/antagonist/succubus/proc/revert_form(forced = FALSE)
	var/mob/living/carbon/human/body = owner?.current
	if(!ishuman(body) || !base_form || isnull(current_form_key))
		return FALSE
	if(!forced && !can_voluntarily_reveal())
		return FALSE
	if(!base_form.apply(body))
		return FALSE
	current_form_key = null
	if(forced)
		body.visible_message(span_boldwarning("[body]'s borrowed face TEARS away, exposing long horns, a lashing tail, and wide infernal wings!"), span_userdanger("My mask shatters, leaving my true flesh exposed!"))
	else
		body.visible_message(span_boldwarning("[body]'s mortal guise peels away in rose-colored light, revealing a horned and winged demon!"), span_love("I let the little mortal mask fall away and stand in my true flesh."))
	refresh_succubus_form_actions(unleash_presence = TRUE)
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
	QDEL_NULL(active_disguise_editor)
	if(old_body)
		unregister_camouflage_integrity_signals(old_body)
		old_body.remove_status_effect(/datum/status_effect/succubus_allure_aura)
	. = ..()
	register_camouflage_integrity_signals(new_body)
	refresh_succubus_form_actions()

/// called via COMSIG_LIVING_DEATH
/datum/antagonist/succubus/proc/on_camouflage_death(datum/source)
	SIGNAL_HANDLER
	revert_form(forced = TRUE)
	var/obj/structure/succubus_rift/rift = get_active_rift()
	if(rift?.current_stage == SUCCUBUS_RIFT_STAGE_OPEN)
		rift.resolve_verdict(ascended = FALSE)

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
	desc = "Wear a remembered mortal identity."
	has_visual_effects = FALSE
	antimagic_flags = NONE
	spell_flags = SPELL_IGNORE_SPELLBLOCK
	associated_skill = null
	charge_required = FALSE
	cooldown_time = 2 SECONDS
	/// Opaque wardrobe key picked in before_cast(), consumed by cast().
	var/chosen_form_key

/datum/action/cooldown/spell/undirected/succubus_weave_disguise/before_cast(mob/living/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return

	chosen_form_key = null
	var/datum/antagonist/succubus/succubus_antag = IS_SUCCUBUS(owner)
	var/list/disguise_choices = succubus_antag?.get_wearable_disguise_choices()
	if(!length(disguise_choices))
		to_chat(owner, span_warning("I have no mortal identities to wear."))
		return . | SPELL_CANCEL_CAST

	var/picked_name = tgui_input_list(owner, "Which identity shall I wear?", "Weave Disguise", disguise_choices)
	if(QDELETED(src) || QDELETED(owner) || IS_SUCCUBUS(owner) != succubus_antag || !can_cast_spell())
		return . | SPELL_CANCEL_CAST
	if(!picked_name || !(picked_name in disguise_choices))
		reset_spell_cooldown()
		return . | SPELL_CANCEL_CAST
	chosen_form_key = disguise_choices[picked_name]

/datum/action/cooldown/spell/undirected/succubus_weave_disguise/cast(mob/living/cast_on)
	. = ..()
	var/form_key = chosen_form_key
	chosen_form_key = null
	var/datum/antagonist/succubus/succubus_antag = IS_SUCCUBUS(owner)
	if(!succubus_antag || isnull(form_key))
		return
	var/datum/identity_snapshot/snap = succubus_antag.get_disguise_snapshot(form_key)
	if(!snap)
		return
	succubus_antag.wear_form(snap, form_key)

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
	if(isnull(succubus_antag.current_form_key))
		to_chat(owner, span_warning("I already wear my own face."))
		return
	succubus_antag.revert_form(FALSE)

// --- Grant / remove wiring ----------------------------------------------------------------------
// Camouflage actions + integrity signals here; the ability kit composes in via
// grant_succubus_abilities()/remove_succubus_abilities() (succubus_abilities.dm).

/datum/antagonist/succubus/proc/grant_succubus_powers()
	var/mob/living/current_mob = owner?.current
	if(!current_mob)
		return
	current_mob.add_spell(/datum/action/cooldown/spell/undirected/succubus_weave_disguise, source = owner)
	current_mob.add_spell(/datum/action/cooldown/spell/undirected/succubus_shed_disguise, source = owner)
	current_mob.add_spell(/datum/action/cooldown/spell/undirected/succubus_create_disguise, source = owner)
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
	current_mob.remove_spell(/datum/action/cooldown/spell/undirected/succubus_create_disguise)
