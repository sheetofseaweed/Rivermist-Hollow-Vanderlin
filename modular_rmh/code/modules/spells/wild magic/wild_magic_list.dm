/datum/wild_surge_entry
	var/name
	var/message
	var/target_mode
	var/spell_type
	var/effect_proc
	var/inner_tele_radius
	var/outer_tele_radius

/datum/wild_surge_entry/New(
	entry_name,
	entry_message,
	entry_target_mode = null,
	entry_spell_type = null,
	entry_effect_proc = null,
	entry_inner_tele_radius = null,
	entry_outer_tele_radius = null
)
	. = ..()
	name = entry_name
	message = entry_message
	target_mode = entry_target_mode
	spell_type = entry_spell_type
	effect_proc = entry_effect_proc
	inner_tele_radius = entry_inner_tele_radius
	outer_tele_radius = entry_outer_tele_radius

/datum/wild_surge_entry/spell/New(
	entry_name,
	entry_message,
	entry_spell_type,
	entry_target_mode,
	entry_inner_tele_radius = null,
	entry_outer_tele_radius = null
)
	. = ..(entry_name, entry_message, entry_target_mode, entry_spell_type, null, entry_inner_tele_radius, entry_outer_tele_radius)

/datum/wild_surge_entry/effect/New(entry_name, entry_message, entry_effect_proc)
	. = ..(entry_name, entry_message, null, null, entry_effect_proc)

GLOBAL_LIST_EMPTY(wild_surge_table)

