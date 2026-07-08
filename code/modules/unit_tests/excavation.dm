/// Tunnel intents must be present on all pick variants so players can select them.
/datum/unit_test/pick_tunnel_intents/Run()
	var/list/picks = list(
		allocate(/obj/item/weapon/pick),
		allocate(/obj/item/weapon/pick/copper),
		allocate(/obj/item/weapon/pick/steel),
		allocate(/obj/item/weapon/pick/stone),
		allocate(/obj/item/weapon/pick/drill),
	)
	for(var/obj/item/weapon/pick/P as anything in picks)
		TEST_ASSERT(PICK_TUNNEL_DOWN in P.possible_item_intents, "[P.type] is missing the tunnel-down intent.")
		TEST_ASSERT(PICK_TUNNEL_UP in P.possible_item_intents, "[P.type] is missing the tunnel-up intent.")
	var/datum/intent/down = new PICK_TUNNEL_DOWN()
	var/datum/intent/up = new PICK_TUNNEL_UP()
	TEST_ASSERT(down.no_attack, "Tunnel-down intent must be no_attack so it can't be used as a weapon intent.")
	TEST_ASSERT(up.no_attack, "Tunnel-up intent must be no_attack so it can't be used as a weapon intent.")

/// Only naturalstone and dirt floors are excavatable.
/datum/unit_test/excavatable_floor_whitelist/Run()
	var/turf/T = run_loc_floor_bottom_left
	var/old_type = T.type
	T.ChangeTurf(/turf/open/floor/naturalstone)
	T = run_loc_floor_bottom_left
	TEST_ASSERT(is_excavatable_floor(T), "Naturalstone floor should be excavatable.")
	T.ChangeTurf(/turf/open/floor/dirt)
	T = run_loc_floor_bottom_left
	TEST_ASSERT(is_excavatable_floor(T), "Dirt floor should be excavatable.")
	T.ChangeTurf(/turf/open/floor/dirt/road)
	T = run_loc_floor_bottom_left
	TEST_ASSERT(is_excavatable_floor(T), "Dirt road should be excavatable (dirt subtype).")
	T.ChangeTurf(old_type)

/// Excavation must refuse cleanly at z-boundaries instead of runtiming.
/datum/unit_test/excavation_z_boundary_refusal/Run()
	var/mob/living/carbon/human/digger = allocate(/mob/living/carbon/human)
	var/obj/item/weapon/pick/P = allocate(/obj/item/weapon/pick)
	var/turf/T = run_loc_floor_bottom_left
	var/old_type = T.type
	T.ChangeTurf(/turf/open/floor/naturalstone)
	T = run_loc_floor_bottom_left
	digger.forceMove(T)
	if(isnull(GET_TURF_BELOW(T)))
		TEST_ASSERT(!P.can_dig_down(T, digger), "can_dig_down must refuse when no turf exists below.")
	if(isnull(GET_TURF_ABOVE(T)))
		TEST_ASSERT(!P.can_dig_up(digger), "can_dig_up must refuse when no turf exists above.")
	T.ChangeTurf(old_type)

/// Floor integrity values from the spec.
/datum/unit_test/excavation_floor_integrity/Run()
	var/turf/open/floor/naturalstone/stone_path = /turf/open/floor/naturalstone
	var/turf/open/floor/dirt/dirt_path = /turf/open/floor/dirt
	TEST_ASSERT_EQUAL(initial(stone_path.max_integrity), 500, "Naturalstone floor integrity should be 500 (wall parity).")
	TEST_ASSERT_EQUAL(initial(dirt_path.max_integrity), 200, "Dirt floor integrity should be 200.")
