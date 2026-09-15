/// A mob spawner which waits for a ghost to claim it.
/obj/effect/mob_spawn/ghost_role
	abstract_type = /obj/effect/mob_spawn/ghost_role
	/// Lowercase role name used in the possession prompt.
	var/prompt_name = ""
	var/prompt_ghost = TRUE
	var/uses = 1
	var/deletes_on_zero_uses_left = TRUE
	/// GHOSTROLE_TAKE_PREFS_* flags controlling customized-character support.
	var/allow_custom_character = NONE
	var/infinite_use = FALSE

	var/you_are_text = ""
	var/flavour_text = ""
	var/important_text = ""
	var/show_flavor = TRUE

	/// Whether the player may return to their former body after taking this role.
	var/temp_body = FALSE
	var/role_ban = ROLE_MANIAC
	var/spawner_job_path

/obj/effect/mob_spawn/ghost_role/Initialize(mapload, preview_only = FALSE)
	. = ..()
	if(preview_only)
		return
	GLOB.poi_list |= src
	LAZYADD(GLOB.mob_spawners[name], src)

/obj/effect/mob_spawn/ghost_role/Destroy()
	GLOB.poi_list -= src
	var/list/spawners = GLOB.mob_spawners[name]
	LAZYREMOVE(spawners, src)
	if(!LAZYLEN(spawners))
		GLOB.mob_spawners -= name
	return ..()

// ATTACK GHOST IGNORING PARENT RETURN VALUE
/obj/effect/mob_spawn/ghost_role/attack_ghost(mob/dead/observer/user)
	if(!SSticker.HasRoundStarted() || isnull(loc) || QDELETED(src))
		return FALSE

	var/static/list/ckeys_trying_to_spawn
	if(user.ckey in ckeys_trying_to_spawn)
		return FALSE
	if(uses <= 0 && !infinite_use)
		to_chat(user, span_warning("This spawner is out of charges!"))
		return FALSE
	if(!can_ghost_take(user))
		return FALSE

	uses -= 1
	var/user_ckey = user.ckey
	LAZYADD(ckeys_trying_to_spawn, user_ckey)

	var/spawn_succeeded = FALSE
	var/prompt_failed = FALSE
	var/apply_prefs = FALSE
	if(prompt_ghost)
		var/prompt = "Become [prompt_name]?"
		if(!temp_body && user.can_reenter_corpse && user.mind)
			prompt += " (Warning: you can no longer be revived!)"
		prompt_failed = browser_alert(user, prompt, buttons = list("Yes", "No"), timeout = 10 SECONDS) != "Yes"

	if(!prompt_failed && can_ghost_take(user) && user.started_as_observer && allow_custom_character)
		var/species_pref_type = user.client.prefs.pref_species?.type || /datum/species/human/northern
		var/custom_prompt = "Because you have not taken a role yet, you may spawn as [((allow_custom_character & GHOSTROLE_TAKE_PREFS_SPECIES) || species_pref_type == /datum/species/human/northern) ? "" : "a human version of "]your customized character with a random name. Would you like to?"
		apply_prefs = browser_alert(user, custom_prompt, "Custom Character", list("Yes", "No"), 10 SECONDS) == "Yes"

	if(!prompt_failed && can_ghost_take(user) && pre_ghost_take(user) && can_ghost_take(user))
		spawn_succeeded = ismob(create_from_ghost(user, apply_prefs, subtract_uses = FALSE))

	if(spawn_succeeded)
		check_uses()
	else
		uses += 1

	LAZYREMOVE(ckeys_trying_to_spawn, user_ckey)
	return spawn_succeeded

/// Runs before the ghost is transferred. This may prompt or sleep; the caller revalidates afterward.
/obj/effect/mob_spawn/ghost_role/proc/pre_ghost_take(mob/dead/observer/user)
	return TRUE

/// Returns whether a ghost can currently take this role.
/obj/effect/mob_spawn/ghost_role/proc/can_ghost_take(mob/dead/observer/user)
	if(QDELETED(src) || QDELETED(user) || !user.client || !user.ckey)
		return FALSE
	if(is_banned_from(user.ckey, role_ban))
		to_chat(user, span_warning("You are banned from this role!"))
		return FALSE
	if(!allow_spawn(user, silent = FALSE))
		return FALSE
	return TRUE

