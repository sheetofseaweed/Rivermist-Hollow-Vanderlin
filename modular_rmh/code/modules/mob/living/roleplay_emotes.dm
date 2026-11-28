#define ROLEPLAY_EMOTE_ICON 'modular_rmh/icons/mob/roleplay_emotes.dmi'
#define ROLEPLAY_EMOTE_VISUAL_DURATION (1.2 SECONDS)
//! Place the indicator above the usual single line of runechat.
#define ROLEPLAY_EMOTE_INDICATOR_HEIGHT 32
#define ROLEPLAY_EMOTE_MOTION_TAG "roleplay_emote"

/datum/emote/living/bow/run_emote(mob/user, params, type_override, intentional = FALSE, targetted = FALSE)
	. = ..()
	if(. && intentional)
		play_roleplay_emote_visual(user)

/datum/emote/living/dance/run_emote(mob/user, params, type_override, intentional = FALSE, targetted = FALSE)
	. = ..()
	if(. && intentional)
		play_roleplay_emote_visual(user)

/datum/emote/living/nod/run_emote(mob/user, params, type_override, intentional = FALSE, targetted = FALSE)
	. = ..()
	if(. && intentional)
		play_roleplay_emote_visual(user)

/datum/emote/living/curtsy
	key = "curtsy"
	key_third_person = "curtsies"
	message = "curtsies."
	mob_type_allowed_typecache = /mob/living/carbon/human
	restraint_check = TRUE
	incapacitated_check = TRUE

/datum/emote/living/curtsy/run_emote(mob/user, params, type_override, intentional = FALSE, targetted = FALSE)
	. = ..()
	if(. && intentional)
		play_roleplay_emote_visual(user)

/mob/living/carbon/human/verb/emote_curtsy()
	set name = "Curtsy"
	set category = "Emotes.Silent"
	emote("curtsy", intentional = TRUE)

/datum/emote/living/wipebrow
	key = "wipebrow"
	key_third_person = "wipesbrow"
	message = "wipes their brow."
	mob_type_allowed_typecache = /mob/living/carbon/human
	hands_use_check = TRUE
	incapacitated_check = TRUE

/datum/emote/living/wipebrow/run_emote(mob/user, params, type_override, intentional = FALSE, targetted = FALSE)
	. = ..()
	if(. && intentional)
		play_roleplay_emote_visual(user)

/mob/living/carbon/human/verb/emote_wipebrow()
	set name = "Wipe Brow"
	set category = "Emotes.Silent"
	emote("wipebrow", intentional = TRUE)

/mob/living/carbon/human
	/// Chat commands and emote verbs have separate cooldowns but share one visual.
	COOLDOWN_DECLARE(roleplay_emote_visual_cooldown)

/// Checks the performer again after run_emote(), which can prompt for a target.
/datum/emote/living/proc/play_roleplay_emote_visual(mob/user)
	if(QDELETED(user) || !ishuman(user))
		return
	var/mob/living/carbon/human/performer = user
	if(performer.stat != CONSCIOUS || HAS_TRAIT(performer, TRAIT_NO_TRANSFORM))
		return
	if(performer.rogue_sneaking || performer.m_intent == MOVE_INTENT_SNEAK)
		return
	if(!COOLDOWN_FINISHED(performer, roleplay_emote_visual_cooldown))
		return

	var/show_indicator = key == "nod" || key == "wipebrow"
	if(key == "wipebrow" && HAS_TRAIT(performer, TRAIT_HANDS_BLOCKED))
		return
	if(!show_indicator && (performer.body_position != STANDING_UP || performer.buckled || !(performer.mobility_flags & MOBILITY_MOVE)))
		return
	COOLDOWN_START(performer, roleplay_emote_visual_cooldown, ROLEPLAY_EMOTE_VISUAL_DURATION)
	if(show_indicator)
		performer.show_roleplay_emote_indicator(key)
		return

	switch(key)
		if("bow")
			performer.animate_roleplay_bow()
		if("dance")
			performer.animate_roleplay_dance()
		if("curtsy")
			performer.animate_roleplay_curtsy()

/mob/living/carbon/human/proc/show_roleplay_emote_indicator(icon_state)
	var/mutable_appearance/indicator_appearance = mutable_appearance(ROLEPLAY_EMOTE_ICON, "", ABOVE_ALL_MOB_LAYER)
	indicator_appearance.pixel_y = ROLEPLAY_EMOTE_INDICATOR_HEIGHT
	apply_offset(indicator_appearance, OFFSET_HEAD)
	var/atom/movable/flick_visual/indicator = flick_overlay_view(indicator_appearance, ROLEPLAY_EMOTE_VISUAL_DURATION)
	indicator.vis_flags = VIS_INHERIT_ID | VIS_INHERIT_PLANE
	flick(icon_state, indicator)

/mob/living/carbon/human/proc/animate_roleplay_bow()
	var/matrix/standing_transform = matrix(transform)
	var/matrix/bend = matrix(1, 0, 0, 0, 0.82, -2)
	if(dir & (EAST | WEST))
		bend = matrix()
		var/facing_east = dir & EAST
		bend.Turn(facing_east ? 18 : -18)
		bend.Translate(facing_east ? 3 : -3, -1)
	animate(src, transform = bend, time = 0.3 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE, tag = ROLEPLAY_EMOTE_MOTION_TAG)
	animate(transform = matrix(), time = 0.2 SECONDS, flags = ANIMATION_RELATIVE)
	animate(transform = standing_transform, time = 0.3 SECONDS, easing = SINE_EASING)

/mob/living/carbon/human/proc/animate_roleplay_dance()
	animate(src, pixel_w = -3, pixel_z = 2, time = 0.2 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE, tag = ROLEPLAY_EMOTE_MOTION_TAG)
	animate(pixel_z = -2, time = 0.1 SECONDS, flags = ANIMATION_RELATIVE)
	animate(pixel_w = 6, pixel_z = 2, time = 0.3 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE)
	animate(pixel_z = -2, time = 0.1 SECONDS, flags = ANIMATION_RELATIVE)
	animate(pixel_w = -3, time = 0.2 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE)

/mob/living/carbon/human/proc/animate_roleplay_curtsy()
	animate(src, pixel_z = -3, time = 0.3 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE, tag = ROLEPLAY_EMOTE_MOTION_TAG)
	animate(pixel_z = 0, time = 0.3 SECONDS, flags = ANIMATION_RELATIVE)
	animate(pixel_z = 3, time = 0.4 SECONDS, easing = SINE_EASING, flags = ANIMATION_RELATIVE)

#undef ROLEPLAY_EMOTE_MOTION_TAG
#undef ROLEPLAY_EMOTE_INDICATOR_HEIGHT
#undef ROLEPLAY_EMOTE_VISUAL_DURATION
#undef ROLEPLAY_EMOTE_ICON
