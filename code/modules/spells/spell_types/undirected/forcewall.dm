/datum/action/cooldown/spell/undirected/forcewall
	name = "Forcewall"
	desc = "Conjure a wall of arcyne force, preventing anyone and anything other than you from moving through it."
	button_icon_state = "forcewall"

	point_cost = 3
	school = SCHOOL_TRANSMUTATION

	charge_time = 2 SECONDS
	charge_drain = 1
	charge_slowdown = 1.3
	cooldown_time = 35 SECONDS
	spell_cost = 30
	spell_flags = SPELL_RITUOS
	slot_level = 3
	slot_only = TRUE
	concentration = TRUE
	slot_label = "Forcewall"
	required_form = FORM_ARCANE
	required_technique = TECHNIQUE_ILLUSION
	required_level = MASTERY_RANK_EXPERT
	prerequisite_spells = list(/datum/action/cooldown/spell/undirected/forcewall/breakable)

	var/wall_type = /obj/effect/forcefield/wizard
	/// Walls of the current cast, dropped when concentration ends.
	var/list/active_walls

/datum/action/cooldown/spell/undirected/forcewall/Destroy()
	active_walls = null
	return ..()

/datum/action/cooldown/spell/undirected/forcewall/cast(atom/cast_on)
	. = ..()
	if(uses_spell_slots())
		on_concentration_broken(CONCENTRATION_REPLACED)
	var/turf/ahead = get_step(owner, owner.dir)
	place_wall(ahead)
	if(owner.dir == SOUTH || owner.dir == NORTH)
		place_wall(get_step(ahead, EAST))
		place_wall(get_step(ahead, WEST))
	else
		place_wall(get_step(ahead, NORTH))
		place_wall(get_step(ahead, SOUTH))

/datum/action/cooldown/spell/undirected/forcewall/proc/place_wall(turf/spot)
	var/atom/wall = new wall_type(spot, owner, antimagic_flags)
	LAZYADD(active_walls, WEAKREF(wall))

/datum/action/cooldown/spell/undirected/forcewall/on_concentration_broken(reason)
	for(var/datum/weakref/wall_ref as anything in active_walls)
		var/atom/wall = wall_ref.resolve()
		if(!QDELETED(wall))
			qdel(wall)
	active_walls = null

/datum/action/cooldown/spell/undirected/forcewall/breakable
	name = "Lesser Forcewall"
	wall_type = /obj/structure/forcefield/casted

	slot_level = 1
	required_level = MASTERY_RANK_NOVICE
	prerequisite_spells = null
	slot_label = "Lesser Forcewall"
