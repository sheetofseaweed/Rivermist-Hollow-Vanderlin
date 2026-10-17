// Animated body breasts. Art and timings come from tools/breast_anim/build_breast_anims.py, which writes BREAST_ANIM_ICON:
// the walk cycle is a BYOND movement state of "pair_<N>_<LAYER>" (plays by itself while the mob moves),
// "pair_<N>_run_<LAYER>" holds the run cycle, "pair_<N>_f<K>_<LAYER>" / "pair_<N>_r<K>_<LAYER>" still frame K
// of the walk / run cycle, "pair_<N>_s<K>_<LAYER>" frame K of the squeeze (press together, release, two bounces). Emotes, interactions (sex_breast_anim.dm) and climax step through those frames on a
// timer: BYOND does not restart a play-once animation on an overlay, so a one-shot animated state does not work.
// Sizes without animation art only have still states. Players can turn their own animation off in Preferences.

#define BREAST_ANIM_ICON 'modular_rmh/icons/mob/sprite_accessory/genitals/breasts_anim.dmi'

#define BREAST_EMOTE_FRAME_TIME (0.2 SECONDS)

/// Frame sequences: "f<K>" is walk cycle frame K, "r<K>" run cycle frame K, "s<K>" squeeze frame K.
#define BREAST_FRAMES_WALK_HALF list("f1", "f2", "f3", "f4")
#define BREAST_FRAMES_WALK_FULL list("f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8")
#define BREAST_FRAMES_WALK_LAUGH list("f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f1", "f2", "f3", "f4")
#define BREAST_FRAMES_SQUEEZE list("s1", "s2", "s3", "s4", "s5", "s6")
/// Squeeze frames are drawn for 0.1 s each (tools/breast_anim/src/squeeze.aseprite).
#define BREAST_SQUEEZE_FRAME_TIME (0.1 SECONDS)

/// Emote key -> frames shown one after another, BREAST_EMOTE_FRAME_TIME each.
GLOBAL_LIST_INIT(breast_emote_anim_frames, list(
	"laugh" = BREAST_FRAMES_WALK_LAUGH,
	"giggle" = BREAST_FRAMES_WALK_FULL,
	"sigh" = BREAST_FRAMES_WALK_HALF,
	"cough" = list("f5", "f6", "f7"),
	"clearthroat" = list("f5", "f6", "f7", "f5", "f6", "f7"),
	// Jumping: the strongest shake, out of step (the run frames with one breast higher first).
	"jump" = list("r2", "r4", "r6", "r8", "r1", "r2", "r3", "r4", "r5", "r6", "r7", "r8"),
	// Dancing: a moderate sway, two walk cycles.
	"dance" = list("f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8"),
	// Shivering: barely.
	"shiver" = list("f1", "f2", "f1", "f2"),
))

/// Emote key -> frame time, for emotes faster than BREAST_EMOTE_FRAME_TIME.
GLOBAL_LIST_INIT(breast_emote_anim_times, list(
	"jump" = 0.1 SECONDS,
	"shiver" = 0.1 SECONDS,
))

/// Event shakes (breast_animation.dm, on the breasts organ): frames and frame time.
#define BREAST_FRAMES_HIT list("r1", "r2", "r3", "r4")
#define BREAST_FRAMES_FALL list("r1", "r2", "r3", "r4", "r5", "r6", "r7", "r8")
#define BREAST_FRAMES_LAND list("r5", "r6", "r7", "r8", "r1", "r2", "r3", "r4")
#define BREAST_FRAMES_RUN_STOP list("r5", "r6", "r7", "r8")
#define BREAST_EVENT_FRAME_TIME (0.1 SECONDS)
/// A stop counts after this long without a step while running.
#define BREAST_RUN_STOP_DELAY (0.35 SECONDS)
/// Brute damage from which a hit shakes the breasts.
#define BREAST_HIT_MIN_DAMAGE 5

/datum/preference/toggle/breast_animation
	savefile_key = "breast_animation"
	savefile_identifier = PREF_PLAYER
	category = "gameplay"
	can_randomize = FALSE
	should_update_preview = FALSE
	default_value = TRUE

/client/verb/toggle_breast_animation()
	set name = "Toggle Breast Animation"
	set desc = "Animate your character's breasts when moving and on some emotes."
	set category = "Preferences"
	prefs.write_preference(/datum/preference/toggle/breast_animation, !prefs.read_preference(/datum/preference/toggle/breast_animation))
	prefs.save_preferences()
	to_chat(usr, span_notice("Breast animation [prefs.read_preference(/datum/preference/toggle/breast_animation) ? "enabled" : "disabled"] for your character."))
	if(ishuman(mob))
		var/mob/living/carbon/human/human_mob = mob
		human_mob.refresh_breast_anim_visuals()

/// Redraws what follows the breast animation: the body, and breast-sized clothing worn over it.
/mob/living/carbon/proc/refresh_breast_anim_visuals()
	update_body_parts()

