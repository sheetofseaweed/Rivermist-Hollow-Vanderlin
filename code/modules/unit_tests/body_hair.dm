/// Every species offering pubic or armpit hair has art drawn for both of its bodies.
/datum/unit_test/body_hair_art_covers_species/Run()
	var/list/hair_accessories = subtypesof(/datum/sprite_accessory/body_hair/pubic) + subtypesof(/datum/sprite_accessory/body_hair/armpit)
	for(var/datum/sprite_accessory/body_hair/accessory_type as anything in hair_accessories)
		var/preview_state = initial(accessory_type.icon_state)
		if(preview_state && !icon_exists(initial(accessory_type.icon), preview_state))
			TEST_FAIL("[accessory_type] has no preferences preview state \"[preview_state]\".")
	for(var/species_id in GLOB.species_list)
		var/species_type = GLOB.species_list[species_id]
		var/datum/species/species = allocate(species_type)
		var/offers_hair = FALSE
		for(var/customizer_type in species.customizers)
			if(ispath(customizer_type, /datum/customizer/bodypart_feature/pubic_hair) || ispath(customizer_type, /datum/customizer/bodypart_feature/armpit_hair))
				offers_hair = TRUE
				break
		if(!offers_hair)
			continue
		for(var/body_icon in list(species.limbs_icon_m, species.limbs_icon_f))
			var/art_key = GLOB.body_hair_art_keys["[body_icon]"]
			if(!art_key)
				TEST_FAIL("[species_type] offers body hair, but its body [body_icon] has no body hair art key.")
				continue
			for(var/datum/sprite_accessory/body_hair/accessory_type as anything in hair_accessories)
				var/art_state = initial(accessory_type.art_state)
				if(!art_state)
					continue
				var/icon_file = GLOB.body_hair_tall_art_keys[art_key] ? initial(accessory_type.tall_icon) : initial(accessory_type.icon)
				if(!icon_exists(icon_file, "[art_state]_[art_key]"))
					TEST_FAIL("[icon_file] has no \"[art_state]_[art_key]\" state for [species_type].")

/// Short bodies get their own pre-aligned art, never a shared sprite shifted by a species offset.
/datum/unit_test/body_hair_uses_per_body_art/Run()
	var/mob/living/carbon/human/dwarf = allocate(/mob/living/carbon/human)
	dwarf.gender = MALE
	dwarf.set_species(/datum/species/dwarf/mountain)
	var/obj/item/bodypart/chest = dwarf.get_bodypart(BODY_ZONE_CHEST)
	var/datum/sprite_accessory/body_hair/pubic/hairy = SPRITE_ACCESSORY(/datum/sprite_accessory/body_hair/pubic/hairy)
	TEST_ASSERT_EQUAL(hairy.get_icon_state(null, chest, dwarf), "hairy_md", "A male dwarf should draw the dwarf pubic hair state.")
	var/list/appearances = hairy.get_appearance(null, chest, "#000000")
	TEST_ASSERT(length(appearances), "A naked dwarf should draw its pubic hair.")
	for(var/mutable_appearance/appearance as anything in appearances)
		TEST_ASSERT_EQUAL(appearance.pixel_y, 0, "Per-body art must not be shifted by a species offset.")

	var/mob/living/carbon/human/ogre = allocate(/mob/living/carbon/human)
	ogre.gender = FEMALE
	ogre.set_species(/datum/species/ogre)
	var/datum/sprite_accessory/body_hair/armpit/armpit = SPRITE_ACCESSORY(/datum/sprite_accessory/body_hair/armpit/hairy)
	TEST_ASSERT_EQUAL(armpit.get_icon(null, ogre.get_bodypart(BODY_ZONE_CHEST), ogre), armpit.tall_icon, "Ogres should draw from the tall armpit hair dmi.")

