// Cleric Holder Datums
/datum/devotion
	var/mob/living/carbon/human/holder_mob = null

	var/devotion = 0
	var/max_devotion = 1000
	var/progression = 0
	var/max_progression = CLERIC_REQ_3

	/// How much devotion is gained per process call
	var/passive_devotion_gain = 0
	/// How much progression is gained per process call
	var/passive_progression_gain = 0
	/// How much devotion is gained per prayer cycle
	var/prayer_effectiveness = 2

	/// Map of cleric level to miracle(s) supports list or not list
	var/list/miracles = list()
	/// List of extra miracles to add unconditionally
	var/list/miracles_extra = list()
	/// Traits added by this
	var/list/traits = list()
	/// Favorite Specie of said god.
	var/list/favored_species = list()
	/// Miracles granted to Favored Species
	var/list/favored_miracles = list()
	var/devotion_color = "#3C41A4"
	/// Excommunicated: no miracle answers, slots stay but miracles refuse to cast.
	var/forsaken = FALSE

	var/list/datum/devotion_task/tasks = list()
	var/list/viable_tasks = list()

/datum/devotion/Destroy(force)
	remove()
	STOP_PROCESSING(SSprocessing, src)
	return ..()

/datum/devotion/process()
	if(!passive_devotion_gain && !passive_progression_gain)
		return PROCESS_KILL
	if(holder_mob.stat >= DEAD)
		return
	update_devotion(passive_devotion_gain, passive_progression_gain)

/// Binds this datum to a mob. A datum already granted refuses; the mob's older datum is retired.
/datum/devotion/proc/grant_to(mob/living/carbon/human/holder)
	if(!holder || holder_mob)
		return FALSE
	if(holder.cleric && holder.cleric != src)
		var/datum/devotion/old_faith = holder.cleric
		old_faith.remove()
		qdel(old_faith)
	if(passive_devotion_gain || passive_progression_gain)
		START_PROCESSING(SSprocessing, src)
	holder_mob = holder
	holder_mob.cleric = src
	RegisterSignal(holder_mob, COMSIG_LIVING_SPELL_REST, PROC_REF(on_spell_rest))
	holder_mob?.hud_used?.initialize_bloodpool()
	holder_mob?.hud_used?.bloodpool.set_fill_color(devotion_color)
	for(var/trait in traits)
		ADD_TRAIT(holder_mob, trait, DEVOTION_TRAIT)
	for(var/datum/action/miracle as anything in miracles_extra)
		grant_miracle(miracle)
	add_verb(holder_mob, list(/mob/living/carbon/human/proc/devotionreport, /mob/living/carbon/human/proc/clericpray))
	check_progression()
	initialize_tasks()
	update_devotion(0)
	return TRUE

/// Long rests refill devotion, short rests restore half the cap. The forsaken get nothing.
/datum/devotion/proc/on_spell_rest(datum/source, rest_type)
	SIGNAL_HANDLER
	if(forsaken)
		return
	if(rest_type & REST_LONG)
		update_devotion(max_devotion)
	else
		update_devotion(round(max_devotion / 2))

/datum/devotion/proc/initialize_tasks()
	if(!holder_mob?.patron)
		return

	var/list/task_types = get_patron_tasks()
	for(var/task_type in task_types)
		add_task(task_type)

/datum/devotion/proc/get_patron_tasks()
	return viable_tasks

/datum/devotion/proc/add_task(datum/devotion_task/task_type)
	var/datum/devotion_task/new_task = new task_type(src)
	tasks += new_task
	return new_task

/datum/devotion/proc/remove_task(datum/devotion_task/task)
	tasks -= task
	qdel(task)

/datum/devotion/proc/remove()
	STOP_PROCESSING(SSprocessing, src)
	if(holder_mob)
		UnregisterSignal(holder_mob, COMSIG_LIVING_SPELL_REST)
		if(holder_mob.cleric == src)
			holder_mob.cleric = null
		holder_mob.remove_spells(source = src)
		remove_verb(holder_mob, list(/mob/living/carbon/human/proc/devotionreport, /mob/living/carbon/human/proc/clericpray))
		for(var/trait in traits)
			REMOVE_TRAIT(holder_mob, trait, DEVOTION_TRAIT)
	holder_mob = null

/datum/devotion/proc/grant_miracle(datum/action/miracle)
	if(!miracle)
		return
	holder_mob.add_spell(miracle, source = src)

/datum/devotion/proc/update_devotion(amount)
	. += devotion
	devotion = clamp(devotion += amount, 0, max_devotion)
	. -= devotion
	holder_mob?.hud_used?.bloodpool?.name = "Devotion: [devotion]"
	holder_mob?.hud_used?.bloodpool?.desc = "Devotion: [devotion]/[max_devotion]"
	holder_mob?.update_spell_slot_hud()
	if(devotion <= 0)
		holder_mob?.hud_used?.bloodpool?.set_value(0, 1 SECONDS)
	else
		holder_mob?.hud_used?.bloodpool?.set_value((100 / (max_devotion / devotion)) / 100, 1 SECONDS)
	if(.)
		SEND_SIGNAL(holder_mob, COMSIG_LIVING_DEVOTION_CHANGED, amount)

