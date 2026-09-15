/**
 *  Skirt peeking
 */
/datum/element/skirt_peeking
	element_flags = ELEMENT_DETACH

/datum/element/skirt_peeking/Attach(datum/peeked)
	. = ..()
	if(!ishuman(peeked))
		return ELEMENT_INCOMPATIBLE

	RegisterSignal(peeked, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(peeked, COMSIG_ATOM_EXAMINE_MORE, PROC_REF(on_examine_more))

/datum/element/skirt_peeking/Detach(datum/source, force)
	UnregisterSignal(source, list(COMSIG_PARENT_EXAMINE, COMSIG_ATOM_EXAMINE_MORE))
	return ..()

/**
 * If peeker is given and is sneaking, and announce_blockers is set, tells
 * the peeker privately what specifically is blocking the peek - a
 * testing/debug aid, only ever sent on the first look. Nothing is said
 * if there's simply nothing peekable to begin with.
 */
/datum/element/skirt_peeking/proc/get_peekable_garment(mob/living/carbon/human/peeked, mob/living/peeker, announce_blockers = FALSE)
	var/sneaking_peeker = announce_blockers && istype(peeker) && peeker.m_intent == MOVE_INTENT_SNEAK

	var/obj/item/clothing/pants/worn_pants = peeked.wear_pants
	var/pants_peekable = worn_pants && is_type_in_typecache(worn_pants.type, GLOB.skirt_peekable_pants)

	var/obj/item/clothing/worn_armor = peeked.wear_armor
	var/dress_peekable = worn_armor && is_type_in_typecache(worn_armor.type, GLOB.skirt_peekable_outerwear)

	var/obj/item/clothing/garment = pants_peekable ? worn_pants : (dress_peekable ? worn_armor : null)
	if(!garment)
		return null

	if(!dress_peekable && worn_armor && CHECK_BITFIELD(worn_armor.body_parts_covered, GROIN))
		if(sneaking_peeker)
			to_chat(peeker, span_notice("([peeked]'s [worn_armor.name] is blocking your view.)"))
		return null

	var/obj/item/cloak_worn = peeked.cloak
	if(cloak_worn && !istype(cloak_worn, /obj/item/clothing/cloak/apron) && CHECK_BITFIELD(cloak_worn.body_parts_covered, GROIN))
		if(sneaking_peeker)
			to_chat(peeker, span_notice("([peeked]'s [cloak_worn.name] is blocking your view.)"))
		return null

	return garment

/// First look: just a hint that peeking is possible.
/datum/element/skirt_peeking/proc/on_examine(mob/living/carbon/human/peeked, mob/user, list/examine_list, list/P)
	SIGNAL_HANDLER

	if(user == peeked)
		return

	var/mob/living/maybe_peeker = isliving(user) ? user : null
	var/obj/item/clothing/garment = get_peekable_garment(peeked, maybe_peeker, announce_blockers = TRUE)
	if(!garment)
		return

	LAZYADDASSOCLIST(examine_list, EXAMINE_SECT_BODY, span_purple("[capitalize(P[THEY])] [P[ARE]] wearing [garment.name]! You could probably <b>peek</b> underneath..."))

/**
 * Colors an organ's descriptor text based on the target's own body color,
 * pushed toward a more intense, flushed tone as arousal rises (never all
 * the way to black - just more saturated/vivid), matching the same
 * breakpoints code/datums/mob_descriptors/descriptors/other.dm uses for
 * its own wording (throbbing/turgid/stiffened/soft, gushing/slickened/wet).
 * At the highest tier the text also pulses - a smooth, fast CSS fade.
 */
/datum/element/skirt_peeking/proc/color_by_arousal(text, mob/living/carbon/human/peeked, arousal)
	if(!text)
		return text

	var/weight
	var/pulsing = FALSE
	switch(arousal)
		if(80 to INFINITY)
			weight = 0.75
			pulsing = TRUE
		if(50 to 80)
			weight = 0.5
		if(20 to 50)
			weight = 0.25
		else
			return text

	var/base_hex = (peeked.dna?.species) ? peeked.dna.species.get_body_color(peeked) : null
	var/list/base_rgb = base_hex ? ReadRGB(base_hex) : null
	if(!base_rgb)
		base_rgb = list(255, 255, 255)

	var/flush_r = 235
	var/flush_g = 30
	var/flush_b = 60

	var/r = round(base_rgb[1] * (1 - weight) + flush_r * weight)
	var/g = round(base_rgb[2] * (1 - weight) + flush_g * weight)
	var/b = round(base_rgb[3] * (1 - weight) + flush_b * weight)

	. = "<font color='[rgb(r, g, b)]'>[text]</font>"
	if(pulsing)
		. = "<style>@keyframes skirt_peek_pulse{0%{opacity:1}50%{opacity:0.4}100%{opacity:1}}</style><span style='animation:skirt_peek_pulse 0.4s ease-in-out infinite'>[.]</span>"

/// Second, closer look within EXAMINE_MORE_WINDOW (engine-driven, see run_examinate()): the actual peek.
/datum/element/skirt_peeking/proc/on_examine_more(mob/living/carbon/human/peeked, mob/user, list/examine_list)
	SIGNAL_HANDLER

	if(!isliving(user) || user == peeked)
		return
	var/mob/living/peeker = user

	var/obj/item/clothing/garment = get_peekable_garment(peeked, peeker)
	if(!garment || !peeker.Adjacent(peeked))
		return

	// Have to actually be aiming for it - anything else selected, nothing happens.
	if(peeker.zone_selected != BODY_ZONE_PRECISE_GROIN)
		return

	var/obj/item/clothing/undies/undies = peeked.underwear

	var/list/arousal_data = list()
	SEND_SIGNAL(peeked, COMSIG_SEX_GET_AROUSAL, arousal_data)
	var/arousal = arousal_data["arousal"]

	var/their = peeked.p_their()
	var/theyre = peeked.p_theyre()
	var/theyve = peeked.p_theyve()

	var/list/seen = list()

	if(undies)
		var/undies_display = undies.color ? "<font color='[undies.color]'>[undies.name]</font>" : undies.name
		seen += undies_display

		if(arousal > VISIBLE_AROUSAL_THRESHOLD)
			if(peeked.getorganslot(ORGAN_SLOT_PENIS))
				seen += color_by_arousal("[capitalize(theyre)] pitching a tent in [their] [undies_display]", peeked, arousal)
			else if(peeked.getorganslot(ORGAN_SLOT_VAGINA))
				seen += color_by_arousal("[capitalize(theyve)] a wet spot on [their] [undies_display]", peeked, arousal)
	else
		// Bare - describe every present organ in full, reusing the same
		// descriptor singletons the rest of the game uses (size, type,
		// pubic hair, and for penis/vagina, arousal wording all included).
		var/obj/item/organ/genitals/butt/buttie = peeked.getorganslot(ORGAN_SLOT_BUTT)
		if(buttie)
			var/datum/mob_descriptor/butt/descriptor = MOB_DESCRIPTOR(/datum/mob_descriptor/butt)
			var/text = descriptor.get_description(peeked)
			if(text)
				seen += text

		if(peeked.getorganslot(ORGAN_SLOT_PENIS))
			var/datum/mob_descriptor/penis/descriptor = MOB_DESCRIPTOR(/datum/mob_descriptor/penis)
			var/text = descriptor.get_description(peeked)
			if(text)
				seen += color_by_arousal(text, peeked, arousal)

		if(peeked.getorganslot(ORGAN_SLOT_TESTICLES))
			var/datum/mob_descriptor/testicles/descriptor = MOB_DESCRIPTOR(/datum/mob_descriptor/testicles)
			var/text = descriptor.get_description(peeked)
			if(text)
				seen += text

		if(peeked.getorganslot(ORGAN_SLOT_VAGINA))
			var/datum/mob_descriptor/vagina/descriptor = MOB_DESCRIPTOR(/datum/mob_descriptor/vagina)
			var/text = descriptor.get_description(peeked)
			if(text)
				seen += color_by_arousal(text, peeked, arousal)

		if(!length(seen))
			seen += "nothing in particular"

	// Stockings/garter: only worth mentioning if a normal look wouldn't
	// already show them (i.e. they're currently obscured by something) -
	// otherwise peeking reveals nothing new about them. Color preserved
	// same as underwear.
	var/list/obscured_slots = peeked.check_obscured_slots()

	var/obj/item/clothing/legwears/socks = peeked.legwear_socks
	if(socks && CHECK_MULTIPLE_BITFIELDS(obscured_slots[SLOT_CHECK_EXTRA], ITEM_SLOT_SOCKS))
		seen += socks.color ? "<font color='[socks.color]'>[socks.name]</font>" : socks.name

	var/obj/item/clothing/garter/garter_worn = peeked.garter
	if(garter_worn && CHECK_MULTIPLE_BITFIELDS(obscured_slots[SLOT_CHECK_EXTRA], ITEM_SLOT_GARTER))
		seen += garter_worn.color ? "<font color='[garter_worn.color]'>[garter_worn.name]</font>" : garter_worn.name

	var/string = "You peek under [garment.name] at [peeked]. You see [english_list(seen, and_text = " and ")]."

	examine_list += span_purple(string)

GLOBAL_LIST_EMPTY(skirt_peekable_pants)
#define SKIRT_PEEKABLE_PANTS_KEYWORDS list("skirt", "kilt", "loincloth")

/obj/item/clothing/pants/Initialize(mapload)
	. = ..()
	if(!is_type_in_typecache(type, GLOB.skirt_peekable_pants))
		var/type_path_text = "[type]"
		for(var/keyword in SKIRT_PEEKABLE_PANTS_KEYWORDS)
			if(findtext(type_path_text, keyword))
				GLOB.skirt_peekable_pants[type] = TRUE
				break

#undef SKIRT_PEEKABLE_PANTS_KEYWORDS

GLOBAL_LIST_EMPTY(skirt_peekable_outerwear)

/obj/item/clothing/shirt/Initialize(mapload)
	. = ..()
	if(!is_type_in_typecache(type, GLOB.skirt_peekable_outerwear) && findtext("[type]", "dress"))
		GLOB.skirt_peekable_outerwear[type] = TRUE

GLOBAL_DATUM_INIT(skirt_peeking_glue, /datum/skirt_peeking_glue, new)

/datum/skirt_peeking_glue

/datum/skirt_peeking_glue/New()
	. = ..()
	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_CREATED, PROC_REF(on_mob_created))

/datum/skirt_peeking_glue/proc/on_mob_created(datum/source, mob/new_mob)
	SIGNAL_HANDLER

	if(ishuman(new_mob))
		new_mob.AddElement(/datum/element/skirt_peeking)
