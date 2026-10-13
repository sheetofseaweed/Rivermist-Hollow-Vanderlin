// Shared support for clothing ported from Azure Peak and Twilight Axis.
// Both modular_azurepeak and modular_twilightaxis rely on this file.

/obj/item/clothing
	/// Second colourable overlay layer used by plumes, crests and trims.
	var/altdetail_tag
	var/altdetail_color
	/// Uses the generic visor/coif toggle below instead of a bespoke AdjustClothes().
	var/ported_adjust = FALSE
	/// Body coverage while toggled open.
	var/adj_open_coverage
	/// flags_inv while toggled open.
	var/adj_open_inv
	/// flags_cover while toggled open.
	var/adj_open_cover
	/// block2add while toggled open.
	var/adj_open_fov
	var/adj_sound

/obj/item/clothing/proc/get_altdetail_tag()
	return altdetail_tag

/obj/item/clothing/proc/get_altdetail_color()
	return altdetail_color

/obj/item/clothing/update_overlays()
	. = ..()
	if(!altdetail_tag)
		return
	var/mutable_appearance/pic = mutable_appearance(icon, "[icon_state][altdetail_tag]")
	pic.appearance_flags = RESET_COLOR
	if(altdetail_color)
		pic.color = altdetail_color
	. += pic

/obj/item/clothing/worn_overlays(mutable_appearance/standing, isinhands = FALSE, icon_file, dummy_block = FALSE)
	. = ..()
	if(isinhands || !altdetail_tag || !standing)
		return
	var/mutable_appearance/pic = mutable_appearance(standing.icon, "[standing.icon_state][altdetail_tag]")
	pic.appearance_flags = RESET_COLOR
	if(altdetail_color)
		pic.color = altdetail_color
	. += pic

/obj/item/clothing/AdjustClothes(mob/user)
	if(!ported_adjust)
		return ..()
	if(loc != user)
		to_chat(user, span_warning("I need to wear [src] to adjust it."))
		return
	if(adjustable == CAN_CADJUST)
		adjustable = CADJUSTED
		icon_state = "[initial(icon_state)]_t"
		body_parts_covered = adj_open_coverage
		flags_inv = adj_open_inv
		flags_cover = adj_open_cover
		block2add = adj_open_fov
	else if(adjustable == CADJUSTED)
		ResetAdjust(user)
	if(adj_sound)
		playsound(user, adj_sound, 50, TRUE, -1)
	update_appearance()
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		H.update_clothing(slot_flags)
		H.update_fov_angles()

/obj/structure/dye_bin/interact(mob/living/user)
	var/obj/item/clothing/C = inserted
	if(!istype(C) || !C.get_altdetail_tag())
		return ..()
	var/list/dat = list("<STYLE> * {text-align: center;} </STYLE>")
	var/ref = REF(src)
	dat += "Item inserted: \the [inserted]<BR>"
	dat += "<A href='byond://?src=[ref];action=eject'>Remove item.</A>"
	dat += "<HR>"
	dat += "Color: <span style='color:[active_color];'>&#9632;</span>"
	dat += "<BR>"
	dat += "<A href='byond://?src=[ref];action=select'>Select new color.</A>"
	dat += "<BR>"
	dat += "<A href='byond://?src=[ref];action=paint;type=base'>Taint with dye.</A>"
	if(C.get_detail_tag())
		dat += " | <A href='byond://?src=[ref];action=paint;type=detail'>Apply dye to accent.</A>"
	dat += " | <A href='byond://?src=[ref];action=paint;type=altdetail'>Apply dye to second accent.</A>"
	var/datum/browser/menu = new(user, "colormate","<CENTER>[src]</CENTER>", 400, 400, src)
	menu.set_content(dat.Join())
	menu.open()

/obj/structure/dye_bin/Topic(href, href_list)
	if(href_list["action"] != "paint" || href_list["type"] != "altdetail")
		return ..()
	var/mob/living/user = usr
	if(!istype(user) || !user.can_perform_action(src, FORBID_TELEKINESIS_REACH))
		return
	var/obj/item/clothing/C = inserted
	if(!istype(C) || !active_color)
		return
	playsound(src, pick('sound/foley/waterwash (1).ogg','sound/foley/waterwash (2).ogg'), 50, FALSE)
	if(!do_after(user, 1 SECONDS, src))
		return
	C.altdetail_color = active_color
	C.update_appearance(UPDATE_OVERLAYS)
	user.visible_message(span_notice("[user] dyes [C] in [src]."), span_notice("I dye [C] in [src]."))
	C.forceMove(get_turf(src))
	inserted = null
	icon_state = initial(icon_state)


