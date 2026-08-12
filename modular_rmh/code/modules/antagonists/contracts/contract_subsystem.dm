SUBSYSTEM_DEF(contracts)
	name = "Antag Contracts"
	flags = SS_BACKGROUND | SS_NO_INIT
	runlevels = RUNLEVEL_GAME
	wait = 1 MINUTES
	var/list/datum/antagonist/contracted_antags = list()

/datum/controller/subsystem/contracts/proc/register(datum/antagonist/antag)
	contracted_antags |= antag

/datum/controller/subsystem/contracts/proc/deregister(datum/antagonist/antag)
	contracted_antags -= antag

/datum/controller/subsystem/contracts/fire(resumed)
	// Iterate a copy: pruning removes from the live list, which would skip the next element
	for(var/datum/antagonist/antag as anything in contracted_antags.Copy())
		if(QDELETED(antag) || !antag.owner)
			contracted_antags -= antag
			continue
		var/datum/antag_contract/contract = antag.current_contract
		if(!contract)
			continue
		if(!antag.owner.current?.client)
			contract.offline_deciseconds += wait
		if(world.time >= contract.deadline)
			antag.close_contract_cycle()
