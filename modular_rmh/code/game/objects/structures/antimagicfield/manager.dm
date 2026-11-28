/**
 * Anti-magic field registry and permission authority.
 *
 * Permission policy: deny-wins. If any active field covers the caster origin
 * or any effect turf and denies the action, the action is blocked. A permissive
 * overlapping field never overrides a denial.
 */
GLOBAL_DATUM_INIT(anti_magic_field_manager, /datum/anti_magic_field_manager, new)

/datum/anti_magic_field_manager
	/// Every registered field, including inactive and dormant devices.
	var/list/fields = list()
	/// Only currently active fields participate in spell interception.
	var/list/active_fields = list()
	/// Zero disables the cap. Set by configuration/admin tooling when justified by profiling.
	var/max_active_fields = 0
	/// Current propagation mode. Only geometric coverage is implemented here.
	var/propagation_mode = ANTI_MAGIC_FIELD_PROPAGATION_GEOMETRIC

	/// Maintainer-reviewed NON-HOSTILE spell actions only.
	/// Every other spell type is prohibited inside a field (default deny).
	/// Do not add broad offensive parent paths here; approve utility spells explicitly.
	var/list/global_whitelist = list(
		// Role conversion / recruitment.
		"/datum/action/cooldown/spell/undirected/list_target/convert_role/servant",
		"/datum/action/cooldown/spell/undirected/list_target/convert_role/town_watch",
		"/datum/action/cooldown/spell/undirected/list_target/convert_role/retainer",
		"/datum/action/cooldown/spell/undirected/list_target/convert_role/chapel_acolyte",
		"/datum/action/cooldown/spell/undirected/list_target/convert_role/forest_ranger",
		"/datum/action/cooldown/spell/undirected/list_target/convert_role/adventurers_guild",

		// Healing, restoration, medicine, and repair.
		"/datum/action/cooldown/spell/healing",
		"/datum/action/cooldown/spell/defeat_absolution",
		"/datum/action/cooldown/spell/revive",
		"/datum/action/cooldown/spell/cure_rot",
		"/datum/action/cooldown/spell/attach_bodypart",
		"/datum/action/cooldown/spell/ocean_embrace",
		"/datum/action/cooldown/spell/mend_item",
		"/datum/action/cooldown/spell/undirected/psydonrespite",
		"/datum/action/cooldown/spell/undirected/regenerate",
		"/datum/action/cooldown/spell/seelie_kiss",
		"/datum/action/cooldown/spell/undirected/song/rejuvenation_song",
		"/datum/action/cooldown/spell/undirected/song/recovery_song",
		"/datum/action/cooldown/spell/undirected/conjure_item/summon_leech/pestra",

		// Medical and information utility.
		"/datum/action/cooldown/spell/diagnose",
		"/datum/action/cooldown/spell/appraise",
		"/datum/action/cooldown/spell/find_flaw",
		"/datum/action/cooldown/spell/detect_singles",
		"/datum/action/cooldown/spell/undirected/locate_dead",
		"/datum/action/cooldown/spell/undirected/arcyne_eye",
		"/datum/action/cooldown/spell/undirected/secondsight",
		"/datum/action/cooldown/spell/undirected/beast_sense",
		"/datum/action/cooldown/spell/eoran_bloom",

		// Non-hostile support buffs.
		"/datum/action/cooldown/spell/undirected/blade_ward",
		"/datum/action/cooldown/spell/undirected/protection_evil_good",
		"/datum/action/cooldown/spell/undirected/call_to_arms",
		"/datum/action/cooldown/spell/undirected/call_to_slaughter",
		"/datum/action/cooldown/spell/undirected/battle_song",
		"/datum/action/cooldown/spell/status/guidance",
		"/datum/action/cooldown/spell/status/haste",
		"/datum/action/cooldown/spell/status/vigorous_craft",
		"/datum/action/cooldown/spell/status/invisibility",
		"/datum/action/cooldown/spell/undirected/song/fervor_song",
		"/datum/action/cooldown/spell/undirected/song/accelakathist",
		"/datum/action/cooldown/spell/undirected/song/furtive_fortissimo",
		"/datum/action/cooldown/spell/undirected/song/intellectual_interval",

		// Communication, harmless tricks, and practical utility.
		"/datum/action/cooldown/spell/undirected/message",
		"/datum/action/cooldown/spell/undirected/personality_commune",
		"/datum/action/cooldown/spell/undirected/soul_speak",
		"/datum/action/cooldown/spell/undirected/howl/call_of_the_moon",
		"/datum/action/cooldown/spell/undirected/call_bird",
		"/datum/action/cooldown/spell/undirected/joke",
		"/datum/action/cooldown/spell/undirected/tragedy",
		"/datum/action/cooldown/spell/undirected/bless_crops",
		"/datum/action/cooldown/spell/undirected/longstrider",
		"/datum/action/cooldown/spell/undirected/feather_falling",
		"/datum/action/cooldown/spell/undirected/touch/darkvision",
		"/datum/action/cooldown/spell/undirected/touch/non_detection",
		"/datum/action/cooldown/spell/undirected/touch/prestidigitation",
		"/datum/action/cooldown/spell/undirected/touch/orison",
		"/datum/action/cooldown/spell/undirected/conjure_item/light",
		"/datum/action/cooldown/spell/undirected/conjure_item/summon_lockpick",
		"/datum/action/cooldown/spell/undirected/conjure_item/calling_card",
		"/datum/action/cooldown/spell/undirected/jaunt/illusory_prop",
		"/datum/action/cooldown/spell/undirected/jaunt/bush_jaunt",
		"/datum/action/cooldown/spell/aoe/knock",
		"/datum/action/cooldown/spell/seelie_replenish",
		// Legacy /obj/effect/proc_holder/spell framework: explicit non-hostile utilities.
		// Offensive, disabling, displacement, and hazardous spells are intentionally absent (default deny).
		"/obj/effect/proc_holder/spell/self/message",
		"/obj/effect/proc_holder/spell/targeted/touch/nondetection",
		"/obj/effect/proc_holder/spell/targeted/touch/lesserknock",
		"/obj/effect/proc_holder/spell/invoked/haste",
		"/obj/effect/proc_holder/spell/invoked/featherfall",
		"/obj/effect/proc_holder/spell/invoked/darkvision",
		"/obj/effect/proc_holder/spell/invoked/longstrider",
		"/obj/effect/proc_holder/spell/invoked/invisibility",
		"/obj/effect/proc_holder/spell/invoked/guidance",
		"/obj/effect/proc_holder/spell/invoked/fortitude",
		"/obj/effect/proc_holder/spell/invoked/counterspell",
		"/obj/effect/proc_holder/spell/invoked/enlarge",
		"/obj/effect/proc_holder/spell/invoked/leap",
		"/obj/effect/proc_holder/spell/invoked/blink",
		"/obj/effect/proc_holder/spell/invoked/mirror_transform",
		"/obj/effect/proc_holder/spell/invoked/mindlink",
		"/obj/effect/proc_holder/spell/invoked/stoneskin",
		"/obj/effect/proc_holder/spell/invoked/hawks_eyes",
		"/obj/effect/proc_holder/spell/invoked/giants_strength",
		"/obj/effect/proc_holder/spell/invoked/create_campfire",
		"/obj/effect/proc_holder/spell/invoked/mending",
		"/obj/effect/proc_holder/spell/self/light",
		"/obj/effect/proc_holder/spell/self/conjure_armor",

	)

