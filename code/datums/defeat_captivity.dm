/// Pocket template used by Defeat captivity profiles. The first implementation deliberately reuses
/// the existing intimate dungeon layout: profile ownership and lifecycle are independent from art,
/// so dedicated goblin, carrier, and dragon templates can replace it without rewriting captivity.
/datum/map_template/pocket/defeat_captivity
	name = "Defeat Captivity"
	id = "pocket_defeat_captivity"
	mappath = "_maps/templates/pockets/kidnap_lairs/wolf_lair.dmm"
	lifecycle_policy = POCKET_LIFECYCLE_KEEP_LOADED
	idle_timeout = 0
	persistence_mode = POCKET_PERSISTENCE_NONE
	instance_type = /datum/pocket_dimension/defeat_captivity
	exit_structure_type = /obj/structure/pocket_dimension_exit/hole

/datum/map_template/pocket/defeat_captivity/wolf
	name = "Wolf Defeat Captivity"
	id = "pocket_defeat_captivity_wolf"
	mappath = "_maps/templates/pockets/kidnap_lairs/wolf_lair.dmm"

/datum/map_template/pocket/defeat_captivity/bandit
	name = "Bandit Defeat Captivity"
	id = "pocket_defeat_captivity_bandit"
	mappath = "_maps/templates/pockets/kidnap_lairs/bandit_lair.dmm"

/datum/map_template/pocket/defeat_captivity/greenskin
	name = "Greenskin Defeat Captivity"
	id = "pocket_defeat_captivity_greenskin"
	mappath = "_maps/templates/pockets/kidnap_lairs/goblin_lair.dmm"

/// Declarative policy for one family of captivity pockets. Content chooses a subtype; the core owns
/// keying, admission, access, ejection, and lifecycle without trying to infer a fuzzy "encounter".
/datum/defeat_captivity_profile
	var/ownership_mode = DEFEAT_CAPTIVITY_SHARED
	var/stable_key = "default"
	var/template_type = /datum/map_template/pocket/defeat_captivity
	var/capacity = 8
	var/access_rule = DEFEAT_CAPTIVITY_ACCESS_RELEASED
	var/delete_when_empty = TRUE
	var/display_name = "captivity pocket"

/datum/defeat_captivity_profile/New(stable_key_override)
	if(stable_key_override)
		stable_key = "[stable_key_override]"
	return ..()

/datum/defeat_captivity_profile/proc/build_instance_key(mob/living/captor, mob/living/captive)
	switch(ownership_mode)
		if(DEFEAT_CAPTIVITY_CARRIER)
			if(!captor || QDELETED(captor))
				return null
			return "[DEFEAT_CAPTIVITY_INSTANCE_PREFIX]::[type]::carrier::[REF(captor)]"
		if(DEFEAT_CAPTIVITY_CAPTIVE)
			if(!captive || QDELETED(captive))
				return null
			return "[DEFEAT_CAPTIVITY_INSTANCE_PREFIX]::[type]::captive::[REF(captive)]"
	return "[DEFEAT_CAPTIVITY_INSTANCE_PREFIX]::[type]::shared::[stable_key]"

/datum/defeat_captivity_profile/proc/get_pocket_holder(mob/living/captor)
	if(ownership_mode == DEFEAT_CAPTIVITY_CARRIER)
		return captor
	return null

/datum/defeat_captivity_profile/proc/get_or_create_instance(mob/living/captor, mob/living/captive)
	var/instance_key = build_instance_key(captor, captive)
	if(!instance_key || !SSpocket_dimensions)
		return null
	var/atom/pocket_holder = get_pocket_holder(captor)
	var/datum/pocket_dimension/defeat_captivity/instance = SSpocket_dimensions.get_or_create_instance(
		instance_key,
		template_type,
		POCKET_LIFECYCLE_KEEP_LOADED,
		0,
		pocket_holder,
	)
	if(!istype(instance))
		return null
	instance.configure_profile(type, pocket_holder)
	return instance

/datum/defeat_captivity_profile/proc/can_admit(datum/pocket_dimension/defeat_captivity/instance)
	return instance && instance.captive_count() < capacity

