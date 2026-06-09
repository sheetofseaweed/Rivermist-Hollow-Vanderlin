/datum/action/cooldown/spell/mage_hand
	name = "Mage Hand"
	desc = "Shape an arcyne hand that can touch a visible living target from afar."
	button_icon_state = "prestidigitation"
	self_cast_possible = FALSE
	cast_range = 7

	point_cost = 2
	school = SCHOOL_TRANSMUTATION
	charge_required = FALSE
	cooldown_time = 2 MINUTES
	spell_cost = 50

	invocation = "Manus arcyne."
	invocation_type = INVOCATION_WHISPER
	attunements = list(
		/datum/attunement/arcyne = 0.2,
	)

	var/tether_duration = 2 MINUTES

/datum/action/cooldown/spell/mage_hand/scrying
	name = "Scrying Mage Hand"
	desc = "Project Mage Hand through a scrying vision."
	spell_cost = 0
	cooldown_time = 0

/datum/action/cooldown/spell/mage_hand/scrying/GiveAction(mob/viewer)
	LAZYOR(viewer.actions, src)

/datum/action/cooldown/spell/mage_hand/is_valid_target(atom/cast_on)
	. = ..()
	if(!.)
		return FALSE
	if(!owner || !isliving(owner))
		return FALSE
	if(!isliving(cast_on))
		return FALSE

	var/mob/living/caster = owner
	var/mob/living/target = cast_on
	if(target == caster)
		return FALSE
	if(QDELETED(target) || target.stat == DEAD)
		return FALSE
	if(get_dist(caster, target) > cast_range)
		return FALSE
	if(!can_see(caster, target, cast_range))
		return FALSE
	return TRUE

/datum/action/cooldown/spell/mage_hand/cast(mob/living/cast_on)
	. = ..()
	var/mob/living/caster = owner
	if(!caster || !cast_on || !is_valid_target(cast_on))
		return

	if(!start_mage_hand_tether(caster, cast_on, tether_duration, cast_range, TRUE, TRUE, TRUE))
		return

	to_chat(caster, span_notice("I send a ghostly hand toward [cast_on]."))
	cast_on.visible_message(
		span_notice("A ghostly blue hand shimmers around [cast_on]."),
		span_notice("A ghostly blue hand shimmers around me."),
	)

/proc/start_mage_hand_tether(mob/living/caster, mob/living/target, duration = 2 MINUTES, range = 7, requires_range = TRUE, requires_line_of_sight = TRUE, show_ui = TRUE)
	if(!caster || !target || caster == target)
		return FALSE
	if(QDELETED(caster) || QDELETED(target))
		return FALSE
	if(caster.stat != CONSCIOUS || target.stat == DEAD)
		return FALSE
	if(!caster.loc || !target.loc)
		return FALSE

	clear_mage_hand_tethers_for(caster)
	var/datum/sex_session/session = get_or_create_sex_session(caster, target, FALSE)
	if(!session)
		return FALSE

	var/datum/sex_remote_context/mage_hand/context = new(caster, target, duration, range)
	context.requires_range = requires_range
	context.requires_line_of_sight = requires_line_of_sight
	session.set_remote_context(context)
	if(show_ui)
		session.show_ui()
	return TRUE

/proc/can_start_scrying_mage_hand(mob/living/caster, mob/living/target)
	if(!caster || !target || caster == target)
		return FALSE
	if(QDELETED(caster) || QDELETED(target))
		return FALSE
	if(caster.stat != CONSCIOUS || target.stat == DEAD)
		return FALSE
	if(!caster.loc || !target.loc)
		return FALSE
	if(!caster.get_spell(/datum/action/cooldown/spell/mage_hand/scrying, TRUE))
		return FALSE
	return TRUE

/proc/start_scrying_mage_hand(mob/living/caster, mob/living/target, show_ui = TRUE)
	if(!can_start_scrying_mage_hand(caster, target))
		return FALSE
	if(!start_mage_hand_tether(caster, target, 2 MINUTES, 7, FALSE, FALSE, show_ui))
		return FALSE

	to_chat(caster, span_notice("I send a ghostly hand through my scrying vision toward [target]."))
	to_chat(target, span_notice("A ghostly blue hand shimmers around me."))
	return TRUE
