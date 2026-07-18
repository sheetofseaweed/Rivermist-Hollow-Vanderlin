// Succubus antagonist — see docs/superpowers/specs/2026-07-17-succubus-antag-design.md

#define IS_SUCCUBUS(mob) (mob?.mind?.has_antag_datum(/datum/antagonist/succubus))

/// Base essence from a first-time partner's climax, before multipliers
#define SUCCUBUS_ESSENCE_BASE_HARVEST 100
/// Each repeat harvest from the same partner multiplies by this...
#define SUCCUBUS_NOVELTY_DECAY 0.4
/// ...but never below this floor
#define SUCCUBUS_NOVELTY_FLOOR 0.1
/// Starting essence cap (later slices raise it via contracts)
#define SUCCUBUS_ESSENCE_CAP_BASE 500
/// Corruption multipliers (married/virgin wired but inert in v1 — detection unscoped)
#define SUCCUBUS_CORRUPTION_CLERGY 5
#define SUCCUBUS_CORRUPTION_MARRIED 1
#define SUCCUBUS_CORRUPTION_VIRGIN 1
/// Max stored identity snapshots in the camouflage wardrobe
#define SUCCUBUS_WARDROBE_CAP 5
/// Essence costs
#define SUCCUBUS_COST_CAMOUFLAGE 15
#define SUCCUBUS_COST_LUST 25
#define SUCCUBUS_COST_APHRODISIAC_KISS 20
/// Camouflage integrity: forced reveal below this health fraction
#define SUCCUBUS_FORM_BREAK_HEALTH_FRACTION 0.4
#define SUCCUBUS_FORM_REVEAL_TIME 4 SECONDS
