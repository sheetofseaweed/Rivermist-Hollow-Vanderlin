// Sorcerer kit: sorcery points as a long-rest pool, Font of Magic conversions and the metamagic switch.

/// Grants the kit once; jobs with TRAIT_SORCERER call this after their slots exist.
/mob/living/proc/grant_sorcery_kit()
	if(!mind?.is_slot_caster())
		return FALSE
	var/static/list/kit = list(
		/datum/action/cooldown/spell/undirected/sorcery/metamagic,
		/datum/action/cooldown/spell/undirected/sorcery/create_slot,
		/datum/action/cooldown/spell/undirected/sorcery/sacrifice_slot,
	)
	for(var/spell_type in kit)
		add_spell(spell_type, source = src)
	return TRUE

/datum/action/cooldown/spell/undirected/sorcery
	button_icon_state = "thaumaturgy"
	spell_type = SPELL_MANA
	spell_cost = 0
	charge_required = FALSE
	cooldown_time = 1 SECONDS
	invocation_type = INVOCATION_NONE
	spell_requirements = NONE
	spell_flags = SPELL_IGNORE_SPELLBLOCK
	learnable = FALSE
	feature_id = FEATURE_SORCERY_POINTS
	feature_rest = REST_LONG

/// Kit spells never spend the pool through the cast chain; conversions and casts do.
/datum/action/cooldown/spell/undirected/sorcery/get_feature_cost()
	return 0

/datum/action/cooldown/spell/undirected/sorcery/proc/get_points()
	var/datum/spell_slots/slots = register_feature()
	return slots ? slots.get_feature_charges(FEATURE_SORCERY_POINTS) : 0

// Metamagic

/datum/action/cooldown/spell/undirected/sorcery/metamagic
	name = "Metamagic"
	desc = "Arm one metamagic for the next spell it fits. Quickened (3): no charge time. Twinned (slot level, 1 for cantrips): a free second cast on another target within ten seconds. Extended (1): double duration. Distant (1): double range. Subtle (1): no invocation."

/datum/action/cooldown/spell/undirected/sorcery/metamagic/get_feature_button_suffix()
	. = ..()
	var/armed = get_spell_slots()?.get_armed_metamagic()
	if(armed)
		. += " [capitalize(armed)] armed"

/datum/action/cooldown/spell/undirected/sorcery/metamagic/cast(atom/cast_on)
	. = ..()
	var/datum/spell_slots/slots = register_feature()
	if(!slots)
		return
	var/list/options = list(
		"Quickened ([METAMAGIC_QUICKENED_COST] points)" = METAMAGIC_QUICKENED,
		"Twinned (slot level in points)" = METAMAGIC_TWINNED,
		"Extended ([METAMAGIC_EXTENDED_COST] point)" = METAMAGIC_EXTENDED,
		"Distant ([METAMAGIC_DISTANT_COST] point)" = METAMAGIC_DISTANT,
		"Subtle ([METAMAGIC_SUBTLE_COST] point)" = METAMAGIC_SUBTLE,
		"Disarm" = "disarm",
	)
	var/choice = browser_input_list(owner, "Arm which metamagic? Sorcery points: [get_points()]/[slots.get_feature_max(FEATURE_SORCERY_POINTS)]", "Metamagic", options, "Disarm", 20 SECONDS)
	if(!choice || QDELETED(src) || QDELETED(owner))
		return
	var/armed = options[choice]
	if(armed == "disarm")
		slots.arm_metamagic(null)
		owner.balloon_alert(owner, "metamagic disarmed")
	else
		slots.arm_metamagic(armed)
		owner.balloon_alert(owner, "[armed] armed")
	build_all_button_icons(UPDATE_BUTTON_NAME)

// Font of Magic

/datum/action/cooldown/spell/undirected/sorcery/create_slot
	name = "Font of Magic: Create Slot"
	desc = "Spend sorcery points to restore one spent spell slot: 2, 3, 5, 6 or 7 points for levels one to five."
	button_icon_state = "createlight"

