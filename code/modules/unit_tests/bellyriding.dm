/datum/unit_test/bellyriding_penetrative_actions_route_internal_climax/Run()
	var/datum/sex_action/bellyriding/anal/anal_action = new
	var/datum/sex_action/bellyriding/vaginal/vaginal_action = new

	TEST_ASSERT_EQUAL(anal_action.hole_id, ORGAN_SLOT_ANUS, "Anal bellyriding should target the victim's anus for climax transfer.")
	TEST_ASSERT_EQUAL(vaginal_action.hole_id, ORGAN_SLOT_VAGINA, "Vaginal bellyriding should target the victim's vagina for climax transfer.")
	TEST_ASSERT_EQUAL(anal_action.handle_climax_message(null, null, FALSE), ORGASM_LOCATION_INTO, "Anal bellyriding should deposit into the target when the harness wearer climaxes.")
	TEST_ASSERT_EQUAL(vaginal_action.handle_climax_message(null, null, FALSE), ORGASM_LOCATION_INTO, "Vaginal bellyriding should deposit into the target when the harness wearer climaxes.")

	qdel(anal_action)
	qdel(vaginal_action)

/// Records which landed hits reach it, without applying damage.
/mob/living/carbon/human/bellyriding_shield_dummy
	var/list/hits_taken = list()

/mob/living/carbon/human/bellyriding_shield_dummy/attacked_by(obj/item/I, mob/living/user)
	hits_taken += "melee"
	return TRUE

/mob/living/carbon/human/bellyriding_shield_dummy/hitby(atom/movable/AM, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum, damage_type)
	hits_taken += "thrown"
	return TRUE

/// Harmless projectile that records every mob it lands on.
/obj/projectile/bellyriding_shield_probe
	nodamage = TRUE
	damage = 0
	dodgeable = FALSE
	var/list/hit_mobs = list()

/obj/projectile/bellyriding_shield_probe/on_hit(atom/target, blocked = FALSE, pierce_hit)
	hit_mobs += target
	return ..()

/datum/unit_test/bellyriding_shield
	abstract_type = /datum/unit_test/bellyriding_shield
	var/turf/center
	var/mob/living/carbon/human/wearer
	var/mob/living/carbon/human/victim
	var/datum/component/bellyriding/harness

/// Straps a restrained victim to a north-facing wearer one tile in from the corner.
/datum/unit_test/bellyriding_shield/proc/strap(victim_type = /mob/living/carbon/human, taur_type)
	center = locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y + 1, run_loc_floor_bottom_left.z)
	wearer = allocate(/mob/living/carbon/human, center)
	victim = allocate(victim_type, center)
	if(taur_type)
		var/obj/item/bodypart/taur/taur = allocate(taur_type)
		taur.taur_color = COLOR_WHITE
		taur.taur_markings = COLOR_WHITE
		taur.taur_tertiary = COLOR_WHITE
		taur.attach_limb(wearer, TRUE)
	wearer.setDir(NORTH)
	ADD_TRAIT(victim, TRAIT_RESTRAINED, TRAIT_GENERIC)
	harness = wearer.AddComponent(/datum/component/bellyriding, wearer)
	harness.store_old_state(victim)
	return harness.strap_victim(victim)

