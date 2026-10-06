/*
 * ============================================================================
 * SOCIAL RECOGNITION SYSTEM
 * ============================================================================
 *
 * Layers:
 *
 * 1. EXAMINE SOCIAL CONTEXT
 *      Raw facts and visible social evidence.
 *
 * 2. SOCIAL PROFILE
 *      How a faction/status interprets that evidence.
 *
 * 3. SOCIAL RECOGNITION
 *      What the observer knows, sees, or infers.
 *
 * 4. SOCIAL REACTION
 *      Optional reaction to the recognition.
 *
 * The system does not create a second job/faction database.
 */

#define SOCIAL_SOURCE_KNOWLEDGE (1 << 0)
#define SOCIAL_SOURCE_COSMETIC (1 << 1)
#define SOCIAL_SOURCE_IDENTITY (1 << 2)
#define SOCIAL_SOURCE_PERSONNEL (1 << 3)
#define SOCIAL_SOURCE_STATUS (1 << 4)

#define SOCIAL_LEVEL_UNKNOWN 0
#define SOCIAL_LEVEL_APPARENT 1
#define SOCIAL_LEVEL_KNOWN 2

#define SOCIAL_PRESENTATION_INSUFFICIENT 0
#define SOCIAL_PRESENTATION_RECOGNIZABLE 1
#define SOCIAL_PRESENTATION_CONVINCING 2

/* Tune by content if necessary. Elite cues also contribute to this. */
#define SOCIAL_PRESTIGE_THRESHOLD 5


/*
 * ============================================================================
 * EXAMINE SOCIAL CONTEXT
 * ============================================================================
 */

/datum/examine_social_context
	var/mob/living/carbon/observer
	var/mob/living/carbon/target

	/* Objective target information. */
	var/datum/job/target_job
	var/target_wanted = FALSE

	/* Visibility. */
	var/target_face_visible = FALSE

	/* Visible social evidence. */
	var/list/visible_items = list()
	var/list/visible_social_cues = list()

	/* Universal visual status. */
	var/prestige_appearance_score = 0

	/* Kept as a compatibility alias for the old prototype typo. */
	var/elite_appearance_score = 0
	var/elite_apperance_score = 0

	/* Existing identity system. */
	var/identity_known = FALSE


/mob/living/carbon/proc/social_identity_is_known(mob/living/carbon/user)
	if(!user?.mind || !mind)
		return FALSE

	/* Direction is observer -> target. */
	return user.mind.do_i_know(mind, real_name)


/mob/living/carbon/proc/build_social_context(mob/living/carbon/user)
	var/datum/examine_social_context/context = new

	context.observer = user
	context.target = src
	context.target_job = mind?.assigned_role
	context.target_wanted = (real_name in GLOB.outlawed_players)

	/* Face visibility only controls the identity/personal-recognition path. */
	context.target_face_visible = IsAdminGhost(user) || is_human_part_visible(src, HIDEFACE)

	if(ishuman(src))
		var/mob/living/carbon/human/H = src
		context.visible_items = H.get_unobscured_social_items()

		for(var/obj/item/I as anything in context.visible_items)
			if(!I)
				continue

			var/list/item_cues = I.get_social_cues()
			if(!item_cues)
				continue

			for(var/cue_key in item_cues)
				var/cue_value = item_cues[cue_key]
				if(isnull(cue_value) || !cue_value)
					continue

				if(isnull(context.visible_social_cues[cue_key]))
					context.visible_social_cues[cue_key] = cue_value
				else
					context.visible_social_cues[cue_key] += cue_value

	/*
	 * Elite equipment is also visible prestige.
	 * Items do not need a second prestige cue just because they are elite.
	 */
	var/generic_prestige = context.visible_social_cues["prestige"]
	if(generic_prestige)
		context.prestige_appearance_score = generic_prestige

	for(var/cue_key in context.visible_social_cues)
		if(findtext(cue_key, "elite:") == 1)
			context.prestige_appearance_score += context.visible_social_cues[cue_key]

	context.elite_appearance_score = context.prestige_appearance_score
	context.elite_apperance_score = context.elite_appearance_score

	if(context.target_face_visible)
		context.identity_known = src.social_identity_is_known(user)

	return context


/mob/living/carbon/human/proc/get_unobscured_social_items()
	var/list/result = list()
	var/list/unobscured = get_unobscured_items(FALSE)

	for(var/obj/item/I as anything in unobscured)
		if(I)
			result += I

	/* Headgear remains useful social evidence even when it hides the face. */
	var/obj/item/head_item = get_item_by_slot(ITEM_SLOT_HEAD)
	if(head_item && !(head_item in result))
		result += head_item

	return result


/*
 * ============================================================================
 * SOCIAL PROFILE
 * ============================================================================
 *
 * Item social_cues use namespaces. Examples:
 *
 *     social_cues = list("faction:town_watch" = 7)
 *     social_cues = list("elite:town_watch" = 5)
 *     social_cues = list("prestige" = 3)
 *
 * The item declares evidence. The profile decides what that evidence means.
 */

