// Admin-authored profiles: sanitising, the library, and attaching to a mob.
//
// The profile file is meant to be hand-edited, so every one of these reads
// against untrusted input rather than against what the menu happens to send.

/datum/unit_test/agent_npc_profile_actions_are_filtered

/datum/unit_test/agent_npc_profile_actions_are_filtered/Run()
	var/list/cleaned = agent_clean_profile_actions(list("say", "fly", "", "approach", 7, "say"))

	TEST_ASSERT(("say" in cleaned), "A real action must survive cleaning.")
	TEST_ASSERT(("approach" in cleaned), "A real action must survive cleaning.")
	TEST_ASSERT(!("fly" in cleaned), "An action outside the vocabulary must be dropped, or a profile permits something dispatch will reject.")
	TEST_ASSERT_EQUAL(length(cleaned), 3, "say, approach and wait, with the duplicate and the junk removed.")

/datum/unit_test/agent_npc_profile_always_permits_wait

/datum/unit_test/agent_npc_profile_always_permits_wait/Run()
	// Without wait an NPC cannot say it is finished: every reply produces a
	// result and the conversation never settles. That is a hang, not a choice.
	TEST_ASSERT(("wait" in agent_clean_profile_actions(list("say"))), "wait must be restored when it is left out.")
	TEST_ASSERT(("wait" in agent_clean_profile_actions(list())), "wait must be present even in an empty action list.")
	TEST_ASSERT(("wait" in agent_clean_profile_actions(null)), "wait must be present even when the list is missing entirely.")

/datum/unit_test/agent_npc_profile_text_is_capped

/datum/unit_test/agent_npc_profile_text_is_capped/Run()
	var/long = ""
	for(var/i in 1 to 300)
		long += "some words here "

	var/capped = agent_clean_profile_text(long)
	TEST_ASSERT_NOTNULL(capped, "Cleaning must return text rather than null.")

	// Every character rides on every request, so an unbounded persona is a
	// permanent per-decision token cost, not a one-off mistake.
	TEST_ASSERT(length(capped) <= AGENT_PROFILE_TEXT_MAX, "Authored text must be capped at AGENT_PROFILE_TEXT_MAX.")
	TEST_ASSERT_EQUAL(agent_clean_profile_text(null), "", "A missing value must clean to empty text, not null.")
	TEST_ASSERT_EQUAL(agent_clean_profile_text(42), "", "A non-text value must clean to empty text.")

/datum/unit_test/agent_npc_profile_clone_is_independent

/datum/unit_test/agent_npc_profile_clone_is_independent/Run()
	var/datum/agent_profile/original = new /datum/agent_profile/villager()
	var/datum/agent_profile/copy = original.clone()

	TEST_ASSERT_NOTNULL(copy, "Cloning must produce a profile.")
	TEST_ASSERT_EQUAL(copy.persona, original.persona, "A clone must carry the same text.")
	TEST_ASSERT_EQUAL(length(copy.permitted_actions), length(original.permitted_actions), "A clone must carry the same actions.")

	copy.permitted_actions = list("say")
	copy.persona = "changed"

	// A live NPC holds a clone. Editing the library entry afterwards must not
	// reach into a character already walking around.
	TEST_ASSERT(("approach" in original.permitted_actions), "Editing a clone must not change the original's actions.")
	TEST_ASSERT(original.persona != "changed", "Editing a clone must not change the original's text.")

	qdel(copy)
	qdel(original)

/datum/unit_test/agent_npc_profile_survives_a_payload_round_trip

/datum/unit_test/agent_npc_profile_survives_a_payload_round_trip/Run()
	var/datum/agent_profile/original = new /datum/agent_profile/villager()
	var/list/payload = original.to_payload()
	TEST_ASSERT_NOTNULL(payload, "A profile must produce a payload.")

	var/datum/agent_profile/rebuilt = agent_profile_from_payload(payload)
	TEST_ASSERT_NOTNULL(rebuilt, "A valid payload must rebuild into a profile.")
	TEST_ASSERT_EQUAL(rebuilt.label, original.label, "The label must survive a save and load.")
	TEST_ASSERT_EQUAL(rebuilt.persona, original.persona, "The persona must survive a save and load.")
	TEST_ASSERT_EQUAL(length(rebuilt.permitted_actions), length(original.permitted_actions), "The actions must survive a save and load.")

	// A hand-edited file can hold anything at all.
	TEST_ASSERT_NULL(agent_profile_from_payload(null), "A missing payload must not produce a profile.")
	TEST_ASSERT_NULL(agent_profile_from_payload("not a list"), "A payload that is not a list must not produce a profile.")

	qdel(rebuilt)
	qdel(original)

