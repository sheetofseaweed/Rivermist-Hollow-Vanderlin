// Bard: Bardic Inspiration charges and Song of Rest.

// Bardic Inspiration

/datum/action/cooldown/spell/bardic_inspiration/bard
	name = "Bardic Inspiration"
	desc = "Inspire a target with stirring words. Each use spends an Inspiration charge that a long rest restores, as does a short rest from Journeyman arcane."
	cooldown_time = 10 SECONDS
	feature_id = FEATURE_BARDIC_INSPIRATION
	feature_rest = REST_LONG

// Song of Rest

/// TRUE while an instrument in the mob's hands or worn slots is playing.
/mob/living/proc/is_playing_instrument()
	for(var/obj/item/instrument/instrument in held_items)
		if(instrument.playing)
			return TRUE
	for(var/obj/item/instrument/instrument in get_equipped_items())
		if(instrument.playing)
			return TRUE
	return FALSE

/// First conscious bard playing within earshot; a performing bard counts for their own rest too.
/mob/living/proc/find_song_of_rest_bard()
	RETURN_TYPE(/mob/living)
	if(!can_hear())
		return null
	for(var/mob/living/bard in hearers(7, src))
		if(bard.stat == CONSCIOUS && bard.get_spell(/datum/action/cooldown/spell/bardic_inspiration/bard, TRUE) && bard.is_playing_instrument())
			return bard
	return null

/mob/living/get_rest_budget_bonus()
	. = ..()
	if(!find_song_of_rest_bard())
		UnregisterSignal(src, COMSIG_LIVING_SPELL_REST)
		return
	// The rest signal follows the final budget read, so the notice only marks rests the song improved.
	RegisterSignal(src, COMSIG_LIVING_SPELL_REST, PROC_REF(song_of_rest_notice), override = TRUE)
	return . + SONG_OF_REST_BONUS

/mob/living/proc/song_of_rest_notice(datum/source, rest_type)
	SIGNAL_HANDLER
	UnregisterSignal(src, COMSIG_LIVING_SPELL_REST)
	if(rest_type & REST_SHORT)
		to_chat(src, span_notice("A song of rest carries me deeper into recovery."))