/datum/social_profile
	var/id
	var/display_name

	/* Personnel/social familiarity traits. */
	var/recognition_trait
	var/rank_trait
	var/specialization_trait

	/* Local institutions are recognizable without special knowledge. */
	var/local_faction_knowledge = TRUE

	/* Namespaced item evidence. */
	var/faction_cue_key
	var/elite_cue_key
	var/list/rank_cue_keys = list()
	var/list/specialization_cue_keys = list()
	var/list/apparent_rank_titles = list()
	var/list/apparent_specialization_titles = list()

	/* Compatibility with older profile/debug code. */
	var/list/faction_cues = list()
	var/list/rank_cues = list()
	var/list/specialization_cues = list()
	var/cosmetic_threshold = 0
	var/specificity = 0

	/* Faction presentation. */
	var/faction_threshold = 0
	var/faction_solid_threshold = 0

	/* Elite equipment. */
	var/elite_threshold = 0
	var/elite_solid_threshold = 0

	/* Rank and specialization presentation. */
	var/rank_threshold = 0
	var/specialization_threshold = 0

	/* Only secret/identity-dependent profiles should set this TRUE. */
	var/face_required = FALSE

	/* Job-based familiarity with the elite subset. */
	var/list/elite_recognition_job_titles = list()
	var/list/elite_job_titles = list()

	/* Existing faction bitflag. */
	var/faction_flag = 0


/datum/social_profile/proc/matches_target(mob/living/carbon/target)
	if(!faction_flag)
		return FALSE

	var/datum/job/J = target.mind?.assigned_role
	if(!J)
		return FALSE

	return !!(J.department_flag & faction_flag)


/datum/social_profile/proc/matches_elite_target(mob/living/carbon/target)
	if(!length(elite_job_titles))
		return FALSE

	var/datum/job/J = target.mind?.assigned_role
	if(!J)
		return FALSE

	return J.title in elite_job_titles


/datum/social_profile/proc/get_cue_score(datum/examine_social_context/context, cue_key)
	if(!cue_key)
		return 0

	return context.visible_social_cues[cue_key] || 0


/*
 * Hidden rules belong here rather than as negative item cues.
 *
 * Example future rule:
 *     a real Watch member wearing an implausibly stripped-down uniform may
 *     receive a hidden concern modifier.
 *
 * The negative evidence itself is not shown to the player as a number.
 */
/datum/social_profile/proc/get_faction_appearance_modifier(datum/examine_social_context/context, datum/social_recognition/recognition)
	return 0


/datum/social_profile/proc/get_elite_appearance_modifier(datum/examine_social_context/context, datum/social_recognition/recognition)
	return 0


/datum/social_profile/proc/get_faction_appearance_score(datum/examine_social_context/context)
	if(faction_cue_key)
		return get_cue_score(context, faction_cue_key)

	/* Old profile-side cue compatibility. */
	var/score = 0
	for(var/cue_key in faction_cues)
		score += get_cue_score(context, cue_key) * faction_cues[cue_key]

	return score


/datum/social_profile/proc/get_elite_appearance_score(datum/examine_social_context/context)
	if(!elite_cue_key)
		return 0

	return get_cue_score(context, elite_cue_key)


/datum/social_profile/proc/get_rank_appearance_score(datum/examine_social_context/context)
	var/score = 0

	if(length(rank_cue_keys))
		for(var/cue_key in rank_cue_keys)
			score += get_cue_score(context, cue_key)
		return score

	for(var/cue_key in rank_cues)
		score += get_cue_score(context, cue_key) * rank_cues[cue_key]

	return score


/datum/social_profile/proc/get_specialization_appearance_score(datum/examine_social_context/context)
	var/score = 0

	for(var/cue_key in apparent_specialization_titles)
		score += get_cue_score(context, cue_key)

	return score


/* Older debug compatibility. */
/datum/social_profile/proc/get_cosmetic_score(datum/examine_social_context/context)
	return get_faction_appearance_score(context)


/datum/social_profile/proc/get_presentation_state(appearance_score)
	if(faction_solid_threshold > 0 && appearance_score >= faction_solid_threshold)
		return SOCIAL_PRESENTATION_CONVINCING

	if(faction_threshold > 0 && appearance_score >= faction_threshold)
		return SOCIAL_PRESENTATION_RECOGNIZABLE

	return SOCIAL_PRESENTATION_INSUFFICIENT


/*
 * Apparent rank/specialization deliberately use visible evidence instead of
 * the target's actual job. Profiles can override these with cue-specific logic.
 */
/datum/social_profile/proc/get_apparent_rank(mob/living/carbon/target, datum/examine_social_context/context, datum/social_recognition/recognition)
	var/best_score = 0
	var/best_title

	for(var/cue_key in apparent_rank_titles)
		var/cue_score = get_cue_score(context, cue_key)
		if(cue_score > best_score)
			best_score = cue_score
			best_title = apparent_rank_titles[cue_key]

	return best_title


/datum/social_profile/proc/get_apparent_specialization(mob/living/carbon/target, datum/examine_social_context/context, datum/social_recognition/recognition)
	var/best_score = 0
	var/best_title

	for(var/cue_key in apparent_specialization_titles)
		var/cue_score = get_cue_score(context, cue_key)
		if(cue_score > best_score)
			best_score = cue_score
			best_title = apparent_specialization_titles[cue_key]

	return best_title


