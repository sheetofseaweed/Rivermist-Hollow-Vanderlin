/obj/machinery/tanningrack
	name = "drying rack"
	desc = "A drying rack for the preparation of food or curing of hides into leather, it can be moved with the help of a wooden stake."
	icon = 'icons/roguetown/misc/structure.dmi'
	icon_state = "dryrack"
	var/obj/item/natural/hide/hide
	/// Herbs currently spread across the rack.
	var/list/drying_herbs = list()
	/// World time of the previous drying update.
	var/last_drying_process
	/// Cached environment multiplier, refreshed infrequently while active.
	var/drying_modifier = 1
	var/drying_condition = "slow indoor air"
	var/next_drying_environment_check
	max_integrity = 200
	density = TRUE
	climbable = TRUE
	anchored = TRUE
	blade_dulling = DULLING_BASHCHOP
	destroy_sound = 'sound/combat/hits/onwood/destroyfurniture.ogg'
	attacked_sound = list('sound/combat/hits/onwood/woodimpact (1).ogg','sound/combat/hits/onwood/woodimpact (2).ogg')

/obj/machinery/tanningrack/examine(mob/user)
	. = ..()
	if(hide)
		. += span_warning("There is a piece of hide ready to be worked. I might need a knife for this.")
	if(length(drying_herbs))
		. += span_notice("[length(drying_herbs)] herb bundle[length(drying_herbs) == 1 ? " is" : "s are"] spread across the rack. The [drying_condition] governs their drying.")
	if(!anchored)
		. += span_warning("It is unanchored and able to be moved.")

/obj/machinery/tanningrack/attack_hand(mob/user, list/modifiers)
	if(hide)
		var/obj/item/I = hide
		hide = null
		I.loc = user.loc
		user.put_in_active_hand(I)
		update_appearance(UPDATE_OVERLAYS)
		return
	if(length(drying_herbs))
		var/obj/item/alch/herb/selected_herb = input(user, "Which herb do I take from the rack?", "Drying rack") as null|anything in drying_herbs
		if(!selected_herb || selected_herb.loc != src || !user.CanReach(src))
			return
		drying_herbs -= selected_herb
		selected_herb.forceMove(get_turf(src))
		user.put_in_active_hand(selected_herb)
		update_appearance(UPDATE_OVERLAYS)
		if(!length(drying_herbs))
			STOP_PROCESSING(SSobj, src)

/obj/machinery/tanningrack/attackby(obj/item/I, mob/living/user, list/modifiers)
	if(istype(I, /obj/item/alch/herb))
		var/obj/item/alch/herb/herb = I
		if(herb.dried)
			to_chat(user, span_warning("[herb] is already dry."))
			return
		if(length(drying_herbs) >= 12)
			to_chat(user, span_warning("There is no room to spread another herb on [src]."))
			return
		if(!user.transferItemToLoc(herb, src))
			to_chat(user, span_warning("[herb] is stuck to my hand!"))
			return
		drying_herbs += herb
		last_drying_process = world.time
		next_drying_environment_check = 0
		refresh_drying_environment()
		START_PROCESSING(SSobj, src)
		to_chat(user, span_notice("I spread [herb] across [src]."))
		update_appearance(UPDATE_OVERLAYS)
		return
	if(istype(I, /obj/item/natural/hide) && !istype(I, /obj/item/natural/hide/cured))
		if(!hide)
			I.forceMove(src)
			hide = I
			update_appearance(UPDATE_OVERLAYS)
			return
		else
			to_chat(user, span_warning("The rack is already occupied!"))
			return
	if((user.used_intent.type == /datum/intent/dagger/cut || user.used_intent.type == /datum/intent/sword/cut || user.used_intent.type == /datum/intent/axe/cut) && hide)
		if(anchored)
			var/skill_level = GET_MOB_SKILL_VALUE_OLD(user, /datum/attribute/skill/craft/tanning)
			var/work_time = (12 SECONDS - (skill_level * 15))
			var/pieces_to_spawn = rand(1, min(skill_level + 1, 6)) //Random number from 1 to skill level
			var/sound_played = FALSE
			to_chat(user, span_warning("I begin scraping the hide's skin..."))
			if(!do_after(user, work_time))
				return
			playsound(src,pick('sound/items/book_open.ogg','sound/items/book_page.ogg'), 100, FALSE)
			QDEL_NULL(hide)
			user.mind.add_sleep_experience(/datum/attribute/skill/craft/tanning, GET_MOB_ATTRIBUTE_VALUE(user, STAT_INTELLIGENCE) * 2) //these numbers may need some revision
			update_appearance(UPDATE_OVERLAYS)
			for(var/i = 0; i < pieces_to_spawn; i++)
				if(prob(skill_level + CLAMP((GET_MOB_ATTRIBUTE_VALUE(user, STAT_FORTUNE) - 10)*2,0,100)))
					new /obj/item/natural/cured/essence(get_turf(user))
					if(!sound_played)
						sound_played = TRUE
						to_chat(user, span_warning("Dendor provides..."))
						playsound(src,pick('sound/items/gem.ogg'), 100, FALSE)
				else
					new /obj/item/natural/hide/cured(get_turf(user))
			return
		else
			to_chat(user, span_warning("I need to anchor this down with a wooden stake before I can work this hide."))
			return
	if(istype(I, /obj/item/grown/log/tree/stake))
		if(anchored)
			anchored = FALSE
			to_chat(user, span_warning("The [src] can now be moved."))
		else
			anchored = TRUE
			to_chat(user, span_warning("You anchor [src]."))
		playsound(src,pick('sound/foley/woodclimb.ogg'), 100, TRUE)
		return
	. = ..()

