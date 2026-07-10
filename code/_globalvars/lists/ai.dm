///all basic ai subtrees
GLOBAL_LIST_EMPTY(ai_subtrees)

///basic ai controllers based on status
GLOBAL_LIST_INIT(ai_controllers_by_status, list(
	AI_STATUS_ON = list(),
	AI_STATUS_OFF = list(),
	AI_STATUS_IDLE = list(),
))

/// Faction alliances used by basic AI target selection. Relations are treated symmetrically by the checker.
GLOBAL_LIST_INIT(ai_faction_allies, list(
	FACTION_UNDEAD = list(FACTION_MINOTAURS),
))

///basic ai controllers based on their z level
GLOBAL_LIST_EMPTY(ai_controllers_by_zlevel)
