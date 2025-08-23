/datum/component/arousal
	/// Our arousal level
	var/arousal = 0
	/// Arousal won't change if active
	var/arousal_frozen = FALSE
	/// Last time arousal increased
	var/last_arousal_increase_time = 0
	/// Last moan time for cooldowns
	var/last_moan = 0
	/// Last pain effect time
	var/last_pain = 0
	///our multiplier
	var/arousal_multiplier = 1

/datum/component/arousal/Initialize(...)
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/component/arousal/Destroy(force)
	. = ..()
	STOP_PROCESSING(SSobj, src)

/datum/component/arousal/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_SEX_ADJUST_AROUSAL, PROC_REF(adjust_arousal))
	RegisterSignal(parent, COMSIG_SEX_SET_AROUSAL, PROC_REF(set_arousal))
	RegisterSignal(parent, COMSIG_SEX_FREEZE_AROUSAL, PROC_REF(freeze_arousal))
	RegisterSignal(parent, COMSIG_SEX_GET_AROUSAL, PROC_REF(get_arousal))
	RegisterSignal(parent, COMSIG_SEX_RECEIVE_ACTION, PROC_REF(receive_sex_action))

/datum/component/arousal/UnregisterFromParent()
	. = ..()
	UnregisterSignal(parent, COMSIG_SEX_ADJUST_AROUSAL)
	UnregisterSignal(parent, COMSIG_SEX_SET_AROUSAL)
	UnregisterSignal(parent, COMSIG_SEX_FREEZE_AROUSAL)
	UnregisterSignal(parent, COMSIG_SEX_GET_AROUSAL)
	UnregisterSignal(parent, COMSIG_SEX_RECEIVE_ACTION)

/datum/component/arousal/process()
	if(!can_lose_arousal())
		return
	adjust_arousal(parent, -1)

/datum/component/arousal/proc/can_lose_arousal()
	if(last_arousal_increase_time + 2 MINUTES > world.time)
		return FALSE
	return TRUE

/datum/component/arousal/proc/set_arousal(datum/source, amount)
	if(amount > arousal)
		last_arousal_increase_time = world.time
	arousal = clamp(amount, 0, MAX_AROUSAL)
	update_arousal_effects()
	return arousal

/datum/component/arousal/proc/adjust_arousal(datum/source, amount)
	if(arousal_frozen)
		return arousal
	if(arousal > 0)
		arousal *= arousal_multiplier
	return set_arousal(source, arousal + amount)

/datum/component/arousal/proc/freeze_arousal(datum/source, freeze_state = null)
	if(freeze_state == null)
		arousal_frozen = !arousal_frozen
	else
		arousal_frozen = freeze_state
	return arousal_frozen

/datum/component/arousal/proc/get_arousal(datum/source, list/arousal_data)
	arousal_data += list(
		"arousal" = arousal,
		"frozen" = arousal_frozen,
		"last_increase" = last_arousal_increase_time
	)

/datum/component/arousal/proc/receive_sex_action(datum/source, arousal_amt, pain_amt, giving, applied_force, applied_speed)
	var/mob/user = parent

	// Apply multipliers
	arousal_amt *= get_force_pleasure_multiplier(applied_force, giving)
	pain_amt *= get_force_pain_multiplier(applied_force)
	pain_amt *= get_speed_pain_multiplier(applied_speed)

	if(user.stat == DEAD)
		arousal_amt = 0
		pain_amt = 0

	if(!arousal_frozen)
		adjust_arousal(source, arousal_amt)

	damage_from_pain(pain_amt)
	try_do_moan(arousal_amt, pain_amt, applied_force, giving)
	try_do_pain_effect(pain_amt, giving)

/datum/component/arousal/proc/update_arousal_effects()
	update_pink_screen()
	update_blueballs()
	update_erect_state()

/datum/component/arousal/proc/update_pink_screen()
	var/mob/user = parent
	var/severity = 0
	switch(arousal)
		if(1 to 10)
			severity = 1
		if(10 to 20)
			severity = 2
		if(20 to 30)
			severity = 3
		if(30 to 40)
			severity = 4
		if(40 to 50)
			severity = 5
		if(50 to 60)
			severity = 6
		if(60 to 70)
			severity = 7
		if(70 to 80)
			severity = 8
		if(80 to 90)
			severity = 9
		if(90 to INFINITY)
			severity = 10
	if(severity > 0)
		user.overlay_fullscreen("horny", /atom/movable/screen/fullscreen/love, severity)
	else
		user.clear_fullscreen("horny")

