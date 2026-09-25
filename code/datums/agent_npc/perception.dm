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
	/// Lowercased name of a person shown -> their handle, or "" when two shown people share it.
	var/list/person_names

/datum/agent_observation/New()
	. = ..()
	handles = list()
	person_names = list()
	built_at = world.time

/datum/agent_observation/Destroy(force, ...)
	handles = null
	person_names = null
	return ..()

/// Resolve a handle offered by this observation. Null means never offered.
/datum/agent_observation/proc/resolve(handle)
	RETURN_TYPE(/atom)
	if(!istext(handle))
		return null
	var/datum/weakref/reference = handles[handle]
	if(!reference)
		var/meant = handle_meant_by(handle)
		reference = meant && handles[meant]
	if(!reference)
		return null
	var/atom/resolved = reference.resolve()
	return QDELETED(resolved) ? null : resolved

/// Models write "[h3] Lexus" or just "Lexus" for h3. Either still names only what this observation showed.
/datum/agent_observation/proc/handle_meant_by(text)
	var/static/regex/handle_in_text = regex(@"\bh(\d+)\b", "i")
	if(handle_in_text.Find(text))
		return "h[handle_in_text.group[1]]"
	// A shared name is ambiguous and resolves to nobody.
	return person_names[LOWER_TEXT(trim(text))] || null

/datum/agent_observation/proc/offer(atom/thing)
	var/handle = "h[length(handles) + 1]"
	handles[handle] = WEAKREF(thing)
	return handle

/// Let a shown person be named by the name the model saw. Two people of one name cancel it.
/datum/agent_observation/proc/offer_name(name, handle)
	var/key = LOWER_TEXT(trim(name))
	if(!length(key))
		return
	person_names[key] = (key in person_names) ? "" : handle

/// Coarse state only. Exact health is server truth, not character knowledge.
/proc/agent_describe_condition(mob/living/target)
	if(target.stat >= DEAD)
		return "dead"
	if(target.stat >= UNCONSCIOUS)
		return "unconscious"
	// Health ignores brute on carbons here, so read the beating the way combat and defeat do.
	var/beaten = agent_combat_beaten(target)
	if(beaten < 0.15)
		return "unhurt"
	if(beaten < 0.5)
		return "hurt"
	if(beaten < 0.8)
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
	// Kept apart with their own cap, so a furnished room cannot crowd out people.
	var/list/fixtures_seen = list()
	for(var/atom/movable/thing in view(AGENT_VIEW_RANGE, pawn))
		if(thing == pawn)
			continue
		var/fixture = agent_is_fixture(thing)
		if(!fixture && !ismob(thing) && !isitem(thing))
			continue
		if(!can_see(pawn, thing, AGENT_VIEW_RANGE))
			continue
		// A sneaker in the dark is seen only if spotted, by the roll hostile NPCs make. Spotting reveals them.
		var/mob/living/living_thing = thing
		if(isliving(living_thing) && agent_is_hidden(living_thing) && !pawn.npc_detect_sneak(living_thing))
			continue
		if(fixture)
			fixtures_seen[thing] = get_dist(pawn, thing)
		else
			seen[thing] = get_dist(pawn, thing)

	// Nearest first, so the cap drops the least relevant things.
	sortTim(seen, GLOBAL_PROC_REF(cmp_numeric_asc), associative = TRUE)

	for(var/atom/movable/thing as anything in seen)
		if(length(entities) >= AGENT_MAX_ENTITIES)
			break
		entities += list(agent_describe_entity(pawn, thing, observation))

	var/turf/here = get_turf(pawn)
	var/list/payload = list(
		"self" = agent_describe_self(pawn, observation),
		"here" = here ? "[here.name]" : "nowhere",
		"entities" = entities,
		"structures" = agent_describe_fixtures(pawn, fixtures_seen, observation),
		"revision" = revision,
	)

	return list("observation" = observation, "payload" = payload)

/// Sneaking in the dark, or faded out. The same test the hostile AI uses before rolling to spot someone.
/proc/agent_is_hidden(mob/living/who)
	return who.rogue_sneaking || who.alpha <= 100

/// The NPC's own gear is character knowledge: both hands, every worn layer, and bag contents.
/proc/agent_describe_self(mob/living/pawn, datum/agent_observation/observation)
	var/list/myself = list(
		"name" = pawn.get_visible_name(),
		"condition" = agent_describe_condition(pawn),
		"holding" = agent_held_names(pawn),
		"wearing" = agent_worn_names(pawn),
		"carrying" = agent_stored_names(pawn),
		"standing" = pawn.body_position != LYING_DOWN,
	)
	if(pawn.buckled)
		myself["on"] = "[pawn.buckled.name]"
	var/datum/ai_controller/agent_social/agent = pawn.ai_controller
	if(istype(agent) && agent.in_combat())
		var/mob/living/foe = agent.blackboard[BB_AGENT_COMBAT_TARGET]
		myself["fighting"] = list("name" = foe.get_visible_name(), "level" = agent.blackboard[BB_AGENT_COMBAT_LEVEL])
	// Handles for what is in hand, so give can say which. Only give accepts them.
	if(observation)
		var/list/held = list()
		for(var/obj/item/item in pawn.held_items)
			if(!QDELETED(item))
				held += list(list("handle" = observation.offer(item), "name" = "[item.name]"))
		myself["held"] = held
	return myself

/// Furniture, doors and machines. Invisible-to-the-mouse fixtures are overlays and decals, not things.
/proc/agent_is_fixture(atom/movable/thing)
	if(!isstructure(thing) && !ismachinery(thing))
		return FALSE
	if(thing.mouse_opacity == MOUSE_OPACITY_TRANSPARENT)
		return FALSE
	return length("[thing.name]") > 0