/datum/social_profile/proc/can_recognize(mob/living/carbon/user, datum/examine_social_context/context)
	if(face_required && !context.target_face_visible)
		return FALSE

	var/faction_score = get_faction_appearance_score(context)
	var/elite_score = get_elite_appearance_score(context)
	var/rank_score = get_rank_appearance_score(context)
	var/specialization_score = get_specialization_appearance_score(context)

	/* Ordinary local knowledge recognizes public institutions by appearance. */
	if(local_faction_knowledge)
		if(faction_threshold > 0 && faction_score >= faction_threshold)
			return TRUE

		if(elite_threshold > 0 && elite_score >= elite_threshold)
			return TRUE

	/* Personnel familiarity is job/trait based. */
	if(recognition_trait && HAS_MIND_TRAIT(user, recognition_trait))
		if(context.target_face_visible && matches_target(context.target))
			return TRUE

	/* Rank and specialization remain privileged recognition paths. */
	if(rank_trait && HAS_MIND_TRAIT(user, rank_trait))
		if(rank_threshold > 0 && rank_score >= rank_threshold)
			return TRUE
		if(context.identity_known && matches_target(context.target))
			return TRUE

	if(specialization_trait && HAS_MIND_TRAIT(user, specialization_trait))
		if(specialization_threshold > 0 && specialization_score >= specialization_threshold)
			return TRUE
		if(context.identity_known && matches_target(context.target))
			return TRUE

	/* Hidden factions require deliberate knowledge of the faction/person. */
	if(!local_faction_knowledge && recognition_trait)
		if(HAS_MIND_TRAIT(user, recognition_trait))
			if(context.identity_known && matches_target(context.target))
				return TRUE

	return FALSE


/*
 * ============================================================================
 * SOCIAL RECOGNITION
 * ============================================================================
 */

/datum/social_recognition
	var/datum/social_profile/profile

	/* Objective truth. */
	var/actual_faction = FALSE
	var/actual_elite = FALSE

	/* Knowledge. */
	var/known_faction = FALSE
	var/known_rank = FALSE
	var/known_specialization = FALSE
	var/known_elite = FALSE
	var/identity_recognized = FALSE
	var/personnel_recognized = FALSE

	/* Appearance. */
	var/apparent_faction = FALSE
	var/apparent_rank = FALSE
	var/apparent_specialization = FALSE
	var/elite_equipment_recognized = FALSE
	var/apparent_elite_member = FALSE

	/* Experienced observer contradictions. */
	var/personnel_mismatch = FALSE
	var/elite_personnel_mismatch = FALSE
	var/presentation_concern = FALSE

	/* Presentation and internal legitimacy. */
	var/presentation_state = SOCIAL_PRESENTATION_INSUFFICIENT
	var/solid_faction = FALSE
	var/social_legitimacy = "unknown"

	/* Scores. */
	var/faction_appearance_score = 0
	var/elite_appearance_score = 0
	var/rank_appearance_score = 0
	var/specialization_appearance_score = 0
	var/prestige_appearance_score = 0

	/* Debug/source bookkeeping. */
	var/source = 0
	var/score = 0

	/* Compatibility flags. */
	var/faction_recognized = FALSE
	var/rank_recognized = FALSE
	var/specialization_recognized = FALSE


