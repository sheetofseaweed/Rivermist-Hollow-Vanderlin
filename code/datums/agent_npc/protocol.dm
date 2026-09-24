/**
 * One decision request in flight.
 *
 * Carries the identity fields that let SSagent_npc decide, on receipt, whether
 * the answer is still about a world that exists. Deadlines use world.time
 * because what matters is how far the game has moved, not wall clock.
 *
 * The transport is owned, not borrowed. Abandoning a request must hand the
 * transport to the subsystem drain, never just drop it: rust-g keeps a native
 * job until its result is collected.
 */
/datum/agent_request
	var/request_id
	var/pawn_id
	/// Survives binding replacement, so a new binding cannot reuse an old identity.
	var/binding_epoch
	var/binding_generation
	var/observation_revision
	var/session_id
	var/round_id
	/// world.time after which this request is dead regardless of what arrives.
	var/deadline = 0
	var/started_at = 0
	var/tokens_reserved = 0
	/// TRUE while this request still holds a reservation on both ledgers.
	/// The flag is what makes release exactly-once.
	var/reservation_open = FALSE
	/// The events this request carried. Kept so a post-submission failure can
	/// put the player's original request back rather than losing it.
	var/list/sent_events
	var/datum/http_request/transport

/datum/agent_request/Destroy(force, ...)
	if(transport)
		stack_trace("agent_request destroyed while still holding a transport; the native job will leak. Use release_transport().")
		transport = null
	return ..()

/// Hand the transport to whoever will drain it. Ownership moves to the caller.
/datum/agent_request/proc/release_transport()
	RETURN_TYPE(/datum/http_request)
	. = transport
	transport = null

/// Fill identity from the binding and build the wire body.
/datum/agent_request/proc/prepare(datum/agent_binding/binding, new_session_id, serial, list/observation, list/events, list/profile)
	// Serial is subsystem owned and monotonic, so no two requests in a session
	// share an id even if a binding is destroyed and recreated for the same pawn.
	request_id = "r[serial]"
	pawn_id = binding.pawn_id
	binding_epoch = binding.epoch
	binding_generation = binding.generation
	observation_revision = binding.observation_revision
	session_id = new_session_id
	round_id = GLOB.round_id
	started_at = world.time
	deadline = world.time + AGENT_DEFAULT_DEADLINE

	// Profile first and observation last: the profile is static per NPC, so a
	// sidecar can cache a prompt prefix built from it.
	return list(
		"protocol_version" = AGENT_PROTOCOL_VERSION,
		"round_id" = round_id,
		"session_id" = session_id,
		"pawn_id" = pawn_id,
		"binding_epoch" = binding_epoch,
		"binding_generation" = binding_generation,
		"request_id" = request_id,
		"observation_revision" = observation_revision,
		"deadline_ds" = AGENT_DEFAULT_DEADLINE,
		"profile" = profile,
		"events" = events,
		"observation" = observation,
	)

/// Options rust-g itself honours. Verified present in the shipped rust_g.dll.
/proc/agent_transport_options()
	return json_encode(list("timeout_seconds" = AGENT_TRANSPORT_TIMEOUT_SECONDS))

/**
 * A transport that gives up on its own.
 *
 * The DM-side deadline stops us waiting; it does not stop the native job. Only
 * rust-g's own timeout bounds the work actually running at the provider.
 */
/datum/http_request/agent/build_options()
	return agent_transport_options()

/datum/agent_request/proc/build_transport_options()
	return agent_transport_options()

/datum/agent_request/proc/begin(url, list/headers, list/body)
	transport = new /datum/http_request/agent(RUSTG_HTTP_METHOD_POST, url, json_encode(body), headers)
	transport.begin_async()
	// begin_async() stores rust-g's error text in id on failure, so a non-null id
	// proves nothing. in_progress is only set when a real job was created.
	return transport.in_progress

/datum/agent_request/proc/is_expired()
	return world.time > deadline

/// Did this request already carry something urgent? Then another urgent event need not abandon it.
/datum/agent_request/proc/carries_urgent()
	for(var/list/entry as anything in sent_events)
		if(entry["urgency"] >= AGENT_EVENT_HIGH)
			return TRUE
	return FALSE

/datum/agent_request/proc/is_complete()
	return transport?.is_complete()

/// Validated result of one request. Never holds unvalidated model output.
/datum/agent_response
	var/ok = FALSE
	/// One of AGENT_REFUSE_* when ok is FALSE.
	var/refusal
	/// Validated action, or null when the model declined.
	var/list/action
	/// Set when the sidecar reports the model refused rather than acted.
	var/model_refusal
	var/tokens_used = 0

