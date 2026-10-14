"""Packs the per-breast-size clothing layers of one garment into a single DMI, with animation that follows the body breasts.

Usage:
    python tools/breast_sized_clothing/pack_breast_sized.py <source folder> <output.dmi> [--preview <file.gif>]

The source folder is named after the female worn state (for example "fallgown_f")
and holds the stencil output:
    <base>_alpha_hide.dmi         "<base>_<N>_hide"            -> "<base>_<N>_hide"
    <base>_breasts.dmi            "pair_<N>_<LAYER>"           -> "<base>_pair_<N>_<LAYER>"
    <base>_extra.dmi              "<base>_<N>_extra"           -> "<base>_<N>_extra"
    <base>_detail_alpha_hide.dmi  "<base>_<N>_detail_hide"     -> "<base>_detail_<N>_hide"
    <base>_detail_breasts.dmi     "pair_<N>_<LAYER>"           -> "<base>_detail_pair_<N>_<LAYER>"
    <base>_detail_extra.dmi       "<base>_<N>_detail_extra"    -> "<base>_detail_<N>_extra"
Detail files are optional. Hide states are always kept because the game uses them to tell which sizes
the garment supports; empty breast and extra states are dropped.

Every breast and extra state also gets two split copies: "<name>_front" holds only the south frame
(drawn above sleeves, gloves and rings) and "<name>_side" holds the other directions.

Animation. For sizes the body breasts animate (see tools/breast_anim), every state is warped frame by
frame to follow the body breasts: per pixel column, the top and bottom edge of the body breast at rest
and in the frame give the motion. Output, with <prefix> being "<base>" or "<base>_detail":
    <prefix>_...            still + walk cycle as a BYOND movement state
    <prefix>_run_...        still + run cycle as a movement state
    <prefix>_f<K>_...       still, walk frame K (emotes step through these)
    <prefix>_r<K>_...       still, run frame K (interactions)
    <prefix>_s<K>_...       still, squeeze frame K (pressing together, release, bounces; interactions)
Profiles: tools/breast_sized_clothing/profiles/<folder name>.json (kept in the repo, so it is versioned and
snapshotted with the code) picks the warp per layer kind, either one mode
for every direction or per direction ("S", "N", "E", "W", with "default" for the rest):
    {"pair": "stretch", "extra": "stretch", "hide": {"S": "bottom", "default": "stretch"}}
    "stretch"  the top stays put, the rest stretches so the bottom follows the breast's bottom edge in that
               column (default; keeps the hide mask covering the garment above the breasts)
    "bottom"   the column moves as a whole with the breast's bottom edge (cups that hold the breast up)
    "free"     the column moves and stretches with both the top and the bottom edge of the breast
    "rigid"    the whole layer moves as one piece by the breast's average bottom edge motion
    "cover"    like "free", but an edge only ever moves outwards: the top follows the breast up but stays when it
               drops, the bottom follows it down but stays when it rises. The layer always covers both its rest
               place and the breast, with a single outline (no ghost of the rest outline as with "fill")
    "none"     the layer does not move
    "cut_under_clothing": true   (optional) also cut the base wherever the breast/extra layers cover it at rest,
               so moving them never uncovers the garment drawn underneath; the body shows there instead.
               For open garments only: on a closed one that would show skin.
    "cut_under_clothing": "fill" the same cut, but the uncovered spots keep the clothing's rest pixels
               (for closed garments).
    "pin_unchanged": ["N"]       (optional) directions where every pixel still equal to the original garment
               (skirt, back of the bodice) stays put and covers the moving breast: they are in front of it there
               (the back view, where a wide skirt overlaps the breasts). Only pixels drawn for the sizes move.
    "worn": "<dmi path from the repo root>"  file holding the garment's worn base state (= the folder name), for
               the preview and check_profiles.py; default icons/roguetown/clothing/onmob/shirts_gown.dmi.
After warping, the hide mask never retreats from where it is at rest (it covers its rest and its warped
area), and wherever that leaves a hole not covered by the warped breast/extra layers, those layers keep their
rest pixels. So a frame never shows the original garment under the cut, nor skin through it.
--preview writes a GIF of the walk and run cycles over the body for checking the warp, and next to it
"<name>_squeeze.gif" with the squeeze frames.
"""

