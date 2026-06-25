/obj/item/clothing/face/lordmask
	item_weight = 450 GRAMS
	name = "golden halfmask"
	desc = "Half of your face turned gold."
	icon_state = "lmask"
	sellprice = 50

/obj/item/clothing/face/lordmask/l
	icon_state = "lmask_l"

/obj/item/clothing/face/lordmask/faceless
	name = "half-face"
	desc = "A face for the faceless."
	color = CLOTHING_SOOT_BLACK

/obj/item/clothing/face/lordmask/faceless/Initialize()
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, CURSED_ITEM_TRAIT)

/obj/item/clothing/face/lordmask/faceless/dropped(mob/living/carbon/human/user)
	. = ..()
	if(QDELETED(src))
		return
	qdel(src)

/obj/item/clothing/face/facemask
	item_weight = 1.2 KILOGRAMS
	name = "iron mask"
	icon_state = "imask"
	desc = "A heavy iron mask that both conceals and protects the face."
	max_integrity = 100
	blocksound = PLATEHIT
	break_sound = 'sound/foley/breaksound.ogg'
	drop_sound = 'sound/foley/dropsound/armor_drop.ogg'
	armor = list("blunt" = DR_ULTRA, "slash" = DBLOCK_HEAVY, "stab" = DBLOCK_HEAVY, "piercing" = DBLOCK_MEDIUM, "fire" = DR_NONE, "acid" = DR_NONE)
	prevent_crits = list(BCLASS_LASHING, BCLASS_BITE, BCLASS_TWIST, BCLASS_CUT, BCLASS_CHOP, BCLASS_BLUNT, BCLASS_STAB)
	flags_inv = HIDEFACE
	body_parts_covered = FACE
	block2add = FOV_BEHIND
	slot_flags = ITEM_SLOT_MASK|ITEM_SLOT_HIP
	experimental_onhip = TRUE
	sewrepair = null
	anvilrepair = /datum/attribute/skill/craft/armor_repair
	clothing_flags = CANT_SLEEP_IN
	smeltresult = null
	melting_material = /datum/material/iron
	melt_amount = 50

	material_category = ARMOR_MAT_PLATE

/obj/item/clothing/face/facemask/goldnosechain
	item_weight = 65 GRAMS
	name = "gold nosechain"
	icon_state = "nosechain_g"
	desc = "A fashionable nose chain with two rings. Its design originated from the Savannah Elf tribes."
	max_integrity = 100
	blocksound = FALSE
	armor = FALSE
	prevent_crits = FALSE
	flags_inv = FALSE
	body_parts_covered = FACE
	block2add = FALSE
	slot_flags = ITEM_SLOT_MASK
	sewrepair = null
	anvilrepair = /datum/attribute/skill/craft/armor_repair
	clothing_flags = FALSE
	sellprice = VALUE_GOLD_ITEM

/obj/item/clothing/face/facemask/silvernosechain
	item_weight = 45 GRAMS
	name = "silver nosechain"
	icon_state = "nosechain_s"
	desc = "A fashionable nose chain with two rings. Its design originated from the Savannah Elf tribes."
	max_integrity = 100
	blocksound = FALSE
	armor = FALSE
	prevent_crits = FALSE
	flags_inv = FALSE
	body_parts_covered = FACE
	block2add = FALSE
	slot_flags = ITEM_SLOT_MASK
	sewrepair = null
	anvilrepair = /datum/attribute/skill/craft/armor_repair
	clothing_flags = FALSE
	sellprice = VALUE_SILVER_ITEM

/obj/item/clothing/face/facemask/silvernosechain/Initialize()
	. = ..()
	enchant(/datum/enchantment/silver)

/obj/item/clothing/face/facemask/goldveil
	item_weight = 1.2 KILOGRAMS
	name = "golden face veil"
	icon_state = "veil_g"
	desc = "A veil made out of golden chains."
	max_integrity = 100
	blocksound = FALSE
	armor = FALSE
	prevent_crits = FALSE
	flags_inv = HIDEFACE
	body_parts_covered = FACE
	block2add = FALSE
	slot_flags = ITEM_SLOT_MASK
	sewrepair = null
	anvilrepair = /datum/attribute/skill/craft/armor_repair
	clothing_flags = FALSE
	sellprice = VALUE_GOLD_ITEM

/obj/item/clothing/face/facemask/silverveil
	item_weight = 1.05 KILOGRAMS
	name = "silver face veil"
	icon_state = "veil_s"
	desc = "A veil made out of silver chains."
	max_integrity = 100
	blocksound = FALSE
	armor = FALSE
	prevent_crits = FALSE
	flags_inv = HIDEFACE
	body_parts_covered = FACE
	block2add = FALSE
	slot_flags = ITEM_SLOT_MASK
	sewrepair = null
	anvilrepair = /datum/attribute/skill/craft/armor_repair
	clothing_flags = FALSE
	sellprice = VALUE_SILVER_ITEM

