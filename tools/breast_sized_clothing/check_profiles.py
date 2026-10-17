"""Checks how a garment follows the breast animation, and compares warp profiles side by side.

Usage:
    python tools/breast_sized_clothing/check_profiles.py "<source folder>"
        Counts defects for the garment's profile (profiles/<folder name>.json).
    python tools/breast_sized_clothing/check_profiles.py "<source folder>" --profile "A=<json>" [--profile ...] [--compare out.gif]
        Also checks the labelled profiles, and with --compare writes a GIF with one preview per profile, e.g.
        --profile 'free={"pair": "free", "extra": "free", "hide": "free"}'

Defects, summed over every walk/run frame per size, and separately over the squeeze frames ("squeeze ..."):
    revealed    pixels of the original garment showing that were hidden at rest, by the hide cut or by the
                breast/extra layers drawn over them (should be 0)
    extra skin  body breast pixels covered by nothing, beyond what is visible at rest (should be ~0 for
                closed garments; open garments show skin by design)
The garment's worn base state (= folder name) is read from the file in the garment's profile "worn"
(default icons/roguetown/clothing/onmob/shirts_gown.dmi); --worn overrides it.
"""

import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import pack_breast_sized as P  # noqa: E402
from dmi import Dmi  # noqa: E402
from PIL import Image, ImageDraw, ImageFont  # noqa: E402


def resolve(profile):
    out = {"cut_under_clothing": profile.get("cut_under_clothing", False), "worn": profile.get("worn", P.DEFAULT_WORN),
           "pin_unchanged": P.resolve_pins(profile.get("pin_unchanged", []), "--profile")}
    for kind in ("pair", "extra", "hide"):
        value = profile.get(kind, "stretch")
        modes = value if isinstance(value, dict) else {"default": value}
        out[kind] = [modes.get(n, modes.get("default", "stretch")) for n in P.DIR_NAMES]
    return out


def defects(base, layers, motion, profile, garment):
    report = {}
    for size in sorted(motion):
        items = [(name, kind, frames[0]) for prefix, name, kind, s, frames in layers if prefix == base and s == size]
        hides = [frame for name, kind, frame in items if kind == "hide"]
        if not hides:
            continue

        rest_covers = [[frame[d].split()[3].load() for name, kind, frame in items if kind != "hide"] for d in range(4)]

        def count(body_frame, group, d):
            hide = [group[name][d] for name, kind, f in items if kind == "hide"][0].split()[3].load()
            covers = [group[name][d].split()[3].load() for name, kind, f in items if kind != "hide"]
            ga, h0, body = garment[d].split()[3].load(), hides[0][d].split()[3].load(), body_frame[d].split()[3].load()
            under = rest_covers[d]
            skin = revealed = 0
            for x in range(32):
                for y in range(32):
                    clothed = any(c[x, y] for c in covers)
                    if body[x, y] and not clothed and not (ga[x, y] and not hide[x, y]):
                        skin += 1
                    hidden_at_rest = h0[x, y] or any(c[x, y] for c in under)
                    if ga[x, y] and hidden_at_rest and not hide[x, y] and not clothed:
                        revealed += 1
            return skin, revealed

        rest = motion[size]["rest"]
        rest_group = P.warp_group(items, rest, rest, profile, garment)
        rest_skin = [count(rest, rest_group, d)[0] for d in range(4)]
        totals = {}
        for cycle in ("walk", "run", "squeeze"):
            key = "squeeze" if cycle == "squeeze" else "cycles"
            extra, revealed = totals.get(key, (0, 0))
            for body_frame in motion[size].get(cycle, []):
                group = P.warp_group(items, rest, body_frame, profile, garment)
                for d in range(4):
                    skin, rev = count(body_frame, group, d)
                    if d != P.NORTH:
                        extra += max(skin - rest_skin[d], 0)
                    revealed += rev
            totals[key] = (extra, revealed)
        report[size] = {"revealed": totals["cycles"][1], "extra skin": totals["cycles"][0],
                        "squeeze revealed": totals["squeeze"][1], "squeeze extra skin": totals["squeeze"][0]}
    return report


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("source")
    parser.add_argument("--worn", help="worn base file; default: the garment profile's \"worn\"")
    parser.add_argument("--compare")
    parser.add_argument("--profile", dest="profiles", action="append", default=[], help="label=json")
    args = parser.parse_args()

    base, layers = P.load_layers(args.source)
    motion = P.load_body_motion()
    own_profile = P.load_profile(args.source)
    worn_path = args.worn or os.path.join(P.ROOT, own_profile["worn"])
    worn = {s.name: P.state_frames(s) for s in Dmi.from_file(worn_path).states if not s.movement}
    garment = worn[base][0]
    variants = [("profile", own_profile)]
    for spec in args.profiles:
        label, _, text = spec.partition("=")
        variants.append((label, resolve(dict({"worn": own_profile["worn"]}, **json.loads(text)))))
    for label, profile in variants:
        print(label, defects(base, layers, motion, profile, garment))
    if not args.compare:
        return

    font = ImageFont.truetype("arial.ttf", 15) if os.name == "nt" else ImageFont.load_default()
    columns = []
    tmp = args.compare + ".part.gif"
    for label, profile in variants:
        P.write_preview(base, layers, motion, profile, tmp)
        with Image.open(tmp) as gif:
            frames = []
            for n in range(gif.n_frames):
                gif.seek(n)
                frames.append(gif.convert("RGB"))
        columns.append((label, frames))
    os.remove(tmp)
    width = sum(f[0].width for _, f in columns) + 12 * (len(columns) - 1)
    height = columns[0][1][0].height + 28
    out = []
    for n in range(len(columns[0][1])):
        sheet = Image.new("RGB", (width, height), (30, 30, 38))
        draw = ImageDraw.Draw(sheet)
        x = 0
        for label, frames in columns:
            draw.text((x + 4, 5), label, font=font, fill=(235, 235, 235))
            sheet.paste(frames[n], (x, 28))
            x += frames[n].width + 12
        out.append(sheet)
    out[0].save(args.compare, save_all=True, append_images=out[1:], duration=100, loop=0)
    print("compare:", args.compare)


if __name__ == "__main__":
    main()
