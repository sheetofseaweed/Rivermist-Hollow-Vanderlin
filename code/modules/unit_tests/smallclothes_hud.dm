/// Every extra slot needs a drawer slot, or items in it can only be reached through the strip menu.
/datum/unit_test/smallclothes_drawer_covers_every_extra_slot

/datum/unit_test/smallclothes_drawer_covers_every_extra_slot/Run()
	var/mob/living/carbon/human/dummy = allocate(/mob/living/carbon/human)
	dummy.set_hud_used(new /datum/hud/human(dummy))
	var/datum/hud/hud = dummy.hud_used

	var/list/expected = list()
	for(var/slot in DEFAULT_SLOT_PRIORITY)
		if(slot & ITEM_SLOT_EXTRA)
			expected += slot

	var/list/found = list()
	var/list/locations = list()
	for(var/atom/movable/screen/inventory/smallclothes/slot as anything in hud.smallclothes_inventory)
		found += slot.slot_id
		TEST_ASSERT(!(slot.screen_loc in locations), "Drawer slot [slot.name] shares [slot.screen_loc] with another slot.")
		locations += slot.screen_loc
		TEST_ASSERT(icon_exists(slot.icon, slot.icon_state), "Drawer slot [slot.name] has no icon state [slot.icon_state].")

	TEST_ASSERT_EQUAL(length(found), length(expected), "The drawer should hold one slot per extra slot.")
	for(var/slot in expected)
		TEST_ASSERT(slot in found, "Extra slot [slot] has no drawer slot.")
	TEST_ASSERT(!hud.smallclothes_shown, "The drawer should start closed.")

	qdel(hud)
	dummy.hud_used = null

/// The open drawer follows equips in human and carbon slots, and veils slots heavy armor covers.
/datum/unit_test/smallclothes_drawer_tracks_worn_and_covered

/datum/unit_test/smallclothes_drawer_tracks_worn_and_covered/proc/drawer_slot(datum/hud/hud, slot_id)
	for(var/atom/movable/screen/inventory/smallclothes/slot as anything in hud.smallclothes_inventory)
		if(slot.slot_id == slot_id)
			return slot

/datum/unit_test/smallclothes_drawer_tracks_worn_and_covered/Run()
	var/mob/living/carbon/human/dummy = allocate(/mob/living/carbon/human)
	dummy.set_hud_used(new /datum/hud/human(dummy))
	var/datum/hud/hud = dummy.hud_used
	var/atom/movable/screen/inventory/smallclothes/underwear_slot = drawer_slot(hud, ITEM_SLOT_UNDER_BOTTOM)
	var/atom/movable/screen/inventory/smallclothes/socks_slot = drawer_slot(hud, ITEM_SLOT_SOCKS)

	var/obj/item/clothing/undies/briefs = allocate(/obj/item/clothing/undies)
	dummy.equip_to_slot(briefs, ITEM_SLOT_UNDER_BOTTOM)
	hud.toggle_smallclothes_inventory()
	TEST_ASSERT(hud.smallclothes_shown, "The sock button should open the drawer.")
	TEST_ASSERT_EQUAL(underwear_slot.icon_state, "genslot", "A worn item should switch its drawer slot to the filled frame.")
	TEST_ASSERT(!underwear_slot.covered, "Nothing covers the underwear yet.")

	// Human-handled slot: heavy armor hiding the undies veils that slot only
	var/obj/item/clothing/armor/plate = allocate(/obj/item/clothing/armor)
	plate.armor_class = AC_HEAVY
	plate.flags_inv = HIDEUNDIESBOT
	dummy.equip_to_slot(plate, ITEM_SLOT_ARMOR)
	TEST_ASSERT(underwear_slot.covered, "Heavy armor over the undies should veil the underwear slot.")
	TEST_ASSERT(!socks_slot.covered, "Armor that hides only undies should not veil the socks.")

	// Carbon-handled slot: equips there return early from the human proc
	var/obj/item/clothing/shoes/greaves = allocate(/obj/item/clothing/shoes)
	greaves.armor_class = AC_HEAVY
	greaves.flags_inv = HIDECLOSELEGS
	dummy.equip_to_slot(greaves, ITEM_SLOT_SHOES)
	TEST_ASSERT(socks_slot.covered, "Heavy greaves hiding the legs should veil the socks.")

	dummy.dropItemToGround(plate, TRUE)
	TEST_ASSERT(!underwear_slot.covered, "Taking the armor off should lift the veil.")

	dummy.dropItemToGround(briefs, TRUE)
	TEST_ASSERT_EQUAL(underwear_slot.icon_state, "underwear", "An emptied drawer slot should show its silhouette again.")

	hud.toggle_smallclothes_inventory()
	TEST_ASSERT(!hud.smallclothes_shown, "A second press should close the drawer.")

	qdel(hud)
	dummy.hud_used = null

/// Worn items are drawn in drawer slots from their own icon_state, so wearing one must keep that state valid.
/datum/unit_test/smallclothes_worn_earrings_keep_item_icon

/datum/unit_test/smallclothes_worn_earrings_keep_item_icon/Run()
	var/mob/living/carbon/human/dummy = allocate(/mob/living/carbon/human)
	for(var/earring_type in list(/obj/item/earring, /obj/item/earring/dangle))
		var/obj/item/earring/left = allocate(earring_type)
		var/obj/item/earring/right = allocate(earring_type)
		dummy.equip_to_slot(left, ITEM_SLOT_EARRING_L)
		dummy.equip_to_slot(right, ITEM_SLOT_EARRING_R)
		TEST_ASSERT_EQUAL(dummy.earring_l, left, "[earring_type] did not go on the left ear.")
		TEST_ASSERT(icon_exists(left.icon, left.icon_state), "A worn left [earring_type] has no item icon state [left.icon_state].")
		TEST_ASSERT(icon_exists(right.icon, right.icon_state), "A worn right [earring_type] has no item icon state [right.icon_state].")
		dummy.dropItemToGround(left, TRUE)
		dummy.dropItemToGround(right, TRUE)

/// The interact heart owns the bottom HUD tile; anything else there would steal its clicks.
/datum/unit_test/hud_interact_heart_has_its_tile

/datum/unit_test/hud_interact_heart_has_its_tile/Run()
	var/mob/living/carbon/human/dummy = allocate(/mob/living/carbon/human)
	dummy.set_hud_used(new /datum/hud/human(dummy))
	var/datum/hud/hud = dummy.hud_used

	var/atom/movable/screen/interact_heart/heart = locate() in hud.static_inventory
	TEST_ASSERT_NOTNULL(heart, "The human hud has no interact heart.")
	TEST_ASSERT_EQUAL(heart.screen_loc, rogueui_interact, "The interact heart moved off the medallion.")
	TEST_ASSERT(icon_exists(heart.icon, "interact"), "The interact heart has no idle state.")
	TEST_ASSERT(icon_exists(heart.icon, "interact_hover"), "The interact heart has no hover state.")
	for(var/atom/movable/screen/other as anything in hud.static_inventory - heart)
		TEST_ASSERT_NOTEQUAL(other.screen_loc, heart.screen_loc, "[other.type] sits on the interact heart.")

	qdel(hud)
	dummy.hud_used = null
