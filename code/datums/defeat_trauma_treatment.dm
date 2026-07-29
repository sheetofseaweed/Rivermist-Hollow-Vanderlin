/// Orders diagnosis consistently so automatic and test-driven treatment never depends on status-list order.
/proc/cmp_defeat_trauma_label_asc(datum/status_effect/debuff/defeat/first, datum/status_effect/debuff/defeat/second)
	return sorttext(second.trauma_label, first.trauma_label)

/// Contract shared by clinic care, shrines, tools, spells, and reagents. A provider diagnoses all
/// compatible traumas, selects one exact status datum, validates it before and after the delay, pays
/// only after success is certain, and removes only that selected datum.
/datum/defeat_trauma_provider
	var/name = "trauma treatment"
	var/provider_tag = DEFEAT_TRAUMA_PROVIDER_UNIVERSAL
	/// Legacy treatment identifier carried by COMSIG_LIVING_DEFEAT_TREATED.
	var/treatment_type = DEFEAT_TREATMENT_UNIVERSAL
	var/list/accepted_categories = list(
		DEFEAT_TRAUMA_CATEGORY_PHYSICAL,
		DEFEAT_TRAUMA_CATEGORY_SPIRITUAL,
	)
	var/list/allowed_trauma_types
	var/requires_adjacent = FALSE
	var/required_area_type
	var/use_trauma_skill = FALSE
	var/treatment_duration_override
	var/resource_cost_override = 0
	var/list/accepted_resource_types
	var/resource_unit_name = "resource unit"
	var/datum/weakref/host_ref

/datum/defeat_trauma_provider/New(datum/host)
	. = ..()
	if(host)
		host_ref = WEAKREF(host)

/datum/defeat_trauma_provider/Destroy()
	host_ref = null
	return ..()

/datum/defeat_trauma_provider/proc/resolve_host()
	var/datum/host = host_ref?.resolve()
	if(QDELETED(host))
		return null
	return host

/datum/defeat_trauma_provider/proc/can_target_trauma(datum/status_effect/debuff/defeat/trauma)
	if(!istype(trauma))
		return FALSE
	if(!(trauma.trauma_category in accepted_categories))
		return FALSE
	if(!(provider_tag in trauma.accepted_provider_tags))
		return FALSE
	if(length(allowed_trauma_types))
		var/type_allowed = FALSE
		for(var/trauma_type in allowed_trauma_types)
			if(istype(trauma, trauma_type))
				type_allowed = TRUE
				break
		if(!type_allowed)
			return FALSE
	return TRUE

/datum/defeat_trauma_provider/proc/diagnose(mob/living/patient)
	var/list/diagnosed = list()
	if(!patient || QDELETED(patient))
		return diagnosed
	for(var/datum/status_effect/debuff/defeat/trauma as anything in patient.status_effects)
		if(can_target_trauma(trauma))
			diagnosed += trauma
	sortTim(diagnosed, GLOBAL_PROC_REF(cmp_defeat_trauma_label_asc))
	return diagnosed

/datum/defeat_trauma_provider/proc/select_target(mob/living/patient, mob/living/helper, datum/status_effect/debuff/defeat/exact_target, interactive = FALSE, obj/item/reserved_resource)
	if(QDELETED(patient) || QDELETED(helper))
		return null
	var/list/diagnosed = interactive ? usable_diagnoses(patient, helper, reserved_resource) : diagnose(patient)
	if(!length(diagnosed))
		return null
	var/datum/status_effect/debuff/defeat/selected
	if(exact_target)
		selected = (exact_target in diagnosed) ? exact_target : null
	else if(!interactive || length(diagnosed) == 1)
		selected = diagnosed[1]
	else
		var/list/options = list()
		var/list/label_counts = list()
		for(var/datum/status_effect/debuff/defeat/trauma as anything in diagnosed)
			var/base_label = treatment_summary(helper, trauma)
			label_counts[base_label] = (label_counts[base_label] || 0) + 1
			var/option_name = label_counts[base_label] == 1 ? base_label : "[base_label] ([label_counts[base_label]])"
			options[option_name] = trauma
		var/choice = input(helper, "Choose the exact trauma to treat.", name) as null|anything in options
		if(QDELETED(patient) || QDELETED(helper))
			return null
		selected = options[choice]
	if(QDELETED(selected) || selected.owner != patient)
		return null
	if(!interactive)
		return selected
	if(alert(helper, treatment_summary(helper, selected), "Confirm [name]", "Begin treatment", "Cancel") != "Begin treatment")
		return null
	if(QDELETED(patient) || QDELETED(helper) || QDELETED(selected) || selected.owner != patient)
		return null
	return selected