/obj/item/clothing/face/facemask/silverveil/Initialize()
	. = ..()
	enchant(/datum/enchantment/silver)

/obj/item/clothing/face/jademask
	item_weight = 2.2 KILOGRAMS
	name = "joapstone mask "
	icon_state = "mask_jade"
	desc = "A joapstone mask that both conceals and protects the face."
	max_integrity = 85
	blocksound = PLATEHIT
	break_sound = 'sound/foley/breaksound.ogg'
	drop_sound = 'sound/foley/dropsound/armor_drop.ogg'
	armor = list("blunt" = DR_ULTRA, "slash" = DBLOCK_HEAVY, "stab" = DBLOCK_HEAVY, "piercing" = DBLOCK_MEDIUM, "fire" = DR_NONE, "acid" = DR_NONE)
	prevent_crits = list(BCLASS_LASHING, BCLASS_BITE, BCLASS_TWIST, BCLASS_CUT, BCLASS_CHOP, BCLASS_BLUNT, BCLASS_STAB)
	flags_inv = HIDEFACE
	body_parts_covered = FACE
	block2add = FOV_BEHIND
	slot_flags = ITEM_SLOT_MASK|ITEM_SLOT_HIP
	experimental_onhip = TRUE
	sewrepair = null
	anvilrepair = null
	clothing_flags = CANT_SLEEP_IN
	sellprice = 70

/obj/item/clothing/face/turqmask
	item_weight = 2.2 KILOGRAMS
	name = "ceruleabaster mask "
	icon_state = "mask_turq"
	desc = "A ceruleabaster mask that both conceals and protects the face."
	max_integrity = 85
	blocksound = PLATEHIT
	break_sound = 'sound/foley/breaksound.ogg'
	drop_sound = 'sound/foley/dropsound/armor_drop.ogg'
	armor = list("blunt" = DR_ULTRA, "slash" = DBLOCK_HEAVY, "stab" = DBLOCK_HEAVY, "piercing" = DBLOCK_MEDIUM, "fire" = DR_NONE, "acid" = DR_NONE)
	prevent_crits = list(BCLASS_LASHING, BCLASS_BITE, BCLASS_TWIST, BCLASS_CUT, BCLASS_CHOP, BCLASS_BLUNT, BCLASS_STAB)
	flags_inv = HIDEFACE | HIDEFACIALHAIR | HIDEHAIR
	body_parts_covered = FACE
	block2add = FOV_BEHIND
	slot_flags = ITEM_SLOT_MASK|ITEM_SLOT_HIP
	experimental_onhip = TRUE
	sewrepair = null
	anvilrepair = null
	clothing_flags = CANT_SLEEP_IN
	sellprice = 95

/obj/item/clothing/face/rosemask
	item_weight = 1.9 KILOGRAMS
	name = "rosellusk mask "
	icon_state = "mask_rose"
	desc = "A rosellusk mask that both conceals and protects the face."
	max_integrity = 85
	blocksound = PLATEHIT
	break_sound = 'sound/foley/breaksound.ogg'
	drop_sound = 'sound/foley/dropsound/armor_drop.ogg'
	armor = list("blunt" = DR_ULTRA, "slash" = DBLOCK_HEAVY, "stab" = DBLOCK_HEAVY, "piercing" = DBLOCK_MEDIUM, "fire" = DR_NONE, "acid" = DR_NONE)
	prevent_crits = list(BCLASS_LASHING, BCLASS_BITE, BCLASS_TWIST, BCLASS_CUT, BCLASS_CHOP, BCLASS_BLUNT, BCLASS_STAB)
	flags_inv = HIDEFACE
	body_parts_covered = FACE
	block2add = FOV_BEHIND
	slot_flags = ITEM_SLOT_MASK|ITEM_SLOT_HIP
	experimental_onhip = TRUE
	sewrepair = null
	anvilrepair = null
	clothing_flags = CANT_SLEEP_IN
	sellprice = 35

