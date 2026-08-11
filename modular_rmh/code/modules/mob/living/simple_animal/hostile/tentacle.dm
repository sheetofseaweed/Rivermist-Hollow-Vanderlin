/datum/targetting_datum/basic/tentacle

/datum/targetting_datum/basic/tentacle/can_quickly_engage_target(mob/living/living_mob, atom/target)
	return can_attack(living_mob, target)

/datum/targetting_datum/basic/tentacle/can_engage_target(mob/living/living_mob, atom/target)
	return can_attack(living_mob, target)

/datum/targetting_datum/basic/tentacle/should_disarm(mob/living/living_mob, atom/target)
	return FALSE

/datum/ai_controller/tentacle
	movement_delay = 0.4 SECONDS
	ai_movement = /datum/ai_movement/hybrid_pathing
	horny_pref_family_flag = HORNY_MOB_TYPE_TENTACLES

	blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic/tentacle(),
	)

	planning_subtrees = list(
		/datum/ai_planning_subtree/flee_target,
		/datum/ai_planning_subtree/kidnap_defeated_prey,

		/datum/ai_planning_subtree/simple_find_horny,
		/datum/ai_planning_subtree/horny,

		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/basic_melee_attack_subtree/agile,
	)

	idle_behavior = /datum/idle_behavior/idle_random_walk

/mob/living/simple_animal/hostile/retaliate/tentacle
	name = "writhing tentacle mass"
	desc = "A restless knot of slick, searching tentacles moving with unsettling purpose."
	icon = 'modular_rmh/icons/mob/monster/tentacles.dmi'
	icon_state = "tentacles"
	icon_living = "tentacles"
	icon_dead = "tentacles_dead"

	faction = list("tentacles")
	gender = MALE
	mob_biotypes = MOB_ORGANIC | MOB_BEAST
	move_to_delay = 2
	vision_range = 7
	aggro_vision_range = 7

	health = 120
	maxHealth = 120
	base_constitution = 8
	base_strength = 9
	base_speed = 12

	base_intents = list(/datum/intent/simple/slam)
	attack_verb_continuous = "lashes"
	attack_verb_simple = "lash"
	attack_sound = 'sound/combat/hits/blunt/woodblunt (1).ogg'
	melee_damage_lower = 10
	melee_damage_upper = 16
	defprob = 20
	defdrain = 8
	candodge = FALSE

	aggressive = FALSE
	stat_attack = UNCONSCIOUS
	retreat_distance = 0
	minimum_distance = 0
	deaggroprob = 0
	food_type = list()
	pooptype = null
	ai_controller = /datum/ai_controller/tentacle
	kidnap_lair_tag = "tentacle_lair"
	kidnap_captivity_profile = /datum/defeat_captivity_profile/shared/tentacle

	emote_see = list("slowly coils in on itself", "tastes the air with a questing tip", "ripples across the ground")

/mob/living/simple_animal/hostile/retaliate/tentacle/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/ai_retaliate)
	var/obj/item/organ/genitals/penis/ovipositor/ovipositor = ensure_typed_ovipositor(src, OVI_EGG_TENTACLE)
	if(ovipositor)
		ovipositor.name = "egg-bearing tentacle"
		ovipositor.desc = "A sensitive, prehensile tentacle adapted to carry and lay soft eggs."

/mob/living/simple_animal/hostile/retaliate/tentacle/simple_limb_hit(zone)
	if(!zone)
		return ""
	return pick("central mass", "thick coil", "questing tendril", "soft underside")

/// Tentacles use the ordinary defeat-captivity flow, but their configured lair is a real map
/// location instead of a pocket instance.
/mob/living/simple_animal/hostile/retaliate/tentacle/complete_kidnap_defeated_prey(mob/living/victim)
	var/obj/effect/landmark/kidnap/entrance/tentacle/entrance = get_tentacle_lair_entrance(src)
	if(!entrance)
		return FALSE
	return victim.kidnap_to_mapped_lair(kidnap_captivity_profile, src, faction, kidnap_lair_tag, entrance)

/datum/defeat_captivity_profile/shared/tentacle
	stable_key = "tentacle_lair"
	display_name = "tentacle lair"
	capacity = 12

