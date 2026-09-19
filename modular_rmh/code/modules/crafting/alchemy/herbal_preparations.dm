#define HERBAL_FRESH_YIELD 5
#define HERBAL_DRIED_YIELD 10
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
	herbal_extract = /datum/reagent/medicine/herbal/decoction/artemisia
	herbal_extract_name = "a bitter cleansing preparation"
	herbal_tags = list("cleansing")

/obj/item/alch/herb/atropa
	herbal_extract = /datum/reagent/medicine/herbal/anodyne/atropa
	herbal_extract_name = "a numbing nightshade preparation"
	herbal_tags = list("pain", "sight")

/obj/item/alch/herb/benedictus
	herbal_extract = /datum/reagent/medicine/herbal/decoction/benedictus
	herbal_extract_name = "a cleansing thistle preparation"
	herbal_tags = list("cleansing")

/obj/item/alch/herb/calendula
	herbal_extract = /datum/reagent/medicine/herbal/calendula_salve
	herbal_extract_name = "a mending salve"
	herbal_tags = list("healing", "mending")

/obj/item/alch/herb/euphorbia
	herbal_extract = /datum/reagent/medicine/herbal/decoction/euphorbia
	herbal_extract_name = "a restorative preparation"
	herbal_tags = list("healing")

/obj/item/alch/herb/euphrasia
	herbal_extract = /datum/reagent/medicine/herbal/euphrasia_eye_wash
	herbal_extract_name = "a clarifying eye wash"
	herbal_tags = list("clarity", "sight")

/obj/item/alch/herb/hypericum
	herbal_extract = /datum/reagent/medicine/herbal/hypericum_tonic
	herbal_extract_name = "a restorative clarity tonic"
	herbal_tags = list("clarity", "vitality")

/obj/item/alch/herb/matricaria
	herbal_extract = /datum/reagent/medicine/herbal/decoction/matricaria
	herbal_extract_name = "a healing and cleansing preparation"
	herbal_tags = list("healing", "cleansing")

/obj/item/alch/herb/mentha
	herbal_extract = /datum/reagent/medicine/herbal/mentha_tea
	herbal_extract_name = "a cleansing clarity tea"
	herbal_tags = list("clarity", "cleansing")

/obj/item/alch/herb/paris
	herbal_extract = /datum/reagent/poison/herbal/paris_poison
	herbal_extract_name = "a deadly crow's-eye poison"
	herbal_tags = list("poison")
	herbal_beneficial = FALSE

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
	. += span_notice("Work dried herbs with measured water and a pestle to prepare a wound paste. The apothecary's handbook lists the mixtures. Use the pestle's secondary action without water to express single-herb extracts.")

/obj/item/reagent_containers/glass/mortar/proc/grind_herb(mob/living/carbon/human/user, obj/item/alch/herb/herb, skip_delay = FALSE)
	if(!herb?.herbal_extract)
		to_chat(user, span_warning("I do not know a reliable preparation for [herb]."))
		return FALSE
	var/extract_amount = herb.dried ? HERBAL_DRIED_YIELD : HERBAL_FRESH_YIELD
	if(reagents.maximum_volume - reagents.total_volume < extract_amount)
		to_chat(user, span_warning("[src] does not have enough room for this extraction."))
		return FALSE
	if(!skip_delay)
		to_chat(user, span_notice("I begin expressing the active compounds from [herb]..."))
		playsound(src, 'sound/foley/mortarpestle.ogg', 100, FALSE)
		if(!do_after(user, 2.5 SECONDS, src))
			return FALSE
	if(!(herb in to_grind))
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

	reagents.add_reagent(herb.herbal_extract, extract_amount, list("quality" = extract_quality, "herbal_strength" = herb.dried ? 1 : 0.5))
	to_chat(user, span_notice("I express [extract_amount] units of [herb.herbal_extract_name] from [herb]."))
	to_grind -= herb
	qdel(herb)
	user.adjust_experience(/datum/attribute/skill/craft/alchemy, GET_MOB_ATTRIBUTE_VALUE(user, STAT_INTELLIGENCE) * user.get_learning_boon(/datum/attribute/skill/craft/alchemy), FALSE)
	return TRUE

