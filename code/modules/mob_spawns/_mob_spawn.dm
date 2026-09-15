/obj/effect/mob_spawn
	abstract_type = /obj/effect/mob_spawn
	name = "mob spawner"
	density = TRUE
	anchored = TRUE

	/// A forced name for the spawned mob. A name passed to create() takes priority.
	var/mob_name
	/// The living mob type created by this spawner.
	var/mob_type = /mob/living/simple_animal/pet/cat/black

	/// Species applied to spawned humans.
	var/datum/species/mob_species
	/// Job used for attributes, traits, and its outfit. The explicit outfit takes priority.
	var/datum/job/equipment_job
	/// Outfit applied to spawned humans.
	var/datum/outfit/outfit
	/// Associative outfit var overrides intended primarily for mapped special cases.
	var/list/outfit_override
	/// Whether a spawned human receives a randomized DNA appearance.
	var/randomise_dna = FALSE
	var/hair_style
	var/facial_hair_style
	var/hair_color
	var/facial_hair_color
	var/skin_tone

/obj/effect/mob_spawn/Initialize(mapload, preview_only = FALSE)
	. = ..()
	var/list/spawner_factions = get_faction()
	if(spawner_factions)
		set_faction(islist(spawner_factions) ? spawner_factions : list(spawner_factions))
	if(!ispath(mob_type, /mob/living))
		stack_trace("[src] has a non-living mob_type: [mob_type]")

/**
 * Creates the configured mob.
 *
 * mob_possessor is the ghost or mob taking possession, when applicable.
 * newname overrides mob_name.
 * apply_prefs controls whether a ghost role applies its possessor's preferences.
 */
/obj/effect/mob_spawn/proc/create(mob/mob_possessor, newname, apply_prefs)
	SHOULD_NOT_SLEEP(TRUE)

	var/mob/living/spawned_mob = new mob_type(get_turf(src))
	special(spawned_mob, mob_possessor, apply_prefs)
	name_mob(spawned_mob, newname)
	equip(spawned_mob)
	return spawned_mob

/// Applies configuration after creation and before equipment is added.
/obj/effect/mob_spawn/proc/special(mob/living/spawned_mob, mob/mob_possessor, apply_prefs, preview_only = FALSE)
	SHOULD_CALL_PARENT(TRUE)

	var/list/spawner_factions = get_faction()
	if(spawner_factions)
		spawned_mob.set_faction(spawner_factions)

	if(!ishuman(spawned_mob))
		return

	var/mob/living/carbon/human/spawned_human = spawned_mob
	if(mob_species)
		spawned_human.set_species(mob_species)

	if(randomise_dna && spawned_human.dna?.species)
		spawned_human.dna.species.random_character(spawned_human)

	if(hair_style)
		spawned_human.set_hair_style(hair_style, FALSE)
	if(hair_color)
		spawned_human.set_hair_color(hair_color, FALSE)
	if(facial_hair_style)
		spawned_human.set_facial_hair_style(facial_hair_style, FALSE)
	if(facial_hair_color)
		spawned_human.set_facial_hair_color(facial_hair_color, FALSE)
	if(skin_tone)
		spawned_human.skin_tone = skin_tone

	spawned_human.update_body()

/// Applies the configured name to a spawned mob.
/obj/effect/mob_spawn/proc/name_mob(mob/living/spawned_mob, forced_name)
	var/chosen_name = forced_name || mob_name
	if(!chosen_name)
		return
	spawned_mob.fully_replace_character_name(null, chosen_name)

/// Applies job attributes and the configured outfit to a spawned human.
/obj/effect/mob_spawn/proc/equip(mob/living/spawned_mob)
	if(!ishuman(spawned_mob))
		return

	var/mob/living/carbon/human/spawned_human = spawned_mob
	var/datum/outfit/outfit_used

	if(equipment_job)
		var/datum/job/real_job = SSjob.GetJobType(equipment_job)
		if(real_job)
			if(spawned_human.gender == FEMALE && real_job.outfit_female)
				outfit_used = real_job.outfit_female
			else
				outfit_used = real_job.outfit

			for(var/trait in real_job.traits)
				ADD_TRAIT(spawned_human, trait, JOB_TRAIT)

			if(spawned_human.attributes)
				real_job.assign_attributes(spawned_human, null)

	if(outfit)
		outfit_used = outfit
	if(!outfit_used)
		return

	if(outfit_override)
		outfit_used = new outfit_used
		for(var/outfit_var in outfit_override)
			var/outfit_value = outfit_override[outfit_var]
			if(!ispath(outfit_value) && !isnull(outfit_value) && !islist(outfit_value))
				CRASH("outfit_override var on [mob_name || type] must be an associative list of outfit var names to paths, lists, or null")
			outfit_used.vars[outfit_var] = outfit_value

	spawned_human.equipOutfit(outfit_used)
