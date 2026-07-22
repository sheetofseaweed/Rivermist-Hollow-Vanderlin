/*======================*
 *                      *
 *        GNOLL         *
 *                      *
 *======================*/

/mob/living/carbon/human/species/gnoll
    race = /datum/species/gnoll

/datum/attribute_holder/sheet/job/species/gnoll/stats
    raw_attribute_list = list(
        STAT_STRENGTH = 2,
        STAT_CONSTITUTION = 2,
        STAT_ENDURANCE = 2,
        STAT_SPEED = 1,
        STAT_INTELLIGENCE = -1,
    )

/datum/attribute_holder/sheet/job/species/gnoll/inherent
    raw_attribute_list = list(

        /datum/attribute/skill/combat/unarmed = 40,
        /datum/attribute/skill/combat/wrestling = 30,
        /datum/attribute/skill/combat/axes = 20,

        /datum/attribute/skill/misc/climbing = 30,
        /datum/attribute/skill/misc/athletics = 30,
        /datum/attribute/skill/misc/sneaking = 20,

    )

/datum/species/gnoll
    name = "Gnoll"
    id = SPEC_ID_GNOLL

    desc = "Gnolls are towering hyena-like beastfolk. Their bodies are built for endurance and close combat, possessing keen senses and frightening jaws. Although feared by most civilized folk, some have abandoned the call of the Dark Star and now wander the world as free hunters."

    default_color = "8A6948"

    species_traits = list(
        EYECOLOR,
        HAIR,
        FACEHAIR,
        LIPS,
        STUBBLE,
        OLDGREY
    )

    inherent_traits = list(
        TRAIT_NOMOBSWAP,
        TRAIT_STRONGBITE,
        TRAIT_LONGSTRIDER
    )

    inherent_sheet = /datum/attribute_holder/sheet/job/species/gnoll/inherent

    use_skintones = FALSE
    possible_ages = NORMAL_AGES_LIST

    changesource_flags = WABBAJACK

    order_num = 20

    limbs_icon_m = 'icons/roguetown/mob/bodies/m/mm.dmi'
    limbs_icon_f = 'icons/roguetown/mob/bodies/f/fm.dmi'

    statsheet_male = /datum/attribute_holder/sheet/job/species/gnoll/stats
    statsheet_female = /datum/attribute_holder/sheet/job/species/gnoll/stats

    enflamed_icon = "widefire"

    organs = list(
        ORGAN_SLOT_BRAIN = /obj/item/organ/brain,
        ORGAN_SLOT_SPLEEN = /obj/item/organ/spleen,
        ORGAN_SLOT_HEART = /obj/item/organ/heart,
        ORGAN_SLOT_LUNGS = /obj/item/organ/lungs,
        ORGAN_SLOT_EYES = /obj/item/organ/eyes/night_vision,
        ORGAN_SLOT_EARS = /obj/item/organ/ears,
        ORGAN_SLOT_TONGUE = /obj/item/organ/tongue,
        ORGAN_SLOT_LIVER = /obj/item/organ/liver,
        ORGAN_SLOT_STOMACH = /obj/item/organ/stomach,
        ORGAN_SLOT_GUTS = /obj/item/organ/guts,
        ORGAN_SLOT_PUBIC = /obj/item/organ/genitals/pubes,
        ORGAN_SLOT_ANUS = /obj/item/organ/genitals/filling_organ/anus,
    )

    meat = list(
        /obj/item/reagent_containers/food/snacks/meat/steak/human = 1,
        /obj/item/reagent_containers/food/snacks/meat/steak = 3
    )

    offset_features_m = list(
        OFFSET_HANDS = list(0,0)
    )

    offset_features_f = list(
        OFFSET_HANDS = list(0,0)
    )

    soundpack_m = /datum/voicepack/human
    soundpack_f = /datum/voicepack/human

    customizers = list(
        /datum/customizer/organ/eyes/humanoid,
        /datum/customizer/bodypart_feature/hair/head/humanoid,
        /datum/customizer/bodypart_feature/hair/facial/humanoid,
        /datum/customizer/bodypart_feature/accessory,
        /datum/customizer/bodypart_feature/face_detail,
        /datum/customizer/bodypart_feature/piercing,

        /datum/customizer/organ/genitals/penis/human,
        /datum/customizer/organ/genitals/vagina/human,
        /datum/customizer/organ/genitals/breasts/human,
        /datum/customizer/organ/genitals/belly/human,
        /datum/customizer/organ/genitals/butt/human,
        /datum/customizer/organ/genitals/testicles/human,

        /datum/customizer/bodypart_feature/pubic_hair,
    )

    bodypart_features = list(
        /datum/bodypart_feature/hair/head,
        /datum/bodypart_feature/hair/facial,
    )

