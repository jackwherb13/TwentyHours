"""Rebuild RAC-scale maps that judges rejected, and recrop people-free swatches."""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent / "pbr"
SW = Path(__file__).resolve().parent / "swatches"
PHOTO = ROOT / "reference" / "photos"
SIZE = 1024

SWATCHES = {
    "maple": ("IMG_0332", (0.42, 0.90, 0.55, 0.97)),
    "racquetball_wood": ("IMG_0332", (0.42, 0.90, 0.55, 0.97)),
    "court_green_paint": ("IMG_0334", (0.55, 0.80, 0.62, 0.86)),
    "court_gold_paint": ("IMG_0332", (0.16, 0.54, 0.22, 0.62)),
    "terrazzo": ("IMG_0339", (0.28, 0.72, 0.52, 0.92)),
    "porcelain_tile": ("IMG_0316", (0.42, 0.70, 0.72, 0.92)),
    "carpet_tile": ("IMG_0327", (0.18, 0.84, 0.32, 0.96)),
    "rubber": ("IMG_0318", (0.48, 0.60, 0.70, 0.78)),
    "turf": ("IMG_0364", (0.15, 0.72, 0.35, 0.86)),
    "ceramic_tile": ("IMG_0379", (0.04, 0.30, 0.14, 0.42)),
    "ceramic_floor_tile": ("IMG_0378", (0.04, 0.86, 0.16, 0.96)),
    "vinyl": ("IMG_0316", (0.42, 0.70, 0.72, 0.92)),
    "sealed_concrete": ("IMG_0365", (0.20, 0.78, 0.36, 0.88)),
    "painted_cmu": ("IMG_0314", (0.05, 0.38, 0.14, 0.48)),
    "gypsum": ("IMG_0339", (0.60, 0.38, 0.72, 0.55)),
    "brick": ("IMG_0339", (0.80, 0.36, 0.96, 0.58)),
    "metal_panel": ("IMG_0359", (0.05, 0.42, 0.28, 0.52)),
    "precast": ("IMG_0349", (0.12, 0.30, 0.28, 0.36)),
    "acoustic_ceiling": ("IMG_0339", (0.22, 0.00, 0.52, 0.12)),
    "steel": ("IMG_0332", (0.40, 0.04, 0.60, 0.12)),
    "mullion_aluminum": ("IMG_0316", (0.70, 0.38, 0.78, 0.70)),
    "door_wood": ("IMG_0327", (0.30, 0.50, 0.40, 0.68)),
    "door_paint": ("IMG_0339", (0.38, 0.48, 0.48, 0.62)),
    "stainless": ("IMG_0369", (0.08, 0.34, 0.18, 0.42)),
    "mosaic_green": ("IMG_0340", (0.40, 0.40, 0.55, 0.55)),
    "wood_cap_rail": ("IMG_0369", (0.02, 0.29, 0.16, 0.335)),
    "bleacher_green": ("IMG_0332", (0.03, 0.55, 0.08, 0.62)),
    "bleacher_gold": ("IMG_0332", (0.16, 0.54, 0.22, 0.62)),
    "sign_paint": ("IMG_0316", (0.18, 0.48, 0.34, 0.62)),
}


def save_rgb(name: str, arr: np.ndarray) -> None:
    Image.fromarray(np.clip(np.rint(arr), 0, 255).astype(np.uint8)).save(OUT / name)


def save_grey(name: str, arr: np.ndarray) -> None:
    Image.fromarray(np.clip(np.rint(arr), 0, 255).astype(np.uint8)).save(OUT / name)


def height_to_normal(height: np.ndarray, strength: float = 8.0) -> np.ndarray:
    h = height.astype(np.float32)
    dx = np.roll(h, -1, axis=1) - np.roll(h, 1, axis=1)
    dy = np.roll(h, -1, axis=0) - np.roll(h, 1, axis=0)
    nx = -dx * strength
    ny = -dy * strength
    nz = np.ones_like(h)
    length = np.sqrt(nx * nx + ny * ny + nz * nz)
    n = np.stack((nx / length, ny / length, nz / length), axis=-1)
    return (n * 0.5 + 0.5) * 255.0


