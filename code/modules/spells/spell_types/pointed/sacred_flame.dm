/datum/action/cooldown/spell/sacred_flame
	name = "Sacred Flame"
	desc = "Burn the target with divine light."
	button_icon_state = "sacredflame"
	sound = 'sound/magic/heal.ogg'
	charge_sound = 'sound/magic/holycharging.ogg'

	spell_type = SPELL_MIRACLE
	antimagic_flags = MAGIC_RESISTANCE_HOLY
	associated_skill = /datum/attribute/skill/magic/holy

	invocation = "Cleansing flames, kindle!"
	invocation_type = INVOCATION_SHOUT

	charge_required = FALSE
	cooldown_time = 10 SECONDS
	spell_cost = 40

	slot_level = 1
	slot_only = TRUE
	slot_label = "Sacred Flame"

	var/stacks_to_add = 3

/datum/action/cooldown/spell/sacred_flame/before_cast(atom/cast_on)
	. = ..()
	stacks_to_add = initial(stacks_to_add)
	switch(get_effect_level())
		if(2)
			stacks_to_add = 4
		if(3)
			stacks_to_add = 5
		if(4)
			stacks_to_add = 7
		if(5)
			stacks_to_add = 9

/datum/action/cooldown/spell/sacred_flame/cast(atom/cast_on)
	. = ..()
	if(!ismob(cast_on))
		if(cast_on.fire_act())
			owner.visible_message(
				"<font color='yellow'>[owner] points at [cast_on], igniting it with sacred flames!</font>",
				"<font color='yellow'>I point at [cast_on], igniting it with sacred flames!</font>",
			)
		else
			owner.visible_message(
				"<font color='yellow'>[owner] points at [cast_on], but it fails to catch fire.</font>",
				"<font color='yellow'>I point at [cast_on], but it fails to catch fire.</font>",
			)
		return
	if(!isliving(cast_on))
		return
	var/mob/living/heretic = cast_on
	owner.visible_message(
		"<font color='yellow'>[owner] points at [heretic], igniting [heretic.p_them()] with sacred flames!!</font>",
		"<font color='yellow'>I point at [heretic], igniting  [heretic.p_them()] with sacred flames!!</font>",
	)
	playsound(heretic, 'sound/items/flint.ogg', 150, FALSE)
	heretic.adjust_divine_fire_stacks(stacks_to_add)
	heretic.IgniteMob()
