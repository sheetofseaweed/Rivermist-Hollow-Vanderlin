// What an agent NPC is shown. In 2026-09-23 play a barstool, clothing and its own bags were invisible.

/// The entry for one atom in a built list, or null. Handles are the only way back to an atom.
/proc/agent_test_find_offered(datum/agent_observation/observation, list/entries, atom/wanted)
	for(var/list/entry as anything in entries)
		if(observation.resolve(entry["handle"]) == wanted)
			return entry
	return null

/datum/unit_test/agent_npc_structures_are_seen

/datum/unit_test/agent_npc_structures_are_seen/Run()
	var/mob/living/carbon/human/pawn = allocate(/mob/living/carbon/human/species/human/northern)
	var/obj/structure/chair/stool/bar/stool = allocate(/obj/structure/chair/stool/bar)

	var/list/built = agent_build_observation(pawn, 1)
	var/datum/agent_observation/observation = built["observation"]
	var/list/payload = built["payload"]
	var/list/entry = agent_test_find_offered(observation, payload["structures"], stool)
	qdel(observation)

	TEST_ASSERT_NOTNULL(entry, "A barstool beside the NPC must be in the scene, with a handle that resolves to it.")
	TEST_ASSERT_EQUAL(entry["name"], "barstool", "A fixture must be named as players see it.")

/datum/unit_test/agent_npc_same_named_structures_are_grouped

/datum/unit_test/agent_npc_same_named_structures_are_grouped/Run()
	var/mob/living/carbon/human/pawn = allocate(/mob/living/carbon/human/species/human/northern)
	var/total = AGENT_STRUCTURE_HANDLES_PER_NAME + 3
	for(var/i in 1 to total)
		allocate(/obj/structure/chair/stool/bar)

	var/list/built = agent_build_observation(pawn, 1)
	var/datum/agent_observation/observation = built["observation"]
	var/list/payload = built["payload"]
	qdel(observation)

	var/listed = 0
	var/counted = 0
	for(var/list/entry as anything in payload["structures"])
		if(entry["name"] != "barstool")
			continue
		listed++
		counted += entry["more"] || 0

	// Twenty stools are one fact about the room, not twenty paid lines.
	TEST_ASSERT_EQUAL(listed, AGENT_STRUCTURE_HANDLES_PER_NAME, "Only the nearest few of one name may be listed.")
	TEST_ASSERT_EQUAL(listed + counted, total, "The rest must be counted, so the model still knows they are there.")

/datum/unit_test/agent_npc_structures_have_their_own_cap

/datum/unit_test/agent_npc_structures_have_their_own_cap/Run()
	var/mob/living/carbon/human/pawn = allocate(/mob/living/carbon/human/species/human/northern)
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human/species/human/northern)
	for(var/i in 1 to AGENT_MAX_STRUCTURES + 3)
		var/obj/structure/chair/stool/bar/stool = allocate(/obj/structure/chair/stool/bar)
		stool.name = "stool [i]"

	var/list/built = agent_build_observation(pawn, 1)
	var/datum/agent_observation/observation = built["observation"]
	var/list/payload = built["payload"]
	var/person = agent_test_find_offered(observation, payload["entities"], bystander)
	qdel(observation)

	TEST_ASSERT_EQUAL(length(payload["structures"]), AGENT_MAX_STRUCTURES, "Fixtures must stop at their own cap.")
	TEST_ASSERT_NOTNULL(person, "A furnished room must never crowd a person out of the scene.")

/datum/unit_test/agent_npc_fixture_state_is_reported

/datum/unit_test/agent_npc_fixture_state_is_reported/Run()
	var/mob/living/carbon/human/pawn = allocate(/mob/living/carbon/human/species/human/northern)
	var/mob/living/carbon/human/sitter = allocate(/mob/living/carbon/human/species/human/northern)
	var/obj/structure/door/door = allocate(/obj/structure/door)
	var/obj/structure/chair/stool/bar/stool = allocate(/obj/structure/chair/stool/bar)

	door.door_opened = FALSE
	var/closed = agent_fixture_state(pawn, door)
	door.door_opened = TRUE
	var/opened = agent_fixture_state(pawn, door)
	door.door_opened = FALSE
	TEST_ASSERT_EQUAL(closed, "closed", "A shut door must say so, or the model walks into it.")
	TEST_ASSERT_EQUAL(opened, "open", "An open door must say so.")

	TEST_ASSERT_NULL(agent_fixture_state(pawn, stool), "An empty stool has nothing worth saying.")
	TEST_ASSERT(stool.buckle_mob(sitter, force = TRUE), "Setup failed: the sitter must be seated.")
	var/taken = agent_fixture_state(pawn, stool)
	var/own = agent_fixture_state(sitter, stool)
	var/list/sitter_self = agent_describe_self(sitter)
	stool.unbuckle_mob(sitter, force = TRUE)

	TEST_ASSERT_EQUAL(taken, "occupied", "A stool someone sits on is taken.")
	TEST_ASSERT_EQUAL(own, "you are on it", "The NPC must know which seat is its own.")
	TEST_ASSERT_EQUAL(sitter_self["on"], "barstool", "The NPC must know it is sitting, and on what.")

/datum/unit_test/agent_npc_others_show_only_visible_clothing

