SUBSYSTEM_DEF(merchant)
	name = "Merchant Packs"
	wait = 60 SECONDS
	init_order = INIT_ORDER_DEFAULT
	runlevels = RUNLEVEL_SETUP | RUNLEVEL_GAME

	var/static/list/group_batch_sizes = list(
		"Raw Materials" = 30,
		"Seeds" = 50,
		"Food" = 15,
		"Drinks" = 15,
		"Narcotics" = 20,
		"Livestock" = 2,
		"Luxury" = 5,
		"Jewelry" = 20,
		"Armor" = 5,
		"Armor(Light)" = 5,
		"Armor(Steel)" = 5,
		"Instruments" = 5,
		"Storage" = 5,
		"Tools" = 5,
		"Medicine" = 20,
		"Shields" = 5,
		"Weapons" = 5,
		"Weapons (Iron)" = 5,
		"Weapons (Steel)" = 5,
		"Weapons (Ranged)" = 5,
		"Ammunition" = 100,
		"Hats" = 10,
		"Masks" = 10,
		"Neckwear" = 10,
		"Cloaks" = 10,
		"Coats & Vests" = 10,
		"Shirts & Dresses" = 10,
		"Trousers" = 10,
		"Stockings" = 10,
		"Footwear" = 10,
		"Gloves" = 10,
		"Belts" = 10,
		"Dyes" = 10,
	)

	var/list/supply_packs = list()
	var/list/supply_cats = list()
	var/list/shoppinglist = list()
	var/list/requestlist = list()
	var/list/fencerequestlist = list()
	var/list/orderhistory = list()
	var/list/trade_requests = list()
	var/list/sending_stuff = list()
	///the amount of currency generated when we spawn everything
	var/extra_currency = 0

	var/datum/lift_master/tram/cargo_boat
	var/cargo_docked = TRUE
	var/datum/lift_master/tram/fence_boat
	var/fence_docked = TRUE

	var/list/world_factions = list()
	var/list/staticly_setup_types = list()
	/// Catatoma ledgers are registered so market changes can refresh only those UIs.
	var/list/catatoma_ledgers = list()
	/// Ensures global merchant-start bonuses are applied only once per round.
	var/merchant_preferences_applied = FALSE

	// New faction management
	var/datum/world_faction/active_faction // Currently selected faction for trading
	var/list/faction_rotation_schedule = list() // When each faction becomes active
	var/list/active_faction_traders = list()

	///this is our list of created nations
	var/list/nations = list()

	/// Cache of recipe component costs to avoid recalculation
	var/static/list/recipe_base_values = list()
	/// This is a static of possible bounty items
	var/static/list/obtainable_items = list()
	/// Cached list of exclusions for the craft requirements
	var/static/list/exclusions = list()
	/// Same as above but adds all the subtypes
	var/static/list/exclusion_subtypes = list(
		/obj/item/ingot,
		/obj/item/ore,
		/obj/item/natural,
	)

	/// world.time at which the current active_faction will be rotated out
	var/active_faction_rotation_time = 0
	/// world.time at which a manual faction rotation becomes available again
	var/manual_rotation_ready_time = 0
	/// Cooldown between player-triggered faction rotations
	var/manual_rotation_cooldown = 10 MINUTES


/datum/controller/subsystem/merchant/Initialize(timeofday)
	setup_map_nations()
	// Initialize recipe values and bounty cache BEFORE factions cause they use it
	initialize_recipe_values()

	// Initialize supply packs
	for(var/pack in subtypesof(/datum/supply_pack))
		var/datum/supply_pack/P = new pack()
		if(!P.contains)
			qdel(P)
			continue
		supply_packs[P.type] = P
		if(!(P.group in supply_cats))
			supply_cats += P.group

	// Initialize factions
	initialize_factions()
	return ..()

/datum/controller/subsystem/merchant/proc/setup_map_nations()
	return //! TODO: when lore done set this up

/**
 * Initializes recipe base values for ALL recipes
 * This runs once and calculates component costs for every craftable item
 */
