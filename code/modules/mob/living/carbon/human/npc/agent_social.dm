/**
 * The pilot agent NPC.
 *
 * A plain townsperson with no combat kit and no hostile faction. Its controller
 * cannot fight, so this mob is safe to leave running when the sidecar is down:
 * it stands, resists, and runs away.
 */
/mob/living/carbon/human/species/human/northern/agent_social
	name = "villager"
	ai_controller = /datum/ai_controller/agent_social
	faction = list(FACTION_TOWN)
	ambushable = FALSE
	flee_in_pain = TRUE
	wander = FALSE