/// Mapper destination for independent and unbound tentacles. At least one must exist on the same
/// z-level as the captor; the nearest valid marker is selected.
/obj/effect/landmark/kidnap/entrance/tentacle
	name = "tentacle lair kidnap entrance"
	lair_tag = "tentacle_lair"

/// Crossing this mapper marker ends mapped tentacle captivity in place. Put it on the physical way
/// out of the lair rather than beside the entrance marker.
/obj/effect/landmark/kidnap/escape/tentacle
	name = "tentacle lair captivity boundary"
	lair_tag = "tentacle_lair"

/proc/get_tentacle_lair_entrance(atom/reference)
	var/turf/reference_turf = get_turf(reference)
	if(!reference_turf)
		return null
	var/list/entrances = GLOB.kidnap_entrance_markers["tentacle_lair"]
	var/obj/effect/landmark/kidnap/entrance/tentacle/nearest_entrance
	var/nearest_distance = INFINITY
	for(var/obj/effect/landmark/kidnap/entrance/tentacle/candidate as anything in entrances)
		var/turf/candidate_turf = get_turf(candidate)
		if(!candidate_turf || candidate_turf.z != reference_turf.z)
			continue
		var/candidate_distance = get_dist(reference_turf, candidate_turf)
		if(candidate_distance >= nearest_distance)
			continue
		nearest_entrance = candidate
		nearest_distance = candidate_distance
	return nearest_entrance

/obj/item/rope/spider_silk/tentacle_resin
	name = "tentacle resin"
	desc = "A warm coil of sticky resin, fibrous enough to bind wrists."
	breakouttime = 10 SECONDS
	slipouttime = 30 SECONDS
	color = "#804b70"

/datum/sex_action/npc/npc_vaginal_sex/tentacle
	name = "Tentacle their vagina"
	description = "Work an egg-bearing tentacle into their vagina."

/datum/sex_action/npc/npc_vaginal_sex/tentacle/shows_on_menu(mob/living/user, mob/living/target)
	return istype(user, /mob/living/simple_animal/hostile/retaliate/tentacle) && !is_maneater_tendril(user) && user != target

/datum/sex_action/npc/npc_vaginal_sex/tentacle/maneater
	name = "Part their petals with a vine"
	description = "Work a seed-bearing plant tendril into their vagina."

/datum/sex_action/npc/npc_vaginal_sex/tentacle/maneater/shows_on_menu(mob/living/user, mob/living/target)
	return is_maneater_tendril(user) && user != target

/datum/sex_action/npc/npc_vaginal_sex/tentacle/maneater/get_start_message(mob/living/user, mob/living/target)
	return "[user] eases a flowering vine into [target]'s cunt!"

/datum/sex_action/npc/npc_vaginal_sex/tentacle/maneater/get_perform_message(mob/living/user, mob/living/target)
	return "[user] [get_generic_force_adjective()] roots its flowering vine in [target]'s pussy."

/datum/sex_action/npc/npc_vaginal_sex/tentacle/maneater/get_finish_message(mob/living/user, mob/living/target)
	return "[user] draws its sap-slick vine out of [target]'s pussy."

/datum/sex_action/npc/npc_vaginal_sex/tentacle/maneater/handle_climax_message(mob/living/user, mob/living/target, must_flip)
	if(must_flip)
		user.visible_message(span_love("[user] shudders as [target] clenches around its flowering vine!"))
		user.lose_virginity()
		target.lose_virginity()
		return ORGASM_LOCATION_ONTO
	user.visible_message(span_love("[user]'s vine pulses warm sap and seed into [target]'s pussy!"))
	user.lose_virginity()
	target.lose_virginity()
	return ORGASM_LOCATION_INTO

/datum/sex_action/npc/npc_anal_sex/tentacle
	name = "Tentacle their anus"
	description = "Work an egg-bearing tentacle into their anus."

/datum/sex_action/npc/npc_anal_sex/tentacle/shows_on_menu(mob/living/user, mob/living/target)
	return istype(user, /mob/living/simple_animal/hostile/retaliate/tentacle) && !is_maneater_tendril(user) && user != target

/datum/sex_action/npc/npc_anal_sex/tentacle/maneater
	name = "Root a vine in their anus"
	description = "Ease a seed-bearing plant tendril into their anus."