/// Central access hook for future breachable entrances and carrier interactions.
/datum/defeat_captivity_profile/proc/can_access(mob/living/user, access_action, datum/component/kidnap_captivity/captivity, datum/pocket_dimension/defeat_captivity/instance)
	if(!user)
		return FALSE
	switch(access_rule)
		if(DEFEAT_CAPTIVITY_ACCESS_RELEASED)
			if(captivity)
				return user == captivity.parent && captivity.released
			// Uncaptured rescuers and native inhabitants may leave a shared lair normally.
			return TRUE
		if(DEFEAT_CAPTIVITY_ACCESS_CAPTOR)
			if(captivity)
				return user == captivity.resolve_captor()
			return user == instance?.carrier_ref?.resolve()
	return FALSE

/datum/defeat_captivity_profile/proc/get_access_denial_message(mob/living/user)
	if(access_rule == DEFEAT_CAPTIVITY_ACCESS_RELEASED)
		return "Defeat still holds you too tightly to cross the threshold."
	return "The folded boundary seals itself against you."

/// Shared profiles may override this with a real exterior anchor. The current legacy markers are
/// inside the old static lairs, so using them as an exterior would only recreate the persistence bug.
/datum/defeat_captivity_profile/proc/get_configured_exterior(datum/component/kidnap_captivity/captivity)
	return null

/datum/defeat_captivity_profile/proc/get_wilds_destination(datum/component/kidnap_captivity/captivity)
	return get_random_kidnap_wilds_turf()

/datum/defeat_captivity_profile/proc/get_ejection_destination(datum/component/kidnap_captivity/captivity, datum/pocket_dimension/defeat_captivity/instance)
	var/turf/destination
	switch(ownership_mode)
		if(DEFEAT_CAPTIVITY_CARRIER)
			destination = instance?.forced_teardown_destination
			if(!is_valid_ejection_turf(destination, instance))
				var/mob/living/captor = captivity.resolve_captor()
				destination = get_turf(captor)
			if(!is_valid_ejection_turf(destination, instance))
				destination = captivity.get_saved_origin()
			if(!is_valid_ejection_turf(destination, instance))
				destination = get_wilds_destination(captivity)
		if(DEFEAT_CAPTIVITY_CAPTIVE)
			destination = get_wilds_destination(captivity)
			if(!is_valid_ejection_turf(destination, instance))
				destination = captivity.get_saved_origin()
		else
			destination = get_configured_exterior(captivity)
			if(!is_valid_ejection_turf(destination, instance))
				destination = captivity.get_saved_origin()
			if(!is_valid_ejection_turf(destination, instance))
				destination = get_wilds_destination(captivity)

	if(!is_valid_ejection_turf(destination, instance))
		destination = find_safe_turf()
	if(!is_valid_ejection_turf(destination, instance))
		return null
	return destination

/datum/defeat_captivity_profile/proc/is_valid_ejection_turf(turf/destination, datum/pocket_dimension/defeat_captivity/instance)
	if(!isturf(destination) || QDELETED(destination))
		return FALSE
	return !instance?.contains_turf(destination)

/datum/defeat_captivity_profile/shared
	ownership_mode = DEFEAT_CAPTIVITY_SHARED
	access_rule = DEFEAT_CAPTIVITY_ACCESS_RELEASED
	capacity = 8
	delete_when_empty = TRUE

/datum/defeat_captivity_profile/shared/greenskin
	stable_key = "greenskin_lair"
	display_name = "greenskin lair"
	template_type = /datum/map_template/pocket/defeat_captivity/greenskin

/datum/defeat_captivity_profile/shared/wolfden
	stable_key = "wolfden_lair"
	display_name = "wolf den"
	template_type = /datum/map_template/pocket/defeat_captivity/wolf

/datum/defeat_captivity_profile/shared/bandit
	stable_key = "bandit_lair"
	display_name = "bandit lair"
	template_type = /datum/map_template/pocket/defeat_captivity/bandit