/datum/unit_test/agent_npc_others_show_only_visible_clothing/Run()
	var/mob/living/carbon/human/pawn = allocate(/mob/living/carbon/human/species/human/northern)
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human/species/human/northern)
	var/obj/item/clothing/pants/trou/trousers = allocate(/obj/item/clothing/pants/trou)
	var/obj/item/clothing/shirt/dress/dress = allocate(/obj/item/clothing/shirt/dress)
	var/obj/item/natural/cloth/cloth = allocate(/obj/item/natural/cloth)
	var/obj/item/natural/feather/feather = allocate(/obj/item/natural/feather)
	// Set here, not read from item data: this tests that examine's rule is honoured, not which items hide what.
	trousers.flags_inv = NONE
	dress.flags_inv = HIDEJUMPSUIT

	TEST_ASSERT(bystander.equip_to_slot_if_possible(trousers, ITEM_SLOT_PANTS, disable_warning = TRUE, bypass_equip_delay_self = TRUE), "Setup failed: the trousers must go on.")
	var/list/bare = agent_visible_worn_names(bystander)
	TEST_ASSERT(("[trousers.name]" in bare), "Setup failed: uncovered trousers must be visible.")

	TEST_ASSERT(bystander.equip_to_slot_if_possible(dress, ITEM_SLOT_ARMOR, disable_warning = TRUE, bypass_equip_delay_self = TRUE), "Setup failed: the dress must go on.")
	TEST_ASSERT(bystander.put_in_active_hand(cloth), "Setup failed: the cloth must be held.")
	TEST_ASSERT(bystander.put_in_inactive_hand(feather), "Setup failed: the feather must be held.")

	var/list/built = agent_build_observation(pawn, 1)
	var/datum/agent_observation/observation = built["observation"]
	var/list/payload = built["payload"]
	var/list/entry = agent_test_find_offered(observation, payload["entities"], bystander)
	qdel(observation)

	TEST_ASSERT_NOTNULL(entry, "Setup failed: the bystander must be in the scene.")
	var/list/wearing = entry["wearing"]
	TEST_ASSERT(("[dress.name]" in wearing), "Other people's outer clothing must be visible.")
	// Examine hides it, so the model must not know it either.
	TEST_ASSERT(!("[trousers.name]" in wearing), "Clothing hidden under other clothing must stay hidden.")
	var/list/holding = entry["holding"]
	TEST_ASSERT(("[feather.name]" in holding), "Both hands are visible, not only the active one.")

/datum/unit_test/agent_npc_self_knows_its_own_gear

/datum/unit_test/agent_npc_self_knows_its_own_gear/Run()
	var/mob/living/carbon/human/pawn = allocate(/mob/living/carbon/human/species/human/northern)
	var/obj/item/clothing/shirt/undershirt/shirt = allocate(/obj/item/clothing/shirt/undershirt)
	var/obj/item/clothing/shirt/dress/dress = allocate(/obj/item/clothing/shirt/dress)
	var/obj/item/natural/cloth/cloth = allocate(/obj/item/natural/cloth)
	var/obj/item/storage/belt/pouch/pouch = allocate(/obj/item/storage/belt/pouch)
	var/obj/item/natural/feather/first = allocate(/obj/item/natural/feather)
	var/obj/item/natural/feather/second = allocate(/obj/item/natural/feather)

	TEST_ASSERT(pawn.equip_to_slot_if_possible(shirt, ITEM_SLOT_UNDERSHIRT, disable_warning = TRUE, bypass_equip_delay_self = TRUE), "Setup failed: the undershirt must go on.")
	TEST_ASSERT(pawn.equip_to_slot_if_possible(dress, ITEM_SLOT_ARMOR, disable_warning = TRUE, bypass_equip_delay_self = TRUE), "Setup failed: the dress must go on.")
	TEST_ASSERT(pawn.put_in_active_hand(cloth), "Setup failed: the cloth must be held.")
	TEST_ASSERT(pawn.put_in_inactive_hand(pouch), "Setup failed: the pouch must be held.")
	first.forceMove(pouch)
	second.forceMove(pouch)

	var/list/myself = agent_describe_self(pawn)
	var/list/holding = myself["holding"]
	var/list/wearing = myself["wearing"]
	var/list/carrying = myself["carrying"]

	TEST_ASSERT_EQUAL(length(holding), 2, "Both hands must be listed.")
	TEST_ASSERT_EQUAL(holding[1], "[cloth.name]", "The active hand comes first.")
	TEST_ASSERT(("[shirt.name]" in wearing), "The NPC knows what it put on, even under other layers.")
	TEST_ASSERT_EQUAL(length(carrying), 1, "The pouch's contents must be listed.")
	var/list/bag = carrying[1]
	TEST_ASSERT_EQUAL(bag["in"], "[pouch.name]", "Contents must say which container holds them.")
	var/list/stored = bag["items"]
	TEST_ASSERT(("[first.name] x2" in stored), "Identical items must be counted, not repeated.")

/datum/unit_test/agent_npc_stored_items_are_capped

/datum/unit_test/agent_npc_stored_items_are_capped/Run()
	var/mob/living/carbon/human/pawn = allocate(/mob/living/carbon/human/species/human/northern)
	var/obj/item/storage/belt/pouch/pouch = allocate(/obj/item/storage/belt/pouch)
	TEST_ASSERT(pawn.put_in_active_hand(pouch), "Setup failed: the pouch must be held.")
	for(var/i in 1 to AGENT_MAX_STORED_SHOWN + 4)
		var/obj/item/natural/feather/feather = allocate(/obj/item/natural/feather)
		feather.name = "feather [i]"
		feather.forceMove(pouch)

	var/list/carrying = agent_stored_names(pawn)
	var/listed = 0
	for(var/list/bag as anything in carrying)
		listed += length(bag["items"])

	// Every name is sent on every request. A full satchel must not be a standing cost.
	TEST_ASSERT_EQUAL(listed, AGENT_MAX_STORED_SHOWN, "Stored item names must stop at the cap.")
