/// Cached appearances generated for human-looking simple mobs.
GLOBAL_LIST_EMPTY(dynamic_human_appearances)

/// Creates a human with the supplied equipment and species, then returns its appearance.
/proc/get_dynamic_human_appearance(outfit_path, species_path = /datum/species/human, mob_spawn_path, r_hand, l_hand, bloody_slots = NONE, animated = TRUE, combat_mode = TRUE)
	if(!species_path)
		return FALSE

	if(!ispath(species_path))
		stack_trace("Attempted to call get_dynamic_human_appearance() with an instantiated species_path. Pass the species datum typepath instead.")
		return FALSE

	var/appearance_key = "[outfit_path]_[species_path]_[mob_spawn_path]_[l_hand]_[r_hand]_[bloody_slots]_[animated]_[combat_mode]"
	if(GLOB.dynamic_human_appearances[appearance_key])
		return GLOB.dynamic_human_appearances[appearance_key]

	var/mob/living/carbon/human/dummy/dummy = new()
	dummy.set_species(species_path)
	dummy.stat = DEAD
	dummy.cmode = combat_mode

	if(outfit_path)
		var/datum/outfit/outfit = new outfit_path()
		if(r_hand != NO_REPLACE)
			outfit.r_hand = r_hand
		if(l_hand != NO_REPLACE)
			outfit.l_hand = l_hand
		dummy.equipOutfit(outfit, visuals_only = TRUE)
	else if(mob_spawn_path)
		var/obj/effect/mob_spawn/spawner = new mob_spawn_path(null, TRUE)
		spawner.outfit_override = list()
		if(r_hand != NO_REPLACE)
			spawner.outfit_override["r_hand"] = r_hand
		if(l_hand != NO_REPLACE)
			spawner.outfit_override["l_hand"] = l_hand
		spawner.special(dummy, dummy, preview_only = TRUE)
		spawner.equip(dummy)
		qdel(spawner)

	for(var/obj/item/carried_item in dummy)
		if(dummy.is_holding(carried_item))
			var/datum/component/two_handed/two_handed = carried_item.GetComponent(/datum/component/two_handed)
			if(two_handed)
				two_handed.wield(dummy)
		if(bloody_slots & carried_item.slot_flags)
			carried_item.add_mob_blood(dummy)

	dummy.update_inv_hands()

	var/mutable_appearance/output = dummy.appearance
	GLOB.dynamic_human_appearances[appearance_key] = output
	qdel(dummy)
	return output

/// Applies a generated human appearance asynchronously, since outfit setup may sleep.
/proc/apply_dynamic_human_appearance(atom/target, outfit_path, species_path = /datum/species/human, mob_spawn_path, r_hand, l_hand, bloody_slots = NONE)
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(set_dynamic_human_appearance), args)

/// Generates and copies a human appearance from the arguments captured by apply_dynamic_human_appearance().
/proc/set_dynamic_human_appearance(list/arguments)
	var/atom/target = arguments[1]
	if(QDELETED(target))
		return
	var/dynamic_appearance = get_dynamic_human_appearance(arglist(arguments.Copy(2)))
	if(QDELETED(target) || !dynamic_appearance)
		return
	target.icon_state = ""
	target.appearance_flags |= KEEP_TOGETHER
	target.copy_overlays(dynamic_appearance, cut_old = TRUE)
