//By Vide Noir https://github.com/EaglePhntm.

/// Dribbles at or below this many units form a drop decal; once a drop gathers more than this it becomes a real puddle.
#define LIQUID_DRIP_MAX_UNITS 5
/// Fill ratio at which a full organ starts leaking faster; below this the drip rate is unchanged.
#define DRIP_PRESSURE_THRESHOLD 0.6
/// Drip rate multiplier reached (and capped at) when the organ is full or overfull.
#define DRIP_PRESSURE_MAX_MULT 6
/// Below this nutrition a hungry owner reabsorbs stored fluid instead of producing it.
#define FLUID_HUNGER_NUTRITION (NUTRITION_LEVEL_HUNGRY - 25)
/// Production speed-up when well fed or free of hunger; from hungry up to well fed it ramps from zero.
#define FLUID_WELL_FED_MULTIPLIER 1.5
/// Units of stored fluid spent per point of nutrition regained when hungry.
#define FLUID_REABSORB_COST 4
/// Capacity shifts smaller than this do not alert self-aware owners.
#define FLUID_CAPACITY_ALERT_MIN_CHANGE 5
/// Leak speed-up when a container under the owner collects the flow.
#define FLUID_COLLECTOR_LEAK_MULTIPLIER 50
/// An engorged organ shrinks a step only this far below the step's threshold, so it does not flicker.
#define FLUID_ENGORGEMENT_HYSTERESIS 0.05
/// Examine text calls an organ full from this share of capacity.
#define FLUID_LOOKS_FULL_RATIO 0.8
/// Examine text calls an organ close to bursting from this share of capacity.
#define FLUID_LOOKS_BURSTING_RATIO 0.95
/// Organs that leak when full let down only at this share of capacity.
#define FLUID_LETDOWN_FULL_RATIO 0.99
/// Units in one let-down, and the random wait between let-downs; on average less than clothes dry off.
#define FLUID_LETDOWN_AMOUNT 3
#define FLUID_LETDOWN_MIN_INTERVAL (3 MINUTES)
#define FLUID_LETDOWN_MAX_INTERVAL (6 MINUTES)

//container organ that can refill self through nutrients etc.
/obj/item/organ/genitals/filling_organ
	name = "self filling organ"

	//faster healing cause those will be rippin alot
	healing_factor = STANDARD_ORGAN_HEALING*3
	decay_factor = STANDARD_ORGAN_DECAY

	/// Capacity added per organ size step when organ_sizeable.
	var/storage_per_size = 100
	/// Fixed capacity for organs that cannot be resized.
	var/max_reagents = 30
	/// TRUE if capacity scales with organ_size set in prefs.
	var/organ_sizeable = FALSE
	/// Reagent this organ produces; null for organs that only hold fluid.
	var/datum/reagent/reagent_to_make = /datum/reagent/consumable/nutriment
	/// Base setting for production; fluid modifiers can force or block it. Read is_producing().
	var/produces_fluid = FALSE
	/// Units produced per second while producing.
	var/production_rate = 1.5
	/// Nutrition spent per unit produced.
	var/nutrition_per_unit = 1
	/// A hungry owner reabsorbs this organ's own fluid as nutrition.
	var/hungerhelp = FALSE
	/// Fill to capacity when inserted at spawn, if producing.
	var/startsfilled = FALSE

	/// Moves foreign reagents into the owner's blood.
	var/absorbing = FALSE
	/// Units absorbed per flow interval.
	var/absorbrate = 1
	/// Multiplier on absorbed units reaching the blood.
	var/absorbmult = 1
	/// Units leaked per flow interval before pressure and modifiers.
	var/driprate = 0.2
	/// Leaks whenever it holds fluid; otherwise leaks only when overfull.
	var/spiller = FALSE
	/// The owner can clench this opening to hold fluid in.
	var/can_hold_in = FALSE
	/// Worn slot that covers the opening and stops leaks.
	var/blocker = ITEM_SLOT_SHIRT
	/// If set, underwear replaces the blocker slot item as the cover.
	var/additional_blocker
	/// Interval between leak, absorb and stored-container exchanges.
	var/processspeed = 5 SECONDS
	/// Applies bloat debuffs when full.
	var/bloatable = FALSE
	/// Lets down a little fluid now and then while completely full, even if it is not a spiller.
	var/leaks_when_full = FALSE
	COOLDOWN_DECLARE(letdown_cooldown)
	/// Where fluid leaked from this organ stains the clothes over it.
	var/stain_zone = FLUID_STAIN_GROIN

	//pregnancy vars
	var/fertility = FALSE //can it be impregnated
	var/pregnant = FALSE // is it pregnant
	var/conventional_pregnancy_stage = 0
	var/conventional_pregnancy_timer
	var/allows_conventional_impregnation = FALSE
	var/spawn_embryo_on_fertilization = FALSE
	var/fertilization_embryo_egg_type = OVI_EGG_EMBRYO
	var/fertilization_embryo_hatch_result_type = null
	var/fertilization_embryo_limit = 3

	//misc
	var/last_size_alert = 0
	var/last_damagespill_alert = 0
	/// If TRUE, small dribbles (<= LIQUID_DRIP_MAX_UNITS) form a colored drop decal instead of pooling as a liquid puddle.
	var/drips_as_drops = FALSE
	/// Whether this organ can visibly swell when its owner has TRAIT_FLUID_ENGORGEMENT.
	var/can_engorge = FALSE
	/// Size steps currently added to the sprite by fullness; visual only.
	var/engorgement_steps = 0

	COOLDOWN_DECLARE(liquidcd)

/obj/item/organ
	var/allows_oviposition_pregnancy = FALSE
	var/oviposition_storage_component_type = null
	var/oviposition_location_name = null
	var/oviposition_lay_verb = "lays"
	var/oviposition_lay_action = "lay"

/mob/living/carbon
	/// Completed internal hatchling births, stored as world.time values for the rolling implantation limit.
	var/list/recent_oviposition_births
	/// Prevents repeated implantation attempts from spamming the recovery warning.
	var/next_oviposition_birth_limit_warning = 0

/// Returns whether another egg or embryo may be implanted under the rolling birth limit.
/mob/living/carbon/proc/can_receive_oviposition_implant(show_feedback = FALSE)
	var/birth_cutoff = world.time - OVIPOSITION_BIRTH_LIMIT_WINDOW
	while(length(recent_oviposition_births) && recent_oviposition_births[1] <= birth_cutoff)
		recent_oviposition_births.Cut(1, 2)

	if(length(recent_oviposition_births) < OVIPOSITION_BIRTH_LIMIT)
		return TRUE

	if(show_feedback && world.time >= next_oviposition_birth_limit_warning)
		var/unlock_birth_index = length(recent_oviposition_births) - OVIPOSITION_BIRTH_LIMIT + 1
		var/time_until_recovered = recent_oviposition_births[unlock_birth_index] + OVIPOSITION_BIRTH_LIMIT_WINDOW - world.time
		to_chat(src, span_warning("My body is still recovering from so many recent births. It cannot accept another egg or embryo for [DisplayTimeText(time_until_recovered)]."))
		next_oviposition_birth_limit_warning = world.time + 1 MINUTES
	return FALSE

