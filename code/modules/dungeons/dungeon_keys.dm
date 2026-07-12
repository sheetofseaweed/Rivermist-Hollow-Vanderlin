/obj/item/dungeon_key
	name = "dungeon key"
	desc = "A jagged shard of crystallized dungeon-light. It thrums near sealed ways."
	icon = 'icons/roguetown/items/keys.dmi'
	icon_state = "rustkey"
	w_class = WEIGHT_CLASS_SMALL
	/// Matches a gate's key_id so only the right key opens the right gate
	var/key_id = "default"
	/// Key looks only - no keyrings, picks, pins or locks from the shared sheet
	var/static/list/key_looks = list(
		"brownkey",
		"rustkey",
		"mazekey",
		"hornkey",
		"birdkey",
		"greenkey",
		"spikekey",
		"ekey",
		"eyekey",
		"ankhkey",
		"bosskey",
	)

/obj/item/dungeon_key/Initialize()
	. = ..()
	icon_state = pick(key_looks)
	update_icon()

// Crystallized dungeon-light glows in the dark - a dropped key stays findable.
/obj/item/dungeon_key/update_overlays()
	. = ..()
	. += emissive_appearance(icon, icon_state, src)

/obj/item/dungeon_key/examine(mob/user)
	. = ..()
	. += span_notice("It resonates with a sealed passage somewhere in this room.")
