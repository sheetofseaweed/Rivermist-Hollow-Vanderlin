/// Agent NPC wire protocol. Bump on any request or response shape change.
#define AGENT_PROTOCOL_VERSION 1

/// Binding is registered and may start a request.
#define AGENT_BINDING_IDLE 1
/// Binding has a request in flight.
#define AGENT_BINDING_PENDING 2
/// Binding is revoked. It starts nothing and accepts nothing.
#define AGENT_BINDING_DISABLED 3

/// Terminal states for an executed action.
#define AGENT_RESULT_SUCCEEDED "succeeded"
/// Dispatched, but the action has no checkable postcondition.
#define AGENT_RESULT_UNVERIFIED "accepted_unverified"
#define AGENT_RESULT_REJECTED "rejected"
#define AGENT_RESULT_FAILED "failed"
#define AGENT_RESULT_INTERRUPTED "interrupted"
#define AGENT_RESULT_EXPIRED "expired"

/// Reasons a response was refused before execution. Logged, never executed.
#define AGENT_REFUSE_GENERATION "stale_generation"
#define AGENT_REFUSE_REVISION "stale_revision"
#define AGENT_REFUSE_UNKNOWN "unknown_request"
#define AGENT_REFUSE_CONSUMED "already_consumed"
#define AGENT_REFUSE_DEADLINE "deadline_passed"
#define AGENT_REFUSE_SESSION "session_mismatch"
#define AGENT_REFUSE_PROTOCOL "protocol_mismatch"
#define AGENT_REFUSE_TRANSPORT "transport_error"
#define AGENT_REFUSE_MALFORMED "malformed_body"
#define AGENT_REFUSE_OVERSIZED "oversized_body"
#define AGENT_REFUSE_PAWN "pawn_unavailable"
#define AGENT_REFUSE_SCHEMA "schema_invalid"
/// The sidecar reached the model but could not get a usable action out of it.
#define AGENT_REFUSE_MODEL "model_refusal"

/// Response bodies larger than this are discarded unparsed.
#define AGENT_MAX_RESPONSE_BYTES 65536
/// Registry ceiling. Registration past this is refused and logged.
#define AGENT_MAX_REGISTERED_PAWNS 32
/**
 * How long a decision stays valid. Server owned; the sidecar cannot extend it.
 *
 * This is the top of a ladder that must stay in this order:
 *
 *   sidecar upstream call  <  AGENT_TRANSPORT_TIMEOUT_SECONDS  <  this
 *
 * Inverted, a slow model answers after DM has stopped listening: the sidecar
 * logs a 200 and the game shows nothing. That is exactly what happened on
 * 2026-09-17, when the sidecar allowed the model 30s against a 15s deadline.
 * The sidecar derives its own budget from the deadline_ds carried on the wire,
 * so raising this value carries the rest of the ladder with it.
 */
#define AGENT_DEFAULT_DEADLINE (25 SECONDS)
/// Requests started per fire, so one fire cannot serialise the whole registry.
#define AGENT_MAX_STARTS_PER_FIRE 4

/// Floor between two requests for one pawn. Stops result-driven request loops.
#define AGENT_MIN_REQUEST_INTERVAL (2 SECONDS)
/// Consecutive transport failures before a pawn stops its ordinary retries.
#define AGENT_MAX_CONSECUTIVE_FAILURES 3
/// Base backoff after a transport failure. Multiplied by the failure count.
#define AGENT_FAILURE_BACKOFF (5 SECONDS)

/**
 * Circuit breaker cooldown.
 *
 * Past the failure limit a pawn stops its ordinary retries, then sends exactly
 * one probe per cooldown. Without a probe the limit is a grave: no request can
 * start, so none can succeed, so the failure count never falls and the NPC is
 * mute for the rest of the round. The cooldown grows with each failed probe.
 */
#define AGENT_BREAKER_COOLDOWN (60 SECONDS)
/// Ceiling on the growing cooldown, so a long outage cannot park a pawn forever.
#define AGENT_BREAKER_COOLDOWN_MAX (10 MINUTES)

/// Reserved per request, settled against usage. Measured 2026-09-18: 3540 average, 4751 peak.
#define AGENT_TOKEN_ESTIMATE 4000
/// Reported usage outside 0..this is treated as a schema violation.
#define AGENT_MAX_TOKENS_PER_RESPONSE 1000000

/// Recent values kept per measured quantity. Bounds cost; percentiles are
/// therefore about recent behaviour, not the whole round.
#define AGENT_STAT_SAMPLES 64

