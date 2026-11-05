/datum/action/cooldown/spell/beam/beam_of_frost
	name = "Beam of Frost"
	desc = "Shoots a beam of frost out, slowing anyone hit by it."
	button_icon_state = "rayoffrost"

	point_cost = 3

	charge_time = 2.5 SECONDS
	charge_drain = 1
	cooldown_time = 20 SECONDS
	spell_cost = 30

	invocation = "Chill!"
	invocation_type = INVOCATION_SHOUT
	spell_flags = SPELL_RITUOS
	beam_icon_state = "medbeam"
	beam_color = "#87CEEB"
	time = 6 SECONDS
	max_distance = 5

	slot_level = 1
	minor_cost = SPELL_MINOR_COST_DEFAULT
	slot_label = "Beam of Frost"
	required_form = FORM_ICE
	required_technique = TECHNIQUE_DESTRUCTION

	var/list/hit_targets
	/// Slot level captured at cast, since the beam outlives the cast.
	var/beam_level
	/// Upcast frostbite duration multiplier, captured with the level.
	var/beam_duration_multiplier = 1

/datum/action/cooldown/spell/beam/beam_of_frost/Destroy()
	hit_targets = null
	return ..()

/datum/action/cooldown/spell/beam/beam_of_frost/cast(atom/cast_on)
	// The parent connects the beam and freezes the first target, so capture the level first.
	beam_level = get_effect_level()
	beam_duration_multiplier = get_upcast_duration_multiplier()
	. = ..()
	addtimer(VARSET_CALLBACK(src, hit_targets, null), time + 5 DECISECONDS)

/datum/action/cooldown/spell/beam/beam_of_frost/on_beam_connect(atom/victim, mob/caster)
	if(!isliving(victim))
		return
	var/mob/living/frozen_guy = victim
	do_freeze(frozen_guy, 1.3)

/datum/action/cooldown/spell/beam/beam_of_frost/beam_entered(datum/beam/source, obj/effect/ebeam/hit, atom/movable/entered)
	if(!isliving(entered))
		return
	if(entered == owner)
		return
	var/mob/living/frozen_guy = entered
	do_freeze(frozen_guy)

/datum/action/cooldown/spell/beam/beam_of_frost/proc/do_freeze(mob/living/victim, extra_modifer = 1)
	if(LAZYACCESS(hit_targets, victim))
		return

	LAZYSET(hit_targets, victim, TRUE)

	if(victim.can_block_magic(antimagic_flags))
		victim.visible_message(
			span_warning("The frost ray fizzles on contact with [victim]!"),
			span_warning("The frost ray fizzles on contact with me!"),
		)
		playsound(victim, 'sound/magic/magic_nulled.ogg', 100)
		qdel(active)
		return

	var/strength = clamp(get_rank_multiplier() * extra_modifer, 0.5, 2)

	var/damage = round(20 * strength)
	if(beam_level == SPELL_SLOT_MINOR)
		damage = 10 * get_cantrip_multiplier()
		strength = 0.5
	else if(!isnull(beam_level))
		damage = round((15 + 10 * beam_level) * get_rank_multiplier())
		strength = clamp(0.5 + 0.25 * beam_level, 0.5, 2)
	victim.adjustFireLoss(damage)
	var/datum/status_effect/debuff/frostbite/frost_type = /datum/status_effect/debuff/frostbite
	victim.apply_status_effect(frost_type, initial(frost_type.duration) * beam_duration_multiplier, strength)

	new /obj/effect/temp_visual/snap_freeze(get_turf(victim))

	playsound(victim, 'sound/items/stonestone.ogg', 100)
	victim.visible_message(
		span_danger("[victim] is struck by the ray of frost!"),
		span_userdanger("I'm struck by the ray of frost!"),
	)

/datum/status_effect/debuff/frostbite
	id = "frostbite"
	alert_type = /atom/movable/screen/alert/status_effect/debuff/frostbite
	duration = 10 SECONDS
	effectedstats = list(STAT_SPEED = -2)
	var/atom_color = "#88BFFF"
	var/strength_multiplier = 1
	var/static/mutable_appearance/frost = mutable_appearance('icons/roguetown/mob/coldbreath.dmi', "breath_m", ABOVE_ALL_MOB_LAYER)

/datum/status_effect/debuff/frostbite/on_creation(mob/living/new_owner, duration_override, strength = 1)
	strength_multiplier = strength
	return ..()

/datum/status_effect/debuff/frostbite/on_apply()
	effectedstats = list(STAT_SPEED = round(-2 * strength_multiplier))
	. = ..()
	owner.add_overlay(frost)
	owner.add_atom_colour(atom_color, TEMPORARY_COLOUR_PRIORITY)
	owner.add_movespeed_modifier(MOVESPEED_ID_FROST_DEBUFF, multiplicative_slowdown = 3, movetypes = GROUND)

/datum/status_effect/debuff/frostbite/on_remove()
	. = ..()
	owner.cut_overlay(frost)
	owner.remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, atom_color)
	owner.remove_movespeed_modifier(MOVESPEED_ID_FROST_DEBUFF)

/atom/movable/screen/alert/status_effect/debuff/frostbite
	name = "Frostbite"
	desc = "I can feel myself slowing down."
	icon_state = "frozen"
	color = "#00fffb"