/mob/living/carbon/human
	/// Set while redrawing for a breast animation frame: update_body_parts() then uses the limb cache (breast_weight.dm).
	var/breast_anim_redraw = FALSE

/mob/living/carbon/human/refresh_breast_anim_visuals()
	breast_anim_redraw = TRUE
	try
		refresh_breast_anim_layers()
	catch(var/exception/error)
		breast_anim_redraw = FALSE
		throw error
	breast_anim_redraw = FALSE

/// Redraws the outermost breast-sized garment; each of these also redraws what is under it and the body.
/mob/living/carbon/human/proc/refresh_breast_anim_layers()
	if(cloak?.breast_sized_icon)
		update_inv_cloak() // also redraws the armor, the shirt and the body
	else if(wear_armor?.breast_sized_icon)
		update_inv_armor() // also redraws the shirt, a breast-sized bra and the body
	else if(wear_shirt?.breast_sized_icon)
		update_inv_shirt() // also redraws a breast-sized bra and the body
	else if(bra?.breast_sized_icon)
		update_inv_undie_top() // also redraws the body
	else
		update_body_parts()

/// Whether owner's breasts use the animated icon. Mobs without a player animate.
/proc/breast_animation_enabled(mob/living/carbon/owner)
	var/datum/preferences/prefs = owner?.client?.prefs
	if(!prefs)
		return TRUE
	return prefs.read_preference(/datum/preference/toggle/breast_animation)

/datum/sprite_accessory/genitals/breasts/pair/get_icon(obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)
	if(breast_animation_enabled(owner))
		return BREAST_ANIM_ICON
	return ..()

/datum/sprite_accessory/genitals/breasts/pair/get_icon_state(obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)
	. = ..()
	var/obj/item/organ/genitals/filling_organ/breasts/breasts = organ
	if(!istype(breasts))
		return
	var/suffix = breasts.get_anim_suffix()
	if(suffix && icon_exists(get_icon(organ, bodypart, owner), "[.][suffix]_ADJ"))
		. += suffix

/obj/item/organ/genitals/filling_organ/breasts
	/// Frame shown by a frame animation ("f<K>", "r<K>" or "s<K>"), or null. See play_breast_frames().
	var/anim_frame
	/// How long each frame of the playing frame animation is shown.
	var/anim_frame_time = BREAST_EMOTE_FRAME_TIME
	/// Alternates the two halves of the slap animation, see sex_breast_anim.dm.
	var/anim_slap_phase = FALSE
	/// Frames of the emote animation playing and the step reached in it.
	var/list/anim_sequence
	var/anim_step = 0
	/// Bumped by every new emote animation so timers of an interrupted one stop.
	var/anim_token = 0
	/// Whether the last render used the run cycle, so moving only redraws when running starts or stops.
	var/anim_running = FALSE
	/// Last step taken while running, for the shake when the owner stops.
	var/anim_last_run_step = 0

/// State suffix for the current animation: an emote, the run cycle, or "" for the default (walk) states.
/obj/item/organ/genitals/filling_organ/breasts/proc/get_anim_suffix()
	if(!owner || !breast_animation_enabled(owner))
		return ""
	if(anim_frame)
		return "_[anim_frame]"
	if(owner.m_intent == MOVE_INTENT_RUN)
		return "_run"
	return ""

/obj/item/organ/genitals/filling_organ/breasts/get_render_key_state()
	. = ..()
	. = "[.]_anim[breast_animation_enabled(owner)][get_anim_suffix()]"

/obj/item/organ/genitals/filling_organ/breasts/Insert(mob/living/M, special, drop_if_replaced, new_zone = null)
	. = ..()
	if(.)
		RegisterSignal(M, COMSIG_MOVABLE_MOVED, PROC_REF(on_owner_moved), override = TRUE)
		RegisterSignal(M, COMSIG_SEX_CLIMAX, PROC_REF(on_owner_climax), override = TRUE)
		RegisterSignal(M, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_owner_damaged), override = TRUE)
		RegisterSignal(M, COMSIG_LIVING_STATUS_KNOCKDOWN, PROC_REF(on_owner_knocked_down), override = TRUE)
		RegisterSignal(M, COMSIG_MOVABLE_THROW_LANDED, PROC_REF(on_owner_landed), override = TRUE)

/obj/item/organ/genitals/filling_organ/breasts/Remove(mob/living/M, special, drop_if_replaced)
	if(M)
		UnregisterSignal(M, list(COMSIG_MOVABLE_MOVED, COMSIG_SEX_CLIMAX, COMSIG_MOB_APPLY_DAMAGE, COMSIG_LIVING_STATUS_KNOCKDOWN, COMSIG_MOVABLE_THROW_LANDED))
	anim_frame = null
	anim_sequence = null
	anim_token++
	return ..()

