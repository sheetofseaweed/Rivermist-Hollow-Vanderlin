/mob/living/carbon/human/proc/get_highest_grab_state_on(mob/living/carbon/human/victim)
	var/grabstate = null
	if(r_grab && r_grab.grabbed == victim)
		if(grabstate == null || r_grab.grab_state > grabstate)
			grabstate = r_grab.grab_state
	if(l_grab && l_grab.grabbed == victim)
		if(grabstate == null || l_grab.grab_state > grabstate)
			grabstate = l_grab.grab_state
	return grabstate

/proc/get_erp_links_for_mob(mob/living/M, active_only = TRUE)
	var/list/out = list()
	if(!istype(M) || QDELETED(M))
		return out

	SEND_SIGNAL(M, COMSIG_ERP_GET_LINKS, out)
	if(!active_only)
		return out

	var/list/active = list()
	for(var/datum/erp_sex_link/L in out)
		if(!istype(L, /datum/erp_sex_link))
			continue
		if(!L || QDELETED(L))
			continue
		if(!L.is_valid())
			continue
		if(!isnull(L.vars["state"]) && L.state != 1)
			continue
		active += L

	return active

/proc/get_erp_partner_for_link(datum/erp_sex_link/L, mob/living/me)
	if(!L || !istype(me))
		return null

	var/mob/living/A = L.actor_active?.get_effect_mob()
	var/mob/living/B = L.actor_passive?.get_effect_mob()
	if(A == me)
		return B
	if(B == me)
		return A

	A = L.actor_active?.physical
	B = L.actor_passive?.physical
	if(A == me)
		return B
	if(B == me)
		return A

	return null

/proc/pick_best_erp_link_for_mob(mob/living/me, mob/living/prefer_partner = null)
	if(!istype(me) || QDELETED(me))
		return null

	var/list/links = get_erp_links_for_mob(me, TRUE)
	if(!links.len)
		return null

	var/datum/erp_sex_link/best = null
	var/best_score = -1

	for(var/datum/erp_sex_link/L in links)
		if(!istype(L, /datum/erp_sex_link))
			continue
		if(!L || QDELETED(L))
			continue
		if(!L.is_valid())
			continue

		var/mob/living/partner = get_erp_partner_for_link(L, me)
		var/score = L.get_climax_score()
		if(prefer_partner && partner == prefer_partner)
			score += 1000

		if(score > best_score)
			best_score = score
			best = L

	return best

/proc/get_erp_scene_participants_for_mob(mob/living/me)
	var/list/out = list()
	if(!istype(me) || QDELETED(me))
		return out

	out |= me

	var/list/links = get_erp_links_for_mob(me, TRUE)
	for(var/datum/erp_sex_link/L in links)
		if(!istype(L, /datum/erp_sex_link))
			continue
		if(!L || QDELETED(L))
			continue
		if(!L.is_valid())
			continue

		var/mob/living/partner = get_erp_partner_for_link(L, me)
		if(istype(partner) && !QDELETED(partner))
			out |= partner

	return out

/proc/get_erp_scene_context_for_mob(mob/living/me)
	var/list/context = list(
		"has_scene" = FALSE,
		"hidden" = FALSE,
		"subtle" = FALSE,
		"span_class" = null,
		"participants" = list(),
	)
	if(!istype(me) || QDELETED(me))
		return context

	var/list/links = get_erp_links_for_mob(me, TRUE)
	if(!links.len)
		return context

	var/list/participants = get_erp_scene_participants_for_mob(me)
	var/hidden_mode = FALSE
	var/scene_key = null

	for(var/datum/erp_sex_link/L in links)
		if(!istype(L, /datum/erp_sex_link))
			continue
		if(!L || QDELETED(L))
			continue
		if(!L.is_valid())
			continue

		var/datum/erp_controller/C = L.session
		if(C)
			if(C.hidden_mode)
				hidden_mode = TRUE
			if(isnull(scene_key))
				scene_key = md5("\ref[C]")

	context["has_scene"] = TRUE
	context["hidden"] = hidden_mode
	context["subtle"] = hidden_mode || any_has_erp_pref(participants, /datum/erp_preference/boolean/subtle_session_messages)
	context["span_class"] = scene_key ? "erp_scene_[copytext(scene_key, 1, 9)]" : "erp_scene_active"
	context["participants"] = participants
	return context

/proc/get_erp_scene_span_class_for_mob(mob/living/me)
	var/list/context = get_erp_scene_context_for_mob(me)
	return context["span_class"] || ""

