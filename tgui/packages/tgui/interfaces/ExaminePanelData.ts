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
};