/datum/unit_test/agent_npc_builtin_profiles_carry_their_actions

/datum/unit_test/agent_npc_builtin_profiles_carry_their_actions/Run()
	var/list/builtins = agent_builtin_profiles()
	TEST_ASSERT_NOTNULL(builtins, "The built-in list must be built.")
	TEST_ASSERT(length(builtins) >= 2, "Setup failed: there should be at least the villager and the sedentary villager.")

	for(var/list/payload as anything in builtins)
		TEST_ASSERT_NOTNULL(payload["type"], "Each built-in must carry its typepath so the menu can copy it.")
		// initial() returns null for list vars, so reading permitted_actions off
		// the typepath instead of an instance would silently empty every profile.
		TEST_ASSERT(length(payload["permitted_actions"]) > 0, "Built-in [payload["type"]] has no permitted actions. Built-ins must be read from an instance, never via initial().")

/datum/unit_test/agent_npc_profile_names_do_not_collide

/datum/unit_test/agent_npc_profile_names_do_not_collide/Run()
	var/list/saved = GLOB.agent_custom_profiles.Copy()
	GLOB.agent_custom_profiles = list()

	var/first = agent_unique_profile_name("tavern keeper")
	TEST_ASSERT_EQUAL(first, "tavern keeper", "An unused name must be taken as written.")

	GLOB.agent_custom_profiles[first] = new /datum/agent_profile()
	var/second = agent_unique_profile_name("tavern keeper")

	// Silently overwriting someone's authored character would be the worst
	// possible outcome of pressing New twice.
	TEST_ASSERT(second != first, "A taken name must be made unique rather than reused.")
	TEST_ASSERT(length(second) > 0, "A unique name must not be empty.")
	TEST_ASSERT_EQUAL(agent_unique_profile_name(""), "new profile", "An empty name must fall back to a usable default.")

	for(var/name in GLOB.agent_custom_profiles)
		qdel(GLOB.agent_custom_profiles[name])
	GLOB.agent_custom_profiles = saved

// ------------------------------------------------------------- attaching

/datum/unit_test/agent_npc_attach_puts_a_controller_on_a_mob

/datum/unit_test/agent_npc_attach_puts_a_controller_on_a_mob/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)

	TEST_ASSERT(!istype(target.ai_controller, /datum/ai_controller/agent_social), "Setup failed: the mob must not start agent controlled.")

	var/datum/agent_profile/profile = new /datum/agent_profile/villager()
	var/refusal = agent_attach_controller(target, profile)

	TEST_ASSERT_NULL(refusal, "Attaching to a plain clientless mob must succeed. Refusal was: [refusal]")
	TEST_ASSERT(istype(target.ai_controller, /datum/ai_controller/agent_social), "The mob must end up with an agent controller.")

	var/datum/ai_controller/agent_social/attached = target.ai_controller
	TEST_ASSERT_NOTNULL(attached.profile, "The attached controller must carry a profile.")
	// A clone, so editing the library entry later cannot reach this pawn.
	TEST_ASSERT(attached.profile != profile, "The controller must hold its own copy of the profile, not the library's instance.")
	TEST_ASSERT_EQUAL(attached.profile.label, profile.label, "The copy must be of the profile that was chosen.")

	agent_test_restore_subsystem(saved, attached.binding)
	qdel(profile)

/datum/unit_test/agent_npc_attach_refuses_a_second_time

/datum/unit_test/agent_npc_attach_refuses_a_second_time/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)

	TEST_ASSERT_NULL(agent_attach_controller(target, null), "Setup failed: the first attach should succeed.")
	var/datum/ai_controller/agent_social/attached = target.ai_controller
	TEST_ASSERT_NOTNULL(attached, "Setup failed: the mob should be agent controlled now.")

	// Attaching again would destroy the live controller and its binding, which
	// is a silent way to lose a conversation mid-sentence.
	TEST_ASSERT_NOTNULL(agent_attach_controller(target, null), "Attaching to an already agent-controlled mob must be refused.")
	TEST_ASSERT(target.ai_controller == attached, "A refused attach must leave the existing controller alone.")

	agent_test_restore_subsystem(saved, attached.binding)

