/**
 * Carries an active partial transformation. Holds the swapped-out original organs
 * and undoes everything (organs, stats, traits, spells) when removed.
 *
 * The static id means only one partial form can ride a body at a time, whichever kit it came from.
 */
/datum/status_effect/partial_transformation
	id = "partial_transformation"
	duration = -1
	tick_interval = -1
	alert_type = /atom/movable/screen/alert/status_effect/partial_transformation
	// Mob deletion (gibs etc.) must run on_remove so the parked original organs get cleaned up.
	on_remove_on_mob_delete = TRUE
	// Organ regeneration (admin heal, resurrection) rebuilds the body's default organs and would
	// desync the shift - drop the whole form whenever that happens.
	remove_on_fullheal = TRUE
	heal_flag_necessary = HEAL_ORGANS|HEAL_REFRESH_ORGANS
	/// Config datum. Owned by the toggle spell - never qdel it from here.
	var/datum/partial_transformation_kit/kit
	/// ORGAN_SLOT -> list of original organ instances, parked in nullspace while shifted.
	var/list/stored_originals = list()
	/// Organ instances we created and inserted.
	var/list/granted_organs = list()

/datum/status_effect/partial_transformation/on_creation(mob/living/new_owner, duration_override, datum/partial_transformation_kit/new_kit)
	if(!istype(new_kit) || !ishuman(new_owner))
		qdel(src)
		return
	kit = new_kit
	effectedstats = kit.shift_stats.Copy()
	examine_text = kit.examine_line
	return ..()

/datum/status_effect/partial_transformation/on_apply()
	apply_organ_swaps()
	for(var/trait in kit.shift_traits)
		ADD_TRAIT(owner, trait, kit.id)
	for(var/spell_path in kit.shift_spells)
		owner.add_spell(spell_path, source = src)
	return ..()

/datum/status_effect/partial_transformation/on_remove()
	for(var/trait in kit.shift_traits)
		REMOVE_TRAIT(owner, trait, kit.id)
	for(var/spell_path in kit.shift_spells)
		owner.remove_spell(spell_path)
	restore_organs()
	return ..()

/datum/status_effect/partial_transformation/proc/apply_organ_swaps()
	var/mob/living/carbon/human/human_owner = owner
	for(var/slot in kit.organ_swaps)
		// Paired slots (like ears) hold several organs - every one of them gets swapped.
		// getorganslotlist builds a fresh list, so removing organs below won't shift it under us.
		var/list/originals = human_owner.getorganslotlist(slot)
		if(!length(originals) && (slot in kit.swap_only_if_present))
			continue
		var/obj/item/organ/first_original = length(originals) ? originals[1] : null
		if(!kit.can_swap_slot(slot, first_original, human_owner))
			continue

		var/organ_path = kit.organ_swaps[slot]
		if(!length(originals))
			grant_replacement_organ(organ_path, null, human_owner)
			continue

		var/list/stored = list()
		for(var/obj/item/organ/original as anything in originals)
			original.Remove(human_owner, special = TRUE)
			original.moveToNullspace()
			// Remove() puts organs on the decay loop; the parked originals must keep fresh.
			STOP_PROCESSING(SSobj, original)
			stored += original
			grant_replacement_organ(organ_path, original, human_owner)
		stored_originals[slot] = stored
	human_owner.update_body_parts(TRUE)

/datum/status_effect/partial_transformation/proc/grant_replacement_organ(organ_path, obj/item/organ/original, mob/living/carbon/human/human_owner)
	var/obj/item/organ/replacement = new organ_path()
	if(original)
		// Paired organs render per side - the replacement takes the original's place.
		replacement.switch_side(original.side)
	kit.prepare_replacement(replacement, original, human_owner)
	replacement.Insert(human_owner, TRUE, FALSE)
	replacement.build_colors_for_accessory(null)
	granted_organs += replacement
	return replacement

/datum/status_effect/partial_transformation/proc/restore_organs()
	var/mob/living/carbon/human/human_owner = owner
	var/owner_gone = QDELETED(human_owner) || !ishuman(human_owner)
	for(var/obj/item/organ/granted as anything in granted_organs)
		if(QDELETED(granted))
			continue
		if(!owner_gone && granted.owner == human_owner)
			granted.Remove(human_owner, special = TRUE)
		// Conjured by the shift - never lootable.
		qdel(granted)
	granted_organs.Cut()
	for(var/slot in stored_originals)
		// If the owner is gone, or something (surgery, organ regeneration) refilled the slot
		// while shifted, the parked originals have nowhere to go.
		var/slot_blocked = owner_gone || length(human_owner.getorganslotlist(slot))
		for(var/obj/item/organ/original as anything in stored_originals[slot])
			if(QDELETED(original))
				continue
			if(slot_blocked)
				qdel(original)
			else
				original.Insert(human_owner, TRUE, FALSE)
	stored_originals.Cut()
	if(!owner_gone)
		human_owner.update_body_parts(TRUE)

/atom/movable/screen/alert/status_effect/partial_transformation
	name = "Partial Shift"
	desc = "Another shape rides my body."
