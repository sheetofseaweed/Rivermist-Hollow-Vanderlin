/// This mob spawner creates its corpse as soon as it initializes.
#define CORPSE_INSTANT 1
/// This mob spawner waits for GAME_STATE_PLAYING before creating its corpse.
#define CORPSE_ROUNDSTART 2

/// The ghost role may use the player's preferred species.
#define GHOSTROLE_TAKE_PREFS_SPECIES (1 << 0)
/// The ghost role may use the player's preferred appearance, excluding their name.
#define GHOSTROLE_TAKE_PREFS_APPEARANCE (1 << 1)

/// A held-item override value which leaves the outfit's existing item unchanged.
#define NO_REPLACE 0

/// A falsy return from create() that explicitly cancels the spawning process.
#define CANCEL_SPAWN FALSE