/obj/item/clothing/face/shellmask
	item_weight = 1.1 KILOGRAMS
	name = "shell mask "
	icon_state = "mask_shell"
	desc = "A shell mask that both conceals and protects the face."
	max_integrity = 85
	blocksound = PLATEHIT
	break_sound = 'sound/foley/breaksound.ogg'
	drop_sound = 'sound/foley/dropsound/armor_drop.ogg'
	armor = list("blunt" = DR_ULTRA, "slash" = DBLOCK_HEAVY, "stab" = DBLOCK_HEAVY, "piercing" = DBLOCK_MEDIUM, "fire" = DR_NONE, "acid" = DR_NONE)
	prevent_crits = list(BCLASS_LASHING, BCLASS_BITE, BCLASS_TWIST, BCLASS_CUT, BCLASS_CHOP, BCLASS_BLUNT, BCLASS_STAB)
	flags_inv = HIDEFACE
	body_parts_covered = FACE
	block2add = FOV_BEHIND
	slot_flags = ITEM_SLOT_MASK|ITEM_SLOT_HIP
	experimental_onhip = TRUE
	sewrepair = null
	anvilrepair = null
	clothing_flags = CANT_SLEEP_IN
	sellprice = 30

/obj/item/clothing/face/coralmask
	item_weight = 1.1 KILOGRAMS
	name = "aoetal mask "
	icon_state = "mask_coral"
	desc = "An aoetal mask that both conceals and protects the face."
	max_integrity = 85
	blocksound = PLATEHIT
	break_sound = 'sound/foley/breaksound.ogg'
	drop_sound = 'sound/foley/dropsound/armor_drop.ogg'
	armor = list("blunt" = DR_ULTRA, "slash" = DBLOCK_HEAVY, "stab" = DBLOCK_HEAVY, "piercing" = DBLOCK_MEDIUM, "fire" = DR_NONE, "acid" = DR_NONE)
	prevent_crits = list(BCLASS_LASHING, BCLASS_BITE, BCLASS_TWIST, BCLASS_CUT, BCLASS_CHOP, BCLASS_BLUNT, BCLASS_STAB)
	flags_inv = HIDEFACE
	body_parts_covered = FACE
	block2add = FOV_BEHIND
	slot_flags = ITEM_SLOT_MASK|ITEM_SLOT_HIP
	experimental_onhip = TRUE
	sewrepair = null
	anvilrepair = null
	clothing_flags = CANT_SLEEP_IN
	sellprice = 80

/obj/item/clothing/face/ambermask
	item_weight = 1.5 KILOGRAMS
	name = "petriamber mask "
	icon_state = "mask_amber"
	desc = "A petriamber mask that both conceals and protects the face."
	max_integrity = 85
	blocksound = PLATEHIT
	break_sound = 'sound/foley/breaksound.ogg'
	drop_sound = 'sound/foley/dropsound/armor_drop.ogg'
	armor = list("blunt" = DR_ULTRA, "slash" = DBLOCK_HEAVY, "stab" = DBLOCK_HEAVY, "piercing" = DBLOCK_MEDIUM, "fire" = DR_NONE, "acid" = DR_NONE)
	prevent_crits = list(BCLASS_LASHING, BCLASS_BITE, BCLASS_TWIST, BCLASS_CUT, BCLASS_CHOP, BCLASS_BLUNT, BCLASS_STAB)
	flags_inv = HIDEFACE
	body_parts_covered = FACE
	block2add = FOV_BEHIND
	slot_flags = ITEM_SLOT_MASK|ITEM_SLOT_HIP
	experimental_onhip = TRUE
	sewrepair = null
	anvilrepair = null
	clothing_flags = CANT_SLEEP_IN
	sellprice = 70

/obj/item/clothing/face/onyxamask
	item_weight = 1.7 KILOGRAMS
	name = "onyxa mask "
	icon_state = "mask_onyxa"
	desc = "An onyxa mask that both conceals and protects the face."
	max_integrity = 85
	blocksound = PLATEHIT
	break_sound = 'sound/foley/breaksound.ogg'
	drop_sound = 'sound/foley/dropsound/armor_drop.ogg'
	armor = list("blunt" = DR_ULTRA, "slash" = DBLOCK_HEAVY, "stab" = DBLOCK_HEAVY, "piercing" = DBLOCK_MEDIUM, "fire" = DR_NONE, "acid" = DR_NONE)
	prevent_crits = list(BCLASS_LASHING, BCLASS_BITE, BCLASS_TWIST, BCLASS_CUT, BCLASS_CHOP, BCLASS_BLUNT, BCLASS_STAB)
	flags_inv = HIDEFACE
	body_parts_covered = FACE
	block2add = FOV_BEHIND
	slot_flags = ITEM_SLOT_MASK|ITEM_SLOT_HIP
	experimental_onhip = TRUE
	sewrepair = null
	anvilrepair = null
	clothing_flags = CANT_SLEEP_IN
	sellprice = 50