/proc/is_subtle_erp_scene_for_mob(mob/living/me)
	var/list/context = get_erp_scene_context_for_mob(me)
	return !!context["subtle"]

/proc/is_mob_in_erp_scene(mob/living/me)
	var/list/context = get_erp_scene_context_for_mob(me)
	return !!context["has_scene"]

/proc/wrap_message_in_erp_scene_span(mob/living/me, text)
	if(!text)
		return text

	var/span_class = get_erp_scene_span_class_for_mob(me)
	if(!span_class)
		return text

	return "<span class='[span_class]'>[text]</span>"

/proc/do_thrust_animate(atom/movable/user, atom/movable/target, pixels = 4, time = 2.7)
	var/datum/erp_sex_link/erp_link
	if(ishuman(user) && ishuman(target))
		erp_link = pick_best_erp_link_for_mob(user, target)
	if(erp_link)
		if(erp_link.speed > SEX_SPEED_MID)
			time = max(0.5, time - 0.25)
		if(erp_link.force < SEX_FORCE_MID)
			pixels = max(1, pixels - 1)
	var/oldx = user.pixel_x
	var/oldy = user.pixel_y
	var/target_x = oldx
	var/target_y = oldy
	var/dir = get_dir(user, target)
	if(user.loc == target.loc)
		dir = user.dir
	switch(dir)
		if(NORTH)
			target_y += pixels
		if(SOUTH)
			target_y -= pixels
		if(WEST)
			target_x -= pixels
		if(EAST)
			target_x += pixels

	animate(user, pixel_x = target_x, pixel_y = target_y, time = time)
	animate(pixel_x = oldx, pixel_y = oldy, time = time)

/mob/living/proc/start_sex_session(mob/living/target, show_ui = TRUE)
	if(!target)
		return
	if(show_ui && client && ishuman(src) && ishuman(target))
		return start_erp_session(target)
	return null

/mob/living/proc/make_sucking_noise()
	if(gender == FEMALE)
		playsound(src, pick('sound/misc/mat/girlmouth (1).ogg','sound/misc/mat/girlmouth (2).ogg'), 25, TRUE, ignore_walls = FALSE)
	else
		playsound(src, pick('sound/misc/mat/guymouth (2).ogg','sound/misc/mat/guymouth (3).ogg','sound/misc/mat/guymouth (4).ogg','sound/misc/mat/guymouth (5).ogg'), 35, TRUE, ignore_walls = FALSE)

/mob/living/proc/can_do_sex()
	return TRUE

/mob/living/carbon/human/MiddleMouseDrop_T(atom/movable/dragged, mob/living/user)
	var/mob/living/carbon/human/target = src

	if(user.mmb_intent)
		return ..()
	if(!istype(dragged))
		return
	// Need to drag yourself to the target.
	if(dragged != user)
		return
	if(!user.can_do_sex())
		to_chat(user, "<span class='warning'>I can't do this.</span>")
		return

	if(!user.start_sex_session(target))
		to_chat(user, "<span class='warning'>I'm already sexing.</span>")
		return

/mob/living/proc/has_hands()
	return TRUE

/mob/living/proc/has_mouth()
	return TRUE

/mob/living/proc/has_penis()
	return gender == MALE

/mob/living/proc/has_testicles()
	return gender == MALE

/mob/living/proc/has_vagina()
	return gender == FEMALE

/mob/living/proc/has_breasts()
	return gender == FEMALE

/mob/living/carbon/human/has_penis()
	return getorganslot(ORGAN_SLOT_PENIS)

/mob/living/carbon/human/has_testicles()
	return getorganslot(ORGAN_SLOT_TESTICLES)

/mob/living/carbon/human/has_vagina()
	return getorganslot(ORGAN_SLOT_VAGINA)

/mob/living/carbon/human/has_breasts()
	RETURN_TYPE(/obj/item/organ/genitals/filling_organ/breasts)
	return getorganslot(ORGAN_SLOT_BREASTS)

/mob/living/carbon/human/proc/has_belly()
	RETURN_TYPE(/obj/item/organ/genitals/belly)
	return getorganslot(ORGAN_SLOT_BELLY)

/mob/living/carbon/human/proc/has_butt()
	RETURN_TYPE(/obj/item/organ/genitals/butt)
	return getorganslot(ORGAN_SLOT_BUTT)

/mob/living/carbon/human/proc/is_fertile()
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = getorganslot(ORGAN_SLOT_VAGINA)
	return vagina.fertility

/mob/living/carbon/human/proc/is_virile()
	var/obj/item/organ/genitals/filling_organ/testicles/testicles = getorganslot(ORGAN_SLOT_TESTICLES)
	return testicles.virility

