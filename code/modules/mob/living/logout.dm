/mob/living/Logout()
	var/turf/current_turf = get_turf(src)
	update_z(null)
	SStrackables.unwatch_mob(src)
	..()
	// Logout removes the client registration, but the SSD mob still belongs to its z-level.
	if(current_turf && !QDELETED(src))
		update_z(current_turf.z)
	if(!key && mind)	//key and mind have become separated.
		mind.active = 0	//This is to stop say, a mind.transfer_to call on a corpse causing a ghost to re-enter its body.
	if(client)
		client.reset_shadow_pool()
