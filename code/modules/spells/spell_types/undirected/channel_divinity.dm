// Divine class features: Channel Divinity, Lay on Hands, Divine Smite and Channel Oath on the feature pools.

/// Heals one limb the way the healing miracle does, injuries included.
/proc/divine_heal_limb(obj/item/bodypart/limb, amount, wound_modifier = 0.25)
	limb.heal_damage(amount, amount)
	limb.heal_wounds(amount * wound_modifier)
	for(var/datum/injury/injury as anything in limb.injuries)
		if(injury.damage_type == WOUND_DIVINE)
			continue
		injury.heal_damage(amount)

// Channel Divinity

/datum/action/cooldown/spell/aoe/churn_undead/channel
	name = "Channel Divinity: Turn Undead"
	desc = "Channel your patron to churn every undead near you. One charge per short rest, two from Expert holy."
	cooldown_time = 10 SECONDS
	spell_cost = 0
	slot_level = null
	learnable = FALSE
	slot_label = "Turn Undead"
	feature_id = FEATURE_CHANNEL_DIVINITY

/datum/action/cooldown/spell/undirected/divine_strike/channel
	name = "Channel Divinity: War Priest"
	desc = "Channel your patron into your next blow, chaining the struck foe. One charge per short rest, two from Expert holy."
	cooldown_time = 10 SECONDS
	spell_cost = 0
	slot_level = null
	learnable = FALSE
	slot_label = "War Priest"
	feature_id = FEATURE_CHANNEL_DIVINITY

/datum/action/cooldown/spell/aoe/preserve_life
	name = "Channel Divinity: Preserve Life"
	desc = "Mend everyone around you for five hit points per rank of holy skill. One charge per short rest, two from Expert holy."
	button_icon_state = "lesserheal"
	sound = 'sound/magic/heal.ogg'

	spell_type = SPELL_MIRACLE
	antimagic_flags = MAGIC_RESISTANCE_HOLY
	associated_skill = /datum/attribute/skill/magic/holy

	invocation = "Hold fast, by my patron's grace!"
	invocation_type = INVOCATION_SHOUT

	click_to_activate = FALSE
	charge_required = FALSE
	cooldown_time = 30 SECONDS
	spell_cost = 0

	required_form = FORM_HOLY
	required_technique = TECHNIQUE_RESTORATION
	learnable = FALSE
	slot_label = "Preserve Life"
	aoe_radius = SPELL_RANGE_AURA
	feature_id = FEATURE_CHANNEL_DIVINITY

/datum/action/cooldown/spell/aoe/preserve_life/is_valid_target(atom/cast_on)
	if(!isliving(cast_on))
		return FALSE
	var/mob/living/target = cast_on
	return target.stat != DEAD && !(target.mob_biotypes & MOB_UNDEAD)

/datum/action/cooldown/spell/aoe/preserve_life/proc/get_heal_amount()
	var/datum/spell_slots/slots = get_spell_slots()
	return PRESERVE_LIFE_HEAL_PER_RANK * max(slots ? slots.get_rank() : 1, 1)

/datum/action/cooldown/spell/aoe/preserve_life/cast_on_thing_in_aoe(mob/living/victim, atom/caster)
	var/amount = get_heal_amount()
	SEND_SIGNAL(owner, COMSIG_LIVING_HEALED_OTHER, amount)
	victim.adjustToxLoss(-amount)
	victim.adjustOxyLoss(-amount)
	if(!iscarbon(victim))
		victim.adjustBruteLoss(-amount)
		victim.adjustFireLoss(-amount)
		return FALSE
	var/mob/living/carbon/patient = victim
	// The worst limb takes the whole mend, like a touch on that limb.
	var/obj/item/bodypart/worst
	for(var/obj/item/bodypart/limb as anything in patient.bodyparts)
		if(!worst || limb.get_damage() > worst.get_damage())
			worst = limb
	if(worst)
		divine_heal_limb(worst, amount)
		patient.update_damage_overlays()
	victim.visible_message(span_info("A gentle light settles over [victim]."), span_notice("A gentle light mends my wounds."))
	return FALSE

// Paladin features

