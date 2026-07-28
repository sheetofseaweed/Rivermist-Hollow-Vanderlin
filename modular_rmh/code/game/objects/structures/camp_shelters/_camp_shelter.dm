GLOBAL_VAR_INIT(camp_shelter_counter, 0)

/proc/generate_camp_shelter_id()
	return "[world.time]_[rand(1, 999999)]_[GLOB.camp_shelter_counter++]"

/// Both forms of a shelter resolve the same pocket instance from this key.
/proc/get_camp_shelter_key(shelter_id)
	return "camp_shelter::[shelter_id]"

/obj/item/camp_shelter
	name = "shelter kit"
	desc = "A bundle of canvas, cord and poles."
	icon = 'icons/roguetown/misc/structure.dmi'
	icon_state = "tent_kit"
	w_class = WEIGHT_CLASS_BULKY
	grid_width = 32
	grid_height = 96
	item_weight = 8 KILOGRAMS
	/// Stable identity shared with the deployed form. Survives every fold/deploy cycle.
	var/shelter_id
	var/color_base_primary = "#c8b48c"
	var/color_base_secondary = "#8c4b3c"
	var/color_flag_primary = "#8c4b3c"
	var/color_flag_secondary = "#c8b48c"
	/// The structure this pitches into.
	var/obj/structure/camp_shelter/deployed_type
	/// Whether the recolour menu offers the two flag layers.
	var/has_flag_layers = FALSE
	var/deploy_time = 5 SECONDS
	/// Set while handing off to the other form, so Destroy() leaves the pocket alone.
	var/transferring = FALSE

/obj/item/camp_shelter/Initialize(mapload, atom/source)
	. = ..()
	if(source)
		copy_camp_shelter_state(source, src)
	if(!shelter_id)
		shelter_id = generate_camp_shelter_id()
	update_appearance()

/obj/item/camp_shelter/Destroy(force)
	// A fold/deploy handoff qdels the old form on purpose; the pocket must outlive it.
	if(!transferring && SSpocket_dimensions)
		SSpocket_dimensions.delete_instance(
			get_pocket_instance_key(),
			"The shelter's folded space comes apart and throws you back out!",
			get_turf(src),
		)
	return ..()

/obj/item/camp_shelter/proc/get_pocket_instance_key()
	return get_camp_shelter_key(shelter_id)

/obj/item/camp_shelter/update_icon_state()
	. = ..()
	color = color_base_primary

/// The four turfs a deployed shelter covers, anchored bottom-left to match the 64x64 art.
/proc/get_camp_shelter_footprint(turf/anchor)
	if(!anchor)
		return null

	var/list/turf/footprint = list()
	for(var/offset_x in 0 to 1)
		for(var/offset_y in 0 to 1)
			var/turf/covered = locate(anchor.x + offset_x, anchor.y + offset_y, anchor.z)
			if(!covered)
				return null
			footprint += covered

	return footprint

/// A pitched shelter covers 2x2 from its own turf, so one anchored outside this
/// footprint can still overlap it. Anchor-only checks miss that.
/proc/get_overlapping_camp_shelter(list/turf/footprint)
	if(!length(footprint))
		return null

	for(var/turf/covered as anything in footprint)
		for(var/obj/structure/camp_shelter/neighbour in range(1, covered))
			var/list/turf/neighbour_footprint = get_camp_shelter_footprint(get_turf(neighbour))
			if(covered in neighbour_footprint)
				return covered

	return null

/obj/item/camp_shelter/proc/get_footprint_blocker(turf/anchor)
	var/list/turf/footprint = get_camp_shelter_footprint(anchor)
	if(!footprint)
		return anchor

	for(var/turf/covered as anything in footprint)
		if(covered.density)
			return covered
		for(var/obj/blocker in covered)
			if(blocker.density)
				return covered

	return get_overlapping_camp_shelter(footprint)

/obj/item/camp_shelter/proc/footprint_is_clear(turf/anchor)
	return !get_footprint_blocker(anchor)

