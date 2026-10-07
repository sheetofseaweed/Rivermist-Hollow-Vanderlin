/datum/action/cooldown/spell/undirected/gnoll_claws
	name = "Gnoll Claws"
	desc = "Extend blunt hunting claws in your free hands, or retract them. Held equipment stays in place."
	button_icon = 'modular_rmh/icons/mob/actions/gnoll_spells.dmi'
	button_icon_state = "claws"
	spell_type = NONE
	antimagic_flags = NONE
	spell_flags = SPELL_IGNORE_SPELLBLOCK
	associated_skill = null
	charge_required = FALSE
	cooldown_time = 1 SECONDS
	has_visual_effects = FALSE
	var/list/datum/weakref/claw_refs = list()

/datum/action/cooldown/spell/undirected/gnoll_claws/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return .
	if(!get_gnoll_antag(owner))
		return . | SPELL_CANCEL_CAST
	if(is_action_active())
		return .
	if(!length(owner.get_empty_held_indexes()))
		to_chat(owner, span_warning("Free a hand before extending your claws."))
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/undirected/gnoll_claws/is_action_active(atom/movable/screen/movable/action_button/current_button)
	for(var/datum/weakref/claw_ref as anything in claw_refs.Copy())
		if(claw_ref.resolve())
			return TRUE
		claw_refs -= claw_ref
	return FALSE

/datum/action/cooldown/spell/undirected/gnoll_claws/proc/retract_claws(show_message = TRUE)
	for(var/datum/weakref/claw_ref as anything in claw_refs)
		var/obj/item/weapon/gnoll_claw/claw = claw_ref.resolve()
		if(claw)
			qdel(claw)
	claw_refs.Cut()
	if(show_message && owner)
		owner.visible_message(span_notice("[owner] retracts their hunting claws."))

/datum/action/cooldown/spell/undirected/gnoll_claws/Remove(mob/remove_from)
	retract_claws(FALSE)
	return ..()

/datum/action/cooldown/spell/undirected/gnoll_claws/cast(atom/cast_on)
	. = ..()
	if(is_action_active())
		retract_claws()
		return
	var/mob/living/carbon/human/champion = owner
	if(!istype(champion) || !get_gnoll_antag(champion))
		return
	for(var/hand_index in champion.get_empty_held_indexes())
		var/claw_type = hand_index == 1 ? /obj/item/weapon/gnoll_claw/left : /obj/item/weapon/gnoll_claw/right
		var/obj/item/weapon/gnoll_claw/claw = new claw_type(champion)
		if(!champion.put_in_hand(claw, hand_index, TRUE))
			qdel(claw)
			continue
		claw_refs += WEAKREF(claw)
	if(!is_action_active())
		to_chat(champion, span_warning("Your hands cannot extend their hunting claws."))
		reset_spell_cooldown()
		return
	champion.visible_message(span_boldnotice("[champion] extends their powerful hunting claws."))

/datum/action/cooldown/spell/undirected/gnoll_howl
	name = "Pack Howl"
	desc = "Howl a message to packmates within fifty tiles on this level. Others can hear the howl."
	button_icon = 'modular_rmh/icons/mob/actions/gnoll_spells.dmi'
	button_icon_state = "howl"
	spell_type = NONE
	antimagic_flags = NONE
	spell_flags = SPELL_IGNORE_SPELLBLOCK
	charge_required = FALSE
	cooldown_time = 1 MINUTES
	has_visual_effects = FALSE
	var/message

/datum/action/cooldown/spell/undirected/gnoll_howl/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return .
	message = browser_input_text(owner, "Howl to your pack.", "Gorellik's Pack", max_length = 200)
	if(QDELETED(src) || !message || !can_cast_spell())
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/undirected/gnoll_howl/cast(atom/cast_on)
	. = ..()
	var/datum/antagonist/gnoll/howler = get_gnoll_antag(owner)
	if(!howler)
		return
	playsound(owner, 'sound/vo/mobs/hyena/yeen_howl.ogg', 75, TRUE)
	for(var/datum/mind/companion in howler.pack.members)
		var/mob/living/body = companion.current
		if(isliving(body) && body.stat != DEAD && body.z == owner.z && get_dist(body, owner) <= 50)
			to_chat(body, span_boldnotice("[owner.real_name] howls to the pack: \"[html_encode(message)]\""))
	owner.log_message("howls: [message] (GNOLL)", LOG_GAME)
	message = null

