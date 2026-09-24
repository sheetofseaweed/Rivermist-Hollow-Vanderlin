/**
 * # Admin-authored agent profiles
 *
 * Profiles written in a round, kept on disk between rounds. The file is plain
 * JSON and meant to be hand-edited, which is exactly why nothing loaded from it
 * is trusted: every field is length-capped and every action is checked against
 * the protocol vocabulary before it reaches a pawn.
 *
 * Built-in profiles stay in DM and are never written here. They can be copied
 * into an editable entry, which is what "new from template" does.
 */

/// name -> /datum/agent_profile. Admin authored, editable, saved to disk.
GLOBAL_LIST_EMPTY(agent_custom_profiles)
/// Text fields the editor may write. Anything else is refused outright.
GLOBAL_LIST_INIT(agent_profile_text_fields, list("label", "persona", "background", "voice", "limits"))

/// An independent copy. Editing a library entry must not reach a live pawn.
/datum/agent_profile/proc/clone()
	var/datum/agent_profile/copy = new /datum/agent_profile()
	copy.label = label
	copy.persona = persona
	copy.background = background
	copy.voice = voice
	copy.limits = limits
	copy.permitted_actions = permitted_actions.Copy()
	copy.aliases = aliases.Copy()
	copy.memory_turns = memory_turns
	return copy

/// A whole number of exchanges within the ceiling, or null for the sidecar default.
/proc/agent_clean_memory_turns(value)
	if(istext(value))
		value = text2num(value)
	if(!isnum(value))
		return null
	// round() with one argument floors in DM; the second argument makes it round to nearest.
	return clamp(round(value, 1), 0, AGENT_MAX_MEMORY_TURNS)

/// Names from a list or a comma-separated line, each capped, blanks and repeats dropped.
/proc/agent_clean_profile_aliases(wanted)
	var/list/raw = istext(wanted) ? splittext(wanted, ",") : wanted
	var/list/cleaned = list()
	if(!islist(raw))
		return cleaned
	for(var/entry in raw)
		if(length(cleaned) >= AGENT_MAX_ALIASES)
			break
		var/name = trim(agent_clean_profile_text(entry, AGENT_PROFILE_LABEL_MAX))
		if(length(name) && !(name in cleaned))
			cleaned += name
	return cleaned

/// Plain text, brackets stripped, capped. Encoding it sent the model "&#39;" and grew on every save and load.
/proc/agent_clean_profile_text(value, limit = AGENT_PROFILE_TEXT_MAX)
	if(!istext(value))
		return ""
	// Tags out whole, then any stray bracket, so nothing written here can become markup in chat.
	return trim(STRIP_HTML_SIMPLE(STRIP_HTML_FULL(html_decode(value), limit), limit))

/**
 * Keep only real actions, and guarantee the one that ends a conversation.
 *
 * A profile without `wait` cannot settle: every reply produces a result, and
 * the NPC has no way to say it is finished. That is a hang, not a preference,
 * so it is repaired rather than refused.
 */
/proc/agent_clean_profile_actions(list/wanted)
	var/list/cleaned = list()
	if(islist(wanted))
		for(var/entry in wanted)
			if(!istext(entry) || !(entry in GLOB.agent_action_vocabulary))
				continue
			if(entry in cleaned)
				continue
			cleaned += entry
	if(!("wait" in cleaned))
		cleaned += "wait"
	return cleaned

/// Build a profile from untrusted data. Returns null only for a non-list.
/proc/agent_profile_from_payload(list/payload)
	if(!islist(payload))
		return null
	var/datum/agent_profile/profile = new /datum/agent_profile()
	profile.label = agent_clean_profile_text(payload["label"], AGENT_PROFILE_LABEL_MAX) || "unnamed"
	profile.persona = agent_clean_profile_text(payload["persona"])
	profile.background = agent_clean_profile_text(payload["background"])
	profile.voice = agent_clean_profile_text(payload["voice"])
	profile.limits = agent_clean_profile_text(payload["limits"])
	profile.permitted_actions = agent_clean_profile_actions(payload["permitted_actions"])
	profile.aliases = agent_clean_profile_aliases(payload["aliases"])
	profile.memory_turns = agent_clean_memory_turns(payload["memory_turns"])
	return profile

/// Every built-in profile, as payloads. Instantiated, never read via initial():
/// initial() returns null for list vars, which would empty permitted_actions.
/proc/agent_builtin_profiles()
	var/static/list/built
	if(built)
		return built
	built = list()
	for(var/datum/agent_profile/profile_type as anything in typesof(/datum/agent_profile))
		var/datum/agent_profile/sample = new profile_type()
		var/list/payload = sample.to_payload()
		payload["type"] = "[profile_type]"
		built += list(payload)
		qdel(sample)
	return built

/// Look a name up in the library, or fall back to a built-in typepath.
/proc/agent_resolve_profile(name)
	RETURN_TYPE(/datum/agent_profile)
	if(!istext(name))
		return null
	var/datum/agent_profile/stored = GLOB.agent_custom_profiles[name]
	if(!QDELETED(stored))
		return stored
	var/profile_type = text2path(name)
	if(ispath(profile_type, /datum/agent_profile))
		return new profile_type()
	return null