/datum/element/wild_magic/proc/BuildWildSurgeTable()
	var/list/L = list()

	L += new /datum/wild_surge_entry/effect("Pink Bubbles",
		span_danger("Pink bubbles start flying out of \[WILD_CASTER\]'s mouth!"),
		TYPE_PROC_REF(/datum/element/wild_magic, surge_mute))

	L += new /datum/wild_surge_entry/spell("Flashpowder",
		span_danger("\[WILD_CASTER\] casts flashpowder!"),
		/datum/action/cooldown/spell/projectile/flashpowder,
		WILD_TARGET_RANDOM_LIVING)

	L += new /datum/wild_surge_entry/spell("Teleport Distortion",
		span_danger("\[WILD_CASTER\] vanishes in a violent magical distortion!"),
		/datum/action/cooldown/spell/undirected/teleport/radius_turf/wild_magic,
		WILD_TARGET_SELF, 1, 5)

	L += new /datum/wild_surge_entry/spell("Fireball",
		span_danger("\[WILD_CASTER\]'s unstable magic erupts into a FIREBALL!"),
		/datum/action/cooldown/spell/projectile/fireball,
		WILD_TARGET_RANDOM_LIVING)

	L += new /datum/wild_surge_entry/spell("Arcyne Tendrils",
		span_danger("Arcyne tendrils erupt from the ground around \[WILD_CASTER\]!"),
		/datum/action/cooldown/spell/aoe/on_turf/ensnare,
		WILD_TARGET_TURF_OF_CAST_ON)

	L += new /datum/wild_surge_entry/spell("Entangler",
		span_nicegreen("Living vines spiral around \[WILD_CASTER\]'s hand as Dendor answers the chaos!"),
		/datum/action/cooldown/spell/undirected/touch/entangler,
		WILD_TARGET_SELF)

	L += new /datum/wild_surge_entry/spell("Wild Heal",
		span_nicegreen("The target's wounds instantly begin to heal."),
		/datum/action/cooldown/spell/healing/greater,
		WILD_TARGET_RANDOM_LIVING)

	L += new /datum/wild_surge_entry/effect("Mist Form",
		span_danger("\[WILD_CASTER\]'s body dissolves into drifting mist!"),
		TYPE_PROC_REF(/datum/element/wild_magic, surge_mist))

	L += new /datum/wild_surge_entry/spell("Ethereal Jaunt",
		span_danger("\[WILD_CASTER\] flickers and slips partially out of reality!"),
		/datum/action/cooldown/spell/undirected/jaunt/ethereal_jaunt,
		WILD_TARGET_SELF)

	L += new /datum/wild_surge_entry/spell("Smoke Bomb",
		span_notice("\[WILD_CASTER\] coughs as a cloud of smoke erupts!"),
		/datum/action/cooldown/spell/undirected/conjure_item/smoke_bomb,
		WILD_TARGET_SELF)

	L += new /datum/wild_surge_entry/spell("Poison Bomb",
		span_danger("\[WILD_CASTER\]'s magic curdles into sickly vapor!"),
		/datum/action/cooldown/spell/undirected/conjure_item/poison_bomb,
		WILD_TARGET_SELF)

	L += new /datum/wild_surge_entry/spell("Light Orb",
		span_notice("A brilliant orb bursts into existence!"),
		/datum/action/cooldown/spell/undirected/conjure_item/light,
		WILD_TARGET_SELF)

	L += new /datum/wild_surge_entry/spell("Brick",
		span_warning("Reality hardens in \[WILD_CASTER\]'s hand!"),
		/datum/action/cooldown/spell/undirected/conjure_item/brick,
		WILD_TARGET_SELF)

	L += new /datum/wild_surge_entry/spell("Guidance",
		span_notice("A faint glow surrounds \[WILD_CASTER\]."),
		/datum/action/cooldown/spell/status/guidance,
		WILD_TARGET_SELF)

	L += new /datum/wild_surge_entry/spell("Haste",
		span_notice("\[WILD_CASTER\]'s movements shimmer and quicken!"),
		/datum/action/cooldown/spell/status/haste,
		WILD_TARGET_SELF)

	L += new /datum/wild_surge_entry/spell("Giant Shape",
		span_notice("\[WILD_CASTER\] begins to grow!"),
		/datum/action/cooldown/spell/undirected/giant_shape,
		WILD_TARGET_SELF)

	L += new /datum/wild_surge_entry/spell("Shadow Step",
		span_warning("\[WILD_CASTER\] melts into the shadows!"),
		/datum/action/cooldown/spell/undirected/shadow_step,
		WILD_TARGET_SELF)

	L += new /datum/wild_surge_entry/spell("Second Sight",
		span_notice("\[WILD_CASTER\]'s vision sharpens."),
		/datum/action/cooldown/spell/undirected/secondsight,
		WILD_TARGET_SELF)

	L += new /datum/wild_surge_entry/spell("Blade Ward",
		span_notice("\[WILD_CASTER\] traces a warding sigil."),
		/datum/action/cooldown/spell/undirected/blade_ward,
		WILD_TARGET_SELF)

	L += new /datum/wild_surge_entry/spell("Longstrider",
		span_notice("A dim pulse radiates from \[WILD_CASTER\]."),
		/datum/action/cooldown/spell/undirected/longstrider,
		WILD_TARGET_SELF)

	L += new /datum/wild_surge_entry/spell("Feather Falling",
		span_notice("A soft aura surrounds \[WILD_CASTER\]."),
		/datum/action/cooldown/spell/undirected/feather_falling,
		WILD_TARGET_SELF)

	L += new /datum/wild_surge_entry/spell("Forcewall",
		span_notice("\[WILD_CASTER\] conjures a shimmering wall of force!"),
		/datum/action/cooldown/spell/undirected/forcewall,
		WILD_TARGET_SELF)

	L += new /datum/wild_surge_entry/spell("Lightning Strike",
		span_warning("Lightning crackles violently!"),
		/datum/action/cooldown/spell/projectile/lightning,
		WILD_TARGET_RANDOM_LIVING)

	L += new /datum/wild_surge_entry/spell("Frost Bolt",
		span_notice("A beam of frost flies forward!"),
		/datum/action/cooldown/spell/projectile/frost_bolt,
		WILD_TARGET_RANDOM_LIVING)

	L += new /datum/wild_surge_entry/spell("Arcyne Bolt",
		span_notice("Arcyne energy erupts forward!"),
		/datum/action/cooldown/spell/projectile/arcyne_bolt,
		WILD_TARGET_RANDOM_LIVING)

	L += new /datum/wild_surge_entry/spell("Acid Splash",
		span_warning("A glob of caustic acid flies!"),
		/datum/action/cooldown/spell/projectile/acid_splash,
		WILD_TARGET_RANDOM_LIVING)

	L += new /datum/wild_surge_entry/spell("Kneestingers",
		span_notice("\[WILD_CASTER\] whispers 'Treefather light the way.' and kneestingers sprout!"),
		/datum/action/cooldown/spell/conjure/kneestingers,
		WILD_TARGET_SELF)

	L += new /datum/wild_surge_entry/spell("Phantom Ear",
		span_notice("\[WILD_CASTER\] whispers 'Lend me thine ear.' and a phantom ear appears."),
		/datum/action/cooldown/spell/conjure/phantom_ear,
		WILD_TARGET_SELF)

	L += new /datum/wild_surge_entry/spell("ROUS",
		span_notice("\[WILD_CASTER\] calls for their brethren!"),
		/datum/action/cooldown/spell/conjure/rous,
		WILD_TARGET_SELF)

	L += new /datum/wild_surge_entry/spell("Bonfire",
		span_notice("\[WILD_CASTER\] shouts 'Bonfire!' and a magical flame appears."),
		/datum/action/cooldown/spell/conjure/bonfire,
		WILD_TARGET_SELF)

	L += new /datum/wild_surge_entry/spell("Raise Lesser Undead",
		span_warning("\[WILD_CASTER\] shouts 'SERVE ME!' and a skeleton rises."),
		/datum/action/cooldown/spell/conjure/raise_lesser_undead,
		WILD_TARGET_SELF)

	L += new /datum/wild_surge_entry/spell("Web",
		span_notice("\[WILD_CASTER\] whispers 'Strands that bind!' and webs appear around you."),
		/datum/action/cooldown/spell/conjure/web,
		WILD_TARGET_SELF)

	L += new /datum/wild_surge_entry/spell("Familiar",
		span_notice("\[WILD_CASTER\] shouts 'B'ST FR'ND!' and a spectral wolf familiar appears."),
		/datum/action/cooldown/spell/conjure/familiar,
		WILD_TARGET_SELF)

	L += new /datum/wild_surge_entry/spell("Beam of Frost",
		span_notice("\[WILD_CASTER\] shouts 'Chill!' and a frost beam emerges."),
		/datum/action/cooldown/spell/beam/beam_of_frost,
		WILD_TARGET_RANDOM_LIVING)

	L += new /datum/wild_surge_entry/spell("Meteor Storm",
		span_boldwarning("METEORS RAIN FROM THE SKY!"),
		/datum/action/cooldown/spell/aoe/on_turf/meteor_storm,
		WILD_TARGET_SELF)

	L += new /datum/wild_surge_entry/spell("Snap Freeze",
		span_notice("Frost envelops the area!"),
		/datum/action/cooldown/spell/aoe/on_turf/snap_freeze,
		WILD_TARGET_RANDOM_LIVING)

	L += new /datum/wild_surge_entry/spell("Arcyne Storm",
		span_notice("\[WILD_CASTER\] shouts 'BE TORN APART!!!' and arcyne energy swirls."),
		/datum/action/cooldown/spell/aoe/on_turf/arcyne_storm,
		WILD_TARGET_RANDOM_LIVING)

	L += new /datum/wild_surge_entry/spell("Repulse",
		span_notice("Everything is violently thrown back!"),
		/datum/action/cooldown/spell/aoe/repulse,
		WILD_TARGET_SELF)

	L += new /datum/wild_surge_entry/spell("Dragon Repulse",
		span_notice("\[WILD_CASTER\] sweeps with force!"),
		/datum/action/cooldown/spell/aoe/repulse/dragon,
		WILD_TARGET_SELF)

	L += new /datum/wild_surge_entry/spell("Churn Undead",
		span_notice("Undead energies churn violently!"),
		/datum/action/cooldown/spell/aoe/churn_undead,
		WILD_TARGET_SELF)

	L += new /datum/wild_surge_entry/effect("Cat Form",
		span_danger("\[WILD_CASTER\]'s body shifts and shrinks into a nimble cat!"),
		TYPE_PROC_REF(/datum/element/wild_magic, surge_cat))

	L += new /datum/wild_surge_entry/effect("Crow Form",
		span_danger("\[WILD_CASTER\]'s body twists and feathers sprout as they become a crow!"),
		TYPE_PROC_REF(/datum/element/wild_magic, surge_crow))

	L += new /datum/wild_surge_entry/spell("Gravity Crush",
		span_danger("\[WILD_CASTER\] crushes space around the target!"),
		/datum/action/cooldown/spell/gravity,
		WILD_TARGET_RANDOM_LIVING)

	L += new /datum/wild_surge_entry/spell("Find Flaw",
		span_notice("\[WILD_CASTER\] peers into hidden weaknesses."),
		/datum/action/cooldown/spell/find_flaw,
		WILD_TARGET_CAST_ON)

	L += new /datum/wild_surge_entry/spell("Chill Touch",
		span_danger("A skeletal hand reaches outward!"),
		/datum/action/cooldown/spell/chill_touch,
		WILD_TARGET_RANDOM_LIVING)

	L += new /datum/wild_surge_entry/spell("Blade Burst",
		span_danger("A storm of blades erupts!"),
		/datum/action/cooldown/spell/blade_burst,
		WILD_TARGET_RANDOM_LIVING)

	L += new /datum/wild_surge_entry/spell("Beast Tame",
		span_notice("A whisper attempts to tame the beast."),
		/datum/action/cooldown/spell/beast_tame,
		WILD_TARGET_CAST_ON)

	L += new /datum/wild_surge_entry/spell("Blindness",
		span_danger("Darkness shrouds the target's eyes!"),
		/datum/action/cooldown/spell/blindness,
		WILD_TARGET_RANDOM_LIVING)

	L += new /datum/wild_surge_entry/spell("Silence",
		span_notice("A zone of silence forms."),
		/datum/action/cooldown/spell/essence/silence/wild_magic,
		WILD_TARGET_RANDOM_LIVING)

	L += new /datum/wild_surge_entry/spell("Toxic Cleanse",
		span_notice("All toxins are purged."),
		/datum/action/cooldown/spell/essence/toxic_cleanse/wild_magic,
		WILD_TARGET_RANDOM_LIVING)

	if(length(L) != 50)
		stack_trace("Wild surge table expected 50 entries, got [length(L)].")

	return L
