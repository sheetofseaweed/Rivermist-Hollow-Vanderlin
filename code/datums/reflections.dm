/*
 * Reflections.
 *
 * One gate, one appearance, two ways of drawing the result. Whether something casts a reflection is
 * answered in exactly one place - casts_reflection() - and both backends ask that and nothing else.
 *
 * REFLECTION_BACKEND_STENCIL: the subject carries a flipped copy of itself on REFLECTION_PLANE, and
 * reflective surfaces punch a hole for it with a REFLECTIVE_DISPLACEMENT_PLANE mask. Costs a surface
 * nothing at all - the subject pays for its own copy - which is why every water tile on the map can
 * afford it. Entry point is make_shiny() below.
 *
 * REFLECTION_BACKEND_OBJECT: the surface tracks the movables near it and owns a real reflection atom
 * per subject, so the reflection is a thing you can address, transform and eventually walk into. Costs
 * a component plus an object per pair, so it only suits a handful of surfaces. See
 * /datum/component/reflection, worn by mirrors.
 *
 * A stencil surface can be promoted to the object backend by giving it the component instead; the gate
 * and the subject-side appearance are shared either way.
 */

/// Whether this movable casts a reflection at all. Inanimate things never do.
/atom/movable/proc/casts_reflection()
	return FALSE

/mob/living/casts_reflection()
	return has_reflection && !HAS_TRAIT(src, TRAIT_NO_REFLECTION)

/// The flipped copy the stencil backend hangs under the subject.
/mob/living/proc/build_reflection_appearance()
	// Never changes, and rebuilding it per appearance update used to flip an icon on every mob's every update.
	var/static/icon/stencil_mask
	if(!stencil_mask)
		stencil_mask = icon('icons/turf/overlays.dmi', "whiteOverlay")
		stencil_mask.Flip(NORTH)

	var/mutable_appearance/reflection = copy_appearance_filter_overlays(appearance)
	if(render_target)
		reflection.render_source = render_target
	reflection.plane = REFLECTION_PLANE
	reflection.pixel_y = -32
	// Mirror our own transform rather than replacing it, or a mob lying down stands up in the water.
	// Negating the matrix' y row flips the finished sprite, so this is identical to Scale(1, -1) when we're upright.
	var/matrix/upright = matrix(transform)
	reflection.transform = matrix(upright.a, upright.b, upright.c, -upright.d, -upright.e, -upright.f)
	reflection.vis_flags = VIS_INHERIT_DIR
	reflection.filters += filter(type = "alpha", icon = stencil_mask)
	return reflection

/**
 * The stencil backend's flipped copy of the subject, hung in its vis_contents.
 *
 * A child atom rather than an overlay, and that distinction is load-bearing. An overlay pinned to a foreign
 * plane gets hoisted out of the render group that an openspace hole blurs and dims, so viewed from a level up
 * the reflection stayed sharp and bright while the mob casting it went soft and dark. A child atom rasterises
 * with its parent and picks up that treatment for free.
 */
/obj/effect/overlay/reflection
	name = ""
	icon_state = "nothing"
	plane = REFLECTION_PLANE
	// We are handed a finished copy of the subject's appearance, so don't let the subject's own colour,
	// transparency and rotation apply a second time on top of it.
	appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	blocks_emissive = NONE

/// Recalculates our reflection for both backends. Safe to call whenever anything about us changes.
/mob/living/proc/update_reflection()
	// Our Destroy clears the reflection early, then keeps working - and plenty of that work ends in
	// update_appearance(). Without this we would build a fresh reflection atom on the way out, lose it from
	// vis_contents when the parent cuts that list, and leave nothing alive to ever delete it.
	if(QDELETED(src))
		return
	if(!casts_reflection())
		clear_reflection()
		// Object-backend surfaces hold their own copy of us, so one call has to reach them too.
		SEND_SIGNAL(src, COMSIG_LIVING_REFLECTION_CHANGED)
		return

	if(!reflective_icon)
		reflective_icon = new
		vis_contents += reflective_icon
	reflective_icon.appearance = build_reflection_appearance()
	// Assigning an appearance can carry these along, so set them afterwards rather than trusting what arrived.
	// VIS_INHERIT_DIR keeps the reflection facing where we face without needing a rebuild every time we turn.
	reflective_icon.appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM
	reflective_icon.vis_flags = VIS_INHERIT_DIR
	SEND_SIGNAL(src, COMSIG_LIVING_REFLECTION_CHANGED)

/// Drops the reflection atom. Nothing else holds it, so we own deleting it.
/mob/living/proc/clear_reflection()
	if(!reflective_icon)
		return
	vis_contents -= reflective_icon
	QDEL_NULL(reflective_icon)

/mob/living/proc/on_reflection_dirtied(datum/source)
	SIGNAL_HANDLER
	update_reflection()

/// Marks a surface as one the stencil backend should show reflections on.
/atom/proc/make_shiny(_shine = SHINE_REFLECTIVE)
	if(total_reflection_mask)
		if(shine != _shine)
			cut_overlay(total_reflection_mask)
		else
			return
	total_reflection_mask = mutable_appearance('icons/turf/overlays.dmi', "whiteFull", plane = REFLECTIVE_DISPLACEMENT_PLANE)
	add_overlay(total_reflection_mask)
	shine = _shine

/atom/proc/make_unshiny()
	cut_overlay(total_reflection_mask)
	shine = SHINE_MATTE