import argparse
import json
import os
import re
import sys

from PIL import Image, ImageChops

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from dmi import Dmi  # noqa: E402

BODY_ANIM = os.path.join(ROOT, "modular_rmh/icons/mob/sprite_accessory/genitals/breasts_anim.dmi")
BODY_ICON = os.path.join(ROOT, "icons/roguetown/mob/bodies/f/fm.dmi")
# The body breasts are drawn with the human female OFFSET_BREASTS (1px down) relative to clothing.
BODY_OFFSET_Y = 1
WALK_DELAY = 1
RUN_DELAY = 1
DIRS = 4
SOUTH, NORTH, EAST, WEST = range(4)
PROFILES = ("stretch", "bottom", "free", "rigid", "cover", "none")
DIR_NAMES = ("S", "N", "E", "W")
DEFAULT_WORN = "icons/roguetown/clothing/onmob/shirts_gown.dmi"


def blank():
    return Image.new("RGBA", (32, 32), (0, 0, 0, 0))


def shifted(image, dy):
    out = blank()
    out.paste(image, (0, dy))
    return out


def is_empty(frames):
    return all(image.getbbox() is None for frame in frames for image in frame)


def state_frames(state):
    images = [image.convert("RGBA") for image in state.frames]
    return [images[i:i + state.dirs] for i in range(0, len(images), state.dirs)]


# ---------------------------------------------------------------- body motion

def load_body_motion():
    """size -> {"rest": [4], "walk"/"run"/"squeeze": [frames][4]} of the body breast silhouette per direction,
    in clothing pixel space. South/east/west come from ADJ, north from BEHIND."""
    still, moving = {}, {}
    for state in Dmi.from_file(BODY_ANIM).states:
        (moving if state.movement else still)[state.name] = state_frames(state)
    motion = {}
    for name in still:
        match = re.match(r"^pair_(\d+)_f1_ADJ$", name)
        if not match:
            continue
        size = int(match.group(1))

        def pick(prefix, frames_by_name, index=None):
            adj = frames_by_name[f"{prefix}_ADJ"]
            behind = frames_by_name.get(f"{prefix}_BEHIND", adj)
            frames = adj if index is None else [adj[index]]
            result = []
            for i, frame in enumerate(frames):
                back = behind[i if index is None else index][NORTH]
                result.append([shifted(img, BODY_OFFSET_Y) for img in (frame[SOUTH], back, frame[EAST], frame[WEST])])
            return result

        squeeze = []
        index = 1
        while f"pair_{size}_s{index}_ADJ" in still:
            squeeze += pick(f"pair_{size}_s{index}", still)
            index += 1
        motion[size] = {
            "rest": pick(f"pair_{size}", still)[0],
            "walk": pick(f"pair_{size}", moving),
            "run": pick(f"pair_{size}_run", moving),
            "squeeze": squeeze,
        }
    return motion


def column_edges(image):
    """x -> (top, bottom) of opaque pixels, or None."""
    alpha = image.split()[3].load()
    edges = []
    for x in range(32):
        rows = [y for y in range(32) if alpha[x, y]]
        edges.append((rows[0], rows[-1]) if rows else None)
    return edges


def column_maps(rest, frame):
    """x -> (t0, b0, t1, b1) for columns covered by the breast, filled from the nearest column."""
    e0, e1 = column_edges(rest), column_edges(frame)
    both = [x for x in range(32) if e0[x] and e1[x]]
    if not both:
        return [None] * 32
    left = min(x for x in range(32) if e0[x] or e1[x])
    right = max(x for x in range(32) if e0[x] or e1[x])
    maps = [None] * 32
    for x in range(left, right + 1):
        nearest = min(both, key=lambda b: abs(b - x))
        maps[x] = e0[nearest] + e1[nearest]
    return maps


# Modes that do not copy the breast pixel for pixel get smoothed edge motion, see smooth_maps().
SMOOTHED_PROFILES = ("stretch", "bottom", "rigid")


