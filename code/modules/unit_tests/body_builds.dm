/// Every build sheet has the limb and skeleton states the limb renderer asks for.
/datum/unit_test/body_build_sprite_states/Run()
	var/static/list/needed_states = list(
		"head", "chest", "l_arm", "r_arm", "l_hand", "r_hand", "l_leg", "r_leg", "l_leg_above", "r_leg_above",
		"head_s", "chest_s", "l_arm_s", "r_arm_s", "l_hand_s", "r_hand_s", "l_leg_s", "r_leg_s", "l_leg_above_s", "r_leg_above_s",
	)
	for(var/build_id in GLOB.body_builds)
		var/datum/body_build/build = GLOB.body_builds[build_id]
		for(var/sheet in list(build.limbs_icon_m, build.limbs_icon_f, build.limbs_icon_m_grey, build.limbs_icon_f_grey))
			if(!sheet)
				continue
			for(var/state in needed_states)
				if(!icon_exists(sheet, state))
					TEST_FAIL("[sheet] of the [build_id] build lacks the \"[state]\" state.")

/// Every build table carries each offset key worn items and genitals read.
/datum/unit_test/body_build_offset_tables/Run()
	var/static/list/worn_keys = list(OFFSET_RING, OFFSET_GLOVES, OFFSET_WRISTS, OFFSET_HANDS, OFFSET_CLOAK, OFFSET_FACEMASK, OFFSET_HEAD, OFFSET_FACE, OFFSET_BELT, OFFSET_BACK, OFFSET_NECK, OFFSET_MOUTH, OFFSET_PANTS, OFFSET_SHIRT, OFFSET_ARMOR, OFFSET_UNDIES)
	var/static/list/genital_keys = list(OFFSET_PENIS, OFFSET_BREASTS, OFFSET_TESTICLES, OFFSET_VAGINA)
	for(var/build_id in GLOB.body_builds)
		var/datum/body_build/build = GLOB.body_builds[build_id]
		for(var/test_gender in list(MALE, FEMALE))
			if(!build.supports(test_gender, BODY_PALETTE_SKIN) && !build.supports(test_gender, BODY_PALETTE_GREY))
				continue
			var/list/offsets = build.get_offsets(test_gender)
			for(var/key in worn_keys)
				if(!islist(offsets?[key]))
					TEST_FAIL("The [build_id] build has no [key] offset for [test_gender].")
			var/list/genital_offsets = build.get_genital_offsets(test_gender)
			for(var/key in genital_keys)
				if(!islist(genital_offsets?[key]))
					TEST_FAIL("The [build_id] build has no [key] genital offset for [test_gender].")

/// Default builds draw the exact sheet each species used before builds existed.
/datum/unit_test/body_build_defaults_keep_bodies/Run()
	for(var/species_id in GLOB.species_list)
		var/datum/species/species = allocate(GLOB.species_list[species_id])
		if(!length(species.allowed_body_builds))
			continue
		for(var/test_gender in list(MALE, FEMALE))
			var/configured = (test_gender == MALE) ? species.default_body_build_m : species.default_body_build_f
			if(!species.is_body_build_valid(configured, test_gender))
				TEST_FAIL("[species.type] has an invalid default [test_gender] build \"[configured]\".")
				continue
			var/datum/body_build/build = GLOB.body_builds[configured]
			var/expected = (test_gender == MALE) ? species.limbs_icon_m : species.limbs_icon_f
			var/drawn = build.get_limbs_icon(test_gender, species.body_build_palette)
			if(drawn != expected)
				TEST_FAIL("[species.type] [test_gender] default build draws [drawn] instead of [expected].")