/obj/item/camp_shelter/proc/try_deploy(mob/user)
	var/turf/anchor = get_turf(user)
	if(!anchor)
		return FALSE

	var/turf/blocker = get_footprint_blocker(anchor)
	if(blocker)
		to_chat(user, span_warning("There isn't enough clear ground here to pitch [src]."))
		return FALSE

	user.visible_message(
		span_notice("[user] starts pitching [src]."),
		span_notice("I start pitching [src]."),
	)
	if(!do_after(user, deploy_time, src))
		return FALSE
	if(QDELETED(src) || QDELETED(user))
		return FALSE

	anchor = get_turf(user)
	if(!anchor || get_footprint_blocker(anchor))
		to_chat(user, span_warning("There isn't enough clear ground here to pitch [src]."))
		return FALSE

	if(loc == user && !user.dropItemToGround(src, TRUE, TRUE))
		to_chat(user, span_warning("I need to put [src] down before pitching it."))
		return FALSE

	var/deploy_dir = user.dir
	transferring = TRUE
	var/obj/structure/camp_shelter/pitched = new deployed_type(anchor, src)
	pitched.setDir(deploy_dir)
	pitched.apply_roof()
	user.visible_message(
		span_notice("[user] pitches [pitched]."),
		span_notice("I pitch [pitched]."),
	)
	qdel(src)
	return TRUE

/obj/item/camp_shelter/proc/recolour(mob/user)
	var/new_base_primary = input(user, "Choose the primary colour:", "Shelter Colours", color_base_primary) as color|null
	if(new_base_primary)
		color_base_primary = new_base_primary

	var/new_base_secondary = input(user, "Choose the secondary colour:", "Shelter Colours", color_base_secondary) as color|null
	if(new_base_secondary)
		color_base_secondary = new_base_secondary

	if(has_flag_layers)
		var/new_flag_primary = input(user, "Choose the primary pennant colour:", "Shelter Colours", color_flag_primary) as color|null
		if(new_flag_primary)
			color_flag_primary = new_flag_primary

		var/new_flag_secondary = input(user, "Choose the secondary pennant colour:", "Shelter Colours", color_flag_secondary) as color|null
		if(new_flag_secondary)
			color_flag_secondary = new_flag_secondary

	update_appearance()
	return TRUE

/obj/item/camp_shelter/proc/show_kit_menu(mob/user)
	switch(tgui_alert(user, "What do you want to do with [src]?", "Shelter", list("Pitch", "Recolour", "Cancel")))
		if("Pitch")
			return try_deploy(user)
		if("Recolour")
			return recolour(user)
	return FALSE

/obj/item/camp_shelter/attack_self(mob/user, list/modifiers)
	INVOKE_ASYNC(src, PROC_REF(show_kit_menu), user)
	return TRUE

/obj/item/camp_shelter/examine(mob/user)
	. = ..()
	. += span_notice("Use it to pitch it on clear ground, or to recolour its cloth.")
	. += span_notice("It needs a clear two-by-two patch to stand.")

/obj/structure/camp_shelter
	name = "shelter"
	desc = "A pitched shelter."
	icon = 'modular_rmh/icons/obj/structures/camp_shelters.dmi'
	icon_state = "tent_basic"
	density = TRUE
	anchored = TRUE
	weatherproof = TRUE
	bound_width = 64
	bound_height = 64
	max_integrity = 200
	blade_dulling = DULLING_BASHCHOP
	resistance_flags = FLAMMABLE
	destroy_sound = 'sound/combat/hits/onwood/destroyfurniture.ogg'
	attacked_sound = list('sound/combat/hits/onwood/woodimpact (1).ogg', 'sound/combat/hits/onwood/woodimpact (2).ogg')
	var/shelter_id
	var/color_base_primary = "#c8b48c"
	var/color_base_secondary = "#8c4b3c"
	var/color_flag_primary = "#8c4b3c"
	var/color_flag_secondary = "#c8b48c"
	/// The item this packs back into.
	var/obj/item/camp_shelter/folded_type
	/// Icon state prefix in camp_shelters.dmi: "tent", "yurt" or "pavilion".
	var/sprite_prefix = "tent"
	var/has_flag_layers = FALSE
	var/fold_time = 4 SECONDS
	var/enter_time = 1 SECONDS
	/// Pocket interior loaded by this shelter.
	var/pocket_template_type = /datum/map_template/pocket/camp_tent
	var/transferring = FALSE
	/// Turfs this shelter is currently roofing. Cleared on fold or destruction.
	var/list/turf/roofed_turfs

