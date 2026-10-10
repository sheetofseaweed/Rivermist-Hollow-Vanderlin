/// Puts an agent NPC on the map at round start: character, outfit, shop and post. Mappers set the vars.
/obj/effect/agent_npc_spawner
	name = "agent NPC spawner"
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x2"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	/// A character written in the profile menu, by its name there. Tried first.
	var/profile_name
	/// The built-in character, used when profile_name is unset or not saved on this server.
	var/profile_type = /datum/agent_profile/villager
	/// The body. Any other mob than the agent one gets the agent controller attached.
	var/mob_type = /mob/living/carbon/human/species/human/northern/agent_social
	/// Clothes and kit, or null for what the body comes with.
	var/outfit
	/// Their name, or null for a random one.
	var/npc_name
	/// MALE or FEMALE, or null to keep whichever the body rolled.
	var/body_gender
	/// A /datum/agent_stock type to keep a shop, or null for none.
	var/shop_type
	/// Keep to this tile when idle, facing the way the spawner faces.
	var/keeps_post = TRUE

/obj/effect/agent_npc_spawner/Initialize(mapload)
	. = ..()
	// Late, so every subsystem the body and its outfit need has started.
	return INITIALIZE_HINT_LATELOAD

/obj/effect/agent_npc_spawner/LateInitialize()
	spawn_npc()
	qdel(src)

/obj/effect/agent_npc_spawner/proc/spawn_npc()
	var/turf/here = get_turf(src)
	if(!here || !ispath(mob_type, /mob/living))
		return null
	var/mob/living/spawned = new mob_type(here)
	var/mob/living/carbon/human/body = spawned
	if(body_gender && istype(body) && body.gender != body_gender)
		agent_set_body_gender(body, body_gender)
	if(npc_name)
		spawned.fully_replace_character_name(spawned.real_name, npc_name)
	if(outfit && istype(body))
		body.equipOutfit(outfit)
	spawned.setDir(dir)

	var/datum/agent_profile/chosen = resolve_profile()
	if(istype(spawned.ai_controller, /datum/ai_controller/agent_social))
		agent_swap_profile(spawned, chosen)
	else
		agent_attach_controller(spawned, chosen)
	var/datum/ai_controller/agent_social/agent = spawned.ai_controller
	if(istype(agent))
		agent.register_cooldown = 0
		agent.ensure_registered()
		if(keeps_post)
			agent.set_post(here, dir)

	if(shop_type)
		spawned.AddComponent(/datum/component/agent_shop, shop_type)
	return spawned

/obj/effect/agent_npc_spawner/proc/resolve_profile()
	RETURN_TYPE(/datum/agent_profile)
	if(profile_name)
		if(!length(GLOB.agent_custom_profiles))
			SSagent_npc?.load_profiles()
		var/datum/agent_profile/custom = GLOB.agent_custom_profiles[profile_name]
		if(!QDELETED(custom))
			return custom
		log_mapping("Agent NPC spawner at [AREACOORD(src)]: no saved profile named '[profile_name]', using [profile_type].")
	return agent_resolve_profile("[profile_type]")

/// Ready-made merchants. Spawn one with the admin Spawn verb to test in a round, or place it on a map.
/obj/effect/agent_npc_spawner/merchant
	name = "agent merchant spawner (grocer)"
	profile_type = /datum/agent_profile/merchant
	shop_type = /datum/agent_stock/supplier/food

/obj/effect/agent_npc_spawner/merchant/tools
	name = "agent merchant spawner (toolseller)"
	shop_type = /datum/agent_stock/supplier/tools

/obj/effect/agent_npc_spawner/merchant/clothier
	name = "agent merchant spawner (clothier)"
	shop_type = /datum/agent_stock/supplier/apparel

/obj/effect/agent_npc_spawner/merchant/pawnbroker
	name = "agent merchant spawner (pawnbroker)"
	shop_type = /datum/agent_stock/dealer

/// Sells company by the quarter hour. Put it at the baths.
/obj/effect/agent_npc_spawner/performer
	name = "agent performer spawner"
	profile_type = /datum/agent_profile/performer
	shop_type = /datum/agent_stock/service
	outfit = /datum/outfit/agent_performer
	body_gender = FEMALE

/obj/effect/agent_npc_spawner/performer/male
	name = "agent performer spawner (male)"
	body_gender = MALE

/// Serves the tavern and chooses her own company. Put it in the tavern.
/obj/effect/agent_npc_spawner/barmaid
	name = "agent barmaid spawner"
	profile_type = /datum/agent_profile/barmaid
	outfit = /datum/outfit/agent_barmaid
	body_gender = FEMALE

/// A plain dress and apron, and nothing on it worth killing for.
/datum/outfit/agent_barmaid
	name = "Agent Barmaid"
	shirt = /obj/item/clothing/shirt/dress/gen/colored/brown
	cloak = /obj/item/clothing/cloak/apron/waist/colored/brown
	shoes = /obj/item/clothing/shoes/simpleshoes

/datum/outfit/agent_barmaid/pre_equip(mob/living/carbon/human/H)
	. = ..()
	if(H.gender == MALE)
		shirt = /obj/item/clothing/shirt/undershirt/colored/random
		pants = /obj/item/clothing/pants/tights/colored/random

/// Light clothes and free hands. Nothing on it is worth killing for.
/datum/outfit/agent_performer
	name = "Agent Performer"
	shirt = /obj/item/clothing/shirt/nightgown/colored/random
	shoes = /obj/item/clothing/shoes/sandals

/datum/outfit/agent_performer/pre_equip(mob/living/carbon/human/H)
	. = ..()
	if(H.gender == MALE)
		shirt = /obj/item/clothing/shirt/undershirt/colored/random
		pants = /obj/item/clothing/pants/tights/colored/random

/// A fresh body made the other sex: a fitting name, and no beard on a woman.
/proc/agent_set_body_gender(mob/living/carbon/human/body, new_gender)
	body.gender = new_gender
	if(new_gender == FEMALE)
		var/datum/bodypart_feature/beard = body.get_bodypart_feature_of_slot(BODYPART_FEATURE_FACIAL_HAIR)
		var/obj/item/bodypart/head/head = body.get_bodypart(BODY_ZONE_HEAD)
		if(beard && head)
			head.remove_bodypart_feature(beard)
	if(body.dna?.species)
		body.fully_replace_character_name(body.real_name, body.dna.species.random_name(new_gender, TRUE))
	body.regenerate_icons()