/datum/species/gnoll/check_roundstart_eligible()
    return TRUE

/datum/species/gnoll/get_possible_names(gender = MALE)
    var/static/list/male_names = list(
        "Rakka",
        "Grash",
        "Korga",
        "Hruk",
        "Zogar",
        "Mogar",
        "Brakka",
        "Thrag"
    )

    var/static/list/female_names = list(
        "Shakka",
        "Vrisha",
        "Khara",
        "Yagra",
        "Rakka",
        "Hasha",
        "Grira",
        "Sazha"
    )

    return gender == FEMALE ? female_names : male_names

/datum/species/gnoll/get_possible_surnames(gender)
    return null

/datum/species/gnoll/after_creation(mob/living/carbon/human/C)
    ..()

/datum/species/gnoll/on_species_gain(mob/living/carbon/human/C, datum/species/old_species)
    . = ..()

/datum/species/gnoll/on_species_loss(mob/living/carbon/human/C)
    . = ..()

/*========================*
 *                        *
 *    GNOLL APPEARANCE    *
 *                        *
 *========================*/

/datum/species/gnoll/get_skin_list()
    return sortList(list(
        "Firepelt" = "#9C6332",
        "Ash" = "#7B746E",
        "Bone" = "#C7B48A",
        "Night" = "#353535",
        "Red" = "#8A432C",
        "Golden" = "#A6844A",
        "Brown" = "#70543B",
        "Spotted" = "#96714C"
    ))

/datum/species/gnoll/check_roundstart_eligible()
    return TRUE

/datum/species/gnoll/after_creation(mob/living/carbon/human/C)
    ..()

    C.grant_language(/datum/language/beast)

    to_chat(C,
        span_info("I can speak Beast Tongue with ,b before my speech."))


/datum/species/gnoll/on_species_gain(mob/living/carbon/human/C, datum/species/old_species)

    . = ..()

    C.ambushable = FALSE

    C.clear_mob_descriptors()

    C.add_mob_descriptor(/datum/mob_descriptor/stature/gnoll)
    C.add_mob_descriptor(/datum/mob_descriptor/height/moderate)
    C.add_mob_descriptor(/datum/mob_descriptor/body/muscular)
    C.add_mob_descriptor(/datum/mob_descriptor/fur/coarse)
    C.add_mob_descriptor(/datum/mob_descriptor/voice/growly)
    C.add_mob_descriptor(/datum/mob_descriptor/face/gnoll/long_muzzle)
    C.add_mob_descriptor(/datum/mob_descriptor/face_exp/gnoll/alert)

    C.regenerate_icons()

/datum/species/gnoll/on_species_loss(mob/living/carbon/human/C)

    . = ..()

    C.clear_mob_descriptors()

customizers = list(

    /datum/customizer/organ/eyes/humanoid,

    /datum/customizer/organ/ears/gnoll,

    /datum/customizer/bodypart_feature/muzzle/gnoll,

    /datum/customizer/bodypart_feature/fur/gnoll,

    /datum/customizer/bodypart_feature/tail/gnoll,

    /datum/customizer/bodypart_feature/accessory,

    /datum/customizer/bodypart_feature/piercing,

    /datum/customizer/organ/genitals/penis/human,
    /datum/customizer/organ/genitals/vagina/human,
    /datum/customizer/organ/genitals/breasts/human,
    /datum/customizer/organ/genitals/testicles/human,
    /datum/customizer/bodypart_feature/pubic_hair,
)

bodypart_features = list(

    /datum/bodypart_feature/fur,
    /datum/bodypart_feature/tail,
    /datum/bodypart_feature/muzzle,

)

body_markings = list(

    /datum/body_marking/spotted,
    /datum/body_marking/stripes,
    /datum/body_marking/tiger,
    /datum/body_marking/tips,
    /datum/body_marking/plain,
    /datum/body_marking/belly,
    /datum/body_marking/backspots,

)