// ---------------------------------------------------------------------------
// Aesthetic storage: purely cosmetic pieces layered over hats, armour and gloves.
// The storage component is only created the first time someone opens it.
// ---------------------------------------------------------------------------

/obj/item/clothing
	/// Storage opened with Shift+RMB to layer cosmetic pieces over this one. Null disables it.
	var/aesthetic_storage_type
	/// Set while stored in another piece's aesthetic storage but toggled hidden.
	var/aesthetic_hidden = FALSE
	/// Layer toggles (cloaks, wrists, rings, masks, hoods) remember whether they were flipped.
	var/layer_flipped = FALSE
	/// Masks with a "_snout" worn sprite can swap to it.
	var/snouted = FALSE

/obj/item/clothing/head
	aesthetic_storage_type = /datum/component/storage/concrete/grid/aesthetic/hat

/obj/item/clothing/armor
	aesthetic_storage_type = /datum/component/storage/concrete/grid/aesthetic/armor

/obj/item/clothing/gloves
	aesthetic_storage_type = /datum/component/storage/concrete/grid/aesthetic/gloves

/datum/component/storage/concrete/grid/aesthetic
	screen_max_rows = 2
	screen_max_columns = 2
	max_w_class = WEIGHT_CLASS_GIGANTIC
	attack_hand_interact = FALSE
	silent = TRUE
	rustle_sound = null
	insert_verb = "fit"
	insert_preposition = "onto"
	allow_big_nesting = TRUE
	/// Slots a piece must be wearable in to be layered here.
	var/allowed_slots = NONE

/datum/component/storage/concrete/grid/aesthetic/Initialize(datum/component/storage/concrete/master)
	. = ..()
	// Only the storage window inserts or removes; the piece keeps its own clicks (visors, plumes, hoods).
	UnregisterSignal(parent, list(
		COMSIG_ATOM_ATTACKBY,
		COMSIG_ATOM_ATTACKBY_SECONDARY,
		COMSIG_CLICK_ALT,
		COMSIG_ATOM_ATTACK_HAND_SECONDARY,
		COMSIG_ITEM_PRE_ATTACK,
		COMSIG_ITEM_ATTACK_SELF,
		COMSIG_MOUSEDROP_ONTO,
		COMSIG_ATOM_ATTACK_PAW,
	))

/datum/component/storage/concrete/grid/aesthetic/can_be_inserted(obj/item/storing, stop_messages, mob/user, worn_check = FALSE, list/modifiers, storage_click = FALSE)
	if(!istype(storing, /obj/item/clothing))
		return FALSE
	if(!(storing.slot_flags & allowed_slots))
		return FALSE
	if(storing.get_armor_rating(STAB) > 0 || storing.get_armor_rating(BLUNT) > 0)
		return FALSE
	if(length(storing.contents) || storing.GetComponent(/datum/component/storage))
		return FALSE
	return ..()

/datum/component/storage/concrete/grid/aesthetic/handle_item_insertion(obj/item/storing, prevent_warning = FALSE, mob/user, datum/component/storage/remote, list/modifiers, storage_click = FALSE)
	. = ..()
	refresh_wearer()

/datum/component/storage/concrete/grid/aesthetic/remove_from_storage(atom/movable/removed, atom/new_location)
	. = ..()
	var/obj/item/clothing/C = removed
	if(istype(C))
		C.aesthetic_hidden = FALSE
	refresh_wearer()

/datum/component/storage/concrete/grid/aesthetic/proc/refresh_wearer()
	var/obj/item/clothing/C = parent
	if(ismob(C.loc))
		var/mob/M = C.loc
		M.update_clothing(C.slot_flags)

/datum/component/storage/concrete/grid/aesthetic/hat
	allowed_slots = ITEM_SLOT_HEAD|ITEM_SLOT_MASK|ITEM_SLOT_NECK

