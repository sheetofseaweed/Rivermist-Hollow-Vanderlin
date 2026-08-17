/// The reflection component must hear about deletions of everything it tracks, or it holds refs to dead movables.
/datum/unit_test/reflection_hooks_qdel_on_tracked_movables
#ifdef FOCUS_REFLECTION_TRACKING
	focus = TRUE
#endif

/datum/unit_test/reflection_hooks_qdel_on_tracked_movables/Run()
	var/turf/floor = run_loc_floor_bottom_left
	TEST_ASSERT_NOTNULL(floor, "Test setup needs a run turf.")

	var/obj/structure/mirror/mirror = allocate(/obj/structure/mirror, floor)
	var/datum/component/reflection/reflection = mirror.GetComponent(/datum/component/reflection)
	TEST_ASSERT_NOTNULL(reflection, "Test setup needs a mirror carrying a reflection component.")

	var/mob/living/carbon/human/subject = allocate(/mob/living/carbon/human, floor)
	var/list/tracked = reflection.vars["reflected_movables"]
	TEST_ASSERT(tracked && (subject in tracked), "The mirror must track a living mob spawned next to it.")

	var/list/hooked = reflection.signal_procs?[subject]
	TEST_ASSERT(hooked && hooked[COMSIG_PARENT_QDELETING], "The reflection component must hook COMSIG_PARENT_QDELETING on every movable it tracks, or deleting one leaves a dangling ref behind.")

/// A tracked movable that dies without an Exited must still leave the mirror's tracking list.
/datum/unit_test/reflection_drops_silently_deleted_movables
#ifdef FOCUS_REFLECTION_TRACKING
	focus = TRUE
#endif

/datum/unit_test/reflection_drops_silently_deleted_movables/Run()
	var/turf/floor = run_loc_floor_bottom_left
	TEST_ASSERT_NOTNULL(floor, "Test setup needs a run turf.")

	var/obj/structure/mirror/mirror = allocate(/obj/structure/mirror, floor)
	var/datum/component/reflection/reflection = mirror.GetComponent(/datum/component/reflection)
	TEST_ASSERT_NOTNULL(reflection, "Test setup needs a mirror carrying a reflection component.")

	var/mob/living/carbon/human/subject = allocate(/mob/living/carbon/human, floor)
	var/list/tracked = reflection.vars["reflected_movables"]
	TEST_ASSERT(tracked && (subject in tracked), "The mirror must track a living mob spawned next to it.")

	// Nullspace first, so the turf's Exited fires while the mirror is not looking - this is how lighting objects vanish.
	subject.moveToNullspace()
	qdel(subject)

	tracked = reflection.vars["reflected_movables"]
	TEST_ASSERT(!tracked || !(subject in tracked), "The mirror kept a reference to a deleted movable, which turns into a hard delete.")

/// Nothing inanimate should ever enter the tracking list - that is what stranded dead lighting objects there.
/datum/unit_test/reflection_ignores_inanimate_movables
#ifdef FOCUS_REFLECTION_TRACKING
	focus = TRUE
#endif

/datum/unit_test/reflection_ignores_inanimate_movables/Run()
	var/turf/floor = run_loc_floor_bottom_left
	TEST_ASSERT_NOTNULL(floor, "Test setup needs a run turf.")

	var/obj/structure/mirror/mirror = allocate(/obj/structure/mirror, floor)
	var/datum/component/reflection/reflection = mirror.GetComponent(/datum/component/reflection)
	TEST_ASSERT_NOTNULL(reflection, "Test setup needs a mirror carrying a reflection component.")

	var/obj/structure/flora/grass/bush/bush = allocate(/obj/structure/flora/grass/bush, floor)
	TEST_ASSERT(!bush.casts_reflection(), "An inanimate structure must not claim to cast a reflection.")

	var/list/tracked = reflection.vars["reflected_movables"]
	TEST_ASSERT(!tracked || !(bush in tracked), "The mirror tracked an inanimate movable it could never draw.")

/// Both backends read one gate, so suppressing a reflection has to suppress it in mirrors and in water alike.
/datum/unit_test/reflection_gate_is_shared_by_both_backends
#ifdef FOCUS_REFLECTION_TRACKING
	focus = TRUE
#endif

