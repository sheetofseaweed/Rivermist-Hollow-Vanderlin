// The horny AI's acts for a skeleton with a funny bone; same mechanics as the flesh versions, bonier words.

/datum/sex_action/npc/npc_throat_sex/funny_bone
	name = "NPC Rattle a funny bone down their throat"

/datum/sex_action/npc/npc_throat_sex/funny_bone/get_perform_message(mob/living/user, mob/living/target)
	return "[user] [get_generic_force_adjective()] rattles [user.p_their()] funny bone down [target]'s throat."

/datum/sex_action/npc/npc_throat_sex/funny_bone/get_finish_message(mob/living/user, mob/living/target)
	return "[user] pulls [user.p_their()] funny bone out of [target]'s throat with a hollow clack."

/datum/sex_action/npc/npc_throat_sex/funny_bone/handle_climax_message(mob/living/user, mob/living/target, must_flip)
	if(must_flip)
		user.visible_message(span_love("[user] shudders in orgasm with a funny bone rattling in [user.p_their()] throat!"))
		user.lose_virginity()
		return ORGASM_LOCATION_SELF
	user.visible_message(span_love("[user]'s funny bone clatters in [target]'s throat, but nothing comes of it!"))
	return ORGASM_LOCATION_SELF

/datum/sex_action/npc/npc_anal_sex/funny_bone
	name = "NPC Rattle a funny bone in their ass"

/datum/sex_action/npc/npc_anal_sex/funny_bone/get_start_message(mob/living/user, mob/living/target)
	return "[user] wedges [user.p_their()] funny bone into [target]'s ass with a creak!"

/datum/sex_action/npc/npc_anal_sex/funny_bone/get_perform_message(mob/living/user, mob/living/target)
	return "[user] [get_generic_force_adjective()] rattles [user.p_their()] funny bone in [target]'s ass."

/datum/sex_action/npc/npc_anal_sex/funny_bone/get_finish_message(mob/living/user, mob/living/target)
	return "[user] pops [user.p_their()] funny bone out of [target]'s butt."

/datum/sex_action/npc/npc_anal_sex/funny_bone/handle_climax_message(mob/living/user, mob/living/target, must_flip)
	if(must_flip)
		user.visible_message(span_love("[user] cums with [user.p_their()] butt from [target]'s rattling funny bone!"))
		user.lose_virginity()
		target.lose_virginity()
		return ORGASM_LOCATION_SELF
	user.visible_message(span_love("[user]'s funny bone clatters in [target]'s butt, but nothing comes of it!"))
	return ORGASM_LOCATION_SELF

/datum/sex_action/npc/npc_vaginal_sex/funny_bone
	name = "NPC Rattle a funny bone in their cunt"

/datum/sex_action/npc/npc_vaginal_sex/funny_bone/get_start_message(mob/living/user, mob/living/target)
	return "[user] slides [user.p_their()] funny bone into [target]'s cunt with a creak!"

/datum/sex_action/npc/npc_vaginal_sex/funny_bone/get_perform_message(mob/living/user, mob/living/target)
	return "[user] [get_generic_force_adjective()] rattles [user.p_their()] funny bone in [target]'s pussy."

/datum/sex_action/npc/npc_vaginal_sex/funny_bone/get_finish_message(mob/living/user, mob/living/target)
	return "[user] pulls [user.p_their()] funny bone out of [target]'s pussy with a hollow clack."

/datum/sex_action/npc/npc_vaginal_sex/funny_bone/handle_climax_message(mob/living/user, mob/living/target, must_flip)
	if(must_flip)
		user.visible_message(span_love("[user] creams [user.p_them()]self around [target]'s funny bone!"))
		user.lose_virginity()
		target.lose_virginity()
		return ORGASM_LOCATION_ONTO
	user.visible_message(span_love("[user]'s funny bone clatters in [target]'s pussy, but nothing comes of it!"))
	return ORGASM_LOCATION_SELF

/datum/sex_action/npc/npc_jerk_over/funny_bone
	name = "NPC Polish a funny bone over them"

/datum/sex_action/npc/npc_jerk_over/funny_bone/get_start_message(mob/living/user, mob/living/target)
	return "[user] grips [user.p_their()] funny bone and points it at [target]..."

/datum/sex_action/npc/npc_jerk_over/funny_bone/get_perform_message(mob/living/user, mob/living/target)
	return "[user] [get_generic_force_adjective()] polishes [user.p_their()] funny bone over [target]..."

/datum/sex_action/npc/npc_jerk_over/funny_bone/get_finish_message(mob/living/user, mob/living/target)
	return "[user] stops polishing [user.p_their()] funny bone."

/datum/sex_action/npc/npc_jerk_over/funny_bone/handle_climax_message(mob/living/user, mob/living/target, must_flip)
	user.visible_message(span_love("[user]'s funny bone rattles over [target], but nothing comes of it!"))
	return ORGASM_LOCATION_SELF

/// What a skeleton with nothing below the belt does instead: cold, rattling pets.
/datum/sex_action/npc/npc_bony_petting
	name = "NPC Pet them with bony fingers"

/datum/sex_action/npc/npc_bony_petting/shows_on_menu(mob/living/user, mob/living/target)
	return FALSE

/datum/sex_action/npc/npc_bony_petting/can_perform(mob/living/user, mob/living/target)
	. = ..()
	if(!. || user == target)
		return FALSE
	return !!target.get_bodypart(BODY_ZONE_HEAD)

/datum/sex_action/npc/npc_bony_petting/on_start(mob/living/user, mob/living/target)
	. = ..()
	if(!.)
		return
	user.visible_message(span_warning("[user] reaches for [target] with cold, clicking finger bones."))

/datum/sex_action/npc/npc_bony_petting/on_perform(mob/living/user, mob/living/target)
	. = ..()
	if(can_show_action_message(user, target))
		user.visible_message(span_love(pick(
			"[user] pats [target]'s head with cold, bony fingers.",
			"[user] strokes [target]'s hair, finger bones clicking softly.",
			"[user] scratches behind [target]'s ear with a bony fingertip.",
			"[user] gives [target] an awkward, rattling pet.",
		)))
	perform_sex_action(target, user, 0.4, 0, 0.2)
	// The skeleton enjoys it most; its climax is what ends the scene.
	perform_sex_action(user, target, 1.5, 0, 1.5)

/datum/sex_action/npc/npc_bony_petting/on_finish(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("[user] draws [user.p_their()] bony hand back from [target]."))
