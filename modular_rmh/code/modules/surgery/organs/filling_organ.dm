//By Vide Noir https://github.com/EaglePhntm.

/// Dribbles at or below this many units form a drop decal; once a drop gathers more than this it becomes a real puddle.
#define LIQUID_DRIP_MAX_UNITS 5
/// Fill ratio at which a full organ starts leaking faster; below this the drip rate is unchanged.
#define DRIP_PRESSURE_THRESHOLD 0.6
/// Drip rate multiplier reached (and capped at) when the organ is full or overfull.
#define DRIP_PRESSURE_MAX_MULT 6

//container organ that can refill self through nutrients etc.
/obj/item/organ/genitals/filling_organ
	name = "self filling organ"

	//faster healing cause those will be rippin alot
	healing_factor = STANDARD_ORGAN_HEALING*3
	decay_factor = STANDARD_ORGAN_DECAY

	//self generating liquid stuff, dont use with absorbing stuff
	var/storage_per_size = 100 //added per organ size
	var/datum/reagent/reagent_to_make = /datum/reagent/consumable/nutriment //naturally generated reagent
	var/refilling = FALSE //slowly refills when not hungry
	var/reagent_generate_rate = 3 //with refilling
	var/hungerhelp = FALSE //if refilling, absorbs reagent_to_make as nutrients if hungry. Conversion is to nutrients direct even if you brew poison in there.
	var/uses_nutrient = TRUE //incase someone for some reason wanna make an OP paradox i guess.
	var/organ_sizeable = FALSE //if organ can be resized in prefs etc, SET THIS RIGHT, IT'S IMPORTANT.
	var/max_reagents = 30 //use if organ not sizeable, it auto calculates with sizeable organs and uses it as a base.
	var/startsfilled = FALSE

	//absorbing etc content liquid stuff, non self generated.
	var/absorbing = FALSE //absorbs liquids within slowly. Wont absorb reagent_to_make type, refilling and hungerhelp are irrelevant to this.
	var/absorbrate = 1 //refilling and hungerhelp are irrelevant to this, each life tick. NO LESS THAN 1 DIGESTS RIGHT.
	var/absorbmult = 1 //free gains
	var/driprate = 0.2
	var/spiller = FALSE //toggles if it will spill its stored_items when not plugged.
	var/blocker = ITEM_SLOT_SHIRT //pick an item slot
	var/additional_blocker
	var/max_femcum = 0
	var/processspeed = 5 SECONDS//will apply the said seconds cooldown each time before any spill or absorb happens.
	var/bloatable = FALSE //will it give bloat debuffs when filled, not good to use with refilling organs.

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

	COOLDOWN_DECLARE(liquidcd)

/obj/item/organ
	var/allows_oviposition_pregnancy = FALSE
	var/oviposition_storage_component_type = null
	var/oviposition_location_name = null
	var/oviposition_lay_verb = "lays"
	var/oviposition_lay_action = "lay"

/obj/item/organ/guts
	// Oral storage lives on guts, but oviposition messaging should read as stomach-based.
	allows_oviposition_pregnancy = TRUE
	oviposition_storage_component_type = /datum/component/body_storage/mouth
	oviposition_location_name = "stomach"
	oviposition_lay_verb = "coughs up"
	oviposition_lay_action = "cough up"

/obj/item/organ/genitals/filling_organ/Insert(mob/living/M, special, drop_if_replaced, new_zone = null) //update size cap n shit on insert
	. = ..()
	if(!.)
		return FALSE
	if(organ_sizeable)
		max_reagents = storage_per_size + (storage_per_size * organ_size)
	create_reagents(max_reagents)
	if(!refilling && M.mind) //mind check so goblins etc have milk on spawn.
		startsfilled = FALSE
	if(special && startsfilled) // won't fill the organ if you insert this organ via surgery
		reagents.add_reagent(reagent_to_make, reagents.maximum_volume)

/obj/item/organ/genitals/filling_organ/on_reagent_change(changetype)
	. = ..()
	if(slot == ORGAN_SLOT_ANUS || slot == ORGAN_SLOT_VAGINA)
		SEND_SIGNAL(src, COMSIG_BODYSTORAGE_CHANGED)

/obj/item/organ/genitals/filling_organ/on_body_storage_inserted(obj/item/inserted_item, target_layer)
	. = ..()
	if(target_layer == STORAGE_LAYER_OUTER || !inserted_item || !reagents?.total_volume)
		return
	spill_excess_reagents()

