"""Rough draft of the "squeeze together" breast animation for the artist to finish in Aseprite.

Usage:
    python tools/breast_anim/draft_squeeze.py [--out "../breasts files/anim/squeeze.aseprite"] [--preview out.gif]

Front (south ADJ) view only is drafted: each half of the rest sprite from breasts.dmi is compressed toward the
centre column (outer edge moves in by `d` px, the cleavage stays) and lifted by `u` px. Side (east ADJ) and back
(north BEHIND) layers reuse existing rest / walk / run frames with matching motion, see pick_squeeze_side_back.py. The file has the same layout as src/run.aseprite: groups "<N>",
layers "<N> front" / "<N> side" / "<N> back", plus a hidden "body ref" layer under them for context.
Then the release: the breasts drop below rest and bounce twice, the first time stronger, the second weaker. A drop
or rise stretches or squashes each column with its top row pinned to the chest, so they stay attached.
Frames: 1 half squeeze, 2 full, 3 hold, 4 drop, 5 rebound up, 6 second smaller drop; then back to rest.
"""

import argparse
import os
import subprocess
import sys
import tempfile

from PIL import Image

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from dmi import Dmi  # noqa: E402
sys.path.insert(0, os.path.dirname(__file__))
from pick_squeeze_side_back import image as anim_image, pick  # noqa: E402

BASE = os.path.join(ROOT, "modular_rmh/icons/mob/sprite_accessory/genitals/breasts.dmi")
BODY = os.path.join(ROOT, "icons/roguetown/mob/bodies/f/fm.dmi")
ASEPRITE = os.environ.get("ASEPRITE", r"G:\SteamLibrary\steamapps\common\Aseprite\Aseprite.exe")
SIZES = (5, 6, 7, 8)  # animated sizes only; 4 stays still for now
CENTRE = 15
SOUTH, NORTH, EAST = 0, 1, 2
# (d, u, k) per frame: d inward squeeze, u lift (px up), k stretch of the bottom edge (px down, negative = up).
# Small sizes are narrow and short, so they move less.
STEPS = {
    "small": [(1, 0, 0), (1, 1, 0), (1, 1, 0), (0, 0, 1), (0, 0, -1), (0, 0, 1)],
    "big": [(1, 0, 0), (2, 1, 0), (2, 1, 0), (0, 0, 2), (0, 0, -1), (0, 0, 1)],
}
FRAME_COUNT = 6
# Preview timing in ms: rest, frames 1-6, rest.
PREVIEW_MS = [400, 100, 100, 300, 100, 100, 80, 400]

LUA = r'''
local dir = app.params["dir"]
local out = app.params["out"]
local sizes = {}
for s in string.gmatch(app.params["sizes"], "%d+") do table.insert(sizes, s) end
local frames = tonumber(app.params["frames"])
local spr = Sprite(32, 32, ColorMode.RGB)
for i = 2, frames do spr:newEmptyFrame() end
local ref = spr.layers[1]
ref.name = "body ref"
for f = 1, frames do spr:newCel(ref, f, Image { fromFile = dir .. "/body.png" }, Point(0, 0)) end
ref.isVisible = true
ref.isEditable = false
for _, n in ipairs(sizes) do
  local group = spr:newGroup()
  group.name = n
  for _, part in ipairs({ "back", "side", "front" }) do
    local layer = spr:newLayer()
    layer.name = n .. " " .. part
    layer.parent = group
    for f = 1, frames do
      spr:newCel(layer, f, Image { fromFile = dir .. "/" .. n .. "_" .. part .. "_" .. f .. ".png" }, Point(0, 0))
    end
  end
  group.isVisible = (n == sizes[#sizes])
end
for f = 1, frames do spr.frames[f].duration = 0.1 end
spr:saveAs(out)
'''


def still(name, d):
    return {s.name: s for s in Dmi.from_file(BASE).states if not s.movement}[name].frames[d].convert("RGBA")


def squeeze(image, d, u):
    src = image.load()
    out = Image.new("RGBA", image.size, (0, 0, 0, 0))
    dst = out.load()
    box = image.getbbox()
    left, right = box[0], box[2] - 1
    for x_to in range(left + d, CENTRE):  # left half, outline kept, interior columns dropped evenly
        x_from = round(left + (x_to - (left + d)) * (CENTRE - left) / (CENTRE - left - d))
        for y in range(32):
            if src[x_from, y][3] and 0 <= y - u < 32:
                dst[x_to, y - u] = src[x_from, y]
    for x_to in range(CENTRE + 1, right - d + 1):
        x_from = round(right - ((right - d) - x_to) * (right - CENTRE) / (right - CENTRE - d))
        for y in range(32):
            if src[x_from, y][3] and 0 <= y - u < 32:
                dst[x_to, y - u] = src[x_from, y]
    for y in range(32):  # cleavage column
        if src[CENTRE, y][3] and 0 <= y - u < 32:
            dst[CENTRE, y - u] = src[CENTRE, y]
    return out


