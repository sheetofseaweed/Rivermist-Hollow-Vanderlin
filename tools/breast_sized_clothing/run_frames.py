"""South view of the run frames r1-r8 for animated sizes 5-8 plus left/right breast bottom heights per frame
(image left = the character's right breast). Used to pick asymmetric frames, e.g. for a self-suck loop.

Usage: python tools/breast_sized_clothing/run_frames.py . "../anim_previews/run_frames_south.png"
"""
import sys

root, out = sys.argv[1], sys.argv[2]
sys.path.insert(0, root + "/tools")
from dmi import Dmi  # noqa: E402
from PIL import Image, ImageDraw, ImageFont  # noqa: E402


def frames(path):  # first frame = south view
    return {s.name: s.frames[0].convert("RGBA") for s in Dmi.from_file(path).states if not s.movement}


anim = frames(root + "/modular_rmh/icons/mob/sprite_accessory/genitals/breasts_anim.dmi")
body = frames(root + "/icons/roguetown/mob/bodies/f/fm.dmi")["fm"]
skin = (232, 183, 150)


def tint(im):
    o = Image.new("RGBA", im.size)
    o.putdata([(p[0] * skin[0] // 255, p[1] * skin[1] // 255, p[2] * skin[2] // 255, p[3]) for p in im.getdata()])
    return o


def shifted(im):
    o = Image.new("RGBA", im.size, (0, 0, 0, 0))
    o.paste(im, (0, 1))
    return o


def bottoms(im):
    a = im.split()[3].load()
    out = []
    for half in (range(0, 16), range(16, 32)):
        cols = [max(y for y in range(32) if a[x, y]) for x in half if any(a[x, y] for y in range(32))]
        out.append(round(sum(cols) / len(cols), 2))
    return out


Z, sizes = 6, (5, 6, 7, 8)
sheet = Image.new("RGBA", (40 + 9 * 32 * Z, 24 + len(sizes) * 32 * Z), (32, 32, 38, 255))
draw = ImageDraw.Draw(sheet)
font = ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", 18)
for c in range(9):
    draw.text((40 + c * 32 * Z + 80, 2), "rest" if c == 0 else f"r{c}", font=font, fill="white")
for r, n in enumerate(sizes):
    draw.text((8, 24 + r * 32 * Z + 90), str(n), font=font, fill="white")
    row = []
    for c in range(9):
        state = f"pair_{n}_ADJ" if c == 0 else f"pair_{n}_r{c}_ADJ"
        row.append(f"{'rest' if c == 0 else 'r%d' % c}:{bottoms(anim[state])}")
        cell = Image.new("RGBA", (32, 32), (90, 90, 105, 255))
        cell.alpha_composite(tint(body))
        cell.alpha_composite(tint(shifted(anim[state])))
        cell = cell.crop((6, 8, 26, 24)).resize((32 * Z, int(16 * 32 * Z / 20)), Image.NEAREST)
        sheet.alpha_composite(cell, (40 + c * 32 * Z, 24 + r * 32 * Z))
    print(n, *row)
sheet.save(out)
