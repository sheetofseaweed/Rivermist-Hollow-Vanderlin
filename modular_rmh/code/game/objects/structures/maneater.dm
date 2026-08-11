/// Every adult maneater owns one folded stomach through this otherwise invisible living proxy.
/// Keeping the carrier as a mob lets the existing sex and captivity systems work without teaching
/// either system how to treat an anchored structure as an actor.
/mob/living/simple_animal/hostile/retaliate/maneater_tendrils
	name = "flowering maneater vines"
	desc = "The unseen feeding vines of a maneater."
	icon = 'modular_rmh/icons/mob/monster/maneater_tentacles.dmi'
	icon_state = "tentacle_medium"
	icon_living = "tentacle_medium"
	icon_dead = "tentacle_big_dead"
	faction = list("maneater")
	gender = PLURAL
	ai_controller = null
	move_resist = INFINITY
	density = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	invisibility = INVISIBILITY_ABSTRACT
	health = 100
	maxHealth = 100
	var/tmp/datum/weakref/maneater_ref

/mob/living/simple_animal/hostile/retaliate/maneater_tendrils/Initialize(mapload)
	. = ..()
	var/obj/item/organ/genitals/penis/ovipositor/ovipositor = ensure_typed_ovipositor(src, OVI_EGG_MANEATER)
	if(ovipositor)
		ovipositor.name = "seed-bearing vine"
		ovipositor.desc = "A flowering tendril adapted to implant soft, root-filled seeds."

/mob/living/simple_animal/hostile/retaliate/maneater_tendrils/proc/set_maneater_owner(obj/structure/flora/grass/maneater/real/maneater)
	maneater_ref = maneater ? WEAKREF(maneater) : null

/mob/living/simple_animal/hostile/retaliate/maneater_tendrils/proc/get_maneater_owner()
	var/obj/structure/flora/grass/maneater/real/maneater = maneater_ref?.resolve()
	if(maneater && !QDELETED(maneater))
		return maneater
	maneater_ref = null
	return null

/mob/living/simple_animal/hostile/retaliate/maneater_tendrils/visible_message(message, self_message, blind_message, vision_distance = DEFAULT_MESSAGE_RANGE, list/ignored_mobs, runechat_message = null, log_seen = NONE, log_seen_msg = null)
	var/obj/structure/flora/grass/maneater/real/maneater = get_maneater_owner()
	if(!maneater)
		return ..()
	// The proxy is abstract-invisible, which would suppress ordinary sex-action announcements.
	// Announce through the visible plant while retaining the vines' name in the prepared message.
	return maneater.visible_message(message, null, blind_message, vision_distance, ignored_mobs, runechat_message, log_seen, log_seen_msg)

/datum/map_template/pocket/defeat_captivity/maneater
	name = "Maneater Stomach"
	id = "pocket_defeat_captivity_maneater"
	mappath = "_maps/templates/pockets/kidnap_lairs/maneater_stomach.dmm"
	instance_type = /datum/pocket_dimension/defeat_captivity/maneater

/obj/structure/pocket_dimension_exit/maneater
	name = "living vine passage"
	desc = "A narrow opening between thick, slowly writhing vines. Push through it to escape the maneater."
	icon = 'modular_rmh/icons/obj/structures/maneater_stomach.dmi'
	icon_state = "vine_exit"

/obj/effect/landmark/pocket_dimension/exit/maneater
	name = "maneater stomach exit marker"
	exit_structure_type = /obj/structure/pocket_dimension_exit/maneater

/datum/defeat_captivity_profile/carrier/maneater
	stable_key = "maneater_stomach"
	display_name = "maneater stomach"
	template_type = /datum/map_template/pocket/defeat_captivity/maneater
	// The defeat knockout blocks this exit at first. Once it wears off, a captive who reaches the
	// opening through the guardian vines may climb back out at the parent plant.
	access_rule = DEFEAT_CAPTIVITY_ACCESS_RELEASED

