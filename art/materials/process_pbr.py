"""Tint ambientCG CC0 maps to RAC photo colors and crop judge swatches."""
from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = Path(__file__).resolve().parent / "pbr_src"
OUT = Path(__file__).resolve().parent
SWATCH = OUT / "swatches"
PHOTO = ROOT / "reference" / "photos"

# Lifted albedo from inventory.json indoor samples (photos are underexposed).
SPECS = {
    "maple": {
        "src": "WoodFloor051",
        "rgb": (220, 196, 164),
        "rough": 0.18,
        "photo": "IMG_0332",
        "box": (0.42, 0.90, 0.55, 0.97),
    },
    "racquetball_wood": {
        "src": "WoodFloor062",
        "rgb": (228, 208, 176),
        "rough": 0.28,
        "photo": "IMG_0332",
        "box": (0.42, 0.90, 0.55, 0.97),
    },
    "terrazzo": {
        "src": "Terrazzo001",
        "rgb": (188, 178, 166),
        "rough": 0.16,
        "photo": "IMG_0314",
        "box": (0.10, 0.84, 0.22, 0.94),
    },
    "porcelain_tile": {
        "src": "Tiles002",
        "rgb": (186, 174, 160),
        "rough": 0.22,
        "photo": "IMG_0316",
        "box": (0.55, 0.86, 0.68, 0.94),
    },
    "carpet_tile": {
        "src": "Carpet008",
        "rgb": (68, 67, 66),
        "rough": 0.92,
        "photo": "IMG_0324",
        "box": (0.36, 0.78, 0.46, 0.90),
    },
    "rubber": {
        "src": "Rubber002",
        "rgb": (173, 164, 148),
        "rough": 0.88,
        "photo": "IMG_0318",
        "box": (0.55, 0.66, 0.64, 0.74),
    },
    "turf": {
        "src": "Grass001",
        "rgb": (77, 84, 47),
        "rough": 0.9,
        "photo": "IMG_0364",
        "box": (0.15, 0.72, 0.35, 0.86),
    },
    "ceramic_tile": {
        "src": "Tiles107",
        "rgb": (232, 224, 210),
        "rough": 0.2,
        "photo": "IMG_0379",
        "box": (0.04, 0.30, 0.14, 0.42),
    },
    "ceramic_floor_tile": {
        "src": "Tiles001",
        "rgb": (196, 180, 160),
        "rough": 0.28,
        "photo": "IMG_0378",
        "box": (0.04, 0.86, 0.16, 0.96),
    },
    "painted_cmu": {
        "src": "Bricks093",
        "rgb": (210, 206, 200),
        "rough": 0.72,
        "photo": "IMG_0314",
        "box": (0.05, 0.38, 0.14, 0.48),
    },
    "brick": {
        "src": "Bricks059",
        "rgb": (120, 84, 68),
        "rough": 0.88,
        "photo": "IMG_0349",
        "box": (0.20, 0.40, 0.40, 0.62),
    },
    "gypsum": {
        "src": "Plaster003",
        "rgb": (220, 220, 222),
        "rough": 0.82,
        "photo": "IMG_0314",
        "box": (0.86, 0.32, 0.96, 0.44),
    },
    "metal_panel": {
        "src": "Metal032",
        "rgb": (145, 150, 153),
        "rough": 0.38,
        "photo": "IMG_0359",
        "box": (0.05, 0.42, 0.28, 0.52),
    },
    "precast": {
        "src": "Concrete034",
        "rgb": (184, 170, 156),
        "rough": 0.78,
        "photo": "IMG_0349",
        "box": (0.12, 0.30, 0.28, 0.36),
    },
    "acoustic_ceiling": {
        "src": "Plaster001",
        "rgb": (232, 230, 226),
        "rough": 0.94,
        "photo": "IMG_0327",
        "box": (0.20, 0.02, 0.40, 0.12),
    },
    "mosaic_green": {
        "src": "Tiles023",
        "rgb": (168, 176, 162),
        "rough": 0.22,
        "photo": "IMG_0340",
        "box": (0.40, 0.40, 0.55, 0.55),
    },
    "sealed_concrete": {
        "src": "Concrete034",
        "rgb": (184, 180, 172),
        "rough": 0.36,
        "photo": "IMG_0365",
        "box": (0.20, 0.78, 0.36, 0.88),
    },
    "vinyl": {
        "src": "Tiles002",
        "rgb": (184, 176, 164),
        "rough": 0.4,
        "photo": "IMG_0316",
        "box": (0.55, 0.86, 0.68, 0.94),
    },
    "steel": {
        "src": "Metal032",
        "rgb": (48, 50, 52),
        "rough": 0.45,
        "photo": "IMG_0332",
        "box": (0.40, 0.04, 0.60, 0.12),
    },
    "mullion_aluminum": {
        "src": "Metal032",
        "rgb": (168, 172, 176),
        "rough": 0.32,
        "photo": "IMG_0368",
        "box": (0.48, 0.20, 0.58, 0.40),
    },
    "stainless": {
        "src": "Metal021",
        "rgb": (180, 184, 186),
        "rough": 0.22,
        "photo": "IMG_0329",
        "box": (0.70, 0.40, 0.80, 0.50),
    },
    "door_wood": {
        "src": "Wood051",
        "rgb": (122, 87, 48),
        "rough": 0.55,
        "photo": "IMG_0329",
        "box": (0.74, 0.50, 0.88, 0.58),
    },
    "door_paint": {
        "src": "Paint002",
        "rgb": (76, 81, 86),
        "rough": 0.5,
        "photo": "IMG_0378",
        "box": (0.04, 0.50, 0.14, 0.62),
    },
    "wood_cap_rail": {
        "src": "Wood051",
        "rgb": (58, 48, 40),
        "rough": 0.5,
        "photo": "IMG_0369",
        "box": (0.20, 0.55, 0.40, 0.62),
    },
    "court_green_paint": {
        "src": "Paint001",
        "rgb": (28, 70, 40),
        "rough": 0.18,
        "photo": "IMG_0334",
        "box": (0.55, 0.80, 0.62, 0.86),
    },
    "court_gold_paint": {
        "src": "Paint002",
        "rgb": (214, 172, 44),
        "rough": 0.2,
        "photo": "IMG_0332",
        "box": (0.17, 0.55, 0.21, 0.62),
    },
    "bleacher_green": {
        "src": "Paint001",
        "rgb": (30, 35, 31),
        "rough": 0.55,
        "photo": "IMG_0332",
        "box": (0.03, 0.55, 0.08, 0.62),
    },
    "bleacher_gold": {
        "src": "Paint002",
        "rgb": (160, 108, 32),
        "rough": 0.5,
        "photo": "IMG_0332",
        "box": (0.17, 0.55, 0.21, 0.62),
    },
    "sign_paint": {
        "src": "Paint001",
        "rgb": (0, 70, 36),
        "rough": 0.4,
        "photo": "IMG_0339",
        "box": (0.40, 0.20, 0.55, 0.30),
    },
}


