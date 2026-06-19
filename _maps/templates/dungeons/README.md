# Dungeon Mapping Guide

How to make content for the dungeon system — both **one-shot dungeons** (open from an
overworld entrance, clear it, loot it, leave, it collapses) and **infinite dungeons**
(endless branching delves with floors, bosses, break rooms, and a meta-progression).

You do two things to add content:

1. **Draw a room** as a `.dmm` map template in `_maps/templates/dungeons/`.
2. **Register it** as a `/datum/map_template/pocket/dungeon` subtype in `code/modules/dungeons/dungeon_template.dm`.

Everything else (loading, collapsing, mob tracking, loot, currency, party logic) is automatic.

---

## 1. The golden rules

- **Every dungeon room turf must use the area `/area/pocket_dimension/dungeon`.** Not a normal
  area. The system finds the room by its turfs; the wrong area breaks lighting, collapse, and ejection.
- **Wall the room in.** The loader seals a 1-tile padding ring around your room with an
  indestructible boundary, but your room should still have its own outer walls
  (`/turf/closed/wall/mineral/wood`, mineral walls, whatever fits the theme).
- **Keep rooms reasonably small** (the test maps are 7×7). Big rooms cost more reserved space.
  Width/height are read automatically from the `.dmm` — you don't declare them.
- **Place landmarks, not hardcoded structures**, for anything the system manages (entries,
  exits, gates, guardians, loot, shrines). Landmarks are invisible markers that the loader
  replaces with the real thing at load time.
- **Native mobs die with the room.** Hostile mobs you map in (or spawn from guardian markers)
  are deleted when the dungeon collapses — they never spill onto the overworld. Players, pets,
  and dropped items are ejected safely.

---

## 2. Landmarks reference

All are placed in the map editor like any `/obj/effect/landmark`. They are invisible in-game.

### Core (from the pocket-dimension base — every room needs these where noted)

| Landmark | Purpose | Required in |
|---|---|---|
| `/obj/effect/landmark/pocket_dimension/entry` | Where mobs arrive when they enter/are dropped in | **Every room** (falls back to room center if missing) |
| `/obj/effect/landmark/pocket_dimension/exit` | Becomes the return seam back to the overworld | One-shot rooms, break rooms, descent rooms. **Never** in combat/boss rooms |
| `/obj/effect/landmark/pocket_dimension/drop_spot` | Preferred tile where shoved/dragged-in things land | Optional |

### Dungeon-specific

| Landmark | Becomes | Notes |
|---|---|---|
| `/obj/effect/landmark/dungeon/guardian` | A hostile mob from `mob_pool` | Set `mob_pool` (weighted list), `spawn_chance`, `force_elite`. Dying guardians are tracked; room "clears" when all are dead |
| `/obj/effect/landmark/dungeon/guardian/boss` | A floor boss | Pulls from the run's **floor config** boss pool by default (`use_floor_boss_pool = TRUE`), or its own `mob_pool` if FALSE. Boss death opens the descent |
| `/obj/effect/landmark/dungeon/guardian/keyholder` | A guardian that drops a `dungeon_key` on death | Set `key_id` to match a key-locked gate in the same room |
| `/obj/effect/landmark/dungeon/loot` | A sealed reward cache | Unlocks when the room is cleared. Uses the template's `loot_table_type` |
| `/obj/effect/landmark/dungeon/gate` | A forward passage to the next room | Default `path_type = combat`. See gate variants below |
| `/obj/effect/landmark/dungeon/gate/back` | The way back to the previous room | Put one in every combat/boss room so the party can retreat |
| `/obj/effect/landmark/dungeon/gate/treasure` | Forward gate biased to a low-danger, high-reward room | |
| `/obj/effect/landmark/dungeon/gate/elite` | Forward gate biased to a champion (elite) room | |
| `/obj/effect/landmark/dungeon/gate/hazard` | Forward gate biased to a harder, richer room | |
| `/obj/effect/landmark/dungeon/shrine` | A break-room vendor (spend motes on heals/boons/caches/banking) | Break/descent rooms only |

**Guardian markers spawn from a weighted list.** Example, set on the marker instance in the map editor's variable edit, or as a subtype in code:

```dm
/obj/effect/landmark/dungeon/guardian/my_wolves
	mob_pool = list(/mob/living/simple_animal/hostile/retaliate/wolf = 10, /mob/living/simple_animal/hostile/retaliate/bear = 2)
```

