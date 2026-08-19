/// Applies immediate wetness effects when an atom becomes immersed in a water turf.
/datum/element/watery_tile
	element_flags = ELEMENT_DETACH | ELEMENT_BESPOKE
	id_arg_index = 2
	/// Depth represented by this element instance.
	var/water_height
	/// Positive water cleans; negative water dirties.
	var/cleanliness_factor
	/// Movables currently present on attached turfs.
	var/list/atom/movable/wet_contents = list()

/datum/element/watery_tile/Destroy(force)
	wet_contents = null
	return ..()

/datum/element/watery_tile/Attach(turf/target, water_height = WATER_HEIGHT_ANKLE, cleanliness_factor = 1)
	. = ..()
	if(!isturf(target))
		return ELEMENT_INCOMPATIBLE

	src.water_height = water_height
	src.cleanliness_factor = cleanliness_factor
	RegisterSignals(target, list(COMSIG_ATOM_ENTERED, COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZED_ON), PROC_REF(enter_water))
	RegisterSignal(target, COMSIG_TURF_EXITED, PROC_REF(exit_water))

	for(var/atom/movable/movable as anything in target.contents)
		if(!(movable.flags_1 & INITIALIZED_1))
			continue
		enter_water(target, movable)

/datum/element/watery_tile/Detach(turf/source)
	UnregisterSignal(source, list(COMSIG_ATOM_ENTERED, COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZED_ON, COMSIG_TURF_EXITED))
	for(var/atom/movable/movable as anything in source.contents)
		exit_water(source, movable)
	return ..()

/datum/element/watery_tile/proc/enter_water(atom/source, atom/movable/entered)
	SIGNAL_HANDLER

	if(QDELETED(entered))
		return
	if(HAS_TRAIT(entered, TRAIT_IMMERSED))
		apply_water(entered)
	if(entered in wet_contents)
		return

	wet_contents |= entered
	RegisterSignal(entered, SIGNAL_ADDTRAIT(TRAIT_IMMERSED), PROC_REF(apply_water))
	RegisterSignal(entered, COMSIG_PARENT_QDELETING, PROC_REF(on_content_deleted))

/datum/element/watery_tile/proc/exit_water(atom/source, atom/movable/gone)
	SIGNAL_HANDLER
	on_content_deleted(gone)

/datum/element/watery_tile/proc/on_content_deleted(atom/movable/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, list(SIGNAL_ADDTRAIT(TRAIT_IMMERSED), COMSIG_PARENT_QDELETING))
	wet_contents -= source

/datum/element/watery_tile/proc/apply_water(atom/movable/source)
	SIGNAL_HANDLER

	var/dirty_water = cleanliness_factor < 0
	if(isobj(source))
		var/obj/object = source
		object.extinguish()
	if(istype(source, /obj/item/clothing))
		var/obj/item/clothing/clothing = source
		if(clothing.wetable)
			clothing.wet.add_water(20, dirty_water)
	if(!isliving(source))
		return

	var/mob/living/living = source
	living.ExtinguishMob()
	if(living.body_position == LYING_DOWN || water_height >= WATER_HEIGHT_DEEP)
		living.SoakMob(FULL_BODY, dirty_water)
	else if(water_height == WATER_HEIGHT_SHALLOW)
		living.SoakMob(BELOW_CHEST, dirty_water)
	else if(water_height == WATER_HEIGHT_ANKLE)
		living.SoakMob(FEET, dirty_water)
