#define CONTRACT_POWER "power"
#define CONTRACT_WEALTH "wealth"
#define CONTRACT_PRESTIGE "prestige"
#define CONTRACT_MAGIC "magic"
#define CONTRACT_REVIVE "revive"
#define CONTRACT_FRIEND "friend"
#define CONTRACT_KNOWLEDGE "knowledge"
#define CONTRACT_UNWILLING "unwilling"

#define BANE_SALT "salt"
#define BANE_LIGHT "light"
#define BANE_IRON "iron"
#define BANE_WHITECLOTHES "whiteclothes"
#define BANE_SILVER "silver"
#define BANE_HARVEST "harvest"
#define BANE_TOOLBOX "toolbox"

#define OBLIGATION_FOOD "food"
#define OBLIGATION_FIDDLE "fiddle"
#define OBLIGATION_DANCEOFF "danceoff"
#define OBLIGATION_GREET "greet"
#define OBLIGATION_PRESENCEKNOWN "presenceknown"
#define OBLIGATION_SAYNAME "sayname"
#define OBLIGATION_ANNOUNCEKILL "announcekill"
#define OBLIGATION_ANSWERTONAME "answername"

#define BAN_HURTWOMAN "hurtwoman"
#define BAN_CHAPEL "chapel"
#define BAN_HURTPRIEST "hurtpriest"
#define BAN_AVOIDWATER "avoidwater"
#define BAN_STRIKEUNCONSCIOUS "strikeunconscious"
#define BAN_HURTLIZARD "hurtlizard"
#define BAN_HURTANIMAL "hurtanimal"

#define BANISH_WATER "water"
#define BANISH_COFFIN "coffin"
#define BANISH_FORMALDYHIDE "embalm"
#define BANISH_RUNES "runes"
#define BANISH_CANDLES "candles"
#define BANISH_DESTRUCTION "destruction"
#define BANISH_FUNERAL_GARB "funeral"

#define LORE 1
#define LAW 2

// Antag contract framework — see docs/superpowers/specs/2026-07-16-antag-contracts-design.md

#define CONTRACT_GRADE_FULL "full"
#define CONTRACT_GRADE_PARTIAL "partial"
#define CONTRACT_GRADE_FAIL "fail"
#define CONTRACT_GRADE_EXCUSED "excused"

/// Goal progress is recorded live via record_contract_progress()
#define CONTRACT_GOAL_COUNTER 1
/// Goal is evaluated by polling get_state_progress() at cycle end
#define CONTRACT_GOAL_STATE 2

/// Offline for at least this fraction of a cycle = EXCUSED grade
#define CONTRACT_EXCUSED_OFFLINE_FRACTION 0.5
/// Storyteller escalation per FULL contract, as fraction of track threshold, times tier
#define CONTRACT_OMEN_ESCALATION_FRACTION 0.025
#define CONTRACT_INTERVENTION_ESCALATION_FRACTION 0.01
