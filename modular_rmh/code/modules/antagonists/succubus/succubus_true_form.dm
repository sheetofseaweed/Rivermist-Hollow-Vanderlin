// True form: a new species-based mob (transform machinery mirrors the werewolf's), the
// original body stashed inside it by die_with_form, mind moved via transfer_to. Revert is
// signal-driven (COMSIG_LIVING_UNSHAPESHIFTED); death reverts the corpse to human too.

// --- True form mob + species (werewolf sprite is a PLACEHOLDER) ----------------------------------

/mob/living/carbon/human/species/succubus_true
	race = /datum/species/succubus_true_form
	// ~80% of the wolf's statline: strong, but not a combat monster
	base_strength = 12
	base_constitution = 12
	base_endurance = 12
	gender = FEMALE
	ambushable = FALSE

/datum/attribute_holder/sheet/job/species/succubus_true_form
	raw_attribute_list = list(
		STAT_STRENGTH = 4,
		STAT_PERCEPTION = 4,
		STAT_CONSTITUTION = 4,
		STAT_ENDURANCE = 4,
		STAT_SPEED = 3,
	)

/datum/species/succubus_true_form
	name = "true succubus"
	id = "succubus_true"
	// A shapeshift-origin species (species_whitelists test requires a changesource)
	changesource_flags = WABBAJACK
	species_traits = list(NO_UNDERWEAR, NOEYESPRITES)
	inherent_traits = list(
		TRAIT_RESISTCOLD,
		TRAIT_ZJUMP,
		TRAIT_NOFALLDAMAGE1,
		TRAIT_CRITICAL_RESISTANCE,
		TRAIT_LONGSTRIDER,
	)

/datum/species/succubus_true_form/regenerate_icons(mob/living/carbon/human/H)
	// PLACEHOLDER: werewolf sheet until succubus art exists
	H.icon = 'modular_rmh/icons/mob/monster/werewolf.dmi'
	H.icon_state = "wwolf_f"
	H.update_damage_overlays()
	return TRUE

/datum/species/succubus_true_form/update_damage_overlays(mob/living/carbon/human/H)
	// Placeholder sheet has wolf-shaped damage states; suppress until real art lands
	H.remove_overlay(DAMAGE_LAYER)
	return TRUE

// --- Transform / revert machinery ----------------------------------------------------------------

/datum/antagonist/succubus
	var/true_form_active = FALSE

/datum/antagonist/succubus/proc/can_assume_true_form(silent = FALSE)
	if(true_form_active)
		return FALSE
	var/mob/living/carbon/human/body = owner?.current
	if(!ishuman(body) || body.stat == DEAD)
		return FALSE
	if(HAS_TRAIT(body, TRAIT_NO_TRANSFORM))
		return FALSE
	if(essence < SUCCUBUS_COST_TRUE_FORM)
		if(!silent)
			to_chat(body, span_warning("I lack the essence to shed this shell."))
		return FALSE
	return TRUE

/datum/antagonist/succubus/proc/assume_true_form()
	if(!can_assume_true_form())
		return FALSE
	var/mob/living/carbon/human/human_user = owner.current
	// The true form wears no masks: shed any stolen face first
	if(!isnull(current_form_key))
		revert_form(forced = FALSE)
	adjust_essence(-SUCCUBUS_COST_TRUE_FORM)
	if(human_user.cmode)
		human_user.toggle_cmode()
	human_user.flash_fullscreen("redflash3")
	human_user.visible_message(
		span_boldwarning("[human_user]'s skin splits with rosy light — wings unfurl, a tail lashes, and something beautiful and terrible steps out of the shell!"),
		span_love("I let the shell fall away. THIS is what I am."),
	)

	var/mob/living/carbon/human/species/succubus_true/new_form = new(get_turf(human_user))
	new_form.age = human_user.age
	// No longer hiding: her own name
	new_form.real_name = human_user.real_name
	new_form.name = new_form.real_name
	new_form.apply_status_effect(/datum/status_effect/shapechange_mob/die_with_form, human_user)
	if(human_user.attributes && new_form.attributes)
		new_form.attributes.copy_skill_state(human_user.attributes)
	new_form.set_patron(human_user.patron)
	new_form.blood_volume = human_user.blood_volume

	// Mirror the human's genital loadout with standard organs
	if(human_user.getorganslot(ORGAN_SLOT_PENIS))
		var/obj/item/organ/genitals/penis/penis = new
		penis.Insert(new_form, TRUE, FALSE)
	if(human_user.getorganslot(ORGAN_SLOT_TESTICLES))
		var/obj/item/organ/genitals/filling_organ/testicles/internal/testicles = new
		testicles.Insert(new_form, TRUE, FALSE)
	if(human_user.getorganslot(ORGAN_SLOT_BREASTS))
		var/obj/item/organ/genitals/filling_organ/breasts/breasts = new
		breasts.Insert(new_form, TRUE, FALSE)
	if(human_user.getorganslot(ORGAN_SLOT_VAGINA))
		var/obj/item/organ/genitals/filling_organ/vagina/vagina = new
		vagina.Insert(new_form, TRUE, FALSE)

	true_form_active = TRUE
	var/datum/mind/succubus_mind = human_user.mind
	if(succubus_mind?.current == human_user)
		// Fires on_body_transfer(), re-homing the camouflage/status signals
		succubus_mind.transfer_to(new_form, TRUE)
	RegisterSignal(new_form, COMSIG_LIVING_UNSHAPESHIFTED, PROC_REF(on_true_form_ended))
	RegisterSignal(new_form, COMSIG_PARENT_QDELETING, PROC_REF(on_true_form_body_deleted))
	playsound(new_form, 'sound/magic/demon_attack1.ogg', 80, TRUE)
	return TRUE

