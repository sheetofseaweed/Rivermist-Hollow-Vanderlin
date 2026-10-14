"""Fills the back (north) view of a breast-sized drawing from its front view: the parts of the garment that big breasts
push out past the body's outline are seen from behind too.

Usage:
    python tools/breast_sized_clothing/back_from_front.py <drawing.dmi or .aseprite> <out.dmi> [--preview out.png]
        [--sizes 1-8] [--margin 1]

For every size N: take the front (south) view, keep its pixels that lie outside the female body sprite's silhouette
(the 1 px gaps between the arms and the torso count as outside, they are see-through from behind too) and that come
from the breasts (differ from size 0's front view, or lie within `margin` px of the size's breast silhouette), mirror
them left-right (back view: the body is symmetric about x -> 30 - x). On the back view first clear what the old drawing
had for the breasts (pixels outside the body that differ from size 0's back view, near the breasts), then put the
mirrored pixels only where the back is empty: from behind the garment's own back (sleeves, bodice, as at size 0) is
nearer than the breasts, so they never cover it. Light pixels among the copied ones (trim, highlights lit from the
front: luminance over --light, default 150) are painted in the garment's main dark colour (the most common of its
darkest quarter of colours) instead, so the armpits get no white dots.
The detail layer is not touched. A .aseprite canvas (make_garment_canvas.py) is read through its "clothing" layer.
"""

import argparse
import os
import re
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools"))
sys.path.insert(0, os.path.join(HERE, "mannequin"))
from dmi import Dmi  # noqa: E402
from PIL import Image, ImageDraw, ImageFont  # noqa: E402

BODY_ICON = os.path.join(ROOT, "icons/roguetown/mob/bodies/f/fm.dmi")
BREASTS = os.path.join(ROOT, "modular_rmh/icons/mob/sprite_accessory/genitals/breasts.dmi")
SOUTH, NORTH = 0, 1
MIRROR_AXIS = 30  # x -> 30 - x maps the body sprite onto itself
SKIN = (232, 183, 150)


def frames(path):
    return {s.name: [f.convert("RGBA") for f in s.frames] for s in Dmi.from_file(path).states if not s.movement}


def load_drawing(path):
    if path.endswith(".aseprite"):
        import make_garment_canvas as canvas
        with tempfile.TemporaryDirectory() as tmp:
            out = os.path.join(tmp, "d.dmi")
            canvas.to_dmi(path, out, mirror="none")
            return frames(out)
    return frames(path)


def silhouette(image):
    a = image.split()[3].load()
    return {(x, y) for x in range(32) for y in range(32) if a[x, y]}


def dilate(points, r):
    out = set(points)
    for (x, y) in points:
        for dx in range(-r, r + 1):
            for dy in range(-r, r + 1):
                out.add((x + dx, y + dy))
    return out


def luminance(p):
    return 0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]


