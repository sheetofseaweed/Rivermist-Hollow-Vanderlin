// Channel Oath options for Vengeance, Conquest and Immortal on the Channel Oath pool.

/// -2 on dodge and parry rolls against the paladin who swore enmity on this mob.
/mob/living/proc/get_enmity_penalty(mob/living/attacker)
	var/datum/status_effect/debuff/vow_of_enmity/vow = has_status_effect(/datum/status_effect/debuff/vow_of_enmity)
	if(!vow || !attacker || vow.hunter_ref?.resolve() != attacker)
		return 0
	return VOW_OF_ENMITY_PENALTY

// Vengeance

/datum/action/cooldown/spell/vow_of_enmity
	name = "Channel Oath: Vow of Enmity"
	desc = "Swear enmity on one foe within five tiles. For a minute their dodges and parries against you suffer a penalty. One charge per short rest, one foe at a time."
	button_icon_state = "createlight"
	sound = 'sound/magic/timestop.ogg'

	spell_type = SPELL_MIRACLE
	antimagic_flags = MAGIC_RESISTANCE_HOLY
	associated_skill = /datum/attribute/skill/magic/holy
	invocation = "I swear your end!"
	invocation_type = INVOCATION_SHOUT

	click_to_activate = TRUE
	self_cast_possible = FALSE
	cast_range = 5
	charge_required = FALSE
	cooldown_time = 10 SECONDS
	spell_cost = 0

	required_form = FORM_HOLY
	required_technique = TECHNIQUE_ALTERATION
	learnable = FALSE
	slot_label = "Vow of Enmity"
	feature_id = FEATURE_CHANNEL_OATH
	/// The foe currently under the vow; a new vow releases them.
	var/datum/weakref/marked_ref

/datum/action/cooldown/spell/vow_of_enmity/Destroy()
	marked_ref = null
	return ..()

/datum/action/cooldown/spell/vow_of_enmity/is_valid_target(atom/cast_on)
	. = ..()
	if(!.)
		return FALSE
	if(!isliving(cast_on))
		return FALSE
	var/mob/living/target = cast_on
	return target.stat != DEAD

/datum/action/cooldown/spell/vow_of_enmity/cast(mob/living/cast_on)
	. = ..()
	var/mob/living/old_mark = marked_ref?.resolve()
	if(old_mark && old_mark != cast_on)
		old_mark.remove_status_effect(/datum/status_effect/debuff/vow_of_enmity)
	cast_on.apply_status_effect(/datum/status_effect/debuff/vow_of_enmity, null, owner)
	marked_ref = WEAKREF(cast_on)
	owner.visible_message(span_warning("[owner] levels a burning glare at [cast_on] and swears enmity!"), span_notice("I swear enmity upon [cast_on]. Their guard will falter before me."))
	to_chat(cast_on, span_userdanger("[owner] has sworn enmity upon you!"))

/datum/status_effect/debuff/vow_of_enmity
	id = "vow_of_enmity"
	duration = 60 SECONDS
	status_type = STATUS_EFFECT_REPLACE
	alert_type = /atom/movable/screen/alert/status_effect/debuff/vow_of_enmity
	var/datum/weakref/hunter_ref

/atom/movable/screen/alert/status_effect/debuff/vow_of_enmity
	name = "Sworn Enmity"
	desc = "A paladin has sworn my end. My guard falters against them."
	icon_state = "restrained"

/datum/status_effect/debuff/vow_of_enmity/on_creation(mob/living/new_owner, duration_override, mob/living/hunter)
	hunter_ref = WEAKREF(hunter)
	return ..()

/datum/status_effect/debuff/vow_of_enmity/on_apply()
	. = ..()
	owner.add_filter("vow_of_enmity", 2, outline_filter(1, "#c01818"))
	return TRUE

/datum/status_effect/debuff/vow_of_enmity/on_remove()
	. = ..()
	owner.remove_filter("vow_of_enmity")
	hunter_ref = null

// Conquest

/datum/action/cooldown/spell/undirected/conquering_presence
	name = "Channel Oath: Conquering Presence"
	desc = "Every foe within three tiles rolls their constitution or is frightened for ten seconds and thrown off balance. One charge per short rest."
	button_icon_state = "createlight"
	sound = 'sound/magic/timestop.ogg'

	spell_type = SPELL_MIRACLE
	antimagic_flags = MAGIC_RESISTANCE_HOLY
	associated_skill = /datum/attribute/skill/magic/holy
	invocation = "KNEEL!"
	invocation_type = INVOCATION_SHOUT

	charge_required = FALSE
	cooldown_time = 10 SECONDS
	spell_cost = 0

	required_form = FORM_HOLY
	required_technique = TECHNIQUE_ILLUSION
	learnable = FALSE
	slot_label = "Conquering Presence"
	feature_id = FEATURE_CHANNEL_OATH

/datum/action/cooldown/spell/undirected/conquering_presence/can_cast_spell(feedback)
	. = ..()
	if(!.)
		return FALSE
	return isliving(owner)

