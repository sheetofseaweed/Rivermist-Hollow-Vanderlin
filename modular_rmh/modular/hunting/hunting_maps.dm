// Hunting & Tracking pack - hunter's maps.
//
// A map is used on a *fresh* mound, before anyone has read it,
// and biases what the trail turns out to lead to. It never guarantees anything on its own: the roll
// scales with Hunting skill, and most maps wear out with use.
//
// This is the only intended way to go looking for a White Stag on purpose. Without a map the stag
// sits at weight 1 against every other category and only from Hunting 30 up, so finding one by
// accident stays a story worth telling.

/obj/item/hunting_map
	name = "crumpled map"
	desc = "A rough sketch of animal migratory patterns and bedding sites."
	icon = 'modular_rmh/icons/obj/hunting/hunting_maps.dmi'
	icon_state = "hunt_map"
	w_class = WEIGHT_CLASS_TINY
	/// The category this map argues for.
	var/datum/hunting_category/target_category = /datum/hunting_category/low_tier
	/// Success chance per Hunting skill level, 0 to 6.
	var/list/skill_chances = list(0, 0, 0, 0, 0, 0, 0)
	/// Fraction of effectiveness lost per use. 0.1 is ten percent.
	var/degradation_rate = 0
	/// Remaining effectiveness multiplier.
	var/current_potency = 1
	/// Hard cap on uses. -1 means unlimited.
	var/uses_left = -1

/obj/item/hunting_map/get_mechanics_examine(mob/user)
	. = ..()
	. += span_info("Use a map on a fresh mound to improve the odds of that trail leading to the creature it describes.")
	. += span_info("Some maps only pay off for skilled hunters.")
	. += span_info("Some maps wear out as you use them, and eventually fall apart.")

/obj/item/hunting_map/afterattack(atom/target, mob/living/user, proximity_flag, list/modifiers)
	. = ..()
	if(!proximity_flag)
		return
	var/obj/effect/hunting_track/trail = target
	if(!istype(trail))
		return

	if(trail.trail_depth > 0 || trail.track_revealed)
		to_chat(user, span_warning("The trail is already cold or established. This is only useful on a fresh mound."))
		return
	if(trail.hunt_category)
		to_chat(user, span_warning("This trail has already been identified."))
		return
	if(trail.influence_attempted)
		to_chat(user, span_warning("This trail has already been cross-examined against a map."))
		return

	var/datum/hunting_category/wanted = new target_category()
	var/area/here = get_area(trail)
	if(!wanted.can_spawn_in_area(here))
		to_chat(user, span_warning("The signs drawn on [src] do not match this terrain."))
		return

	user.visible_message(
		span_notice("[user] consults [src] while examining the earth."),
		span_notice("You cross-reference the signs in the dirt with the markings on [src]..."),
	)
	if(!do_after(user, 3 SECONDS, target = trail))
		return
	if(QDELETED(trail) || trail.influence_attempted || trail.hunt_category)
		return

	var/skill = GET_MOB_SKILL_VALUE_OLD(user, /datum/attribute/skill/misc/hunting)
	if(prob(skill_chances[clamp(skill + 1, 1, length(skill_chances))] * current_potency))
		trail.secret_map_influence = target_category
	// Set either way: one map per trail, so a pile of maps cannot be rerolled against one mound.
	trail.influence_attempted = TRUE
	to_chat(user, span_info("You feel a bit more confident about the direction of this trail."))

	if(degradation_rate > 0)
		current_potency = max(0, current_potency - degradation_rate)
		if(current_potency <= 0)
			to_chat(user, span_danger("[src] has become completely illegible and falls apart."))
			qdel(src)
			return

	if(uses_left > 0)
		uses_left--
		if(uses_left <= 0)
			to_chat(user, span_danger("[src] tears into useless scraps from heavy use."))
			qdel(src)

/obj/item/hunting_map/white_stag
	name = "legend of the white stag"
	desc = "An esoteric map detailed with blessed silver ink. It claims to track the movements of a Great White Stag. \
	Only the best hunters can decipher the signs properly when reading it against an animal track."
	target_category = /datum/hunting_category/white_stag
	skill_chances = list(1, 1, 5, 10, 14, 18, 20)
	degradation_rate = 0.1
	uses_left = 3

/obj/item/hunting_map/boars
	name = "boar signs"
	desc = "A simple map marking where bramblesnouts have been goring people lately. Easy enough for any hunter to follow."
	target_category = /datum/hunting_category/boars
	skill_chances = list(20, 30, 40, 50, 70, 90, 100)
	degradation_rate = 0
	uses_left = 5

/// Testing copy: always works, once.
/obj/item/hunting_map/white_stag/debug
	name = "legend of the white stag (debug)"
	skill_chances = list(100, 100, 100, 100, 100, 100, 100)
	degradation_rate = 0
	uses_left = 1