def main_dark_colour(drawing):
    """The most common colour among the darkest quarter of the drawing's colours."""
    counts = {}
    for imgs in drawing.values():
        for img in imgs:
            for p in img.getdata():
                if p[3] == 255:
                    counts[p] = counts.get(p, 0) + 1
    colours = sorted(counts, key=luminance)
    darkest = colours[:max(1, len(colours) // 4)]
    return max(darkest, key=lambda c: counts[c])


def back_from_front(drawing, sizes, margin, light=150):
    state = next(re.match(r"^(\w+?)_f_0$", n).group(1) for n in drawing if re.match(r"^\w+?_f_0$", n))
    body = silhouette(frames(BODY_ICON)["fm"][SOUTH])
    breasts = frames(BREASTS)
    front0 = drawing[f"{state}_f_0"][SOUTH].load()
    dark = main_dark_colour(drawing)
    back0 = drawing[f"{state}_f_0"][NORTH].load()
    result = {name: [f.copy() for f in imgs] for name, imgs in drawing.items()}
    changed = {}
    for n in sizes:
        name = f"{state}_f_{n}"
        front = drawing[name][SOUTH]
        fp = front.load()
        adj = breasts.get(f"pair_{n}_ADJ")
        shape = set()
        if adj:
            shifted = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
            shifted.paste(adj[SOUTH], (0, 1))
            shape = dilate(silhouette(shifted), margin)
        picked = []
        for x in range(32):
            for y in range(32):
                if not fp[x, y][3] or (x, y) in body:
                    continue
                if fp[x, y] != front0[x, y] or (x, y) in shape:
                    picked.append((x, y))
        back = result[name][NORTH]
        bp = back.load()
        # Old breast pixels of the back view: outside the body, near the (mirrored) breast shape, not the garment's own.
        near = {(MIRROR_AXIS - x, y) for (x, y) in dilate(shape, 1)} if shape else set()
        for (x, y) in near:
            if 0 <= x < 32 and 0 <= y < 32 and (x, y) not in body and bp[x, y][3] and bp[x, y] != back0[x, y]:
                bp[x, y] = (0, 0, 0, 0)
        count = 0
        for (x, y) in picked:
            mx = MIRROR_AXIS - x
            if 0 <= mx < 32 and not bp[mx, y][3]:
                bp[mx, y] = dark if luminance(fp[x, y]) > light else fp[x, y]
                count += 1
        changed[n] = count
    return state, result, changed


def write(path, data):
    dmi = Dmi(32, 32)
    for name, imgs in data.items():
        st = dmi.state(name, dirs=len(imgs))
        st.frames.extend(imgs)
    dmi.to_file(path)


def preview(path, state, before, after, sizes):
    body = frames(BODY_ICON)["fm"][NORTH]
    breasts = frames(BREASTS)

    def tint(im):
        o = Image.new("RGBA", im.size)
        o.putdata([(p[0] * SKIN[0] // 255, p[1] * SKIN[1] // 255, p[2] * SKIN[2] // 255, p[3]) for p in im.getdata()])
        return o

    def cell(img, n):
        c = Image.new("RGBA", (32, 32), (80, 80, 96, 255))
        behind = breasts.get(f"pair_{n}_BEHIND")
        if behind:
            s = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
            s.paste(behind[NORTH], (0, 1))
            c.alpha_composite(tint(s))
        c.alpha_composite(tint(body))
        c.alpha_composite(img)
        return c.resize((128, 128), Image.NEAREST)

    font = ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", 14)
    sheet = Image.new("RGBA", (70 + len(sizes) * 136, 300), (32, 32, 38, 255))
    d = ImageDraw.Draw(sheet)
    d.text((6, 70), "было", font=font, fill="white")
    d.text((6, 210), "стало", font=font, fill="white")
    for i, n in enumerate(sizes):
        x = 70 + i * 136
        d.text((x + 50, 4), str(n), font=font, fill="yellow")
        sheet.alpha_composite(cell(before[f"{state}_f_{n}"][NORTH], n), (x, 24))
        sheet.alpha_composite(cell(after[f"{state}_f_{n}"][NORTH], n), (x, 164))
    sheet.save(path)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("source")
    parser.add_argument("out")
    parser.add_argument("--preview")
    parser.add_argument("--sizes", default="1-8")
    parser.add_argument("--margin", type=int, default=1)
    parser.add_argument("--light", type=int, default=150, help="copied pixels brighter than this get the dark colour")
    args = parser.parse_args()
    lo, _, hi = args.sizes.partition("-")
    sizes = list(range(int(lo), int(hi or lo) + 1))
    drawing = load_drawing(args.source)
    state, result, changed = back_from_front(drawing, sizes, args.margin, args.light)
    write(args.out, result)
    print(f"{args.out}: {state}, pixels copied per size: {changed}")
    if args.preview:
        preview(args.preview, state, drawing, result, sizes)


if __name__ == "__main__":
    main()