/datum/action/cooldown/spell/undirected/gnoll_scent
	name = "Scent the Quarry"
	desc = "Find the rough bearing of your contract's marked quarry. The quarry senses the hunt."
	button_icon = 'modular_rmh/icons/mob/actions/gnollmiracles.dmi'
	button_icon_state = "sniff"
	spell_type = NONE
	antimagic_flags = NONE
	spell_flags = SPELL_IGNORE_SPELLBLOCK
	charge_required = FALSE
	cooldown_time = 1 MINUTES
	has_visual_effects = FALSE

/datum/action/cooldown/spell/undirected/gnoll_scent/cast(atom/cast_on)
	var/datum/antagonist/gnoll/hunter = get_gnoll_antag(owner)
	var/keen = hunter?.pack?.get_favor() >= GNOLL_FAVOR_KEEN_TRAIL
	cooldown_time = keen ? 30 SECONDS : initial(cooldown_time)
	. = ..()
	var/datum/contract_goal/gnoll/hunt/hunt = hunter?.pack.get_goal(/datum/contract_goal/gnoll/hunt)
	var/mob/living/carbon/human/quarry = hunt?.get_quarry()
	if(!quarry)
		to_chat(owner, span_warning("There is no living quarry marked for the pack right now."))
		reset_spell_cooldown()
		return
	var/turf/hunter_turf = get_turf(owner)
	var/turf/quarry_turf = get_turf(quarry)
	if(!hunter_turf || !quarry_turf || hunter_turf.z != quarry_turf.z)
		to_chat(owner, span_notice("[hunt.quarry_name]'s scent is beyond this level."))
		return
	var/distance = get_dist(hunter_turf, quarry_turf)
	if(distance > 120)
		to_chat(owner, span_notice("[hunt.quarry_name]'s scent is too distant to follow from here."))
		return
	var/proximity = distance <= 15 ? "nearby" : (distance <= 50 ? "some distance away" : "far away")
	if(keen)
		proximity = "about [max(5, round(distance, 5))] paces away"
	to_chat(owner, span_notice("[hunt.quarry_name]'s scent lies [dir2text(get_dir(hunter_turf, quarry_turf))], [proximity]."))
	to_chat(quarry, span_warning("A distant, watchful presence follows your scent. Gorellik's pack has marked you for a living hunt."))

/datum/action/cooldown/spell/undirected/gnoll_honor_hunt
	name = "Honor the Hunt"
	desc = "Conclude the pack's hunt beside its subdued, awake quarry."
	button_icon_state = "lesserheal"
	spell_type = NONE
	antimagic_flags = NONE
	spell_flags = SPELL_IGNORE_SPELLBLOCK
	charge_required = FALSE
	cooldown_time = 5 SECONDS
	has_visual_effects = FALSE

/datum/action/cooldown/spell/undirected/gnoll_honor_hunt/cast(atom/cast_on)
	. = ..()
	var/datum/antagonist/gnoll/hunter = get_gnoll_antag(owner)
	var/datum/contract_goal/gnoll/hunt/hunt = hunter?.pack.get_goal(/datum/contract_goal/gnoll/hunt)
	if(!hunt?.conclude(owner))
		to_chat(owner, span_warning("Stand beside the marked quarry once your pack has subdued them: knocked out and revived, yielded, or held bound for thirty seconds. They must be awake."))
		reset_spell_cooldown()

/datum/action/cooldown/spell/undirected/gnoll_stalk
	name = "Stalk"
	desc = "Vanish into the hunt until you attack or take damage. Damage prevents Stalk for one minute. Use again to reveal yourself."
	button_icon = 'modular_rmh/icons/mob/actions/gnollmiracles.dmi'
	button_icon_state = "stalk"
	spell_type = NONE
	antimagic_flags = NONE
	spell_flags = SPELL_IGNORE_SPELLBLOCK
	charge_required = FALSE
	cooldown_time = 2 MINUTES
	has_visual_effects = FALSE

