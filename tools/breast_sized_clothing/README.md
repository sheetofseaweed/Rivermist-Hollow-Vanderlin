# Breast-size clothing and breast animation

How to add garments and animation art. Code: `modular_rmh/code/modules/clothing/breast_sized_clothing.dm`,
`modular_rmh/code/modules/mob/body_breasts_front.dm`, `body_groin_front.dm`, `breast_animation.dm`.
Layer values: `code/__DEFINES/misc.dm` (search `FRONT_LAYER`).

## Adding a garment with breast-size sprites

0. Drawing canvas: `python tools/breast_sized_clothing/mannequin/make_garment_canvas.py to-aseprite <drawing.dmi> <state>_f[...].aseprite [--detail <detail.dmi>]`
   makes a 128x32 Aseprite file (S, N, E, W; one frame per size 0-8) with the locked mannequin under a "clothing"
   (and "detail") layer; `to-dmi <file.aseprite> <out.dmi> [--detail-out <detail.dmi>]` exports it back (state taken
   from the file name, pixel alpha kept, layer opacity ignored). Round trip verified pixel-exact on 31 garments.
   If only one side view was redrawn, `to-dmi` mirrors it onto the other (default `--mirror auto`, compares with the
   original drawing next to the file; `--mirror east|west|none` to force). The detail layer is not mirrored: it is
   redone to fit the finished drawing.
0. Back view from the front: `python tools/breast_sized_clothing/back_from_front.py <drawing.dmi|.aseprite> <out.dmi> [--preview out.png]`
   copies the breast parts of the garment that stick out past the body outline (front view, mirrored) to the back view,
   clearing the old drawing's breast pixels there first and never covering the garment's own back. See its docstring.
0. From full per-size drawings (`<state>_f_<N>`, sizes 0-8, 4 dirs) make the stencil with
   `python tools/breast_sized_clothing/split_stencil.py "<drawing.dmi>" <worn.dmi> "<out folder>"`
   (rule below; it refuses unless base - hide + breasts + extra rebuilds the drawing exactly; `--compare <folder>`
   diffs against an existing stencil; it matched the hand-made winter gown and chemise stencils exactly).
1. Put the stencil output in a folder named after the female worn state, e.g. `breasts files/fallgown_f/`:
   `<state>_f_alpha_hide.dmi`, `<state>_f_breasts.dmi`, `<state>_f_extra.dmi`, and optionally the same three
   with `_detail` for the paint layer. States: `<state>_f_<N>_hide`, `pair_<N>_<LAYER>`, `<state>_f_<N>_extra`
   (detail: `<state>_f_<N>_detail_hide`, `<state>_f_<N>_detail_extra`), sizes 0-8.
