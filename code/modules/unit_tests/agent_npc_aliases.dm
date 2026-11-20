// Aliases: other names an NPC answers to. Positive evidence only, and never while masked.

/// An unbound agent pawn whose profile answers to the given aliases.
/datum/unit_test/proc/agent_test_aliased_pawn(list/aliases)
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = allocate(/mob/living/carbon/human/species/human/northern/agent_social)
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	controller.profile.aliases = aliases
	return pawn

/datum/unit_test/agent_npc_aliases_are_cleaned

/datum/unit_test/agent_npc_aliases_are_cleaned/Run()
	var/list/cleaned = agent_clean_profile_aliases("Ike, Айзек, , Ike, <b>Zeb</b>, Fifth, Sixth")
	TEST_ASSERT_EQUAL(length(cleaned), AGENT_MAX_ALIASES, "Aliases must stop at the cap; each one is matched on every line heard.")
	TEST_ASSERT_EQUAL(cleaned[1], "Ike", "Surrounding spaces must be trimmed.")
	TEST_ASSERT_EQUAL(cleaned[2], "Айзек", "A Cyrillic alias must survive cleaning intact.")
	TEST_ASSERT_EQUAL(cleaned[3], "Zeb", "Markup must be stripped, blanks and repeats dropped.")
	TEST_ASSERT_EQUAL(length(agent_clean_profile_aliases(list("Ike", 7, null))), 1, "Non-text entries must be dropped.")
	TEST_ASSERT_EQUAL(length(agent_clean_profile_aliases(42)), 0, "A non-list, non-text value is no aliases.")

/datum/unit_test/agent_npc_profile_text_stays_plain

/datum/unit_test/agent_npc_profile_text_stays_plain/Run()
	TEST_ASSERT_EQUAL(agent_clean_profile_text("You're <b>kind</b>"), "You're kind", "Apostrophes must reach the model as apostrophes, and tags must go.")
	// Profiles saved before this fix hold encoded text. Loading must repair it, not encode it again.
	TEST_ASSERT_EQUAL(agent_clean_profile_text("You&#39;re kind"), "You're kind", "Old encoded text must decode on load.")
	var/once = agent_clean_profile_text("O'Brien & sons <3")
	TEST_ASSERT_EQUAL(agent_clean_profile_text(once), once, "Cleaning twice must change nothing, or every save and load grows the text.")
	TEST_ASSERT(!findtext(agent_clean_profile_text("&lt;script&gt;alert(1)&lt;/script&gt;"), "<"), "Encoded markup must not come back as markup.")

/datum/unit_test/agent_npc_aliases_survive_the_library

/datum/unit_test/agent_npc_aliases_survive_the_library/Run()
	var/datum/agent_profile/original = new /datum/agent_profile/villager()
	original.aliases = list("Ike", "Айзек")
	var/datum/agent_profile/copy = original.clone()
	var/datum/agent_profile/rebuilt = agent_profile_from_payload(original.to_payload())

	TEST_ASSERT_EQUAL(length(copy.aliases), 2, "A clone must carry the aliases.")
	copy.aliases += "Third"
	TEST_ASSERT_EQUAL(length(original.aliases), 2, "Editing a clone must not change the original's aliases.")
	TEST_ASSERT_EQUAL(length(rebuilt.aliases), 2, "Aliases must survive a save and load.")
	TEST_ASSERT_EQUAL(rebuilt.aliases[2], "Айзек", "A Cyrillic alias must survive a save and load.")
	qdel(original)
	qdel(copy)
	qdel(rebuilt)

/datum/unit_test/agent_npc_aliases_wake_the_npc

/datum/unit_test/agent_npc_aliases_wake_the_npc/Run()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_aliased_pawn(list("Zebulon", "Айзек"))
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_EQUAL(pawn.get_visible_name(), pawn.real_name, "Setup failed: the NPC's face must be showing.")

	TEST_ASSERT_EQUAL(controller.self_address_strength("Zebulon, come here"), AGENT_NAMED_STRONG, "A nickname said as a vocative must address the NPC.")
	// The case aliases exist for: a transliteration folding cannot reach.
	TEST_ASSERT_EQUAL(controller.self_address_strength("Айзек, иди сюда"), AGENT_NAMED_STRONG, "A Cyrillic alias must address the NPC.")
	var/list/context = controller.build_emote_context(pawn, "hugs Zebulon.")
	TEST_ASSERT_EQUAL(context["named_us"], AGENT_NAMED_STRONG, "An emote naming an alias names the NPC.")

	controller.profile.aliases = list()
	TEST_ASSERT_EQUAL(controller.self_address_strength("Zebulon, come here"), AGENT_NAMED_NONE, "Without the alias, the same line must not address the NPC.")

/datum/unit_test/agent_npc_aliases_are_ignored_while_masked

/datum/unit_test/agent_npc_aliases_are_ignored_while_masked/Run()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_aliased_pawn(list("Zebulon"))
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller

	pawn.name_override = "Masked Stranger"
	var/strength = controller.self_address_strength("Zebulon, come here")
	var/list/names = controller.addressable_names()
	pawn.name_override = null

	// A disguised NPC turning at its nickname gives the disguise away.
	TEST_ASSERT_EQUAL(strength, AGENT_NAMED_NONE, "A masked NPC must not answer to its aliases.")
	TEST_ASSERT_EQUAL(length(names), 1, "Only the visible name may be used while masked.")
