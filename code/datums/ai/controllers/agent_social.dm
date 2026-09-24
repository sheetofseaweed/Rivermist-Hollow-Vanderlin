/**
 * # Agent social controller
 *
 * The pilot pawn for agent-driven NPCs. Purpose built rather than reskinned
 * from a hostile, because every existing humanoid controller carries branches
 * that are unsafe as an unsupervised fallback: human_bum has mug and loot, and
 * every human_npc user in the tree is a hostile.
 *
 * It cannot fight. Attacked, it stands, resists, breaks restraints and runs.
 * That is the whole autonomous repertoire, which is what makes the sidecar
 * outage fallback safe by construction rather than by hope.
 */
/datum/ai_controller/agent_social
	movement_delay = 0.5 SECONDS
	max_target_distance = 9
	ai_movement = /datum/ai_movement/hybrid_pathing
	idle_behavior = /datum/idle_behavior/nothing
	// Idling would add up to 5s to every reaction on top of the model round
	// trip. Affordable for a pilot; revisit before the registry grows.
	can_idle = FALSE

	blackboard = list(
		// It never fights, so any target it holds is something to run from.
		BB_BASIC_MOB_FLEEING = TRUE,
		BB_AGENT_FLEE_UNTIL = 0,
	)

	planning_subtrees = list(
		// REFLEX, indices 1..5. Never agent owned.
		/datum/ai_planning_subtree/generic_stand,
		/datum/ai_planning_subtree/generic_break_restraints,
		/datum/ai_planning_subtree/generic_resist/agent,
		/datum/ai_planning_subtree/agent_flee_recovery,
		/datum/ai_planning_subtree/flee_target,
		// OBJECTIVE, index 6. The only agent owned slot.
		/datum/ai_planning_subtree/agent_intent,
	)

	/// A bound pawn keeps planning on z-levels the engine would otherwise idle.
	var/require_wakefulness = TRUE
	/// Our registration with SSagent_npc. Always guard with QDELETED.
	var/datum/agent_binding/binding
	/// Who this character is. Set the typepath; New() instantiates it.
	var/profile_type = /datum/agent_profile/villager
	var/datum/agent_profile/profile
	/// Throttles registration retries for pawns that spawn before the subsystem.
	COOLDOWN_DECLARE(register_cooldown)
	/// Whether the thinking bubble is on the pawn. Our own flag: the typing indicator clears itself for clientless mobs.
	var/thinking = FALSE
	/// The item held out, watched until taken or the offer ends. Weak, so it never pins the item.
	var/datum/weakref/watched_offer

/datum/ai_controller/agent_social/New(atom/new_pawn)
	// An instance, not initial() on the typepath: initial() returns null for
	// list vars, which would silently empty permitted_actions.
	profile = new profile_type()
	return ..()

/datum/ai_controller/agent_social/PossessPawn(atom/new_pawn)
	. = ..()
	RegisterSignal(pawn, COMSIG_MOVABLE_HEAR, PROC_REF(on_pawn_heard))
	RegisterSignal(pawn, COMSIG_ATOM_ATTACK_HAND, PROC_REF(on_pawn_touched))
	RegisterSignal(pawn, COMSIG_MOB_FED, PROC_REF(on_pawn_fed))
	RegisterSignal(pawn, COMSIG_LIVING_ITEM_OFFERED, PROC_REF(on_item_offered))
	RegisterSignal(pawn, COMSIG_MOB_UNBUCKLED, PROC_REF(on_unbuckled))
	ensure_registered()

/datum/ai_controller/agent_social/UnpossessPawn(destroy)
	if(pawn)
		// Before letting go, or a detached mob keeps a bubble nothing will ever clear.
		show_thinking(FALSE)
		UnregisterSignal(pawn, list(COMSIG_MOVABLE_HEAR, COMSIG_ATOM_ATTACK_HAND, COMSIG_MOB_FED, COMSIG_LIVING_ITEM_OFFERED, COMSIG_MOB_UNBUCKLED, COMSIG_LIVING_STOPPED_OFFERING_ITEM))
		stop_watching_offer()
	release_binding("pawn unpossessed")
	return ..()

