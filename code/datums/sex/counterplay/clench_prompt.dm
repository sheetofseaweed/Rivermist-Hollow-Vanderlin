#define CLENCH_PROMPT_INTERVAL (12 SECONDS)

/// Builds the clickable counterplay line shown to the action's target.
/datum/sex_action/proc/build_clench_prompt()
	var/list/verbs = get_clench_verbs(hole_id)
	var/action_ref = REF(src)
	var/armed = action_target?.wants_auto_clench()
	var/clench_link = "<a href='byond://?src=[action_ref];clench=1'>[uppertext(verbs["clench"])]!</a>"
	var/auto_link = "<a href='byond://?src=[action_ref];auto_clench=1'>[armed ? "Stop auto-[verbs["clench"]]ing" : "Always [verbs["clench"]]"]</a>"
	return span_warning("[action_user] is using me. [clench_link] ([auto_link])")

/// Sends the prompt if the target is in combat mode and the throttle has elapsed.
/datum/sex_action/proc/send_clench_prompt(force = FALSE)
	if(!action_target?.client || action_target == action_user)
		return
	if(!action_target.cmode)
		return
	if(!force && world.time < next_clench_prompt_time)
		return
	next_clench_prompt_time = world.time + CLENCH_PROMPT_INTERVAL
	to_chat(action_target, build_clench_prompt())

/// Validates and dispatches a clench href. Returns TRUE when the click did something.
/datum/sex_action/proc/handle_clench_topic(mob/living/clicker, list/href_list)
	if(!istype(clicker) || QDELETED(clicker) || QDELETED(src))
		return FALSE
	if(clicker != action_target || clicker == action_user)
		return FALSE
	if(!is_runtime_active())
		return FALSE

	if(href_list["auto_clench"])
		clicker.auto_clench_override = !clicker.wants_auto_clench()
		to_chat(clicker, span_notice("Auto-clench [clicker.auto_clench_override ? "armed" : "disarmed"]."))
		return TRUE

	if(href_list["clench"])
		if(!can_clench(clicker))
			to_chat(clicker, span_warning("I cannot bring myself to tense up again yet."))
			return FALSE
		var/result = try_clench(clicker)
		if(result != CLENCH_RESULT_FAIL)
			action_user.stop_doing("sex_action_[REF(src)]")
		return TRUE

	return FALSE

/datum/sex_action/Topic(href, list/href_list)
	. = ..()
	handle_clench_topic(usr, href_list)
