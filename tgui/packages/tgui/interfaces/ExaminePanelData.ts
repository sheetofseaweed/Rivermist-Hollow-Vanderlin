export type WeaponIntent = {
  name: string;
  // Which grip this intent belongs to - "normal" (default one-handed
  // moveset), "gripped" (two-handed/wielded moveset, only distinct entries
  // not already in "normal"), or "alt" (the reversed alt-grip moveset
  // toggled by right-clicking the weapon, same "only what's new" rule).
  grip: "normal" | "gripped" | "alt";
};

export type ExaminePanelData = {
  // Identity
  character_name: string;
  headshot: string;
  nsfw_headshot: string;
  obscured: boolean;
  // Descriptions
  flavor_text: string;
  ooc_notes: string;
  // Descriptions, but requiring manual input to see
  flavor_text_nsfw: string;
  ooc_notes_nsfw: string;
  img_gallery: string[];
  nsfw_img_gallery: string[];
  is_playing: boolean;
  has_song: boolean;
  is_naked: boolean;
  // Character preview
  has_headshot: boolean;
  has_nsfw_headshot: boolean;
  preview_image: string;
  worn_items: WornItemsData;
  //RMH EDITED START - preview gating state, so the UI can tell "still rendering"
  // apart from "out of examine range" and "this holder has no in-game body".
  preview_available: boolean;
  preview_in_range: boolean;
  //RMH EDITED END
};

export type ExamineItem = {
  name: string;
  desc: string;
  icon: string;
  quality: number;
  weight?: number | null;
  // Raw price in amna, present only if the viewer can see prices
  // (gated server-side the same way get_displayed_price() gates it).
  price?: number | null;
  // Pre-formatted label ("Light Armour"/"Medium Armour"/"Heavy Armour"),
  // computed server-side from armor_class (AC_LIGHT/MEDIUM/HEAVY) so this
  // type never has to duplicate those numeric defines itself. Deliberately
  // no per-damage-type breakdown here - that's redundant with the chat-side
  // hover tooltip (get_examine_gear() / the {?} link) and was dropped from
  // this panel on purpose.
  armorClassLabel?: string | null;
  // Only present for items with force > 0.
  weaponDamage?: { force: number; types: string[] } | null;
  // Weapon category by typepath - "Sword"/"Axe"/"Mace"/"Knife"/"Polearm"/
  // "Flail"/"Whip"/"Katar"/"Knuckles"/"Firearm", or null if unclassified.
  weaponCategory?: string | null;
  // Actual attack intents (chop/stab/pick/bash/pommel strike/...) across
  // every grip state, not just the skill/category - see
  // get_weapon_intent_names(). Each entry says which grip it belongs to so
  // the UI can color special-grip-only intents differently.
  intents?: WeaponIntent[] | null;
  // The weapon's unique "Strong" RMB-stance attack (weapon_special), if any.
  specialAttack?: { name: string; desc: string } | null;
  // Best-effort BG3-style property badges (Light/Extra Reach/Two-Handed/
  // Versatile) - see get_weapon_tag_badges() for the mapping.
  tags?: string[] | null;
};

export type WornSlot = {
  label: string;
  status: "item" | "hidden" | "empty";
  item?: ExamineItem;
};

export type HeldItem = ExamineItem & { wielded: boolean };

export type WornItemsData = {
  slots: Record<string, WornSlot>;
  hands: HeldItem[];
};