/datum/defeat_captivity_profile/carrier/maneater/get_ejection_destination(datum/component/kidnap_captivity/captivity, datum/pocket_dimension/defeat_captivity/instance)
	var/mob/living/simple_animal/hostile/retaliate/maneater_tendrils/vines = captivity?.resolve_captor()
	var/obj/structure/flora/grass/maneater/real/maneater = vines?.get_maneater_owner()
	if(!maneater)
		return ..()

	var/mob/living/victim = captivity.parent
	var/list/valid_destinations = list()
	for(var/turf/open/candidate in orange(1, maneater))
		if(candidate.is_blocked_turf(TRUE, victim))
			continue
		if(locate(/obj/structure/flora/grass/maneater/real) in candidate)
			continue
		if(is_valid_ejection_turf(candidate, instance))
			valid_destinations += candidate
	if(length(valid_destinations))
		return pick(valid_destinations)
	return null

/datum/pocket_dimension/defeat_captivity/maneater

/datum/pocket_dimension/defeat_captivity/maneater/Destroy(force)
	// Pocket teardown normally ejects every living occupant. Stomach flora belongs to the pocket
	// instead, so remove it before the parent returns captives to the destroyed plant's turf.
	for(var/mob/occupant as anything in get_occupants())
		if(istype(occupant, /mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/maneater))
			qdel(occupant)
	return ..()

/datum/pocket_dimension/defeat_captivity/maneater/proc/ensure_stomach_guardians(atom/reference)
	var/guardian_count = 0
	for(var/mob/occupant as anything in get_occupants())
		if(istype(occupant, /mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/maneater))
			guardian_count++

	var/guardians_needed = 3 - guardian_count
	if(guardians_needed <= 0)
		return

	var/list/valid_turfs = list()
	for(var/turf/open/candidate as anything in RANGE_TURFS(3, reference))
		if(!contains_turf(candidate) || candidate.is_blocked_turf(TRUE))
			continue
		valid_turfs += candidate
	if(length(valid_turfs) < guardians_needed)
		for(var/turf/open/candidate as anything in affected_turfs)
			if((candidate in valid_turfs) || candidate.is_blocked_turf(TRUE))
				continue
			valid_turfs += candidate

	while(guardians_needed > 0 && length(valid_turfs))
		var/turf/spawn_turf = pick_n_take(valid_turfs)
		var/guardian_type = pickweight(list(
			/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/maneater/small = 3,
			/mob/living/simple_animal/hostile/retaliate/tentacle/ambusher/maneater = 1,
		))
		new guardian_type(spawn_turf)
		guardians_needed--

//safer maneater
/obj/structure/flora/grass/maneater
	name = "grass"
	desc = "Green and vivid. Was that a tendril?"
	icon = 'icons/roguetown/mob/monster/maneater.dmi'
	icon_state = "maneater-hidden"
	max_integrity = 5

/obj/structure/flora/grass/maneater/update_icon()
	. = ..()
	return

/obj/structure/flora/grass/maneater/real
	var/aggroed = 0
	max_integrity = 100
	integrity_failure = 0.15
	attacked_sound = list('sound/vo/mobs/plant/pain (1).ogg','sound/vo/mobs/plant/pain (2).ogg','sound/vo/mobs/plant/pain (3).ogg','sound/vo/mobs/plant/pain (4).ogg')
	var/list/eatablez = list(/obj/item/bodypart, /obj/item/organ, /obj/item/reagent_containers/food/snacks/meat)
	var/last_eat
	buckle_lying = FALSE
	buckle_prevents_pull = TRUE
	var/seednutrition = 0
	var/max_seednutrition = 100
	var/mob/planter = null
	/// Victim currently being prepared for swallowing.
	var/datum/weakref/horny_victim_ref
	/// Invisible living actor used for sex actions and as this plant's stomach carrier.
	var/mob/living/simple_animal/hostile/retaliate/maneater_tendrils/sex_proxy
	var/swallow_timer
	var/swallow_time = 30 SECONDS

/obj/structure/flora/grass/maneater/real/process()
	if(seednutrition >= max_seednutrition)
		produce_seed()
		seednutrition = 0
	if(world.time > aggroed + 30 SECONDS && !has_buckled_mobs())
		aggroed = 0
		update_icon()
		STOP_PROCESSING(SSobj, src)
		return TRUE