def smooth_maps(maps):
    """A single column moving differently from both neighbours (the cleavage, for one) would leave a lone
    pixel sticking out of the garment's outline: smooth the edge motion with a 3-column median."""
    columns = [x for x in range(32) if maps[x]]
    if not columns:
        return maps
    left, right = columns[0], columns[-1]
    maps = list(maps)
    top = [m[2] - m[0] for m in maps[left:right + 1]]
    bottom = [m[3] - m[1] for m in maps[left:right + 1]]
    last = len(top) - 1
    for i, x in enumerate(range(left, right + 1)):
        if i == 0 or i == last:
            # An edge column has one neighbour: a two-value "median" would just pick the larger motion.
            dt, db = top[i], bottom[i]
        else:
            dt = sorted(top[i - 1:i + 2])[1]
            db = sorted(bottom[i - 1:i + 2])[1]
        t0, b0 = maps[x][0], maps[x][1]
        maps[x] = (t0, b0, t0 + dt, b0 + db)
    return maps


def warp(image, maps, profile):
    if profile == "none" or image.getbbox() is None:
        return image
    if profile == "rigid":
        deltas = [m[3] - m[1] for m in maps if m]
        dy = round(sum(deltas) / len(deltas)) if deltas else 0
        return shifted(image, dy)
    src = image.load()
    out = blank()
    dst = out.load()
    for x in range(32):
        m = maps[x]
        for y in range(32):
            if m is None:
                sy = y
            else:
                t0, b0, t1, b1 = m
                if profile == "stretch":
                    # Top edge pinned: only the bottom edge moves.
                    t1 = t0
                elif profile == "cover":
                    t1, b1 = min(t0, t1), max(b0, b1)
                if profile == "bottom":
                    sy = y - (b1 - b0)
                elif y < t1:
                    sy = y - (t1 - t0)
                elif y > b1:
                    sy = y - (b1 - b0)
                elif b1 == t1:
                    sy = t0
                else:
                    sy = t0 + round((y - t1) * (b0 - t0) / (b1 - t1))
            if 0 <= sy < 32:
                dst[x, y] = src[x, sy]
    return out


# ---------------------------------------------------------------- packing

def load_layers(source):
    """List of (prefix, rest, kind, size, frames) for every state of the stencil output."""
    base = os.path.basename(os.path.normpath(source))
    layers = []
    for tag in ("", "_detail"):
        prefix = f"{base}{tag}"
        sources = (
            ("hide", f"{prefix}_alpha_hide.dmi", re.compile(rf"^{re.escape(base)}_(\d+){tag}_hide$"), lambda m: f"_{m.group(1)}_hide"),
            ("pair", f"{prefix}_breasts.dmi", re.compile(r"^pair_(\d+)_([A-Z]+)$"), lambda m: f"_pair_{m.group(1)}_{m.group(2)}"),
            ("extra", f"{prefix}_extra.dmi", re.compile(rf"^{re.escape(base)}_(\d+){tag}_extra$"), lambda m: f"_{m.group(1)}_extra"),
        )
        for kind, filename, pattern, rest_name in sources:
            path = os.path.join(source, filename)
            if not os.path.exists(path):
                if not tag:
                    raise SystemExit(f"missing required file: {path}")
                continue
            for state in Dmi.from_file(path).states:
                match = pattern.match(state.name)
                if not match:
                    raise SystemExit(f"unexpected state {state.name!r} in {path}")
                frames = state_frames(state)
                if kind != "hide" and is_empty(frames):
                    continue
                layers.append((prefix, rest_name(match), kind, int(match.group(1)), frames))
    return base, layers


PROFILE_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "profiles")


def profile_path(source):
    return os.path.join(PROFILE_DIR, os.path.basename(os.path.normpath(source)) + ".json")


def load_profile(source):
    path = profile_path(source)
    if not os.path.exists(path):
        print(f"warning: no profile {path}, using defaults")
    profile = {"pair": "stretch", "extra": "stretch", "hide": "stretch"}
    if os.path.exists(path):
        profile.update(json.load(open(path)))
    cut_under = profile.pop("cut_under_clothing", False)
    if cut_under not in (True, False, "fill"):
        raise SystemExit(f"{path}: cut_under_clothing = {cut_under!r}, expected true, false or \"fill\"")
    resolved = {"cut_under_clothing": cut_under, "worn": profile.pop("worn", DEFAULT_WORN),
                "pin_unchanged": resolve_pins(profile.pop("pin_unchanged", []), path)}
    for kind, value in profile.items():
        modes = value if isinstance(value, dict) else {"default": value}
        per_dir = [modes.get(name, modes.get("default", "stretch")) for name in DIR_NAMES]
        for mode in per_dir:
            if mode not in PROFILES:
                raise SystemExit(f"{path}: {kind} = {value!r}, expected modes from {PROFILES}")
        resolved[kind] = per_dir
    return resolved


