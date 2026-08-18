#define HERBAL_FRESH_YIELD 5
#define HERBAL_DRIED_YIELD 10
#define HERBAL_CONCENTRATION_TIME 3 SECONDS
#define HERBAL_CANDLE_INTERVAL 10 SECONDS

// Herb preparation profiles deliberately point at the existing herbal reagents.
// Those reagents remain the authority for effects, dosage, and overdose behavior.
/obj/item/alch/herb
	var/herbal_extract
	var/herbal_extract_name
	var/list/herbal_tags
	var/herbal_beneficial = TRUE
	var/dried = FALSE
	var/drying_progress = 0
	var/drying_time = 20 MINUTES
	var/herbal_preparation_quality = 1

/obj/item/alch/herb/examine(mob/user)
	. = ..()
	. += span_notice("It is [dried ? "fully dried and ready for a strong extraction" : "fresh and suited to a quick, weak extraction"].")
	if(!isliving(user) || !herbal_extract)
		return
	var/alchemy_skill = GET_MOB_SKILL_VALUE_OLD(user, /datum/attribute/skill/craft/alchemy)
	if(alchemy_skill >= SKILL_RANK_APPRENTICE)
		. += span_info("Its established preparation profile is [herbal_extract_name].")
		if(!herbal_beneficial)
			. += span_warning("That profile is harmful rather than medicinal.")
	if(alchemy_skill >= SKILL_RANK_JOURNEYMAN && length(herbal_tags))
		. += span_info("Its useful affinities are [english_list(herbal_tags)].")

/obj/item/alch/herb/proc/finish_drying()
	if(dried)
		return
	dried = TRUE
	drying_progress = drying_time
	herbal_preparation_quality = 2
	name = "dried [initial(name)]"
	update_appearance()

/obj/item/alch/herb/artemisia
	herbal_extract = /datum/reagent/buff/herbal/artemisia_luck
	herbal_extract_name = "an invigorating fortune tonic"
	herbal_tags = list("fortune", "vitality")

/obj/item/alch/herb/atropa
	herbal_extract = /datum/reagent/poison/herbal/weak_atropa
	herbal_extract_name = "a weak atropa poison"
	herbal_tags = list("poison")
	herbal_beneficial = FALSE

/obj/item/alch/herb/benedictus
	herbal_extract = /datum/reagent/buff/herbal/benedictus_vigor
	herbal_extract_name = "a vigorous endurance tonic"
	herbal_tags = list("fortitude", "vitality")

/obj/item/alch/herb/calendula
	herbal_extract = /datum/reagent/medicine/herbal/calendula_salve
	herbal_extract_name = "a mending salve"
	herbal_tags = list("healing", "mending")

/obj/item/alch/herb/euphorbia
	herbal_extract = /datum/reagent/buff/herbal/euphorbia_strength
	herbal_extract_name = "a strengthening tonic"
	herbal_tags = list("fortitude", "vitality")

/obj/item/alch/herb/euphrasia
	herbal_extract = /datum/reagent/medicine/herbal/euphrasia_eye_wash
	herbal_extract_name = "a clarifying eye wash"
	herbal_tags = list("clarity", "sight")

/obj/item/alch/herb/hypericum
	herbal_extract = /datum/reagent/medicine/herbal/hypericum_tonic
	herbal_extract_name = "a restorative clarity tonic"
	herbal_tags = list("clarity", "vitality")

/obj/item/alch/herb/matricaria
	herbal_extract = /datum/reagent/poison/herbal/matricaria_irritant
	herbal_extract_name = "a sedating irritant"
	herbal_tags = list("poison", "sedation")
	herbal_beneficial = FALSE

/obj/item/alch/herb/mentha
	herbal_extract = /datum/reagent/medicine/herbal/mentha_tea
	herbal_extract_name = "a cleansing clarity tea"
	herbal_tags = list("clarity", "cleansing")

