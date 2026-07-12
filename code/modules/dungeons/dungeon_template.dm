/area/pocket_dimension/dungeon
	name = "Dungeon"

// NOTE: area datums are shared between simultaneous instances of the same
// template, so /area/pocket_dimension.linked_pocket is unreliable for dungeons.
// Nothing in the dungeon system may rely on linked_pocket.

/datum/map_template/pocket/dungeon
	name = "_dungeon_base"
	id = "_dungeon_base"
	lifecycle_policy = POCKET_LIFECYCLE_COLLAPSE
	idle_timeout = DUNGEON_DEFAULT_IDLE_TIMEOUT
	instance_type = /datum/pocket_dimension/dungeon
	/// DUNGEON_THEME_* tag used for entrance/gate filtering
	var/theme
	/// Pick weight inside a filtered template pool
	var/dungeon_weight = 10
	/// Base danger tier (1-5); combined with run depth for selection
	var/difficulty_tier = 1
	/// DUNGEON_ROOM_* kind
	var/room_kind = DUNGEON_ROOM_ONESHOT
	/// /datum/loot_table path used by reward caches in this dungeon
	var/loot_table_type
	/// Examine hint shown on gates leading to a room of this template
	var/gate_hint = "Something stirs in the dark beyond."

/// Returns an assoc list of template datum -> weight for all dungeon templates
/// matching the given filters. Templates are the cached datums registered in
/// SSpocket_dimensions.templates_by_id (built from SSmapping.map_templates).
/proc/get_dungeon_template_pool(room_kind, theme = null, min_tier = 0, max_tier = INFINITY, list/exclude_ids)
	var/list/pool = list()
	for(var/template_id in SSpocket_dimensions.templates_by_id)
		var/datum/map_template/pocket/dungeon/template = SSpocket_dimensions.templates_by_id[template_id]
		if(!istype(template))
			continue
		if(template.room_kind != room_kind)
			continue
		if(theme && template.theme != theme)
			continue
		if(template.difficulty_tier < min_tier || template.difficulty_tier > max_tier)
			continue
		if(exclude_ids && (template.id in exclude_ids))
			continue
		pool[template] = max(1, template.dungeon_weight)
	return pool

/// Weighted-picks a dungeon template. Soft excludes (the anti-repeat memory)
/// relax first, then tier, then theme - but hard_exclude_id (the template of
/// the room the party is standing in) survives every stage except the absolute
/// last resort, so the same room never chains twice in a row unless it is
/// literally the only template of its kind.
/proc/pick_dungeon_template(room_kind, theme = null, min_tier = 0, max_tier = INFINITY, list/exclude_ids, hard_exclude_id)
	var/list/full_exclude = exclude_ids ? exclude_ids.Copy() : list()
	if(hard_exclude_id)
		full_exclude |= hard_exclude_id
	var/list/hard_only = hard_exclude_id ? list(hard_exclude_id) : null
	var/list/pool = get_dungeon_template_pool(room_kind, theme, min_tier, max_tier, full_exclude)
	if(!length(pool))
		pool = get_dungeon_template_pool(room_kind, theme, min_tier, max_tier, hard_only)
	if(!length(pool))
		pool = get_dungeon_template_pool(room_kind, theme, exclude_ids = hard_only)
	if(!length(pool))
		pool = get_dungeon_template_pool(room_kind, exclude_ids = hard_only)
	if(!length(pool))
		pool = get_dungeon_template_pool(room_kind)
	if(!length(pool))
		return null
	return pickweight(pool)

// -- Test templates (used by unit tests; theme TEST keeps them out of real pools) --

/datum/map_template/pocket/dungeon/test_onebite
	name = "Test One-Bite Dungeon"
	id = "dungeon_test_onebite"
	mappath = "_maps/templates/dungeons/_test/dungeon_test_onebite.dmm"
	theme = DUNGEON_THEME_TEST
	room_kind = DUNGEON_ROOM_ONESHOT
	loot_table_type = /datum/loot_table/debug
	gate_hint = "It smells of sawdust and unit tests."

/datum/map_template/pocket/dungeon/test_break
	name = "Test Break Room"
	id = "dungeon_test_break"
	mappath = "_maps/templates/dungeons/_test/dungeon_test_break.dmm"
	theme = DUNGEON_THEME_TEST
	room_kind = DUNGEON_ROOM_BREAK