/obj/item/clothing/face/opalmask
	item_weight = 1.8 KILOGRAMS
	name = "opaloise mask "
	icon_state = "mask_opal"
	desc = "An opaloise mask that both conceals and protects the face."
	max_integrity = 85
	blocksound = PLATEHIT
	break_sound = 'sound/foley/breaksound.ogg'
	drop_sound = 'sound/foley/dropsound/armor_drop.ogg'
	armor = list("blunt" = DR_ULTRA, "slash" = DBLOCK_HEAVY, "stab" = DBLOCK_HEAVY, "piercing" = DBLOCK_MEDIUM, "fire" = DR_NONE, "acid" = DR_NONE)
	prevent_crits = list(BCLASS_LASHING, BCLASS_BITE, BCLASS_TWIST, BCLASS_CUT, BCLASS_CHOP, BCLASS_BLUNT, BCLASS_STAB)
	flags_inv = HIDEFACE
	body_parts_covered = FACE
	block2add = FOV_BEHIND
	slot_flags = ITEM_SLOT_MASK|ITEM_SLOT_HIP
	experimental_onhip = TRUE
	sewrepair = null
	anvilrepair = null
	clothing_flags = CANT_SLEEP_IN
	sellprice = 100

/obj/item/clothing/face/jademask
	item_weight = 2.2 KILOGRAMS
	name = "joapstone mask "
	icon_state = "mask_jade"
	desc = "A joapstone mask that both conceals and protects the face."
	max_integrity = 85
	blocksound = PLATEHIT
	break_sound = 'sound/foley/breaksound.ogg'
	drop_sound = 'sound/foley/dropsound/armor_drop.ogg'
	armor = list("blunt" = DR_ULTRA, "slash" = DBLOCK_HEAVY, "stab" = DBLOCK_HEAVY, "piercing" = DBLOCK_MEDIUM, "fire" = DR_NONE, "acid" = DR_NONE)
	prevent_crits = list(BCLASS_LASHING, BCLASS_BITE, BCLASS_TWIST, BCLASS_CUT, BCLASS_CHOP, BCLASS_BLUNT, BCLASS_STAB)
	flags_inv = HIDEFACE
	body_parts_covered = FACE
	block2add = FOV_BEHIND
	slot_flags = ITEM_SLOT_MASK|ITEM_SLOT_HIP
	experimental_onhip = TRUE
	sewrepair = null
	anvilrepair = null
	clothing_flags = CANT_SLEEP_IN
	sellprice = 70

/obj/item/clothing/face/turqmask
	item_weight = 2.2 KILOGRAMS
	name = "ceruleabaster mask "
	icon_state = "mask_turq"
	desc = "A ceruleabaster mask that both conceals and protects the face."
	max_integrity = 85
	blocksound = PLATEHIT
	break_sound = 'sound/foley/breaksound.ogg'
	drop_sound = 'sound/foley/dropsound/armor_drop.ogg'
	armor = list("blunt" = DR_ULTRA, "slash" = DBLOCK_HEAVY, "stab" = DBLOCK_HEAVY, "piercing" = DBLOCK_MEDIUM, "fire" = DR_NONE, "acid" = DR_NONE)
	prevent_crits = list(BCLASS_LASHING, BCLASS_BITE, BCLASS_TWIST, BCLASS_CUT, BCLASS_CHOP, BCLASS_BLUNT, BCLASS_STAB)
	flags_inv = HIDEFACE | HIDEFACIALHAIR | HIDEHAIR
	body_parts_covered = FACE
	block2add = FOV_BEHIND
	slot_flags = ITEM_SLOT_MASK|ITEM_SLOT_HIP
	experimental_onhip = TRUE
	sewrepair = null
	anvilrepair = null
	clothing_flags = CANT_SLEEP_IN
	sellprice = 95

/obj/item/clothing/face/rosemask
	item_weight = 1.9 KILOGRAMS
	name = "rosellusk mask "
	icon_state = "mask_rose"
	desc = "A rosellusk mask that both conceals and protects the face."
	max_integrity = 85
	blocksound = PLATEHIT
	break_sound = 'sound/foley/breaksound.ogg'
	drop_sound = 'sound/foley/dropsound/armor_drop.ogg'
	armor = list("blunt" = DR_ULTRA, "slash" = DBLOCK_HEAVY, "stab" = DBLOCK_HEAVY, "piercing" = DBLOCK_MEDIUM, "fire" = DR_NONE, "acid" = DR_NONE)
	prevent_crits = list(BCLASS_LASHING, BCLASS_BITE, BCLASS_TWIST, BCLASS_CUT, BCLASS_CHOP, BCLASS_BLUNT, BCLASS_STAB)
	flags_inv = HIDEFACE
	body_parts_covered = FACE
	block2add = FOV_BEHIND
	slot_flags = ITEM_SLOT_MASK|ITEM_SLOT_HIP
	experimental_onhip = TRUE
	sewrepair = null
	anvilrepair = null
	clothing_flags = CANT_SLEEP_IN
	sellprice = 35

