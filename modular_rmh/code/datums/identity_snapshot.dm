/**
 * A portable copy of a human's visible identity: everything another player can
 * see or hear that says "this is who I am". Capture from a live human, apply to
 * any human, keep as long as needed — holds no references to the source mob.
 *
 * Foundation for changeling-style disguises (succubus camouflage); the vampire
 * Mask of a Thousand Faces predates this and can be retrofitted onto it.
 * apply() works on any fully populated snapshot, captured or hand-built.
 */
/datum/identity_snapshot
	/// Deep copy of the source's DNA (species, features, markings, blood, name) — never a live reference
	var/datum/dna/dna
	var/real_name
	var/gender
	var/age
	var/voice_type
	var/voice_color
	var/honorary
	var/honorary_suffix
	/// Sprite accessory typepaths, as used by set_hair_style()/set_facial_hair_style()
	var/hair_style_type
	var/facial_hair_style_type
	var/hair_color
	var/facial_hair_color
	var/eye_color_right
	var/eye_color_left

/datum/identity_snapshot/Destroy()
	QDEL_NULL(dna)
	return ..()

/// Fills this snapshot from a live human. Returns src for chaining.
/datum/identity_snapshot/proc/capture(mob/living/carbon/human/source)
	if(!istype(source) || !source.dna)
		return
	QDEL_NULL(dna)
	dna = new
	source.dna.copy_dna(dna)
	real_name = source.real_name
	gender = source.gender
	age = source.age
	voice_type = source.voice_type
	voice_color = source.voice_color
	honorary = source.honorary
	honorary_suffix = source.honorary_suffix
	var/datum/bodypart_feature/hair/head_feature = source.get_bodypart_feature_of_slot(BODYPART_FEATURE_HAIR)
	var/datum/bodypart_feature/hair/facial_feature = source.get_bodypart_feature_of_slot(BODYPART_FEATURE_FACIAL_HAIR)
	hair_style_type = head_feature?.accessory_type
	facial_hair_style_type = facial_feature?.accessory_type
	hair_color = source.get_hair_color()
	facial_hair_color = source.get_facial_hair_color()
	eye_color_right = source.get_eye_color(RIGHT_SIDE)
	eye_color_left = source.get_eye_color(LEFT_SIDE)
	return src

/// Applies this snapshot to a live human's current body. Returns TRUE on success.
/datum/identity_snapshot/proc/apply(mob/living/carbon/human/target)
	if(!istype(target) || !target.dna || !dna)
		return FALSE
	dna.transfer_identity(target)
	target.real_name = real_name
	target.age = age
	target.voice_type = voice_type
	target.voice_color = voice_color
	target.honorary = honorary
	target.honorary_suffix = honorary_suffix
	target.set_hair_color(hair_color, FALSE)
	target.set_hair_style(hair_style_type, FALSE)
	target.set_facial_hair_color(facial_hair_color, FALSE)
	target.set_facial_hair_style(facial_hair_style_type, FALSE)
	target.set_eye_color(eye_color_right, eye_color_left, FALSE)
	// updateappearance() re-derives .gender from dna.unique_identity's encoded gender block,
	// clobbering any earlier assignment — so gender must be (re)applied after it, not before.
	target.updateappearance(mutcolor_update = TRUE)
	target.gender = gender
	target.name = target.get_visible_name()
	return TRUE
