/datum/loot_table/dungeon
	name = "dungeon"
	loot_table = list(
		list(
			// Materials
			/obj/item/natural/bundle/stick = 2,
			/obj/item/natural/fibers = 4,
			/obj/item/natural/stone = 4,
			/obj/item/ore/coal	= 4,
			/obj/item/ingot/iron = 1,
			/obj/item/ingot/steel = 1,
			/obj/item/ore/iron = 3,
			/obj/item/natural/bundle/fibers = 2,

			// Clothing
			/obj/item/clothing/cloak/stabard = 3,
			/obj/item/storage/backpack/satchel = 3,
			/obj/item/clothing/shoes/simpleshoes = 4,
			/obj/item/clothing/shirt/undershirt/colored/random = 5,
			/obj/item/storage/belt/leather/cloth = 4,
			/obj/item/clothing/cloak/raincloak/colored/mortus = 3,
			/obj/item/clothing/head/armingcap = 4,
			/obj/item/clothing/cloak/apron/waist = 3,
			/obj/item/storage/belt/leather/rope = 3,
			/obj/item/clothing/pants/tights/colored/vagrant = 4,
			/obj/item/clothing/gloves/leather = 4,
			/obj/item/clothing/shoes/boots = 4,
			/obj/item/clothing/shoes/boots/leather = 4,
			/obj/item/storage/belt/leather/knifebelt/iron = 2,
			/obj/item/storage/belt/leather/knifebelt/black/steel = 1,

			// Money
			/obj/item/coin/copper = 5,
			/obj/item/coin/silver = 5,
			/obj/item/coin/gold = 5,
			/obj/item/coin/copper/pile = 3,
			/obj/item/coin/silver/pile = 2,
			/obj/item/coin/gold/pile = 1,

			// Garbage and Miscellanous
			/obj/item/instrument/flute = 3,
			/obj/item/fertilizer/ash = 5,
			/obj/item/natural/glass/shard = 5,
			/obj/item/candle/yellow = 3,
			/obj/item/flashlight/flare/torch = 3,
			/obj/item/reagent_containers/glass/bowl = 4,
			/obj/item/reagent_containers/glass/cup = 4,
			/obj/item/reagent_containers/glass/cup/wooden = 4,
			/obj/item/reagent_containers/glass/cup/steel = 3,
			/obj/item/reagent_containers/glass/cup/golden = 1,
			/obj/item/reagent_containers/glass/cup/skull = 1,
			/obj/item/reagent_containers/glass/bucket = 3,
			/obj/item/natural/feather = 4,
			/obj/item/paper/scroll = 3,
			/obj/item/rope = 3,
			/obj/item/rope/chain = 3,
			/obj/item/clothing/face/cigarette/pipe = 3,
			/obj/item/paper = 3,
			/obj/item/reagent_containers/glass/bowl = 3,
			/obj/item/storage/bag/tray = 3,

			//medical
			/obj/item/needle = 4,
			/obj/item/natural/cloth = 5,
			/obj/item/natural/bundle/cloth = 3,

			//weapons
			/obj/item/weapon/mace = 2,
			/obj/item/weapon/knife/dagger/steel = 3,
			/obj/item/gun/ballistic/revolver/grenadelauncher/bow = 2,
			/obj/item/gun/ballistic/revolver/grenadelauncher/bow/short = 2,
			/obj/item/gun/ballistic/revolver/grenadelauncher/crossbow = 2,
			/obj/item/ammo_holder/quiver/arrows = 2,
			/obj/item/ammo_holder/quiver/bolts = 2,
			/obj/item/weapon/mace/woodclub/crafted = 3,
			/obj/item/weapon/mace/steel/morningstar =2,
			/obj/item/weapon/mace/cudgel = 2,
			/obj/item/weapon/knife = 3,
			/obj/item/weapon/knife/copper = 3,
			/obj/item/weapon/polearm/halberd = 1,
			/obj/item/weapon/polearm/woodstaff = 3,
			/obj/item/weapon/spear = 2,
			/obj/item/weapon/knife/dagger/navaja = 2,
			/obj/item/weapon/sword/sabre/cutlass = 2,
			/obj/item/weapon/sword/long = 2,
			/obj/item/weapon/flail = 1,
			/obj/item/weapon/estoc = 1,
			/obj/item/weapon/sword/long/greatsword/zwei = 1,
			/obj/item/weapon/polearm/eaglebeak/lucerne = 1,
			/obj/item/weapon/polearm/eaglebeak = 1,
			/obj/item/weapon/spear = 1,
			/obj/item/weapon/knife/throwingknife/steel = 1,

			// tools
			/obj/item/weapon/shovel = 3,
			/obj/item/weapon/thresher = 3,
			/obj/item/flint = 4,
			/obj/item/weapon/polearm/halberd/bardiche/woodcutter = 3,
			/obj/item/weapon/axe = 3,
			/obj/item/weapon/hammer = 3,
			/obj/item/weapon/tongs = 3,
			/obj/item/weapon/pick = 3,

			//armor
			/obj/item/clothing/armor/leather = 2,
			/obj/item/clothing/armor/leather/hide = 2,
			/obj/item/clothing/armor/gambeson = 2,
			/obj/item/clothing/pants/chainlegs = 2,
			/obj/item/clothing/pants/platelegs = 1,
			/obj/item/clothing/gloves/chain = 2,
			/obj/item/clothing/armor/chainmail = 1,
			/obj/item/clothing/armor/chainmail/iron = 2,
			/obj/item/clothing/armor/chainmail/hauberk = 1,
			/obj/item/clothing/armor/plate = 1,
			/obj/item/clothing/neck/gorget = 1,
			/obj/item/clothing/head/helmet/kettle = 1,
			/obj/item/clothing/head/helmet/leather = 2,
			/obj/item/clothing/head/helmet/horned = 1,
			/obj/item/clothing/head/helmet/skullcap = 1,
			/obj/item/clothing/head/helmet/winged = 1,
			/obj/item/clothing/armor/plate = 1,


			//food
			/obj/item/reagent_containers/food/snacks/hardtack = 3,
			/obj/item/reagent_containers/food/snacks/butterslice = 3,
			/obj/item/reagent_containers/powder/salt = 3,
			/obj/item/reagent_containers/food/snacks/egg = 3,

		)
	)
	base_max = 1

