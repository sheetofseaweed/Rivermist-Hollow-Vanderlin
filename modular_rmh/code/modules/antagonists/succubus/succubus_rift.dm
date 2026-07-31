// Rift of Lust: the Tier 4 campaign objective and staged ritual foundation.

GLOBAL_LIST_EMPTY(active_succubus_rifts)

/obj/effect/temp_visual/small_smoke/succubus_rift
	color = "#D34CBB"
	alpha = 180

/datum/antagonist/succubus
	/// The current ritual structure. The global registry owns the strong reference.
	var/tmp/datum/weakref/active_rift_ref
	/// A destroyed attempt cannot immediately be reseeded.
	var/tmp/rift_retry_at = 0
	/// The final Rift verdict persists for objective and round-end reporting.
	var/tmp/rift_ascended = FALSE
	var/tmp/rift_banished = FALSE
	/// The last Open Rift was sealed, but its mistress chose to remain and rebuild.
	var/tmp/rift_repelled = FALSE

/datum/objective/succubus/rift
	name = "rift of lust"
	flavor = "Pact"
	triumph_count = 5

/datum/objective/succubus/rift/on_creation()
	update_explanation_text()

/datum/objective/succubus/rift/check_completion()
	var/datum/antagonist/succubus/succubus_antag = owner?.has_antag_datum(/datum/antagonist/succubus)
	return succubus_antag?.rift_ascended || FALSE

/datum/objective/succubus/rift/update_explanation_text()
	var/progress = "No Rift has been seeded."
	var/datum/antagonist/succubus/succubus_antag = owner?.has_antag_datum(/datum/antagonist/succubus)
	var/obj/structure/succubus_rift/rift = succubus_antag?.get_active_rift()
	if(succubus_antag?.rift_ascended)
		progress = "I held the breach and ascended beyond my mortal shell."
	else if(succubus_antag?.rift_banished)
		progress = "The breach was sealed, and I was dragged back through it."
	else if(rift)
		switch(rift.current_stage)
			if(SUCCUBUS_RIFT_STAGE_SEED)
				progress = "The Rift is seeded."
			if(SUCCUBUS_RIFT_STAGE_WIDENED)
				progress = "The Rift is widened."
			if(SUCCUBUS_RIFT_STAGE_OPEN)
				progress = "The Rift stands open."
	else if(succubus_antag?.rift_repelled)
		if(succubus_antag.get_succubus_contract_tier() < SUCCUBUS_RIFT_UNLOCK_TIER)
			progress = "The last breach was sealed. Asmodeus stripped my favor; I must rebuild from Tier 1."
		else
			progress = "The last breach was sealed, but my favor has recovered. I may try again."
	else if(succubus_antag?.rift_retry_at > world.time)
		var/minutes_left = max(1, CEILING((succubus_antag.rift_retry_at - world.time) / (1 MINUTES), 1))
		progress = "The last breach collapsed. I may try again in [minutes_left] minute[minutes_left == 1 ? "" : "s"]."
	explanation_text = "Earn Tier [SUCCUBUS_RIFT_UNLOCK_TIER] favor, reveal my True Form, and open the Rift of Lust within the town. [progress]"

/datum/antagonist/succubus/proc/forge_succubus_objectives()
	for(var/datum/objective/succubus/rift/rift_objective in objectives)
		return rift_objective
	var/datum/objective/succubus/rift/rift_objective = new(null, owner)
	objectives += rift_objective
	return rift_objective

/datum/antagonist/succubus/proc/get_active_rift()
	var/obj/structure/succubus_rift/rift = active_rift_ref?.resolve()
	if(QDELETED(rift))
		active_rift_ref = null
		return null
	return rift

/datum/antagonist/succubus/proc/refresh_rift_objective()
	for(var/datum/objective/succubus/rift/rift_objective in objectives)
		rift_objective.update_explanation_text()

/datum/antagonist/succubus/proc/discard_active_rift(refresh_objective = TRUE)
	var/obj/structure/succubus_rift/rift = get_active_rift()
	if(rift)
		qdel(rift)
	active_rift_ref = null
	if(refresh_objective)
		refresh_rift_objective()

/datum/antagonist/succubus/proc/cleanup_rift_retinue()
	for(var/datum/mind/member as anything in harem?.members)
		if(member != owner)
			unenthrall(member, keep_memories = TRUE)

	if(summoned_imp_minds)
		for(var/datum/mind/imp_mind as anything in summoned_imp_minds.Copy())
			var/datum/antagonist/succubus_imp/imp_datum = imp_mind?.has_antag_datum(/datum/antagonist/succubus_imp)
			if(imp_datum?.mistress_mind != owner)
				continue
			imp_datum.mistress_mind = null
			if(imp_mind.current)
				to_chat(imp_mind.current, span_boldnotice("The Rift's verdict severs my bond to the succubus. My borrowed form remains my own until its time expires."))
		summoned_imp_minds.Cut()

	QDEL_LIST(summoned_lusthounds)
	QDEL_LIST(infernal_snares)