/// Frightens one foe; returns TRUE when the roll failed and the fear took hold.
/datum/action/cooldown/spell/undirected/conquering_presence/proc/frighten(mob/living/target)
	if(target.diceroll(target.get_stat(STAT_CONSTITUTION), context = DICE_CONTEXT_MENTAL) > DICE_FAILURE)
		target.visible_message(span_notice("[target] stands firm before [owner]'s presence."), span_notice("I hold my ground against [owner]'s dread presence."))
		return FALSE
	target.apply_status_effect(/datum/status_effect/incapacitating/off_balanced, CONQUERING_PRESENCE_DURATION)
	target.apply_status_effect(/datum/status_effect/debuff/frightened, CONQUERING_PRESENCE_DURATION, owner)
	target.visible_message(span_warning("[target] quails before [owner]!"), span_userdanger("Dread crushes my will before [owner]!"))
	return TRUE

/// Neutral is every mob's default faction, so only a real shared faction or an ally bond spares a target.
/mob/living/proc/is_sworn_ally(mob/living/other)
	if(length((faction - FACTION_NEUTRAL) & other.faction))
		return TRUE
	return LAZYLEN(allies) && LAZYLEN(other.allies) && length(allies & other.allies)

/datum/action/cooldown/spell/undirected/conquering_presence/cast(mob/living/cast_on)
	. = ..()
	var/frightened = 0
	for(var/mob/living/target in view(CONQUERING_PRESENCE_RANGE, cast_on))
		if(target == cast_on || target.stat == DEAD)
			continue
		if(cast_on.is_sworn_ally(target))
			continue
		if(frighten(target))
			frightened++
	if(!frightened)
		to_chat(cast_on, span_notice("No foe quails before me."))

/// Dread of the paladin; the playtest dropped the forced flight, so nothing moves the mob.
/datum/status_effect/debuff/frightened
	id = "frightened"
	duration = 10 SECONDS
	status_type = STATUS_EFFECT_REPLACE
	alert_type = /atom/movable/screen/alert/status_effect/debuff/frightened
	var/datum/weakref/source_ref

/atom/movable/screen/alert/status_effect/debuff/frightened
	name = "Frightened"
	desc = "Dread of my foe shakes my guard!"
	icon_state = "stressvg"

/datum/status_effect/debuff/frightened/on_creation(mob/living/new_owner, duration_override, mob/living/source)
	source_ref = WEAKREF(source)
	return ..()

/datum/status_effect/debuff/frightened/on_apply()
	. = ..()
	return TRUE

/datum/status_effect/debuff/frightened/on_remove()
	. = ..()
	source_ref = null

// Immortal

/datum/action/cooldown/spell/undirected/undying_sentinel
	name = "Channel Oath: Undying Sentinel"
	desc = "Refuse to fall: mend your worst wounds for ten per rank of holy skill and staunch every bleed, even while down. One charge per short rest."
	button_icon_state = "lesserheal"
	sound = 'sound/magic/heal.ogg'

	spell_type = SPELL_MIRACLE
	antimagic_flags = MAGIC_RESISTANCE_HOLY
	associated_skill = /datum/attribute/skill/magic/holy
	invocation_type = INVOCATION_NONE

	charge_required = FALSE
	cooldown_time = 10 SECONDS
	spell_cost = 0

	required_form = FORM_HOLY
	required_technique = TECHNIQUE_RESTORATION
	learnable = FALSE
	slot_label = "Undying Sentinel"
	feature_id = FEATURE_CHANNEL_OATH

/datum/action/cooldown/spell/undirected/undying_sentinel/can_cast_spell(feedback)
	. = ..()
	if(!.)
		return FALSE
	return isliving(owner)

/datum/action/cooldown/spell/undirected/undying_sentinel/proc/get_heal_amount()
	return max(UNDYING_SENTINEL_HEAL_PER_RANK, UNDYING_SENTINEL_HEAL_PER_RANK * get_feature_rank())

/datum/action/cooldown/spell/undirected/undying_sentinel/cast(mob/living/cast_on)
	. = ..()
	var/amount = get_heal_amount()
	cast_on.adjustToxLoss(-amount)
	cast_on.adjustOxyLoss(-amount)
	if(!iscarbon(cast_on))
		cast_on.adjustBruteLoss(-amount)
		cast_on.adjustFireLoss(-amount)
		return
	var/mob/living/carbon/sentinel = cast_on
	// The worst limb takes the full mend, the next worst half; every bleed stops.
	var/list/limbs = sentinel.bodyparts.Copy()
	sortTim(limbs, GLOBAL_PROC_REF(cmp_bodypart_damage_dsc))
	if(length(limbs) >= 1)
		divine_heal_limb(limbs[1], amount)
	if(length(limbs) >= 2)
		divine_heal_limb(limbs[2], amount / 2)
	for(var/obj/item/bodypart/limb as anything in sentinel.bodyparts)
		for(var/datum/wound/wound as anything in limb.wounds)
			wound.bleed_rate = 0
		for(var/datum/injury/injury as anything in limb.injuries)
			injury.clamp_injury()
	sentinel.update_damage_overlays()
	sentinel.visible_message(span_notice("[sentinel]'s wounds knit as [sentinel.p_they()] refuse[sentinel.p_s()] to fall."), span_notice("My oath holds me up. My wounds close and my blood stays in me."))

/proc/cmp_bodypart_damage_dsc(obj/item/bodypart/a, obj/item/bodypart/b)
	return b.get_damage() - a.get_damage()