def crop_swatches() -> None:
    SW.mkdir(parents=True, exist_ok=True)
    for name, (photo, box) in SWATCHES.items():
        path = PHOTO / f"{photo}.jpg"
        if not path.exists():
            path = PHOTO / f"{photo}.JPG"
        if not path.exists():
            print("missing photo", photo)
            continue
        im = Image.open(path).convert("RGB")
        w, h = im.size
        x0, y0, x1, y1 = box
        crop = im.crop((int(x0 * w), int(y0 * h), int(x1 * w), int(y1 * h)))
        if min(crop.size) < 8:
            print("tiny crop", name)
            continue
        crop = crop.resize((256, 256), Image.Resampling.LANCZOS)
        crop.save(SW / f"{name}.jpg", quality=92)
        print("swatch", name, crop.size)


def _fill_rect(img, height, rough, x0, y0, x1, y1, color, rng, tile_std):
    x0 = max(0, x0)
    y0 = max(0, y0)
    x1 = min(SIZE, x1)
    y1 = min(SIZE, y1)
    if x1 <= x0 or y1 <= y0:
        return
    tile = np.zeros((y1 - y0, x1 - x0, 3), np.float32)
    tile[:] = color
    tile += rng.normal(0, tile_std, tile.shape)
    img[y0:y1, x0:x1] = tile
    height[y0:y1, x0:x1] = 1.0
    rough[y0:y1, x0:x1] = 0.22 * 255.0


