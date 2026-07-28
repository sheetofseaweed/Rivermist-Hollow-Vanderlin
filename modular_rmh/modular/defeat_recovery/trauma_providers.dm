/// A resource-backed physical trauma provider. It is intentionally not mapped here: mappers can place
/// it wherever it fits, and tune the provider datum without changing the interaction contract.
/obj/machinery/defeat_medical_machine
	name = "trauma treatment apparatus"
	desc = "A compact medical frame for treating one precisely diagnosed defeat injury. It consumes one to three bandages according to the injury's severity."
	icon = 'icons/roguetown/misc/machines.dmi'
	icon_state = "lottery"
	density = TRUE
	var/datum/defeat_trauma_provider/medical/machine/treatment_provider

/obj/machinery/defeat_medical_machine/Initialize(mapload)
	. = ..()
	treatment_provider = new(src)

/obj/machinery/defeat_medical_machine/Destroy()
	QDEL_NULL(treatment_provider)
	return ..()

/obj/machinery/defeat_medical_machine/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	to_chat(user, span_notice("Hold a bandage or bandage roll in my active hand and use it on [src] to begin treatment."))

/obj/machinery/defeat_medical_machine/attackby(obj/item/offering, mob/living/user, list/modifiers)
	if(QDELETED(user) || QDELETED(offering) || QDELETED(treatment_provider) || !treatment_provider.accepts_resource(offering))
		return ..()
	var/mob/living/patient = input(user, "Who should the apparatus diagnose?", name) as null|mob in view(1, src)
	if(!patient || QDELETED(patient) || QDELETED(user) || QDELETED(offering) || QDELETED(treatment_provider))
		return
	if(!treatment_provider.treat(patient, user, interactive = TRUE, reserved_resource = offering))
		to_chat(user, span_warning("The treatment cannot be completed. Keep enough bandages in my active hand and remain beside [src] and [patient]."))
		return
	user.visible_message(span_notice("[user] completes a focused treatment for [patient] with [src]."), span_notice("I complete one focused trauma treatment for [patient]."))

/// A resource-backed spiritual provider. Silver remains in the user's hand throughout diagnosis and
/// the rite, and is debited only once the selected trauma has passed its final validation.
/obj/structure/defeat_trauma_shrine
	name = "shrine of solace"
	desc = "A small shrine that accepts one to three silver coins to soothe one chosen spiritual trauma."
	icon = 'icons/roguetown/misc/structure.dmi'
	icon_state = "elfs"
	density = TRUE
	anchored = TRUE
	var/datum/defeat_trauma_provider/shrine/structure/treatment_provider

/obj/structure/defeat_trauma_shrine/Initialize(mapload)
	. = ..()
	treatment_provider = new(src)

/obj/structure/defeat_trauma_shrine/Destroy()
	QDEL_NULL(treatment_provider)
	return ..()

/obj/structure/defeat_trauma_shrine/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	to_chat(user, span_notice("Hold silver coins in my active hand and offer them to [src] to begin a rite."))

/obj/structure/defeat_trauma_shrine/attackby(obj/item/offering, mob/living/user, list/modifiers)
	if(QDELETED(user) || QDELETED(offering) || QDELETED(treatment_provider) || !treatment_provider.accepts_resource(offering))
		return ..()
	var/mob/living/patient = input(user, "Who should receive the shrine's solace?", name) as null|mob in view(1, src)
	if(!patient || QDELETED(patient) || QDELETED(user) || QDELETED(offering) || QDELETED(treatment_provider))
		return
	if(!treatment_provider.treat(patient, user, interactive = TRUE, reserved_resource = offering))
		to_chat(user, span_warning("The rite cannot be completed. Keep enough silver in my active hand and remain beside [src] and [patient]."))
		return
	user.visible_message(span_notice("[user] offers silver at [src], easing one trauma from [patient]."), span_notice("I complete one focused rite for [patient]."))

/// Both providers are ordinary blueprint constructions and therefore appear in the existing globally
/// reachable construction browser. They require no map placement or special roundstart grant.
/datum/blueprint_recipe/engineering/defeat_medical_machine
	name = "trauma treatment apparatus"
	desc = "A resource-backed apparatus for diagnosing and treating one physical defeat trauma."
	result_type = /obj/machinery/defeat_medical_machine
	required_materials = list(
		/obj/item/ingot/iron = 2,
		/obj/item/natural/wood/plank = 2,
		/obj/item/natural/glass = 1,
	)
	supports_directions = TRUE
	craftdiff = 2
	build_time = 8 SECONDS

/datum/blueprint_recipe/masonry/defeat_trauma_shrine
	name = "shrine of solace"
	desc = "A small resource-backed shrine for soothing one spiritual defeat trauma."
	result_type = /obj/structure/defeat_trauma_shrine
	required_materials = list(
		/obj/item/natural/stone = 4,
		/obj/item/ingot/silver = 1,
	)
	supports_directions = TRUE
	craftdiff = 1
	build_time = 6 SECONDS