/datum/antagonist/succubus/proc/prepare_for_rift_retry()
	if(true_form_active)
		leave_true_form(force = TRUE)

	contracts_completed_full = 0
	essence = 0
	refresh_succubus_contract_progression()

	if(current_contract)
		current_contract.grade = CONTRACT_GRADE_EXCUSED
		current_contract.completed_early = FALSE
		contract_history += current_contract
		current_contract = null
	if(contract_pool)
		contract_created_at = world.time - length(contract_history) * contract_pool.cycle_length
	else
		contract_created_at = world.time
	rift_retry_at = 0

/datum/antagonist/succubus/proc/prompt_rift_defeat_choice()
	var/mob/living/restored_body = owner?.current
	var/choice
	if(!QDELETED(restored_body) && restored_body.client)
		choice = tgui_alert(
			restored_body,
			"The sealed Rift has cast me back into my mortal shell and stripped away Asmodeus's favor. I can cling to this world and rebuild from Tier 1, or stop resisting and let the last infernal tether drag me away from active play.",
			"The Rift's Verdict",
			list("Cling to This World", "Surrender to the Rift"),
			SUCCUBUS_RIFT_DEFEAT_PROMPT_TIMEOUT,
		)

	if(QDELETED(src) || !owner || owner.has_antag_datum(/datum/antagonist/succubus) != src)
		return FALSE
	if(choice == "Surrender to the Rift" && retire_through_rift(ascended = FALSE))
		rift_banished = TRUE
		rift_repelled = FALSE
		refresh_rift_objective()
		return TRUE

	if(contract_pool && !current_contract)
		issue_next_contract()
	restored_body = owner.current
	if(!QDELETED(restored_body))
		to_chat(restored_body, span_boldnotice("I cling to the mortal world. If I want the Rift again, I must earn every measure of Asmodeus's favor anew."))
	refresh_rift_objective()
	return TRUE

/datum/antagonist/succubus/proc/retire_through_rift(ascended)
	if(true_form_active)
		leave_true_form(force = TRUE)

	var/mob/living/restored_body = owner?.current
	if(QDELETED(restored_body))
		return FALSE
	if(ascended)
		to_chat(restored_body, span_boldnotice("The Rift accepts me. My mortal shell falls away as I ascend beyond this world."))
	else
		restored_body.visible_message(
			span_boldwarning("A last rose-colored tether coils around [restored_body] and tears them from the mortal world!"),
			span_userdanger("I stop resisting. The last infernal tether hooks into my soul and drags me screaming into the lower planes!"),
		)
	restored_body.ghostize(can_reenter_corpse = FALSE)
	restored_body.moveToNullspace()
	return TRUE

/datum/antagonist/succubus/proc/can_invoke_rift(mob/living/form_body, silent = FALSE)
	if(!istype(form_body) || owner?.current != form_body)
		return FALSE
	if(get_succubus_contract_tier() < SUCCUBUS_RIFT_UNLOCK_TIER)
		if(!silent)
			to_chat(form_body, span_warning("Asmodeus has not yet entrusted me with the final breach."))
		return FALSE
	if(!true_form_active)
		if(!silent)
			to_chat(form_body, span_warning("Only my unveiled form can tear at the boundary."))
		return FALSE
	if(!isturf(form_body.loc))
		if(!silent)
			to_chat(form_body, span_warning("I must stand within the waking world to begin the ritual."))
		return FALSE
	if(essence < SUCCUBUS_RIFT_STAGE_COST)
		if(!silent)
			to_chat(form_body, span_warning("I need [SUCCUBUS_RIFT_STAGE_COST] essence for the next ritual stage."))
		return FALSE

	var/obj/structure/succubus_rift/rift = get_active_rift()
	if(rift)
		if(rift.current_stage >= SUCCUBUS_RIFT_STAGE_OPEN)
			if(!silent)
				to_chat(form_body, span_warning("The Rift already stands open."))
			return FALSE
		if(form_body.z != rift.z || get_dist(form_body, rift) > 1)
			if(!silent)
				to_chat(form_body, span_warning("I must stand beside my Rift to widen it."))
			return FALSE
		if(!rift.is_ready_for_next_stage())
			if(!silent)
				var/seconds_left = max(1, round((rift.next_stage_at - world.time) / (1 SECONDS)))
				to_chat(form_body, span_warning("The breach must mature for another [seconds_left] second[seconds_left == 1 ? "" : "s"]."))
			return FALSE
		return TRUE

	if(rift_retry_at > world.time)
		if(!silent)
			var/seconds_left = max(1, round((rift_retry_at - world.time) / (1 SECONDS)))
			to_chat(form_body, span_warning("The boundary resists me for another [seconds_left] second[seconds_left == 1 ? "" : "s"]."))
		return FALSE
	if(length(GLOB.active_succubus_rifts))
		if(!silent)
			to_chat(form_body, span_warning("Another Rift already strains the world's boundary."))
		return FALSE
	var/turf/ritual_turf = get_turf(form_body)
	if(!isopenturf(ritual_turf) || !istype(get_area(ritual_turf), /area/outdoors/town))
		if(!silent)
			to_chat(form_body, span_warning("The first tear must be seeded beneath the open sky within the town."))
		return FALSE
	return TRUE