/datum/action/cooldown/spell/undirected/gnoll_stalk/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return .
	var/datum/antagonist/gnoll/hunter = get_gnoll_antag(owner)
	if(!hunter)
		return . | SPELL_CANCEL_CAST
	if(owner.has_status_effect(/datum/status_effect/invisibility/gnoll_stalk))
		var/mob/living/hunter_body = owner
		hunter_body.remove_status_effect(/datum/status_effect/invisibility/gnoll_stalk)
		return . | SPELL_CANCEL_CAST
	if(!isnull(hunter.last_hunt_damage_time) && world.time < hunter.last_hunt_damage_time + GNOLL_STALK_RECOVERY)
		var/seconds_left = ceil((hunter.last_hunt_damage_time + GNOLL_STALK_RECOVERY - world.time) / (1 SECONDS))
		to_chat(owner, span_warning("Your wounds disrupt the shroud. Wait [seconds_left] seconds."))
		return . | SPELL_CANCEL_CAST
	if(owner.can_block_magic(MAGIC_RESISTANCE, charge_cost = 0))
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/undirected/gnoll_stalk/cast(atom/cast_on)
	. = ..()
	var/mob/living/hunter_body = owner
	hunter_body.apply_status_effect(/datum/status_effect/invisibility/gnoll_stalk)

/datum/action/cooldown/spell/undirected/gnoll_stalk/Trigger(trigger_flags, atom/target)
	var/mob/living/hunter_body = owner
	if(hunter_body?.has_status_effect(/datum/status_effect/invisibility/gnoll_stalk))
		hunter_body.remove_status_effect(/datum/status_effect/invisibility/gnoll_stalk)
		return TRUE
	return ..()

/datum/action/cooldown/spell/undirected/gnoll_stalk/Remove(mob/living/remove_from)
	remove_from.remove_status_effect(/datum/status_effect/invisibility/gnoll_stalk)
	return ..()

/// Use native invisibility so movement and perception cannot accidentally reveal the shroud.
/datum/status_effect/invisibility/gnoll_stalk
	id = "gnoll_stalk"
	duration = -1

/datum/status_effect/invisibility/gnoll_stalk/on_apply()
	. = ..()
	if(!.)
		return FALSE
	RegisterSignal(owner, COMSIG_MOB_ATTACK_HAND, PROC_REF(on_unarmed_attack))
	RegisterSignal(owner, list(COMSIG_MOB_ITEM_ATTACK, COMSIG_MOB_ATTACK_RANGED, COMSIG_MOB_THROW, COMSIG_MOB_KICK), PROC_REF(on_attack))
	RegisterSignal(owner, COMSIG_MOB_MIDDLECLICKON, PROC_REF(on_middle_click))
	RegisterSignal(owner, COMSIG_MOB_CAST_SPELL, PROC_REF(on_spell_cast))

/datum/status_effect/invisibility/gnoll_stalk/proc/on_unarmed_attack(mob/living/source, mob/living/attacker, mob/living/target)
	SIGNAL_HANDLER
	if(source.used_intent?.type != INTENT_HELP)
		qdel(src)

/datum/status_effect/invisibility/gnoll_stalk/proc/on_attack()
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/invisibility/gnoll_stalk/proc/on_middle_click(mob/living/source, atom/target)
	SIGNAL_HANDLER
	if(isliving(target) && source.Adjacent(target))
		qdel(src)

/datum/status_effect/invisibility/gnoll_stalk/proc/on_spell_cast(mob/living/source, datum/action/cooldown/spell/spell)
	SIGNAL_HANDLER
	if(!istype(spell, /datum/action/cooldown/spell/undirected/gnoll_scent))
		qdel(src)

