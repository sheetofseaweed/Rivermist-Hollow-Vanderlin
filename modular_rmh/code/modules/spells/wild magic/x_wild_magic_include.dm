
// --- CONFIG ---

// --- CORE ---
#define WILD_CHANCE 100
#define WILD_CD 1 SECONDS
#define WILD_SHAPESHIFT_DURATION 30 SECONDS

// --- HELPERS ---
#define WILD_TARGET_SELF 1
#define WILD_TARGET_CAST_ON 2
#define WILD_TARGET_RANDOM_LIVING 3
#define WILD_TARGET_TURF_OF_CAST_ON 4
#define WILD_TARGET_TURF_OF_CASTER 5

// --- LOAD ORDER ---
#include "wild_magic_job_list.dm"
#include "wild_magic_list.dm"
#include "wild_magic_core.dm"