/**
 * Turn overheard speech into an event the agent can answer.
 *
 * The signal carries the emitting proc's whole args list as ONE payload, so the
 * handler must take a list. A handler declaring unpacked parameters compiles
 * clean and silently binds the list to the wrong argument.
 *
 * The raw payload is not forwarded. It is composed here through lang_treat on
 * our own pawn, because /mob/living/Hear() returns early for clientless mobs,
 * before language incomprehension is ever applied. Forwarding the raw message
 * would hand the agent text this character cannot actually understand.
 */
/datum/ai_controller/agent_social/proc/on_pawn_heard(datum/source, list/hearing_args)
	SIGNAL_HANDLER
	if(!islist(hearing_args) || !binding || QDELETED(binding))
		return

	var/atom/movable/speaker = hearing_args[HEARING_SPEAKER]
	if(QDELETED(speaker) || speaker == pawn)
		return

	var/mob/living/living_pawn = pawn
	if(!isliving(living_pawn) || living_pawn.stat >= UNCONSCIOUS || !living_pawn.can_hear())
		return

	var/understood = living_pawn.lang_treat(
		speaker,
		hearing_args[HEARING_LANGUAGE],
		hearing_args[HEARING_RAW_MESSAGE],
		null,
		null,
		no_quote = TRUE,
	)

	// get_visible_name is on /mob/living, and it honours disguise. Anything else
	// is named plainly rather than guessed at.
	var/speaker_name = "[speaker.name]"
	if(isliving(speaker))
		var/mob/living/living_speaker = speaker
		speaker_name = living_speaker.get_visible_name()

	// Speech from another agent NPC must not refresh the continuation budget.
	// Two agents replenishing each other is a conversation with no end that no
	// per-turn cap can stop. It is still heard; it just does not buy more turns.
	var/from_another_agent = !isnull(SSagent_npc?.bindings?["[REF(speaker)]"])

	// Bounds checked: Hear() passes its whole args list, but callers that build
	// one by hand stop at the four named HEARING_* fields. Indexing past the end
	// runtimes, and a runtime in a signal handler loses the speech silently.
	var/list/mods = (length(hearing_args) >= HEARING_MESSAGE_MODS) ? hearing_args[HEARING_MESSAGE_MODS] : null
	var/list/context = build_speech_context(speaker, understood, hearing_args[HEARING_RAW_MESSAGE], mods)

	var/list/detail = list(
		"speaker" = speaker_name,
		"text" = understood,
		"distance" = context["distance"],
		"whispered" = context["whispered"],
		"shouted" = agent_speech_is_shouted(context["volume"]),
		// Named for what it is: a cheap local estimate of the social scene, not
		// the set of mobs the speech engine actually delivered to.
		"nearby_people" = context["nearby_people"],
	)

	var/classification = classify_speech(speaker, understood, context)
	detail["addressing"] = classification

	// Said to the model plainly, so a nameless "yes" reads as the answer it is.
	detail["from_partner"] = binding.is_partner(speaker)
	detail["spoken_to_you"] = context["focused"]
	// Heard as players hear it, but the NPC must not act as if it can see the speaker.
	if(isliving(speaker) && agent_is_hidden(speaker))
		detail["unseen"] = TRUE

	route_speech(classification, speaker_name, understood, detail, from_another_agent, speaker)

/**
 * What does one classified line actually do?
 *
 * Returns the route taken, so the decision can be tested without staging a
 * hearing event. Nothing here is ever discarded: the worst outcome for a line
 * is that it waits and rides along with the next real decision.
 */
