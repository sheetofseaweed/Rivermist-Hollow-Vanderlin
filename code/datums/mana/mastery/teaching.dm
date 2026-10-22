// Teaching: a wizard who takes apprentices guides an adjacent caster into one of their own spells.

/// How long teacher and student must hold still together.
#define TEACH_SPELL_CHANNEL (20 SECONDS)
/// Form ranks below a spell's requirement a guided student may still learn at.
#define TEACH_SPELL_LEVEL_GRACE 1
/// Arcane experience the student gains from a finished lesson.
#define TEACH_SPELL_EXPERIENCE 30

/datum/action/innate/teach_spell
	name = "Teach Spell"
	desc = "Guide a caster beside me through one of my spells. We must both hold still for the lesson."
	button_icon = 'icons/mob/actions/roguespells.dmi'
	button_icon_state = "knowledge"
	/// Length of the shared channel; tests shorten it.
	var/channel_time = TEACH_SPELL_CHANNEL
	/// Student of the lesson under way, so a teacher runs one lesson at a time.
	var/datum/weakref/student_ref

/datum/action/innate/teach_spell/Activate()
	var/mob/living/teacher = owner
	if(!istype(teacher) || !teacher.mind)
		return
	if(student_ref?.resolve())
		to_chat(teacher, span_warning("I am already in the middle of a lesson."))
		return
	var/list/teachable = get_teachable_spells(teacher)
	if(!length(teachable))
		to_chat(teacher, span_warning("I know no spell I could put into words for another."))
		return
	var/list/students = get_students(teacher)
	if(!length(students))
		to_chat(teacher, span_warning("No caster stands beside me to teach."))
		return
	var/mob/living/student
	if(length(students) == 1)
		student = students[students[1]]
	else
		var/picked = tgui_input_list(teacher, "Whom do I teach?", "Teach Spell", students)
		student = picked ? students[picked] : null
	if(!student)
		return
	var/picked_spell = tgui_input_list(teacher, "Which spell do I teach [student]?", "Teach Spell", teachable)
	if(!picked_spell)
		return
	teach(teacher, student, teachable[picked_spell])

/// Name to mob for every caster adjacent to the teacher.
/datum/action/innate/teach_spell/proc/get_students(mob/living/teacher)
	var/list/students = list()
	for(var/mob/living/candidate in range(1, teacher))
		if(candidate == teacher || !candidate.mind?.spell_mastery || !teacher.Adjacent(candidate))
			continue
		var/key = candidate.name
		if(students[key])
			key = "[key] ([length(students) + 1])"
		students[key] = candidate
	return students

/// Name to typepath for every grimoire-worthy spell the teacher knows.
/datum/action/innate/teach_spell/proc/get_teachable_spells(mob/living/teacher)
	var/list/teachable = list()
	var/datum/spell_mastery/mastery = teacher.mind?.spell_mastery
	if(!mastery)
		return teachable
	for(var/datum/action/cooldown/spell/spell_path as anything in mastery.unlocked_spells)
		if(!initial(spell_path.learnable) || !initial(spell_path.required_form))
			continue
		teachable[initial(spell_path.name)] = spell_path
	return teachable