/// Species without builds keep the cut, offsets and sprites the old copy-pasted render code chose.
/datum/unit_test/body_build_legacy_species_unchanged/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	for(var/species_id in GLOB.roundstart_species)
		human.set_species(GLOB.species_list[species_id], FALSE)
		var/datum/species/species = human.dna.species
		if(length(species.allowed_body_builds))
			continue
		for(var/test_gender in list(MALE, FEMALE))
			human.gender = test_gender
			var/legacy_cut = MALE_SPRITES
			if(species.sexes && (test_gender == FEMALE && !species.swap_female_clothes || test_gender == MALE && species.swap_male_clothes || test_gender == MALE && species.swap_male_clothes_but_not_offsets))
				legacy_cut = FEMALE_SPRITES
			var/legacy_torso = MALE_SPRITES
			if(species.sexes)
				if(test_gender == FEMALE && !species.swap_female_clothes)
					legacy_torso = FEMALE_BOOB
				else if(test_gender == MALE && species.swap_male_clothes)
					legacy_torso = FEMALE_SPRITES
			var/feminine_tables = legacy_cut && !(test_gender == MALE && species.swap_male_clothes_but_not_offsets)
			var/feminine_genitals = species.sexes && (test_gender == FEMALE && !species.swap_female_clothes || test_gender == MALE && species.swap_male_clothes)
			var/label = "[species.type] [test_gender]"
			if(human.get_worn_cut() != legacy_cut)
				TEST_FAIL("[label] worn cut changed.")
			if(human.get_torso_cut() != legacy_torso)
				TEST_FAIL("[label] torso cut changed.")
			if(human.get_offset_features() != (feminine_tables ? species.offset_features_f : species.offset_features_m))
				TEST_FAIL("[label] offset table changed.")
			if(human.get_genital_offsets() != (feminine_genitals ? species.offset_genitals_f : species.offset_genitals_m))
				TEST_FAIL("[label] genital offset table changed.")
			if(human.get_damage_icon() != (feminine_tables ? species.dam_icon_f : species.dam_icon_m))
				TEST_FAIL("[label] damage sheet changed.")
			if(human.get_limbs_icon() != ((test_gender == MALE) ? species.limbs_icon_m : species.limbs_icon_f))
				TEST_FAIL("[label] limb sheet changed.")
			if(human.uses_feminine_sleeves() != ((test_gender == FEMALE) ^ species.swap_female_clothes))
				TEST_FAIL("[label] sleeve set changed.")

/// A build swaps the limb sheet, offsets and cached render key; an unknown build falls back.
/datum/unit_test/body_build_render/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.gender = MALE
	human.set_species(/datum/species/human/northern)
	human.dna.features["body_build"] = BODY_BUILD_AVERAGE
	human.update_body_parts(TRUE)
	var/average_key = human.generate_icon_render_key()
	var/obj/item/bodypart/chest = human.get_bodypart(BODY_ZONE_CHEST)
	TEST_ASSERT_EQUAL(chest.species_icon, 'icons/roguetown/mob/bodies/m/mm.dmi', "An average man should draw mm.dmi.")
	human.dna.features["body_build"] = BODY_BUILD_BROAD
	human.update_body_parts(TRUE)
	TEST_ASSERT_NOTEQUAL(human.generate_icon_render_key(), average_key, "Builds must not share cached limbs.")
	TEST_ASSERT_EQUAL(chest.species_icon, 'icons/roguetown/mob/bodies/m/mt.dmi', "A broad man should draw mt.dmi.")
	TEST_ASSERT_EQUAL(human.get_offset_features()[OFFSET_HEAD][2], 1, "The broad frame raises hats a pixel.")
	human.dna.features["body_build"] = BODY_BUILD_LITHE
	var/datum/body_build/resolved = human.get_body_build()
	TEST_ASSERT_EQUAL(resolved?.id, BODY_BUILD_AVERAGE, "Humans cannot take the elven lithe body.")
	human.dna.features["body_build"] = "nonsense"
	resolved = human.get_body_build()
	TEST_ASSERT_EQUAL(resolved?.id, BODY_BUILD_AVERAGE, "An unknown build should fall back to the species default.")