/obj/item/organ/genitals/filling_organ/proc/get_reagent_capacity()
	var/captarget
	if(organ_sizeable)
		captarget = storage_per_size + (storage_per_size * organ_size)
	else
		captarget = max_reagents
	if(fertility && pregnant)
		captarget *= 0.5
	else if(has_oviposition_pregnancy())
		captarget *= 0.5
	if(length(contents))
		for(var/obj/item/thing as anything in contents)
			if(thing.type != /obj/item/dildo/plug) //plugs wont take space as they are especially for this.
				captarget -= thing.w_class * 10
	return max(0, captarget)

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

/// Drips `amount` units of our reagents onto `target`. For organs flagged [drips_as_drops], small dribbles form a
/// colored drop decal that grows and eventually pools into a real puddle; everything else pools immediately.
/obj/item/organ/genitals/filling_organ/proc/drip_to_turf(turf/target, amount)
	if(!target || !reagents || amount <= 0)
		return
	amount = min(amount, reagents.total_volume)
	if(amount <= 0)
		return

	//big dribble, a non-dropping organ, or an owner whose quirk forces raw puddles: pool as liquid, skipping the decal.
	if(!drips_as_drops || amount > LIQUID_DRIP_MAX_UNITS || owner?.has_quirk(/datum/quirk/peculiarity/free_flowing))
		target.add_liquid_from_reagents(reagents, amount = amount)
		reagents.remove_all(amount)
		return

	var/obj/effect/decal/cleanable/liquid_drip/drop = locate() in target
	if(!drop)
		drop = new(target)
	drop.absorb_drip(reagents, amount)
	//once enough fluid has gathered in one spot, collapse the drop into a real liquid puddle.
	if(drop.reagents?.total_volume > LIQUID_DRIP_MAX_UNITS)
		target.add_liquid_from_reagents(drop.reagents, amount = drop.reagents.total_volume)
		qdel(drop)

/obj/item/organ/genitals/filling_organ/on_life()
	var/mob/living/carbon/human/H = owner

	..()

	//get arousal data
	var/list/arousal_data = list()
	SEND_SIGNAL(H, COMSIG_SEX_GET_AROUSAL, arousal_data)

	update_reagent_capacity(H)
	handle_bloat()
	handle_overflow()
	regenerate_reagents(H, arousal_data)

	if(!COOLDOWN_FINISHED(src, liquidcd))
		return
	if(reagents.total_volume && absorbing) //slowly inject to your blood if they have reagents. Will not work if refilling because i cant properly seperate the reagents for which to keep which to dump.
		reagents.trans_to(owner, absorbrate, absorbmult, TRUE, FALSE)
	if(!length(contents)) //if nothing is plugging the hole, stuff will drip out.
		var/tempdriprate = driprate
		//the fuller the organ, the faster it leaks: ramps from base rate at DRIP_PRESSURE_THRESHOLD up to DRIP_PRESSURE_MAX_MULT when full.
		var/fullness = reagents.maximum_volume ? (reagents.total_volume / reagents.maximum_volume) : 0
		var/pressure = clamp((fullness - DRIP_PRESSURE_THRESHOLD) / (1 - DRIP_PRESSURE_THRESHOLD), 0, 1)
		tempdriprate *= 1 + (pressure * (DRIP_PRESSURE_MAX_MULT - 1))
		if((reagents.total_volume && spiller) || (reagents.total_volume > reagents.maximum_volume)) //spiller or above it's capacity to leak.
			var/obj/item/clothing/blockingitem = H.mob_slot_wearing(blocker)
			if(!isnull(additional_blocker))
				if(H.underwear)
					blockingitem = H.underwear
			if(!(blockingitem && !blockingitem.genital_access)) //we drippin
				if(prob(5)) //with selfawaregeni quirk you got some chance to see what type of liquid is dripping from you.
					if(owner.has_quirk(/datum/quirk/peculiarity/selfawaregeni))
						if(!MOBTIMER_FINISHED(H, "organ_drip", rand(20,120)))
							return

						MOBTIMER_SET(H, "organ_drip")
						to_chat(H, pick(span_info("A little bit of [english_list(reagents.reagent_list)] drips from my [pick(altnames)]..."),
							span_info("Some liquid drips from my [pick(altnames)]."),
							span_info("My [pick(altnames)] spills some liquid."),
							span_info("Some [english_list(reagents.reagent_list)] drips from my [pick(altnames)].")))
				var/obj/item/reagent_containers/the_bottle
				if((owner.mobility_flags & MOBILITY_STAND))
					for(var/obj/item/reagent_containers/bottle in owner.loc) //having a bottle under us speed up leak greatly and transfer the leak there instead.
						if(bottle.reagents.total_volume >= bottle.reagents.maximum_volume)
							continue
						if(bottle.reagents.flags & REFILLABLE)
							the_bottle = bottle
							break
				if(!the_bottle) //no bottle so just spill
					var/turf/ownerloc = get_turf(owner)
					if(ownerloc)
						drip_to_turf(ownerloc, tempdriprate)
				else
					tempdriprate *= 50 //since default values are basically decimals.
					reagents.trans_to(the_bottle, min(tempdriprate))
					if(!MOBTIMER_FINISHED(H, "organ_drip", rand(20,120)))
						return

					MOBTIMER_SET(H, "organ_drip")
					to_chat(owner, span_info("I collect the fluids dripping from me in \the [the_bottle]."))
	else //we got something in contents
		for(var/obj/item/reagent_containers/contentitem in contents) //we got a bottle inside
			if(contentitem.reagents && contentitem.spillable)
				if(contentitem.reagents.total_volume) //stir the pot
					contentitem.reagents.trans_to(reagents, rand(4,8))
				if(refilling && reagents.total_volume)
					reagents.trans_to(contentitem, rand(4,8))

	COOLDOWN_START(src, liquidcd, processspeed)