/datum/antagonist/succubus/proc/refresh_succubus_rift_action(mob/living/form_body)
	if(!istype(form_body))
		return
	if(true_form_active && owner?.current == form_body && get_succubus_contract_tier() >= SUCCUBUS_RIFT_UNLOCK_TIER)
		form_body.add_spell(/datum/action/cooldown/spell/undirected/succubus_rift, source = form_body)
		return
	form_body.remove_spell(/datum/action/cooldown/spell/undirected/succubus_rift)

/obj/structure/succubus_rift
	name = "nascent rift"
	desc = "A trembling obelisk of rose-purple light, only beginning to split the air around it."
	// Temporary shared portal art until the Rift receives its own sprite.
	icon = 'icons/roguetown/topadd/death/vamp-lord.dmi'
	icon_state = "obelisk"
	color = "#A64AA8"
	alpha = 160
	density = FALSE
	anchored = TRUE
	max_integrity = SUCCUBUS_RIFT_SEED_INTEGRITY
	light_system = MOVABLE_LIGHT
	light_outer_range = 2
	light_color = "#C14CB7"
	/// The mind whose Succubus datum owns this ritual.
	var/tmp/datum/weakref/owner_mind_ref
	var/tmp/current_stage = 0
	var/tmp/next_stage_at = 0
	/// Prevents two destruction paths from applying collapse consequences twice.
	var/tmp/collapsing = FALSE
	/// Rift-B's bounded incursion state. Natural expiry feeds Rift-C's verdict.
	var/tmp/incursion_active = FALSE
	var/tmp/incursion_ends_at = 0
	var/tmp/incursion_wave_timer = TIMER_ID_NULL
	var/tmp/incursion_end_timer = TIMER_ID_NULL
	var/tmp/active_demon_cap = 0
	var/tmp/total_demon_cap = 0
	var/tmp/total_demons_spawned = 0
	/// Universal closure progress. Future holy tools contribute through add_seal_progress().
	var/tmp/seal_progress = 0
	/// Strong ownership is intentional: the Rift deletes every surviving NPC during cleanup.
	var/tmp/list/mob/living/incursion_demons = list()

/obj/structure/succubus_rift/proc/bind_to(datum/antagonist/succubus/owner_datum)
	if(QDELETED(src) || QDELETED(owner_datum) || !owner_datum.owner || owner_mind_ref)
		return FALSE
	if(owner_datum.get_active_rift() || length(GLOB.active_succubus_rifts))
		return FALSE
	owner_mind_ref = WEAKREF(owner_datum.owner)
	owner_datum.active_rift_ref = WEAKREF(src)
	owner_datum.rift_repelled = FALSE
	GLOB.active_succubus_rifts += src
	return TRUE

/obj/structure/succubus_rift/proc/is_ready_for_next_stage()
	if(current_stage >= SUCCUBUS_RIFT_STAGE_OPEN)
		return FALSE
	return current_stage == 0 || world.time >= next_stage_at

/obj/structure/succubus_rift/proc/get_next_channel_time()
	switch(current_stage)
		if(0)
			return SUCCUBUS_RIFT_SEED_CHANNEL
		if(SUCCUBUS_RIFT_STAGE_SEED)
			return SUCCUBUS_RIFT_WIDEN_CHANNEL
		if(SUCCUBUS_RIFT_STAGE_WIDENED)
			return SUCCUBUS_RIFT_OPEN_CHANNEL
	return 0