GLOBAL_LIST_INIT(herbal_mortar_recipes, init_subtypes(/datum/herbal_mortar_recipe, list(), allow_abstract = FALSE))

/datum/herbal_mortar_recipe
	abstract_type = /datum/herbal_mortar_recipe
	var/name
	var/list/herbs = list()
	var/water_amount = 10
	var/paste_type
	var/paste_amount = 10
	var/preparation_time = 10 SECONDS

/datum/herbal_mortar_recipe/proc/can_prepare(obj/item/reagent_containers/glass/mortar/mortar)
	if(QDELETED(mortar) || !paste_type || !length(herbs))
		return FALSE
	if(length(mortar.reagents.reagent_list) != 1 || mortar.reagents.get_reagent_amount(/datum/reagent/water) != water_amount)
		return FALSE
	if(paste_amount > mortar.reagents.maximum_volume)
		return FALSE
	var/list/remaining = herbs.Copy()
	for(var/obj/item/ingredient as anything in mortar.to_grind)
		if(QDELETED(ingredient) || ingredient.loc != mortar || !istype(ingredient, /obj/item/alch/herb))
			return FALSE
		var/obj/item/alch/herb/herb = ingredient
		if(!herb.dried || !remaining[herb.type])
			return FALSE
		remaining[herb.type]--
		if(!remaining[herb.type])
			remaining -= herb.type
	return !length(remaining)

/datum/herbal_mortar_recipe/proc/prepare(obj/item/reagent_containers/glass/mortar/mortar)
	if(!can_prepare(mortar))
		return FALSE
	for(var/obj/item/ingredient as anything in mortar.to_grind.Copy())
		mortar.to_grind -= ingredient
		qdel(ingredient)
	mortar.reagents.remove_reagent(/datum/reagent/water, water_amount)
	mortar.reagents.add_reagent(paste_type, paste_amount)
	return TRUE

/obj/item/reagent_containers/glass/mortar/proc/try_prepare_herbal_paste(mob/living/user)
	if(!reagents.has_reagent(/datum/reagent/water))
		return FALSE
	var/has_herbs = FALSE
	for(var/obj/item/alch/herb/herb in to_grind)
		has_herbs = TRUE
		break
	if(!has_herbs)
		return FALSE
	var/datum/herbal_mortar_recipe/selected
	for(var/datum/herbal_mortar_recipe/recipe as anything in GLOB.herbal_mortar_recipes)
		if(recipe.can_prepare(src))
			selected = recipe
			break
	if(!selected)
		to_chat(user, span_warning("This is not a known paste mixture. I need the exact dried herbs and water listed in the apothecary's handbook, with no other ingredients."))
		return TRUE
	to_chat(user, span_notice("I begin working the dried herbs into [selected.name]..."))
	playsound(src, 'sound/foley/mortarpestle.ogg', 100, FALSE)
	if(!do_after(user, selected.preparation_time, src) || QDELETED(src) || !user.CanReach(src))
		return TRUE
	if(!selected.prepare(src))
		to_chat(user, span_warning("The ingredients have changed; I cannot finish the paste."))
		return TRUE
	to_chat(user, span_notice("I prepare [selected.paste_amount] measures of [selected.name]. Soak a dressing in it to treat wounds."))
	user.adjust_experience(/datum/attribute/skill/craft/alchemy, GET_MOB_ATTRIBUTE_VALUE(user, STAT_INTELLIGENCE) * user.get_learning_boon(/datum/attribute/skill/craft/alchemy), FALSE)
	return TRUE

