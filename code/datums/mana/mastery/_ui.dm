/// TGUI front for a spell mastery: tracks, catalogue, learning and the prepared set.
/datum/spellbook
	var/mob/living/owner
	var/datum/spell_mastery/mastery
	/// Allows refunding known spells.
	var/unlearn_mode = FALSE

/datum/spellbook/New(mob/living/owner, datum/spell_mastery/_mastery)
	src.owner = owner
	mastery = _mastery || owner?.mind?.get_spell_mastery()

/datum/spellbook/Destroy(force)
	owner = null
	mastery = null
	return ..()

/datum/spellbook/ui_state(mob/user)
	return GLOB.always_state

/datum/spellbook/proc/open_unlearn(mob/user)
	unlearn_mode = TRUE
	ui_interact(user)

/datum/spellbook/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SpellBook")
		ui.open()

/datum/spellbook/ui_static_data(mob/user)
	var/list/data = list()
	data["techniques"] = GLOB.all_techniques
	data["forms"] = GLOB.all_forms
	return data

/datum/spellbook/ui_data(mob/user)
	var/list/data = list()
	if(!mastery)
		return data

	data["unspentFormPoints"] = mastery.unspent_form_points
	data["unspentTechniquePoints"] = mastery.unspent_technique_points
	data["unlearnMode"] = unlearn_mode
	data["usesPreparation"] = mastery.uses_preparation
	data["preparedCount"] = length(mastery.prepared_spells)
	data["maxPrepared"] = mastery.get_max_prepared()
	data["canPrepare"] = mastery.can_prepare(FALSE)
	data["bookAtHand"] = mastery.is_book_at_hand()
	data["inCombatMode"] = !!owner?.cmode
	data["slotInfo"] = get_slot_info()

	var/list/form_modifiers = get_modifiers_by_form()
	var/list/technique_modifiers = get_modifiers_by_technique()

	var/list/technique_data = list()
	for(var/technique in GLOB.all_techniques)
		technique_data += list(list(
			"id" = technique,
			"name" = technique,
			"level" = mastery.get_technique_level(technique),
			"rank" = mastery.get_technique_rank_name(technique),
			"modifiers" = technique_modifiers[technique],
		))
	data["techniqueLevels"] = technique_data

	var/list/form_data = list()
	for(var/form in GLOB.all_forms)
		form_data += list(list(
			"id" = form,
			"name" = form,
			"level" = mastery.get_form_level(form),
			"rank" = mastery.get_form_rank_name(form),
			"modifiers" = form_modifiers[form],
		))
	data["formLevels"] = form_data

	var/list/spell_data = list()
	for(var/datum/action/cooldown/spell/spell_path as anything in subtypesof(/datum/action/cooldown/spell))
		if(!initial(spell_path.learnable))
			continue
		var/technique = initial(spell_path.required_technique)
		var/form = initial(spell_path.required_form)
		if(!form)
			continue
		var/is_unlocked = (spell_path in mastery.unlocked_spells)
		var/needs_prep = mastery.needs_preparation(spell_path)
		var/slot_level = initial(spell_path.slot_level)
		var/list/prerequisite_data = list()
		for(var/datum/action/cooldown/spell/prerequisite as anything in get_spell_prerequisites(spell_path))
			prerequisite_data += list(list(
				"name" = initial(prerequisite.name),
				"known" = (prerequisite in mastery.unlocked_spells),
			))

		spell_data += list(list(
			"path" = "[spell_path]",
			"name" = initial(spell_path.name),
			"desc" = initial(spell_path.desc),
			"technique" = technique,
			"form" = form,
			"level" = initial(spell_path.required_level),
			"slotLevel" = isnull(slot_level) ? null : slot_level,
			"formCost" = form ? 1 : 0,
			"techniqueCost" = technique ? 1 : 0,
			"unlocked" = is_unlocked,
			"canLearn" = mastery.can_learn_spell(spell_path),
			"canUnlearn" = is_unlocked,
			"needsPreparation" = needs_prep,
			"prepared" = is_unlocked && mastery.is_prepared(spell_path),
			"icon" = "[initial(spell_path.button_icon)]",
			"iconState" = initial(spell_path.button_icon_state),
			"heretical" = initial(spell_path.heretical_spell),
			"prerequisites" = prerequisite_data,
		))
	data["spells"] = spell_data
	return data

/datum/spellbook/proc/get_slot_info()
	return owner?.mind?.spell_slots?.get_ui_info()

/datum/spellbook/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	if(!mastery)
		return

	switch(action)
		if("invest_technique")
			var/technique = params["technique"]
			if(!(technique in GLOB.all_techniques))
				return
			. = mastery.invest_technique(technique, 1)

		if("invest_form")
			var/form = params["form"]
			if(!(form in GLOB.all_forms))
				return
			. = mastery.invest_form(form, 1)

		if("learn_spell")
			var/spell_path = text2path(params["path"])
			. = mastery.try_learn_spell(spell_path)

		if("unlearn_spell")
			var/spell_path = text2path(params["path"])
			. = mastery.try_unlearn_spell(spell_path)

		if("prepare_spell")
			var/spell_path = text2path(params["path"])
			. = mastery.set_prepared(spell_path, !!params["state"])

/datum/spellbook/proc/get_modifiers_by_form()
	return get_modifiers_by_key("form")

/datum/spellbook/proc/get_modifiers_by_technique()
	return get_modifiers_by_key("technique")

/// Collects gear modifiers from the body, summed per form or technique.
/datum/spellbook/proc/get_modifiers_by_key(key)
	var/mob/living/body = mastery?.get_body()
	if(!body)
		return list()
	var/list/modifiers = list()
	SEND_SIGNAL(body, COMSIG_SPELL_REQUEST_MODIFIERS, modifiers)

	var/list/by_key = list()
	for(var/list/entry in modifiers)
		var/id = entry[key]
		if(!id)
			continue
		if(!by_key[id])
			by_key[id] = list(SPELLMOD_COST = 1, SPELLMOD_CASTSPEED = 1, SPELLMOD_MAGNITUDE = 0)
		by_key[id][SPELLMOD_COST] *= entry[SPELLMOD_COST]
		by_key[id][SPELLMOD_CASTSPEED] *= entry[SPELLMOD_CASTSPEED]
		by_key[id][SPELLMOD_MAGNITUDE] += entry[SPELLMOD_MAGNITUDE]
	return by_key
