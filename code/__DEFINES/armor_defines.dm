// Twilight-style armor tiers stored as legacy-compatible threshold values.
// Always pass these through normalize_armor_rating() / normalize_penetration()
// before comparing them as tiers.

#define ARMOR_TIER_NONE 0
#define ARMOR_TIER_LIGHT 1
#define ARMOR_TIER_MEDIUM 2
#define ARMOR_TIER_HEAVY 3
#define ARMOR_TIER_BSTEEL 4
#define ARMOR_TIER_SUPER 4
#define ARMOR_TIER_ULTRA 5

#define PEN_NONE 0
#define PEN_LIGHT 10
#define PEN_MEDIUM 25
#define PEN_HEAVY 35
#define PEN_BSTEEL 50

#define DBLOCK_NONE 0
#define DBLOCK_LIGHT 10
#define DBLOCK_MEDIUM 25
#define DBLOCK_HEAVY 50
#define DBLOCK_BSTEEL 75

#define DR_NONE 0
#define DR_LIGHT 10
#define DR_MEDIUM 25
#define DR_HEAVY 50
#define DR_SUPER 65
#define DR_ULTRA 75

#define ARMOR_DR_ABSORB_TYPES list("blunt")
#define ARMOR_DR_PIERCE_TYPES list("fire", "acid", "bullet")
#define ARMOR_DR_TYPES list("blunt", "fire", "acid", "bullet")
#define ARMOR_DBLOCK_TYPES list("slash", "stab", "piercing")

#define PEN_PASSTHROUGH_RATIO 0.1
#define PEN_PASSTHROUGH_CAP 8

// Blocked-damage ratios for projectile-style armor overmatch.
#define PEN_PROJECTILE_EQUAL_BLOCK_RATIO 0.8
#define PEN_PROJECTILE_OVERMATCH_BLOCK_RATIO 0.2