def resolve_pins(names, where):
    """["N", ...] -> direction indexes."""
    for name in names:
        if name not in DIR_NAMES:
            raise SystemExit(f"{where}: pin_unchanged {names!r}, expected direction names from {DIR_NAMES}")
    return [DIR_NAMES.index(name) for name in names]


def worn_garments(base, profile):
    """prefix -> the worn base frames [4] of that layer set ("<base>" and "<base>_detail"), for pin_unchanged."""
    if not profile.get("pin_unchanged"):
        return {}
    states = {s.name: state_frames(s) for s in Dmi.from_file(os.path.join(ROOT, profile["worn"])).states if not s.movement}
    return {prefix: states[prefix][0] for prefix in (base, base + "_detail") if prefix in states}


def pin_unchanged(items, warped, garment, dirs):
    """Puts back the rest pixels wherever the rest picture still equals the original garment, in directions dirs."""
    for d in dirs:
        rest = garment[d].copy()
        for name, kind, frame in items:
            if kind == "hide":
                rest.putalpha(Image.composite(Image.new("L", (32, 32), 0), rest.split()[3], frame[d].split()[3]))
        for name, kind, frame in items:
            if kind != "hide":
                rest.alpha_composite(frame[d])
        g, r = garment[d].load(), rest.load()
        pinned = [(x, y) for x in range(32) for y in range(32) if g[x, y][3] and r[x, y] == g[x, y]]
        if not pinned:
            continue
        for name, kind, frame in items:
            image = warped[name][d].copy()
            src, dst = frame[d].load(), image.load()
            for p in pinned:
                dst[p] = src[p]
            warped[name][d] = image


def split(frame, keep_south):
    return [image if (d == SOUTH) == keep_south else blank() for d, image in enumerate(frame)]


def add_state(dmi, name, frames, *, movement=False, delay=1):
    state = dmi.state(name, dirs=DIRS, movement=movement)
    for frame in frames:
        state.frames.extend(frame)
        state.delays.append(delay)


def add_variants(dmi, name, kind, still, moving=None, delay=1):
    """Adds the state (and for breast/extra layers its _front/_side splits) with an optional movement version."""
    parts = [("", None)] if kind == "hide" else [("", None), ("_front", True), ("_side", False)]
    for suffix, keep_south in parts:
        cut = (lambda f: f) if keep_south is None else (lambda f, k=keep_south: split(f, k))
        add_state(dmi, name + suffix, [cut(f) for f in still])
        if moving:
            add_state(dmi, name + suffix, [cut(f) for f in moving], movement=True, delay=delay)


def outline(images):
    """x -> (top, bottom) of the union of images, or None."""
    union = blank()
    for image in images:
        union.alpha_composite(image)
    return column_edges(union)


def keep_outline(maps, edges):
    """For "bottom" mode, where each column shifts by its bottom edge motion: nudge columns so the shifted
    outline (edges, the garment's own top and bottom per column) gets no new lone pixel sticking up or down
    past both neighbours that was not there at rest."""
    maps = list(maps)
    for _ in range(3):
        changed = False
        for x in range(1, 31):
            if not (maps[x] and maps[x - 1] and maps[x + 1] and edges[x] and edges[x - 1] and edges[x + 1]):
                continue
            delta = [maps[k][3] - maps[k][1] for k in (x - 1, x, x + 1)]
            tops = [edges[k][0] + delta[i] for i, k in enumerate((x - 1, x, x + 1))]
            bottoms = [edges[k][1] + delta[i] for i, k in enumerate((x - 1, x, x + 1))]
            rest_tops = [edges[k][0] for k in (x - 1, x, x + 1)]
            rest_bottoms = [edges[k][1] for k in (x - 1, x, x + 1)]
            fix = 0
            if tops[1] < tops[0] and tops[1] < tops[2] and not (rest_tops[1] < rest_tops[0] and rest_tops[1] < rest_tops[2]):
                fix = min(tops[0], tops[2]) - tops[1]
            elif bottoms[1] > bottoms[0] and bottoms[1] > bottoms[2] and not (rest_bottoms[1] > rest_bottoms[0] and rest_bottoms[1] > rest_bottoms[2]):
                fix = max(bottoms[0], bottoms[2]) - bottoms[1]
                # The top outline matters more: skip a bottom fix that would make the top stick up.
                if tops[1] + fix < tops[0] and tops[1] + fix < tops[2] and not (rest_tops[1] < rest_tops[0] and rest_tops[1] < rest_tops[2]):
                    fix = 0
            if fix:
                t0, b0, t1, b1 = maps[x]
                maps[x] = (t0, b0, t1, b1 + fix)
                changed = True
        if not changed:
            break
    return maps