/obj/structure/camp_shelter/Initialize(mapload, atom/source)
	. = ..()
	roofed_turfs = list()
	// State must land before the component reads its instance key, so this cannot move
	// after AddComponent.
	if(source)
		copy_camp_shelter_state(source, src)
	if(!shelter_id)
		shelter_id = generate_camp_shelter_id()

	AddComponent(/datum/component/pocket_access, \
		pocket_template_type, \
		POCKET_ACCESS_INSTANCE_CUSTOM, \
		POCKET_LIFECYCLE_HIBERNATE, \
		5 MINUTES, \
		get_pocket_instance_key(), \
		FALSE, \
		FALSE, \
		FALSE, \
		"Shelter", \
		"You lift the flap. Step inside?", \
		null, \
		"The shelter comes apart and folded space throws you back out!")

	update_appearance()

/obj/structure/camp_shelter/Destroy(force)
	clear_roof()
	roofed_turfs = null
	if(!transferring && SSpocket_dimensions)
		SSpocket_dimensions.delete_instance(
			get_pocket_instance_key(),
			"The shelter collapses and throws you back out!",
			get_turf(src),
		)
	return ..()

/obj/structure/camp_shelter/proc/get_pocket_instance_key()
	return get_camp_shelter_key(shelter_id)

/obj/structure/camp_shelter/proc/get_pocket_instance()
	return SSpocket_dimensions?.get_instance(get_pocket_instance_key())

/obj/structure/camp_shelter/update_overlays()
	. = ..()
	. += mutable_appearance(icon, "[sprite_prefix]_overlay_primary", color = color_base_primary)
	. += mutable_appearance(icon, "[sprite_prefix]_overlay_secondary", color = color_base_secondary)
	. += mutable_appearance(icon, "[sprite_prefix]_overlay")
	if(!has_flag_layers)
		return
	. += mutable_appearance(icon, "[sprite_prefix]_flag_primary", color = color_flag_primary)
	. += mutable_appearance(icon, "[sprite_prefix]_flag_secondary", color = color_flag_secondary)

/// Marks the covered turfs weatherproof. pseudo_roof is typed as a turf and
/// reassess_stack() discards anything that is not a path, so this must store a path.
/obj/structure/camp_shelter/proc/apply_roof()
	clear_roof()

	var/list/turf/footprint = get_camp_shelter_footprint(get_turf(src))
	if(!footprint)
		return

	for(var/turf/covered as anything in footprint)
		covered.pseudo_roof = /turf/closed/wall/mineral/tent
		roofed_turfs += covered
		covered.reassess_stack()

/obj/structure/camp_shelter/proc/clear_roof()
	for(var/turf/covered as anything in roofed_turfs)
		if(QDELETED(covered))
			continue
		covered.pseudo_roof = null
		covered.reassess_stack()

	roofed_turfs = list()

/obj/structure/camp_shelter/proc/can_fold()
	var/datum/pocket_dimension/instance = get_pocket_instance()
	if(!instance)
		return TRUE
	return !instance.has_occupants()

/// Hibernates the pocket and swaps this structure back into its folded kit.
/// Returns the new item, or null if the shelter could not be packed up.
/obj/structure/camp_shelter/proc/fold_into_item()
	if(!can_fold())
		return null

	var/turf/anchor = get_turf(src)
	if(!anchor)
		return null

	var/datum/pocket_dimension/instance = get_pocket_instance()
	if(instance && !instance.hibernate())
		return null

	clear_roof()
	transferring = TRUE
	var/obj/item/camp_shelter/packed = new folded_type(anchor, src)
	qdel(src)
	return packed