/datum/controller/subsystem/merchant/proc/initialize_recipe_values()
	if(length(recipe_base_values))
		return // Already initialized

	log_game("Calculating recipe component costs for all craftable items...")

	// Process ALL repeatable crafting recipes
	for(var/datum/repeatable_crafting_recipe/recipe_type as anything in subtypesof(/datum/repeatable_crafting_recipe))
		var/datum/repeatable_crafting_recipe/recipe = new recipe_type()
		var/output = recipe.output

		if(output)
			var/cost = calculate_component_cost(recipe.requirements, recipe.reagent_requirements)
			recipe_base_values[output] = cost + (recipe.craftdiff * 10)

		qdel(recipe)

	// Process ALL orderless slapcraft recipes
	for(var/datum/orderless_slapcraft/recipe_type as anything in subtypesof(/datum/orderless_slapcraft))
		var/datum/orderless_slapcraft/recipe = new recipe_type()
		var/output = recipe.output_item

		if(output)
			var/cost = calculate_component_cost(recipe.requirements)
			recipe_base_values[output] = cost + 10

		qdel(recipe)

	// Process ALL anvil recipes
	for(var/datum/anvil_recipe/recipe_type as anything in subtypesof(/datum/anvil_recipe))
		if(IS_ABSTRACT(recipe_type))
			continue
		var/datum/anvil_recipe/recipe = new recipe_type()
		var/output = recipe.created_item

		if(output)
			var/list/all_requirements = list()
			if(recipe.req_bar)
				all_requirements[recipe.req_bar] = recipe.num_of_materials

			if(length(recipe.additional_items))
				for(var/item in recipe.additional_items)
					all_requirements[item] = 1

			var/cost = calculate_component_cost(all_requirements)
			recipe_base_values[output] = cost + (recipe.craftdiff * 10)

		qdel(recipe)

	// Process ALL artificer recipes
	for(var/datum/artificer_recipe/recipe_type as anything in subtypesof(/datum/artificer_recipe))
		var/datum/artificer_recipe/recipe = new recipe_type()
		var/output = recipe.created_item

		if(output)
			var/list/all_requirements = list()
			if(recipe.required_item)
				all_requirements[recipe.required_item] = 1

			if(length(recipe.additional_items))
				for(var/item in recipe.additional_items)
					all_requirements[item] = 1

			var/cost = calculate_component_cost(all_requirements)
			recipe_base_values[output] = cost + (recipe.craftdiff * 10)

		qdel(recipe)

	// Process ALL container craft recipes
	for(var/datum/container_craft/recipe_type as anything in subtypesof(/datum/container_craft))
		var/datum/container_craft/recipe = new recipe_type()
		var/output = recipe.output

		if(output)
			var/cost = calculate_component_cost(recipe.requirements, recipe.reagent_requirements)
			recipe_base_values[output] = cost + 10

		qdel(recipe)

	log_game("Calculated recipe values for [length(recipe_base_values)] craftable items")

/**
 * Calculates the total cost of components in a recipe
 * Arguments:
 *   requirements - List of required items (path = amount)
 *   reagent_requirements - Optional list of required reagents
 * Returns:
 *   Total component cost, or 0 if cannot be calculated
 */
/datum/controller/subsystem/merchant/proc/calculate_component_cost(list/requirements, list/reagent_requirements)
	var/total_cost = 0

	// Calculate item component costs
	if(length(requirements))
		for(var/component_type in requirements)
			var/amount = 1

			// Handle different requirement formats
			if(isnum(requirements[component_type]))
				amount = requirements[component_type]
			else if(islist(requirements[component_type]))
				amount = length(requirements[component_type])

			var/component_value = get_item_base_value(component_type)

			if(component_value <= 0)
				// If we can't determine a component's value, we can't calculate total cost
				return 0

			total_cost += component_value * amount

	// Calculate reagent costs (simplified - you may want to add actual reagent values)
	if(length(reagent_requirements))
		for(var/reagent in reagent_requirements)
			var/amount = reagent_requirements[reagent]
			// Use a base cost per unit of reagent (adjust as needed)
			total_cost += amount * 0.5

	return total_cost

/**
 * Gets the base value of an item
 * Checks recipe values first, then falls back to sellprice
 * Arguments:
 *   item_type - The path of the item
 * Returns:
 *   The base value, or 0 if not found
 */