/obj/structure/succubus_rift/proc/advance_stage(ignore_maturation = FALSE, trigger_stage_effects = TRUE)
	if(collapsing || current_stage >= SUCCUBUS_RIFT_STAGE_OPEN)
		return FALSE
	if(!ignore_maturation && !is_ready_for_next_stage())
		return FALSE

	current_stage++
	switch(current_stage)
		if(SUCCUBUS_RIFT_STAGE_SEED)
			name = "nascent rift"
			desc = "A trembling obelisk of rose-purple light, only beginning to split the air around it."
			icon_state = "obelisk"
			color = "#A64AA8"
			alpha = 160
			max_integrity = SUCCUBUS_RIFT_SEED_INTEGRITY
			next_stage_at = world.time + SUCCUBUS_RIFT_MATURATION
		if(SUCCUBUS_RIFT_STAGE_WIDENED)
			name = "widening rift"
			desc = "The obelisk has cracked into a hungry wound, pulsing as the boundary thins."
			icon_state = "obelisk"
			color = "#D34CBB"
			alpha = 220
			max_integrity = SUCCUBUS_RIFT_WIDENED_INTEGRITY
			next_stage_at = world.time + SUCCUBUS_RIFT_MATURATION
		if(SUCCUBUS_RIFT_STAGE_OPEN)
			name = "Rift of Lust"
			desc = "A fully opened infernal wound hangs in the world. Something beyond it is waiting."
			icon_state = "portal"
			color = null
			alpha = 255
			max_integrity = SUCCUBUS_RIFT_OPEN_INTEGRITY
			next_stage_at = 0
	atom_integrity = max_integrity

	var/datum/mind/owner_mind = owner_mind_ref?.resolve()
	var/datum/antagonist/succubus/owner_datum = owner_mind?.has_antag_datum(/datum/antagonist/succubus)
	owner_datum?.refresh_rift_objective()

	if(!trigger_stage_effects)
		return TRUE

	switch(current_stage)
		if(SUCCUBUS_RIFT_STAGE_SEED)
			emit_rose_mist(1)
			for(var/mob/living/carbon/human/dreamer as anything in GLOB.player_list)
				if(dreamer.stat < UNCONSCIOUS || dreamer.stat >= DEAD)
					continue
				to_chat(dreamer, span_notice("A rose-colored crack opens behind my eyelids. Something on the far side learns the shape of my name."))
		if(SUCCUBUS_RIFT_STAGE_WIDENED)
			emit_rose_mist(2)
			for(var/mob/living/carbon/human/witness as anything in GLOB.player_list)
				if(witness.stat >= DEAD || !isturf(witness.loc))
					continue
				to_chat(witness, span_warning("For one breath, a warm whisper curls behind my thoughts: the boundary is thinning."))
		if(SUCCUBUS_RIFT_STAGE_OPEN)
			emit_rose_mist(2)
			var/area_name = get_area_name(src)
			priority_announce(
				"An infernal breach has torn fully open in [area_name]. Creatures are crossing through it now.",
				"Infernal Incursion",
				'sound/misc/alert.ogg',
			)
			start_incursion()
	return TRUE

/obj/structure/succubus_rift/proc/emit_rose_mist(radius)
	var/turf/center = get_turf(src)
	if(!isturf(center))
		return
	for(var/turf/affected_turf as anything in RANGE_TURFS(radius, center))
		new /obj/effect/temp_visual/small_smoke/succubus_rift(affected_turf)

/obj/structure/succubus_rift/proc/configure_incursion_limits(player_count)
	active_demon_cap = clamp(
		CEILING(max(player_count, 1) / SUCCUBUS_RIFT_PLAYERS_PER_DEMON, 1),
		SUCCUBUS_RIFT_MIN_ACTIVE_DEMONS,
		SUCCUBUS_RIFT_MAX_ACTIVE_DEMONS,
	)
	total_demon_cap = clamp(
		8 + active_demon_cap,
		SUCCUBUS_RIFT_MIN_TOTAL_DEMONS,
		SUCCUBUS_RIFT_MAX_TOTAL_DEMONS,
	)
	total_demons_spawned = 0

/obj/structure/succubus_rift/proc/start_incursion()
	if(collapsing || current_stage != SUCCUBUS_RIFT_STAGE_OPEN || incursion_active)
		return FALSE

	var/player_count = 0
	for(var/mob/living/player as anything in GLOB.player_list)
		if(player.stat >= DEAD || !isturf(player.loc))
			continue
		player_count++
	configure_incursion_limits(player_count)

	incursion_active = TRUE
	incursion_ends_at = world.time + SUCCUBUS_RIFT_TRIAL_DURATION
	incursion_wave_timer = addtimer(CALLBACK(src, PROC_REF(spawn_incursion_wave)), SUCCUBUS_RIFT_WAVE_INTERVAL, TIMER_LOOP | TIMER_STOPPABLE | TIMER_DELETE_ME)
	incursion_end_timer = addtimer(CALLBACK(src, PROC_REF(on_incursion_expired)), SUCCUBUS_RIFT_TRIAL_DURATION, TIMER_STOPPABLE | TIMER_DELETE_ME)
	spawn_incursion_wave()
	return TRUE

