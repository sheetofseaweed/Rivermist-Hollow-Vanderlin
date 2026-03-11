/mob/living/carbon/human/verb/open_interact_panel()
	set name = "Open ERP Panel"
	set category = "IC"

	var/list/possible_mobs = list()
	if(istype(loc, /obj/structure/closet))
		var/obj/structure/closet/hiding_spot = loc
		for(var/mob/living/L in hiding_spot.contents)
			if(L.stat == DEAD)
				continue
			possible_mobs += L
	else
		for(var/mob/living/L in view(1, src))
			if(L.stat == DEAD)
				continue
			possible_mobs += L


	if(LAZYLEN(possible_mobs))
		var/mob/living/choice = browser_input_list(src, "Who do you wish to interact with?", "Sex Session", possible_mobs, null)
		if(choice)
			if(!start_sex_session(choice))
				to_chat(src, span_info("Could not start the session with [choice]!"))