/// Runs the lesson: refusal check, shared channel, then the guided learn with rank grace.
/datum/action/innate/teach_spell/proc/teach(mob/living/teacher, mob/living/student, datum/action/cooldown/spell/spell_path)
	var/refusal = get_teach_refusal(teacher, student, spell_path)
	if(refusal)
		to_chat(teacher, span_warning(refusal))
		return FALSE
	var/spell_name = initial(spell_path.name)
	teacher.visible_message(
		span_notice("[teacher] begins guiding [student] through the shapes of [spell_name]."),
		span_notice("I begin guiding [student] through [spell_name]. We must both hold still."),
	)
	to_chat(student, span_notice("[teacher] is teaching me [spell_name]. I must stay close and hold still."))
	student_ref = WEAKREF(student)
	var/finished = do_after(teacher, channel_time, student, extra_checks = CALLBACK(src, PROC_REF(student_attends), teacher, student))
	student_ref = null
	if(!finished)
		if(!QDELETED(teacher))
			to_chat(teacher, span_warning("The lesson breaks off."))
		if(!QDELETED(student))
			to_chat(student, span_warning("The lesson breaks off."))
		return FALSE
	refusal = get_teach_refusal(teacher, student, spell_path)
	if(refusal)
		to_chat(teacher, span_warning(refusal))
		return FALSE
	var/datum/spell_mastery/student_mastery = student.mind.spell_mastery
	if(!student_mastery.try_learn_spell(spell_path, TEACH_SPELL_LEVEL_GRACE))
		to_chat(teacher, span_warning("[student] cannot take hold of [spell_name]."))
		return FALSE
	var/prepared_note = student_mastery.is_prepared(spell_path) ? "It waits ready in my mind." : "I can prepare it from my grimoire."
	teacher.visible_message(
		span_notice("[student] traces [spell_name] back to [teacher] without a flaw."),
		span_notice("[student] holds [spell_name] now. My lesson is done."),
	)
	to_chat(student, span_notice("Under [teacher]'s guidance [spell_name] settles into my mind. [prepared_note]"))
	student.adjust_experience(/datum/attribute/skill/magic/arcane, TEACH_SPELL_EXPERIENCE)
	return TRUE

/// The channel holds while the student stays conscious and beside the teacher.
/datum/action/innate/teach_spell/proc/student_attends(mob/living/teacher, mob/living/student)
	return !QDELETED(student) && student.stat == CONSCIOUS && teacher.Adjacent(student)

/// Why the lesson cannot happen now, or null when the student may learn the spell.
/datum/action/innate/teach_spell/proc/get_teach_refusal(mob/living/teacher, mob/living/student, datum/action/cooldown/spell/spell_path)
	var/datum/spell_mastery/mastery = teacher.mind?.spell_mastery
	var/spell_name = initial(spell_path.name)
	if(!mastery || !(spell_path in mastery.unlocked_spells))
		return "I do not know [spell_name] well enough to teach it."
	var/form = initial(spell_path.required_form)
	if(!initial(spell_path.learnable) || !form)
		return "[spell_name] is not a spell that can be taught."
	if(!istype(student) || student == teacher)
		return "I need a student other than myself."
	var/datum/spell_mastery/student_mastery = student.mind?.spell_mastery
	if(!student_mastery)
		return "[student] has no grasp of the arcyne to build on."
	if(student.stat != CONSCIOUS)
		return "[student] is in no state to learn."
	if(!teacher.Adjacent(student))
		return "[student] must stand beside me."
	if(spell_path in student_mastery.unlocked_spells)
		return "[student] already knows [spell_name]."
	if(student_mastery.can_learn_spell(spell_path, TEACH_SPELL_LEVEL_GRACE))
		return null
	var/needed_level = max(0, initial(spell_path.required_level) - TEACH_SPELL_LEVEL_GRACE)
	if(needed_level > 0 && student_mastery.get_form_level(form) < needed_level)
		return "[student] needs [needed_level] point[needed_level == 1 ? "" : "s"] of [form] mastery before I can guide [student.p_them()] into [spell_name]."
	if((student_mastery.spendable_form_points[form] || 0) < 1)
		return "[student] has no free point of [form] mastery to spend on [spell_name]."
	var/technique = initial(spell_path.required_technique)
	if(technique && (student_mastery.spendable_technique_points[technique] || 0) < 1)
		return "[student] has no free point of [technique] mastery to spend on [spell_name]."
	return "[student] has not learned the spells [spell_name] builds on."

#undef TEACH_SPELL_CHANNEL
#undef TEACH_SPELL_LEVEL_GRACE
#undef TEACH_SPELL_EXPERIENCE