/datum/ai_controller/agent_social/proc/route_speech(classification, speaker_name, text, list/detail, from_another_agent = FALSE, atom/movable/speaker = null, kind = AGENT_LINE_SPEECH)
	if(QDELETED(binding))
		return "unbound"

	// Overheard. It still reaches the agent, folded into the next real decision,
	// but it neither buys one nor extends the interaction. Two players chatting
	// nearby used to do both.
	if(!agent_speech_wakes_us(classification))
		return buffer_speech(speaker_name, text, detail, "buffered", kind)

	// Rationed, not silenced, and only ever for speech we could not classify.
	// Directed lines and attacks never reach this branch.
	if(classification == AGENT_SPEECH_AMBIGUOUS)
		if(!binding.may_spend_on_ambiguous())
			SSagent_npc?.note_ambiguous_deferred()
			return buffer_speech(speaker_name, text, detail, "rationed", kind)
		binding.note_ambiguous_spend()

	// Two agents answering each other loop until one waits. A few exchanges are life; then they buffer.
	if(from_another_agent)
		if(!binding.agent_exchange_allowed(speaker))
			SSagent_npc?.note_agent_exchange_capped()
			return buffer_speech(speaker_name, text, detail, "capped", kind)
		binding.note_agent_exchange(speaker)
	else if(ismob(speaker))
		// A player puts someone real in the scene. Clientless NPCs neither count nor reset anything.
		var/mob/speaking_mob = speaker
		if(speaking_mob.client)
			binding.reset_agent_exchanges()

	// This line buys a decision, so it replaces a waiting overheard copy rather than being dropped as one.
	binding.drop_buffered_speech(speaker_name, text)

	// Whoever bought this decision is who the NPC answers, if it does. Dispatch fixes the partner.
	binding.note_candidate(speaker)

	// Only directed lines buy turns on hearing. Unclear ones earn them in engage_candidate(), by being answered.
	var/replenish = !from_another_agent && classification == AGENT_SPEECH_DIRECTED
	binding.mark_dirty(agent_line_event(kind, TRUE), AGENT_EVENT_LOW, detail, replenish = replenish)
	return "sent"

/// The event name a routed line is recorded under: answered, or only kept for later.
/proc/agent_line_event(kind, answered)
	if(kind == AGENT_LINE_EMOTE)
		return answered ? "saw_emote" : "noticed_emote"
	return answered ? "heard_speech" : "overheard_speech"

/// Keep a line for the next decision, once. This check once ran before routing and dropped answers.
/datum/ai_controller/agent_social/proc/buffer_speech(speaker_name, text, list/detail, route, kind = AGENT_LINE_SPEECH)
	if(binding.speech_already_buffered(speaker_name, text))
		return "duplicate"
	binding.push_event(agent_line_event(kind, FALSE), AGENT_EVENT_LOW, detail)
	return route

/**
 * Everything cheap and local we can say about one heard line.
 *
 * Built once, because the classifier, the event payload and the telemetry all
 * want the same facts and view() is not free. Signal handlers must not sleep,
 * and nothing here does.
 */
/datum/ai_controller/agent_social/proc/build_speech_context(atom/movable/speaker, text, raw_text, list/mods)
	// Range rechecked per line: a player who walks off is suspended, not ended, and counts again on return.
	var/focused = binding?.has_focus_from(speaker) && get_dist(pawn, speaker) <= AGENT_FOCUS_RANGE
	var/list/context = list(
		"distance" = get_dist(pawn, speaker),
		"whispered" = islist(mods) && mods[WHISPER_MODE],
		// Read from the raw line, because volume is physical: you can hear that
		// someone is shouting in a language you do not speak.
		"volume" = say_test(raw_text),
		// Which script the NPC is being spoken to in, so a failed name match in
		// a script we cannot read is not mistaken for an absent name.
		"script" = agent_text_script(text),
		"focused" = focused,
		// They explicitly turned to a different NPC and are still near it.
		"focused_elsewhere" = !focused && agent_focus_held_elsewhere(speaker, binding),
		"nearby_people" = 0,
		"named_someone_else" = FALSE,
	)

	// Split once for the whole crowd; each nearby mob is checked against it.
	var/list/prepared = agent_prepare_words(text)
	for(var/mob/living/nearby in view(AGENT_VIEW_RANGE, pawn))
		if(nearby == pawn || nearby == speaker)
			continue
		// Someone who cannot hear is not an alternative audience.
		if(nearby.stat >= UNCONSCIOUS || !nearby.can_hear())
			continue
		context["nearby_people"]++
		if(!context["named_someone_else"] && agent_name_in_vocative(nearby.get_visible_name(), text, prepared))
			context["named_someone_else"] = TRUE
	return context

