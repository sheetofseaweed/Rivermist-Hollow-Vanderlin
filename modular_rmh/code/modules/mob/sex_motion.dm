// Interaction motion: characters shift a few pixels while an interaction plays, in the direction that fits it.
// Moves use pixel_w / pixel_z with relative, parallel animations (as the shiver emote does), so they always return to
// where they started, never drift when cycles overlap, and do not fight species, taur or lying offsets in pixel_x/y.
// Kinds (sex_action.motion_kind), all scaled by force (tables below, never more than 5 px):
//   thrust   the user moves toward the target; also every existing do_thrust_animate() call (overridden below)
//   lean     the user leans in toward the target, softer (oral, face)
//   impact   the target jolts away from the user (slaps, strikes)
//   pull     the target is drawn toward the user
//   bob      the user bobs up and down in place (bouncing breasts)
//   paizuri  toward the target in step with the boob job breast frames: press, hold, ease back
// Players can turn their own character's motion off ("Toggle Interaction Motion"). Notes and the per-action list:
// "breasts files/docs/IMPLEMENTATION_NOTES.md".

#define SEX_MOTION_THRUST "thrust"
#define SEX_MOTION_LEAN "lean"
#define SEX_MOTION_IMPACT "impact"
#define SEX_MOTION_PULL "pull"
#define SEX_MOTION_BOB "bob"
#define SEX_MOTION_PAIZURI "paizuri"

/// Pixels by force (low, mid, high, extreme) per kind.
GLOBAL_LIST_INIT(sex_motion_pixels, list(
	SEX_MOTION_THRUST = list(2, 3, 4, 5),
	SEX_MOTION_LEAN = list(1, 2, 2, 3),
	SEX_MOTION_IMPACT = list(1, 2, 2, 3),
	SEX_MOTION_PULL = list(2, 3, 3, 4),
	SEX_MOTION_BOB = list(0, 1, 2, 3),
	SEX_MOTION_PAIZURI = list(2, 3, 3, 4),
))
/// Partner pushed along by a thrust, by force (low, mid, high, extreme): only at high force and up.
GLOBAL_LIST_INIT(sex_motion_recoil, list(0, 0, 1, 2))
/// Thrusts per cycle by speed (low, mid, high, extreme): faster reads as faster.
GLOBAL_LIST_INIT(sex_motion_pumps, list(1, 1, 2, 3))

/// Share of one pump spent moving forward and back; the rest is a pause. The forward move is short so its peak lands
/// with the action's sound, which plays at the start of the cycle.
#define SEX_MOTION_FORWARD_SHARE 0.12
#define SEX_MOTION_BACK_SHARE 0.45
#define SEX_MOTION_MIN_STEP (0.08 SECONDS)
#define SEX_MOTION_MAX_STEP (0.6 SECONDS)
#define SEX_MOTION_MAX_FORWARD (0.15 SECONDS)
#define SEX_MOTION_MAX_PIXELS 5

/datum/sex_action
	/// SEX_MOTION_* played once per cycle (actions that call do_thrust_animate() themselves leave this null).
	var/motion_kind
	/// Thrusts go up and down instead of toward the target (riding).
	var/motion_vertical = FALSE
	/// Pull: a small shudder of the target at extreme force (struggling for air).
	var/motion_struggle = FALSE
	/// Lean: a hard lean (high force and up) also pushes the target 1 px.
	var/motion_push_target = FALSE

/datum/preference/toggle/sex_motion
	savefile_key = "sex_motion"
	savefile_identifier = PREF_PLAYER
	category = "gameplay"
	can_randomize = FALSE
	should_update_preview = FALSE
	default_value = TRUE

/client/verb/toggle_sex_motion()
	set name = "Toggle Interaction Motion"
	set desc = "Let your character shift a few pixels while interactions play."
	set category = "Preferences"
	prefs.write_preference(/datum/preference/toggle/sex_motion, !prefs.read_preference(/datum/preference/toggle/sex_motion))
	prefs.save_preferences()
	to_chat(usr, span_notice("Interaction motion [prefs.read_preference(/datum/preference/toggle/sex_motion) ? "enabled" : "disabled"] for your character."))

/// Whether mover may be shifted by interaction motion. Mobs without a player move.
/proc/sex_motion_enabled(atom/movable/mover)
	if(!ismob(mover))
		return FALSE
	var/mob/mob_mover = mover
	var/datum/preferences/prefs = mob_mover.client?.prefs
	if(!prefs)
		return TRUE
	return prefs.read_preference(/datum/preference/toggle/sex_motion)

