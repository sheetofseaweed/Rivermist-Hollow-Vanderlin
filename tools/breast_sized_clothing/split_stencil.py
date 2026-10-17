"""Splits full per-size drawings of a garment into the stencil the packer reads (pack_breast_sized.py).

Usage:
    python tools/breast_sized_clothing/split_stencil.py <drawing.dmi> <worn.dmi> <out folder> [--state <base>]
        [--compare <stencil folder>]

<drawing.dmi> holds "<base>_<N>" (N = 0-8, 4 dirs S N E W), <worn.dmi> the garment's worn base state "<base>"
(for example icons/roguetown/clothing/onmob/shirts_gown.dmi). <base> defaults to the drawing file name.
Writes into <out folder>: <base>_alpha_hide.dmi, <base>_alpha_keep.dmi, <base>_breasts.dmi, <base>_extra.dmi.

Rule (the same as the hand-made stencils, see README):
    breasts  drawing pixels inside the body breast silhouette of that size (pair_<N>_ADJ for S/E/W,
             pair_<N>_BEHIND for N, from breasts.dmi) shifted 1 px down into clothing space
    extra    drawing pixels outside the silhouette that differ from the base
    hide     base pixels where the drawing is empty (white mask); keep = the rest of the base
The result is checked by rebuilding base - hide + breasts + extra, which must equal the drawing pixel for pixel;
the script stops otherwise. --compare also diffs against an existing stencil folder.
"""

import argparse
import os
import sys

from PIL import Image

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from dmi import Dmi  # noqa: E402

BODY_BREASTS = os.path.join(ROOT, "modular_rmh/icons/mob/sprite_accessory/genitals/breasts.dmi")
BODY_OFFSET_Y = 1
SIZES = range(9)
SOUTH, NORTH, EAST, WEST = range(4)
WHITE = (255, 255, 255, 255)
CLEAR = (0, 0, 0, 0)


def frames(path):
    return {s.name: [f.convert("RGBA") for f in s.frames] for s in Dmi.from_file(path).states if not s.movement}


def blank():
    return Image.new("RGBA", (32, 32), CLEAR)


def shifted(image, dy):
    out = blank()
    out.paste(image, (0, dy))
    return out


def silhouettes(body, size):
    """Per direction: (layer name, opaque mask) or None."""
    out = []
    for d in range(4):
        layer = "BEHIND" if d == NORTH else "ADJ"
        name = f"pair_{size}_{layer}"
        if size == 0 or name not in body:
            out.append(None)
            continue
        out.append((layer, shifted(body[name][d], BODY_OFFSET_Y).split()[3].load()))
    return out


def split(drawing, base, shape):
    """One direction: (breasts, extra, hide, keep) images."""
    breasts, extra, hide, keep = blank(), blank(), blank(), blank()
    src, ref = drawing.load(), base.load()
    b, e, h, k = breasts.load(), extra.load(), hide.load(), keep.load()
    for x in range(32):
        for y in range(32):
            p, q = src[x, y], ref[x, y]
            inside = shape is not None and shape[x, y]
            if p[3]:
                if inside:
                    b[x, y] = p
                elif not q[3] or p != q:
                    e[x, y] = p
            if q[3]:
                if p[3]:
                    k[x, y] = WHITE
                else:
                    h[x, y] = WHITE
    return breasts, extra, hide, keep


def rebuild(base, breasts, extra, hide):
    out = base.copy()
    out.putalpha(Image.composite(Image.new("L", (32, 32), 0), out.split()[3], hide.split()[3]))
    out.alpha_composite(breasts)
    out.alpha_composite(extra)
    return out


def same(a, b):
    """Pixel-equal, treating every fully transparent pixel as the same."""
    return [p if p[3] else CLEAR for p in a.getdata()] == [p if p[3] else CLEAR for p in b.getdata()]


def write(path, states):
    dmi = Dmi(32, 32)
    for name, images in states:
        state = dmi.state(name, dirs=4)
        state.frames.extend(images)
    dmi.to_file(path)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("drawing")
    parser.add_argument("worn")
    parser.add_argument("out")
    parser.add_argument("--state")
    parser.add_argument("--compare")
    args = parser.parse_args()
    base_name = args.state or os.path.splitext(os.path.basename(args.drawing))[0]
    drawing = frames(args.drawing)
    worn = frames(args.worn)
    if base_name not in worn:
        sys.exit(f"{args.worn} has no state {base_name!r}")
    base = worn[base_name]
    body = frames(BODY_BREASTS)

    hide_states, keep_states, extra_states, breast_states = [], [], [], []
    for n in SIZES:
        name = f"{base_name}_{n}"
        if name not in drawing:
            sys.exit(f"{args.drawing} has no state {name!r}")
        shapes = silhouettes(body, n)
        per_layer = {"ADJ": [blank() for _ in range(4)], "BEHIND": [blank() for _ in range(4)]}
        hides, keeps, extras = [], [], []
        for d in range(4):
            breasts, extra, hide, keep = split(drawing[name][d], base[d], shapes[d] and shapes[d][1])
            if shapes[d]:
                per_layer[shapes[d][0]][d] = breasts
            if not same(rebuild(base[d], breasts, extra, hide), drawing[name][d]):
                sys.exit(f"rebuild of {name} dir {d} differs from the drawing")
            hides.append(hide)
            keeps.append(keep)
            extras.append(extra)
        hide_states.append((f"{name}_hide", hides))
        keep_states.append((f"{name}_keep", keeps))
        extra_states.append((f"{name}_extra", extras))
        if n == 0:
            breast_states.append(("pair_0_FRONT", per_layer["ADJ"]))
            continue
        breast_states.append((f"pair_{n}_ADJ", per_layer["ADJ"]))
        if f"pair_{n}_BEHIND" in body:
            breast_states.append((f"pair_{n}_BEHIND", per_layer["BEHIND"]))

    os.makedirs(args.out, exist_ok=True)
    out = os.path.join(args.out, base_name)
    write(out + "_alpha_hide.dmi", hide_states)
    write(out + "_alpha_keep.dmi", keep_states)
    write(out + "_extra.dmi", extra_states)
    write(out + "_breasts.dmi", breast_states)
    print(f"{args.out}: stencil for {base_name}, rebuild matches the drawing for all sizes")

    if args.compare:
        mismatches = 0
        for suffix in ("_alpha_hide", "_alpha_keep", "_extra", "_breasts"):
            mine = frames(out + suffix + ".dmi")
            theirs = frames(os.path.join(args.compare, base_name + suffix + ".dmi"))
            for state in sorted(set(mine) | set(theirs)):
                a, b = mine.get(state), theirs.get(state)
                if a is None or b is None or any(not same(x, y) for x, y in zip(a, b)):
                    mismatches += 1
                    print(f"  differs: {suffix} {state}")
        print(f"compare with {args.compare}: {mismatches} differing states")


if __name__ == "__main__":
    main()
