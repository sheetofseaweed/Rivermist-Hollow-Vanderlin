GLOBAL_LIST_EMPTY(heraldboard_notices)
GLOBAL_LIST_EMPTY(heraldboard_listings)

// Re-opens SSroguemachine (defined upstream in
// code/controllers/subsystem/roguemachine.dm via PROCESSING_SUBSYSTEM_DEF) to
// add the one var this feature needs, instead of touching that file. DM
// merges every declaration of a type across the whole codebase, so this is
// enough - no core patch required.
/datum/controller/subsystem/processing/roguemachine
	var/list/heraldboards = list()


#define POSTING_TIER_NOTICE "notice"
#define POSTING_TIER_LISTING "listing"

#define HERALDBOARD_NOTICE_LIFETIME (30 MINUTES)

#define HERALDBOARD_TITLE_MAX_LENGTH 50
#define HERALDBOARD_BODY_MAX_LENGTH 500
#define HERALDBOARD_NAME_MAX_LENGTH 50
#define HERALDBOARD_ROLE_MAX_LENGTH 50

/// TRUE if this human may pin a no-expiry Standing Listing.
/obj/structure/fake_machine/heraldboard/proc/can_post_listing(mob/living/carbon/human/H)
	if(!istype(H) || !H.job)
		return FALSE
	var/datum/job/J = SSjob.GetJob(H.job)
	if(!J)
		return FALSE
	return istype(J, /datum/job/lord) || istype(J, /datum/job/captain)

/// TRUE if this human may tear down another's ordinary Notice.
/obj/structure/fake_machine/heraldboard/proc/can_authority_remove(mob/living/carbon/human/H)
	return can_post_listing(H) // same two roles cover both privileges on RMH

/datum/heraldboard_posting
	var/posting_id
	var/tier
	var/title
	var/body
	var/poster_name
	var/poster_title
	var/truename
	var/poster_job
	var/posted_at
	var/expiry_timer_id
	var/signature_attested

/datum/heraldboard_posting/New(tier, title, body, poster_name, poster_title, truename, poster_job)
	src.tier = tier
	src.title = title
	src.body = body
	src.poster_name = poster_name
	src.poster_title = poster_title
	src.truename = truename
	src.poster_job = poster_job
	src.posted_at = world.time
	src.posting_id = "[world.time]_[text_ref(src)]"
	src.signature_attested = (poster_name == truename) && (poster_title == poster_job)

/datum/heraldboard_posting/Destroy()
	if(expiry_timer_id)
		deltimer(expiry_timer_id)
		expiry_timer_id = null
	return ..()

/proc/heraldboard_get_list_for_tier(tier)
	switch(tier)
		if(POSTING_TIER_NOTICE)
			return GLOB.heraldboard_notices
		if(POSTING_TIER_LISTING)
			return GLOB.heraldboard_listings
	return null

/proc/heraldboard_find_post_by_truename(tier, truename)
	var/list/target = heraldboard_get_list_for_tier(tier)
	if(!target)
		return null
	for(var/datum/heraldboard_posting/P in target)
		if(P.truename == truename)
			return P
	return null

/proc/heraldboard_find_post_by_id(posting_id)
	for(var/datum/heraldboard_posting/P in GLOB.heraldboard_notices)
		if(P.posting_id == posting_id)
			return P
	for(var/datum/heraldboard_posting/P in GLOB.heraldboard_listings)
		if(P.posting_id == posting_id)
			return P
	return null

/proc/heraldboard_add_posting(tier, title, body, poster_name, poster_title, mob/living/carbon/human/poster)
	if(!poster || !ishuman(poster))
		return null
	if(tier != POSTING_TIER_NOTICE && tier != POSTING_TIER_LISTING)
		return null
	var/list/target_list = heraldboard_get_list_for_tier(tier)
	if(!target_list)
		return null
	var/datum/heraldboard_posting/existing = heraldboard_find_post_by_truename(tier, poster.real_name)
	if(existing)
		heraldboard_remove_posting(existing)
	var/datum/heraldboard_posting/new_post = new(tier, title, body, poster_name, poster_title, poster.real_name, poster.job)
	target_list += new_post
	if(tier == POSTING_TIER_NOTICE)
		new_post.expiry_timer_id = addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heraldboard_remove_posting), new_post), HERALDBOARD_NOTICE_LIFETIME, TIMER_STOPPABLE)
	heraldboard_broadcast_post_change(poster)
	return new_post