/datum/devotion/proc/check_devotion(required)
	if(forsaken)
		return FALSE
	return devotion >= abs(required)

/datum/devotion/proc/update_progression(amount)
	. += progression
	progression = clamp(progression += amount, 0, max_progression)
	. -= progression

	if(.)
		check_progression()

/datum/devotion/proc/check_progression()
	var/static/list/tiers = list(
		CLERIC_T0 = CLERIC_REQ_0,
		CLERIC_T1 = CLERIC_REQ_1,
		CLERIC_T2 = CLERIC_REQ_2,
		CLERIC_T3 = CLERIC_REQ_3,
	)

	for(var/tier in tiers)
		var/requirement = tiers[tier]
		if(progression >= requirement)
			var/miracle_list = miracles[tier]
			if(!islist(miracle_list))
				miracle_list = list(miracle_list)
			if(!length(miracle_list))
				continue
			for(var/miracle in miracle_list)
				grant_miracle(miracle)
			if(holder_mob.dna?.species?.id in favored_species)
				var/favored_miracle_list = favored_miracles[tier]
				if(!islist(favored_miracle_list))
					favored_miracle_list = list(favored_miracle_list)
				if(length(favored_miracle_list))
					for(var/favored_miracle in favored_miracle_list)
						grant_miracle(favored_miracle)

/datum/devotion/proc/make_priest()
	max_devotion = DEVOTION_CAP_PRIEST
	devotion = max_devotion
	progression = CLERIC_REQ_3
	passive_devotion_gain = 1
	miracles_extra += list(
		/datum/action/cooldown/spell/undirected/touch/orison,
		/datum/action/cooldown/spell/cure_rot,
		/datum/action/cooldown/spell/undirected/succubus_consecrate_refuge,
		/datum/action/cooldown/spell/succubus_deliverance,
		/datum/action/cooldown/spell/succubus_seal_rift,
	)

/datum/devotion/proc/make_templar()
	max_devotion = DEVOTION_CAP_PALADIN
	devotion = max_devotion
	progression = CLERIC_REQ_2
	max_progression = CLERIC_REQ_3

/datum/devotion/proc/make_cleric()
	max_devotion = DEVOTION_CAP_CLERIC
	devotion = max_devotion
	progression = CLERIC_REQ_3
	max_progression = CLERIC_REQ_3

/datum/devotion/proc/make_acolyte()
	max_devotion = DEVOTION_CAP_ACOLYTE
	devotion = max_devotion
	progression = CLERIC_REQ_3
	max_progression = CLERIC_REQ_3

/mob/living/carbon/human/proc/devotionreport()
	set name = "Check Devotion"
	set category = "RoleUnique.Divine"

	if(!ishuman(src))
		return
	var/datum/devotion/C = src.cleric
	to_chat(src,"My devotion is [C.devotion].")

// Generation Procs

/mob/living/carbon/human/proc/clericpray()
	set name = "Give Prayer"
	set category = "RoleUnique.Divine"

	if(!ishuman(src))
		return
	var/datum/devotion/C = src.cleric
	if(!C || src.stat >= DEAD)
		return
	if(C.devotion >= C.max_devotion)
		to_chat(src, "<font color='red'>I have reached the limit of my devotion...</font>")
		return
	var/prayersesh = 0
	visible_message("[src] kneels their head in prayer.", "I kneel my head in prayer to [patron.name].")
	for(var/i in 1 to 50)
		if(do_after(src, 3 SECONDS, timed_action_flags = (IGNORE_USER_DIR_CHANGE), hidden = FALSE))
			if(C.devotion >= C.max_devotion)
				to_chat(src, "<font color='red'>I have reached the limit of my devotion...</font>")
				break
			var/devotion_multiplier = 1
			if(mind)
				devotion_multiplier += (GET_MOB_SKILL_VALUE_OLD(src, /datum/attribute/skill/magic/holy) / 4)
			var/amount = floor(C.prayer_effectiveness * devotion_multiplier)
			C.update_devotion(amount)
			C.update_progression(amount)
			prayersesh += amount
		else
			visible_message("[src] concludes their prayer.", "I conclude my prayer.")
			break
	to_chat(src, "<font color='purple'>I gained [prayersesh] devotion!</font>")

/datum/devotion/proc/excommunicate()
	if(!HAS_TRAIT(holder_mob, TRAIT_FANATICAL))
		prayer_effectiveness = 0
		forsaken = TRUE
		update_devotion(-devotion)
		to_chat(holder_mob, span_userdanger("I have been forsaken! The gods no longer listen to my prayers nor my requests."))
		STOP_PROCESSING(SSprocessing, src)

/datum/devotion/proc/recommunicate()
	if(!HAS_TRAIT(holder_mob, TRAIT_FANATICAL))
		prayer_effectiveness = initial(prayer_effectiveness)
		forsaken = FALSE
		update_devotion(0)
		to_chat(holder_mob, span_boldnotice("I have been welcomed back into the folds of the gods."))
		if(passive_devotion_gain || passive_progression_gain)
			START_PROCESSING(SSprocessing, src)