/datum/component/storage/concrete/grid/aesthetic/armor
	allowed_slots = ITEM_SLOT_CLOAK|ITEM_SLOT_ARMOR|ITEM_SLOT_SHIRT

/datum/component/storage/concrete/grid/aesthetic/gloves
	allowed_slots = ITEM_SLOT_RING|ITEM_SLOT_GLOVES

/// Returns our aesthetic storage, optionally creating it. Pieces that already carry another storage never get one.
/obj/item/clothing/proc/get_aesthetic_storage(create = FALSE)
	if(!aesthetic_storage_type)
		return null
	var/datum/component/storage/existing = GetComponent(/datum/component/storage)
	if(existing)
		return istype(existing, /datum/component/storage/concrete/grid/aesthetic) ? existing : null
	if(!create)
		return null
	return AddComponent(aesthetic_storage_type)

/obj/item/clothing/proc/open_aesthetic_storage(mob/user)
	if(!aesthetic_storage_type || loc != user)
		return FALSE
	var/datum/component/storage/S = get_aesthetic_storage(TRUE)
	if(!S)
		return FALSE
	S.user_show_to_mob(user, TRUE)
	return TRUE

/// Lets the wearer pick a stored piece and show or hide it. Returns TRUE if anything was stored.
/obj/item/clothing/proc/toggle_aesthetic_layer(mob/user)
	if(loc != user)
		return FALSE
	var/list/stored = list()
	for(var/obj/item/clothing/C in contents)
		stored["[C.name] ([C.aesthetic_hidden ? "hidden" : "shown"])"] = C
	if(!length(stored) || !get_aesthetic_storage())
		return FALSE
	var/choice = browser_input_list(user, "Choose a piece to show or hide.", "Layering", stored)
	var/obj/item/clothing/picked = stored[choice]
	if(!picked || picked.loc != src)
		return TRUE
	picked.aesthetic_hidden = !picked.aesthetic_hidden
	to_chat(user, span_info("[picked] will be [picked.aesthetic_hidden ? "hidden under" : "shown over"] [src]."))
	user.update_clothing(slot_flags)
	return TRUE

/obj/item/clothing/ShiftRightClick(mob/user)
	if(open_aesthetic_storage(user))
		return TRUE
	return ..()

/obj/item/clothing/AltRightClick(mob/user, list/modifiers)
	if(toggle_aesthetic_layer(user))
		return TRUE
	return ..()

/obj/item/clothing/get_examine_name(mob/user, use_article = TRUE)
	. = ..()
	if(!aesthetic_storage_type || !length(contents) || !get_aesthetic_storage())
		return
	var/list/shown = list()
	for(var/obj/item/clothing/C in contents)
		if(!C.aesthetic_hidden)
			shown += C.name
	if(length(shown))
		. += " ([shown.Join(", ")])"

/obj/item/clothing/build_worn_icon(age = AGE_ADULT, default_layer = 0, default_icon_file = null, isinhands = FALSE, femaleuniform = NO_FEMALE_UNIFORM, override_state = null, coom = FALSE, customi = null, sleeveindex, breast_size = 0, icon/clip_mask = null)
	var/mutable_appearance/standing = ..()
	if(isinhands || !aesthetic_storage_type || !length(contents) || !get_aesthetic_storage())
		return standing
	for(var/obj/item/clothing/C in contents)
		if(C.aesthetic_hidden)
			continue
		var/mutable_appearance/layered = C.build_worn_icon(age, default_layer, C.mob_overlay_icon, FALSE, femaleuniform, null, coom, customi, sleeveindex, breast_size, clip_mask)
		if(!layered)
			continue
		layered.appearance_flags |= RESET_COLOR
		layered.pixel_x -= standing.pixel_x
		layered.pixel_y -= standing.pixel_y
		standing.overlays += layered
	return standing

/// Shift+RMB on a piece you carry opens it instead of looking past it.
/mob/living/ShiftRightClickOn(atom/clicked_atom, list/modifiers)
	if(istype(clicked_atom, /obj/item/clothing) && clicked_atom.loc == src)
		clicked_atom.ShiftRightClick(src)
		return
	return ..()

// ---------------------------------------------------------------------------
// Middle-click layer and visibility toggles
// ---------------------------------------------------------------------------

