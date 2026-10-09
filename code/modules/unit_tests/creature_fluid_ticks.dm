/datum/unit_test/creature_testicles_refill_after_emptying

/datum/unit_test/creature_testicles_refill_after_emptying/Run()
	var/mob/living/simple_animal/hostile/retaliate/wolf/wolf = allocate(/mob/living/simple_animal/hostile/retaliate/wolf)
	wolf.gender = MALE
	wolf.give_genitals()
	var/obj/item/organ/genitals/filling_organ/testicles/testes = wolf.getorganslot(ORGAN_SLOT_TESTICLES)
	TEST_ASSERT_NOTNULL(testes, "Test setup: the wolf grew no testicles.")
	var/seed_type = testes.reagent_to_make
	var/full_amount = testes.reagents.get_reagent_amount(seed_type)
	var/nutrition_before = wolf.nutrition

	var/ticking_while_full = testes.creature_fluid_ticking
	testes.reagents.remove_reagent(seed_type, 10)
	var/ticking_after_emptying = testes.creature_fluid_ticking
	var/listed_after_emptying = (testes in SSslowobj.processing)
	var/emptied_amount = testes.reagents.get_reagent_amount(seed_type)

	testes.creature_fluid_ticked_at = world.time - 30 SECONDS
	testes.process_creature_fluids()
	var/amount_after_tick = testes.reagents.get_reagent_amount(seed_type)
	for(var/tick in 1 to 10)
		if(!testes.creature_fluid_ticking)
			break
		testes.creature_fluid_ticked_at = world.time - 1 MINUTES
		testes.process_creature_fluids()
	var/refilled_amount = testes.reagents.get_reagent_amount(seed_type)
	var/ticking_when_refilled = testes.creature_fluid_ticking
	var/listed_when_refilled = (testes in SSslowobj.processing)
	testes.stop_creature_fluid_ticks()

	TEST_ASSERT(!ticking_while_full, "A full creature organ must not tick.")
	TEST_ASSERT(ticking_after_emptying, "Emptying a creature organ must start its ticks.")
	TEST_ASSERT(listed_after_emptying, "A ticking creature organ must be on the slow object loop.")
	TEST_ASSERT(amount_after_tick > emptied_amount, "A creature tick must refill some seed.")
	TEST_ASSERT(refilled_amount >= full_amount - 0.1, "Creature testicles must refill to capacity ([refilled_amount] of [full_amount]).")
	TEST_ASSERT(!ticking_when_refilled, "A refilled creature organ must stop ticking.")
	TEST_ASSERT(!listed_when_refilled, "A refilled creature organ must leave the slow object loop.")
	TEST_ASSERT_EQUAL(wolf.nutrition, nutrition_before, "Creature fluid refills must not cost nutrition.")

/datum/unit_test/creature_vagina_drains_foreign_fluid

/datum/unit_test/creature_vagina_drains_foreign_fluid/Run()
	var/mob/living/simple_animal/hostile/retaliate/wolf/wolf = allocate(/mob/living/simple_animal/hostile/retaliate/wolf)
	wolf.gender = FEMALE
	wolf.give_genitals()
	var/obj/item/organ/genitals/filling_organ/vagina/vagina = wolf.getorganslot(ORGAN_SLOT_VAGINA)
	TEST_ASSERT_NOTNULL(vagina, "Test setup: the wolf grew no vagina.")

	vagina.reagents.add_reagent(/datum/reagent/consumable/cum, 5)
	var/ticking_after_creampie = vagina.creature_fluid_ticking
	COOLDOWN_RESET(vagina, liquidcd)
	vagina.creature_fluid_ticked_at = world.time - 30 SECONDS
	vagina.process_creature_fluids()
	var/seed_left = vagina.reagents.get_reagent_amount(/datum/reagent/consumable/cum)
	vagina.stop_creature_fluid_ticks()

	TEST_ASSERT(ticking_after_creampie, "Foreign fluid in a creature organ must start its ticks.")
	TEST_ASSERT(seed_left < 5, "A creature tick must start draining foreign fluid.")

/datum/unit_test/creature_fluid_ticks_skip_carbons_and_the_dead

/datum/unit_test/creature_fluid_ticks_skip_carbons_and_the_dead/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.gender = MALE
	human.give_genitals()
	var/obj/item/organ/genitals/filling_organ/testicles/human_testes = human.getorganslot(ORGAN_SLOT_TESTICLES)
	TEST_ASSERT_NOTNULL(human_testes, "Test setup: the human grew no testicles.")
	human_testes.reagents.add_reagent(human_testes.reagent_to_make, 10)
	human_testes.reagents.remove_reagent(human_testes.reagent_to_make, 5)
	var/human_ticking = human_testes.creature_fluid_ticking

	var/mob/living/simple_animal/hostile/retaliate/wolf/wolf = allocate(/mob/living/simple_animal/hostile/retaliate/wolf)
	wolf.gender = MALE
	wolf.give_genitals()
	var/obj/item/organ/genitals/filling_organ/testicles/wolf_testes = wolf.getorganslot(ORGAN_SLOT_TESTICLES)
	TEST_ASSERT_NOTNULL(wolf_testes, "Test setup: the wolf grew no testicles.")
	wolf_testes.reagents.remove_reagent(wolf_testes.reagent_to_make, 5)
	var/wolf_ticking = wolf_testes.creature_fluid_ticking
	wolf.death()
	var/still_owned = wolf_testes.owner == wolf
	var/amount_at_death = wolf_testes.reagents.get_reagent_amount(wolf_testes.reagent_to_make)
	wolf_testes.creature_fluid_ticked_at = world.time - 30 SECONDS
	wolf_testes.process_creature_fluids()
	var/dead_wolf_ticking = wolf_testes.creature_fluid_ticking
	var/amount_after_dead_tick = wolf_testes.reagents.get_reagent_amount(wolf_testes.reagent_to_make)
	wolf_testes.stop_creature_fluid_ticks()

	TEST_ASSERT(!human_ticking, "Carbon organs tick in Life and must never use the creature loop.")
	TEST_ASSERT(wolf_ticking, "Test setup: emptying the wolf's testicles should start its ticks.")
	TEST_ASSERT(still_owned, "Test setup: a dead wolf should keep its organs.")
	TEST_ASSERT(!dead_wolf_ticking, "A dead creature's organs must stop ticking.")
	TEST_ASSERT_EQUAL(amount_after_dead_tick, amount_at_death, "A dead creature must not refill.")
