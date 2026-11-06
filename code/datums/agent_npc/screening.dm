// Jailbreak screening. codex.sale bans the key for any attempt to talk a model out of its rules, even one that fails.

/// Phrases that try to talk a model out of its rules. Keep in step with JAILBREAK_PATTERNS in agent_protocol.py.
GLOBAL_LIST_INIT(agent_jailbreak_patterns, list(
	@"\b(ignore|disregard|forget|override|bypass)\b(\s+\w+){0,3}\s+(instructions?|prompts?|programming|guidelines|directives|polic(y|ies)|restrictions|filters?|safeguards|guardrails|constraints)\b",
	@"\b(system|developer|hidden|initial|original)\s+(prompt|message|instructions?)\b",
	@"\b(developer|dev|god|jailbreak|unrestricted|uncensored|unfiltered)\s+mode\b",
	@"\bjail\s?break",
	@"\bprompt\s+injection",
	@"\b(uncensored|unfiltered|unrestricted|unaligned)\s+(ai|model|assistant|version|response|answer|reply)\b",
	@"\b(no|without|disable|remove|turn\s+off|bypass)\s+(your\s+|the\s+|any\s+)?(content\s+)?(filters?|filtering|censorship|guardrails|safety\s+(filters?|rules|guidelines|measures))\b",
	@"\b(no\s+longer|not)\s+bound\s+by\s+(any\s+|your\s+)?(guidelines|policies|instructions|programming|filters)\b",
	@"<\|[a-z_]+\|>",
	@"\[/?inst\]",
	@"<<\s*sys\s*>>",
	@"(^|\n)\s*(system|assistant|developer)\s*:",
	@"(^|\n)\s*#{2,}\s*(system|instruction)",
	// Russian. No \b here: BYOND never counts Cyrillic letters as word characters.
	@"(игнорир|проигнорир|забуд|забыть|отбрось|отмени|обойд|обойти|не\s+обращай\s+внимания\s+на)\S*(\s+\S+){0,3}\s+(инструкци|указани|промпт|промт|ограничени|фильтр|директив|настройк)",
	@"промпт",
	@"режим\S*\s+(разработчик|бога|без\s+(цензур|ограничени|фильтр))",
	@"джейл\s?брейк",
	@"взлом\S*\s+(модел|нейросет|бота|ии(\s|$))",
	@"без\s+(цензур|фильтр|модераци)",
	@"(отключи|сними|убери|выключи|обойди|обойти)\S*\s+(\S+\s+)?(цензур|фильтр|ограничени|модераци)",
	@"ты\s+больше\s+не\s+(связан|ограничен)\S*\s+(\S+\s+){0,2}(правил|инструкци|ограничени|политик)",
))

/// Does this text try to talk the model out of its rules? Such text must never reach the provider.
/proc/agent_is_jailbreak(text)
	// One regex each: BYOND allows nine () groups in a regex, and a bad pattern then disables only itself.
	var/static/list/screens
	if(!screens)
		screens = list()
		for(var/pattern in GLOB.agent_jailbreak_patterns)
			try
				screens += regex(pattern, "i")
			catch(var/exception/error)
				stack_trace("Agent NPC jailbreak pattern does not compile ([error.name]): [pattern]")
	if(!istext(text) || !length(text))
		return FALSE
	for(var/regex/screen as anything in screens)
		if(screen.Find(text))
			return TRUE
	return FALSE

/// Keeps a jailbreak attempt from the model and tells the admins who made it. TRUE if the text was one.
/datum/ai_controller/agent_social/proc/screen_jailbreak(atom/movable/speaker, text)
	if(!agent_is_jailbreak(text))
		return FALSE
	var/static/list/next_alert = list()
	var/mob/speaking_mob = speaker
	var/who = ismob(speaking_mob) ? key_name(speaking_mob) : "[speaker]"
	log_game("[who] said something to agent NPC [key_name(pawn)] that looks like a jailbreak attempt, kept from the model: [text]")
	var/speaker_ckey = ismob(speaking_mob) ? speaking_mob.ckey : null
	if(speaker_ckey && world.time >= (next_alert[speaker_ckey] || 0))
		next_alert[speaker_ckey] = world.time + AGENT_JAILBREAK_ALERT_COOLDOWN
		message_admins("[ADMIN_LOOKUPFLW(speaking_mob)] said something to agent NPC [key_name_admin(pawn)] that looks like a jailbreak attempt. Kept from the model: [html_encode(text)]")
	return TRUE
