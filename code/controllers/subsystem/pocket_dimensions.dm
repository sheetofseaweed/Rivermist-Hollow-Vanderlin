SUBSYSTEM_DEF(pocket_dimensions)
	name = "Pocket Dimensions"
	init_order = INIT_ORDER_POCKETS
	wait = 10 SECONDS
	lazy_load = FALSE

	var/list/templates_by_id = list()
	var/list/templates_by_type = list()
	var/list/instances_by_key = list()
	var/list/instances_by_id = list()
	/// Per-key futures covering the yielding map activation window.
	var/list/creation_reservations = list()
	var/list/currentrun = list()
	var/next_instance_id = 1

/datum/controller/subsystem/pocket_dimensions/Initialize(timeofday)
	if(initialized)
		return
	rebuild_template_cache()
	return ..()

/datum/controller/subsystem/pocket_dimensions/proc/rebuild_template_cache()
	templates_by_id.Cut()
	templates_by_type.Cut()

	for(var/template_id in SSmapping.map_templates)
		var/datum/map_template/pocket/template = SSmapping.map_templates[template_id]
		if(!istype(template) || !template.mappath)
			continue

		templates_by_id[template.id] = template
		templates_by_type[template.type] = template

/datum/controller/subsystem/pocket_dimensions/proc/resolve_template(template_ref)
	if(istype(template_ref, /datum/map_template/pocket))
		return template_ref
	if(istext(template_ref))
		return templates_by_id[template_ref]
	if(ispath(template_ref, /datum/map_template/pocket))
		return templates_by_type[template_ref]
	return null

/datum/controller/subsystem/pocket_dimensions/proc/get_instance(instance_key)
	instance_key = "[instance_key]"
	var/datum/pocket_dimension/instance = instances_by_key[instance_key]
	if(QDELETED(instance))
		instances_by_key -= instance_key
		if(instance)
			instances_by_id -= "[instance.instance_id]"
		return null
	return instance

/datum/controller/subsystem/pocket_dimensions/proc/get_or_create_instance(instance_key, template_ref, lifecycle_policy = null, idle_timeout = null, atom/pocket_holder = null)
	instance_key = "[instance_key]"
	var/datum/pocket_dimension/instance = get_instance(instance_key)
	if(instance)
		instance.apply_lifecycle_settings(lifecycle_policy, idle_timeout)
		instance.set_pocket_holder(pocket_holder)
		return instance
	var/datum/pocket_dimension_creation_reservation/existing_reservation = creation_reservations[instance_key]
	if(existing_reservation)
		var/wait_started = world.time
		while(!existing_reservation.finished)
			if(world.time > wait_started + 2 MINUTES)
				return null
			stoplag()
		instance = get_instance(instance_key)
		if(instance)
			instance.apply_lifecycle_settings(lifecycle_policy, idle_timeout)
			instance.set_pocket_holder(pocket_holder)
		return instance

	var/datum/map_template/pocket/template = resolve_template(template_ref)
	if(!template)
		return null

	var/instance_type = template.instance_type
	if(!ispath(instance_type, /datum/pocket_dimension))
		instance_type = /datum/pocket_dimension

	var/datum/pocket_dimension_creation_reservation/reservation = new
	creation_reservations[instance_key] = reservation
	instance = new instance_type(template, instance_key, next_instance_id++, lifecycle_policy, idle_timeout, pocket_holder)
	if(!instance.activate())
		qdel(instance)
		reservation.finished = TRUE
		if(creation_reservations[instance_key] == reservation)
			creation_reservations -= instance_key
		return null

	register_instance(instance)
	reservation.finished = TRUE
	if(creation_reservations[instance_key] == reservation)
		creation_reservations -= instance_key
	return instance

/datum/pocket_dimension_creation_reservation
	var/finished = FALSE

/datum/controller/subsystem/pocket_dimensions/proc/register_instance(datum/pocket_dimension/instance)
	if(!instance)
		return

	instances_by_key[instance.instance_key] = instance
	instances_by_id["[instance.instance_id]"] = instance

/datum/controller/subsystem/pocket_dimensions/proc/unregister_instance(datum/pocket_dimension/instance)
	if(!instance)
		return

	if(instances_by_key[instance.instance_key] == instance)
		instances_by_key -= instance.instance_key
	if(instances_by_id["[instance.instance_id]"] == instance)
		instances_by_id -= "[instance.instance_id]"

/datum/controller/subsystem/pocket_dimensions/proc/delete_instance(instance_or_key, eject_message = null, atom/eject_destination_override = null)
	var/datum/pocket_dimension/instance
	if(istype(instance_or_key, /datum/pocket_dimension))
		instance = instance_or_key
	else
		instance = get_instance(instance_or_key)

	if(!instance)
		return FALSE

	instance.eject_teardown_contents(eject_message, eject_destination_override)

	unregister_instance(instance)
	qdel(instance)
	return TRUE

/datum/controller/subsystem/pocket_dimensions/proc/get_child_instances(datum/pocket_dimension/parent_instance)
	var/list/child_instances = list()
	if(!parent_instance)
		return child_instances

	for(var/instance_id in instances_by_id)
		var/datum/pocket_dimension/instance = instances_by_id[instance_id]
		if(!instance || QDELETED(instance) || instance == parent_instance)
			continue

		var/atom/pocket_holder = instance.get_pocket_holder()
		if(!pocket_holder)
			continue
		if(!parent_instance.contains_turf(get_turf(pocket_holder)))
			continue

		child_instances += instance

	return child_instances

/datum/controller/subsystem/pocket_dimensions/proc/get_debug_instances()
	var/list/instances = list()

	for(var/instance_id = 1 to next_instance_id - 1)
		var/datum/pocket_dimension/instance = instances_by_id["[instance_id]"]
		if(!instance || QDELETED(instance))
			continue
		instances += instance

	return instances

/datum/controller/subsystem/pocket_dimensions/proc/build_debug_instance_choices()
	var/list/choices = list()

	for(var/datum/pocket_dimension/instance as anything in get_debug_instances())
		choices[instance.get_debug_label()] = instance

	return choices

/datum/controller/subsystem/pocket_dimensions/stat_entry(msg)
	var/active_instances = 0
	var/hibernating_instances = 0

	for(var/instance_id in instances_by_id)
		var/datum/pocket_dimension/instance = instances_by_id[instance_id]
		if(QDELETED(instance))
			continue
		if(instance.is_hibernating())
			hibernating_instances++
		else
			active_instances++

	msg = "I:[length(instances_by_id)] A:[active_instances] H:[hibernating_instances] CR:[length(currentrun)]"
	return ..()

/datum/controller/subsystem/pocket_dimensions/fire(resumed)
	if(!resumed)
		currentrun = list()
		for(var/instance_id in instances_by_id)
			var/datum/pocket_dimension/instance = instances_by_id[instance_id]
			if(QDELETED(instance))
				continue
			currentrun += instance

	while(length(currentrun))
		var/datum/pocket_dimension/instance = currentrun[length(currentrun)]
		currentrun.len--

		if(QDELETED(instance))
			continue

		instance.process_pocket()
		instance.process_idle_lifecycle()

		if(MC_TICK_CHECK)
			return