/// One carrier owns one active pocket for its entire lifetime. Empty carrier pockets remain ready for
/// another swallow; deletion of the carrier tears the pocket down at the carrier's last turf.
/datum/defeat_captivity_profile/carrier
	ownership_mode = DEFEAT_CAPTIVITY_CARRIER
	access_rule = DEFEAT_CAPTIVITY_ACCESS_CAPTOR
	capacity = 4
	delete_when_empty = FALSE
	display_name = "carrier pocket"

/// One isolated pocket per victim. Contextual release deliberately tries the wilds before the saved
/// capture turf so future dragons cannot eject prisoners into a still-hostile encounter by default.
/datum/defeat_captivity_profile/per_captive
	ownership_mode = DEFEAT_CAPTIVITY_CAPTIVE
	access_rule = DEFEAT_CAPTIVITY_ACCESS_SEALED
	capacity = 1
	delete_when_empty = TRUE
	display_name = "isolated captivity pocket"

/// Pocket-dimension specialization that tracks only captivity components, using weak references.
/// It does no polling: membership changes, movement, owner deletion, and subsystem teardown drive it.
/datum/pocket_dimension/defeat_captivity
	var/profile_type = /datum/defeat_captivity_profile
	var/list/captive_refs = list()
	var/datum/weakref/carrier_ref
	var/turf/forced_teardown_destination
	var/teardown_started = FALSE

/datum/pocket_dimension/defeat_captivity/Destroy(force)
	// Parent Destroy dispatches eject_teardown_contents() dynamically. Run our contextual pass while
	// membership and carrier context still exist; teardown_started makes the parent call a no-op.
	eject_teardown_contents()
	var/atom/carrier = carrier_ref?.resolve()
	if(carrier)
		UnregisterSignal(carrier, COMSIG_PARENT_QDELETING)
	carrier_ref = null
	captive_refs = null
	forced_teardown_destination = null
	return ..()

/datum/pocket_dimension/defeat_captivity/proc/configure_profile(new_profile_type, atom/pocket_holder)
	if(ispath(new_profile_type, /datum/defeat_captivity_profile))
		profile_type = new_profile_type
	if(!pocket_holder || QDELETED(pocket_holder) || carrier_ref)
		return
	carrier_ref = WEAKREF(pocket_holder)
	RegisterSignal(pocket_holder, COMSIG_PARENT_QDELETING, PROC_REF(on_carrier_qdeleting))

/datum/pocket_dimension/defeat_captivity/proc/on_carrier_qdeleting(datum/source)
	SIGNAL_HANDLER
	forced_teardown_destination = get_turf(source)
	if(SSpocket_dimensions)
		SSpocket_dimensions.delete_instance(src, "Your captor is destroyed, and the pocket convulses around you!", forced_teardown_destination)

/datum/pocket_dimension/defeat_captivity/proc/captive_count()
	prune_captives()
	return length(captive_refs)

/datum/pocket_dimension/defeat_captivity/proc/prune_captives()
	if(!captive_refs)
		return
	for(var/captive_key in captive_refs.Copy())
		var/datum/weakref/captive_ref = captive_refs[captive_key]
		var/datum/component/kidnap_captivity/captivity = captive_ref?.resolve()
		if(!istype(captivity) || QDELETED(captivity))
			captive_refs -= captive_key

/datum/pocket_dimension/defeat_captivity/proc/register_captive(datum/component/kidnap_captivity/captivity)
	if(!captivity || QDELETED(captivity))
		return FALSE
	captive_refs["[REF(captivity)]"] = WEAKREF(captivity)
	touch()
	return TRUE

/datum/pocket_dimension/defeat_captivity/proc/unregister_captive(datum/component/kidnap_captivity/captivity, delete_when_empty = TRUE)
	if(!captive_refs)
		return
	captive_refs -= "[REF(captivity)]"
	if(teardown_started || !delete_when_empty || captive_count())
		return
	if(SSpocket_dimensions && !QDELETED(src))
		SSpocket_dimensions.delete_instance(src)