/// The name this NPC can legitimately be addressed by. get_visible_name honours
/// disguise, so a hidden identity is not what wakes it.
/datum/ai_controller/agent_social/proc/addressable_name()
	var/mob/living/living_pawn = pawn
	return isliving(living_pawn) ? living_pawn.get_visible_name() : "[pawn?.name]"

/// The visible name, plus profile aliases only while the face is showing. A masked NPC answers to no nickname.
/datum/ai_controller/agent_social/proc/addressable_names()
	var/visible = addressable_name()
	var/list/names = list(visible)
	var/mob/living/living_pawn = pawn
	if(!isliving(living_pawn) || visible != living_pawn.real_name || !length(profile?.aliases))
		return names
	return names + profile.aliases

/// The strongest way any of our names was said. Aliases only ever add evidence of address.
/datum/ai_controller/agent_social/proc/self_address_strength(text)
	. = AGENT_NAMED_NONE
	for(var/name in addressable_names())
		. = max(., agent_self_address_strength(name, text))
		if(. == AGENT_NAMED_STRONG)
			return

/**
 * Was that said to us?
 *
 * Three answers, not two. Only the first four rules claim to know; everything
 * else is honestly ambiguous. The classifier stays lopsided — a wasted decision
 * is a fraction of a penny, an NPC that ignores someone looks broken — so only
 * positive evidence that a line belonged elsewhere produces `overheard`.
 */
/datum/ai_controller/agent_social/proc/classify_speech(atom/movable/speaker, text, list/context)
	// Talk To is the one answer that is not a guess, and reads no text. It outranks everything below.
	if(context["focused"])
		return AGENT_SPEECH_DIRECTED

	// Only a strong mention is certain. A weak one is usually talk about us, so it goes through the ration.
	var/named = self_address_strength(text)
	if(named == AGENT_NAMED_STRONG)
		return AGENT_SPEECH_DIRECTED

	// Talk To on another NPC outranks every guess below, but not our name said strongly.
	if(context["focused_elsewhere"])
		return AGENT_SPEECH_OVERHEARD

	// A whisper carries one tile. Past that is the eavesdrop band, where what
	// arrives is a starred copy, so hearing one proves proximity rather than
	// intent. An eavesdropped whisper falls through to the ordinary rules.
	if(context["whispered"] && context["distance"] <= AGENT_WHISPER_INTENDED_RANGE)
		return AGENT_SPEECH_DIRECTED

	// They addressed someone here, even our partner's "Bob, pass the ale". A weak mention of us earns attention.
	if(context["named_someone_else"])
		return named == AGENT_NAMED_WEAK ? AGENT_SPEECH_AMBIGUOUS : AGENT_SPEECH_OVERHEARD

	// Our partner's reply needs no name. Anyone else's line falls through to the rules below.
	if(binding?.is_partner(speaker))
		return AGENT_SPEECH_DIRECTED

	// Nobody else could have been the audience.
	if(context["nearby_people"] <= 0)
		return AGENT_SPEECH_DIRECTED

	// A shout is a deliberate attempt to be heard at distance, and the engine
	// extends its range to match. Loud and public is not the same as ours, so
	// this is worth attention rather than a claim of certainty.
	if(agent_speech_is_shouted(context["volume"]))
		return AGENT_SPEECH_AMBIGUOUS

	// Distant chatter in company. Skipped for scripts we cannot name-match, or one language group goes unheard.
	if(context["distance"] > AGENT_DIRECT_SPEECH_RANGE && agent_script_is_matchable(context["script"]))
		return named == AGENT_NAMED_WEAK ? AGENT_SPEECH_AMBIGUOUS : AGENT_SPEECH_OVERHEARD

	return AGENT_SPEECH_AMBIGUOUS

/// Does this classification schedule a decision? Ambiguous still does: without
/// an attention budget to bound it, silence is the worse failure.
/proc/agent_speech_wakes_us(classification)
	return classification != AGENT_SPEECH_OVERHEARD