/obj/item/clothing/face/shellmask
	item_weight = 1.1 KILOGRAMS
	name = "shell mask "
	icon_state = "mask_shell"
	desc = "A shell mask that both conceals and protects the face."
	max_integrity = 85
	blocksound = PLATEHIT
	break_sound = 'sound/foley/breaksound.ogg'
	drop_sound = 'sound/foley/dropsound/armor_drop.ogg'
	armor = list("blunt" = DR_ULTRA, "slash" = DBLOCK_HEAVY, "stab" = DBLOCK_HEAVY, "piercing" = DBLOCK_MEDIUM, "fire" = DR_NONE, "acid" = DR_NONE)
	prevent_crits = list(BCLASS_LASHING, BCLASS_BITE, BCLASS_TWIST, BCLASS_CUT, BCLASS_CHOP, BCLASS_BLUNT, BCLASS_STAB)
	flags_inv = HIDEFACE
	body_parts_covered = FACE
	block2add = FOV_BEHIND
	slot_flags = ITEM_SLOT_MASK|ITEM_SLOT_HIP
	experimental_onhip = TRUE
	sewrepair = null
	anvilrepair = null
	clothing_flags = CANT_SLEEP_IN
	sellprice = 30

/obj/item/clothing/face/coralmask
	item_weight = 1.1 KILOGRAMS
	name = "aoetal mask "
	icon_state = "mask_coral"
	desc = "An aoetal mask that both conceals and protects the face."
	max_integrity = 85
	blocksound = PLATEHIT
	break_sound = 'sound/foley/breaksound.ogg'
	drop_sound = 'sound/foley/dropsound/armor_drop.ogg'
	armor = list("blunt" = DR_ULTRA, "slash" = DBLOCK_HEAVY, "stab" = DBLOCK_HEAVY, "piercing" = DBLOCK_MEDIUM, "fire" = DR_NONE, "acid" = DR_NONE)
	prevent_crits = list(BCLASS_LASHING, BCLASS_BITE, BCLASS_TWIST, BCLASS_CUT, BCLASS_CHOP, BCLASS_BLUNT, BCLASS_STAB)
	flags_inv = HIDEFACE
	body_parts_covered = FACE
	block2add = FOV_BEHIND
	slot_flags = ITEM_SLOT_MASK|ITEM_SLOT_HIP
	experimental_onhip = TRUE
	sewrepair = null
	anvilrepair = null
	clothing_flags = CANT_SLEEP_IN
	sellprice = 80

/obj/item/clothing/face/ambermask
	item_weight = 1.5 KILOGRAMS
	name = "petriamber mask "
	icon_state = "mask_amber"
	desc = "A petriamber mask that both conceals and protects the face."
	max_integrity = 85
	blocksound = PLATEHIT
	break_sound = 'sound/foley/breaksound.ogg'
	drop_sound = 'sound/foley/dropsound/armor_drop.ogg'
	armor = list("blunt" = DR_ULTRA, "slash" = DBLOCK_HEAVY, "stab" = DBLOCK_HEAVY, "piercing" = DBLOCK_MEDIUM, "fire" = DR_NONE, "acid" = DR_NONE)
	prevent_crits = list(BCLASS_LASHING, BCLASS_BITE, BCLASS_TWIST, BCLASS_CUT, BCLASS_CHOP, BCLASS_BLUNT, BCLASS_STAB)
	flags_inv = HIDEFACE
	body_parts_covered = FACE
	block2add = FOV_BEHIND
	slot_flags = ITEM_SLOT_MASK|ITEM_SLOT_HIP
	experimental_onhip = TRUE
	sewrepair = null
	anvilrepair = null
	clothing_flags = CANT_SLEEP_IN
	sellprice = 70

/obj/item/clothing/face/onyxamask
	item_weight = 1.7 KILOGRAMS
	name = "onyxa mask "
	icon_state = "mask_onyxa"
	desc = "An onyxa mask that both conceals and protects the face."
	max_integrity = 85
	blocksound = PLATEHIT
	break_sound = 'sound/foley/breaksound.ogg'
	drop_sound = 'sound/foley/dropsound/armor_drop.ogg'
	armor = list("blunt" = DR_ULTRA, "slash" = DBLOCK_HEAVY, "stab" = DBLOCK_HEAVY, "piercing" = DBLOCK_MEDIUM, "fire" = DR_NONE, "acid" = DR_NONE)
	prevent_crits = list(BCLASS_LASHING, BCLASS_BITE, BCLASS_TWIST, BCLASS_CUT, BCLASS_CHOP, BCLASS_BLUNT, BCLASS_STAB)
	flags_inv = HIDEFACE
	body_parts_covered = FACE
	block2add = FOV_BEHIND
	slot_flags = ITEM_SLOT_MASK|ITEM_SLOT_HIP
	experimental_onhip = TRUE
	sewrepair = null
	anvilrepair = null
	clothing_flags = CANT_SLEEP_IN
	sellprice = 50