/datum/pocket_dimension/defeat_captivity/proc/can_profile_access(mob/living/user, access_action, datum/component/kidnap_captivity/captivity)
	var/datum/defeat_captivity_profile/profile = captivity?.profile
	var/temporary_profile = FALSE
	if(!profile && ispath(profile_type, /datum/defeat_captivity_profile))
		profile = new profile_type
		temporary_profile = TRUE
	var/allowed = profile?.can_access(user, access_action, captivity, src)
	if(temporary_profile)
		qdel(profile)
	return allowed

/datum/pocket_dimension/defeat_captivity/proc/get_profile_access_denial_message(mob/living/user, datum/component/kidnap_captivity/captivity)
	var/datum/defeat_captivity_profile/profile = captivity?.profile
	var/temporary_profile = FALSE
	if(!profile && ispath(profile_type, /datum/defeat_captivity_profile))
		profile = new profile_type
		temporary_profile = TRUE
	var/message = profile?.get_access_denial_message(user) || "The folded boundary refuses you."
	if(temporary_profile)
		qdel(profile)
	return message

/datum/pocket_dimension/defeat_captivity/can_exit_mob(mob/user, obj/structure/pocket_dimension_exit/exit_object, show_feedback = TRUE)
	var/datum/component/kidnap_captivity/captivity = user?.GetComponent(/datum/component/kidnap_captivity)
	if(captivity && captivity.resolve_instance() != src)
		captivity = null
	if(can_profile_access(user, "exit", captivity))
		return TRUE
	if(show_feedback)
		to_chat(user, span_warning(get_profile_access_denial_message(user, captivity)))
	return FALSE

/datum/pocket_dimension/defeat_captivity/exit_mob(mob/user)
	var/datum/component/kidnap_captivity/captivity = user?.GetComponent(/datum/component/kidnap_captivity)
	if(captivity && captivity.resolve_instance() != src)
		captivity = null
	if(!can_profile_access(user, "exit", captivity))
		to_chat(user, span_warning(get_profile_access_denial_message(user, captivity)))
		return FALSE
	if(captivity)
		return captivity.release_to_context("You cross the folded threshold and escape captivity.")
	return ..()

/datum/pocket_dimension/defeat_captivity/eject_teardown_contents(message = null, atom/override_destination = null)
	if(teardown_started)
		return
	teardown_started = TRUE
	if(isturf(override_destination))
		forced_teardown_destination = override_destination
	prune_captives()
	for(var/captive_key in captive_refs?.Copy())
		var/datum/weakref/captive_ref = captive_refs[captive_key]
		var/datum/component/kidnap_captivity/captivity = captive_ref?.resolve()
		if(!istype(captivity) || QDELETED(captivity))
			continue
		captivity.eject_for_teardown(message)
	captive_refs?.Cut()
	return ..(message, override_destination || find_safe_turf())

/// Resolve old lair tags into explicit profile types. Static landmark locations remain valid map
/// content during migration, but no gameplay admission depends on them anymore.
/proc/get_defeat_captivity_profile_for_lair(lair_tag)
	switch(lair_tag)
		if("greenskin_lair")
			return /datum/defeat_captivity_profile/shared/greenskin
		if("wolfden_lair")
			return /datum/defeat_captivity_profile/shared/wolfden
		if("bandit_lair")
			return /datum/defeat_captivity_profile/shared/bandit
	return /datum/defeat_captivity_profile/shared

/// Compatibility wrapper for existing content and tests. New captors should call kidnap_to_pocket()
/// with their configured profile so carrier ownership can retain the actual captor reference.
/mob/living/proc/kidnap_to_lair(lair_tag, list/captor_faction = null)
	return kidnap_to_pocket(get_defeat_captivity_profile_for_lair(lair_tag), null, captor_faction, lair_tag)