/datum/unit_test/bellyriding_shield/front_arc/Run()
	TEST_ASSERT(strap(), "Could not strap the victim to the harness.")
	TEST_ASSERT_EQUAL(victim.buckled, wearer, "The victim was not buckled to the wearer.")

	for(var/direction in list(NORTH, NORTHEAST, NORTHWEST))
		TEST_ASSERT_EQUAL(harness.get_shield(get_step(center, direction), BODY_ZONE_CHEST), victim, "A hit from [dir2text(direction)] of a north-facing wearer should land on the victim.")
	for(var/direction in list(EAST, WEST, SOUTH, SOUTHEAST, SOUTHWEST))
		TEST_ASSERT_NULL(harness.get_shield(get_step(center, direction), BODY_ZONE_CHEST), "A hit from [dir2text(direction)] of a north-facing wearer should land on the wearer.")
	TEST_ASSERT_NULL(harness.get_shield(center, BODY_ZONE_CHEST), "A hit from the wearer's own tile has no side and should land on the wearer.")
	TEST_ASSERT_NULL(harness.get_shield(wearer, BODY_ZONE_CHEST), "The wearer's own hits should never land on the victim.")

	// get_dir() calls this tile NORTHEAST, but the shot comes almost from the east.
	var/turf/east_shot = locate(center.x + 3, center.y + 1, center.z)
	TEST_ASSERT_NULL(harness.get_shield(east_shot, BODY_ZONE_CHEST), "A ranged hit from the side should land on the wearer.")
	var/turf/front_shot = locate(center.x + 1, center.y + 3, center.z)
	TEST_ASSERT_EQUAL(harness.get_shield(front_shot, BODY_ZONE_CHEST), victim, "A ranged hit from the front should land on the victim.")

	wearer.setDir(EAST)
	TEST_ASSERT_EQUAL(harness.get_shield(get_step(center, EAST), BODY_ZONE_CHEST), victim, "The front arc should turn with the wearer.")
	TEST_ASSERT_NULL(harness.get_shield(get_step(center, NORTH), BODY_ZONE_CHEST), "The old front should be open after the wearer turns.")

/datum/unit_test/bellyriding_shield/zones/Run()
	TEST_ASSERT(strap(), "Could not strap the victim to the harness.")
	var/turf/front = get_step(center, NORTH)
	for(var/zone in list(BODY_ZONE_CHEST, BODY_ZONE_PRECISE_STOMACH, BODY_ZONE_PRECISE_GROIN, BODY_ZONE_L_LEG, BODY_ZONE_PRECISE_R_FOOT))
		TEST_ASSERT_EQUAL(harness.get_shield(front, zone), victim, "The victim should cover the wearer's [zone].")
	for(var/zone in list(BODY_ZONE_HEAD, BODY_ZONE_PRECISE_NECK, BODY_ZONE_PRECISE_MOUTH, BODY_ZONE_L_ARM, BODY_ZONE_PRECISE_R_HAND))
		TEST_ASSERT_NULL(harness.get_shield(front, zone), "The wearer's [zone] should stay open above or beside the victim.")

/datum/unit_test/bellyriding_shield/needs_live_strapped_victim/Run()
	TEST_ASSERT(strap(), "Could not strap the victim to the harness.")
	var/turf/front = get_step(center, NORTH)
	TEST_ASSERT_EQUAL(harness.get_shield(front, BODY_ZONE_CHEST), victim, "A live strapped victim should shield the wearer.")

	victim.death()
	TEST_ASSERT_EQUAL(victim.buckled, wearer, "Death should not unbuckle the victim, or this test checks nothing.")
	TEST_ASSERT_NULL(harness.get_shield(front, BODY_ZONE_CHEST), "A dead victim should stop shielding the wearer.")

	harness.unbuckle_victim()
	TEST_ASSERT_NULL(harness.get_shield(front, BODY_ZONE_CHEST), "An unstrapped victim should not shield the wearer.")

/datum/unit_test/bellyriding_shield/routes_hits/Run()
	TEST_ASSERT(strap(/mob/living/carbon/human/bellyriding_shield_dummy), "Could not strap the victim to the harness.")
	var/mob/living/carbon/human/bellyriding_shield_dummy/dummy = victim
	var/turf/front = get_step(center, NORTH)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human, front)
	attacker.zone_selected = BODY_ZONE_CHEST

	var/obj/item/weapon/sword/sabre/sabre = allocate(/obj/item/weapon/sword/sabre)
	TEST_ASSERT(wearer.attacked_by(sabre, attacker), "A shielded melee hit should report that it landed.")
	TEST_ASSERT_EQUAL(dummy.hits_taken.Join(","), "melee", "A melee hit from the front should land on the victim.")

	var/obj/item/natural/stone/stone = allocate(/obj/item/natural/stone, front)
	var/datum/thrownthing/throw_data = allocate(/datum/thrownthing, stone, wearer, SOUTH, 5, 1, attacker, FALSE, MOVE_FORCE_DEFAULT, FALSE, null, BODY_ZONE_CHEST)
	wearer.hitby(stone, FALSE, TRUE, FALSE, throw_data)
	TEST_ASSERT_EQUAL(dummy.hits_taken.Join(","), "melee,thrown", "A throw from the front should land on the victim.")