/// Rebuild opted-in admin overlays only when the authoritative active registry changes.
/// The visualization is client-local; it must never be maintained by a per-tick process.
/datum/anti_magic_field_manager/proc/refresh_admin_debug_views()
	for(var/client/debug_client as anything in GLOB.clients)
		if(debug_client.anti_magic_field_debug_enabled)
			debug_client.refresh_anti_magic_field_debug()



/datum/anti_magic_field_manager/proc/register_field(obj/structure/anti_magic_field/field)
	if(!field || QDELETED(field))
		return FALSE
	if(!(field in fields))
		fields += field
	return TRUE

/datum/anti_magic_field_manager/proc/has_available_slot()
	return !max_active_fields || length(active_fields) < max_active_fields

/datum/anti_magic_field_manager/proc/activate_field(obj/structure/anti_magic_field/field)
	if(!field || QDELETED(field) || field.obj_broken || !field.is_built)
		return FALSE
	if(field.is_active)
		return TRUE
	if(!has_available_slot())
		return FALSE

	active_fields += field
	field.is_active = TRUE
	field.waiting_for_slot = FALSE
	field.on_field_activated()
	refresh_admin_debug_views()
	return TRUE

/datum/anti_magic_field_manager/proc/deactivate_field(obj/structure/anti_magic_field/field)
	if(!field || QDELETED(field) || !field.is_active)
		return FALSE

	active_fields -= field
	field.is_active = FALSE
	field.on_field_deactivated()
	refresh_admin_debug_views()
	promote_waiting_throwables()
	return TRUE