/// visible_message skips clientless mobs, so emotes arrive here instead. Routed like speech; returns the route.
/datum/ai_controller/agent_social/proc/on_emote_perceived(mob/emoter, text, intentional, audible)
	SHOULD_NOT_SLEEP(TRUE)
	if(!binding || QDELETED(binding))
		return "unbound"
	var/mob/living/living_pawn = pawn
	if(!isliving(living_pawn) || QDELETED(emoter) || emoter == living_pawn)
		return "unseen"
	if(!agent_can_perceive_emote(living_pawn, emoter, audible))
		return "unseen"
	var/cleaned = agent_clean_emote_text(text)
	if(!cleaned)
		return "unseen"

	var/emoter_name = "[emoter.name]"
	var/unseen = FALSE
	if(isliving(emoter))
		var/mob/living/living_emoter = emoter
		emoter_name = living_emoter.get_visible_name()
		unseen = agent_is_hidden(living_emoter)
		// Players past arm's length get a sneaking emoter's emote starred. So does the NPC.
		if(!audible && living_emoter.m_intent == MOVE_INTENT_SNEAK && get_dist(living_pawn, living_emoter) > SNEAKY_EMOTE_VISIBLE_RANGE)
			cleaned = stars(cleaned)

	var/list/context = build_emote_context(emoter, cleaned)
	var/classification = classify_emote(emoter, intentional, context)
	var/list/detail = list(
		"speaker" = emoter_name,
		"text" = cleaned,
		"distance" = context["distance"],
		"nearby_people" = context["nearby_people"],
		"addressing" = classification,
		"from_partner" = binding.is_partner(emoter),
		"spoken_to_you" = context["focused"],
	)
	// Said plainly, so the model does not read a cough as a remark.
	if(!intentional)
		detail["involuntary"] = TRUE
	if(unseen)
		detail["unseen"] = TRUE

	var/from_another_agent = !isnull(SSagent_npc?.bindings?["[REF(emoter)]"])
	return route_speech(classification, emoter_name, cleaned, detail, from_another_agent, emoter, AGENT_LINE_EMOTE)

/// The facts classify_emote reads. Built once, like the speech context.
/datum/ai_controller/agent_social/proc/build_emote_context(mob/emoter, text)
	var/focused = binding?.has_focus_from(emoter) && get_dist(pawn, emoter) <= AGENT_FOCUS_RANGE
	var/list/words = agent_emote_words(text)
	var/named_us = AGENT_NAMED_NONE
	// Capitalised or transliterated is strong; lowercase is weak, so "she will sit" never summons Will.
	for(var/name in addressable_names())
		if(agent_emote_mentions(name, words))
			named_us = AGENT_NAMED_STRONG
			break
	if(named_us == AGENT_NAMED_NONE && self_address_strength(text) != AGENT_NAMED_NONE)
		named_us = AGENT_NAMED_WEAK

	var/list/context = list(
		"distance" = get_dist(pawn, emoter),
		"focused" = focused,
		"focused_elsewhere" = !focused && agent_focus_held_elsewhere(emoter, binding),
		"named_us" = named_us,
		"nearby_people" = 0,
		"named_someone_else" = FALSE,
	)
	for(var/mob/living/nearby in view(AGENT_VIEW_RANGE, pawn))
		if(nearby == pawn || nearby == emoter || nearby.stat >= UNCONSCIOUS)
			continue
		context["nearby_people"]++
		if(!context["named_someone_else"] && agent_emote_mentions(nearby.get_visible_name(), words))
			context["named_someone_else"] = TRUE
	return context

/// Emotes name people mid-sentence, so any mention counts. Unaimed emotes in company are only noticed.
/datum/ai_controller/agent_social/proc/classify_emote(mob/emoter, intentional, list/context)
	// A cough, a sneeze, a pain scream. Kept, so it is not lost, but it buys nothing.
	if(!intentional)
		return AGENT_SPEECH_OVERHEARD
	if(context["focused"])
		return AGENT_SPEECH_DIRECTED
	if(context["named_us"] == AGENT_NAMED_STRONG)
		return AGENT_SPEECH_DIRECTED
	if(context["focused_elsewhere"])
		return AGENT_SPEECH_OVERHEARD
	if(context["named_someone_else"])
		return context["named_us"] == AGENT_NAMED_WEAK ? AGENT_SPEECH_AMBIGUOUS : AGENT_SPEECH_OVERHEARD
	if(binding?.is_partner(emoter))
		return AGENT_SPEECH_DIRECTED
	// Nobody else close enough to have been the audience.
	if(context["nearby_people"] <= 0 && context["distance"] <= AGENT_DIRECT_SPEECH_RANGE)
		return AGENT_SPEECH_DIRECTED
	if(context["named_us"] == AGENT_NAMED_WEAK)
		return AGENT_SPEECH_AMBIGUOUS
	// Right beside us, in company. Maybe ours; the ration decides.
	if(context["distance"] <= AGENT_REACH_DISTANCE)
		return AGENT_SPEECH_AMBIGUOUS
	return AGENT_SPEECH_OVERHEARD