/// Builds set the clothing cut per sex: broad women wear the masculine cut, slim men the mixed one.
/datum/unit_test/body_build_clothing_cut/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.gender = FEMALE
	human.set_species(/datum/species/human/northern)
	human.dna.features["body_build"] = BODY_BUILD_BROAD
	TEST_ASSERT_EQUAL(human.get_body_cut(), BODY_CUT_MASCULINE, "A broad woman wears the masculine cut.")
	TEST_ASSERT_EQUAL(human.get_torso_cut(), MALE_SPRITES, "A broad woman's shirts use the masculine sprites.")
	TEST_ASSERT_EQUAL(human.get_damage_icon(), 'icons/roguetown/mob/bodies/dam/dam_male.dmi', "The broad frame uses the masculine damage sheet.")
	TEST_ASSERT_EQUAL(human.get_marking_sex(), "m", "The broad frame uses masculine marking art.")
	human.dna.features["body_build"] = BODY_BUILD_SLIM
	TEST_ASSERT_EQUAL(human.get_torso_cut(), FEMALE_BOOB, "A slim woman's shirts add the chest overlay.")
	TEST_ASSERT_EQUAL(human.get_torso_cut(TRUE), FEMALE_SPRITES, "A hidden chest drops the chest overlay.")
	human.gender = MALE
	human.dna.features["body_build"] = BODY_BUILD_SLIM
	TEST_ASSERT_EQUAL(human.get_body_cut(), BODY_CUT_MIXED, "A slim man wears the elven mixed cut.")
	TEST_ASSERT_EQUAL(human.get_worn_cut(), FEMALE_SPRITES, "A slim man's ordinary slots use feminine sprites.")
	TEST_ASSERT_EQUAL(human.get_torso_cut(), MALE_SPRITES, "A slim man's shirts keep the masculine sprites.")
	TEST_ASSERT(!human.uses_feminine_sleeves(), "A slim man keeps masculine sleeves.")
	TEST_ASSERT_EQUAL(human.get_offset_features()[OFFSET_FACE][2], 0, "mem.dmi eyes sit at the mm.dmi height.")
	TEST_ASSERT_EQUAL(human.get_marking_offset(BODY_ZONE_HEAD), -1, "Masculine marking art is drawn a pixel higher than mem.dmi.")

/// A build change touches nothing but the build, and refuses builds the body cannot take.
/datum/unit_test/body_build_preference_change/Run()
	var/datum/preferences/prefs = allocate(/datum/preferences)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	prefs.set_species_preference(/datum/species/human/northern)
	prefs.write_preference(/datum/preference/choiced/gender, FEMALE)
	prefs.validate_customizer_entries()
	prefs.sanitize_body_build()
	TEST_ASSERT_EQUAL(prefs.get_body_build_id(), BODY_BUILD_SLIM, "A human woman should start on the slim body.")
	var/datum/customizer_entry/hair = prefs.get_customizer_entry_of_type(/datum/customizer_entry/hair/head)
	TEST_ASSERT_NOTNULL(hair, "A human should have a hair entry.")
	var/old_hair = hair.accessory_type
	var/old_name = prefs.read_preference(/datum/preference/text/real_name)
	prefs.character_setup_apply_body_build(user, BODY_BUILD_BROAD)
	TEST_ASSERT_EQUAL(prefs.features["body_build"], BODY_BUILD_BROAD, "The broad build should be saved.")
	TEST_ASSERT_EQUAL(hair.accessory_type, old_hair, "A build change must keep the hairstyle.")
	TEST_ASSERT_EQUAL(prefs.read_preference(/datum/preference/text/real_name), old_name, "A build change must keep the name.")
	prefs.character_setup_apply_body_build(user, BODY_BUILD_AVERAGE)
	TEST_ASSERT_EQUAL(prefs.features["body_build"], BODY_BUILD_BROAD, "Average has no feminine body and must be refused.")
	prefs.character_setup_apply_body_build(user, BODY_BUILD_LITHE)
	TEST_ASSERT_EQUAL(prefs.features["body_build"], BODY_BUILD_BROAD, "Lithe is offered to elves only.")