/obj/item/alch/herb/paris
	herbal_extract = /datum/reagent/medicine/herbal/paris_poultice
	herbal_extract_name = "a numbing poultice"
	herbal_tags = list("healing", "soothing")

/obj/item/alch/herb/rosa
	herbal_extract = /datum/reagent/medicine/herbal/simple_rosa
	herbal_extract_name = "a soothing restorative"
	herbal_tags = list("healing", "soothing")

/obj/item/alch/herb/salvia
	herbal_extract = /datum/reagent/buff/herbal/salvia_wisdom
	herbal_extract_name = "a fortifying wisdom tonic"
	herbal_tags = list("clarity", "fortitude")

/obj/item/alch/herb/symphitum
	herbal_extract = /datum/reagent/medicine/herbal/symphitum_tea
	herbal_extract_name = "a mending tea"
	herbal_tags = list("healing", "mending")

/obj/item/alch/herb/taraxacum
	herbal_extract = /datum/reagent/medicine/herbal/taraxacum_extract
	herbal_extract_name = "a cleansing restorative"
	herbal_tags = list("cleansing", "healing")

/obj/item/alch/herb/urtica
	herbal_extract = /datum/reagent/medicine/herbal/urtica_brew
	herbal_extract_name = "a blood-restoring brew"
	herbal_tags = list("blood", "vitality")

/obj/item/alch/herb/valeriana
	herbal_extract = /datum/reagent/medicine/herbal/valeriana_draught
	herbal_extract_name = "a soothing sleep draught"
	herbal_tags = list("sedation", "soothing")

// Lavender remains without an extraction profile until its existing content is made obtainable.

/obj/item/reagent_containers/glass/mortar/examine(mob/user)
	. = ..()
	if(!herbal_batch_count)
		return
	. += span_notice("It holds [herbal_batch_count] prepared herbal batch[herbal_batch_count == 1 ? "" : "es"]. Two or more can be concentrated with a pestle.")
	if(herbal_catalyst)
		. += span_info("[herbal_catalyst.name] is bound into the mixture as a catalyst.")

/obj/item/reagent_containers/glass/mortar/proc/grind_herb(mob/living/carbon/human/user)
	var/obj/item/alch/herb/herb = to_grind
	if(!herb?.herbal_extract)
		to_chat(user, span_warning("I do not know a reliable preparation for [herb]."))
		return FALSE
	var/extract_amount = herb.dried ? HERBAL_DRIED_YIELD : HERBAL_FRESH_YIELD
	if(reagents.maximum_volume - reagents.total_volume < extract_amount)
		to_chat(user, span_warning("[src] does not have enough room for this extraction."))
		return FALSE
	to_chat(user, span_notice("I begin expressing the active compounds from [herb]..."))
	playsound(src, 'sound/foley/mortarpestle.ogg', 100, FALSE)
	if(!do_after(user, 2.5 SECONDS, src) || to_grind != herb)
		return FALSE

	var/alchemy_skill = GET_MOB_SKILL_VALUE_OLD(user, /datum/attribute/skill/craft/alchemy)
	var/extract_quality = 1
	if(alchemy_skill >= SKILL_RANK_APPRENTICE)
		extract_quality = 2
	if(alchemy_skill >= SKILL_RANK_EXPERT)
		extract_quality = 3
	if(alchemy_skill >= SKILL_RANK_LEGENDARY)
		extract_quality = 4
	if(herb.dried)
		extract_quality = min(extract_quality + 1, 4)

	reagents.add_reagent(herb.herbal_extract, extract_amount, list("quality" = extract_quality))
	LAZYINITLIST(herbal_support_tags)
	LAZYINITLIST(herbal_reagent_tags)
	for(var/tag as anything in herb.herbal_tags)
		herbal_support_tags[tag] = (herbal_support_tags[tag] || 0) + 1
	if(!herbal_reagent_tags[herb.herbal_extract])
		herbal_reagent_tags[herb.herbal_extract] = herb.herbal_tags.Copy()
	herbal_batch_count++
	to_chat(user, span_notice("I express [extract_amount] units of [herb.herbal_extract_name] from [herb]."))
	QDEL_NULL(to_grind)
	user.adjust_experience(/datum/attribute/skill/craft/alchemy, GET_MOB_ATTRIBUTE_VALUE(user, STAT_INTELLIGENCE) * user.get_learning_boon(/datum/attribute/skill/craft/alchemy), FALSE)
	return TRUE