/// The sprite cache must not hand one body's sprite to another body with the same state name.
/datum/unit_test/accessory_cache_keys_icon_file/Run()
	var/datum/sprite_accessory/body_hair/body/hairy = SPRITE_ACCESSORY(/datum/sprite_accessory/body_hair/body/hairy)
	var/cache_size = length(hairy.accessory_icon_cache)
	hairy.get_overlay("t2", "#123456", TRUE, 'icons/roguetown/mob/bodies/m/mm.dmi')
	hairy.get_overlay("t2", "#123456", TRUE, 'icons/roguetown/mob/bodies/m/md.dmi')
	TEST_ASSERT_EQUAL(length(hairy.accessory_icon_cache) - cache_size, 2, "Chest hair from two body files should get two cache entries.")

/datum/unit_test/pubic_hair_grooming_cycle/Run()
	var/datum/bodypart_feature/hair/body_hair/pubic/pubic_hair = allocate(/datum/bodypart_feature/hair/body_hair/pubic)
	var/heart = /datum/sprite_accessory/body_hair/pubic/style/heart
	pubic_hair.set_hairiness_level(HAIRINESS_VERY_HAIRY, TRUE)

	TEST_ASSERT(pubic_hair.shape(heart), "A full bush should take a style.")
	TEST_ASSERT_EQUAL(pubic_hair.accessory_type, heart, "A styled bush should draw the style.")
	TEST_ASSERT_EQUAL(pubic_hair.current_level, HAIRINESS_SOME_HAIR, "Styling should cut the hair to trim length.")
	TEST_ASSERT_EQUAL(pubic_hair.grooming_state, HAIR_GROOMING_STYLED, "Styling should mark the hair as styled.")
	TEST_ASSERT(!pubic_hair.shape(heart), "Restyling into the same shape should do nothing.")

	TEST_ASSERT(pubic_hair.grow_one_level(), "Styled hair should grow back toward its natural length.")
	TEST_ASSERT_EQUAL(pubic_hair.accessory_type, /datum/sprite_accessory/body_hair/pubic/hairy, "Regrowth should wear the style off.")
	TEST_ASSERT_EQUAL(pubic_hair.grooming_state, HAIR_GROOMING_TRIMMED, "Hair still short of its natural length counts as trimmed.")
	pubic_hair.grow_one_level()
	TEST_ASSERT_EQUAL(pubic_hair.grooming_state, HAIR_GROOMING_NATURAL, "Hair back at its natural length counts as natural.")

	TEST_ASSERT(pubic_hair.trim(), "A full bush should trim.")
	TEST_ASSERT_EQUAL(pubic_hair.current_level, HAIRINESS_SOME_HAIR, "Trimming should cut the hair to trim length.")
	TEST_ASSERT(pubic_hair.shave(), "Trimmed hair should shave.")
	TEST_ASSERT(!pubic_hair.shape(heart), "Shaved skin has nothing to style.")
	TEST_ASSERT(!pubic_hair.set_style(heart), "A preference style needs some hair.")
	TEST_ASSERT_EQUAL(pubic_hair.accessory_type, /datum/sprite_accessory/body_hair/pubic/shaved, "Shaved hair should draw nothing.")