/obj/item/clothing/face/opalmask
	item_weight = 1.8 KILOGRAMS
	name = "opaloise mask "
	icon_state = "mask_opal"
	desc = "An opaloise mask that both conceals and protects the face."
	max_integrity = 85
	blocksound = PLATEHIT
	break_sound = 'sound/foley/breaksound.ogg'
	drop_sound = 'sound/foley/dropsound/armor_drop.ogg'
	armor = list("blunt" = DR_ULTRA, "slash" = DBLOCK_HEAVY, "stab" = DBLOCK_HEAVY, "piercing" = DBLOCK_MEDIUM, "fire" = DR_NONE, "acid" = DR_NONE)
	prevent_crits = list(BCLASS_LASHING, BCLASS_BITE, BCLASS_TWIST, BCLASS_CUT, BCLASS_CHOP, BCLASS_BLUNT, BCLASS_STAB)
	flags_inv = HIDEFACE
	body_parts_covered = FACE
	block2add = FOV_BEHIND
	slot_flags = ITEM_SLOT_MASK|ITEM_SLOT_HIP
	experimental_onhip = TRUE
	sewrepair = null
	anvilrepair = null
	clothing_flags = CANT_SLEEP_IN
	sellprice = 100

/obj/item/clothing/face/shepherd/clothmask
	item_weight = 25 GRAMS
	name = "cloth mask"
	icon_state = "clothm"
	desc = "A simple cloth mask that suppresses bad odors, or offers minor protection when doing dirty work such as mining or gravedigging."
	flags_inv = HIDEFACE|HIDEFACIALHAIR
	body_parts_covered = NECK|MOUTH
	slot_flags = ITEM_SLOT_MASK|ITEM_SLOT_HIP
	adjustable = CAN_CADJUST
	resistance_flags = FLAMMABLE
	toggle_icon_state = TRUE
	experimental_onhip = TRUE

/obj/item/clothing/face/facemask/prisoner
	clothing_flags = NONE //they're used to this being stuck on their face

/obj/item/clothing/face/facemask/prisoner/Initialize()
	. = ..()
	name = "cursed mask"
	desc = "We are often criminals in the eyes of the earth, not only for having committed crimes, but because we know that crimes have been committed."
	ADD_TRAIT(src, TRAIT_NODROP, CURSED_ITEM_TRAIT)
	flags_inv = HIDEFACIALHAIR //so prisoners can actually be identified

/obj/item/clothing/face/facemask/prisoner/dropped(mob/living/carbon/human/user)
	. = ..()
	if(QDELETED(src))
		return
	qdel(src)

/obj/item/clothing/face/facemask/steel
	name = "steel mask"
	icon_state = "smask"
	armor = list("blunt" = DR_ULTRA, "slash" = DBLOCK_BSTEEL, "stab" = DBLOCK_BSTEEL, "piercing" = DBLOCK_BSTEEL, "fire" = DR_NONE, "acid" = DR_NONE)
	desc = "A knightly steel mask that both conceals and protects the face. Usually paired with a bascinet."
	max_integrity = 300
	smeltresult = /obj/item/ingot/steel
	melting_material = /datum/material/steel
	melt_amount = 100

/obj/item/clothing/face/facemask/steel/steppe
	name = "steppe war mask"
	icon_state = "steppemask"
	desc = "A steel mask shaped like a face with a prominent moustache, used for protection and intimidation by the steppe riders"

/obj/item/clothing/face/facemask/steel/steppebeast
	name = "steppe beast mask"
	icon_state = "steppemask_snout"
	desc = "A steel mask shaped like a beast's face, worn by steppe riders to intimidate their enemies."

/obj/item/clothing/face/facemask/silver
	item_weight = 1.4 KILOGRAMS
	name = "silver mask"
	icon = 'icons/roguetown/clothing/special/adept.dmi'
	mob_overlay_icon = 'icons/roguetown/clothing/special/onmob/adept.dmi'
	icon_state = "silvermask"
	armor = list("blunt" = DR_ULTRA, "slash" = DBLOCK_BSTEEL, "stab" = DBLOCK_BSTEEL, "piercing" = DBLOCK_BSTEEL, "fire" = DR_NONE, "acid" = DR_NONE)
	desc = "A custom-made silver penance mask, created especially for the Adepts of the Inquisitorial Lodge."
	max_integrity = 300
	smeltresult = /obj/item/ingot/silver
	melting_material = /datum/material/silver
	melt_amount = 100
	var/cross_retracted = 0 // Does the silver mask has it's 3 little spuds retracted or not. Used for toggling.

