/obj/item/pocket_dimension_tester
	name = "folded-space scroll"
	desc = "A debugging scroll that opens a small test pocket dimension."
	icon_state = "skub"
	item_state = "skub"
	w_class = WEIGHT_CLASS_SMALL
	var/template_ref = /datum/map_template/pocket/test_chamber
	var/access_mode = POCKET_ACCESS_INSTANCE_OWNER
	var/pocket_lifecycle_policy = POCKET_LIFECYCLE_HIBERNATE
	var/pocket_idle_timeout = 2 MINUTES

/obj/item/pocket_dimension_tester/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/pocket_access, template_ref, access_mode, pocket_lifecycle_policy, pocket_idle_timeout, null, TRUE, TRUE, TRUE, "Pocket Dimension", "The scroll hums with folded space. What do you want it to do?", "The pocket dimension buckles and throws you back into mundane space!", "The scroll burns away, and the pocket dimension collapses around you!")