/datum/sex_action/proc/get_motion_force_index()
	return clamp(force, SEX_FORCE_LOW, SEX_FORCE_EXTREME) - SEX_FORCE_LOW + 1

/datum/sex_action/proc/get_motion_pixels(kind)
	var/list/scale = GLOB.sex_motion_pixels[kind]
	return min(scale[get_motion_force_index()], SEX_MOTION_MAX_PIXELS)

/// Seconds of one cycle at the current speed.
/datum/sex_action/proc/get_motion_cycle_time()
	return do_time / get_speed_multiplier()

/// Unit step (x, y) from mover toward target; on one tile, the way mover faces.
/proc/get_sex_motion_step(atom/movable/mover, atom/movable/target)
	var/dir = get_dir(mover, target)
	if(!dir || mover.loc == target.loc)
		dir = mover.dir
	var/dx = 0
	var/dy = 0
	if(dir & EAST)
		dx = 1
	else if(dir & WEST)
		dx = -1
	if(dir & NORTH)
		dy = 1
	else if(dir & SOUTH)
		dy = -1
	return list(dx, dy)

/// Moves mover by (dx, dy) px and back: forward, then back, then a pause; repeated pumps times. Net offset 0.
/proc/sex_motion_nudge(atom/movable/mover, dx, dy, forward, back, pause = 0, pumps = 1, forward_easing = QUAD_EASING|EASE_OUT)
	if(!mover || (!dx && !dy) || !sex_motion_enabled(mover))
		return
	for(var/pump in 1 to pumps)
		if(pump == 1)
			animate(mover, pixel_w = dx, pixel_z = dy, time = forward, easing = forward_easing, flags = ANIMATION_PARALLEL|ANIMATION_RELATIVE)
		else
			animate(pixel_w = dx, pixel_z = dy, time = forward, easing = forward_easing, flags = ANIMATION_RELATIVE)
		animate(pixel_w = -dx, pixel_z = -dy, time = back, easing = SINE_EASING, flags = ANIMATION_RELATIVE)
		if(pause > 0 && pump < pumps)
			animate(pixel_w = 0, time = pause, flags = ANIMATION_RELATIVE)

/// A quick 1 px shudder from side to side (climax, struggling).
/proc/sex_motion_shudder(atom/movable/mover, times = 3)
	if(!mover || !sex_motion_enabled(mover))
		return
	animate(mover, pixel_w = 1, time = 0.05 SECONDS, flags = ANIMATION_PARALLEL|ANIMATION_RELATIVE)
	for(var/i in 1 to times)
		animate(pixel_w = -2, time = 0.05 SECONDS, flags = ANIMATION_RELATIVE)
		animate(pixel_w = 2, time = 0.05 SECONDS, flags = ANIMATION_RELATIVE)
	animate(pixel_w = -1, time = 0.05 SECONDS, flags = ANIMATION_RELATIVE)

/// Steps of one pump: forward and back times fitted to the cycle and the number of pumps.
/datum/sex_action/proc/get_motion_steps(pumps)
	var/pump_time = get_motion_cycle_time() / pumps
	var/forward = clamp(pump_time * SEX_MOTION_FORWARD_SHARE, SEX_MOTION_MIN_STEP, SEX_MOTION_MAX_FORWARD)
	var/back = clamp(pump_time * SEX_MOTION_BACK_SHARE, SEX_MOTION_MIN_STEP, SEX_MOTION_MAX_STEP)
	var/pause = max(0, pump_time - forward - back)
	return list(forward, back, pause)