/// True when a middle-click should go to the base sleeve tear/roll handling instead.
/obj/item/clothing/proc/is_sleeve_click(mob/living/user, list/modifiers)
	if(nodismemsleeves || !istype(user))
		return FALSE
	if(LAZYACCESS(modifiers, ALT_CLICKED))
		return (l_sleeve_status != SLEEVE_NOMOD || r_sleeve_status != SLEEVE_NOMOD)
	if(user.zone_selected == l_sleeve_zone && l_sleeve_status != SLEEVE_NOMOD)
		return TRUE
	if(user.zone_selected == r_sleeve_zone && r_sleeve_status != SLEEVE_NOMOD)
		return TRUE
	return FALSE

/obj/item/clothing/cloak/MiddleClick(mob/living/user, list/modifiers)
	if(is_sleeve_click(user, modifiers))
		return ..()
	if(!istype(user))
		return
	layer_flipped = !layer_flipped
	alternate_worn_layer = layer_flipped ? UNDER_ARMOR_LAYER : initial(alternate_worn_layer)
	to_chat(user, span_info("I wear [src] [layer_flipped ? "under" : "over"] my armor."))
	user.update_inv_cloak()
	user.update_inv_armor()
	user.update_inv_back()

/obj/item/clothing/wrists/MiddleClick(mob/living/user, list/modifiers)
	if(is_sleeve_click(user, modifiers))
		return ..()
	if(!istype(user))
		return
	layer_flipped = !layer_flipped
	alternate_worn_layer = layer_flipped ? (ARMOR_LAYER - 0.5) : initial(alternate_worn_layer)
	to_chat(user, span_info("I wear [src] [layer_flipped ? "over" : "under"] my armor."))
	user.update_inv_wrists()
	user.update_inv_gloves()
	user.update_inv_armor()
	user.update_inv_shirt()

/obj/item/clothing/ring/MiddleClick(mob/living/user, list/modifiers)
	if(!istype(user))
		return
	layer_flipped = !layer_flipped
	alternate_worn_layer = layer_flipped ? UNDER_ARMOR_LAYER : initial(alternate_worn_layer)
	to_chat(user, span_info("I wear [src] [layer_flipped ? "under" : "over"] my sleeves."))
	user.update_inv_ring()
	user.update_inv_gloves()

/obj/item/clothing/face/MiddleClick(mob/living/user, list/modifiers)
	if(!istype(user))
		return
	layer_flipped = !layer_flipped
	alternate_worn_layer = layer_flipped ? (HAIR_LAYER + 0.5) : initial(alternate_worn_layer)
	to_chat(user, span_info("I wear [src] [layer_flipped ? "under" : "over"] my hair."))
	user.update_inv_wear_mask()

/obj/item/clothing/face/AltRightClick(mob/user, list/modifiers)
	if(loc != user)
		return ..()
	var/snout_state = "[initial(icon_state)]_snout"
	if(!snouted && !(mob_overlay_icon && icon_exists(mob_overlay_icon, snout_state)))
		return ..()
	snouted = !snouted
	icon_state = snouted ? snout_state : initial(icon_state)
	to_chat(user, span_info("I adjust [src] to fit [snouted ? "a snout" : "a flat face"]."))
	update_appearance()
	user.update_inv_wear_mask()
	return TRUE

/// Cycles: hair and ears tucked -> ears out -> hair out -> tucked again.
/obj/item/clothing/head/MiddleClick(mob/living/user, list/modifiers)
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	switch(flags_inv & (HIDEEARS|HIDEHAIR))
		if(HIDEEARS|HIDEHAIR)
			flags_inv &= ~HIDEEARS
			to_chat(user, span_info("I free my ears from under [src]."))
		if(HIDEHAIR)
			flags_inv &= ~HIDEHAIR
			to_chat(user, span_info("I pull my hair out from under [src]."))
		else
			flags_inv |= (HIDEEARS|HIDEHAIR)
			to_chat(user, span_info("I tuck my hair and ears under [src]."))
	if(H.head == src)
		H.head_update(src, TRUE)
		H.update_inv_head()

