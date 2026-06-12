/datum/examine_panel
	/// Mob that the examine panel belongs to.
	var/mob/living/carbon/human/holder
	/// The screen containing the appearance of the mob
	var/atom/movable/screen/map_view/examine_panel_screen/examine_panel_screen

	var/datum/preferences/pref = null

	var/is_playing = FALSE

	var/mob/viewing

	/// Current direction of the character preview doll
	var/preview_dir = SOUTH
	/// Whether the viewer has opened the character preview (so we only flatten icons on demand)
	var/preview_requested = FALSE

/datum/examine_panel/New(mob/holder_mob)
	if(holder_mob)
		holder = holder_mob

/datum/examine_panel/Destroy(force)
	if(holder && viewing)
		LAZYREMOVE(holder.examine_panels, REF(viewing))
	holder = null
	viewing = null
	return ..()

/// Returns the base64 preview of the holder facing preview_dir, served from the mob-level cache.
/datum/examine_panel/proc/get_preview_image()
	var/mob/living/carbon/human/preview_mob = holder
	if(!ishuman(preview_mob))
		return ""
	return preview_mob.get_examine_preview(preview_dir)

// -------------------------------------------------------------------------
// Mob-level preview cache.
// Flattened previews are stored on the human itself, so any number of viewers
// opening/closing/spamming the examine panel share the same icons. The cache
// is invalidated whenever the mob's overlays change (clothes, limbs, wounds,
// blood - everything funnels through apply_overlay/remove_overlay), and
// rebuilds are throttled to at most once per second per mob.
// -------------------------------------------------------------------------

/// Throwaway render proxy for flattening examine previews, mirroring the
/// contract ledger's preview proxy. Exists only for the duration of one
/// getFlatIcon call.
/obj/effect/abstract/examine_preview_proxy
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE

/mob/living/carbon/human
	/// Open examine panels for this mob, indexed by REF of the viewing mob.
	/// Lets repeat "Examine Closer" clicks refocus the existing window.
	var/list/examine_panels
	/// Cached base64 examine previews, indexed by "[dir]"
	var/list/examine_preview_cache
	/// Whether the cached previews no longer match our current appearance
	var/examine_preview_dirty = TRUE
	/// world.time of the last cache wipe, for rebuild throttling
	var/examine_preview_last_wipe = 0

/// Marks the cached examine previews as stale. Cheap - safe to call often.
/mob/living/carbon/human/proc/dirty_examine_preview()
	examine_preview_dirty = TRUE

// Every visual change (equipment, bodyparts, wounds, blood overlays...)
// goes through these two procs, making them a perfect invalidation funnel.
/mob/living/carbon/human/apply_overlay(cache_index)
	. = ..()
	dirty_examine_preview()

/mob/living/carbon/human/remove_overlay(cache_index)
	dirty_examine_preview()
	return ..()

/**
 * Returns a base64 data URL of this human flattened via getFlatIcon in the wanted direction.
 * getFlatIcon ignores the mob's transform (so resize/height scaling and lying rotation are
 * stripped) and expands the canvas to fit every overlay, so oversized taur sprites
 * (64px icons with offset_x/body_offset_y) are included whole.
 *
 * When the appearance changed, the whole cache is wiped and directions are rebuilt lazily,
 * but no more than once per second - spam clicking or rapid re-equipping serves the
 * slightly stale image instead of hammering the icon blender.
 */
/// Fixed canvas size (px) for examine previews. Big enough for 64px taur
/// sprites with body offsets, and keeps the on-screen scale constant no matter
/// how far blood splatter or held items stretch the flattened bounding box.
#define EXAMINE_PREVIEW_CANVAS 96