/// Records a successfully completed internal hatchling birth for the rolling implantation limit.
/mob/living/carbon/proc/record_oviposition_birth()
	LAZYADD(recent_oviposition_births, world.time)

/// Ends every active pregnancy after a successful resurrection rune rescue.
/// Embryo sacs are destroyed, while ordinary eggs remain implanted but dormant.
/mob/living/carbon/proc/end_pregnancies_after_rune_resurrection()
	var/ended_pregnancy = FALSE

	for(var/obj/item/organ/organ as anything in internal_organs)
		var/list/growing_eggs = organ.get_oviposition_eggs(TRUE)
		if(!length(growing_eggs))
			continue

		var/datum/component/body_storage/storage = organ.get_oviposition_storage()
		var/recalculate_storage_bulk = FALSE
		for(var/obj/item/oviposition_egg/egg as anything in growing_eggs)
			var/datum/component/pregnancy/pregnancy = egg.get_pregnancy_component()
			if(!pregnancy)
				continue

			if(egg.egg_type == OVI_EGG_EMBRYO)
				if(!pregnancy.remove_from_host(BODYSTORAGE_REMOVE_INTERNAL))
					continue
				qdel(egg)
			else
				qdel(pregnancy)
				egg.apply_scale_to_appearance()
				recalculate_storage_bulk = TRUE
			ended_pregnancy = TRUE

		if(recalculate_storage_bulk)
			storage?.recalculate_current_bulk(organ)

	if(ended_pregnancy)
		to_chat(src, span_blue("The resurrection rune's magic stills every pregnancy within me."))
	return ended_pregnancy

/obj/item/organ/guts
	// Oral storage lives on guts, but oviposition messaging should read as stomach-based.
	allows_oviposition_pregnancy = TRUE
	oviposition_storage_component_type = /datum/component/body_storage/mouth
	oviposition_location_name = "stomach"
	oviposition_lay_verb = "coughs up"
	oviposition_lay_action = "cough up"

/obj/item/organ/genitals/filling_organ/Insert(mob/living/M, special, drop_if_replaced, new_zone = null)
	. = ..()
	if(!.)
		return FALSE
	// Stored fluid survives removal and reinsertion.
	if(!reagents)
		create_reagents(get_base_capacity())
	reagents.maximum_volume = get_reagent_capacity()
	if(pregnant)
		start_pregnancy_lactation()
	// Surgery passes special = FALSE, so only spawned bodies start full.
	if(special && startsfilled && is_producing())
		add_produced_fluid(reagents.maximum_volume)
	if(reagent_to_make)
		RegisterSignal(M, COMSIG_MOB_FOOD_EAT, PROC_REF(on_owner_ate))

/obj/item/organ/genitals/filling_organ/Remove(mob/living/M, special, drop_if_replaced)
	if(pregnant)
		M?.remove_fluid_modifier(/datum/fluid_modifier/pregnancy_lactation, FLUID_SOURCE_PREGNANCY)
	engorgement_steps = 0
	if(M)
		UnregisterSignal(M, COMSIG_MOB_FOOD_EAT)
	return ..()

/obj/item/organ/genitals/filling_organ/consider_processing(in_bleedout = FALSE)
	..()
	// Fluid upkeep runs every life tick, not only while the organ is hurt.
	needs_processing = TRUE
	return TRUE

/obj/item/organ/genitals/filling_organ/on_reagent_change(changetype)
	. = ..()
	if(slot == ORGAN_SLOT_ANUS || slot == ORGAN_SLOT_VAGINA)
		SEND_SIGNAL(src, COMSIG_BODYSTORAGE_CHANGED)

/obj/item/organ/genitals/filling_organ/on_body_storage_inserted(obj/item/inserted_item, target_layer)
	. = ..()
	if(target_layer == STORAGE_LAYER_OUTER || !inserted_item || !reagents?.total_volume)
		return
	spill_excess_reagents()

/// Capacity from organ size alone, before modifiers, pregnancy and stored items.
/obj/item/organ/genitals/filling_organ/proc/get_base_capacity()
	if(organ_sizeable)
		return storage_per_size + (storage_per_size * organ_size)
	return max_reagents

/// The one source of truth for how much fluid this organ can hold right now.
/obj/item/organ/genitals/filling_organ/proc/get_reagent_capacity()
	var/capacity = get_base_capacity() * get_capacity_multiplier()
	if(has_oviposition_pregnancy())
		capacity *= 0.5
	else if(fertility && pregnant)
		// A hidden pregnancy takes room only as the belly grows, down to half when full term.
		capacity *= 1 - 0.5 * (conventional_pregnancy_stage / 3)
	for(var/obj/item/thing in contents)
		// Plugs and pumps sit in or over the opening, so they take no room inside.
		if(thing.type != /obj/item/dildo/plug && !istype(thing, /obj/item/reagent_containers/glass/fluid_pump))
			capacity -= thing.w_class * 10
	return max(0, capacity)

/obj/item/organ/genitals/filling_organ/proc/spill_reagents(amount)
	if(!reagents || amount <= 0)
		return 0
	var/turf/ownerloc = get_turf(owner)
	if(!ownerloc)
		return 0
	var/spill_amount = min(reagents.total_volume, amount)
	ownerloc.add_liquid_from_reagents(reagents, amount = spill_amount)
	reagents.remove_all(spill_amount)
	return spill_amount

/obj/item/organ/genitals/filling_organ/proc/spill_excess_reagents()
	if(!reagents)
		return 0
	var/captarget = get_reagent_capacity()
	if(captarget != reagents.maximum_volume)
		reagents.maximum_volume = captarget
	var/excess_amount = reagents.total_volume - captarget
	if(excess_amount <= 0)
		return 0
	return spill_reagents(excess_amount)

/// Drips `amount` units of our reagents onto `target`, as drops for organs flagged [drips_as_drops].
/obj/item/organ/genitals/filling_organ/proc/drip_to_turf(turf/target, amount)
	spill_fluid_to_turf(target, reagents, amount, drips_as_drops && !owner?.has_quirk(/datum/quirk/peculiarity/free_flowing))

/// Spills fluid onto a turf: small amounts form a colored drop that grows into a puddle, larger ones pool at once.
/proc/spill_fluid_to_turf(turf/target, datum/reagents/source, amount, as_drops = TRUE)
	if(!target || !source || amount <= 0)
		return
	amount = min(amount, source.total_volume)
	if(amount <= 0)
		return

	if(!as_drops || amount > LIQUID_DRIP_MAX_UNITS)
		target.add_liquid_from_reagents(source, amount = amount)
		source.remove_all(amount)
		return

	var/obj/effect/decal/cleanable/liquid_drip/drop = locate() in target
	if(!drop)
		drop = new(target)
	drop.absorb_drip(source, amount)
	//once enough fluid has gathered in one spot, collapse the drop into a real liquid puddle.
	if(drop.reagents?.total_volume > LIQUID_DRIP_MAX_UNITS)
		target.add_liquid_from_reagents(drop.reagents, amount = drop.reagents.total_volume)
		qdel(drop)

