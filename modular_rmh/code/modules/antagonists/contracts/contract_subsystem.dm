SUBSYSTEM_DEF(contracts)
	name = "Antag Contracts"
	flags = SS_BACKGROUND | SS_NO_INIT
	runlevels = RUNLEVEL_GAME
	wait = 1 MINUTES
	var/list/datum/contract_party/contract_parties = list()

/datum/controller/subsystem/contracts/proc/register(datum/contract_party/party)
	contract_parties |= party

/datum/controller/subsystem/contracts/proc/deregister(datum/contract_party/party)
	contract_parties -= party

/datum/controller/subsystem/contracts/fire(resumed)
	// Iterate a copy: pruning removes from the live list, which would skip the next element
	for(var/datum/contract_party/party as anything in contract_parties.Copy())
		if(QDELETED(party) || !length(party.antags))
			contract_parties -= party
			continue
		var/datum/antag_contract/contract = party.current_contract
		if(!contract)
			continue
		if(!party.has_online_member())
			contract.offline_deciseconds += wait
		if(world.time >= contract.deadline)
			party.close_contract_cycle()