def warp_frame(frame, rest, body_frame, modes, edges=None):
    """modes: warp mode per direction; edges: per direction outline of the garment layers, for keep_outline()."""
    warped = []
    for d, image in enumerate(frame):
        maps = column_maps(rest[d], body_frame[d])
        if modes[d] in SMOOTHED_PROFILES:
            maps = smooth_maps(maps)
        if modes[d] == "bottom" and edges:
            maps = keep_outline(maps, edges[d])
        warped.append(warp(image, maps, modes[d]))
    return warped


def warp_group(items, rest, body_frame, profile, garment=None):
    """Warps the layers of one size and prefix for one body frame and holds the cut, see the module docstring.
    items: list of (rest_name, kind, still frame [4 dirs]); garment: the worn base frames of this prefix, needed for
    pin_unchanged; returns rest_name -> warped frame."""
    garment_layers = [frame for name, kind, frame in items if kind != "hide"]
    edges = [outline([frame[d] for frame in garment_layers]) for d in range(DIRS)] if garment_layers else None
    warped = {name: warp_frame(frame, rest, body_frame, profile[kind], edges) for name, kind, frame in items}
    if garment and profile.get("pin_unchanged"):
        pin_unchanged(items, warped, garment, profile["pin_unchanged"])
    hides = [(name, frame) for name, kind, frame in items if kind == "hide"]
    if not hides:
        return warped
    hide_name, hide_rest = hides[0]
    clothing = [(name, frame) for name, kind, frame in items if kind != "hide"]
    for d in range(DIRS):
        rest_alpha = hide_rest[d].split()[3]
        hide = warped[hide_name][d].copy()
        hide.paste(hide_rest[d], (0, 0), rest_alpha)
        if profile.get("cut_under_clothing"):
            # Cut the base under the clothing's rest position too; these pixels are not filled below.
            for name, frame in clothing:
                hide.paste(Image.new("RGBA", (32, 32), (255, 255, 255, 255)), (0, 0), frame[d].split()[3].point(lambda a: 255 if a else 0))
        warped[hide_name][d] = hide
        if not clothing:
            continue
        covered = Image.new("L", (32, 32), 0)
        for name, _ in clothing:
            covered = ImageChops.lighter(covered, warped[name][d].split()[3])
        held = rest_alpha.point(lambda a: 255 if a else 0)
        if profile.get("cut_under_clothing") == "fill":
            for name, frame in clothing:
                held = ImageChops.lighter(held, frame[d].split()[3].point(lambda a: 255 if a else 0))
        hole = ImageChops.multiply(held, ImageChops.invert(covered.point(lambda a: 255 if a else 0)))
        if hole.getbbox() is None:
            continue
        for name, frame in clothing:
            fill = Image.composite(frame[d], blank(), hole)
            layer = fill.copy()
            layer.alpha_composite(warped[name][d])
            warped[name][d] = layer
    return warped


