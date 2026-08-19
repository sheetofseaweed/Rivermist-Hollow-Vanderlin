/datum/keybinding/ghost
	category = CATEGORY_MISC
	weight = WEIGHT_MOB
	var/emote_key

/datum/keybinding/ghost/can_use(client/user)
	return isobserver(user.mob) ? TRUE : FALSE