**Gate variants** only change which kind of room they roll toward and the danger/reward shown
on examine. A forward gate stays **sealed until the room is cleared**; back gates are always open.

**Key-locked gates:** set `requires_key = TRUE` and a `key_id` on a gate marker, then place a
`/obj/effect/landmark/dungeon/guardian/keyholder` with the same `key_id` in that room. Players
must kill the keyholder, grab the dropped key, and apply it to the gate.

You can also drop a plain `/obj/effect/spawner/map_spawner` in a room for cosmetic/loot variety —
it rolls at load time like anywhere else in the game.

---

## 3. Registering a room template

Add a subtype to `code/modules/dungeons/dungeon_template.dm`. The base sets sane defaults
(collapse lifecycle, idle timeout, the dungeon instance type) — you only set what differs.

```dm
/datum/map_template/pocket/dungeon/wolf_den
	name = "Wolf Den"
	id = "dungeon_wolf_den"                                  // unique, referenced by id
	mappath = "_maps/templates/dungeons/wolf_den.dmm"
	theme = DUNGEON_THEME_WOLF
	room_kind = DUNGEON_ROOM_ONESHOT
	difficulty_tier = 1
	dungeon_weight = 10                                      // pick weight within its pool
	loot_table_type = /datum/loot_table/mining_cache         // used by loot caches
	gate_hint = "You smell wet fur and old blood."           // shown on gates that lead here
```

Templates auto-register at init (every `/datum/map_template/pocket/dungeon` subtype is loaded),
so no list to edit. Resolve one in code by `id` via `SSpocket_dimensions.resolve_template("dungeon_wolf_den")`.

### Template fields

| Field | Meaning |
|---|---|
| `name` / `id` | Display name and unique id (id is how everything references it) |
| `mappath` | Path to the `.dmm` |
| `theme` | `DUNGEON_THEME_*` — `BANDIT`, `WOLF`, `TENTACLE`, `TEST` (add your own in `code/__DEFINES/dungeons.dm`) |
| `room_kind` | `DUNGEON_ROOM_*` — `ONESHOT`, `COMBAT`, `BREAK`, `BOSS`, `DESCENT` |
| `difficulty_tier` | 1–5+; how dangerous. Infinite runs pick templates in a tier band around the current floor |
| `dungeon_weight` | Relative pick weight inside its filtered pool |
| `loot_table_type` | A `/datum/loot_table` subtype the room's caches roll from |
| `gate_hint` | Flavor line shown when examining a gate that leads to this template |

---

## 4. Room kinds — what each needs

### `ONESHOT` — a one-bite dungeon
Self-contained. Player enters, clears guardians, loots, leaves via the exit seam, it collapses.
- ✅ `entry` landmark
- ✅ `exit` landmark (the return seam)
- ✅ one or more `guardian` markers (or mapped-in hostiles)
- ✅ one or more `loot` markers
- ❌ no gates needed

### `BREAK` — a safe room (infinite dungeon)
The only place players can leave an infinite run, and where they regroup.
- ✅ `entry` landmark
- ✅ `exit` landmark (overworld return — only break/descent rooms have working exits)
- ✅ **2–3 forward `gate` markers** (the branching choice). Mix variants for risk/reward
- ✅ optional `shrine` marker
- ❌ no guardians (break rooms auto-clear)

### `COMBAT` — a fight room (infinite dungeon)
- ✅ `entry` landmark
- ✅ a `gate/back` marker (retreat)
- ✅ **1+ forward `gate` markers** (sealed until cleared)
- ✅ guardians (and optional `loot`, `keyholder` + key-locked gate)
- ❌ **no exit landmark** — combat rooms intentionally have no overworld exit; the loader strips
  any fallback. Players leave a stretch only by reaching a break room

### `BOSS` — caps a floor (infinite dungeon)
- ✅ `entry` landmark
- ✅ a `gate/back` marker
- ✅ a `guardian/boss` marker
- ✅ **one forward `gate`** — it becomes the **descent** to the next floor when the boss dies
- ✅ optional `loot`
- ❌ no exit landmark

### `DESCENT` — the room you arrive in on the next floor
Treat it like a break room (entry + exit + forward gates). Crossing into it raises the floor and
despawns the floor behind you. The starter build reuses the break-room layout for this.

