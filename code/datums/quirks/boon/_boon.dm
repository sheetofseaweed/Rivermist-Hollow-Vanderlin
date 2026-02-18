/datum/quirk/boon
	abstract_type = /datum/quirk/boon
	quirk_category = QUIRK_BOON

/datum/quirk/boon/keen_eye
	name = "Keen Eye"
	desc = "Years of hunting and tracking have honed your sight. You're better at noticing details and spotting hidden things."
	point_value = -5
	incompatible_quirks = list(
		/datum/quirk/vice/bad_sight
	)

/datum/quirk/boon/night_vision
	name = "Night Vision"
	desc = "You can see better in darkness than most. Perhaps you have elf blood, or maybe you just spent too many nights as a watchman."
	point_value = -4
	incompatible_quirks = list(
		/datum/quirk/vice/bad_sight,
		/datum/quirk/vice/cyclops_left,
		/datum/quirk/vice/cyclops_right
	)

/datum/quirk/boon/night_vision/on_spawn()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	H.lighting_alpha = LIGHTING_PLANE_ALPHA_LESSER_NV_TRAIT
	H.update_sight()

/datum/quirk/boon/night_vision/on_remove()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	H.lighting_alpha = initial(H.lighting_alpha)
	H.update_sight()

/datum/quirk/boon/light_footed
	name = "Light Footed"
	desc = "You move with grace and agility. Your steps are quieter then most."
	point_value = -6

/datum/quirk/boon/light_footed/on_spawn()
	if(!ishuman(owner))
		return
	ADD_TRAIT(owner, TRAIT_LIGHT_STEP, "[type]")

/datum/quirk/boon/light_footed/on_remove()
	if(!ishuman(owner))
		return
	REMOVE_TRAIT(owner, TRAIT_LIGHT_STEP, "[type]")

/datum/quirk/boon/quick_learner
	name = "Quick Learner"
	desc = "You pick up new skills faster than most. Your mind is sharp and eager to learn."
	point_value = -5

/datum/quirk/boon/iron_will
	name = "Iron Will"
	desc = "Your resolve is unshakeable. You handle the horrors of war better then most."
	point_value = -4

/datum/quirk/boon/iron_will/on_spawn()
	ADD_TRAIT(owner, TRAIT_STEELHEARTED, "[type]")

/datum/quirk/boon/iron_will/on_remove()
	if(owner)
		REMOVE_TRAIT(owner, TRAIT_STEELHEARTED, "[type]")

/datum/quirk/boon/composed
	name = "Composed"
	desc = "You handle stress better than most. Pressure doesn't get to you as easily."
	point_value = -3

/datum/quirk/boon/composed/on_life(mob/living/user)
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	if(prob(1) && H.get_stress_amount() > 5)
		H.adjust_stress(-1)

/* This is a future idea
/datum/quirk/boon/light_sleeper
	name = "Light Sleeper"
	desc = "You wake easily and need less sleep than most. Years of dangerous living have trained you to be alert even in rest."
	point_value = -2

/datum/quirk/boon/light_sleeper/on_spawn()
	ADD_TRAIT(owner, TRAIT_LIGHT_SLEEPER, "[type]")

/datum/quirk/boon/light_sleeper/on_remove()
	REMOVE_TRAIT(owner, TRAIT_LIGHT_SLEEPER, "[type]")
*/

/datum/quirk/boon/second_language
	name = "Second Language"
	desc = "You know an additional language."
	quirk_category = QUIRK_BOON
	point_value = -1
	customization_label = "Choose Language"
	customization_options = list(
		/datum/language/elvish,
		/datum/language/dwarvish,
		/datum/language/deepspeak,
		/datum/language/zalad,
		/datum/language/oldpsydonic,
		/datum/language/hellspeak,
		/datum/language/orcish,
	)

/datum/quirk/boon/second_language/on_spawn()
	if(!customization_value || !ispath(customization_value, /datum/language))
		return

	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.grant_language(customization_value)

