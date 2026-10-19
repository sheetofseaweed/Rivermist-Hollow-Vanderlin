/// Grows a working penis and testicles on the caster for a while; casting again lets them fade.
/datum/action/cooldown/spell/undirected/temporary_futanari
	name = "Phallic Blessing"
	desc = "Grow a working penis and testicles for fifteen minutes. Cast again to let them fade early."
	button_icon_state = "love"
	spell_type = NONE
	antimagic_flags = NONE
	spell_flags = SPELL_IGNORE_SPELLBLOCK
	charge_required = FALSE
	has_visual_effects = FALSE
	cooldown_time = 30 SECONDS
	/// How long the anatomy lasts, unless something ends it early.
	var/blessing_duration = 15 MINUTES

/datum/action/cooldown/spell/undirected/temporary_futanari/is_valid_target(atom/cast_on)
	return iscarbon(owner)

/datum/action/cooldown/spell/undirected/temporary_futanari/cast(atom/cast_on)
	. = ..()
	var/mob/living/carbon/caster = owner
	var/datum/status_effect/temporary_futanari/blessing = caster.has_status_effect(/datum/status_effect/temporary_futanari)
	if(blessing)
		blessing.request_dissipation()
		return
	if(get_real_organ(caster, ORGAN_SLOT_PENIS) && caster.getorganslot(ORGAN_SLOT_TESTICLES))
		to_chat(caster, span_warning("My body already has everything this blessing would grant."))
		reset_spell_cooldown()
		return
	caster.apply_status_effect(/datum/status_effect/temporary_futanari, blessing_duration)

/// Owns only the organs it added, and waits for any running sex action to end before removing them.
/datum/status_effect/temporary_futanari
	id = "temporary_futanari"
	duration = STATUS_EFFECT_PERMANENT
	tick_interval = 5 SECONDS
	alert_type = null
	var/expires_at = 0
	var/dissipating = FALSE
	var/list/datum/weakref/added_organs = list()

/datum/status_effect/temporary_futanari/on_creation(mob/living/new_owner, blessing_duration = 15 MINUTES)
	expires_at = world.time + blessing_duration
	return ..(new_owner)

/datum/status_effect/temporary_futanari/on_apply()
	. = ..()
	var/mob/living/carbon/body = owner
	if(!istype(body))
		return FALSE
	var/list/before = list(body.getorganslot(ORGAN_SLOT_PENIS), body.getorganslot(ORGAN_SLOT_TESTICLES))
	body.give_gender_potion_genitals_for_gender(MALE)
	for(var/obj/item/organ/genitals/organ in list(body.getorganslot(ORGAN_SLOT_PENIS), body.getorganslot(ORGAN_SLOT_TESTICLES)))
		if(!(organ in before))
			added_organs += WEAKREF(organ)
	if(!length(added_organs))
		return FALSE
	body.regenerate_icons()
	to_chat(owner, span_love("Warm magic gathers between my legs and takes a firm, working shape."))
	return TRUE

/datum/status_effect/temporary_futanari/tick()
	if(!dissipating && world.time < expires_at)
		return
	if(owner.sex_scene && length(owner.sex_scene.get_actions_involving(owner)))
		return
	qdel(src)

/datum/status_effect/temporary_futanari/on_remove()
	if(length(added_organs))
		for(var/datum/weakref/organ_ref as anything in added_organs)
			var/obj/item/organ/genitals/organ = organ_ref.resolve()
			if(organ?.owner == owner)
				owner.remove_gender_potion_genital_organ(organ)
		added_organs.Cut()
		owner.regenerate_icons()
		to_chat(owner, span_notice("The borrowed anatomy fades away."))
	return ..()

/// Ends the blessing as soon as the owner is out of any sex action.
/datum/status_effect/temporary_futanari/proc/request_dissipation()
	if(dissipating)
		return
	dissipating = TRUE
	to_chat(owner, span_notice("The blessing begins to fade; it will be gone once I am done."))