/obj/item/clothing/head/roguehood/AltRightClick(mob/user, list/modifiers)
	if(loc != user)
		return ..()
	if(toggle_aesthetic_layer(user))
		return TRUE
	layer_flipped = !layer_flipped
	alternate_worn_layer = layer_flipped ? (HAIR_LAYER - 0.5) : initial(alternate_worn_layer)
	to_chat(user, span_info("I wear [src] [layer_flipped ? "over" : "under"] my hair."))
	user.update_inv_head()
	return TRUE

// ---------------------------------------------------------------------------
// Holy symbols: pray with middle-click, some can be worn around the wrist
// ---------------------------------------------------------------------------

/obj/item/clothing/neck/psycross
	/// Worn-sprite file used while the amulet is wrapped around the wrist. Null if it has no wrist sprites.
	var/wrist_mob_icon
	var/wrist_display = FALSE

/obj/item/clothing/neck/psycross/MiddleClick(mob/living/user, list/modifiers)
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	if(!(/mob/living/carbon/human/proc/clericpray in H.verbs))
		to_chat(user, span_warning("I don't know the proper prayers."))
		return
	H.changeNext_move(CLICK_CD_MELEE)
	H.clericpray()

/obj/item/clothing/neck/psycross/attack_hand_secondary(mob/user, list/modifiers)
	if(!wrist_mob_icon || loc != user)
		return ..()
	wrist_display = !wrist_display
	mob_overlay_icon = wrist_display ? wrist_mob_icon : initial(mob_overlay_icon)
	sleeved = wrist_display ? wrist_mob_icon : initial(sleeved)
	to_chat(user, span_info("I adjust [src] to hang [wrist_display ? "from my wrist" : "around my neck"]."))
	user.regenerate_clothes()
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

// ---------------------------------------------------------------------------
// Mechanics hints (examine -> mechanics)
// ---------------------------------------------------------------------------

/obj/item/clothing/get_mechanics_examine(mob/user)
	. = ..()
	if(hoodtype)
		. += span_info("Right-click it while worn to raise or lower the hood.")
	else if(adjustable > 0)
		. += span_info("Right-click it while worn to adjust how it is worn - raise a visor, loosen a coif, open a robe.")
	if(!nodismemsleeves && (r_sleeve_status != SLEEVE_NOMOD || l_sleeve_status != SLEEVE_NOMOD))
		. += span_info("Middle-click it while targeting a sleeve or leg to tear that part off for an emergency bandage; Alt+middle-click rolls it up or down. Tearing success scales with Strength.")
	if((aesthetic_storage_type && !GetComponent(/datum/component/storage)) || get_aesthetic_storage())
		. += span_info("Shift+RMB on [src] in your inventory opens its aesthetic storage, letting you layer purely decorative pieces over it.")
		. += span_info("Alt+RMB lets you show or hide the pieces layered over [src].")
	if(dyeable || sewrepair)
		. += span_info("It can be dyed in a dye bin[get_detail_tag() ? ", accents included" : ""].")

/obj/item/clothing/head/get_mechanics_examine(mob/user)
	. = ..()
	. += span_info("Middle-click it to cycle whether your ears and hair show from under it.")

/obj/item/clothing/head/helmet/get_mechanics_examine(mob/user)
	. = ..()
	. += span_info("Lifted visors offer a wider field of view, but expose your face to precise strikes.")
	. += span_info("Certain helmets can be decorated by clicking them with a feather, a piece of cloth, or both.")

/obj/item/clothing/head/roguehood/get_mechanics_examine(mob/user)
	. = ..()
	. += span_info("Alt+RMB while worn moves the hood under or over your hair. Most fully drawn hoods hide the wearer's identity.")

/obj/item/clothing/cloak/get_mechanics_examine(mob/user)
	. = ..()
	. += span_info("Certain cloaks - jupons, tabards and surcoats - can be given a pattern and colouring by right-clicking them.")
	. += span_info("Middle-click it to wear it over or under your armor.")

/obj/item/clothing/wrists/get_mechanics_examine(mob/user)
	. = ..()
	. += span_info("Middle-click it to wear it over or under your armor and gloves.")

/obj/item/clothing/ring/get_mechanics_examine(mob/user)
	. = ..()
	. += span_info("Middle-click it to wear it over or under your sleeves.")