/datum/loot_table/dungeon/materials
	name = "material"
	loot_table = list(
		list(
			// Materials
			/obj/item/natural/bundle/stick = 2,
			/obj/item/natural/fibers = 3,
			/obj/item/natural/stone = 3,
			/obj/item/grown/log/tree/small = 3,
			/obj/item/ore/coal	= 3,
			/obj/item/ingot/iron = 2,
			/obj/item/ingot/steel = 2,
			/obj/item/ore/iron = 3,
			/obj/item/natural/bundle/fibers = 2
			)
		)
	base_max = 2

/datum/loot_table/dungeon/clothing
	name = "clothing"
	loot_table = list(
		list(
			// Clothing
			/obj/item/clothing/cloak/stabard = 3,
			/obj/item/storage/backpack/satchel = 3,
			/obj/item/clothing/shoes/simpleshoes = 4,
			/obj/item/clothing/shirt/undershirt/colored/random = 5,
			/obj/item/storage/belt/leather/cloth = 4,
			/obj/item/clothing/cloak/raincloak/colored/mortus = 3,
			/obj/item/clothing/head/armingcap = 4,
			/obj/item/clothing/cloak/apron/waist = 3,
			/obj/item/storage/belt/leather/rope = 3,
			/obj/item/clothing/pants/tights/colored/vagrant = 4,
			/obj/item/clothing/gloves/leather = 4,
			/obj/item/clothing/shoes/boots = 4,
			/obj/item/clothing/shoes/boots/leather = 4
			)
		)
	base_max = 2

/datum/loot_table/dungeon/money
	name = "money"
	loot_table = list(
		list(
			// Clothing
			/obj/item/clothing/cloak/stabard = 3,
			/obj/item/storage/backpack/satchel = 3,
			/obj/item/clothing/shoes/simpleshoes = 4,
			/obj/item/clothing/shirt/undershirt/colored/random = 5,
			/obj/item/storage/belt/leather/cloth = 4,
			/obj/item/clothing/cloak/raincloak/colored/mortus = 3,
			/obj/item/clothing/head/armingcap = 4,
			/obj/item/clothing/cloak/apron/waist = 3,
			/obj/item/storage/belt/leather/rope = 3,
			/obj/item/clothing/pants/tights/colored/vagrant = 4,
			/obj/item/clothing/gloves/leather = 4,
			/obj/item/clothing/shoes/boots = 4,
			/obj/item/clothing/shoes/boots/leather = 4
			)
		)
	base_max = 2