/obj/structure/succubus_rift/proc/spawn_incursion_wave()
	if(!incursion_active || collapsing || current_stage != SUCCUBUS_RIFT_STAGE_OPEN)
		return 0

	for(var/mob/living/demon as anything in incursion_demons.Copy())
		if(QDELETED(demon))
			incursion_demons -= demon
			continue
		refresh_incursion_friends(demon)

	var/spawn_count = min(
		SUCCUBUS_RIFT_WAVE_SIZE,
		active_demon_cap - length(incursion_demons),
		total_demon_cap - total_demons_spawned,
	)
	if(spawn_count <= 0)
		return 0

	var/list/spawn_turfs = list()
	for(var/turf/candidate as anything in RANGE_TURFS(SUCCUBUS_RIFT_SPAWN_RADIUS, src))
		if(!isopenturf(candidate) || candidate.is_blocked_turf())
			continue
		spawn_turfs += candidate
	if(!length(spawn_turfs))
		return 0

	var/spawned = 0
	for(var/i in 1 to min(spawn_count, length(spawn_turfs)))
		var/turf/spawn_turf = pick_n_take(spawn_turfs)
		new /obj/effect/temp_visual/small_smoke/succubus_rift(spawn_turf)
		var/mob/living/new_demon
		if(prob(SUCCUBUS_RIFT_HELLHOUND_CHANCE))
			new_demon = new /mob/living/simple_animal/hostile/retaliate/infernal/hellhound(spawn_turf)
		else
			new_demon = new /mob/living/simple_animal/hostile/retaliate/infernal/imp(spawn_turf)
		if(track_incursion_demon(new_demon))
			spawned++

	if(spawned)
		visible_message(span_boldwarning("[src] convulses as [spawned == 1 ? "an infernal creature claws" : "infernal creatures claw"] through!"))
	return spawned

/obj/structure/succubus_rift/proc/track_incursion_demon(mob/living/demon)
	if(QDELETED(demon) || (demon in incursion_demons))
		return FALSE
	incursion_demons += demon
	total_demons_spawned++
	RegisterSignal(demon, COMSIG_PARENT_QDELETING, PROC_REF(on_incursion_demon_deleting))
	refresh_incursion_friends(demon)
	return TRUE

/obj/structure/succubus_rift/proc/refresh_incursion_friends(mob/living/demon)
	if(QDELETED(demon))
		return
	var/datum/mind/owner_mind = owner_mind_ref?.resolve()
	var/datum/antagonist/succubus/owner_datum = owner_mind?.has_antag_datum(/datum/antagonist/succubus)
	if(!owner_datum)
		return

	if(isliving(owner_mind.current))
		demon.befriend(owner_mind.current)
	for(var/datum/mind/member as anything in owner_datum.harem?.members)
		if(isliving(member.current))
			demon.befriend(member.current)
	for(var/datum/mind/imp_mind as anything in owner_datum.summoned_imp_minds)
		if(isliving(imp_mind.current))
			demon.befriend(imp_mind.current)
	for(var/mob/living/lusthound as anything in owner_datum.summoned_lusthounds)
		if(!QDELETED(lusthound))
			demon.befriend(lusthound)

/obj/structure/succubus_rift/proc/on_incursion_demon_deleting(datum/source)
	SIGNAL_HANDLER
	incursion_demons -= source

/obj/structure/succubus_rift/proc/on_incursion_expired()
	incursion_end_timer = TIMER_ID_NULL
	resolve_verdict(ascended = TRUE)

/obj/structure/succubus_rift/proc/end_incursion(show_message = TRUE)
	if(!incursion_active)
		return FALSE
	cleanup_incursion()
	if(show_message && !QDELETED(src))
		visible_message(span_boldwarning("[src]'s pulse falls still. The last infernal shapes are dragged back beyond the breach."))
	return TRUE

/obj/structure/succubus_rift/proc/cleanup_incursion()
	incursion_active = FALSE
	incursion_ends_at = 0
	if(incursion_wave_timer != TIMER_ID_NULL)
		deltimer(incursion_wave_timer)
		incursion_wave_timer = TIMER_ID_NULL
	if(incursion_end_timer != TIMER_ID_NULL)
		deltimer(incursion_end_timer)
		incursion_end_timer = TIMER_ID_NULL
	for(var/mob/living/demon as anything in incursion_demons.Copy())
		if(!QDELETED(demon))
			UnregisterSignal(demon, COMSIG_PARENT_QDELETING)
			qdel(demon)
	incursion_demons.Cut()