/datum/antagonist/succubus/proc/leave_true_form()
	var/mob/living/form_body = owner?.current
	if(!true_form_active || !isliving(form_body))
		return FALSE
	// The status effect restores the stashed human and moves the mind back
	form_body.remove_status_effect(/datum/status_effect/shapechange_mob/die_with_form)
	return TRUE

/// COMSIG_LIVING_UNSHAPESHIFTED handler — fires on any revert, including death-in-form
/datum/antagonist/succubus/proc/on_true_form_ended(mob/living/status_owner, mob/living/status_caster_mob)
	SIGNAL_HANDLER
	true_form_active = FALSE
	UnregisterSignal(status_owner, list(COMSIG_LIVING_UNSHAPESHIFTED, COMSIG_PARENT_QDELETING))
	var/mob/living/restored = status_caster_mob
	// die_with_form does NOT move the mind back (only the /from_spell subtype does); we must,
	// or restore_caster()'s qdel(owner) strands the player in the deleted true-form body
	var/datum/mind/form_mind = status_owner?.mind
	if(form_mind?.current == status_owner && isliving(restored))
		form_mind.transfer_to(restored, TRUE)
	if(isliving(restored))
		restored.visible_message(
			span_warning("The terrible glamour collapses back into [restored]'s mortal shell."),
			span_love("I fold myself back into the little shell."),
		)

/// True-form body gibbed/deleted without an unshapeshift, so the revert path never runs —
/// clear the stale flag. Signal auto-unregisters on the qdel.
/datum/antagonist/succubus/proc/on_true_form_body_deleted(datum/source)
	SIGNAL_HANDLER
	true_form_active = FALSE

// --- Form spell -----------------------------------------------------------------------------------

/datum/action/cooldown/spell/undirected/succubus_true_form
	name = "True Form"
	desc = "Shed the mortal shell and stand revealed — or fold back into it. Entering costs essence, and there is no hiding what you are afterward."
	has_visual_effects = FALSE
	antimagic_flags = NONE
	spell_flags = SPELL_IGNORE_SPELLBLOCK
	associated_skill = null
	charge_required = FALSE
	cooldown_time = SUCCUBUS_TRUE_FORM_COOLDOWN

/datum/action/cooldown/spell/undirected/succubus_true_form/before_cast(mob/living/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	var/datum/antagonist/succubus/succubus_antag = IS_SUCCUBUS(owner)
	if(!succubus_antag)
		return . | SPELL_CANCEL_CAST
	// can_assume_true_form messages on failure; leaving is always allowed
	if(!succubus_antag.true_form_active && !succubus_antag.can_assume_true_form())
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/undirected/succubus_true_form/cast(mob/living/cast_on)
	. = ..()
	var/datum/antagonist/succubus/succubus_antag = IS_SUCCUBUS(owner)
	if(!succubus_antag)
		return
	if(succubus_antag.true_form_active)
		succubus_antag.leave_true_form()
	else
		succubus_antag.assume_true_form()
