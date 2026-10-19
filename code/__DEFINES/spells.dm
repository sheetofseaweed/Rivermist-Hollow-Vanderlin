// Spell slot casting. A null tier means no cast in progress; zero is a real Minor cast.
#define SPELL_SLOT_MINOR 0
#define SPELL_SLOT_MIN 1
#define SPELL_SLOT_MAX 5
/// Reserve mana cost of a Minor cast for spells that do not set their own.
#define SPELL_MINOR_COST_DEFAULT 10
/// Reserve mana cost of a combat cantrip; utility cantrips cost less.
#define SPELL_CANTRIP_COST 10
#define SPELL_UTILITY_CANTRIP_COST 5
/// Natural reserve recharge per second for archetype casters; leylines stay the fast refill.
#define CASTER_BASE_MANA_RECHARGE 0.5

// Caster archetypes pick the slot ladder a job follows.
#define CASTER_FULL "full"
#define CASTER_HALF "half"
#define CASTER_THIRD "third"
#define CASTER_PACT "pact"

#define SHORT_REST_BASE_CHARGES 2
#define SHORT_REST_ADVANCED_CHARGES 3
#define SHORT_REST_DURATION (60 SECONDS)
#define SHORT_REST_BUDGET 8
#define LONG_REST_DURATION (5 MINUTES)
/// Rolling gate between completed long rests, close to one in-game day.
#define LONG_REST_GATE (90 MINUTES)

// Rest kinds; also the refill trigger of class features.
#define REST_SHORT (1<<0)
#define REST_LONG (1<<1)

// Why a concentration effect ended.
#define CONCENTRATION_REPLACED "replaced"
#define CONCENTRATION_WOUNDED "wounded"
#define CONCENTRATION_DEATH "death"
#define CONCENTRATION_DISMISSED "dismissed"

// Class feature ids stored on /datum/spell_slots.
#define FEATURE_ARCANE_RECOVERY "arcane_recovery"

#define RIGHT_X_TIER_1 150
#define RIGHT_X_TIER_2 RIGHT_X_TIER_1 + 50
#define RIGHT_X_TIER_3 RIGHT_X_TIER_2 + 90
#define RIGHT_Y_RIGHT 50
#define RIGHT_Y_LEFT -50

#define DOWN_Y_TIER_1 -150
#define DOWN_X_RIGHT 50
#define DOWN_X_LEFT -50
#define DOWN_Y_TIER_2 DOWN_Y_TIER_1 -50
#define DOWN_Y_TIER_3 DOWN_Y_TIER_2 -90

#define LEFT_X_TIER_1 -150
#define LEFT_X_TIER_2 LEFT_X_TIER_1 - 50
#define LEFT_X_TIER_3 LEFT_X_TIER_1 - 90
#define LEFT_Y_RIGHT 50
#define LEFT_Y_LEFT -50

#define UP_Y_TIER_1 150
#define UP_Y_TIER_2 UP_Y_TIER_1 + 50
#define UP_Y_TIER_3 UP_Y_TIER_2 + 90
#define UP_X_RIGHT 50
#define UP_X_LEFT -50
