// Breast animation on ERP interactions: every cycle of an action (after on_perform, see run_runtime()) the
// receiving side's breasts play frames from breast_animation.dm. Force and speed set how hard they move.

/// Who gets the animation: the action's user or its target.
#define BREAST_ANIM_ON_USER "user"
#define BREAST_ANIM_ON_TARGET "target"

/// Kinds of motion, see play_perform_breast_anim().
#define BREAST_ANIM_THRUST "thrust"
#define BREAST_ANIM_BOOBJOB "boobjob"
#define BREAST_ANIM_TOUCH "touch"
#define BREAST_ANIM_SLAP "slap"
/// Pressed together, released, two bounces: the squeeze frames once per cycle.
#define BREAST_ANIM_SQUEEZE "squeeze"
/// Lifted and dropped: the squeeze frames from the lift on.
#define BREAST_ANIM_HEFT "heft"
/// Boob job with her own breasts: pressed together (squeeze frames 1-3), a short hold, and eased back (3-1).
#define BREAST_ANIM_PAIZURI "paizuri"
#define BREAST_FRAMES_PAIZURI list("s1", "s2", "s3", "s3", "s3", "s2", "s1")
/// The whole run cycle (bouncing for an audience).
#define BREAST_ANIM_RUN "run"
/// The first half of the run cycle (a spray).
#define BREAST_ANIM_JOLT "jolt"
/// A loop given by the action, get_breast_loop_frames().
#define BREAST_ANIM_LOOP "loop"

#define BREAST_FRAMES_RUN_FULL list("r1", "r2", "r3", "r4", "r5", "r6", "r7", "r8")
#define BREAST_FRAMES_RUN_SLAP_FIRST list("r1", "r2", "r3", "r4")
#define BREAST_FRAMES_RUN_SLAP_SECOND list("r4", "r5", "r6", "r7", "r8")
#define BREAST_RUN_FRAME_TIME (0.1 SECONDS)

/datum/sex_action
	/// BREAST_ANIM_ON_USER / BREAST_ANIM_ON_TARGET: whose breasts move each cycle, or null for none.
	var/breast_anim_on
	/// BREAST_ANIM_* motion kind.
	var/breast_anim_kind
	/// Animate both the user's and the target's breasts (breast to breast).
	var/breast_anim_both = FALSE

/// Frames for BREAST_ANIM_LOOP, shown at BREAST_EMOTE_FRAME_TIME each.
/datum/sex_action/proc/get_breast_loop_frames()
	return null

/// Rough motion: the run cycle when force and speed are both high, half a walk cycle when both are low,
/// a full walk cycle otherwise.
/datum/sex_action/proc/play_intensity_breast_anim(mob/living/carbon/human/receiver)
	// Several thrusts per cycle (sex_motion.dm): half a run cycle for each, fitted to the thrust.
	var/pumps = GLOB.sex_motion_pumps[clamp(speed, SEX_SPEED_LOW, SEX_SPEED_EXTREME) - SEX_SPEED_LOW + 1]
	if(pumps > 1)
		var/list/frames = list()
		for(var/i in 1 to pumps)
			frames += BREAST_FRAMES_RUN_SLAP_FIRST
		receiver.play_breast_frames(frames, max(0.05 SECONDS, get_motion_cycle_time() / pumps / length(BREAST_FRAMES_RUN_SLAP_FIRST)))
		return
	if(force >= SEX_FORCE_HIGH && speed >= SEX_SPEED_HIGH)
		receiver.play_breast_frames(BREAST_FRAMES_RUN_FULL, BREAST_RUN_FRAME_TIME)
	else if(force <= SEX_FORCE_LOW && speed <= SEX_SPEED_LOW)
		receiver.play_breast_frames(BREAST_FRAMES_WALK_HALF)
	else
		receiver.play_breast_frames(BREAST_FRAMES_WALK_FULL)

