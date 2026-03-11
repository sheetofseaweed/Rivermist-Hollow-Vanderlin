/**
 * PORTAL CONTROL RING
*/
/*/obj/item/clothing/ring/portal_control //do something here
	name = "Portal control ring"
	desc = "Ring to control "
	icon_state = "g_ring_ruby"*/


/**
 * PORTAL LIGHT
*/

/obj/item/portallight
    name = "portal light"
    desc = "A softly pulsing arcane device."
    icon = 'modular_rmh/icons/obj/lewd/fleshlight.dmi'
    icon_state = "unpaired"
    var/obj/item/clothing/undies/portalpanties/linked_underwear = null
    var/mutable_appearance/organ_overlay
    var/mutable_appearance/sleeve_overlay
    var/org_target = ORGAN_SLOT_VAGINA
    loadout_blacklisted = TRUE
    w_class = WEIGHT_CLASS_SMALL
    body_storage_bulk = 100 //so that people can't stuff it in for now

/obj/item/portallight/Initialize(mapload)
	. = ..()
	update_erp_item_tags()

/obj/item/portallight/proc/get_wearer()
    if(!linked_underwear)
        return null
    return linked_underwear.current_wearer

/obj/item/portallight/proc/is_held_by(mob/living/carbon/human/user)
    return (user.get_active_held_item() == src)

/obj/item/portallight/proc/get_erp_target_organ_type()
	if(org_target == ORGAN_SLOT_ANUS)
		return SEX_ORGAN_ANUS
	return SEX_ORGAN_VAGINA

/obj/item/portallight/proc/update_erp_item_tags()
	erp_item_tags = list("portal")
	switch(get_erp_target_organ_type())
		if(SEX_ORGAN_ANUS)
			erp_item_tags += "portal_anus"
		else
			erp_item_tags += "portal_vagina"

/obj/item/portallight/proc/is_erp_linked_to(atom/partner_atom, required_target_organ = null)
	var/mob/living/carbon/human/wearer = get_wearer()
	if(!wearer || QDELETED(wearer))
		return FALSE
	if(!linked_underwear || QDELETED(linked_underwear))
		return FALSE
	if(linked_underwear.current_wearer != wearer)
		return FALSE
	if(wearer.underwear != linked_underwear)
		return FALSE
	if(partner_atom && wearer != partner_atom)
		return FALSE
	if(required_target_organ && get_erp_target_organ_type() != required_target_organ)
		return FALSE
	return TRUE

/obj/item/portallight/update_appearance()
	. = ..()
	cut_overlay(organ_overlay)
	cut_overlay(sleeve_overlay)
	icon_state = "unpaired"
	update_erp_item_tags()
	if(!get_wearer())
		return

	var/mob/living/carbon/human/user = get_wearer()
	if(!user)
		return
	if(user.underwear != linked_underwear)
		return

	sleeve_overlay = mutable_appearance(icon, "portal_sleeve_normal")
	var/sleevecolor = user.skin_tone
	sleeve_overlay.color = "#" + sleevecolor
	add_overlay(sleeve_overlay)

	if(linked_underwear.org_target == ORGAN_SLOT_VAGINA)
		organ_overlay = mutable_appearance(icon, "portal_vag")
	else
		organ_overlay = mutable_appearance(icon, "portal_anus")
	organ_overlay.color = "#f37272"
	add_overlay(organ_overlay)

	icon_state = "paired"


/obj/item/portallight/attack_self(mob/user, params)
	if(!linked_underwear)
		to_chat(user, span_info("The portal isn't connected to anything!"))
		return FALSE
	var/mob/living/carbon/human/target = get_wearer()
	if(!target)
		to_chat(user, span_info("There's no one on the other side!"))
		return FALSE
	var/mob/living/carbon/human/user_human = user
	if(!istype(user_human))
		return FALSE
	var/datum/erp_controller/controller = erp_prepare_controller(user_human, target, TRUE, TRUE)
	if(!controller)
		to_chat(user_human, span_warning("The portal refuses to stabilize."))
		return FALSE
	controller.forced_action_scope = ERP_SCOPE_OTHER
	controller.context_required_item_tags = islist(erp_item_tags) ? erp_item_tags.Copy() : list("portal")
	var/datum/erp_sex_ui/ui = controller.ui
	if(ui)
		ui.active_tab = "actions"
		var/datum/erp_sex_ui_tab/actions/actions_tab = ui.actions_tab
		if(actions_tab)
			actions_tab.selected_actor_type = null
			actions_tab.selected_partner_type = get_erp_target_organ_type()
	controller.request_ui_update()
	controller.open_ui(user_human)
	. = ..()

