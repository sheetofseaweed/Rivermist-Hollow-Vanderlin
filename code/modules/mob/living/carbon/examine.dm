/mob/living/carbon/get_examine_name(mob/user, use_article=FALSE)
	if(IsAdminGhost(user))
		return ..()
	return get_visible_name(html_tags = list("EM"))


/mob/living/carbon/examine(mob/user)
	. = list()

	var/list/P
	if(user == src)
		P = list(
			THEY = "I",
			THEM = "me",
			THEIR = "my",
			HAVE = "have",
			ARE = "am",
			THEYRE = "I am",
			THEYVE = "I have"
		)
	else
		P = list(
			THEY = p_they(TRUE),
			THEM = p_them(),
			THEIR = p_their(),
			HAVE = p_have(),
			ARE = p_are(),
			THEYRE = "[p_they(TRUE)] [p_are()]",
			THEYVE = "[p_they(TRUE)] [p_have()]",
		)

	var/alist/examine_sections = get_examine_list(user, P)

	//The wrap-up. Anything else we need to do before we start spanning things, we do it here.
	//Note that this also sends a copy of our subjective pronouns.
	SEND_SIGNAL(src, COMSIG_PARENT_EXAMINE, user, examine_sections, P)


	// round any decimal sections up to the rest of the group
	var/list/rounded_sections = list()
	for(var/section_index,section in examine_sections)
		if(!length(section))
			continue
		var/rounded_index = floor(section_index)
		LISTASSERTLEN(rounded_sections, rounded_index, list())
		LAZYADDASSOC(rounded_sections, rounded_index, section)

	for(var/i = 1, i <= length(rounded_sections), i++)
		var/list/section = rounded_sections[i]
		if(!length(section))
			continue
		var/join_marker
		switch(i)
			if(EXAMINE_SECT_SPECIES)
				join_marker = " "
			else
				join_marker = "\n"
		var/joined_section = section.Join(join_marker)
		// post modifiers
		switch(i)
			if(EXAMINE_SECT_WARNING)
				joined_section = span_tinywarning(joined_section)
			if(EXAMINE_SECT_GEAR)
				joined_section = "<hr>[joined_section]<hr>"
		. += joined_section


/**
 * The contents of the examine box.
 * user = the examiner
 * P = the list of pronouns with a defined key, like THEY
 **/
/mob/living/carbon/proc/get_examine_list(mob/user, list/P)
	. = alist()
	// Our name
	LAZYADDASSOCLIST(., EXAMINE_SECT_NAME, span_larger("[get_examine_string(user, TRUE)]."))
	// Social context check.
	LAZYADDASSOC(., EXAMINE_SECT_SOCIALCONTEXT+0.5, get_examine_social(user, P, .))
	// Our face
	var/can_see_face = IsAdminGhost(user) || is_human_part_visible(src, HIDEFACE)
	LAZYADDASSOC(., EXAMINE_SECT_FACE+0.5, can_see_face ? get_examine_face(user, P, .) : get_examine_noface(user, P, .))
	// Our gear
	LAZYADDASSOC(., EXAMINE_SECT_GEAR+0.5, get_examine_gear(user, P, .))
	/// Our physical aspects
	LAZYADDASSOC(., EXAMINE_SECT_BODY+0.5, get_examine_body(user, P, .))
	/// Warnings
	LAZYADDASSOC(., EXAMINE_SECT_WARNING+0.5, get_examine_warnings(user, P, .))
	/// Our health
	LAZYADDASSOC(., EXAMINE_SECT_HEALTH+0.5, get_examine_health(user, P, .))
	// Antag stuff. This throws itself wherever it feels like.
	for(var/datum/antagonist/antag_datum in user.mind?.antag_datums)
		antag_datum.examine_target(user, src, P, .)

// Details we will only surmise by seeing their face
/mob/living/carbon/proc/get_examine_face(mob/user, list/P, list/examine_list)
	var/self_inspect = user == src
	var/pl = self_inspect ? "" : p_s()
	//var/mob/dead/observer/O = isobserver(user) ? user : null
	//var/mob/living/L = isliving(user) ? user : null
	//var/mob/living/carbon/C = iscarbon(user) ? user : null
	//var/mob/living/carbon/human/H = ishuman(user) ? user : null

	. = list()

	// Ooc lang
	var/player_language = client?.prefs?.read_preference(/datum/preference/text/player_language)
	if(player_language) //should be tied to known persons but can't do that until there is a way to recognise new people
		. += span_tiny("OOC: This player speaks [player_language].")

	// Lord's title
	if(GLOB.lord_titles[real_name]) //should be tied to known persons but can't do that until there is a way to recognise new people
		. += span_notice("[P[THEYVE]] been granted the title of \"[GLOB.lord_titles[real_name]]\".")

	// Fish
	if(HAS_TRAIT(src, TRAIT_FISHFACE))
		if(self_inspect) // we fish
			user.add_stress(/datum/stress_event/self_fishface)
		else if(HAS_TRAIT(user, TRAIT_FISHFACE)) // we also fish
			user.add_stress(/datum/stress_event/fellow_fishface)
		else
			user.add_stress(/datum/stress_event/fishface)
			. += span_necrosis("A hideous Triton.")
	// Beauty/Ugly
	else //if youre a fish face you cant cancel it out
		var/ugly = HAS_ANY_OF_TRAITS(src, list(TRAIT_UGLY, TRAIT_ABOMINATION, TRAIT_DISFIGURED)) //todo: ABOMINATION descriptor
		var/beautiful = HAS_TRAIT(src, TRAIT_BEAUTIFUL)
		if(ugly ^ beautiful)
			if(beautiful)
				var/beauty_desc = "gorgeous"
				if(src.pronouns == SHE_HER)
					beauty_desc = "beautiful"
				else if(src.pronouns == HE_HIM)
					beauty_desc = "handsome"
				. += span_rose("[P[THEYRE]] [beauty_desc]!")
				user.add_stress(self_inspect ? /datum/stress_event/beautiful_self : /datum/stress_event/beautiful)
			else // you can only be ugly then, huh.
				. += span_necrosis("[P[THEYRE]] hideous!")
				user.add_stress(self_inspect ? /datum/stress_event/ugly_self : /datum/stress_event/ugly)

	if(HAS_TRAIT(src, TRAIT_ALLURE))
		. += span_love(span_bold("[P[THEYVE]] quite a tempting appeal"))
		user.add_stress(self_inspect ? /datum/stress_event/allure_self : /datum/stress_event/allure)

	// Self inspections
	if(!self_inspect)
		//Old Party
		if(HAS_TRAIT(src, TRAIT_OLDPARTY) && HAS_TRAIT(user, TRAIT_OLDPARTY))
			. += span_nicegreen("Ahh... my old friend!")
			user.add_stress(/datum/stress_event/saw_old_party)
		// Intolerant
		else if(!HAS_TRAIT(user, TRAIT_TOLERANT)) // friendship is kinda like tolerance after all
			if(!isdarkelf(user) && isdarkelf(src))
				user.add_stress(/datum/stress_event/delf)
			if(!istiefling(user) && istiefling(src))
				user.add_stress(/datum/stress_event/tieb)
			if(!ishalforc(user) && ishalforc(src))
				user.add_stress(/datum/stress_event/horc)

		// Excommunications
		if(real_name in GLOB.excommunicated_players)
			. += span_redtextbig("GOD-FORSAKEN!")
		if(real_name in GLOB.heretical_players)
			. += span_redtextbig("HERETIC! SHAME!")

		// Outlaws
		if(HAS_CHARACTER_TRAIT(user, TRAIT_KNOWBANDITS) && (real_name in GLOB.outlawed_players))
			. += span_boldred(mind?.special_role == "Bandit" ? "BANDIT!" : "OUTLAW!")

		// Court Agents
		var/list/known_frumentarii = user.mind?.cached_frumentarii
		if(name in known_frumentarii)
			if(known_frumentarii[name])
				. += span_smallgreen("[P[THEYRE]] an agent of the court.")
			else
				. += span_redtextsmall("[P[THEYRE]] an ex-agent of the court.")

		// Faceless
		if(HAS_TRAIT(src, TRAIT_FACELESS))
			. += span_userdanger("NO FACE!!")
		// Foreigner
		if(HAS_TRAIT(src, TRAIT_FOREIGNER) && !HAS_TRAIT(user, TRAIT_FOREIGNER))
			. += span_tinywarning("A foreigner.")
			user.add_stress(/datum/stress_event/para/foreigner)
		// Thuild
		if(HAS_TRAIT(src, TRAIT_THIEVESGUILD) && HAS_TRAIT(user, TRAIT_THIEVESGUILD))
			. += span_smallgreen("A member of the Thieves' Guild.")


		// Cabal
		if(HAS_TRAIT(user, TRAIT_CABAL) && (istype(patron, /datum/patron/inhumen/zizo) || HAS_TRAIT(src, TRAIT_CABAL)))
			. += span_purple("A fellow seeker of Her ascension.")
		// The disgusing inquistion section
		var/they_pur = HAS_TRAIT(user, TRAIT_PURITAN)
		var/they_inquis = HAS_TRAIT(user, TRAIT_INQUISITION)
		var/im_pur = HAS_TRAIT(src, TRAIT_PURITAN)
		var/im_inquis = HAS_TRAIT(src, TRAIT_INQUISITION)
		var/inquis_msg
		if(they_inquis && im_inquis)
			inquis_msg = "A Practical of our Inquisitorial Sect."
		if(they_inquis && im_pur)
			inquis_msg = "The Lorde-Inquisitor of our Inquisitorial Sect."
		if(they_pur && im_inquis)
			inquis_msg = "Subordinate to me in the Inquisitorial Sect."
		if(they_pur && im_pur)
			inquis_msg = "The Lord-Inquisitor of the Sect sent here. That should be me though..."
		if(inquis_msg)
			. += span_silver(inquis_msg)


		// Disgust
		var/disgust_msg
		switch(disgust)
			if(DISGUST_LEVEL_SLIGHTLYGROSS to DISGUST_LEVEL_GROSS)
				disgust_msg = "[P[THEY]] look[pl] a little disgusted."
			if(DISGUST_LEVEL_GROSS to DISGUST_LEVEL_VERYGROSS)
				disgust_msg = span_warning("[P[THEY]] look[pl] disgusted.")
			if(DISGUST_LEVEL_VERYGROSS to DISGUST_LEVEL_DISGUSTED)
				disgust_msg = span_necrosis("[P[THEY]] look[pl] really disgusted.")
			if(DISGUST_LEVEL_DISGUSTED to INFINITY)
				disgust_msg = span_necrosis(html_tag("B", "[P[THEY]] look[pl] extremely disgusted."))
		if(disgust_msg && (HAS_TRAIT(user, TRAIT_EMPATH) || disgust >= DISGUST_LEVEL_DISGUSTED))
			. += disgust_msg

		// Stress
		var/stress_msg
		switch(stress)
			if(15 to INFINITY)
				stress_msg = span_boldred("[P[THEYRE]] having a panic attack.")
			if(STRESS_INSANE to 15)
				stress_msg = span_red("[P[THEYRE]] twitching at the eyes.")
			if(STRESS_VBAD to STRESS_INSANE)
				stress_msg = span_warning("[P[THEY]] look[pl] really stressed.")
			if(STRESS_BAD to STRESS_VBAD)
				stress_msg = span_tinywarning("[P[THEY]] look[pl] stressed.")
			if(STRESS_NEUTRAL to STRESS_BAD)
				stress_msg = span_tinynotice("[P[THEY]] look[pl] a little stressed.")
		if(stress_msg && (HAS_TRAIT(user, TRAIT_EMPATH) || stress >= STRESS_INSANE))
			. += stress_msg

		//Drunkenness
		var/drunk_msg
		switch(drunkenness)
			if(3 to 11)
				drunk_msg = span_tinynoticeital("[P[THEYRE]] tipsy.")
			if(11.01 to 21)
				drunk_msg = span_tinynoticeital("[P[THEY]] look[pl] a little drunk.")
			if(21.01 to 41) //.01s are used in case drunkenness ends up to be a small decimal
				drunk_msg = span_tinynotice("[P[THEYRE]] visibly drunk.")
			if(41.01 to 51)
				drunk_msg = span_smallnotice("[P[THEYRE]] drunk, flushed, and [P[THEIR]] breath smells of ale.")
			if(51.01 to 61)
				drunk_msg = span_notice("[P[THEY]] look[pl] very flushed, with breath reeking of ale.")
			if(61.01 to 91)
				drunk_msg = span_boldnotice("[P[THEYRE]] a drunken mess.")
			if(91.01 to INFINITY)
				drunk_msg = span_bignotice(html_tag("B", "[P[THEYRE]] completely shitfaced."))
		if(drunk_msg)
			. += drunk_msg
		// Closed eyes
		if(eyesclosed)
			. += "[capitalize(P[THEIR])] eyes are closed."