/datum/unit_test/agent_npc_swapping_a_profile_keeps_the_binding

/datum/unit_test/agent_npc_swapping_a_profile_keeps_the_binding/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)

	var/datum/agent_profile/first = new /datum/agent_profile/villager/sedentary()
	TEST_ASSERT_NULL(agent_attach_controller(target, first), "Setup failed: the first attach should succeed.")

	var/datum/ai_controller/agent_social/attached = target.ai_controller
	TEST_ASSERT_NOTNULL(attached, "Setup failed: the mob should be agent controlled.")
	var/datum/agent_binding/binding = attached.binding
	TEST_ASSERT_NOTNULL(binding, "Setup failed: the controller should hold a binding.")

	var/datum/agent_profile/second = new /datum/agent_profile/villager()
	second.label = "tavern keeper"
	TEST_ASSERT_NULL(agent_swap_profile(target, second), "Swapping the profile of an agent controlled mob must succeed.")

	// The point of swapping rather than reattaching: the controller and its
	// binding survive, so a conversation in progress is not thrown away.
	TEST_ASSERT(target.ai_controller == attached, "Swapping must keep the same controller.")
	TEST_ASSERT(attached.binding == binding, "Swapping must keep the same binding, or the conversation so far is lost.")
	TEST_ASSERT_EQUAL(attached.profile.label, "tavern keeper", "The controller must be playing the new character.")
	TEST_ASSERT(attached.profile != second, "The controller must hold its own copy, not the library's instance.")

	// This guard is only reachable on a mob that IS agent controlled. Checking it
	// on a mob without an agent proves nothing: the istype check refuses first,
	// so the test passes whether or not this guard exists at all.
	TEST_ASSERT_NOTNULL(agent_swap_profile(target, null), "Swapping to a profile that no longer exists must be refused.")
	TEST_ASSERT_EQUAL(attached.profile.label, "tavern keeper", "A refused swap must leave the character it was playing alone.")

	agent_test_restore_subsystem(saved, attached.binding)
	qdel(second)
	qdel(first)

/datum/unit_test/agent_npc_swapping_refuses_a_mob_without_an_agent

/datum/unit_test/agent_npc_swapping_refuses_a_mob_without_an_agent/Run()
	var/mob/living/carbon/human/species/human/northern/bum/target = allocate(/mob/living/carbon/human/species/human/northern/bum)
	var/datum/ai_controller/existing = target.ai_controller
	var/datum/agent_profile/profile = new /datum/agent_profile/villager()

	// Wrapped, because dropping the istype guard does not produce a wrong answer
	// here: it reaches for .profile on a controller that has no such var, which
	// runtimes, aborts Run(), and records a pass. try/catch is what sees that.
	var/caught = FALSE
	var/refusal
	try
		refusal = agent_swap_profile(target, profile)
	catch
		caught = TRUE

	TEST_ASSERT(!caught, "Swapping on a mob that is not agent controlled must be refused cleanly, not runtime.")
	TEST_ASSERT_NOTNULL(refusal, "Swapping on a mob that is not agent controlled must be refused.")
	TEST_ASSERT(target.ai_controller == existing, "A refused swap must leave the mob's controller untouched.")

	qdel(profile)

/datum/unit_test/agent_npc_detach_restores_the_original_controller

/datum/unit_test/agent_npc_detach_restores_the_original_controller/Run()
	var/list/saved = agent_test_arm_subsystem()
	// A bum declares its own controller, so this is where restoring can be seen.
	var/mob/living/carbon/human/species/human/northern/bum/target = allocate(/mob/living/carbon/human/species/human/northern/bum)

	TEST_ASSERT(istype(target.ai_controller, /datum/ai_controller/human_bum), "Setup failed: a bum should start with its own controller.")

	TEST_ASSERT_NULL(agent_attach_controller(target, null), "Setup failed: attaching to the bum should succeed.")
	var/datum/ai_controller/agent_social/attached = target.ai_controller
	TEST_ASSERT_NOTNULL(attached, "Setup failed: the bum should be agent controlled now.")
	agent_test_restore_subsystem(saved, attached.binding)

	TEST_ASSERT_NULL(agent_detach_controller(target), "Detaching an agent controlled mob must succeed.")

	// Leaving the mob with no controller would permanently break an NPC that
	// an admin only meant to borrow.
	TEST_ASSERT(istype(target.ai_controller, /datum/ai_controller/human_bum), "Detaching must put the mob's own controller back.")

