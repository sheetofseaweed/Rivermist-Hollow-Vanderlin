// Succubus antagonist defines.

#define IS_SUCCUBUS(mob) (mob?.mind?.has_antag_datum(/datum/antagonist/succubus))

/// Base essence from a first-time partner's climax, before multipliers
#define SUCCUBUS_ESSENCE_BASE_HARVEST 100
/// Each repeat harvest from the same partner multiplies by this...
#define SUCCUBUS_NOVELTY_DECAY 0.4
/// ...but never below this floor
#define SUCCUBUS_NOVELTY_FLOOR 0.1
/// Starting essence cap
#define SUCCUBUS_ESSENCE_CAP_BASE 500
/// Corruption multipliers (married/virgin wired but inert until detection exists)
#define SUCCUBUS_CORRUPTION_CLERGY 5
#define SUCCUBUS_CORRUPTION_MARRIED 1
#define SUCCUBUS_CORRUPTION_VIRGIN 1
/// Max stored identity snapshots in the camouflage wardrobe
#define SUCCUBUS_WARDROBE_CAP 5
/// Essence costs
#define SUCCUBUS_COST_CAMOUFLAGE 15
#define SUCCUBUS_COST_LUST 25
#define SUCCUBUS_COST_APHRODISIAC_KISS 20
/// Multiplier on horny-KO thresholds for TRAIT_LUSTFUL_STAMINA holders —
/// tiring out a succubus in bed should be a heroic feat, not an afternoon
#define SUCCUBUS_HORNY_KO_MULT 10
/// Essence per unit of absorbed sexual fluid, before decay
#define SUCCUBUS_ESSENCE_PER_REAGENT_UNIT 2
/// Per-originator decay: multiplier compounds per SUCCUBUS_REAGENT_DECAY_UNIT units absorbed
#define SUCCUBUS_REAGENT_DECAY 0.5
#define SUCCUBUS_REAGENT_DECAY_UNIT 20
/// Camouflage integrity: forced reveal below this health fraction
#define SUCCUBUS_FORM_BREAK_HEALTH_FRACTION 0.4
#define SUCCUBUS_FORM_REVEAL_TIME 4 SECONDS
/// True form
#define SUCCUBUS_COST_TRUE_FORM 50
#define SUCCUBUS_TRUE_FORM_COOLDOWN 5 MINUTES
/// Enthrall
#define SUCCUBUS_COST_ENTHRALL 100
#define SUCCUBUS_THRALL_CAP 3
/// Harvests from a partner before their will can be bound
#define SUCCUBUS_ENTHRALL_MIN_HARVESTS 3
/// Whisper / Charm
#define SUCCUBUS_COST_WHISPER 5
#define SUCCUBUS_COST_CHARM 15
#define SUCCUBUS_CHARM_COOLDOWN 2 MINUTES