/datum/sex_action/proc/play_perform_breast_anim()
	if(!breast_anim_on || !breast_anim_kind)
		return
	var/mob/living/carbon/human/receiver = breast_anim_on == BREAST_ANIM_ON_USER ? action_user : action_target
	// Breast interactions (not penetration, which only shakes them) feed the Breast Enthusiast vice.
	if(breast_anim_kind != BREAST_ANIM_THRUST)
		var/list/owners = list(receiver)
		if(breast_anim_both)
			owners |= receiver == action_user ? action_target : action_user
		notify_breast_interaction(owners)
	if(breast_anim_both)
		var/mob/living/carbon/human/other = receiver == action_user ? action_target : action_user
		if(ishuman(other) && other != receiver)
			play_breast_anim_on(other)
	if(!ishuman(receiver))
		return
	play_breast_anim_on(receiver)

/datum/sex_action/proc/play_breast_anim_on(mob/living/carbon/human/receiver)
	switch(breast_anim_kind)
		if(BREAST_ANIM_THRUST, BREAST_ANIM_BOOBJOB)
			play_intensity_breast_anim(receiver)
		if(BREAST_ANIM_TOUCH)
			receiver.play_breast_frames(BREAST_FRAMES_WALK_HALF)
		if(BREAST_ANIM_SQUEEZE)
			receiver.play_breast_frames(BREAST_FRAMES_SQUEEZE, BREAST_SQUEEZE_FRAME_TIME)
		if(BREAST_ANIM_PAIZURI)
			receiver.play_breast_frames(BREAST_FRAMES_PAIZURI, BREAST_SQUEEZE_FRAME_TIME)
		if(BREAST_ANIM_HEFT)
			receiver.play_breast_frames(list("s2", "s3", "s4", "s5", "s6"), BREAST_SQUEEZE_FRAME_TIME)
		if(BREAST_ANIM_RUN)
			receiver.play_breast_frames(BREAST_FRAMES_RUN_FULL, BREAST_RUN_FRAME_TIME)
		if(BREAST_ANIM_JOLT)
			receiver.play_breast_frames(BREAST_FRAMES_RUN_SLAP_FIRST, BREAST_RUN_FRAME_TIME)
		if(BREAST_ANIM_LOOP)
			var/list/frames = get_breast_loop_frames()
			if(length(frames))
				receiver.play_breast_frames(frames)
		if(BREAST_ANIM_SLAP)
			// Slaps alternate the two halves of the run cycle.
			var/obj/item/organ/genitals/filling_organ/breasts/breasts = receiver.getorganslot(ORGAN_SLOT_BREASTS)
			if(!breasts)
				return
			breasts.anim_slap_phase = !breasts.anim_slap_phase
			receiver.play_breast_frames(breasts.anim_slap_phase ? BREAST_FRAMES_RUN_SLAP_FIRST : BREAST_FRAMES_RUN_SLAP_SECOND, BREAST_RUN_FRAME_TIME)

// Penetration and riding: the penetrated side.
/datum/sex_action/sex/vaginal
	breast_anim_on = BREAST_ANIM_ON_TARGET
	breast_anim_kind = BREAST_ANIM_THRUST

/datum/sex_action/sex/anal
	breast_anim_on = BREAST_ANIM_ON_TARGET
	breast_anim_kind = BREAST_ANIM_THRUST

/datum/sex_action/scissoring
	breast_anim_on = BREAST_ANIM_ON_TARGET
	breast_anim_kind = BREAST_ANIM_THRUST

/datum/sex_action/sex/other/vagina
	breast_anim_on = BREAST_ANIM_ON_USER
	breast_anim_kind = BREAST_ANIM_THRUST

/datum/sex_action/sex/other/anal
	breast_anim_on = BREAST_ANIM_ON_USER
	breast_anim_kind = BREAST_ANIM_THRUST

// Boob jobs: the breasts' owner.
/datum/sex_action/sex/boobjob
	breast_anim_on = BREAST_ANIM_ON_TARGET
	breast_anim_kind = BREAST_ANIM_BOOBJOB

// Giving one with her own breasts (also hands-free): pressed together and eased back, without the release bounces.
// Having them used by someone else keeps the bouncing (boobjob kind, above).
/datum/sex_action/sex/other/boobjob
	breast_anim_on = BREAST_ANIM_ON_USER
	breast_anim_kind = BREAST_ANIM_PAIZURI