/mob/living/carbon/proc/resolve_social_profile(mob/living/carbon/user, datum/examine_social_context/context, datum/social_profile/profile)
	if(!profile)
		return null

	var/datum/social_recognition/recognition = new
	recognition.profile = profile

	/* Objective truth. */
	recognition.actual_faction = profile.matches_target(context.target)
	recognition.actual_elite = profile.matches_elite_target(context.target)

	/* Universal visual status. */
	recognition.prestige_appearance_score = context.prestige_appearance_score

	/* Personal identity. */
	if(context.identity_known)
		recognition.identity_recognized = TRUE
		recognition.source |= SOCIAL_SOURCE_IDENTITY

	/* Appearance. */
	var/faction_modifier = profile.get_faction_appearance_modifier(context, recognition)
	recognition.faction_appearance_score = max(profile.get_faction_appearance_score(context) + faction_modifier, 0)

	var/elite_modifier = profile.get_elite_appearance_modifier(context, recognition)
	recognition.elite_appearance_score = max(profile.get_elite_appearance_score(context) + elite_modifier, 0)

	recognition.rank_appearance_score = max(profile.get_rank_appearance_score(context), 0)

	recognition.specialization_appearance_score = max(profile.get_specialization_appearance_score(context), 0)

	recognition.presentation_state = profile.get_presentation_state(recognition.faction_appearance_score)
	recognition.solid_faction = (recognition.presentation_state == SOCIAL_PRESENTATION_CONVINCING)

	/* Public faction recognition. */
	if(
		profile.local_faction_knowledge && \
		profile.faction_threshold > 0 && \
		recognition.faction_appearance_score >= profile.faction_threshold
	)
		recognition.apparent_faction = TRUE
		recognition.source |= SOCIAL_SOURCE_COSMETIC

	/*
	 * Personnel familiarity.
	 *
	 * This is job/trait based rather than a hierarchy database. Seeing the face
	 * is the important discriminator for "I know my people" recognition.
	 */
	if(
		profile.recognition_trait && \
		HAS_MIND_TRAIT(user, profile.recognition_trait) && \
		context.target_face_visible
	)
		if(recognition.actual_faction)
			recognition.personnel_recognized = TRUE
			recognition.known_faction = TRUE
			recognition.source |= SOCIAL_SOURCE_PERSONNEL | SOCIAL_SOURCE_KNOWLEDGE
		else if(recognition.apparent_faction)
			recognition.personnel_mismatch = TRUE

	/*
	 * Secret/antagonistic faction recognition uses the identity/knowledge path.
	 */
	if(!profile.local_faction_knowledge)
		if(
			profile.recognition_trait && \
			HAS_MIND_TRAIT(user, profile.recognition_trait) && \
			context.identity_known && \
			recognition.actual_faction
		)
			recognition.known_faction = TRUE
			recognition.source |= SOCIAL_SOURCE_KNOWLEDGE

	/* Personal identity overrides misleading clothing when the observer has the required familiarity. */
	if(
		recognition.identity_recognized && \
		profile.recognition_trait && \
		HAS_MIND_TRAIT(user, profile.recognition_trait) && \
		recognition.actual_faction
	)
		recognition.personnel_recognized = TRUE
		recognition.known_faction = TRUE
		recognition.source |= SOCIAL_SOURCE_PERSONNEL | SOCIAL_SOURCE_KNOWLEDGE

	/* Elite equipment is ordinary local visual knowledge. */
	if(
		profile.elite_threshold > 0 && \
		recognition.elite_appearance_score >= profile.elite_threshold
	)
		recognition.elite_equipment_recognized = TRUE
		recognition.source |= SOCIAL_SOURCE_STATUS | SOCIAL_SOURCE_COSMETIC

	/*
	 * Elite member inference requires the normal faction presentation to be
	 * convincing and the elite equipment itself to meet its solid threshold.
	 * This prevents an elite helmet from becoming an elite identity by itself.
	 */
	if(
		recognition.presentation_state == SOCIAL_PRESENTATION_CONVINCING && \
		recognition.elite_equipment_recognized && \
		(
			profile.elite_solid_threshold <= 0 || \
			recognition.elite_appearance_score >= profile.elite_solid_threshold
		)
	)
		recognition.apparent_elite_member = TRUE

	/*
	 * Leaders/experienced jobs can recognize the elite subset as personnel.
	 * This is explicitly job-based instead of being inferred from rank order.
	 */
	var/datum/job/observer_job = user.mind?.assigned_role
	if(
		context.target_face_visible && \
		observer_job && \
		length(profile.elite_recognition_job_titles) && \
		(observer_job.title in profile.elite_recognition_job_titles)
	)
		if(recognition.actual_elite)
			recognition.known_elite = TRUE
			recognition.known_faction = TRUE
			recognition.personnel_recognized = TRUE
			recognition.source |= SOCIAL_SOURCE_PERSONNEL | SOCIAL_SOURCE_KNOWLEDGE
		else if(recognition.apparent_elite_member)
			recognition.elite_personnel_mismatch = TRUE

	/* Known rank. */
	if(
		profile.rank_trait && \
		HAS_MIND_TRAIT(user, profile.rank_trait) && \
		context.target_job
	)
		if(recognition.identity_recognized || recognition.known_faction)
			recognition.known_rank = TRUE
			recognition.source |= SOCIAL_SOURCE_KNOWLEDGE

	/* Apparent rank. */
	if(
		profile.rank_trait && \
		HAS_MIND_TRAIT(user, profile.rank_trait) && \
		profile.rank_threshold > 0 && \
		recognition.rank_appearance_score >= profile.rank_threshold
	)
		recognition.apparent_rank = TRUE
		recognition.source |= SOCIAL_SOURCE_COSMETIC

	/* Known specialization. */
	if(
		profile.specialization_trait && \
		HAS_MIND_TRAIT(user, profile.specialization_trait) && \
		context.target.get_social_specialization()
	)
		if(recognition.identity_recognized || recognition.known_faction)
			recognition.known_specialization = TRUE
			recognition.source |= SOCIAL_SOURCE_KNOWLEDGE

	/* Apparent specialization. */
	if(
		profile.specialization_trait && \
		HAS_MIND_TRAIT(user, profile.specialization_trait) && \
		profile.specialization_threshold > 0 && \
		recognition.specialization_appearance_score >= profile.specialization_threshold
	)
		recognition.apparent_specialization = TRUE
		recognition.source |= SOCIAL_SOURCE_COSMETIC

	/* Compatibility flags. */
	recognition.faction_recognized = recognition.known_faction || recognition.apparent_faction
	recognition.rank_recognized = recognition.known_rank || recognition.apparent_rank
	recognition.specialization_recognized = recognition.known_specialization || recognition.apparent_specialization

	/* Internal legitimacy. */
	recognition.social_legitimacy = "unknown"
	if(recognition.presentation_state == SOCIAL_PRESENTATION_CONVINCING)
		if(recognition.actual_faction)
			recognition.social_legitimacy = "solid"
		else if(recognition.apparent_faction)
			recognition.social_legitimacy = "disguised"
	else if(recognition.faction_appearance_score > 0)
		if(recognition.actual_faction)
			recognition.social_legitimacy = "partial"
		else if(recognition.apparent_faction)
			recognition.social_legitimacy = "suspicious"

	/* Debug score. */
	recognition.score = max(recognition.faction_appearance_score, recognition.elite_appearance_score, recognition.prestige_appearance_score)

	if(recognition.known_faction)
		recognition.score = max(recognition.score, 100)

	if(recognition.identity_recognized)
		recognition.score = max(recognition.score, 150)

	/* Keep elite-equipment-only and contradiction results alive. */
	if(
		!recognition.identity_recognized && \
		!recognition.faction_recognized && \
		!recognition.rank_recognized && \
		!recognition.specialization_recognized && \
		!recognition.elite_equipment_recognized && \
		!recognition.personnel_mismatch && \
		!recognition.elite_personnel_mismatch
	)
		qdel(recognition)
		return null

	return recognition