/datum/map_template/pocket/dungeon/test_combat
	name = "Test Combat Room"
	id = "dungeon_test_combat"
	mappath = "_maps/templates/dungeons/_test/dungeon_test_combat.dmm"
	theme = DUNGEON_THEME_TEST
	room_kind = DUNGEON_ROOM_COMBAT
	loot_table_type = /datum/loot_table/debug

/datum/map_template/pocket/dungeon/test_descent
	name = "Test Descent Room"
	id = "dungeon_test_descent"
	mappath = "_maps/templates/dungeons/_test/dungeon_test_break.dmm" // reuse break layout (entry+exit+gates)
	theme = DUNGEON_THEME_TEST
	room_kind = DUNGEON_ROOM_DESCENT

/datum/map_template/pocket/dungeon/test_boss
	name = "Test Boss Room"
	id = "dungeon_test_boss"
	mappath = "_maps/templates/dungeons/_test/dungeon_test_boss.dmm"
	theme = DUNGEON_THEME_TEST
	room_kind = DUNGEON_ROOM_BOSS
	loot_table_type = /datum/loot_table/debug
	gate_hint = "Something vast breathes in the dark ahead."

/datum/map_template/pocket/dungeon/test_scatter
	name = "Test Scatter Room"
	id = "dungeon_test_scatter"
	mappath = "_maps/templates/dungeons/_test/dungeon_test_scatter.dmm"
	theme = DUNGEON_THEME_TEST
	room_kind = DUNGEON_ROOM_COMBAT
	loot_table_type = /datum/loot_table/debug

// -- The Sunken Warrens: underground swamp goblin starter set --

/datum/map_template/pocket/dungeon/swampgob
	name = "_swampgob_base"
	id = "_swampgob_base"
	theme = DUNGEON_THEME_SWAMPGOB
	loot_table_type = /datum/loot_table/dungeon/swampgob

/datum/map_template/pocket/dungeon/swampgob/break_hollow
	name = "Root-Choked Hollow"
	id = "swampgob_break_hollow"
	mappath = "_maps/templates/dungeons/swampgob/break_hollow.dmm"
	room_kind = DUNGEON_ROOM_BREAK

/datum/map_template/pocket/dungeon/swampgob/descent_sinkhole
	name = "Sinkhole Landing"
	id = "swampgob_descent_sinkhole"
	mappath = "_maps/templates/dungeons/swampgob/descent_sinkhole.dmm"
	room_kind = DUNGEON_ROOM_DESCENT

/datum/map_template/pocket/dungeon/swampgob/combat_mireway
	name = "The Mireway"
	id = "swampgob_combat_mireway"
	mappath = "_maps/templates/dungeons/swampgob/combat_mireway.dmm"
	room_kind = DUNGEON_ROOM_COMBAT
	difficulty_tier = 1
	gate_hint = "Marsh-stink and goblin chatter drift through."

/datum/map_template/pocket/dungeon/swampgob/combat_shroomcave
	name = "Shroom-Lit Cave"
	id = "swampgob_combat_shroomcave"
	mappath = "_maps/templates/dungeons/swampgob/combat_shroomcave.dmm"
	room_kind = DUNGEON_ROOM_COMBAT
	difficulty_tier = 1
	gate_hint = "A pale fungal glow seeps around the frame."

/datum/map_template/pocket/dungeon/swampgob/combat_leechpools
	name = "The Leech Pools"
	id = "swampgob_combat_leechpools"
	mappath = "_maps/templates/dungeons/swampgob/combat_leechpools.dmm"
	room_kind = DUNGEON_ROOM_COMBAT
	difficulty_tier = 2
	loot_table_type = /datum/loot_table/dungeon/tier2
	gate_hint = "Still black water laps at something beyond."

/datum/map_template/pocket/dungeon/swampgob/combat_gobwarren
	name = "Goblin Warren"
	id = "swampgob_combat_gobwarren"
	mappath = "_maps/templates/dungeons/swampgob/combat_gobwarren.dmm"
	room_kind = DUNGEON_ROOM_COMBAT
	difficulty_tier = 2
	loot_table_type = /datum/loot_table/dungeon/tier2
	gate_hint = "Skull-totems and squabbling voices. A warren."

/datum/map_template/pocket/dungeon/swampgob/boss_kingshall
	name = "The Bog-King's Hall"
	id = "swampgob_boss_kingshall"
	mappath = "_maps/templates/dungeons/swampgob/boss_kingshall.dmm"
	room_kind = DUNGEON_ROOM_BOSS
	difficulty_tier = 2
	loot_table_type = /datum/loot_table/dungeon/tier3
	gate_hint = "Drums. Torchlight. Something vast squats on a throne of mud."
