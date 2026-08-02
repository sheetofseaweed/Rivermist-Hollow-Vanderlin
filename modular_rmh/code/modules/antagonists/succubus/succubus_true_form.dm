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

/datum/antagonist/succubus/proc/is_linked_retinue(mob/living/possible_friend)
	if(!possible_friend || !owner)
		return FALSE
	if(possible_friend.mind == owner)
		return TRUE

	var/mob/living/simple_animal/hostile/retaliate/wolf/companion/lustbound/hound = possible_friend
	if(istype(hound) && hound.mistress_mind_ref?.resolve() == owner)
		return TRUE
	if(!possible_friend.mind)
		return FALSE

	var/datum/antagonist/succubus_thrall/thrall_datum = possible_friend.mind.has_antag_datum(/datum/antagonist/succubus_thrall)
	if(thrall_datum?.mistress_mind == owner)
		return TRUE

	var/datum/antagonist/succubus_imp/imp_datum = possible_friend.mind.has_antag_datum(/datum/antagonist/succubus_imp)
	return imp_datum?.mistress_mind == owner

/datum/antagonist/succubus/proc/grant_true_form_actions(mob/living/form_body)
	if(!istype(form_body))
		return
	// Body-sourced actions die with the spawned form and do not follow the mind home.
	form_body.add_spell(/datum/action/cooldown/spell/succubus_wingbeat, source = form_body)
	form_body.add_spell(/datum/action/cooldown/spell/aoe/repulse/dragon/succubus, source = form_body)
	form_body.add_spell(/datum/action/cooldown/spell/succubus_sovereign_gaze, source = form_body)
	form_body.add_spell(/datum/action/cooldown/spell/undirected/succubus_predatory_claws, source = form_body)
	refresh_succubus_rift_action(form_body)

/datum/antagonist/succubus/proc/remove_true_form_actions(mob/living/form_body)
	if(!istype(form_body))
		return
	form_body.remove_spell(/datum/action/cooldown/spell/succubus_wingbeat)
	form_body.remove_spell(/datum/action/cooldown/spell/aoe/repulse/dragon/succubus)
	form_body.remove_spell(/datum/action/cooldown/spell/succubus_sovereign_gaze)
	form_body.remove_spell(/datum/action/cooldown/spell/undirected/succubus_predatory_claws)
	form_body.remove_spell(/datum/action/cooldown/spell/undirected/succubus_rift)

/datum/antagonist/succubus/proc/unleash_overwhelming_presence(mob/living/form_body)
	if(!istype(form_body))
		return
	form_body.visible_message(
		span_boldwarning("A crushing infernal presence rolls outward from [form_body]!"),
		span_love("The room buckles beneath the weight of my unveiled presence."),
	)
	for(var/mob/living/victim in view(SUCCUBUS_TRUE_FORM_PRESENCE_RANGE, form_body))
		// The stashed human body lives inside the form; only affect map-present mobs.
		if(!isturf(victim.loc) || victim == form_body || victim.stat == DEAD || is_linked_retinue(victim))
			continue
		new /obj/effect/temp_visual/dir_setting/curse(get_turf(victim), get_dir(form_body, victim))
		if(get_dist(form_body, victim) <= 1)
			victim.Knockdown(SUCCUBUS_TRUE_FORM_PRESENCE_KNOCKDOWN)
			to_chat(victim, span_userdanger("The unveiled demon's presence drives me to the ground!"))
		else
			victim.Immobilize(SUCCUBUS_TRUE_FORM_PRESENCE_IMMOBILIZE)
			to_chat(victim, span_userdanger("The unveiled demon's presence arrests me for a heartbeat!"))

