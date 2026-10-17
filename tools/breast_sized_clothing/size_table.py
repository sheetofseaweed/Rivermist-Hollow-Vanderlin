"""Picture of breast sizes 0-8 as the code maps them to sprites (body fm + pair_<N>_BEHIND/_ADJ, human offset -1).

Usage: python tools/breast_sized_clothing/size_table.py . "../anim_previews/breast_sizes_table.png"
"""
import sys
root = sys.argv[1]; out = sys.argv[2]
sys.path.insert(0, root + "/tools")
from dmi import Dmi
from PIL import Image, ImageDraw, ImageFont

def frames(p):
    return {s.name: [f.convert("RGBA") for f in s.frames] for s in Dmi.from_file(p).states if not s.movement}
body = frames(root + "/icons/roguetown/mob/bodies/f/fm.dmi")["fm"]
br = frames(root + "/modular_rmh/icons/mob/sprite_accessory/genitals/breasts.dmi")
skin = (232, 183, 150)
def tint(im):
    o = Image.new("RGBA", im.size); o.putdata([(p[0]*skin[0]//255, p[1]*skin[1]//255, p[2]*skin[2]//255, p[3]) for p in im.getdata()]); return o
def shift(im, dy=1):  # OFFSET_BREASTS (0,-1) for human female = 1 px down
    o = Image.new("RGBA", im.size, (0,0,0,0)); o.paste(im, (0, dy)); return o

rows = [
 (0, "Flat", "редактор", "BREAST_SIZE_FLAT", "скорость +2", (60,90,60)),
 (1, "Very Small", "редактор", "BREAST_SIZE_VERY_SMALL", "скорость +1", (60,90,60)),
 (2, "Small", "редактор", "BREAST_SIZE_SMALL", "—", (60,90,60)),
 (3, "Normal", "редактор (по умолч.)", "BREAST_SIZE_NORMAL", "—", (60,90,60)),
 (4, "Large", "редактор, макс.", "BREAST_SIZE_LARGE", "тел. +1, скор. −1", (60,90,60)),
 (5, "Enormous", "квирк Generous Figure", "BREAST_SIZE_ENORMOUS", "тел. +2, скор. −1", (130,90,40)),
 (6, "towering", "вайс Naturally Endowed", "organ_size = 6 (число)", "статы: см. ниже", (130,60,60)),
 (7, "gigantic", "только наполнение", "нет define", "статы не меняет", (70,70,110)),
 (8, "titanic", "только наполнение", "нет define", "статы не меняет", (70,70,110)),
]
dirs = [(0, "S"), (2, "E"), (1, "N")]
Z = 5; CW = 32*Z; PAD = 8
f = lambda s: ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", s)
fb = lambda s: ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", s)
mono = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 13)
colw = CW + PAD; head = 54; textblock = 150
W = 70 + colw*9 + PAD; H = head + textblock + (CW+PAD)*3 + 58
img = Image.new("RGBA", (W, H), (32,32,38,255)); d = ImageDraw.Draw(img)
d.text((PAD, 10), "Размеры груди: значение в коде → спрайт  (pair_<видимый размер>_ADJ / _BEHIND, breasts.dmi, сдвиг человека −1 px)", font=fb(18), fill="white")
for i, (n, name, how, define, stats, col) in enumerate(rows):
    x = 70 + i*colw
    d.rectangle([x, head, x+CW, head+textblock-6], fill=col)
    d.text((x+6, head+2), str(n), font=fb(30), fill="white")
    d.text((x+40, head+10), name, font=fb(17), fill="white")
    d.text((x+6, head+46), how, font=f(13), fill=(235,235,235))
    d.text((x+6, head+68), define, font=mono, fill=(255,230,150))
    d.text((x+6, head+88), stats, font=f(13), fill=(235,235,235))
    st = [s for s in (f"pair_{n}_ADJ", f"pair_{n}_BEHIND") if s in br]
    d.text((x+6, head+110), "\n".join(st), font=mono, fill=(170,220,255))
    for r, (di, lab) in enumerate(dirs):
        y = head + textblock + r*(CW+PAD)
        cell = Image.new("RGBA", (32,32), (90,90,105,255))
        if f"pair_{n}_BEHIND" in br: cell.alpha_composite(tint(shift(br[f"pair_{n}_BEHIND"][di])))
        cell.alpha_composite(tint(body[di]))
        if f"pair_{n}_ADJ" in br: cell.alpha_composite(tint(shift(br[f"pair_{n}_ADJ"][di])))
        img.alpha_composite(cell.resize((CW, CW), Image.NEAREST), (x, y))
for r, (di, lab) in enumerate(dirs):
    d.text((20, head+textblock+r*(CW+PAD)+CW//2-14), lab, font=fb(24), fill="white")
d.text((PAD, H-50), "Зелёные: редактор. Оранжевый: квирк Generous Figure. Красный: вайс Naturally Endowed (или наполнение). Синие: только наполнение (квирк Swelling Glands, до +3).\nУ вайса статы остаются от размера из редактора, а у 5-го пропадают совсем.", font=f(15), fill=(220,220,220))
img.save(out)
print(img.size)
