#define TOWNWATCH_COMMAND_MEMBER 0
#define TOWNWATCH_COMMAND_SERGEANT 1
#define TOWNWATCH_COMMAND_CAPTAIN 2

#define TOWNWATCH_ORDER_ATTACK "attack"
#define TOWNWATCH_ORDER_MOVEMENT "movement"
#define TOWNWATCH_ORDER_DEFENSE "defense"

#define TOWNWATCH_TARGET_SINGLE 1
#define TOWNWATCH_TARGET_AREA 2

#define TOWNWATCH_COMMAND_RANGE 7
#define TOWNWATCH_COMMAND_COOLDOWN (120 SECONDS)

/datum/town_watch_command_definition
	var/id
	var/name
	var/description

	// Radial menu presentation.
	var/radial_icon_file
	var/radial_icon_state

	// SINGLE = click one target.
	// AREA = affect all valid Town Watch in range.
	var/targeting_mode = TOWNWATCH_TARGET_SINGLE
	var/range = TOWNWATCH_COMMAND_RANGE

	// Mechanical effect.
	var/duration = 30 SECONDS
	var/list/stat_modifiers = list()
	var/list/granted_traits = list()

	// Message shown to the recipient.
	var/target_message

/datum/town_watch_command_definition/attack
	id = TOWNWATCH_ORDER_ATTACK
	name = "Attack"
	description = "Orders nearby Town Watch to press the attack."
	targeting_mode = TOWNWATCH_TARGET_AREA
	duration = 30 SECONDS
	stat_modifiers = list(
		"strength" = 2,
		"endurance" = 1
	)
	target_message = "Your superior orders you to attack!"

	radial_icon_file = null
	radial_icon_state = "attack"

/datum/town_watch_command_definition/movement
	id = TOWNWATCH_ORDER_MOVEMENT
	name = "Move!"
	description = "Orders a Town Watch member to move quickly."
	targeting_mode = TOWNWATCH_TARGET_SINGLE
	duration = 15 SECONDS
	stat_modifiers = list(
		"speed" = 2
	)
	target_message = "Your superior orders you to move!"

	radial_icon_file = null
	radial_icon_state = "movement"

/datum/town_watch_command_definition/defense
	id = TOWNWATCH_ORDER_DEFENSE
	name = "Defend!"
	description = "Orders Town Watch to hold their ground."
	targeting_mode = TOWNWATCH_TARGET_AREA
	duration = 45 SECONDS
	stat_modifiers = list(
		"perception" = 2,
		"endurance" = 1
	)
	target_message = "Your superior orders you to hold the line!"

	radial_icon_file = null
	radial_icon_state = "defense"

/datum/town_watch_command_trait
	var/mob/living/carbon/human/owner

	var/authority_level = TOWNWATCH_COMMAND_MEMBER

	var/list/commands = list()

	var/list/text_banks = list(
		TOWNWATCH_ORDER_ATTACK = list(
			"FORWARD!",
			"PRESS THE ATTACK!",
			"ENGAGE!",
			"TO ARMS!"
		),

		TOWNWATCH_ORDER_MOVEMENT = list(
			"MOVE!",
			"MOVE, MOVE!",
			"GET MOVING!",
			"FORWARD!"
		),

		TOWNWATCH_ORDER_DEFENSE = list(
			"HOLD!",
			"HOLD THE LINE!",
			"STAND FAST!",
			"DEFEND THIS POSITION!"
		)
	)

	var/list/command_emotes = list(
		TOWNWATCH_ORDER_ATTACK = "haltyell",
		TOWNWATCH_ORDER_MOVEMENT = "haltyell",
		TOWNWATCH_ORDER_DEFENSE = "haltyell"
	)

	var/datum/action/cooldown/spell/undirected/town_watch_command/action
	var/datum/radial_menu/persistent/command_menu
	var/datum/town_watch_command_targeter/targeter

