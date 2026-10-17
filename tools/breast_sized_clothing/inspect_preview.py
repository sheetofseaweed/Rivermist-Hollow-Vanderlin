"""Visual helpers for reviewing breast-sized garments with the artist (Python composites, not in-game captures).

    python tools/breast_sized_clothing/inspect_preview.py grid "<folder>" out.png [--dir S|N|E|W]
        Gridded sheet, rows sizes 5-8, columns rest / walk 1-8 / run 1-8, garment over the body. The artist marks
        suspicious pixels in pure blue (#0000FF) and sends the image back.
    python tools/breast_sized_clothing/inspect_preview.py marks marked.png [--dir S] [--folder "<folder>"]
        Finds the blue marks (any scale, approximate colours) and prints size / frame / sprite pixel (x, y from the
        top left) for each; with --folder it also says which layer draws there (clothing layer, base, body).
    python tools/breast_sized_clothing/inspect_preview.py stack "<lower folder>" "<upper folder>" out.gif
        Lower garment in the shirt slot, upper in the armor slot, walk cycle, front and side, matching the in-game
        order (lifted fronts cut by the bases above; lower layers skipped under a closed upper: pass --closed).
"""

import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import pack_breast_sized as P  # noqa: E402
from dmi import Dmi  # noqa: E402
from PIL import Image, ImageDraw, ImageFont  # noqa: E402

SKIN = (232, 183, 150)
DIRS = {"S": 0, "N": 1, "E": 2, "W": 3}
CROP = (4, 7, 28, 23)  # sprite area shown in the grid: x0, y0, x1, y1
SCALE = 10
LABEL_W, LABEL_H, GAP = 70, 24, 6
COLUMNS = ["rest"] + [f"walk {i}" for i in range(1, 9)] + [f"run {i}" for i in range(1, 9)]
SIZES = (5, 6, 7, 8)


def font(size=14):
    try:
        return ImageFont.truetype("arial.ttf", size)
    except OSError:
        return ImageFont.load_default()