/*
 * ============================================================================
 * SOCIAL ADAPTERS
 * ============================================================================
 */

/mob/living/carbon/proc/get_social_specialization()
	if(!mind?.assigned_role)
		return null

	var/datum/job/job = mind.assigned_role
	var/title = job.get_informed_title(src)
	if(!title || title == "Unassigned")
		return null

	return title


/*
 * ============================================================================
 * PROFILE DESCRIPTION
 * ============================================================================
 */

/datum/social_profile/proc/get_membership_phrase(qualifier = "")
	if(qualifier)
		return "[qualifier] member of [display_name]"
	return "a member of [display_name]"


/datum/social_profile/proc/get_elite_equipment_phrase()
	return "elite equipment associated with [display_name]"


/datum/social_profile/proc/get_description(mob/living/carbon/user, datum/examine_social_context/context, datum/social_recognition/recognition, list/P)
	var/primary_statement
	var/secondary_statement
	var/datum/job/J = context.target_job
	var/rank_title
	var/specialization_title
	var/show_job_title = recognition.presentation_state >= SOCIAL_PRESENTATION_RECOGNIZABLE
	var/pl = p_s()

	/* Known information takes precedence over appearance. */
	if(recognition.known_faction)
		if(recognition.known_elite)
			if(show_job_title && recognition.known_rank && J)
				rank_title = J.get_informed_title(context.target)

			if(rank_title)
				primary_statement = "[P[THEYRE]] the [rank_title] of [display_name], one of the faction's elite"
			else
				primary_statement = "[P[THEYRE]] an elite member of [display_name]"

		else if(show_job_title && recognition.known_rank && J)
			rank_title = J.get_informed_title(context.target)

			if(rank_title)
				primary_statement = "[P[THEYRE]] the [rank_title] of [display_name]"
			else
				primary_statement = "[P[THEYRE]] a member of [display_name]"

		else
			primary_statement = "[P[THEYRE]] a member of [display_name]"

		/* Visible clothing can still be notably incomplete. */
		if(
			recognition.faction_appearance_score > 0 && \
			recognition.presentation_state != SOCIAL_PRESENTATION_CONVINCING && \
			!recognition.elite_equipment_recognized
		)
			secondary_statement = "[P[THEIR]] current attire is incomplete"

	/* Convincing visual faction presentation. */
	else if(recognition.presentation_state == SOCIAL_PRESENTATION_CONVINCING)
		if(recognition.apparent_elite_member)
			primary_statement = "[P[THEY]] appear[pl] to be an elite member of [display_name]"
		else
			primary_statement = "[P[THEY]] appear[pl] to be a member of [display_name]"

	/* Recognizable but incomplete presentation. */
	else if(recognition.presentation_state == SOCIAL_PRESENTATION_RECOGNIZABLE)
		primary_statement = "[P[THEYRE]] wearing [display_name] garb, but the presentation looks incomplete"

	/* Personal identity without enough faction evidence. */
	else if(recognition.identity_recognized)
		primary_statement = "[P[THEYRE]] someone I recognize"

	/* Elite equipment remains independently visible. */
	if(recognition.elite_equipment_recognized && !recognition.apparent_elite_member && !secondary_statement)
		secondary_statement = "[P[THEYRE]] wearing [get_elite_equipment_phrase()]"

	/* Apparent rank. */
	if(
		!secondary_statement && \
		show_job_title && \
		!recognition.known_rank && \
		recognition.apparent_rank
	)
		rank_title = get_apparent_rank(context.target, context, recognition)
		if(rank_title)
			secondary_statement = "[P[THEY]] appear[pl] to hold the rank of [rank_title]"

	/* Specialization. */
	if(
		!secondary_statement && \
		show_job_title && \
		recognition.known_specialization
	)
		specialization_title = context.target.get_social_specialization()
		if(specialization_title)
			secondary_statement = "[P[THEYRE]] known to specialize as [specialization_title]"

	else if(
		!secondary_statement && \
		show_job_title && \
		recognition.apparent_specialization
	)
		specialization_title = get_apparent_specialization(context.target, context, recognition)
		if(specialization_title)
			secondary_statement = "[P[THEY]] appear[pl] to specialize as [specialization_title]"

	/* Experienced personnel contradiction overrides lesser secondary details. */
	if(recognition.elite_personnel_mismatch)
		secondary_statement = "I don't recognize [P[THEM]] as one of the [display_name] elite"
	else if(recognition.personnel_mismatch)
		secondary_statement = "I don't recognize [P[THEM]] as one of [display_name]"

	/* Universal prestige when no faction-specific statement explains it. */
	if(!primary_statement && !secondary_statement)
		if(context.prestige_appearance_score >= SOCIAL_PRESTIGE_THRESHOLD)
			primary_statement = "[P[THEY]] look[pl] unusually well-equipped"

	if(!primary_statement && !secondary_statement)
		return null

	if(!secondary_statement)
		return "[primary_statement]."

	if(!primary_statement)
		return "[secondary_statement]."

	return "[primary_statement]. [secondary_statement]."
