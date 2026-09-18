/obj/item/essence_vial
	name = "essence vial"
	desc = "A small crystalline vial designed to hold alchemical essences."
	icon = 'icons/roguetown/items/glass_reagent_container.dmi'
	icon_state = "essence_vial"
	w_class = WEIGHT_CLASS_TINY
	var/essence_fill = "essence_liquid"
	var/datum/thaumaturgical_essence/contained_essence = null
	var/essence_amount = 0
	var/max_essence = 60
	var/extract_amount = 60 // Amount to try to extract when used
	var/list/extract_values = list(1, 2, 3, 4, 5, 10, 15, 30, 60)
	var/extract_index = 1
	var/secondary_extract_amount = 30

/obj/item/essence_vial/combat
	name = "combat flask"
	desc = "A larger crystalline flask designed to hold large amounts of essences."
	icon_state = "clear_bottle4"
	essence_fill = "combat_essence_fill"
	max_essence = 100
	extract_amount = 100
	extract_values = list(10, 20, 30, 40, 50, 60, 70, 80, 90, 100)
	secondary_extract_amount = 100

/obj/item/essence_vial/Initialize()
	. = ..()
	update_appearance(UPDATE_OVERLAYS)

/obj/item/essence_vial/attack_self(mob/user, list/modifiers)
	if(extract_amount == extract_values[extract_values.len])
		extract_index = 1
	else
		extract_index = min(extract_index + 1, extract_values.len)
	extract_amount = extract_values[extract_index]

	to_chat(user, span_info("You adjust the vial to extract [extract_amount] unit[extract_amount > 1 ? "s" : ""] of essence."))

/obj/item/essence_vial/attack_self_secondary(mob/user, list/modifiers)
	if(extract_amount != secondary_extract_amount)
		extract_amount = secondary_extract_amount
		to_chat(user, span_info("You adjust the vial to extract [extract_amount] unit[extract_amount > 1 ? "s" : ""] of essence."))

/obj/item/essence_vial/proc/check_vial_menu_validity(mob/user)
	return user && (src in user.contents)

/obj/item/essence_vial/update_overlays()
	. = ..()
	if(!contained_essence || essence_amount <= 0)
		return
	var/used_alpha = min(255, 100 + (essence_amount * 15))
	. += mutable_appearance(icon, essence_fill, alpha = used_alpha, color = contained_essence.color)
	. += emissive_appearance(icon, essence_fill, alpha = used_alpha)

/obj/item/essence_vial/examine(mob/user)
	. = ..()
	if(contained_essence && essence_amount > 0)
		if(!HAS_TRAIT(user, TRAIT_LEGENDARY_ALCHEMIST))
			. += span_notice("Contains [essence_amount] units of essence smelling of [contained_essence.smells_like].")
		else
			. += span_notice("Contains [essence_amount] units of [contained_essence.name].")
			. += span_notice("It smells of [contained_essence.smells_like].")
	else
		. += span_notice("It appears to be empty.")

	. += span_notice("Set to extract [extract_amount] unit[extract_amount > 1 ? "s" : ""] when used. Use in hand to adjust.")

/obj/item/essence_vial/proc/can_hold_essence()
	return essence_amount < max_essence

/obj/item/essence_vial/proc/get_available_space()
	return max_essence - essence_amount


/datum/thaumaturgical_essence
	var/name = "essence"
	var/desc = "A concentrated magical essence."
	var/tier = 0 // 0 = Basic, 1 = First Compound, 2 = Second Compound
	var/color = "#FFFFFF"
	var/icon_state = "essence_basic"
	var/smells_like = "magic"
	/// Mana attunement associated with this essence.
	var/datum/attunement/attunement

// =============================================================================
// TIER 0 - BASIC ESSENCES
// =============================================================================

/datum/thaumaturgical_essence/air
	name = "Air Essence"
	desc = "The essence of wind and movement."
	color = "#E6F3FF"
	smells_like = "fresh breeze"
	attunement = /datum/attunement/aeromancy

/datum/thaumaturgical_essence/water
	name = "Water Essence"
	desc = "The essence of flowing water."
	color = "#4A90E2"
	smells_like = "clear streams"
	attunement = /datum/attunement/blood

/datum/thaumaturgical_essence/fire
	name = "Fire Essence"
	desc = "The essence of burning flame."
	color = "#FF6B35"
	smells_like = "smoke and ash"
	attunement = /datum/attunement/fire

/datum/thaumaturgical_essence/earth
	name = "Earth Essence"
	desc = "The essence of solid ground."
	color = "#8B4513"
	smells_like = "rich soil"
	attunement = /datum/attunement/earth

/datum/thaumaturgical_essence/order
	name = "Order Essence"
	desc = "The essence of structure and harmony."
	color = "#FFD700"
	smells_like = "purity and stagnation"

/datum/thaumaturgical_essence/chaos
	name = "Chaos Essence"
	desc = "The essence of change and discord."
	color = "#8A2BE2"
	smells_like = "freedom and chaos"
	attunement = /datum/attunement/polymorph

// =============================================================================
// TIER 1 - FIRST COMPOUND ESSENCES
// =============================================================================

/datum/thaumaturgical_essence/frost
	name = "Frost Essence"
	desc = "The essence of bitter cold."
	tier = 1
	color = "#87CEEB"
	smells_like = "winter air"
	attunement = /datum/attunement/ice

/datum/thaumaturgical_essence/light
	name = "Light Essence"
	desc = "The essence of illumination."
	tier = 1
	smells_like = "warm embrace"
	attunement = /datum/attunement/light

/datum/thaumaturgical_essence/motion
	name = "Motion Essence"
	desc = "The essence of movement and speed."
	tier = 1
	color = "#32CD32"
	smells_like = "rushing wind"
	attunement = /datum/attunement/time

/datum/thaumaturgical_essence/cycle
	name = "Cycle Essence"
	desc = "The essence of renewal and time."
	tier = 1
	color = "#20B2AA"
	smells_like = "changing seasons"

/datum/thaumaturgical_essence/energia
	name = "Energia Essence"
	desc = "The essence of raw energy."
	tier = 1
	color = "#FF1493"
	smells_like = "crackling energy"
	attunement = /datum/attunement/electric

/datum/thaumaturgical_essence/void
	name = "Void Essence"
	desc = "The essence of emptiness."
	tier = 1
	color = "#2F2F2F"
	smells_like = "the abyss"
	attunement = /datum/attunement/illusion

/datum/thaumaturgical_essence/poison
	name = "Poison Essence"
	desc = "The essence of toxicity."
	tier = 1
	color = "#9ACD32"
	smells_like = "toxic fumes"
	attunement = /datum/attunement/dark

/datum/thaumaturgical_essence/life
	name = "Life Essence"
	desc = "The essence of vitality."
	tier = 1
	color = "#FF69B4"
	smells_like = "blooming flowers"
	attunement = /datum/attunement/life

/datum/thaumaturgical_essence/crystal
	name = "Crystal Essence"
	desc = "The essence of crystalline structure."
	tier = 1
	color = "#DA70D6"
	smells_like = "gem dust"

// =============================================================================
// TIER 2 - SECOND COMPOUND ESSENCES
// =============================================================================

/datum/thaumaturgical_essence/magic
	name = "Magic Essence"
	desc = "The essence of pure arcynic power."
	tier = 2
	color = "#9370DB"
	smells_like = "raw magic"
	attunement = /datum/attunement/arcyne

/datum/thaumaturgical_essence/death
	name = "Death Essence"
	desc = "The essence of pure death."
	tier = 2
	color = "#221123"
	smells_like = "death and the end"
	attunement = /datum/attunement/death
