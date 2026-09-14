// Hunting & Tracking pack - what a trail can lead to, and where.
//
// The roster and areas are built against RMH's own fauna and area tree. Area matching is istype()
// based, so listing a parent area covers its subtypes.

/datum/hunting_category
	var/name = "Generic"
	/// Animal type path = relative weight.
	var/list/animals = list()
	/// Weight of this category being picked, indexed by Hunting skill 0-6 (so seven entries).
	var/list/skill_weights = list(0, 0, 0, 0, 0, 0, 0)
	/// Animal type path = hunting_track icon_state to use for its trail.
	var/list/preferred_tracks = list()
	/// Area type = percentage bonus to this category's weight there. Empty means "anywhere".
	var/list/preferred_areas = list()
	/// Cap on extra animals a hunting party can flush out alongside the quarry.
	var/bonus_animal_amount = 1

/datum/hunting_category/proc/can_spawn_in_area(area/checked_area)
	if(!checked_area)
		return FALSE
	if(!length(preferred_areas))
		return TRUE
	for(var/area_type in preferred_areas)
		if(istype(checked_area, area_type))
			return TRUE
	return FALSE

/datum/hunting_category/proc/get_area_bonus(area/checked_area)
	if(!checked_area || !length(preferred_areas))
		return 0
	for(var/area_type in preferred_areas)
		if(istype(checked_area, area_type))
			return preferred_areas[area_type]
	return 0

/datum/hunting_category/low_tier
	bonus_animal_amount = 8
	name = "Small Game"
	skill_weights = list(100, 80, 50, 20, 10, 5, 5)
	animals = list(
		/mob/living/simple_animal/hostile/retaliate/bigrat = 15,
		/mob/living/simple_animal/hostile/retaliate/bobcat = 10,
		/mob/living/simple_animal/hostile/retaliate/fox = 15,
	)
	preferred_tracks = list(
		/mob/living/simple_animal/hostile/retaliate/bigrat = "small",
		/mob/living/simple_animal/hostile/retaliate/bobcat = "small",
		/mob/living/simple_animal/hostile/retaliate/fox = "canine",
	)
	preferred_areas = list(
		/area/outdoors/woods_safe = 30,
		/area/outdoors/basin = 20,
	)

/datum/hunting_category/mid_tier
	bonus_animal_amount = 5
	name = "Forest Denizens"
	skill_weights = list(10, 40, 100, 80, 50, 30, 10)
	animals = list(
		/mob/living/simple_animal/hostile/retaliate/wolf = 15,
		/mob/living/simple_animal/hostile/retaliate/saiga = 20,
		/mob/living/simple_animal/hostile/retaliate/saigabuck = 10,
	)
	preferred_tracks = list(
		/mob/living/simple_animal/hostile/retaliate/wolf = "canine",
		/mob/living/simple_animal/hostile/retaliate/saiga = "cervine",
		/mob/living/simple_animal/hostile/retaliate/saigabuck = "cervine",
	)
	preferred_areas = list(
		/area/outdoors/woods_safe = 50,
		/area/outdoors/mountains = 20,
	)

/datum/hunting_category/high_tier
	bonus_animal_amount = 3
	name = "Great Beasts"
	skill_weights = list(0, 5, 20, 50, 100, 120, 150)
	animals = list(
		/mob/living/simple_animal/hostile/retaliate/direbear = 10,
		/mob/living/simple_animal/hostile/retaliate/troll = 3,
	)
	preferred_tracks = list(
		/mob/living/simple_animal/hostile/retaliate/direbear = "ursine",
		/mob/living/simple_animal/hostile/retaliate/troll = "ursine",
	)
	preferred_areas = list(
		/area/outdoors/mountains = 40,
		/area/outdoors/woods_safe = 15,
	)

/datum/hunting_category/mire_dwellers
	bonus_animal_amount = 6
	name = "Mire Dwellers"
	skill_weights = list(30, 30, 30, 25, 25, 20, 20)
	animals = list(
		/mob/living/simple_animal/hostile/retaliate/mirespider = 30,
	)
	preferred_tracks = list(
		/mob/living/simple_animal/hostile/retaliate/mirespider = "small",
	)
	preferred_areas = list(
		/area/outdoors/bog = 60,
	)

/// Bramblesnouts are the hunt's heavy prize - rare, and a real fight. Kept in their own category
/// so they cannot crowd out ordinary game.
/datum/hunting_category/boars
	bonus_animal_amount = 2
	name = "Bramblesnout"
	skill_weights = list(0, 0, 5, 10, 15, 20, 25)
	animals = list(
		/mob/living/simple_animal/hostile/retaliate/boar = 1,
	)
	preferred_tracks = list(
		/mob/living/simple_animal/hostile/retaliate/boar = "suidae",
	)
	preferred_areas = list(
		/area/outdoors/woods_safe = 40,
		/area/outdoors/bog = 30,
	)

/// The hunt's legend. Named to match ordinary deer on purpose, so nothing about the trail tells a
/// hunter what is waiting at the end of it until they see it.
/datum/hunting_category/white_stag
	bonus_animal_amount = 0
	name = "Forest Denizens"
	skill_weights = list(0, 0, 0, 1, 2, 3, 5)
	animals = list(
		/mob/living/carbon/human/species/white_stag = 1,
	)
	preferred_tracks = list(
		/mob/living/carbon/human/species/white_stag = "cervine",
	)
	preferred_areas = list(
		/area/outdoors/woods_safe = 40,
		/area/outdoors/mountains = 20,
	)