/mob/living/proc/mouth_is_free()
	return !is_mouth_covered()

/mob/living/proc/foot_is_free()
	return is_barefoot()

/mob/living/proc/is_barefoot()
	for(var/item_slot in DEFAULT_SLOT_PRIORITY)
		var/obj/item/clothing = get_item_by_slot(item_slot)
		if(!clothing) // Don't have this slot or not wearing anything in it
			continue
		if(clothing.body_parts_covered & FEET)
			return FALSE
	// If didn't stop before, then we're barefoot
	return TRUE

/mob/living/carbon/human/has_mouth()
	return get_bodypart(BODY_ZONE_HEAD)

/mob/living/carbon/human/has_hands() // technically should be an and but i'll replicate original behavior
	return get_bodypart(BODY_ZONE_L_ARM) || get_bodypart(BODY_ZONE_R_ARM)

/mob/living/proc/return_character_information()
	var/list/data = list()
	if(has_hands())
		data += "<div>...have hands.</div>"
	if(has_mouth())
		data += "<div>...have a mouth, which is [mouth_is_free() ? "uncovered" : "covered"].</div>"
	return data

/mob/living/proc/get_active_precise_hand()
	var/active_hand = BODY_ZONE_PRECISE_L_HAND
	if(active_hand_index != 1)
		active_hand = BODY_ZONE_PRECISE_R_HAND
	return active_hand

/mob/proc/check_handholding()
	return

/mob/living/carbon/human/check_handholding()
	if(pulledby && pulledby != src)
		var/obj/item/bodypart/LH
		var/obj/item/bodypart/RH
		LH = get_bodypart(BODY_ZONE_PRECISE_L_HAND)
		RH = get_bodypart(BODY_ZONE_PRECISE_R_HAND)
		if(LH || RH)
			for(var/obj/item/grabbing/G in src.grabbedby)
				if(G.limb_grabbed == LH || G.limb_grabbed == RH)
					return TRUE

/mob/proc/get_erp_pref(pref_type)
	if(!client?.prefs)
		return FALSE

	if(!ispath(pref_type, /datum/erp_preference))
		return FALSE

	var/datum/erp_preference/pref = new pref_type()
	return pref.get_value(client.prefs)

/mob/proc/set_erp_pref(pref_type, value)
	if(!client?.prefs)
		return FALSE

	if(!ispath(pref_type, /datum/erp_preference))
		return FALSE

	var/datum/erp_preference/pref = new pref_type()
	pref.set_value(client.prefs, value)
	client.prefs.save_preferences()
	return TRUE

/mob/proc/has_erp_pref(pref_type)
	return get_erp_pref(pref_type) == TRUE

/mob/proc/get_all_erp_prefs()
	if(!client?.prefs)
		return list()

	var/list/prefs_by_category = list()

	for(var/pref_type in subtypesof(/datum/erp_preference))
		var/datum/erp_preference/pref = new pref_type()
		var/category = pref.category
		var/value = pref.get_value(client.prefs)

		if(!prefs_by_category[category])
			prefs_by_category[category] = list()

		prefs_by_category[category][pref_type] = list(
			"name" = pref.name,
			"description" = pref.description,
			"value" = value,
			"pref_object" = pref
		)

	return prefs_by_category

/proc/any_has_erp_pref(list/mobs, pref_type)
	for(var/mob/M in mobs)
		if(M.has_erp_pref(pref_type))
			return TRUE
	return FALSE

/proc/all_have_erp_pref(list/mobs, pref_type)
	for(var/mob/M in mobs)
		if(!M.has_erp_pref(pref_type))
			return FALSE
	return TRUE

/mob/living/proc/has_kink(kink_name)
	if(!client?.prefs?.erp_preferences)
		return FALSE
	var/list/kink_prefs = client.prefs.erp_preferences["kinks"]
	if(!kink_prefs || !kink_prefs[kink_name])
		return FALSE
	return kink_prefs[kink_name]["enabled"]