/obj/structure/succubus_rift/proc/can_seal_rift(mob/living/user, silent = FALSE)
	if(QDELETED(src) || collapsing || current_stage != SUCCUBUS_RIFT_STAGE_OPEN)
		if(!silent && user)
			to_chat(user, span_warning("The breach is not open to a sealing rite."))
		return FALSE
	if(!istype(user) || QDELETED(user) || user.stat != CONSCIOUS || !isturf(user.loc) || !Adjacent(user))
		if(!silent && user)
			to_chat(user, span_warning("I must stand beside the Rift, conscious and steady, to seal it."))
		return FALSE

	var/datum/mind/owner_mind = owner_mind_ref?.resolve()
	var/datum/antagonist/succubus/owner_datum = owner_mind?.has_antag_datum(/datum/antagonist/succubus)
	if(!owner_datum)
		return FALSE
	if(owner_datum.is_linked_retinue(user))
		if(!silent)
			to_chat(user, span_warning("My infernal bond recoils from any attempt to seal its mistress's Rift."))
		return FALSE
	return TRUE

/obj/structure/succubus_rift/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return
	if(current_stage != SUCCUBUS_RIFT_STAGE_OPEN || collapsing)
		return
	if(!can_seal_rift(user))
		return TRUE

	user.visible_message(
		span_notice("[user] braces against [src] and begins forcing its edges together!"),
		span_boldnotice("I begin sealing the Rift. I must hold steady."),
	)
	if(!do_after(user, SUCCUBUS_RIFT_SEAL_CHANNEL, src))
		return TRUE
	if(!can_seal_rift(user))
		return TRUE
	add_seal_progress(1, user)
	return TRUE

/// Universal closure seam. Future holy tools may pass a larger amount through this proc.
/obj/structure/succubus_rift/proc/add_seal_progress(amount = 1, mob/living/contributor)
	if(amount <= 0 || QDELETED(src) || collapsing || current_stage != SUCCUBUS_RIFT_STAGE_OPEN)
		return FALSE
	if(contributor && !can_seal_rift(contributor, silent = TRUE))
		return FALSE

	seal_progress = min(seal_progress + amount, SUCCUBUS_RIFT_SEAL_CONTRIBUTIONS)
	visible_message(span_boldnotice("[src]'s edges buckle inward! The sealing rite is [seal_progress]/[SUCCUBUS_RIFT_SEAL_CONTRIBUTIONS] complete."))
	if(contributor)
		to_chat(contributor, span_notice("My will catches in the breach and forces part of it closed."))
	if(seal_progress >= SUCCUBUS_RIFT_SEAL_CONTRIBUTIONS)
		resolve_verdict(ascended = FALSE)
	return TRUE

/obj/structure/succubus_rift/proc/resolve_verdict(ascended, delete_rift = TRUE)
	if(collapsing || QDELETED(src) || current_stage != SUCCUBUS_RIFT_STAGE_OPEN)
		return FALSE
	collapsing = TRUE
	cleanup_incursion()

	var/datum/mind/owner_mind = owner_mind_ref?.resolve()
	var/datum/antagonist/succubus/owner_datum = owner_mind?.has_antag_datum(/datum/antagonist/succubus)
	if(!owner_datum)
		if(delete_rift)
			qdel(src)
		return FALSE

	owner_datum.rift_ascended = ascended
	owner_datum.rift_banished = FALSE
	owner_datum.rift_repelled = !ascended
	owner_datum.rift_retry_at = 0
	owner_datum.cleanup_rift_retinue()
	if(!ascended)
		owner_datum.prepare_for_rift_retry()

	var/area_name = get_area_name(src)
	if(ascended)
		visible_message(span_boldnotice("[src] blooms into rose-gold light as its mistress passes beyond the mortal world!"))
		priority_announce(
			"The infernal breach in [area_name] has folded shut. Its mistress survived the trial and vanished beyond mortal reach.",
			"Infernal Incursion Resolved",
			'sound/misc/alert.ogg',
		)
	else
		visible_message(span_boldwarning("[src] collapses and wrenches its mistress back into her weakened mortal shell!"))
		priority_announce(
			"The infernal breach in [area_name] has been sealed. Its mistress was torn from her unveiled form, stripped of infernal favor, and left to mortal judgment.",
			"Infernal Incursion Repelled",
			'sound/misc/alert.ogg',
		)

	if(ascended)
		owner_datum.retire_through_rift(ascended = TRUE)
	if(owner_datum.get_active_rift() == src)
		owner_datum.active_rift_ref = null
	owner_datum.refresh_rift_objective()
	if(!ascended)
		INVOKE_ASYNC(owner_datum, TYPE_PROC_REF(/datum/antagonist/succubus, prompt_rift_defeat_choice))
	if(delete_rift)
		qdel(src)
	return TRUE

