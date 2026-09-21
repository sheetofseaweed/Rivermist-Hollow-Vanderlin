/**
 * # Agent NPC telemetry
 *
 * Measured, not estimated. Every latency and cost figure in the design
 * documents is a guess; nothing has ever been recorded from a live round.
 *
 * The two latencies are kept apart because they have different fixes. Queue
 * wait is ours: pacing, concurrency and backoff. Round trip is the provider's.
 * Added together they are the delay a player actually feels, and knowing which
 * half dominates is the whole point of separating them.
 *
 * Requests that hit the deadline are deliberately absent. They never reach
 * consume_pass, and recording them would inject a constant equal to the
 * deadline into the round trip distribution. They are counted as
 * AGENT_REFUSE_DEADLINE in refusal_counts instead, which is where to look if
 * the decision count seems low against the number of requests started.
 */

/**
 * One measured quantity.
 *
 * Lifetime count, total and range, plus a bounded ring of recent values. The
 * ring is what makes a percentile possible without keeping every sample.
 */
/datum/agent_stat
	var/count = 0
	var/sum = 0
	var/lowest = 0
	var/highest = 0
	/// Newest last. Bounded, so percentiles describe recent behaviour.
	var/list/samples

/datum/agent_stat/New()
	. = ..()
	samples = list()

/datum/agent_stat/Destroy(force, ...)
	samples = null
	return ..()

/**
 * Record one observation.
 *
 * Non-numbers are refused rather than coerced. In DM `null < 5` is true and
 * `sum += null` is silent, so one bad caller would quietly poison the range.
 */
/datum/agent_stat/proc/record(value)
	if(!isnum(value))
		return FALSE
	if(!count || value < lowest)
		lowest = value
	if(!count || value > highest)
		highest = value
	count++
	sum += value
	samples += value
	if(length(samples) > AGENT_STAT_SAMPLES)
		samples.Cut(1, 2)
	return TRUE

/datum/agent_stat/proc/mean()
	return count ? (sum / count) : 0

/// Nearest-rank percentile over the retained samples, not the whole lifetime.
/datum/agent_stat/proc/percentile(fraction)
	if(!length(samples))
		return 0
	var/list/ordered = sortTim(samples.Copy(), GLOBAL_PROC_REF(cmp_numeric_asc))
	var/index = CEILING(length(ordered) * fraction, 1)
	return ordered[clamp(index, 1, length(ordered))]

/// Deciseconds, to one decimal. Raw ticks mean nothing to an operator.
/datum/agent_stat/proc/summary_ds()
	if(!count)
		return "none"
	return "n=[count] avg [round(mean() / 10, 0.1)]s p95 [round(percentile(0.95) / 10, 0.1)]s max [round(highest / 10, 0.1)]s"

/datum/agent_stat/proc/summary_plain()
	if(!count)
		return "none"
	return "n=[count] avg [round(mean(), 1)] p95 [percentile(0.95)] max [highest]"

/// Round-scoped counters. One per subsystem run, cleared only by a new run.
/datum/agent_telemetry
	/// Requests that came back and were consumed, refused or not.
	var/decisions = 0
	/// Lone requests sent after the breaker opened. Counted, never timed: their
	/// wait is the cooldown, which says nothing about pacing.
	var/breaker_probes = 0
	/// Decisions bought by speech we could not classify, and lines that wanted
	/// one and were rationed. The ratio is what the ambiguous limits tune from.
	var/ambiguous_requests = 0
	var/ambiguous_deferred = 0
	/// Queued to sent.
	var/datum/agent_stat/queue_wait
	/// Sent to consumed.
	var/datum/agent_stat/round_trip
	/**
	 * Reported token usage.
	 *
	 * Only responses that actually reported usage are recorded. A gap between
	 * this count and `decisions` is the provider staying silent, which is worth
	 * seeing rather than averaging into a misleadingly low cost per decision.
	 */
	var/datum/agent_stat/tokens
	/**
	 * Observation built to objective finished. Staleness at execution.
	 *
	 * Objectives only. Say and emote run the moment the reply lands, so their
	 * age is the round trip, which is already measured on its own. Mixing the
	 * two would hide the long tail that actually matters.
	 */
	var/datum/agent_stat/observation_age
	/// Steps completed per self-driven chain.
	var/datum/agent_stat/chain_depth
	/// Action name the model chose -> count. Recorded before authorisation, so
	/// asking for things the profile forbids stays visible.
	var/list/action_counts
	/// Terminal state -> count.
	var/list/result_counts

/datum/agent_telemetry/New()
	. = ..()
	queue_wait = new()
	round_trip = new()
	tokens = new()
	observation_age = new()
	chain_depth = new()
	action_counts = list()
	result_counts = list()

/datum/agent_telemetry/Destroy(force, ...)
	QDEL_NULL(queue_wait)
	QDEL_NULL(round_trip)
	QDEL_NULL(tokens)
	QDEL_NULL(observation_age)
	QDEL_NULL(chain_depth)
	action_counts = null
	result_counts = null
	return ..()

/// One consumed reply, whatever it turned out to say.
/datum/agent_telemetry/proc/note_decision(latency_ds, tokens_used)
	decisions++
	round_trip.record(latency_ds)
	if(tokens_used > 0)
		tokens.record(tokens_used)

/datum/agent_telemetry/proc/note_action(action_name)
	if(!action_name)
		return FALSE
	action_counts[action_name] = (action_counts[action_name] || 0) + 1
	return TRUE

/datum/agent_telemetry/proc/note_result(state_name)
	if(!state_name)
		return FALSE
	result_counts[state_name] = (result_counts[state_name] || 0) + 1
	return TRUE

/// Format a name -> count list for the status readout.
/datum/agent_telemetry/proc/format_counts(list/counts)
	if(!length(counts))
		return "none"
	var/list/parts = list()
	for(var/key in counts)
		parts += "[key]=[counts[key]]"
	return parts.Join(", ")