/datum/herbal_mortar_recipe/calendula
	name = "calendula wound paste"
	herbs = list(/obj/item/alch/herb/calendula = 2)
	paste_type = /datum/reagent/medicine/herbal/wound_paste/calendula

/datum/herbal_mortar_recipe/mending
	name = "calendula-symphitum wound paste"
	herbs = list(/obj/item/alch/herb/calendula = 1, /obj/item/alch/herb/symphitum = 1)
	paste_type = /datum/reagent/medicine/herbal/wound_paste/mending

/datum/herbal_mortar_recipe/cooling
	name = "mentha-symphitum wound paste"
	herbs = list(/obj/item/alch/herb/mentha = 1, /obj/item/alch/herb/symphitum = 1)
	paste_type = /datum/reagent/medicine/herbal/wound_paste/cooling

/datum/herbal_mortar_recipe/anodyne
	name = "atropa wound paste"
	herbs = list(/obj/item/alch/herb/atropa = 1, /obj/item/alch/herb/calendula = 1)
	paste_type = /datum/reagent/medicine/herbal/wound_paste/anodyne

/datum/reagent/medicine/herbal/wound_paste
	name = "herbal wound paste"
	description = "A paste for soaked dressings. It treats wounds on the bandaged limb, not internal ailments."
	metabolization_rate = 0.2
	var/wound_healing = 1
	var/burn_healing = 1
	var/pain_relief = 0

/datum/reagent/medicine/herbal/wound_paste/on_bodypart_absorb(obj/item/bodypart/bodypart, mob/living/carbon/patient, amount_to_transfer)
	var/remaining_healing = amount_to_transfer
	var/treated_wound = FALSE
	for(var/datum/injury/injury as anything in bodypart.injuries)
		if(injury.damage_type == WOUND_DIVINE || injury.damage <= 0)
			continue
		treated_wound = TRUE
		var/healing_multiplier = injury.damage_type == WOUND_BURN ? burn_healing : wound_healing
		if(healing_multiplier > 0 && remaining_healing > 0)
			var/healing = min(injury.damage, remaining_healing * healing_multiplier)
			injury.heal_damage(healing)
			remaining_healing -= healing / healing_multiplier
	if(treated_wound && pain_relief)
		bodypart.add_pain(-amount_to_transfer * pain_relief)

/datum/reagent/medicine/herbal/wound_paste/calendula
	name = "Calendula Wound Paste"
	color = "#ff8c00"
	wound_healing = 2
	burn_healing = 3

/datum/reagent/medicine/herbal/wound_paste/mending
	name = "Calendula-Symphitum Wound Paste"
	color = "#a4a653"
	wound_healing = 3
	burn_healing = 1

/datum/reagent/medicine/herbal/wound_paste/cooling
	name = "Mentha-Symphitum Wound Paste"
	color = "#90ee90"
	pain_relief = 1

/datum/reagent/medicine/herbal/wound_paste/anodyne
	name = "Atropa Wound Paste"
	color = "#75606f"
	pain_relief = 2

/datum/reagent/medicine/herbal/anodyne/atropa
	name = "Atropa Anodyne"
	description = "A numbing nightshade preparation for pain and irritated eyes."
	color = "#75606f"
	metabolization_rate = 0.3
	overdose_threshold = 20

/datum/reagent/medicine/herbal/anodyne/atropa/on_mob_life(mob/living/carbon/patient, efficiency)
	if(volume > 0.99)
		patient.add_chem_effect(CE_PAINKILLER, 8, "[type]")
		patient.adjustOrganLoss(ORGAN_SLOT_EYES, -0.1 * REM * efficiency)
	return ..()

/datum/reagent/medicine/herbal/anodyne/atropa/on_mob_end_metabolize(mob/living/patient)
	patient.remove_chem_effect(CE_PAINKILLER, "[type]")
	return ..()

