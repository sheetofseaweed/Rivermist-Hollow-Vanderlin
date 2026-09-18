// RMH - Клеймо quirk: start the round already branded. Atmospheric, for exiles
// and renegades who were marked before they ever arrived.

/datum/quirk/vice/branded
	name = "Branded"
	desc = "Someone marked you as theirs, or as an outcast, long before you came here. The brand never faded."
	desc_hint = "Choose where the brand sits and what it reads. It is permanent unless a legendary healer cuts it away."
	quirk_category = QUIRK_VICE
	point_value = 2
	preview_render = FALSE

	customization_type = QUIRK_SELECT
	customization_label = "Brand location"
	customization_options = list(
		BODY_ZONE_PRECISE_SKULL,
		BODY_ZONE_PRECISE_NECK,
		BODY_ZONE_CHEST,
		BODY_ZONE_PRECISE_STOMACH,
		BODY_ZONE_PRECISE_GROIN,
		BODY_ZONE_L_ARM,
		BODY_ZONE_R_ARM,
		BODY_ZONE_L_LEG,
		BODY_ZONE_R_LEG,
	)

	extra_customization_fields = list(
		list(
			"key" = "brand_text",
			"label" = "Brand text (max 10 characters)",
			"type" = QUIRK_TEXT,
			"default" = "X",
			"placeholder" = "Up to 10 characters",
		),
	)

// Label the dropdown with the same wording examine uses, so "throat" in the menu
// is "throat" in game. parse_zone has no case for stomach and returns it as-is.
/datum/quirk/vice/branded/get_option_name(option)
	return capitalize(parse_zone(option))

/datum/quirk/vice/branded/on_spawn()
	if(!owner || !ishuman(owner))
		return

	var/chosen_zone = customization_value
	if(!chosen_zone)
		chosen_zone = pick(customization_options)

	var/obj/item/bodypart/limb = owner.get_bodypart(check_zone(chosen_zone))
	if(!limb)
		return

	var/text = LAZYACCESS(extra_customization_values, "brand_text")
	if(!text || !length(text))
		text = "X"
	// Byte-safe: copytext would halve Cyrillic input.
	text = copytext_char(text, 1, 11)

	limb.brand_text = text
	limb.brand_zone = chosen_zone
	to_chat(owner, span_boldwarning("The brand on my [parse_zone(chosen_zone)] still reads '[uppertext(text)]'. It always will."))
