// safety

/datum/controller/subsystem/job/proc/younglings_assertion()
	for(var/datum/job/job as anything in all_occupations)
		for(var/age as anything in job.allowed_ages)
			if(age == AGE_CHILD)
				stack_trace("[job] IS ALLOWING YOUNGLINGS.")


/datum/controller/subsystem/job/proc/remove_younglings()
	for(var/datum/job/job as anything in all_occupations)
		job.allowed_ages -= AGE_CHILD
		if(!length(job.allowed_ages))
			all_occupations -= job
			name_occupations -= job.title
			type_occupations -= job.type
			joinable_occupations -= job
			qdel(job)
	younglings_assertion()