// Caresses: the breasts' owner.
/datum/sex_action/masturbate/breasts
	breast_anim_on = BREAST_ANIM_ON_USER
	breast_anim_kind = BREAST_ANIM_TOUCH

/datum/sex_action/masturbate/nipples
	breast_anim_on = BREAST_ANIM_ON_USER
	breast_anim_kind = BREAST_ANIM_TOUCH

/datum/sex_action/masturbate/other/breasts
	breast_anim_on = BREAST_ANIM_ON_TARGET
	breast_anim_kind = BREAST_ANIM_TOUCH

/datum/sex_action/masturbate/other/nipples
	breast_anim_on = BREAST_ANIM_ON_TARGET
	breast_anim_kind = BREAST_ANIM_TOUCH

/datum/sex_action/suck_nipples
	breast_anim_on = BREAST_ANIM_ON_TARGET
	breast_anim_kind = BREAST_ANIM_TOUCH

// Slaps: the breasts' owner.
/datum/sex_action/masturbate/slap_breasts
	breast_anim_on = BREAST_ANIM_ON_USER
	breast_anim_kind = BREAST_ANIM_SLAP

/datum/sex_action/masturbate/other/slap_breasts
	breast_anim_on = BREAST_ANIM_ON_TARGET
	breast_anim_kind = BREAST_ANIM_SLAP

// Breast interactions (sex_breast_actions.dm).
/datum/sex_action/masturbate/other/squeeze_breasts
	breast_anim_on = BREAST_ANIM_ON_TARGET
	breast_anim_kind = BREAST_ANIM_TOUCH

/datum/sex_action/bury_face
	breast_anim_on = BREAST_ANIM_ON_TARGET
	breast_anim_kind = BREAST_ANIM_TOUCH

/datum/sex_action/cleavage_smother
	breast_anim_on = BREAST_ANIM_ON_USER
	breast_anim_kind = BREAST_ANIM_TOUCH

/datum/sex_action/breast_press
	breast_anim_on = BREAST_ANIM_ON_USER
	breast_anim_kind = BREAST_ANIM_TOUCH
	breast_anim_both = TRUE

/datum/sex_action/milk_breasts
	breast_anim_on = BREAST_ANIM_ON_TARGET
	breast_anim_kind = BREAST_ANIM_TOUCH

/datum/sex_action/spray_milk
	breast_anim_on = BREAST_ANIM_ON_USER
	breast_anim_kind = BREAST_ANIM_JOLT

/datum/sex_action/masturbate/heft_breasts
	breast_anim_on = BREAST_ANIM_ON_USER
	breast_anim_kind = BREAST_ANIM_HEFT

/datum/sex_action/suck_own_nipple
	breast_anim_on = BREAST_ANIM_ON_USER
	breast_anim_kind = BREAST_ANIM_LOOP

/datum/sex_action/suck_own_nipple/get_breast_loop_frames()
	return loop_frames

/datum/sex_action/bounce_breasts
	breast_anim_on = BREAST_ANIM_ON_USER
	breast_anim_kind = BREAST_ANIM_RUN

/datum/sex_action/masturbate/squeeze_together
	breast_anim_on = BREAST_ANIM_ON_USER
	breast_anim_kind = BREAST_ANIM_SQUEEZE

#undef BREAST_ANIM_ON_USER
#undef BREAST_ANIM_ON_TARGET
#undef BREAST_ANIM_THRUST
#undef BREAST_ANIM_BOOBJOB
#undef BREAST_ANIM_TOUCH
#undef BREAST_ANIM_SLAP
#undef BREAST_ANIM_SQUEEZE
#undef BREAST_ANIM_HEFT
#undef BREAST_ANIM_PAIZURI
#undef BREAST_FRAMES_PAIZURI
#undef BREAST_ANIM_RUN
#undef BREAST_ANIM_JOLT
#undef BREAST_ANIM_LOOP
#undef BREAST_FRAMES_RUN_FULL
#undef BREAST_FRAMES_RUN_SLAP_FIRST
#undef BREAST_FRAMES_RUN_SLAP_SECOND
#undef BREAST_RUN_FRAME_TIME
