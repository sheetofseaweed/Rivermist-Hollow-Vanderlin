/obj/item/dungeon_key
	name = "dungeon key"
	desc = "A jagged shard of crystallized dungeon-light. It thrums near sealed ways."
	icon = 'icons/roguetown/misc/structure.dmi'
	icon_state = "ladder01"
	w_class = WEIGHT_CLASS_SMALL
	/// Matches a gate's key_id so only the right key opens the right gate
	var/key_id = "default"

/obj/item/dungeon_key/examine(mob/user)
	. = ..()
	. += span_notice("It resonates with a sealed passage somewhere in this room.")
