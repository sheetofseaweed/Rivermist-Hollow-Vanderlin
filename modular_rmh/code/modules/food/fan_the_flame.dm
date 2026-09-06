/**
 * Fanning a lit fire speeds along whatever is cooking on it.
 *
 * Right-click a lit hearth or oven to start fanning; it repeats until the fire
 * goes out or the channel is interrupted. Costs no fuel - only the time spent
 * standing there.
 */

/// Which item's active crafts get sped up. Ovens carry the craft component
/// themselves; a hearth passes it to whatever is hung on it.
/obj/machinery/light/fueled/proc/get_cooking_target()
	return src

/obj/machinery/light/fueled/hearth/get_cooking_target()
	return attachment

/obj/machinery/light/fueled/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return
	. = SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	if(!on)
		to_chat(user, span_warning("There's no fire lit to fan."))
		return
	user.visible_message(span_notice("[user] starts fanning the flames on [src]."), span_notice("I start fanning the flames on [src]."))
	var/fanned = FALSE
	while(on && do_after(user, 2 SECONDS, src))
		fanned = TRUE
		fan_crafts(user)
	if(fanned)
		to_chat(user, span_notice("I stop fanning the flames."))

/obj/machinery/light/fueled/proc/fan_crafts(mob/user)
	var/obj/item/target = get_cooking_target()
	if(!target)
		return
	var/skill_bonus = 0
	if(user.mind)
		skill_bonus = GET_MOB_SKILL_VALUE_OLD(user, /datum/attribute/skill/craft/cooking) / 6
	var/bonus_progress = 2 SECONDS * (1 + skill_bonus)
	for(var/datum/container_craft_operation/op as anything in GLOB.active_container_crafts)
		if(op.crafter != target)
			continue
		op.add_progress(bonus_progress)
