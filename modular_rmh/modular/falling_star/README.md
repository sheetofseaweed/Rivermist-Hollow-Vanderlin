# Falling star event setup

This pack is admin spawned. It does not add a roundstart event, loot source, or new mob type.

1. Assemble each hunter as a human with the existing Demon species. Add the **Falling Star Hunter** trait through Modify Traits.
2. Give each hunter **Star Hunter's Grasp** and **Star Hunter's Temptation** through Give Spell. The spells only work while the hunter trait is present.
3. Spawn one `/obj/structure/falling_star_crystal` for each hunter. Set its `bound_hunter_name` to that hunter's name through View Variables before players can break it.
4. Distribute 50 `/obj/item/falling_star_shard` items per crystal. Each is consumed when used on a crystal. `/obj/item/falling_star_shard/medium` is a separate, single-use counter to the marked hunters.

The crystal bond is narrative: breaking the crystal announces the named hunter globally. It does not automatically change the hunter's damage protection. The crystal's arousal effects and the hunter's Temptation spell respect the **Lust Magic Targetable** preference.
