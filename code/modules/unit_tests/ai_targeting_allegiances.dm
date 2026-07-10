/datum/unit_test/ai_targeting_respects_job_group
	procs_tested = list(
		/datum/targetting_datum/proc/can_attack,
		/mob/living/proc/ai_targeting_ally_check,
		/mob/living/proc/get_ai_targeting_job_group,
		/mob/living/proc/ai_targeting_same_job_group,
	)

/datum/unit_test/ai_targeting_respects_job_group/Run()
	var/datum/targetting_datum/basic/targetting_datum = allocate(/datum/targetting_datum/basic)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	attacker.faction = list(FACTION_HOSTILE)
	target.faction = list(FACTION_TOWN)

	TEST_ASSERT(targetting_datum.can_attack(attacker, target), "Test setup should allow basic AI to attack before job group allegiance is applied.")

	attacker.mind_initialize()
	target.mind_initialize()
	var/datum/job/watch_captain/attacker_department_role = allocate(/datum/job/watch_captain)
	var/datum/job/watch_sergeant/target_department_role = allocate(/datum/job/watch_sergeant)
	attacker.mind.assigned_role = attacker_department_role
	target.mind.assigned_role = target_department_role

	TEST_ASSERT(!targetting_datum.can_attack(attacker, target), "Basic AI should not attack targets in the same job department.")

	var/datum/job/watch_guard/job_group = allocate(/datum/job/watch_guard)
	var/datum/job/advclass/watch_guard/bulwark/attacker_role = allocate(/datum/job/advclass/watch_guard/bulwark)
	var/datum/job/advclass/watch_guard/sentinel/target_role = allocate(/datum/job/advclass/watch_guard/sentinel)
	attacker_role.parent_job = job_group
	target_role.parent_job = job_group
	attacker.mind.assigned_role = attacker_role
	target.mind.assigned_role = target_role

	TEST_ASSERT(!targetting_datum.can_attack(attacker, target), "Basic AI should not attack targets in the same job group.")
	attacker.mind.assigned_role = null
	target.mind.assigned_role = null

/datum/unit_test/ai_targeting_respects_family
	procs_tested = list(
		/datum/targetting_datum/proc/can_attack,
		/mob/living/proc/ai_targeting_ally_check,
		/mob/living/proc/ai_targeting_same_family,
	)

/datum/unit_test/ai_targeting_respects_family/Run()
	var/datum/targetting_datum/basic/targetting_datum = allocate(/datum/targetting_datum/basic)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	attacker.faction = list(FACTION_HOSTILE)
	target.faction = list(FACTION_TOWN)

	TEST_ASSERT(targetting_datum.can_attack(attacker, target), "Test setup should allow basic AI to attack before family allegiance is applied.")

	var/datum/heritage/shared_family = allocate(/datum/heritage)
	attacker.family_datum = shared_family
	target.family_datum = shared_family

	TEST_ASSERT(!targetting_datum.can_attack(attacker, target), "Basic AI should not attack targets in the same family.")
	attacker.family_datum = null
	target.family_datum = null

/datum/unit_test/ai_targeting_respects_faction_relations
	procs_tested = list(
		/datum/targetting_datum/proc/can_attack,
		/mob/living/proc/ai_targeting_ally_check,
		/mob/living/proc/ai_targeting_related_faction_check,
		/proc/ai_faction_relation_check,
	)

/datum/unit_test/ai_targeting_respects_faction_relations/Run()
	var/datum/targetting_datum/basic/targetting_datum = allocate(/datum/targetting_datum/basic)
	var/mob/living/carbon/human/undead = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/minotaur = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/townie = allocate(/mob/living/carbon/human)
	undead.faction = list(FACTION_UNDEAD)
	minotaur.faction = list(FACTION_MINOTAURS)
	townie.faction = list(FACTION_TOWN)

	TEST_ASSERT(!targetting_datum.can_attack(undead, minotaur), "Basic AI should not attack factions linked by AI targeting relations.")
	TEST_ASSERT(!targetting_datum.can_attack(minotaur, undead), "AI targeting faction relations should be symmetric.")
	TEST_ASSERT(targetting_datum.can_attack(undead, townie), "Unrelated factions should remain valid basic AI targets.")