/datum/controller/subsystem/merchant/proc/get_item_base_value(item_type)
	// Check if it's a craftable item with recipe cost
	if(item_type in recipe_base_values)
		return recipe_base_values[item_type]

	// Check that we have a movable type.
	if(!ispath(item_type, /atom/movable))
		return 0

	// Otherwise use sellprice directly
	var/atom/movable/movable_type = item_type
	var/base_sellprice = initial(movable_type.sellprice)
	if(base_sellprice > 0)
		return base_sellprice

	return 0

/datum/controller/subsystem/merchant/proc/get_sell_modifier(atom/sell_type, datum/world_faction/faction)
	if(!faction)
		faction = active_faction

	if(!faction)
		return 1

	return faction.return_sell_modifier(sell_type)

/datum/controller/subsystem/merchant/proc/register_sellable_item(atom/sell_type)
	if(sell_type in staticly_setup_types)
		return

	staticly_setup_types |= sell_type
	for(var/datum/world_faction/faction in world_factions)
		faction.setup_sell_data(sell_type)

/datum/controller/subsystem/merchant/proc/initialize_factions()

	for(var/datum/world_faction/faction as anything in subtypesof(/datum/world_faction))
		var/datum/world_faction/new_faction = new faction
		if((SSmapping.config.map_name in new_faction.allowed_maps) || !length(new_faction.allowed_maps))
			world_factions |= new_faction
		else
			qdel(new_faction)
	if(!length(world_factions))
		return
	shuffle(world_factions)

	// Set initial active faction
	active_faction = pick(world_factions)

	// Schedule faction rotations (every 45 minutes)
	var/rotation_time = 45 MINUTES
	for(var/i = 1 to length(world_factions))
		var/datum/world_faction/faction = world_factions[i]
		faction_rotation_schedule[faction] = world.time + (rotation_time * (i - 1))
	reschedule_faction_queue(active_faction)
	active_faction_rotation_time = world.time + rotation_time

/datum/controller/subsystem/merchant/proc/rotate_active_faction()
	var/datum/world_faction/next_faction
	var/earliest_time = INFINITY
	for(var/datum/world_faction/faction in faction_rotation_schedule)
		var/scheduled_time = faction_rotation_schedule[faction]
		if(scheduled_time <= world.time && scheduled_time < earliest_time)
			earliest_time = scheduled_time
			next_faction = faction
	if(next_faction && next_faction != active_faction)
		set_active_faction(next_faction)

/datum/controller/subsystem/merchant/proc/reschedule_faction_queue(datum/world_faction/starting_faction)
	// Rebuilds the round-robin queue so starting_faction is active now,
	// with the remaining factions queued up in sequence afterward.
	var/list/remaining = world_factions.Copy()
	remaining -= starting_faction

	var/index = 1
	for(var/datum/world_faction/faction in remaining)
		faction_rotation_schedule[faction] = world.time + (45 MINUTES * index)
		index++

	faction_rotation_schedule[starting_faction] = world.time + (45 MINUTES * length(world_factions))

/// Central point for changing the active faction, whether by schedule or by player choice
/datum/controller/subsystem/merchant/proc/set_active_faction(datum/world_faction/new_faction, manual = FALSE)
	if(!new_faction || !(new_faction in world_factions))
		return FALSE
	if(new_faction == active_faction)
		return TRUE
	active_faction = new_faction
	if(manual)
		reschedule_faction_queue(new_faction)
		manual_rotation_ready_time = world.time + manual_rotation_cooldown
	else
		faction_rotation_schedule[new_faction] = world.time + (45 MINUTES * length(world_factions))

	var/next_time = faction_rotation_schedule[new_faction]
	for(var/faction in faction_rotation_schedule)
		next_time = min(next_time, faction_rotation_schedule[faction])
	active_faction_rotation_time = next_time
	for(var/obj/item/book/secret/ledger/ledger as anything in catatoma_ledgers)
		ledger.on_faction_changed()
	refresh_ledger_uis()
	return TRUE

/datum/controller/subsystem/merchant/fire(resumed)
	// Update all factions
	for(var/datum/world_faction/faction in world_factions)
		faction.handle_world_change()

	// Check for faction rotation
	rotate_active_faction()
	refresh_ledger_uis()

