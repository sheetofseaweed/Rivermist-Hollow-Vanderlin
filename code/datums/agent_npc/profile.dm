/**
 * Who an agent NPC is.
 *
 * This is game content, so it lives in DM, not in the sidecar. The sidecar
 * turns a profile into a system prompt; DM decides what the character is and
 * what it is allowed to do. That split keeps DM provider-independent while
 * leaving it authoritative over the character.
 *
 * permitted_actions is not decoration. It is check one of the four
 * authorisation checks, enforced in dispatch before anything executes.
 */
/datum/agent_profile
	/// Short label used in logs and in the prompt header.
	var/label = "villager"
	/// Character brief. Written in second person, given to the model as itself.
	var/persona = "You are an ordinary villager going about your day."
	/// What this character knows. Character knowledge, never server truth.
	var/background = "You live in this town. You know your neighbours by sight."
	/// How the character speaks. Kept separate so it can be tuned alone.
	var/voice = "You speak plainly and briefly, in period-appropriate language."
	/// Hard limits, stated to the model and enforced in DM.
	var/list/permitted_actions = list("say", "emote", "wait")
	/// Described to the model so it knows what it cannot do.
	var/limits = "You cannot fight. If threatened you run. You do not know anything you have not seen or been told."
	/// Other names this character answers to. Only ever evidence FOR being addressed, never against.
	var/list/aliases = list()

/// Wire form. Static per NPC, so the sidecar can cache a prompt built from it.
/datum/agent_profile/proc/to_payload()
	return list(
		"label" = label,
		"persona" = persona,
		"background" = background,
		"voice" = voice,
		"limits" = limits,
		"permitted_actions" = permitted_actions.Copy(),
		"aliases" = aliases.Copy(),
	)

/datum/agent_profile/proc/permits(action_name)
	return (action_name in permitted_actions)

/// The pilot profile: the four pilot actions plus wait.
/datum/agent_profile/villager
	label = "villager"
	persona = "You are a villager in a small medieval town. You are wary of \
		strangers but not rude. You have your own small concerns: the weather, \
		the harvest, your neighbours."
	background = "You live here and know the town by sight. You do not know \
		anything that happens out of your view, and you do not know what any \
		stranger is thinking."
	voice = "You speak briefly, a sentence or two, in plain period language. \
		You never narrate your own actions or describe yourself from outside."
	permitted_actions = list("say", "emote", "approach", "use", "touch", "wait")
	limits = "You cannot fight, and you will not try. If you are attacked you \
		run. You only know what you can see or have been told."

/// A talker. Same character, but it will not walk anywhere or touch anything.
/// Worth using for a first supervised round, where less motion is less risk.
/datum/agent_profile/villager/sedentary
	permitted_actions = list("say", "emote", "wait")