/datum/unit_test/bellyriding_shield/projectiles/Run()
	TEST_ASSERT(strap(), "Could not strap the victim to the harness.")
	var/obj/projectile/bellyriding_shield_probe/front_shot = allocate(/obj/projectile/bellyriding_shield_probe)
	front_shot.starting = locate(center.x, center.y + 3, center.z)
	wearer.bullet_act(front_shot, BODY_ZONE_CHEST)
	TEST_ASSERT_EQUAL(front_shot.hit_mobs.len, 1, "A shot from the front should land on exactly one mob.")
	TEST_ASSERT_EQUAL(front_shot.hit_mobs[1], victim, "A shot from the front should land on the victim.")

	var/obj/projectile/bellyriding_shield_probe/back_shot = allocate(/obj/projectile/bellyriding_shield_probe)
	back_shot.starting = locate(center.x, center.y - 1, center.z)
	wearer.bullet_act(back_shot, BODY_ZONE_CHEST)
	TEST_ASSERT_EQUAL(back_shot.hit_mobs.len, 1, "A shot from behind should land on exactly one mob.")
	TEST_ASSERT_EQUAL(back_shot.hit_mobs[1], wearer, "A shot from behind should land on the wearer.")

/datum/unit_test/bellyriding_shield/taur_flanks/Run()
	TEST_ASSERT(strap(taur_type = /obj/item/bodypart/taur/otie), "Could not strap the victim to the taur harness.")
	TEST_ASSERT(HAS_TRAIT(wearer, TRAIT_PONYGIRL_RIDEABLE), "Taurs lost their mount trait, so the loop case is not covered.")
	for(var/direction in list(EAST, WEST))
		TEST_ASSERT_EQUAL(harness.get_shield(get_step(center, direction), BODY_ZONE_CHEST), victim, "A taur's victim should cover the [dir2text(direction)] flank.")
	for(var/direction in list(NORTH, SOUTH, NORTHEAST, SOUTHWEST))
		TEST_ASSERT_NULL(harness.get_shield(get_step(center, direction), BODY_ZONE_CHEST), "A taur's victim should not cover [dir2text(direction)].")

	TEST_ASSERT_NULL(victim.get_pony_mount(), "A strapped victim is not a rider; the mount redirect would loop with the shield.")
	var/obj/projectile/bellyriding_shield_probe/flank_shot = allocate(/obj/projectile/bellyriding_shield_probe)
	flank_shot.starting = locate(center.x + 3, center.y, center.z)
	wearer.bullet_act(flank_shot, BODY_ZONE_CHEST)
	TEST_ASSERT_EQUAL(flank_shot.hit_mobs.len, 1, "A flank shot on a taur should land on exactly one mob.")
	TEST_ASSERT_EQUAL(flank_shot.hit_mobs[1], victim, "A flank shot on a taur should land on the victim.")

/datum/unit_test/bellyriding_shield_keeps_pony_redirect/Run()
	var/mob/living/carbon/human/carrier = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/rider = allocate(/mob/living/carbon/human)
	ADD_TRAIT(carrier, TRAIT_PONYGIRL_RIDEABLE, TRAIT_GENERIC)
	TEST_ASSERT(carrier.buckle_mob(rider), "Could not mount the pony carrier.")
	TEST_ASSERT_EQUAL(rider.get_pony_mount(), carrier, "A normal rider should still pass hits to the mount.")