/// Could this pawn perceive that emote? The sense matches the emote, and walls block both.
/proc/agent_can_perceive_emote(mob/living/pawn, mob/emoter, audible)
	if(pawn.stat >= UNCONSCIOUS)
		return FALSE
	var/turf/ours = get_turf(pawn)
	var/turf/theirs = get_turf(emoter)
	if(!ours || !theirs || ours.z != theirs.z)
		return FALSE
	if(get_dist(ours, theirs) > DEFAULT_MESSAGE_RANGE)
		return FALSE
	if(audible ? !pawn.can_hear() : pawn.is_blind())
		return FALSE
	if(emoter.invisibility > pawn.see_invisible)
		return FALSE
	return can_see(pawn, emoter, DEFAULT_MESSAGE_RANGE)

/// Markup out, entities decoded, length capped. The model reads words, not HTML.
/proc/agent_clean_emote_text(text)
	if(!istext(text))
		return null
	var/cleaned = trim(html_decode(STRIP_HTML_FULL(text, AGENT_EMOTE_TEXT_MAX)))
	return length(cleaned) ? cleaned : null

/datum/ai_controller/agent_social/Destroy(force, ...)
	release_binding("controller destroyed")
	QDEL_NULL(profile)
	return ..()

/// Register with SSagent_npc, retrying for pawns that spawned before it existed.
/datum/ai_controller/agent_social/proc/ensure_registered()
	if(binding && !QDELETED(binding))
		return TRUE
	binding = null
	if(QDELETED(pawn) || !isliving(pawn))
		return FALSE
	if(!COOLDOWN_FINISHED(src, register_cooldown))
		return FALSE
	COOLDOWN_START(src, register_cooldown, AGENT_REGISTER_RETRY)
	binding = SSagent_npc?.register_pawn(pawn, src)
	return !isnull(binding)

/datum/ai_controller/agent_social/proc/release_binding(reason)
	if(binding && !QDELETED(binding))
		SSagent_npc?.unregister_pawn(binding, reason)
	binding = null

/**
 * Keep a bound pawn awake wherever it spawned.
 *
 * The parent puts a controller to AI_STATUS_OFF when its z-level is outside
 * SSmobs.town_z and holds no clients. An agent NPC there would register,
 * receive events, and silently never plan. Only that one reason is overridden:
 * death, incapacitation and player takeover are rechecked and still win.
 */
/datum/ai_controller/agent_social/get_expected_ai_status()
	. = ..()
	if(. != AI_STATUS_OFF || !require_wakefulness)
		return .
	if(!binding || QDELETED(binding) || QDELETED(pawn) || !able_to_run)
		return .
	var/mob/living/mob_pawn = pawn
	if(!isliving(mob_pawn) || mob_pawn.client || mob_pawn.stat >= UNCONSCIOUS)
		return .
	return AI_STATUS_ON

/**
 * Turn being hit into an actual flee.
 *
 * flee_target needs both BB_BASIC_MOB_FLEEING and a live target, and the base
 * attacked handler sets neither: it only touches alert and status. Without this
 * the controller's reflex tier would look complete and never run.
 *
 * This is a reflex, so it must work with the sidecar down. Notifying the agent
 * is the last thing it does, and is optional.
 */