/obj/item/organ/genitals/filling_organ/on_life(delta_time, times_fired, in_bleedout, virus_immunity, antibiotics, immunity_weakness, passed_temp)
	. = ..()
	if(!owner || !reagents)
		return
	process_fluids(delta_time)

/// One fluid tick: capacity and production every tick, leaking and absorbing on the slower flow interval.
/obj/item/organ/genitals/filling_organ/proc/process_fluids(seconds)
	update_reagent_capacity()
	handle_overflow()
	produce_fluid(seconds)
	stamp_own_fluids()
	handle_bloat()
	update_engorgement()
	check_conception()
	if(!COOLDOWN_FINISHED(src, liquidcd))
		return
	COOLDOWN_START(src, liquidcd, processspeed)
	absorb_foreign_reagents()
	if(length(contents))
		exchange_with_stored_containers()
	else if(!HAS_TRAIT(src, TRAIT_PASSIVE_LEAK_BLOCKED))
		leak_reagents()

/// Whether the organ makes fluid now: its base setting, forced or blocked by the owner's fluid modifiers.
/obj/item/organ/genitals/filling_organ/proc/is_producing()
	if(!get_produced_reagent())
		return FALSE
	var/forced = FALSE
	for(var/datum/fluid_modifier/modifier as anything in owner?.get_fluid_modifiers(src))
		if(modifier.blocks_production)
			return FALSE
		if(modifier.forces_production)
			forced = TRUE
	return produces_fluid || forced

/obj/item/organ/genitals/filling_organ/proc/get_production_multiplier()
	. = 1
	for(var/datum/fluid_modifier/modifier as anything in owner?.get_fluid_modifiers(src))
		. *= modifier.rate_multiplier

/obj/item/organ/genitals/filling_organ/proc/get_capacity_multiplier()
	. = 1
	for(var/datum/fluid_modifier/modifier as anything in owner?.get_fluid_modifiers(src))
		. *= modifier.capacity_multiplier

/obj/item/organ/genitals/filling_organ/proc/get_nutrition_cost_multiplier()
	. = 1
	for(var/datum/fluid_modifier/modifier as anything in owner?.get_fluid_modifiers(src))
		. *= modifier.nutrition_cost_multiplier

/obj/item/organ/genitals/filling_organ/proc/get_leak_multiplier()
	. = 1
	for(var/datum/fluid_modifier/modifier as anything in owner?.get_fluid_modifiers(src))
		. *= modifier.leak_multiplier

/obj/item/organ/genitals/filling_organ/proc/get_climax_multiplier()
	. = 1
	for(var/datum/fluid_modifier/modifier as anything in owner?.get_fluid_modifiers(src))
		. *= modifier.climax_multiplier

/// Reagent the organ makes right now: an active swap, else its natural fluid.
/obj/item/organ/genitals/filling_organ/proc/get_produced_reagent()
	return LAZYACCESS(owner?.fluid_reagent_overrides, slot) || reagent_to_make

/// Reagent types that count as the organ's own: its natural fluid and any active swap.
/obj/item/organ/genitals/filling_organ/proc/get_own_fluid_types()
	var/datum/reagent/produced = get_produced_reagent()
	if(!produced)
		return null
	if(!reagent_to_make || produced == reagent_to_make)
		return list(produced)
	return list(reagent_to_make, produced)

/obj/item/organ/genitals/filling_organ/proc/is_own_fluid(datum/reagent/reagent_type)
	var/list/own_types = get_own_fluid_types()
	return own_types && (reagent_type in own_types)

/obj/item/organ/genitals/filling_organ/proc/get_own_fluid_amount()
	. = 0
	for(var/reagent_type in get_own_fluid_types())
		. += reagents.get_reagent_amount(reagent_type)

/// Share of capacity filled with the organ's own fluid, from 0 to 1.
/obj/item/organ/genitals/filling_organ/proc/get_own_fullness()
	if(!reagents?.maximum_volume)
		return 0
	return min(get_own_fluid_amount() / reagents.maximum_volume, 1)

/// Grows the sprite while full for owners with TRAIT_FLUID_ENGORGEMENT; redraws only when the step changes.
/obj/item/organ/genitals/filling_organ/proc/update_engorgement()
	var/target_steps = 0
	if(can_engorge && HAS_TRAIT(owner, TRAIT_FLUID_ENGORGEMENT))
		var/fullness = get_own_fullness()
		target_steps = get_engorgement_steps_for(fullness)
		if(target_steps < engorgement_steps && get_engorgement_steps_for(fullness + FLUID_ENGORGEMENT_HYSTERESIS) >= engorgement_steps)
			target_steps = engorgement_steps
	if(target_steps == engorgement_steps)
		return
	engorgement_steps = target_steps
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		carbon_owner.update_body_parts(TRUE)

/obj/item/organ/genitals/filling_organ/proc/get_engorgement_steps_for(fullness)
	if(fullness >= FLUID_ENGORGEMENT_STEP_3)
		return 3
	if(fullness >= FLUID_ENGORGEMENT_STEP_2)
		return 2
	if(fullness >= FLUID_ENGORGEMENT_STEP_1)
		return 1
	return 0

/// Size shown by sprites and examine text: organ_size plus engorgement, capped by the sprites that exist.
/obj/item/organ/genitals/filling_organ/proc/get_visible_size()
	if(!engorgement_steps)
		return organ_size
	var/datum/sprite_accessory/genitals/accessory = SPRITE_ACCESSORY(accessory_type)
	if(!istype(accessory))
		return organ_size
	return max(organ_size, min(organ_size + engorgement_steps, accessory.get_max_size_state(src, owner)))

/obj/item/organ/genitals/filling_organ/get_render_key_state()
	return get_visible_size()

/// Examine phrase for a visibly full organ, or null when it does not look full.
/obj/item/organ/genitals/filling_organ/proc/get_fullness_description()
	if(!reagents?.maximum_volume || !reagents.total_volume)
		return null
	var/fullness = reagents.total_volume / reagents.maximum_volume
	if(fullness < FLUID_LOOKS_FULL_RATIO)
		return null
	var/datum/reagent/main_fluid = reagents.get_master_reagent()
	var/fluid_name = LOWER_TEXT(main_fluid.name)
	if(fullness >= FLUID_LOOKS_BURSTING_RATIO)
		return "swollen near to bursting with [fluid_name]"
	return "heavy with [fluid_name]"

/// Units released at climax for a location, scaled by modifiers and fullness, capped by what is held and the space given.
/obj/item/organ/genitals/filling_organ/proc/get_climax_release(climax_location, space_limit = INFINITY)
	if(!reagents?.total_volume)
		return 0
	var/amount = get_base_climax_release(climax_location) * get_climax_multiplier() * get_pent_up_multiplier()
	amount = max(amount, min(1, reagents.total_volume))
	return max(0, min(amount, reagents.total_volume, space_limit))