/// Nearest first. Same-named fixtures past the per-name cap are counted on the last one listed.
/proc/agent_describe_fixtures(mob/living/pawn, list/fixtures_seen, datum/agent_observation/observation)
	var/list/described = list()
	if(!length(fixtures_seen))
		return described
	sortTim(fixtures_seen, GLOBAL_PROC_REF(cmp_numeric_asc), associative = TRUE)

	var/list/shown_per_name = list()
	var/list/last_of_name = list()
	for(var/obj/thing as anything in fixtures_seen)
		var/label = "[thing.name]"
		if(shown_per_name[label] >= AGENT_STRUCTURE_HANDLES_PER_NAME)
			var/list/last = last_of_name[label]
			last["more"] = (last["more"] || 0) + 1
			continue
		if(length(described) >= AGENT_MAX_STRUCTURES)
			continue
		var/list/entry = list(
			"handle" = observation.offer(thing),
			"name" = label,
			"distance" = fixtures_seen[thing],
			"direction" = dir2text(get_dir(pawn, thing)),
		)
		var/state = agent_fixture_state(pawn, thing)
		if(state)
			entry["state"] = state
		described += list(entry)
		shown_per_name[label] = (shown_per_name[label] || 0) + 1
		last_of_name[label] = entry
	return described

/// The one fact about a fixture that changes what can be done with it.
/proc/agent_fixture_state(mob/living/pawn, obj/thing)
	if(istype(thing, /obj/structure/door))
		var/obj/structure/door/door = thing
		return door.door_opened ? "open" : "closed"
	if(istype(thing, /obj/structure/closet))
		var/obj/structure/closet/closet = thing
		return closet.opened ? "open" : "closed"
	if(pawn.buckled == thing)
		return "you are on it"
	if(thing.has_buckled_mobs())
		return "occupied"
	return null

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
		observation.offer_name(described["name"], described["handle"])
		described["kind"] = "person"
		described["condition"] = agent_describe_condition(living_thing)
		// Only what is visibly held. Pockets and bags are not character knowledge.
		described["holding"] = agent_held_names(living_thing)
		// Only what examine would show. Clothing hidden under other clothing stays hidden.
		if(iscarbon(living_thing))
			described["wearing"] = agent_visible_worn_names(living_thing)
		// Who started it matters to how hard the NPC may answer, so the model is told.
		var/datum/ai_controller/agent_social/agent = pawn.ai_controller
		if(istype(agent) && agent.is_aggressor(living_thing))
			described["hostile"] = TRUE
		if(living_thing.surrendering)
			described["posture"] = "yielding"
		else if(living_thing.buckled)
			described["posture"] = "on the [living_thing.buckled.name]"
		else if(living_thing.body_position == LYING_DOWN)
			described["posture"] = "lying down"
		return described

	described["name"] = "[thing.name]"
	described["kind"] = "item"
	return described

/proc/agent_item_name(obj/item/held)
	return QDELETED(held) ? null : "[held.name]"

/// Both hands, the active one first. Only the active hand used to be listed.
/proc/agent_held_names(mob/living/who)
	var/list/names = list()
	var/obj/item/active = who.get_active_held_item()
	if(!QDELETED(active))
		names += "[active.name]"
	for(var/obj/item/held in who.held_items)
		if(held == active || QDELETED(held))
			continue
		names += "[held.name]"
	return names

/// Skin and tattoos use clothing slots, but examine does not call them clothing, so neither do we.
/proc/agent_item_is_body(obj/item/thing)
	return istype(thing, /obj/item/clothing/armor/regenerating/skin) || istype(thing, /obj/item/clothing/shirt/undershirt/easttats)

/// Everything the NPC itself wears, hidden layers included. It knows what it put on.
/proc/agent_worn_names(mob/living/who)
	var/list/names = list()
	for(var/obj/item/worn as anything in who.get_equipped_items())
		if(QDELETED(worn) || agent_item_is_body(worn))
			continue
		names += "[worn.name]"
	return names

/// What another person visibly wears. get_unobscured_items is what examine prints from.
/proc/agent_visible_worn_names(mob/living/carbon/who)
	var/list/names = list()
	for(var/obj/item/worn as anything in who.get_unobscured_items(FALSE))
		if(length(names) >= AGENT_MAX_WORN_SHOWN)
			break
		if(QDELETED(worn) || agent_item_is_body(worn))
			continue
		names += "[worn.name]"
	return names

/// Own containers, one level deep. Repeats are counted and the total capped, or a purse costs tokens per coin.
/proc/agent_stored_names(mob/living/who)
	var/list/containers = list()
	var/list/sources = list()
	for(var/obj/item/held in who.held_items)
		sources += held
	var/list/worn = who.get_equipped_items()
	if(worn)
		sources += worn

	var/budget = AGENT_MAX_STORED_SHOWN
	for(var/obj/item/container as anything in sources)
		if(budget <= 0)
			break
		if(QDELETED(container))
			continue
		var/list/inside = list()
		SEND_SIGNAL(container, COMSIG_TRY_STORAGE_RETURN_INVENTORY, inside, FALSE)
		if(!length(inside))
			continue
		var/list/counts = list()
		for(var/obj/item/stored in inside)
			var/label = "[stored.name]"
			counts[label] = (counts[label] || 0) + 1
		var/list/names = list()
		for(var/label in counts)
			if(budget <= 0)
				break
			names += counts[label] > 1 ? "[label] x[counts[label]]" : label
			budget--
		if(length(names))
			containers += list(list("in" = "[container.name]", "items" = names))
	return containers