/obj/structure/succubus_rift/proc/collapse(delete_rift = TRUE, apply_retry = TRUE)
	if(collapsing || QDELETED(src))
		return FALSE
	collapsing = TRUE
	cleanup_incursion()

	var/datum/mind/owner_mind = owner_mind_ref?.resolve()
	var/datum/antagonist/succubus/owner_datum = owner_mind?.has_antag_datum(/datum/antagonist/succubus)
	if(apply_retry && owner_datum)
		owner_datum.rift_retry_at = max(owner_datum.rift_retry_at, world.time + SUCCUBUS_RIFT_RETRY_COOLDOWN)
		if(owner_datum.owner?.current)
			to_chat(owner_datum.owner.current, span_userdanger("The Rift collapses, and the recoiling boundary shuts me out for a time!"))
	visible_message(span_boldwarning("[src] folds inward with a shriek of tortured air!"))

	if(owner_datum?.get_active_rift() == src)
		owner_datum.active_rift_ref = null
	owner_datum?.refresh_rift_objective()
	if(delete_rift)
		qdel(src)
	return TRUE

/obj/structure/succubus_rift/atom_destruction(damage_flag)
	if(current_stage == SUCCUBUS_RIFT_STAGE_OPEN)
		resolve_verdict(ascended = FALSE, delete_rift = FALSE)
	else
		collapse(delete_rift = FALSE)
	return ..()

/obj/structure/succubus_rift/Destroy()
	cleanup_incursion()
	GLOB.active_succubus_rifts -= src
	var/datum/mind/owner_mind = owner_mind_ref?.resolve()
	var/datum/antagonist/succubus/owner_datum = owner_mind?.has_antag_datum(/datum/antagonist/succubus)
	if(owner_datum?.active_rift_ref?.resolve() == src)
		owner_datum.active_rift_ref = null
	owner_mind_ref = null
	return ..()

/datum/action/cooldown/spell/undirected/succubus_rift
	name = "Invoke the Rift of Lust"
	desc = "Seed or widen the final breach. Every stage demands 100 essence and an uninterrupted ritual in True Form."
	has_visual_effects = FALSE
	antimagic_flags = NONE
	spell_flags = SPELL_IGNORE_SPELLBLOCK
	spell_requirements = SPELL_REQUIRES_NO_MOVE
	associated_skill = null
	associated_stat = null
	invocation_type = INVOCATION_NONE
	charge_required = TRUE
	charge_time = SUCCUBUS_RIFT_SEED_CHANNEL
	charge_message = "I begin drawing an infernal wound into the world..."
	charge_sound = 'sound/misc/portalopen.ogg'
	cooldown_time = SUCCUBUS_RIFT_ACTION_COOLDOWN

/datum/action/cooldown/spell/undirected/succubus_rift/get_adjusted_charge_time()
	var/datum/antagonist/succubus/succubus_antag = IS_SUCCUBUS(owner)
	var/obj/structure/succubus_rift/rift = succubus_antag?.get_active_rift()
	return rift?.get_next_channel_time() || SUCCUBUS_RIFT_SEED_CHANNEL

/datum/action/cooldown/spell/undirected/succubus_rift/can_cast_spell(feedback = TRUE)
	. = ..()
	if(!.)
		return FALSE
	var/datum/antagonist/succubus/succubus_antag = IS_SUCCUBUS(owner)
	return succubus_antag?.can_invoke_rift(owner, silent = !feedback) || FALSE

/datum/action/cooldown/spell/undirected/succubus_rift/is_valid_target(atom/cast_on)
	. = ..()
	if(!.)
		return FALSE
	var/datum/antagonist/succubus/succubus_antag = IS_SUCCUBUS(owner)
	return succubus_antag?.can_invoke_rift(owner, silent = TRUE) || FALSE

/datum/action/cooldown/spell/undirected/succubus_rift/before_cast(atom/cast_on)
	var/datum/antagonist/succubus/succubus_antag = IS_SUCCUBUS(owner)
	if(!succubus_antag?.can_invoke_rift(owner))
		return SPELL_CANCEL_CAST
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	succubus_antag = IS_SUCCUBUS(owner)
	if(!succubus_antag?.can_invoke_rift(owner))
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/undirected/succubus_rift/cast(mob/living/cast_on)
	. = ..()
	var/datum/antagonist/succubus/succubus_antag = IS_SUCCUBUS(owner)
	if(!succubus_antag?.can_invoke_rift(owner))
		return

	var/obj/structure/succubus_rift/rift = succubus_antag.get_active_rift()
	if(!rift)
		rift = new(get_turf(owner))
		if(!rift.bind_to(succubus_antag) || !rift.advance_stage())
			qdel(rift)
			return
	else if(!rift.advance_stage())
		return

	succubus_antag.adjust_essence(-SUCCUBUS_RIFT_STAGE_COST)
	playsound(rift, 'sound/misc/portalactivate.ogg', 100, FALSE, pressure_affected = FALSE)
	switch(rift.current_stage)
		if(SUCCUBUS_RIFT_STAGE_SEED)
			rift.visible_message(span_boldwarning("Rose-purple light knots beneath [owner] and hardens into a trembling infernal obelisk!"))
			to_chat(owner, span_love("The first wound takes root. I must let it mature before widening it."))
		if(SUCCUBUS_RIFT_STAGE_WIDENED)
			rift.visible_message(span_boldwarning("[rift] cracks wider as the air around it begins to pulse!"))
			to_chat(owner, span_love("The boundary thins beneath my hands. One final ritual will tear it open."))
		if(SUCCUBUS_RIFT_STAGE_OPEN)
			rift.visible_message(span_boldwarning("[rift] tears fully open with a deep, hungry thrum!"))
			to_chat(owner, span_love("The Rift stands open. I must hold it while the lower planes answer my call."))