/datum/status_effect/invisibility/gnoll_stalk/on_remove()
	UnregisterSignal(owner, list(COMSIG_MOB_ATTACK_HAND, COMSIG_MOB_ITEM_ATTACK, COMSIG_MOB_ATTACK_RANGED, COMSIG_MOB_THROW, COMSIG_MOB_KICK, COMSIG_MOB_MIDDLECLICKON, COMSIG_MOB_CAST_SPELL))
	return ..()

/datum/action/cooldown/spell/gnoll_abduct
	name = "Abduct"
	desc = "Cast on yourself to set an anchor. Channel on an aggressively grabbed adult to bring them and nearby packmates there. Faster on your contract quarry. Costs each travelling Gnoll some blood, less with Gorellik's favor; heavy recent damage interrupts the rite. Travelling with packmates leaves a passage for one pursuer."
	button_icon = 'modular_rmh/icons/mob/actions/gnollmiracles.dmi'
	button_icon_state = "abduct"
	spell_type = NONE
	antimagic_flags = NONE
	spell_flags = SPELL_IGNORE_SPELLBLOCK
	charge_required = FALSE
	click_to_activate = TRUE
	self_cast_possible = TRUE
	cast_range = 1
	cooldown_time = 5 MINUTES
	has_visual_effects = FALSE
	var/datum/weakref/anchor_ref
	var/channeling = FALSE

/proc/get_gnoll_abduct_blood_cost(datum/antagonist/gnoll/hunter)
	return hunter?.pack?.get_favor() >= GNOLL_FAVOR_SWIFT_PATH ? round(GNOLL_ABDUCT_BLOOD_COST / 2) : GNOLL_ABDUCT_BLOOD_COST

/datum/action/cooldown/spell/gnoll_abduct/Grant(mob/grant_to)
	. = ..()
	if(!anchor_ref && istype(get_turf(grant_to), /turf/open/floor))
		anchor_ref = WEAKREF(get_turf(grant_to))

/datum/action/cooldown/spell/gnoll_abduct/Destroy()
	anchor_ref = null
	return ..()

/datum/action/cooldown/spell/gnoll_abduct/proc/can_abduct(mob/living/carbon/human/caster, mob/living/carbon/human/quarry, turf/anchor)
	var/datum/antagonist/gnoll/hunter = get_gnoll_antag(caster)
	if(QDELETED(src) || QDELETED(caster) || QDELETED(quarry) || !istype(caster) || !istype(quarry) || !istype(caster.dna?.species, /datum/species/gnoll_champion) || !hunter || owner != caster || !can_cast_spell() || !hunter.can_focus_abduction())
		return FALSE
	if(quarry.stat == DEAD || !(quarry.age in list(AGE_ADULT, AGE_MIDDLEAGED, AGE_OLD, AGE_IMMORTAL)) || quarry.buckled || caster.pulling != quarry || caster.grab_state < GRAB_AGGRESSIVE || !caster.Adjacent(quarry))
		return FALSE
	if(caster.blood_volume < BLOOD_VOLUME_SURVIVE + get_gnoll_abduct_blood_cost(hunter) || HAS_TRAIT(caster, TRAIT_NO_TELEPORT) || HAS_TRAIT(quarry, TRAIT_NO_TELEPORT))
		return FALSE
	if(!istype(anchor, /turf/open/floor) || anchor.density || anchor.is_transition_turf())
		return FALSE
	var/area/origin_area = get_area(caster)
	var/area/quarry_area = get_area(quarry)
	var/area/anchor_area = get_area(anchor)
	if((origin_area.area_flags | quarry_area.area_flags | anchor_area.area_flags) & NO_TELEPORT)
		return FALSE
	for(var/atom/movable/obstacle in anchor)
		if(obstacle.density && !isliving(obstacle))
			return FALSE
	return TRUE

