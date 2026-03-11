#define QUEST_DIFFICULTY_EASY "Easy"
#define QUEST_DIFFICULTY_MEDIUM "Medium"
#define QUEST_DIFFICULTY_HARD "Hard"

#define QUEST_RETRIEVAL "Retrieval"
#define QUEST_COURIER "Courier"
#define QUEST_KILL_EASY "Kill"
#define QUEST_CLEAR_OUT "Clear Out"
#define QUEST_RAID "Raid"
#define QUEST_OUTLAW "Outlaw"
#define QUEST_BEACON "Beacon"

#define QUEST_REWARD_EASY_LOW 30
#define QUEST_REWARD_EASY_HIGH 35
#define QUEST_REWARD_MEDIUM_LOW 45
#define QUEST_REWARD_MEDIUM_HIGH 65
#define QUEST_REWARD_HARD_LOW 120
#define QUEST_REWARD_HARD_HIGH 180

#define QUEST_DEPOSIT_EASY 5
#define QUEST_DEPOSIT_MEDIUM 10
#define QUEST_DEPOSIT_HARD 20

#define QUEST_HANDLER_REWARD_MULTIPLIER 2

// Delivery quest additional reward scaling
#define QUEST_DELIVERY_DISTANCE_DIVISOR 8 // Divides the distance for reward calculation
#define QUEST_DELIVERY_DISTANCE_BONUS 1 // Adds a bonus for longer distances
#define QUEST_COURIER_BONUS_FLAT 10 // Flat bonus for courier quests, since you gotta wait for a person to open a package
#define QUEST_DELIVERY_PER_ITEM_BONUS 2 // Bonus per item delivered


// ==>>> NEW LIST

#define QUEST_KILL_MOBS_LIST list(\
	/mob/living/simple_animal/hostile/skeleton = 5,\
	/mob/living/simple_animal/hostile/skeleton/axe = 5,\
	/mob/living/simple_animal/hostile/skeleton/spear = 5,\
	/mob/living/simple_animal/hostile/skeleton/bow = 5,\
	/mob/living/simple_animal/hostile/retaliate/shade = 4,\
	/mob/living/simple_animal/hostile/retaliate/poltergeist = 4,\
	/mob/living/simple_animal/hostile/retaliate/smallrat = 2,\
	/mob/living/simple_animal/hostile/retaliate/bigrat = 3,\
	/mob/living/simple_animal/hostile/retaliate/bat = 3,\
	/mob/living/simple_animal/hostile/retaliate/frog = 2,\
	/mob/living/simple_animal/hostile/retaliate/raccoon = 4,\
	/mob/living/simple_animal/hostile/retaliate/fox = 4,\
	/mob/living/simple_animal/hostile/retaliate/wolf = 5,\
	/mob/living/simple_animal/hostile/retaliate/spider = 5,\
	/mob/living/simple_animal/hostile/retaliate/meatvine = 5,\
	/mob/living/carbon/human/species/goblin = 4,\
	/mob/living/carbon/human/species/kobold = 4,\
	/mob/living/carbon/human/species/skeleton = 4,\
	/mob/living/carbon/human/species/zizombie = 4,\
)
#define QUEST_KILL_MEDIUM_LIST list(\
	/mob/living/simple_animal/hostile/orc = 8,\
	/mob/living/simple_animal/hostile/orc/orc2 = 8,\
	/mob/living/simple_animal/hostile/orc/orc_marauder = 7,\
	/mob/living/simple_animal/hostile/orc/orc_marauder/spear = 7,\
	/mob/living/simple_animal/hostile/orc/spear = 7,\
	/mob/living/simple_animal/hostile/orc/spear2 = 7,\
	/mob/living/simple_animal/hostile/orc/ranged = 6,\
	/mob/living/simple_animal/hostile/deepone/spit = 7,\
	/mob/living/simple_animal/hostile/deepone/wiz = 6,\
	/mob/living/simple_animal/hostile/deepone/elite = 5,\
	/mob/living/simple_animal/hostile/retaliate/gator = 6,\
	/mob/living/simple_animal/hostile/retaliate/bogbug = 6,\
	/mob/living/simple_animal/hostile/retaliate/wolf = 6,\
	/mob/living/simple_animal/hostile/retaliate/spider = 6,\
	/mob/living/simple_animal/hostile/retaliate/spider/mutated = 6,\
	/mob/living/simple_animal/hostile/retaliate/bobcat = 5,\
	/mob/living/simple_animal/hostile/retaliate/snapper = 5,\
	/mob/living/carbon/human/species/goblin = 5,\
	/mob/living/carbon/human/species/goblin/npc = 5,\
	/mob/living/carbon/human/species/goblin/cave = 5,\
	/mob/living/carbon/human/species/goblin/sea = 5,\
	/mob/living/carbon/human/species/orc = 6,\
	/mob/living/carbon/human/species/orc/warrior = 6,\
	/mob/living/carbon/human/species/orc/marauder = 6,\
)
#define QUEST_RAID_LIST list(\
	/mob/living/simple_animal/hostile/orc = 8,\
	/mob/living/simple_animal/hostile/orc/orc_marauder = 6,\
	/mob/living/simple_animal/hostile/deepone/elite = 5,\
	/mob/living/simple_animal/hostile/werewolf = 5,\
	/mob/living/simple_animal/hostile/retaliate/lamia = 5,\
	/mob/living/simple_animal/hostile/retaliate/gator = 4,\
	/mob/living/simple_animal/hostile/retaliate/headless = 4,\
	/mob/living/simple_animal/hostile/retaliate/direbear = 2,\
)
#define QUEST_OUTLAW_KILL_LIST list(\
	/mob/living/simple_animal/hostile/retaliate/troll/cave = 8,\
	/mob/living/simple_animal/hostile/retaliate/infernal/fiend = 7,\
	/mob/living/simple_animal/hostile/retaliate/elemental/collossus = 4,\
	/mob/living/simple_animal/hostile/retaliate/minotaur = 4,\
	/mob/living/simple_animal/hostile/dreamfiend/ancient = 3,\
	/mob/living/simple_animal/hostile/retaliate/voiddragon = 2,\
)
