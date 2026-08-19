//The minimum for glide_size to be clamped to.
//Clamped to 5 because byond's glide size scaling is actually just completely broken and "step"
//movement is better than dealing with the awful camera juddering
#define MIN_GLIDE_SIZE 4
//The maximum for glide_size to be clamped to.
//This shouldn't be higher than the icon size, and generally you shouldn't be changing this, but it's here just in case.
#define MAX_GLIDE_SIZE 8

//This is a global so it can be changed in game, if you want to make this a bit faster you can make it a constant/define directly in the code
//GLOBAL_VAR_INIT(glide_size_multiplier, 1.25)

GLOBAL_VAR_INIT(glide_size_multiplier, 1.0)

///Broken down, here's what this does:
/// divides the world icon_size (32) by delay divided by ticklag to get the number of pixels something should be moving each tick.
/// The division result is given a min value of 1 to prevent obscenely slow glide sizes from being set
/// Then that's multiplied by the global glide size multiplier. 1.25 by default feels pretty close to spot on. This is just to try to get byond to behave.
/// The whole result is then clamped to within the range above.
/// Not very readable but it works
#define DELAY_TO_GLIDE_SIZE(delay) (clamp(((world.icon_size / max((delay) / world.tick_lag, 1)) * GLOB.glide_size_multiplier), MIN_GLIDE_SIZE, MAX_GLIDE_SIZE))

///Similar to DELAY_TO_GLIDE_SIZE, except without the clamping, and it supports piping in an unrelated scalar
#define MOVEMENT_ADJUSTED_GLIDE_SIZE(delay, movement_disparity) (world.icon_size / ((delay) / world.tick_lag) * movement_disparity * GLOB.glide_size_multiplier)

//Movement loop priority. Only one loop can run at a time, this dictates that
// Higher numbers beat lower numbers
///Standard, go lower then this if you want to override, higher otherwise
#define MOVEMENT_DEFAULT_PRIORITY 10
///Very few things should override this
#define MOVEMENT_SPACE_PRIORITY 100
///Higher then the heavens
#define MOVEMENT_ABOVE_SPACE_PRIORITY (MOVEMENT_SPACE_PRIORITY + 1)

//Movement loop flags
///Should the loop act immediately following its addition?
#define MOVEMENT_LOOP_START_FAST (1<<0)
///Do we not use the priority system?
#define MOVEMENT_LOOP_IGNORE_PRIORITY (1<<1)

#define DEFAULT_MOB_SNEAK_TIME 5 SECONDS

/**
 * Values stored in /atom/movable/currently_z_moving.
 * Higher values take priority when movement causes another z-movement path to run.
 */
#define CURRENTLY_Z_CLIMBING_DOWN 0.5
#define CURRENTLY_Z_FALLING 1
#define CURRENTLY_Z_MOVING_GENERIC 2
#define CURRENTLY_Z_FALLING_FROM_MOVE 3
#define CURRENTLY_Z_ASCENDING 4

/// Repair anything src is pulling after a grouped z-move.
#define ZMOVE_CHECK_PULLING (1<<0)
/// Repair src's relationship with its puller after a grouped z-move.
#define ZMOVE_CHECK_PULLEDBY (1<<1)
/// Apply fall-specific eligibility checks.
#define ZMOVE_FALL_CHECKS (1<<2)
/// Require the movable to be capable of flight.
#define ZMOVE_CAN_FLY_CHECKS (1<<3)
/// Apply living incapacitation checks. Interpreted by living overrides.
#define ZMOVE_INCAPACITATED_CHECKS (1<<4)
/// Require a living mover to be standing. Interpreted by living overrides.
#define ZMOVE_LYING_CHECKS (1<<5)
/// Skip zPassIn() and zPassOut() obstacle checks.
#define ZMOVE_IGNORE_OBSTACLES (1<<6)
/// Give the mover feedback when validation fails.
#define ZMOVE_FEEDBACK (1<<7)
/// Allow living movers to delegate movement to an atom they are buckled to.
#define ZMOVE_ALLOW_BUCKLED (1<<8)
/// Include pulled atoms in the grouped z-move.
#define ZMOVE_INCLUDE_PULLED (1<<9)
/// Skip the anchored check.
#define ZMOVE_ALLOW_ANCHORED (1<<10)
/// Require the destination to be a water turf.
#define ZMOVE_WATER_CHECKS (1<<11)

#define ZMOVE_CHECK_PULLS (ZMOVE_CHECK_PULLING|ZMOVE_CHECK_PULLEDBY)

#define ZMOVE_FLIGHT_FLAGS (ZMOVE_CAN_FLY_CHECKS|ZMOVE_INCAPACITATED_CHECKS|ZMOVE_CHECK_PULLS|ZMOVE_ALLOW_BUCKLED|ZMOVE_INCLUDE_PULLED)
#define ZMOVE_STAIRS_FLAGS (ZMOVE_CHECK_PULLEDBY|ZMOVE_ALLOW_BUCKLED)
#define ZMOVE_LADDER_FLAGS (ZMOVE_CHECK_PULLEDBY|ZMOVE_ALLOW_BUCKLED|ZMOVE_INCLUDE_PULLED)
#define Z_MOVE_CLIMBING_FLAGS (ZMOVE_LADDER_FLAGS|ZMOVE_INCAPACITATED_CHECKS|ZMOVE_LYING_CHECKS)
#define ZMOVE_FALL_FLAGS (ZMOVE_FALL_CHECKS|ZMOVE_ALLOW_BUCKLED)
#define ZMOVE_SWIM_FLAGS (ZMOVE_WATER_CHECKS|ZMOVE_INCAPACITATED_CHECKS|ZMOVE_CHECK_PULLS|ZMOVE_ALLOW_BUCKLED)
