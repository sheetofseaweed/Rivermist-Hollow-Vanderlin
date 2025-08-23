/mob/living/carbon/human/proc/id_check_in_5()
	addtimer(CALLBACK(src, PROC_REF(age_verify)), 5 SECONDS)

/mob/living/carbon/human/proc/age_verify()
	if(age == AGE_CHILD) // ABSOLUTELY NOT.
		message_admins("[src] HAS LOADED IN AS A CHILD.")
		stack_trace("[src] HAS LOADED IN AS A CHILD")
		QDEL_IN(src, 5 SECONDS)