/mob/living/carbon/proc/get_examine_noface(mob/user, list/P, list/examine_list)
	. = list()
	if(stat < UNCONSCIOUS && isliving(user))
		var/mob/living/living_user = user
		if(living_user.has_quirk(/datum/quirk/vice/wanted) && user != src)
			user.add_stress(/datum/stress_event/hunted)


/mob/living/carbon/proc/get_examine_gear(mob/user, list/P, list/examine_list)
	. = list()
	var/list/unobscured = get_unobscured_items(FALSE)
	for(var/obj/item/I as anything in unobscured)
		// These are part of the wearer's body, despite using clothing slots internally.
		if(istype(I, /obj/item/clothing/armor/regenerating/skin) || istype(I, /obj/item/clothing/shirt/undershirt/easttats))
			continue
		var/slot_title = null
		switch(unobscured[I]) // this could probably be abstracted into its own proc at some point
			if(ITEM_SLOT_SHIRT, ITEM_SLOT_ARMOR, ITEM_SLOT_PANTS, ITEM_SLOT_CLOAK, ITEM_SLOT_SHOES)
				slot_title = " on"
			if(ITEM_SLOT_HEAD)
				slot_title = " on [P[THEIR]] head"
			if(ITEM_SLOT_MASK)
				slot_title = " on [P[THEIR]] face"
			if(ITEM_SLOT_MOUTH)
				slot_title = " in [P[THEIR]] mouth"
			if(ITEM_SLOT_NECK)
				slot_title = " around [P[THEIR]] neck"
			if(ITEM_SLOT_BACK_L)
				slot_title = " on [P[THEIR]] left shoulder"
			if(ITEM_SLOT_BACK_R)
				slot_title = " on [P[THEIR]] right shoulder"
			if(ITEM_SLOT_WRISTS)
				slot_title = " on [P[THEIR]] wrist[I.gender == PLURAL ? "s" : ""]"
			if(ITEM_SLOT_GLOVES)
				slot_title = " on [P[THEIR]] hand[I.gender == PLURAL ? "s" : ""]"
			if(ITEM_SLOT_RING)
				slot_title = " on [P[THEIR]] finger[I.gender == PLURAL ? "s" : ""]"
			if(ITEM_SLOT_BELT)
				slot_title = " around [P[THEIR]] waist"
			if(ITEM_SLOT_BELT_L)
				slot_title = " on [P[THEIR]] left side"
			if(ITEM_SLOT_BELT_R)
				slot_title = " on [P[THEIR]] right side"
			if(ITEM_SLOT_ARMSLEEVES)
				. += " on [P[THEIR]] arms."
			if(ITEM_SLOT_GARTER)
				. += " on [P[THEIR]] waist."
			if(ITEM_SLOT_CHOKER)
				. += " around [P[THEIR]] neck."
			if(ITEM_SLOT_SOCKS)
				. += " on [P[THEIR]] legs."
			if(ITEM_SLOT_EARRING_L)
				. += " in [P[THEIR]] left ear."
			if(ITEM_SLOT_EARRING_R)
				. += " in [P[THEIR]] right ear."
		// Worn armour gets a hover tooltip with its protection summary.
		var/examine_phrase = I.get_examine_string(user, use_examine_name = TRUE)
		if(istype(I, /obj/item/clothing))
			var/obj/item/clothing/worn_clothing = I
			var/armor_tip = worn_clothing.get_brief_armor_tip()
			if(armor_tip)
				examine_phrase = span_tooltip_html(armor_tip, examine_phrase)
		. += "[I.get_examine_icon(user)] - [P[THEYVE]] [examine_phrase][slot_title]."
	for(var/obj/item/I in held_items)
		if(I.item_flags & ABSTRACT)
			continue
		var/wielding = I.is_wielded()
		. += "[I.get_examine_icon(user)] - [P[THEYRE]] [wielding ? "wielding" : "holding"] [I.get_examine_string(user, use_examine_name = TRUE)] in [P[THEIR]] [wielding ? "hands" : get_held_index_name(get_held_index_of_item(I))]."


