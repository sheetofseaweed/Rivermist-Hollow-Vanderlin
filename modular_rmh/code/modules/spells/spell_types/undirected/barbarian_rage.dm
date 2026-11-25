// Barbarian Rage on the class feature pools.

/datum/action/cooldown/spell/undirected/barbrage/rage
	name = "Rage: Frenzy"
	desc = "Enter a state of martial fervor: strength, constitution and endurance surge for 45 seconds while your senses dull. Spends a Rage charge, which a long rest restores."
	slot_label = "Frenzy"
	rage_status = /datum/status_effect/buff/barbrage/charged
	feature_id = FEATURE_RAGE
	feature_rest = REST_LONG

/datum/action/cooldown/spell/undirected/wildrage/rage
	name = "Rage: Wild Surge"
	desc = "Enter a rage that releases the magic roiling inside you with a random magical effect; strength and endurance surge for 45 seconds. Spends a Rage charge, which a long rest restores."
	slot_label = "Wild Surge"
	rage_status = /datum/status_effect/buff/wildrage/charged
	feature_id = FEATURE_RAGE
	feature_rest = REST_LONG

/datum/action/cooldown/spell/undirected/giant_shape/rage
	name = "Rage: Giant Shape"
	desc = "Borrow power from the Giant. Spends a Rage charge, which a long rest restores."
	slot_label = "Giant Shape"
	feature_id = FEATURE_RAGE
	feature_rest = REST_LONG

// Charged rages hit harder than the old stamina rages, since each one is a limited resource now.
/datum/status_effect/buff/barbrage/charged
	effectedstats = list(STAT_STRENGTH = 3, STAT_CONSTITUTION = 2, STAT_ENDURANCE = 3, STAT_PERCEPTION = -2, STAT_INTELLIGENCE = -2)
	duration = 45 SECONDS

/datum/status_effect/buff/wildrage/charged
	effectedstats = list(STAT_STRENGTH = 3, STAT_CONSTITUTION = 1, STAT_ENDURANCE = 2, STAT_PERCEPTION = -1, STAT_INTELLIGENCE = -1)
	duration = 45 SECONDS