/proc/heraldboard_remove_posting(datum/heraldboard_posting/post)
	if(!post)
		return
	var/list/target_list = heraldboard_get_list_for_tier(post.tier)
	if(target_list)
		target_list -= post
	qdel(post)
	heraldboard_broadcast_post_change()

/// Pushes fresh data + icon to every board on the map and lets nearby folks
/// hear a courier land, unless they're the one who just posted/removed.
/proc/heraldboard_broadcast_post_change(mob/excluding)
	var/turf/excluding_turf = excluding ? get_turf(excluding) : null
	for(var/obj/structure/fake_machine/heraldboard/board in SSroguemachine.heraldboards)
		board.update_icon()
		SStgui.update_uis(board)
		if(excluding_turf && get_dist(board, excluding_turf) <= 1)
			continue
		playsound(board, 'sound/ambience/noises/birds (7).ogg', 50, FALSE, -1)
		board.visible_message(span_smallred("A courier bird lands, delivering a new posting!"))

/obj/structure/fake_machine/heraldboard
	name = "herald's board"
	desc = "A large wooden board bearing postings and proclamations from all across the realm."
	icon = 'modular_rmh/icons/obj/structures/heraldboard64.dmi'
	icon_state = "heraldboard0"
	density = TRUE
	blade_dulling = DULLING_BASH
	layer = ABOVE_MOB_LAYER
	plane = GAME_PLANE_UPPER

/obj/structure/fake_machine/heraldboard/Initialize()
	. = ..()
	SSroguemachine.heraldboards += src
	update_icon()

/obj/structure/fake_machine/heraldboard/Destroy()
	SSroguemachine.heraldboards -= src
	return ..()

/obj/structure/fake_machine/heraldboard/wall
	icon = 'modular_rmh/icons/obj/structures/heraldboard32.dmi'
	density = FALSE
	layer = ABOVE_MOB_LAYER
	pixel_y = 32

/obj/structure/fake_machine/heraldboard/wall/OnCrafted(dirin, mob/user)
	pixel_x = 0
	pixel_y = 0
	switch(dirin)
		if(NORTH)
			pixel_y = 32
		if(SOUTH)
			pixel_y = -32
		if(EAST)
			pixel_x = 32
		if(WEST)
			pixel_x = -32
	. = ..()

/obj/structure/fake_machine/heraldboard/update_icon()
	. = ..()
	var/total_length = length(GLOB.heraldboard_notices) + length(GLOB.heraldboard_listings)
	switch(total_length)
		if(0)
			icon_state = "heraldboard0"
		if(1 to 3)
			icon_state = "heraldboard1"
		if(4 to 6)
			icon_state = "heraldboard2"
		else
			icon_state = "heraldboard3"

/obj/structure/fake_machine/heraldboard/attack_hand(mob/user)
	. = ..()
	if(!ishuman(user))
		return
	ui_interact(user)

/obj/structure/fake_machine/heraldboard/ui_state(mob/user)
	return GLOB.human_adjacent_state

/obj/structure/fake_machine/heraldboard/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "HeraldBoard", name, 1000, 760)
		ui.open()

