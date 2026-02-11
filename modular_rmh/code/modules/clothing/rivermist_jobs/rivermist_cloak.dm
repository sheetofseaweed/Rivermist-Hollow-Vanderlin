/obj/item/clothing/cloak/cape/puritan/townhall
	name = "rich dark cape"
	desc = "A fancy dark cape."
	icon_state = "puritan_cape"
	allowed_race = SPECIES_BASE_BODY

/obj/item/clothing/cloak/ordinatorcape/townhall
	name = "marshall cape"
	desc = "A flowing red cape complete with an ornately patterned steel shoulderguard. Made to last. Made to ENDURE. Made to LIVE."

/obj/item/clothing/cloak/half/duelcape/townhall
	name = "duelist cape"
	desc = "A cape designed for duelists."

/obj/item/clothing/cloak/cape/colored/townhall
	color = CLOTHING_BLACK

/obj/item/clothing/cloak/captain/town_watch
	name = "watch captain's cape"
	desc = "A cape with a gold-embroidered heraldry of Duskmar Duchy."

/obj/item/clothing/cloak/cape/colored/moon_priest
	color = "#62656C"

/obj/item/clothing/cloak/half/shadowcloak/warrior_priest
	name = "dark cloak"
	desc = "A heavy leather cloak held together by a gilded pin."

/obj/item/clothing/cloak/cape/colored/wizard
	color = CLOTHING_BLACK

/obj/item/clothing/cloak/cape/colored/random/Initialize()
	color = pick_assoc(GLOB.noble_dyes)
	return ..()

/obj/item/clothing/cloak/cape/colored/brown
	color = CLOTHING_BROWN

/obj/item/clothing/cloak/poncho/colored/random/Initialize()
	color = pick_assoc(GLOB.common_dyes)
	return ..()
