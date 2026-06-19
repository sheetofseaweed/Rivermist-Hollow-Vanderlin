/mob/living/simple_animal/hostile/boss/dungeon
	abstract_type = /mob/living/simple_animal/hostile/boss/dungeon
	name = "dungeon horror"
	desc = "A guardian of the deep places, swollen with the dungeon's malice."
	faction = list("dungeon")
	/// Motes dropped when this boss dies (before floor scaling)
	var/mote_bounty = 200

/mob/living/simple_animal/hostile/boss/dungeon/test
	name = "Test Warden"
	desc = "A practice effigy that hits back."
	maxHealth = 200
	health = 200
	melee_damage_lower = 10
	melee_damage_upper = 15
	mote_bounty = 100

GLOBAL_LIST_INIT(dungeon_boss_prefixes, list("Dread", "Gorged", "Elder", "Ravening", "Black", "Hollow"))
GLOBAL_LIST_INIT(dungeon_boss_titles, list("the Alpha", "the Devourer", "the Warden", "the Unbroken", "the Maw"))

/// Promotes any living mob into a floor boss: scales stats, dresses it up,
/// gives it a healthbar and (for non-ATB mobs) a telegraphed ability kit.
/// Returns the mote bounty the boss should award on death.
/proc/make_dungeon_boss(mob/living/boss, floor = 1, tier = 1)
	if(!isliving(boss))
		return 0
	var/factor = 1 + max(0, floor - 1) * 0.35
	boss.maxHealth = round(max(1, boss.maxHealth) * factor)
	boss.health = boss.maxHealth
	// Optional vars — only scale what this mob actually has.
	if("melee_damage_lower" in boss.vars)
		boss.vars["melee_damage_lower"] = round(boss.vars["melee_damage_lower"] * (1 + max(0, floor - 1) * 0.2))
	if("melee_damage_upper" in boss.vars)
		boss.vars["melee_damage_upper"] = round(boss.vars["melee_damage_upper"] * (1 + max(0, floor - 1) * 0.2))
	if("obj_damage" in boss.vars)
		boss.vars["obj_damage"] = round(boss.vars["obj_damage"] * factor)

	// Presence: name + aura + bigger sprite.
	boss.name = "[pick(GLOB.dungeon_boss_prefixes)] [boss.name] [pick(GLOB.dungeon_boss_titles)]"
	boss.add_atom_colour("#7a1f1f", TEMPORARY_COLOUR_PRIORITY)
	var/matrix/scale = matrix(boss.transform)
	scale.Scale(1.3)
	boss.transform = scale

	// Healthbar for the whole room.
	boss.AddComponent(/datum/component/dungeon_boss_healthbar, boss.name)

	// Abilities: keep ATB for real bosses, else attach the lightweight kit.
	if(istype(boss, /mob/living/simple_animal/hostile/boss))
		if(istype(boss, /mob/living/simple_animal/hostile/boss/dungeon))
			scale_dungeon_boss_atb(boss, floor)
	else
		boss.AddComponent(/datum/component/dungeon_boss_abilities, null)

	// Mote bounty: bespoke bosses define their own; others scale by floor.
	var/bounty = 150 + max(0, floor - 1) * 50
	if(istype(boss, /mob/living/simple_animal/hostile/boss/dungeon))
		var/mob/living/simple_animal/hostile/boss/dungeon/dboss = boss
		bounty = max(bounty, dboss.mote_bounty)
	return bounty

/// Floor-scaling tweak for the bespoke ATB boss subtype's ability economy.
/proc/scale_dungeon_boss_atb(mob/living/simple_animal/hostile/boss/dungeon/boss, floor)
	if(!istype(boss) || floor <= 1)
		return
	if(boss.atb)
		boss.atb.point_regen_delay = max(1, round(boss.atb.point_regen_delay * max(0.5, 1 - (floor - 1) * 0.08)))