/*
 * ============================================================================
 * SOCIAL REACTIONS
 * ============================================================================
 */

/datum/examine_social_reaction
	var/stress_type
	var/list/phrases = list()


/datum/examine_social_reaction/proc/get_phrase()
	if(!length(phrases))
		return null
	return pick(phrases)


/*
 * ============================================================================
 * FACTION RELATIONSHIP DETERMINATION
 * ============================================================================
 *
 * Directional by design.
 */

/mob/living/carbon/proc/get_faction_relationship(user_faction, target_faction)
	if(user_faction & target_faction)
		return "allied"

	if((user_faction & TOWNWATCH) && (target_faction & VILLAINS))
		return "hostile"

	if((user_faction & TOWNWATCH) && (target_faction & TOWNHALL))
		return "protect_duty"

	if((user_faction & TOWNHALL) && (target_faction & VILLAINS))
		return "diplomatic_hostile"

	/* Deliberately asymmetric reverse relationship. */
	if((user_faction & VILLAINS) && (target_faction & TOWNWATCH))
		return "hostile_to_watch"

	if((user_faction & SCHOLARS) && (target_faction & CHAPEL))
		return "tense"

	if((user_faction & TRADERS) && (target_faction & TAVERN))
		return "tense"

	return "neutral"


/datum/social_profile/proc/get_profile_faction_flag()
	return faction_flag


/*
 * ============================================================================
 * REACTION GENERATION
 * ============================================================================
 */

