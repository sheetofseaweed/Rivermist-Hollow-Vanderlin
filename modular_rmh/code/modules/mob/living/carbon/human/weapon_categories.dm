/*
 * Weapon type shown as the category badge in the Examine Closer tooltip.
 * There's no weapon-type var in the codebase, so this classifies by typepath.
 * Order matters: named sub-branches are checked before their generic family,
 * and greataxe is a sibling of /axe rather than a subtype, so it needs its
 * own check. Returns null for anything unclassified.
 */

/obj/item/proc/get_weapon_category()
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

	if(istype(src, /obj/item/weapon/greataxe))
		return "Greataxe"
	if(istype(src, /obj/item/weapon/axe))
		return "Axe"

	if(istype(src, /obj/item/weapon/mace/warhammer))
		return "Warhammer"
	if(istype(src, /obj/item/weapon/mace))
		return "Mace"

	if(istype(src, /obj/item/weapon/knife/dagger))
		return "Dagger"
	if(istype(src, /obj/item/weapon/knife))
		return "Knife"
	if(istype(src, /obj/item/weapon/sickle))
		return "Sickle"

	if(istype(src, /obj/item/weapon/polearm/halberd))
		return "Halberd"
	if(istype(src, /obj/item/weapon/polearm/spear))
		return "Spear"
	if(istype(src, /obj/item/weapon/polearm))
		return "Polearm"

	if(istype(src, /obj/item/weapon/flail))
		return "Flail"
	if(istype(src, /obj/item/weapon/whip))
		return "Whip"
	if(istype(src, /obj/item/weapon/katar))
		return "Katar"
	if(istype(src, /obj/item/weapon/knuckles))
		return "Knuckles"
	if(istype(src, /obj/item/weapon/pick))
		return "War Pick"

	if(istype(src, /obj/item/weapon/shield/tower))
		return "Tower Shield"
	if(istype(src, /obj/item/weapon/shield/heater))
		return "Heater Shield"
	if(istype(src, /obj/item/weapon/shield))
		return "Shield"

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