/// Units released at climax before modifiers; a null location is a quick climax with no partner.
/obj/item/organ/genitals/filling_organ/proc/get_base_climax_release(climax_location)
	return 0

/obj/item/organ/genitals/filling_organ/proc/get_pent_up_multiplier()
	return 1

/obj/item/organ/genitals/filling_organ/proc/is_pent_up()
	return FALSE

/// Nutrition per unit made; a swapped fluid never costs less than it feeds, so drinking it cannot profit.
/obj/item/organ/genitals/filling_organ/proc/get_nutrition_cost_per_unit()
	var/cost = nutrition_per_unit
	var/datum/reagent/produced = get_produced_reagent()
	if(produced != reagent_to_make)
		var/datum/reagent/consumable/food = GLOB.chemical_reagents_list[produced]
		if(istype(food))
			cost = max(cost, food.nutriment_factor * FLUID_SWAP_NUTRITION_MARGIN)
	return cost * get_nutrition_cost_multiplier()

/obj/item/organ/genitals/filling_organ/proc/pay_for_fluid(amount)
	if(amount <= 0 || HAS_TRAIT(owner, TRAIT_NOHUNGER))
		return
	owner.adjust_nutrition(-amount * get_nutrition_cost_per_unit())

/// Adds own fluid up to the free space and returns the units actually added.
/obj/item/organ/genitals/filling_organ/proc/add_produced_fluid(amount)
	var/datum/reagent/produced = get_produced_reagent()
	if(!produced || !reagents)
		return 0
	amount = min(amount, reagents.maximum_volume - reagents.total_volume)
	if(amount <= 0)
		return 0
	reagents.add_reagent(produced, amount)
	return amount

/// Switches the produced reagent and converts the stored own fluid, keeping the holder and capacity.
/obj/item/organ/genitals/filling_organ/proc/set_reagent_to_make(datum/reagent/new_reagent)
	if(!new_reagent || new_reagent == reagent_to_make)
		return
	var/datum/reagent/old_reagent = reagent_to_make
	reagent_to_make = new_reagent
	var/own_fluid = reagents?.get_reagent_amount(old_reagent)
	if(own_fluid > 0)
		reagents.remove_reagent(old_reagent, own_fluid)
		reagents.add_reagent(new_reagent, own_fluid)

/// Applies the current capacity, alerting self-aware owners about large shifts.
/obj/item/organ/genitals/filling_organ/proc/update_reagent_capacity()
	var/capacity = get_reagent_capacity()
	var/change = abs(capacity - reagents.maximum_volume)
	if(!change)
		return
	reagents.maximum_volume = capacity
	if(change < FLUID_CAPACITY_ALERT_MIN_CHANGE || world.time <= last_size_alert + 12 SECONDS)
		return
	if(owner.has_quirk(/datum/quirk/peculiarity/selfawaregeni))
		last_size_alert = world.time
		to_chat(owner, span_blue("My [pick(altnames)] hold a different amount now."))

/// Applies bloat debuffs when bloatable and full of foreign fluid; own fluid never bloats.
/obj/item/organ/genitals/filling_organ/proc/handle_bloat()
	if(!bloatable) //we wont make removals because other organs may be conflicting and shit.
		return
	var/foreign_volume = reagents.total_volume - get_own_fluid_amount()
	if(foreign_volume > (reagents.maximum_volume / 3) && !owner.has_status_effect(/datum/status_effect/debuff/bloattwo)) //more than 1/3 full, light bloat.
		owner.apply_status_effect(/datum/status_effect/debuff/bloatone)
	if(foreign_volume > (reagents.maximum_volume / 2)) //more than half full, heavy bloat.
		owner.apply_status_effect(/datum/status_effect/debuff/bloattwo)

/// Spills reagents that no longer fit once the capacity has dropped below the stored volume.
/obj/item/organ/genitals/filling_organ/proc/handle_overflow()
	if(reagents.maximum_volume >= reagents.total_volume)
		return
	if(world.time > last_damagespill_alert + 30 SECONDS)
		last_damagespill_alert = world.time
		owner.visible_message(span_info("[owner]'s [pick(altnames)] can not hold all of the liquids in anymore and spill some of it's contents!"), span_info("My [pick(altnames)] can not hold all of the liquids in anymore and spill some of it's contents!!"), span_unconscious("I hear a splash."))
	var/overflow_amount = reagents.total_volume - reagents.maximum_volume
	var/spill_amount = min(reagents.total_volume, overflow_amount + 15)
	spill_reagents(spill_amount)

/// Nutrition-driven production; a hungry owner reabsorbs fluid instead. Subtypes replace the drive.
/obj/item/organ/genitals/filling_organ/proc/produce_fluid(seconds)
	if(HAS_TRAIT(owner, TRAIT_NOHUNGER))
		if(is_producing())
			add_produced_fluid(production_rate * get_nourishment_multiplier() * get_production_multiplier() * seconds)
		return
	if(owner.nutrition < FLUID_HUNGER_NUTRITION)
		if(hungerhelp)
			reabsorb_for_nutrition(seconds)
		return
	if(!is_producing())
		return
	var/amount = production_rate * get_production_multiplier() * get_nourishment_multiplier() * seconds
	if(amount > 0)
		pay_for_fluid(add_produced_fluid(amount))

/// Production speed from how fed the owner is: none when hungry, full when well fed, faster beyond.
/obj/item/organ/genitals/filling_organ/proc/get_nourishment_multiplier()
	if(HAS_TRAIT(owner, TRAIT_NOHUNGER) || owner.nutrition > NUTRITION_LEVEL_WELL_FED)
		return FLUID_WELL_FED_MULTIPLIER
	return clamp((owner.nutrition - NUTRITION_LEVEL_HUNGRY) / (NUTRITION_LEVEL_WELL_FED - NUTRITION_LEVEL_HUNGRY), 0, 1)

/// Turns this organ's own fluid back into nutrition, at a loss.
/obj/item/organ/genitals/filling_organ/proc/reabsorb_for_nutrition(seconds)
	var/own_fluid = reagents.get_reagent_amount(reagent_to_make)
	var/nutrition_gain = min(production_rate * seconds, own_fluid / FLUID_REABSORB_COST)
	if(nutrition_gain <= 0)
		return
	reagents.remove_reagent(reagent_to_make, nutrition_gain * FLUID_REABSORB_COST)
	owner.adjust_nutrition(nutrition_gain)

/// Moves foreign reagents into the owner's blood; the organ keeps its own fluid.
/obj/item/organ/genitals/filling_organ/proc/absorb_foreign_reagents()
	if(!absorbing || !reagents.total_volume)
		return
	reagents.trans_to(owner, absorbrate, absorbmult, TRUE, FALSE, ignored_reagents = get_own_fluid_types())

/// Whether stored open containers get refilled from this organ.
/obj/item/organ/genitals/filling_organ/proc/refills_stored_containers()
	return is_producing()