/datum/controller/subsystem/merchant/proc/register_ledger(obj/item/book/secret/ledger/ledger)
	catatoma_ledgers |= ledger

/datum/controller/subsystem/merchant/proc/unregister_ledger(obj/item/book/secret/ledger/ledger)
	catatoma_ledgers -= ledger

/datum/controller/subsystem/merchant/proc/refresh_ledger_uis()
	for(var/obj/item/book/secret/ledger/ledger as anything in catatoma_ledgers)
		if(QDELETED(ledger))
			catatoma_ledgers -= ledger
			continue
		SStgui.update_uis(ledger)


/datum/controller/subsystem/merchant/proc/get_active_faction_rotation_seconds_left()
	if(!active_faction_rotation_time)
		return 0
	return max(0, round((active_faction_rotation_time - world.time) / 10))

/datum/controller/subsystem/merchant/proc/can_manual_rotate()
	return world.time >= manual_rotation_ready_time

/datum/controller/subsystem/merchant/proc/get_manual_rotation_seconds_left()
	return max(0, round((manual_rotation_ready_time - world.time) / 10))

/datum/controller/subsystem/merchant/proc/manual_rotate_faction(datum/world_faction/chosen_faction, mob/user)
	if(!can_manual_rotate())
		if(user)
			to_chat(user, "<span class='warning'>The trade routes can't be redirected again so soon.</span>")
		return FALSE
	if(!chosen_faction || !(chosen_faction in world_factions))
		return FALSE
	if(chosen_faction == active_faction)
		if(user)
			to_chat(user, "<span class='warning'>[chosen_faction.faction_name] is already the active trading faction.</span>")
		return FALSE
	set_active_faction(chosen_faction, manual = TRUE)
	if(user)
		to_chat(user, "<span class='notice'>You redirect the trade routes. [chosen_faction.faction_name] is now active.</span>")
	return TRUE

/// Add an order to the queue belonging to the faction that quoted it.
/datum/controller/subsystem/merchant/proc/queue_supply_order(datum/supply_pack/pack, quantity = 1, datum/world_faction/faction = active_faction)
	if(!pack || !faction || !(faction in world_factions) || quantity <= 0)
		return FALSE
	pack = faction.faction_supply_packs[pack.type]
	if(!pack)
		return FALSE
	var/list/faction_orders = requestlist[faction]
	if(!faction_orders)
		faction_orders = list()
		requestlist[faction] = faction_orders
	faction_orders[pack] += quantity
	return TRUE

/datum/controller/subsystem/merchant/proc/prepare_cargo_shipment()
	if(!cargo_boat || !cargo_docked)
		return
	draw_selling_changes()
	cargo_boat.show_tram()

	// Gather available flooring spaces from the lift system
	var/list/boat_spaces = list()
	for(var/obj/structure/industrial_lift/lift in cargo_boat.lift_platforms)
		boat_spaces |= cargo_boat.get_valid_turfs(lift)

	if(!length(boat_spaces))
		return

	if(length(requestlist))
		for(var/datum/world_faction/ordering_faction as anything in requestlist)
			var/list/faction_orders = requestlist[ordering_faction]
			if(!length(faction_orders))
				continue
			var/list/items_by_group = list()
			var/list/admin_flagged_types = list()
			for(var/datum/supply_pack/requested as anything in faction_orders)
				var/quantity = faction_orders[requested]
				if(quantity <= 0 || !length(requested.contains))
					continue
				var/group_name = requested.group || "General"
				if(!items_by_group[group_name])
					items_by_group[group_name] = list()
				for(var/i in 1 to quantity)
					for(var/item_type in requested.contains)
						if(!item_type)
							continue
						if(requested.admin_spawned)
							admin_flagged_types |= item_type
						items_by_group[group_name] += item_type

			for(var/group_name in items_by_group)
				var/list/group_items = items_by_group[group_name]
				var/list/current_chest_batch = list()
				var/max_batch_size = group_batch_sizes[group_name] || 5
				for(var/item_type in group_items)
					current_chest_batch += item_type
					if(length(current_chest_batch) >= max_batch_size)
						spawn_delivery_chest(group_name, current_chest_batch, boat_spaces, ordering_faction, admin_flagged_types)
						current_chest_batch = list()
				if(length(current_chest_batch))
					spawn_delivery_chest(group_name, current_chest_batch, boat_spaces, ordering_faction, admin_flagged_types)

	if(length(sending_stuff))
		for(var/atom/movable/item as anything in sending_stuff)
			if(QDELETED(item))
				continue
			var/turf/boat_turf = pick(boat_spaces)
			if(ispath(item))
				var/atom/movable/spawned_item = new item(boat_turf)
				register_lift_cargo(spawned_item)
			else
				item.forceMove(boat_turf)
				register_lift_cargo(item)
		sending_stuff.Cut()

	requestlist.Cut()
	spawn_faction_traders()
	cargo_docked = FALSE
	SEND_GLOBAL_SIGNAL(COMSIG_DISPATCH_CARGO, cargo_boat)