/// Things that are physical but do not need to see your face to establish.
/// Since these tend to vary in location items must be added to the list manually.
/mob/living/carbon/proc/get_examine_body(mob/user, list/P, list/examine_list)
	var/self_inspect = user == src
	var/pl = self_inspect ? "" : p_s()
	//RMH EDITED START - Клеймо: brands and handprints report here, not in the face
	//pass, so a mask cannot hide a brand that sits on a bare arm.
	var/list/brand_lines = get_brand_body_lines(user, P)
	//RMH EDITED END
	//var/mob/dead/observer/O = isobserver(user) ? user : null
	var/mob/living/L = isliving(user) ? user : null
	//var/mob/living/carbon/C = iscarbon(user) ? user : null
	//var/mob/living/carbon/human/H = ishuman(user) ? user : null

	. = list()
	//RMH EDITED START - Клеймо
	if(length(brand_lines))
		. += brand_lines
	//RMH EDITED END

	// Species, just below the name
	var/datum/species/species = dna?.species
	if(species)
		var/species_name = "\improper [user.mind?.has_antag_datum(/datum/antagonist/maniac) ? "disgusting pig" : species.name]"
		LAZYADDASSOCLIST(examine_list, EXAMINE_SECT_SPECIES, "[P[THEYRE]] \a [species_name].")

	// Maniac, higher up than others
	if(HAS_TRAIT(src, TRAIT_MANIAC_AWOKEN))
		LAZYADDASSOCLIST(examine_list, EXAMINE_SECT_FACE, span_big(span_phobia("THE WORLD TWISTS! MANIAC!")))
	// Leper
	if(HAS_TRAIT(src, TRAIT_LEPROSY))
		. += span_necrosis("A LEPER...")
	// Fat
	if(HAS_TRAIT(src, TRAIT_FAT))
		. += span_boldnotice("[P[THEYRE]] obese!")
	// Pricing
	if(HAS_TRAIT(user, TRAIT_SEEPRICES) && sellprice)
		. += span_tinynoticeital("[P[THEYRE]] worth around [sellprice] mammon\s.")
	if(HAS_TRAIT(user, TRAIT_MATTHIOS_EYES))
		var/atom/item = get_most_expensive()
		if(item)
			. += span_tinynoticeital("You get the feeling [P[THEIR]] most valuable possession is [item.get_examine_name(user)].")

	// Fluid coats on bare skin, then a creampie
	var/datum/component/fluid_coated/coated = GetComponent(/datum/component/fluid_coated)
	if(coated)
		. += coated.get_examine_lines(user, P)
	var/datum/status_effect/facial/internal/creampie = null
	if(isobserver(user) || get_location_accessible(src, BODY_ZONE_PRECISE_GROIN, skipundies = TRUE))
		creampie = has_status_effect(/datum/status_effect/facial/internal)
	if(creampie)
		var/wet_or_dry = !creampie?.has_dried_up ? "dripping out cum" : "stained with dried cum"
		if(user != src && isliving(user))
			. += (L.STAPER >= 8 && L.STAINT >= 5) ? span_info("[P[THEYRE]] [wet_or_dry]!") : span_warning("[P[THEYRE]] letting out some glossy stuff!")
		else
			. += span_info("[P[THEYRE]] [wet_or_dry]!")


	/// Stat comparing
	if(!self_inspect && L && user.cmode)
		var/final_str = STASTR
		var/final_con = STACON
		var/final_spd = STASPD
		if(HAS_TRAIT(src, TRAIT_DECEIVING_MEEKNESS))
			final_str = 10
			final_con = 10
			final_spd = 10

		var/list/comp_msg = list()
		var/str_msg
		switch(final_str - L.STASTR)
			if(5 to INFINITY)
				str_msg = span_bold("[P[THEY]] look[pl] much stronger than me.")
				user.add_stress(/datum/stress_event/para/str)
			if(1 to 5)
				str_msg = "[P[THEY]] look[pl] stronger than me."
				user.add_stress(/datum/stress_event/para/str)
			if(0)
				str_msg = "[P[THEY]] look[pl] about as strong as me."
			if(-5 to -1)
				str_msg = "[P[THEY]] look[pl] weaker than me."
			else
				str_msg =  span_bold("[P[THEY]] look[pl] much weaker than me.")
		if(str_msg)
			comp_msg += str_msg

		if(L.STAPER >= 12)
			var/con_msg
			switch(final_con - L.STACON)
				if(5 to INFINITY)
					con_msg = span_bold("[P[THEY]] look[pl] much more bulky than me.")
				if(1 to 5)
					con_msg = "[P[THEY]] look[pl] more bulky than me."
				if(0)
					con_msg = "[P[THEY]] look[pl] about as bulky as me."
				if(-5 to -1)
					con_msg = "[P[THEY]] look[pl] frailer than me."
				else
					con_msg =  span_bold("[P[THEY]] look[pl] much frailer than me.")
			if(con_msg)
				comp_msg += con_msg

			var/spd_msg
			switch(final_spd - L.STASPD)
				if(5 to INFINITY)
					spd_msg = span_bold("[P[THEY]] look[pl] much quicker than me.")
				if(1 to 5)
					spd_msg = "[P[THEY]] look[pl] quicker than me."
				if(0)
					spd_msg = "[P[THEY]] look[pl] about as quick as me."
				if(-5 to -1)
					spd_msg = "[P[THEY]] look[pl] slower than me."
				else
					spd_msg =  span_bold("[P[THEY]] look[pl] much slower than me.")
			if(spd_msg)
				comp_msg += spd_msg
		if(length(comp_msg))
			. += span_warning(comp_msg.Join(" "))


/// General miscellaneous stuff that's typically good to know about someone.
/mob/living/carbon/proc/get_examine_warnings(mob/user, list/P, list/examine_list)
	//var/self_inspect = user == src
	//var/pl = self_inspect ? "" : p_s()
	//var/mob/dead/observer/O = isobserver(user) ? user : null
	var/mob/living/L = isliving(user) ? user : null
	//var/mob/living/carbon/C = iscarbon(user) ? user : null
	//var/mob/living/carbon/human/H = ishuman(user) ? user : null

	. = list()

	//Cuffs
	if(handcuffed)
		var/handcuff_msg = "[capitalize(P[THEIR])] arms are restrained by [handcuffed.get_examine_string(user)]!"
		. += "<A href='byond://?src=[REF(src)];item=[ITEM_SLOT_HANDCUFFED]'>[handcuff_msg]</A>"
	if(legcuffed)
		var/legcuff_msg = "[capitalize(P[THEIR])] legs are restrained by [legcuffed.get_examine_string(user)]!"
		. += "<A href='byond://?src=[REF(src)];item=[ITEM_SLOT_LEGCUFFED]'>[legcuff_msg]</A>"

	//Bloody hands
	var/list/obscured_slots = check_obscured_slots(FALSE)
	if(num_hands && GET_ATOM_BLOOD_DNA_LENGTH(src) && !(obscured_slots[SLOT_CHECK_REGULAR] & ITEM_SLOT_GLOVES))
		. += "[P[THEYVE]] [span_bloody("blood")] on [P[THEIR]] hand[num_hands > 1 ? "s" : ""]."

	// Fire
	var/fire_str
	if(on_fire)
		fire_str = span_boldwarning("on fire!")
		if(L?.has_quirk(/datum/quirk/vice/addiction/pyromaniac)) // living only
			fire_str += span_boldred(" IT'S BEAUTIFUL!")
			L.sate_addiction(/datum/quirk/vice/addiction/pyromaniac)
	else if(fire_stacks + divine_fire_stacks > 0)
		fire_str += "covered in something flammable."
	else if(fire_stacks < 0 && !on_fire)
		fire_str += "soaked."
	if(fire_str)
		. += "[P[THEYRE]] [fire_str]"

	// Grabs
	if(pulledby && pulledby.grab_state)
		. += "[P[THEYRE]] being grabbed by [pulledby]."

	//Disgusting behemoth of stun absorption
	if(islist(stun_absorption))
		for(var/i in stun_absorption)
			if(stun_absorption[i]["end_time"] > world.time && stun_absorption[i]["examine_message"])
				. += "[P[THEYRE]][stun_absorption[i]["examine_message"]]"

	//Status effects
	var/list/status_examines = status_effect_examines(user, P=P)
	if(length(status_examines))
		. += status_examines


/// Things relevant to one's health.
/mob/living/carbon/proc/get_heartbeat_examine_link(label)
	var/heartbeat_tip = "Listen for a heartbeat. A working heart keeps blood moving and helps prevent brain damage; if it is stopped, restart or replace the heart, treat cardiac arrest, and restore breathing or blood oxygen."
	return "<a href='byond://?src=[REF(src)];check_hb=1'>[span_tooltip(heartbeat_tip, label)]</a>"

