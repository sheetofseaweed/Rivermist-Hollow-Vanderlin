"""Picks existing frames (rest, walk f1-f8, run r1-r8 from breasts_anim.dmi) for the side (east ADJ) and back
(north BEHIND) views of the squeeze animation, matching each squeeze frame's vertical motion.

Usage: python tools/breast_anim/pick_squeeze_side_back.py
Prints the choice per size and view; draft_squeeze.py imports pick() to fill the side and back layers.
Motion is measured against the rest frame: mean top and bottom edge per column, in px (+ = down).
"""
import os
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from dmi import Dmi  # noqa: E402

ANIM = os.path.join(ROOT, "modular_rmh/icons/mob/sprite_accessory/genitals/breasts_anim.dmi")
CANDIDATES = ["rest"] + [f"f{i}" for i in range(1, 9)] + [f"r{i}" for i in range(1, 9)]
VIEWS = {"side": (2, "ADJ"), "back": (1, "BEHIND")}
# Per squeeze frame: (bottom target, top target, top weight). Lift moves the whole breast; drops keep the top pinned.
TARGETS = {
    "small": [(0, 0, 0.5), (-1, -1, 0.5), (-1, -1, 0.5), (1, 0, 0.5), (-1, 0, 0.3), (1, 0, 0.5)],
    "big": [(0, 0, 0.5), (-1, -1, 0.5), (-1, -1, 0.5), (2, 0, 0.5), (-1, 0, 0.3), (1, 0, 0.5)],
}

_states = None


def states():
    global _states
    if _states is None:
        _states = {s.name: s for s in Dmi.from_file(ANIM).states if not s.movement}
    return _states


def image(size, name, view):
    d, layer = VIEWS[view]
    state = f"pair_{size}_{layer}" if name == "rest" else f"pair_{size}_{name}_{layer}"
    return states()[state].frames[d].convert("RGBA")


def edges(im):
    a = im.split()[3].load()
    cols = {}
    for x in range(32):
        ys = [y for y in range(32) if a[x, y]]
        if ys:
            cols[x] = (ys[0], ys[-1])
    if not cols:
        return 0, 0
    return sum(t for t, _ in cols.values()) / len(cols), sum(b for _, b in cols.values()) / len(cols)


def pick(size, view):
    """Candidate names for the 6 squeeze frames; consecutive repeats avoided when an equal match exists."""
    rest_top, rest_bottom = edges(image(size, "rest", view))
    motion = {}
    for name in CANDIDATES:
        top, bottom = edges(image(size, name, view))
        motion[name] = (top - rest_top, bottom - rest_bottom)
    chosen = []
    for bottom_t, top_t, top_w in TARGETS["small" if size <= 5 else "big"]:
        def cost(name):
            top, bottom = motion[name]
            return abs(bottom - bottom_t) + top_w * abs(top - top_t)
        chosen.append(min(CANDIDATES, key=lambda n: (cost(n), n != (chosen[-1] if chosen else None), CANDIDATES.index(n))))
    return chosen, motion


if __name__ == "__main__":
    for size in (5, 6, 7, 8):
        for view in VIEWS:
            chosen, motion = pick(size, view)
            print(size, view, " ".join(f"{n}{tuple(round(v, 1) for v in motion[n])}" for n in chosen))
