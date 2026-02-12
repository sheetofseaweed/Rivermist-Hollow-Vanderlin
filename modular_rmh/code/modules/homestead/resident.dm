#define RESIDENT_BALANCE_MIN 50
#define RESIDENT_BALANCE_MAX 150
#define RESIDENT_COST 10

/*
#define RESIDENT_ALLOWED_JOB_TYPES list( \
	/datum/job/roguetown/adventurer, \
	/datum/job/roguetown/mercenary, \
	/datum/job/roguetown/court_agent \
)
*/
/datum/quirk/resident
	name = "Resident"
	desc = "I'm a resident of Rivermist Hollow. I have an account in the city's treasury and a home in the city."
	value = RESIDENT_COST
//	mob_trait = TRAIT_RESIDENT //If the quirk system is removed, replace it with traits.
	gain_text = span_notice("I feel at home in Rivermist Hollow.")
	lose_text = span_danger("I no longer feel like a local resident.")

/proc/apply_resident_starting_money(mob/living/carbon/human/H)
	if(!H || QDELETED(H))
		return

	if(!SStreasury)
		return

	var/starting_balance = rand(RESIDENT_BALANCE_MIN, RESIDENT_BALANCE_MAX)

	if(H in SStreasury.bank_accounts)
		SStreasury.generate_money_account(starting_balance, H)
	else
		SStreasury.create_bank_account(H, starting_balance)

	to_chat(H, span_notice("As a citizen of Rivermist Hollow, you receive [starting_balance] coins from the city treasury."))

/datum/job/towner/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()

	if(!spawned || QDELETED(spawned))
		return

	if(!spawned.has_quirk(/datum/quirk/resident))
		new /datum/quirk/resident(spawned, TRUE)

	apply_resident_starting_money(spawned)

/datum/quirk/resident/proc/should_attempt_spawn(mob/living/carbon/human/H)
	if(!H.mind || !H.job)
		return FALSE

	var/datum/job/J = SSjob.name_occupations[H.job]
	if(!J)
		return FALSE

#ifdef RESIDENT_ALLOWED_JOB_TYPES
	return J.type in RESIDENT_ALLOWED_JOB_TYPES
#else
	return TRUE
#endif

#undef RESIDENT_BALANCE_MIN
#undef RESIDENT_BALANCE_MAX
#undef RESIDENT_COST