/mob/living/carbon/proc/get_examine_health(mob/user, list/P, list/examine_list)
	var/self_inspect = user == src
	var/pl = self_inspect ? "" : p_s()
	var/mob/dead/observer/O = isobserver(user) ? user : null
	//var/mob/living/L = isliving(user) ? user : null
	//var/mob/living/carbon/C = iscarbon(user) ? user : null
	//var/mob/living/carbon/human/H = ishuman(user) ? user : null

	. = list()

	// General Damage
	var/overall_damage = getBruteLoss() + getFireLoss() //no need to calculate each of these twice
	if(!(self_inspect && hal_screwyhud == SCREWYHUD_HEALTHY)) //fake healthy
		// Damage
		var/max_health = 1 //let's not divide by 0
		for(var/obj/item/bodypart/bodypart as anything in bodyparts)
			max_health += bodypart.max_damage
		var/damage_msg
		switch(overall_damage/max_health)
			if(0.0625 to 0.125)
				damage_msg = "[P[THEYRE]] a little wounded."
			if(0.125 to 0.25)
				damage_msg = span_warning("[P[THEYRE]] wounded.")
			if(0.25 to 0.5)
				damage_msg = span_boldwarning("[P[THEYRE]] severely wounded.")
			if(0.5 to INFINITY)
				damage_msg = span_boldred("[P[THEYRE]] gravely wounded.")
		if(damage_msg)
			. += damage_msg

	// missing limbs
	var/appears_dead = FALSE
	var/is_clearly_dead = FALSE
	for(var/t in get_missing_limbs())
		var/limb_msg = "[capitalize(P[THEIR])] [parse_zone(t)] is gone."
		if(t==BODY_ZONE_HEAD)
			limb_msg = span_boldred(limb_msg)
			is_clearly_dead = TRUE
		else
			limb_msg = span_boldwarning(limb_msg)
		. += limb_msg

	if(has_status_effect(/datum/status_effect/defeat_knockout))
		. += span_boldwarning("[P[THEYRE]] defeated and unable to rise.")

	// Health statuses
	if(stat == DEAD || (HAS_TRAIT(src, TRAIT_FAKEDEATH)))
		appears_dead = TRUE
		if(suiciding)
			. += span_red("[P[THEY]] appear[pl] to have committed suicide... there is no hope of recovery.")
		if(hellbound)
			. += span_red("[P[THEIR]] soul seems to have been ripped out of [P[THEIR]] body. Revival is impossible.")

	if(is_clearly_dead || (stat == DEAD && (IsAdminGhost(user) || self_inspect)))
		. += span_boldred("[P[THEYRE]] dead.")
	else if(appears_dead || stat >= UNCONSCIOUS)
		. += span_boldwarning("[P[THEYRE]] unconscious.")
	else if(InCritical())
		. += span_warning("[P[THEYRE]] barely unconscious.")

	//The Nymphomaniac Underground
	if(isliving(user))
		var/mob/living/living_user = user
		if((!appears_dead) && stat == CONSCIOUS && src.has_quirk(/datum/quirk/vice/addiction/lovefiend))
			var/datum/quirk/vice/addiction/bonercheck = src.get_quirk(/datum/quirk/vice/addiction/lovefiend)
			if((bonercheck) && (bonercheck.sated == 0))
				if(living_user.has_quirk(/datum/quirk/vice/addiction/lovefiend)) //Takes one to know one
					switch(rand(1,5))
						if(1)
							. += span_love("I can sense [P[THEIR]] <B>need</B> for fun...")
						if(2)
							. += span_love("[P[THEYRE]] <B>aching</B> for a release.")
						if(3)
							. += span_love("A carnal need <B>stirs</B> within [P[THEIR]] core.")
						if(4)
							. += span_love("I can practically feel [P[THEIR]] <B>horniness</B>...")
						if(5)
							. += span_love("Embers of desire <B>smolder</B> within [P[THEIR]].")
				else if(Adjacent(user)) //No nympho, but close enough to notice.
					switch(rand(1,4))
						if(1)
							. += span_love("[P[THEYRE]] shifting their legs quite a bit...")
						if(2)
							. += span_love("I can see [P[THEYRE]] is a bit restless...")
						if(3)
							. += span_love("[P[THEY]] seem distracted...")
						if(4)
							. += span_love("[P[THEYRE]] restless, for some reason.")

	// Blood volume
	if(!SEND_SIGNAL(src, COMSIG_DISGUISE_STATUS))
		var/blood_lvl_msg
		switch(blood_volume)
			if(-INFINITY to BLOOD_VOLUME_SURVIVE)
				blood_lvl_msg = html_tag("B", "[P[THEYRE]] extremely pale and sickly.")
			if(BLOOD_VOLUME_SURVIVE to BLOOD_VOLUME_BAD)
				blood_lvl_msg = html_tag("B", "[P[THEYRE]] very pale.")
			if(BLOOD_VOLUME_BAD to BLOOD_VOLUME_OKAY)
				blood_lvl_msg = "[P[THEYRE]] pale."
			if(BLOOD_VOLUME_OKAY to BLOOD_VOLUME_SAFE)
				blood_lvl_msg = "[P[THEYRE]] a little pale."
		if(blood_lvl_msg)
			. += span_artery(blood_lvl_msg)

	// Bleeding
	var/bleed_rate = get_bleed_rate()
	if(bleed_rate)
		var/bleed_wording = "bleeding"
		switch(bleed_rate)
			if(0 to 1)
				bleed_wording = "bleeding slightly"
			if(1 to 5)
				bleed_wording = "bleeding"
			if(5 to 10)
				bleed_wording = "bleeding a lot"
			if(10 to INFINITY)
				bleed_wording = "bleeding profusely"
		var/list/bleeding_limbs = list()
		for(var/obj/item/bodypart/bleeder in bodyparts)
			if(!bleeder.get_bleed_rate() || !get_location_accessible(src, bleeder.body_zone))
				continue
			bleeding_limbs += parse_zone(bleeder.body_zone)
		var/bleeding_msg
		if(length(bleeding_limbs))
			bleeding_msg = "[capitalize(P[THEIR])] [english_list(bleeding_limbs)] [bleeding_limbs.len > 1 ? "are" : "is"] [bleed_wording]!"
		else
			bleeding_msg = "[P[THEYRE]] [bleed_wording]!"
		if(bleed_rate >= 5)
			bleeding_msg = html_tag("B", bleeding_msg)
		. += span_bloody(bleeding_msg)

	// Nutrition
	if(nutrition < (NUTRITION_LEVEL_STARVING - 50))
		. += span_boldwarning("[P[THEY]] look[pl] emaciated.")
	else if(HAS_TRAIT(user, TRAIT_EXTEROCEPTION))
		var/nutrition_msg
		switch(nutrition)
			if(NUTRITION_LEVEL_HUNGRY to NUTRITION_LEVEL_FED)
				nutrition_msg = "peckish"
			if(NUTRITION_LEVEL_STARVING to NUTRITION_LEVEL_HUNGRY)
				nutrition_msg = "hungry"
			if(NUTRITION_LEVEL_STARVING-50 to NUTRITION_LEVEL_STARVING)
				nutrition_msg = "starved"
		if(nutrition_msg)
			. += span_tinywarning("[P[THEY]] look[pl] [nutrition_msg].")
		var/hydration_msg
		switch(hydration)
			if(HYDRATION_LEVEL_THIRSTY to HYDRATION_LEVEL_SMALLTHIRST)
				hydration_msg = "like [P[THEIR]] mouth is dry"
			if(HYDRATION_LEVEL_DEHYDRATED to HYDRATION_LEVEL_THIRSTY)
				hydration_msg = "thirsty"
			if(0 to HYDRATION_LEVEL_DEHYDRATED)
				hydration_msg = html_tag("B", "dehydrated")
		if(hydration_msg)
			. += span_tinywarning("[P[THEY]] look[pl] [hydration_msg].")

	if(Adjacent(user))
		if(O)
			var/static/list/check_zones = list(
				BODY_ZONE_HEAD,
				BODY_ZONE_PRECISE_MOUTH,
				BODY_ZONE_CHEST,
				BODY_ZONE_R_ARM,
				BODY_ZONE_L_ARM,
				BODY_ZONE_R_LEG,
				BODY_ZONE_L_LEG,
			)
			var/list/zone_str = list()
			for(var/zone in check_zones)
				var/obj/item/bodypart/bodypart = get_bodypart(zone)
				if(!bodypart)
					continue
				zone_str += "<a href='byond://?src=[REF(src)];inspect_limb=[zone]'>Inspect [parse_zone(zone)]</a>"
			if(length(zone_str))
				. += zone_str.Join(" ")
			. += get_heartbeat_examine_link("Check Heartbeat")
		else
			var/checked_zone = check_zone(user.zone_selected)
			. += "<a href='byond://?src=[REF(src)];inspect_limb=[checked_zone]'>Inspect [parse_zone(checked_zone)]</a>"
			if(!self_inspect && body_position == LYING_DOWN && (user.zone_selected == BODY_ZONE_CHEST))
				. += get_heartbeat_examine_link("Listen to Heartbeat")

	// i dont really wanna put this here but its kinda of a huge hassel to make an appropriate spot
	if(IsAdminGhost(user))
		var/obj/item/organ/heart/heart = getorganslot(ORGAN_SLOT_HEART)
		if(heart && heart.maniacs)
			for(var/datum/antagonist/maniac/M in heart.maniacs)
				var/K = LAZYACCESS(heart.inscryptions, M)
				var/W = LAZYACCESS(heart.maniacs2wonder_ids, M)
				var/N = M.owner?.name
				. += span_notice("Inscryption[N ? " by [N]'s " : ""][W ? "Wonder #[W]" : ""]: [K ? K : ""]")

/*
 * ============================================================================
 * SOCIAL RECOGNITION SYSTEM
 * ============================================================================
 *
 * Layers:
 *
 * 1. EXAMINE SOCIAL CONTEXT
 *      Raw facts and visible social evidence.
 *
 * 2. SOCIAL PROFILE
 *      How a faction/status interprets that evidence.
 *
 * 3. SOCIAL RECOGNITION
 *      What the observer knows, sees, or infers.
 *
 * 4. SOCIAL REACTION
 *      Optional reaction to the recognition.
 *
 * The system does not create a second job/faction database.
 */

#define SOCIAL_SOURCE_KNOWLEDGE (1 << 0)
#define SOCIAL_SOURCE_COSMETIC (1 << 1)
#define SOCIAL_SOURCE_IDENTITY (1 << 2)
#define SOCIAL_SOURCE_PERSONNEL (1 << 3)
#define SOCIAL_SOURCE_STATUS (1 << 4)

#define SOCIAL_LEVEL_UNKNOWN 0
#define SOCIAL_LEVEL_APPARENT 1
#define SOCIAL_LEVEL_KNOWN 2

#define SOCIAL_PRESENTATION_INSUFFICIENT 0
#define SOCIAL_PRESENTATION_RECOGNIZABLE 1
#define SOCIAL_PRESENTATION_CONVINCING 2

/* Tune by content if necessary. Elite cues also contribute to this. */
#define SOCIAL_PRESTIGE_THRESHOLD 5


/*
 * ============================================================================
 * EXAMINE SOCIAL CONTEXT
 * ============================================================================
 */

/datum/examine_social_context
	var/mob/living/carbon/observer
	var/mob/living/carbon/target

	/* Objective target information. */
	var/datum/job/target_job
	var/target_wanted = FALSE

	/* Visibility. */
	var/target_face_visible = FALSE

	/* Visible social evidence. */
	var/list/visible_items = list()
	var/list/visible_social_cues = list()

	/* Universal visual status. */
	var/prestige_appearance_score = 0

	/* Kept as a compatibility alias for the old prototype typo. */
	var/elite_appearance_score = 0
	var/elite_apperance_score = 0

	/* Existing identity system. */
	var/identity_known = FALSE


/mob/living/carbon/proc/social_identity_is_known(mob/living/carbon/user)
	if(!user?.mind || !mind)
		return FALSE

	/* Direction is observer -> target. */
	return user.mind.do_i_know(mind, real_name)


/mob/living/carbon/proc/build_social_context(mob/living/carbon/user)
	var/datum/examine_social_context/context = new

	context.observer = user
	context.target = src
	context.target_job = mind?.assigned_role
	context.target_wanted = (real_name in GLOB.outlawed_players)

	/* Face visibility only controls the identity/personal-recognition path. */
	context.target_face_visible = IsAdminGhost(user) || is_human_part_visible(src, HIDEFACE)

	if(ishuman(src))
		var/mob/living/carbon/human/H = src
		context.visible_items = H.get_unobscured_social_items()

		for(var/obj/item/I as anything in context.visible_items)
			if(!I)
				continue

			var/list/item_cues = I.get_social_cues()
			if(!item_cues)
				continue

			for(var/cue_key in item_cues)
				var/cue_value = item_cues[cue_key]
				if(isnull(cue_value) || !cue_value)
					continue

				if(isnull(context.visible_social_cues[cue_key]))
					context.visible_social_cues[cue_key] = cue_value
				else
					context.visible_social_cues[cue_key] += cue_value

	/*
	 * Elite equipment is also visible prestige.
	 * Items do not need a second prestige cue just because they are elite.
	 */
	var/generic_prestige = context.visible_social_cues["prestige"]
	if(generic_prestige)
		context.prestige_appearance_score = generic_prestige

	for(var/cue_key in context.visible_social_cues)
		if(findtext(cue_key, "elite:") == 1)
			context.prestige_appearance_score += context.visible_social_cues[cue_key]

	context.elite_appearance_score = context.prestige_appearance_score
	context.elite_apperance_score = context.elite_appearance_score

	if(context.target_face_visible)
		context.identity_known = src.social_identity_is_known(user)

	return context


/mob/living/carbon/human/proc/get_unobscured_social_items()
	var/list/result = list()
	var/list/unobscured = get_unobscured_items(FALSE)

	for(var/obj/item/I as anything in unobscured)
		if(I)
			result += I

	/* Headgear remains useful social evidence even when it hides the face. */
	var/obj/item/head_item = get_item_by_slot(ITEM_SLOT_HEAD)
	if(head_item && !(head_item in result))
		result += head_item

	return result


/*
 * ============================================================================
 * SOCIAL PROFILE
 * ============================================================================
 *
 * Item social_cues use namespaces. Examples:
 *
 *     social_cues = list("faction:town_watch" = 7)
 *     social_cues = list("elite:town_watch" = 5)
 *     social_cues = list("prestige" = 3)
 *
 * The item declares evidence. The profile decides what that evidence means.
 */

/datum/social_profile
	var/id
	var/display_name

	/* Personnel/social familiarity traits. */
	var/recognition_trait
	var/rank_trait
	var/specialization_trait

	/* Local institutions are recognizable without special knowledge. */
	var/local_faction_knowledge = TRUE

	/* Namespaced item evidence. */
	var/faction_cue_key
	var/elite_cue_key
	var/list/rank_cue_keys = list()
	var/list/specialization_cue_keys = list()
	var/list/apparent_rank_titles = list()
	var/list/apparent_specialization_titles = list()

	/* Compatibility with older profile/debug code. */
	var/list/faction_cues = list()
	var/list/rank_cues = list()
	var/list/specialization_cues = list()
	var/cosmetic_threshold = 0
	var/specificity = 0

	/* Faction presentation. */
	var/faction_threshold = 0
	var/faction_solid_threshold = 0

	/* Elite equipment. */
	var/elite_threshold = 0
	var/elite_solid_threshold = 0

	/* Rank and specialization presentation. */
	var/rank_threshold = 0
	var/specialization_threshold = 0

	/* Only secret/identity-dependent profiles should set this TRUE. */
	var/face_required = FALSE

	/* Job-based familiarity with the elite subset. */
	var/list/elite_recognition_job_titles = list()
	var/list/elite_job_titles = list()

	/* Existing faction bitflag. */
	var/faction_flag = 0


/datum/social_profile/proc/matches_target(mob/living/carbon/target)
	if(!faction_flag)
		return FALSE

	var/datum/job/J = target.mind?.assigned_role
	if(!J)
		return FALSE

	return !!(J.department_flag & faction_flag)


/datum/social_profile/proc/matches_elite_target(mob/living/carbon/target)
	if(!length(elite_job_titles))
		return FALSE

	var/datum/job/J = target.mind?.assigned_role
	if(!J)
		return FALSE

	return J.title in elite_job_titles


/datum/social_profile/proc/get_cue_score(datum/examine_social_context/context, cue_key)
	if(!cue_key)
		return 0

	return context.visible_social_cues[cue_key] || 0


/*
 * Hidden rules belong here rather than as negative item cues.
 *
 * Example future rule:
 *     a real Watch member wearing an implausibly stripped-down uniform may
 *     receive a hidden concern modifier.
 *
 * The negative evidence itself is not shown to the player as a number.
 */
/datum/social_profile/proc/get_faction_appearance_modifier(datum/examine_social_context/context, datum/social_recognition/recognition)
	return 0


/datum/social_profile/proc/get_elite_appearance_modifier(datum/examine_social_context/context, datum/social_recognition/recognition)
	return 0


/datum/social_profile/proc/get_faction_appearance_score(datum/examine_social_context/context)
	if(faction_cue_key)
		return get_cue_score(context, faction_cue_key)

	/* Old profile-side cue compatibility. */
	var/score = 0
	for(var/cue_key in faction_cues)
		score += get_cue_score(context, cue_key) * faction_cues[cue_key]

	return score


/datum/social_profile/proc/get_elite_appearance_score(datum/examine_social_context/context)
	if(!elite_cue_key)
		return 0

	return get_cue_score(context, elite_cue_key)


/datum/social_profile/proc/get_rank_appearance_score(datum/examine_social_context/context)
	var/score = 0

	if(length(rank_cue_keys))
		for(var/cue_key in rank_cue_keys)
			score += get_cue_score(context, cue_key)
		return score

	for(var/cue_key in rank_cues)
		score += get_cue_score(context, cue_key) * rank_cues[cue_key]

	return score


/datum/social_profile/proc/get_specialization_appearance_score(datum/examine_social_context/context)
	var/score = 0

	for(var/cue_key in apparent_specialization_titles)
		score += get_cue_score(context, cue_key)

	return score


/* Older debug compatibility. */
/datum/social_profile/proc/get_cosmetic_score(datum/examine_social_context/context)
	return get_faction_appearance_score(context)


/datum/social_profile/proc/get_presentation_state(appearance_score)
	if(faction_solid_threshold > 0 && appearance_score >= faction_solid_threshold)
		return SOCIAL_PRESENTATION_CONVINCING

	if(faction_threshold > 0 && appearance_score >= faction_threshold)
		return SOCIAL_PRESENTATION_RECOGNIZABLE

	return SOCIAL_PRESENTATION_INSUFFICIENT


/*
 * Apparent rank/specialization deliberately use visible evidence instead of
 * the target's actual job. Profiles can override these with cue-specific logic.
 */
/datum/social_profile/proc/get_apparent_rank(mob/living/carbon/target, datum/examine_social_context/context, datum/social_recognition/recognition)
	var/best_score = 0
	var/best_title

	for(var/cue_key in apparent_rank_titles)
		var/cue_score = get_cue_score(context, cue_key)
		if(cue_score > best_score)
			best_score = cue_score
			best_title = apparent_rank_titles[cue_key]

	return best_title


/datum/social_profile/proc/get_apparent_specialization(mob/living/carbon/target, datum/examine_social_context/context, datum/social_recognition/recognition)
	var/best_score = 0
	var/best_title

	for(var/cue_key in apparent_specialization_titles)
		var/cue_score = get_cue_score(context, cue_key)
		if(cue_score > best_score)
			best_score = cue_score
			best_title = apparent_specialization_titles[cue_key]

	return best_title


/datum/social_profile/proc/can_recognize(mob/living/carbon/user, datum/examine_social_context/context)
	if(face_required && !context.target_face_visible)
		return FALSE

	var/faction_score = get_faction_appearance_score(context)
	var/elite_score = get_elite_appearance_score(context)
	var/rank_score = get_rank_appearance_score(context)
	var/specialization_score = get_specialization_appearance_score(context)

	/* Ordinary local knowledge recognizes public institutions by appearance. */
	if(local_faction_knowledge)
		if(faction_threshold > 0 && faction_score >= faction_threshold)
			return TRUE

		if(elite_threshold > 0 && elite_score >= elite_threshold)
			return TRUE

	/* Personnel familiarity is job/trait based. */
	if(recognition_trait && HAS_MIND_TRAIT(user, recognition_trait))
		if(context.target_face_visible && matches_target(context.target))
			return TRUE

	/* Rank and specialization remain privileged recognition paths. */
	if(rank_trait && HAS_MIND_TRAIT(user, rank_trait))
		if(rank_threshold > 0 && rank_score >= rank_threshold)
			return TRUE
		if(context.identity_known && matches_target(context.target))
			return TRUE

	if(specialization_trait && HAS_MIND_TRAIT(user, specialization_trait))
		if(specialization_threshold > 0 && specialization_score >= specialization_threshold)
			return TRUE
		if(context.identity_known && matches_target(context.target))
			return TRUE

	/* Hidden factions require deliberate knowledge of the faction/person. */
	if(!local_faction_knowledge && recognition_trait)
		if(HAS_MIND_TRAIT(user, recognition_trait))
			if(context.identity_known && matches_target(context.target))
				return TRUE

	return FALSE


/*
 * ============================================================================
 * SOCIAL RECOGNITION
 * ============================================================================
 */

/datum/social_recognition
	var/datum/social_profile/profile

	/* Objective truth. */
	var/actual_faction = FALSE
	var/actual_elite = FALSE

	/* Knowledge. */
	var/known_faction = FALSE
	var/known_rank = FALSE
	var/known_specialization = FALSE
	var/known_elite = FALSE
	var/identity_recognized = FALSE
	var/personnel_recognized = FALSE

	/* Appearance. */
	var/apparent_faction = FALSE
	var/apparent_rank = FALSE
	var/apparent_specialization = FALSE
	var/elite_equipment_recognized = FALSE
	var/apparent_elite_member = FALSE

	/* Experienced observer contradictions. */
	var/personnel_mismatch = FALSE
	var/elite_personnel_mismatch = FALSE
	var/presentation_concern = FALSE

	/* Presentation and internal legitimacy. */
	var/presentation_state = SOCIAL_PRESENTATION_INSUFFICIENT
	var/solid_faction = FALSE
	var/social_legitimacy = "unknown"

	/* Scores. */
	var/faction_appearance_score = 0
	var/elite_appearance_score = 0
	var/rank_appearance_score = 0
	var/specialization_appearance_score = 0
	var/prestige_appearance_score = 0

	/* Debug/source bookkeeping. */
	var/source = 0
	var/score = 0

	/* Compatibility flags. */
	var/faction_recognized = FALSE
	var/rank_recognized = FALSE
	var/specialization_recognized = FALSE


/mob/living/carbon/proc/resolve_social_profile(mob/living/carbon/user, datum/examine_social_context/context, datum/social_profile/profile)
	if(!profile)
		return null

	var/datum/social_recognition/recognition = new
	recognition.profile = profile

	/* Objective truth. */
	recognition.actual_faction = profile.matches_target(context.target)
	recognition.actual_elite = profile.matches_elite_target(context.target)

	/* Universal visual status. */
	recognition.prestige_appearance_score = context.prestige_appearance_score

	/* Personal identity. */
	if(context.identity_known)
		recognition.identity_recognized = TRUE
		recognition.source |= SOCIAL_SOURCE_IDENTITY

	/* Appearance. */
	var/faction_modifier = profile.get_faction_appearance_modifier(context, recognition)
	recognition.faction_appearance_score = max(profile.get_faction_appearance_score(context) + faction_modifier, 0)

	var/elite_modifier = profile.get_elite_appearance_modifier(context, recognition)
	recognition.elite_appearance_score = max(profile.get_elite_appearance_score(context) + elite_modifier, 0)

	recognition.rank_appearance_score = max(profile.get_rank_appearance_score(context), 0)

	recognition.specialization_appearance_score = max(profile.get_specialization_appearance_score(context), 0)

	recognition.presentation_state = profile.get_presentation_state(recognition.faction_appearance_score)
	recognition.solid_faction = (recognition.presentation_state == SOCIAL_PRESENTATION_CONVINCING)

	/* Public faction recognition. */
	if(
		profile.local_faction_knowledge && \
		profile.faction_threshold > 0 && \
		recognition.faction_appearance_score >= profile.faction_threshold
	)
		recognition.apparent_faction = TRUE
		recognition.source |= SOCIAL_SOURCE_COSMETIC

	/*
	 * Personnel familiarity.
	 *
	 * This is job/trait based rather than a hierarchy database. Seeing the face
	 * is the important discriminator for "I know my people" recognition.
	 */
	if(
		profile.recognition_trait && \
		HAS_MIND_TRAIT(user, profile.recognition_trait) && \
		context.target_face_visible
	)
		if(recognition.actual_faction)
			recognition.personnel_recognized = TRUE
			recognition.known_faction = TRUE
			recognition.source |= SOCIAL_SOURCE_PERSONNEL | SOCIAL_SOURCE_KNOWLEDGE
		else if(recognition.apparent_faction)
			recognition.personnel_mismatch = TRUE

	/*
	 * Secret/antagonistic faction recognition uses the identity/knowledge path.
	 */
	if(!profile.local_faction_knowledge)
		if(
			profile.recognition_trait && \
			HAS_MIND_TRAIT(user, profile.recognition_trait) && \
			context.identity_known && \
			recognition.actual_faction
		)
			recognition.known_faction = TRUE
			recognition.source |= SOCIAL_SOURCE_KNOWLEDGE

	/* Personal identity overrides misleading clothing when the observer has the required familiarity. */
	if(
		recognition.identity_recognized && \
		profile.recognition_trait && \
		HAS_MIND_TRAIT(user, profile.recognition_trait) && \
		recognition.actual_faction
	)
		recognition.personnel_recognized = TRUE
		recognition.known_faction = TRUE
		recognition.source |= SOCIAL_SOURCE_PERSONNEL | SOCIAL_SOURCE_KNOWLEDGE

	/* Elite equipment is ordinary local visual knowledge. */
	if(
		profile.elite_threshold > 0 && \
		recognition.elite_appearance_score >= profile.elite_threshold
	)
		recognition.elite_equipment_recognized = TRUE
		recognition.source |= SOCIAL_SOURCE_STATUS | SOCIAL_SOURCE_COSMETIC

	/*
	 * Elite member inference requires the normal faction presentation to be
	 * convincing and the elite equipment itself to meet its solid threshold.
	 * This prevents an elite helmet from becoming an elite identity by itself.
	 */
	if(
		recognition.presentation_state == SOCIAL_PRESENTATION_CONVINCING && \
		recognition.elite_equipment_recognized && \
		(
			profile.elite_solid_threshold <= 0 || \
			recognition.elite_appearance_score >= profile.elite_solid_threshold
		)
	)
		recognition.apparent_elite_member = TRUE

	/*
	 * Leaders/experienced jobs can recognize the elite subset as personnel.
	 * This is explicitly job-based instead of being inferred from rank order.
	 */
	var/datum/job/observer_job = user.mind?.assigned_role
	if(
		context.target_face_visible && \
		observer_job && \
		length(profile.elite_recognition_job_titles) && \
		(observer_job.title in profile.elite_recognition_job_titles)
	)
		if(recognition.actual_elite)
			recognition.known_elite = TRUE
			recognition.known_faction = TRUE
			recognition.personnel_recognized = TRUE
			recognition.source |= SOCIAL_SOURCE_PERSONNEL | SOCIAL_SOURCE_KNOWLEDGE
		else if(recognition.apparent_elite_member)
			recognition.elite_personnel_mismatch = TRUE

	/* Known rank. */
	if(
		profile.rank_trait && \
		HAS_MIND_TRAIT(user, profile.rank_trait) && \
		context.target_job
	)
		if(recognition.identity_recognized || recognition.known_faction)
			recognition.known_rank = TRUE
			recognition.source |= SOCIAL_SOURCE_KNOWLEDGE

	/* Apparent rank. */
	if(
		profile.rank_trait && \
		HAS_MIND_TRAIT(user, profile.rank_trait) && \
		profile.rank_threshold > 0 && \
		recognition.rank_appearance_score >= profile.rank_threshold
	)
		recognition.apparent_rank = TRUE
		recognition.source |= SOCIAL_SOURCE_COSMETIC

	/* Known specialization. */
	if(
		profile.specialization_trait && \
		HAS_MIND_TRAIT(user, profile.specialization_trait) && \
		context.target.get_social_specialization()
	)
		if(recognition.identity_recognized || recognition.known_faction)
			recognition.known_specialization = TRUE
			recognition.source |= SOCIAL_SOURCE_KNOWLEDGE

	/* Apparent specialization. */
	if(
		profile.specialization_trait && \
		HAS_MIND_TRAIT(user, profile.specialization_trait) && \
		profile.specialization_threshold > 0 && \
		recognition.specialization_appearance_score >= profile.specialization_threshold
	)
		recognition.apparent_specialization = TRUE
		recognition.source |= SOCIAL_SOURCE_COSMETIC

	/* Compatibility flags. */
	recognition.faction_recognized = recognition.known_faction || recognition.apparent_faction
	recognition.rank_recognized = recognition.known_rank || recognition.apparent_rank
	recognition.specialization_recognized = recognition.known_specialization || recognition.apparent_specialization

	/* Internal legitimacy. */
	recognition.social_legitimacy = "unknown"
	if(recognition.presentation_state == SOCIAL_PRESENTATION_CONVINCING)
		if(recognition.actual_faction)
			recognition.social_legitimacy = "solid"
		else if(recognition.apparent_faction)
			recognition.social_legitimacy = "disguised"
	else if(recognition.faction_appearance_score > 0)
		if(recognition.actual_faction)
			recognition.social_legitimacy = "partial"
		else if(recognition.apparent_faction)
			recognition.social_legitimacy = "suspicious"

	/* Debug score. */
	recognition.score = max(recognition.faction_appearance_score, recognition.elite_appearance_score, recognition.prestige_appearance_score)

	if(recognition.known_faction)
		recognition.score = max(recognition.score, 100)

	if(recognition.identity_recognized)
		recognition.score = max(recognition.score, 150)

	/* Keep elite-equipment-only and contradiction results alive. */
	if(
		!recognition.identity_recognized && \
		!recognition.faction_recognized && \
		!recognition.rank_recognized && \
		!recognition.specialization_recognized && \
		!recognition.elite_equipment_recognized && \
		!recognition.personnel_mismatch && \
		!recognition.elite_personnel_mismatch
	)
		qdel(recognition)
		return null

	return recognition


/*
 * ============================================================================
 * SOCIAL ADAPTERS
 * ============================================================================
 */

/mob/living/carbon/proc/get_social_specialization()
	if(!mind?.assigned_role)
		return null

	var/datum/job/job = mind.assigned_role
	var/title = job.get_informed_title(src)
	if(!title || title == "Unassigned")
		return null

	return title


/*
 * ============================================================================
 * PROFILE DESCRIPTION
 * ============================================================================
 */

/datum/social_profile/proc/get_membership_phrase(qualifier = "")
	if(qualifier)
		return "[qualifier] member of [display_name]"
	return "a member of [display_name]"


/datum/social_profile/proc/get_elite_equipment_phrase()
	return "elite equipment associated with [display_name]"


/datum/social_profile/proc/get_description(mob/living/carbon/user, datum/examine_social_context/context, datum/social_recognition/recognition, list/P)
	var/primary_statement
	var/secondary_statement
	var/datum/job/J = context.target_job
	var/rank_title
	var/specialization_title
	var/show_job_title = recognition.presentation_state >= SOCIAL_PRESENTATION_RECOGNIZABLE
	var/pl = p_s()

	/* Known information takes precedence over appearance. */
	if(recognition.known_faction)
		if(recognition.known_elite)
			if(show_job_title && recognition.known_rank && J)
				rank_title = J.get_informed_title(context.target)

			if(rank_title)
				primary_statement = "[P[THEYRE]] the [rank_title] of [display_name], one of the faction's elite"
			else
				primary_statement = "[P[THEYRE]] an elite member of [display_name]"

		else if(show_job_title && recognition.known_rank && J)
			rank_title = J.get_informed_title(context.target)

			if(rank_title)
				primary_statement = "[P[THEYRE]] the [rank_title] of [display_name]"
			else
				primary_statement = "[P[THEYRE]] a member of [display_name]"

		else
			primary_statement = "[P[THEYRE]] a member of [display_name]"

		/* Visible clothing can still be notably incomplete. */
		if(
			recognition.faction_appearance_score > 0 && \
			recognition.presentation_state != SOCIAL_PRESENTATION_CONVINCING && \
			!recognition.elite_equipment_recognized
		)
			secondary_statement = "[P[THEIR]] current attire is incomplete"

	/* Convincing visual faction presentation. */
	else if(recognition.presentation_state == SOCIAL_PRESENTATION_CONVINCING)
		if(recognition.apparent_elite_member)
			primary_statement = "[P[THEY]] appear[pl] to be an elite member of [display_name]"
		else
			primary_statement = "[P[THEY]] appear[pl] to be a member of [display_name]"

	/* Recognizable but incomplete presentation. */
	else if(recognition.presentation_state == SOCIAL_PRESENTATION_RECOGNIZABLE)
		primary_statement = "[P[THEYRE]] wearing [display_name] garb, but the presentation looks incomplete"

	/* Personal identity without enough faction evidence. */
	else if(recognition.identity_recognized)
		primary_statement = "[P[THEYRE]] someone I recognize"

	/* Elite equipment remains independently visible. */
	if(recognition.elite_equipment_recognized && !recognition.apparent_elite_member && !secondary_statement)
		secondary_statement = "[P[THEYRE]] wearing [get_elite_equipment_phrase()]"

	/* Apparent rank. */
	if(
		!secondary_statement && \
		show_job_title && \
		!recognition.known_rank && \
		recognition.apparent_rank
	)
		rank_title = get_apparent_rank(context.target, context, recognition)
		if(rank_title)
			secondary_statement = "[P[THEY]] appear[pl] to hold the rank of [rank_title]"

	/* Specialization. */
	if(
		!secondary_statement && \
		show_job_title && \
		recognition.known_specialization
	)
		specialization_title = context.target.get_social_specialization()
		if(specialization_title)
			secondary_statement = "[P[THEYRE]] known to specialize as [specialization_title]"

	else if(
		!secondary_statement && \
		show_job_title && \
		recognition.apparent_specialization
	)
		specialization_title = get_apparent_specialization(context.target, context, recognition)
		if(specialization_title)
			secondary_statement = "[P[THEY]] appear[pl] to specialize as [specialization_title]"

	/* Experienced personnel contradiction overrides lesser secondary details. */
	if(recognition.elite_personnel_mismatch)
		secondary_statement = "I don't recognize [P[THEM]] as one of the [display_name] elite"
	else if(recognition.personnel_mismatch)
		secondary_statement = "I don't recognize [P[THEM]] as one of [display_name]"

	/* Universal prestige when no faction-specific statement explains it. */
	if(!primary_statement && !secondary_statement)
		if(context.prestige_appearance_score >= SOCIAL_PRESTIGE_THRESHOLD)
			primary_statement = "[P[THEY]] look[pl] unusually well-equipped"

	if(!primary_statement && !secondary_statement)
		return null

	if(!secondary_statement)
		return "[primary_statement]."

	if(!primary_statement)
		return "[secondary_statement]."

	return "[primary_statement]. [secondary_statement]."
/*
 * ============================================================================
 * SOCIAL REACTIONS
 * ============================================================================
 */

/datum/examine_social_reaction
	var/stress_type
	var/list/phrases = list()


/datum/examine_social_reaction/proc/get_phrase()
	if(!length(phrases))
		return null
	return pick(phrases)


/*
 * ============================================================================
 * FACTION RELATIONSHIP DETERMINATION
 * ============================================================================
 *
 * Directional by design.
 */

/mob/living/carbon/proc/get_faction_relationship(user_faction, target_faction)
	if(user_faction & target_faction)
		return "allied"

	if((user_faction & TOWNWATCH) && (target_faction & VILLAINS))
		return "hostile"

	if((user_faction & TOWNWATCH) && (target_faction & TOWNHALL))
		return "protect_duty"

	if((user_faction & TOWNHALL) && (target_faction & VILLAINS))
		return "diplomatic_hostile"

	/* Deliberately asymmetric reverse relationship. */
	if((user_faction & VILLAINS) && (target_faction & TOWNWATCH))
		return "hostile_to_watch"

	if((user_faction & SCHOLARS) && (target_faction & CHAPEL))
		return "tense"

	if((user_faction & TRADERS) && (target_faction & TAVERN))
		return "tense"

	return "neutral"


/datum/social_profile/proc/get_profile_faction_flag()
	return faction_flag


/*
 * ============================================================================
 * REACTION GENERATION
 * ============================================================================
 */

/datum/social_profile/proc/get_reactions(mob/living/carbon/user, datum/examine_social_context/context, datum/social_recognition/recognition, list/reactions)
	/* Personnel contradictions take priority over normal faction feelings. */
	if(recognition.elite_personnel_mismatch)
		var/datum/examine_social_reaction/elite_mismatch = new
		elite_mismatch.stress_type = /datum/stress_event/paranoia
		elite_mismatch.phrases = list(
			"That's elite gear, but they're not one of the people who should be wearing it.",
			"I know who is supposed to hold that standing. This isn't one of them.",
			"Those are the marks of one of our elites. The person wearing them is not."
		)
		reactions += elite_mismatch
		return

	if(recognition.personnel_mismatch)
		var/datum/examine_social_reaction/personnel_mismatch = new
		personnel_mismatch.stress_type = /datum/stress_event/paranoia
		personnel_mismatch.phrases = list(
			"I know my people. This isn't one of them.",
			"Something is wrong. I don't recognize this person as one of ours.",
			"That's our uniform, but not one of our people."
		)
		reactions += personnel_mismatch
		return

	/* Known outlaw identification remains a positive identification. */
	if(id == "outlaw" && recognition.known_faction)
		var/datum/examine_social_reaction/known_outlaw = new
		known_outlaw.stress_type = /datum/stress_event/paranoia
		known_outlaw.phrases = list(
			"I'm certain they're an outlaw.",
			"I know what they are. An outlaw.",
			"That's an outlaw. I recognize them.",
			"There's no mistaking it. They're an outlaw."
		)
		reactions += known_outlaw
		return

	if(!recognition.faction_recognized)
		return

	if(!user.mind?.assigned_role)
		return

	var/user_faction = user.mind.assigned_role.department_flag
	var/target_faction = get_profile_faction_flag()
	if(!target_faction)
		return

	var/relationship = user.get_faction_relationship(user_faction, target_faction)

	if(should_be_suspicious(user, context, recognition))
		var/datum/examine_social_reaction/wary_presentation = new
		wary_presentation.stress_type = /datum/stress_event/paranoia
		wary_presentation.phrases = list(
			"Something about their presentation doesn't add up.",
			"Something is wrong with the way they're presenting themselves.",
			"That isn't how this should look."
		)
		reactions += wary_presentation
		return

	switch(relationship)
		if("allied")
			var/datum/examine_social_reaction/allied = new
			allied.stress_type = /datum/stress_event/fellow
			allied.phrases = list(
				"Good. I'm not the one here.",
				"It's always nice to feel that I have someone to rely on.",
				"Staying together is always better than working on my own here."
			)
			reactions += allied

		if("protect_duty")
			var/datum/examine_social_reaction/protect_duty = new
			protect_duty.phrases = list(
				"My job is to keep them safe.",
				"I'm paid to protect them.",
				"Best to be nearby in case of emergency."
			)
			reactions += protect_duty

		if("higher_rank")
			var/datum/examine_social_reaction/higher_rank = new
			higher_rank.stress_type = /datum/stress_event/highrank_respect
			higher_rank.phrases = list(
				"At least someone to rely on.",
				"Better obey their orders; their rank is higher than mine.",
				"Good, someone actually viable here."
			)
			reactions += higher_rank

		if("cooperative")
			var/datum/examine_social_reaction/cooperative = new
			cooperative.stress_type = /datum/stress_event/rely_on
			cooperative.phrases = list(
				"Better to work with them for my own interests.",
				"They'll protect me if we are on good terms, right?",
				"Great, someone who will help me if things get ugly."
			)
			reactions += cooperative

		if("loyal")
			var/datum/examine_social_reaction/loyal = new
			loyal.phrases = list(
				"My job is to serve them.",
				"I should be ready to assist, if necessary.",
				"Should be ready to serve; that's why I'm here."
			)
			reactions += loyal

		if("seperated_authority")
			var/datum/examine_social_reaction/seperated_authority = new
			seperated_authority.phrases = list(
				"We have the same interests, but not jurisdictions.",
				"Someone has to keep an eye on the town, and someone stays in the dark forest.",
				"Only if we weren't separated..."
			)
			reactions += seperated_authority

		if("tense")
			var/datum/examine_social_reaction/tense = new
			tense.stress_type = /datum/stress_event/tense
			tense.phrases = list(
				"We have different interests.",
				"I should be careful around them.",
				"Best to keep distance."
			)
			reactions += tense

		if("diplomatic_hostile")
			var/datum/examine_social_reaction/diplomatic_hostile = new
			diplomatic_hostile.stress_type = /datum/stress_event/unease
			diplomatic_hostile.phrases = list(
				"Not a place for THEM.",
				"Better call someone who can get rid of this person.",
				"Best to stay aware with THOSE walking here."
			)
			reactions += diplomatic_hostile

		if("hostile")
			var/datum/examine_social_reaction/hostile = new
			hostile.stress_type = /datum/stress_event/fearful
			hostile.phrases = list(
				"Trouble. I don't want them near me.",
				"I should keep my distance from them.",
				"Best not to draw their attention."
			)
			reactions += hostile

		if("hostile_to_watch")
			var/datum/examine_social_reaction/hostile_to_watch = new
			hostile_to_watch.stress_type = /datum/stress_event/outlaw_near_watch
			hostile_to_watch.phrases = list(
				"A lawman... What a day to live.",
				"I should be careful around those bastards.",
				"Better prepare myself if they are upon my track."
			)
			reactions += hostile_to_watch

		if("fearful")
			var/datum/examine_social_reaction/fearful = new
			fearful.stress_type = /datum/stress_event/fearful
			fearful.phrases = list(
				"Damn it, don't wanna fall in their hands!",
				"What?! How did this person manage to GET here!?",
				"No, no, no, no, please tell me it's not them!"
			)
			reactions += fearful

		if("disagreeing")
			var/datum/examine_social_reaction/disagreeing = new
			disagreeing.phrases = list(
				"We have different ways to live this life.",
				"It's annoying to stay with someone who devoted their life to this.",
				"Why won't we get along?"
			)
			reactions += disagreeing

		if("neutral")
			return


/datum/social_profile/proc/should_be_suspicious(mob/living/carbon/user, datum/examine_social_context/context, datum/social_recognition/recognition)
	/* Only explicit lore anchors should produce hidden suspicion. */
	return FALSE


/*
 * ============================================================================
 * GLOBAL PROFILE REGISTRY
 * ============================================================================
 */

GLOBAL_LIST_INIT(social_profiles, list(
	new /datum/social_profile/town_watch,
	new /datum/social_profile/outlaw
))


/*
 * ============================================================================
 * RESOLVE ALL SOCIAL PROFILES
 * ============================================================================
 */

/mob/living/carbon/proc/get_social_recognitions(mob/living/carbon/user, datum/examine_social_context/context)
	var/list/recognitions = list()

	for(var/datum/social_profile/profile as anything in GLOB.social_profiles)
		if(!profile)
			continue

		if(!profile.can_recognize(user, context))
			continue

		var/datum/social_recognition/recognition = \
			resolve_social_profile(user, context, profile)

		if(recognition)
			recognitions += recognition

	return recognitions


/*
 * ============================================================================
 * TOWN WATCH
 * ============================================================================
 */

/datum/social_profile/town_watch
	id = "town_watch"
	display_name = "the Town Watch"
	faction_flag = TOWNWATCH
	faction_cue_key = "faction:town_watch"
	elite_cue_key = "elite:town_watch"
	specialization_cue_keys = "specialization:"

	recognition_trait = TRAIT_KNOW_WATCH
	rank_trait = TRAIT_KNOW_WATCH_RANK
	specialization_trait = TRAIT_KNOW_WATCH_SPECIALIZATION

	faction_threshold = 10
	faction_solid_threshold = 15

	elite_threshold = 3
	elite_solid_threshold = 5

	rank_threshold = 3
	specialization_threshold = 3

	rank_cue_keys = list(
		"rank:town_watch:captain",
		"rank:town_watch:sergeant",
		"rank:town_watch:warden",
		"rank:town_watch:guard"
	)

	apparent_rank_titles = list(
		"rank:town_watch:captain" = "Town Watch Captain",
		"rank:town_watch:sergeant" = "Town Watch Sergeant",
		"rank:town_watch:warden" = "Town Watch Warden",
		"rank:town_watch:guard" = "Town Watch Guard"
	)

	apparent_specialization_titles = list(
		"specialization:prosecutor" = "Prosecutor",
		"specialization:executioner" = "Executioner",
		"specialization:Juggernaut" = "Juggernaut",
		"specialization:Charm" = "Charm of the corps"
	)

	/* High-status Watch roles are treated as the elite subset. */
	elite_job_titles = list(
		"Town Watch Captain",
		"Town Watch Sergeant",
		"Town Watch Warden"
	)

	/* Leaders/experienced Watch personnel and the Burgmeister know the elite subset. */
	elite_recognition_job_titles = list(
		"Burgmeister",
		"Town Watch Captain",
		"Town Watch Sergeant",
		"Town Watch Warden"
	)

	/* Compatibility/debug fields. */
	cosmetic_threshold = 5
	specificity = 50


/datum/social_profile/town_watch/get_membership_phrase(qualifier = "")
	if(qualifier)
		return "[qualifier] member of the Town Watch"
	return "a member of the Town Watch"


/datum/social_profile/town_watch/get_elite_equipment_phrase()
	return "elite Town Watch equipment"


/* No generic negative deduction; add only lore-specific anchors here. */
/datum/social_profile/town_watch/get_faction_appearance_modifier(datum/examine_social_context/context, datum/social_recognition/recognition)
	return 0


/*
 * ============================================================================
 * OUTLAW
 * ============================================================================
 */

/datum/social_profile/outlaw
	id = "outlaw"
	display_name = "an outlaw"
	faction_flag = VILLAINS
	local_faction_knowledge = FALSE
	recognition_trait = TRAIT_KNOWBANDITS
	face_required = TRUE


/datum/social_profile/outlaw/matches_target(mob/living/carbon/target)
	return target.real_name in GLOB.outlawed_players


/datum/social_profile/outlaw/get_membership_phrase(qualifier = "")
	return "an outlaw"


/datum/social_profile/outlaw/get_description(mob/living/carbon/user, datum/examine_social_context/context, datum/social_recognition/recognition, list/P)
	if(recognition.known_faction)
		return "[P[THEYRE]] an outlaw."

	if(recognition.identity_recognized)
		return "[P[THEYRE]] someone I recognize."

	return null


/*
 * ============================================================================
 * REACTION RESOLUTION
 * ============================================================================
 */

/mob/living/carbon/proc/resolve_strongest_social_reaction(mob/living/carbon/user, list/reactions)
	var/datum/examine_social_reaction/best_reaction
	var/best_strength = -INFINITY
	var/datum/examine_social_reaction/first_phrase_only

	for(var/datum/examine_social_reaction/reaction as anything in reactions)
		if(!reaction)
			continue

		if(!reaction.stress_type)
			if(!first_phrase_only)
				first_phrase_only = reaction
			continue

		if(user.has_stress_type(reaction.stress_type))
			continue

		var/datum/stress_event/event = new reaction.stress_type
		if(!event.can_apply(user))
			qdel(event)
			continue

		var/stress_value = event.get_stress(user)
		var/strength = abs(stress_value)
		if(strength > best_strength)
			best_strength = strength
			best_reaction = reaction

		qdel(event)

	if(best_reaction)
		return best_reaction

	return first_phrase_only


/*
 * ============================================================================
 * SOCIAL EXAMINE ENTRY POINT
 * ============================================================================
 */

/mob/living/carbon/proc/get_examine_social(mob/living/carbon/user, list/P, list/examine_list)
	. = list()

	if(user == src)
		return
	if(!isliving(user))
		return

	var/datum/examine_social_context/context = build_social_context(user)
	if(!context)
		return

	var/list/recognitions = get_social_recognitions(user, context)
	var/list/descriptions = list()

	for(var/datum/social_recognition/recognition as anything in recognitions)
		var/description = recognition.profile.get_description(user, context, recognition, P)
		if(description)
			descriptions += description

	/* Universal prestige, unless already expressed through elite equipment. */
	if(context.prestige_appearance_score >= SOCIAL_PRESTIGE_THRESHOLD)
		var/show_generic_prestige = TRUE
		for(var/datum/social_recognition/recognition as anything in recognitions)
			if(recognition.elite_equipment_recognized || recognition.apparent_elite_member)
				show_generic_prestige = FALSE
				break

		if(show_generic_prestige)
			descriptions += "[P[THEY]] look unusually well-equipped."

	/* De-duplicate descriptions. */
	for(var/description in descriptions)
		if(!description)
			continue
		if(description in .)
			continue
		. += description

	/* Reactions remain independent from recognition descriptions. */
	var/list/reactions = list()
	for(var/datum/social_recognition/recognition as anything in recognitions)
		recognition.profile.get_reactions(user, context, recognition, reactions)

	var/datum/examine_social_reaction/best_reaction = \
		resolve_strongest_social_reaction(user, reactions)

	if(best_reaction)
		var/phrase = best_reaction.get_phrase()
		if(phrase)
			. += phrase

		if(best_reaction.stress_type)
			user.add_stress(best_reaction.stress_type)