/// Recalculates and applies the reagent capacity, alerting self-aware owners when it shifts.
/obj/item/organ/genitals/filling_organ/proc/update_reagent_capacity(mob/living/carbon/human/H)
	if(isanimal(H))
		return
	var/captarget = get_reagent_capacity()
	if(captarget == reagents.maximum_volume)
		return
	//so that vaginas don't spam messages
	if(reagents.has_reagent(/datum/reagent/consumable/femcum) && (reagents.get_reagent_amount(/datum/reagent/consumable/femcum) > captarget * 0.8))
		return
	reagents.maximum_volume = captarget
	if(H.has_quirk(/datum/quirk/peculiarity/selfawaregeni) && world.time > last_size_alert + 12 SECONDS)
		last_size_alert = world.time
		to_chat(H, span_blue("My [pick(altnames)] hold a different amount now."))

/// Applies bloat debuffs when bloatable and sufficiently full.
/obj/item/organ/genitals/filling_organ/proc/handle_bloat()
	if(!bloatable) //we wont make removals because other organs may be conflicting and shit.
		return
	if(reagents.total_volume > (reagents.maximum_volume / 3) && !owner.has_status_effect(/datum/status_effect/debuff/bloattwo)) //more than 1/3 full, light bloat.
		owner.apply_status_effect(/datum/status_effect/debuff/bloatone)
	if(reagents.total_volume > (reagents.maximum_volume / 2)) //more than half full, heavy bloat.
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

/// Generates or consumes the organ's reagent based on nutrition. Vagina overrides this for arousal-driven lube.
/obj/item/organ/genitals/filling_organ/proc/regenerate_reagents(mob/living/carbon/human/H, list/arousal_data)
	if(!HAS_TRAIT(src, TRAIT_NOHUNGER)) //if not nohunger
		if(owner.nutrition < (NUTRITION_LEVEL_HUNGRY - 25) && hungerhelp) //consumes if hungry and uses nutrient, putting below the limit so person dont get stress message spam.
			var/remove_amount = min(reagent_generate_rate, reagents.total_volume)
			if(uses_nutrient) //add nutrient
				owner.adjust_nutrition(remove_amount) //since hunger factor is so tiny compared to the nutrition levels it has to fill
			reagents.remove_reagent(reagent_to_make, (remove_amount * 4)) //we consume our own reagents for food less efficently, allowing running out (may undo this multiplier later.)
		else if((reagents.total_volume < reagents.maximum_volume) && refilling && owner.nutrition > (NUTRITION_LEVEL_FED + 25)) //if organ is not full.
			var/max_restore = owner.nutrition > (NUTRITION_LEVEL_WELL_FED) ? reagent_generate_rate * 2 : reagent_generate_rate
			var/restore_amount = min(max_restore, reagents.maximum_volume - reagents.total_volume) // amount restored if fed, capped by reagents.maximum_volume
			if(uses_nutrient) //consume nutrient
				owner.adjust_nutrition(-restore_amount)
			reagents.add_reagent(reagent_to_make, restore_amount)
	else //if nohunger, should just regenerate stuff for free no matter what, if refilling.
		if((reagents.total_volume < reagents.maximum_volume) && refilling)
			var/max_restore = reagent_generate_rate * 2
			var/restore_amount = min(max_restore, reagents.maximum_volume - reagents.total_volume)
			reagents.add_reagent(reagent_to_make, restore_amount)