/datum/social_profile/proc/get_reactions(mob/living/carbon/user, datum/examine_social_context/context, datum/social_recognition/recognition, list/reactions)
	/* Personnel contradictions take priority over normal faction feelings. */
	if(recognition.elite_personnel_mismatch)
		var/datum/examine_social_reaction/elite_mismatch = new
		elite_mismatch.stress_type = /datum/stress_event/paranoia
		elite_mismatch.phrases = list(
			"That's elite gear, but they're not one of the people who should be wearing it.",
			"I know who is supposed to hold that standing. This isn't one of them.",
			"Those are the marks of one of our elites. The person wearing them is not."
		)
		reactions += elite_mismatch
		return

	if(recognition.personnel_mismatch)
		var/datum/examine_social_reaction/personnel_mismatch = new
		personnel_mismatch.stress_type = /datum/stress_event/paranoia
		personnel_mismatch.phrases = list(
			"I know my people. This isn't one of them.",
			"Something is wrong. I don't recognize this person as one of ours.",
			"That's our uniform, but not one of our people."
		)
		reactions += personnel_mismatch
		return

	/* Known outlaw identification remains a positive identification. */
	if(id == "outlaw" && recognition.known_faction)
		var/datum/examine_social_reaction/known_outlaw = new
		known_outlaw.stress_type = /datum/stress_event/paranoia
		known_outlaw.phrases = list(
			"I'm certain they're an outlaw.",
			"I know what they are. An outlaw.",
			"That's an outlaw. I recognize them.",
			"There's no mistaking it. They're an outlaw."
		)
		reactions += known_outlaw
		return

	if(!recognition.faction_recognized)
		return

	if(!user.mind?.assigned_role)
		return

	var/user_faction = user.mind.assigned_role.department_flag
	var/target_faction = get_profile_faction_flag()
	if(!target_faction)
		return

	var/relationship = user.get_faction_relationship(user_faction, target_faction)

	if(should_be_suspicious(user, context, recognition))
		var/datum/examine_social_reaction/wary_presentation = new
		wary_presentation.stress_type = /datum/stress_event/paranoia
		wary_presentation.phrases = list(
			"Something about their presentation doesn't add up.",
			"Something is wrong with the way they're presenting themselves.",
			"That isn't how this should look."
		)
		reactions += wary_presentation
		return

	switch(relationship)
		if("allied")
			var/datum/examine_social_reaction/allied = new
			allied.stress_type = /datum/stress_event/fellow
			allied.phrases = list(
				"Good. I'm not the one here.",
				"It's always nice to feel that I have someone to rely on.",
				"Staying together is always better than working on my own here."
			)
			reactions += allied

		if("protect_duty")
			var/datum/examine_social_reaction/protect_duty = new
			protect_duty.phrases = list(
				"My job is to keep them safe.",
				"I'm paid to protect them.",
				"Best to be nearby in case of emergency."
			)
			reactions += protect_duty

		if("higher_rank")
			var/datum/examine_social_reaction/higher_rank = new
			higher_rank.stress_type = /datum/stress_event/highrank_respect
			higher_rank.phrases = list(
				"At least someone to rely on.",
				"Better obey their orders; their rank is higher than mine.",
				"Good, someone actually viable here."
			)
			reactions += higher_rank

		if("cooperative")
			var/datum/examine_social_reaction/cooperative = new
			cooperative.stress_type = /datum/stress_event/rely_on
			cooperative.phrases = list(
				"Better to work with them for my own interests.",
				"They'll protect me if we are on good terms, right?",
				"Great, someone who will help me if things get ugly."
			)
			reactions += cooperative

		if("loyal")
			var/datum/examine_social_reaction/loyal = new
			loyal.phrases = list(
				"My job is to serve them.",
				"I should be ready to assist, if necessary.",
				"Should be ready to serve; that's why I'm here."
			)
			reactions += loyal

		if("seperated_authority")
			var/datum/examine_social_reaction/seperated_authority = new
			seperated_authority.phrases = list(
				"We have the same interests, but not jurisdictions.",
				"Someone has to keep an eye on the town, and someone stays in the dark forest.",
				"Only if we weren't separated..."
			)
			reactions += seperated_authority

		if("tense")
			var/datum/examine_social_reaction/tense = new
			tense.stress_type = /datum/stress_event/tense
			tense.phrases = list(
				"We have different interests.",
				"I should be careful around them.",
				"Best to keep distance."
			)
			reactions += tense

		if("diplomatic_hostile")
			var/datum/examine_social_reaction/diplomatic_hostile = new
			diplomatic_hostile.stress_type = /datum/stress_event/unease
			diplomatic_hostile.phrases = list(
				"Not a place for THEM.",
				"Better call someone who can get rid of this person.",
				"Best to stay aware with THOSE walking here."
			)
			reactions += diplomatic_hostile

		if("hostile")
			var/datum/examine_social_reaction/hostile = new
			hostile.stress_type = /datum/stress_event/fearful
			hostile.phrases = list(
				"Trouble. I don't want them near me.",
				"I should keep my distance from them.",
				"Best not to draw their attention."
			)
			reactions += hostile

		if("hostile_to_watch")
			var/datum/examine_social_reaction/hostile_to_watch = new
			hostile_to_watch.stress_type = /datum/stress_event/outlaw_near_watch
			hostile_to_watch.phrases = list(
				"A lawman... What a day to live.",
				"I should be careful around those bastards.",
				"Better prepare myself if they are upon my track."
			)
			reactions += hostile_to_watch

		if("fearful")
			var/datum/examine_social_reaction/fearful = new
			fearful.stress_type = /datum/stress_event/fearful
			fearful.phrases = list(
				"Damn it, don't wanna fall in their hands!",
				"What?! How did this person manage to GET here!?",
				"No, no, no, no, please tell me it's not them!"
			)
			reactions += fearful

		if("disagreeing")
			var/datum/examine_social_reaction/disagreeing = new
			disagreeing.phrases = list(
				"We have different ways to live this life.",
				"It's annoying to stay with someone who devoted their life to this.",
				"Why won't we get along?"
			)
			reactions += disagreeing

		if("neutral")
			return


/datum/social_profile/proc/should_be_suspicious(mob/living/carbon/user, datum/examine_social_context/context, datum/social_recognition/recognition)
	/* Only explicit lore anchors should produce hidden suspicion. */
	return FALSE


/*
 * ============================================================================
 * GLOBAL PROFILE REGISTRY
 * ============================================================================
 */

GLOBAL_LIST_INIT(social_profiles, list(
	new /datum/social_profile/town_watch,
	new /datum/social_profile/outlaw
))


/*
 * ============================================================================
 * RESOLVE ALL SOCIAL PROFILES
 * ============================================================================
 */

/mob/living/carbon/proc/get_social_recognitions(mob/living/carbon/user, datum/examine_social_context/context)
	var/list/recognitions = list()

	for(var/datum/social_profile/profile as anything in GLOB.social_profiles)
		if(!profile)
			continue

		if(!profile.can_recognize(user, context))
			continue

		var/datum/social_recognition/recognition = \
			resolve_social_profile(user, context, profile)

		if(recognition)
			recognitions += recognition

	return recognitions


/*
 * ============================================================================
 * TOWN WATCH
 * ============================================================================
 */