/mob/living/proc/kidnap_to_pocket(profile_spec, mob/living/captor, list/captor_faction = null, stable_key = null)
	if(!has_status_effect(/datum/status_effect/defeat_knockout))
		return FALSE
	if(GetComponent(/datum/component/kidnap_captivity))
		return FALSE
	if(!ispath(profile_spec, /datum/defeat_captivity_profile))
		return FALSE

	var/datum/defeat_captivity_profile/profile = new profile_spec(stable_key)
	var/datum/pocket_dimension/defeat_captivity/instance = profile.get_or_create_instance(captor, src)
	if(!instance || !profile.can_admit(instance))
		qdel(profile)
		return FALSE
	var/datum/component/kidnap_captivity/captivity = AddComponent(/datum/component/kidnap_captivity, profile, instance, captor, captor_faction, stable_key)
	if(!istype(captivity) || !captivity.enter_pocket())
		if(captivity)
			qdel(captivity)
		return FALSE
	visible_message(
		span_userdanger("[src] is dragged in and dumped on the ground, freshly captured!"),
		span_userdanger("You are dragged into a lair, far from any help..."),
	)
	return TRUE

/// Compatibility name retained for callers and old escape landmarks; destination order now belongs
/// to the active profile, including the mandatory wilds-first per-captive policy.
/mob/living/proc/kidnap_escape_to_wilds(datum/component/kidnap_captivity/captivity)
	if(!captivity || captivity.parent != src)
		return FALSE
	return captivity.release_to_context("You force your way out - free, but far from safety.")

/// Captivity state and return context. The component owns its profile datum but only weakly refers to
/// the instance, captor, and origin; the pocket owns no captive strongly, avoiding component cycles.
/datum/component/kidnap_captivity
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/lair_tag
	var/datum/defeat_captivity_profile/profile
	var/datum/weakref/instance_ref
	var/datum/weakref/captor_ref
	var/turf/saved_origin
	var/list/captor_faction
	var/captive_since = 0
	var/released = FALSE
	var/admitted = FALSE
	var/ending = FALSE
	var/datum/action/innate/defeat_refuse_advances/refuse_action
	var/surrender_available = FALSE
	var/captivity_climaxes = 0
	var/ko_release_timer
	var/surrender_timer
	var/rune_fallback_timer

/datum/component/kidnap_captivity/Initialize(profile_spec, datum/pocket_dimension/defeat_captivity/instance, mob/living/captor, list/captor_faction = null, stable_key = null)
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	if(istype(profile_spec, /datum/defeat_captivity_profile))
		profile = profile_spec
	else
		// Compatibility for old direct AddComponent calls that supplied only a lair tag.
		if(istext(profile_spec))
			stable_key = "[profile_spec]"
			profile_spec = get_defeat_captivity_profile_for_lair(stable_key)
		if(!ispath(profile_spec, /datum/defeat_captivity_profile))
			return COMPONENT_INCOMPATIBLE
		profile = new profile_spec(stable_key)
	if(!instance)
		instance = profile.get_or_create_instance(captor, parent)
	lair_tag = stable_key || profile.stable_key
	src.captor_faction = captor_faction?.Copy()
	if(captor)
		captor_ref = WEAKREF(captor)
	saved_origin = get_turf(parent)
	captive_since = world.time

	if(!instance || !profile.can_admit(instance))
		QDEL_NULL(profile)
		return COMPONENT_INCOMPATIBLE
	instance_ref = WEAKREF(instance)
	if(!instance.register_captive(src))
		QDEL_NULL(profile)
		return COMPONENT_INCOMPATIBLE
	return ..()

/datum/component/kidnap_captivity/RegisterWithParent()
	. = ..()
	ko_release_timer = addtimer(CALLBACK(src, PROC_REF(release_from_knockout)), KIDNAP_KO_RELEASE, TIMER_STOPPABLE)
	surrender_timer = addtimer(CALLBACK(src, PROC_REF(offer_surrender)), KIDNAP_SURRENDER_WINDOW, TIMER_STOPPABLE)
	RegisterSignal(parent, COMSIG_SEX_CLIMAX, PROC_REF(on_captive_climax))
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_captive_moved))
	RegisterSignal(parent, COMSIG_PARENT_QDELETING, PROC_REF(on_captive_qdeleting))