/datum/antagonist/succubus/proc/can_assume_true_form(silent = FALSE)
	if(true_form_active)
		return FALSE
	var/mob/living/carbon/human/body = owner?.current
	if(!ishuman(body) || body.stat == DEAD)
		return FALSE
	if(get_succubus_contract_tier() < SUCCUBUS_TRUE_FORM_UNLOCK_TIER)
		if(!silent)
			to_chat(body, span_warning("Asmodeus has not yet granted me the power to shed this shell."))
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
		if(nulltozero(new_form.attributes.raw_attribute_list[/datum/attribute/skill/combat/unarmed]) < SUCCUBUS_TRUE_FORM_CLAW_SKILL_FLOOR)
			new_form.attributes.set_skill_level(
				/datum/attribute/skill/combat/unarmed,
				SUCCUBUS_TRUE_FORM_CLAW_SKILL_FLOOR,
				TRUE,
			)
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
	grant_true_form_actions(new_form)
	playsound(new_form, 'sound/magic/demon_attack1.ogg', 80, TRUE)
	unleash_overwhelming_presence(new_form)
	return TRUE

/datum/antagonist/succubus/proc/can_leave_true_form(silent = FALSE)
	var/mob/living/form_body = owner?.current
	if(!true_form_active || !isliving(form_body))
		return FALSE
	var/obj/structure/succubus_rift/rift = get_active_rift()
	if(rift?.current_stage == SUCCUBUS_RIFT_STAGE_OPEN && !rift.collapsing)
		if(!silent)
			to_chat(form_body, span_userdanger("The open Rift has chained me to my unveiled shape. I cannot retreat into my mortal shell until its verdict is decided!"))
		return FALSE
	return TRUE

/datum/antagonist/succubus/proc/leave_true_form(force = FALSE)
	var/mob/living/form_body = owner?.current
	if(!force && !can_leave_true_form())
		return FALSE
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
	remove_true_form_actions(status_owner)
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
	var/obj/structure/succubus_rift/rift = get_active_rift()
	if(rift?.current_stage == SUCCUBUS_RIFT_STAGE_OPEN)
		rift.resolve_verdict(ascended = FALSE)

/// True-form body gibbed/deleted without an unshapeshift, so the revert path never runs —
/// clear the stale flag. Signal auto-unregisters on the qdel.
/datum/antagonist/succubus/proc/on_true_form_body_deleted(datum/source)
	SIGNAL_HANDLER
	true_form_active = FALSE
	var/obj/structure/succubus_rift/rift = get_active_rift()
	if(rift?.current_stage == SUCCUBUS_RIFT_STAGE_OPEN)
		rift.resolve_verdict(ascended = FALSE)

// --- True-form combat mobility and control --------------------------------------------------------

/datum/intent/simple/succubus_claw
	name = "claw"
	icon_state = "inclaw"
	blade_class = BCLASS_CUT
	attack_verb = list("claws", "slashes", "rakes")
	animname = "claw"
	hitsound = "smallslash"
	penfactor = PEN_LIGHT
	candodge = TRUE
	canparry = TRUE
	miss_text = "rakes the air!"
	miss_sound = "blunthwoosh"
	item_damage_type = "slash"

/obj/item/weapon/succubus_claw
	parent_type = /obj/item/weapon/werewolf_claw
	name = "predatory claw"
	desc = "A rose-black talon grown from the unveiled flesh of a succubus."
	force = DAMAGE_KNIFE
	wdefense = MEDIOCRE_PARRY
	wlength = WLENGTH_SHORT
	possible_item_intents = list(/datum/intent/simple/succubus_claw)

/obj/item/weapon/succubus_claw/left
	icon_state = "claw_l"

/obj/item/weapon/succubus_claw/right
	icon_state = "claw_r"

/datum/action/cooldown/spell/undirected/succubus_predatory_claws
	name = "Predatory Claws"
	desc = "Extend or retract a pair of keen natural claws. Both hands must be empty to extend them."
	button_icon_state = "claws"
	has_visual_effects = FALSE
	antimagic_flags = NONE
	spell_flags = SPELL_IGNORE_SPELLBLOCK
	associated_skill = null
	charge_required = FALSE
	cooldown_time = SUCCUBUS_TRUE_FORM_CLAW_COOLDOWN

	var/extended = FALSE
	var/datum/weakref/left_claw_ref
	var/datum/weakref/right_claw_ref

