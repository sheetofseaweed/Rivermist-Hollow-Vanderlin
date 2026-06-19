/// A telegraphed special move for a promoted boss.
/datum/dungeon_boss_ability
	var/name = "ability"
	var/cooldown = 8 SECONDS
	var/telegraph = "winds up!"
	var/next_use = 0

/datum/dungeon_boss_ability/proc/ready(world_time = world.time)
	return world_time >= next_use

/datum/dungeon_boss_ability/proc/use(mob/living/boss, atom/target)
	next_use = world.time + cooldown
	if(telegraph)
		boss.visible_message(span_warning("[boss] [telegraph]"))
	do_effect(boss, target)

/datum/dungeon_boss_ability/proc/do_effect(mob/living/boss, atom/target)
	return

/datum/dungeon_boss_ability/lunge
	name = "lunge"
	telegraph = "lunges!"
	cooldown = 7 SECONDS

/datum/dungeon_boss_ability/lunge/do_effect(mob/living/boss, atom/target)
	if(target)
		boss.throw_at(get_turf(target), 4, 1)

/datum/dungeon_boss_ability/slam
	name = "slam"
	telegraph = "raises up for a ground slam!"
	cooldown = 12 SECONDS

/datum/dungeon_boss_ability/slam/do_effect(mob/living/boss, atom/target)
	for(var/mob/living/victim in range(1, boss))
		if(victim == boss || !victim.mind)
			continue
		victim.Knockdown(2 SECONDS)
		victim.apply_damage(15, BRUTE)

/datum/dungeon_boss_ability/enrage
	name = "enrage"
	telegraph = "roars with fury!"
	cooldown = 25 SECONDS

/datum/dungeon_boss_ability/enrage/do_effect(mob/living/boss, atom/target)
	if(istype(boss, /mob/living/simple_animal/hostile))
		var/mob/living/simple_animal/hostile/animal = boss
		animal.move_to_delay = max(1, animal.move_to_delay - 1)

/// Attaches a small ability kit to any living mob and fires it at its target.
/datum/component/dungeon_boss_abilities
	var/list/datum/dungeon_boss_ability/abilities = list()

/datum/component/dungeon_boss_abilities/Initialize(list/ability_types)
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	for(var/ability_type as anything in (ability_types || list(/datum/dungeon_boss_ability/lunge, /datum/dungeon_boss_ability/slam)))
		abilities += new ability_type
	START_PROCESSING(SSprocessing, src)

/datum/component/dungeon_boss_abilities/Destroy(force)
	STOP_PROCESSING(SSprocessing, src)
	abilities = null
	return ..()

/datum/component/dungeon_boss_abilities/process(seconds_per_tick)
	var/mob/living/boss = parent
	if(QDELETED(boss) || boss.stat >= UNCONSCIOUS)
		return
	var/atom/target = boss.vars["target"]   // simple_animal hostiles track .target
	if(!target)
		return
	for(var/datum/dungeon_boss_ability/ability as anything in abilities)
		if(ability.ready())
			ability.use(boss, target)
			break