/datum/sex_action/npc/npc_anal_sex/tentacle/maneater/shows_on_menu(mob/living/user, mob/living/target)
	return is_maneater_tendril(user) && user != target

/datum/sex_action/npc/npc_anal_sex/tentacle/maneater/get_start_message(mob/living/user, mob/living/target)
	return "[user] works a tapering green vine into [target]'s ass!"

/datum/sex_action/npc/npc_anal_sex/tentacle/maneater/get_perform_message(mob/living/user, mob/living/target)
	return "[user] [get_generic_force_adjective()] drives its rooting vine into [target]'s ass."

/datum/sex_action/npc/npc_anal_sex/tentacle/maneater/get_finish_message(mob/living/user, mob/living/target)
	return "[user] slowly unroots its slick vine from [target]'s butt."

/datum/sex_action/npc/npc_anal_sex/tentacle/maneater/handle_climax_message(mob/living/user, mob/living/target, must_flip)
	if(must_flip)
		user.visible_message(span_love("[user] trembles as [target] wrings its vine tight!"))
		user.lose_virginity()
		target.lose_virginity()
		return ORGASM_LOCATION_SELF
	user.visible_message(span_love("[user]'s vine swells and spills warm seed into [target]'s butt!"))
	user.lose_virginity()
	target.lose_virginity()
	return ORGASM_LOCATION_INTO

/datum/sex_action/npc/npc_throat_sex/tentacle
	name = "Tentacle their throat"
	description = "Ease an egg-bearing tentacle into their mouth."

/datum/sex_action/npc/npc_throat_sex/tentacle/shows_on_menu(mob/living/user, mob/living/target)
	return istype(user, /mob/living/simple_animal/hostile/retaliate/tentacle) && !is_maneater_tendril(user) && user != target

/datum/sex_action/npc/npc_throat_sex/tentacle/maneater
	name = "Feed them a flowering vine"
	description = "Ease a seed-bearing plant tendril into their mouth."

/datum/sex_action/npc/npc_throat_sex/tentacle/maneater/shows_on_menu(mob/living/user, mob/living/target)
	return is_maneater_tendril(user) && user != target

/datum/sex_action/npc/npc_throat_sex/tentacle/maneater/get_perform_message(mob/living/user, mob/living/target)
	return "[user] [get_generic_force_adjective()] feeds its flowering vine down [target]'s throat."

/datum/sex_action/npc/npc_throat_sex/tentacle/maneater/get_finish_message(mob/living/user, mob/living/target)
	return "[user] lets its flowering vine slip free of [target]'s throat."

/datum/sex_action/npc/npc_throat_sex/tentacle/maneater/handle_climax_message(mob/living/user, mob/living/target, must_flip)
	if(must_flip)
		user.visible_message(span_love("[user] quivers from the pressure around its flowering vine!"))
		user.lose_virginity()
		return ORGASM_LOCATION_SELF
	user.visible_message(span_love("[user]'s vine pulses a mouthful of sweet sap and seed into [target]'s throat!"))
	user.lose_virginity()
	return ORGASM_LOCATION_ORAL

/datum/sex_action/tentacle_jerk
	name = "Tentacle jerk them off"
	description = "Coil a smaller tentacle around their penis."
	check_same_tile = FALSE
	user_menu_zone_mask = SEX_UI_ZONE_BODY
	target_menu_zone_mask = SEX_UI_ZONE_GENITALS

/datum/sex_action/tentacle_jerk/shows_on_menu(mob/living/user, mob/living/target)
	if(!istype(user, /mob/living/simple_animal/hostile/retaliate/tentacle) || is_maneater_tendril(user) || user == target)
		return FALSE
	return !!target.getorganslot(ORGAN_SLOT_PENIS)

/datum/sex_action/tentacle_jerk/can_perform(mob/living/user, mob/living/target)
	. = ..()
	if(!. || !shows_on_menu(user, target))
		return FALSE
	if(!check_location_accessible(user, target, BODY_ZONE_PRECISE_GROIN, TRUE))
		return FALSE
	return !check_sex_lock(target, ORGAN_SLOT_PENIS)

