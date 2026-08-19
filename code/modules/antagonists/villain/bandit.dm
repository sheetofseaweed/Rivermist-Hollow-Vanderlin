
/datum/antagonist/bandit
	name = "Bandit"
	roundend_category = "Bandits"
	antagpanel_category = "Bandit"
	show_in_roundend = FALSE
	job_rank = ROLE_BANDIT
	antag_hud_type = ANTAG_HUD_BANDIT
	antag_hud_name = "bandit"
	var/tri_amt
	var/contrib
	var/datum/team/bandits/bandit_team
	contract_pool_type = /datum/contract_pool/bandit
	antag_flags = FLAG_ANTAG_CAP_IGNORE
	confess_lines = list(
		"FREEDOM!!!",
		"I WILL NOT LIVE IN YOUR WALLS!",
		"I WILL NOT FOLLOW YOUR RULES!",
	)

	innate_traits = list(
		TRAIT_BANDITCAMP,
		TRAIT_SEEPRICES,
		TRAIT_STEELHEARTED,
		TRAIT_VILLAIN,
	)

/datum/antagonist/bandit/examine_friendorfoe(datum/antagonist/examined_datum, mob/examiner, mob/examined)
	if(istype(examined_datum, /datum/antagonist/bandit))
		if(examiner.real_name in GLOB.outlawed_players)
			if(examined.real_name in GLOB.outlawed_players)
				return span_boldnotice("Another free man. My ally.")
			else
				return span_boldnotice("Pardoned free man?! Can I still trust [examined.p_them()]?!")
		else if(examined.real_name in GLOB.outlawed_players)
			return span_boldnotice("Free man still on the run. Fool.")
		else
			return span_boldnotice("Fellow pardoned free man.")

/datum/antagonist/bandit/on_gain()
	. = ..()
	owner.special_role = ROLE_BANDIT
	owner.current?.purge_combat_knowledge()
	finalize_bandit()
	equip_bandit()
	var/mob/living/bandit_body = owner.current
	bandit_body?.review_patron_contract()
	reveal_bandit_camp_entrances(bandit_body)
	if(ishuman(owner.current))
		addtimer(CALLBACK(owner.current, TYPE_PROC_REF(/mob/living/carbon/human, choose_name_popup), "BANDIT"), 5 SECONDS)

/datum/antagonist/bandit/proc/finalize_bandit()
	if(!ishuman(owner.current))
		return
	owner.current.playsound_local(get_turf(owner.current), 'sound/music/traitor.ogg', 80, FALSE, pressure_affected = FALSE)
	var/mob/living/carbon/human/human_bandit = owner.current
	human_bandit.set_patron(/datum/patron/faerun/evil_gods/Mask)

/datum/antagonist/bandit/greet()
	to_chat(owner.current, span_alert("I am a BANDIT!"))
	to_chat(owner.current, span_info("I belong to a free company of thieves, scouts, and fences. Our contracts are shared: every bandit's work advances the same demands."))
	to_chat(owner.current, span_info("I can review the company's current objectives and progress at any time with <b>IC → Review Contract</b>."))
	to_chat(owner.current, span_warning("Rivermist Hollow permits only low-level conflict. I must steal, trespass, deceive, and escape without killing anyone."))
	..()

/proc/isbandit(mob/living/checked_mob)
	return istype(checked_mob) && checked_mob.mind && checked_mob.mind.has_antag_datum(/datum/antagonist/bandit)

/datum/antagonist/bandit/proc/equip_bandit()
	owner.forget_and_be_forgotten()
	for(var/datum/mind/found_mind as anything in bandit_team?.members)
		owner.share_identities(found_mind)
	return TRUE

/datum/antagonist/bandit/create_team(datum/team/bandits/new_team)
	if(new_team)
		if(!istype(new_team))
			stack_trace("Wrong team type passed to [type] initialization.")
			return
		bandit_team = new_team
		return
	for(var/datum/team/bandits/existing_team as anything in GLOB.antagonist_teams)
		bandit_team = existing_team
		return
	bandit_team = new()

/datum/antagonist/bandit/get_team()
	return bandit_team

/datum/antagonist/bandit/get_shared_contract_party()
	return bandit_team?.contract_party

/datum/antagonist/bandit/get_contract_minds()
	if(bandit_team)
		return bandit_team.members
	return list(owner)

/datum/team/bandits
	name = "The Bandit Free Company"
	member_name = "bandit"
	var/datum/contract_party/contract_party

/datum/team/bandits/New(starting_members)
	contract_party = new /datum/contract_party(/datum/contract_pool/bandit, TRUE)
	return ..()

/datum/team/bandits/Destroy()
	QDEL_NULL(contract_party)
	return ..()

/datum/team/bandits/roundend_report()
	var/list/report = list(..())
	var/contract_report = contract_party?.roundend_ledger()
	if(contract_report)
		report += contract_report
	return report.Join("<br>")
