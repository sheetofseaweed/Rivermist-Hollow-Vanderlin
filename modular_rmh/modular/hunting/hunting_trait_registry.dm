// Hunting & Tracking pack - registering the trait into the core listings from the modular layer.
//
// Right-clicking SKILLS on the HUD does not list skills - it walks GLOB.roguetraits and prints
// every trait the mob has. The admin trait panel walks GLOB.traits_by_type, and the readable name
// comes from GLOB.trait_name_map, which is generated from traits_by_type. A trait absent from
// those lists still works perfectly - it just never shows up anywhere.
//
// Both lists live in code/_globalvars/traits.dm and cannot reference a define declared in this
// layer, since core is included first. So instead of editing them we append at init: BYOND
// initializes globals in include order, and this file sits at the end of the .dme, so
// GLOB.roguetraits and GLOB.traits_by_type are both already built by the time this runs.

GLOBAL_LIST_INIT(hunting_trait_registration, register_hunting_traits())

/proc/register_hunting_traits()
	GLOB.roguetraits[TRAIT_PERFECT_TRACKER] = span_info("I can read any track, no matter how faint or old, as clear as day.")
	// Keyed by the readable name on purpose: generate_trait_name_map() inverts this list, so the
	// SKILLS readout and the admin panel both end up showing "Master Tracker" rather than the
	// raw define name.
	if(islist(GLOB.traits_by_type[/mob]))
		GLOB.traits_by_type[/mob]["Master Tracker"] = TRAIT_PERFECT_TRACKER
	// Force a rebuild in case something already generated the map from the un-appended lists.
	GLOB.trait_name_map = null
	return list()