/datum/action/cooldown/spell/healing/lay_on_hands
	name = "Lay on Hands"
	desc = "Touch someone to mend them from your oath's pool of ten hit points per rank of holy skill, up to twenty-five per touch. A poisoned target is cleansed for five points instead. A long rest refills the pool."
	cast_range = 1
	cooldown_time = 5 SECONDS
	spell_cost = 0
	slot_level = null
	minor_cost = 0
	learnable = FALSE
	slot_label = "Lay on Hands"
	feature_id = FEATURE_LAY_ON_HANDS
	feature_rest = REST_LONG
	var/pending_spend = 0
	/// TRUE when this touch cleanses toxins instead of healing.
	var/cleansing = FALSE

/datum/action/cooldown/spell/healing/lay_on_hands/get_feature_cost()
	return max(pending_spend, 1)

/// Toxins and poisons in the blood are what the touch can cleanse; the realm has no diseases.
/datum/action/cooldown/spell/healing/lay_on_hands/proc/needs_cleansing(mob/living/target)
	if(!target.reagents)
		return FALSE
	for(var/datum/reagent/reagent as anything in target.reagents.reagent_list)
		if(istype(reagent, /datum/reagent/toxin) || istype(reagent, /datum/reagent/poison))
			return TRUE
	return FALSE

/// A poisoned target is cleansed for five points; otherwise the touch spends up to the healing base.
/datum/action/cooldown/spell/healing/lay_on_hands/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return .
	var/datum/spell_slots/slots = register_feature()
	var/pool = slots ? slots.get_feature_charges(feature_id) : 0
	cleansing = FALSE
	if(isliving(cast_on) && pool >= LAY_ON_HANDS_CLEANSE_COST && needs_cleansing(cast_on))
		cleansing = TRUE
		pending_spend = LAY_ON_HANDS_CLEANSE_COST
		return .
	pending_spend = min(pool, initial(base_healing))
	if(pending_spend <= 0)
		return . | SPELL_CANCEL_CAST
	base_healing = pending_spend

/datum/action/cooldown/spell/healing/lay_on_hands/cast(mob/living/cast_on)
	if(!cleansing)
		return ..()
	cleansing = FALSE
	cast_on.reagents?.remove_all_type(/datum/reagent/toxin, 999)
	cast_on.reagents?.remove_all_type(/datum/reagent/poison, 999)
	owner.visible_message(span_notice("[owner] lays a hand on [cast_on] and draws the poison from [cast_on.p_their()] blood."), span_notice("I draw the poison from [cast_on]'s blood."))
	return TRUE

/datum/action/cooldown/spell/undirected/divine_smite
	name = "Divine Smite"
	desc = "Spend a spell slot to wreathe your next melee hit in radiance: fifteen holy fire per slot level, more against the undead."
	button_icon_state = "createlight"
	sound = 'sound/magic/timestop.ogg'

	spell_type = SPELL_MIRACLE
	antimagic_flags = MAGIC_RESISTANCE_HOLY
	associated_skill = /datum/attribute/skill/magic/holy
	invocation_type = INVOCATION_NONE

	charge_required = FALSE
	cooldown_time = 5 SECONDS
	spell_cost = 30

	required_form = FORM_HOLY
	required_technique = TECHNIQUE_DESTRUCTION
	slot_level = 1
	slot_only = TRUE
	learnable = FALSE
	slot_label = "Divine Smite"

/datum/action/cooldown/spell/undirected/divine_smite/can_cast_spell(feedback)
	. = ..()
	if(!.)
		return FALSE
	return isliving(owner)

/datum/action/cooldown/spell/undirected/divine_smite/cast(mob/living/cast_on)
	. = ..()
	var/level = get_effect_level() || 1
	cast_on.apply_status_effect(/datum/status_effect/divine_smite, cast_on.get_active_held_item(), level)

/datum/status_effect/divine_smite
	id = "divine_smite"
	status_type = STATUS_EFFECT_REPLACE
	duration = 15 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/buff/divine_smite
	on_remove_on_mob_delete = TRUE
	var/datum/weakref/buffed_item
	var/smite_level = 1

/atom/movable/screen/alert/status_effect/buff/divine_smite
	name = "Divine Smite"
	desc = "My next melee hit bursts with radiant fire."
	icon_state = "stressvg"