/obj/item/reagent_containers/glass/mortar/proc/try_concentrate_herbs(mob/living/carbon/human/user)
	if(!herbal_batch_count)
		return FALSE
	if(herbal_batch_count < 2)
		to_chat(user, span_warning("I need at least two herbal batches before I can concentrate an effect."))
		return TRUE

	var/list/candidates = list()
	for(var/datum/reagent/reagent as anything in reagents.reagent_list)
		if(!herbal_reagent_tags[reagent.type])
			to_chat(user, span_warning("The mixture contains non-herbal material and cannot be concentrated cleanly."))
			return TRUE
		candidates += reagent
	if(!length(candidates))
		reset_herbal_batch()
		return FALSE
	if(herbal_catalyst && !istype(herbal_catalyst, /datum/thaumaturgical_essence/order))
		var/list/catalyzed_candidates = list()
		var/catalyst_favors_poison = istype(herbal_catalyst, /datum/thaumaturgical_essence/poison)
		for(var/datum/reagent/candidate as anything in candidates)
			if(ispath(candidate.type, /datum/reagent/poison) == catalyst_favors_poison)
				catalyzed_candidates += candidate
		if(!length(catalyzed_candidates))
			to_chat(user, span_warning("The bound [herbal_catalyst.name] cannot stabilize any remaining effect."))
			return TRUE
		candidates = catalyzed_candidates

	var/datum/reagent/selected_reagent
	var/alchemy_skill = GET_MOB_SKILL_VALUE_OLD(user, /datum/attribute/skill/craft/alchemy)
	if(alchemy_skill >= SKILL_RANK_JOURNEYMAN)
		var/list/choices = list()
		for(var/datum/reagent/candidate as anything in candidates)
			choices["[candidate.name] ([round(candidate.volume, 0.1)]u)"] = candidate.type
		var/choice = input(user, "Which effect do I preserve while concentrating the mixture?", "Herbal concentration") as null|anything in choices
		if(!choice || !user.CanReach(src))
			return TRUE
		selected_reagent = reagents.get_reagent(choices[choice])
	else
		for(var/datum/reagent/candidate as anything in candidates)
			if(!selected_reagent || candidate.volume > selected_reagent.volume || (candidate.volume == selected_reagent.volume && candidate.recipe_quality > selected_reagent.recipe_quality))
				selected_reagent = candidate
		to_chat(user, span_notice("Without finer control, I settle on the strongest presence: [selected_reagent.name]."))
	if(!selected_reagent)
		return TRUE

	var/selected_type = selected_reagent.type
	var/selected_name = selected_reagent.name
	to_chat(user, span_notice("I begin reducing the mixture around [selected_name]..."))
	playsound(src, 'sound/foley/mortarpestle.ogg', 100, FALSE)
	if(!do_after(user, HERBAL_CONCENTRATION_TIME, src) || !user.CanReach(src))
		return TRUE
	selected_reagent = reagents.get_reagent(selected_type)
	if(!selected_reagent || herbal_batch_count < 2)
		return TRUE

	var/support_count = 0
	for(var/tag as anything in herbal_reagent_tags[selected_type])
		support_count = max(support_count, herbal_support_tags[tag] || 0)
	var/concentrated_quality = selected_reagent.recipe_quality
	if(support_count >= 2)
		concentrated_quality++
	if(herbal_catalyst)
		var/is_poison = ispath(selected_type, /datum/reagent/poison)
		if(istype(herbal_catalyst, /datum/thaumaturgical_essence/order) || (is_poison && istype(herbal_catalyst, /datum/thaumaturgical_essence/poison)) || (!is_poison && (istype(herbal_catalyst, /datum/thaumaturgical_essence/life) || istype(herbal_catalyst, /datum/thaumaturgical_essence/cycle))))
			concentrated_quality++
	var/concentrated_amount = max(1, round(reagents.total_volume * 0.5, 0.1))
	concentrated_quality = min(concentrated_quality, 4)

	herbal_processing = TRUE
	reagents.clear_reagents()
	reagents.add_reagent(selected_type, concentrated_amount, list("quality" = concentrated_quality))
	herbal_processing = FALSE
	var/datum/reagent/concentrate = reagents.get_reagent(selected_type)
	if(concentrate)
		concentrate.name = "concentrated [selected_name]"
		concentrate.add_data("custom_name", concentrate.name)
	reset_herbal_batch()
	to_chat(user, span_notice("The mixture reduces to [concentrated_amount] units of [concentrate?.name || selected_name]."))
	user.adjust_experience(/datum/attribute/skill/craft/alchemy, GET_MOB_ATTRIBUTE_VALUE(user, STAT_INTELLIGENCE) * 2 * user.get_learning_boon(/datum/attribute/skill/craft/alchemy), FALSE)
	return TRUE