2. Pack it (add `--preview <file>.gif` to check how it follows the breast animation):
   `python tools/breast_sized_clothing/pack_breast_sized.py "<folder>" modular_rmh/icons/clothing/onmob/breast_sized/<state>.dmi`
   The profile `tools/breast_sized_clothing/profiles/<state>_f.json` (in the repo, versioned with the code; the
   packer warns and uses defaults if it is missing) picks how each layer follows the animation:
   `{"pair": "stretch", "extra": "stretch", "hide": "stretch"}`, one mode or per direction
   (`{"S": "bottom", "default": "stretch"}`). Modes: `stretch` (top pinned, bottom follows the breast; default),
   `free` (every pixel follows the breast, top and bottom; best for closed garments, no skin pokes out),
   `bottom` (each column shifts with the breast's bottom edge, no stretching), `rigid` (whole layer shifts as one),
   `cover` (like `free`, but edges only move outwards, so the layer covers both its rest place and the breast with a
   single outline), `none` (static). Extra keys: `"cut_under_clothing": true` (open garments: cut the base under the
   clothing's rest position, the body shows there) or `"fill"` (keep the clothing's rest pixels there; with `free`
   this can draw a doubled outline, `cover` avoids it), `"worn": "<dmi>"` (file with the garment's base state, for
   previews and checks; default `shirts_gown.dmi`). Current choices: summer gown `bottom` on S / `stretch` +
   `cut_under_clothing: true`; fall gown `free` + `fill`; winter and spring gowns `free`; silk dress (chemise,
   `shirts.dmi`) `cover` + `fill`; royal gown (`shirts_royalty.dmi`) `free` (artist's pick) + `"pin_unchanged": ["N"]` (in the back view every pixel still
   equal to the original garment stays put and covers the breast: the wide skirt is in front of it there, it used to
   jump with the walk cycle), closed, its detail stencil
   made from a colour map (base colour -> detail colour, see `breasts files/royaldress_f/_build_royaldress.py`); bras (bra, bikini top, exotic silk bra) like the summer gown, shibari `free`, all
   with `cut_under_clothing: true` (draft art). Check closed garments for skin showing through in the preview.
   In `stretch`, `bottom` and `rigid` the per-column motion is smoothed (3-column median), and `bottom` also
   keeps the garment outline from growing new lone pixels above (top edge first) or below its neighbours;
   `free` follows the breast exactly, unsmoothed, so closed garments do not show skin.
   The packer also writes `<state>_f[_detail][anim]_<N>_cover_front` for every size and frame: the base left after the
   hide cut where the body breast of that frame is (paint only where the base is). The game draws these first in the
   garment's lifted front layer, so the lifted body breasts are never cut by the garment at runtime (that cut froze
   the server for up to ~130 ms per new frame). Body breast icons carry pre-split `*_ADJ_front` / `*_ADJ_side`
   states (`tools/breast_anim/south_split.py`). Repack every garment after changing this.
   The hide mask never retreats from its rest position in any frame, and holes it would leave are filled
   with the clothing's rest pixels, so no frame shows the original garment under the cut.
   Repack every garment after rebuilding the body animation: the warp is computed from `breasts_anim.dmi`.
3. Give the item the icon: `breast_sized_icon = 'modular_rmh/icons/clothing/onmob/breast_sized/<state>.dmi'`
   (see the gown subtypes at the end of `breast_sized_clothing.dm`). The item needs `boobed = TRUE`.
4. Build: `"C:\Users\Kas\.claude\tools\byond\516.1687\bin\dm.exe" vanderlin.dme`. If it says
   `cannot find file` for an icon you just wrote, a running DreamDaemon holds `vanderlin.rsc`: stop it,
   or rename `vanderlin.rsc` so it is rebuilt.