/obj/item/clothing/face/get_mechanics_examine(mob/user)
	. = ..()
	. += span_info("Middle-click it to wear it over or under your hair.")
	if(mob_overlay_icon && icon_exists(mob_overlay_icon, "[initial(icon_state)]_snout"))
		. += span_info("Alt+RMB while worn swaps between the snouted and the flat-faced fit.")

/obj/item/clothing/neck/psycross/get_mechanics_examine(mob/user)
	. = ..()
	. += span_info("Middle-click it to kneel in prayer, if you know the prayers. Praying generates devotion for miracles.")
	. += span_info("Typing '*pray' lets you write a dedicated prayer to your patron; such prayers are, rarely, answered.")
	if(wrist_mob_icon)
		. += span_info("Right-click it while worn to wear it around your wrist instead of your neck.")

/obj/item/clothing/gloves/get_mechanics_examine(mob/user)
	. = ..()
	if(unarmed_bonus != 1)
		. += span_notice("Unarmed damage while worn: x[unarmed_bonus].")

/obj/item/clothing/shoes/get_mechanics_examine(mob/user)
	. = ..()
	if(istype(GetComponent(/datum/component/storage), /datum/component/storage/concrete/boots))
		. += span_info("It can hide a knife, a coin or a key. Click it with one to slip it in; right-click it to draw it back out.")

/datum/armor/ported/padded
	blunt = DR_SUPER
	slash = DBLOCK_MEDIUM
	stab = DBLOCK_LIGHT
	piercing = DBLOCK_BSTEEL
	fire = DR_LIGHT
	acid = DR_NONE

/datum/armor/ported/leather
	blunt = DR_ULTRA
	slash = DBLOCK_MEDIUM
	stab = DBLOCK_MEDIUM
	piercing = DBLOCK_HEAVY
	fire = DR_MEDIUM
	acid = DR_NONE

/datum/armor/ported/bronze
	blunt = DR_MEDIUM
	slash = DBLOCK_MEDIUM
	stab = DBLOCK_MEDIUM
	piercing = DBLOCK_MEDIUM
	fire = DR_MEDIUM
	acid = DR_NONE

/datum/armor/ported/plate_bsteel
	blunt = DR_MEDIUM
	slash = DBLOCK_BSTEEL
	stab = DBLOCK_BSTEEL
	piercing = DBLOCK_BSTEEL
	fire = DR_LIGHT
	acid = DR_NONE

/datum/armor/ported/newmoon_hood
	blunt = DR_HEAVY
	slash = DBLOCK_BSTEEL
	stab = DBLOCK_BSTEEL
	piercing = DBLOCK_BSTEEL
	fire = DR_NONE
	acid = DR_NONE

/datum/armor/ported/insulated_brigandine
	blunt = DR_HEAVY
	slash = DBLOCK_HEAVY
	stab = DBLOCK_MEDIUM
	piercing = DBLOCK_HEAVY
	fire = DR_ULTRA
	acid = DR_NONE

/datum/armor/ported/newmoon_jacket
	blunt = DR_SUPER
	slash = DBLOCK_BSTEEL
	stab = DBLOCK_BSTEEL
	piercing = DBLOCK_BSTEEL
	fire = DR_NONE
	acid = DR_NONE

/datum/armor/ported/gnoll_standard
	blunt = DR_SUPER
	slash = DBLOCK_HEAVY
	stab = DBLOCK_HEAVY
	piercing = DBLOCK_HEAVY
	fire = DR_MEDIUM
	acid = DR_NONE

/datum/armor/ported/insulated_leather
	blunt = DR_ULTRA
	slash = DBLOCK_MEDIUM
	stab = DBLOCK_MEDIUM
	piercing = DBLOCK_HEAVY
	fire = DR_ULTRA
	acid = DR_NONE

/datum/armor/ported/gnoll_strong
	blunt = DR_MEDIUM
	slash = DBLOCK_BSTEEL
	stab = DBLOCK_BSTEEL
	piercing = DBLOCK_HEAVY
	fire = DR_MEDIUM
	acid = DR_NONE

/datum/armor/ported/gnoll_weak
	blunt = DR_ULTRA
	slash = DBLOCK_HEAVY
	stab = DBLOCK_HEAVY
	piercing = DBLOCK_MEDIUM
	fire = DR_MEDIUM
	acid = DR_NONE