/obj/structure/fake_machine/heraldboard/ui_data(mob/user)
	var/list/data = list()
	data["scout_regions"] = build_scout_regions()
	if(!ishuman(user))
		data["postings"] = list()
		data["can_post_listing"] = FALSE
		data["can_authority_remove"] = FALSE
		data["user_default_name"] = ""
		data["user_default_role"] = ""
		data["has_active_notice"] = FALSE
		data["has_active_listing"] = FALSE
		return data
	var/mob/living/carbon/human/H = user
	var/can_listing = can_post_listing(H)
	var/can_auth_remove = can_authority_remove(H)
	var/list/postings = list()
	var/has_active_listing = FALSE
	var/has_active_notice = FALSE
	for(var/datum/heraldboard_posting/P in GLOB.heraldboard_listings)
		if(P.truename == H.real_name)
			has_active_listing = TRUE
		postings += list(serialize_posting(P, H, can_auth_remove))
	for(var/datum/heraldboard_posting/P in GLOB.heraldboard_notices)
		if(P.truename == H.real_name)
			has_active_notice = TRUE
		postings += list(serialize_posting(P, H, can_auth_remove))
	data["postings"] = postings
	data["can_post_listing"] = can_listing
	data["can_authority_remove"] = can_auth_remove
	data["user_default_name"] = H.real_name
	data["user_default_role"] = H.job || ""
	data["has_active_notice"] = has_active_notice
	data["has_active_listing"] = has_active_listing
	return data

/// Reads RMH's own SSregionthreat (nothing else consumed this proc before -
/// see code/controllers/subsystem/regional_threat.dm). No blockade/faction/
/// writ fields: RMH's threat regions don't track any of that, unlike Azure's.
/obj/structure/fake_machine/heraldboard/proc/build_scout_regions()
	var/list/rows = list()
	if(!SSregionthreat)
		return rows
	for(var/datum/threat_region_display/TRS in SSregionthreat.get_threat_regions_for_display())
		rows += list(list(
			"region_name" = TRS.region_name,
			"danger_level" = TRS.danger_level,
			"danger_color" = TRS.danger_color,
		))
		qdel(TRS) // transient display copy, only needed for the lines just above
	return rows

/obj/structure/fake_machine/heraldboard/proc/serialize_posting(datum/heraldboard_posting/P, mob/living/carbon/human/viewer, viewer_is_authority)
	var/list/entry = list()
	entry["posting_id"] = P.posting_id
	entry["tier"] = P.tier
	entry["title"] = P.title
	entry["body"] = P.body
	entry["poster_name"] = P.poster_name
	entry["poster_title"] = P.poster_title
	entry["signature_attested"] = P.signature_attested ? TRUE : FALSE
	entry["posted_at_label"] = format_posted_at_label(P.posted_at)
	entry["expires_in_label"] = (P.tier == POSTING_TIER_NOTICE) ? format_expires_in_label(P.posted_at) : ""
	entry["is_own"] = (viewer && P.truename == viewer.real_name) ? TRUE : FALSE
	entry["can_authority_remove"] = (viewer_is_authority && P.tier == POSTING_TIER_NOTICE) ? TRUE : FALSE
	return entry

/obj/structure/fake_machine/heraldboard/proc/format_posted_at_label(posted_at)
	var/elapsed = world.time - posted_at
	if(elapsed < 1 MINUTES)
		return "just now"
	var/minutes = round(elapsed / (1 MINUTES))
	if(minutes < 60)
		return "[minutes]m ago"
	var/hours = round(minutes / 60)
	return "[hours]h ago"

/obj/structure/fake_machine/heraldboard/proc/format_expires_in_label(posted_at)
	var/expires_at = posted_at + HERALDBOARD_NOTICE_LIFETIME
	var/remaining = expires_at - world.time
	if(remaining <= 0)
		return "any moment"
	var/minutes = CEILING(remaining / (1 MINUTES), 1)
	return "in [minutes]m"

/obj/structure/fake_machine/heraldboard/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	var/mob/living/carbon/human/H = usr
	if(!istype(H))
		return TRUE
	if(!H.can_perform_action(src, NEED_DEXTERITY|FORBID_TELEKINESIS_REACH))
		return TRUE
	switch(action)
		if("make_post")
			handle_make_post(H, params)
			return TRUE
		if("remove_post")
			handle_remove_post(H, params)
			return TRUE
		if("authority_remove_post")
			handle_authority_remove_post(H, params)
			return TRUE

