/obj/structure/chem_separator
	name = "alembic"
	desc = "A device that separates liquids through distillation."
	icon = 'icons/obj/medical/chemical.dmi'
	icon_state = "separator"
	density = TRUE
	anchored = TRUE
	light_power = 1
	var/fill_icon = 'icons/obj/reagentfillings.dmi'
	var/fill_icon_state = "separator"
	/// Icons for different percentages of reagent volume.
	var/list/fill_icon_thresholds = list(1, 30, 80)
	/// Thermometer icon thresholds in Celsius.
	var/list/temperature_icon_thresholds = list(0, 50, 100)
	/// Whether the burner is currently heating the mixture.
	var/burning = FALSE
	/// Whether the chosen reagent is actively boiling.
	var/boiling = FALSE
	var/datum/looping_sound/boiling/soundloop
	/// Heating rate in degrees per second for a full separator.
	var/heating_rate = 5
	/// Maximum amount distilled per second.
	var/distillation_rate = 5
	/// Current separation temperature in Kelvin.
	var/required_temp = T0C + 100
	/// Temporary vapor storage.
	var/datum/reagents/condenser
	/// Type of reagent currently being separated.
	var/separating_reagent_type
	/// Condensate container.
	var/obj/item/reagent_containers/beaker
	var/distill_message_shown = FALSE
	var/datum/distillation_recipe/active_recipe

/obj/structure/chem_separator/Initialize(mapload)
	. = ..()
	create_reagents(300, TRANSPARENT | INJECTABLE)
	condenser = new /datum/reagents(300, TRANSPARENT | INJECTABLE)
	soundloop = new(src, FALSE)

/obj/structure/chem_separator/Destroy()
	STOP_PROCESSING(SSobj, src)
	soundloop?.stop()
	QDEL_NULL(soundloop)
	QDEL_NULL(condenser)
	if(beaker && !QDELETED(beaker))
		beaker.forceMove(drop_location())
	beaker = null
	active_recipe = null
	separating_reagent_type = null
	return ..()

/obj/structure/chem_separator/handle_atom_del(atom/deleted_atom)
	. = ..()
	if(deleted_atom != beaker)
		return
	beaker = null
	stop()

/obj/structure/chem_separator/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return
	ui_interact(user)

/obj/structure/chem_separator/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(user.cmode)
		return NONE

	if(ignite_with(tool, user))
		return ITEM_INTERACT_SUCCESS

	if(!istype(tool, /obj/item/reagent_containers) || (tool.item_flags & ABSTRACT) || !tool.is_open_container())
		return NONE

	var/obj/item/reagent_containers/new_beaker = tool
	if(!user.transferItemToLoc(new_beaker, src))
		return ITEM_INTERACT_BLOCKING
	replace_beaker(new_beaker)
	balloon_alert(user, "container inserted")
	return ITEM_INTERACT_SUCCESS

/// Attempts to ignite the separator with an item that supplies an ignition effect.
/obj/structure/chem_separator/proc/ignite_with(obj/item/tool, mob/living/user)
	var/ignition_message = tool.ignition_effect(src, user)
	if(!ignition_message)
		return FALSE
	user.visible_message(ignition_message)
	start()
	return TRUE

/// Inserts, replaces, or ejects the condensate container.
/obj/structure/chem_separator/proc/replace_beaker(obj/item/reagent_containers/new_beaker)
	if(beaker == new_beaker)
		return FALSE
	if(beaker)
		stop()
		beaker.forceMove(drop_location())
		beaker = null
	if(new_beaker)
		beaker = new_beaker
		beaker.forceMove(src)
	update_appearance(UPDATE_ICON)
	return TRUE

/obj/structure/chem_separator/fire_act(exposed_temperature, exposed_volume)
	if(!burning)
		start()
	return ..()

/obj/structure/chem_separator/extinguish()
	. = ..()
	if(burning)
		stop()

/// Starts heating after selecting the first recipe-bearing reagent, or the lowest boiling reagent.
/obj/structure/chem_separator/proc/start()
	if(burning || !beaker || !reagents.total_volume || beaker.reagents.holder_full())
		return FALSE

	var/list/reagents_sorted = sortList(reagents.reagent_list.Copy(), GLOBAL_PROC_REF(cmp_reagents_boiling_asc))
	var/datum/reagent/chosen_reagent
	for(var/datum/reagent/candidate as anything in reagents_sorted)
		if(length(GLOB.distillation_recipes[candidate.type]))
			chosen_reagent = candidate
			break
	if(!chosen_reagent)
		chosen_reagent = reagents_sorted[1]
	if(!chosen_reagent)
		return FALSE

	separating_reagent_type = chosen_reagent.type
	required_temp = chosen_reagent.boiling_point
	burning = TRUE
	update_appearance(UPDATE_ICON)
	START_PROCESSING(SSobj, src)
	return TRUE

