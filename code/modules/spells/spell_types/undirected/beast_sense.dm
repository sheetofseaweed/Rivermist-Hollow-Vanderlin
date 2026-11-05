/datum/action/cooldown/spell/undirected/beast_sense
	name = "Beastial Senses"
	desc = "Grants a keen sense of smell and excellent vision for ten minutes, to better hunt with. The minor form lasts five."
	button_icon_state = "bestialsense"
	sound = 'sound/vo/smokedrag.ogg'

	spell_type = SPELL_MIRACLE
	antimagic_flags = MAGIC_RESISTANCE_HOLY
	associated_skill = /datum/attribute/skill/magic/holy

	invocation = "Beast-Lord, lend me the eyes of the zad, the nose of the volf."
	invocation_type = INVOCATION_WHISPER

	charge_required = FALSE
	cooldown_time = 10 MINUTES
	spell_cost = 20

	required_form = FORM_LIFE
	required_technique = TECHNIQUE_ILLUSION
	slot_level = 1
	minor_cost = SPELL_MINOR_COST_DEFAULT

/datum/action/cooldown/spell/undirected/beast_sense/can_cast_spell(feedback)
	. = ..()
	if(!.)
		return
	if(!iscarbon(owner))
		return FALSE
	var/mob/living/carbon/C = owner
	var/obj/item/organ/eyes/eyes = C.getorgan(/obj/item/organ/eyes)
	if(!eyes)
		if(feedback)
			to_chat(owner, span_warning("The tree father can not restore my eyes."))
		return FALSE

/datum/action/cooldown/spell/undirected/beast_sense/cast(atom/cast_on)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(grant_status), is_minor_cast()), rand(5 SECONDS, 9 SECONDS))

/// A Minor prayer lasts half the time.
/datum/action/cooldown/spell/undirected/beast_sense/proc/grant_status(minor = FALSE)
	var/mob/living/carbon/C = owner
	if(QDELETED(C))
		return
	to_chat(C, span_greentext("A raven passes overhead... your prayer was heard!"))
	playsound(C, 'sound/vo/mobs/bird/CROW_01.ogg', 60, TRUE, -1)
	C.apply_status_effect(/datum/status_effect/buff/beastsense, minor ? 5 MINUTES : null)