/datum/quirk/boon/pet
	name = "Loyal Companion"
	desc = "You have a loyal animal companion that will follow and protect you."
	point_value = -3
	customization_label = "Choose Pet Type"
	preview_render = FALSE
	customization_options = list(
		/mob/living/simple_animal/pet/cat/cabbit,
		/mob/living/simple_animal/pet/cat/black,
		/mob/living/simple_animal/hostile/retaliate/frog,
		/mob/living/simple_animal/hostile/retaliate/chicken,
		/mob/living/simple_animal/hostile/retaliate/fox,
		/mob/living/simple_animal/hostile/retaliate/raccoon,
	)

	/// Reference to the spawned pet
	var/mob/living/simple_animal/pet_mob

/datum/quirk/boon/pet/on_spawn()
	if(!get_turf(owner))
		addtimer(CALLBACK(src, PROC_REF(on_spawn)), 0.5 SECONDS)
		return

	if(!ishuman(owner))
		return

	var/mob/living/carbon/human/H = owner

	// Check if a pet type was selected
	if(!customization_value || !ispath(customization_value, /mob/living/simple_animal))
		customization_value = /mob/living/simple_animal/pet/cat/black

	// Spawn the pet at the owner's location
	pet_mob = new customization_value(get_turf(H))

	if(!pet_mob)
		return

	// Tame the pet to the owner
	pet_mob.tamed(H)
	ADD_TRAIT(pet_mob, TRAIT_TINY, "[type]")

	// Set a name if the pet doesn't have a unique one
	if(pet_mob.name == initial(pet_mob.name))
		var/new_name = stripped_input(H, "What is your pet's name?", "Pet Name", initial(pet_mob.name), MAX_NAME_LEN)
		if(new_name)
			pet_mob.fully_replace_character_name(null, new_name)

	var/datum/component/obeys_commands/command_component = pet_mob.GetComponent(/datum/component/obeys_commands)
	if(command_component)
		var/datum/pet_command/follow/follow_command = command_component.available_commands["Follow"]
		if(follow_command)
			pet_mob.ai_controller?.set_blackboard_key(BB_CURRENT_PET_TARGET, H)
			follow_command.execute_action(pet_mob.ai_controller)

/datum/quirk/boon/pet/on_remove()
	// Don't delete the pet when quirk is removed, just release it
	if(pet_mob && !QDELETED(pet_mob))
		pet_mob.owner = null
		pet_mob.tame = FALSE
		pet_mob = null

/datum/quirk/boon/pet/get_option_name(option)
	if(ispath(option, /mob/living/simple_animal))
		var/mob/living/simple_animal/A = option
		return initial(A.name)
	return ..()

/datum/quirk/boon/folk_hero
	name = "Folk Hero"
	desc = "You're a local legend who saved your community from great danger. People recognize you, even as a foreigner."
	point_value = -10
	blocked_ages = list(
		AGE_CHILD,
	)
	preview_render = FALSE