/mob/living
	var/list/attached_sex_toys = list()

	///npc organs to use
	var/ball_organ = /obj/item/organ/genitals/filling_organ/testicles
	var/ball_min = MIN_TESTICLES_SIZE
	var/ball_max = MAX_TESTICLES_SIZE
	var/breast_organ = /obj/item/organ/genitals/filling_organ/breasts
	var/breast_min = MIN_BREASTS_SIZE
	var/breast_max = MAX_BREASTS_SIZE
	var/ass_organ = /obj/item/organ/genitals/butt
	var/ass_min = MIN_BUTT_SIZE
	var/ass_max = MAX_BUTT_SIZE
	var/penis_organ = /obj/item/organ/genitals/penis
	var/penis_min = MIN_PENIS_SIZE
	var/penis_max = MAX_PENIS_SIZE
	var/butt_organ = /obj/item/organ/genitals/butt
	var/butt_min = MIN_BUTT_SIZE
	var/butt_max = MAX_BUTT_SIZE
	var/vagina_organ = /obj/item/organ/genitals/filling_organ/vagina
	var/show_genitals = FALSE
	var/mouth_blocked = FALSE

/mob/living/Initialize()
	. = ..()
	if(ai_controller)
		var/datum/ai_planning_subtree/horny/hornybehavior = locate() in ai_controller.planning_subtrees
		if(hornybehavior)
			addtimer(CALLBACK(src, PROC_REF(give_genitals)), 1)

/mob/living/proc/give_genitals()
	if(!isanimal(src))
		var/mob/living/carbon/human/user = src
		if(gender == MALE)
			var/obj/item/organ/genitals/filling_organ/testicles/testicles = user.getorganslot(ORGAN_SLOT_TESTICLES)
			if(!testicles)
				if(!show_genitals)
					testicles = new /obj/item/organ/genitals/filling_organ/testicles/invisible
				else
					testicles = new ball_organ
				testicles.organ_size = rand(ball_min, ball_max)
				testicles.Insert(user, TRUE)
			var/obj/item/organ/genitals/penis/penis = user.getorganslot(ORGAN_SLOT_PENIS)
			if(!penis)
				if(!show_genitals)
					penis = new /obj/item/organ/genitals/penis
				else
					penis = new penis_organ
				penis.organ_size = rand(penis_min, penis_max)
				penis.Insert(user, TRUE)
		if(gender == FEMALE)
			var/obj/item/organ/genitals/butt/buttie = user.getorganslot(ORGAN_SLOT_BUTT)
			if(!buttie)
				if(!show_genitals)
					buttie = new /obj/item/organ/genitals/butt/invisible
				else
					buttie = new butt_organ
				buttie.organ_size = rand(butt_min, butt_max)
				buttie.Insert(user, TRUE)
			var/obj/item/organ/genitals/filling_organ/breasts/breasts = user.getorganslot(ORGAN_SLOT_BREASTS)
			if(!breasts)
				if(!show_genitals)
					breasts = new /obj/item/organ/genitals/filling_organ/breasts
				else
					breasts = new breast_organ
				breasts.organ_size = rand(breast_min,breast_max)
				breasts.Insert(user, TRUE)
			var/obj/item/organ/genitals/filling_organ/vagina/vagina = user.getorganslot(ORGAN_SLOT_VAGINA)
			if(!vagina)
				if(!show_genitals)
					vagina = new /obj/item/organ/genitals/filling_organ/vagina
				else
					vagina = new vagina_organ
				vagina.Insert(user, TRUE)
			if(prob(5)) //5 chance to be dickgirl.
				var/obj/item/organ/genitals/filling_organ/testicles/testicles = user.getorganslot(ORGAN_SLOT_TESTICLES)
				if(!testicles)
					if(!show_genitals)
						testicles = new /obj/item/organ/genitals/filling_organ/testicles/invisible
					else
						testicles = new ball_organ
					testicles.organ_size = rand(ball_min, ball_max)
					testicles.Insert(user, TRUE)
				var/obj/item/organ/genitals/penis/penis = user.getorganslot(ORGAN_SLOT_PENIS)
				if(!penis)
					if(!show_genitals)
						penis = new /obj/item/organ/genitals/penis
					else
						penis = new penis_organ
					penis.organ_size = rand(penis_min, penis_max)
					penis.Insert(user, TRUE)
		color_key_source_list_from_carbon(src)

/mob/living/proc/adjacent_or_closet(atom/neighbor)
	if(istype(loc, /obj/structure/closet) || istype(loc, /obj/structure/handcart) || istype(neighbor.loc, /obj/structure/closet) || istype(neighbor.loc, /obj/structure/handcart)) // within container
		return loc == neighbor.loc
	return Adjacent(neighbor)

/mob/living/proc/check_closet(atom/neighbor)
	if(istype(loc, /obj/structure/closet) || istype(loc, /obj/structure/handcart) || istype(neighbor.loc, /obj/structure/closet) || istype(neighbor.loc, /obj/structure/handcart)) // within container
		return loc == neighbor.loc
	else
		return FALSE
