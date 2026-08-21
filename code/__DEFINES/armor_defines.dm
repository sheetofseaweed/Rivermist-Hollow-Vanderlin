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

// Blunt hits multiply armor integrity damage (armor absorbs the blow but bruises).
#define BLUNT_ARMOR_INTEGRITY_MULT 1.6

// Armor integrity failure threshold (fraction of max_integrity at which armor enters broken state).
// Mirrors the TA value; clothing base already sets integrity_failure = 0.1 so this is a named constant.
#define ARMOR_INTEG_FAILURE 0.1

// Fully blocked melee attacks can still transmit blunt trauma through armor.
#define ARMOR_TRAUMA_MINIMUM 1.25
#define ARMOR_TRAUMA_MAXIMUM 15
#define ARMOR_TRAUMA_MAX_DELIVERY_MULT 2
#define ARMOR_TRAUMA_ARMOR_TIER_SCALE 0.1
#define ARMOR_TRAUMA_CON_SCALE 0.025
#define ARMOR_TRAUMA_CON_MULT_MIN 0.7
#define ARMOR_TRAUMA_CON_MULT_MAX 1.15

// item_weight is stored in kilograms.
#define ARMOR_TRAUMA_MASS_LIGHT 0.75
#define ARMOR_TRAUMA_MASS_MEDIUM 1.5
#define ARMOR_TRAUMA_MASS_HEAVY 2.5
#define ARMOR_TRAUMA_MASS_VERY_HEAVY 4
#define ARMOR_TRAUMA_MASS_EXTREME 7

#define ARMOR_TRAUMA_IMPACT_LIGHT 2
#define ARMOR_TRAUMA_IMPACT_MEDIUM 5
#define ARMOR_TRAUMA_IMPACT_HEAVY 8
#define ARMOR_TRAUMA_IMPACT_VERY_HEAVY 10
#define ARMOR_TRAUMA_IMPACT_EXTREME 12

#define ARMOR_TRAUMA_MULT_STAB 0.35
#define ARMOR_TRAUMA_MULT_CUT 0.65
#define ARMOR_TRAUMA_MULT_PICK 0.65
#define ARMOR_TRAUMA_MULT_CHOP 0.85
#define ARMOR_TRAUMA_MULT_BLUNT 1.1
#define ARMOR_TRAUMA_MULT_SMASH 1.35
