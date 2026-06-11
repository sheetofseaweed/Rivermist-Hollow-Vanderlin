// -- Infinite dungeon system (see docs/superpowers/specs/2026-06-10-infinite-dungeons-design.md) --

// Room kinds for /datum/map_template/pocket/dungeon
#define DUNGEON_ROOM_ONESHOT "oneshot"
#define DUNGEON_ROOM_COMBAT "combat"
#define DUNGEON_ROOM_BREAK "break"

// Theme tags used to filter template pools
#define DUNGEON_THEME_BANDIT "bandit"
#define DUNGEON_THEME_WOLF "wolf"
#define DUNGEON_THEME_TENTACLE "tentacle"
#define DUNGEON_THEME_TEST "test"

// Gate roles
#define DUNGEON_GATE_FORWARD "forward"
#define DUNGEON_GATE_BACK "back"

// Entrance kinds
#define DUNGEON_ENTRANCE_ONESHOT "oneshot"
#define DUNGEON_ENTRANCE_INFINITE "infinite"

/// Idle timeout for an uncleared dungeon nobody is inside
#define DUNGEON_DEFAULT_IDLE_TIMEOUT (10 MINUTES)
/// How long a cleared, empty dungeon lingers before collapsing
#define DUNGEON_CLEARED_IDLE_TIMEOUT (3 MINUTES)
/// How long an entrance stays dormant after its dungeon collapses
#define DUNGEON_ENTRANCE_COOLDOWN (20 MINUTES)
/// Combat rooms cleared between break rooms in an infinite run
#define DUNGEON_RUN_STRETCH_LENGTH 5
/// A run force-collapses after this long with no client-bearing occupant
#define DUNGEON_RUN_ABANDON_TIMEOUT (30 MINUTES)