/// Flipping the body keeps name, hair, pronouns and voice; a default build moves to the new default.
/datum/unit_test/body_build_sex_toggle/Run()
	var/datum/preferences/prefs = allocate(/datum/preferences)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	prefs.set_species_preference(/datum/species/human/northern)
	prefs.write_preference(/datum/preference/choiced/gender, FEMALE)
	prefs.write_preference(/datum/preference/choiced/pronouns, THEY_THEM)
	prefs.write_preference(/datum/preference/choiced/voice_type, VOICE_TYPE_ANDRO)
	prefs.validate_customizer_entries()
	prefs.sanitize_body_build()
	var/datum/customizer_entry/hair = prefs.get_customizer_entry_of_type(/datum/customizer_entry/hair/head)
	var/old_hair = hair?.accessory_type
	var/old_name = prefs.read_preference(/datum/preference/text/real_name)
	var/datum/preference/gender_preference = GLOB.preference_entries[/datum/preference/choiced/gender]
	gender_preference.handle_link(prefs, user)
	TEST_ASSERT_EQUAL(prefs.read_preference(/datum/preference/choiced/gender), MALE, "The toggle should flip to masculine.")
	TEST_ASSERT_EQUAL(prefs.get_body_build_id(), BODY_BUILD_AVERAGE, "The default feminine build should become the default masculine one.")
	TEST_ASSERT_EQUAL(prefs.read_preference(/datum/preference/text/real_name), old_name, "The toggle must keep the name.")
	TEST_ASSERT_EQUAL(prefs.read_preference(/datum/preference/choiced/pronouns), THEY_THEM, "The toggle must keep pronouns.")
	TEST_ASSERT_EQUAL(prefs.read_preference(/datum/preference/choiced/voice_type), VOICE_TYPE_ANDRO, "The toggle must keep the voice.")
	var/datum/customizer_entry/hair_after = prefs.get_customizer_entry_of_type(/datum/customizer_entry/hair/head)
	TEST_ASSERT_EQUAL(hair_after?.accessory_type, old_hair, "The toggle must keep the hairstyle.")
	prefs.character_setup_apply_body_build(user, BODY_BUILD_BROAD)
	gender_preference.handle_link(prefs, user)
	TEST_ASSERT_EQUAL(prefs.get_body_build_id(), BODY_BUILD_BROAD, "A build both sexes share should survive the toggle.")

/// Picking another species keeps the customizers it still allows and a build it still offers.
/datum/unit_test/body_build_species_change_keeps_customizers/Run()
	var/datum/preferences/prefs = allocate(/datum/preferences)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	prefs.set_species_preference(/datum/species/human/northern)
	prefs.write_preference(/datum/preference/choiced/gender, MALE)
	prefs.validate_customizer_entries()
	prefs.features["body_build"] = BODY_BUILD_MUSCULAR
	var/datum/customizer_entry/hair = prefs.get_customizer_entry_of_type(/datum/customizer_entry/hair/head)
	TEST_ASSERT_NOTNULL(hair, "A human should have a hair entry.")
	var/old_hair = hair.accessory_type
	var/old_colors = hair.accessory_colors
	var/old_name = prefs.read_preference(/datum/preference/text/real_name)
	prefs.character_setup_apply_species(user, SPEC_ID_HALF_ELF)
	TEST_ASSERT(istype(prefs.pref_species, /datum/species/human/halfelf), "The species should change to half-elf.")
	TEST_ASSERT(prefs.get_customizer_entry_of_type(/datum/customizer_entry/hair/head) == hair, "The hair entry should be kept, not rebuilt.")
	TEST_ASSERT_EQUAL(hair.accessory_type, old_hair, "The hairstyle should be kept.")
	TEST_ASSERT_EQUAL(hair.accessory_colors, old_colors, "The hair colour should be kept.")
	TEST_ASSERT_EQUAL(prefs.read_preference(/datum/preference/choiced/gender), MALE, "The species change should keep the body.")
	TEST_ASSERT_EQUAL(prefs.get_body_build_id(), BODY_BUILD_MUSCULAR, "A build the new species offers should be kept.")
	TEST_ASSERT_EQUAL(prefs.read_preference(/datum/preference/text/real_name), old_name, "The species change should keep the name.")
	prefs.character_setup_apply_species(user, SPEC_ID_DWARF)
	TEST_ASSERT_NULL(prefs.features["body_build"], "A species without builds should clear the saved build.")