/// The pubic hair is told once per examine, on the genital it frames.
/datum/unit_test/pubic_hair_described_once/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/organ/genitals/penis/penis = new
	penis.Insert(human, TRUE, FALSE)
	var/obj/item/organ/genitals/filling_organ/testicles/testicles = new
	testicles.Insert(human, TRUE, FALSE)
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = new
	vagina.Insert(human, TRUE, FALSE)
	var/datum/bodypart_feature/hair/body_hair/pubic/pubic_hair = new
	pubic_hair.set_accessory_type(/datum/sprite_accessory/body_hair/pubic/hairy, null, human)
	human.add_bodypart_feature(pubic_hair)

	var/datum/mob_descriptor/penis_descriptor = MOB_DESCRIPTOR(/datum/mob_descriptor/penis)
	var/datum/mob_descriptor/testicles_descriptor = MOB_DESCRIPTOR(/datum/mob_descriptor/testicles)
	var/datum/mob_descriptor/vagina_descriptor = MOB_DESCRIPTOR(/datum/mob_descriptor/vagina)
	var/penis_text = penis_descriptor.get_description(human)
	var/testicles_text = testicles_descriptor.get_description(human)
	var/vagina_text = vagina_descriptor.get_description(human)
	var/all_text = "[penis_text] [testicles_text] [vagina_text]"
	TEST_ASSERT_EQUAL(length(splittext(all_text, "pubic hair")) - 1, 1, "Pubic hair should be described exactly once: [all_text]")
	TEST_ASSERT(findtext(testicles_text, ", framed by a dense bush of pubic hair"), "Balls follow the penis in examine, so they carry the hair: [testicles_text]")

	penis.sheath_type = SHEATH_TYPE_SLIT
	penis.erect_state = ERECT_STATE_NONE
	penis_text = penis_descriptor.get_description(human)
	TEST_ASSERT(findtext(penis_text, "genital slit, framed by"), "Balls hidden in a slit should pass the hair to the slit: [penis_text]")

	pubic_hair.set_material(BODY_HAIR_MATERIAL_FUR)
	pubic_hair.set_style(/datum/sprite_accessory/body_hair/pubic/style/heart)
	penis_text = penis_descriptor.get_description(human)
	TEST_ASSERT(findtext(penis_text, "a heart-shaped tuft of pubic fur"), "Style and material should show in the text: [penis_text]")

/datum/unit_test/armpit_hair_examine/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/datum/mob_descriptor/armpit_hair/descriptor = MOB_DESCRIPTOR(/datum/mob_descriptor/armpit_hair)
	TEST_ASSERT(!descriptor.can_describe(human), "No armpit hair feature means no armpit line.")
	var/datum/bodypart_feature/hair/body_hair/armpit/armpit_hair = new
	armpit_hair.set_accessory_type(/datum/sprite_accessory/body_hair/armpit/hairy, null, human)
	human.add_bodypart_feature(armpit_hair)
	TEST_ASSERT(descriptor.can_describe(human), "Bare hairy armpits should be described.")
	TEST_ASSERT_EQUAL(descriptor.get_description(human), "a dense bush of armpit hair", "Armpit text should name the level and material.")
	TEST_ASSERT(human.remove_hair_at_zone(BODY_ZONE_L_ARM), "Hair removal on an arm should strip the armpit.")
	TEST_ASSERT(!descriptor.can_describe(human), "Shaved armpits should not be described.")

	human.next_body_hair_growth = 0
	human.handle_body_hair_growth()
	TEST_ASSERT_EQUAL(armpit_hair.current_level, HAIRINESS_SHAVED, "Armpit hair must not regrow while regrowth is off.")
	armpit_hair.growth_enabled = TRUE
	human.next_body_hair_growth = 0
	human.handle_body_hair_growth()
	TEST_ASSERT_EQUAL(armpit_hair.current_level, HAIRINESS_STUBBLE, "Armpit hair should regrow one level per growth tick.")
	human.handle_body_hair_growth()
	TEST_ASSERT_EQUAL(armpit_hair.current_level, HAIRINESS_STUBBLE, "Regrowth should wait for the growth interval.")

/// Armpit hair starts on only for species known for it, and every species picks its own material.
/datum/unit_test/armpit_hair_defaults/Run()
	var/mob/living/carbon/human/dwarf = allocate(/mob/living/carbon/human)
	dwarf.set_species(/datum/species/dwarf/mountain)
	var/datum/customizer/dwarf_customizer = CUSTOMIZER(/datum/customizer/bodypart_feature/armpit_hair/enabled)
	var/datum/customizer_entry/armpit_hair/dwarf_entry = dwarf_customizer.make_default_customizer_entry(dwarf, FALSE)
	TEST_ASSERT(!dwarf_entry.disabled, "Dwarves should start with armpit hair.")
	TEST_ASSERT_EQUAL(dwarf_entry.material, BODY_HAIR_MATERIAL_BRAIDS, "Dwarves should default to braids.")

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.set_species(/datum/species/human/northern)
	var/datum/customizer/human_customizer = CUSTOMIZER(/datum/customizer/bodypart_feature/armpit_hair)
	var/datum/customizer_entry/armpit_hair/human_entry = human_customizer.make_default_customizer_entry(human, FALSE)
	TEST_ASSERT(human_entry.disabled, "Humans should start without armpit hair.")
	TEST_ASSERT_EQUAL(human_entry.material, BODY_HAIR_MATERIAL_HAIR, "Humans should default to hair.")