/obj/structure/flora/grass/maneater/real/atom_break(damage_flag)
	. = ..()
	reset_horny_capture(TRUE)
	unbuckle_all_mobs()
	if(contents.len)
		for(var/obj/item/eaten in contents)
			var/turf/target = get_ranged_target_turf(src, pick(GLOB.alldirs), 1)
			playsound(src,'sound/misc/maneaterspit.ogg', 100)
			eaten.forceMove(target)
			contents.Remove(eaten)
	STOP_PROCESSING(SSobj, src)

/obj/structure/flora/grass/maneater/real/Destroy()
	reset_horny_capture(TRUE)
	unbuckle_all_mobs()
	if(contents.len)
		for(var/obj/item/eaten in contents)
			var/turf/target = get_ranged_target_turf(src, pick(GLOB.alldirs), 1)
			playsound(src,'sound/misc/maneaterspit.ogg', 100)
			eaten.forceMove(target)
			contents.Remove(eaten)
	STOP_PROCESSING(SSobj, src)
	. = ..()

/obj/structure/flora/grass/maneater/real/Crossed(atom/movable/AM)
	. = ..()
	if(world.time <= last_eat + 5 SECONDS)
		return
	if(has_buckled_mobs())
		return

	if(!aggroed)
		START_PROCESSING(SSobj, src)
	aggroed = world.time
	update_icon()

	if(!isliving(AM))
		if(is_type_in_list(AM, eatablez))
			last_eat = world.time
			playsound(src,'sound/misc/eat.ogg', rand(30,60), TRUE)
			AM.forceMove(src)
			seednutrition += 10
		return

	var/mob/living/victim = AM
	if(victim == planter)
		return
	if(!victim.ambushable())
		return
	if(victim.m_intent == MOVE_INTENT_SNEAK)
		return

	if(!buckle_mob(victim, TRUE, check_loc = FALSE))
		return
	if(victim_allows_horny_capture(victim))
		begin_horny_swallow(victim)
	else
		begin_eat(victim)

/obj/structure/flora/grass/maneater/real/proc/victim_allows_horny_capture(mob/living/victim)
	if(!ishuman(victim) || victim.stat == DEAD || victim.status_flags & GODMODE)
		return FALSE
	if(HAS_TRAIT(victim, TRAIT_DEFEAT_REFUSE_ADVANCES))
		return FALSE
	if(!(victim.get_cached_horny_mob_family_flags() & HORNY_MOB_TYPE_MANEATERS))
		return FALSE
	// Maneaters are sexless plants, so opting into either ordinary horny-mob target sex enables them.
	return !!victim.get_cached_horny_mob_pref_flags()

/obj/structure/flora/grass/maneater/real/proc/get_sex_proxy()
	if(sex_proxy && !QDELETED(sex_proxy))
		sex_proxy.forceMove(get_turf(src))
		sex_proxy.set_maneater_owner(src)
		return sex_proxy
	sex_proxy = new(get_turf(src))
	sex_proxy.set_maneater_owner(src)
	return sex_proxy

/obj/structure/flora/grass/maneater/real/proc/begin_horny_swallow(mob/living/victim)
	if(!victim || QDELETED(victim) || victim.buckled != src)
		return FALSE
	reset_horny_capture()
	horny_victim_ref = WEAKREF(victim)

	var/mob/living/simple_animal/hostile/retaliate/maneater_tendrils/vines = get_sex_proxy()
	var/datum/sex_scene_controller/scene_controller = vines?.open_sex_scene(victim, FALSE)
	if(scene_controller)
		var/list/action_choices = list(
			/datum/sex_action/npc/npc_anal_sex/tentacle/maneater,
			/datum/sex_action/npc/npc_throat_sex/tentacle/maneater,
			/datum/sex_action/maneater_vine_caress,
		)
		if(victim.getorganslot(ORGAN_SLOT_VAGINA))
			action_choices += /datum/sex_action/npc/npc_vaginal_sex/tentacle/maneater
		if(victim.getorganslot(ORGAN_SLOT_PENIS))
			action_choices += /datum/sex_action/tentacle_jerk/maneater
		while(length(action_choices))
			var/action_type = pick_n_take(action_choices)
			if(scene_controller.try_start_action(action_type, "ai"))
				break
		scene_controller.set_current_force(rand(SEX_FORCE_MID, SEX_FORCE_MAX))
		scene_controller.set_current_speed(rand(SEX_SPEED_MID, SEX_SPEED_MAX))

	visible_message(span_warningbig("[src]'s flowering vines close around [victim] and begin drawing them toward its maw!"))
	to_chat(victim, span_userdanger("The maneater's vines tease and restrain you while its throat slowly opens beneath you. You have [DisplayTimeText(swallow_time)] to break free!"))
	swallow_timer = addtimer(CALLBACK(src, PROC_REF(complete_horny_swallow)), swallow_time, TIMER_STOPPABLE | TIMER_DELETE_ME)
	return TRUE

