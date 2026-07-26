// Succubus antagonist defines.

#define IS_SUCCUBUS(mob) (mob?.mind?.has_antag_datum(/datum/antagonist/succubus))

/// Base essence from a first-time partner's climax, before multipliers
#define SUCCUBUS_ESSENCE_BASE_HARVEST 50
/// Each repeat harvest from the same partner multiplies by this...
#define SUCCUBUS_NOVELTY_DECAY 0.4
/// ...but never below this floor
#define SUCCUBUS_NOVELTY_FLOOR 0.1
/// Arousal adds at most 50% to a climax harvest
#define SUCCUBUS_AROUSAL_BONUS_DIVISOR 500
#define SUCCUBUS_AROUSAL_BONUS_MAX 0.5
/// Starting essence cap
#define SUCCUBUS_ESSENCE_CAP_BASE 300
#define SUCCUBUS_ESSENCE_CAP_TIER_2 350
#define SUCCUBUS_ESSENCE_CAP_TIER_3 400
#define SUCCUBUS_ESSENCE_CAP_TIER_4 500
#define SUCCUBUS_CONTRACT_TIER_MAX 4
#define SUCCUBUS_CONTRACT_HIGH_AROUSAL 250
/// Corruption multipliers (married/virgin wired but inert until detection exists)
#define SUCCUBUS_CORRUPTION_CLERGY 3
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
#define SUCCUBUS_ESSENCE_PER_REAGENT_UNIT 1
/// Per-originator decay: multiplier compounds per SUCCUBUS_REAGENT_DECAY_UNIT units absorbed
#define SUCCUBUS_REAGENT_DECAY 0.5
#define SUCCUBUS_REAGENT_DECAY_UNIT 20
/// Camouflage integrity: forced reveal below this health fraction
#define SUCCUBUS_FORM_BREAK_HEALTH_FRACTION 0.4
#define SUCCUBUS_FORM_REVEAL_TIME 4 SECONDS
/// True form
#define SUCCUBUS_COST_TRUE_FORM 100
#define SUCCUBUS_TRUE_FORM_COOLDOWN 5 MINUTES
/// Enthrall
#define SUCCUBUS_COST_ENTHRALL 150
#define SUCCUBUS_THRALL_CAP 3
#define SUCCUBUS_ENTHRALL_PROMPT_TIMEOUT 30 SECONDS
#define SUCCUBUS_THRALL_UPKEEP_PER_CYCLE 15
/// Harvests from a partner before their will can be bound
#define SUCCUBUS_ENTHRALL_MIN_HARVESTS 3
/// Whisper / Charm
#define SUCCUBUS_COST_WHISPER 5
#define SUCCUBUS_COST_CHARM 15
#define SUCCUBUS_CHARM_COOLDOWN 2 MINUTES
/// Beguiling Doubles
#define SUCCUBUS_COST_BEGUILING_DOUBLES 25
#define SUCCUBUS_BEGUILING_DOUBLES_COOLDOWN 1 MINUTES
#define SUCCUBUS_BEGUILING_DOUBLE_COUNT 3
#define SUCCUBUS_BEGUILING_DOUBLE_DURATION 5 SECONDS
#define SUCCUBUS_BEGUILING_DOUBLE_STEP_DELAY 0.5 SECONDS
#define SUCCUBUS_BEGUILING_DOUBLE_STEPS 6
/// Tier 3: Whispering Imp
#define SUCCUBUS_COST_SUMMON_IMP 75
#define SUCCUBUS_SUMMON_IMP_COOLDOWN 10 MINUTES
#define SUCCUBUS_SUMMON_IMP_RETRY_COOLDOWN 30 SECONDS
#define SUCCUBUS_SUMMON_IMP_POLL_TIME 15 SECONDS
#define SUCCUBUS_SUMMON_IMP_CAP 1
#define SUCCUBUS_SUMMON_IMP_DURATION 30 MINUTES
#define SUCCUBUS_SUMMON_IMP_WARNING_TIME 1 MINUTES
/// Tier 3: Infernal Snare
#define SUCCUBUS_COST_INFERNAL_SNARE 30
#define SUCCUBUS_INFERNAL_SNARE_COOLDOWN 45 SECONDS
#define SUCCUBUS_INFERNAL_SNARE_CAP 2
#define SUCCUBUS_INFERNAL_SNARE_DURATION 10 MINUTES
#define SUCCUBUS_INFERNAL_SNARE_IMMOBILIZE 3 SECONDS
#define SUCCUBUS_INFERNAL_SNARE_KNOCKDOWN 1 SECONDS
/// Tier 3: Lustbound Hound
#define SUCCUBUS_COST_SUMMON_LUSTHOUND 75
#define SUCCUBUS_SUMMON_LUSTHOUND_COOLDOWN 10 MINUTES
#define SUCCUBUS_SUMMON_LUSTHOUND_CAP 1
#define SUCCUBUS_SUMMON_LUSTHOUND_DURATION 10 MINUTES
