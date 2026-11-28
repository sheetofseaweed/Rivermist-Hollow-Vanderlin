/**
 * Shared anti-magic field structure behavior.
 * The structure's own turf is the visual/coverage center anchor.
 * Even-sized footprints use the conventional -half..(+half-1) tile range.
 */
/datum/looping_sound/anti_magic_field
	mid_sounds = list('sound/misc/loops/LightCrystal1.ogg')
	mid_length = 72
	volume = 35
	extra_range = 2
	falloff_distance = 2
	vary = TRUE

/obj/structure/anti_magic_field
	name = "anti-magic field generator"
	desc = "A device that suppresses unauthorized magical effects within a fixed area."
	icon = 'modular_rmh/icons/obj/structures/antimagicfield.dmi'
	icon_state = "antimagicstationary"
	SET_BASE_PIXEL(-16, -12)
	anchored = TRUE
	density = FALSE
	max_integrity = 200
	integrity_failure = 0.5
	break_sound = 'sound/combat/hits/onmetal/metalimpact (1).ogg'
	attacked_sound = list(
		'sound/combat/hits/onmetal/metalimpact (1).ogg',
		'sound/combat/hits/onmetal/metalimpact (2).ogg',
	)

	/// Width and height in tiles. The object turf is the center anchor; even footprints use -half..(+half-1).
	var/field_width = ANTI_MAGIC_FIELD_STATIONARY_WIDTH
	var/field_height = ANTI_MAGIC_FIELD_STATIONARY_HEIGHT
	/// Number of Z levels above and below the anchor. Stationary=1; throwable=0.
	var/field_z_coverage = 1
	var/is_active = FALSE
	var/is_built = TRUE
	var/waiting_for_slot = FALSE
	/// Local associative list: action identifier => TRUE (allow) / FALSE (deny).
	var/list/whitelist_overrides = list()
	var/datum/looping_sound/anti_magic_field/humming_sound

	/// Icon hooks. Set these when corresponding states exist in the DMI.
	var/icon_state_active
	var/icon_state_inactive
	var/icon_state_waiting
	var/icon_state_constructing
	var/icon_state_broken

/obj/structure/anti_magic_field/Initialize(mapload)
	. = ..()
	GLOB.anti_magic_field_manager.register_field(src)
	update_appearance(UPDATE_ICON_STATE)

/obj/structure/anti_magic_field/Destroy()
	GLOB.anti_magic_field_manager.unregister_field(src)
	QDEL_NULL(humming_sound)
	return ..()

/obj/structure/anti_magic_field/proc/covers_turf(turf/test_turf)
	if(!test_turf || !is_active)
		return FALSE
	var/turf/anchor = get_turf(src)
	if(!anchor)
		return FALSE
	if(test_turf.z < anchor.z - field_z_coverage || test_turf.z > anchor.z + field_z_coverage)
		return FALSE
	// Center the footprint on the generator instead of treating its turf as
	// the south-west corner. For even dimensions (8x8 / 4x4), the footprint
	// is necessarily asymmetric by one tile: -4..+3 for an 8-wide field.
	var/min_x = anchor.x - round(field_width / 2)
	var/min_y = anchor.y - round(field_height / 2)
	return test_turf.x >= min_x && test_turf.x < min_x + field_width \
		&& test_turf.y >= min_y && test_turf.y < min_y + field_height

/obj/structure/anti_magic_field/proc/permits_action(action_id)
	if(!istext(action_id) || !length(action_id))
		return FALSE
	if(action_id in whitelist_overrides)
		return whitelist_overrides[action_id]
	return GLOB.anti_magic_field_manager.is_globally_whitelisted(action_id)

/obj/structure/anti_magic_field/proc/activate_field(mob/user)
	if(obj_broken || !is_built)
		return FALSE
	if(GLOB.anti_magic_field_manager.activate_field(src))
		return TRUE
	if(user)
		to_chat(user, span_warning("The field remains OFF: the configured active-field limit is occupied."))
	return FALSE

/obj/structure/anti_magic_field/proc/deactivate_field()
	return GLOB.anti_magic_field_manager.deactivate_field(src)

/obj/structure/anti_magic_field/proc/on_field_activated()
	if(!humming_sound)
		humming_sound = new(src, FALSE)
	humming_sound.start()
	update_appearance(UPDATE_ICON_STATE)

/obj/structure/anti_magic_field/proc/on_field_deactivated()
	QDEL_NULL(humming_sound)
	update_appearance(UPDATE_ICON_STATE)

/obj/structure/anti_magic_field/update_icon_state()
	. = ..()
	if(obj_broken && icon_state_broken)
		icon_state = icon_state_broken
		return
	if(!is_built && icon_state_constructing)
		icon_state = icon_state_constructing
		return
	if(waiting_for_slot && icon_state_waiting)
		icon_state = icon_state_waiting
		return
	if(is_active && icon_state_active)
		icon_state = icon_state_active
		return
	if(!is_active && icon_state_inactive)
		icon_state = icon_state_inactive
		return
	icon_state = initial(icon_state)

/obj/structure/anti_magic_field/examine(mob/user)
	. = ..()
	. += span_notice("Field coverage: [field_width]x[field_height].")
	if(field_z_coverage)
		. += span_notice("Vertical coverage: [field_z_coverage] level(s) above and below the anchor.")
	if(is_active)
		. += span_notice("The anti-magic field is active.")
	else if(waiting_for_slot)
		. += span_warning("The anti-magic field is dormant and waiting for an active slot.")
	else
		. += span_warning("The anti-magic field is OFF.")
	. += span_info("Integrity: [get_integrity()]/[max_integrity].")