/obj/structure/flora/grass/maneater/real/proc/stop_horny_actions()
	if(!sex_proxy || QDELETED(sex_proxy))
		return
	sex_proxy.sex_scene?.stop_action()

/obj/structure/flora/grass/maneater/real/proc/reset_horny_capture(delete_proxy = FALSE)
	if(swallow_timer)
		deltimer(swallow_timer)
		swallow_timer = null
	horny_victim_ref = null
	stop_horny_actions()
	if(delete_proxy)
		QDEL_NULL(sex_proxy)

/obj/structure/flora/grass/maneater/real/proc/complete_horny_swallow()
	swallow_timer = null
	var/mob/living/victim = horny_victim_ref?.resolve()
	horny_victim_ref = null
	if(!victim || QDELETED(victim) || victim.buckled != src || victim.loc != loc || obj_broken)
		stop_horny_actions()
		return FALSE

	stop_horny_actions()
	visible_message(span_userdanger("[src]'s maw yawns open and swallows [victim] whole!"))
	unbuckle_mob(victim, TRUE)

	var/added_knockout = !victim.has_status_effect(/datum/status_effect/defeat_knockout)
	if(added_knockout)
		victim.apply_status_effect(/datum/status_effect/defeat_knockout)
	var/mob/living/simple_animal/hostile/retaliate/maneater_tendrils/vines = get_sex_proxy()
	if(!victim.kidnap_to_pocket(/datum/defeat_captivity_profile/carrier/maneater, vines, list("maneater"), "maneater_stomach"))
		if(added_knockout)
			victim.remove_status_effect(/datum/status_effect/defeat_knockout)
		maneater_spit_out(victim)
		return FALSE

	var/datum/component/kidnap_captivity/captivity = victim.GetComponent(/datum/component/kidnap_captivity)
	var/datum/pocket_dimension/defeat_captivity/maneater/stomach = captivity?.resolve_instance()
	stomach?.ensure_stomach_guardians(victim)
	last_eat = world.time
	to_chat(victim, span_userdanger("Warm, yielding walls close around you. Hungry green vines stir nearby."))
	return TRUE

/obj/structure/flora/grass/maneater/real/post_unbuckle_mob(mob/living/unbuckled_mob)
	. = ..()
	if(unbuckled_mob == horny_victim_ref?.resolve())
		reset_horny_capture()

