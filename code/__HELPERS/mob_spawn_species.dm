/// Creates corpse-spawner subtypes for every species currently available at roundstart in RMH.
#define CREATE_ALL_SPECIES_SPAWNERS(path) \
	##path/aasimar { \
		mob_species = /datum/species/aasimar; \
	} \
	##path/beastkin { \
		mob_species = /datum/species/anthromorph; \
	} \
	##path/beastkin/small { \
		mob_species = /datum/species/anthromorphsmall; \
	} \
	##path/beastkin/small/half { \
		mob_species = /datum/species/half_anthromorphsmall; \
	} \
	##path/construct { \
		mob_species = /datum/species/automaton/construct; \
	} \
	##path/construct/doll { \
		mob_species = /datum/species/automaton/construct/doll; \
	} \
	##path/dragonborn { \
		mob_species = /datum/species/dragonborn; \
	} \
	##path/dwarf { \
		mob_species = /datum/species/dwarf/mountain; \
	} \
	##path/dwarf/duergar { \
		mob_species = /datum/species/dwarf/duergar; \
	} \
	##path/elf { \
		mob_species = /datum/species/elf/snow; \
	} \
	##path/elf/dark { \
		mob_species = /datum/species/elf/dark; \
	} \
	##path/elf/dark/drider { \
		mob_species = /datum/species/elf/dark/drider; \
	} \
	##path/elf/wood { \
		mob_species = /datum/species/elf/wood; \
	} \
	##path/fluvian { \
		mob_species = /datum/species/fluvian; \
	} \
	##path/gnome { \
		mob_species = /datum/species/gnome; \
	} \
	##path/gnome/deep { \
		mob_species = /datum/species/gnome/deep; \
	} \
	##path/gnoll { \
		mob_species = /datum/species/gnoll; \
	} \
	##path/goblin { \
		mob_species = /datum/species/goblin/player; \
	} \
	##path/half_drow { \
		mob_species = /datum/species/human/halfdrow; \
	} \
	##path/half_elf { \
		mob_species = /datum/species/human/halfelf; \
	} \
	##path/half_orc { \
		mob_species = /datum/species/halforc; \
	} \
	##path/halfling { \
		mob_species = /datum/species/halfling; \
	} \
	##path/harpy { \
		mob_species = /datum/species/harpy; \
	} \
	##path/hollow_kin { \
		mob_species = /datum/species/demihuman; \
	} \
	##path/kobold { \
		mob_species = /datum/species/kobold; \
	} \
	##path/kobold/classic { \
		mob_species = /datum/species/kobold/classic; \
	} \
	##path/lizardfolk { \
		mob_species = /datum/species/lizardfolk; \
	} \
	##path/medicator { \
		mob_species = /datum/species/medicator; \
	} \
	##path/ogre { \
		mob_species = /datum/species/ogre; \
	} \
	##path/rakshari { \
		mob_species = /datum/species/rakshari; \
	} \
	##path/seelie { \
		mob_species = /datum/species/seelie; \
	} \
	##path/tabaxi { \
		mob_species = /datum/species/tabaxi; \
	} \
	##path/taur_kin { \
		mob_species = /datum/species/taur_kin; \
	} \
	##path/tiefling { \
		mob_species = /datum/species/tieberian; \
	} \
	##path/triton { \
		mob_species = /datum/species/triton; \
	} \
	##path/yuanti { \
		mob_species = /datum/species/yuanti; \
	}