/datum/component/kidnap_captivity/UnregisterFromParent()
	deltimer(ko_release_timer)
	deltimer(surrender_timer)
	deltimer(rune_fallback_timer)
	ko_release_timer = null
	surrender_timer = null
	rune_fallback_timer = null
	UnregisterSignal(parent, list(COMSIG_SEX_CLIMAX, COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING))
	var/mob/living/victim = parent
	if(victim)
		REMOVE_TRAIT(victim, TRAIT_DEFEAT_REFUSE_ADVANCES, KIDNAP_TRAIT)
	if(refuse_action)
		refuse_action.Remove(victim)
		QDEL_NULL(refuse_action)
	var/datum/pocket_dimension/defeat_captivity/instance = resolve_instance()
	instance?.unregister_captive(src, profile?.delete_when_empty)
	instance_ref = null
	return ..()

/datum/component/kidnap_captivity/Destroy(force)
	. = ..()
	QDEL_NULL(profile)
	captor_ref = null
	saved_origin = null
	captor_faction = null
	return .

/datum/component/kidnap_captivity/proc/resolve_instance()
	var/datum/pocket_dimension/defeat_captivity/instance = instance_ref?.resolve()
	if(istype(instance) && !QDELETED(instance))
		return instance
	instance_ref = null
	return null

/datum/component/kidnap_captivity/proc/resolve_captor()
	var/mob/living/captor = captor_ref?.resolve()
	if(istype(captor) && !QDELETED(captor))
		return captor
	captor_ref = null
	return null

/datum/component/kidnap_captivity/proc/get_saved_origin()
	if(isturf(saved_origin) && !QDELETED(saved_origin))
		return saved_origin
	return null

/datum/component/kidnap_captivity/proc/enter_pocket()
	var/mob/living/victim = parent
	var/datum/pocket_dimension/defeat_captivity/instance = resolve_instance()
	if(!victim || QDELETED(victim) || !instance)
		return FALSE
	if(!instance.send_movable_inside(victim, forced_drop_turf = null))
		return FALSE
	admitted = TRUE
	return TRUE

/datum/component/kidnap_captivity/proc/on_captive_moved(datum/source, atom/old_loc, direction, forced)
	SIGNAL_HANDLER
	if(ending || !admitted)
		return
	var/datum/pocket_dimension/defeat_captivity/instance = resolve_instance()
	if(instance?.contains_turf(get_turf(parent)))
		return
	ending = TRUE
	qdel(src)

/datum/component/kidnap_captivity/proc/on_captive_qdeleting(datum/source)
	SIGNAL_HANDLER
	ending = TRUE
	qdel(src)

/datum/component/kidnap_captivity/proc/get_contextual_destination()
	return profile?.get_ejection_destination(src, resolve_instance())

/datum/component/kidnap_captivity/proc/release_to_context(message = null)
	if(ending)
		return FALSE
	var/mob/living/victim = parent
	var/turf/destination = get_contextual_destination()
	if(!victim || QDELETED(victim) || !destination)
		return FALSE
	ending = TRUE
	victim.forceMove(destination)
	qdel(src)
	if(message)
		to_chat(victim, span_notice(message))
	return TRUE

/datum/component/kidnap_captivity/proc/eject_for_teardown(message = null)
	if(ending)
		return FALSE
	var/mob/living/victim = parent
	var/turf/destination = get_contextual_destination()
	if(!victim || QDELETED(victim) || !destination)
		return FALSE
	ending = TRUE
	victim.forceMove(destination)
	qdel(src)
	if(message)
		to_chat(victim, span_warning(message))
	return TRUE

/// Rune completion calls this before moving the body. Returning the saved origin lets the rune keep
/// a meaningful compass target rather than pointing back to a temporary pocket reservation.
/datum/component/kidnap_captivity/proc/prepare_rune_return()
	var/turf/origin = get_saved_origin()
	if(!ending)
		deltimer(rune_fallback_timer)
		rune_fallback_timer = null
		ending = TRUE
		qdel(src)
	return origin

/// A successfully queued rune return owns the captive now. Cancel the unattended-choice fallback
/// immediately so it cannot reject and wake them during the rune's delayed completion callback.
/datum/component/kidnap_captivity/proc/cancel_rune_choice_fallback()
	if(!rune_fallback_timer)
		return FALSE
	deltimer(rune_fallback_timer)
	rune_fallback_timer = null
	return TRUE