/obj/item/portallight/MiddleClick(mob/user, params)
	. = ..()
	if(!linked_underwear)
		to_chat(user, span_info("The portal isn't connected to anything!"))
		return
	var/mob/living/carbon/human/target = get_wearer()
	if(!target)
		to_chat(user, span_info("There's no one on the other side!"))
		return
	if(linked_underwear.org_target == ORGAN_SLOT_VAGINA)
		to_chat(user, span_info("You refocus the portal to your target's backside!"))
		org_target = ORGAN_SLOT_ANUS
		linked_underwear.org_target = ORGAN_SLOT_ANUS
		update_appearance()
		return
	else if(target.getorganslot(ORGAN_SLOT_VAGINA))
		to_chat(user, span_info("You refocus the portal to your target's loins!"))
		org_target = ORGAN_SLOT_VAGINA
		linked_underwear.org_target = ORGAN_SLOT_VAGINA
		update_appearance()
		return
/**
 * PORTAL PANTIES
*/

/obj/item/clothing/undies/portalpanties
    name = "portal panties"
    desc = "Laced with unstable portal magic."
    icon = 'modular_rmh/icons/obj/lewd/fleshlight.dmi'
    mob_overlay_icon = 'modular_rmh/icons/obj/lewd/portals_onmob.dmi'
    item_state = "panties"
    icon_state = "panties"
    gendered = TRUE
    slot_flags = ITEM_SLOT_UNDER_BOTTOM
    loadout_blacklisted = TRUE

    var/obj/item/portallight/linked_light = null
    var/mob/living/carbon/human/current_wearer = null
    var/org_target = ORGAN_SLOT_VAGINA
    misc_flags = CRAFTING_TEST_EXCLUDE

/obj/item/clothing/undies/portalpanties/equipped(mob/living/carbon/human/H, slot)
	. = ..()
	current_wearer = H
	if(current_wearer.getorganslot(ORGAN_SLOT_VAGINA))
		org_target = ORGAN_SLOT_VAGINA
		to_chat(current_wearer, span_info("You feel magical energies focus around your loins."))
		if(linked_light)
			linked_light.org_target = ORGAN_SLOT_VAGINA
	else
		org_target = ORGAN_SLOT_ANUS
		to_chat(current_wearer, span_info("You feel magical energies focus around your backside."))
		if(linked_light)
			linked_light.org_target = ORGAN_SLOT_ANUS

	if(linked_light)

		linked_light.linked_underwear = src

		linked_light.update_appearance()

/obj/item/clothing/undies/portalpanties/dropped(mob/living/carbon/human/H)
	. = ..()
	if(current_wearer)
		current_wearer = null

		if(linked_light)

			linked_light.linked_underwear = null

			linked_light.update_appearance()

/obj/item/clothing/undies/portalpanties/Destroy()
    if(current_wearer && linked_light)
        linked_light.linked_underwear = null
    . = ..()
/obj/item/clothing/undies/portalpanties/attackby(obj/item/I, mob/living/carbon/human/user)
    if(!istype(I, /obj/item/portallight))
        return ..()

    var/obj/item/portallight/P = I

    if(linked_light == P)
        linked_light = null
        P.linked_underwear = null
        P.update_appearance()
        to_chat(user, span_notice("[P] has been successfully unlinked."))

        return

    linked_light = P
    P.linked_underwear = src
    linked_light.org_target = org_target
    linked_light.update_appearance()

    update_appearance()

    to_chat(user, span_notice("[P] has been successfully linked."))

/**
 * CRAFT AND SUPPLY
*/
/datum/supply_pack/portals_and_fleshlight
	name = "Set of Portal Smallclothes"
	cost = 200
	contains = list(
		/obj/item/portallight,
		/obj/item/clothing/undies/portalpanties
		)