/datum/sex_action/tentacle_jerk/on_start(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning(get_start_message(user, target)))

/datum/sex_action/tentacle_jerk/proc/get_start_message(mob/living/user, mob/living/target)
	return "[user] coils a slick tentacle around [target]'s cock."

/datum/sex_action/tentacle_jerk/on_perform(mob/living/user, mob/living/target)
	. = ..()
	if(can_show_action_message(user, target))
		user.visible_message(spanify_force(get_perform_message(user, target)))
	playsound(target, 'sound/misc/mat/fingering.ogg', 30, TRUE, -2, ignore_walls = FALSE)
	perform_sex_action(target, user, 2, 0, 2)
	handle_passive_ejaculation(target)

/datum/sex_action/tentacle_jerk/proc/get_perform_message(mob/living/user, mob/living/target)
	return "[user] [get_generic_force_adjective()] milks [target]'s cock with a rippling tentacle."

/datum/sex_action/tentacle_jerk/on_finish(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning(get_finish_message(user, target)))

/datum/sex_action/tentacle_jerk/proc/get_finish_message(mob/living/user, mob/living/target)
	return "[user] unwinds its tentacle from [target]'s cock."

/datum/sex_action/tentacle_jerk/lock_sex_object(mob/living/user, mob/living/target)
	add_sex_lock(target, ORGAN_SLOT_PENIS, null, FALSE)

/datum/sex_action/tentacle_jerk/maneater
	name = "Wind vines around their cock"
	description = "Coil a flowering tendril around their penis."

/datum/sex_action/tentacle_jerk/maneater/shows_on_menu(mob/living/user, mob/living/target)
	if(!is_maneater_tendril(user) || user == target)
		return FALSE
	return !!target.getorganslot(ORGAN_SLOT_PENIS)

/datum/sex_action/tentacle_jerk/maneater/get_start_message(mob/living/user, mob/living/target)
	return "[user] winds a pair of flowering vines around [target]'s cock."

/datum/sex_action/tentacle_jerk/maneater/get_perform_message(mob/living/user, mob/living/target)
	return "[user] [get_generic_force_adjective()] milks [target]'s cock between pulsing, sap-slick vines."

/datum/sex_action/tentacle_jerk/maneater/get_finish_message(mob/living/user, mob/living/target)
	return "[user] lets its flowering vines uncurl from [target]'s cock."

/datum/sex_action/maneater_vine_caress
	name = "Envelop them in flowering vines"
	description = "Stroke and squeeze their body with warm, sap-slick tendrils."
	check_same_tile = FALSE
	user_menu_zone_mask = SEX_UI_ZONE_BODY
	target_menu_zone_mask = SEX_UI_ZONE_BODY

/datum/sex_action/maneater_vine_caress/shows_on_menu(mob/living/user, mob/living/target)
	return is_maneater_tendril(user) && user != target

/datum/sex_action/maneater_vine_caress/can_perform(mob/living/user, mob/living/target)
	. = ..()
	return . && shows_on_menu(user, target)

/datum/sex_action/maneater_vine_caress/on_start(mob/living/user, mob/living/target)
	. = ..()
	if(!.)
		return FALSE
	user.visible_message(span_warning("Flowering vines from [user] curl around [target]'s body and draw tight."))
	return TRUE

/datum/sex_action/maneater_vine_caress/on_perform(mob/living/user, mob/living/target)
	. = ..()
	if(can_show_action_message(user, target))
		user.visible_message(spanify_force("The vines of [user] [get_generic_force_adjective()] stroke and squeeze [target]."))
	playsound(target, 'sound/misc/mat/fingering.ogg', 30, TRUE, -2, ignore_walls = FALSE)
	perform_sex_action(target, user, 2, 0, 2)
	perform_sex_action(user, target, 0.5, 0, 0.5)

/datum/sex_action/maneater_vine_caress/on_finish(mob/living/user, mob/living/target)
	. = ..()
	user.visible_message(span_warning("The flowering vines of [user] loosen their hold on [target]."))

/proc/is_maneater_tendril(mob/living/tendril)
	return istype(tendril, /mob/living/simple_animal/hostile/retaliate/maneater_tendrils) \
		|| istype(tendril, /mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/maneater)
