
///Whether a mob is a werewolf. Returns the werewolf antag datum if found.
#define IS_WEREWOLF(mob) (mob?.mind?.has_antag_datum(/datum/antagonist/werewolf))

// Rage thresholds for /datum/rage/werewolf
#define WW_RAGE_LOW "25"
#define WW_RAGE_MEDIUM "50"
#define WW_RAGE_HIGH "75"
#define WW_RAGE_CRITICAL "100"

// Transformation rules
#define WW_FORCED_TRANSFORM_NIGHT_COUNT 3
#define WW_TRANSFORMATION_COOLDOWN 5 MINUTES
#define WW_TRANSFORMATION_AGONY_INTERVAL (1.5 SECONDS)
// Stun cover for the transformation animation - derived from the agony sleeps so it can't outlive a failed transform by much.
#define WW_TRANSFORMATION_LOCKDOWN (WW_TRANSFORMATION_AGONY_INTERVAL * 2 + 0.5 SECONDS)
#define WW_PENDING_TRANSFORM_REMINDER 30 SECONDS
#define WW_RESTLESS_STRESS_LIGHT 2
#define WW_RESTLESS_STRESS_MEDIUM 4
#define WW_RESTLESS_STRESS_HEAVY 6
#define WW_LAIR_CREATION_TIME 8 SECONDS

// Objective tuning
#define WW_BREED_OBJECTIVE_MIN 5
#define WW_BREED_OBJECTIVE_MAX 10
#define WW_HUNT_OBJECTIVE_MIN 4
#define WW_HUNT_OBJECTIVE_MAX 8
#define WW_SLAY_OBJECTIVE_MIN 4
#define WW_SLAY_OBJECTIVE_MAX 8
#define WW_CONVERT_OBJECTIVE_MIN 3
#define WW_CONVERT_OBJECTIVE_MAX 4
#define WW_CONTRACT_OBJECTIVE_TARGET 400
#define WW_CONTRACT_SCORE_BASE 5
#define WW_CONTRACT_SCORE_STEP 10
#define WW_TRAP_OBJECTIVE_TARGET 4
#define WW_TRAP_ORGASM_TRIGGER 10
#define WW_TRAP_TIME_TRIGGER 10 MINUTES
#define WW_TRAP_RESET_COOLDOWN 2 MINUTES

// Voluntary conversion tuning
#define WW_CREAMPIE_CONVERSION_CHANCE 30
#define WW_CREAMPIE_KNOT_MULTIPLIER 2
#define WW_CONVERSION_PROMPT_TIMEOUT 20 SECONDS
#define WW_VOLUNTARY_BITE_COOLDOWN 6 MINUTES
