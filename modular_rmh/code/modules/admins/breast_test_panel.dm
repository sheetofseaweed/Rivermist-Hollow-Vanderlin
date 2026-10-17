// Admin test panel for the breast system: one View Variables entry on a human ("Breast Test Panel") opens a small
// window to set the breast size, fill the breasts with their own milk to a share, toggle lactation and Swelling
// Glands, and watch the fill (the window refreshes itself every few seconds while it is open).
// For testers (see "breasts files/docs/TEST_GUIDE.md"). Every change is logged.

#define VV_HK_BREAST_TEST_PANEL "breast_test_panel"
/// How often the open window refreshes itself.
#define BREAST_PANEL_REFRESH_MS 3000
/// Trait source of the swelling toggled from the panel.
#define BREAST_PANEL_TRAIT_SOURCE "breast_test_panel"

/mob/living/carbon/human/vv_get_dropdown()
	. = ..()
	VV_DROPDOWN_OPTION(VV_HK_BREAST_TEST_PANEL, "Breast Test Panel")

/mob/living/carbon/human/vv_do_topic(list/href_list)
	. = ..()
	if(href_list[VV_HK_BREAST_TEST_PANEL])
		if(!check_rights(R_SPAWN))
			return
		// Kept in a list: the window's links point at the panel, which would otherwise be garbage collected.
		var/datum/breast_test_panel/panel = GLOB.breast_test_panels[REF(src)]
		if(!panel)
			panel = new(src)
			GLOB.breast_test_panels[REF(src)] = panel
		panel.show(usr)

GLOBAL_LIST_EMPTY(breast_test_panels)

/datum/breast_test_panel
	var/mob/living/carbon/human/target

/datum/breast_test_panel/New(mob/living/carbon/human/target)
	. = ..()
	src.target = target

/datum/breast_test_panel/proc/show(mob/viewer)
	if(QDELETED(target))
		to_chat(viewer, span_warning("The target is gone."))
		return
	var/obj/item/organ/genitals/filling_organ/breasts/breasts = target.getorganslot(ORGAN_SLOT_BREASTS)
	var/list/html = list("<html><head><meta charset='utf-8'><title>Breast Test Panel</title>")
	// Self-refresh: asks for a fresh copy of the window every few seconds; stops when the window is closed.
	html += "<script>setTimeout(function(){window.location='byond://?src=[REF(src)];refresh=1';}, [BREAST_PANEL_REFRESH_MS]);</script>"
	html += "</head><body>"
	html += "<b>[target]</b> ([target.ckey || "no player"])<hr>"
	if(!breasts)
		html += "No breasts organ.<br>"
	else
		var/max_volume = breasts.reagents?.maximum_volume || 0
		var/own = breasts.get_own_fluid_amount()
		html += "Size (organ): <b>[breasts.organ_size]</b> &nbsp; visible: <b>[breasts.get_visible_size()]</b><br>"
		html += "Set size: "
		for(var/size in 0 to 8)
			html += "<a href='byond://?src=[REF(src)];size=[size]'>[size]</a> "
		var/percent_now = max_volume ? round(own / max_volume * 100, 0.1) : 0
		html += "<br><br>Own milk: <b>[round(own, 0.1)] / [max_volume]</b> ([percent_now] %)"
		html += " &nbsp; full (75 %+): <b>[breasts.is_full_of_milk() ? "yes" : "no"]</b>, swollen: <b>[breasts.engorgement_steps ? "+[breasts.engorgement_steps]" : "no"]</b><br>"
		// Fill bar with the swelling (65 %) and full (75 %) marks.
		html += "<div style='position:relative;width:400px;height:14px;background:#333;border:1px solid #888'>"
		html += "<div style='width:[round(clamp(percent_now, 0, 100) * 4)]px;height:14px;background:#e8e0c8'></div>"
		html += "<div style='position:absolute;left:260px;top:0;width:1px;height:14px;background:#4a8'></div>"
		html += "<div style='position:absolute;left:300px;top:0;width:1px;height:14px;background:#c55'></div></div>"
		html += "<small>green: swelling 65 %, red: full 75 %</small><br>"
		html += "Lactation: <b>[breasts.produces_fluid ? "on" : "off"]</b> <a href='byond://?src=[REF(src)];lactation=1'>toggle</a>"
		html += " &nbsp; producing now: <b>[breasts.is_producing() ? "yes" : "no"]</b>"
		if(breasts.is_producing() != breasts.produces_fluid)
			html += " <small>(a potion or effect overrides the setting)</small>"
		html += "<br>"
		html += "Fill to: "
		for(var/percent in list(0, 25, 50, 64, 65, 74, 75, 95, 100))
			html += "<a href='byond://?src=[REF(src)];fill=[percent]'>[percent]%</a> "
		html += "<a href='byond://?src=[REF(src)];fill=custom'>other...</a><br><br>"
	html += "Swelling Glands (trait): <b>[HAS_TRAIT(target, TRAIT_FLUID_ENGORGEMENT) ? "on" : "off"]</b> "
	html += "<a href='byond://?src=[REF(src)];swelling=1'>toggle</a><br>"
	var/datum/quirk/vice/breast_enthusiast/vice = target.get_quirk(/datum/quirk/vice/breast_enthusiast)
	html += "Breast Enthusiast (vice): <b>[vice ? "on, hunger stage [vice.hunger_stage]" : "off"]</b> "
	html += "<a href='byond://?src=[REF(src)];enthusiast=1'>toggle</a><br>"
	html += "<hr><small>refreshes every [BREAST_PANEL_REFRESH_MS / 1000] s</small> <a href='byond://?src=[REF(src)];refresh=1'>refresh now</a>"
	html += "</body></html>"
	viewer << browse(html.Join(), "window=breast_test_panel_[REF(target)];size=460x380")

