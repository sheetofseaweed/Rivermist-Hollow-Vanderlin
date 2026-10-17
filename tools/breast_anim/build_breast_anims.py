"""Builds the animated body breast icon (breasts_anim.dmi) from the art sources in tools/breast_anim/src.

Usage:
    python tools/breast_anim/build_breast_anims.py

Output states, for the "pair" accessory (states are "<icon_state>_<size><suffix>_<LAYER>"):
    pair_<N>_<LAYER>           still frame from breasts.dmi; sizes in ANIM_SIZES also get the walk
                               cycle as a BYOND movement state, so it plays whenever the mob moves
    pair_<N>_run_<LAYER>       same still frame, run cycle as the movement state (used while sprinting)
    pair_<N>_r<K>_<LAYER>      still frame K (1-8) of the run cycle, for interactions
    pair_<N>_f<K>_<LAYER>      still frame K (1-8) of the walk cycle; emotes step through these from DM
                               (GLOB.breast_emote_anim_frames in breast_animation.dm), because BYOND does not
                               restart a play-once animation on an overlay
    pair_<N>_s<K>_<LAYER>      still frame K of the squeeze animation (pressing together, release, two bounces),
                               stepped from DM like the emotes
Sizes without animation art are copied as still states only, so the file fully replaces breasts.dmi.

Sources:
    src/walk.dmi        "pair_<N>_<LAYER>" still + movement states, drawn 1px lower than the game: shifted up
    src/run.aseprite    groups "<N>", layers "<N> front" (south ADJ), "<N> side" (east ADJ, west is mirrored),
                        "<N> back" (north BEHIND); 8 frames, all motion (no rest pose). Exported with the
                        Aseprite CLI (set ASEPRITE to its path if it is not the default below).
    src/squeeze.aseprite same layout, 6 frames (the artist's copy lives in "breasts files/anim/squeeze.aseprite").
                        Extra layers (e.g. "body ref") are ignored.
Timings are in BYOND ticks (1 tick = 0.1 s).
"""

import json
import os
import subprocess
import sys
import tempfile

from PIL import Image, ImageOps

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from dmi import Dmi  # noqa: E402
from south_split import add_south_splits  # noqa: E402

SRC = os.path.join(os.path.dirname(__file__), "src")
BASE = os.path.join(ROOT, "modular_rmh/icons/mob/sprite_accessory/genitals/breasts.dmi")
OUT = os.path.join(ROOT, "modular_rmh/icons/mob/sprite_accessory/genitals/breasts_anim.dmi")
ASEPRITE = os.environ.get("ASEPRITE", r"G:\SteamLibrary\steamapps\common\Aseprite\Aseprite.exe")

ANIM_SIZES = (5, 6, 7, 8)
LAYERS = ("ADJ", "BEHIND")
WALK_SHIFT_Y = -1
WALK_DELAY = 1
RUN_DELAY = 1
DIRS = 4  # BYOND order: south, north, east, west
SOUTH, NORTH, EAST, WEST = range(4)


def blank():
    return Image.new("RGBA", (32, 32), (0, 0, 0, 0))


def shifted(image, dy):
    out = blank()
    out.paste(image, (0, dy))
    return out


def add_state(dmi, name, frames, *, movement=False, delay=1, loop=0):
    """frames: list of [south, north, east, west] images."""
    state = dmi.state(name, dirs=DIRS, loop=loop, movement=movement)
    for frame in frames:
        state.frames.extend(frame)
        state.delays.append(delay)
    return state


def state_frames(state):
    return [state.frames[i:i + state.dirs] for i in range(0, len(state.frames), state.dirs)]


def load_walk():
    walk = {}
    for state in Dmi.from_file(os.path.join(SRC, "walk.dmi")).states:
        if state.movement:
            walk[state.name] = [[shifted(img.convert("RGBA"), WALK_SHIFT_Y) for img in frame] for frame in state_frames(state)]
    return walk


def load_run(source="run.aseprite"):
    """Frames of an Aseprite animation source (layout of src/run.aseprite) as pair_<N>_<LAYER> -> frames."""
    with tempfile.TemporaryDirectory() as tmp:
        sheet = os.path.join(tmp, "sheet.png")
        data = os.path.join(tmp, "sheet.json")
        subprocess.run([
            ASEPRITE, "-b", "--all-layers", "--split-layers", "--list-layers",
            os.path.join(SRC, source),
            "--data", data, "--format", "json-array", "--filename-format", "{layer}|{frame}",
            "--sheet", sheet, "--sheet-type", "rows",
        ], check=True, capture_output=True)
        info = json.load(open(data))
        image = Image.open(sheet).convert("RGBA")
    opacity = {layer["name"]: layer.get("opacity", 255) for layer in info["meta"]["layers"]}
    for layer, value in opacity.items():
        if value < 255:
            # Layer opacity is an editor setting, not part of the art: export at full opacity.
            print(f"warning: layer {layer!r} has opacity {value}, exporting at full opacity")
    cells = {}
    for frame in info["frames"]:
        layer, index = frame["filename"].split("|")
        rect = frame["frame"]
        cell = image.crop((rect["x"], rect["y"], rect["x"] + 32, rect["y"] + 32))
        if opacity.get(layer, 255) < 255:
            cell.putalpha(cell.split()[3].point(lambda a: 255 if a else 0))
        cells[(layer, int(index))] = cell
    frame_count = 1 + max(index for layer, index in cells if layer.split(" ")[0].isdigit())
    run = {}
    for size in ANIM_SIZES:
        adj, behind = [], []
        for index in range(frame_count):
            front = cells[(f"{size} front", index)]
            side = cells[(f"{size} side", index)]
            back = cells[(f"{size} back", index)]
            adj.append([front, blank(), side, ImageOps.mirror(side)])
            behind.append([blank(), back, blank(), blank()])
        run[f"pair_{size}_ADJ"] = adj
        run[f"pair_{size}_BEHIND"] = behind
    return run


def main():
    base = {state.name: state for state in Dmi.from_file(BASE).states}
    walk = load_walk()
    run = load_run()
    squeeze = load_run("squeeze.aseprite")
    out = Dmi(32, 32)
    for name, state in base.items():
        if not name.startswith("pair_"):
            continue
        still = [[img.convert("RGBA") for img in frame] for frame in state_frames(state)]
        size = int(name.split("_")[1])
        layer = name.rsplit("_", 1)[1]
        add_state(out, name, still)
        if size not in ANIM_SIZES:
            continue
        add_state(out, name, walk[name], movement=True, delay=WALK_DELAY)
        run_name = f"pair_{size}_run_{layer}"
        add_state(out, run_name, still)
        add_state(out, run_name, run[name], movement=True, delay=RUN_DELAY)
        for index, frame in enumerate(walk[name], 1):
            add_state(out, f"pair_{size}_f{index}_{layer}", [frame])
        for index, frame in enumerate(run[name], 1):
            add_state(out, f"pair_{size}_r{index}_{layer}", [frame])
        for index, frame in enumerate(squeeze[name], 1):
            add_state(out, f"pair_{size}_s{index}_{layer}", [frame])
    # "_front"/"_side" copies of the ADJ states, so the game never splits them at runtime (south_split.py).
    add_south_splits(out)
    out.to_file(OUT)
    print(f"{OUT}: {len(out.states)} states")


if __name__ == "__main__":
    main()
