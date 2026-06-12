// Moonkissed - the lesser werewolf. Carries a shallow strain of the mooncurse:
// no beast form, no lair, no contracts, no rage. Just the moon's kiss and the pack.

/datum/antagonist/werewolf/lesser
	/// How many times the moonkissed form has been embraced, for the pack objectives.
	var/times_shifted = 0

/datum/antagonist/werewolf/lesser/grant_werewolf_powers()
	owner.current.add_spell(/datum/action/cooldown/spell/undirected/partial_transformation/moonkissed, source = owner)
	RegisterSignal(owner.current, COMSIG_MOB_PARTIAL_SHIFTED, PROC_REF(on_moonkissed_shift))

/datum/antagonist/werewolf/lesser/remove_werewolf_powers()
	var/mob/living/current_mob = owner?.current
	if(!current_mob)
		return
	UnregisterSignal(current_mob, COMSIG_MOB_PARTIAL_SHIFTED)
	// Removing the status effect restores the original ears/tail/genitals.
	current_mob.remove_status_effect(/datum/status_effect/partial_transformation)
	current_mob.remove_spell(/datum/action/cooldown/spell/undirected/partial_transformation/moonkissed)

/datum/antagonist/werewolf/lesser/on_body_transfer(mob/living/old_body, mob/living/new_body)
	. = ..()
	if(old_body)
		UnregisterSignal(old_body, COMSIG_MOB_PARTIAL_SHIFTED)
	if(new_body)
		RegisterSignal(new_body, COMSIG_MOB_PARTIAL_SHIFTED, PROC_REF(on_moonkissed_shift), override = TRUE)

/datum/antagonist/werewolf/lesser/proc/on_moonkissed_shift(datum/source, datum/partial_transformation_kit/kit)
	SIGNAL_HANDLER

	times_shifted++
	refresh_werewolf_objectives()

/datum/antagonist/werewolf/lesser/forge_werewolf_objectives()
	var/list/new_objectives = list(
		new /datum/objective/werewolf/survive(),
		new /datum/objective/werewolf/pack_elder(),
		new /datum/objective/werewolf_counter/embrace_gift(),
	)
	for(var/datum/objective/objective as anything in new_objectives)
		objective.owner = owner
		objectives += objective

// Deliberately not chaining into the full werewolf greet - it announces the wrong curse.
/datum/antagonist/werewolf/lesser/greet()
	to_chat(owner.current, span_userdanger("The mooncurse runs shallow in my veins. I am moonkissed, not moonbound - I must follow the pack that made me."))
	owner.announce_objectives()