/obj/structure/fake_machine/heraldboard/proc/handle_make_post(mob/living/carbon/human/H, list/params)
	var/tier = "[params["tier"]]"
	if(tier != POSTING_TIER_NOTICE && tier != POSTING_TIER_LISTING)
		to_chat(H, span_warning("Unknown posting kind."))
		return
	if(tier == POSTING_TIER_LISTING && !can_post_listing(H))
		to_chat(H, span_warning("Only the Lord or the Captain may pin a Standing Listing."))
		return
	var/title = sanitize_input("[params["title"]]", HERALDBOARD_TITLE_MAX_LENGTH)
	var/body = sanitize_input("[params["body"]]", HERALDBOARD_BODY_MAX_LENGTH, multiline = TRUE)
	var/poster_name = sanitize_input("[params["poster_name"]]", HERALDBOARD_NAME_MAX_LENGTH)
	var/poster_title = sanitize_input("[params["poster_title"]]", HERALDBOARD_ROLE_MAX_LENGTH)
	if(!title || !body || !poster_name)
		to_chat(H, span_warning("The posting must bear a title, a body, and a name."))
		return
	heraldboard_add_posting(tier, title, body, poster_name, poster_title, H)
	message_admins("[ADMIN_LOOKUPFLW(H)] has made a [tier] herald's board post. The message was: [body]")

/obj/structure/fake_machine/heraldboard/proc/handle_remove_post(mob/living/carbon/human/H, list/params)
	var/posting_id = "[params["posting_id"]]"
	var/datum/heraldboard_posting/P = heraldboard_find_post_by_id(posting_id)
	if(!P)
		return
	if(P.truename != H.real_name)
		to_chat(H, span_warning("That posting is not yours to take down."))
		return
	playsound(loc, 'sound/foley/dropsound/paper_drop.ogg', 50, FALSE, -1)
	loc.visible_message(span_smallred("[H] tears down a posting!"))
	heraldboard_remove_posting(P)
	message_admins("[ADMIN_LOOKUPFLW(H)] has removed their herald's board post.")

/obj/structure/fake_machine/heraldboard/proc/handle_authority_remove_post(mob/living/carbon/human/H, list/params)
	if(!can_authority_remove(H))
		to_chat(H, span_warning("You hold no authority to take down another's posting."))
		return
	var/posting_id = "[params["posting_id"]]"
	var/datum/heraldboard_posting/P = heraldboard_find_post_by_id(posting_id)
	if(!P)
		return
	if(P.tier == POSTING_TIER_LISTING)
		to_chat(H, span_warning("A Standing Listing may not be taken down by authority while its issuer lives."))
		return
	playsound(loc, 'sound/foley/dropsound/paper_drop.ogg', 50, FALSE, -1)
	loc.visible_message(span_smallred("[H] tears down a posting!"))
	heraldboard_remove_posting(P)
	message_admins("[ADMIN_LOOKUPFLW(H)] has authoritatively removed a herald's board post by [P.truename].")

/obj/structure/fake_machine/heraldboard/proc/sanitize_input(text, max_length, multiline = FALSE)
	if(!text || text == "null")
		return null
	text = trim(text)
	if(!length_char(text))
		return null
	if(length_char(text) > max_length)
		text = copytext_char(text, 1, max_length + 1)
	return text

#undef POSTING_TIER_NOTICE
#undef POSTING_TIER_LISTING
#undef HERALDBOARD_NOTICE_LIFETIME
#undef HERALDBOARD_TITLE_MAX_LENGTH
#undef HERALDBOARD_BODY_MAX_LENGTH
#undef HERALDBOARD_NAME_MAX_LENGTH
#undef HERALDBOARD_ROLE_MAX_LENGTH
// ==================== END HERALD'S BOARD ====================