/obj/item/reagent_containers/glass/mortar/proc/try_add_herbal_catalyst(obj/item/essence_vial/vial, mob/living/carbon/human/user)
	if(!herbal_batch_count)
		to_chat(user, span_warning("There is no herbal mixture here to stabilize."))
		return FALSE
	if(herbal_catalyst)
		to_chat(user, span_warning("The mixture already holds an essence catalyst."))
		return FALSE
	if(GET_MOB_SKILL_VALUE_OLD(user, /datum/attribute/skill/craft/alchemy) < SKILL_RANK_APPRENTICE)
		to_chat(user, span_warning("I lack the skill to bind an essence into this mixture safely."))
		return FALSE
	var/datum/thaumaturgical_essence/essence = vial.contained_essence
	if(!essence || vial.essence_amount < 1)
		to_chat(user, span_warning("[vial] contains no usable essence."))
		return FALSE
	if(!istype(essence, /datum/thaumaturgical_essence/order) && !istype(essence, /datum/thaumaturgical_essence/life) && !istype(essence, /datum/thaumaturgical_essence/cycle) && !istype(essence, /datum/thaumaturgical_essence/poison))
		to_chat(user, span_warning("[essence.name] has no stable relationship with this kind of herbal concentration."))
		return FALSE
	var/has_beneficial_extract = FALSE
	var/has_poisonous_extract = FALSE
	for(var/reagent_type as anything in herbal_reagent_tags)
		if(ispath(reagent_type, /datum/reagent/poison))
			has_poisonous_extract = TRUE
		else
			has_beneficial_extract = TRUE
	if((istype(essence, /datum/thaumaturgical_essence/life) || istype(essence, /datum/thaumaturgical_essence/cycle)) && !has_beneficial_extract)
		to_chat(user, span_warning("[essence.name] cannot reinforce any effect in this poisonous mixture."))
		return FALSE
	if(istype(essence, /datum/thaumaturgical_essence/poison) && !has_poisonous_extract)
		to_chat(user, span_warning("[essence.name] cannot reinforce any effect in this beneficial mixture."))
		return FALSE
	herbal_catalyst = essence
	vial.essence_amount--
	if(vial.essence_amount <= 0)
		vial.contained_essence = null
	vial.update_appearance(UPDATE_OVERLAYS)
	to_chat(user, span_notice("I bind one unit of [essence.name] into the herbal mixture."))
	return TRUE