/datum/status_effect/divine_smite/on_creation(mob/living/new_owner, duration_override, obj/item/I, level)
	. = ..()
	smite_level = max(level, 1)
	if(istype(I) && !(I.item_flags & ABSTRACT))
		buffed_item = WEAKREF(I)
		if(!I.light_outer_range && I.light_system == STATIC_LIGHT)
			I.set_light(1)
		RegisterSignal(I, COMSIG_ITEM_AFTERATTACK, PROC_REF(item_afterattack))
	else
		RegisterSignal(owner, COMSIG_MOB_ATTACK_HAND, PROC_REF(hand_attack))

/datum/status_effect/divine_smite/on_remove()
	. = ..()
	UnregisterSignal(owner, COMSIG_MOB_ATTACK_HAND)
	if(buffed_item)
		var/obj/item/I = buffed_item.resolve()
		if(istype(I))
			I.set_light(0)
			UnregisterSignal(I, COMSIG_ITEM_AFTERATTACK)

/datum/status_effect/divine_smite/proc/item_afterattack(obj/item/source, atom/target, mob/user, proximity_flag, list/modifiers)
	if(!proximity_flag || !isliving(target))
		return
	smite(target, user)

/datum/status_effect/divine_smite/proc/hand_attack(datum/source, mob/living/carbon/human/M, mob/living/carbon/human/H, datum/martial_art/attacker_style)
	if(!istype(M) || !istype(H))
		return
	if(!istype(M.used_intent, INTENT_HARM))
		return
	smite(H, M)

/datum/status_effect/divine_smite/proc/smite(mob/living/target, mob/user)
	var/damage = DIVINE_SMITE_DAMAGE_PER_LEVEL * smite_level
	if(target.mob_biotypes & MOB_UNDEAD)
		damage += DIVINE_SMITE_DAMAGE_PER_LEVEL
		target.adjust_divine_fire_stacks(smite_level)
		target.IgniteMob()
	target.adjustFireLoss(damage)
	target.visible_message(span_warning("Radiant fire bursts from [user]'s strike into [target]!"), vision_distance = COMBAT_MESSAGE_RANGE)
	qdel(src)

// Channel Oath

/datum/action/cooldown/spell/undirected/protection_evil_good/channel_oath
	name = "Channel Oath: Sacred Weapon"
	desc = "Call your oath to ward you from the otherworldly. One charge per short rest."
	cooldown_time = 30 SECONDS
	spell_cost = 0
	slot_level = null
	learnable = FALSE
	slot_label = "Sacred Weapon"
	feature_id = FEATURE_CHANNEL_OATH

/datum/action/cooldown/spell/pointed/silence/channel_oath
	name = "Channel Oath: Champion's Silence"
	desc = "Your oath smothers every voice near the target. One charge per short rest."
	cooldown_time = 10 SECONDS
	learnable = FALSE
	slot_label = "Champion's Silence"
	feature_id = FEATURE_CHANNEL_OATH

/datum/action/cooldown/spell/aoe/hellfire_burst
	name = "Channel Oath: Hellfire Burst"
	desc = "Infernal flames erupt from you and ignite everyone nearby. One charge per short rest."
	button_icon_state = "hellfire"
	sound = 'sound/magic/fireball.ogg'

	spell_type = SPELL_MIRACLE
	antimagic_flags = MAGIC_RESISTANCE_UNHOLY
	associated_skill = /datum/attribute/skill/magic/holy

	invocation = "Burn with me!"
	invocation_type = INVOCATION_SHOUT

	click_to_activate = FALSE
	charge_required = FALSE
	cooldown_time = 30 SECONDS
	spell_cost = 0

	required_form = FORM_HOLY
	required_technique = TECHNIQUE_DESTRUCTION
	heretical_spell = TRUE
	learnable = FALSE
	slot_label = "Hellfire Burst"
	aoe_radius = SPELL_RANGE_AURA
	feature_id = FEATURE_CHANNEL_OATH

/datum/action/cooldown/spell/aoe/hellfire_burst/is_valid_target(atom/cast_on)
	if(!isliving(cast_on))
		return FALSE
	var/mob/living/target = cast_on
	return target.stat != DEAD

/datum/action/cooldown/spell/aoe/hellfire_burst/cast_on_thing_in_aoe(mob/living/victim, atom/caster)
	victim.adjust_fire_stacks(3)
	victim.IgniteMob()
	victim.AddElement(/datum/element/hellfire_overlay)
	victim.visible_message(span_danger("Hellfire washes over [victim]!"), span_userdanger("Hellfire washes over me!"))
	return FALSE
