#define WILD_TARGET_SELF 1
#define WILD_TARGET_RANDOM_LIVING 2
#define WILD_TARGET_CAST_ON 3
#define WILD_TARGET_TURF_OF_CAST_ON 4
#define WILD_TARGET_TURF_OF_CASTER 5

/datum/wild_surge_entry
	var/name
	var/message
	var/target_mode
	var/spell_type
	var/progname
	var/inner_tele_radius
	var/outer_tele_radius

GLOBAL_LIST_INIT(wild_surge_table, init_wild_surge_table())

/proc/init_wild_surge_table()
	var/list/L = list()

	// ======================================================
	// PROC ENTRIES
	// ======================================================

	L += WildProc("Pink Bubbles",
		span_danger("Pink bubbles start flying out of \[WILD_CASTER\]'s mouth!"),
		"surge_mute")

	L += WildProc("Mist Form",
		span_danger("\[WILD_CASTER\]'s body dissolves into drifting mist!"),
		"surge_mist")

	L += WildProc("Cat Form",
		span_danger("\[WILD_CASTER\]'s body shifts into a nimble cat!"),
		"surge_cat")

	L += WildProc("Crow Form",
		span_danger("\[WILD_CASTER\]'s body twists into a crow!"),
		"surge_crow")

	// ======================================================
	// SPELL ENTRIES 2–50
	// ======================================================

	AddSpell(L,"Flashpowder",
		span_danger("\[WILD_CASTER\] casts flashpowder!"),
		/obj/projectile/magic/flashpowder,
		WILD_TARGET_RANDOM_LIVING)

	AddSpell(L,"Teleport Distortion",
		span_danger("\[WILD_CASTER\] vanishes in a violent magical distortion!"),
		/datum/action/cooldown/spell/undirected/teleport/radius_turf,
		WILD_TARGET_SELF, 1, 5)

	AddSpell(L,"Fireball",
		span_danger("\[WILD_CASTER\]'s unstable magic erupts into a FIREBALL!"),
		/datum/action/cooldown/spell/projectile/fireball,
		WILD_TARGET_RANDOM_LIVING)

	AddSpell(L,"Arcyne Tendrils",
		span_danger("Arcyne tendrils erupt from the ground around \[WILD_CASTER\]!"),
		/datum/action/cooldown/spell/aoe/on_turf/ensnare,
		WILD_TARGET_TURF_OF_CAST_ON)

	AddSpell(L,"Entangler",
		span_nicegreen("Living vines spiral around \[WILD_CASTER\]'s hand as Dendor answers the chaos!"),
		/datum/action/cooldown/spell/undirected/touch/entangler,
		WILD_TARGET_SELF)

	AddSpell(L,"Wild Heal",
		span_nicegreen("The target's wounds instantly begin to heal."),
		/datum/action/cooldown/spell/healing/greater,
		WILD_TARGET_RANDOM_LIVING)

	AddSpell(L,"Ethereal Jaunt",
		span_danger("\[WILD_CASTER\] flickers and slips partially out of reality!"),
		/datum/action/cooldown/spell/undirected/jaunt/ethereal_jaunt,
		WILD_TARGET_SELF)

	AddSpell(L,"Smoke Bomb",
		span_notice("\[WILD_CASTER\] coughs as a cloud of smoke erupts!"),
		/datum/action/cooldown/spell/undirected/conjure_item/smoke_bomb,
		WILD_TARGET_SELF)

	AddSpell(L,"Poison Bomb",
		span_danger("\[WILD_CASTER\]'s magic curdles into sickly vapor!"),
		/datum/action/cooldown/spell/undirected/conjure_item/poison_bomb,
		WILD_TARGET_SELF)

	AddSpell(L,"Light Orb",
		span_notice("A brilliant orb bursts into existence!"),
		/datum/action/cooldown/spell/undirected/conjure_item/light,
		WILD_TARGET_SELF)

	AddSpell(L,"Brick",
		span_warning("Reality hardens in \[WILD_CASTER\]'s hand!"),
		/datum/action/cooldown/spell/undirected/conjure_item/brick,
		WILD_TARGET_SELF)

	AddSpell(L,"Guidance",
		span_notice("A faint glow surrounds \[WILD_CASTER\]."),
		/datum/action/cooldown/spell/status/guidance,
		WILD_TARGET_SELF)

	AddSpell(L,"Haste",
		span_notice("\[WILD_CASTER\]'s movements shimmer and quicken!"),
		/datum/action/cooldown/spell/status/haste,
		WILD_TARGET_SELF)

	AddSpell(L,"Giant Shape",
		span_notice("\[WILD_CASTER\] begins to grow!"),
		/datum/action/cooldown/spell/undirected/giant_shape,
		WILD_TARGET_SELF)

	AddSpell(L,"Shadow Step",
		span_warning("\[WILD_CASTER\] melts into the shadows!"),
		/datum/action/cooldown/spell/undirected/shadow_step,
		WILD_TARGET_SELF)

	AddSpell(L,"Second Sight",
		span_notice("\[WILD_CASTER\]'s vision sharpens."),
		/datum/action/cooldown/spell/undirected/secondsight,
		WILD_TARGET_SELF)

	AddSpell(L,"Blade Ward",
		span_notice("\[WILD_CASTER\] traces a warding sigil."),
		/datum/action/cooldown/spell/undirected/blade_ward,
		WILD_TARGET_SELF)

	AddSpell(L,"Longstrider",
		span_notice("A dim pulse radiates from \[WILD_CASTER\]."),
		/datum/action/cooldown/spell/undirected/longstrider,
		WILD_TARGET_SELF)

	AddSpell(L,"Feather Falling",
		span_notice("A soft aura surrounds \[WILD_CASTER\]."),
		/datum/action/cooldown/spell/undirected/feather_falling,
		WILD_TARGET_SELF)

	AddSpell(L,"Forcewall",
		span_notice("\[WILD_CASTER\] conjures a shimmering wall of force!"),
		/datum/action/cooldown/spell/undirected/forcewall,
		WILD_TARGET_SELF)

	AddSpell(L,"Lightning Strike",
		span_warning("Lightning crackles violently!"),
		/datum/action/cooldown/spell/projectile/lightning,
		WILD_TARGET_RANDOM_LIVING)

	AddSpell(L,"Frost Bolt",
		span_notice("A beam of frost flies forward!"),
		/datum/action/cooldown/spell/projectile/frost_bolt,
		WILD_TARGET_RANDOM_LIVING)

	AddSpell(L,"Arcyne Bolt",
		span_notice("Arcyne energy erupts forward!"),
		/datum/action/cooldown/spell/projectile/arcyne_bolt,
		WILD_TARGET_RANDOM_LIVING)

	AddSpell(L,"Acid Splash",
		span_warning("A glob of caustic acid flies!"),
		/datum/action/cooldown/spell/projectile/acid_splash,
		WILD_TARGET_RANDOM_LIVING)

	AddSpell(L,"Meteor Storm",
		span_boldwarning("METEORS RAIN FROM THE SKY!"),
		/datum/action/cooldown/spell/aoe/on_turf/meteor_storm,
		WILD_TARGET_SELF)

	AddSpell(L,"Snap Freeze",
		span_notice("Frost envelops the area!"),
		/datum/action/cooldown/spell/aoe/on_turf/snap_freeze,
		WILD_TARGET_RANDOM_LIVING)

	AddSpell(L,"Repulse",
		span_notice("Everything is violently thrown back!"),
		/datum/action/cooldown/spell/aoe/repulse,
		WILD_TARGET_SELF)

	AddSpell(L,"Dragon Repulse",
		span_notice("\[WILD_CASTER\] sweeps with force!"),
		/datum/action/cooldown/spell/aoe/repulse/dragon,
		WILD_TARGET_SELF)

	AddSpell(L,"Churn Undead",
		span_notice("Undead energies churn violently!"),
		/datum/action/cooldown/spell/aoe/churn_undead,
		WILD_TARGET_SELF)

	AddSpell(L,"Gravity Crush",
		span_danger("\[WILD_CASTER\] crushes space around the target!"),
		/datum/action/cooldown/spell/gravity,
		WILD_TARGET_RANDOM_LIVING)

	AddSpell(L,"Find Flaw",
		span_notice("\[WILD_CASTER\] peers into hidden weaknesses."),
		/datum/action/cooldown/spell/find_flaw,
		WILD_TARGET_CAST_ON)

	AddSpell(L,"Chill Touch",
		span_danger("A skeletal hand reaches outward!"),
		/datum/action/cooldown/spell/chill_touch,
		WILD_TARGET_RANDOM_LIVING)

	AddSpell(L,"Blade Burst",
		span_danger("A storm of blades erupts!"),
		/datum/action/cooldown/spell/blade_burst,
		WILD_TARGET_RANDOM_LIVING)

	AddSpell(L,"Beast Tame",
		span_notice("A whisper attempts to tame the beast."),
		/datum/action/cooldown/spell/beast_tame,
		WILD_TARGET_CAST_ON)

	AddSpell(L,"Blindness",
		span_danger("Darkness shrouds the target's eyes!"),
		/datum/action/cooldown/spell/blindness,
		WILD_TARGET_RANDOM_LIVING)

	AddSpell(L,"Silence",
		span_notice("A zone of silence forms."),
		/datum/action/cooldown/spell/essence/silence,
		WILD_TARGET_RANDOM_LIVING)

	AddSpell(L,"Toxic Cleanse",
		span_notice("All toxins are purged."),
		/datum/action/cooldown/spell/essence/toxic_cleanse,
		WILD_TARGET_RANDOM_LIVING)

	while(length(L) < 50)
		AddSpell(L,"Chaotic Spark",
			span_notice("Chaotic sparks scatter wildly."),
			/datum/action/cooldown/spell/projectile/arcyne_bolt,
			WILD_TARGET_RANDOM_LIVING)

	return L


/proc/WildSpell(name, message, spell_type, target_mode, inner=null, outer=null)
	var/datum/wild_surge_entry/E = new
	E.name = name
	E.message = message
	E.spell_type = spell_type
	E.target_mode = target_mode
	E.inner_tele_radius = inner
	E.outer_tele_radius = outer
	return E

/proc/WildProc(name, message, procname)
	var/datum/wild_surge_entry/E = new
	E.name = name
	E.message = message
	E.progname = procname
	return E

/proc/AddSpell(list/L, name, message, spell_type, target_mode, inner=null, outer=null)
	L += WildSpell(name, message, spell_type, target_mode, inner, outer)