/datum/reagent/poison/herbal/paris_poison
	name = "Paris Poison"
	description = "A deadly crow's-eye poison that causes nausea, confusion, and paralysis."
	color = "#384b2a"
	metabolization_rate = 0.7
	overdose_threshold = 10

/datum/reagent/poison/herbal/paris_poison/on_mob_life(mob/living/carbon/patient, efficiency)
	patient.adjustToxLoss(1.5 * efficiency)
	patient.add_nausea(1)
	patient.set_confusion_if_lower(2 SECONDS * efficiency)
	if(prob(10 * efficiency))
		patient.Unconscious(5)
	return ..()

/datum/reagent/medicine/herbal/compound
	parent_type = /datum/reagent/medicine/herbal/decoction

/datum/reagent/medicine/herbal/compound/purifying
	name = "Artemisia-Taraxacum Purifying Decoction"
	description = "A bitter compound that eases toxins and purges small amounts of harmful reagents."
	color = "#b7a85f"
	toxin_healing = 1.5

/datum/reagent/medicine/herbal/compound/purifying/on_mob_life(mob/living/carbon/patient, efficiency)
	if(volume > 0.99)
		for(var/datum/reagent/other as anything in patient.reagents.reagent_list.Copy())
			if(istype(other, /datum/reagent/poison) || istype(other, /datum/reagent/toxin))
				patient.reagents.remove_reagent(other.type, min(0.5 * efficiency, other.volume))
	return ..()

/datum/reagent/medicine/herbal/compound/restorative
	name = "Mentha-Hypericum Restorative Decoction"
	description = "A bright herbal compound that steadies the body and lifts the mood."
	color = "#96b878"
	brute_healing = 0.5
	burn_healing = 0.5

/datum/reagent/medicine/herbal/compound/restorative/on_mob_metabolize(mob/living/patient)
	. = ..()
	patient.add_stress(/datum/stress_event/herbal_wellness)

/datum/reagent/medicine/herbal/compound/bloodroot
	name = "Rosa-Valeriana Bloodroot Decoction"
	description = "A red herbal compound that restores blood and supports recovery."
	color = "#a64b59"
	brute_healing = 0.5

/datum/reagent/medicine/herbal/compound/bloodroot/on_mob_life(mob/living/carbon/patient, efficiency)
	if(volume > 0.99)
		patient.adjust_bloodvolume(5 * herbal_strength * efficiency, BLOOD_VOLUME_NORMAL)
	return ..()

/datum/herbal_mortar_recipe/return_recipe_data()
	var/datum/reagent/medicine/herbal/wound_paste/paste = paste_type
	return list(
		"type" = "container_craft",
		"name" = name,
		"category" = "Herbal Poultices",
		"craft_verb" = "grinding ",
		"crafting_time" = preparation_time / (1 SECONDS),
		"requirements" = items_list(herbs),
		"reagents" = reagents_list(list(/datum/reagent/water = water_amount)),
		"container_name" = "mortar and pestle",
		"extra_html" = "All herbs must be fully dried. Put exactly these herbs and water into the mortar, then use a pestle. No other ingredients may be present.<br>Yields [paste_amount] measures of [initial(paste.name)]. Soak cloth in the paste and bandage the wounded limb.<br>Per measure: up to [initial(paste.wound_healing)] wound damage or [initial(paste.burn_healing)] burn damage healed across the limb's injuries; [initial(paste.pain_relief)] pain relief on a wounded limb. No internal healing.",
	)

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

/datum/reagent/herbal_infusion
	name = "crude aromatic infusion"
	description = "A crude herbal infusion in spirits for distilling aromatic oil. It is not a finished remedy."
	reagent_state = LIQUID
	boiling_point = T0C + 100

/datum/reagent/herbal_infusion/rosa
	name = "Crude Rosa Infusion"
	color = "#d991aa"
	taste_description = "rose petals"

/datum/reagent/herbal_infusion/mentha
	name = "Crude Mentha Infusion"
	color = "#82ad7e"
	taste_description = "mint leaves"

