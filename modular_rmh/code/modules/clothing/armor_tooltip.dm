// v2 CORRECTION: the previous version of this file displayed a purely
// cosmetic tier scale (armor_to_protection_class()/armor_to_color(), the
// WEAK/NORMAL/ENDURED/RESISTANT/IMMUNE words) that has nothing to do with
// what RMH's own combat code actually does with an armor rating. RMH already
// has a second, REAL tier system ported from Twilight Axis/Azure Peak -
// ARMOR_DR_ABSORB_TYPES / ARMOR_DR_PIERCE_TYPES / ARMOR_DBLOCK_TYPES
// (code/__DEFINES/armor_defines.dm) plus normalize_armor_rating() and
// get_armor_blocked_damage() (code/modules/mob/living/living_defense.dm) -
// this is what run_armor_check() actually uses to resolve a hit, and it's
// what Azure Peak's / Twilight Axis's own UI (generate_tooltip(),
// defense_examine() in their clothing.dm/items.dm) displays. This file now
// builds its display directly from that real system instead of the cosmetic
// one, via get_real_armor_tier() -> normalize_armor_rating(), so the tooltip
// can't drift from what combat actually does.
//
// Three categories, each a real, distinct mechanic (verbatim from Azure/TFA):
//   ABSORB (blunt)             - each tier = +20% effective armor HP; a fully
//                                absorbed hit never reaches the wearer's HP
//                                until the armor itself breaks.
//   REDUCE (fire; would also be acid/bullet on Azure/TFA)
//                              - each tier reduces damage by 20% of base; the
//                                reduced amount still reaches HP.
//   BLOCK  (slash, stab, piercing)
//                              - fully blocks hits below its tier; a hit at
//                                the same tier partially penetrates (20%),
//                                a hit above it penetrates fully.
// RMH-specific gaps vs Azure/TFA (checked against the actual combat code,
// not guessed):
//   - No BULLET row: RMH's /datum/armor has no separate "bullet" var at all -
//     piercing is explicitly documented as "basically projectiles" (see its
//     var comment in code/datums/armor/_base.dm), so ranged and melee
//     piercing share one stat here. Adding a fake BULLET row would either
//     crash (get_rating() CRASH()es on an unknown key) or show a number that
//     doesn't correspond to anything.
//   - No ACID row: the var exists (armor.get_rating(ACID) is safe to call)
//     but nothing in the codebase currently calls run_armor_check() with
//     attack_flag="acid" - it isn't wired into real damage resolution yet,
//     so showing it would describe a mechanic that doesn't fire in practice.
//
// Three surfaces:
//   1. get_examine_gear()'s "I have a <item> on ..." line (chat) - brief
//      ABSORPTION/BLOCK/RESIST digest, ported from generate_tooltip().
//   2. the item's own "{?}" inspect link - NO tooltip on the link itself
//      (matches Azure/TFA - the link is plain, only the full breakdown it
//      opens has tooltips); {?} still guarantees it shows up whenever the
//      item has real armor, even without armor_class set.
//   3. the {?} full breakdown's ABSORB:/REDUCE:/BLOCK: headers - each
//      underlined and tooltipped with its own real mechanic explanation,
//      ported verbatim from defense_examine(). Plain span_tooltip() here
//      (not the HTML variant) since the explanations are plain sentences -
//      matches Azure/TFA's own choice of SPAN_TOOLTIP over
//      SPAN_TOOLTIP_DANGEROUS_HTML for exactly these three lines.
//   4. the examine panel's per-slot hover tooltip (React) - gets the same
//      real tiers/colors as structured data instead of HTML.

#define ARMOR_ABSORB_TOOLTIP "Each tier increases effective HP of the armor by 20%. Absorbed attacks never reach HP. The armor must be broken first."
#define ARMOR_REDUCE_TOOLTIP "Each tier reduces damage by 20% of base. Reduced damage still reaches HP. Armor absorbs what was blocked."
#define ARMOR_BLOCK_TOOLTIP "Blocks attacks below this tier (Armor takes all damage). Same tier penetrates 20% (80% goes to armor). Exceeding tier penetrates fully."

/// Fixed color per real 0-5 tier, ported verbatim from Azure Peak / Twilight
/// Axis's colorgrade_rating() (human_topic.dm) - NOT armor_to_color(), this
/// is a different, unrelated scale (see file header).
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
	return "#ff00ff" // shouldn't happen - loud color to flag a bad tier during testing

