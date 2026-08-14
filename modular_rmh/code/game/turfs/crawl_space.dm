/turf/open/floor/crawl_space
	name = "crawlspace"
	desc = "Too small to pass without crawling."
	icon = 'modular_rmh/icons/turf/roguefloor.dmi'
	icon_state = "concretefloor2"
	neighborlay = "dirtedge"
	footstep = FOOTSTEP_FLOOR
	barefootstep = FOOTSTEP_HARD_BAREFOOT
	clawfootstep = FOOTSTEP_HARD_CLAW
	heavyfootstep = FOOTSTEP_GENERIC_HEAVY
	var/randomize_icon = TRUE
	var/icon_variants = 3

/turf/open/floor/crawl_space/Initialize(mapload)
	. = ..()
	if(randomize_icon)
		icon_state = "crawlspace_[rand(1, icon_variants)]"

/turf/open/floor/crawl_space/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(!.)
		return
	if(!iscarbon(mover))
		return
	var/mob/living/carbon/crawler = mover
	if(!(crawler.mobility_flags & MOBILITY_STAND))
		return
	return FALSE

/turf/open/floor/crawl_space/Bumped(atom/movable/bumped_atom)
	. = ..()
	if(!iscarbon(bumped_atom))
		return

	var/mob/living/carbon/crawler = bumped_atom
	if(!crawler.client)
		return
	if(!(crawler.mobility_flags & MOBILITY_STAND))
		return
	// Walking into a low ceiling fires Bumped every step the key is held, and a
	// row of these tiles would otherwise print once per tile.
	if(TIMER_COOLDOWN_CHECK(crawler, "crawlspace_warning"))
		return

	TIMER_COOLDOWN_START(crawler, "crawlspace_warning", 3 SECONDS)
	to_chat(crawler, span_warning("I must crawl to fit in [src]."))

/turf/open/floor/crawl_space/fixed
	randomize_icon = FALSE