/// Stored open containers pour into the organ, and a producing organ refills them.
/obj/item/organ/genitals/filling_organ/proc/exchange_with_stored_containers()
	var/producing = refills_stored_containers()
	for(var/obj/item/reagent_containers/container in contents)
		// A pump draws on its own; exchanging would pour its catch back in.
		if(!container.reagents || !container.spillable || istype(container, /obj/item/reagent_containers/glass/fluid_pump))
			continue
		if(container.reagents.total_volume)
			container.reagents.trans_to(reagents, rand(4, 8))
		if(producing && reagents.total_volume)
			reagents.trans_to(container, rand(4, 8))

/// Leaks fluid into covering clothes first; a bare opening drips into a container underneath or onto the floor.
/obj/item/organ/genitals/filling_organ/proc/leak_reagents(forced_amount)
	if(!reagents.total_volume)
		return
	var/leak_amount = forced_amount || get_leak_amount() || try_letdown()
	if(leak_amount <= 0)
		return
	var/obj/item/reagent_containers/glass/fluid_pump/pump = get_leak_pump()
	if(pump)
		reagents.trans_to(pump, leak_amount, transfered_by = owner)
		return
	var/list/covers = get_opening_covers()
	if(length(covers))
		leak_amount = soak_into_covers(covers, leak_amount)
		if(leak_amount <= 0)
			return
	else
		var/obj/item/reagent_containers/collector = find_leak_collector()
		if(collector)
			reagents.trans_to(collector, leak_amount * FLUID_COLLECTOR_LEAK_MULTIPLIER)
			if(MOBTIMER_FINISHED(owner, "organ_drip", rand(20, 120)))
				MOBTIMER_SET(owner, "organ_drip")
				to_chat(owner, span_info("I collect the fluids dripping from me in \the [collector]."))
			return
		leak_amount = cling_to_skin(leak_amount)
		if(leak_amount <= 0)
			return
	if(prob(5) && owner.has_quirk(/datum/quirk/peculiarity/selfawaregeni) && MOBTIMER_FINISHED(owner, "organ_drip", rand(20, 120)))
		MOBTIMER_SET(owner, "organ_drip")
		to_chat(owner, pick(span_info("A little bit of [english_list(reagents.reagent_list)] drips from my [pick(altnames)]..."),
			span_info("Some liquid drips from my [pick(altnames)]."),
			span_info("My [pick(altnames)] spills some liquid."),
			span_info("Some [english_list(reagents.reagent_list)] drips from my [pick(altnames)].")))
	leave_fluid_scent(get_turf(owner), owner, get_fluid_scent_kind(reagents.get_master_reagent()))
	drip_to_turf(get_turf(owner), leak_amount)

/// Units leaked per flow interval: spillers and overfull organs push harder as they fill.
/obj/item/organ/genitals/filling_organ/proc/get_leak_amount()
	var/fullness = reagents.maximum_volume ? (reagents.total_volume / reagents.maximum_volume) : 0
	if(!spiller && fullness <= 1)
		return 0
	var/pressure = clamp((fullness - DRIP_PRESSURE_THRESHOLD) / (1 - DRIP_PRESSURE_THRESHOLD), 0, 1)
	return driprate * (1 + (pressure * (DRIP_PRESSURE_MAX_MULT - 1))) * get_leak_multiplier() * get_retention_multiplier()

/// A completely full leaky organ lets down a small burst now and then, so clothes get damp but dry off between.
/obj/item/organ/genitals/filling_organ/proc/try_letdown()
	if(!leaks_when_full || reagents.total_volume < reagents.maximum_volume * FLUID_LETDOWN_FULL_RATIO)
		return 0
	if(!COOLDOWN_FINISHED(src, letdown_cooldown))
		return 0
	COOLDOWN_START(src, letdown_cooldown, rand(FLUID_LETDOWN_MIN_INTERVAL, FLUID_LETDOWN_MAX_INTERVAL))
	return FLUID_LETDOWN_AMOUNT * get_leak_multiplier()

/// A pump with room over this organ's opening; testicles leak through the penis, so its pump counts.
/obj/item/organ/genitals/filling_organ/proc/get_leak_pump()
	var/obj/item/organ/opening = slot == ORGAN_SLOT_TESTICLES ? owner?.getorganslot(ORGAN_SLOT_PENIS) : src
	if(!opening)
		return null
	var/obj/item/reagent_containers/glass/fluid_pump/pump = locate() in opening.contents
	if(!pump || pump.reagents.holder_full())
		return null
	return pump

/// Worn garments without genital access over the opening, innermost first.
/obj/item/organ/genitals/filling_organ/proc/get_opening_covers()
	if(!iscarbon(owner))
		return null
	var/mob/living/carbon/carbon_owner = owner
	var/list/covers = list()
	if(additional_blocker == "bra")
		covers += carbon_owner.bra
		if(carbon_owner.underwear?.covers_breasts)
			covers += carbon_owner.underwear
	else if(additional_blocker)
		covers += carbon_owner.underwear
	covers += carbon_owner.mob_slot_wearing(blocker)
	for(var/obj/item/clothing/cover as anything in covers.Copy())
		if(!istype(cover) || cover.genital_access)
			covers -= cover
	return covers

/// Soaks leaked fluid into the covers from the inside out and returns what drips through them all.
/obj/item/organ/genitals/filling_organ/proc/soak_into_covers(list/covers, amount)
	var/obj/item/clothing/outermost
	for(var/obj/item/clothing/cover as anything in covers)
		// A cover that does not soak holds the fluid in.
		if(!cover.can_soak_fluid())
			return 0
		amount -= cover.soak_fluid(reagents, amount, stain_zone)
		if(amount <= 0)
			return 0
		outermost = cover
	if(iscarbon(owner))
		outermost?.apply_wet_stress(owner)
	return amount

/// Finds a refillable container under a standing owner to catch leaks.
/obj/item/organ/genitals/filling_organ/proc/find_leak_collector()
	if(!(owner.mobility_flags & MOBILITY_STAND))
		return null
	for(var/obj/item/reagent_containers/container in owner.loc)
		if(!container.reagents || container.reagents.total_volume >= container.reagents.maximum_volume)
			continue
		if(container.reagents.flags & REFILLABLE)
			return container
	return null