/datum/action/cooldown/spell/undirected/succubus_predatory_claws/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	if(!istype(owner, /mob/living/carbon/human/species/succubus_true))
		return . | SPELL_CANCEL_CAST
	if(extended)
		return
	if(owner.get_active_held_item() || owner.get_inactive_held_item())
		to_chat(owner, span_warning("I need both hands empty before I can extend my claws."))
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/undirected/succubus_predatory_claws/proc/get_predatory_claw(datum/weakref/claw_ref)
	if(!claw_ref)
		return null
	return claw_ref.resolve()

/datum/action/cooldown/spell/undirected/succubus_predatory_claws/proc/retract_predatory_claws(show_message = TRUE)
	var/obj/item/weapon/succubus_claw/left_claw = get_predatory_claw(left_claw_ref)
	var/obj/item/weapon/succubus_claw/right_claw = get_predatory_claw(right_claw_ref)
	if(left_claw)
		qdel(left_claw)
	if(right_claw)
		qdel(right_claw)
	left_claw_ref = null
	right_claw_ref = null
	extended = FALSE
	if(show_message && owner)
		owner.visible_message(
			span_warning("[owner]'s predatory talons recede into her fingertips."),
			span_love("My talons recede, leaving my hands free once more."),
		)

/datum/action/cooldown/spell/undirected/succubus_predatory_claws/Remove(mob/living/remove_from)
	retract_predatory_claws(show_message = FALSE)
	return ..()

/datum/action/cooldown/spell/undirected/succubus_predatory_claws/is_action_active(atom/movable/screen/movable/action_button/current_button)
	return extended

/datum/action/cooldown/spell/undirected/succubus_predatory_claws/cast(atom/cast_on)
	. = ..()
	if(extended)
		retract_predatory_claws()
		return

	var/mob/living/carbon/human/species/succubus_true/form_owner = owner
	if(!istype(form_owner))
		return
	var/obj/item/weapon/succubus_claw/left/left_claw = new(form_owner)
	var/obj/item/weapon/succubus_claw/right/right_claw = new(form_owner)
	if(!form_owner.put_in_hand(left_claw, 1, TRUE) || !form_owner.put_in_hand(right_claw, 2, TRUE))
		qdel(left_claw)
		qdel(right_claw)
		to_chat(form_owner, span_warning("My hands cannot hold their predatory shape."))
		return

	left_claw_ref = WEAKREF(left_claw)
	right_claw_ref = WEAKREF(right_claw)
	extended = TRUE
	form_owner.visible_message(
		span_boldwarning("[form_owner]'s fingers lengthen into rose-black talons!"),
		span_love("My fingers lengthen into keen predatory claws."),
	)

/datum/action/cooldown/spell/succubus_wingbeat
	name = "Wingbeat"
	desc = "Launch yourself toward clear ground with one mighty beat of your wings."
	button_icon_state = "jump"
	has_visual_effects = FALSE
	antimagic_flags = NONE
	spell_flags = SPELL_IGNORE_SPELLBLOCK
	associated_skill = null
	self_cast_possible = FALSE
	aim_assist = FALSE
	cast_range = SUCCUBUS_TRUE_FORM_WINGBEAT_RANGE
	charge_required = FALSE
	cooldown_time = SUCCUBUS_TRUE_FORM_WINGBEAT_COOLDOWN
	sound = 'sound/misc/tail_swing.ogg'

