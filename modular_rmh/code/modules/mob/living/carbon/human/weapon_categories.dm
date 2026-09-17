// Weapon-type taxonomy for the Examine Closer tooltip's category tag
// (tgui/packages/tgui/interfaces/ExaminePanelPages.tsx's "weaponCategory"
// badge, packed by examine_tgui.dm's pack_examine_item()). Split out into
// its own modular file since it's a self-contained classification table
// over existing core weapon types, not core behavior itself.

/// Weapon category by typepath - the closest thing RMH has to a "weapon type"
/// field (there's no dedicated var for it). Order matters: most specific
/// branch first, generic family fallback last - a naive single-check-per-
/// family version (checking only istype(src, /obj/item/weapon/sword) etc.)
/// silently mislabels or drops real weapons in two different ways, both
/// confirmed against the actual typepath tree:
///   - A greatsword (/obj/item/weapon/sword/long/greatsword) IS a subtype of
///     the base /sword, so it matched the generic "Sword" bucket instead of
///     its own name - the greatsword-shows-as-"Sword" bug.
///   - A greataxe (/obj/item/weapon/greataxe) is a SIBLING of /axe, not a
///     subtype of it (they only share /obj/item/weapon as a common ancestor),
///     so it matched nothing at all and got no category tag whatsoever.
/// Modeled loosely on bg3.wiki's per-weapon-type list (Battleaxes, Longswords,
/// Greatswords, Warhammers, etc. as distinct categories rather than one
/// generic "Sword"/"Axe" bucket each), but built from what Vanderlin actually
/// has (code/game/objects/items/weapons/melee/*.dm,
/// code/game/objects/items/weapons/ranged/*.dm), not copied from BG3's own
/// weapon list - Vanderlin has plenty BG3 doesn't (sabres, khopeshes, katanas,
/// kaskaras, war picks as a mining-pick hybrid, blowguns, airguns, muskets)
/// and no 1:1 equivalent for some BG3 categories (no darts/slings/tridents/
/// glaives/war-picks-as-pure-weapons as their own Vanderlin typepaths).
/obj/item/proc/get_weapon_category()
	// --- Swords: check named sub-branches before the generic /sword fallback ---
	if(istype(src, /obj/item/weapon/sword/long/greatsword))
		return "Greatsword"
	if(istype(src, /obj/item/weapon/sword/long))
		return "Longsword"
	if(istype(src, /obj/item/weapon/sword/short))
		return "Shortsword"
	if(istype(src, /obj/item/weapon/sword/scimitar))
		return "Scimitar"
	if(istype(src, /obj/item/weapon/sword/rapier))
		return "Rapier"
	if(istype(src, /obj/item/weapon/sword/sabre))
		return "Sabre"
	if(istype(src, /obj/item/weapon/sword/katana))
		return "Katana"
	if(istype(src, /obj/item/weapon/sword/khopesh))
		return "Khopesh"
	if(istype(src, /obj/item/weapon/sword/gladius))
		return "Gladius"
	if(istype(src, /obj/item/weapon/sword))
		return "Sword"

	// --- Axes: greataxe is a sibling of /axe, not a subtype - check it separately ---
	if(istype(src, /obj/item/weapon/greataxe))
		return "Greataxe"
	if(istype(src, /obj/item/weapon/axe))
		return "Axe"

	// --- Blunt: warhammer is a /mace subtype, not its own branch ---
	if(istype(src, /obj/item/weapon/mace/warhammer))
		return "Warhammer"
	if(istype(src, /obj/item/weapon/mace))
		return "Mace"

	// --- Bladed/piercing sidearms ---
	if(istype(src, /obj/item/weapon/knife/dagger))
		return "Dagger"
	if(istype(src, /obj/item/weapon/knife))
		return "Knife"
	if(istype(src, /obj/item/weapon/sickle))
		return "Sickle"

	// --- Polearms ---
	if(istype(src, /obj/item/weapon/polearm/halberd))
		return "Halberd"
	if(istype(src, /obj/item/weapon/polearm/spear))
		return "Spear"
	if(istype(src, /obj/item/weapon/polearm))
		return "Polearm"

	// --- Everything else with its own family ---
	if(istype(src, /obj/item/weapon/flail))
		return "Flail"
	if(istype(src, /obj/item/weapon/whip))
		return "Whip"
	if(istype(src, /obj/item/weapon/katar))
		return "Katar"
	if(istype(src, /obj/item/weapon/knuckles))
		return "Knuckles"
	// Mining pick doubles as a war pick in melee - keep it as its own
	// category rather than folding it into Axe, they play differently.
	if(istype(src, /obj/item/weapon/pick))
		return "War Pick"

	// --- Shields (e.g. the blessed "Covenant" tower shield) ---
	if(istype(src, /obj/item/weapon/shield/tower))
		return "Tower Shield"
	if(istype(src, /obj/item/weapon/shield/heater))
		return "Heater Shield"
	if(istype(src, /obj/item/weapon/shield))
		return "Shield"

	// --- Ranged: named sub-branches (bow size, musket) before the family fallback ---
	if(istype(src, /obj/item/gun/ballistic/revolver/grenadelauncher/bow/long))
		return "Longbow"
	if(istype(src, /obj/item/gun/ballistic/revolver/grenadelauncher/bow/short))
		return "Shortbow"
	if(istype(src, /obj/item/gun/ballistic/revolver/grenadelauncher/bow))
		return "Bow"
	if(istype(src, /obj/item/gun/ballistic/revolver/grenadelauncher/crossbow))
		return "Crossbow"
	if(istype(src, /obj/item/gun/ballistic/revolver/grenadelauncher/pistol/musket))
		return "Musket"
	if(istype(src, /obj/item/gun/ballistic/revolver/grenadelauncher/pistol))
		return "Pistol"
	if(istype(src, /obj/item/gun/ballistic/revolver/grenadelauncher/blowgun))
		return "Blowgun"
	if(istype(src, /obj/item/gun/ballistic/revolver/grenadelauncher/airgun))
		return "Airgun"
	if(istype(src, /obj/item/gun))
		return "Firearm"
	return null