/mob/living/carbon/human/proc/get_examine_preview(wanted_dir = SOUTH)
	if(examine_preview_dirty && world.time >= examine_preview_last_wipe + 1 SECONDS)
		examine_preview_cache = null
		examine_preview_dirty = FALSE
		examine_preview_last_wipe = world.time
	if(!examine_preview_cache)
		examine_preview_cache = list()
	var/dir_key = "[wanted_dir]"
	if(examine_preview_cache[dir_key])
		return examine_preview_cache[dir_key]
	// Flatten through a throwaway obj proxy (same recipe as the contract
	// ledger's target previews) rather than the mob or an appearance copy:
	// - the proxy's dir is fully ours, so the preview doesn't follow the
	//   mob's in-game facing and the rotate buttons work for all four sides
	//   (getFlatIcon lets a non-SOUTH appearance dir override defdir);
	// - /mutable_appearance/New() stomps plane to FLOAT_PLANE, which made
	//   getFlatIcon's plane filter skip every overlay carrying an explicit
	//   plane (hands, head) - an obj keeps a real plane like the mob does;
	// - transform is deliberately not copied, stripping resize/height
	//   scaling and lying rotation from the doll.
	var/obj/effect/abstract/examine_preview_proxy/render_proxy = new()
	render_proxy.icon = icon
	render_proxy.icon_state = icon_state
	render_proxy.dir = wanted_dir
	render_proxy.color = color
	render_proxy.alpha = alpha
	if(length(overlays))
		render_proxy.overlays = overlays.Copy()
	if(length(underlays))
		render_proxy.underlays = underlays.Copy()
	var/icon/flat_icon = getFlatIcon(render_proxy, wanted_dir, no_anim = TRUE)
	qdel(render_proxy)
	if(!flat_icon)
		return ""
	// Normalize to a fixed, centered canvas so the doll renders at the same
	// scale regardless of how overlays stretched the flattened bounding box.
	var/flat_width = flat_icon.Width()
	var/flat_height = flat_icon.Height()
	if(flat_width != EXAMINE_PREVIEW_CANVAS || flat_height != EXAMINE_PREVIEW_CANVAS)
		var/crop_x1 = round((flat_width - EXAMINE_PREVIEW_CANVAS) / 2) + 1
		var/crop_y1 = round((flat_height - EXAMINE_PREVIEW_CANVAS) / 2) + 1
		flat_icon.Crop(crop_x1, crop_y1, crop_x1 + EXAMINE_PREVIEW_CANVAS - 1, crop_y1 + EXAMINE_PREVIEW_CANVAS - 1)
	var/encoded = icon2base64(flat_icon)
	if(!encoded)
		return ""
	examine_preview_cache[dir_key] = "data:image/png;base64,[encoded]"
	return examine_preview_cache[dir_key]

#undef EXAMINE_PREVIEW_CANVAS

/datum/examine_panel/ui_state(mob/user)
	return GLOB.always_state

/atom/movable/screen/map_view/examine_panel_screen
	name = "examine panel screen"

/datum/examine_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ExaminePanel")
		ui.open()