/datum/anti_magic_field_manager/proc/unregister_field(obj/structure/anti_magic_field/field)
	if(!field)
		return
	var/was_active = field.is_active
	active_fields -= field
	fields -= field
	if(was_active)
		field.is_active = FALSE
		field.on_field_deactivated()
		refresh_admin_debug_views()
		promote_waiting_throwables()

/// If an administrator enables a cap, only waiting throwables auto-promote.
/// Stationary installations remain OFF and require a deliberate toggle.
/datum/anti_magic_field_manager/proc/promote_waiting_throwables()
	if(!has_available_slot())
		return
	for(var/obj/structure/anti_magic_field/throwable/field as anything in fields)
		if(QDELETED(field) || !field.waiting_for_slot || !field.is_built || field.is_active)
			continue
		if(activate_field(field))
			field.visible_message(span_notice("[field] powers up as an anti-magic field slot becomes available."))
			break

/datum/anti_magic_field_manager/proc/is_globally_whitelisted(action_id)
	if(!istext(action_id) || !length(action_id))
		return FALSE
	for(var/allowed_action_id in global_whitelist)
		if(action_id == allowed_action_id || findtext(action_id, "[allowed_action_id]/") == 1)
			return TRUE
	return FALSE

/// Check a caster origin and every turf that the effect will touch.
/// This is the shared path for direct, AOE and cone spell validation.
/datum/anti_magic_field_manager/proc/is_action_blocked_on_turfs(turf/source_turf, action_id, list/effect_turfs)
	if(!istext(action_id) || !length(action_id))
		return FALSE
	if(!source_turf && !length(effect_turfs))
		return FALSE

	for(var/obj/structure/anti_magic_field/field as anything in active_fields)
		if(QDELETED(field))
			continue

		var/overlaps = source_turf && field.covers_turf(source_turf)
		if(!overlaps && islist(effect_turfs))
			for(var/turf/effect_turf as anything in effect_turfs)
				if(effect_turf && field.covers_turf(effect_turf))
					overlaps = TRUE
					break

		if(overlaps && !field.permits_action(action_id))
			return TRUE
	return FALSE

/// Compatibility wrapper for ordinary source/target effects.
/datum/anti_magic_field_manager/proc/is_action_blocked(atom/source, action_id, atom/target)
	var/turf/source_turf = get_turf(source)
	var/turf/target_turf = get_turf(target)
	var/list/effect_turfs = list()
	if(target_turf)
		effect_turfs += target_turf
	return is_action_blocked_on_turfs(source_turf, action_id, effect_turfs)

/// Throttle explanatory chat for repeated projectile interception. Spell audio is not duplicated here.
/datum/anti_magic_field_manager/proc/notify_blocked(mob/caster)
	if(!caster || QDELETED(caster))
		return
	if(world.time < caster.anti_magic_field_message_cooldown)
		return
	caster.anti_magic_field_message_cooldown = world.time + (1.5 SECONDS)
	to_chat(caster, span_warning("An anti-magic field suppresses my spell."))

/mob
	/// Anti-magic rejection feedback throttle; avoids chat spam from repeated projectile movement checks.
	var/tmp/anti_magic_field_message_cooldown = 0