/datum/unit_test/agent_npc_detach_refuses_a_mob_it_does_not_own

/datum/unit_test/agent_npc_detach_refuses_a_mob_it_does_not_own/Run()
	var/mob/living/carbon/human/species/human/northern/bum/target = allocate(/mob/living/carbon/human/species/human/northern/bum)
	var/datum/ai_controller/existing = target.ai_controller

	TEST_ASSERT_NOTNULL(agent_detach_controller(target), "Detaching a mob that was never agent controlled must be refused.")
	TEST_ASSERT(target.ai_controller == existing, "A refused detach must leave the mob's controller untouched.")

/datum/unit_test/agent_npc_detach_leaves_a_purpose_built_pawn_alone

/datum/unit_test/agent_npc_detach_leaves_a_purpose_built_pawn_alone/Run()
	var/list/saved = agent_test_arm_subsystem()
	var/mob/living/carbon/human/species/human/northern/agent_social/pawn = agent_test_bound_pawn()
	var/datum/ai_controller/agent_social/controller = pawn.ai_controller
	TEST_ASSERT_NOTNULL(controller, "Setup failed: the pilot pawn must carry an agent controller.")
	agent_test_restore_subsystem(saved, controller.binding)

	TEST_ASSERT_NULL(agent_detach_controller(pawn), "Detaching the pilot pawn must succeed.")

	// This mob type declares the agent controller as its own, so a naive restore
	// would immediately re-attach the thing it was just asked to remove.
	TEST_ASSERT(!istype(pawn.ai_controller, /datum/ai_controller/agent_social), "Detaching must not restore the agent controller it just removed.")

/datum/unit_test/agent_npc_memory_turns_are_cleaned

/datum/unit_test/agent_npc_memory_turns_are_cleaned/Run()
	TEST_ASSERT_NULL(agent_clean_memory_turns(null), "No value must stay no value: the sidecar default applies.")
	TEST_ASSERT_NULL(agent_clean_memory_turns("lots"), "A non-number must fall back to the sidecar default.")
	TEST_ASSERT_EQUAL(agent_clean_memory_turns(8), 8, "A sane number must survive.")
	TEST_ASSERT_EQUAL(agent_clean_memory_turns("8"), 8, "The window may send text; it must still read as a number.")
	TEST_ASSERT_EQUAL(agent_clean_memory_turns(7.6), 8, "Exchanges are whole.")
	// Every remembered exchange is resent on every request, so the ceiling is a cost bound.
	TEST_ASSERT_EQUAL(agent_clean_memory_turns(500), AGENT_MAX_MEMORY_TURNS, "Memory must stop at the ceiling.")
	TEST_ASSERT_EQUAL(agent_clean_memory_turns(-3), 0, "Memory cannot be negative.")

/datum/unit_test/agent_npc_memory_turns_reach_the_wire

/datum/unit_test/agent_npc_memory_turns_reach_the_wire/Run()
	var/datum/agent_profile/original = new /datum/agent_profile/villager()
	var/list/default_payload = original.to_payload()
	original.memory_turns = 12
	var/list/payload = original.to_payload()
	var/datum/agent_profile/copy = original.clone()
	var/datum/agent_profile/rebuilt = agent_profile_from_payload(payload)
	var/copied = copy.memory_turns
	var/reloaded = rebuilt.memory_turns
	qdel(original)
	qdel(copy)
	qdel(rebuilt)

	TEST_ASSERT_NULL(default_payload["memory_turns"], "A profile that sets nothing must leave the sidecar default in charge.")
	TEST_ASSERT_EQUAL(payload["memory_turns"], 12, "The sidecar can only honour a length it is sent.")
	TEST_ASSERT_EQUAL(copied, 12, "A clone must carry the memory length.")
	TEST_ASSERT_EQUAL(reloaded, 12, "The memory length must survive a save and load.")