// The existing thrust, reworked: force sets the reach (2-5 px), speed the timing and number of thrusts per cycle,
// a hard thrust pushes the partner along, riding goes up and down, a partner lying on the user's tile is pressed down.
// The pixels and time arguments of the old calls are ignored.
/datum/sex_action/do_thrust_animate(atom/movable/user, atom/movable/target, pixels = 4, time = 2.7)
	if(!user || !target || user == target)
		return
	var/reach = get_motion_pixels(SEX_MOTION_THRUST)
	var/list/step = get_sex_motion_step(user, target)
	if(motion_vertical)
		step = list(0, 1)
	else if(isliving(target) && isliving(user) && user.loc == target.loc)
		var/mob/living/living_target = target
		var/mob/living/living_user = user
		if(living_target.body_position == LYING_DOWN && living_user.body_position != LYING_DOWN)
			step = list(0, -1)
	var/pumps = GLOB.sex_motion_pumps[clamp(speed, SEX_SPEED_LOW, SEX_SPEED_EXTREME) - SEX_SPEED_LOW + 1]
	var/list/timing = get_motion_steps(pumps)
	sex_motion_nudge(user, step[1] * reach, step[2] * reach, timing[1], timing[2], timing[3], pumps)
	var/recoil = GLOB.sex_motion_recoil[get_motion_force_index()]
	if(recoil && !motion_vertical)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(sex_motion_nudge), target, step[1] * recoil, step[2] * recoil, 0.08 SECONDS, timing[2]), timing[1])

/// Once per cycle, after on_perform(): the action's own motion kind.
/datum/sex_action/proc/play_perform_motion()
	if(!motion_kind || !action_user || !action_target)
		return
	var/mob/living/user = action_user
	var/mob/living/target = action_target
	var/reach = get_motion_pixels(motion_kind)
	switch(motion_kind)
		if(SEX_MOTION_THRUST)
			do_thrust_animate(user, target)
		if(SEX_MOTION_LEAN)
			var/list/step = get_sex_motion_step(user, target)
			var/list/timing = get_motion_steps(1)
			sex_motion_nudge(user, step[1] * reach, step[2] * reach, timing[1], timing[2])
			if(motion_push_target && GLOB.sex_motion_recoil[get_motion_force_index()] && user != target)
				addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(sex_motion_nudge), target, step[1], step[2], 0.08 SECONDS, timing[2]), timing[1])
		if(SEX_MOTION_IMPACT)
			if(user == target)
				return
			var/list/step = get_sex_motion_step(user, target)
			sex_motion_nudge(target, step[1] * reach, step[2] * reach, 0.05 SECONDS, 0.25 SECONDS, forward_easing = LINEAR_EASING)
		if(SEX_MOTION_PULL)
			if(user == target)
				return
			var/list/step = get_sex_motion_step(target, user)
			var/list/timing = get_motion_steps(1)
			sex_motion_nudge(target, step[1] * reach, step[2] * reach, timing[1], timing[2])
			if(motion_struggle && force >= SEX_FORCE_EXTREME)
				addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(sex_motion_shudder), target, 2), timing[1])
		if(SEX_MOTION_BOB)
			if(!reach)
				return
			// Two bobs over one run of the run cycle (8 frames, 0.8 s).
			sex_motion_nudge(user, 0, reach, 0.15 SECONDS, 0.2 SECONDS, 0.05 SECONDS, 2, SINE_EASING)
		if(SEX_MOTION_PAIZURI)
			// In step with BREAST_FRAMES_PAIZURI (sex_breast_anim.dm): press over frames 1-3, hold, ease back.
			var/list/step = get_sex_motion_step(user, target)
			if(!sex_motion_enabled(user))
				return
			animate(user, pixel_w = step[1] * reach, pixel_z = step[2] * reach, time = 0.2 SECONDS, easing = SINE_EASING, flags = ANIMATION_PARALLEL|ANIMATION_RELATIVE)
			animate(pixel_w = 0, time = 0.2 SECONDS, flags = ANIMATION_RELATIVE)
			animate(pixel_w = -step[1] * reach, pixel_z = -step[2] * reach, time = 0.3 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE)

/// Climax: a short shudder.
/mob/living/proc/play_climax_motion()
	sex_motion_shudder(src, 3)

// ---------------------------------------------------------------- which action moves how
// Actions that already call do_thrust_animate() in on_perform() (penetration, oral sex, riding, facesitting, thighs,
// scissoring, bellyriding, chastity grinding, NPCs) get the reworked thrust automatically.
// Hand actions, kissing, self actions (except bouncing), milking, spraying and storage do not move.

// Riding: up and down.
/datum/sex_action/sex/other/vagina
	motion_vertical = TRUE

/datum/sex_action/sex/other/anal
	motion_vertical = TRUE

/datum/sex_action/npc/npc_vaginal_ride_sex
	motion_vertical = TRUE

/datum/sex_action/npc/npc_anal_ride_sex
	motion_vertical = TRUE