/datum/defeat_trauma_provider/proc/provider_location_text()
	var/atom/host = resolve_host()
	if(host)
		return "[host] in [get_area(host)]"
	if(required_area_type)
		return "the required treatment area"
	return "the patient's current location"

/datum/defeat_trauma_provider/proc/resource_cost_text(datum/status_effect/debuff/defeat/target)
	var/cost = resource_cost_for(target)
	if(cost <= 0)
		return "none"
	var/suffix = cost == 1 ? "" : "s"
	return "[cost] [resource_unit_name][suffix]"

/// Complete pre-channel disclosure used by both the selection list and final confirmation.
/datum/defeat_trauma_provider/proc/treatment_summary(mob/living/helper, datum/status_effect/debuff/defeat/target)
	return "[target.trauma_label] ([defeat_severity_label(target.severity)]) - [target.treatment_description] Duration: [DisplayTimeText(treatment_time(helper, target))]. Cost: [resource_cost_text(target)]. Provider: [name] at [provider_location_text()]."

/// Candidates a specific provider can actually begin with right now. Used when several nearby
/// stations exist so callers never select an unusable first match.
/datum/defeat_trauma_provider/proc/usable_diagnoses(mob/living/patient, mob/living/helper, obj/item/reserved_resource)
	var/list/usable = list()
	for(var/datum/status_effect/debuff/defeat/trauma as anything in diagnose(patient))
		if(validate(patient, helper, trauma, reserved_resource))
			usable += trauma
	return usable

/datum/defeat_trauma_provider/proc/validate(mob/living/patient, mob/living/helper, datum/status_effect/debuff/defeat/target, obj/item/reserved_resource)
	if(!patient || QDELETED(patient) || patient.stat == DEAD || !helper || QDELETED(helper) || helper.stat == DEAD)
		return FALSE
	if(QDELETED(target) || target.owner != patient || !(target in patient.status_effects) || !can_target_trauma(target))
		return FALSE
	var/atom/host = resolve_host()
	if(host_ref && !host)
		return FALSE
	if(host)
		if(!helper.Adjacent(host) || !patient.Adjacent(host))
			return FALSE
	else if(requires_adjacent && helper != patient && !helper.Adjacent(patient))
		return FALSE
	if(required_area_type && !istype(get_area(patient), required_area_type))
		return FALSE
	if(use_trauma_skill && target.treatment_skill)
		var/has_role_training = (provider_tag == DEFEAT_TRAUMA_PROVIDER_MEDICAL && HAS_TRAIT(helper, TRAIT_SURGEON)) \
			|| (provider_tag == DEFEAT_TRAUMA_PROVIDER_SHRINE && HAS_TRAIT(helper, TRAIT_HOLY))
		if(!has_role_training && GET_MOB_SKILL_VALUE_OLD(helper, target.treatment_skill) < target.treatment_skill_requirement)
			return FALSE
	if(reserved_resource && (QDELETED(reserved_resource) || helper.get_active_held_item() != reserved_resource))
		return FALSE
	return has_resources_for(target, reserved_resource)

/datum/defeat_trauma_provider/proc/treatment_time(mob/living/helper, datum/status_effect/debuff/defeat/target)
	if(!isnull(treatment_duration_override))
		return treatment_duration_override
	var/duration = target.treatment_duration
	if(use_trauma_skill && target.treatment_skill)
		duration -= GET_MOB_SKILL_VALUE_OLD(helper, target.treatment_skill) * 0.5 SECONDS
	return max(2 SECONDS, duration)

/datum/defeat_trauma_provider/proc/resource_cost_for(datum/status_effect/debuff/defeat/target)
	if(!isnull(resource_cost_override))
		return resource_cost_override
	return target.treatment_resource_cost * defeat_severity_rank(target.severity)

/datum/defeat_trauma_provider/proc/has_resources_for(datum/status_effect/debuff/defeat/target, obj/item/reserved_resource)
	var/cost = resource_cost_for(target)
	if(cost <= 0)
		return TRUE
	if(reserved_resource)
		return accepts_resource(reserved_resource) && resource_value(reserved_resource) >= cost
	return FALSE