/datum/loot_table/dungeon/misc
	name = "misc"
	loot_table = list(
		list(
			// Garbage and Miscellanous
			/obj/item/instrument/flute = 3,
			/obj/item/instrument/lute = 3,
			/obj/item/instrument/accord = 3,
			/obj/item/fertilizer/ash = 5,
			/obj/item/natural/glass/shard = 5,
			/obj/item/candle/yellow = 3,
			/obj/item/flashlight/flare/torch = 3,
			/obj/item/flashlight/flare/torch/lantern = 1,
			/obj/item/reagent_containers/glass/bowl = 4,
			/obj/item/reagent_containers/glass/cup = 4,
			/obj/item/reagent_containers/glass/cup/wooden = 4,
			/obj/item/reagent_containers/glass/cup/steel = 3,
			/obj/item/reagent_containers/glass/cup/golden = 1,
			/obj/item/reagent_containers/glass/cup/skull = 1,
			/obj/item/reagent_containers/glass/bucket = 3,
			/obj/item/natural/feather = 4,
			/obj/item/paper/scroll = 3,
			/obj/item/rope = 3,
			/obj/item/rope/chain = 3,
			/obj/item/clothing/face/cigarette/pipe = 3,
			/obj/item/clothing/face/cigarette/rollie = 3,
			/obj/item/paper = 3,
			/obj/item/reagent_containers/glass/bowl = 3,
			/obj/item/storage/bag/tray = 3
			)
		)
	base_max = 1

/datum/loot_table/dungeon/medical
	name = "medical"
	loot_table = list(
		list(
			//medical
			/obj/item/needle = 4,
			/obj/item/natural/cloth = 5,
			/obj/item/natural/bundle/cloth = 3
			)
		)
	base_max = 2

/datum/loot_table/dungeon/weapons
	name = "weapons"
	loot_table = list(
			list(
			//weapons
			/obj/item/weapon/mace = 2,
			/obj/item/weapon/knife/dagger/steel = 3,
			/obj/item/gun/ballistic/revolver/grenadelauncher/bow = 2,
			/obj/item/gun/ballistic/revolver/grenadelauncher/bow/short = 2,
			/obj/item/gun/ballistic/revolver/grenadelauncher/crossbow = 2,
			/obj/item/ammo_holder/quiver/arrows = 2,
			/obj/item/ammo_holder/quiver/bolts = 2,
			/obj/item/weapon/mace/woodclub/crafted = 3,
			/obj/item/weapon/mace/steel/morningstar =2,
			/obj/item/weapon/mace/cudgel = 2,
			/obj/item/weapon/knife = 3,
			/obj/item/weapon/knife/copper = 3,
			/obj/item/weapon/polearm/halberd = 1,
			/obj/item/weapon/polearm/woodstaff = 3,
			/obj/item/weapon/spear = 2,
			/obj/item/weapon/knife/dagger/navaja = 2,
			/obj/item/weapon/sword/sabre/cutlass = 2,
			/obj/item/weapon/sword/long = 2,
			/obj/item/weapon/flail = 1,
			/obj/item/weapon/estoc = 1,
			/obj/item/weapon/sword/long/greatsword/zwei = 1,
			/obj/item/weapon/polearm/eaglebeak/lucerne = 1,
			/obj/item/weapon/polearm/eaglebeak = 1,
			/obj/item/weapon/spear = 1


			)
		)
	base_max = 1

/datum/loot_table/dungeon/tools
	name = "tools"
	loot_table = list(
		list(
			// tools
			/obj/item/weapon/shovel = 3,
			/obj/item/weapon/thresher = 3,
			/obj/item/flint = 4,
			/obj/item/weapon/polearm/halberd/bardiche/woodcutter = 3,
			/obj/item/weapon/axe = 3,
			/obj/item/weapon/hammer = 3,
			/obj/item/weapon/tongs = 3,
			/obj/item/weapon/pick = 3
		)
		)
	base_max = 1