/datum/examine_panel/ui_data(mob/user)

	var/flavor_text = ""
	var/flavor_text_nsfw = ""
	var/obscured = FALSE
	var/ooc_notes = ""
	var/ooc_notes_nsfw = ""
	var/headshot = ""
	var/nsfw_headshot = ""
	var/list/img_gallery = list()
	var/list/nsfw_img_gallery = list()
	var/char_name = ""
	var/song_url = ""
	var/has_song = FALSE
	var/is_naked = FALSE
	var/has_headshot = FALSE
	var/has_nsfw_headshot = FALSE

	if(ishuman(holder))
		var/mob/living/carbon/human/holder_human = holder
		if(!(holder.wear_armor && holder.wear_armor.flags_inv) && !(holder.wear_shirt && holder.wear_shirt.flags_inv) && !(holder_human.underwear) || holder_human.get_erp_pref(/datum/erp_preference/boolean/always_show_nsfw_flavor))
			is_naked = TRUE
		obscured = ((!isobserver(user))) && ((holder_human.wear_mask && (holder_human.wear_mask.flags_inv & HIDEFACE)) || (holder_human.head && (holder_human.head.flags_inv & HIDEFACE))) // ((!isobserver(user)) && !holder_human.client?.prefs?.masked_examine)
		flavor_text = obscured ? "Obscured" : (holder.flavortext || "")
		flavor_text_nsfw = obscured ? "Obscured" : (holder.nsfwflavortext || "")
		ooc_notes = holder.ooc_notes || ""
		ooc_notes_nsfw = holder.erpprefs_flavor || ""
		char_name = holder.name || ""
		song_url = holder.song_link || ""
		if(!obscured)
			headshot = holder.headshot_link || ""
			nsfw_headshot = holder.nsfw_headshot_link || ""
			img_gallery = holder.img_gallery ? holder.img_gallery.Copy() : list()
			nsfw_img_gallery = holder.nsfw_img_gallery ? holder.nsfw_img_gallery.Copy() : list()
			has_headshot = !!holder.headshot_link
			has_nsfw_headshot = !!holder.nsfw_headshot_link
		if(!holder.headshot_link)
			headshot = "headshot_red.png"
		if(!holder.nsfw_headshot_link)
			nsfw_headshot = "headshot_red.png"

	else if(pref)
		is_naked = TRUE
		obscured = FALSE
		flavor_text = pref.flavortext || ""
		flavor_text_nsfw = pref.nsfwflavortext || ""
		ooc_notes = pref.ooc_notes || ""
		ooc_notes_nsfw = pref.erpprefs_flavor || ""
		headshot = pref.headshot_link || ""
		nsfw_headshot = pref.nsfw_headshot_link || ""
		has_headshot = !!pref.headshot_link
		has_nsfw_headshot = !!pref.nsfw_headshot_link
		img_gallery = pref.img_gallery ? pref.img_gallery.Copy() : list()
		nsfw_img_gallery = pref.nsfw_img_gallery ? pref.nsfw_img_gallery.Copy() : list()
		char_name = pref.real_name || ""
		song_url = pref.song_link || ""
		if(!headshot)
			headshot = "headshot_red.png"
		if(!nsfw_headshot)
			nsfw_headshot = "headshot_red.png"

	if(song_url)
		has_song = TRUE

	ooc_notes = html_encode(ooc_notes)
	ooc_notes = parsemarkdown_basic(ooc_notes, hyperlink=TRUE)
	ooc_notes_nsfw = html_encode(ooc_notes_nsfw)
	ooc_notes_nsfw = parsemarkdown_basic(ooc_notes_nsfw, hyperlink=TRUE)
	flavor_text = html_encode(flavor_text)
	flavor_text = parsemarkdown_basic(flavor_text, hyperlink=TRUE)
	flavor_text_nsfw = html_encode(flavor_text_nsfw)
	flavor_text_nsfw = parsemarkdown_basic(flavor_text_nsfw, hyperlink=TRUE)

	var/list/data = list(
		// Identity
		"character_name" = obscured ? "Unknown" : char_name,
		"headshot" = headshot,
		"nsfw_headshot" = nsfw_headshot,
		"obscured" = obscured ? TRUE : FALSE,
		// Descriptions
		"flavor_text" = flavor_text,
		"ooc_notes" = ooc_notes,
		// Descriptions, but requiring manual input to see
		"flavor_text_nsfw" = flavor_text_nsfw,
		"ooc_notes_nsfw" = ooc_notes_nsfw,
		"img_gallery" = img_gallery,
		"nsfw_img_gallery" = nsfw_img_gallery,
		"is_playing" = is_playing,
		"has_song" = has_song,
		"is_naked" = is_naked,
		"has_headshot" = has_headshot,
		"has_nsfw_headshot" = has_nsfw_headshot,
		"preview_image" = preview_requested ? get_preview_image() : "",
	)
	return data

/datum/examine_panel/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()

	if(.)
		return

	if(action == "generate_preview")
		preview_requested = TRUE
		return TRUE

	if(action == "rotate")
		preview_requested = TRUE
		// turn() with a positive angle is counterclockwise in BYOND
		preview_dir = turn(preview_dir, params["clockwise"] ? -90 : 90)
		return TRUE

	if(!viewing)
		return

	var/client/C
	var/web_sound_url
	var/artist_name = "Song Artist Hidden"
	var/song_title
	var/list/music_extra_data = list()

	C = viewing.client

	if(ishuman(holder))
		web_sound_url = holder.song_link
		if(holder.song_artist)
			artist_name = holder.song_artist
		song_title = holder.song_title

	else if(pref)
		web_sound_url= pref.song_link
		if(pref.song_artist)
			artist_name = pref.song_artist
		song_title = pref.song_title

	if(!C || !web_sound_url)
		return

	if(!web_sound_url)
		return

	switch(action)
		if("toggle")
			if(!is_playing)
				is_playing = TRUE
				music_extra_data["link"] = web_sound_url
				music_extra_data["title"] = song_title
				music_extra_data["duration"] = "Song Duration Hidden"
				music_extra_data["artist"] = artist_name
				C.tgui_panel?.play_music(web_sound_url, music_extra_data)
			else
				is_playing = FALSE
				C.tgui_panel?.stop_music()
			return TRUE

/datum/examine_panel/ui_close()
	viewing.client?.tgui_panel?.stop_music()
	QDEL_NULL(src)

/datum/examine_panel/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/simple/headshot_imgs),
	)

/datum/asset/simple/headshot_imgs
	assets = list(
		"headshot_background.png" = 'icons/tgui/headshot_background.png',
		"headshot_red.png" = 'icons/tgui/headshot_red.png',
		)