Layering, decided with the artist: base minus hide mask, then breasts (BEHIND, ADJ), extra, then the detail
copy recoloured with `detail_color`. The south view of breasts/extra is lifted above gloves, rings and belts.
Several garments stack over the chest, bottom to top: bra slot, shirt slot, armor slot, tabard-layer cloak (aprons)
(`get_chest_stack()`). Each cuts only its own base, so a lower garment shows through an upper one's cut. Lifted
south views go to BREAST_BRA/SHIRT/ARMOR/CLOAK_FRONT_LAYER (17.58/17.55/17.5/17.45, body breasts 17.6 under them), each cut
by the bases of the garments above it. A plain garment covering the chest (no breast sizes) keeps everything
under it unlifted. A breast-sized garment's HIDEBOOB does not switch off the sizes of the one under it.
Under a closed breast-sized garment (`breast_sized_closed = TRUE`: winter and spring gowns) the garments below draw
no breast or extra layers at all, so their animation cannot poke out from under it. Open garments (summer, fall,
chemise) leave the ones below fully visible in their cut; clipping those to the rest outline was tried and left holes.
A bra uses its sizes only when no plain (non breast-sized) garment hiding the breasts is worn over it
(`bra_draws_breast_sized_layers()`); otherwise it keeps its old sprite (bikini: old `_B<size>` states). Any worn bra
without sizes keeps the body breasts unlifted, as before.
Set `breast_sized_closed` on every new garment that covers the whole chest. The clothing art is drawn for the body breast
sprite currently in `breasts.dmi` (the artist's "1pix down" file shifted up 1px).

## Body breast animation

`python tools/breast_anim/build_breast_anims.py` rebuilds `breasts_anim.dmi` from `tools/breast_anim/src/`:
- `walk.dmi`: still + movement states per size, drawn 1px low (the script shifts it up).
- `run.aseprite`: groups `5`..`8`, layers `<N> front` / `<N> side` (east; west is mirrored) / `<N> back`,
  8 motion frames, no rest pose. Exported with the Aseprite CLI (`ASEPRITE` env var overrides the path).
- `squeeze.aseprite`: same layout, 6 frames (press together, release, two bounces); built as still states
  `pair_<N>_s<K>`, played by the `squeeze` interaction kind at 0.1 s per frame. The artist's copy is
  `breasts files/anim/squeeze.aseprite`; copy it here before building. Extra layers (`body ref`) are ignored.
  Drafts: `tools/breast_anim/draft_squeeze.py`; any source can be previewed with `tools/breast_anim/preview_anim.py`.
- Walk/run frame timings are constants at the top of the script. Emotes are lists of walk frames in
  `GLOB.breast_emote_anim_frames` (`breast_animation.dm`), stepped on a timer (`BREAST_EMOTE_FRAME_TIME`):
  BYOND does not restart a play-once animated state on an overlay, so one-shot states do not work.
  Adding an emote is one line there.

ERP interactions: `modular_rmh/code/modules/mob/sex_breast_anim.dm`. Each action type sets `breast_anim_on`
(user or target, the receiving side) and `breast_anim_kind` (`thrust` and `boobjob`: run cycle when force and
speed are both HIGH or more, half walk cycle when both are LOW, full walk cycle otherwise; `touch`: half walk
cycle; `slap`: run frames 1-4 and 4-8 on alternate slaps; `squeeze`: the squeeze frames). It plays once per action cycle, called from `run_runtime()` after `on_perform()`.
Climax plays 1.5 walk cycles. Adding an action is two vars on its type.

Only sizes in `ANIM_SIZES` animate; others are copied as still states. Players toggle their own animation
with the `Toggle Breast Animation` verb (Preferences tab).

## Checking a change

1. Pack with `--preview` and look at the GIF: rows are sizes 5-8, columns walk S/E/N then run S/E/N; the
   `<name>_squeeze.gif` next to it shows the squeeze frames.
2. Count defects instead of eyeballing: `python tools/breast_sized_clothing/check_profiles.py "<folder>"`
   prints, per size, `revealed` (original garment showing because the cut moved; must be 0) and
   `extra skin` (body breast left uncovered beyond what shows at rest; ~0 for closed garments), and the same
   two counts over the squeeze frames.
3. To compare profiles, add `--profile 'label={json}'` per candidate and `--compare out.gif` for a side-by-side
   preview, and let the artist pick. Then write the chosen profile to `profiles/<state>_f.json` and repack.
4. Review with the artist: `python tools/breast_sized_clothing/inspect_preview.py grid "<folder>" out.png`
   makes a gridded sheet (sizes 5-8 x rest / walk 1-8 / run 1-8); they mark bad pixels in blue and send it back;
   `inspect_preview.py marks marked.png --folder "<folder>"` turns the marks into size / frame / pixel / layer.
   `inspect_preview.py stack "<lower>" "<upper>" out.gif [--closed]` previews two garments worn together.
5. Build with the portable compiler. In-game check is still needed: previews are Python composites.

BYOND notes, verified with test worlds: `icon(file, state)` returns both the still and the movement version,
but `Insert()` keeps only the still one, so movement versions must be inserted with `moving = 1`
(done in `get_overlay()`); a one-frame blank inserted into a direction blanks it in every frame; a
one-frame mask multiplied over an animated icon applies to every frame.