/obj/structure/camp_shelter/proc/try_fold(mob/user)
	if(!can_fold())
		to_chat(user, span_warning("Someone is still inside [src]."))
		return FALSE

	if(tgui_alert(user, "Pack up [src]?", "Shelter", list("Fold", "Cancel")) != "Fold")
		return FALSE
	if(QDELETED(src) || QDELETED(user))
		return FALSE

	user.visible_message(
		span_notice("[user] starts packing up [src]."),
		span_notice("I start packing up [src]."),
	)
	if(!do_after(user, fold_time, src))
		return FALSE
	if(QDELETED(src) || QDELETED(user))
		return FALSE
	if(!Adjacent(user))
		to_chat(user, span_warning("I need to stay close to [src] to pack it up."))
		return FALSE

	var/obj/item/camp_shelter/packed = fold_into_item()
	if(!packed)
		to_chat(user, span_warning("Someone is still inside."))
		return FALSE

	user.visible_message(
		span_notice("[user] packs up [packed]."),
		span_notice("I pack up [packed]."),
	)
	return TRUE

/obj/structure/camp_shelter/proc/try_enter(mob/user)
	var/datum/component/pocket_access/access = GetComponent(/datum/component/pocket_access)
	if(!access)
		return FALSE

	user.visible_message(
		span_notice("[user] lifts the flap of [src]."),
		span_notice("I lift the flap of [src]."),
	)
	if(!do_after(user, enter_time, src))
		return FALSE
	if(QDELETED(src) || QDELETED(user))
		return FALSE
	if(!Adjacent(user))
		to_chat(user, span_warning("I need to stay close to [src] to get inside."))
		return FALSE

	// Announce from the shelter, not the user: by the time they are inside they are no
	// longer in view of anyone stood outside.
	visible_message(span_notice("[user] disappears inside [src]."))
	if(!access.enter_user(user))
		return FALSE

	to_chat(user, span_notice("I duck inside [src]."))
	return TRUE

// Bypasses the pocket_access component's own COMSIG_ATOM_ATTACK_HAND handler, which
// would move the user instantly. Deliberately does not call parent, since that is what
// sends the signal.
/obj/structure/camp_shelter/attack_hand(mob/user, list/modifiers)
	add_fingerprint(user)
	INVOKE_ASYNC(src, PROC_REF(try_enter), user)
	return TRUE

/obj/structure/camp_shelter/attack_paw(mob/user)
	INVOKE_ASYNC(src, PROC_REF(try_enter), user)
	return TRUE

/obj/structure/camp_shelter/attack_hand_secondary(mob/user, list/modifiers)
	INVOKE_ASYNC(src, PROC_REF(try_fold), user)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/structure/camp_shelter/examine(mob/user)
	. = ..()
	. += span_notice("Right-click to pack it up. It won't fold while anyone is inside.")

/// Moves identity and colours between the two forms. Both carry the same var names,
/// so one proc covers item to structure and structure to item.
/proc/copy_camp_shelter_state(atom/source, atom/target)
	if(!source || !target)
		return FALSE

	var/list/state = list()
	if(istype(source, /obj/item/camp_shelter))
		var/obj/item/camp_shelter/folded = source
		state = list(folded.shelter_id, folded.color_base_primary, folded.color_base_secondary, folded.color_flag_primary, folded.color_flag_secondary)
	else if(istype(source, /obj/structure/camp_shelter))
		var/obj/structure/camp_shelter/deployed = source
		state = list(deployed.shelter_id, deployed.color_base_primary, deployed.color_base_secondary, deployed.color_flag_primary, deployed.color_flag_secondary)
	else
		return FALSE

	if(istype(target, /obj/item/camp_shelter))
		var/obj/item/camp_shelter/folded = target
		folded.shelter_id = state[1]
		folded.color_base_primary = state[2]
		folded.color_base_secondary = state[3]
		folded.color_flag_primary = state[4]
		folded.color_flag_secondary = state[5]
		return TRUE

	if(istype(target, /obj/structure/camp_shelter))
		var/obj/structure/camp_shelter/deployed = target
		deployed.shelter_id = state[1]
		deployed.color_base_primary = state[2]
		deployed.color_base_secondary = state[3]
		deployed.color_flag_primary = state[4]
		deployed.color_flag_secondary = state[5]
		return TRUE

	return FALSE