/obj/item/organ/genitals/filling_organ/proc/organ_jumped()
	var/mob/living/carbon/human/H = owner

	var/stealth = GET_MOB_SKILL_VALUE_OLD(H, /datum/attribute/skill/misc/sneaking)
	var/keepinsidechance = CLAMP((rand(25,100) - (stealth * 20)),0,100) //basically cant lose your item if you have 5 stealth.
	if(reagents.total_volume > reagents.maximum_volume / 2 && spiller && prob(keepinsidechance)) //if you have more than half full spiller organ.
		owner.visible_message(span_info("[owner]'s [pick(altnames)] spill some of it's contents with the pressure on it!"),span_info("My [pick(altnames)] spill some of it's contents with the pressure on it! [keepinsidechance]%"),span_unconscious("I hear a splash."))
		var/turf/ownerloc = get_turf(owner)
		if(ownerloc)
			ownerloc.add_liquid_from_reagents(reagents, amount = reagents.maximum_volume/3)
			reagents.remove_all(reagents.maximum_volume/3)
			playsound(owner, 'sound/foley/waterenter.ogg', 15)

	if(!isanimal(H) && H.mind)
		if(length(contents))
			for(var/obj/item/organ_stored_item as anything in contents)
				if(istype(organ_stored_item, /obj/item/dildo)) //dildo keeps stuff in even if you have no pants ig
					return

			var/obj/item/clothing/blockingitem = get_organ_blocker(H, zone)
			if(!blockingitem || blockingitem.genital_access) //checks if the item has genital_access, like skirts, if not, it blocks the thing from flying off.
				return

			if(prob(keepinsidechance))
				var/obj/item/rand_item = SEND_SIGNAL(src, COMSIG_BODYSTORAGE_REMOVE_RAND_ITEM, STORAGE_LAYER_INNER)
				if(!rand_item)
					return
				if(H.client?.prefs?.read_preference(/datum/preference/toggle/showrolls))
					to_chat(H, span_alert("Damn! I lose my [pick(altnames)]'s grip on [rand_item]! [keepinsidechance]%"))
				else
					to_chat(H, span_alert("Damn! I lose my [pick(altnames)]'s grip on [rand_item]!"))
				playsound(H, 'sound/misc/mat/insert (1).ogg', 20, TRUE, -2, ignore_walls = FALSE)

				rand_item.doMove(get_turf(H))
				var/yeet = rand(4)
				var/turf/selectedturf = pick(orange(H, yeet)) //object flies off the hole with pressure at a random turf, funny.
				rand_item.throw_at(selectedturf, yeet, 2)
			else
				if(H.client?.prefs?.read_preference(/datum/preference/toggle/showrolls))
					if(keepinsidechance < 10)
						to_chat(H, span_blue("I easily maintain my [pick(altnames)]'s grip on it's contents. [keepinsidechance]%"))
					else
						to_chat(H, span_info("Phew, I maintain my [pick(altnames)]'s grip on it's contents. [keepinsidechance]%"))
				else
					if(keepinsidechance < 10)
						to_chat(H, span_blue("I easily maintain my [pick(altnames)]'s grip on it's contents."))
					else
						to_chat(H, span_info("Phew, I maintain my [pick(altnames)]'s grip on it's contents."))

/obj/item/organ/proc/supports_oviposition_pregnancy()
	return allows_oviposition_pregnancy && oviposition_storage_component_type

/obj/item/organ/proc/get_oviposition_storage()
	if(!supports_oviposition_pregnancy())
		return null
	return GetComponent(oviposition_storage_component_type)

/obj/item/organ/proc/get_oviposition_location_name()
	if(oviposition_location_name)
		return oviposition_location_name
	return name

/obj/item/organ/proc/get_oviposition_lay_verb()
	return oviposition_lay_verb

/obj/item/organ/proc/get_oviposition_lay_self_message()
	return "I [oviposition_lay_action] the ripe egg from my [get_oviposition_location_name()]!"

/obj/item/organ/proc/is_oviposition_egg(obj/item/oviposition_egg/egg)
	if(!egg)
		return FALSE

	var/datum/component/body_storage/storage = get_oviposition_storage()
	if(!storage)
		return FALSE

	return storage.check_item_in_layer(src, egg, STORAGE_LAYER_DEEP)

/obj/item/organ/proc/get_oviposition_eggs(include_growing = null)
	var/list/eggs = list()
	var/datum/component/body_storage/storage = get_oviposition_storage()
	if(!storage)
		return eggs

	for(var/obj/item/stored_item as anything in storage.deep_layer_contents)
		if(!istype(stored_item, /obj/item/oviposition_egg))
			continue
		var/obj/item/oviposition_egg/egg = stored_item
		var/growing = egg.has_pregnancy()
		if(isnull(include_growing) || include_growing == growing)
			eggs += egg

	return eggs

/obj/item/organ/proc/count_internal_hatching_eggs()
	var/count = 0
	for(var/obj/item/oviposition_egg/egg as anything in get_oviposition_eggs())
		if(egg.hatch_inside_host)
			count += 1
	return count

/obj/item/organ/proc/sanitize_internal_womb_holders()
	var/datum/component/body_storage/storage = get_oviposition_storage()
	if(!storage)
		return FALSE

	var/needs_bulk_recalculation = FALSE
	for(var/layer in storage.available_layers)
		if(!storage.available_layers[layer])
			continue
		var/list/layer_contents = storage.all_layers[layer]
		if(!islist(layer_contents))
			continue
		for(var/obj/item/stored_item as anything in layer_contents.Copy())
			if(QDELETED(stored_item) || stored_item.loc != src)
				layer_contents -= stored_item
				needs_bulk_recalculation = TRUE
				continue
			if(!istype(stored_item, /obj/item/mob_holder/internal_womb))
				continue
			var/obj/item/mob_holder/internal_womb/holder = stored_item
			if(holder.held_mob)
				continue
			layer_contents -= holder
			contents -= holder
			needs_bulk_recalculation = TRUE
			qdel(holder)

	for(var/obj/item/stored_item as anything in contents.Copy())
		if(QDELETED(stored_item) || stored_item.loc != src)
			contents -= stored_item
			needs_bulk_recalculation = TRUE
			continue
		if(!istype(stored_item, /obj/item/mob_holder/internal_womb))
			continue
		var/obj/item/mob_holder/internal_womb/holder = stored_item
		if(holder.held_mob)
			continue
		contents -= holder
		needs_bulk_recalculation = TRUE
		qdel(holder)

	if(needs_bulk_recalculation)
		storage.recalculate_current_bulk(src)
	return needs_bulk_recalculation

/obj/item/organ/proc/count_internal_womb_hatchlings()
	var/datum/component/body_storage/storage = get_oviposition_storage()
	if(!storage)
		return 0

	sanitize_internal_womb_holders()

	var/count = 0
	for(var/layer in storage.available_layers)
		if(!storage.available_layers[layer])
			continue
		var/list/layer_contents = storage.all_layers[layer]
		if(!islist(layer_contents))
			continue
		for(var/obj/item/stored_item as anything in layer_contents)
			if(istype(stored_item, /obj/item/mob_holder/internal_womb))
				count += 1
	return count

/obj/item/organ/proc/start_oviposition_egg_growth(obj/item/oviposition_egg/egg, mob/living/father = null, hatch_result_type = null, fertilized = FALSE, list/father_features = null, father_name = null)
	if(!owner)
		return FALSE
	if(!egg || !is_oviposition_egg(egg) || egg.has_pregnancy())
		return FALSE
	if(egg.requires_fertilization() && !fertilized && !father && !LAZYLEN(father_features))
		return FALSE
	if(!hatch_result_type)
		hatch_result_type = egg.get_hatch_result_type()

	var/mob/living/egg_mother = egg.get_oviposition_mother(owner)
	egg.AddComponent(/datum/component/pregnancy, egg_mother, father, hatch_result_type, fertilized, father_features, father_name)
	return TRUE

