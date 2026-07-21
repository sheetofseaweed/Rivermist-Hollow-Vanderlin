// Enthrall: harem team, thrall antag, consent flow, release.
// Consent flow mirrors the werewolf conversion prompt (pending flag, async tgui_alert, re-validate).

// --- Harem team -----------------------------------------------------------------------------------

/datum/team/succubus_harem
	name = "Harem"
	member_name = "thrall"
	var/datum/mind/mistress

/datum/antagonist/succubus
	var/datum/team/succubus_harem/harem

/datum/antagonist/succubus/get_team()
	return harem

/datum/antagonist/succubus/proc/ensure_harem()
	if(!harem)
		harem = new
		harem.mistress = owner
		harem.add_member(owner)
	return harem

/datum/antagonist/succubus/proc/count_thralls()
	var/count = 0
	for(var/datum/mind/member as anything in harem?.members)
		if(member != owner && member.has_antag_datum(/datum/antagonist/succubus_thrall))
			count++
	return count

// --- Thrall antag datum ---------------------------------------------------------------------------

/datum/antagonist/succubus_thrall
	name = "Enthralled"
	roundend_category = "Other Villains"
	antagpanel_category = "Villain"
	show_in_antagpanel = TRUE
	// PLACEHOLDER HUD: vampire icons until succubus art exists
	antag_hud_type = ANTAG_HUD_VAMPIRE
	antag_hud_name = "vamp"
	var/datum/mind/mistress_mind
	var/datum/team/succubus_harem/harem

/datum/antagonist/succubus_thrall/get_team()
	return harem

/datum/antagonist/succubus_thrall/on_gain()
	var/datum/objective/serve = new
	serve.owner = owner
	serve.explanation_text = "Serve and protect my mistress. Her nature must stay hidden."
	objectives += serve
	return ..()

/datum/antagonist/succubus_thrall/greet()
	to_chat(owner.current, span_userdanger("My will is no longer my own. I serve my mistress — her desires are mine, her secrets are sacred."))
	if(mistress_mind?.current)
		to_chat(owner.current, span_love("My mistress is [mistress_mind.current.real_name]. I must aid her, cover for her, and bring her what she hungers for."))
	owner.announce_objectives()
	return ..()

/datum/antagonist/succubus_thrall/Destroy()
	harem?.remove_member(owner)
	harem = null
	mistress_mind = null
	return ..()

// --- Eligibility + consent flow -------------------------------------------------------------------

/mob/living/carbon/human
	var/tmp/succubus_enthrall_prompt_pending = FALSE

/datum/antagonist/succubus/proc/can_enthrall(mob/living/carbon/human/target)
	if(!istype(target) || !target.mind || target == owner?.current)
		return FALSE
	if(!target.has_erp_pref(/datum/erp_preference/boolean/enthrallable))
		return FALSE // warded will
	if(IS_SUCCUBUS(target) || target.mind.has_antag_datum(/datum/antagonist/succubus_thrall))
		return FALSE
	if((partner_harvests[target.mind] || 0) < SUCCUBUS_ENTHRALL_MIN_HARVESTS)
		return FALSE // not yet steeped enough
	if(essence < SUCCUBUS_COST_ENTHRALL)
		return FALSE
	if(count_thralls() >= SUCCUBUS_THRALL_CAP)
		return FALSE
	return TRUE

/datum/antagonist/succubus/proc/offer_enthrallment(mob/living/carbon/human/target)
	if(target.succubus_enthrall_prompt_pending)
		if(owner?.current)
			to_chat(owner.current, span_warning("Their will is already being tested."))
		return FALSE
	if(!target.client)
		if(owner?.current)
			to_chat(owner.current, span_warning("Their mind is vacant; there is nothing to bind."))
		return FALSE
	target.succubus_enthrall_prompt_pending = TRUE
	INVOKE_ASYNC(src, PROC_REF(prompt_enthrallment), WEAKREF(target))
	if(owner?.current)
		to_chat(owner.current, span_love("I press my will against [target.real_name]'s..."))
	return TRUE

/datum/antagonist/succubus/proc/prompt_enthrallment(datum/weakref/target_ref)
	var/mob/living/carbon/human/target = target_ref?.resolve()
	if(!istype(target))
		return FALSE
	var/mistress_name = owner?.current?.real_name || "the demoness"
	var/choice = tgui_alert(target, "[mistress_name]'s essence coils through my veins, sweet and heavy, coaxing my will to kneel. Do I surrender it?", "Surrender", list("Surrender", "Resist"), WW_CONVERSION_PROMPT_TIMEOUT)
	// Clear the flag only while target is still valid (writing it on a hard-deleted target runtimes)
	if(!QDELETED(target))
		target.succubus_enthrall_prompt_pending = FALSE

	if(QDELETED(target) || QDELETED(src))
		return FALSE
	if(choice != "Surrender")
		to_chat(target, span_notice("I hold fast against the sweet pressure."))
		if(owner?.current)
			to_chat(owner.current, span_warning("[target.real_name] resists my binding. Stubborn thing."))
		return FALSE
	// Re-validate: the prompt window is long
	if(!can_enthrall(target))
		if(owner?.current)
			to_chat(owner.current, span_warning("The moment has passed; the binding slips away unfinished."))
		return FALSE
	return complete_enthrallment(target)