/**
 * Assembles a physical chest on the deck, loads it with up to 5 items,
 * and prints a parchment manifest lying over it.
 */
/datum/controller/subsystem/merchant/proc/spawn_delivery_chest(category, list/items_to_pack, list/boat_spaces, datum/world_faction/ordering_faction, list/admin_flagged_types)
	if(!length(boat_spaces) || !length(items_to_pack))
		return
	var/turf/spawn_turf = pick(boat_spaces)
	if(!spawn_turf)
		return
	var/obj/structure/closet/crate/chest/merchant/delivery_chest = new(spawn_turf)
	delivery_chest.name = "[LOWER_TEXT(category)] delivery chest"
	register_lift_cargo(delivery_chest)
	var/manifest_contents = "<h2>[ordering_faction?.faction_name || "Unknown"] [category] Supply Division</h2><hr><b>Contained Cargo Manifest:</b><ul>"
	for(var/item_type in items_to_pack)
		var/atom/movable/item = item_type
		if(ispath(item_type))
			item = new item_type(delivery_chest)
		else
			item.forceMove(delivery_chest)
		if(item_type in admin_flagged_types)
			item.flags_1 |= ADMIN_SPAWNED_1
		if(isitem(item))
			var/list/quality_result = ordering_faction?.get_faction_quality_calculator(item)
			if(quality_result)
				create_quality_item(item, quality_result[1], quality_override = quality_result[2])
		manifest_contents += "<li>[item.name]</li>"
	manifest_contents += "</ul><hr><i>Seal of Authenticity - Approved Shipment.</i>"
	var/obj/item/paper/manifest = new(spawn_turf)
	manifest.name = "manifest parchment ([LOWER_TEXT(category)])"
	manifest.info = manifest_contents
	manifest.update_appearance()
	manifest.pixel_x = delivery_chest.pixel_x + rand(-3, 3)
	manifest.pixel_y = delivery_chest.pixel_y + rand(-3, 3)
	register_lift_cargo(manifest)

/**
 * Clean internal utility to link any instantiated delivery item back to the platform
 */
/datum/controller/subsystem/merchant/proc/register_lift_cargo(atom/movable/cargo_item)
	if(!cargo_boat)
		return
	for(var/obj/structure/industrial_lift/lift in cargo_boat.lift_platforms)
		lift.held_cargo |= cargo_item

/datum/controller/subsystem/merchant/proc/send_cargo_ship_back()
	var/obj/effect/landmark/tram/queued_path/cargo_stop/cargo_stop = cargo_boat.idle_platform
	cargo_stop.UnregisterSignal(cargo_boat, COMSIG_TRAM_EMPTY)
	if(!SSticker.HasRoundStarted())
		return
	if(!cargo_stop.next_path_id)
		return
	var/obj/effect/landmark/tram/destination_platform
	for (var/obj/effect/landmark/tram/destination as anything in GLOB.tram_landmarks[cargo_stop.specific_lift_id])
		if(destination.platform_code == cargo_stop.next_path_id)
			destination_platform = destination
			break

	if (!destination_platform)
		return FALSE

	cargo_boat.tram_travel(destination_platform, rapid = FALSE)
	cargo_boat.callback_platform = destination_platform