/// The character menu must expose the regrowth, material and shape controls, or players cannot reach them.
/datum/unit_test/body_hair_menu_controls/Run()
	var/datum/preferences/prefs = allocate(/datum/preferences)
	prefs.validate_customizer_entries()
	var/list/tasks_by_feature = list()
	for(var/list/feature as anything in prefs.character_setup_build_features_data())
		var/list/tasks = list()
		for(var/list/extra as anything in feature["extras"])
			tasks += extra["task"]
		tasks_by_feature[feature["key"]] = tasks
	var/list/pubic_tasks = tasks_by_feature["[/datum/customizer/bodypart_feature/pubic_hair]"]
	TEST_ASSERT(pubic_tasks, "Humans should see a pubic hair feature in the menu.")
	for(var/task in list("pubic_hair_style", "body_hair_material", "toggle_body_hair_growth"))
		TEST_ASSERT(task in pubic_tasks, "The pubic hair feature should offer [task].")
	var/list/armpit_tasks = tasks_by_feature["[/datum/customizer/bodypart_feature/armpit_hair]"]
	TEST_ASSERT(armpit_tasks, "Humans should see an armpit hair feature in the menu.")
	TEST_ASSERT("toggle_body_hair_growth" in armpit_tasks, "Armpit hair should offer regrowth.")

	var/datum/customizer_entry/armpit_hair/armpit_entry = prefs.get_customizer_entry_for_customizer_type(/datum/customizer/bodypart_feature/armpit_hair)
	prefs.handle_customizer_topic(null, list("customizer" = "[/datum/customizer/bodypart_feature/armpit_hair]", "customizer_task" = "toggle_body_hair_growth"))
	TEST_ASSERT(armpit_entry.growth_enabled, "The regrowth button should switch armpit regrowth on.")

/// Each species offers only materials that fit its body, and a species swap drops a material the new one lacks.
/datum/unit_test/body_hair_materials_fit_species/Run()
	for(var/species_id in GLOB.species_list)
		var/species_type = GLOB.species_list[species_id]
		var/datum/species/species = allocate(species_type)
		TEST_ASSERT(length(species.body_hair_materials), "[species_type] needs at least one body hair material.")
		for(var/material in species.body_hair_materials)
			TEST_ASSERT(material in BODY_HAIR_MATERIALS_ANY, "[species_type] lists unknown body hair material [material].")

	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.set_species(/datum/species/human/northern)
	TEST_ASSERT(!(BODY_HAIR_MATERIAL_FUR in human.dna.species.body_hair_materials), "Humans should not grow fur.")
	var/datum/customizer_choice/pubic_choice = CUSTOMIZER_CHOICE(/datum/customizer_choice/bodypart_feature/pubic_hair)
	var/datum/customizer_entry/pubic_hair/pubic_entry = pubic_choice.make_default_customizer_entry(human, /datum/customizer/bodypart_feature/pubic_hair)
	pubic_entry.material = BODY_HAIR_MATERIAL_FUR
	pubic_choice.validate_entry(human, pubic_entry)
	TEST_ASSERT_EQUAL(pubic_entry.material, BODY_HAIR_MATERIAL_HAIR, "A human's fur should fall back to hair.")
	pubic_entry.material = BODY_HAIR_MATERIAL_BRAIDS
	pubic_choice.validate_entry(human, pubic_entry)
	TEST_ASSERT_EQUAL(pubic_entry.material, BODY_HAIR_MATERIAL_BRAIDS, "Humans may braid their hair.")

	human.set_species(/datum/species/anthromorph)
	pubic_entry.material = BODY_HAIR_MATERIAL_FUR
	pubic_choice.validate_entry(human, pubic_entry)
	TEST_ASSERT_EQUAL(pubic_entry.material, BODY_HAIR_MATERIAL_FUR, "Anthromorphs should keep their fur.")
