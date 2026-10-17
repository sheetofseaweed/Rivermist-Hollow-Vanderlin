"""GIF and contact sheet of a breast animation source (layout of src/run.aseprite: groups "<N>", layers
"<N> front" / "<N> side" / "<N> back") over the body, rows south / east / north, one column per size.
Layer opacity is an editor setting and is ignored (every drawn pixel exported opaque), like the build does.

Usage: python tools/breast_anim/preview_anim.py <file.aseprite> <out.gif> [--sizes 5,6,7,8] [--still-first]
--still-first puts the rest pose from breasts_anim.dmi before and after the frames.
Frame durations come from the Aseprite file.
"""
import argparse
import json
import os
import subprocess
import sys
import tempfile

from PIL import Image

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from dmi import Dmi  # noqa: E402

ASEPRITE = os.environ.get("ASEPRITE", r"G:\SteamLibrary\steamapps\common\Aseprite\Aseprite.exe")
ANIM = os.path.join(ROOT, "modular_rmh/icons/mob/sprite_accessory/genitals/breasts_anim.dmi")
BODY = os.path.join(ROOT, "icons/roguetown/mob/bodies/f/fm.dmi")
SOUTH, NORTH, EAST = 0, 1, 2
SKIN = (232, 183, 150)
LUA = 'local s = app.open(app.params["src"]) for _, l in ipairs(s.layers) do local function f(x) if x.isGroup then for _, c in ipairs(x.layers) do f(c) end else x.opacity = 255 end end f(l) end s:saveAs(app.params["dst"])'


def export(path, tmp):
    copy = os.path.join(tmp, "copy.aseprite")
    script = os.path.join(tmp, "opaque.lua")
    open(script, "w").write(LUA)
    subprocess.run([ASEPRITE, "-b", "--script-param", f"src={os.path.abspath(path)}", "--script-param", f"dst={copy}", "--script", script], check=True, capture_output=True)
    data, sheet = os.path.join(tmp, "s.json"), os.path.join(tmp, "s.png")
    subprocess.run([ASEPRITE, "-b", "--all-layers", "--split-layers", copy, "--data", data, "--format", "json-array",
                    "--filename-format", "{layer}|{frame}", "--sheet", sheet, "--sheet-type", "rows"], check=True, capture_output=True)
    info = json.load(open(data))
    image = Image.open(sheet).convert("RGBA")
    cells, durations = {}, {}
    for frame in info["frames"]:
        layer, index = frame["filename"].split("|")
        r = frame["frame"]
        cells[(layer, int(index))] = image.crop((r["x"], r["y"], r["x"] + 32, r["y"] + 32))
        durations[int(index)] = frame["duration"]
    return cells, [durations[i] for i in sorted(durations)]


def tint(im):
    out = Image.new("RGBA", im.size)
    out.putdata([(p[0] * SKIN[0] // 255, p[1] * SKIN[1] // 255, p[2] * SKIN[2] // 255, p[3]) for p in im.getdata()])
    return out


def shifted(im):  # human OFFSET_BREASTS -1 = 1 px down
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.paste(im, (0, 1))
    return out


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("source")
    parser.add_argument("out")
    parser.add_argument("--sizes", default="5,6,7,8")
    parser.add_argument("--still-first", action="store_true")
    args = parser.parse_args()
    sizes = [int(s) for s in args.sizes.split(",")]
    with tempfile.TemporaryDirectory() as tmp:
        cells, durations = export(args.source, tmp)
    body = {s.name: s for s in Dmi.from_file(BODY).states}["fm"]
    bodies = {d: body.frames[d].convert("RGBA") for d in (SOUTH, EAST, NORTH)}
    rest = {s.name: s for s in Dmi.from_file(ANIM).states if not s.movement}

    def sheet(get):
        out = Image.new("RGBA", (32 * len(sizes), 96), (90, 90, 105, 255))
        for i, n in enumerate(sizes):
            front, side, back = get(n)
            for row, (d, behind, adj) in enumerate([(SOUTH, None, front), (EAST, None, side), (NORTH, back, None)]):
                cell = Image.new("RGBA", (32, 32), (90, 90, 105, 255))
                if behind is not None:
                    cell.alpha_composite(tint(shifted(behind)))
                cell.alpha_composite(tint(bodies[d]))
                if adj is not None:
                    cell.alpha_composite(tint(shifted(adj)))
                out.alpha_composite(cell, (32 * i, 32 * row))
        return out.resize((out.width * 5, out.height * 5), Image.NEAREST)

    def opaque(im):
        im = im.copy()
        im.putalpha(im.split()[3].point(lambda a: 255 if a else 0))
        return im

    frames = [sheet(lambda n, k=k: tuple(opaque(cells[(f"{n} {part}", k)]) for part in ("front", "side", "back")))
              for k in range(len(durations))]
    times = list(durations)
    if args.still_first:
        still = sheet(lambda n: (rest[f"pair_{n}_ADJ"].frames[SOUTH].convert("RGBA"), rest[f"pair_{n}_ADJ"].frames[EAST].convert("RGBA"),
                                 rest[f"pair_{n}_BEHIND"].frames[NORTH].convert("RGBA")))
        frames = [still] + frames + [still]
        times = [400] + times + [400]
    frames[0].save(args.out, save_all=True, append_images=frames[1:], duration=times, loop=0, disposal=2)
    strip = Image.new("RGBA", (frames[0].width * len(frames) + 8 * (len(frames) - 1), frames[0].height), (32, 32, 38, 255))
    for i, f in enumerate(frames):
        strip.alpha_composite(f, (i * (f.width + 8), 0))
    strip.save(os.path.splitext(args.out)[0] + ".png")
    print(args.out, "frames:", len(durations), "durations ms:", durations)


if __name__ == "__main__":
    main()