/// Restores one slot of the level for its point cost. Returns TRUE on success.
/datum/action/cooldown/spell/undirected/sorcery/create_slot/proc/restore_slot(level)
	var/datum/spell_slots/slots = register_feature()
	var/list/costs = SORCERY_SLOT_COSTS
	if(!slots || level < SPELL_SLOT_MIN || level > SPELL_SLOT_MAX)
		return FALSE
	if(slots.get_max(level) <= 0 || slots.get_current(level) >= slots.get_max(level))
		owner.balloon_alert(owner, "no spent level [level] slot!")
		return FALSE
	if(!slots.use_feature(FEATURE_SORCERY_POINTS, costs[level]))
		owner.balloon_alert(owner, "not enough sorcery points!")
		return FALSE
	slots.restore(level, 1)
	to_chat(owner, span_notice("I shape raw sorcery into a level [level] spell slot. [slots.get_feature_charges(FEATURE_SORCERY_POINTS)] sorcery points remain."))
	return TRUE

/datum/action/cooldown/spell/undirected/sorcery/create_slot/cast(atom/cast_on)
	. = ..()
	var/datum/spell_slots/slots = register_feature()
	if(!slots)
		return
	var/list/costs = SORCERY_SLOT_COSTS
	var/list/options = list()
	for(var/level in SPELL_SLOT_MIN to SPELL_SLOT_MAX)
		if(slots.get_max(level) <= 0 || slots.get_current(level) >= slots.get_max(level))
			continue
		options["Level [level] ([costs[level]] points)"] = level
	if(!length(options))
		owner.balloon_alert(owner, "no spent slots to restore!")
		return
	var/choice = browser_input_list(owner, "Restore which slot? Sorcery points: [get_points()]", "Font of Magic", options, "Cancel", 20 SECONDS)
	if(!choice || !options[choice] || QDELETED(src) || QDELETED(owner))
		return
	restore_slot(options[choice])

/datum/action/cooldown/spell/undirected/sorcery/sacrifice_slot
	name = "Font of Magic: Sacrifice Slot"
	desc = "Break a spell slot into sorcery points: one point per slot level, up to the pool's size."
	button_icon_state = "bloodsteal"

/// Breaks one slot of the level into points. Returns the points gained.
/datum/action/cooldown/spell/undirected/sorcery/sacrifice_slot/proc/break_slot(level)
	var/datum/spell_slots/slots = register_feature()
	if(!slots || !slots.can_spend(level, TRUE))
		return 0
	var/room = slots.get_feature_max(FEATURE_SORCERY_POINTS) - slots.get_feature_charges(FEATURE_SORCERY_POINTS)
	if(room <= 0)
		owner.balloon_alert(owner, "sorcery points are full!")
		return 0
	slots.spend(level)
	var/gained = slots.restore_feature(FEATURE_SORCERY_POINTS, level)
	to_chat(owner, span_notice("I unravel a level [level] spell slot into [gained] sorcery point[gained == 1 ? "" : "s"]. [slots.get_feature_charges(FEATURE_SORCERY_POINTS)] in all."))
	return gained

/datum/action/cooldown/spell/undirected/sorcery/sacrifice_slot/cast(atom/cast_on)
	. = ..()
	var/datum/spell_slots/slots = register_feature()
	if(!slots)
		return
	var/room = slots.get_feature_max(FEATURE_SORCERY_POINTS) - slots.get_feature_charges(FEATURE_SORCERY_POINTS)
	if(room <= 0)
		owner.balloon_alert(owner, "sorcery points are full!")
		return
	var/list/options = list()
	for(var/level in SPELL_SLOT_MIN to SPELL_SLOT_MAX)
		if(slots.get_current(level) <= 0)
			continue
		options["Level [level] (+[min(level, room)] points)"] = level
	if(!length(options))
		owner.balloon_alert(owner, "no slots to sacrifice!")
		return
	var/choice = browser_input_list(owner, "Sacrifice which slot? Sorcery points: [get_points()]", "Font of Magic", options, "Cancel", 20 SECONDS)
	if(!choice || !options[choice] || QDELETED(src) || QDELETED(owner))
		return
	break_slot(options[choice])