/datum/action/cooldown/spell/succubus_wingbeat/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	if(!istype(owner, /mob/living/carbon/human/species/succubus_true))
		return . | SPELL_CANCEL_CAST
	var/mob/living/living_owner = owner
	if(living_owner.throwing || living_owner.body_position != STANDING_UP)
		to_chat(owner, span_warning("I need my footing before I can launch myself."))
		return . | SPELL_CANCEL_CAST
	var/turf/target_turf = get_turf(cast_on)
	if(target_turf == get_turf(owner))
		to_chat(owner, span_warning("I need somewhere else to launch myself."))
		return . | SPELL_CANCEL_CAST
	if(!isopenturf(target_turf) || isgroundlessturf(target_turf) || target_turf.is_blocked_turf(exclude_mobs = TRUE))
		to_chat(owner, span_warning("I need clear, solid ground to land on."))
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/succubus_wingbeat/cast(atom/cast_on)
	. = ..()
	var/turf/target_turf = get_turf(cast_on)
	if(!target_turf)
		return
	owner.setDir(get_dir(owner, target_turf))
	owner.visible_message(
		span_boldwarning("[owner] snaps her wings open and hurtles through the air!"),
		span_love("One savage wingbeat hurls me forward."),
	)
	owner.safe_throw_at(
		target = target_turf,
		range = get_dist(owner, target_turf),
		speed = 1,
		thrower = owner,
		force = MOVE_FORCE_EXTREMELY_STRONG,
		gentle = TRUE,
	)

/datum/action/cooldown/spell/succubus_sovereign_gaze
	name = "Sovereign Gaze"
	desc = "Fix a creature in your unveiled gaze, briefly arresting their body and weakening their resolve."
	button_icon_state = "love"
	active_msg = "You gather your will behind your gaze..."
	deactive_msg = "You let the pressure behind your gaze subside."
	self_cast_possible = FALSE
	cast_range = SUCCUBUS_TRUE_FORM_GAZE_RANGE
	charge_time = SUCCUBUS_TRUE_FORM_GAZE_CHARGE_TIME
	charge_message = "Your eyes blaze with sovereign light."
	charge_sound = 'sound/magic/chargingold.ogg'
	cooldown_time = SUCCUBUS_TRUE_FORM_GAZE_COOLDOWN
	sound = 'sound/magic/PSY.ogg'
	spell_cost = 0
	spell_requirements = SPELL_REQUIRES_NO_ANTIMAGIC|SPELL_REQUIRES_NO_MOVE
	antimagic_flags = MAGIC_RESISTANCE_MIND
	associated_skill = null
	has_visual_effects = FALSE

/datum/action/cooldown/spell/succubus_sovereign_gaze/on_start_charge()
	. = ..()
	if(!owner)
		return
	owner.visible_message(
		span_boldwarning("[owner]'s eyes kindle with a terrible rose-gold light!"),
		span_love("My sovereign will gathers behind my eyes."),
	)

/datum/action/cooldown/spell/succubus_sovereign_gaze/is_valid_target(atom/cast_on)
	. = ..()
	if(!.)
		return FALSE
	if(!istype(owner, /mob/living/carbon/human/species/succubus_true))
		return FALSE
	var/mob/living/living_target = cast_on
	if(!istype(living_target) || !isturf(living_target.loc) || living_target.stat != CONSCIOUS)
		return FALSE
	var/mob/living/living_owner = owner
	if(living_owner.stat != CONSCIOUS || living_owner.is_blind() || living_target.is_blind())
		return FALSE
	var/datum/antagonist/succubus/succubus_antag = IS_SUCCUBUS(living_owner)
	if(!succubus_antag || succubus_antag.is_linked_retinue(living_target))
		return FALSE
	if(!can_see(living_owner, living_target, SUCCUBUS_TRUE_FORM_GAZE_RANGE))
		return FALSE
	if(!(living_target in view(SUCCUBUS_TRUE_FORM_GAZE_RANGE, living_owner)))
		return FALSE
	return check_target_facings(living_owner, living_target) == FACING_EACHOTHER

