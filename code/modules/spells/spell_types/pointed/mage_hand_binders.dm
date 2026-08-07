/**
 * Conjured bindings for Mage Hand.
 *
 * With a tether already on someone, shift-clicking them aims at whatever body zone the caster has
 * selected: arms and legs get shackles, eyes get a blindfold. Every bind hangs off one binder item
 * in the caster's hand - drop it or use it in hand and the whole lot unravels.
 */

/obj/item/restraints/arcyne
	name = "arcyne shackles"
	desc = "Bands of hard blue light, shut fast around flesh. They do not seem to be attached to anything."
	gender = PLURAL
	icon = MAGE_HAND_OVERLAY_ICON
	icon_state = "arcyne_binders"
	item_weight = 0
	w_class = WEIGHT_CLASS_SMALL
	grid_width = 32
	grid_height = 32
	throwforce = 0
	breakouttime = 20 SECONDS
	slipouttime = 40 SECONDS
	resistance_flags = INDESTRUCTIBLE | FIRE_PROOF | ACID_PROOF | LAVA_PROOF
	/// Matches what rope inflicts, so conjured legcuffs are no worse than the mundane kind.
	var/legcuff_multiplicative_slowdown = 3
	/// The Mage Hand that conjured us.
	var/datum/weakref/context_ref
	/// Which bind zone we stand for, reported back when we come off.
	var/bind_zone

/obj/item/restraints/arcyne/Destroy()
	unbind_wearer()
	var/datum/sex_remote_context/mage_hand/context = context_ref?.resolve()
	context_ref = null
	context?.on_bind_lost(bind_zone)
	return ..()

/obj/item/restraints/arcyne/dropped(mob/user, silent = FALSE)
	. = ..()
	// The target broke out. Deleted next tick so the breakout finishes with a live item.
	QDEL_IN(src, 0)

/// Clears whichever cuff slot still points at us, mirroring what rope does when it is destroyed mid-bind.
/obj/item/restraints/arcyne/proc/unbind_wearer()
	if(!iscarbon(loc))
		return
	var/mob/living/carbon/wearer = loc
	if(wearer.handcuffed == src)
		wearer.set_handcuffed(null)
		wearer.update_handcuffed()
		if(wearer.buckled && wearer.buckled.buckle_requires_restraints)
			wearer.buckled.unbuckle_mob(wearer)
	if(wearer.legcuffed == src)
		wearer.legcuffed = null
		wearer.update_inv_legcuffed()
		wearer.remove_movespeed_modifier(MOVESPEED_ID_LEGCUFF_SLOWDOWN, TRUE)

/obj/item/arcyne_binders
	name = "arcyne binders"
	desc = "The near end of a conjured binding, humming cold against the palm. Let go and it unravels."
	gender = PLURAL
	icon = MAGE_HAND_OVERLAY_ICON
	icon_state = "arcyne_binders"
	item_weight = 0
	w_class = WEIGHT_CLASS_TINY
	grid_width = 32
	grid_height = 32
	throwforce = 0
	resistance_flags = INDESTRUCTIBLE | FIRE_PROOF | ACID_PROOF | LAVA_PROOF
	/// The Mage Hand whose binds we hold.
	var/datum/weakref/context_ref
	/// Guards the loop between our own deletion and the context releasing its binds.
	var/dispelling = FALSE

/obj/item/arcyne_binders/Destroy()
	dispel()
	return ..()

/obj/item/arcyne_binders/dropped(mob/user, silent = FALSE)
	. = ..()
	if(user)
		to_chat(user, span_warning("The binding slips my grip and comes apart."))
	dispel()

/obj/item/arcyne_binders/attack_self(mob/user, list/modifiers)
	to_chat(user, span_notice("I let the binding come apart."))
	dispel()

/// Releases every bind this binder holds and unravels itself.
/obj/item/arcyne_binders/proc/dispel()
	if(dispelling)
		return
	dispelling = TRUE
	var/datum/sex_remote_context/mage_hand/context = context_ref?.resolve()
	context_ref = null
	context?.release_all_binds()
	if(!QDELETED(src))
		qdel(src)

/mob/living/ShiftClick(mob/user, list/modifiers)
	if(try_mage_hand_bind(user, src))
		return
	return ..()

/// Turns a shift-click on a Mage Hand's victim into a bind on the caster's selected body zone. Toggles a zone already bound.
/proc/try_mage_hand_bind(mob/user, mob/living/target)
	if(!isliving(user) || !iscarbon(target) || user == target)
		return FALSE
	var/mob/living/caster = user
	var/datum/sex_remote_context/mage_hand/context = get_mage_hand_context(caster, target)
	if(!context)
		return FALSE
	var/zone = mage_hand_bind_zone_for(caster.zone_selected)
	if(!zone)
		return FALSE

	if(context.active_binds[zone])
		context.release_bind(zone)
		to_chat(caster, span_notice("I let the [mage_hand_bind_name(zone)] on [target] unravel."))
		return TRUE

	if(!context.try_bind(zone))
		to_chat(caster, span_warning("The binding will not take hold there."))
		return TRUE

	to_chat(caster, span_notice("My ghostly hand locks [mage_hand_bind_name(zone)] onto [target]."))
	to_chat(target, span_userdanger("Bands of cold blue light snap shut over me!"))
	target.visible_message(
		span_warning("Bands of cold blue light snap shut over [target]."),
		ignored_mobs = list(caster, target),
	)
	return TRUE

/// The caster's own live Mage Hand on this target, or null.
/proc/get_mage_hand_context(mob/living/caster, mob/living/target)
	if(!caster?.sex_scene)
		return null
	for(var/datum/sex_remote_context/mage_hand/context as anything in caster.sex_scene.remote_contexts)
		if(!istype(context) || QDELETED(context))
			continue
		if(context.get_caster() != caster || context.get_target() != target)
			continue
		if(!context.is_valid(context.scene))
			continue
		return context
	return null

/proc/mage_hand_bind_zone_for(selected_zone)
	switch(selected_zone)
		if(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_PRECISE_L_HAND, BODY_ZONE_PRECISE_R_HAND)
			return MAGE_HAND_ZONE_ARMS
		if(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG, BODY_ZONE_PRECISE_L_FOOT, BODY_ZONE_PRECISE_R_FOOT)
			return MAGE_HAND_ZONE_LEGS
		if(BODY_ZONE_PRECISE_L_EYE, BODY_ZONE_PRECISE_R_EYE)
			return MAGE_HAND_ZONE_EYES
	return null

/proc/mage_hand_bind_name(zone)
	switch(zone)
		if(MAGE_HAND_ZONE_ARMS)
			return "shackles"
		if(MAGE_HAND_ZONE_LEGS)
			return "leg irons"
		if(MAGE_HAND_ZONE_EYES)
			return "blindfold"
	return "binding"
