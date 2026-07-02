#define DAMAGE_AXE 20
#define DAMAGE_AXE_WIELD 25
#define DAMAGE_HEAVYAXE_WIELD 30
#define DAMAGE_BAD_AXE 13
#define DAMAGE_BAD_AXE_WIELD 18

#define DAMAGE_WEAK_FLAIL 17
#define DAMAGE_NORMAL_FLAIL 23
#define DAMAGE_GOOD_FLAIL 28

#define DAMAGE_CLUB 15
#define DAMAGE_CLUB_WIELD 20
#define DAMAGE_MACE 20
#define DAMAGE_MACE_WIELD 25
#define DAMAGE_HEAVYCLUB_WIELD 30

#define DAMAGE_HAMMER 10
#define DAMAGE_HAMMER_WIELD 15
#define DAMAGE_PICK 16

#define DAMAGE_KNIFE 13
#define DAMAGE_DAGGER 15

#define DAMAGE_SHIELD 15

#define DAMAGE_KATAR 15
#define DAMAGE_KNUCKLES 22

#define DAMAGE_STAFF 10
#define DAMAGE_STAFF_WIELD 15
#define DAMAGE_SPEAR 15
#define DAMAGE_SPEARPLUS 18
#define DAMAGE_SPEAR_WIELD 25
#define DAMAGE_HALBERD_WIELD 30

#define DAMAGE_SHORTSWORD 16
#define DAMAGE_SWORD 20
#define DAMAGE_SWORD_WIELD 25
#define DAMAGE_LONGSWORD_WIELD 28
#define DAMAGE_GREATSWORD_WIELD 30

#define DAMAGE_WHIP 20

// ===== AP DEFINES =======
// Pen values are legacy-scale but tier-aligned: always equal to a PEN_* constant
// from armor_defines.dm so normalize_penetration() yields the designed tier.
// Tier design (from Twilight Axis): NONE=training/base cuts, LIGHT=axe chop,
// MEDIUM=sword thrust/longsword chop, HEAVY=spear/estoc, BSTEEL=halfsword/dagger pick.
#define AP_AXE_CUT PEN_NONE
#define AP_AXE_CHOP PEN_LIGHT
#define AP_HEAVYAXE_CHOP PEN_MEDIUM
#define AP_HEAVYAXE_STAB PEN_MEDIUM
#define AP_FLAIL_STRIKE PEN_NONE		// blunt: pen unused by DR-absorb path
#define AP_CLUB_STRIKE PEN_MEDIUM		// blunt: pen unused by DR-absorb path; tier kept from legacy 25
#define AP_CLUB_HEAVY_STRIKE PEN_HEAVY
#define AP_FLAIL_SMASH PEN_BSTEEL
#define AP_CLUB_SMASH PEN_MEDIUM
#define AP_HEAVY_SMASH PEN_HEAVY
#define AP_SPEAR_THRUST PEN_HEAVY
#define AP_POLEARM_THRUST PEN_HEAVY
#define AP_POLEARM_BASH PEN_LIGHT
#define AP_POLEARM_CHOP PEN_LIGHT
#define AP_GREATAXE_CHOP PEN_MEDIUM
#define AP_SWORD_THRUST PEN_MEDIUM
#define AP_SWORD_CHOP PEN_NONE

//wdefense defines
#define TERRIBLE_PARRY -1
#define BAD_PARRY 0
#define MEDIOCRE_PARRY 1
#define AVERAGE_PARRY 2
#define GOOD_PARRY 3
#define GREAT_PARRY 4
#define ULTMATE_PARRY 5

//wbalance defines
#define VERY_EASY_TO_DODGE -2
#define EASY_TO_DODGE -1
#define DODGE_CHANCE_NORMAL 0
#define HARD_TO_DODGE 1
#define VERY_HARD_TO_DODGE 2