/datum/unit_test/reflection_gate_is_shared_by_both_backends/Run()
	var/turf/floor = run_loc_floor_bottom_left
	TEST_ASSERT_NOTNULL(floor, "Test setup needs a run turf.")

	var/obj/structure/mirror/mirror = allocate(/obj/structure/mirror, floor)
	var/mob/living/carbon/human/subject = allocate(/mob/living/carbon/human, floor)

	TEST_ASSERT(subject.casts_reflection(), "An ordinary human casts a reflection.")
	TEST_ASSERT(mirror.can_reflect(subject), "An ordinary human is reflected by a mirror.")
	TEST_ASSERT_NOTNULL(subject.reflective_icon, "An ordinary human carries a stencil reflection for water to show.")

	ADD_TRAIT(subject, TRAIT_NO_REFLECTION, "unit_test")
	TEST_ASSERT(!subject.casts_reflection(), "TRAIT_NO_REFLECTION must clear the shared gate.")
	TEST_ASSERT(!mirror.can_reflect(subject), "A mirror must not reflect something carrying TRAIT_NO_REFLECTION.")
	TEST_ASSERT_NULL(subject.reflective_icon, "Water must not reflect something carrying TRAIT_NO_REFLECTION either.")

	REMOVE_TRAIT(subject, TRAIT_NO_REFLECTION, "unit_test")
	TEST_ASSERT(subject.casts_reflection(), "Dropping the trait restores the shared gate.")
	TEST_ASSERT_NOTNULL(subject.reflective_icon, "Dropping the trait restores the stencil reflection.")

	// has_reflection is the other half of the gate, and vampires flip it directly.
	subject.has_reflection = FALSE
	subject.update_reflection()
	TEST_ASSERT(!mirror.can_reflect(subject), "A mirror must respect has_reflection.")
	TEST_ASSERT_NULL(subject.reflective_icon, "Water must respect has_reflection.")

/// A mob lying in a puddle has to lie down in the puddle too, which means keeping its own transform.
/datum/unit_test/reflection_mirrors_the_subjects_transform
#ifdef FOCUS_REFLECTION_TRACKING
	focus = TRUE
#endif

/datum/unit_test/reflection_mirrors_the_subjects_transform/Run()
	var/turf/floor = run_loc_floor_bottom_left
	TEST_ASSERT_NOTNULL(floor, "Test setup needs a run turf.")

	var/mob/living/carbon/human/subject = allocate(/mob/living/carbon/human, floor)
	TEST_ASSERT_NOTNULL(subject.reflective_icon, "Test setup needs a subject that casts a reflection.")

	// Upright, the reflection is the plain vertical flip it always was.
	var/matrix/upright = subject.reflective_icon.transform
	TEST_ASSERT_EQUAL(upright.a, 1, "An upright reflection must not be rotated.")
	TEST_ASSERT_EQUAL(upright.e, -1, "An upright reflection must be flipped vertically.")

	subject.set_body_position(LYING_DOWN)
	subject.set_lying_angle(90)
	TEST_ASSERT_NOTNULL(subject.reflective_icon, "A lying subject still casts a reflection.")

	// The reflection has to be our own transform with its y row negated - anything else is a standing reflection.
	var/matrix/lying = subject.transform
	var/matrix/reflected = subject.reflective_icon.transform
	TEST_ASSERT_EQUAL(reflected.a, lying.a, "A lying reflection must keep the subject's rotation.")
	TEST_ASSERT_EQUAL(reflected.b, lying.b, "A lying reflection must keep the subject's rotation.")
	TEST_ASSERT_EQUAL(reflected.d, -lying.d, "A lying reflection must flip the subject's rotation vertically.")
	TEST_ASSERT_EQUAL(reflected.e, -lying.e, "A lying reflection must flip the subject's rotation vertically.")
	TEST_ASSERT_NOTEQUAL(reflected.b, 0, "A mob lying at 90 degrees must produce a rotated reflection, not an upright one.")

/// Walking up to a mirror should ease the reflection in rather than switch it on at the last tile.
/datum/unit_test/reflection_fades_in_with_distance
#ifdef FOCUS_REFLECTION_TRACKING
	focus = TRUE
#endif

/datum/unit_test/reflection_fades_in_with_distance/Run()
	var/turf/floor = run_loc_floor_bottom_left
	TEST_ASSERT_NOTNULL(floor, "Test setup needs a run turf.")

	var/obj/structure/mirror/mirror = allocate(/obj/structure/mirror, floor)
	var/datum/component/reflection/reflection = mirror.GetComponent(/datum/component/reflection)
	TEST_ASSERT_NOTNULL(reflection, "Test setup needs a mirror carrying a reflection component.")

	var/mob/living/carbon/human/subject = allocate(/mob/living/carbon/human, floor)
	TEST_ASSERT_EQUAL(reflection.get_reflection_alpha(subject), 255, "Standing on the mirror's own tile is full strength.")

	// One tile along the reflected direction, then two - the far one must be visible but dimmer.
	var/turf/near = get_step(floor, reflection.reflected_dir)
	var/turf/far = get_step(near, reflection.reflected_dir)
	TEST_ASSERT_NOTNULL(near, "Test setup needs a turf in front of the mirror.")
	TEST_ASSERT_NOTNULL(far, "Test setup needs a second turf in front of the mirror.")

	subject.forceMove(near)
	var/near_alpha = reflection.get_reflection_alpha(subject)
	subject.forceMove(far)
	var/far_alpha = reflection.get_reflection_alpha(subject)

	TEST_ASSERT_EQUAL(near_alpha, 255, "The tile in front of the mirror is full strength.")
	TEST_ASSERT(far_alpha > 0, "A mob two tiles out must still be reflected, or the reflection pops in at the last step.")
	TEST_ASSERT(far_alpha < near_alpha, "A mob two tiles out must be dimmer than one tile out, so approaching eases in.")