/// How long an orphaned transport is polled before its result is written off.
#define AGENT_DRAIN_TIMEOUT (60 SECONDS)
/// Orphaned transports polled per fire.
#define AGENT_MAX_DRAIN_PER_FIRE 8
/**
 * Ceiling on ALL outstanding work: live requests plus draining transports.
 *
 * max_concurrent bounds decisions we are waiting on. It does not bound work
 * still running at the provider after we abandoned it, which is what draining
 * holds. Without this, repeated supersession frees decision capacity while real
 * outstanding operations keep climbing.
 */
#define AGENT_MAX_OUTSTANDING 12

/// Seconds after which rust-g abandons the HTTP call itself.
/// Verified present in the shipped rust_g.dll beside struct RequestOptions.
/// Must stay below AGENT_DEFAULT_DEADLINE; see the ladder documented there.
#define AGENT_TRANSPORT_TIMEOUT_SECONDS 22

/// world.time until which a scared agent NPC keeps running. Refreshed per hit.
#define BB_AGENT_FLEE_UNTIL "BB_agent_flee_until"
/// How long one attack keeps the pawn fleeing.
#define AGENT_FLEE_DURATION (15 SECONDS)
/// Beyond this, and past the flee window, the threat is considered lost.
#define AGENT_FLEE_SIGHT_RANGE 7
/// Gap between attempts to register a pawn that spawned before the subsystem.
#define AGENT_REGISTER_RETRY (5 SECONDS)

/// Tiles of the observation. Also the range handles are drawn from.
#define AGENT_VIEW_RANGE 7
/// Cap on entities in one observation, nearest first.
#define AGENT_MAX_ENTITIES 40
/// Structures and machines get their own cap, so a furnished room cannot crowd out people.
#define AGENT_MAX_STRUCTURES 12
/// Same-named fixtures past this many are counted, not listed. Ten tables are one table.
#define AGENT_STRUCTURE_HANDLES_PER_NAME 2
/// Garments listed per person seen. Outermost first, as examine orders them.
#define AGENT_MAX_WORN_SHOWN 8
/// Item names listed from the NPC's own bags and pouches, across all of them.
#define AGENT_MAX_STORED_SHOWN 12
/// Letters of an emote passed on. Custom emotes can run long; every letter is paid for.
#define AGENT_EMOTE_TEXT_MAX 400

/// Atom the current objective is aimed at. Resolved from a handle, never raw.
#define BB_AGENT_OBJECTIVE_TARGET "BB_agent_objective_target"
/// An objective that has not finished by now is abandoned as unreachable.
#define AGENT_OBJECTIVE_TIMEOUT (30 SECONDS)
/// Tiles at which approach counts as arrived, and use may reach.
#define AGENT_REACH_DISTANCE 1
/// Per-controller result of the last `use`. Behaviors are singletons, so
/// anything pawn-scoped must live on the blackboard, never on the behavior.
#define BB_AGENT_PICKED_UP "BB_agent_picked_up"
/// Per-controller outcome of the last `touch`, an agent_result list. On the blackboard for the same reason.
#define BB_AGENT_TOUCH_RESULT "BB_agent_touch_result"

/**
 * Self-driven decisions allowed after one external interaction.
 *
 * Without continuation an NPC completes one step and stops, because results
 * deliberately do not schedule work. Without a cap, every reply produces a
 * result which produces a reply and nothing external is ever needed. This is
 * the bound between those two failures.
 */
#define AGENT_CONTINUATION_BUDGET 4
/// An interaction lapses after this long regardless of remaining budget.
#define AGENT_CONTINUATION_WINDOW (2 MINUTES)

/// Where admin-authored profiles live between rounds. Hand-editable on purpose.
#define AGENT_PROFILE_FILE "data/agent_profiles.json"
/// Caps on admin-authored profile text. Every character is sent on every
/// request, so an unbounded persona is a permanent per-decision token cost.
#define AGENT_PROFILE_LABEL_MAX 48
#define AGENT_PROFILE_TEXT_MAX 1000
/// Other names an NPC answers to, like a Cyrillic spelling. Each is matched on every line heard.
#define AGENT_MAX_ALIASES 4
/// Attach targets are drawn from the admin's own view rather than the world.
#define AGENT_ATTACH_RANGE 7

/**
 * Within this many tiles, speech is assumed to be aimed at us.
 *
 * The whole directedness test errs toward hearing. A wasted decision costs a
 * fraction of a penny; an NPC that ignores a player talking to it reads as
 * broken, which is far more expensive.
 */
#define AGENT_DIRECT_SPEECH_RANGE 3

/**
 * How far a whisper carries to its intended listener.
 *
 * send_speech sets message_range to 1 for a whisper and then adds
 * EAVESDROP_EXTRA_RANGE on top, handing anyone in that extra band a stars()'d
 * copy. So hearing a whisper proves we were close enough to overhear it, not
 * that it was meant for us. Distance is what tells the two apart.
 */
#define AGENT_WHISPER_INTENDED_RANGE 1