/datum/container_craft/cooking/herbal_oil/after_craft(atom/created_output, obj/item/crafter, mob/initiator, list/found_optional_requirements, list/found_optional_wildcards, list/found_optional_reagents, list/removing_items)
	. = ..()
	var/datum/reagent/infusion = crafter.reagents.get_reagent(created_reagent)
	if(!infusion)
		return
	// Distillation carries reagent data into a different product.
	infusion.data -= "custom_name"
	infusion.data -= "custom_tastes"
	infusion.data -= "metabolization_mult"
	infusion.metabolization_rate = initial(infusion.metabolization_rate)

/datum/container_craft/cooking/herbal_oil/extra_html()
	. = ..()
	. += "Heat the pot on a lit fire to at least [required_chem_temp - T0C]&deg;C. Transfer the infusion to an alembic to distill the finished oil. Fresh or dried herbs may be used; drying improves brewing quality, not oil yield."

/datum/distillation_recipe/herbal_oil
	abstract_type = /datum/distillation_recipe/herbal_oil
	required_temp = T0C + 100
	distill_sound = "bubbles"

/datum/distillation_recipe/herbal_oil/rosa
	name = "Distill Rosa Perfume Oil"
	id = "herbal_rosa_oil"
	distilled_reagent = /datum/reagent/herbal_infusion/rosa
	results = list(/datum/reagent/consumable/herbal/rosa_oil = 1 / 3)
	distill_message = "Fragrant rose oil collects from the steaming infusion."

/datum/distillation_recipe/herbal_oil/mentha
	name = "Distill Mentha Cooling Oil"
	id = "herbal_mentha_oil"
	distilled_reagent = /datum/reagent/herbal_infusion/mentha
	results = list(/datum/reagent/medicine/herbal/mentha_oil = 1 / 3)
	distill_message = "Cool mint-scented oil collects from the steaming infusion."

/datum/distillation_recipe/herbal_oil/return_recipe_data()
	var/datum/reagent/input_type = distilled_reagent
	var/output_text = ""
	for(var/datum/reagent/result_type as anything in results)
		output_text += "[round(results[result_type] * 30, 0.01)] measures of [initial(result_type.name)]<br>"
	return list(
		"type" = "book_entry",
		"name" = name,
		"category" = "Herbal Distillation",
		"html" = "<h2>[name]</h2><p>Input: 30 measures of [initial(input_type.name)]. Separation temperature: [initial(input_type.boiling_point) - T0C]&deg;C.</p><p>Output:<br>[output_text]</p><p>Insert the infusion vessel into the alembic and load its contents. Replace it with an empty receiving vessel, then start heating. The alembic chooses the fraction automatically. Keep different infusions in separate batches for a pure oil.</p><p>Yield scales with the infusion actually distilled. Extra water does not produce extra oil. Finished oil can be used in aromatic candles; it has no further herbal refinement recipe.</p>",
	)

/datum/reagent/medicine/herbal/decoction
	name = "herbal decoction"
	description = "A slow oral herbal remedy. Fresh herbs give half-strength medicine."
	var/toxin_healing = 0
	var/brute_healing = 0
	var/burn_healing = 0
	var/herbal_strength = 0.5

/datum/reagent/medicine/herbal/decoction/on_new(list/incoming_data)
	. = ..()
	herbal_strength = CLAMP(incoming_data?["herbal_strength"] || 0.5, 0.5, 1)
	data["herbal_strength"] = herbal_strength

/datum/reagent/medicine/herbal/decoction/on_merge(list/incoming_data, other_volume)
	var/merged_strength = min(herbal_strength, incoming_data?["herbal_strength"] || 0.5)
	. = ..()
	herbal_strength = merged_strength
	data["herbal_strength"] = herbal_strength