/// Stops heating and returns any uncondensed vapor to the input mixture.
/obj/structure/chem_separator/proc/stop()
	STOP_PROCESSING(SSobj, src)
	soundloop?.stop()
	if(condenser?.total_volume)
		condenser.trans_to(reagents, condenser.total_volume)
	separating_reagent_type = null
	active_recipe = null
	distill_message_shown = FALSE
	boiling = FALSE
	burning = FALSE
	update_appearance(UPDATE_ICON)

/// Moves the inserted container's contents into the separator.
/obj/structure/chem_separator/proc/load()
	if(burning || !beaker?.reagents.total_volume || reagents.holder_full())
		return FALSE
	beaker.reagents.trans_to(reagents, beaker.reagents.total_volume)
	update_appearance(UPDATE_ICON)
	return TRUE

/// Moves the separator's contents into the inserted container.
/obj/structure/chem_separator/proc/unload()
	if(burning || !reagents.total_volume || !beaker || beaker.reagents.holder_full())
		return FALSE
	reagents.trans_to(beaker.reagents, reagents.total_volume)
	update_appearance(UPDATE_ICON)
	return TRUE

/obj/structure/chem_separator/proc/can_process(turf/location)
	if(!burning || !location || !separating_reagent_type || !beaker)
		return FALSE
	if(T0C + location.return_temperature() > required_temp)
		return FALSE
	if(beaker.reagents.holder_full())
		return FALSE
	if(!reagents.get_reagent_amount(separating_reagent_type))
		return FALSE
	return TRUE

/obj/structure/chem_separator/proc/check_recipe()
	var/datum/distillation_recipe/previous_recipe = active_recipe
	if(!separating_reagent_type)
		active_recipe = null
	else
		active_recipe = find_distillation_recipe(separating_reagent_type, reagents)
	if(active_recipe != previous_recipe)
		distill_message_shown = FALSE

/obj/structure/chem_separator/process(seconds_per_tick)
	var/turf/location = get_turf(src)
	if(!can_process(location))
		stop()
		return

	if(reagents.chem_temp < required_temp)
		reagents.adjust_thermal_energy(heating_rate * seconds_per_tick * SPECIFIC_HEAT_DEFAULT * reagents.maximum_volume)
		reagents.chem_temp = min(reagents.chem_temp, required_temp)
		update_appearance(UPDATE_ICON)
		return

	if(!boiling)
		boiling = TRUE
		distill_message_shown = FALSE
		soundloop.start()

	check_recipe()
	var/vapor_amount = min(distillation_rate * seconds_per_tick, reagents.get_reagent_amount(separating_reagent_type))
	if(active_recipe)
		var/result_ratio = 0
		for(var/result_type in active_recipe.results)
			result_ratio += active_recipe.results[result_type]
		if(result_ratio > 0)
			var/output_space = beaker.reagents.maximum_volume - beaker.reagents.total_volume
			vapor_amount = min(vapor_amount, output_space / result_ratio)

	if(vapor_amount <= 0)
		stop()
		return

	var/datum/reagent/source_reagent = reagents.get_reagent(separating_reagent_type)
	var/distilled_data = reagents.copy_data(source_reagent)
	var/distilled_amount = reagents.trans_id_to(condenser, separating_reagent_type, vapor_amount)
	if(!distilled_amount)
		stop()
		return
	condenser.chem_temp = T0C + location.return_temperature()

	if(active_recipe)
		if(!distill_message_shown)
			if(active_recipe.distill_message)
				visible_message(active_recipe.distill_message)
			if(active_recipe.distill_sound)
				playsound(src, active_recipe.distill_sound, 50, TRUE)
			distill_message_shown = TRUE

		condenser.remove_reagent(separating_reagent_type, distilled_amount)
		if(active_recipe.consume_reagents)
			for(var/required_reagent in active_recipe.required_reagents)
				var/consume_amount = active_recipe.required_reagents[required_reagent] * (distilled_amount / distillation_rate)
				reagents.remove_reagent(required_reagent, consume_amount)
		for(var/result_type in active_recipe.results)
			var/result_amount = active_recipe.results[result_type] * distilled_amount
			var/result_data = distilled_data
			if(islist(distilled_data))
				var/list/list_data = distilled_data
				result_data = list_data.Copy()
			beaker.reagents.add_reagent(result_type, result_amount, result_data)
		active_recipe.on_distill(reagents, beaker.reagents, distilled_amount)
	else if(!has_potential_recipe())
		condenser.trans_to(beaker.reagents, condenser.total_volume)

	update_appearance(UPDATE_ICON)

