/datum/enchantment/on_hit/rewind
	enchantment_name = "Temporal Rewind"
	examine_text = "It seems both old and new at the same time."
	essence_recipe = list(
		/datum/thaumaturgical_essence/cycle = 50,
		/datum/thaumaturgical_essence/magic = 30,
		/datum/thaumaturgical_essence/void = 20
	)
	cooldown_time = 10 SECONDS
	var/active_item = FALSE
	var/rewind_timer

/datum/enchantment/on_hit/rewind/register_triggers(atom/item)
	. = ..()
	// on_hit/on_simple_attack handled by parent; add the defensive signal manually
	registered_signals += COMSIG_ITEM_HIT_RESPONSE
	RegisterSignal(item, COMSIG_ITEM_HIT_RESPONSE, PROC_REF(on_hit_response))

/datum/enchantment/on_hit/rewind/Destroy(force, ...)
	if(rewind_timer)
		deltimer(rewind_timer)
		rewind_timer = null
	return ..()

/datum/enchantment/on_hit/rewind/apply_attack_effects(obj/item/source, mob/living/attacked, mob/living/attacker, actual_damage)
	var/turf/target_turf = get_turf(attacker)
	active_item = TRUE
	rewind_timer = addtimer(CALLBACK(src, PROC_REF(complete_rewind), WEAKREF(attacker), target_turf), 5 SECONDS, TIMER_STOPPABLE)

/datum/enchantment/on_hit/rewind/proc/on_hit_response(obj/item/I, mob/living/owner, mob/living/attacker)
	if(!COOLDOWN_FINISHED(src, hit_cooldown))
		return
	if(active_item)
		return
	var/turf/target_turf = get_turf(owner)
	active_item = TRUE
	COOLDOWN_START(src, hit_cooldown, cooldown_time)
	rewind_timer = addtimer(CALLBACK(src, PROC_REF(complete_rewind), WEAKREF(owner), target_turf), 5 SECONDS, TIMER_STOPPABLE)

/datum/enchantment/on_hit/rewind/proc/complete_rewind(datum/weakref/target_ref, turf/target_turf)
	rewind_timer = null
	var/mob/living/target = target_ref.resolve()
	if(target && target_turf)
		to_chat(target, span_notice("Temporal magic rewinds you back in time!"))
		do_teleport(target, target_turf, channel = TELEPORT_CHANNEL_QUANTUM)
	active_item = FALSE