/datum/reagent/medicine/herbal/decoction/on_mob_metabolize(mob/living/patient)
	. = ..()
	patient.add_stress(/datum/stress_event/herbal_calm)

/datum/reagent/medicine/herbal/decoction/on_mob_life(mob/living/carbon/patient, efficiency)
	if(volume >= 1)
		var/potency = herbal_strength * efficiency
		if(toxin_healing)
			patient.adjustToxLoss(-toxin_healing * potency)
		if(brute_healing)
			patient.adjustBruteLoss(-brute_healing * REM * potency, FALSE)
		if(burn_healing)
			patient.adjustFireLoss(-burn_healing * REM * potency, FALSE)
	return ..()

/datum/reagent/medicine/herbal/decoction/on_bodypart_absorb(obj/item/bodypart/bodypart, mob/living/carbon/patient, amount_to_transfer)
	return

/datum/reagent/medicine/herbal/decoction/artemisia
	name = "Artemisia Bitter Decoction"
	description = "A bitter oral remedy that eases toxin damage. It does not purge poisons still in the blood."
	color = "#a0aa80"
	toxin_healing = 1

/datum/reagent/medicine/herbal/decoction/benedictus
	name = "Benedictus Cleansing Decoction"
	description = "A thistle decoction that eases toxin damage."
	color = "#ad925d"
	toxin_healing = 0.75

/datum/reagent/medicine/herbal/decoction/matricaria
	name = "Matricaria Restorative Decoction"
	description = "A chamomile decoction that heals bruises and burns and eases toxin damage."
	color = "#eedb93"
	toxin_healing = 0.5
	brute_healing = 0.75
	burn_healing = 0.75

/datum/reagent/medicine/herbal/decoction/euphorbia
	name = "Euphorbia Restorative Decoction"
	description = "An oral herbal remedy for bruises and burns."
	color = "#83a865"
	brute_healing = 1
	burn_healing = 1

/datum/container_craft/cooking/herbal_decoction
	abstract_type = /datum/container_craft/cooking/herbal_decoction
	category = "Herbal Decoctions"
	used_skill = /datum/attribute/skill/craft/alchemy
	reagent_requirements = list(/datum/reagent/water = 25)
	water_conversion = 0.4
	crafting_time = 10 SECONDS
	required_chem_temp = T0C + 80
	craft_verb = "brewing "
	complete_message = "The herbal decoction is ready."

/datum/container_craft/cooking/herbal_decoction/after_craft(atom/created_output, obj/item/crafter, mob/initiator, list/found_optional_requirements, list/found_optional_wildcards, list/found_optional_reagents, list/removing_items)
	. = ..()
	var/datum/reagent/medicine/herbal/decoction/remedy = crafter.reagents.get_reagent(created_reagent)
	if(!istype(remedy))
		return
	var/strength = 1
	var/herb_count = 0
	for(var/obj/item/alch/herb/herb in removing_items)
		herb_count++
		if(!herb.dried)
			strength = 0.5
	if(!herb_count)
		strength = 0.5
	// Existing batches retain the weaker strength when mixed.
	if(remedy.volume > reagent_requirements[/datum/reagent/water] * water_conversion)
		strength = min(strength, remedy.herbal_strength)
	remedy.herbal_strength = strength
	remedy.data["herbal_strength"] = strength

/datum/container_craft/cooking/herbal_decoction/extra_html()
	. = ..()
	var/datum/reagent/medicine/herbal/decoction/remedy_type = created_reagent
	. += "Heat on a lit fire to [required_chem_temp - T0C]&deg;C. Fresh herbs or mixed fresh/dried batches give half strength; every herb must be dried for full strength. Mixing strengths keeps the weaker strength.<br>[initial(remedy_type.description)] Drink the decoction; it does not treat wounds through a bandage."

#undef HERBAL_CANDLE_INTERVAL
#undef HERBAL_DRIED_YIELD
#undef HERBAL_FRESH_YIELD