def pack(source, output, preview=None, profile=None):
    base, layers = load_layers(source)
    profile = profile or load_profile(source)
    motion = load_body_motion()
    garments = worn_garments(base, profile)
    result = Dmi(32, 32)
    groups = {}
    for prefix, rest_name, kind, size, frames in layers:
        if size not in motion:
            add_variants(result, prefix + rest_name, kind, frames)
            continue
        groups.setdefault((prefix, size), []).append((rest_name, kind, frames))
    for (prefix, size), group in groups.items():
        body = motion[size]
        items = [(name, kind, frames[0]) for name, kind, frames in group]
        garment = garments.get(prefix)
        walk = [warp_group(items, body["rest"], f, profile, garment) for f in body["walk"]]
        run = [warp_group(items, body["rest"], f, profile, garment) for f in body["run"]]
        squeeze = [warp_group(items, body["rest"], f, profile, garment) for f in body["squeeze"]]
        for rest_name, kind, frames in group:
            add_variants(result, prefix + rest_name, kind, frames, [w[rest_name] for w in walk], WALK_DELAY)
            add_variants(result, f"{prefix}_run{rest_name}", kind, frames, [r[rest_name] for r in run], RUN_DELAY)
            for index, frame in enumerate(walk, 1):
                add_variants(result, f"{prefix}_f{index}{rest_name}", kind, [frame[rest_name]])
            for index, frame in enumerate(run, 1):
                add_variants(result, f"{prefix}_r{index}{rest_name}", kind, [frame[rest_name]])
            for index, frame in enumerate(squeeze, 1):
                add_variants(result, f"{prefix}_s{index}{rest_name}", kind, [frame[rest_name]])

    os.makedirs(os.path.dirname(os.path.abspath(output)), exist_ok=True)
    result.to_file(output)
    print(f"{output}: {len(result.states)} states, profile {profile}")
    if preview:
        write_preview(base, layers, motion, profile, preview)
        write_squeeze_preview(base, layers, motion, profile, os.path.splitext(preview)[0] + "_squeeze.gif")


# ---------------------------------------------------------------- preview

def compose_cell(garment, by_size, size, body, body_frame, behind, adj, d, rest, profile, tint):
    """One preview cell: body breasts (behind, body, adj) under the garment base cut by the warped hide mask."""
    cell = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    if behind is not None:
        cell.alpha_composite(tint(shifted(behind, BODY_OFFSET_Y)))
    cell.alpha_composite(tint(body[d]))
    cell.alpha_composite(tint(shifted(adj, BODY_OFFSET_Y)))
    cut = garment[d].copy()
    over = []
    group = warp_group(by_size[size], rest, body_frame, profile, garment)
    for rest_name, kind, frame in by_size[size]:
        warped = group[rest_name][d]
        if kind == "hide":
            hide = warped.split()[3].point(lambda a: 255 if a else 0)
            cut.putalpha(Image.composite(Image.new("L", (32, 32), 0), cut.split()[3], hide))
        else:
            over.append(warped)
    cell.alpha_composite(cut)
    for image in over:
        cell.alpha_composite(image)
    return cell