/datum/ai_controller/agent_social/on_pawn_attacked(atom/source, atom/attacker, damage)
	. = ..()
	if(attacker == pawn || QDELETED(attacker) || !isliving(attacker))
		return

	set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, attacker)
	set_blackboard_key(BB_AGENT_FLEE_UNTIL, world.time + AGENT_FLEE_DURATION)
	// A chosen seat is not resisted, so nothing else would get the NPC up to run.
	var/mob/living/living_pawn = pawn
	if(isliving(living_pawn) && living_pawn.buckled && living_pawn.buckled == blackboard[BB_AGENT_SEAT])
		agent_execute_stand(living_pawn)

	if(binding && !QDELETED(binding))
		var/list/detail = list("by" = "[attacker.name]")
		// A flurry of blows is one event with a count, not twelve that push out everything else.
		if(!binding.coalesce_event("attacked", detail))
			binding.mark_dirty("attacked", AGENT_EVENT_HIGH, detail)

/// An empty hand on us. In combat mode relay_attackers already reports it as an attack.
/datum/ai_controller/agent_social/proc/on_pawn_touched(datum/source, mob/living/user, list/modifiers)
	SIGNAL_HANDLER
	if(!isliving(user) || user == pawn || user.cmode)
		return
	note_stimulus(agent_touch_kind(user), user)

/datum/ai_controller/agent_social/proc/on_pawn_fed(datum/source, mob/feeder, obj/item/fed_with)
	SIGNAL_HANDLER
	if(!isliving(feeder) || feeder == pawn)
		return
	note_stimulus(AGENT_STIMULUS_FED, feeder, list("item" = "[fed_with?.name]"))

/// Someone did something to us. Addressed like a word said to our face; rough handling cannot wait.
/datum/ai_controller/agent_social/proc/note_stimulus(kind, mob/living/by, list/extra)
	if(!binding || QDELETED(binding) || QDELETED(by))
		return "unbound"
	var/list/detail = list("what" = kind, "by" = by.get_visible_name())
	if(extra)
		detail += extra
	// Felt, not seen: the NPC must not describe someone it cannot see.
	if(agent_is_hidden(by))
		detail["unseen"] = TRUE
	if(binding.coalesce_event("physical", detail))
		return "coalesced"
	// An agent's `use` on another agent is an empty-hand click, so the same loop cap as speech applies.
	var/from_another_agent = !isnull(SSagent_npc?.bindings?["[REF(by)]"])
	if(from_another_agent)
		if(!binding.agent_exchange_allowed(by))
			SSagent_npc?.note_agent_exchange_capped()
			binding.push_event("physical", AGENT_EVENT_LOW, detail)
			return "capped"
		binding.note_agent_exchange(by)
	else if(by.client)
		binding.reset_agent_exchanges()
	binding.note_candidate(by)
	var/urgency = (kind in list(AGENT_STIMULUS_GRABBED, AGENT_STIMULUS_SHOVED, AGENT_STIMULUS_STRUCK)) ? AGENT_EVENT_HIGH : AGENT_EVENT_LOW
	binding.mark_dirty("physical", urgency, detail, replenish = !from_another_agent)
	return "sent"

/// Someone holds an item out to us. Directed, like being spoken to; take accepts it.
/datum/ai_controller/agent_social/proc/on_item_offered(datum/source, mob/living/offerer, obj/offered_item)
	SIGNAL_HANDLER
	if(!isliving(offerer) || offerer == pawn)
		return
	note_stimulus(AGENT_STIMULUS_OFFERED, offerer, list("item" = "[offered_item?.name]"))

/// Off the seat, whoever did it. A seat we were pulled from is no longer one we chose.
/datum/ai_controller/agent_social/proc/on_unbuckled(datum/source, atom/movable/old_seat)
	SIGNAL_HANDLER
	if(blackboard[BB_AGENT_SEAT] == old_seat)
		clear_blackboard_key(BB_AGENT_SEAT)

/// After holding something out: tell the NPC if it was taken. One offer at a time, as the game allows.
/datum/ai_controller/agent_social/proc/watch_offer(obj/item/item)
	stop_watching_offer()
	if(QDELETED(item) || QDELETED(pawn))
		return
	watched_offer = WEAKREF(item)
	RegisterSignal(item, COMSIG_OBJ_HANDED_OVER, PROC_REF(on_offer_taken))
	RegisterSignal(pawn, COMSIG_LIVING_STOPPED_OFFERING_ITEM, PROC_REF(on_offer_ended))

