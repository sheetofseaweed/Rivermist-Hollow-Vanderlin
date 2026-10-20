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
/// Non-casters that only carry rest-gated class features.
#define CASTER_NONE "none"

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
#define FEATURE_CHANNEL_DIVINITY "channel_divinity"
#define FEATURE_CHANNEL_OATH "channel_oath"
#define FEATURE_LAY_ON_HANDS "lay_on_hands"
#define FEATURE_WILD_SHAPE "wild_shape"
#define FEATURE_SORCERY_POINTS "sorcery_points"
#define FEATURE_BARDIC_INSPIRATION "bardic_inspiration"
#define FEATURE_RAGE "rage"
#define FEATURE_KI "ki"
/// Wild Shape charges per short rest.
#define WILD_SHAPE_CHARGES 2
/// Rage charges before the Expert and Master bonuses.
#define RAGE_CHARGES_BASE 2
/// Extra short-rest budget levels from a bard's Song of Rest.
#define SONG_OF_REST_BONUS 4

// Sorcerer metamagic: armed on the slot datum, paid in sorcery points when a cast uses it.
#define METAMAGIC_QUICKENED "quickened"
#define METAMAGIC_TWINNED "twinned"
#define METAMAGIC_EXTENDED "extended"
#define METAMAGIC_DISTANT "distant"
#define METAMAGIC_SUBTLE "subtle"
#define METAMAGIC_QUICKENED_COST 3
#define METAMAGIC_EXTENDED_COST 1
#define METAMAGIC_DISTANT_COST 1
#define METAMAGIC_SUBTLE_COST 1
/// Sorcery points to create a slot of level 1 to 5.
#define SORCERY_SLOT_COSTS list(2, 3, 5, 6, 7)
/// Window for the free second cast of a twinned spell.
#define TWINNED_CAST_WINDOW (10 SECONDS)
/// Form mastery points the completed Rituos grants a slot caster.
#define RITUOS_FORM_POINTS 3
/// Lay on Hands pool per holy rank, in hit points.
#define LAY_ON_HANDS_POOL_PER_RANK 5
/// Divine Smite holy fire per slot level.
#define DIVINE_SMITE_DAMAGE_PER_LEVEL 15
/// Preserve Life mend per holy rank, per ally.
#define PRESERVE_LIFE_HEAL_PER_RANK 5

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
