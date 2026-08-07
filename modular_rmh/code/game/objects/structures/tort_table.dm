#define TORTURE_STAGE_PAINS_ONLY 1
#define TORTURE_STAGE_WAIT_DONE 2

/obj/structure/bondage/torture_table
	name = "torture table"
	desc = "A cruel table meant for restraining captives."
	icon = 'modular_rmh/icons/obj/structures/tort_table.dmi'
	icon_state = "tort_table"
	SET_BASE_PIXEL(-16, 0)
	layer = TABLE_LAYER
	plane = GAME_PLANE
	buckle_lying = 90
	max_integrity = 250
	debris = list(/obj/item/natural/wood/plank = 1)

	var/buckle_offset_y = 6

/obj/structure/bondage/torture_table/post_buckle_mob(mob/living/M)
	. = ..()
	M.set_mob_offsets("bed_buckle", _x = 0, _y = buckle_offset_y)

/obj/structure/bondage/torture_table/post_unbuckle_mob(mob/living/M)
	. = ..()
	M.reset_offsets("bed_buckle")



/obj/structure/bondage/torture_table/lever
	name = "torture table lever"
	desc = "A torture table fitted with a lever."
	icon_state = "tort_table_lever"
	SET_BASE_PIXEL(-16, 0)

	var/torture_active = FALSE
	var/list/torture_targets
	var/mob/living/last_operator
	var/lever_icon_state

	var/next_flavor_time = 0
	var/next_reaction_time = 0


/obj/structure/bondage/torture_table/lever/Initialize(mapload)
	. = ..()
	torture_targets = list()
	lever_icon_state = initial(icon_state)

/obj/structure/bondage/torture_table/lever/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/structure/bondage/torture_table/lever/attack_hand_secondary(mob/living/user, params)
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return
	if(!has_buckled_mobs())
		to_chat(user, span_warning("There's no one strapped onto [src]."))
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

	if(torture_active)
		var/choice = alert(user, "What do you wish to do with [src]?", "", "Unlatch", "Torture")
		switch(choice)
			if("Unlatch")
				torture_active = FALSE
				last_operator = user
				user.visible_message(
					span_notice("[user] releases the lever on [src]."),
					span_notice("I release the lever on [src]."))
				playsound(get_turf(src), 'sound/foley/lever.ogg', 80, TRUE)
				STOP_PROCESSING(SSobj, src)

			if("Torture")
				user.changeNext_move(CLICK_CD_MELEE)
				last_operator = user
				user.visible_message(
					span_warning("[user] pulls the lever on [src]!"),
					span_warning("I pull the lever on [src]!"))
				playsound(get_turf(src), 'sound/foley/lever.ogg', 80, TRUE)

				for(var/mob/living/M in buckled_mobs)
					if(isnull(torture_targets[M]))
						torture_targets[M] = TORTURE_STAGE_PAINS_ONLY
					var/arousal = rand(0)
					var/pain = rand(5,10)
					var/climax = rand(0)

					SEND_SIGNAL(M, COMSIG_SEX_GENERIC_ACTION, user, arousal, pain, climax, src)
				START_PROCESSING(SSobj, src)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

	user.changeNext_move(CLICK_CD_MELEE)
	last_operator = user
	torture_active = TRUE
	user.visible_message(
		span_warning("[user] latches the lever on [src]."),
		span_warning("I latch the lever on [src]."))
	playsound(get_turf(src), 'sound/foley/lever.ogg', 80, TRUE)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/structure/bondage/torture_table/lever/user_unbuckle_mob(mob/living/buckled_mob, mob/living/user)
	if(latched)
		if(isliving(user) && user.STASTR >= 18)
			if(do_after(user, 2.5 SECONDS))
				user.visible_message(span_warning("[user] breaks [src] open!"))
				unlock()
				latched = FALSE
				return ..()
		else
			to_chat(user, span_warning("Unlatch it first!"))
			return FALSE
	else
		return ..()
	return ..()

/obj/structure/bondage/torture_table/lever/post_buckle_mob(mob/living/M)
	. = ..()
	if(torture_active)
		torture_targets[M] = TORTURE_STAGE_PAINS_ONLY

/obj/structure/bondage/torture_table/lever/user_unbuckle_mob(mob/living/buckled_mob, mob/living/user)
	if(latched)
		if(isliving(user) && user.STASTR >= 18)
			if(do_after(user, 2.5 SECONDS))
				user.visible_message(span_warning("[user] breaks [src] open!"))
				unlock()
				latched = FALSE
				return ..()
		else
			to_chat(usr, span_warning("Unlatch it first!"))
			return FALSE
	else
		torture_active = FALSE
		icon_state = lever_icon_state
		STOP_PROCESSING(SSobj, src)
		return ..()
	torture_active = FALSE
	icon_state = lever_icon_state
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/structure/bondage/torture_table/lever/process(delta_time)
	if(!torture_active)
		if(!has_buckled_mobs())
			STOP_PROCESSING(SSobj, src)
		return

	var/any_active = FALSE
	for(var/mob/living/M in buckled_mobs)
		if(QDELETED(M))
			continue

		if(isnull(torture_targets[M]))
			torture_targets[M] = TORTURE_STAGE_PAINS_ONLY

		var/stage = torture_targets[M]
		if(stage == TORTURE_STAGE_PAINS_ONLY)
			any_active = TRUE
			var/pain_amt = rand(8,16)
			SEND_SIGNAL(M, COMSIG_SEX_GENERIC_ACTION, last_operator, 0, pain_amt, 0, src)
			torture_targets[M] = TORTURE_STAGE_WAIT_DONE


		else if(stage == TORTURE_STAGE_WAIT_DONE)
			any_active = TRUE
			if(prob(35))
				torture_targets[M] = TORTURE_STAGE_PAINS_ONLY

		if(world.time >= next_reaction_time)
			next_reaction_time = world.time + 20 SECONDS

			if(prob(60))
				M.visible_message(
					span_danger("[M] strains against the restraints as the [src] tightens painfully."),
					span_danger("Pain shoots through your body as the restraints pull tighter."))

			else if(prob(40))
				M.visible_message(
					span_warning("[M] jerks against the torture table."),
					span_warning("The restraints dig painfully into your limbs."))

		if(world.time >= next_flavor_time)
			next_flavor_time = world.time + 20 SECONDS
			if(prob(60))
				to_chat(M, span_danger("The torture table slowly stretches your body further."))

	if(!any_active)
		torture_active = FALSE
		icon_state = lever_icon_state
		STOP_PROCESSING(SSobj, src)

#undef TORTURE_STAGE_PAINS_ONLY
#undef TORTURE_STAGE_WAIT_DONE
