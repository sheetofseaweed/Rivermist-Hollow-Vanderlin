/**
 * Stateless, data-driven config for a partial transformation: cosmetic organ swaps,
 * minor stat boosts, traits and spells applied while shifted.
 *
 * One instance is owned by each toggle spell ([/datum/action/cooldown/spell/undirected/partial_transformation])
 * and handed to the status effect that does the actual work. To add a new look (fox, cat, ...),
 * subtype this datum and a toggle spell - no other code needed.
 */
/datum/partial_transformation_kit
	/// Unique string used as the trait source key.
	var/id = "partial"
	/// Player-facing name of the form.
	var/form_name = "partial form"
	/// ORGAN_SLOT_* string -> organ typepath inserted while shifted. Originals are stored and restored on revert.
	var/list/organ_swaps = list()
	/// Slots from organ_swaps that are only swapped when the target already has an organ there.
	var/list/swap_only_if_present = list()
	/// STAT_* typepath -> amount applied while shifted.
	var/list/shift_stats = list()
	/// Traits held while shifted.
	var/list/shift_traits = list()
	/// Spell typepaths granted while shifted.
	var/list/shift_spells = list()
	/// Traits that block shifting, on top of TRAIT_NO_TRANSFORM.
	/// Assoc trait -> denial message; plain entries fall back to a generic message.
	var/list/blocking_traits = list()
	/// Cooldown applied to the toggle spell after a successful shift or revert.
	var/cooldown = PARTIAL_TRANSFORM_COOLDOWN
	var/shift_sound
	var/unshift_sound
	/// Message on shift; %FORM% is replaced with form_name.
	var/shift_message = "My body twists into its %FORM%!"
	/// Message on revert; %FORM% is replaced with form_name.
	var/unshift_message = "My body settles back into its mundane shape."
	/// Optional line added to examines while shifted. Supports SUBJECTPRONOUN.
	var/examine_line

/// Per-slot veto before a swap happens. original can be null for slots not in swap_only_if_present.
/datum/partial_transformation_kit/proc/can_swap_slot(slot, obj/item/organ/original, mob/living/carbon/human/target)
	return TRUE

/// Lets the kit copy state from the original organ onto its replacement before insertion.
/datum/partial_transformation_kit/proc/prepare_replacement(obj/item/organ/replacement, obj/item/organ/original, mob/living/carbon/human/target)
	return

/// Denial message shown when one of blocking_traits stops the shift.
/datum/partial_transformation_kit/proc/get_block_message(trait)
	var/message = blocking_traits[trait]
	if(message)
		return message
	return "Something keeps my body from changing."