/**
 * How a heard line was classified.
 *
 * Three states rather than two, because "we think this was ours" and "we have
 * no idea" are different claims and should not be recorded as the same one.
 * Ambiguous still wakes the NPC today; the distinction is what lets an
 * attention budget rate-limit it later without silencing real address.
 */
#define AGENT_SPEECH_DIRECTED "directed"
#define AGENT_SPEECH_AMBIGUOUS "ambiguous"
#define AGENT_SPEECH_OVERHEARD "overheard"

/// What a routed line was. Speech and emotes share one route, rations and caps.
#define AGENT_LINE_SPEECH "speech"
#define AGENT_LINE_EMOTE "emote"

/// Something done to the NPC's body. The last three are rough and cannot wait for a reply in flight.
#define AGENT_STIMULUS_TOUCHED "touched"
#define AGENT_STIMULUS_FED "fed"
#define AGENT_STIMULUS_GRABBED "grabbed"
#define AGENT_STIMULUS_SHOVED "shoved"
#define AGENT_STIMULUS_STRUCK "struck"

/// Ways the touch action may lay a hand on someone. Tap is the default.
#define AGENT_TOUCH_TAP "tap"
#define AGENT_TOUCH_HUG "hug"
#define AGENT_TOUCH_HEADPAT "headpat"
/// Help someone lying down: the game's own shake, which also rouses and stands them.
#define AGENT_TOUCH_HELP "help"

/// Scripts a Latin name can be matched against. Anything else and a failed
/// match means nothing, so it must never count as evidence against the NPC.
#define AGENT_SCRIPT_LATIN "latin"
#define AGENT_SCRIPT_CYRILLIC "cyrillic"
#define AGENT_SCRIPT_MIXED "mixed"
#define AGENT_SCRIPT_OTHER "other"
#define AGENT_SCRIPT_NONE "none"

/**
 * The bound on erring toward hearing.
 *
 * Ambiguous speech still wakes an NPC, because silence is the worse failure.
 * Unbounded, though, a busy tavern is an unlimited stream of paid decisions:
 * one pawn answering ambiguous chatter can outspend a whole round.
 *
 * Directed speech and attacks ignore both of these entirely. Only lines we
 * genuinely could not classify are rationed.
 *
 * **These two numbers are starting points for measurement, not balance.** The
 * telemetry counts ambiguous requests taken and deferred; tune from that.
 */
#define AGENT_AMBIGUOUS_INTERVAL (12 SECONDS)
#define AGENT_AMBIGUOUS_ROUND_LIMIT 40
/// One NPC's share of the shared round limit, so a busy room cannot spend it for everyone.
#define AGENT_AMBIGUOUS_PAWN_LIMIT 15

/// Decisions one agent's lines may buy another before they are buffered. Two agents otherwise loop forever.
#define AGENT_MAX_AGENT_EXCHANGES 3
/// A quiet spell this long resets that count, so two NPCs may chat again later.
#define AGENT_AGENT_EXCHANGE_WINDOW (5 MINUTES)

/// How long a partner's line needs no name to count as a reply. Shorter than the continuation window.
#define AGENT_REPLY_WINDOW (30 SECONDS)

/// How near a player must be to turn to an NPC, and to keep speaking to it.
#define AGENT_FOCUS_RANGE 7
/// How long an unused Talk To lasts. Each line renews it, so it only lapses in silence.
#define AGENT_FOCUS_DURATION (2 MINUTES)

/// Letters sampled to decide a line's script. Reading every letter cost 4.3 ms per NPC, measured.
#define AGENT_SCRIPT_SAMPLE 64
/// Bytes, not letters: Cyrillic is two bytes a letter, so 32 of those.
#define AGENT_NAME_WORD_MAX 64
/// Word positions searched for a name, half from each end. Names are said at a line's edges.
#define AGENT_NAME_WORDS_MAX 48

/// How firmly a line addresses someone by name.
#define AGENT_NAMED_NONE 0
/// The name somewhere in the middle, which is usually talk ABOUT someone.
#define AGENT_NAMED_WEAK 1
/// A vocative, the first or last word, or the whole name.
#define AGENT_NAMED_STRONG 2

/// Shorter than this and a folded name is too generic to match on.
#define AGENT_FOLD_MIN_LENGTH 4
/// Russian case endings are short: Исааку, Исааком. Allow that much trailing.
#define AGENT_FOLD_MAX_SUFFIX 3

/// Low urgency events wait for the in-flight request to land.
#define AGENT_EVENT_LOW 1
/// High urgency events abandon the in-flight request and force a new one.
#define AGENT_EVENT_HIGH 2
/// Per-pawn event ring size. Overflow drops oldest low-urgency entries first.
#define AGENT_MAX_EVENTS_PER_PAWN 12