def stretch(image, k):
    """Moves each column's bottom edge down by k (up when negative), top row pinned; rows resampled evenly."""
    if not k:
        return image
    src = image.load()
    out = Image.new("RGBA", image.size, (0, 0, 0, 0))
    dst = out.load()
    for x in range(32):
        rows = [y for y in range(32) if src[x, y][3]]
        if not rows:
            continue
        top, bottom = rows[0], rows[-1]
        new_bottom = max(top, min(31, bottom + k))
        for y in range(top, new_bottom + 1):
            y_from = top if new_bottom == top else round(top + (y - top) * (bottom - top) / (new_bottom - top))
            dst[x, y] = src[x, y_from]
    return out


def frames_for(size):
    rest = still(f"pair_{size}_ADJ", SOUTH)
    steps = STEPS["small" if size <= 5 else "big"]
    side = [anim_image(size, name, "side") for name in pick(size, "side")[0]]
    back = [anim_image(size, name, "back") for name in pick(size, "back")[0]]
    return rest, [stretch(squeeze(rest, d, u) if d or u else rest, k) for d, u, k in steps], side, back


def preview(path):
    body_state = {s.name: s for s in Dmi.from_file(BODY).states}["fm"]
    bodies = {SOUTH: body_state.frames[SOUTH].convert("RGBA"), EAST: body_state.frames[EAST].convert("RGBA"),
              NORTH: body_state.frames[NORTH].convert("RGBA")}
    skin = (232, 183, 150)

    def tint(im):
        o = Image.new("RGBA", im.size)
        o.putdata([(p[0] * skin[0] // 255, p[1] * skin[1] // 255, p[2] * skin[2] // 255, p[3]) for p in im.getdata()])
        return o

    def shifted(im):
        o = Image.new("RGBA", im.size, (0, 0, 0, 0))
        o.paste(im, (0, 1))
        return o

    data = {n: frames_for(n) for n in SIZES}
    sheets = []
    for k in range(-1, FRAME_COUNT):  # rest, frames; columns = sizes, rows = S, E, N
        sheet = Image.new("RGBA", (32 * len(SIZES), 32 * 3), (90, 90, 105, 255))
        for i, n in enumerate(SIZES):
            rest, frames, side, back = data[n]
            views = [
                (SOUTH, None, rest if k < 0 else frames[k]),
                (EAST, None, anim_image(n, "rest", "side") if k < 0 else side[k]),
                (NORTH, anim_image(n, "rest", "back") if k < 0 else back[k], None),
            ]
            for row, (d, behind, adj) in enumerate(views):
                cell = Image.new("RGBA", (32, 32), (90, 90, 105, 255))
                if behind is not None:
                    cell.alpha_composite(tint(shifted(behind)))
                cell.alpha_composite(tint(bodies[d]))
                if adj is not None:
                    cell.alpha_composite(tint(shifted(adj)))
                sheet.alpha_composite(cell, (32 * i, 32 * row))
        sheets.append(sheet.resize((sheet.width * 5, sheet.height * 5), Image.NEAREST))
    order = list(range(FRAME_COUNT + 1)) + [0]
    sheets[0].save(path, save_all=True, append_images=[sheets[i] for i in order[1:]], duration=PREVIEW_MS, loop=0, disposal=2)
    strip = Image.new("RGBA", (sheets[0].width * len(sheets) + 8 * (len(sheets) - 1), sheets[0].height), (32, 32, 38, 255))
    for i, s in enumerate(sheets):
        strip.alpha_composite(s, (i * (s.width + 8), 0))
    strip.save(os.path.splitext(path)[0] + ".png")


def main():
    parser = argparse.ArgumentParser()
    # Default: the artist's folder next to the repo; copy the finished file to src/squeeze.aseprite for the build.
    parser.add_argument("--out", default=os.path.join(ROOT, "..", "breasts files", "anim", "squeeze.aseprite"))
    parser.add_argument("--preview")
    args = parser.parse_args()
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        body = {s.name: s for s in Dmi.from_file(BODY).states}["fm"].frames[0].convert("RGBA")
        body.save(os.path.join(tmp, "body.png"))
        for n in SIZES:
            _, frames, side, back = frames_for(n)
            for f, image in enumerate(frames, 1):
                image.save(os.path.join(tmp, f"{n}_front_{f}.png"))
                side[f - 1].save(os.path.join(tmp, f"{n}_side_{f}.png"))
                back[f - 1].save(os.path.join(tmp, f"{n}_back_{f}.png"))
        script = os.path.join(tmp, "make.lua")
        open(script, "w").write(LUA)
        subprocess.run([ASEPRITE, "-b", "--script-param", f"dir={tmp}", "--script-param", f"out={os.path.abspath(args.out)}",
                        "--script-param", "sizes=" + ",".join(map(str, SIZES)), "--script-param", f"frames={FRAME_COUNT}",
                        "--script", script], check=True)
    print(args.out)
    if args.preview:
        preview(args.preview)
        print(args.preview)


if __name__ == "__main__":
    main()
