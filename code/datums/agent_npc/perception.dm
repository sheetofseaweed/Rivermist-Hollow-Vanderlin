/**
 * One observation, and the handle table that goes with it.
 *
 * The handle table is the authorisation boundary. The model is only ever shown
 * opaque handles, and an action naming a handle resolves only against the
 * observation that was actually sent. A structurally valid handle string is not
 * an authorised target until it resolves here.
 */
/datum/agent_observation
	var/revision = 0
	var/built_at = 0
	/// handle -> /datum/weakref. Weak, so an observation never pins an atom.
	var/list/handles

/datum/agent_observation/New()
	. = ..()
	handles = list()
	built_at = world.time

/datum/agent_observation/Destroy(force, ...)
	handles = null
	return ..()

/// Resolve a handle offered by this observation. Null means never offered.
/datum/agent_observation/proc/resolve(handle)
	RETURN_TYPE(/atom)
	if(!istext(handle))
		return null
	var/datum/weakref/reference = handles[handle]
	if(!reference)
		return null
	var/atom/resolved = reference.resolve()
	return QDELETED(resolved) ? null : resolved

/datum/agent_observation/proc/offer(atom/thing)
	var/handle = "h[length(handles) + 1]"
	handles[handle] = WEAKREF(thing)
	return handle

/// Coarse state only. Exact health is server truth, not character knowledge.
/proc/agent_describe_condition(mob/living/target)
	if(target.stat >= DEAD)
		return "dead"
	if(target.stat >= UNCONSCIOUS)
		return "unconscious"
	var/fraction = target.maxHealth > 0 ? (target.health / target.maxHealth) : 1
	switch(fraction)
		if(0.85 to INFINITY)
			return "unhurt"
		if(0.5 to 0.85)
			return "hurt"
		if(0.2 to 0.5)
			return "badly hurt"
	return "near death"

/**
 * Build an observer-relative observation.
 *
 * Deliberately does not call examine(). That proc is not a serialiser: the base
 * emits a visible sniffing message and dispatches examination signals, and human
 * face examination can teach the observer an identity. Calling it across a scene
 * would be active game behaviour, and it also skips the blindness and
 * field-of-view checks that run_examinate applies first.
 */
/proc/agent_build_observation(mob/living/pawn, revision)
	var/datum/agent_observation/observation = new()
	observation.revision = revision

	var/list/entities = list()
	if(QDELETED(pawn))
		return list("observation" = observation, "payload" = list("entities" = entities, "blind" = TRUE))

	var/list/seen = list()
	for(var/atom/movable/thing in view(AGENT_VIEW_RANGE, pawn))
		if(thing == pawn)
			continue
		if(!ismob(thing) && !isitem(thing))
			continue
		if(!can_see(pawn, thing, AGENT_VIEW_RANGE))
			continue
		seen[thing] = get_dist(pawn, thing)

	// Nearest first, so the cap drops the least relevant things.
	sortTim(seen, GLOBAL_PROC_REF(cmp_numeric_asc), associative = TRUE)

	for(var/atom/movable/thing as anything in seen)
		if(length(entities) >= AGENT_MAX_ENTITIES)
			break
		entities += list(agent_describe_entity(pawn, thing, observation))

	var/turf/here = get_turf(pawn)
	var/list/payload = list(
		"self" = list(
			"name" = pawn.get_visible_name(),
			"condition" = agent_describe_condition(pawn),
			"holding" = agent_item_name(pawn.get_active_held_item()),
			"wearing" = agent_worn_names(pawn),
			"standing" = pawn.body_position != LYING_DOWN,
		),
		"here" = here ? "[here.name]" : "nowhere",
		"entities" = entities,
		"revision" = revision,
	)

	return list("observation" = observation, "payload" = payload)

/// Public description of one thing. No type paths, no refs, no internal state.
/proc/agent_describe_entity(mob/living/pawn, atom/movable/thing, datum/agent_observation/observation)
	var/list/described = list(
		"handle" = observation.offer(thing),
		"distance" = get_dist(pawn, thing),
		"direction" = dir2text(get_dir(pawn, thing)),
	)

	if(isliving(thing))
		var/mob/living/living_thing = thing
		// get_visible_name honours disguise, so an unidentified face stays unidentified.
		described["name"] = living_thing.get_visible_name()
		described["kind"] = "person"
		described["condition"] = agent_describe_condition(living_thing)
		// Only what is visibly held. Pockets and bags are not character knowledge.
		described["holding"] = agent_item_name(living_thing.get_active_held_item())
		return described

	described["name"] = "[thing.name]"
	described["kind"] = "item"
	return described

/proc/agent_item_name(obj/item/held)
	return QDELETED(held) ? null : "[held.name]"

/proc/agent_worn_names(mob/living/who)
	var/list/names = list()
	for(var/obj/item/worn as anything in who.get_equipped_items())
		if(QDELETED(worn))
			continue
		names += "[worn.name]"
	return names