/datum/action/cooldown/spell/gnoll_abduct/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return .
	var/mob/living/carbon/human/caster = owner
	if(!istype(caster) || !get_gnoll_antag(caster) || channeling)
		return . | SPELL_CANCEL_CAST
	if(cast_on == caster)
		var/turf/new_anchor = get_turf(caster)
		if(!istype(new_anchor, /turf/open/floor))
			to_chat(caster, span_warning("Choose solid ground for your anchor."))
			return . | SPELL_CANCEL_CAST
		channeling = TRUE
		to_chat(caster, span_notice("You begin anchoring a path through Gorellik's wilds."))
		var/anchored = do_after(caster, 10 SECONDS, target = caster)
		if(QDELETED(src))
			return . | SPELL_CANCEL_CAST
		channeling = FALSE
		if(anchored && owner == caster && get_gnoll_antag(caster) && get_turf(caster) == new_anchor)
			anchor_ref = WEAKREF(new_anchor)
			to_chat(caster, span_notice("Your hunting path is anchored here."))
		return . | SPELL_CANCEL_CAST
	var/mob/living/carbon/human/quarry = cast_on
	var/turf/anchor = anchor_ref?.resolve()
	if(!can_abduct(caster, quarry, anchor))
		to_chat(caster, span_warning("Keep an aggressive grab on a living adult, a clear anchor and enough blood. Heavy recent damage disrupts the rite."))
		return . | SPELL_CANCEL_CAST
	var/datum/antagonist/gnoll/hunter = get_gnoll_antag(caster)
	var/datum/contract_goal/gnoll/hunt/hunt = hunter.pack.get_goal(/datum/contract_goal/gnoll/hunt)
	var/channel_time = hunt?.quarry_ref?.resolve() == quarry ? 6 SECONDS : 15 SECONDS
	channeling = TRUE
	caster.visible_message(span_warning("[caster] opens a wavering path through the wilds and begins drawing [quarry] into it."))
	to_chat(quarry, span_warning("The air shimmers around you. Break the Gnoll's grasp to escape the passage!"))
	var/finished = do_after(caster, channel_time, target = quarry, extra_checks = CALLBACK(src, PROC_REF(can_abduct), caster, quarry, anchor))
	if(QDELETED(src))
		return . | SPELL_CANCEL_CAST
	channeling = FALSE
	if(!finished || !can_abduct(caster, quarry, anchor))
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/gnoll_abduct/cast(atom/cast_on)
	var/mob/living/carbon/human/caster = owner
	var/mob/living/carbon/human/quarry = cast_on
	var/turf/anchor = anchor_ref?.resolve()
	if(!can_abduct(caster, quarry, anchor))
		reset_spell_cooldown()
		return
	var/datum/antagonist/gnoll/hunter = get_gnoll_antag(caster)
	var/swift = hunter.pack?.get_favor() >= GNOLL_FAVOR_SWIFT_PATH
	cooldown_time = swift ? 3 MINUTES : initial(cooldown_time)
	var/blood_cost = get_gnoll_abduct_blood_cost(hunter)
	. = ..()
	var/turf/origin = get_turf(quarry)
	var/turf/caster_origin = get_turf(caster)
	var/list/companions = list()
	for(var/datum/mind/member in hunter.pack.members)
		var/mob/living/carbon/human/companion = member.current
		if(!istype(companion) || QDELETED(companion) || !istype(companion.dna?.species, /datum/species/gnoll_champion) || companion == caster || companion == quarry || companion.stat == DEAD || companion.buckled || get_dist(origin, companion) > 7 || companion.z != origin.z || companion.blood_volume < BLOOD_VOLUME_SURVIVE + blood_cost)
			continue
		companions += companion
	if(!do_teleport(caster, anchor, no_effects = TRUE))
		reset_spell_cooldown()
		return
	if(!do_teleport(quarry, anchor, no_effects = TRUE))
		caster.forceMove(caster_origin)
		reset_spell_cooldown()
		return
	caster.blood_volume -= blood_cost
	var/hitchhikers = 0
	for(var/mob/living/carbon/human/companion as anything in companions)
		if(do_teleport(companion, anchor, no_effects = TRUE))
			companion.blood_volume -= blood_cost
			hitchhikers++
			to_chat(companion, span_notice("Your packmate draws you along their hunting path."))
	if(hitchhikers)
		new /obj/structure/fluff/traveltile/gnoll_hunt_rift(origin, anchor)
	to_chat(caster, span_notice("You have brought your quarry to the anchor. Restore and release them after the hunt."))