def find_map(folder: Path, kind: str) -> Path:
    for p in folder.iterdir():
        name = p.name.lower()
        if kind == "color" and "_color." in name:
            return p
        if kind == "normal" and "_normalgl." in name:
            return p
        if kind == "roughness" and "_roughness." in name:
            return p
    raise FileNotFoundError(f"{folder} missing {kind}")


def tint(arr: np.ndarray, target: tuple[int, int, int]) -> np.ndarray:
    a = arr.astype(np.float32)
    mean = np.maximum(a.reshape(-1, 3).mean(axis=0), 8.0)
    t = np.array(target, dtype=np.float32)
    scaled = a * (t / mean)
    # Keep grain, pull mean onto the RAC sample.
    out = scaled * 0.55 + (a / mean) * t * 0.45
    return np.clip(np.rint(out), 0, 255).astype(np.uint8)


def roughness_map(path: Path, target: float) -> np.ndarray:
    a = np.array(Image.open(path).convert("L"), dtype=np.float32)
    mean = max(float(a.mean()), 8.0)
    out = a * (target * 255.0 / mean)
    return np.clip(np.rint(out), 0, 255).astype(np.uint8)


def crop_swatch(name: str, spec: dict) -> None:
    photo = spec.get("photo")
    box = spec.get("box")
    if not photo or not box:
        return
    path = PHOTO / f"{photo}.jpg"
    if not path.exists():
        path = PHOTO / f"{photo}.JPG"
    if not path.exists():
        print("missing photo", photo)
        return
    im = Image.open(path).convert("RGB")
    w, h = im.size
    x0, y0, x1, y1 = box
    crop = im.crop((int(x0 * w), int(y0 * h), int(x1 * w), int(y1 * h)))
    crop = crop.resize((256, 256), Image.Resampling.LANCZOS)
    crop.save(SWATCH / f"{name}.jpg", quality=90)


def main() -> None:
    SWATCH.mkdir(parents=True, exist_ok=True)
    (OUT / "pbr").mkdir(exist_ok=True)
    catalog = {}
    for name, spec in SPECS.items():
        folder = SRC / spec["src"]
        color = np.array(Image.open(find_map(folder, "color")).convert("RGB"))
        color = tint(color, spec["rgb"])
        normal = Image.open(find_map(folder, "normal")).convert("RGB")
        rough = roughness_map(find_map(folder, "roughness"), spec["rough"])
        cpath = OUT / "pbr" / f"{name}_color.png"
        npath = OUT / "pbr" / f"{name}_normal.png"
        rpath = OUT / "pbr" / f"{name}_roughness.png"
        Image.fromarray(color).save(cpath)
        normal.save(npath)
        Image.fromarray(rough).save(rpath)
        crop_swatch(name, spec)
        catalog[name] = {
            "source": f"ambientCG {spec['src']} CC0",
            "color": str(cpath.relative_to(ROOT)).replace("\\", "/"),
            "normal": str(npath.relative_to(ROOT)).replace("\\", "/"),
            "roughness": str(rpath.relative_to(ROOT)).replace("\\", "/"),
            "rgb": list(spec["rgb"]),
            "rough": spec["rough"],
            "photo": spec.get("photo"),
        }
        print(name, "ok", spec["src"])
    (OUT / "pbr" / "catalog.json").write_text(json.dumps(catalog, indent=2), encoding="utf-8")
    print("wrote", len(catalog), "materials")


if __name__ == "__main__":
    main()
