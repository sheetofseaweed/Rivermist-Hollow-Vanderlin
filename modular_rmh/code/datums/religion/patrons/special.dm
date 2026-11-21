/// Maniac patron. Never pickable; its prayers are the maniac's own puzzle.
/datum/patron/faerun/evil_gods/shattered_idol
	name = "The Shattered Idol"
	display_name = "The Shattered Idol"
	domain = "Broken divinity of spider-schemes, blood-hunger, and forbidden revelation."
	desc = "A shattered thing formed from truths no mortal mind should hold. Lolth's webs and Gruumsh's hunger have tangled together into a god-shaped wound."
	flaws = "Nothing, Everything, Nothing"
	worshippers = "Broken Minds, Overshared Secrets, Space-Faring Species Like You, Misanthropes"
	sins = "The Unseen, Secrets, Worthless Pigs"
	boons = "You are drawn to the flavour of other followers of Lolth, and may see them when you consume without worry."
	added_traits = list(TRAIT_ORGAN_EATER, TRAIT_CABAL)
	preference_accessible = FALSE
	confess_lines = list(
		"WHERE AM I!",
		"NONE OF THIS IS REAL!",
		"WHAT AM I WORSHIPPING?!"
	)

/datum/patron/faerun/evil_gods/shattered_idol/can_pray(mob/living/follower)
	var/datum/antagonist/maniac/dreamer = follower.mind?.has_antag_datum(/datum/antagonist/maniac)
	if(dreamer)
		return TRUE
	// A non-maniac with this patron should not exist; the dream swallows them.
	INVOKE_ASYNC(follower, GLOBAL_PROC_REF(cant_wake_up), follower)
	message_admins("[ADMIN_LOOKUPFLW(follower)] has been gibbed due to praying as a non-maniac with their patron set to The Shattered Idol.")
	return FALSE

/datum/patron/faerun/evil_gods/shattered_idol/hear_prayer(mob/living/follower, message)
	var/datum/antagonist/maniac/dreamer = follower.mind?.has_antag_datum(/datum/antagonist/maniac)
	if(!dreamer)
		return FALSE
	if(text2num(message) == dreamer.sum_keys)
		INVOKE_ASYNC(dreamer, TYPE_PROC_REF(/datum/antagonist/maniac, wake_up))
		return TRUE
	. = ..()