/// Returns whether the selected reagent has a recipe whose other conditions are not yet met.
/obj/structure/chem_separator/proc/has_potential_recipe()
	if(!separating_reagent_type)
		return FALSE
	return length(GLOB.distillation_recipes[separating_reagent_type]) > 0

/obj/structure/chem_separator/update_overlays()
	. = ..()
	set_light(burning ? light_power : 0)
	if(burning)
		. += mutable_appearance(icon, "[icon_state]_burn")
		. += emissive_appearance(icon, "[icon_state]_burn", src)

	if(reagents.total_volume)
		var/is_glowing = FALSE
		for(var/datum/reagent/reagent as anything in reagents.reagent_list)
			if(reagent.glows)
				is_glowing = TRUE
				break
		var/threshold
		for(var/index in 1 to fill_icon_thresholds.len)
			if(ROUND_UP(100 * reagents.total_volume / reagents.maximum_volume) >= fill_icon_thresholds[index])
				threshold = index
		if(threshold)
			var/fill_name = "[fill_icon_state]_m_[fill_icon_thresholds[threshold]]"
			var/mutable_appearance/filling = mutable_appearance(fill_icon, fill_name)
			filling.color = mix_color_from_reagents(reagents.reagent_list)
			. += filling
			if(is_glowing)
				. += emissive_appearance(fill_icon, fill_name)

	if(beaker)
		. += "[icon_state]_beaker"
		if(beaker.reagents.total_volume)
			var/is_glowing = FALSE
			for(var/datum/reagent/reagent as anything in beaker.reagents.reagent_list)
				if(reagent.glows)
					is_glowing = TRUE
					break
			var/threshold
			for(var/index in 1 to fill_icon_thresholds.len)
				if(ROUND_UP(100 * beaker.reagents.total_volume / beaker.reagents.maximum_volume) >= fill_icon_thresholds[index])
					threshold = index
			if(threshold)
				var/fill_name = "[fill_icon_state]_b_[fill_icon_thresholds[threshold]]"
				var/mutable_appearance/filling = mutable_appearance(fill_icon, fill_name)
				filling.color = mix_color_from_reagents(beaker.reagents.reagent_list)
				. += filling
				if(is_glowing)
					. += emissive_appearance(fill_icon, fill_name)
		if(boiling && separating_reagent_type)
			var/datum/reagent/reagent_prototype = GLOB.chemical_reagents_list[separating_reagent_type]
			var/mutable_appearance/dripping = mutable_appearance(fill_icon, "separator_dripping")
			dripping.color = reagent_prototype?.color || COLOR_WHITE
			. += dripping

	var/temperature_threshold
	for(var/index in 1 to temperature_icon_thresholds.len)
		if(ROUND_UP(reagents.chem_temp - T0C) >= temperature_icon_thresholds[index])
			temperature_threshold = index
	if(temperature_threshold)
		var/fill_name = "[icon_state]_temp_[temperature_icon_thresholds[temperature_threshold]]"
		. += mutable_appearance(icon, fill_name)

/obj/structure/chem_separator/ui_state(mob/user)
	return GLOB.physical_state

/obj/structure/chem_separator/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ChemSeparator", name)
		ui.open()

/obj/structure/chem_separator/ui_data(mob/user)
	var/list/data = list()
	var/turf/location = get_turf(src)
	data["is_burning"] = burning
	data["temperature"] = reagents.total_volume ? reagents.chem_temp - T0C : location?.return_temperature()
	data["own_total_volume"] = reagents.total_volume
	data["own_maximum_volume"] = reagents.maximum_volume
	data["own_reagent_color"] = mix_color_from_reagents(reagents.reagent_list)
	data["beaker"] = !!beaker
	if(beaker)
		data["beaker_total_volume"] = beaker.reagents.total_volume
		data["beaker_maximum_volume"] = beaker.reagents.maximum_volume
		data["beaker_reagent_color"] = mix_color_from_reagents(beaker.reagents.reagent_list)
	return data

/obj/structure/chem_separator/ui_act(action, params)
	if(..())
		return TRUE

	switch(action)
		if("load")
			return load()
		if("unload")
			return unload()
		if("start")
			return start()
		if("stop")
			if(!burning)
				return FALSE
			stop()
			return TRUE
		if("eject")
			if(!beaker)
				return FALSE
			return replace_beaker()
	return FALSE