/// Creates a mob for a validated ghost and optionally consumes one use.
/obj/effect/mob_spawn/ghost_role/proc/create_from_ghost(mob/dead/observer/user, apply_prefs, subtract_uses = TRUE)
	SHOULD_NOT_OVERRIDE(TRUE)
	SHOULD_NOT_SLEEP(TRUE)
	ASSERT(istype(user))

	var/user_ckey = user.ckey
	if(!temp_body)
		user.mind = null

	var/mob/created = create(user, apply_prefs = apply_prefs)
	if(ismob(created))
		created.log_message("was created as [prompt_name] for [user_ckey].", LOG_GAME)
		SEND_SIGNAL(src, COMSIG_GHOSTROLE_SPAWNED, created)
		if(subtract_uses)
			uses -= 1
			check_uses()
	else if(isnull(created))
		CRASH("An instance of [type] did not return anything when creating a mob.")
	return created

/obj/effect/mob_spawn/ghost_role/create(mob/mob_possessor, newname, apply_prefs)
	if(!mob_possessor.key)
		CRASH("Attempted to create an instance of [type] with a mob that had no key attached.")
	return ..()

/obj/effect/mob_spawn/ghost_role/special(mob/living/spawned_mob, mob/mob_possessor, apply_prefs, preview_only = FALSE)
	. = ..()
	if(preview_only)
		return

	if(mob_possessor)
		if(mob_possessor.client && apply_prefs && allow_custom_character && ishuman(spawned_mob))
			var/mob/living/carbon/human/spawned_human = spawned_mob
			var/datum/preferences/player_prefs = mob_possessor.client.prefs
			var/spawner_species = mob_species || spawned_human.dna?.species?.type
			if(allow_custom_character & GHOSTROLE_TAKE_PREFS_APPEARANCE)
				player_prefs.apply_prefs_to(spawned_human, icon_updates = FALSE)
				if(spawner_species && !(allow_custom_character & GHOSTROLE_TAKE_PREFS_SPECIES))
					spawned_human.set_species(spawner_species, icon_update = FALSE)
			else if(allow_custom_character & GHOSTROLE_TAKE_PREFS_SPECIES)
				var/preferred_species = player_prefs.pref_species?.type
				if(preferred_species)
					spawned_human.set_species(preferred_species, icon_update = FALSE, pref_load = player_prefs)

			spawned_human.fully_replace_character_name(spawned_human.real_name, spawned_human.dna.species.random_name())
			spawned_human.update_body()
			spawned_human.update_body_parts(TRUE)

		if(mob_possessor.mind)
			mob_possessor.mind.transfer_to(spawned_mob, force_key_move = TRUE)
		else
			spawned_mob.PossessByPlayer(mob_possessor.key)

	var/datum/mind/spawned_mind = spawned_mob.mind
	if(spawned_mind)
		if(spawner_job_path)
			spawned_mind.set_assigned_role(SSjob.GetJobType(spawner_job_path))
		spawned_mind.name = spawned_mob.real_name

	if(show_flavor)
		var/output_message = "<span class='big bold'>[you_are_text]</span>"
		if(flavour_text != "")
			output_message += "\n<span class='info'><b>[flavour_text]</b></span>"
		if(important_text != "")
			output_message += "\n[span_userdanger(important_text)]"
		to_chat(spawned_mob, output_message)

/// Deletes a depleted finite-use spawner when configured to do so.
/obj/effect/mob_spawn/ghost_role/proc/check_uses()
	if(!uses && !infinite_use && deletes_on_zero_uses_left)
		qdel(src)

/// Override to add role-specific availability checks.
/obj/effect/mob_spawn/ghost_role/proc/allow_spawn(mob/user, silent = FALSE)
	return TRUE

/obj/effect/mob_spawn/ghost_role/human
	icon = 'icons/mob/mob.dmi'
	icon_state = "ghost_yellow"
	mob_type = /mob/living/carbon/human/species/human/northern