/datum/ai_controller/agent_social/proc/stop_watching_offer()
	var/obj/item/item = watched_offer?.resolve()
	if(item)
		UnregisterSignal(item, COMSIG_OBJ_HANDED_OVER)
	watched_offer = null
	if(pawn)
		UnregisterSignal(pawn, COMSIG_LIVING_STOPPED_OFFERING_ITEM)

/// Ridden along with the next decision rather than buying one: a thank-you is the taker's to start.
/datum/ai_controller/agent_social/proc/on_offer_taken(obj/item/item, mob/living/taker, mob/living/offerer)
	SIGNAL_HANDLER
	if(binding && !QDELETED(binding) && isliving(taker))
		binding.push_event("offer_taken", AGENT_EVENT_LOW, list("by" = taker.get_visible_name(), "item" = "[item.name]"))
	stop_watching_offer()

/datum/ai_controller/agent_social/proc/on_offer_ended(datum/source)
	SIGNAL_HANDLER
	stop_watching_offer()

/// What an empty hand did, read from the intent it was used with. No intent is no evidence of harm.
/proc/agent_touch_kind(mob/living/user)
	var/intent_type = user.used_intent?.type
	if(!intent_type || ispath(intent_type, INTENT_HELP))
		return AGENT_STIMULUS_TOUCHED
	if(ispath(intent_type, INTENT_GRAB))
		return AGENT_STIMULUS_GRABBED
	if(ispath(intent_type, INTENT_DISARM))
		return AGENT_STIMULUS_SHOVED
	return AGENT_STIMULUS_STRUCK

/**
 * Is the pawn free to pursue an agent objective?
 *
 * Re-evaluated every plan. Any reflex condition suspends the objective rather
 * than cancelling it, so the agent is told what happened and can decide again.
 */
/datum/ai_controller/agent_social/proc/reflex_guard_clear()
	var/mob/living/living_pawn = pawn
	if(!isliving(living_pawn) || QDELETED(living_pawn))
		return FALSE
	if(living_pawn.stat >= UNCONSCIOUS)
		return FALSE
	if(living_pawn.body_position == LYING_DOWN)
		return FALSE
	if(blackboard[BB_BASIC_MOB_CURRENT_TARGET])
		return FALSE
	var/mob/living/carbon/carbon_pawn = living_pawn
	if(iscarbon(carbon_pawn) && (carbon_pawn.handcuffed || carbon_pawn.legcuffed))
		return FALSE
	return TRUE

/**
 * Cancel only the agent's own objective.
 *
 * CancelActions() finishes every running behavior, so using it to retarget
 * would also cancel an active resist or restraint break. Retargeting must not
 * be able to interrupt a reflex.
 */
/// Returns TRUE if something was actually cancelled.
/datum/ai_controller/agent_social/proc/cancel_agent_objective()
	. = FALSE
	if(!LAZYLEN(current_behaviors))
		return
	for(var/datum/ai_behavior/current_behavior as anything in current_behaviors)
		if(!istype(current_behavior, /datum/ai_behavior/agent_approach))
			continue
		var/list/arguments = list(src, FALSE)
		var/list/stored_arguments = behavior_args[current_behavior.type]
		if(stored_arguments)
			arguments += stored_arguments
		current_behavior.finish_action(arglist(arguments))
		. = TRUE

/// A faint typing bubble while a decision is in flight, so a player can see they were heard.
/datum/ai_controller/agent_social/proc/show_thinking(state)
	// Fainter than a player's, which also keeps the two appearances from being confused.
	var/static/mutable_appearance/thinking_indicator
	if(!thinking_indicator)
		thinking_indicator = mutable_appearance('icons/mob/talk.dmi', "default0", FLY_LAYER)
		thinking_indicator.alpha = 140
	var/atom/movable/body = pawn
	state = !!state
	if(QDELETED(body) || state == thinking)
		return
	thinking = state
	if(state)
		body.add_overlay(thinking_indicator)
	else
		body.cut_overlay(thinking_indicator)

/// Drop a threat we have finished running from, so the pawn can settle.
/datum/ai_controller/agent_social/proc/clear_threat()
	clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)
	clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)
	set_blackboard_key(BB_AGENT_FLEE_UNTIL, 0)
