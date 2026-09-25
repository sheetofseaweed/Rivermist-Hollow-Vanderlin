#define FALLING_STAR_SHARDS_REQUIRED 50
#define FALLING_STAR_AURA_RANGE 3
#define FALLING_STAR_AURA_INTERVAL (10 SECONDS)

/obj/item/falling_star_shard
	name = "small falling star shard"
	desc = "A sliver of a fallen star. Fifty distinct slivers can shatter a bound star crystal."
	icon = 'modular_rmh/modular/falling_star/star_shards.dmi'
	icon_state = "small"
	w_class = WEIGHT_CLASS_TINY
	item_weight = 50 GRAMS
	force = 0
	throwforce = 0
	item_flags = NOBLUDGEON

/obj/item/falling_star_shard/medium
	name = "medium falling star shard"
	desc = "A single-use shard that can stun a star-bound hunter for fifteen seconds."
	icon_state = "medium"
	item_weight = 150 GRAMS

/obj/item/falling_star_shard/medium/attack(mob/living/target, mob/living/user, list/modifiers)
	if(!ishuman(target) || !HAS_TRAIT(target, TRAIT_EVENT_HUNTER))
		to_chat(user, span_warning("The shard has no hold over [target]."))
		return

	if(target.stat == DEAD)
		to_chat(user, span_warning("The shard finds no living will to bind."))
		return

	target.Stun(15 SECONDS, ignore_canstun = TRUE)
	target.visible_message(
		span_warning("[user] presses [src] against [target], and starlight locks them in place!"),
		span_userdanger("[user] presses [src] against me, and starlight locks my body in place!"),
	)
	qdel(src)
	return TRUE

/obj/structure/falling_star_crystal
	name = "bound star crystal"
	desc = "A great shard of a fallen star. Small star shards can wear away its infernal bond."
	icon = 'modular_rmh/modular/falling_star/star_crystal.dmi'
	icon_state = "large"
	pixel_x = -16
	density = TRUE
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE
	/// Set through View Variables by an event admin before players can break the crystal.
	var/bound_hunter_name = "an unnamed hunter"
	var/shards_used = 0
	var/broken = FALSE
	var/tmp/aura_timer

/obj/structure/falling_star_crystal/Initialize(mapload)
	. = ..()
	if(. == INITIALIZE_HINT_QDEL)
		return .
	aura_timer = addtimer(CALLBACK(src, PROC_REF(pulse_aura)), FALLING_STAR_AURA_INTERVAL, TIMER_LOOP | TIMER_STOPPABLE | TIMER_DELETE_ME)
	return .

/obj/structure/falling_star_crystal/Destroy()
	if(aura_timer)
		deltimer(aura_timer)
		aura_timer = null
	return ..()

/obj/structure/falling_star_crystal/examine(mob/user)
	. = ..()
	. += span_notice("[shards_used] of [FALLING_STAR_SHARDS_REQUIRED] small star shards have been offered to it.")
	return .

/obj/structure/falling_star_crystal/attackby(obj/item/attacking_item, mob/living/user, params)
	if(!istype(attacking_item, /obj/item/falling_star_shard) || istype(attacking_item, /obj/item/falling_star_shard/medium))
		return ..()
	if(QDELETED(attacking_item))
		return TRUE
	if(broken)
		return TRUE

	shards_used++
	qdel(attacking_item)
	if(shards_used < FALLING_STAR_SHARDS_REQUIRED)
		to_chat(user, span_notice("The shard sinks into the crystal. [shards_used]/[FALLING_STAR_SHARDS_REQUIRED] have been offered."))
		return TRUE

	broken = TRUE
	visible_message(span_boldwarning("[src] fractures into dying starlight!"))
	priority_announce(
		"The bound star crystal of [bound_hunter_name] has been shattered!",
		"A Star Bond Broken",
		'sound/misc/alert.ogg',
	)
	qdel(src)
	return TRUE

