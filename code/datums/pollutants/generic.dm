///Splashing blood makes a tiny bit of this
/datum/pollutant/metallic_scent
	name = "Metallic Scent"
	pollutant_flags = POLLUTANT_SMELL
	smell_intensity = 1
	descriptor = "smell"
	scent = "a metallic scent"

/datum/pollutant/rot/sewage
	name = "Sewage Scent"
	pollutant_flags = POLLUTANT_SMELL|POLLUTANT_APPEARANCE //RMH EDITED - smell only, no miasma
	smell_intensity = 1
	descriptor = "smell"
	scent = "sewage"
	color = "#3a6600"

//RMH EDITED START - rot is a faint smell only; breathing it no longer gives miasma
/datum/pollutant/rot
	name = "Rotten Scent"
	pollutant_flags = POLLUTANT_SMELL
	smell_intensity = 0.5
	descriptor = "smell"
	scent = "a rotten scent"
	color = "#3a6600"
//RMH EDITED END

/datum/pollutant/steam
	name = "Steam Scent"
	pollutant_flags = POLLUTANT_SMELL
	smell_intensity = 0.75
	descriptor = "smell"
	scent = "a steamy scent"
	color = "#ffffff"