/// Turn a completed transport into a validated response. Order matters:
/// cheap structural checks run before anything large is parsed or trusted.
/proc/agent_validate_response(datum/agent_request/request, datum/agent_binding/binding)
	var/datum/agent_response/result = new()

	if(isnull(request?.transport))
		result.refusal = AGENT_REFUSE_TRANSPORT
		return result

	var/datum/http_response/raw = request.transport.into_response()
	if(raw.errored)
		result.refusal = AGENT_REFUSE_TRANSPORT
		return result

	if(text2num(raw.status_code) != 200)
		result.refusal = AGENT_REFUSE_TRANSPORT
		return result

	if(length(raw.body) > AGENT_MAX_RESPONSE_BYTES)
		result.refusal = AGENT_REFUSE_OVERSIZED
		return result

	var/list/body
	try
		body = json_decode(raw.body)
	catch
		result.refusal = AGENT_REFUSE_MALFORMED
		return result

	if(!islist(body))
		result.refusal = AGENT_REFUSE_MALFORMED
		return result

	var/list/echo = body["echo"]
	if(!islist(echo))
		result.refusal = AGENT_REFUSE_SCHEMA
		return result

	if(echo["protocol_version"] != AGENT_PROTOCOL_VERSION)
		result.refusal = AGENT_REFUSE_PROTOCOL
		return result

	if(echo["session_id"] != request.session_id || echo["round_id"] != request.round_id)
		result.refusal = AGENT_REFUSE_SESSION
		return result

	if(echo["request_id"] != request.request_id)
		result.refusal = AGENT_REFUSE_UNKNOWN
		return result

	// Epoch first: a rebuilt binding for the same pawn gets a fresh epoch, so a
	// reply aimed at the previous binding cannot be laundered through generation.
	if(echo["binding_epoch"] != binding.epoch)
		result.refusal = AGENT_REFUSE_GENERATION
		return result

	if(echo["binding_generation"] != binding.generation)
		result.refusal = AGENT_REFUSE_GENERATION
		return result

	if(echo["observation_revision"] != binding.observation_revision)
		result.refusal = AGENT_REFUSE_REVISION
		return result

	var/reported_tokens = text2num(body["tokens_used"])
	if(!isnull(body["tokens_used"]))
		if(isnull(reported_tokens) || reported_tokens < 0 || reported_tokens > AGENT_MAX_TOKENS_PER_RESPONSE)
			result.refusal = AGENT_REFUSE_SCHEMA
			return result
	result.tokens_used = reported_tokens || 0

	if(body["refusal"])
		result.ok = TRUE
		result.model_refusal = "[body["refusal"]]"
		return result

	result.action = agent_validate_action(body["action"])
	if(isnull(result.action))
		result.refusal = AGENT_REFUSE_SCHEMA
		return result

	result.ok = TRUE
	return result

/**
 * Every action the protocol knows about.
 *
 * One list, so validation and the profile editor cannot drift apart. Adding an
 * action here without teaching dispatch_decision about it gets you a profile
 * that permits something the executor will reject.
 */
GLOBAL_LIST_INIT(agent_action_vocabulary, list("say", "emote", "me", "approach", "use", "touch", "sit", "stand", "give", "take", "fight", "stop", "wait"))

/// Structural check only. Handle authorisation happens at execution, not here.
/proc/agent_validate_action(list/action)
	if(!islist(action))
		return null

	var/name = action["name"]
	if(!(name in GLOB.agent_action_vocabulary))
		return null

	switch(name)
		if("say")
			var/text = action["text"]
			if(!istext(text) || !length(text))
				return null
			return list("name" = "say", "text" = text)
		if("emote")
			var/key = action["key"]
			if(!istext(key) || !length(key))
				return null
			return list("name" = "emote", "key" = key)
		if("me")
			var/text = action["text"]
			if(!istext(text) || !length(text))
				return null
			return list("name" = "me", "text" = text)
		if("stand")
			return list("name" = "stand")
		if("stop")
			return list("name" = "stop")
		if("fight")
			var/handle = action["handle"]
			if(!istext(handle) || !length(handle))
				return null
			// The level is checked at dispatch against the ladder and the profile; unnamed is a brawl.
			var/level = action["key"]
			if(!istext(level) || !length(level))
				level = AGENT_COMBAT_BRAWL
			return list("name" = "fight", "handle" = handle, "key" = level)
		if("give")
			var/handle = action["handle"]
			if(!istext(handle) || !length(handle))
				return null
			// The item's handle is optional: without one, whatever is in the active hand.
			var/item_handle = action["key"]
			return list("name" = "give", "handle" = handle, "key" = istext(item_handle) ? item_handle : "")
		if("approach", "use", "sit", "take")
			var/handle = action["handle"]
			if(!istext(handle) || !length(handle))
				return null
			return list("name" = name, "handle" = handle)
		if("touch")
			var/handle = action["handle"]
			if(!istext(handle) || !length(handle))
				return null
			// The way is checked at dispatch, against agent_touch_ways(); a missing one is a tap.
			var/way = action["key"]
			if(!istext(way) || !length(way))
				way = AGENT_TOUCH_TAP
			return list("name" = "touch", "handle" = handle, "key" = way)
		if("wait")
			// The quiescent outcome. Without it a conversation can never settle.
			return list("name" = "wait")

	return null
