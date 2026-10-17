"""Adds "<state>_front" (south view only) and "<state>_side" (every view but south) copies of every "*_ADJ" state,
still and movement versions alike, to a body breast DMI. The game lifts the front view of the body breasts above
hands and sleeves (modular_rmh/code/modules/mob/body_breasts_front.dm) and used to cut these copies at runtime,
which cost tens of milliseconds per new frame.

Usage:
    python tools/breast_anim/south_split.py <file.dmi> [more files]   (in place; states already split are skipped)
build_breast_anims.py calls add_south_splits() before writing breasts_anim.dmi.
"""

import os
import sys

from PIL import Image

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from dmi import Dmi  # noqa: E402

SOUTH = 0  # BYOND direction order: south, north, east, west


def add_south_splits(dmi):
    """Appends the split copies for every *_ADJ state of dmi that does not have them yet; returns how many were added."""
    names = {(s.name, s.movement) for s in dmi.states}
    added = 0
    for state in list(dmi.states):
        if not state.name.endswith("_ADJ") or state.dirs != 4:
            continue
        for suffix, keep_south in (("_front", True), ("_side", False)):
            if (state.name + suffix, state.movement) in names:
                continue
            copy = dmi.state(state.name + suffix, dirs=4, movement=state.movement, loop=state.loop, rewind=state.rewind)
            for index, image in enumerate(state.frames):
                is_south = index % 4 == SOUTH
                copy.frames.append(image if is_south == keep_south else Image.new("RGBA", image.size, (0, 0, 0, 0)))
            copy.delays = list(state.delays)
            added += 1
    return added


def main(paths):
    for path in paths:
        dmi = Dmi.from_file(path)
        added = add_south_splits(dmi)
        if added:
            dmi.to_file(path)
        print(f"{path}: {added} split states added, {len(dmi.states)} states")


if __name__ == "__main__":
    main(sys.argv[1:])