---

## 5. One-shot dungeons end-to-end

1. Draw the room, area `/area/pocket_dimension/dungeon`, with `entry`, `exit`, guardian(s), loot.
2. Register a `/datum/map_template/pocket/dungeon` with `room_kind = DUNGEON_ROOM_ONESHOT`, a
   `theme`, a `difficulty_tier`, and a `loot_table_type`.
3. Place an entrance on the overworld map: `/obj/structure/dungeon_entrance`.
   - `theme_filter` — restrict to one theme (null = any one-shot template)
   - `tier_min` / `tier_max` — the danger band this location rolls from
   - `respawn_cooldown` — dormancy after the dungeon collapses before it re-rolls a fresh one

```dm
// In a map, or as a mapping subtype:
/obj/structure/dungeon_entrance/wolf_country
	theme_filter = DUNGEON_THEME_WOLF
	tier_min = 1
	tier_max = 2
```

Multiple one-shot templates sharing a theme/tier band give that entrance variety — each use
rolls a different one.

---

## 6. Infinite dungeons end-to-end

1. Make a set of rooms: at least one `BREAK`, several `COMBAT` (varied tiers), one `BOSS`, and a
   `DESCENT` room — all sharing a `theme`.
2. Register them as templates (one per `.dmm`), each with the right `room_kind` and `theme`.
3. Define a **floor config** in `code/modules/dungeons/dungeon_floors.dm`:

```dm
/datum/dungeon_floor_config/gnawed_hollows
	floor = 1
	floor_name = "The Gnawed Hollows"
	themes = list(DUNGEON_THEME_WOLF, DUNGEON_THEME_BANDIT)   // rooms pull from these
	tier = 1                                                  // base danger for this floor
	stretch_length = 5                                        // combat rooms before the boss/break
	boss_pool = list(/mob/living/simple_animal/hostile/boss/dungeon/wolf_alpha = 10)
```

Floors are looked up by number; beyond the deepest defined floor the last config repeats with a
rising tier, so the dungeon is genuinely endless. Add configs for floors 1–5 (`DUNGEON_MAX_DESIGNED_FLOOR`)
to hand-author the early game.

4. Place an **infinite** entrance on the overworld: `/obj/structure/dungeon_entrance/infinite`.
   Players alt-click it to open the **assemble-your-party** screen; the leader descends with the
   present party. Right-click opens the **Delver's Ledger** (spend echoes on unlocks/cosmetics).

---

## 7. Bosses

**Any `/mob/living` typepath in a floor's `boss_pool` becomes a boss.** When spawned, the system
promotes it via `make_dungeon_boss()`: floor-scaled stats, a dressed-up name + aura + bigger
sprite, a floating **healthbar** the whole room sees, and — for non-ATB mobs — a telegraphed
ability kit (lunge / ground-slam / enrage). So you can make a regular wolf or bandit into a floor
boss just by listing it:

```dm
/datum/dungeon_floor_config/gnawed_hollows
	boss_pool = list(/mob/living/simple_animal/hostile/retaliate/wolf = 10)
```

For a **hand-crafted** boss with the full ATB ability economy, still make a
`/mob/living/simple_animal/hostile/boss/dungeon` subtype (its bespoke abilities are kept; it also
gets the generic scaling + healthbar):

```dm
/mob/living/simple_animal/hostile/boss/dungeon/wolf_alpha
	name = "Alpha of the Pack"
	maxHealth = 400
	health = 400
	melee_damage_lower = 18
	melee_damage_upper = 26
	mote_bounty = 250          // big mote drop on death (others scale by floor)
```

You never scale bosses by hand — `make_dungeon_boss()` does it at spawn. Give bespoke bosses ATB
abilities (`/datum/action/boss` subtypes); see `code/modules/mob/living/simple_animal/hostile/bosses/`.

---

## 8. Loot

Reward caches use the template's `loot_table_type`, a `/datum/loot_table` subtype
(see `code/datums/components/loot_spawner/loot_tables/`). The cache rolls per looter and scales
with the run's floor (`delve_level`) and the looter's luck. Point deeper/rarer templates at richer
tables. The `extra_cache` meta-unlock gives owners one extra share per cache automatically.

---

## 8.5. Encounter director & randomization (infinite dungeons)

