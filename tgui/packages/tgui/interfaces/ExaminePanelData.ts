export type WeaponIntent = {
  name: string;
  /** Which grip supplies this attack; drives its colour in the tooltip. */
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
  /** Only present when the viewer is allowed to see prices. */
  price?: number | null;
  /** "Light Armour" / "Medium Armour" / "Heavy Armour", formatted server-side. */
  armorClassLabel?: string | null;
  /** Only present for items that deal force damage. */
  weaponDamage?: { force: number } | null;
  /** Weapon type name, or null if unclassified. */
  weaponCategory?: string | null;
  /** Attack intents across every grip. */
  intents?: WeaponIntent[] | null;
  /** The weapon's "Strong" RMB-stance attack, if any. */
  specialAttack?: { name: string; desc: string } | null;
  /** Property badges: Light / Extra Reach / Two-Handed / Versatile. */
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
