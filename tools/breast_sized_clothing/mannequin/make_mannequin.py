"""Builds the female mannequin Aseprite file for drawing breast-sized clothing.

Usage:
    python tools/breast_sized_clothing/mannequin/make_mannequin.py "<out.aseprite>"

96x32 canvas with the south, east and north views side by side, one frame (tagged "size N") per breast size 0-8,
layers: breasts behind (BEHIND), body, breasts (ADJ), and an empty "clothing" layer on top. Breasts sit where they
are in game for humans (breasts.dmi shifted 1px down), the frame the stencil uses. Needs the Aseprite CLI
(ASEPRITE env var overrides the default path).
"""

import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from dmi import Dmi  # noqa: E402
from PIL import Image  # noqa: E402

ASEPRITE = os.environ.get("ASEPRITE", r"G:\SteamLibrary\steamapps\common\Aseprite\Aseprite.exe")
BODY_ICON = os.path.join(ROOT, "icons/roguetown/mob/bodies/f/fm.dmi")
BREASTS = os.path.join(ROOT, "modular_rmh/icons/mob/sprite_accessory/genitals/breasts.dmi")
VIEWS = (0, 2, 1)  # BYOND frame order is S, N, E, W: take S, E, N


def frames(path):
    return {s.name: [f.convert("RGBA") for f in s.frames] for s in Dmi.from_file(path).states if not s.movement}


def shifted(image, dy):
    out = Image.new("RGBA", image.size, (0, 0, 0, 0))
    out.paste(image, (0, dy))
    return out


def main(out):
    body = frames(BODY_ICON)["fm"]
    breasts = frames(BREASTS)
    with tempfile.TemporaryDirectory() as tmp:
        for size in range(9):
            for layer in ("behind", "body", "breasts"):
                image = Image.new("RGBA", (96, 32), (0, 0, 0, 0))
                for i, d in enumerate(VIEWS):
                    if layer == "body":
                        part = body[d]
                    else:
                        state = f"pair_{size}_{'BEHIND' if layer == 'behind' else 'ADJ'}"
                        if state not in breasts:
                            continue
                        part = shifted(breasts[state][d], 1)
                    image.alpha_composite(part, (i * 32, 0))
                image.save(os.path.join(tmp, f"{layer}_{size}.png"))
        subprocess.run([ASEPRITE, "-b", "--script-param", f"dir={tmp}", "--script-param", f"out={os.path.abspath(out)}",
                        "--script", os.path.join(HERE, "make_mannequin.lua")], check=True)
    print(out)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    main(sys.argv[1])