/obj/item/clothing/face/facemask/silver/Initialize(mapload)
	. = ..()
	enchant(/datum/enchantment/silver)

/obj/item/clothing/face/facemask/silver/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return
	if(!cross_retracted)
		icon_state = "silvermask_rimless"
		cross_retracted = 1
		playsound(user, 'sound/items/indexer_shut.ogg', 65, TRUE)
	else
		icon_state = "silvermask"
		cross_retracted = 0
		playsound(user, 'sound/items/indexer_open.ogg', 65, TRUE)
	update_appearance(UPDATE_ICON)
	if(loc == user && ishuman(user))
		var/mob/living/carbon/H = user
		H.update_inv_head()
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/item/clothing/face/facemask/shadowfacemask
	item_weight = 290 GRAMS
	name = "anthraxi war mask"
	desc = "A metal mask resembling a spider's face. Such a visage haunts many an older dark elf's nitemares - while the younger generation simply scoffs at such relics."
	icon_state = "shadowfacemask"
	smeltresult = null// the mask is made out of silk and cloth, turns out it was giving "free" iron
	melting_material = null

/obj/item/clothing/face/shepherd
	item_weight = 25 GRAMS
	name = "halfmask"
	icon_state = "shepherd"
	flags_inv = HIDEFACE|HIDEFACIALHAIR
	body_parts_covered = NECK|MOUTH
	slot_flags = ITEM_SLOT_MASK|ITEM_SLOT_HIP
	adjustable = CAN_CADJUST
	resistance_flags = FLAMMABLE
	toggle_icon_state = TRUE
	experimental_onhip = TRUE
	salvage_amount = 1
	gas_transfer_coefficient = 0.3

/obj/item/clothing/face/shepherd/AdjustClothes(mob/user)
	if(loc == user)
		if(adjustable == CAN_CADJUST)
			adjustable = CADJUSTED
			if(toggle_icon_state)
				icon_state = "[initial(icon_state)]_t"
			flags_inv = null
			body_parts_covered = NECK
			if(ishuman(user))
				var/mob/living/carbon/H = user
				H.update_inv_wear_mask()
			gas_transfer_coefficient = 0
		else if(adjustable == CADJUSTED)
			ResetAdjust(user)
			flags_inv = HIDEFACE|HIDEFACIALHAIR
			body_parts_covered = NECK|MOUTH
			if(user)
				if(ishuman(user))
					var/mob/living/carbon/H = user
					H.update_inv_wear_mask()
		user.regenerate_clothes()

/obj/item/clothing/face/shepherd/rag
	icon_state = "ragmask"

/obj/item/clothing/face/shepherd/shadowmask
	name = "purple halfmask"
	icon_state = "shadowmask"
	desc = "Tiny drops of white dye mark its front, not unlike teeth. A smile that leers from shadow."

/obj/item/clothing/face/feld
	item_weight = 356 GRAMS
	name = "feldsher's mask"
	desc = "Three times the beaks means three times the doctor."
	icon_state = "feldmask"
	item_state = "feldmask"
	resistance_flags = FLAMMABLE
	flags_inv = HIDEFACE|HIDEHAIR|HIDEFACIALHAIR
	body_parts_covered = FACE|EARS|EYES|MOUTH|NECK
	slot_flags = ITEM_SLOT_MASK|ITEM_SLOT_HIP
	sewrepair = /datum/attribute/skill/misc/sewing/mending
	gas_transfer_coefficient = 0.3

/obj/item/clothing/face/phys
	item_weight = 356 GRAMS
	name = "physicker's mask"
	desc = "Packed with herbs to conceal the rot."
	icon_state = "surgmask"
	item_state = "surgmask"
	resistance_flags = FLAMMABLE
	flags_inv = HIDEFACE|HIDEHAIR|HIDEFACIALHAIR
	body_parts_covered = FACE|EARS|EYES|MOUTH|NECK
	slot_flags = ITEM_SLOT_MASK|ITEM_SLOT_HIP
	sewrepair = /datum/attribute/skill/misc/sewing/mending
	gas_transfer_coefficient = 0.3

