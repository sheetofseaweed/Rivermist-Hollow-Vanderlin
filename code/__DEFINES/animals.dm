#define TROLL_HEALTH 350
#define CAVETROLL_HEALTH 650
#define BOGTROLL_HEALTH 350
#define MOLE_HEALTH 200
#define BOGBUG_HEALTH 160
#define SPIDER_HEALTH 120
#define VOLF_HEALTH 110
#define SHADE_HEALTH 75
#define ROUS_HEALTH 35
#define ROUSABOM_HEALTH 800

#define FEMALE_MOOBEAST_HEALTH 100
#define MALE_MOOBEAST_HEALTH 150
#define FEMALE_GOTE_HEALTH 80
#define MALE_GOTE_HEALTH 120
#define CALF_HEALTH 20
#define CHICKEN_HEALTH 15
#define FEMALE_SAIGA_HEALTH 150
#define MALE_SAIGA_HEALTH 200

/// Hunger budget a mount carries. Far above the generic animal's so a ride can draw on it.
#define MOUNT_FOOD_MAX 400
/// Hunger a mount spends per tile carrying a rider, at a walk and at a gallop.
#define MOUNT_RIDE_COST 0.2
#define MOUNT_GALLOP_RIDE_COST 0.45
/// Below this share of its hunger a mount tires and plods, and by how much its move delay grows.
#define MOUNT_TIRED_THRESHOLD 0.25
#define MOUNT_TIRED_SLOWDOWN 2
/// Per-tile chance a starved mount throws its rider: a floor, a climb per minute left empty, and a cap.
#define MOUNT_BUCK_BASE_CHANCE 1
#define MOUNT_BUCK_CHANCE_PER_MINUTE 2
#define MOUNT_BUCK_MAX_CHANCE 20
/// Condition a rider has last been told about, so the warnings fire on change rather than every tile.
#define MOUNT_WARNING_NONE 0
#define MOUNT_WARNING_TIRING 1
#define MOUNT_WARNING_SPENT 2
/// Units of water a mount drinks per swig, and the hunger it restores.
#define MOUNT_DRINK_UNITS 15
#define MOUNT_DRINK_VALUE 30