/// Converts a raw /datum/armor rating (0-100ish) into the real 0-5 tier that
/// actually governs run_armor_check()'s math for that damage type. Thin
/// wrapper around the game's own normalize_armor_rating() (living_defense.dm)
/// so this display can never drift from what combat actually does.
/proc/get_real_armor_tier(attack_flag, raw_rating)
	return normalize_armor_rating(attack_flag, raw_rating)

/// Colored HTML dot row for one damage type, ported near-verbatim from
/// colorgrade_rating(). tier must already be a real tier (0-5) from
/// get_real_armor_tier() above - never pass a raw armor rating here.
/proc/colorgrade_rating_html(label, tier, max_tier = 4)
	if(isnull(tier))
		tier = 0
	var/color = armor_tier_color(tier)
	var/dots = ""
	for(var/i in 1 to max_tier)
		dots += (i <= tier) ? "<font color='[color]'>●</font>" : "<font color='#404040'>○</font>"
	return "<font color='[color]'>[label]</font> [dots]"

/// One "<u><b>HEADER:</b></u> row of dots" line, with a plain-text hover
/// explanation on the header (span_tooltip - plain sentences, no markup).
/proc/build_armor_category_line(header, header_tip, list/rows)
	return span_tooltip(header_tip, "<u><b>[header]:</b></u>") + " " + rows.Join(" | ")

/// Full colored ABSORB/REDUCE/BLOCK breakdown for the {?} full inspect
/// popup, ported from Azure Peak / Twilight Axis's defense_examine()
/// (game/objects/items.dm). Replaces the old flat "DEFENSE:" list in
/// get_inspect_entries() (code/modules/clothing/clothing.dm).
/obj/item/clothing/proc/get_armor_breakdown_html()
	var/datum/armor/item_armor = get_armor()
	if(!item_armor.has_any_armor())
		return ""

	var/blunt_tier = get_real_armor_tier(BLUNT, item_armor.get_rating(BLUNT))
	var/slash_tier = get_real_armor_tier(SLASH, item_armor.get_rating(SLASH))
	var/stab_tier = get_real_armor_tier(STAB, item_armor.get_rating(STAB))
	var/pierce_tier = get_real_armor_tier(PIERCE, item_armor.get_rating(PIERCE))

	var/list/lines = list()
	lines += build_armor_category_line("ABSORB", ARMOR_ABSORB_TOOLTIP, list(
		colorgrade_rating_html("BLUNT", blunt_tier, 5),
	))
	lines += build_armor_category_line("REDUCE", ARMOR_REDUCE_TOOLTIP, list(
		colorgrade_rating_html("BURN", get_real_armor_tier(FIRE, item_armor.get_rating(FIRE)), 5),
	))
	lines += build_armor_category_line("BLOCK", ARMOR_BLOCK_TOOLTIP, list(
		colorgrade_rating_html("SLASH", slash_tier, 4),
		colorgrade_rating_html("STAB", stab_tier, 4),
		colorgrade_rating_html("PIERCING", pierce_tier, 4),
	))
	return lines.Join("<br>")

/// Brief ABSORPTION/BLOCK/RESIST hover digest for the chat-side surfaces
/// (get_examine_gear()'s narration line), ported from Azure Peak / Twilight
/// Axis's /obj/item/clothing/generate_tooltip() (clothing.dm).
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

/// Text label for armor_class (AC_LIGHT/MEDIUM/HEAVY, __DEFINES/clothing.dm),
/// computed server-side so the Examine Closer panel never has to duplicate
/// the numeric define values itself (a client-side copy would silently go
/// stale if those defines ever change). Used by pack_examine_item().
/proc/armor_class_to_label(armor_class)
	switch(armor_class)
		if(AC_LIGHT)
			return "Light Armour"
		if(AC_MEDIUM)
			return "Medium Armour"
		if(AC_HEAVY)
			return "Heavy Armour"
	return ""

// {?} carries no tooltip of its own (matches Azure/TFA - the link is plain);
// this only guarantees it shows up whenever the item has real armor, even
// for pieces that never set has_inspect_verb (e.g. armor without an
// armor_class weight tier).
/obj/item/clothing/get_inspect_button()
	var/datum/armor/item_armor = get_armor()
	if(item_armor.has_any_armor())
		return " <span class='info'><a href='byond://?src=[REF(src)];inspect=1'>{?}</a></span>"
	return ..()
