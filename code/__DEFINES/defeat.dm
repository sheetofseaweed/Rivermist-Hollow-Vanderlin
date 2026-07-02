#define DEFEAT_MODE_KO_RUNE "ko_rune"
#define DEFEAT_MODE_KO_ONLY "ko_only"
#define DEFEAT_MODE_NO_RETURN "no_return"
#define DEFEAT_MODE_DEFAULT DEFEAT_MODE_KO_RUNE

#define DEFEAT_REASON_DAMAGE "damage"
#define DEFEAT_REASON_PAIN "pain"
#define DEFEAT_REASON_DEATH "death"
#define DEFEAT_REASON_HAZARD "hazard"
#define DEFEAT_REASON_HORNY "horny"

#define DEFEAT_SEVERITY_LIGHT "light"
#define DEFEAT_SEVERITY_NORMAL "normal"
#define DEFEAT_SEVERITY_SEVERE "severe"

#define DEFEAT_TREATMENT_MEDICAL "medical"
#define DEFEAT_TREATMENT_SPIRITUAL "spiritual"
#define DEFEAT_TREATMENT_UNIVERSAL "universal"

#define DEFEAT_RUNE_MAX_CHARGES 5
#define DEFEAT_RUNE_RECHARGE_TIME (60 MINUTES)
/// Sentinel in the cost table meaning "bill a fraction of current blood" instead of a flat amount.
#define DEFEAT_RUNE_BLOOD_FRACTION_SENTINEL -1
/// Fraction of current blood drawn as the blood tax when spending the final charge.
#define DEFEAT_RUNE_LAST_CHARGE_BLOOD_FRACTION (2/3)

// --- Kidnapping (section 6) ---
/// Trait source for the pacifism held over a captive after their knockout is released.
#define KIDNAP_TRAIT "kidnap_captivity"
/// How long after being kidnapped the knockout wears off, handing the captive their agency back.
#define KIDNAP_KO_RELEASE (1 MINUTES)
/// How long a captive has before the surrender option is offered.
#define KIDNAP_SURRENDER_WINDOW (15 MINUTES)
/// How many climaxes endured in captivity offer the surrender option early.
#define KIDNAP_SURRENDER_CLIMAXES 4
/// How long a surrendered NPC-in-distress lingers before despawning.
#define KIDNAP_NPC_DECAY (30 MINUTES)
/// How far a would-be captor looks for rescuers/allies when deciding whether it dares drag prey off.
#define KIDNAP_GUARD_VIEW 6

// --- NPC-in-distress (rescue NPCs) ---
/// do_after time to free a distress NPC.
#define NPC_DISTRESS_RESCUE_TIME (5 SECONDS)
/// Silver coins dropped as a rescue reward (inclusive range).
#define NPC_DISTRESS_REWARD_MIN 10
#define NPC_DISTRESS_REWARD_MAX 20
/// How far a distress NPC looks for nearby players before crying out.
#define NPC_DISTRESS_PLEA_VIEW 7
#define DEFEAT_RUNE_SPEND_KIND "kind"
#define DEFEAT_RUNE_CHARGES_REMAINING "charges_remaining"
#define DEFEAT_RUNE_SPEND_FIRST_FREE "first_free"
#define DEFEAT_RUNE_SPEND_CHARGED "charged"
#define DEFEAT_RUNE_SPEND_EMERGENCY "emergency"

#define DEFEAT_DAMAGE_THRESHOLD_DEFAULT 200
#define DEFEAT_SHOCK_WARNING_STAGE SHOCK_STAGE_4
#define DEFEAT_SHOCK_DEFEAT_STAGE SHOCK_STAGE_6
#define DEFEAT_SHOCK_HARD_STAGE SHOCK_STAGE_8
#define DEFEAT_SHOCK_SUSTAIN_DURATION (3 SECONDS)
#define DEFEAT_SHOCK_WARNING_COOLDOWN (10 SECONDS)
/// Warn the player once total damage reaches this fraction of their defeat threshold.
#define DEFEAT_DAMAGE_WARNING_FRACTION 0.7
#define DEFEAT_ACTIVE_HARM_WINDOW (3 SECONDS)
#define DEFEAT_AUTO_RESCUE_HEALING_THRESHOLD 10
/// Empty-handed revive channel: longest (no medical skill) and shortest (legendary). Scales by rank.
#define DEFEAT_REVIVE_TIME_MAX (150 SECONDS)
#define DEFEAT_REVIVE_TIME_MIN (45 SECONDS)
/// Climax count at which the gradual "you are nearing a horny defeat" warnings begin.
#define DEFEAT_HORNY_WARNING_START 2
/// How long a horny knockout lasts before the victim picks themselves back up unaided (the light case).
#define DEFEAT_HORNY_SELF_RECOVER_TIME (2 MINUTES)
/// Fraction of the (hidden) horny-defeat threshold at which the warning escalates to stage 2.
#define DEFEAT_HORNY_WARNING_BUILD_FRACTION 0.6