/datum/social_profile/town_watch
	id = "town_watch"
	display_name = "the Town Watch"
	faction_flag = TOWNWATCH
	faction_cue_key = "faction:town_watch"
	elite_cue_key = "elite:town_watch"
	specialization_cue_keys = "specialization:"

	recognition_trait = TRAIT_KNOW_WATCH
	rank_trait = TRAIT_KNOW_WATCH_RANK
	specialization_trait = TRAIT_KNOW_WATCH_SPECIALIZATION

	faction_threshold = 10
	faction_solid_threshold = 15

	elite_threshold = 3
	elite_solid_threshold = 5

	rank_threshold = 3
	specialization_threshold = 3

	rank_cue_keys = list(
		"rank:town_watch:captain",
		"rank:town_watch:sergeant",
		"rank:town_watch:warden",
		"rank:town_watch:guard"
	)

	apparent_rank_titles = list(
		"rank:town_watch:captain" = "Town Watch Captain",
		"rank:town_watch:sergeant" = "Town Watch Sergeant",
		"rank:town_watch:warden" = "Town Watch Warden",
		"rank:town_watch:guard" = "Town Watch Guard"
	)

	apparent_specialization_titles = list(
		"specialization:prosecutor" = "Prosecutor",
		"specialization:executioner" = "Executioner",
		"specialization:Juggernaut" = "Juggernaut",
		"specialization:Charm" = "Charm of the corps"
	)

	/* High-status Watch roles are treated as the elite subset. */
	elite_job_titles = list(
		"Town Watch Captain",
		"Town Watch Sergeant",
		"Town Watch Warden"
	)

	/* Leaders/experienced Watch personnel and the Burgmeister know the elite subset. */
	elite_recognition_job_titles = list(
		"Burgmeister",
		"Town Watch Captain",
		"Town Watch Sergeant",
		"Town Watch Warden"
	)

	/* Compatibility/debug fields. */
	cosmetic_threshold = 5
	specificity = 50


/datum/social_profile/town_watch/get_membership_phrase(qualifier = "")
	if(qualifier)
		return "[qualifier] member of the Town Watch"
	return "a member of the Town Watch"


/datum/social_profile/town_watch/get_elite_equipment_phrase()
	return "elite Town Watch equipment"


/* No generic negative deduction; add only lore-specific anchors here. */
/datum/social_profile/town_watch/get_faction_appearance_modifier(datum/examine_social_context/context, datum/social_recognition/recognition)
	return 0


/*
 * ============================================================================
 * OUTLAW
 * ============================================================================
 */

/datum/social_profile/outlaw
	id = "outlaw"
	display_name = "an outlaw"
	faction_flag = VILLAINS
	local_faction_knowledge = FALSE
	recognition_trait = TRAIT_KNOWBANDITS
	face_required = TRUE


/datum/social_profile/outlaw/matches_target(mob/living/carbon/target)
	return target.real_name in GLOB.outlawed_players


/datum/social_profile/outlaw/get_membership_phrase(qualifier = "")
	return "an outlaw"


/datum/social_profile/outlaw/get_description(mob/living/carbon/user, datum/examine_social_context/context, datum/social_recognition/recognition, list/P)
	if(recognition.known_faction)
		return "[P[THEYRE]] an outlaw."

	if(recognition.identity_recognized)
		return "[P[THEYRE]] someone I recognize."

	return null


/*
 * ============================================================================
 * REACTION RESOLUTION
 * ============================================================================
 */

/mob/living/carbon/proc/resolve_strongest_social_reaction(mob/living/carbon/user, list/reactions)
	var/datum/examine_social_reaction/best_reaction
	var/best_strength = -INFINITY
	var/datum/examine_social_reaction/first_phrase_only

	for(var/datum/examine_social_reaction/reaction as anything in reactions)
		if(!reaction)
			continue

		if(!reaction.stress_type)
			if(!first_phrase_only)
				first_phrase_only = reaction
			continue

		if(user.has_stress_type(reaction.stress_type))
			continue

		var/datum/stress_event/event = new reaction.stress_type
		if(!event.can_apply(user))
			qdel(event)
			continue

		var/stress_value = event.get_stress(user)
		var/strength = abs(stress_value)
		if(strength > best_strength)
			best_strength = strength
			best_reaction = reaction

		qdel(event)

	if(best_reaction)
		return best_reaction

	return first_phrase_only


/*
 * ============================================================================
 * SOCIAL EXAMINE ENTRY POINT
 * ============================================================================
 */

/mob/living/carbon/proc/get_examine_social(mob/living/carbon/user, list/P, list/examine_list)
	. = list()

	if(user == src)
		return
	if(!isliving(user))
		return

	var/datum/examine_social_context/context = build_social_context(user)
	if(!context)
		return

	var/list/recognitions = get_social_recognitions(user, context)
	var/list/descriptions = list()

	for(var/datum/social_recognition/recognition as anything in recognitions)
		var/description = recognition.profile.get_description(user, context, recognition, P)
		if(description)
			descriptions += description

	/* Universal prestige, unless already expressed through elite equipment. */
	if(context.prestige_appearance_score >= SOCIAL_PRESTIGE_THRESHOLD)
		var/show_generic_prestige = TRUE
		for(var/datum/social_recognition/recognition as anything in recognitions)
			if(recognition.elite_equipment_recognized || recognition.apparent_elite_member)
				show_generic_prestige = FALSE
				break

		if(show_generic_prestige)
			descriptions += "[P[THEY]] look unusually well-equipped."

	/* De-duplicate descriptions. */
	for(var/description in descriptions)
		if(!description)
			continue
		if(description in .)
			continue
		. += description

	/* Reactions remain independent from recognition descriptions. */
	var/list/reactions = list()
	for(var/datum/social_recognition/recognition as anything in recognitions)
		recognition.profile.get_reactions(user, context, recognition, reactions)

	var/datum/examine_social_reaction/best_reaction = \
		resolve_strongest_social_reaction(user, reactions)

	if(best_reaction)
		var/phrase = best_reaction.get_phrase()
		if(phrase)
			. += phrase

		if(best_reaction.stress_type)
			user.add_stress(best_reaction.stress_type)