/obj/machinery/tanningrack/process()
	if(!length(drying_herbs))
		return PROCESS_KILL
	if(world.time >= next_drying_environment_check)
		refresh_drying_environment()
	var/elapsed_time = max(world.time - last_drying_process, 0)
	last_drying_process = world.time
	if(!drying_modifier || !elapsed_time)
		return
	var/has_fresh_herbs = FALSE
	for(var/obj/item/alch/herb/herb as anything in drying_herbs)
		if(herb.dried)
			continue
		herb.drying_progress += elapsed_time * drying_modifier
		if(herb.drying_progress >= herb.drying_time)
			herb.finish_drying()
			visible_message(span_notice("[herb] finishes drying on [src]."))
		else
			has_fresh_herbs = TRUE
	if(!has_fresh_herbs)
		return PROCESS_KILL

/obj/machinery/tanningrack/proc/refresh_drying_environment()
	next_drying_environment_check = world.time + 30 SECONDS
	var/area/rack_area = get_area(src)
	if(rack_area?.outdoors)
		if(SSParticleWeather.runningWeather?.target_trait == PARTICLEWEATHER_RAIN)
			drying_modifier = 0
			drying_condition = "falling rain"
			return
		drying_modifier = 2
		drying_condition = "open air"
		return
	for(var/obj/machinery/light/nearby_fire as anything in GLOB.fires_list)
		if(QDELETED(nearby_fire) || nearby_fire.z != z)
			continue
		if(get_dist(src, nearby_fire) <= 2)
			drying_modifier = 1.67
			drying_condition = "nearby fire"
			return
	drying_modifier = 1
	drying_condition = "slow indoor air"

/obj/machinery/tanningrack/Destroy()
	STOP_PROCESSING(SSobj, src)
	var/turf/drop_turf = get_turf(src)
	for(var/obj/item/alch/herb/herb as anything in drying_herbs)
		herb.forceMove(drop_turf)
	drying_herbs = null
	if(hide)
		hide.forceMove(drop_turf)
		hide = null
	return ..()

/obj/machinery/tanningrack/update_overlays()
	. = ..()
	if(hide)
		var/mutable_appearance/hide_overlay = new /mutable_appearance(hide)
		hide_overlay.pixel_y = hide.base_pixel_x
		hide_overlay.pixel_x = hide.base_pixel_y
		. += hide_overlay
	var/herb_overlays = 0
	for(var/obj/item/alch/herb/herb as anything in drying_herbs)
		var/mutable_appearance/herb_overlay = new /mutable_appearance(herb)
		herb_overlay.pixel_x += (herb_overlays - 1) * 7
		herb_overlay.pixel_y += 5 + (herb_overlays % 2) * 4
		. += herb_overlay
		herb_overlays++
		if(herb_overlays >= 3)
			break
