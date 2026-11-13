/**
 * Admin right-click menu: three entries (Admin..., GM..., Debug...) instead of thirty.
 *
 * The admin verbs listed here are hidden from the right-click menu (set popup_menu = FALSE in
 * their own files) but stay real verbs: the command bar, hotkeys and the Admin Menu keep working.
 * Each entry lists only the actions that fit the clicked target and that the admin's rights grant,
 * then calls the original verb, so its own checks, confirmations and logging all still apply.
 */

/// group -> list of list(name, proc path, required target type). Order is the order shown.
/proc/admin_context_actions()
	var/static/list/actions = list(
		"Admin" = list(
			list("Show Player Panel", /datum/admins/proc/show_player_panel, /mob),
			list("Admin PM", /client/proc/cmd_admin_pm_context, /mob),
			list("Subtle Message", /client/proc/cmd_admin_subtle_message, /mob),
			list("Get Mob", /client/proc/cmd_get_mob, /mob),
			list("Heal Mob", /datum/admins/proc/admin_heal, /mob/living),
			list("Rejuvenate", /client/proc/cmd_admin_rejuvenate, /mob/living),
			list("Godmode", /client/proc/cmd_admin_godmode, /mob),
			list("Toggle Sleeping", /datum/admins/proc/admin_sleep, /mob/living),
			list("Check Contents", /client/proc/cmd_admin_check_contents, /mob/living),
			list("Drop Everything", /client/proc/cmd_admin_drop_everything, /mob),
			list("Send To Cryo", /client/proc/send_to_cryo, /mob),
			list("Delete", /client/proc/cmd_admin_delete, /atom),
		),
		"GM" = list(
			list("Direct Narrate", /client/proc/cmd_admin_direct_narrate, /mob),
			list("Local Narrate", /client/proc/cmd_admin_local_narrate, /atom),
			list("Force Speech", /client/proc/force_say, /mob/living),
			list("Send Messenger Bird Letter", /client/proc/send_bird_letter, /mob),
			list("Give Spell", /client/proc/give_spell, /mob),
			list("Remove Spell", /client/proc/remove_spell, /mob),
			list("Bless", /datum/admins/proc/admin_bless, /mob/living/carbon/human),
			list("Curse", /datum/admins/proc/admin_curse, /mob/living/carbon/human),
			list("Anoint New Priest", /datum/admins/proc/anoint_priest, /mob/living/carbon/human),
			list("Trigger Subclass Menu", /datum/admins/proc/prompt_subclass, /mob/living),
			list("Select Equipment", /client/proc/cmd_admin_dress, /mob),
			list("Make Simple Animal", /client/proc/cmd_admin_animalize, /mob),
			list("Assume Direct Control", /client/proc/cmd_assume_direct_control, /mob),
			list("Give Control To Player", /client/proc/cmd_give_control_to_player, /mob),
			list("Smite", /client/proc/smite, /mob/living),
			list("Heart Attack", /client/proc/heart_attack, /mob/living/carbon),
			list("Explosion", /client/proc/cmd_admin_explosion, /atom),
			list("Gib", /client/proc/cmd_admin_gib, /mob),
		),
		"Debug" = list(
			list("View Variables", /client/proc/debug_variables, /datum),
			list("Mark Object", /client/proc/mark_datum_mapview, /datum),
			list("Atom ProcCall", /client/proc/callproc_datum, /datum),
		),
	)
	return actions

/client/proc/context_menu_admin(atom/target as mob|obj|turf in view())
	set name = "Admin..."
	set category = null
	set desc = "Player and moderation actions on this target."
	open_admin_context_group("Admin", target)

/client/proc/context_menu_gm(atom/target as mob|obj|turf in view())
	set name = "GM..."
	set category = null
	set desc = "Storytelling and game master actions on this target."
	open_admin_context_group("GM", target)

/client/proc/context_menu_debug(atom/target as mob|obj|turf in view())
	set name = "Debug..."
	set category = null
	set desc = "View Variables, marking and proc calls on this target."
	open_admin_context_group("Debug", target)

/// The verbs added for the right-click menu. Granted to every admin by add_admin_menu_verbs().
/proc/admin_context_menu_verbs()
	return list(/client/proc/context_menu_admin, /client/proc/context_menu_gm, /client/proc/context_menu_debug)

/// Lists the actions of one group that fit target and that this admin holds, then runs the pick.
/client/proc/open_admin_context_group(group, atom/target)
	if(!holder || QDELETED(target))
		return
	var/list/choices = list()
	for(var/list/action as anything in admin_context_actions()[group])
		var/verb_path = action[2]
		if(!istype(target, action[3]) || !(verb_path in verbs))
			continue
		choices[action[1]] = verb_path
	if(!length(choices))
		to_chat(src, span_warning("You have no [group] actions for [target]."))
		return
	var/picked = tgui_input_list(usr, "[target] ([target.type])", "[group]: [target]", choices)
	if(!picked || !holder || QDELETED(target))
		return
	var/verb_path = choices[picked]
	// Rights may have changed while the list was open.
	if(!(verb_path in verbs))
		return
	run_admin_target_verb(verb_path, target)

/// Calls an admin verb on target directly, asking for any extra argument the verb needs.
/client/proc/run_admin_target_verb(verb_path, atom/target)
	if(!holder || QDELETED(target) || !(verb_path in verbs))
		return
	var/list/arguments = list(target)
	if(verb_path == /client/proc/cmd_give_control_to_player)
		var/list/players = list()
		for(var/client/candidate as anything in GLOB.clients)
			players[candidate.key] = candidate
		var/player_key = tgui_input_list(usr, "Who takes control of [target]?", "Give Control To Player", sortList(players))
		var/client/player = players[player_key]
		if(!player || QDELETED(target))
			return
		arguments += player
	// ispath() does not work on proc paths: tell /datum/admins verbs apart by their path text.
	var/datum/verb_owner = findtext("[verb_path]", "/datum/admins/proc/") == 1 ? holder : src
	call(verb_owner, verb_path)(arglist(arguments))

/// Verb path -> mob type it targets, for the admin verbs that take a mob argument.
/proc/admin_mob_target_verbs()
	var/static/list/mob_verbs
	if(mob_verbs)
		return mob_verbs
	mob_verbs = list()
	for(var/group in admin_context_actions())
		for(var/list/action as anything in admin_context_actions()[group])
			if(ispath(action[3], /mob))
				mob_verbs[action[2]] = action[3]
	return mob_verbs

/**
 * Runs a mob-targeting verb from the Admin Menu: the mob comes from the Players / Nearby / All
 * picker instead of BYOND's list of every mob in the world.
 */
/client/proc/run_admin_mob_verb(verb_path)
	set waitfor = FALSE
	var/required_type = admin_mob_target_verbs()[verb_path]
	if(!required_type || !holder)
		return
	var/procpath/verb_ref = verb_path
	var/mob/target = admin_pick_mob(src, verb_ref.name)
	if(!target)
		return
	if(!istype(target, required_type))
		to_chat(src, span_warning("[verb_ref.name] cannot be used on [target]."))
		return
	run_admin_target_verb(verb_path, target)