/datum/controller/subsystem/merchant/proc/prepare_fence_shipment()
	if(!fence_boat || !fence_docked)
		return

	fence_boat.show_tram()
	var/list/boat_spaces = list()
	for(var/obj/structure/industrial_lift/lift in fence_boat.lift_platforms)
		boat_spaces |= fence_boat.get_valid_turfs(lift)

	for(var/atom/movable/request as anything in fencerequestlist)
		for(var/i = 1 to fencerequestlist[request])
			var/turf/boat_turf = pick_n_take(boat_spaces)
			var/atom/movable/new_item = new request
			new_item.forceMove(boat_turf)
			for(var/obj/structure/industrial_lift/lift in fence_boat.lift_platforms)
				lift.held_cargo |= new_item

	fencerequestlist = list()
	fence_docked = FALSE
	SEND_GLOBAL_SIGNAL(COMSIG_DISPATCH_CARGO, fence_boat)

/datum/controller/subsystem/merchant/proc/send_fence_ship_back()
	var/obj/effect/landmark/tram/queued_path/fence_stop/cargo_stop = fence_boat.idle_platform
	cargo_stop.UnregisterSignal(fence_boat, COMSIG_TRAM_EMPTY)
	if(!SSticker.HasRoundStarted())
		return
	if(!cargo_stop.next_path_id)
		return
	var/obj/effect/landmark/tram/destination_platform
	for (var/obj/effect/landmark/tram/destination as anything in GLOB.tram_landmarks[cargo_stop.specific_lift_id])
		if(destination.platform_code == cargo_stop.next_path_id)
			destination_platform = destination
			break

	if (!destination_platform)
		return FALSE

	fence_boat.tram_travel(destination_platform, rapid = FALSE)
	fence_boat.callback_platform = destination_platform

/datum/controller/subsystem/merchant/proc/adjust_sell_multiplier(obj/change_type, change = 0)
	active_faction.adjust_sell_multiplier(change_type, change)


/datum/controller/subsystem/merchant/proc/handle_selling(obj/selling_type)
	active_faction.handle_selling(selling_type)

/datum/controller/subsystem/merchant/proc/changed_sell_prices(atom/atom_type, old_price, new_price)
	active_faction.changed_sell_prices(atom_type, old_price, new_price)

/datum/controller/subsystem/merchant/proc/draw_selling_changes()
	for(var/datum/world_faction/active_faction in world_factions)
		active_faction.draw_selling_changes()

/datum/controller/subsystem/merchant/proc/set_faction_sell_values(atom/sell_type)
	staticly_setup_types |= sell_type
	for(var/datum/world_faction/active_faction in world_factions)
		active_faction.setup_sell_data(sell_type)

/datum/controller/subsystem/merchant/proc/spawn_faction_traders()
	if(!cargo_docked || !length(world_factions))
		return

	var/datum/world_faction/selected_faction = active_faction
	if(!selected_faction)
		return
	if(!selected_faction.trader_schedule_generated || selected_faction.next_boat_trader_count <= 0)
		selected_faction.reset_trader_schedule()
		return

	// Find spawn location on or near the boat
	var/list/possible_turfs = list()
	for(var/obj/structure/industrial_lift/lift in cargo_boat.lift_platforms)
		possible_turfs |= cargo_boat.get_valid_turfs(lift)

	if(!length(possible_turfs))
		return

	// Create all scheduled traders
	var/list/new_traders = selected_faction.create_scheduled_traders(possible_turfs)

	for(var/mob/living/simple_animal/hostile/retaliate/trader/faction_trader/trader in new_traders)
		active_faction_traders += trader
		trader.ai_controller?.set_blackboard_key(BB_CURRENT_MIN_MOVE_DISTANCE, 0)
		trader.ai_controller?.PauseAiUntilSignal(COMSIG_MOB_CARGO_DOCKED, 1 MINUTES) // Wait for docking, with a timeout as a safety net.
	selected_faction.reset_trader_schedule()

/datum/controller/subsystem/merchant/proc/unlock_supply_packs(list/incoming_packs)
	for(var/datum/supply_pack/pack in supply_packs)
		if(!(pack.type in incoming_packs))
			continue
		pack.unlocked = TRUE


/obj/Initialize()
	. = ..()
	if(sellprice)
		if(!(type in SSmerchant.staticly_setup_types))
			if(!istype(src, /obj/item/coin))
				SSmerchant.set_faction_sell_values(type)
