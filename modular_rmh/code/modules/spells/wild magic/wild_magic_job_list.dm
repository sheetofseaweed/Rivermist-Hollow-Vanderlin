/// Jobs that should receive Wild Magic on spawn
var/static/list/WILD_MAGIC_JOB_TYPES = list(
	/datum/job/advclass/combat/adventurer_barbarian/wild_magic,
	/datum/job/advclass/swamp_witch/wild,
	/datum/job/advclass/combat/adventurer_sorcerer/wild_magic
)

/datum/job/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()
	if(spawned && ishuman(spawned))
		for(var/T in WILD_MAGIC_JOB_TYPES)
			if(ispath(T) && istype(src, T))
				spawned.AddElement(/datum/element/wild_magic)
				break