/obj/item/organ/proc/fertilize_oviposition_egg(mob/living/father = null, hatch_result_type = null, list/father_features = null, father_name = null)
	if(!owner)
		return null

	for(var/obj/item/oviposition_egg/egg as anything in get_oviposition_eggs(FALSE))
		if(!egg.requires_fertilization())
			continue
		if(start_oviposition_egg_growth(egg, father, hatch_result_type, TRUE, father_features, father_name))
			return egg

	return null

/obj/item/organ/proc/has_oviposition_pregnancy()
	for(var/obj/item/oviposition_egg/egg as anything in get_oviposition_eggs(TRUE))
		var/datum/component/pregnancy/pregnancy = egg.get_pregnancy_component()
		if(pregnancy && !pregnancy.laid)
			return TRUE
	return FALSE

/obj/item/organ/proc/has_conventional_pregnancy()
	return FALSE

/obj/item/organ/proc/can_attempt_impregnation(allow_embryo_pregnancy = FALSE)
	return FALSE

/obj/item/organ/proc/can_start_fertilization_embryo_pregnancy(allow_embryo_pregnancy = FALSE)
	return FALSE

/obj/item/organ/proc/try_start_fertilization_embryo_pregnancy(mob/living/father = null, allow_embryo_pregnancy = FALSE, hatch_result_type = null, list/father_features = null, father_name = null)
	return FALSE

/obj/item/organ/proc/be_impregnated(mob/living/father = null, allow_embryo_pregnancy = FALSE, embryo_hatch_result_type = null, list/father_features = null, father_name = null)
	return FALSE

/obj/item/organ/genitals/filling_organ/has_conventional_pregnancy()
	return allows_conventional_impregnation && pregnant

/obj/item/organ/genitals/filling_organ/can_attempt_impregnation(allow_embryo_pregnancy = FALSE)
	if(!fertility || !owner || owner.stat == DEAD)
		return FALSE
	if(supports_oviposition_pregnancy() && LAZYLEN(get_oviposition_eggs(FALSE)))
		return TRUE
	if(can_start_fertilization_embryo_pregnancy(allow_embryo_pregnancy))
		return TRUE
	return allows_conventional_impregnation && !pregnant