/datum/antagonist/succubus/proc/complete_enthrallment(mob/living/carbon/human/target)
	ensure_harem()
	var/datum/antagonist/succubus_thrall/thrall_datum = new
	thrall_datum.mistress_mind = owner
	thrall_datum.harem = harem
	harem.add_member(target.mind)
	target.mind.add_antag_datum(thrall_datum)
	adjust_essence(-SUCCUBUS_COST_ENTHRALL)
	if(owner?.current)
		to_chat(owner.current, span_love("[target.real_name]'s will folds into mine. My harem grows."))
	return TRUE

/// Release a thrall. keep_memories = TRUE is the exorcism path: the freed thrall
/// remembers everything — a walking deduction bomb.
/datum/antagonist/succubus/proc/unenthrall(datum/mind/thrall_mind, keep_memories = TRUE)
	var/datum/antagonist/succubus_thrall/thrall_datum = thrall_mind?.has_antag_datum(/datum/antagonist/succubus_thrall)
	if(!thrall_datum)
		return FALSE
	var/mob/living/freed = thrall_mind.current
	thrall_mind.remove_antag_datum(/datum/antagonist/succubus_thrall)
	if(freed)
		if(keep_memories)
			to_chat(freed, span_boldwarning("The fog lifts — and I remember EVERYTHING. Her faces. Her hungers. What she made me do."))
		else
			to_chat(freed, span_warning("The fog lifts, taking its secrets with it. What... was I doing?"))
	return TRUE

// --- Enthrall spell -------------------------------------------------------------------------------

/datum/action/cooldown/spell/succubus_enthrall
	name = "Enthrall"
	desc = "Bind a lover's will to your own. They must be steeped in your essence — and they must, in the end, choose to kneel."
	has_visual_effects = FALSE
	antimagic_flags = NONE
	spell_flags = SPELL_IGNORE_SPELLBLOCK
	associated_skill = null
	self_cast_possible = FALSE
	cast_range = 1
	charge_required = FALSE
	cooldown_time = 30 SECONDS

/datum/action/cooldown/spell/succubus_enthrall/is_valid_target(atom/cast_on)
	. = ..()
	if(!.)
		return FALSE
	return ishuman(cast_on)

/datum/action/cooldown/spell/succubus_enthrall/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	var/mob/living/carbon/human/target = cast_on
	if(!istype(target))
		return
	var/datum/antagonist/succubus/succubus_antag = IS_SUCCUBUS(owner)
	if(!succubus_antag)
		return . | SPELL_CANCEL_CAST
	if(succubus_antag.can_enthrall(target))
		return
	// Succubus-only failure whispers; the target hears nothing
	if(!target.has_erp_pref(/datum/erp_preference/boolean/enthrallable))
		to_chat(owner, span_notice("Their will is anchored beyond my reach."))
	else if((succubus_antag.partner_harvests[target.mind] || 0) < SUCCUBUS_ENTHRALL_MIN_HARVESTS)
		to_chat(owner, span_notice("They are not yet steeped enough in me."))
	else if(succubus_antag.count_thralls() >= SUCCUBUS_THRALL_CAP)
		to_chat(owner, span_warning("I cannot hold another will; my harem is full."))
	else if(succubus_antag.essence < SUCCUBUS_COST_ENTHRALL)
		to_chat(owner, span_warning("I lack the essence to forge such a bond."))
	else
		to_chat(owner, span_warning("Their will cannot be bound."))
	return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/succubus_enthrall/cast(mob/living/carbon/human/cast_on)
	. = ..()
	var/datum/antagonist/succubus/succubus_antag = IS_SUCCUBUS(owner)
	if(!succubus_antag || !istype(cast_on))
		return
	// Essence is charged only on an accepted surrender (complete_enthrallment), never a refusal
	succubus_antag.offer_enthrallment(cast_on)

// --- Admin ----------------------------------------------------------------------------------------

/datum/antagonist/succubus/get_admin_commands()
	. = ..()
	.["Release Thrall"] = CALLBACK(src, PROC_REF(admin_release_thrall))

/datum/antagonist/succubus/proc/admin_release_thrall(mob/admin)
	var/list/thrall_minds = list()
	for(var/datum/mind/member as anything in harem?.members)
		if(member != owner && member.has_antag_datum(/datum/antagonist/succubus_thrall))
			// Disambiguate same-named thralls so none is unreachable in the picker
			var/label = member.name || "[member]"
			while(thrall_minds[label])
				label += "*"
			thrall_minds[label] = member
	if(!length(thrall_minds))
		to_chat(admin, span_notice("No thralls to release."))
		return
	var/choice = input(admin, "Release which thrall? (Memories are kept — the exorcism path.)", "Release Thrall") as null|anything in thrall_minds
	if(!choice)
		return
	unenthrall(thrall_minds[choice], keep_memories = TRUE)
	message_admins("[key_name_admin(admin)] released a thrall of [key_name_admin(owner)].")
