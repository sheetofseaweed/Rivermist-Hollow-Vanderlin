// Infernal Snare: a bounded, owner-tracked Tier 3 control trap.

/datum/antagonist/succubus
	var/list/obj/structure/succubus_infernal_snare/infernal_snares = list()

/obj/item/rope/chain/infernal
	desc = "A chain animated by smouldering infernal force, eager to wind around a captive's legs."
	color = "#8F35A8"
	breakouttime = 10 SECONDS

/obj/structure/succubus_infernal_snare
	name = "infernal snare"
	desc = "A faint knot of infernal sigils, waiting to lash out at the unwary."
	icon = 'icons/roguetown/misc/traps.dmi'
	icon_state = "trap_plate"
	color = "#8F35A8"
	alpha = 100
	density = FALSE
	anchored = TRUE
	max_integrity = 40
	/// The mind whose succubus datum owns this snare.
	var/datum/weakref/owner_mind_ref
	/// Set before applying effects so simultaneous crossings cannot fire twice.
	var/spent = FALSE

/obj/structure/succubus_infernal_snare/Initialize(mapload)
	. = ..()
	QDEL_IN(src, SUCCUBUS_INFERNAL_SNARE_DURATION)

/obj/structure/succubus_infernal_snare/Destroy()
	var/datum/mind/owner_mind = owner_mind_ref?.resolve()
	var/datum/antagonist/succubus/owner_datum = owner_mind?.has_antag_datum(/datum/antagonist/succubus)
	if(owner_datum)
		owner_datum.infernal_snares -= src
	owner_mind_ref = null
	return ..()

/obj/structure/succubus_infernal_snare/proc/bind_to(datum/antagonist/succubus/owner_datum)
	if(!owner_datum?.owner)
		return FALSE
	owner_mind_ref = WEAKREF(owner_datum.owner)
	owner_datum.infernal_snares += src
	return TRUE

/obj/structure/succubus_infernal_snare/proc/is_friendly(mob/living/possible_friend)
	var/datum/mind/owner_mind = owner_mind_ref?.resolve()
	if(!owner_mind || !possible_friend)
		return FALSE
	var/mob/living/simple_animal/hostile/retaliate/wolf/companion/lustbound/hound = possible_friend
	if(istype(hound) && hound.mistress_mind_ref?.resolve() == owner_mind)
		return TRUE
	if(!possible_friend.mind)
		return FALSE
	if(possible_friend.mind == owner_mind)
		return TRUE

	var/datum/antagonist/succubus_thrall/thrall_datum = possible_friend.mind.has_antag_datum(/datum/antagonist/succubus_thrall)
	if(thrall_datum?.mistress_mind == owner_mind)
		return TRUE

	var/datum/antagonist/succubus_imp/imp_datum = possible_friend.mind.has_antag_datum(/datum/antagonist/succubus_imp)
	return imp_datum?.mistress_mind == owner_mind

/obj/structure/succubus_infernal_snare/Crossed(atom/movable/arrived, oldloc)
	. = ..()
	if(spent || !isliving(arrived))
		return

	var/mob/living/victim = arrived
	if(victim.throwing || (victim.movement_type & MOVETYPE_NOT_TOUCHING_GROUND))
		return
	if(is_friendly(victim))
		return

	spent = TRUE
	victim.Immobilize(SUCCUBUS_INFERNAL_SNARE_IMMOBILIZE)
	victim.Knockdown(SUCCUBUS_INFERNAL_SNARE_KNOCKDOWN)
	if(iscarbon(victim))
		var/mob/living/carbon/carbon_victim = victim
		var/obj/item/rope/chain/infernal/bindings = new(get_turf(carbon_victim))
		if(!bindings.apply_cuffs(carbon_victim, leg = TRUE))
			qdel(bindings)
	visible_message(
		span_danger("Infernal tendrils erupt from [src] and coil around [victim]!"),
	)
	playsound(src, 'sound/magic/demon_attack1.ogg', 60, TRUE)
	qdel(src)

/datum/action/cooldown/spell/succubus_infernal_snare
	name = "Lay Infernal Snare"
	desc = "Bind a nearby patch of ground with a faint, single-use infernal snare."
	has_visual_effects = FALSE
	antimagic_flags = NONE
	spell_flags = SPELL_IGNORE_SPELLBLOCK
	associated_skill = null
	self_cast_possible = FALSE
	cast_range = 3
	aim_assist = FALSE
	charge_required = FALSE
	cooldown_time = SUCCUBUS_INFERNAL_SNARE_COOLDOWN

/datum/action/cooldown/spell/succubus_infernal_snare/is_valid_target(atom/cast_on)
	. = ..()
	if(!.)
		return FALSE
	return !isnull(get_turf(cast_on))

/datum/action/cooldown/spell/succubus_infernal_snare/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return

	var/datum/antagonist/succubus/succubus_antag = IS_SUCCUBUS(owner)
	if(!succubus_antag || succubus_antag.get_succubus_contract_tier() < SUCCUBUS_RETINUE_UNLOCK_TIER)
		to_chat(owner, span_warning("My patron has not yet taught me this snare."))
		return . | SPELL_CANCEL_CAST
	if(succubus_antag.essence < SUCCUBUS_COST_INFERNAL_SNARE)
		to_chat(owner, span_warning("I lack the essence to bind an infernal snare."))
		return . | SPELL_CANCEL_CAST
	if(length(succubus_antag.infernal_snares) >= SUCCUBUS_INFERNAL_SNARE_CAP)
		to_chat(owner, span_warning("I cannot sustain another infernal snare."))
		return . | SPELL_CANCEL_CAST

	var/turf/target_turf = get_turf(cast_on)
	if(!isopenturf(target_turf) || isgroundlessturf(target_turf) || target_turf.is_blocked_turf(exclude_mobs = TRUE))
		to_chat(owner, span_warning("The snare needs clear, solid ground."))
		return . | SPELL_CANCEL_CAST
	if(locate(/obj/structure/succubus_infernal_snare) in target_turf)
		to_chat(owner, span_warning("An infernal snare already binds that ground."))
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/succubus_infernal_snare/cast(atom/cast_on)
	. = ..()
	var/datum/antagonist/succubus/succubus_antag = IS_SUCCUBUS(owner)
	var/turf/open/target_turf = get_turf(cast_on)
	if(!succubus_antag || !istype(target_turf))
		return

	var/obj/structure/succubus_infernal_snare/snare = new(target_turf)
	if(!snare.bind_to(succubus_antag))
		qdel(snare)
		return

	succubus_antag.adjust_essence(-SUCCUBUS_COST_INFERNAL_SNARE)
	to_chat(owner, span_love("I knot a patient hunger into the ground."))