/// Vagina generates lube from arousal instead of nutrition, and may grow oviposition eggs.
/obj/item/organ/genitals/filling_organ/vagina/regenerate_reagents(mob/living/carbon/human/H, list/arousal_data)
	refilling = (arousal_data["arousal"] > VISIBLE_AROUSAL_THRESHOLD)
	var/check_volume = 0
	if(reagent_to_make in reagents.reagent_list)
		check_volume = reagents.reagent_list[reagent_to_make].volume
	else
		check_volume = reagents.total_volume
	if((check_volume < max_femcum) && refilling)
		var/max_restore = reagent_generate_rate * 2
		var/restore_amount = min(max_restore, reagents.maximum_volume - max_femcum)
		reagents.add_reagent(reagent_to_make, restore_amount)
	try_generate_oviposition_egg()

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
				if(H.client?.prefs.showrolls)
					to_chat(H, span_alert("Damn! I lose my [pick(altnames)]'s grip on [rand_item]! [keepinsidechance]%"))
				else
					to_chat(H, span_alert("Damn! I lose my [pick(altnames)]'s grip on [rand_item]!"))
				playsound(H, 'sound/misc/mat/insert (1).ogg', 20, TRUE, -2, ignore_walls = FALSE)

				rand_item.doMove(get_turf(H))
				var/yeet = rand(4)
				var/turf/selectedturf = pick(orange(H, yeet)) //object flies off the hole with pressure at a random turf, funny.
				rand_item.throw_at(selectedturf, yeet, 2)
			else
				if(H.client?.prefs.showrolls)
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
			if(owner.has_quirk(/datum/quirk/peculiarity/selfawaregeni))
				to_chat(owner, span_love("A warm pulse runs through one of the eggs in my [get_oviposition_location_name()]."))
			else
				to_chat(owner, span_love("Something in my [get_oviposition_location_name()] has been fertilized."))
			return TRUE

		for(var/obj/item/oviposition_egg/egg as anything in hosted_eggs)
			if(!egg.requires_fertilization() && start_oviposition_egg_growth(egg, father, null, FALSE, father_features, father_name))
				return TRUE

	if(try_start_fertilization_embryo_pregnancy(father, allow_embryo_pregnancy, embryo_hatch_result_type, father_features, father_name))
		if(owner.has_quirk(/datum/quirk/peculiarity/selfawaregeni))
			to_chat(owner, span_love("Something fertile settles deep in my [get_oviposition_location_name()]."))
		else
			to_chat(owner, span_love("Something in my [get_oviposition_location_name()] has taken root."))
		return TRUE

	if(!allows_conventional_impregnation || pregnant)
		return FALSE
	to_chat(owner, span_love("I feel a surge of warmth in my [src.name], I'm definitely pregnant!"))
	owner.apply_status_effect(/datum/status_effect/debuff/impregnation)
	reagents.maximum_volume *= 0.5
	pregnant = TRUE
	conventional_pregnancy_stage = 0

	if(owner.getorganslot(ORGAN_SLOT_BREASTS))
		var/obj/item/organ/genitals/filling_organ/breasts/breasties = owner.getorganslot(ORGAN_SLOT_BREASTS)
		if(!breasties.refilling)
			breasties.refilling = TRUE
			to_chat(owner, span_love("I feel damp warmness on my nipples, I'm definitely leaking milk..."))
	conventional_pregnancy_timer = addtimer(CALLBACK(src, PROC_REF(advance_conventional_pregnancy)), 3 HOURS, TIMER_STOPPABLE)
	SEND_SIGNAL(src, COMSIG_BODYSTORAGE_CHANGED)
	return TRUE

/obj/item/organ/genitals/filling_organ/proc/clear_conventional_pregnancy()
	if(!pregnant)
		return

	if(conventional_pregnancy_timer)
		deltimer(conventional_pregnancy_timer)
		conventional_pregnancy_timer = null

	pregnant = FALSE
	conventional_pregnancy_stage = 0
	to_chat(owner, span_love("I feel my [src] shrink to how it was before. Pregnancy is no more."))
	SEND_SIGNAL(src, COMSIG_BODYSTORAGE_CHANGED)

/obj/item/organ/genitals/filling_organ/proc/advance_conventional_pregnancy()
	if(!pregnant || !owner)
		conventional_pregnancy_timer = null
		return

	if(conventional_pregnancy_stage < 3 && prob(30))
		conventional_pregnancy_stage += 1
		to_chat(owner, span_love("I notice my belly has grown due to pregnancy..."))
		SEND_SIGNAL(src, COMSIG_BODYSTORAGE_CHANGED)

	if(conventional_pregnancy_stage < 3)
		conventional_pregnancy_timer = addtimer(CALLBACK(src, PROC_REF(advance_conventional_pregnancy)), 6 HOURS, TIMER_STOPPABLE)
	else
		conventional_pregnancy_timer = null

/obj/item/organ/genitals/filling_organ/can_start_fertilization_embryo_pregnancy(allow_embryo_pregnancy = FALSE)
	if(!fertility || !owner || owner.stat == DEAD)
		return FALSE
	if(!allow_embryo_pregnancy || !spawn_embryo_on_fertilization || !supports_oviposition_pregnancy())
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