/datum/action/cooldown/spell/undirected/town_watch_command
	name = "Issue Order"
	desc = "Issue an order to the Town Watch."
	background_icon = 'icons/mob/actions/roguespells.dmi'
	background_icon_state = "spell0"
	base_background_icon_state = "spell0"
	active_background_icon_state = "spell1"
	button_icon = 'icons/mob/actions/roguespells.dmi'
	button_icon_state = "command"
	check_flags = AB_CHECK_CONSCIOUS|AB_CHECK_PHASED
	cooldown_time = TOWNWATCH_COMMAND_COOLDOWN
	text_cooldown = TRUE
	spell_type = SPELL_MANA
	spell_cost = 0
	charge_required = FALSE
	click_to_activate = FALSE
	var/datum/town_watch_command_trait/command_trait

/datum/action/cooldown/spell/undirected/town_watch_command/IsAvailable()
	if(!command_trait || !command_trait.owner || !HAS_TRAIT(command_trait.owner, TRAIT_TOWNWATCH_COMMAND))
		return FALSE
	return ..()

/datum/action/cooldown/spell/undirected/town_watch_command/can_cast_spell(feedback = TRUE)
	if(!command_trait || !command_trait.owner || !HAS_TRAIT(command_trait.owner, TRAIT_TOWNWATCH_COMMAND))
		if(feedback)
			owner.balloon_alert(owner, "I no longer have authority to issue orders.")
		return FALSE
	return TRUE

/datum/action/cooldown/spell/undirected/town_watch_command/cast(atom/cast_on)
	. = ..()
	if(!command_trait || !command_trait.owner || !HAS_TRAIT(command_trait.owner, TRAIT_TOWNWATCH_COMMAND))
		return FALSE
	if(command_trait.command_menu)
		return FALSE
	command_trait.open_command_menu()
	return !!command_trait.command_menu

/datum/action/cooldown/spell/undirected/town_watch_command/Grant(mob/grant_to)
	. = ..()
	if(owner && !button_icon)
		button_icon = 'icons/mob/actions/roguespells.dmi'
	if(owner && !button_icon_state)
		button_icon_state = "command"

/datum/town_watch_command_trait/sergeant
	authority_level = TOWNWATCH_COMMAND_SERGEANT

/datum/town_watch_command_trait/captain
	authority_level = TOWNWATCH_COMMAND_CAPTAIN

/datum/town_watch_command_trait/New(mob/living/carbon/human/new_owner)
	owner = new_owner

	commands = list(
		new /datum/town_watch_command_definition/attack,
		new /datum/town_watch_command_definition/movement,
		new /datum/town_watch_command_definition/defense
	)

	action = new /datum/action/cooldown/spell/undirected/town_watch_command
	action.command_trait = src
	action.Grant(owner)

	..()


/datum/town_watch_command_trait/Destroy()
	close_command_menu()
	cleanup_targeter()

	if(action)
		action.Remove(owner)
		QDEL_NULL(action)

	owner = null
	commands = null
	text_banks = null
	command_emotes = null

	return ..()

/mob/living/carbon/human/proc/grant_town_watch_command(authority_level = null)
	if(town_watch_command_trait)
		if(isnull(authority_level) || town_watch_command_trait.authority_level == authority_level)
			return town_watch_command_trait
		remove_town_watch_command()

	if(isnull(authority_level))
		if(mind?.assigned_role)
			var/datum/job/J = mind.assigned_role
			if(J?.parent_job)
				J = J.parent_job

			if(istype(J, /datum/job/watch_captain))
				authority_level = TOWNWATCH_COMMAND_CAPTAIN
			else if(istype(J, /datum/job/watch_sergeant))
				authority_level = TOWNWATCH_COMMAND_SERGEANT

	if(isnull(authority_level))
		return

	var/trait_type

	switch(authority_level)
		if(TOWNWATCH_COMMAND_SERGEANT)
			trait_type = /datum/town_watch_command_trait/sergeant
		if(TOWNWATCH_COMMAND_CAPTAIN)
			trait_type = /datum/town_watch_command_trait/captain
		else
			return

	var/datum/town_watch_command_trait/new_trait = new trait_type(src)
	town_watch_command_trait = new_trait
	ADD_TRAIT(src, TRAIT_TOWNWATCH_COMMAND, TOWNWATCH_COMMAND_TRAIT_SOURCE)
	return new_trait