/obj/item/reagent_containers/glass/mortar/proc/reset_herbal_batch()
	herbal_batch_count = 0
	herbal_support_tags = null
	herbal_reagent_tags = null
	herbal_catalyst = null

// Only the repository's two explicitly beneficial oils receive an inhaled delivery form.
/obj/item/candle/herbal
	name = "aromatic candle"
	desc = "A candle infused with a mild, beneficial herbal oil. Its effect remains close to the flame."
	var/aroma_reagent
	var/aroma_pollutant
	var/next_aroma_release

/obj/item/candle/herbal/process()
	. = ..()
	if(QDELETED(src) || !lit || !aroma_reagent || world.time < next_aroma_release)
		return
	next_aroma_release = world.time + HERBAL_CANDLE_INTERVAL
	var/turf/candle_turf = get_turf(src)
	if(aroma_pollutant)
		candle_turf?.pollute_turf(aroma_pollutant, 3)
	for(var/mob/living/carbon/target in view(1, src))
		if(!target.reagents || target.reagents.get_reagent_amount(aroma_reagent) >= 1)
			continue
		target.reagents.add_reagent(aroma_reagent, 0.2, list("quality" = 2))

/obj/item/candle/herbal/mentha
	name = "mentha aromatic candle"
	desc = "A candle infused with mentha cooling oil. Its close fragrance gently eases strain and pain."
	color = "#90ee90"
	light_color = "#b9f6ca"
	aroma_reagent = /datum/reagent/medicine/herbal/mentha_oil
	aroma_pollutant = /datum/pollutant/fragrance/mint

/obj/item/candle/herbal/rosa
	name = "rosa aromatic candle"
	desc = "A candle infused with rosa perfume oil. Its close fragrance gently lifts the spirits."
	color = "#ff9ec4"
	light_color = "#ffb6c9"
	aroma_reagent = /datum/reagent/consumable/herbal/rosa_oil
	aroma_pollutant = /datum/pollutant/fragrance/rose

/datum/repeatable_crafting_recipe/alchemy/herbal_candle
	abstract_type = /datum/repeatable_crafting_recipe/alchemy/herbal_candle
	category = "Alchemy"
	skillcraft = /datum/attribute/skill/craft/alchemy
	allow_inverse_start = TRUE
	subtypes_allowed = TRUE
	starting_atom = /obj/item/candle
	attacked_atom = /obj/item/reagent_containers/glass
	requirements = list(
		/obj/item/candle = 1,
	)
	craft_time = 5 SECONDS
	craftdiff = 1

/datum/repeatable_crafting_recipe/alchemy/herbal_candle/check_start(obj/item/attacked_item, obj/item/attacking_item, mob/user)
	var/obj/item/candle/used_candle
	if(istype(attacked_item, /obj/item/candle))
		used_candle = attacked_item
	else if(istype(attacking_item, /obj/item/candle))
		used_candle = attacking_item
	if(!used_candle || used_candle.infinite || used_candle.lit || istype(used_candle, /obj/item/candle/herbal))
		return FALSE
	return ..()

/datum/repeatable_crafting_recipe/alchemy/herbal_candle/mentha
	name = "mentha aromatic candle"
	output = /obj/item/candle/herbal/mentha
	reagent_requirements = list(
		/datum/reagent/medicine/herbal/mentha_oil = 5,
	)

/datum/repeatable_crafting_recipe/alchemy/herbal_candle/rosa
	name = "rosa aromatic candle"
	output = /obj/item/candle/herbal/rosa
	reagent_requirements = list(
		/datum/reagent/consumable/herbal/rosa_oil = 5,
	)

#undef HERBAL_CANDLE_INTERVAL
#undef HERBAL_CONCENTRATION_TIME
#undef HERBAL_DRIED_YIELD
#undef HERBAL_FRESH_YIELD
