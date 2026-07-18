/datum/unit_test/identity_snapshot_roundtrip/Run()
	var/mob/living/carbon/human/alice = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/bob = allocate(/mob/living/carbon/human)

	alice.real_name = "Alice Snapshot Test"
	alice.gender = FEMALE
	alice.honorary = "Dame"
	alice.voice_color = "ff00ff"
	alice.set_hair_color("#ff0000", FALSE)
	alice.set_eye_color("#00ff00", "#0000ff", FALSE)

	bob.real_name = "Bob Snapshot Test"
	bob.gender = MALE
	bob.set_hair_color("#123456", FALSE)

	var/datum/identity_snapshot/bob_base = new
	bob_base.capture(bob)
	var/datum/identity_snapshot/alice_snap = new
	alice_snap.capture(alice)

	TEST_ASSERT_EQUAL(alice_snap.real_name, "Alice Snapshot Test", "capture must record real_name")
	TEST_ASSERT_EQUAL(alice_snap.hair_color, "#ff0000", "capture must record hair color")
	TEST_ASSERT_EQUAL(alice_snap.eye_color_right, "#00ff00", "capture must record right eye color")
	TEST_ASSERT_EQUAL(alice_snap.eye_color_left, "#0000ff", "capture must record left eye color")

	TEST_ASSERT(alice_snap.apply(bob), "apply must succeed on a valid human")
	TEST_ASSERT_EQUAL(bob.real_name, "Alice Snapshot Test", "apply must set real_name")
	TEST_ASSERT_EQUAL(bob.get_hair_color(), "#ff0000", "apply must set hair color")
	TEST_ASSERT_EQUAL(bob.get_eye_color(RIGHT_SIDE), "#00ff00", "apply must set right eye color")
	TEST_ASSERT_EQUAL(bob.gender, FEMALE, "apply must set gender")
	TEST_ASSERT_EQUAL(bob.honorary, "Dame", "apply must set honorary")
	TEST_ASSERT_EQUAL(bob.voice_color, "ff00ff", "apply must set voice color")

	TEST_ASSERT(bob_base.apply(bob), "restoring the base snapshot must succeed")
	TEST_ASSERT_EQUAL(bob.real_name, "Bob Snapshot Test", "restore must return real_name")
	TEST_ASSERT_EQUAL(bob.get_hair_color(), "#123456", "restore must return hair color")
	TEST_ASSERT_EQUAL(bob.gender, MALE, "restore must return gender")

	qdel(alice_snap)
	qdel(bob_base)

/datum/unit_test/identity_snapshot_independence/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	victim.real_name = "Ghost Snapshot Test"
	var/source_species_type = victim.dna.species.type

	var/datum/identity_snapshot/snap = new
	snap.capture(victim)
	qdel(victim)

	TEST_ASSERT_EQUAL(snap.real_name, "Ghost Snapshot Test", "snapshot must survive source deletion")
	TEST_ASSERT_NOTNULL(snap.dna, "snapshot DNA must survive source deletion")
	TEST_ASSERT_EQUAL(snap.dna.species.type, source_species_type, "snapshot DNA must deep-copy species")

	var/mob/living/carbon/human/receiver = allocate(/mob/living/carbon/human)
	TEST_ASSERT(snap.apply(receiver), "apply must work after the source was qdel'd")
	TEST_ASSERT_EQUAL(receiver.real_name, "Ghost Snapshot Test", "apply after source deletion must carry identity")
	qdel(snap)

/datum/unit_test/identity_snapshot_invalid_apply/Run()
	var/datum/identity_snapshot/empty_snap = new
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	var/original_name = target.real_name
	TEST_ASSERT(!empty_snap.apply(target), "apply without captured dna must fail")
	TEST_ASSERT_EQUAL(target.real_name, original_name, "failed apply must not touch the target")
	qdel(empty_snap)