/mob/living/carbon/human/proc/remove_town_watch_command()
	if(!town_watch_command_trait)
		return

	REMOVE_TRAIT(src, TRAIT_TOWNWATCH_COMMAND, TOWNWATCH_COMMAND_TRAIT_SOURCE)
	QDEL_NULL(town_watch_command_trait)

/mob/living/carbon/human/proc/sync_town_watch_command()
	if(HAS_TRAIT(src, TRAIT_TOWNWATCH_COMMAND))
		if(!town_watch_command_trait)
			grant_town_watch_command()
		return

	if(town_watch_command_trait)
		remove_town_watch_command()

/mob/living/carbon/human/proc/is_town_watch_member()
	if(!mind)
		return FALSE

	var/datum/job/J = mind.assigned_role
	if(!J)
		return FALSE

	if(J.parent_job)
		J = J.parent_job

	if(!(J.department_flag & TOWNWATCH))
		return FALSE

	return stat != DEAD

/mob/living/carbon/human/proc/get_town_watch_command_authority()
	if(!town_watch_command_trait)
		return TOWNWATCH_COMMAND_MEMBER

	return town_watch_command_trait.authority_level

/datum/town_watch_command_trait/proc/can_target(mob/living/carbon/human/target)
	if(!target || target == owner)
		return FALSE

	if(!target.is_town_watch_member())
		return FALSE

	var/target_authority = target.get_town_watch_command_authority()

	// You may command people below your rank.
	if(target_authority >= authority_level)
		return FALSE

	return TRUE

/datum/town_watch_command_trait/proc/open_command_menu()
	if(!owner || !owner.client)
		return

	if(command_menu)
		return

	var/list/choices = list()

	for(var/datum/town_watch_command_definition/command as anything in commands)
		var/datum/radial_menu_choice/choice = new

		choice.name = command.name
		choice.info = command.description

		if(command.radial_icon_file && command.radial_icon_state)
			choice.image = image(command.radial_icon_file, command.radial_icon_state)

		choices[command] = choice

	var/menu_id = "townwatch_command_[REF(owner)]"
	command_menu = show_radial_menu_persistent(owner, owner, choices, CALLBACK(src, TYPE_PROC_REF(/datum/town_watch_command_trait, command_selected)), menu_id, 48, TRUE, "radial_slice")

/datum/town_watch_command_trait/proc/command_selected(datum/town_watch_command_definition/command, params)
	close_command_menu()

	if(!command)
		return

	if(!owner || !HAS_TRAIT(owner, TRAIT_TOWNWATCH_COMMAND))
		return

	if(!owner.is_town_watch_member())
		return

	switch(command.targeting_mode)
		if(TOWNWATCH_TARGET_SINGLE)
			start_target_selection(command)

		if(TOWNWATCH_TARGET_AREA)
			issue_area_command(command)

/datum/town_watch_command_targeter
	var/client/owner
	var/datum/town_watch_command_trait/command_trait
	var/datum/town_watch_command_definition/command

/datum/town_watch_command_targeter/New(client/new_owner, datum/town_watch_command_trait/new_trait, datum/town_watch_command_definition/new_command)
	owner = new_owner
	command_trait = new_trait
	command = new_command

	owner.mouse_pointer_icon = null
	owner.click_intercept = src

/datum/town_watch_command_targeter/proc/InterceptClickOn(mob/living/carbon/human/user, params, atom/target)
	var/list/modifiers = params2list(params)

	if(modifiers["right"])
		cleanup()
		return TRUE

	if(istype(target, /atom/movable/screen))
		return FALSE

	if(!istype(target, /mob/living/carbon/human))
		return TRUE

	var/mob/living/carbon/human/H = target

	if(command_trait.issue_command(command, H))
		cleanup()

	return TRUE

/datum/town_watch_command_targeter/proc/cleanup()
	if(owner)
		if(owner.click_intercept == src)
			owner.click_intercept = null

		owner.mouse_pointer_icon = null
		owner.mob?.update_mouse_pointer()

	owner = null
	command_trait = null
	command = null

