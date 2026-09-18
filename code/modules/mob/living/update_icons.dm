/mob/living/proc/update_effect_scaling()
	var/new_scale = max(0.2, 1 + ((get_chem_effect(CE_ENLARGING) - get_chem_effect(CE_SHRINKING)) * 0.1))
	if(new_scale == chemical_scale)
		return
	resize = new_scale / chemical_scale
	chemical_scale = new_scale
	update_transform()

/mob/living/regenerate_icons()
	if(HAS_TRAIT(src, TRAIT_NO_TRANSFORM))
		return 1
	update_inv_hands()
	update_inv_handcuffed()
	update_inv_legcuffed()

/mob/living/update_fire(fire_icon = "Generic_mob_burning")
	remove_overlay(FIRE_LAYER)
	if(on_fire || islava(loc))
		var/mutable_appearance/new_fire_overlay = mutable_appearance('icons/mob/OnFire.dmi', fire_icon, -FIRE_LAYER)
		if(divine_fire_stacks > fire_stacks)
			new_fire_overlay.color = list(0,0,0, 0,0,0, 0,0,0, 1,1,1)
		new_fire_overlay.appearance_flags = RESET_COLOR
		overlays_standing[FIRE_LAYER] = new_fire_overlay

	apply_overlay(FIRE_LAYER)