/datum/defeat_trauma_provider/proc/consume_resources(datum/status_effect/debuff/defeat/target, obj/item/reserved_resource)
	var/cost = resource_cost_for(target)
	if(cost <= 0)
		return TRUE
	if(reserved_resource)
		if(!accepts_resource(reserved_resource) || resource_value(reserved_resource) < cost)
			return FALSE
		if(istype(reserved_resource, /obj/item/coin))
			var/obj/item/coin/coins = reserved_resource
			if(coins.quantity == cost)
				qdel(coins)
			else
				coins.set_quantity(coins.quantity - cost)
			return TRUE
		if(istype(reserved_resource, /obj/item/natural/bundle/cloth/bandage))
			var/obj/item/natural/bundle/cloth/bandage/bandages = reserved_resource
			if(bandages.amount == cost)
				qdel(bandages)
			else
				bandages.amount -= cost
				bandages.update_bundle()
			return TRUE
		if(cost == 1)
			qdel(reserved_resource)
			return TRUE
		return FALSE
	return FALSE

/datum/defeat_trauma_provider/proc/perform_treatment_delay(mob/living/patient, mob/living/helper, datum/status_effect/debuff/defeat/target)
	var/duration = treatment_time(helper, target)
	if(duration <= 0)
		return TRUE
	return do_after(helper, duration, target = patient)

/datum/defeat_trauma_provider/proc/treat(mob/living/patient, mob/living/helper, datum/status_effect/debuff/defeat/exact_target, interactive = FALSE, skip_delay = FALSE, obj/item/reserved_resource)
	if(QDELETED(patient) || QDELETED(helper) || (reserved_resource && QDELETED(reserved_resource)))
		return FALSE
	var/datum/status_effect/debuff/defeat/target = select_target(patient, helper, exact_target, interactive, reserved_resource)
	if(!validate(patient, helper, target, reserved_resource))
		return FALSE
	if(!skip_delay && !perform_treatment_delay(patient, helper, target))
		return FALSE
	if(!validate(patient, helper, target, reserved_resource))
		return FALSE
	if(!consume_resources(target, reserved_resource))
		return FALSE
	qdel(target)
	SEND_SIGNAL(patient, COMSIG_LIVING_DEFEAT_TREATED, helper, treatment_type)
	return TRUE

/datum/defeat_trauma_provider/proc/accepts_resource(obj/item/resource)
	if(!resource)
		return FALSE
	for(var/resource_type in accepted_resource_types)
		if(istype(resource, resource_type))
			return TRUE
	return FALSE

/datum/defeat_trauma_provider/proc/resource_value(obj/item/resource)
	if(istype(resource, /obj/item/coin))
		var/obj/item/coin/coins = resource
		return coins.quantity
	if(istype(resource, /obj/item/natural/bundle/cloth/bandage))
		var/obj/item/natural/bundle/cloth/bandage/bandages = resource
		return bandages.amount
	return 1

/datum/defeat_trauma_provider/medical
	name = "medical trauma treatment"
	provider_tag = DEFEAT_TRAUMA_PROVIDER_MEDICAL
	treatment_type = DEFEAT_TREATMENT_MEDICAL
	accepted_categories = list(DEFEAT_TRAUMA_CATEGORY_PHYSICAL)
	requires_adjacent = TRUE
	use_trauma_skill = TRUE

/datum/defeat_trauma_provider/medical/clinic
	required_area_type = /area/indoors/town/clinic_large
	resource_cost_override = 0

/datum/defeat_trauma_provider/medical/tool
	resource_cost_override = 0
	treatment_duration_override = 0
	requires_adjacent = FALSE

/datum/defeat_trauma_provider/medical/compatibility
	resource_cost_override = 0
	treatment_duration_override = 0
	requires_adjacent = FALSE

/datum/defeat_trauma_provider/medical/machine
	accepted_resource_types = list(/obj/item/natural/cloth/bandage, /obj/item/natural/bundle/cloth/bandage)
	resource_unit_name = "bandage"
	resource_cost_override = null

/datum/defeat_trauma_provider/shrine
	name = "spiritual trauma treatment"
	provider_tag = DEFEAT_TRAUMA_PROVIDER_SHRINE
	treatment_type = DEFEAT_TREATMENT_SPIRITUAL
	accepted_categories = list(DEFEAT_TRAUMA_CATEGORY_SPIRITUAL)
	requires_adjacent = TRUE
	use_trauma_skill = TRUE

/datum/defeat_trauma_provider/shrine/church
	required_area_type = /area/indoors/town/church
	resource_cost_override = 0

/datum/defeat_trauma_provider/shrine/compatibility
	resource_cost_override = 0
	treatment_duration_override = 0
	requires_adjacent = FALSE

/datum/defeat_trauma_provider/shrine/structure
	accepted_resource_types = list(/obj/item/coin/silver)
	resource_unit_name = "silver coin"
	resource_cost_override = null

/datum/defeat_trauma_provider/universal
	name = "universal trauma treatment"
	provider_tag = DEFEAT_TRAUMA_PROVIDER_UNIVERSAL
	resource_cost_override = 0
	treatment_duration_override = 0