/datum/town_watch_command_trait/proc/issue_command(datum/town_watch_command_definition/command, mob/living/carbon/human/target)
	if(!owner)
		return FALSE

	if(!HAS_TRAIT(owner, TRAIT_TOWNWATCH_COMMAND))
		return FALSE

	if(!can_target(target))
		to_chat(owner, span_warning("I cannot give orders to that person."))
		return FALSE

	if(get_dist(owner, target) > command.range)
		to_chat(owner, span_warning("That person is too far away to hear my order."))
		return FALSE

	announce_command(command)

	var/datum/status_effect/buff/town_watch_order/effect = target.apply_status_effect(/datum/status_effect/buff/town_watch_order, src, command)

	if(!effect)
		return FALSE

	action.StartCooldown()

	return TRUE

/datum/town_watch_command_trait/proc/issue_area_command(datum/town_watch_command_definition/command)
	if(!owner || !owner.is_town_watch_member())
		return FALSE

	if(!owner.can_speak_vocal())
		to_chat(owner, span_warning("I cannot give orders without being able to speak."))
		return FALSE

	var/list/targets = list()

	for(var/mob/living/carbon/human/H in view(command.range, owner))
		if(!can_target(H))
			continue

		targets += H

	if(!length(targets))
		to_chat(owner, span_warning("There is nobody under my command nearby."))
		return FALSE

	announce_command(command)

	var/applied = 0

	for(var/mob/living/carbon/human/H in targets)
		var/datum/status_effect/buff/town_watch_order/effect = H.apply_status_effect(/datum/status_effect/buff/town_watch_order, src, command)

		if(effect)
			applied++

	if(!applied)
		return FALSE

	action.StartCooldown()

	return TRUE

/datum/town_watch_command_trait/proc/announce_command(datum/town_watch_command_definition/command)
	var/list/bank = text_banks[command.id]

	if(length(bank))
		owner.say(pick(bank))

	var/emote_name = command_emotes[command.id]

	if(emote_name)
		owner.emote(emote_name)

/datum/status_effect/buff/town_watch_order
	id = "town_watch_order"
	status_type = STATUS_EFFECT_REPLACE
	alert_type = /atom/movable/screen/alert/status_effect/town_watch_order

	var/datum/town_watch_command_trait/issuer_trait
	var/mob/living/carbon/human/issuer
	var/datum/town_watch_command_definition/command
	var/authority_level

/datum/status_effect/buff/town_watch_order/on_creation(mob/living/carbon/human/new_owner, datum/town_watch_command_trait/new_issuer_trait, datum/town_watch_command_definition/new_command)
	issuer_trait = new_issuer_trait
	issuer = new_issuer_trait?.owner
	command = new_command

	if(issuer_trait)
		authority_level = issuer_trait.authority_level

	effectedstats = command.stat_modifiers.Copy()
	duration = command.duration

	. = ..()

	if(linked_alert && command)
		linked_alert.name = command.name
		linked_alert.desc = command.description

/datum/status_effect/buff/town_watch_order/on_apply()
	. = ..()

	if(!.)
		return FALSE

	if(command)
		for(var/trait in command.granted_traits)
			ADD_TRAIT(owner, trait, src)

		if(command.target_message)
			to_chat(owner, span_blue(command.target_message))

	return TRUE


/datum/status_effect/buff/town_watch_order/on_remove()
	if(command)
		for(var/trait in command.granted_traits)
			REMOVE_TRAIT(owner, trait, src)

	. = ..()

/atom/movable/screen/alert/status_effect/town_watch_order
	name = "Under Orders"
	desc = "A Town Watch superior has issued you an order."
	icon_state = "buff"

/datum/town_watch_command_trait/proc/close_command_menu()
	if(command_menu)
		if(!QDELETED(command_menu))
			qdel(command_menu)

	command_menu = null


/datum/town_watch_command_trait/proc/cleanup_targeter()
	if(targeter)
		targeter.cleanup()
		QDEL_NULL(targeter)

/datum/town_watch_command_trait/proc/start_target_selection(datum/town_watch_command_definition/command)
	if(!owner?.client)
		return

	if(owner.client.click_intercept)
		to_chat(owner, span_warning("I am already selecting a target."))
		return

	cleanup_targeter()
	targeter = new /datum/town_watch_command_targeter(owner.client, src, command)
	to_chat(owner, span_notice("Select a Town Watch member to receive [command.name]. Right-click to cancel."))