def write_squeeze_preview(base, layers, motion, profile, path):
    """Squeeze frames (rest, s1..sN, rest) of each animated size over the body, columns S, E, N."""
    worn = os.path.join(ROOT, profile.get("worn", DEFAULT_WORN))
    worn_states = {s.name: state_frames(s) for s in Dmi.from_file(worn).states if not s.movement}
    garment = worn_states.get(base, [[blank()] * 4])[0]
    body = {s.name: state_frames(s) for s in Dmi.from_file(BODY_ICON).states}["fm"][0]
    still = {s.name: state_frames(s) for s in Dmi.from_file(BODY_ANIM).states if not s.movement}
    by_size = {}
    for prefix, rest_name, kind, size, frames in layers:
        if prefix == base:
            by_size.setdefault(size, []).append((rest_name, kind, frames[0]))
    sizes = sorted(s for s in motion if s in by_size and motion[s]["squeeze"])
    if not sizes:
        return
    skin = (232, 183, 150)

    def tint(image):
        out = Image.new("RGBA", image.size)
        out.putdata([(p[0] * skin[0] // 255, p[1] * skin[1] // 255, p[2] * skin[2] // 255, p[3]) for p in image.getdata()])
        return out

    count = max(len(motion[s]["squeeze"]) for s in sizes)
    frames_out, durations = [], []
    for step in [0] + list(range(1, count + 1)) + [0]:
        sheet = Image.new("RGBA", (32 * 3, 32 * len(sizes)), (70, 70, 90, 255))
        for row, size in enumerate(sizes):
            rest = motion[size]["rest"]
            body_frame = rest if step == 0 else motion[size]["squeeze"][step - 1]
            state = f"pair_{size}" if step == 0 else f"pair_{size}_s{step}"
            for col, d in enumerate((SOUTH, EAST, NORTH)):
                behind = still.get(f"{state}_BEHIND")
                cell = compose_cell(garment, by_size, size, body, body_frame, behind[0][d] if behind else None,
                                    still[f"{state}_ADJ"][0][d], d, rest, profile, tint)
                sheet.alpha_composite(cell, (col * 32, row * 32))
        frames_out.append(sheet.resize((sheet.width * 4, sheet.height * 4), Image.NEAREST).convert("RGB"))
        durations.append(400 if step == 0 else 120)
    frames_out[0].save(path, save_all=True, append_images=frames_out[1:], duration=durations, loop=0)
    print(f"preview: {path}")


def write_preview(base, layers, motion, profile, path):
    """Walk and run cycles of each animated size over the body (S, E, N), base cut by the warped hide mask."""
    worn = os.path.join(ROOT, profile.get("worn", DEFAULT_WORN))
    worn_states = {s.name: state_frames(s) for s in Dmi.from_file(worn).states if not s.movement}
    garment = worn_states.get(base, [[blank()] * 4])[0]
    body_states = {s.name: state_frames(s) for s in Dmi.from_file(BODY_ICON).states}
    body = body_states["fm"][0]
    anim_still, anim_moving = {}, {}
    for s in Dmi.from_file(BODY_ANIM).states:
        (anim_moving if s.movement else anim_still)[s.name] = state_frames(s)
    by_size = {}
    for prefix, rest_name, kind, size, frames in layers:
        if prefix == base:
            by_size.setdefault(size, []).append((rest_name, kind, frames[0]))
    skin = (232, 183, 150)

    def tint(image):
        out = Image.new("RGBA", image.size)
        out.putdata([(p[0] * skin[0] // 255, p[1] * skin[1] // 255, p[2] * skin[2] // 255, p[3]) for p in image.getdata()])
        return out

    columns = [("walk", d) for d in (SOUTH, EAST, NORTH)] + [("run", d) for d in (SOUTH, EAST, NORTH)]
    sizes = sorted(s for s in motion if s in by_size)
    scale, ticks = 3, 8
    frames_out = []
    for tick in range(ticks):
        sheet = Image.new("RGBA", (32 * len(columns), 32 * len(sizes)), (70, 70, 90, 255))
        for row, size in enumerate(sizes):
            for col, (cycle, d) in enumerate(columns):
                body_frame = motion[size][cycle][tick % len(motion[size][cycle])]
                rest = motion[size]["rest"]
                cell = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
                prefix_state = f"pair_{size}" if cycle == "walk" else f"pair_{size}_run"
                behind = anim_moving.get(f"{prefix_state}_BEHIND")
                adj = anim_moving[f"{prefix_state}_ADJ"]
                if behind:
                    cell.alpha_composite(tint(shifted(behind[tick % len(behind)][d], BODY_OFFSET_Y)))
                cell.alpha_composite(tint(body[d]))
                cell.alpha_composite(tint(shifted(adj[tick % len(adj)][d], BODY_OFFSET_Y)))
                cut = garment[d].copy()
                over = []
                group = warp_group(by_size[size], rest, body_frame, profile, garment)
                for rest_name, kind, frame in by_size[size]:
                    warped = group[rest_name][d]
                    if kind == "hide":
                        hide = warped.split()[3].point(lambda a: 255 if a else 0)
                        cut.putalpha(Image.composite(Image.new("L", (32, 32), 0), cut.split()[3], hide))
                    else:
                        over.append(warped)
                cell.alpha_composite(cut)
                for image in over:
                    cell.alpha_composite(image)
                sheet.alpha_composite(cell, (col * 32, row * 32))
        frames_out.append(sheet.resize((sheet.width * scale, sheet.height * scale), Image.NEAREST).convert("RGB"))
    frames_out[0].save(path, save_all=True, append_images=frames_out[1:], duration=100, loop=0)
    print(f"preview: {path}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("source")
    parser.add_argument("output")
    parser.add_argument("--preview")
    args = parser.parse_args()
    pack(args.source, args.output, args.preview)
