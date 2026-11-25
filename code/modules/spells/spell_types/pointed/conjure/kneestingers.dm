/datum/action/cooldown/spell/conjure/kneestingers
	name = "Fungal Illumination"
	desc = "Conjure a ring of kneestingers to light the path. The minor form raises a single stinger."
	button_icon_state = "kneestinger"
	sound = 'sound/items/dig_shovel.ogg'
	self_cast_possible = FALSE

	cast_range = 1
	spell_type = SPELL_MIRACLE
	antimagic_flags = MAGIC_RESISTANCE_HOLY
	associated_skill = /datum/attribute/skill/magic/holy

	invocation = "Treefather light the way."
	invocation_type = INVOCATION_WHISPER

	charge_required = FALSE
	cooldown_time = 30 SECONDS
	spell_cost = 30

	required_form = FORM_LIFE
	required_technique = TECHNIQUE_SUMMONING
	slot_level = 1
	minor_cost = SPELL_MINOR_COST_DEFAULT

	summon_type = list(/obj/structure/kneestingers/decaying)
	summon_radius = 1
	summon_amount = 3
	upcast_extra_summons = TRUE

/// Minor raises one stinger under the caster; slot casts raise the ring.
/datum/action/cooldown/spell/conjure/kneestingers/get_summon_amount()
	if(is_minor_cast())
		return 1
	return ..()

/datum/action/cooldown/spell/conjure/kneestingers/get_summon_radius()
	if(is_minor_cast())
		return 0
	return ..()
