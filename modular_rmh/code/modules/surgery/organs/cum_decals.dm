// Ejaculate floor decals: small drips that grow into puddles. Mirrors BlueMoon's semen/semendrip, but reagent-agnostic
// (tints itself to whatever fluid it holds) so it works for any climax fluid routed through deposit_cum_on_turf().

/// Spills of at least this many units pool straight into a puddle decal instead of starting life as a drip.
#define CUM_PUDDLE_MIN_VOLUME 40
/// A drip that accumulates at least this many units grows into a puddle decal.
#define CUM_DRIP_TO_PUDDLE_VOLUME 10

/// Shared base for sexual-fluid floor decals. Holds the spilled reagents and tints itself to match them.
/obj/effect/decal/cleanable/sexfluid
	abstract_type = /obj/effect/decal/cleanable/sexfluid
	name = "fluid"
	desc = ""
	gender = PLURAL
	icon = 'modular_rmh/icons/obj/genitals/cum_effects.dmi'
	alpha = 200

/obj/effect/decal/cleanable/sexfluid/Initialize(mapload)
	. = ..()
	if(. == INITIALIZE_HINT_QDEL)
		return .
	recolor_to_reagents()

/// Pulls `amount` units out of `source` into our own reagents, then retints to match.
/obj/effect/decal/cleanable/sexfluid/proc/absorb_fluid(datum/reagents/source, amount)
	if(source && amount > 0 && reagents)
		source.trans_to(src, amount)
	recolor_to_reagents()

/// Greyscale sprites, so a plain colour multiply reproduces the fluid colour faithfully. Goes through add_atom_colour
/// because a direct `color =` assignment is overwritten by the atom-colour priority system on the next update.
/obj/effect/decal/cleanable/sexfluid/proc/recolor_to_reagents()
	if(reagents?.total_volume)
		add_atom_colour(mix_color_from_reagents(reagents.reagent_list), FIXED_COLOUR_PRIORITY)

/obj/effect/decal/cleanable/sexfluid/replace_decal(obj/effect/decal/cleanable/sexfluid/existing)
	. = ..()
	if(!. || QDELETED(src) || !istype(existing))
		return .
	// We are being merged into the pre-existing decal; hand over our reagents so nothing is lost.
	if(reagents?.total_volume && existing.reagents)
		reagents.trans_to(existing.reagents, reagents.total_volume)
	existing.recolor_to_reagents()
	return .

/obj/effect/decal/cleanable/sexfluid/attack_hand(mob/user)
	if(can_lick_fluids(user)) //bite intent + empty hand: lick the fluid up
		handle_fluid_lick(user, reagents, src, name, FALSE)
		if(!reagents || reagents.total_volume <= 0)
			qdel(src)
		return TRUE
	return ..()

/obj/effect/decal/cleanable/sexfluid/attack_hand_secondary(mob/user, list/modifiers)
	if(can_lick_fluids(user)) //bite intent + empty hand: drink it up continuously
		handle_fluid_lick(user, reagents, src, name, TRUE)
		if(!reagents || reagents.total_volume <= 0)
			qdel(src)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	return ..()

/obj/effect/decal/cleanable/sexfluid/cum
	name = "semen"
	icon_state = "semen1"
	random_icon_states = list("semen1", "semen2", "semen3", "semen4", "semen5", "semen6", "semen7", "semen8", "semen9", "semen10", "semen11", "semen12", "semen13", "semen14")

/obj/effect/decal/cleanable/sexfluid/cumdrip
	name = "drips of fluid"
	icon_state = "drip1"
	random_icon_states = list("drip1", "drip2", "drip3", "drip4", "drip5")

/// Spills `amount` of `source` onto `target`. Small spills form a drip that grows into a puddle once it gathers
/// CUM_DRIP_TO_PUDDLE_VOLUME; spills of CUM_PUDDLE_MIN_VOLUME or more (or onto an existing puddle) pool immediately.
/proc/deposit_cum_on_turf(turf/target, datum/reagents/source, amount)
	if(!target || !source || amount <= 0)
		return 0
	amount = min(amount, source.total_volume)
	if(amount <= 0)
		return 0

	var/obj/effect/decal/cleanable/sexfluid/cum/puddle = locate() in target
	if(amount >= CUM_PUDDLE_MIN_VOLUME || puddle) //big load, or pooling onto an existing puddle.
		if(!puddle)
			puddle = new(target)
		puddle.absorb_fluid(source, amount)
		return amount

	var/obj/effect/decal/cleanable/sexfluid/cumdrip/drip = locate() in target
	if(!drip)
		drip = new(target)
	drip.absorb_fluid(source, amount)
	if(drip.reagents?.total_volume >= CUM_DRIP_TO_PUDDLE_VOLUME) //grown past a drip: collapse into a puddle.
		puddle = new(target)
		drip.reagents.trans_to(puddle.reagents, drip.reagents.total_volume)
		puddle.recolor_to_reagents()
		qdel(drip)
	return amount

#undef CUM_PUDDLE_MIN_VOLUME
#undef CUM_DRIP_TO_PUDDLE_VOLUME