/datum/breast_test_panel/Topic(href, list/href_list)
	. = ..()
	if(!usr?.client?.holder || !check_rights(R_SPAWN))
		return
	if(QDELETED(target))
		return
	var/obj/item/organ/genitals/filling_organ/breasts/breasts = target.getorganslot(ORGAN_SLOT_BREASTS)
	if(href_list["size"] && breasts)
		var/size = clamp(text2num(href_list["size"]), 0, 8)
		breasts.organ_size = size
		redraw()
		log_change("set breast size of [key_name(target)] to [size]")
	if(href_list["fill"] && breasts?.reagents)
		var/percent = href_list["fill"] == "custom" ? input(usr, "Fill the breasts with their own milk to (%)", "Breast Test Panel", 75) as null|num : text2num(href_list["fill"])
		if(!isnull(percent))
			percent = clamp(percent, 0, 100)
			breasts.reagents.clear_reagents()
			var/datum/reagent/fluid = breasts.get_produced_reagent() || breasts.reagent_to_make
			if(fluid && percent)
				breasts.reagents.add_reagent(fluid, breasts.reagents.maximum_volume * percent / 100)
			breasts.update_engorgement()
			redraw()
			log_change("filled the breasts of [key_name(target)] to [percent]%")
	if(href_list["lactation"] && breasts)
		breasts.produces_fluid = !breasts.produces_fluid
		log_change("turned lactation [breasts.produces_fluid ? "on" : "off"] for [key_name(target)]")
	if(href_list["swelling"])
		if(HAS_TRAIT_FROM(target, TRAIT_FLUID_ENGORGEMENT, BREAST_PANEL_TRAIT_SOURCE))
			REMOVE_TRAIT(target, TRAIT_FLUID_ENGORGEMENT, BREAST_PANEL_TRAIT_SOURCE)
		else
			ADD_TRAIT(target, TRAIT_FLUID_ENGORGEMENT, BREAST_PANEL_TRAIT_SOURCE)
		breasts?.update_engorgement()
		redraw()
		log_change("toggled Swelling Glands on [key_name(target)]")
	if(href_list["enthusiast"])
		if(target.get_quirk(/datum/quirk/vice/breast_enthusiast))
			target.remove_quirk(/datum/quirk/vice/breast_enthusiast)
			log_change("removed the Breast Enthusiast vice from [key_name(target)]")
		else
			target.add_quirk(/datum/quirk/vice/breast_enthusiast)
			log_change("gave the Breast Enthusiast vice to [key_name(target)]")
	show(usr)

/datum/breast_test_panel/proc/redraw()
	target.update_body_parts(TRUE)
	target.update_inv_armor() // also the shirt and a breast-sized bra
	target.update_inv_cloak()
	target.update_breast_size_effect()

/datum/breast_test_panel/proc/log_change(message)
	log_admin("[key_name(usr)] [message] (Breast Test Panel).")
	message_admins("[key_name_admin(usr)] [message] (Breast Test Panel).")

#undef VV_HK_BREAST_TEST_PANEL
#undef BREAST_PANEL_REFRESH_MS
#undef BREAST_PANEL_TRAIT_SOURCE
