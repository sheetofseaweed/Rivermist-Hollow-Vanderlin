/*
 * Armour readouts for clothing, shown in two places:
 *   - hovering a worn item's name when examining someone (get_examine_gear)
 *   - the item's own "{?}" inspect popup (get_inspect_entries)
 *
 * Tiers come from normalize_armor_rating(), the same helper run_armor_check()
 * uses, so the dots always match what combat actually does. The three
 * categories below mirror ARMOR_DR_ABSORB_TYPES / ARMOR_DR_PIERCE_TYPES /
 * ARMOR_DBLOCK_TYPES, and their descriptions are taken from the formulas in
 * get_armor_blocked_damage() and getarmor().
 */

#define ARMOR_ABSORB_TOOLTIP "The armour takes the whole blow instead of you while it holds. Higher tiers wear down slower: integrity damage is divided by 1 + 0.2 per tier, so tier 5 armour lasts twice as long."
#define ARMOR_REDUCE_TOOLTIP "Cuts incoming damage by 1 - 1/(1 + 0.2 per tier): about 17% at tier 1, up to 50% at tier 5. The remainder still reaches you."
#define ARMOR_BLOCK_TOOLTIP "Attacks with less penetration than this tier are stopped outright. Melee lets 10% through per penetration step, capped at 80%. Projectiles let 20% through at equal tier and 80% above it."

/proc/armor_tier_color(tier)
	switch(tier)
		if(0)
			return "#808080"
		if(1)
			return "#c0a739"
		if(2)
			return "#e3e63c"
		if(3)
			return "#1a9c00"
		if(4)
			return "#339dff"
		if(5)
			return "#c757af"
	return "#ff00ff"

/proc/get_real_armor_tier(attack_flag, raw_rating)
	return normalize_armor_rating(attack_flag, raw_rating)

/// Expects a tier from get_real_armor_tier(), never a raw armour rating.
/proc/colorgrade_rating_html(label, tier, max_tier = 4)
	if(isnull(tier))
		tier = 0
	var/color = armor_tier_color(tier)
	var/dots = ""
	for(var/i in 1 to max_tier)
		dots += (i <= tier) ? "<font color='[color]'>●</font>" : "<font color='#404040'>○</font>"
	return "<font color='[color]'>[label]</font> [dots]"

/proc/build_armor_category_line(header, header_tip, list/rows)
	return span_tooltip(header_tip, "<u><b>[header]:</b></u>") + " " + rows.Join(" | ")

/obj/item/clothing/proc/get_armor_breakdown_html()
	var/datum/armor/item_armor = get_armor()
	if(!item_armor.has_any_armor())
		return ""

	var/list/lines = list()
	lines += build_armor_category_line("ABSORB", ARMOR_ABSORB_TOOLTIP, list(
		colorgrade_rating_html("BLUNT", get_real_armor_tier(BLUNT, item_armor.get_rating(BLUNT)), 5),
	))
	lines += build_armor_category_line("REDUCE", ARMOR_REDUCE_TOOLTIP, list(
		colorgrade_rating_html("BURN", get_real_armor_tier(FIRE, item_armor.get_rating(FIRE)), 5),
	))
	lines += build_armor_category_line("BLOCK", ARMOR_BLOCK_TOOLTIP, list(
		colorgrade_rating_html("SLASH", get_real_armor_tier(SLASH, item_armor.get_rating(SLASH)), 4),
		colorgrade_rating_html("STAB", get_real_armor_tier(STAB, item_armor.get_rating(STAB)), 4),
		colorgrade_rating_html("PIERCING", get_real_armor_tier(PIERCE, item_armor.get_rating(PIERCE)), 4),
	))
	return lines.Join("<br>")

/obj/item/clothing/proc/get_brief_armor_tip()
	var/datum/armor/item_armor = get_armor()
	if(!item_armor.has_any_armor())
		return ""

	var/list/lines = list()
	lines += "<b>ABSORPTION:</b> " + colorgrade_rating_html("🔨 BLUNT", get_real_armor_tier(BLUNT, item_armor.get_rating(BLUNT)), 5)
	lines += "<b>BLOCK:</b> " + list(
		colorgrade_rating_html("🪓 SLASH", get_real_armor_tier(SLASH, item_armor.get_rating(SLASH)), 4),
		colorgrade_rating_html("🗡️ STAB", get_real_armor_tier(STAB, item_armor.get_rating(STAB)), 4),
		colorgrade_rating_html("🏹 PIERCE", get_real_armor_tier(PIERCE, item_armor.get_rating(PIERCE)), 4),
	).Join(" | ")
	var/fire_rating = item_armor.get_rating(FIRE)
	if(fire_rating > 0)
		lines += "<b>RESIST:</b> " + colorgrade_rating_html("🔥 FIRE", get_real_armor_tier(FIRE, fire_rating), 5)
	return lines.Join("<br>")

/proc/armor_class_to_label(armor_class)
	switch(armor_class)
		if(AC_LIGHT)
			return "Light Armour"
		if(AC_MEDIUM)
			return "Medium Armour"
		if(AC_HEAVY)
			return "Heavy Armour"
	return ""

/obj/item/clothing/get_inspect_button()
	var/datum/armor/item_armor = get_armor()
	if(item_armor.has_any_armor())
		return " <span class='info'><a href='byond://?src=[REF(src)];inspect=1'>{?}</a></span>"
	return ..()