/datum/component/arousal/proc/update_blueballs()
	var/mob/user = parent
	if(last_arousal_increase_time + 30 SECONDS > world.time)
		return
	if(arousal >= BLUEBALLS_GAIN_THRESHOLD)
		user.add_stress(/datum/stressevent/blue_balls)
	else if(arousal <= BLUEBALLS_LOOSE_THRESHOLD)
		user.remove_stress(/datum/stressevent/blue_balls)

/datum/component/arousal/proc/update_erect_state()


/datum/component/arousal/proc/damage_from_pain(pain_amt)
	var/mob/living/carbon/user = parent
	if(pain_amt < PAIN_MINIMUM_FOR_DAMAGE)
		return
	var/damage = (pain_amt / PAIN_DAMAGE_DIVISOR)
	var/obj/item/bodypart/part = user.get_bodypart(BODY_ZONE_CHEST)
	if(!part)
		return
	user.apply_damage(damage, BRUTE, part)

/datum/component/arousal/proc/try_do_moan(arousal_amt, pain_amt, applied_force, giving)
	var/mob/user = parent
	if(arousal_amt < 1.5)
		return
	if(user.stat != CONSCIOUS)
		return
	if(last_moan + MOAN_COOLDOWN >= world.time)
		return
	if(prob(50))
		return
	var/chosen_emote
	switch(arousal_amt)
		if(0 to 5)
			chosen_emote = "sexmoanlight"
		if(5 to INFINITY)
			chosen_emote = "sexmoanhvy"

	if(pain_amt >= PAIN_MILD_EFFECT)
		if(giving)
			if(prob(30))
				chosen_emote = "groan"
		else
			if(prob(40))
				chosen_emote = "painmoan"
	if(pain_amt >= PAIN_MED_EFFECT)
		if(giving)
			if(prob(50))
				chosen_emote = "groan"
		else
			if(prob(60))
				chosen_emote = "painmoan"

	last_moan = world.time
	user.emote(chosen_emote, forced = TRUE)

/datum/component/arousal/proc/try_do_pain_effect(pain_amt, giving)
	var/mob/user = parent
	if(pain_amt < PAIN_MILD_EFFECT)
		return
	if(last_pain + PAIN_COOLDOWN >= world.time)
		return
	if(prob(50))
		return
	last_pain = world.time
	if(pain_amt >= PAIN_HIGH_EFFECT)
		var/pain_msg = pick(list("IT HURTS!!!", "IT NEEDS TO STOP!!!", "I CAN'T TAKE IT ANYMORE!!!"))
		to_chat(user, span_boldwarning(pain_msg))
		user.flash_fullscreen("redflash2")
		if(prob(70) && user.stat == CONSCIOUS)
			user.visible_message(span_warning("[user] shudders in pain!"))
	else if(pain_amt >= PAIN_MED_EFFECT)
		var/pain_msg = pick(list("It hurts!", "It pains me!"))
		to_chat(user, span_boldwarning(pain_msg))
		user.flash_fullscreen("redflash1")
		if(prob(40) && user.stat == CONSCIOUS)
			user.visible_message(span_warning("[user] shudders in pain!"))
	else
		var/pain_msg = pick(list("It hurts a little...", "It stings...", "I'm aching..."))
		to_chat(user, span_warning(pain_msg))

/datum/component/arousal/proc/get_force_pleasure_multiplier(passed_force, giving)
	switch(passed_force)
		if(SEX_FORCE_LOW)
			if(giving)
				return 0.8
			else
				return 0.8
		if(SEX_FORCE_MID)
			if(giving)
				return 1.2
			else
				return 1.2
		if(SEX_FORCE_HIGH)
			if(giving)
				return 1.6
			else
				return 1.2
		if(SEX_FORCE_EXTREME)
			if(giving)
				return 2.0
			else
				return 0.8

/datum/component/arousal/proc/get_force_pain_multiplier(passed_force)
	switch(passed_force)
		if(SEX_FORCE_LOW)
			return 0.5
		if(SEX_FORCE_MID)
			return 1.0
		if(SEX_FORCE_HIGH)
			return 2.0
		if(SEX_FORCE_EXTREME)
			return 3.0

/datum/component/arousal/proc/get_speed_pain_multiplier(passed_speed)
	switch(passed_speed)
		if(SEX_SPEED_LOW)
			return 0.8
		if(SEX_SPEED_MID)
			return 1.0
		if(SEX_SPEED_HIGH)
			return 1.2
		if(SEX_SPEED_EXTREME)
			return 1.4

/datum/stressevent/blue_balls
	timer = 1 MINUTES
	stressadd = 2
	desc = span_red("My loins ache!")