/// A name not already taken, so saving cannot silently overwrite another entry.
/proc/agent_unique_profile_name(wanted)
	var/base = agent_clean_profile_text(wanted, AGENT_PROFILE_LABEL_MAX)
	if(!length(base))
		base = "new profile"
	if(!GLOB.agent_custom_profiles[base])
		return base
	for(var/i in 2 to 99)
		if(!GLOB.agent_custom_profiles["[base] [i]"])
			return "[base] [i]"
	return "[base] [rand(100, 999)]"

/datum/controller/subsystem/agent_npc/proc/save_profiles()
	var/list/out = list()
	for(var/name in GLOB.agent_custom_profiles)
		var/datum/agent_profile/profile = GLOB.agent_custom_profiles[name]
		if(QDELETED(profile))
			continue
		out[name] = profile.to_payload()

	if(fexists(AGENT_PROFILE_FILE))
		fdel(AGENT_PROFILE_FILE)
	WRITE_FILE(file(AGENT_PROFILE_FILE), json_encode(out))
	log_agent("saved [length(out)] custom profile(s) to [AGENT_PROFILE_FILE]")
	return length(out)

/**
 * Replace the library with what is on disk.
 *
 * A hand-edited file is expected, so a broken one must not take the menu with
 * it. Anything unreadable leaves the library untouched and says so.
 */
/datum/controller/subsystem/agent_npc/proc/load_profiles()
	if(!fexists(AGENT_PROFILE_FILE))
		return 0

	var/list/decoded
	try
		decoded = json_decode(file2text(file(AGENT_PROFILE_FILE)))
	catch
		log_agent("could not parse [AGENT_PROFILE_FILE]; keeping the profiles already loaded")
		return -1

	if(!islist(decoded))
		log_agent("[AGENT_PROFILE_FILE] did not contain a profile table; keeping the profiles already loaded")
		return -1

	GLOB.agent_custom_profiles = list()
	for(var/name in decoded)
		var/datum/agent_profile/profile = agent_profile_from_payload(decoded[name])
		if(!profile)
			continue
		GLOB.agent_custom_profiles["[name]"] = profile
	log_agent("loaded [length(GLOB.agent_custom_profiles)] custom profile(s) from [AGENT_PROFILE_FILE]")
	return length(GLOB.agent_custom_profiles)

/**
 * Put an agent controller on an existing mob.
 *
 * Returns null on success, or a message explaining the refusal. PossessPawn
 * already destroys whatever controller was there, so this only has to decide
 * whether the swap is allowed at all.
 */
/proc/agent_attach_controller(mob/living/target, datum/agent_profile/source_profile)
	if(QDELETED(target) || !isliving(target))
		return "that mob is gone"
	// The binding refuses to act on a mob with a client, so attaching would
	// appear to work and then do nothing at all.
	if(target.client)
		return "[target.name] is player controlled"
	if(istype(target.ai_controller, /datum/ai_controller/agent_social))
		return "[target.name] is already agent controlled"

	var/datum/ai_controller/agent_social/controller = new(target)
	if(QDELETED(controller) || controller.pawn != target)
		return "the agent controller would not attach to [target.name]"

	if(source_profile)
		QDEL_NULL(controller.profile)
		controller.profile = source_profile.clone()

	// The controller already tried to register during possession. Retry now in
	// case the subsystem was off then, or the profile decided admission.
	controller.register_cooldown = 0
	controller.ensure_registered()
	return null

/**
 * Change the character an already-attached controller is playing.
 *
 * The controller and its binding are kept. Detaching and reattaching to change
 * a persona would drop the binding, and with it the conversation so far.
 */
/proc/agent_swap_profile(mob/living/target, datum/agent_profile/source_profile)
	if(QDELETED(target) || !isliving(target))
		return "that mob is gone"
	if(!source_profile)
		return "that profile no longer exists"
	var/datum/ai_controller/agent_social/existing = target.ai_controller
	if(!istype(existing))
		return "[target.name] is not agent controlled"

	QDEL_NULL(existing.profile)
	existing.profile = source_profile.clone()
	return null

/// Take agent control off a mob and put its own controller back, if it had one.
/proc/agent_detach_controller(mob/living/target)
	if(QDELETED(target) || !isliving(target))
		return "that mob is gone"
	if(!istype(target.ai_controller, /datum/ai_controller/agent_social))
		return "[target.name] is not agent controlled"

	// initial() on a typepath var gives the controller the mob type declares.
	var/restore = initial(target.ai_controller)
	QDEL_NULL(target.ai_controller)

	// A purpose-built agent mob declares the agent controller, so restoring it
	// would re-attach the thing we were just asked to remove.
	if(ispath(restore, /datum/ai_controller) && !ispath(restore, /datum/ai_controller/agent_social))
		new restore(target)
	return null