/// Explicitly refusing a surfaced rune ejects first, clears all captivity state, then uses the common
/// bounded environmental recovery profile. That profile applies ordinary Defeat trauma.
/datum/component/kidnap_captivity/proc/reject_rune_and_wake()
	if(ending || !released)
		return FALSE
	var/mob/living/victim = parent
	var/turf/destination = get_contextual_destination()
	if(!victim || QDELETED(victim) || !destination)
		return FALSE
	deltimer(rune_fallback_timer)
	rune_fallback_timer = null
	ending = TRUE
	victim.forceMove(destination)
	qdel(src)
	if(!victim.perform_defeat_rescue(null, "rune rejection", /datum/defeat_recovery_profile/environmental))
		return FALSE
	to_chat(victim, span_warning("You reject the rune and wrench yourself awake. Freedom comes with the full weight of your defeat."))
	return TRUE

/datum/component/kidnap_captivity/proc/release_from_knockout()
	var/mob/living/victim = parent
	if(!victim || QDELETED(victim) || released)
		return
	released = TRUE
	if(victim.defeat_mode == DEFEAT_MODE_KO_RUNE && victim.kidnap_surface_rune_return())
		rune_fallback_timer = addtimer(CALLBACK(src, PROC_REF(resolve_rune_choice_fallback)), KIDNAP_RUNE_DECISION_FALLBACK, TIMER_STOPPABLE)
		to_chat(victim, span_blue("Your captors' hold is all that keeps you. Call the rune, or reject it and wake with the consequences of defeat."))
		return
	if(!victim.perform_defeat_rescue(null, "captivity release", /datum/defeat_recovery_profile/environmental, src))
		released = FALSE
		return
	grant_refuse_advances(victim)
	to_chat(victim, span_warning("The grip of defeat loosens - you can move, fight, and seek the profile's way out."))

/// One-shot universal last resort for a vanished rune controller/action or an unattended choice.
/// It is component-owned and stoppable; every normal release path cancels it in teardown.
/datum/component/kidnap_captivity/proc/resolve_rune_choice_fallback()
	rune_fallback_timer = null
	if(ending || !released)
		return FALSE
	var/mob/living/victim = parent
	if(!victim || QDELETED(victim) || !victim.has_status_effect(/datum/status_effect/defeat_knockout))
		return FALSE
	to_chat(victim, span_warning("The rune's answer fades. Rather than remain trapped in defeat, you wrench yourself awake without it."))
	return reject_rune_and_wake()

/datum/component/kidnap_captivity/proc/grant_refuse_advances(mob/living/victim)
	if(refuse_action || !victim)
		return
	refuse_action = new(victim)
	refuse_action.Grant(victim)

/datum/component/kidnap_captivity/proc/offer_surrender()
	var/mob/living/victim = parent
	if(!victim || QDELETED(victim))
		return
	surrender_available = TRUE
	to_chat(victim, span_userdanger("Despair claws at you. You may use the Surrender to Captivity verb, but it cannot be undone."))

/datum/component/kidnap_captivity/proc/on_captive_climax(datum/source, datum/sex_action/action, mob/living/receiver, mob/living/partner, mob/living/performer)
	SIGNAL_HANDLER
	captivity_climaxes++
	if(captivity_climaxes >= KIDNAP_SURRENDER_CLIMAXES && !surrender_available)
		offer_surrender()

/datum/component/kidnap_captivity/proc/do_surrender()
	var/mob/living/carbon/human/victim = parent
	if(!ishuman(victim))
		return FALSE
	var/turf/destination = get_contextual_destination()
	if(!destination)
		return FALSE
	ending = TRUE
	victim.forceMove(destination)
	victim.become_npc_in_distress(decays = TRUE, captor_faction = captor_faction)
	qdel(src)
	return TRUE

/datum/component/kidnap_captivity/proc/end_captivity()
	if(ending)
		return
	ending = TRUE
	qdel(src)