/obj/item/clothing/face/courtphysician
	item_weight = 275 GRAMS
	name = "court physican's mask"
	desc = "Similar to a feldsher's mask, this one is made with actual bone! Don't ask whose."
	icon_state = "docmask"
	item_state = "docmask"
	resistance_flags = FLAMMABLE
	flags_inv = HIDEFACE|HIDEFACIALHAIR
	body_parts_covered = FACE|EARS|EYES|MOUTH|NECK
	slot_flags = ITEM_SLOT_MASK|ITEM_SLOT_HIP
	sewrepair = /datum/attribute/skill/misc/sewing/mending
	gas_transfer_coefficient = 0.3
	icon = 'icons/roguetown/clothing/courtphys.dmi'
	mob_overlay_icon = 'icons/roguetown/clothing/onmob/courtphys.dmi'

/obj/item/clothing/face/phys/plaguebearer
	name = "plague's mask"
	desc = "Packed with herbs and obfuscated enough."
	clothing_flags = BLOCK_GAS_SMOKE_EFFECT

/obj/item/clothing/face/facemask/copper
	item_weight = 945 GRAMS
	name = "copper mask"
	icon_state = "cmask"
	desc = "A heavy copper mask that conceals and protects the face, though not very effectively."
	max_integrity = 100
	blocksound = PLATEHIT
	break_sound = 'sound/foley/breaksound.ogg'
	drop_sound = 'sound/foley/dropsound/armor_drop.ogg'
	armor = list("blunt" = DR_HEAVY, "slash" = DBLOCK_HEAVY, "stab" = DBLOCK_HEAVY, "piercing" = DBLOCK_MEDIUM, "fire" = DR_NONE, "acid" = DR_NONE)
	flags_inv = HIDEFACE
	body_parts_covered = FACE
	block2add = FOV_BEHIND
	slot_flags = ITEM_SLOT_MASK|ITEM_SLOT_HIP
	experimental_onhip = TRUE
	sewrepair = null
	anvilrepair = /datum/attribute/skill/craft/armor_repair
	smeltresult = /obj/item/ingot/copper
	melting_material = /datum/material/copper

//................ Druids Mask ............... //
/obj/item/clothing/face/druid
	item_weight = 356 GRAMS
	name = "druids mask"
	desc = "Roots from an old oak-tree, shaped according to the wishes of Tree-father."
	icon = 'icons/roguetown/clothing/head.dmi'
	mob_overlay_icon = 'icons/roguetown/clothing/onmob/head.dmi'
	icon_state = "dendormask"
	resistance_flags = FIRE_PROOF
	flags_inv = HIDEFACE
	body_parts_covered = FACE
	block2add = FOV_BEHIND
	slot_flags = ITEM_SLOT_MASK
	experimental_onhip = TRUE

	armor = ARMOR_WEAK
	prevent_crits = CUT_AND_MINOR_CRITS

/obj/item/clothing/face/skullmask
	item_weight = 240 GRAMS
	name = "skull mask"
	icon_state = "skullmask"
	max_integrity = 100
	blocksound = PLATEHIT
	break_sound = 'sound/foley/breaksound.ogg'
	drop_sound = 'sound/foley/dropsound/gen_drop.ogg'
	resistance_flags = FIRE_PROOF
	armor = list("blunt" = DR_LIGHT, "slash" = DBLOCK_MEDIUM, "stab" = DBLOCK_MEDIUM, "piercing" = DBLOCK_LIGHT, "fire" = DR_NONE, "acid" = DR_NONE)
	prevent_crits = null
	flags_inv = HIDEFACE
	body_parts_covered = FACE
	block2add = FOV_BEHIND
	slot_flags = ITEM_SLOT_MASK|ITEM_SLOT_HIP
	experimental_onhip = TRUE
	smeltresult = /obj/item/alch/bone

/obj/item/clothing/face/facemask/goldmask
	item_weight = 2.8 KILOGRAMS
	name = "gold mask"
	icon_state = "goldmask"
	max_integrity = 150
	sellprice = 100
	smeltresult = /obj/item/ingot/gold
	melting_material = /datum/material/gold

/obj/item/clothing/face/operavisage
	item_weight = 356 GRAMS
	name = "opera visage"
	desc = "A painted wooden opera mask worn by the faithful of Sune, usually during their rituals."
	icon_state = "eoramask"
	mob_overlay_icon = 'icons/roguetown/clothing/onmob/64x64/head.dmi'
	bloody_icon = 'icons/effects/blood64x64.dmi'
	bloody_icon_state = "helmetblood_big"
	worn_x_dimension = 64
	worn_y_dimension = 64
	dynamic_hair_suffix = ""
	salvage_result = /obj/item/natural/silk
	flags_inv = HIDEFACE
	resistance_flags = FLAMMABLE