/datum/sex_action/chastity/ride_cage
	motion_vertical = TRUE

/datum/sex_action/chastity/ride_cage_slit
	motion_vertical = TRUE

// Thrusts that had no motion.
/datum/sex_action/sex/boobjob
	motion_kind = SEX_MOTION_THRUST

/datum/sex_action/frotting
	motion_kind = SEX_MOTION_THRUST

/datum/sex_action/footjob_intimate
	motion_kind = SEX_MOTION_THRUST

/datum/sex_action/use_their_feet
	motion_kind = SEX_MOTION_THRUST

/datum/sex_action/foot_grind_vagina
	motion_kind = SEX_MOTION_THRUST

/datum/sex_action/sex/other/footjob
	motion_kind = SEX_MOTION_THRUST

// Boob job with her own breasts (also hands-free): in step with the breast frames.
/datum/sex_action/sex/other/boobjob
	motion_kind = SEX_MOTION_PAIZURI

// Leaning in with the face.
/datum/sex_action/suck_nipples
	motion_kind = SEX_MOTION_LEAN

/datum/sex_action/suck_balls
	motion_kind = SEX_MOTION_LEAN

/datum/sex_action/crotch_nuzzle
	motion_kind = SEX_MOTION_LEAN

/datum/sex_action/armpit_nuzzle
	motion_kind = SEX_MOTION_LEAN

/datum/sex_action/penis_head_worship
	motion_kind = SEX_MOTION_LEAN

/datum/sex_action/foot_lick
	motion_kind = SEX_MOTION_LEAN

/datum/sex_action/tonguebath
	motion_kind = SEX_MOTION_LEAN

/datum/sex_action/lick_soaked_clothes
	motion_kind = SEX_MOTION_LEAN

/datum/sex_action/lick_coat
	motion_kind = SEX_MOTION_LEAN

/datum/sex_action/chastity/lick_belt
	motion_kind = SEX_MOTION_LEAN

/datum/sex_action/chastity/rim_shield
	motion_kind = SEX_MOTION_LEAN

/datum/sex_action/bury_face
	motion_kind = SEX_MOTION_LEAN
	motion_push_target = TRUE

// Breast to breast: only the one who presses.
/datum/sex_action/breast_press
	motion_kind = SEX_MOTION_LEAN

// Strikes: the target jolts away.
/datum/sex_action/spanking
	motion_kind = SEX_MOTION_IMPACT

/datum/sex_action/masturbate/other/slap_breasts
	motion_kind = SEX_MOTION_IMPACT

/datum/sex_action/masturbate/other/slap_pussy
	motion_kind = SEX_MOTION_IMPACT

/datum/sex_action/masturbate/other/slap_balls
	motion_kind = SEX_MOTION_IMPACT

/datum/sex_action/impact_play
	motion_kind = SEX_MOTION_IMPACT

/datum/sex_action/wax_play
	motion_kind = SEX_MOTION_IMPACT

/datum/sex_action/beads/yank
	motion_kind = SEX_MOTION_IMPACT

// Drawn in: the target moves toward the user.
/datum/sex_action/cleavage_smother
	motion_kind = SEX_MOTION_PULL
	motion_struggle = TRUE

/datum/sex_action/chastity/force_cage
	motion_kind = SEX_MOTION_PULL

/datum/sex_action/chastity/force_belt
	motion_kind = SEX_MOTION_PULL

/datum/sex_action/chastity/force_rim
	motion_kind = SEX_MOTION_PULL

/datum/sex_action/chastity/nuzzle_cage
	motion_kind = SEX_MOTION_PULL

/datum/sex_action/nipple_clamps/tug
	motion_kind = SEX_MOTION_PULL

// Bouncing breasts for an audience.
/datum/sex_action/bounce_breasts
	motion_kind = SEX_MOTION_BOB

#undef SEX_MOTION_THRUST
#undef SEX_MOTION_LEAN
#undef SEX_MOTION_IMPACT
#undef SEX_MOTION_PULL
#undef SEX_MOTION_BOB
#undef SEX_MOTION_PAIZURI
#undef SEX_MOTION_FORWARD_SHARE
#undef SEX_MOTION_BACK_SHARE
#undef SEX_MOTION_MIN_STEP
#undef SEX_MOTION_MAX_STEP
#undef SEX_MOTION_MAX_FORWARD
#undef SEX_MOTION_MAX_PIXELS
