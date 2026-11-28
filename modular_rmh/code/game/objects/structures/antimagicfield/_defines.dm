/// Anti-magic field geometry and lifecycle constants.
#define ANTI_MAGIC_FIELD_STATIONARY_WIDTH 8
#define ANTI_MAGIC_FIELD_STATIONARY_HEIGHT 8
#define ANTI_MAGIC_FIELD_THROWABLE_WIDTH 4
#define ANTI_MAGIC_FIELD_THROWABLE_HEIGHT 4
#define ANTI_MAGIC_FIELD_THROWABLE_BUILD_TIME (5 SECONDS)
#define ANTI_MAGIC_FIELD_RECOVERY_TIME (5 SECONDS)

/// Propagation modes. GEOMETRIC is implemented in this refactor.
/// ATMOSPHERIC is reserved until the project's SSair connectivity API is integrated.
#define ANTI_MAGIC_FIELD_PROPAGATION_GEOMETRIC 1
#define ANTI_MAGIC_FIELD_PROPAGATION_ATMOSPHERIC 2

/// A max_active_fields value of zero means unlimited active fields.
