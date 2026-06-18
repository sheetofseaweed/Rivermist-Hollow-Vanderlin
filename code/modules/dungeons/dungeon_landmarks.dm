/obj/effect/landmark/dungeon
	name = "dungeon marker"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE

// -- Guardian spawn point: replaced by a mob from the pool on dungeon load --

/obj/effect/landmark/dungeon/guardian
	name = "dungeon guardian marker"
	/// Weighted assoc list of mob typepaths; one is spawned on dungeon load
	var/list/mob_pool = list()
	/// Chance this marker spawns anything at all
	var/spawn_chance = 100

/obj/effect/landmark/dungeon/guardian/proc/spawn_guardian(turf/spawn_turf)
	if(!length(mob_pool) || !prob(spawn_chance))
		return null
	var/mob_type = pickweight(mob_pool.Copy())
	if(!ispath(mob_type, /mob/living))
		return null
	return new mob_type(spawn_turf)

/obj/effect/landmark/dungeon/guardian/test
	name = "test dungeon guardian marker"
	mob_pool = list(/mob/living/simple_animal/hostile/retaliate/wolf = 10)

/obj/effect/landmark/dungeon/guardian/boss
	name = "dungeon boss marker"
	/// When TRUE, the room pulls its boss from the run's floor config boss_pool
	/// instead of this marker's mob_pool.
	var/use_floor_boss_pool = TRUE

/obj/effect/landmark/dungeon/guardian/boss/test
	name = "test boss marker"
	use_floor_boss_pool = FALSE
	mob_pool = list(/mob/living/simple_animal/hostile/boss/dungeon/test = 10)

// -- Loot point: replaced by a sealed reward cache on dungeon load --

/obj/effect/landmark/dungeon/loot
	name = "dungeon loot marker"
	var/cache_type = /obj/structure/dungeon_loot_cache

/obj/effect/landmark/dungeon/loot/proc/create_cache(turf/cache_turf, datum/pocket_dimension/dungeon/owner)
	var/obj/structure/dungeon_loot_cache/cache = new cache_type(cache_turf)
	var/datum/map_template/pocket/dungeon/dungeon_template = owner?.get_dungeon_template()
	if(dungeon_template?.loot_table_type)
		cache.loot = new dungeon_template.loot_table_type
	cache.delve_level = max(1, owner?.depth)
	return cache

// -- Gate point: recorded by the instance, built by the run controller --

/obj/effect/landmark/dungeon/gate
	name = "dungeon gate marker"
	var/gate_role = DUNGEON_GATE_FORWARD

/obj/effect/landmark/dungeon/gate/back
	name = "dungeon back gate marker"
	gate_role = DUNGEON_GATE_BACK

// -- Reward cache: sealed until the room is cleared --

/obj/structure/dungeon_loot_cache
	name = "sealed cache"
	desc = "A heavy stone cache, shut tight by some lingering will. Perhaps it opens when the danger passes."
	icon = 'icons/roguetown/misc/structure.dmi'
	icon_state = "closet3"
	density = TRUE
	anchored = TRUE
	var/locked = TRUE
	/// Loot table datum instance; rolled once per taker
	var/datum/loot_table/loot
	/// Delve level passed into the loot table for quantity/rarity scaling
	var/delve_level = 1
	/// How many different people can claim a share
	var/max_takers = 3
	/// Minds that already claimed their share
	var/list/takers = list()

/obj/structure/dungeon_loot_cache/Destroy()
	if(loot)
		qdel(loot)
		loot = null
	takers = null
	return ..()

/obj/structure/dungeon_loot_cache/examine(mob/user)
	. = ..()
	if(locked)
		. += span_warning("It is sealed shut by something unseen.")
	else
		. += span_notice("It hangs open, waiting to be claimed.")

/obj/structure/dungeon_loot_cache/proc/unseal()
	if(!locked)
		return
	locked = FALSE
	name = "unsealed cache"
	desc = "A heavy stone cache. Whatever held it shut has let go."
	visible_message(span_notice("[src] clicks and grinds open!"))

/obj/structure/dungeon_loot_cache/attack_hand(mob/user, list/modifiers)
	. = ..()
	try_loot(user)

/obj/structure/dungeon_loot_cache/proc/try_loot(mob/living/user)
	if(!istype(user))
		return FALSE
	if(locked)
		to_chat(user, span_warning("The cache is sealed by some lingering will. Whatever guards this place must fall first."))
		return FALSE
	if(!loot)
		to_chat(user, span_warning("The cache is empty."))
		return FALSE
	if(user.mind && (user.mind in takers))
		to_chat(user, span_warning("I have already claimed my share from this cache."))
		return FALSE
	if(length(takers) >= max_takers)
		to_chat(user, span_warning("The cache has been picked clean."))
		return FALSE
	loot.spawn_loot(user, delve_level, user.return_item_rarity())
	if(user.mind)
		takers += user.mind
	to_chat(user, span_notice("I claim my share from the cache."))
	return TRUE
