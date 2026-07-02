/datum/status_effect/buff/tempo_one
	id = "tempo_1"
	duration = 30 SECONDS
	status_type = STATUS_EFFECT_REFRESH
	alert_type = null

/datum/status_effect/buff/tempo_one/on_apply()
	. = ..()
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.stamina = max(H.stamina - (H.maximum_stamina / 3), 0)
	to_chat(owner, span_info("Tempo!"))

/datum/status_effect/buff/tempo_two
	id = "tempo_2"
	duration = 30 SECONDS
	status_type = STATUS_EFFECT_REFRESH
	alert_type = null

/datum/status_effect/buff/tempo_two/on_apply()
	. = ..()
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.stamina = max(H.stamina - (H.maximum_stamina / 2), 0)
	to_chat(owner, span_notice("Tempo!!"))

/datum/status_effect/buff/tempo_three
	id = "tempo_3"
	duration = 30 SECONDS
	status_type = STATUS_EFFECT_REFRESH
	alert_type = null

/datum/status_effect/buff/tempo_three/on_apply()
	. = ..()
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.stamina = 0
	to_chat(owner, span_notice("<b>TEMPO!!!</b>"))