Combat rooms don't have to be hand-stuffed with fixed guardians. The director can fill them from
**per-floor mob pools**, scatter them randomly, enhance them, and slap a **room trait** on top.

**Floor mob pool.** Give a floor config a `combat_mob_pool` — a list of `/datum/dungeon_spawn_entry`,
each a mob path + weight + **combat style** + min tier:

```dm
/datum/dungeon_floor_config/gnawed_hollows/New()
	. = ..()
	combat_mob_pool = list(
		new /datum/dungeon_spawn_entry(/mob/living/simple_animal/hostile/retaliate/wolf, 10, DUNGEON_STYLE_MELEE),
		new /datum/dungeon_spawn_entry(/mob/living/simple_animal/hostile/retaliate/some_archer, 6, DUNGEON_STYLE_RANGED, 2),
	)
	density_min = 2
	density_max = 4
	enhance_chance = 25   // % per mob to get affixes
	elite_chance = 8      // % per mob to become a champion
```

Styles are `DUNGEON_STYLE_MELEE` / `_RANGED` / `_CASTER`. Room traits use them to filter (see below).

**Two markers feed the pool:**
- `/obj/effect/landmark/dungeon/guardian/random` — spawns one mob from the floor pool at this tile.
  Optional `style_filter` restricts it. (A plain `guardian` marker with an empty `mob_pool` also
  falls back to the floor pool.)
- `/obj/effect/landmark/dungeon/encounter` — requests a **scatter**: the director drops
  `density_min..density_max` mobs (scaled by party size) on random open floor tiles. Optional
  `density_override` and `style_filter`.

**Enhancement** happens automatically: deeper rooms enhance every guardian (affixes), and each mob
rolls `elite_chance` to become a named **Champion** with bonus affixes + aura + bigger mote drop.

**Room traits** are fully automatic — **mappers do nothing.** Each combat room has a 50% chance to
roll one trait that reshapes its encounter. Current set: **Emboldened** (stronger), **Enraged**
(faster), **Swarm** (more, weaker), **Treasure-laden** (bonus cache), **Archers' Roost** /
**Brute Hall** (only ranged / only melee — these use the style tags, so populate your pool with the
right styles). Add a trait by adding a `/datum/dungeon_room_trait` subtype — it auto-registers.

---

## 9. Quick checklists

**One-shot room:** dungeon area ✓ · walls ✓ · `entry` ✓ · `exit` ✓ · guardian(s) ✓ · `loot` ✓ · template registered (`ONESHOT`) ✓ · entrance placed ✓

**Combat room:** dungeon area ✓ · walls ✓ · `entry` ✓ · `gate/back` ✓ · forward `gate`(s) ✓ · guardian(s) ✓ · **no `exit`** ✓ · template registered (`COMBAT`) ✓

**Break room:** dungeon area ✓ · walls ✓ · `entry` ✓ · `exit` ✓ · 2–3 forward `gate`s ✓ · optional `shrine` ✓ · **no guardians** ✓ · template registered (`BREAK`) ✓

**Boss room:** dungeon area ✓ · walls ✓ · `entry` ✓ · `gate/back` ✓ · `guardian/boss` ✓ · one forward `gate` ✓ · **no `exit`** ✓ · template registered (`BOSS`) ✓ · boss added to a floor `boss_pool` ✓

---

## 10. Common mistakes

- **Wrong area** → room won't clear/collapse correctly. Always `/area/pocket_dimension/dungeon`.
- **Exit landmark in a combat/boss room** → it's stripped anyway; players think they can leave mid-fight. Don't place it.
- **Forward gate but no `entry` in the destination template** → mobs land on the room center (works, but place an `entry` for control).
- **Boss room with no forward gate** → no descent appears after the boss dies; the floor dead-ends.
- **Keyholder `key_id` doesn't match the gate's `key_id`** → the key won't fit; the vault is unreachable.
- **New theme/room-kind string not added to `code/__DEFINES/dungeons.dm`** → won't compile.
- **Template `id` collision** → templates are keyed by `id`; duplicates clobber each other.

---

For the design rationale and the full system specs, see
`docs/superpowers/specs/2026-06-10-infinite-dungeons-design.md`,
`docs/superpowers/specs/2026-06-15-roguelike-dungeon-crawler-design.md`, and
`docs/superpowers/specs/2026-06-18-dungeon-encounter-system-design.md`.