/datum/action/cooldown/spell/succubus_sovereign_gaze/cast(mob/living/cast_on)
	. = ..()
	if(QDELETED(owner) || QDELETED(cast_on))
		return

	if(HAS_TRAIT(cast_on, TRAIT_PROTECTION_EVIL_GOOD))
		var/datum/status_effect/buff/protection_evil_good/ward = cast_on.has_status_effect(/datum/status_effect/buff/protection_evil_good)
		if(ward)
			cast_on.visible_message(
				ward.get_ward_message_visible(owner),
				ward.get_ward_message(owner),
			)
		else
			cast_on.visible_message(
				span_warning("A sacred ward flares around [cast_on], severing [owner]'s gaze!"),
				span_userdanger("My ward flares and severs the demon's hold on my mind!"),
			)
		to_chat(owner, span_warning("A sacred ward turns my will aside."))
		return

	if(cast_on.can_block_magic(MAGIC_RESISTANCE_MIND))
		to_chat(owner, span_warning("[cast_on]'s mind repels my gaze."))
		to_chat(cast_on, span_notice("The pressure of [owner]'s gaze breaks against the wards around my mind."))
		return

	new /obj/effect/temp_visual/dir_setting/curse(get_turf(cast_on), get_dir(owner, cast_on))
	owner.visible_message(
		span_boldwarning("[owner]'s burning gaze fixes [cast_on] in place!"),
		span_love("My will closes around [cast_on] like a fist."),
	)
	to_chat(cast_on, span_userdanger("[owner]'s unveiled gaze catches mine, and my body locks beneath its impossible weight!"))
	cast_on.Immobilize(SUCCUBUS_TRUE_FORM_GAZE_IMMOBILIZE)
	cast_on.apply_status_effect(/datum/status_effect/debuff/mesmerised, SUCCUBUS_TRUE_FORM_GAZE_MESMERISED_DURATION)

/datum/action/cooldown/spell/aoe/repulse/dragon/succubus
	name = "Barbed Tail Sweep"
	desc = "Sweep your barbed tail around you, knocking nearby enemies away."
	aoe_radius = SUCCUBUS_TRUE_FORM_TAIL_SWEEP_RANGE
	cooldown_time = SUCCUBUS_TRUE_FORM_TAIL_SWEEP_COOLDOWN
	click_to_activate = FALSE
	charge_required = FALSE
	spell_cost = 0
	associated_skill = null
	min_throw = SUCCUBUS_TRUE_FORM_TAIL_SWEEP_THROW_RANGE
	max_throw = SUCCUBUS_TRUE_FORM_TAIL_SWEEP_THROW_RANGE
	repulse_force = MOVE_FORCE_STRONG
	antimagic_flags = NONE
	spell_flags = SPELL_IGNORE_SPELLBLOCK

/datum/action/cooldown/spell/aoe/repulse/dragon/succubus/is_valid_target(atom/cast_on)
	. = ..()
	if(!.)
		return FALSE
	return isliving(cast_on) && isturf(cast_on.loc)

/datum/action/cooldown/spell/aoe/repulse/dragon/succubus/cast_on_thing_in_aoe(mob/living/victim, atom/caster)
	if(victim.stat == DEAD || victim.anchored || victim.move_resist == INFINITY)
		return
	var/datum/antagonist/succubus/succubus_antag = IS_SUCCUBUS(owner)
	if(!succubus_antag || succubus_antag.is_linked_retinue(victim))
		return

	if(sparkle_path)
		new sparkle_path(get_turf(victim), get_dir(caster, victim))
	victim.Knockdown(SUCCUBUS_TRUE_FORM_TAIL_SWEEP_KNOCKDOWN)
	to_chat(victim, span_userdanger("[caster]'s barbed tail sweeps my legs out from under me!"))
	var/turf/throw_target = get_edge_target_turf(caster, get_dir(caster, get_step_away(victim, caster)))
	victim.safe_throw_at(
		target = throw_target,
		range = SUCCUBUS_TRUE_FORM_TAIL_SWEEP_THROW_RANGE,
		speed = 1,
		thrower = caster,
		force = repulse_force,
		gentle = TRUE,
	)

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
	if(succubus_antag.true_form_active && !succubus_antag.can_leave_true_form())
		return . | SPELL_CANCEL_CAST
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