/datum/quirk/boon/folk_hero/on_spawn()
	if(!ishuman(owner))
		return
	RegisterSignal(owner, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/quirk/boon/folk_hero/on_remove()
	if(!ishuman(owner))
		return
	UnregisterSignal(owner, COMSIG_PARENT_EXAMINE)

/datum/quirk/boon/folk_hero/proc/on_examine(mob/living/source, mob/user, list/examine_list)
	if(!ishuman(user) || !ishuman(source))
		return

	var/mob/living/carbon/human/H = source
	var/mob/living/carbon/human/examiner = user

	if(!examiner.mind || !H.mind)
		return

	// Folk heroes are recognized by others
	if(prob(80)) // 80% chance people recognize them
		examine_list += span_notice("You recognize [H.real_name], the folk hero!")

		// Add them to known people if not already known
		if(!examiner.mind.do_i_know(H.mind))
			examiner.mind.i_know_person(H.mind)
			H.mind.i_know_person(examiner.mind)

/datum/quirk/boon/quick_hands
	name = "Quick Hands"
	desc = "You have great hand-eye coordination and know how to move your fingers fast. All crafts are 10% faster."
	point_value = -4

/datum/quirk/boon/quick_hands/on_spawn()
	if(!ishuman(owner))
		return
	ADD_TRAIT(owner, TRAIT_QUICK_HANDS, "[type]")

/datum/quirk/boon/quick_hands/on_remove()
	if(!ishuman(owner))
		return
	REMOVE_TRAIT(owner, TRAIT_QUICK_HANDS, "[type]")

/datum/quirk/boon/naturalist
	name = "Naturalist"
	desc = "Your body is attuned to the natural world. You extract more nourishment from unprocessed, natural foods - fruits, vegetables, and simple preparations sustain you better than they do others."
	point_value = -8

/datum/quirk/boon/naturalist/on_spawn()
	ADD_TRAIT(owner, TRAIT_FORAGER, "[type]")

/datum/quirk/boon/naturalist/on_remove()
	if(!ishuman(owner))
		return
	REMOVE_TRAIT(owner, TRAIT_FORAGER, "[type]")

/datum/quirk/boon/always_prepared
	name = "Always Prepared"
	desc = "You start with a cart, lantern, and tent. You're ready for anything."
	point_value = -6
	preview_render = FALSE
	incompatible_quirks = list(
		/datum/quirk/vice/rough_start,
	)
	customization_label = "With or Without Cart"
	customization_options = list(
		"With Cart",
		"Without Cart"
	)

	var/obj/item/flashlight/flare/torch/lantern/L
	var/obj/item/tent_kit/tent

/datum/quirk/boon/always_prepared/on_spawn()
	if(!owner)
		return
	if(!customization_value)
		customization_value = "Without Cart"


	var/turf/T = get_turf(owner)

	if(customization_value == "With Cart")
		L = new(T)
		tent = new(T)
		var/obj/structure/handcart/cart = new(T)
		cart.put_in(null, L)
		cart.put_in(null, tent)

	to_chat(owner, span_notice("Your equipment is ready. You're well prepared for the journey ahead."))

/datum/quirk/boon/always_prepared/after_job_spawn(datum/job/job)
	if(customization_value == "Without Cart") // we run this shit back incase jobs changed stuff
		var/turf/T = get_turf(owner)
		L = new(T)
		tent = new(T)
		if(!owner.equip_to_appropriate_slot(L) || isturf(L.loc)) //missing a limb can cause phantom success procs
			for(var/obj/item/storage/storage in owner.contents)
				if(storage)
					if(SEND_SIGNAL(storage, COMSIG_TRY_STORAGE_INSERT, L, null))
						break
		if(!owner.equip_to_appropriate_slot(tent)|| isturf(tent.loc))
			for(var/obj/item/storage/storage in owner.contents)
				if(storage)
					if(SEND_SIGNAL(storage, COMSIG_TRY_STORAGE_INSERT, tent, null))
						break
	L = null
	tent = null

/datum/quirk/boon/rider
	name = "Experienced Rider"
	desc = "You begin with expert riding skills and your own mount."
	point_value = -6
	preview_render = FALSE

/datum/quirk/boon/rider/on_spawn()
	if(!owner || !ishuman(owner))
		return

	var/mob/living/carbon/human/H = owner

	var/turf/T = get_turf(owner)
	if(!T)
		return
	var/mob/living/simple_animal/hostile/retaliate/saiga/S = new(T)
	S.tamed(H)

	to_chat(owner, span_notice("Your trusted mount awaits you."))

/datum/quirk/boon/rider/after_job_spawn(datum/job/job)
	. = ..()
	if(!owner || !ishuman(owner))
		return

	var/mob/living/carbon/human/H = owner
	H.clamped_adjust_skillrank(/datum/skill/misc/riding, 2, 2, TRUE)

/datum/quirk/boon/beautiful
	name = "Strikingly Beautiful"
	desc = "You are remarkably attractive, improving social interactions."
	point_value = -2

/datum/quirk/boon/beautiful/on_spawn()
	if(!owner)
		return

	ADD_TRAIT(owner, TRAIT_BEAUTIFUL, "[type]")

	to_chat(owner, span_notice("You catch your reflection and can't help but admire yourself."))

/datum/quirk/boon/beautiful/on_remove()
	if(!owner)
		return
	REMOVE_TRAIT(owner, TRAIT_BEAUTIFUL, "[type]")

/datum/quirk/boon/value
	name = "Skilled Appraiser"
	desc = "I know how to estimate an item's value, more or less."
	point_value = -2

/datum/quirk/boon/value/on_spawn()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	ADD_TRAIT(H, TRAIT_SEEPRICES, "[type]")

/datum/quirk/boon/night_owl
	name = "Night Owl"
	desc = "I've always preferred Lune over Elysius. I am no longer fatigued by being tired."
	point_value = -3

/datum/quirk/boon/night_owl/on_spawn()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	ADD_TRAIT(H, TRAIT_NIGHT_OWL, "[type]")

/datum/quirk/duelist
	name = "Sword Training"
	desc = "I sword training and stashed a short sword."
	point_value = -2

/datum/quirk/boon/duelist/on_spawn()
	var/mob/living/carbon/human/H = owner
	H.adjust_skillrank_up_to(/datum/skill/combat/swords, 3, TRUE)
	if(H.mind)
		H.mind.special_items["Short Sword"] = /obj/item/weapon/sword/short

/datum/quirk/boon/fence
	name = "Fencer"
	desc = "I have trained in agile sword fighting. I dodge more easily without wearing anything and have stashed my rapier nearby."
	point_value = -4

/datum/quirk/boon/fence/on_spawn()
	var/mob/living/carbon/human/H = owner
	ADD_TRAIT(H, TRAIT_DODGEEXPERT, "[type]")
	H.adjust_skillrank_up_to(/datum/skill/combat/swords, 3, TRUE)
	if(H.mind)
		H.mind.special_items["Rapier"] = /obj/item/weapon/sword/rapier

/datum/quirk/boon/duelist
	name = "Sword Training"
	desc = "I sword training and stashed a short sword."
	point_value = -2

/datum/quirk/boon/duelist/on_spawn()
	var/mob/living/carbon/human/H = owner
	H.adjust_skillrank_up_to(/datum/skill/combat/swords, 3, TRUE)
	if(H.mind)
		H.mind.special_items["Short Sword"] = /obj/item/weapon/sword/short

/datum/quirk/boon/training2
	name = "Mace Training"
	desc = "I have mace training and stashed a mace."
	point_value = -3

/datum/quirk/boon/training2/on_spawn()
	var/mob/living/carbon/human/H = owner
	H.adjust_skillrank_up_to(/datum/skill/combat/axesmaces, 3, TRUE)
	if(H.mind)
		H.mind.special_items["Mace"] = /obj/item/weapon/mace/spiked

/datum/quirk/boon/training4
	name = "Polearms Training"
	desc = "I have polearm training and stashed a spear."
	point_value = -3

/datum/quirk/boon/training4/on_spawn()
	var/mob/living/carbon/human/H = owner
	H.adjust_skillrank_up_to(/datum/skill/combat/polearms, 3, TRUE)
	if(H.mind)
		H.mind.special_items["Spear"] = /obj/item/weapon/polearm/spear

/datum/quirk/boon/training5
	name = "Knife Training"
	desc = "I have knife training and stashed a parrying dagger."
	point_value = -3

/datum/quirk/boon/training5/on_spawn()
	var/mob/living/carbon/human/H = owner
	H.adjust_skillrank_up_to(/datum/skill/combat/knives, 3, TRUE)
	if(H.mind)
		H.mind.special_items["Dagger"] = /obj/item/weapon/knife/dagger/steel

/datum/quirk/boon/training6
	name = "Axe Training"
	desc = "I have training with axes and am a capable jumberjack. I've also stashed a copper axe."
	point_value = -3

/datum/quirk/boon/training6/on_spawn()
	var/mob/living/carbon/human/H = owner
	H.adjust_skillrank_up_to(/datum/skill/combat/axesmaces, 3, TRUE)
	H.adjust_skillrank_up_to(/datum/skill/labor/lumberjacking, 3, TRUE)
	if(H.mind)
		H.mind.special_items["Axe"] = /obj/item/weapon/axe/copper

/datum/quirk/boon/training8
	name = "Shield Training"
	desc = "I have shield training and stashed a shield. As long as I have a shield in one hand I can catch arrows with ease."
	point_value = -3

/datum/quirk/boon/training8/on_spawn()
	var/mob/living/carbon/human/H = owner
	H.adjust_skillrank_up_to(/datum/skill/combat/shields, 3, TRUE)
	if(H.mind)
		H.mind.special_items["Shield"] = /obj/item/weapon/shield/wood

/datum/quirk/boon/training9
	name = "Unarmed Training"
	desc = "I have journeyman unarmed training and stashed some dusters."
	point_value = -3

/datum/quirk/boon/training9/on_spawn()
	var/mob/living/carbon/human/H = owner
	H.adjust_skillrank_up_to(/datum/skill/combat/unarmed, 3, TRUE)
	H.adjust_skillrank_up_to(/datum/skill/combat/wrestling, 3, TRUE)

/datum/quirk/boon/mtraining1
	name = "Medical Training"
	desc = "I have basic medical training and stashed some med supplies."
	point_value = -2

/datum/quirk/boon/mtraining1/on_spawn()
	var/mob/living/carbon/human/H = owner
	H.adjust_skillrank_up_to(/datum/skill/misc/medicine, 4, TRUE)
	H.add_spell(/datum/action/cooldown/spell/diagnose)
	if(H.mind)
		H.mind.special_items["Patch Kit"] = /obj/item/storage/fancy/ifak
		H.mind.special_items["Surgery Kit"] = /obj/item/storage/backpack/satchel/surgbag

/datum/quirk/boon/greenthumb
	name = "Green Thumb"
	desc = "I've always been rather good at tending to plants, and I have some powerful fertilizer stashed away and a women of ill repute. (Raises skill to journeyman)"
	point_value = -2

/datum/quirk/boon/greenthumb/on_spawn()
	var/mob/living/carbon/human/H = owner
	H.adjust_skillrank_up_to(/datum/skill/labor/farming, 4, TRUE)
	if(H.mind)
		H.mind.special_items["Fertilizer 1"] = /obj/item/fertilizer
		H.mind.special_items["Fertilizer 2"] = /obj/item/fertilizer
		H.mind.special_items["Fertilizer 3"] = /obj/item/fertilizer
		H.mind.special_items["Whore"] = /obj/item/weapon/hoe // I too respect a humble farmer.

/datum/quirk/boon/eagle_eyed
	name = "Eagle Eyed"
	desc = "I was always good at spotting distant things."
	point_value = -2

/datum/quirk/boon/eagle_eyed/on_spawn()
	var/mob/living/carbon/human/H = owner
	H.change_stat(STATKEY_PER, 2)

/datum/quirk/boon/training10
	name = "Bow Training"
	desc = "I have journeyman bow training and stashed a bow."
	point_value = -3

/datum/quirk/boon/training10/on_spawn()
	var/mob/living/carbon/human/H = owner
	H.adjust_skillrank_up_to(/datum/skill/combat/bows, 3, TRUE)
	if(H.mind)
		H.mind.special_items["Bow"] = /obj/item/gun/ballistic/revolver/grenadelauncher/bow/long
		H.mind.special_items["Quiver"] = /obj/item/ammo_holder/quiver/arrows

/datum/quirk/boon/bookworm
	name = "Bookworm"
	desc = "I love books and I became quite skilled at reading and writing. What's more, my mind is much sharper for the experience."
	point_value = -2

/datum/quirk/boon/bookworm/on_spawn()
	var/mob/living/carbon/human/H = owner
	H.adjust_skillrank_up_to(/datum/skill/misc/reading, 4, TRUE)
	H.change_stat("intelligence", 2)

/datum/quirk/boon/thief
	name = "Thief"
	desc = "Life's not easy around here, but I've made mine a little easier by taking things of others. I am a great at picking pockets and locks. I've stashed some picks nearby."
	point_value = -4

/datum/quirk/boon/thief/on_spawn()
	var/mob/living/carbon/human/H = owner
	H.adjust_skillrank_up_to(/datum/skill/misc/stealing, 4, TRUE)
	H.adjust_skillrank_up_to(/datum/skill/misc/lockpicking, 4, TRUE)
	H.mind.special_items["Lockpicks"] = /obj/item/lockpickring/mundane

/datum/quirk/boon/languagesavant
	name = "Polyglot"
	desc = "I have always picked up on languages easily. I know the languages of all the races found in this land, and my flexible tongue is certainly useful in the bedchamber."
	point_value = -2//Believe it or not, this is a really niche quirk with very few actual use-cases.

/datum/quirk/boon/languagesavant/on_spawn()
	var/mob/living/carbon/human/H = owner
	H.grant_language(/datum/language/dwarvish)
	H.grant_language(/datum/language/elvish)
	H.grant_language(/datum/language/hellspeak)
	H.grant_language(/datum/language/celestial)
	H.grant_language(/datum/language/orcish)
	H.grant_language(/datum/language/beast)
	H.grant_language(/datum/language/thievescant)
	ADD_TRAIT(H, TRAIT_GOODLOVER, "[type]")

/datum/quirk/boon/mastercraftsmen // Named this way to absorb the old quirk. Keeps old saves cleaner without them needing to reset quirks.
	name = "Jack of All Trades"
	desc = "I've always had steady hands. I'm experienced enough in most fine craftsmanship to make a career out of it, if I can procure my own tools."
	point_value = -4 //

/datum/quirk/boon/mastercraftsmen/on_spawn()
	var/mob/living/carbon/human/H = owner
	H.adjust_skillrank_up_to(/datum/skill/craft/crafting, 3, TRUE)
	H.adjust_skillrank_up_to(/datum/skill/craft/blacksmithing, 3, TRUE)
	H.adjust_skillrank_up_to(/datum/skill/craft/carpentry, 3, TRUE)
	H.adjust_skillrank_up_to(/datum/skill/craft/masonry, 3, TRUE)
	H.adjust_skillrank_up_to(/datum/skill/craft/cooking, 3, TRUE)
	H.adjust_skillrank_up_to(/datum/skill/craft/engineering, 3, TRUE)
	H.adjust_skillrank_up_to(/datum/skill/misc/sewing, 3, TRUE)
	H.adjust_skillrank_up_to(/datum/skill/craft/smelting, 3, TRUE)

/datum/quirk/boon/masterbuilder
	name = "Practiced Builder"
	desc = "I have experience in putting up large structures and foundations for buildings. I can even use a sawmill if I can find one, and I have a handcart and two sacks hidden away for transporting my construction materials."
	point_value = -2 // I have a lot of respect for people who actually bother making buildings that will be deleted within an hour or two.

/datum/quirk/boon/masterbuilder/on_spawn()
	var/mob/living/carbon/human/H = owner
	H.adjust_skillrank_up_to(/datum/skill/craft/carpentry, 4, TRUE)
	H.adjust_skillrank_up_to(/datum/skill/craft/masonry, 4, TRUE)
	H.adjust_skillrank_up_to(/datum/skill/craft/engineering, 4, TRUE) // Needed to install things like levers in a house. This unfortunately means construction workers can make illegal firearms.
	H.adjust_skillrank_up_to(/datum/skill/craft/crafting, 3, TRUE) // Pretty sure some crafting stations use this. Also stone axes and whatever other basic tools they need.
	if(H.mind)
		H.mind.special_items["Handcart"] = /obj/structure/handcart //TO-DO: Implement sawmill and the trait to use it. Giving them a handcart to move materials with.
		H.mind.special_items["Sack 1"] = /obj/item/storage/sack
		H.mind.special_items["Sack 2"] = /obj/item/storage/sack

/datum/quirk/boon/mastersmith
	name = "Practiced Smith"
	desc = "I am a metalworker by trade, and I have the tools for my practice stashed away." // Needs looking at after the smithing rework goes through.
	point_value = -4 // Armor-making. Weapon-making. Everyone wants the gamer gear.

/datum/quirk/boon/mastersmith/on_spawn()
	var/mob/living/carbon/human/H = owner
	H.adjust_skillrank_up_to(/datum/skill/craft/blacksmithing, 4, TRUE)
	H.adjust_skillrank_up_to(/datum/skill/craft/engineering, 4, TRUE)
	H.adjust_skillrank_up_to(/datum/skill/craft/smelting, 4, TRUE)
	H.adjust_skillrank_up_to(/datum/skill/craft/crafting, 3, TRUE)
	if(H.mind)
		H.mind.special_items["Hammer"] = /obj/item/weapon/hammer
		H.mind.special_items["Tongs"] = /obj/item/weapon/tongs
		H.mind.special_items["Coal"] = /obj/item/ore/coal

/datum/quirk/boon/mastertailor
	name = "Practiced Tailor"
	desc = "I'm particularly skilled in working with needle, thread, and loom. I also have a needle, thread, and scissors hidden away."
	point_value = -4

/datum/quirk/boon/mastertailor/on_spawn()
	var/mob/living/carbon/human/H = owner
	H.adjust_skillrank_up_to(/datum/skill/misc/sewing, 4, TRUE)
	H.adjust_skillrank_up_to(/datum/skill/craft/crafting, 4, TRUE)
	H.adjust_skillrank_up_to(/datum/skill/misc/medicine, 3, TRUE)//Being skilled with a needle offers some overlap with stitching up peoples' wounds. Also, weaving isn't a skill anymore so...
	if(H.mind)
		H.mind.special_items["Scissors"] = /obj/item/weapon/knife/scissors/steel
		H.mind.special_items["Needle"] = /obj/item/needle
		H.mind.special_items["Thread"] = /obj/item/natural/bundle/fibers/full

/datum/quirk/boon/bleublood
	name = "Noble Lineage"
	desc = "I am of noble blood."
	point_value = -3

/datum/quirk/boon/bleublood/on_spawn()
	var/mob/living/carbon/human/H = owner
	ADD_TRAIT(H, TRAIT_NOBLE, "[type]")
	H.adjust_skillrank_up_to(/datum/skill/misc/reading, 2, TRUE)

/datum/quirk/boon/richpouch
	name = "Rich Pouch"
	desc = "I have a pouch full of mammons."
	point_value = -2

/datum/quirk/boon/richpouch/on_spawn()
	var/mob/living/carbon/human/H = owner
	var/obj/item/pouch = new /obj/item/storage/belt/pouch/coins/rich(get_turf(H))
	H.put_in_hands(pouch, forced = TRUE)

/datum/quirk/boon/nasty_eater
	name = "Not a Picky Eater"
	desc = "I can eat even the most spoiled, raw, or toxic food and water as if they were delicacies. I'm even immune to the berry poison some folk like to coat their arrows with."
	point_value = -2

/datum/quirk/boon/nasty_eater/on_spawn()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	ADD_TRAIT(H, TRAIT_NASTY_EATER, "[type]")

/datum/quirk/boon/alcohol_tolerance
	name = "Alcohol Tolerance"
	desc = "Alcohol doesn't affect me much."
	point_value = -1
	gain_text = span_notice("I feel like you could drink a whole keg!")
	lose_text = span_danger("I don't feel as resistant to alcohol anymore. Somehow.")

/datum/quirk/boon/alcohol_tolerance/on_spawn()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	ADD_TRAIT(H, TRAIT_LIGHT_DRINKER, "[type]")

/datum/quirk/boon/alcohol_tolerance/on_remove()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	REMOVE_TRAIT(H, TRAIT_LIGHT_DRINKER, "[type]")

/datum/quirk/boon/empath
	name = "Empath"
	desc = "I can better tell the mood of those around me."
	point_value = -4
	gain_text = span_notice("I feel in tune with those around you.")
	lose_text = span_danger("I feel isolated from others.")

/datum/quirk/boon/empath/on_spawn()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	ADD_TRAIT(H, TRAIT_EMPATH, "[type]")

/datum/quirk/boon/empath/on_remove()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	REMOVE_TRAIT(H, TRAIT_EMPATH, "[type]")

/datum/quirk/boon/musician
	name = "Musician"
	desc = "I am good at playing music. I've also hidden a lute!"
	point_value = -1
	gain_text = span_notice("I know everything about musical instruments.")
	lose_text = span_danger("I forget how musical instruments work.")

/datum/quirk/boon/empath/on_spawn()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	ADD_TRAIT(H, TRAIT_MUSICIAN, "[type]")

/datum/quirk/boon/empath/on_remove()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	REMOVE_TRAIT(H, TRAIT_MUSICIAN, "[type]")

/datum/quirk/boon/selfaware
	name = "Self-Aware"
	desc = "I know the extent of my wounds to a terrifying scale."
	point_value = -2

/datum/quirk/boon/selfaware/on_spawn()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	ADD_TRAIT(H, TRAIT_SELF_AWARE, "[type]")

/datum/quirk/boon/selfaware/on_remove()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	REMOVE_TRAIT(H, TRAIT_SELF_AWARE, "[type]")
