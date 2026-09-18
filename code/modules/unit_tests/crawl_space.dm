/datum/unit_test/crawl_space_gap
#ifdef FOCUS_CRAWL_SPACE
	focus = TRUE
#endif
	var/old_turf_type

/datum/unit_test/crawl_space_gap/Run()
	old_turf_type = run_loc_floor_bottom_left.type
	var/turf/open/floor/crawl_space/gap = run_loc_floor_bottom_left.ChangeTurf(/turf/open/floor/crawl_space)
	TEST_ASSERT(istype(gap), "Expected the test turf to become a crawlspace.")

	TEST_ASSERT(icon_exists(gap.icon, gap.icon_state), "Crawlspace picked icon state '[gap.icon_state]', which is missing from [gap.icon].")

	var/mob/living/carbon/human/crawler = allocate(/mob/living/carbon/human, gap)

	TEST_ASSERT(!gap.CanAllowThrough(crawler, gap), "A standing mob must not fit through the crawlspace.")

	crawler.set_resting(TRUE, silent = TRUE)
	// Voluntary resting never applies TRAIT_FLOORED, so MOBILITY_STAND stays set. That is the regression.
	TEST_ASSERT(!HAS_TRAIT(crawler, TRAIT_FLOORED), "Voluntary resting should not floor the mob; the test premise is wrong otherwise.")
	TEST_ASSERT(crawler.body_position == LYING_DOWN, "set_resting() should have laid the mob down.")
	TEST_ASSERT(gap.CanAllowThrough(crawler, gap), "A resting mob must fit through the crawlspace.")

	crawler.set_resting(FALSE, silent = TRUE)
	crawler.set_body_position(STANDING_UP)
	TEST_ASSERT(!gap.CanAllowThrough(crawler, gap), "Standing back up must block the crawlspace again.")

	ADD_TRAIT(crawler, TRAIT_FLOORED, TRAIT_SOURCE_UNIT_TESTS)
	TEST_ASSERT(gap.CanAllowThrough(crawler, gap), "A floored mob must fit through the crawlspace.")
	REMOVE_TRAIT(crawler, TRAIT_FLOORED, TRAIT_SOURCE_UNIT_TESTS)

/datum/unit_test/crawl_space_gap/Destroy()
	if(old_turf_type)
		run_loc_floor_bottom_left.ChangeTurf(old_turf_type)
	return ..()
