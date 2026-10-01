/// Look-alike humans share limb_icon_cache slots, so a cache load must keep each human's own organ sprites.
/datum/unit_test/limb_cache_keeps_breast_sizes_apart/Run()
	var/mob/living/carbon/human/cached = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/loader = allocate(/mob/living/carbon/human)
	loader.gender = cached.gender
	loader.age = cached.age
	loader.skin_tone = cached.skin_tone
	give_render_test_breasts(cached, BREAST_SIZE_SMALL)
	give_render_test_breasts(loader, BREAST_SIZE_ENORMOUS)

	cached.update_body_parts(TRUE)
	TEST_ASSERT(has_limb_icon_state(cached, "pair_[BREAST_SIZE_SMALL]_ADJ"), "The cached human should draw its own small breasts.")

	loader.icon_render_key = null
	loader.update_body_parts()
	TEST_ASSERT(has_limb_icon_state(loader, "pair_[BREAST_SIZE_ENORMOUS]_ADJ"), "A cache load should keep the loader's own breast size.")
	TEST_ASSERT(!has_limb_icon_state(loader, "pair_[BREAST_SIZE_SMALL]_ADJ"), "A cache load must not show another human's breast size.")

/datum/unit_test/organ_render_key_tracks_sprite_inputs/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/filling_organ/breasts/breasts = give_render_test_breasts(human, BREAST_SIZE_NORMAL)
	var/last_key = human.generate_icon_render_key()

	breasts.accessory_colors = "#FF0000"
	TEST_ASSERT_NOTEQUAL(human.generate_icon_render_key(), last_key, "Organ colours should change the render key.")
	last_key = human.generate_icon_render_key()

	breasts.accessory_type = /datum/sprite_accessory/genitals/breasts/quad
	TEST_ASSERT_NOTEQUAL(human.generate_icon_render_key(), last_key, "Organ accessory type should change the render key.")
	last_key = human.generate_icon_render_key()

	var/obj/item/organ/genitals/belly/belly = allocate(/obj/item/organ/genitals/belly)
	belly.Insert(human, TRUE, FALSE)
	last_key = human.generate_icon_render_key()
	belly.set_fullness_growth_steps(2)
	TEST_ASSERT_NOTEQUAL(human.generate_icon_render_key(), last_key, "Belly growth should change the render key.")

	var/obj/item/organ/genitals/penis/penis = allocate(/obj/item/organ/genitals/penis)
	penis.accessory_type = /datum/sprite_accessory/genitals/penis/human
	penis.Insert(human, TRUE, FALSE)
	penis.erect_state = ERECT_STATE_NONE
	last_key = human.generate_icon_render_key()
	penis.erect_state = ERECT_STATE_HARD
	TEST_ASSERT_NOTEQUAL(human.generate_icon_render_key(), last_key, "An erection should change the render key.")

/datum/unit_test/proc/give_render_test_breasts(mob/living/carbon/human/human, size)
	var/obj/item/organ/genitals/filling_organ/breasts/breasts = allocate(/obj/item/organ/genitals/filling_organ/breasts)
	breasts.accessory_type = /datum/sprite_accessory/genitals/breasts/pair
	breasts.accessory_colors = "#FFFFFF"
	breasts.organ_size = size
	breasts.Insert(human, TRUE, FALSE)
	return breasts

/datum/unit_test/proc/has_limb_icon_state(mob/living/carbon/human/human, state)
	for(var/mutable_appearance/overlay as anything in human.overlays_standing[BODYPARTS_LAYER])
		if(overlay.icon_state == state)
			return TRUE
	return FALSE