/datum/antagonist/succubus/proc/admin_debug_rift(mob/admin)
	var/static/list/debug_options = list(
		"Refill Essence",
		"Make Current Stage Ready",
		"Advance Rift Stage",
		"Spawn Incursion Wave",
		"End Incursion Now",
		"Force Rift Ascension",
		"Force Rift Closure",
		"Collapse Rift",
	)
	var/choice = input(admin, "Choose a Rift smoke-test action.", "Rift Debug Control") as null|anything in debug_options
	if(!choice)
		return
	if(QDELETED(src) || !owner || owner.has_antag_datum(/datum/antagonist/succubus) != src)
		return

	var/mob/living/current_body = owner.current
	var/obj/structure/succubus_rift/rift = get_active_rift()
	switch(choice)
		if("Refill Essence")
			essence = essence_cap
			to_chat(admin, span_notice("Refilled [key_name_admin(owner)] to [essence]/[essence_cap] essence."))
		if("Make Current Stage Ready")
			if(!rift || rift.current_stage >= SUCCUBUS_RIFT_STAGE_OPEN)
				to_chat(admin, span_warning("There is no maturing Rift stage to ready."))
				return
			rift.next_stage_at = world.time
			to_chat(admin, span_notice("The current Rift stage is now ready to advance."))
		if("Advance Rift Stage")
			if(!rift)
				var/turf/spawn_turf = get_turf(current_body)
				if(!isturf(spawn_turf))
					to_chat(admin, span_warning("The Succubus has no map-present body for a debug Rift."))
					return
				rift = new(spawn_turf)
				if(!rift.bind_to(src))
					qdel(rift)
					to_chat(admin, span_warning("Another active Rift prevents debug creation."))
					return
			if(!rift.advance_stage(ignore_maturation = TRUE))
				to_chat(admin, span_warning("The Rift is already fully open."))
				return
			to_chat(admin, span_notice("Advanced the Rift to stage [rift.current_stage] without charging essence."))
		if("Spawn Incursion Wave")
			if(!rift?.incursion_active)
				to_chat(admin, span_warning("There is no active Rift incursion to reinforce."))
				return
			var/spawned = rift.spawn_incursion_wave()
			to_chat(admin, span_notice("Spawned [spawned] Rift demon[spawned == 1 ? "" : "s"]. Active: [length(rift.incursion_demons)]/[rift.active_demon_cap]; total: [rift.total_demons_spawned]/[rift.total_demon_cap]."))
		if("End Incursion Now")
			if(!rift?.incursion_active)
				to_chat(admin, span_warning("There is no active Rift incursion to end."))
				return
			rift.end_incursion()
			to_chat(admin, span_notice("Ended the Rift incursion and cleaned its owned demons. The Rift remains open for verdict testing."))
		if("Force Rift Ascension")
			if(!rift?.resolve_verdict(ascended = TRUE))
				to_chat(admin, span_warning("There is no unresolved Open Rift to ascend through."))
				return
			to_chat(admin, span_notice("Forced the Rift's ascension verdict and retired its owner from active play."))
		if("Force Rift Closure")
			if(!rift?.resolve_verdict(ascended = FALSE))
				to_chat(admin, span_warning("There is no unresolved Open Rift to seal."))
				return
			to_chat(admin, span_notice("Forced the Rift's closure verdict and opened its owner's survival-or-banishment choice."))
		if("Collapse Rift")
			if(!rift)
				to_chat(admin, span_warning("There is no active Rift to collapse."))
				return
			rift.collapse(apply_retry = FALSE)
			to_chat(admin, span_notice("Collapsed the Rift without applying a retry lockout."))

	message_admins("[key_name_admin(admin)] used Rift debug control '[choice]' on [key_name_admin(owner)].")
