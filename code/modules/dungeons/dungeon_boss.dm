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

/// Bosses are not /retaliate subtypes, so the affix system skips them.
/// This scales a dungeon boss by floor: health, melee, and ATB regen.
/proc/scale_dungeon_boss(mob/living/simple_animal/hostile/boss/dungeon/boss, floor)
	if(!istype(boss) || floor <= 1)
		return
	var/factor = 1 + (floor - 1) * 0.35
	boss.maxHealth = round(boss.maxHealth * factor)
	boss.health = boss.maxHealth
	boss.melee_damage_lower = round(boss.melee_damage_lower * (1 + (floor - 1) * 0.2))
	boss.melee_damage_upper = round(boss.melee_damage_upper * (1 + (floor - 1) * 0.2))
	if(boss.atb)
		boss.atb.point_regen_delay = max(1, round(boss.atb.point_regen_delay * max(0.5, 1 - (floor - 1) * 0.08)))
	boss.name = "[boss.name] (Floor [floor])"
