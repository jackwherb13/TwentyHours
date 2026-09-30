"""Write close-up captures of each tinted RAC color map."""
from __future__ import annotations

import re
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
LUAU = ROOT / "src" / "ReplicatedStorage" / "RAC" / "Materials.luau"
OUT = ROOT / "verification" / "materials" / "captures"
SW = ROOT / "art" / "materials" / "swatches"
OUT.mkdir(parents=True, exist_ok=True)

KEYS = [
    "maple",
    "racquetball_wood",
    "terrazzo",
    "porcelain_tile",
    "carpet_tile",
    "rubber",
    "turf",
    "sealed_concrete",
    "ceramic_tile",
    "ceramic_floor_tile",
    "vinyl",
    "painted_cmu",
    "brick",
    "gypsum",
    "metal_panel",
    "precast",
    "acoustic_ceiling",
    "mosaic_green",
    "steel",
    "mullion_aluminum",
    "stainless",
    "door_wood",
    "door_paint",
    "wood_cap_rail",
    "court_green_paint",
    "court_gold_paint",
    "bleacher_green",
    "bleacher_gold",
    "sign_paint",
    "glass",
]


def main() -> None:
    text = LUAU.read_text(encoding="utf-8")
    for key in KEYS:
        m = re.search(
            rf"\n\t{key} = \{{.*?\n\t\tcolor = Color3\.fromRGB\((\d+), (\d+), (\d+)\),",
            text,
            re.S,
        )
        if not m:
            print("no rgb", key)
            continue
        rgb = np.array([int(m.group(1)), int(m.group(2)), int(m.group(3))], np.float32)
        tm = re.search(rf"\n\t{key} = \{{.*?\n\t\ttexture = ([^\n]+)", text, re.S)
        arr = np.zeros((1024, 1024, 3), np.float32)
        arr[:] = rgb
        if key == "glass":
            import sys

            sys.path.insert(0, str(Path(__file__).resolve().parent))
            from iterate_maps import glass_preview

            arr = glass_preview()
        elif tm:
            raw = tm.group(1).strip().rstrip(",")
            if raw.startswith('"'):
                path = ROOT / raw.strip('"')
                if path.exists():
                    src = np.array(Image.open(path).convert("RGB"), dtype=np.float32)
                    arr = src
        im = Image.fromarray(np.rint(arr).astype(np.uint8)).resize((900, 900), Image.Resampling.LANCZOS)
        im.save(OUT / f"{key}.png")
        print(key, "ok")


if __name__ == "__main__":
    main()
