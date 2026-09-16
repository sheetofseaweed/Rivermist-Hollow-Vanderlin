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

/// Response bodies larger than this are discarded unparsed.
#define AGENT_MAX_RESPONSE_BYTES 65536
/// Registry ceiling. Registration past this is refused and logged.
#define AGENT_MAX_REGISTERED_PAWNS 32
/// How long a decision stays valid. Server owned; the sidecar cannot extend it.
#define AGENT_DEFAULT_DEADLINE (15 SECONDS)
/// Requests started per fire, so one fire cannot serialise the whole registry.
#define AGENT_MAX_STARTS_PER_FIRE 4

/// Floor between two requests for one pawn. Stops result-driven request loops.
#define AGENT_MIN_REQUEST_INTERVAL (2 SECONDS)
/// Consecutive transport failures before a pawn stops retrying on its own.
#define AGENT_MAX_CONSECUTIVE_FAILURES 3
/// Base backoff after a transport failure. Multiplied by the failure count.
#define AGENT_FAILURE_BACKOFF (5 SECONDS)

/// Reserved per request before sending, then settled against reported usage.
#define AGENT_TOKEN_ESTIMATE 2000
/// Reported usage outside 0..this is treated as a schema violation.
#define AGENT_MAX_TOKENS_PER_RESPONSE 1000000

/// How long an orphaned transport is polled before its result is written off.
#define AGENT_DRAIN_TIMEOUT (60 SECONDS)
/// Orphaned transports polled per fire.
#define AGENT_MAX_DRAIN_PER_FIRE 8

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

/// Atom the current objective is aimed at. Resolved from a handle, never raw.
#define BB_AGENT_OBJECTIVE_TARGET "BB_agent_objective_target"
/// An objective that has not finished by now is abandoned as unreachable.
#define AGENT_OBJECTIVE_TIMEOUT (30 SECONDS)
/// Tiles at which approach counts as arrived, and use may reach.
#define AGENT_REACH_DISTANCE 1

/// Low urgency events wait for the in-flight request to land.
#define AGENT_EVENT_LOW 1
/// High urgency events abandon the in-flight request and force a new one.
#define AGENT_EVENT_HIGH 2
/// Per-pawn event ring size. Overflow drops oldest low-urgency entries first.
#define AGENT_MAX_EVENTS_PER_PAWN 12
