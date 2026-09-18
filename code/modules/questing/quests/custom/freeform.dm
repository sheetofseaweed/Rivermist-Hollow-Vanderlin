/datum/quest/custom/freeform
	issue_label = "Freeform (steward verified)"
	commission_type = "Freeform"
	var/custom_objective_text = ""

/datum/quest/custom/freeform/get_objective_text()
	return custom_objective_text || ..()

/datum/quest/custom/freeform/build_from_user(mob/user)
	if(!fill_common_fields(user))
		return FALSE
	custom_objective_text = tgui_input_text(user, "Describe what the contractor must do:", "Commission Objective", "", 300)
	if(!custom_objective_text)
		return FALSE
	title = tgui_input_text(user, "Give the commission a title:", "Commission Title", "", 80)
	if(!title)
		return FALSE
	return TRUE

/datum/quest/custom/freeform/build_from_pledge(obj/item/paper/scroll/quest/pledge/pledge, mob/steward)
	if(!..())
		return FALSE
	custom_objective_text = pledge.pledge_objective
	return !!custom_objective_text

/datum/quest/custom/freeform/build_pledge(obj/item/paper/scroll/quest/pledge/pledge)
	..()
	pledge.pledge_objective = custom_objective_text

