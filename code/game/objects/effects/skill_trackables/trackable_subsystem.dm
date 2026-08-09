SUBSYSTEM_DEF(trackables)
	name = "Trackable Effect Manager"
	flags = SS_NO_FIRE

	///Assoc list of always_revealed_trait to the list of trackers that trait reveals.
	var/list/trackables_to_trait = list()
	///Assoc list of always_revealed_trait to weakrefs of the mobs currently holding it.
	var/list/mobs_by_trait = list()
	///Mobs whose trait changes we are listening to. Only mobs a client has taken over end up here.
	var/list/watched_mobs = list()


///Starts listening to a mob's trait changes and syncs it up to the tracks it should already know.
/datum/controller/subsystem/trackables/proc/watch_mob(mob/living/target)
	if(!isliving(target) || QDELETED(target) || (target in watched_mobs))
		return

	watched_mobs += target
	RegisterSignal(target, COMSIG_PARENT_QDELETING, PROC_REF(on_watched_mob_deleted))
	for(var/trait in trackables_to_trait)
		register_trait_signals(target, trait)
	sync_mob(target)

///Stops listening to a mob and drops it out of every trait registry.
/datum/controller/subsystem/trackables/proc/unwatch_mob(mob/living/target)
	if(!(target in watched_mobs))
		return

	watched_mobs -= target
	UnregisterSignal(target, COMSIG_PARENT_QDELETING)
	for(var/trait in trackables_to_trait)
		UnregisterSignal(target, list(SIGNAL_ADDTRAIT(trait), SIGNAL_REMOVETRAIT(trait)))
		revoke_trait(target, trait)

/datum/controller/subsystem/trackables/proc/on_watched_mob_deleted(mob/living/source)
	SIGNAL_HANDLER
	unwatch_mob(source)

/datum/controller/subsystem/trackables/proc/register_trait_signals(mob/living/target, trait)
	RegisterSignals(target, list(SIGNAL_ADDTRAIT(trait), SIGNAL_REMOVETRAIT(trait)), PROC_REF(on_trait_changed), override = TRUE)

///Not every REMOVE_TRAIT variant passes the trait along with the signal, so resync the mob instead of trusting the argument.
/datum/controller/subsystem/trackables/proc/on_trait_changed(mob/living/source)
	SIGNAL_HANDLER
	sync_mob(source)

///Brings a mob's trait-revealed track knowledge in line with the traits it currently holds.
/datum/controller/subsystem/trackables/proc/sync_mob(mob/living/target)
	if(QDELETED(target))
		return

	for(var/trait in trackables_to_trait)
		if(HAS_TRAIT(target, trait))
			grant_trait(target, trait)
		else
			revoke_trait(target, trait)

///Records that a mob holds a tracked trait and reveals every track that trait covers.
/datum/controller/subsystem/trackables/proc/grant_trait(mob/living/target, trait)
	var/datum/weakref/mob_ref = WEAKREF(target)
	if(!mob_ref)
		return

	var/list/knowers = mobs_by_trait[trait]
	if(!knowers)
		knowers = list()
		mobs_by_trait[trait] = knowers
	if(mob_ref in knowers)
		return
	knowers += mob_ref

	for(var/obj/effect/skill_tracker/tracker as anything in trackables_to_trait[trait])
		tracker.reveal_to_trait_holder(target)

///Drops a mob out of a trait's registry and hides every track that trait was revealing.
/datum/controller/subsystem/trackables/proc/revoke_trait(mob/living/target, trait)
	var/list/knowers = mobs_by_trait[trait]
	var/datum/weakref/mob_ref = target.weak_reference
	if(!mob_ref || !(mob_ref in knowers))
		return
	knowers -= mob_ref

	for(var/obj/effect/skill_tracker/tracker as anything in trackables_to_trait[trait])
		tracker.remove_knower(target)

/datum/controller/subsystem/trackables/proc/add_new_trackable(obj/effect/skill_tracker/tracker)
	var/trait = tracker.always_revealed_trait
	if(!trait)
		return

	if(!trackables_to_trait[trait])
		//First track to care about this trait, so nothing was listening for it yet.
		trackables_to_trait[trait] = list()
		for(var/mob/living/watched as anything in watched_mobs)
			register_trait_signals(watched, trait)
			if(HAS_TRAIT(watched, trait))
				grant_trait(watched, trait)

	trackables_to_trait[trait] |= tracker

/datum/controller/subsystem/trackables/proc/remove_trackable(obj/effect/skill_tracker/tracker)
	var/trait = tracker.always_revealed_trait
	if(!trait || !trackables_to_trait[trait])
		return

	trackables_to_trait[trait] -= tracker
