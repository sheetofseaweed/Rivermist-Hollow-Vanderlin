// Blob sprites by VelSlime, ported from Ratwood/Ochre Valley.
// The same blob serves as an ooze's voluntary form and its vulnerable death remnant.
/mob/living/simple_animal/hostile/retaliate/ooze_blob
	name = "ooze"
	desc = "A translucent, animate mass of ooze."
	icon = 'modular_rmh/icons/mob/ooze_blob.dmi'
	icon_state = "ooze"
	icon_living = "ooze"
	icon_dead = "ooze_dead"
	color = "#88ff7d"
	footstep_type = FOOTSTEP_MOB_SLIME
	mob_biotypes = MOB_ORGANIC | MOB_BEAST
	faction = list("zombie")
	base_intents = list(/datum/intent/simple/bite)
	health = 65
	maxHealth = 65
	melee_damage_lower = 9
	melee_damage_upper = 14
	base_strength = 7
	base_constitution = 13
	base_speed = 9
	move_to_delay = 3
	vision_range = 7
	aggro_vision_range = 9
	simple_detect_bonus = 20
	defprob = 40
	deaggroprob = 0
	del_on_deaggro = 44 SECONDS
	retreat_health = 0.3
	remains_type = null
	food_type = list(/obj/item/reagent_containers/food/snacks, /obj/item/bodypart, /obj/item/organ)
	attack_sound = 'sound/gore/flesh_eat_03.ogg'
	ai_controller = /datum/ai_controller/volf/agile
	var/next_chomp = 0

/mob/living/simple_animal/hostile/retaliate/ooze_blob/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/ai_aggro_system)
	AddElement(/datum/element/ai_retaliate)
	AddElement(/datum/element/ai_flee_while_injured, 0.75, retreat_health)

/mob/living/simple_animal/hostile/retaliate/ooze_blob/AttackingTarget()
	. = ..()
	if(!. || !iscarbon(target) || world.time < next_chomp || !prob(8))
		return
	var/mob/living/carbon/victim = target
	next_chomp = world.time + 120 SECONDS
	if(base_strength + rand(0, 6) <= GET_MOB_ATTRIBUTE_VALUE(victim, STAT_CONSTITUTION))
		visible_message(span_warning("[src] fails to drag [victim] down!"))
		return
	victim.Knockdown(2 SECONDS)
	victim.adjustOxyLoss(10)
	victim.visible_message(span_danger("[src] pulls [victim] to the ground!"), span_danger("The ooze drags me down!"))
	playsound(victim, 'sound/foley/zfall.ogg', 100, FALSE)

/mob/living/simple_animal/hostile/retaliate/ooze_blob/get_sound(input)
	switch(input)
		if("aggro")
			return 'sound/foley/gross.ogg'
		if("pain")
			return 'sound/foley/butcher.ogg'
		if("death")
			return 'sound/foley/bubb (1).ogg'
		if("idle", "cidle")
			return pick('sound/foley/water_land2.ogg', 'sound/foley/water_land3.ogg')
	return ..()

/mob/living/simple_animal/hostile/retaliate/ooze_blob/suffering
	name = "suffering ooze"
	health = 25
	maxHealth = 25
	melee_damage_lower = 1
	melee_damage_upper = 1
	move_to_delay = 20
	base_strength = 2
	del_on_deaggro = null
	var/datum/weakref/source_body

/mob/living/simple_animal/hostile/retaliate/ooze_blob/suffering/Destroy()
	var/mob/living/carbon/human/body = source_body?.resolve()
	if(body)
		UnregisterSignal(body, COMSIG_LIVING_REVIVE)
	source_body = null
	return ..()

/mob/living/simple_animal/hostile/retaliate/ooze_blob/suffering/proc/link_body(mob/living/carbon/human/body)
	source_body = WEAKREF(body)
	RegisterSignal(body, COMSIG_LIVING_REVIVE, PROC_REF(on_body_revived))

/mob/living/simple_animal/hostile/retaliate/ooze_blob/suffering/proc/on_body_revived(mob/living/carbon/human/body, full_heal_flags)
	SIGNAL_HANDLER
	if(body.stat == DEAD)
		return
	if(mind?.current == src)
		mind.transfer_to(body, TRUE)
	to_chat(body, span_notice("My form coheres again."))
	qdel(src)

/mob/living/simple_animal/hostile/retaliate/ooze_blob/suffering/revive(full_heal_flags = NONE, excess_healing = 0, force_grab_ghost = FALSE)
	var/mob/living/carbon/human/body = source_body?.resolve()
	if(body && body.stat == DEAD)
		return body.revive(HEAL_ALL | HEAL_ORGANS)
	return ..()

/datum/action/cooldown/spell/undirected/shapeshift/ooze
	name = "Blob Form"
	desc = "Let my humanoid body collapse into a mobile ooze."
	charge_required = FALSE
	cooldown_time = 50 SECONDS
	possible_shapes = list(/mob/living/simple_animal/hostile/retaliate/ooze_blob)
	die_with_shapeshifted_form = FALSE
	convert_damage = FALSE

/datum/action/cooldown/spell/undirected/shapeshift/ooze/do_shapeshift(mob/living/caster)
	. = ..()
	if(!. || !ishuman(caster))
		return
	var/mob/living/carbon/human/human = caster
	var/mob/living/blob = .
	blob.color = "#[human.dna.features["mcolor"] || "79F299"]"