/datum/loot_table/dungeon/armor
	name = "armor"
	loot_table = list(
			list(
			//armor
			/obj/item/clothing/armor/leather = 2,
			/obj/item/clothing/armor/leather/hide = 2,
			/obj/item/clothing/armor/gambeson = 2,
			/obj/item/clothing/pants/chainlegs = 2,
			/obj/item/clothing/pants/platelegs = 1,
			/obj/item/clothing/gloves/chain = 2,
			/obj/item/clothing/armor/chainmail = 1,
			/obj/item/clothing/armor/chainmail/iron = 2,
			/obj/item/clothing/armor/chainmail/hauberk = 1,
			/obj/item/clothing/armor/plate = 1,
			/obj/item/clothing/neck/gorget = 1,
			/obj/item/clothing/head/helmet/kettle = 1,
			/obj/item/clothing/head/helmet/leather = 2,
			/obj/item/clothing/head/helmet/horned = 1,
			/obj/item/clothing/head/helmet/skullcap = 1,
			/obj/item/clothing/head/helmet/winged = 1,
			/obj/item/clothing/armor/plate = 1
			)
		)
	base_max = 1

/datum/loot_table/dungeon/food
	name = "food"
	loot_table = list(
		list(
			//food
			/obj/item/reagent_containers/food/snacks/hardtack = 3,
			/obj/item/reagent_containers/food/snacks/butterslice = 3,
			/obj/item/reagent_containers/powder/salt = 3,
			/obj/item/reagent_containers/food/snacks/egg = 3
			)
		)
	base_max = 2

/datum/loot_table/dungeon/spells
	name = "spells"
	loot_table = list(
		list(
			//spells
			/obj/item/book/granter/spell/magick/fetch = 3,
			/obj/item/book/granter/spell/magick/fireball = 3,
			/obj/item/book/granter/spell/magick/lightning = 2,
			/obj/item/book/granter/spell/magick/blindness = 2,
			/obj/item/book/granter/spell/magick/invisibility = 2,
			/obj/item/book/granter/spell/magick/greaterfireball = 1
			)
		)
	base_max = 1

/obj/effect/spawner/map_spawner/loot/dungeon
	name = "dungeon spawner"
	loot_table_type = /datum/loot_table/dungeon

/obj/effect/spawner/map_spawner/loot/dungeon/materials
	//icon_state = "dungeon material"
	loot_table_type = /datum/loot_table/dungeon/materials

/obj/effect/spawner/map_spawner/loot/dungeon/clothing
	//icon_state = "dungeon clothing"
	loot_table_type = /datum/loot_table/dungeon/clothing

/obj/effect/spawner/map_spawner/loot/dungeon/money
	//icon_state = "dungeon money"
	loot_table_type = /datum/loot_table/dungeon/money

/obj/effect/spawner/map_spawner/loot/dungeon/misc
	//icon_state = "dungeon misc"
	loot_table_type = /datum/loot_table/dungeon/misc

/obj/effect/spawner/map_spawner/loot/dungeon/medical
	//icon_state = "dungeon medical"
	loot_table_type = /datum/loot_table/dungeon/medical

/obj/effect/spawner/map_spawner/loot/dungeon/weapons
	//icon_state = "dungeon weapon"
	loot_table_type = /datum/loot_table/dungeon/weapons

/obj/effect/spawner/map_spawner/loot/dungeon/tools
	//icon_state = "dungeon tools"
	loot_table_type = /datum/loot_table/dungeon/tools

/obj/effect/spawner/map_spawner/loot/dungeon/armor
	//icon_state = "dungeon armor"
	loot_table_type = /datum/loot_table/dungeon/armor

/obj/effect/spawner/map_spawner/loot/dungeon/food
	//icon_state = "dungeon food"
	loot_table_type = /datum/loot_table/dungeon/food

/obj/effect/spawner/map_spawner/loot/dungeon/spells
	//icon_state = "dungeon spells"
	loot_table_type = /datum/loot_table/dungeon/spells
