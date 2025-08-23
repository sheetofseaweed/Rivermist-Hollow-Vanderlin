/obj/item/organ/penis
	name = "penis"
	icon_state = "severedtail" //placeholder
	visible_organ = TRUE
	zone = BODY_ZONE_PRECISE_GROIN
	slot = ORGAN_SLOT_PENIS

	var/sheath_type = SHEATH_TYPE_NONE
	var/erect_state = ERECT_STATE_NONE
	var/penis_type = PENIS_TYPE_PLAIN
	var/penis_size = DEFAULT_PENIS_SIZE
	var/functional = TRUE

/obj/item/organ/penis/Initialize()
	. = ..()

/obj/item/organ/penis/proc/update_erect_state()
	var/oldstate = erect_state
	var/new_state = ERECT_STATE_NONE

	erect_state = new_state
	if(oldstate != erect_state && owner)
		owner.update_body_parts(TRUE)


/obj/item/organ/penis/proc/create_fake_variant(mob/living/carbon/human/user)
	var/obj/item/penis_fake/fake = new()
	fake.copy_properties_from(src)
	fake.set_original_owner(user)
	return fake

/obj/item/penis_fake
	name = "penis"
	icon_state = "severedtail" //placeholder
	var/sheath_type = SHEATH_TYPE_NONE
	var/erect_state = ERECT_STATE_NONE
	var/penis_type = PENIS_TYPE_PLAIN
	var/penis_size = DEFAULT_PENIS_SIZE
	// Tracking vars
	var/original_owner_ckey = null
	var/original_owner_name = null
	var/insertion_timestamp = null

/obj/item/penis_fake/Initialize()
	. = ..()
	insertion_timestamp = world.time

/obj/item/penis_fake/proc/copy_properties_from(obj/item/organ/penis/source)
	if(!source)
		return
	sheath_type = source.sheath_type
	erect_state = source.erect_state
	penis_type = source.penis_type
	penis_size = source.penis_size
	grid_height = 32 * penis_size
	name = "[source.name]"

/obj/item/penis_fake/proc/set_original_owner(mob/living/carbon/human/owner)
	if(owner?.ckey)
		original_owner_ckey = owner.ckey
		original_owner_name = owner.real_name || owner.name

/obj/item/penis_fake/proc/is_owned_by(mob/living/carbon/human/user)
	if(!user?.ckey)
		return FALSE
	return user.ckey == original_owner_ckey