/obj/structure/flora/grass/maneater/real/proc/begin_eat(mob/living/victim, chew_factor = 1)
	if(victim.loc != loc)
		return

	visible_message(span_warningbig("[src] begins to gnaw on [victim]!"))
	if(!do_after(victim, 2 SECONDS, progress = FALSE))
		visible_message(span_warning("[src] stops chewing on [victim]!"))
		return
	if(victim.getBruteLoss() > 20)
		maneater_spit_out(victim)

	playsound(src,'sound/misc/eat.ogg', rand(30,60), TRUE)
	if(!iscarbon(victim))
		victim.adjustBruteLoss(20)
	else
		var/zone = pick(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
		var/obj/item/bodypart/limb = victim.get_bodypart(zone)
		if(!limb)
			begin_eat(victim)
		victim.flash_fullscreen("redflash3")
		playsound(src.loc, list('sound/vo/mobs/plant/attack (1).ogg','sound/vo/mobs/plant/attack (2).ogg','sound/vo/mobs/plant/attack (3).ogg','sound/vo/mobs/plant/attack (4).ogg'), 100, FALSE, -1)
		if(prob(chew_factor * 15))
			if(limb.receive_damage(25))
				seednutrition += 25
				//maneater_spit_out(victim)
		else
			victim.run_armor_check(zone, BCLASS_CUT, 20)

	if(victim.stat == DEAD)
		if(iscarbon(victim))
			var/mob/living/carbon/c_victim = victim
			if(c_victim.mind || c_victim.last_mind)
				c_victim.gib()
				seednutrition += 50
				return
		else
			if(victim.mind)
				victim.gib()
				seednutrition += 50
				return

		maneater_spit_out(victim)

	begin_eat(victim, chew_factor * 2)

/obj/structure/flora/grass/maneater/real/proc/maneater_spit_out(mob/living/C)
	if(!C)
		return
	if(!isliving(C))
		return
	if(C == horny_victim_ref?.resolve())
		reset_horny_capture()
	visible_message(span_danger("[src] spits out [C]!"))
	if(C.buckled == src)
		unbuckle_mob(C, TRUE)
	var/turf/target = get_ranged_target_turf(src, pick(GLOB.alldirs), 3)
	C.throw_at(target, 3, 2)
	playsound(src,'sound/misc/maneaterspit.ogg', 100)
	return TRUE

/obj/structure/flora/grass/maneater/real/update_icon()
	. = ..()
	if(obj_broken)
		name = "MANEATER"
		desc = "This cunning creature is thankfully defeated."
		icon_state = "maneater-dead"
		return
	if(aggroed)
		name = "MANEATER"
		icon_state = "maneater"
	else
		name = "grass"
		icon_state = "maneater-hidden"

/obj/structure/flora/grass/maneater/real/user_unbuckle_mob(mob/living/M, mob/user, break_factor = 1)
	if(obj_broken)
		. = ..()
		return
	if(!isliving(user))
		return

	var/mob/living/L = user
	var/time2mount = CLAMP((L.STASTR * 2 * break_factor), 1, 99)
	if(istype(src, /obj/structure/flora/grass/maneater/real/juvenile))
		time2mount *= 2
	user.changeNext_move(CLICK_CD_FAST, override = TRUE)
	if(user != M)
		user.visible_message(span_warning("[user] tries to pull [M] free of [src]!"))
	else
		user.visible_message(span_warning("[user] tries to break free of [src]!"))

	if(!do_after(user, 1.5 SECONDS))
		user.visible_message(span_warning("[M] stops struggling!"))
		return
	if(!prob(time2mount))
		user_unbuckle_mob(M, user, break_factor * 1.5)
	. = ..()

/obj/structure/flora/grass/maneater/real/user_buckle_mob(mob/living/M, mob/living/user) //Don't want them getting put on the rack other than by spiking
	return

/obj/structure/flora/grass/maneater/real/attackby(obj/item/W, mob/user, params)
	. = ..()
	aggroed = world.time
	update_icon()


//JUVENILE MANEATER

/obj/structure/flora/grass/maneater/real/juvenile
	name = "juvenile maneater"
	desc = "Green and vivid. This one seems smaller than usual."
	icon = 'icons/roguetown/mob/monster/maneater.dmi'
	icon_state = "maneater-hidden"
	max_integrity = 50
	seednutrition = 0
	max_seednutrition = 50
	var/growth_stage = 1
	var/max_growth_stage = 3
	var/growth_time = 20 MINUTES


/obj/structure/flora/grass/maneater/real/juvenile/Initialize()
	. = ..()
	transform = transform.Scale(0.5, 0.5)  // Start at half size
	addtimer(CALLBACK(src, .proc/try_grow), growth_time)

/obj/structure/flora/grass/maneater/real/juvenile/Crossed(atom/movable/AM)
	. = ..()
	if(world.time <= last_eat + 5 SECONDS)
		return
	if(has_buckled_mobs())
		return
	if(isliving(AM))
		return

	if(is_type_in_list(AM, eatablez))
		last_eat = world.time
		playsound(src,'sound/misc/eat.ogg', rand(30,60), TRUE)
		AM.forceMove(src)
		seednutrition += 10

	return

/obj/structure/flora/grass/maneater/real/juvenile/proc/try_grow()
	if(growth_stage < max_growth_stage)
		growth_stage++
		// We end up at 1.0 size by final stage
		transform = transform.Scale(1.26, 1.26)
		visible_message(span_warning("[src] grows bigger!"))
		playsound(loc, list('sound/vo/mobs/plant/attack (1).ogg','sound/vo/mobs/plant/attack (2).ogg','sound/vo/mobs/plant/attack (3).ogg','sound/vo/mobs/plant/attack (4).ogg'), 100, FALSE, -1)
		addtimer(CALLBACK(src, .proc/try_grow), growth_time)
		return

	// Replace with adult form
	visible_message(span_danger("[src] reaches full maturity!"))
	var/turf/T = get_turf(src)
	var/obj/structure/flora/grass/maneater/real/myboy = new(T)
	myboy.planter = planter
	qdel(src)

/obj/structure/flora/grass/maneater/real/juvenile/update_icon()
	. = ..()
	name = "juvenile " + name


//MANEATER SEEDS

/obj/item/maneaterseed
	name = "maneater seed"
	desc = "A seed from a maneater. It looks like it could grow into something dangerous if planted in green grass or dirt."
	icon = 'icons/roguetown/mob/monster/maneater.dmi'
	icon_state = "maneater-seed"
	max_integrity = 5
	sellprice = 30

/obj/item/maneaterseed/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	var/turf/T = get_turf(target)
	if(can_grow_at(T, user))
		if(!proximity_flag)
			return
		user.visible_message(span_notice("[user] begins planting a maneater seed."), \
				span_notice("I begin planting the maneater seed."))
		if(do_after(user, 10 SECONDS))
			var/obj/structure/flora/grass/maneater/real/juvenile/myboy = new(T)
			myboy.planter = user
			user.visible_message(span_notice("[user] plants a maneater seed."), \
				span_notice("I plant the maneater seed."))
			qdel(src)
			message_admins("[user]/([user.ckey]) plants a maneater seed at [ADMIN_VERBOSEJMP(T)]")
			return
	. = ..()

/obj/item/maneaterseed/proc/can_grow_at(turf/target, mob/user)
	if(!istype(target, /turf/open/floor/dirt) && !istype(target, /turf/open/floor/grass))
		return FALSE
	for(var/obj/structure/flora/grass/maneater/maneater in target)
		if(user)
			to_chat(user, span_warning("The maneater plants need more space between them to grow."))
		return FALSE
	for(var/turf/adjacent in orange(2, target))
		for(var/obj/structure/flora/grass/maneater/maneater in adjacent)
			if(user)
				to_chat(user, span_warning("The maneater plants need more space between them to grow."))
			return FALSE
	for(var/obj/effect/decal/uneven_ground in target) // Prevent planting on mapped cobble decals, etc.
		if(user)
			to_chat(user, span_warning("The ground is too uneven to plant a maneater seed here."))
		return FALSE
	return TRUE

/// Eggs laid by stomach vines hatch as damp seedlings. On natural soil they take root by themselves;
/// elsewhere they remain portable and can be planted exactly like an ordinary maneater seed.
/obj/item/maneaterseed/seedling
	name = "maneater seedling"
	desc = "A newly hatched tangle of hungry roots. It will take root on green grass or dirt."

/obj/item/maneaterseed/seedling/Initialize(mapload)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(try_take_root)), 2 SECONDS, TIMER_DELETE_ME)

/obj/item/maneaterseed/seedling/proc/try_take_root()
	var/turf/rooting_turf = get_turf(src)
	if(loc != rooting_turf || !can_grow_at(rooting_turf))
		return
	visible_message(span_warning("[src] splits open and drives pale roots into [rooting_turf]!"))
	new /obj/structure/flora/grass/maneater/real/juvenile(rooting_turf)
	qdel(src)

/obj/structure/flora/grass/maneater/real/proc/produce_seed()
	visible_message(span_warning("[src] spits out a seed!"))
	var/turf/target = get_ranged_target_turf(src, pick(GLOB.alldirs), rand(1,3))
	var/obj/item/maneaterseed/S = new(get_turf(src))
	S.throw_at(target,3,2)
	playsound(src,'sound/misc/maneaterspit.ogg', 100)
