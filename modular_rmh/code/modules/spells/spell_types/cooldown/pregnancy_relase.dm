///The spell allows you to reset pregnancy values. I don't want to pay child support.

/datum/action/cooldown/spell/pregnancy_relase
	name = "Extractio Divina"
	desc = "Your offspring has matured enough inside your body and now you can send him to the gods. This will reset your pregnancy."
	button_icon_state = "shieldsparkles"

	self_cast_possible = TRUE
	click_to_activate = FALSE

	charge_required = TRUE
	charge_time = 1 MINUTES
	charge_message = "The gods are preparing to accept your life spark."

	spell_type = SPELL_MANA
	spell_cost = 0
	spell_requirements = NONE
	invocation_type = INVOCATION_NONE
	point_cost = 0

/datum/action/cooldown/spell/pregnancy_relase/cast(atom/cast_on)
	. = ..()
	to_chat(owner, span_notice("The gods begin the ritual of accepting your creation."))
	if(!isliving(owner))
		return

	var/obj/item/organ/genitals/filling_organ/womb/womb = owner.getorganslot(ORGAN_SLOT_WOMB)

	if(!womb)
		to_chat(owner, span_warning("You have no womb."))
		return

	if("conventional_pregnancy_stage" in womb.vars)
		womb.conventional_pregnancy_stage = 0
		to_chat(owner, span_notice("The gods accept your spark of life. Your pregnancy has gone."))
	else
		to_chat(owner, span_warning("You have no pregnancy to reset."))
		return

	if("pregnant" in womb.vars)
		womb.pregnant = 0
	else
		to_chat(owner, span_warning("You have no pregnancy to reset."))
		return

	qdel(src)