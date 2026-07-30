SUBSYSTEM_DEF(blueprints)
	name = "Blueprint Visibility Manager"
	flags = SS_NO_FIRE

/// Hands a mob entering blueprint mode an image for every blueprint already standing.
/// Blueprints are alpha 0 / invisibility 100, so without this they are invisible and unclickable.
/datum/controller/subsystem/blueprints/proc/add_viewer_to_all(mob/viewer)
	if(!viewer?.client)
		return
	for(var/obj/structure/blueprint/blueprint in GLOB.active_blueprints)
		blueprint.add_viewer(viewer)

/// Drops every blueprint image held by a client leaving blueprint mode.
/datum/controller/subsystem/blueprints/proc/remove_viewer_from_all(client/viewer_client)
	if(!viewer_client)
		return
	for(var/obj/structure/blueprint/blueprint in GLOB.active_blueprints)
		blueprint.remove_viewer_client(viewer_client)

/// Shows a freshly set up blueprint to everyone currently in blueprint mode.
/datum/controller/subsystem/blueprints/proc/add_new_blueprint(obj/structure/blueprint/blueprint)
	for(var/mob/viewer in GLOB.player_list)
		if(HAS_TRAIT(viewer, TRAIT_BLUEPRINT_VISION) && viewer.client)
			blueprint.add_viewer(viewer)

/datum/controller/subsystem/blueprints/proc/remove_blueprint(obj/structure/blueprint/blueprint)
	blueprint.clear_all_viewers()
