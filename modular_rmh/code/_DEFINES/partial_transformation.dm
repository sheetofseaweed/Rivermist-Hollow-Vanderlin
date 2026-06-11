/// Default cooldown between partial transformation toggles.
#define PARTIAL_TRANSFORM_COOLDOWN (3 MINUTES)

/// Sent on a mob when it completes a partial transformation shift: (datum/partial_transformation_kit/kit)
#define COMSIG_MOB_PARTIAL_SHIFTED "mob_partial_shifted"
/// Sent on a mob when it reverts a partial transformation: (datum/partial_transformation_kit/kit)
#define COMSIG_MOB_PARTIAL_UNSHIFTED "mob_partial_unshifted"