def tint(image, colour):
    out = Image.new("RGBA", image.size)
    out.putdata([(p[0] * colour[0] // 255, p[1] * colour[1] // 255, p[2] * colour[2] // 255, p[3]) for p in image.convert("RGBA").getdata()])
    return out


def alpha(image):
    return image.split()[3].point(lambda a: 255 if a else 0)


def cut(image, mask):
    image = image.copy()
    image.putalpha(Image.composite(Image.new("L", image.size, 0), image.split()[3], mask))
    return image


def body_frames():
    return [s for s in Dmi.from_file(P.BODY_ICON).states if s.name == "fm"][0].frames


class Garment:
    def __init__(self, folder):
        self.base, self.layers = P.load_layers(folder)
        self.profile = P.load_profile(folder)
        worn = {s.name: P.state_frames(s) for s in Dmi.from_file(os.path.join(P.ROOT, self.profile["worn"])).states if not s.movement}
        self.garment = worn[self.base][0]

    def parts(self, motion, size, body_frame, d):
        """(base cut by the hide mask, breast + extra layers) for one frame and direction."""
        items = [(name, kind, frames[0]) for prefix, name, kind, s, frames in self.layers if prefix == self.base and s == size]
        group = P.warp_group(items, motion[size]["rest"], body_frame, self.profile, self.garment)
        base = self.garment[d].copy()
        over = Image.new("RGBA", (32, 32))
        for name, kind, _ in items:
            if kind == "hide":
                base = cut(base, alpha(group[name][d]))
            else:
                over.alpha_composite(group[name][d])
        return base, over


def frames_for(motion, size):
    return [motion[size]["rest"]] + motion[size]["walk"] + motion[size]["run"]


def compose_single(garment, motion, body, size, body_frame, d):
    cell = Image.new("RGBA", (32, 32), (70, 70, 90, 255))
    cell.alpha_composite(tint(body[d], SKIN))
    cell.alpha_composite(tint(body_frame[d], SKIN))
    base, over = garment.parts(motion, size, body_frame, d)
    cell.alpha_composite(base)
    cell.alpha_composite(over)
    return cell


def grid(folder, out, d):
    garment, motion, body = Garment(folder), P.load_body_motion(), body_frames()
    w, h = (CROP[2] - CROP[0]) * SCALE, (CROP[3] - CROP[1]) * SCALE
    sheet = Image.new("RGB", (LABEL_W + len(COLUMNS) * (w + GAP), LABEL_H + len(SIZES) * (h + GAP)), (25, 25, 32))
    draw = ImageDraw.Draw(sheet)
    for c, label in enumerate(COLUMNS):
        draw.text((LABEL_W + c * (w + GAP) + 4, 4), label, font=font(), fill=(230, 230, 230))
    for r, size in enumerate(SIZES):
        draw.text((6, LABEL_H + r * (h + GAP) + h // 2 - 8), f"size {size}", font=font(), fill=(230, 230, 230))
        for c, body_frame in enumerate(frames_for(motion, size)):
            tile = compose_single(garment, motion, body, size, body_frame, d).crop(CROP).resize((w, h), Image.NEAREST).convert("RGB")
            tile_draw = ImageDraw.Draw(tile)
            for i in range(1, CROP[2] - CROP[0]):
                tile_draw.line([(i * SCALE, 0), (i * SCALE, h)], fill=(55, 55, 65))
            for j in range(1, CROP[3] - CROP[1]):
                tile_draw.line([(0, j * SCALE), (w, j * SCALE)], fill=(55, 55, 65))
            sheet.paste(tile, (LABEL_W + c * (w + GAP), LABEL_H + r * (h + GAP)))
    sheet.save(out)
    print(out)


def marks(path, d, folder=None):
    image = Image.open(path).convert("RGB")
    w, h = (CROP[2] - CROP[0]) * SCALE, (CROP[3] - CROP[1]) * SCALE
    full_w = LABEL_W + len(COLUMNS) * (w + GAP)
    scale = full_w / image.width
    found = {}
    px = image.load()
    for x in range(image.width):
        for y in range(image.height):
            r, g, b = px[x, y]
            if b > 110 and b > r + 50 and b > g + 50:
                gx, gy = x * scale - LABEL_W, y * scale - LABEL_H
                c, row = int(gx // (w + GAP)), int(gy // (h + GAP))
                if not (0 <= c < len(COLUMNS) and 0 <= row < len(SIZES)):
                    continue
                lx, ly = int((gx - c * (w + GAP)) // SCALE), int((gy - row * (h + GAP)) // SCALE)
                if lx < CROP[2] - CROP[0] and ly < CROP[3] - CROP[1]:
                    found.setdefault((SIZES[row], c), set()).add((lx + CROP[0], ly + CROP[1]))
    garment = Garment(folder) if folder else None
    motion = P.load_body_motion() if folder else None
    for (size, c), pixels in sorted(found.items()):
        print(f"size {size}, {COLUMNS[c]}: {sorted(pixels)}")
        if garment:
            body_frame = frames_for(motion, size)[c]
            base, over = garment.parts(motion, size, body_frame, d)
            for x, y in sorted(pixels):
                what = "clothing layer" if over.getpixel((x, y))[3] else "base" if base.getpixel((x, y))[3] else "body" if body_frame[d].getpixel((x, y))[3] else "empty"
                print(f"    ({x},{y}): {what}")
    print("coordinates are approximate (+-1px) on a downscaled image")


def stack(lower_folder, upper_folder, out, closed):
    lower, upper = Garment(lower_folder), Garment(upper_folder)
    motion, body = P.load_body_motion(), body_frames()
    colours = ((235, 230, 215), (200, 90, 110))
    scale = 4
    cell_size = 32 * scale
    frames = []
    for t in range(8):
        sheet = Image.new("RGB", (len(SIZES) * 2 * cell_size + 20, cell_size + 30), (25, 25, 32))
        draw = ImageDraw.Draw(sheet)
        draw.text((6, 4), f"walk {t + 1}: sizes 5-8, front and side", font=font(), fill=(230, 230, 230))
        for si, size in enumerate(SIZES):
            body_frame = motion[size]["walk"][t]
            for j, d in enumerate((0, 2)):
                cell = Image.new("RGBA", (32, 32), (70, 70, 90, 255))
                cell.alpha_composite(tint(body[d], SKIN))
                skin = tint(body_frame[d], SKIN)
                lower_base, lower_over = (tint(i, colours[0]) for i in lower.parts(motion, size, body_frame, d))
                upper_base, upper_over = (tint(i, colours[1]) for i in upper.parts(motion, size, body_frame, d))
                if closed:
                    lower_over = Image.new("RGBA", (32, 32))
                if d != 0:
                    for image in (skin, lower_base, lower_over, upper_base, upper_over):
                        cell.alpha_composite(image)
                else:
                    cell.alpha_composite(lower_base)
                    cell.alpha_composite(upper_base)
                    cell.alpha_composite(cut(cut(skin, alpha(lower_base)), alpha(upper_base)))
                    cell.alpha_composite(cut(lower_over, alpha(upper_base)))
                    cell.alpha_composite(upper_over)
                sheet.paste(cell.resize((cell_size, cell_size), Image.NEAREST).convert("RGB"), (10 + (si * 2 + j) * cell_size, 26))
        frames.append(sheet)
    frames[0].save(out, save_all=True, append_images=frames[1:], duration=150, loop=0)
    print(out)


def main():
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="command", required=True)
    g = sub.add_parser("grid")
    g.add_argument("folder")
    g.add_argument("out")
    g.add_argument("--dir", default="S", choices=DIRS)
    m = sub.add_parser("marks")
    m.add_argument("image")
    m.add_argument("--dir", default="S", choices=DIRS)
    m.add_argument("--folder")
    s = sub.add_parser("stack")
    s.add_argument("lower")
    s.add_argument("upper")
    s.add_argument("out")
    s.add_argument("--closed", action="store_true")
    args = parser.parse_args()
    if args.command == "grid":
        grid(args.folder, args.out, DIRS[args.dir])
    elif args.command == "marks":
        marks(args.image, DIRS[args.dir], args.folder)
    else:
        stack(args.lower, args.upper, args.out, args.closed)


if __name__ == "__main__":
    main()