/// Switches between the walk and run cycles when the owner starts or stops running.
/obj/item/organ/genitals/filling_organ/breasts/proc/on_owner_moved(mob/living/source)
	SIGNAL_HANDLER
	var/running = source.m_intent == MOVE_INTENT_RUN
	if(running && !source.buckled)
		anim_last_run_step = world.time
		addtimer(CALLBACK(src, PROC_REF(check_run_stop)), BREAST_RUN_STOP_DELAY, TIMER_UNIQUE|TIMER_OVERRIDE)
	if(running == anim_running)
		return
	anim_running = running
	if(iscarbon(source))
		var/mob/living/carbon/carbon_source = source
		carbon_source.refresh_breast_anim_visuals()

/// Shows the next frame of the emote animation, or the normal state once it is over.
/obj/item/organ/genitals/filling_organ/breasts/proc/step_emote_anim(token)
	if(token != anim_token || !iscarbon(owner))
		return
	anim_step++
	if(anim_step > length(anim_sequence))
		anim_frame = null
		anim_sequence = null
	else
		anim_frame = anim_sequence[anim_step]
		addtimer(CALLBACK(src, PROC_REF(step_emote_anim), token), anim_frame_time)
	var/mob/living/carbon/carbon_owner = owner
	carbon_owner.refresh_breast_anim_visuals()

/// Running and then stopping: the breasts swing on for a moment.
/obj/item/organ/genitals/filling_organ/breasts/proc/check_run_stop()
	if(!ishuman(owner) || world.time - anim_last_run_step < BREAST_RUN_STOP_DELAY)
		return
	var/mob/living/carbon/human/human_owner = owner
	human_owner.play_breast_frames(BREAST_FRAMES_RUN_STOP, BREAST_EVENT_FRAME_TIME)

/obj/item/organ/genitals/filling_organ/breasts/proc/on_owner_damaged(mob/living/source, damage, damagetype, def_zone)
	SIGNAL_HANDLER
	if(damagetype != BRUTE || damage < BREAST_HIT_MIN_DAMAGE || !ishuman(source))
		return
	var/mob/living/carbon/human/human_source = source
	human_source.play_breast_frames(BREAST_FRAMES_HIT, BREAST_EVENT_FRAME_TIME)

/obj/item/organ/genitals/filling_organ/breasts/proc/on_owner_knocked_down(mob/living/source, amount, ignore_canstun)
	SIGNAL_HANDLER
	if(amount <= 0 || !ishuman(source))
		return
	var/mob/living/carbon/human/human_source = source
	human_source.play_breast_frames(BREAST_FRAMES_FALL, BREAST_EVENT_FRAME_TIME)

/// Landing a jump (a jump throws the jumper, _onclick/other_mobs.dm).
/obj/item/organ/genitals/filling_organ/breasts/proc/on_owner_landed(mob/living/source)
	SIGNAL_HANDLER
	if(!ishuman(source))
		return
	var/mob/living/carbon/human/human_source = source
	human_source.play_breast_frames(BREAST_FRAMES_LAND, BREAST_EVENT_FRAME_TIME)

/obj/item/organ/genitals/filling_organ/breasts/proc/on_owner_climax(mob/living/source)
	SIGNAL_HANDLER
	if(ishuman(source))
		var/mob/living/carbon/human/human_source = source
		human_source.play_breast_frames(BREAST_FRAMES_WALK_LAUGH)

/// Plays the breast animation for emote_key, if it has one.
/mob/living/carbon/human/proc/play_breast_emote_anim(emote_key)
	var/list/frames = GLOB.breast_emote_anim_frames[emote_key]
	if(frames)
		play_breast_frames(frames, GLOB.breast_emote_anim_times[emote_key] || BREAST_EMOTE_FRAME_TIME)

/// Shows frames ("f<K>" walk, "r<K>" run cycle frames) one after another, frame_time each.
/// A new animation replaces the one playing.
/mob/living/carbon/human/proc/play_breast_frames(list/frames, frame_time = BREAST_EMOTE_FRAME_TIME)
	if(!length(frames) || !breast_animation_enabled(src))
		return
	var/obj/item/organ/genitals/filling_organ/breasts/breasts = getorganslot(ORGAN_SLOT_BREASTS)
	if(!breasts)
		return
	breasts.anim_sequence = frames
	breasts.anim_frame_time = frame_time
	breasts.anim_step = 0
	breasts.step_emote_anim(++breasts.anim_token)

/datum/emote/run_emote(mob/user, params, type_override, intentional = FALSE, targetted = FALSE)
	. = ..()
	if(. && ishuman(user) && GLOB.breast_emote_anim_frames[key])
		var/mob/living/carbon/human/human_user = user
		human_user.play_breast_emote_anim(key)

#undef BREAST_ANIM_ICON
#undef BREAST_FRAMES_HIT
#undef BREAST_FRAMES_FALL
#undef BREAST_FRAMES_LAND
#undef BREAST_FRAMES_RUN_STOP
#undef BREAST_EVENT_FRAME_TIME
#undef BREAST_RUN_STOP_DELAY
#undef BREAST_HIT_MIN_DAMAGE
