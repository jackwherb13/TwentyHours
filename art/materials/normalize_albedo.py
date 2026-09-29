"""Make color maps modulate Part.Color instead of baking the tint twice."""
from __future__ import annotations

import re
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
LUAU = ROOT / "src" / "ReplicatedStorage" / "RAC" / "Materials.luau"
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
]

text = LUAU.read_text(encoding="utf-8")
for key in KEYS:
    m = re.search(
        rf"{key} = \{{.*?color = Color3\.fromRGB\((\d+), (\d+), (\d+)\),.*?texture = \"([^\"]+)\"",
        text,
        re.S,
    )
    if not m:
        print("no block", key)
        continue
    r, g, b, texture = m.group(1), m.group(2), m.group(3), m.group(4)
    path = ROOT / texture.replace("\\", "/")
    arr = np.array(Image.open(path).convert("RGB"), dtype=np.float32)
    t = np.maximum(np.array([int(r), int(g), int(b)], dtype=np.float32), 8.0)
    out = np.clip(arr * (255.0 / t), 0, 255)
    Image.fromarray(np.rint(out).astype(np.uint8)).save(path)
    print(key, "mean", np.rint(out.reshape(-1, 3).mean(0)).astype(int).tolist())