/obj/item/organ/genitals/filling_organ/be_impregnated(mob/living/father = null, allow_embryo_pregnancy = FALSE, embryo_hatch_result_type = null, list/father_features = null, father_name = null)
	if(!fertility || !owner || owner.stat == DEAD)
		return FALSE

	var/list/hosted_eggs = get_oviposition_eggs()
	if(length(hosted_eggs))
		var/obj/item/oviposition_egg/fertilized_egg = fertilize_oviposition_egg(father, null, father_features, father_name)
		if(fertilized_egg)
			hint_conception()
			return TRUE

		for(var/obj/item/oviposition_egg/egg as anything in hosted_eggs)
			if(!egg.requires_fertilization() && start_oviposition_egg_growth(egg, father, null, FALSE, father_features, father_name))
				return TRUE

	// Do not silently fall back to conventional pregnancy when a requested embryo implantation is birth-limited.
	if(allow_embryo_pregnancy && spawn_embryo_on_fertilization && supports_oviposition_pregnancy() && iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		if(!carbon_owner.can_receive_oviposition_implant(TRUE))
			return FALSE

	if(try_start_fertilization_embryo_pregnancy(father, allow_embryo_pregnancy, embryo_hatch_result_type, father_features, father_name))
		hint_conception()
		return TRUE

	if(!allows_conventional_impregnation || pregnant)
		return FALSE
	// Nothing announces it; signs come later, and a seed sachet can tell.
	pregnant = TRUE
	conventional_pregnancy_stage = 0
	start_hidden_pregnancy()
	conventional_pregnancy_timer = addtimer(CALLBACK(src, PROC_REF(advance_conventional_pregnancy)), 3 HOURS, TIMER_STOPPABLE)
	SEND_SIGNAL(src, COMSIG_BODYSTORAGE_CHANGED)
	return TRUE

/obj/item/organ/genitals/filling_organ/proc/clear_conventional_pregnancy()
	if(!pregnant)
		return

	if(conventional_pregnancy_timer)
		deltimer(conventional_pregnancy_timer)
		conventional_pregnancy_timer = null

	stop_pregnancy_signs()
	pregnant = FALSE
	conventional_pregnancy_stage = 0
	// Milk only lingers if the pregnancy had got far enough to start it.
	if(owner?.has_fluid_modifier(/datum/fluid_modifier/pregnancy_lactation, FLUID_SOURCE_PREGNANCY))
		end_pregnancy_lactation()
	update_reagent_capacity()
	to_chat(owner, span_love("I feel my [src] shrink to how it was before. Pregnancy is no more."))
	SEND_SIGNAL(src, COMSIG_BODYSTORAGE_CHANGED)

/obj/item/organ/genitals/filling_organ/proc/start_pregnancy_lactation()
	owner?.add_fluid_modifier(/datum/fluid_modifier/pregnancy_lactation, FLUID_SOURCE_PREGNANCY)

/// Milk keeps flowing for a while after the pregnancy ends.
/obj/item/organ/genitals/filling_organ/proc/end_pregnancy_lactation()
	if(!owner)
		return
	owner.remove_fluid_modifier(/datum/fluid_modifier/pregnancy_lactation, FLUID_SOURCE_PREGNANCY)
	owner.add_fluid_modifier(/datum/fluid_modifier/pregnancy_lactation, FLUID_SOURCE_POST_PREGNANCY)
	addtimer(CALLBACK(owner, TYPE_PROC_REF(/mob/living, remove_fluid_modifier), /datum/fluid_modifier/pregnancy_lactation, FLUID_SOURCE_POST_PREGNANCY), POST_PREGNANCY_LACTATION_TIME, TIMER_UNIQUE|TIMER_OVERRIDE)

/obj/item/organ/genitals/filling_organ/proc/advance_conventional_pregnancy()
	if(!pregnant || !owner)
		conventional_pregnancy_timer = null
		return

	if(conventional_pregnancy_stage < 3 && prob(30))
		advance_pregnancy_stage()

	if(conventional_pregnancy_stage < 3)
		conventional_pregnancy_timer = addtimer(CALLBACK(src, PROC_REF(advance_conventional_pregnancy)), 6 HOURS, TIMER_STOPPABLE)
	else
		conventional_pregnancy_timer = null

/obj/item/organ/genitals/filling_organ/can_start_fertilization_embryo_pregnancy(allow_embryo_pregnancy = FALSE)
	if(!fertility || !owner || owner.stat == DEAD)
		return FALSE
	if(!allow_embryo_pregnancy || !spawn_embryo_on_fertilization || !supports_oviposition_pregnancy())
		return FALSE
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		if(!carbon_owner.can_receive_oviposition_implant())
			return FALSE
	if(pregnant)
		return FALSE
	if(fertilization_embryo_limit <= 0)
		return FALSE
	return (count_internal_hatching_eggs() + count_internal_womb_hatchlings()) < fertilization_embryo_limit

/obj/item/organ/genitals/filling_organ/try_start_fertilization_embryo_pregnancy(mob/living/father = null, allow_embryo_pregnancy = FALSE, hatch_result_type = null, list/father_features = null, father_name = null)
	if(!can_start_fertilization_embryo_pregnancy(allow_embryo_pregnancy))
		return FALSE

	var/embryo_hatch_result_type = hatch_result_type || fertilization_embryo_hatch_result_type
	if(!embryo_hatch_result_type && father)
		embryo_hatch_result_type = get_oviposition_parent_hatch_result_type(father)
	if(!embryo_hatch_result_type || !ispath(embryo_hatch_result_type, /mob/living))
		return FALSE

	var/obj/item/oviposition_egg/embryo = new
	embryo.set_egg_type(fertilization_embryo_egg_type || OVI_EGG_EMBRYO)
	embryo.set_oviposition_mother(owner)

	var/fit_result = SEND_SIGNAL(src, COMSIG_BODYSTORAGE_TRY_INSERT, embryo, STORAGE_LAYER_DEEP)
	switch(fit_result)
		if(INSERT_FEEDBACK_OK, INSERT_FEEDBACK_OK_FORCE, INSERT_FEEDBACK_OK_OVERRIDE, INSERT_FEEDBACK_ALMOST_FULL)
			if(start_oviposition_egg_growth(embryo, father, embryo_hatch_result_type, TRUE, father_features, father_name))
				return TRUE

	SEND_SIGNAL(src, COMSIG_BODYSTORAGE_TRY_REMOVE, embryo, STORAGE_LAYER_DEEP, BODYSTORAGE_REMOVE_INTERNAL)
	qdel(embryo)
	return FALSE

//had to make this ghetto ass shit, fucks sake
/mob/living/carbon/proc/mob_slot_wearing(zone)
	if(iscarbon(src))
		var/mob/living/carbon/human/H = src
		for(var/obj/item/clothing/equipped_item in H.get_equipped_items(include_pockets = FALSE))
			if(equipped_item.slot_flags & zone)
				return equipped_item
			else
				continue

/obj/item/organ/proc/get_stretched(datum/source, diff)
	return

/obj/item/organ/genitals/filling_organ/get_stretched(diff)
	if(!istype(src, /obj/item/organ/genitals/filling_organ) && !stretchable)
		return
	var/mob/living/carbon/human/H = owner
	var/datum/component/arousal/aro = owner.GetComponent(/datum/component/arousal)
	switch(diff)
		if(1 to 3)
			stretched_coefficient += 0.05
			to_chat(owner, span_love("My [pick(src.altnames)] is getting stretched..."))
		if(3 to 5)
			stretched_coefficient += 0.1
			to_chat(owner, span_alert("This stretching is hurting my [pick(src.altnames)]!"))
			aro.try_do_pain_effect(PAIN_MED_EFFECT, FALSE)
		if(5 to INFINITY)
			stretched_coefficient += 0.5
			to_chat(owner, span_love("AHH, GET IT ALL OUT OF MY [capitalize(pick(src.altnames))]!"))
			aro.try_do_pain_effect(PAIN_HIGH_EFFECT, FALSE)
	if(stretched_coefficient > 3)
		H.Immobilize(20)
		//try increase organ size (code later)
	stretched_coefficient = CLAMP(stretched_coefficient, 1, 3)
	SEND_SIGNAL(src, COMSIG_BODYSTORAGE_UPDATE_SIZE)

/// A small puddle's worth of dripped fluid. Uses greyscale drop sprites tinted to whatever liquid it holds.
/obj/effect/decal/cleanable/liquid_drip
	name = "drips of liquid"
	desc = ""
	icon = 'modular_rmh/icons/obj/genitals/effects.dmi'
	icon_state = "drip1"
	random_icon_states = list("drip1", "drip2", "drip3", "drip4", "drip5")
	alpha = 200
	/// Once the drop is ~halfway to becoming a puddle it swaps to a larger "fem" splatter sprite, chosen once.
	var/grown_to_fem = FALSE

/obj/effect/decal/cleanable/liquid_drip/Initialize(mapload)
	. = ..()
	if(. == INITIALIZE_HINT_QDEL)
		return .
	pixel_x = base_pixel_x + rand(-5, 5)
	pixel_y = base_pixel_y + rand(-3, 3)

/// Pulls `amount` units out of `source` into our reagents, then tints to match the held fluid and mirrors its
/// translucency. Sprites are greyscale so a plain colour multiply reproduces the fluid colour faithfully; colour must
/// go through add_atom_colour or the atom-colour priority system overwrites a direct `color =` on the next update.
/obj/effect/decal/cleanable/liquid_drip/proc/absorb_drip(datum/reagents/source, amount)
	if(source && amount > 0 && reagents)
		source.trans_to(src, amount)
	if(!reagents?.total_volume)
		return
	add_atom_colour(mix_color_from_reagents(reagents.reagent_list), FIXED_COLOUR_PRIORITY)
	// translucent liquids leave translucent drops: route the fluid's opacity to our alpha.
	alpha = get_mixed_opacity()
	// halfway to a puddle: grow into a larger, random "fem" splatter.
	if(!grown_to_fem && reagents.total_volume >= (LIQUID_DRIP_MAX_UNITS * 0.5))
		grown_to_fem = TRUE
		icon = 'modular_rmh/icons/obj/genitals/cum_effects.dmi'
		icon_state = "fem[rand(1, 10)]"

/// Volume-weighted average opacity (0-255) of our held reagents. For a single fluid this is just its own opacity,
/// so a pure femcum/cum drop takes that reagent's opacity 1:1. (The liquid-turf formula's +1/max floors distort
/// the sub-unit volumes a drip deals in, so we use a straight weighted average instead.)
/obj/effect/decal/cleanable/liquid_drip/proc/get_mixed_opacity()
	if(!reagents?.total_volume)
		return alpha
	var/weighted_opacity = 0
	for(var/datum/reagent/reagent as anything in reagents.reagent_list)
		weighted_opacity += reagent.opacity * reagent.volume
	return clamp(round(weighted_opacity / reagents.total_volume), 0, 255)

#undef LIQUID_DRIP_MAX_UNITS
#undef DRIP_PRESSURE_THRESHOLD
#undef DRIP_PRESSURE_MAX_MULT
#undef FLUID_HUNGER_NUTRITION
#undef FLUID_WELL_FED_MULTIPLIER
#undef FLUID_REABSORB_COST
#undef FLUID_CAPACITY_ALERT_MIN_CHANGE
#undef FLUID_COLLECTOR_LEAK_MULTIPLIER
#undef FLUID_ENGORGEMENT_HYSTERESIS
#undef FLUID_LOOKS_FULL_RATIO
#undef FLUID_LOOKS_BURSTING_RATIO
#undef FLUID_LETDOWN_FULL_RATIO
#undef FLUID_LETDOWN_AMOUNT
#undef FLUID_LETDOWN_MIN_INTERVAL
#undef FLUID_LETDOWN_MAX_INTERVAL