/obj/structure/falling_star_crystal/proc/pulse_aura()
	if(broken)
		return
	for(var/mob/living/carbon/human/target in range(FALLING_STAR_AURA_RANGE, src))
		if(target.stat == DEAD || HAS_TRAIT(target, TRAIT_EVENT_HUNTER) || !target.has_erp_pref(/datum/erp_preference/boolean/lust_magic_targetable))
			continue
		SEND_SIGNAL(target, COMSIG_SEX_ADJUST_AROUSAL, 2)
		if(get_dist(src, target) <= 1 && !target.has_status_effect(/datum/status_effect/debuff/aphrodisiac))
			target.apply_status_effect(/datum/status_effect/debuff/aphrodisiac)

/datum/action/cooldown/spell/falling_star_hunt_stun
	name = "Star Hunter's Grasp"
	desc = "Briefly stun a mortal you are hunting."
	has_visual_effects = FALSE
	associated_skill = null
	self_cast_possible = FALSE
	cast_range = 4
	charge_required = FALSE
	cooldown_time = 20 SECONDS

/datum/action/cooldown/spell/falling_star_hunt_stun/is_valid_target(atom/cast_on)
	. = ..()
	if(!. || !ishuman(cast_on) || cast_on == owner)
		return FALSE
	return !HAS_TRAIT(cast_on, TRAIT_EVENT_HUNTER)

/datum/action/cooldown/spell/falling_star_hunt_stun/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return .
	if(!HAS_TRAIT(owner, TRAIT_EVENT_HUNTER))
		return . | SPELL_CANCEL_CAST
	return .

/datum/action/cooldown/spell/falling_star_hunt_stun/cast(mob/living/carbon/human/cast_on)
	. = ..()
	if(!HAS_TRAIT(owner, TRAIT_EVENT_HUNTER) || !ishuman(cast_on) || cast_on.stat == DEAD)
		return .
	cast_on.Stun(3 SECONDS)
	to_chat(cast_on, span_warning("Starlight catches at my limbs!"))
	return .

/datum/action/cooldown/spell/falling_star_hunt_lust
	name = "Star Hunter's Temptation"
	desc = "Kindle desire and leave a brief aphrodisiac haze on a mortal."
	has_visual_effects = FALSE
	associated_skill = null
	self_cast_possible = FALSE
	cast_range = 4
	charge_required = FALSE
	cooldown_time = 12 SECONDS

/datum/action/cooldown/spell/falling_star_hunt_lust/is_valid_target(atom/cast_on)
	. = ..()
	if(!. || !ishuman(cast_on) || cast_on == owner)
		return FALSE
	return !HAS_TRAIT(cast_on, TRAIT_EVENT_HUNTER)

/datum/action/cooldown/spell/falling_star_hunt_lust/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return .
	var/mob/living/carbon/human/target = cast_on
	if(!HAS_TRAIT(owner, TRAIT_EVENT_HUNTER) || !istype(target) || !target.has_erp_pref(/datum/erp_preference/boolean/lust_magic_targetable))
		return . | SPELL_CANCEL_CAST
	return .

/datum/action/cooldown/spell/falling_star_hunt_lust/cast(mob/living/carbon/human/cast_on)
	. = ..()
	if(!HAS_TRAIT(owner, TRAIT_EVENT_HUNTER) || !ishuman(cast_on) || cast_on.stat == DEAD || !cast_on.has_erp_pref(/datum/erp_preference/boolean/lust_magic_targetable))
		return .
	SEND_SIGNAL(cast_on, COMSIG_SEX_ADJUST_AROUSAL, 15)
	cast_on.apply_status_effect(/datum/status_effect/debuff/aphrodisiac)
	to_chat(cast_on, span_love("A wave of unnatural warmth washes through me."))
	return .

#undef FALLING_STAR_SHARDS_REQUIRED
#undef FALLING_STAR_AURA_RANGE
#undef FALLING_STAR_AURA_INTERVAL