def porcelain_12x24(target, grout_rgb, grout_px=4) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    # 12x24 in running bond. Map is 4 ft: 4 courses of 12" x 24" boards, half-tile offset.
    rng = np.random.default_rng(21)
    t = np.array(target, np.float32)
    g = np.array(grout_rgb, np.float32)
    img = np.zeros((SIZE, SIZE, 3), np.float32)
    img[:] = g
    height = np.full((SIZE, SIZE), 0.18, np.float32)
    rough = np.full((SIZE, SIZE), 0.55 * 255.0, np.float32)
    tile_w, tile_h = 512, 256
    rows = SIZE // tile_h
    for r in range(rows):
        off = (tile_w // 2) if r % 2 else 0
        y0 = r * tile_h + grout_px
        y1 = (r + 1) * tile_h - grout_px
        x = -off
        while x < SIZE:
            if off and x > 0 and x + tile_w > SIZE:
                break
            jitter = rng.normal(0, 1.4, 3)
            color = np.clip(t + jitter, 0, 255)
            x0 = x + grout_px
            x1 = x + tile_w - grout_px
            if x0 < 0:
                _fill_rect(img, height, rough, SIZE + x0, y0, SIZE, y1, color, rng, 1.6)
                _fill_rect(img, height, rough, 0, y0, x1, y1, color, rng, 1.6)
            else:
                _fill_rect(img, height, rough, x0, y0, min(SIZE, x1), y1, color, rng, 1.6)
            x += tile_w
    return np.clip(img, 0, 255), height_to_normal(height, 5.0), rough


def acoustic_act(target) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    rng = np.random.default_rng(9)
    t = np.array(target, np.float32)
    img = np.zeros((SIZE, SIZE, 3), np.float32)
    img[:] = t
    img += rng.normal(0, 1.8, img.shape)
    # Fissured ACT: sparse dark pinholes.
    ys = rng.integers(0, SIZE, 18000)
    xs = rng.integers(0, SIZE, 18000)
    img[ys, xs] *= 0.78
    height = np.ones((SIZE, SIZE), np.float32)
    height[ys, xs] = 0.55
    # Tile bevel (T-bar is a separate part).
    edge = 10
    for i in range(edge):
        k = 0.92 + 0.08 * (i / edge)
        img[i, :] *= k
        img[-i - 1, :] *= k
        img[:, i] *= k
        img[:, -i - 1] *= k
        height[i, :] = 0.7 + 0.3 * (i / edge)
        height[-i - 1, :] = 0.7 + 0.3 * (i / edge)
        height[:, i] = np.minimum(height[:, i], 0.7 + 0.3 * (i / edge))
        height[:, -i - 1] = np.minimum(height[:, -i - 1], 0.7 + 0.3 * (i / edge))
    rough = np.full((SIZE, SIZE), 0.95 * 255.0, np.float32)
    return np.clip(img, 0, 255), height_to_normal(height, 4.0), rough


def brushed_metal(target, rough_v: float) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    rng = np.random.default_rng(4)
    t = np.array(target, np.float32)
    img = np.zeros((SIZE, SIZE, 3), np.float32)
    img[:] = t
    streaks = rng.normal(0, 1.0, (SIZE, 1, 1))
    img += np.repeat(np.repeat(streaks, SIZE, axis=1), 3, axis=2) * 5.0
    grey = rng.normal(0, 1.0, (SIZE, SIZE, 1))
    img += np.repeat(grey, 3, axis=2) * 1.4
    height = 0.5 + rng.normal(0, 0.02, (SIZE, SIZE)).astype(np.float32)
    height += np.repeat(rng.normal(0, 0.015, (SIZE, 1)), SIZE, axis=1)
    rough = np.full((SIZE, SIZE), rough_v * 255.0, np.float32)
    rough += rng.normal(0, 4.0, rough.shape)
    return np.clip(img, 0, 255), height_to_normal(height, 3.0), np.clip(rough, 0, 255)


def artificial_turf(target) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    rng = np.random.default_rng(13)
    t = np.array(target, np.float32)
    img = np.zeros((SIZE, SIZE, 3), np.float32)
    img[:] = t
    for _ in range(3):
        img += rng.normal(0, 5.0, img.shape)
    # Directional yarn.
    for x in range(SIZE):
        img[:, x] += (x % 5 - 2) * 1.8
    # Occasional darker thatch, no leaves.
    ys = rng.integers(0, SIZE, 4000)
    xs = rng.integers(0, SIZE, 4000)
    img[ys, xs] *= 0.85
    height = 0.55 + rng.random((SIZE, SIZE)).astype(np.float32) * 0.45
    rough = np.full((SIZE, SIZE), 0.90 * 255.0, np.float32)
    return np.clip(img, 0, 255), height_to_normal(height, 5.0), rough


def flatten_existing(name: str, mix: float, target) -> None:
    arr = np.array(Image.open(OUT / f"{name}_color.png").convert("RGB"), dtype=np.float32)
    t = np.array(target, np.float32)
    mean = np.maximum(arr.reshape(-1, 3).mean(axis=0), 8.0)
    scaled = arr * (t / mean)
    out = scaled * (1 - mix) + t * mix
    save_rgb(f"{name}_color.png", out)


def paint_solid(target, std: float = 1.2) -> np.ndarray:
    rng = np.random.default_rng(11)
    img = np.zeros((SIZE, SIZE, 3), np.float32)
    img[:] = target
    img += rng.normal(0, std, img.shape)
    return np.clip(img, 0, 255)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    crop_swatches()

    color, normal, rough = porcelain_12x24((204, 198, 188), (148, 144, 138), grout_px=3)
    save_rgb("porcelain_tile_color.png", color)
    save_rgb("porcelain_tile_normal.png", normal)
    save_grey("porcelain_tile_roughness.png", rough)

    color, normal, rough = porcelain_12x24((196, 188, 176), (150, 146, 140), grout_px=3)
    save_rgb("vinyl_color.png", color)
    save_rgb("vinyl_normal.png", normal)
    save_grey("vinyl_roughness.png", np.clip(rough + 40, 0, 255))

    color, normal, rough = acoustic_act((226, 224, 218))
    save_rgb("acoustic_ceiling_color.png", color)
    save_rgb("acoustic_ceiling_normal.png", normal)
    save_grey("acoustic_ceiling_roughness.png", rough)

    color, normal, rough = brushed_metal((180, 184, 186), 0.22)
    save_rgb("stainless_color.png", color)
    save_rgb("stainless_normal.png", normal)
    save_grey("stainless_roughness.png", rough)

    color, normal, rough = brushed_metal((48, 50, 54), 0.32)
    save_rgb("mullion_aluminum_color.png", color)
    save_rgb("mullion_aluminum_normal.png", normal)
    save_grey("mullion_aluminum_roughness.png", rough)

    color, normal, rough = artificial_turf((77, 84, 47))
    save_rgb("turf_color.png", color)
    save_rgb("turf_normal.png", normal)
    save_grey("turf_roughness.png", rough)

    flatten_existing("terrazzo", 0.35, (198, 190, 178))
    save_rgb("sign_paint_color.png", paint_solid((0, 70, 36), 1.0))
    save_rgb("court_green_paint_color.png", paint_solid((28, 70, 40), 1.0))
    save_rgb("court_gold_paint_color.png", paint_solid((214, 172, 44), 1.0))
    save_rgb("bleacher_green_color.png", paint_solid((30, 35, 31), 1.0))
    save_rgb("bleacher_gold_color.png", paint_solid((160, 108, 32), 1.0))
    save_rgb("door_paint_color.png", paint_solid((76, 81, 86), 1.4))
    print("refined maps")


if __name__ == "__main__":
    main()
