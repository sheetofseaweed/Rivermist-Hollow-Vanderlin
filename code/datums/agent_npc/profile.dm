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
	/// Exchanges the sidecar remembers for this character. Null uses the sidecar's own default.
	var/memory_turns = null
	/// How hard this character fights back when attacked, on the combat ladder. None means it runs.
	var/combat_retaliate = AGENT_COMBAT_NONE
	/// How hard it may start a fight itself. Strangers are met one rung at a time.
	var/combat_initiate = AGENT_COMBAT_NONE

/// Wire form. Static per NPC, so the sidecar can cache a prompt built from it.
/datum/agent_profile/proc/to_payload()
	var/list/actions = permitted_actions.Copy()
	if(combat_enabled())
		actions |= GLOB.agent_combat_actions
	return list(
		"label" = label,
		"persona" = persona,
		"background" = background,
		"voice" = voice,
		"limits" = limits,
		"permitted_actions" = actions,
		"aliases" = aliases.Copy(),
		"memory_turns" = memory_turns,
		"combat_retaliate" = combat_retaliate,
		"combat_initiate" = combat_initiate,
	)

/datum/agent_profile/proc/permits(action_name)
	// Fighting comes from the combat limits, so ticking it on a pacifist can never arm them.
	if(action_name in GLOB.agent_combat_actions)
		return combat_enabled()
	return (action_name in permitted_actions)

/datum/agent_profile/proc/combat_enabled()
	return agent_combat_rank(combat_retaliate) > 0 || agent_combat_rank(combat_initiate) > 0

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
	permitted_actions = list("say", "emote", "me", "approach", "use", "touch", "sit", "stand", "give", "take", "wait")
	limits = "You cannot fight, and you will not try. If you are attacked you \
		run. You only know what you can see or have been told."

/// A talker. Same character, but it will not walk anywhere or touch anything.
/// Worth using for a first supervised round, where less motion is less risk.
/datum/agent_profile/villager/sedentary
	permitted_actions = list("say", "emote", "me", "wait")

/// A town guard: answers violence in kind, and will start a fight to keep the peace.
/datum/agent_profile/guard
	label = "guard"
	persona = "You are a guard in a small medieval town. You keep the peace, and you use force when words fail."
	background = "You know the town and its trouble-makers by sight. You only know what you have seen or been told."
	voice = "You speak briefly and with authority, in plain period language. You never narrate your own actions."
	permitted_actions = list("say", "emote", "me", "approach", "use", "touch", "sit", "stand", "give", "take", "wait")
	limits = "Warn before you fight, and fight no harder than the trouble deserves. Stand down when someone yields."
	combat_retaliate = AGENT_COMBAT_DOWNED
	combat_initiate = AGENT_COMBAT_DOWNED

/// A stallholder. Its shop comes from where it is placed; the profile is only the person.
/datum/agent_profile/merchant
	label = "merchant"
	persona = "You are a merchant who keeps a stall in a small medieval town. You like a sale, a fair bargain, and a customer who comes back."
	background = "You know your wares and your prices, and the town by sight. You only know what you have seen or been told."
	voice = "You speak briefly and warmly, like someone who talks to customers all day, in plain period language. You never narrate your own actions."
	permitted_actions = list("say", "emote", "me", "approach", "touch", "sit", "stand", "give", "take", "wait")
	limits = "Never invent wares or prices. You only sell what you are shown as for sale, at the prices shown."
	combat_retaliate = AGENT_COMBAT_BRAWL

/// Sells company at the baths. The private part is DM's alone; the model only talks, flirts and haggles.
/datum/agent_profile/performer
	label = "performer"
	persona = "You are a courtesan at the town's bathhouse. You sell your company by the quarter hour, and you are good at it."
	background = "You know the bathhouse regulars and their habits, and the town by sight. You only know what you have seen or been told."
	voice = "You speak warmly and teasingly, but discreetly, in plain period language. You never narrate your own actions."
	permitted_actions = list("say", "emote", "me", "approach", "touch", "sit", "stand", "give", "take", "wait")
	limits = "Keep talk suggestive but never explicit, and never describe intimate acts. Prices come only from what you sell, at the prices shown. What happens in private happens without words."
	combat_retaliate = AGENT_COMBAT_BRAWL
