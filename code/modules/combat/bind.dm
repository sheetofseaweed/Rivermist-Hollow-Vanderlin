// TEMPO_TAG_BINDABLE: reserved for the vulnerable-strike bind path (TA checkdefense parity), not wired here.
// This file implements the parry-path weapon bind: if the defender's active aim subzone matches the
// attacker's subzone at the moment of parry, and the defender is skilled enough (journeyman+), the
// defender earns a brief lock on the attacker — Immobilize + click delay — and both weapons take wear.

/**
 * Defensive boon from matching aim subzones: lock the attacker's weapon. (TA port, adapted)
 * Skill-gated (journeyman+ with the parrying weapon), cooldown-gated, near-never fires chest-vs-chest.
 *
 * @param used_weapon   The defender's active parrying weapon.
 * @param user          The attacking mob.
 * @param vuln_exception If TRUE, the defender's weapon also takes heavier wear. Not yet wired; reserved for the vulnerable-strike path.
 * @return TRUE if the bind fired.
 */
/mob/living/carbon/human/proc/try_bind(obj/item/used_weapon, mob/living/user, vuln_exception = FALSE)
	if(!used_weapon || !user.get_active_held_item())
		return FALSE
	// Skill gate: journeyman (30/60) in the parrying weapon's associated skill.
	if(nulltozero(GET_MOB_SKILL_VALUE(src, used_weapon.associated_skill)) < SKILL_LEVEL_JOURNEYMAN)
		return FALSE
	// Cooldown gate.
	if(has_status_effect(/datum/status_effect/debuff/bindcd))
		return FALSE
	// Zone match gate.
	// For mindless NPCs without a zone_selected, fall back to coarse zone comparison.
	var/def_bindzone = check_bind_subzone(zone_selected)
	if(!check_bind(def_bindzone, user.zone_selected))
		if(user.mind || (check_zone(zone_selected) != check_zone(user.zone_selected)))
			return FALSE
	// Chest-vs-chest is the default aim; near-never binds to avoid free passive procs.
	if(zone_selected == BODY_ZONE_CHEST && user.zone_selected == BODY_ZONE_CHEST)
		if(!prob(3))
			return FALSE

	// Apply bind effects to the defender.
	apply_status_effect(/datum/status_effect/buff/weapon_binded)
	apply_status_effect(/datum/status_effect/debuff/bindcd)

	// Penalize the attacker: brief stagger and click lockout (durations mirror clash.dm's riposte lockout).
	user.Immobilize(0.3 SECONDS)
	user.changeNext_move(15) // immediate 1.5 s gate; the clickcd below overwrites it to the full 3 s (same pattern as clash.dm)
	user.apply_status_effect(/datum/status_effect/debuff/clickcd, 3 SECONDS)

	// Weapon wear: attacker's weapon takes the brunt.
	var/obj/item/their_weapon = user.get_active_held_item()
	var/att_intdam = their_weapon.max_blade_int ? INTEG_PARRY_DECAY : INTEG_PARRY_DECAY_NOSHARP
	their_weapon.take_damage(att_intdam, BRUTE, their_weapon.damage_type)
	their_weapon.remove_bintegrity(SHARPNESS_ONHIT_DECAY, src)

	// Vulnerable exception: defender's weapon also suffers from the strain.
	if(vuln_exception)
		used_weapon.take_damage(INTEG_PARRY_DECAY_NOSHARP * 3, BRUTE, used_weapon.damage_type)
		used_weapon.remove_bintegrity(SHARPNESS_ONHIT_DECAY * 3, src)

	// Visuals and sound.
	flash_fullscreen("whiteflash")
	user.flash_fullscreen("whiteflash")
	var/datum/effect_system/spark_spread/S = new()
	S.set_up(4, FALSE, get_turf(src))
	S.start()
	playsound(src, pick(used_weapon.parrysound), 100, TRUE, 2)
	visible_message(span_warning("[src] binds [user]'s weapon with [used_weapon]!"))
	return TRUE
