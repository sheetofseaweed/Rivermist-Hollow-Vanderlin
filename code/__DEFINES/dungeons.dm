// -- Infinite dungeon system (see docs/superpowers/specs/2026-06-10-infinite-dungeons-design.md) --

// Room kinds for /datum/map_template/pocket/dungeon
#define DUNGEON_ROOM_ONESHOT "oneshot"
#define DUNGEON_ROOM_COMBAT "combat"
#define DUNGEON_ROOM_BREAK "break"

// Theme tags used to filter template pools
#define DUNGEON_THEME_BANDIT "bandit"
#define DUNGEON_THEME_WOLF "wolf"
#define DUNGEON_THEME_TENTACLE "tentacle"
#define DUNGEON_THEME_SWAMPGOB "swampgob"
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

// -- Roguelike crawler additions --

// Additional room kinds
#define DUNGEON_ROOM_BOSS "boss"
#define DUNGEON_ROOM_DESCENT "descent"

// Additional gate role
#define DUNGEON_GATE_DESCENT "descent"

// Path types (branching risk/reward)
#define DUNGEON_PATH_COMBAT "combat"
#define DUNGEON_PATH_TREASURE "treasure"
#define DUNGEON_PATH_HAZARD "hazard"
#define DUNGEON_PATH_ELITE "elite"
#define DUNGEON_PATH_SHORTCUT "shortcut"

/// Highest floor the floor-config registry guarantees a hand-authored config for;
/// beyond this, the deepest config is reused with a rising tier.
#define DUNGEON_MAX_DESIGNED_FLOOR 5

// -- Party & raid management --

// Join approval threshold for outsiders petitioning an at-rest party
#define DUNGEON_JOIN_APPROVAL_ANY "any"          // any single present member approves
#define DUNGEON_JOIN_APPROVAL_MAJORITY "majority"// >half of present members
#define DUNGEON_JOIN_APPROVAL_LEADER "leader"    // party leader only
/// Active approval mode
#define DUNGEON_JOIN_APPROVAL_MODE DUNGEON_JOIN_APPROVAL_ANY

/// A muster auto-resolves (leader/threshold force-advance) after this long waiting
#define DUNGEON_MUSTER_TIMEOUT (45 SECONDS)
/// Grace after which a disconnected member stops gating a muster
#define DUNGEON_MUSTER_SSD_GRACE (20 SECONDS)

// -- In-run currency (motes) & meta-currency (echoes) --

/// Base motes a normal guardian drops on death
#define DUNGEON_MOTE_GUARDIAN_BASE 10
/// Extra motes per floor
#define DUNGEON_MOTE_FLOOR_BONUS 5
/// Elite guardian mote multiplier
#define DUNGEON_MOTE_ELITE_MULT 3
/// Fraction of unspent motes that converts to echoes when a run is banked
#define DUNGEON_ECHO_CONVERSION 0.25
/// Save-manager file name for per-ckey dungeon meta progression
#define DUNGEON_SAVE_FILE "dungeon"

// -- Encounter director: combat styles for spawn-entry tagging --

#define DUNGEON_STYLE_MELEE "melee"
#define DUNGEON_STYLE_RANGED "ranged"
#define DUNGEON_STYLE_CASTER "caster"

/// % chance a trait-eligible room rolls a room trait
#define DUNGEON_ROOM_TRAIT_CHANCE 50

/// Faction shared by every dungeon-native guardian (prevents infighting)
#define FACTION_DUNGEON "dungeon"
/// Channel time to work a dungeon gate open (players only)
#define DUNGEON_GATE_TRAVERSE_TIME (2 SECONDS)
/// Grace after a full party wipe before the dungeon ends the run
#define DUNGEON_WIPE_GRACE (30 SECONDS)

// -- Roguelike Heart: door rewards & stretch deck --

/// What a forward gate promises for clearing the room beyond it
#define DUNGEON_REWARD_BOON "boon"
#define DUNGEON_REWARD_MOTES "motes"
#define DUNGEON_REWARD_LOOT "loot"
#define DUNGEON_REWARD_HEAL "heal"
#define DUNGEON_REWARD_VAULT "vault"

/// Weighted remainder of the stretch deck after guarantees (VAULT is guarantee-only)
#define DUNGEON_DECK_REMAINDER_WEIGHTS list(DUNGEON_REWARD_MOTES = 40, DUNGEON_REWARD_HEAL = 25, DUNGEON_REWARD_LOOT = 20, DUNGEON_REWARD_BOON = 15)

/// How many recent combat templates a run remembers and avoids repeating
#define DUNGEON_RECENT_TEMPLATE_MEMORY 3

// -- Roguelike Heart: boon rarity --

#define DUNGEON_BOON_COMMON "common"
#define DUNGEON_BOON_RARE "rare"
#define DUNGEON_BOON_EPIC "epic"
