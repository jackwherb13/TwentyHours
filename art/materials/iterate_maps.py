"""Generate RAC-scale maps and material-only swatches from the judge notes."""
from __future__ import annotations

import re
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent / "pbr"
SW = Path(__file__).resolve().parent / "swatches"
SRC = Path(__file__).resolve().parent / "pbr_src"
PHOTO = ROOT / "reference" / "photos"
LUAU = ROOT / "src" / "ReplicatedStorage" / "RAC" / "Materials.luau"
CAPTURE = ROOT / "verification" / "materials" / "captures"
PAIRS = ROOT / "verification" / "materials" / "pairs"
SIZE = 1024

# Template RGB — Part.Color fallback and pair renderer tint.
COLORS = {
    "maple": (210, 186, 158),
    "racquetball_wood": (210, 186, 158),
    "terrazzo": (140, 132, 122),
    "porcelain_tile": (176, 166, 154),
    "carpet_tile": (78, 76, 74),
    "rubber": (184, 176, 160),
    "turf": (80, 82, 50),
    "sealed_concrete": (208, 198, 180),
    "ceramic_tile": (168, 154, 128),
    "ceramic_floor_tile": (168, 158, 144),
    "vinyl": (176, 166, 154),
    "painted_cmu": (200, 196, 188),
    "brick": (110, 68, 56),
    "gypsum": (200, 200, 202),
    "glass": (40, 48, 52),
    "metal_panel": (136, 142, 150),
    "precast": (178, 167, 157),
    "acoustic_ceiling": (186, 184, 178),
    "mosaic_green": (134, 138, 128),
    "steel": (208, 204, 198),
    "mullion_aluminum": (22, 22, 24),
    "stainless": (196, 196, 192),
    "door_wood": (198, 188, 177),
    "door_paint": (100, 98, 86),
    "wood_cap_rail": (186, 160, 120),
    "court_green_paint": (22, 52, 36),
    "court_gold_paint": (198, 176, 80),
    "bleacher_green": (32, 42, 38),
    "bleacher_gold": (196, 148, 42),
    "sign_paint": (50, 62, 56),
}

ROUGH = {
    "maple": 0.14,
    "racquetball_wood": 0.22,
    "terrazzo": 0.08,
    "porcelain_tile": 0.20,
    "carpet_tile": 0.94,
    "rubber": 0.16,
    "turf": 0.90,
    "sealed_concrete": 0.30,
    "ceramic_tile": 0.16,
    "ceramic_floor_tile": 0.26,
    "vinyl": 0.28,
    "painted_cmu": 0.72,
    "brick": 0.88,
    "gypsum": 0.80,
    "glass": 0.06,
    "metal_panel": 0.36,
    "precast": 0.78,
    "acoustic_ceiling": 0.94,
    "mosaic_green": 0.20,
    "steel": 0.50,
    "mullion_aluminum": 0.28,
    "stainless": 0.18,
    "door_wood": 0.42,
    "door_paint": 0.38,
    "wood_cap_rail": 0.36,
    "court_green_paint": 0.14,
    "court_gold_paint": 0.16,
    "bleacher_green": 0.48,
    "bleacher_gold": 0.42,
    "sign_paint": 0.36,
}

# Tight material-only crops. No people, no whole assemblies.
SWATCHES = {
    "maple": ("IMG_0332", (0.38, 0.84, 0.82, 0.98)),
    "racquetball_wood": ("IMG_0332", (0.38, 0.84, 0.82, 0.98)),
    "court_green_paint": ("IMG_0334", (0.58, 0.82, 0.70, 0.90)),
    "court_gold_paint": ("IMG_0334", (0.476, 0.698, 0.489, 0.708)),
    "terrazzo": ("IMG_0314", (0.32, 0.72, 0.55, 0.90)),
    "porcelain_tile": ("IMG_0316", (0.42, 0.74, 0.68, 0.92)),
    "carpet_tile": ("IMG_0324", (0.32, 0.72, 0.55, 0.94)),
    "rubber": ("IMG_0318", (0.48, 0.64, 0.64, 0.72)),
    "turf": ("IMG_0364", (0.18, 0.78, 0.52, 0.94)),
    "ceramic_tile": ("IMG_0379", (0.16, 0.36, 0.32, 0.50)),
    "ceramic_floor_tile": ("IMG_0378", (0.10, 0.86, 0.28, 0.97)),
    "vinyl": ("IMG_0316", (0.42, 0.74, 0.68, 0.92)),
    "sealed_concrete": ("IMG_0365", (0.18, 0.80, 0.48, 0.94)),
    "painted_cmu": ("IMG_0314", (0.02, 0.30, 0.16, 0.52)),
    "gypsum": ("IMG_0314", (0.80, 0.30, 0.96, 0.52)),
    "brick": ("IMG_0349", (0.22, 0.46, 0.40, 0.60)),
    "metal_panel": ("IMG_0359", (0.02, 0.44, 0.18, 0.54)),
    "precast": ("IMG_0349", (0.10, 0.334, 0.32, 0.370)),
    "acoustic_ceiling": ("IMG_0314", (0.08, 0.00, 0.38, 0.14)),
    "steel": ("IMG_0332", (0.18, 0.16, 0.40, 0.22)),
    "mullion_aluminum": ("IMG_0316", (0.748, 0.44, 0.782, 0.56)),
    "door_wood": ("IMG_0324", (0.035, 0.44, 0.095, 0.68)),
    "door_paint": ("IMG_0339", (0.405, 0.46, 0.47, 0.54)),
    "stainless": ("IMG_0369", (0.12, 0.36, 0.22, 0.385)),
    "mosaic_green": ("IMG_0340", (0.40, 0.54, 0.52, 0.66)),
    "wood_cap_rail": ("IMG_0369", (0.055, 0.301, 0.11, 0.308)),
    "bleacher_green": ("IMG_0332", (0.50, 0.52, 0.68, 0.64)),
    "bleacher_gold": ("IMG_0332", (0.16, 0.51, 0.215, 0.60)),
    "sign_paint": ("IMG_0316", (0.22, 0.56, 0.30, 0.70)),
    "glass": ("IMG_0365", (0.32, 0.40, 0.48, 0.54)),
}


def save_rgb(name: str, arr: np.ndarray) -> None:
    Image.fromarray(np.clip(np.rint(arr), 0, 255).astype(np.uint8)).save(OUT / name)


def save_grey(name: str, arr: np.ndarray) -> None:
    g = np.clip(np.rint(arr), 0, 255).astype(np.uint8)
    Image.fromarray(g).save(OUT / name)


def height_to_normal(height: np.ndarray, strength: float = 6.0) -> np.ndarray:
    h = height.astype(np.float32)
    dx = np.roll(h, -1, axis=1) - np.roll(h, 1, axis=1)
    dy = np.roll(h, -1, axis=0) - np.roll(h, 1, axis=0)
    nx = -dx * strength
    ny = -dy * strength
    nz = np.ones_like(h)
    length = np.sqrt(nx * nx + ny * ny + nz * nz)
    n = np.stack((nx / length, ny / length, nz / length), axis=-1)
    return (n * 0.5 + 0.5) * 255.0


def write_set(name: str, color: np.ndarray, height: np.ndarray, rough: np.ndarray, nstr: float = 6.0) -> None:
    save_rgb(f"{name}_color.png", color)
    save_rgb(f"{name}_normal.png", height_to_normal(height, nstr))
    save_grey(f"{name}_roughness.png", rough)


def cloud(h: int, w: int, rng: np.random.Generator, scale: int = 16, std: float = 8.0) -> np.ndarray:
    sh, sw = max(2, h // scale), max(2, w // scale)
    sm = rng.normal(0, 1.0, (sh, sw)).astype(np.float32)
    im = Image.fromarray(((sm - sm.min()) / (np.ptp(sm) + 1e-6) * 255).astype(np.uint8), "L")
    big = np.array(im.resize((w, h), Image.Resampling.BICUBIC), np.float32)
    return (big / 255.0 - 0.5) * 2.0 * std


def load_pack(pack: str, kind: str = "Color") -> np.ndarray:
    folder = SRC / pack
    hits = list(folder.glob(f"*_{kind}.jpg")) + list(folder.glob(f"*_{kind}.png"))
    if not hits:
        hits = list(folder.glob(f"*{kind}.jpg"))
    im = Image.open(hits[0]).convert("RGB").resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    return np.array(im, np.float32)


def tint_mean(arr: np.ndarray, target, contrast: float = 0.55) -> np.ndarray:
    t = np.array(target, np.float32)
    mean = np.maximum(arr.reshape(-1, 3).mean(axis=0), 8.0)
    scaled = arr * (t / mean)
    centered = (scaled - t) * contrast + t
    return np.clip(centered, 0, 255)


def _smooth1d(n: int, rng: np.random.Generator, sigma: float) -> np.ndarray:
    x = rng.normal(0, 1, n).astype(np.float32)
    k = int(sigma * 6) | 1
    t = np.linspace(-3, 3, k)
    ker = np.exp(-0.5 * t * t)
    ker /= ker.sum()
    return np.convolve(x, ker, mode="same").astype(np.float32)


def maple_strips(target, n: int = 43, seed: int = 5) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """2.25 in maple strip in an 8 ft map: 8*12/2.25 ≈ 42.7 boards. Long 4–8 ft boards."""
    rng = np.random.default_rng(seed)
    t = np.array(target, np.float32)
    img = np.zeros((SIZE, SIZE, 3), np.float32)
    img[:] = t
    height = np.ones((SIZE, SIZE), np.float32)
    rough = np.full((SIZE, SIZE), ROUGH["maple"] * 255.0, np.float32)
    bh = SIZE / n
    grain = _smooth1d(SIZE, rng, 14.0)
    grain = (grain - grain.mean()) / (grain.std() + 1e-6)
    for i in range(n):
        y0, y1 = int(round(i * bh)) + 1, int(round((i + 1) * bh))
        if y1 <= y0:
            continue
        x = 0
        while x < SIZE:
            length = int(rng.integers(560, 1024))
            x1 = min(SIZE, x + length)
            delta = float(rng.normal(0, 7.5))
            warm = rng.normal(0, 1.6, 3) * np.array([1.1, 0.6, 0.25])
            col = np.clip(t + delta + warm, 0, 255)
            sl = img[y0:y1, x:x1]
            sl[:] = col
            sl += grain[None, x:x1, None] * 2.0
            sl += rng.normal(0, 0.6, sl.shape)
            img[y0:y1, x:x1] = sl
            if x > 0:
                img[y0:y1, x : x + 1] *= 0.96
                height[y0:y1, x : x + 1] = 0.86
            x = x1
        seam = int(round(i * bh))
        src = min(SIZE - 1, seam + 1)
        img[seam] = img[src] * 0.94
        height[seam] = 0.82
        yy = np.linspace(0, 1, max(1, y1 - y0))[:, None, None]
        img[y0:y1] += (0.5 - np.abs(yy - 0.42)) * 3.0
    return np.clip(img, 0, 255), height, rough


def stacked_cmu(target) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    rng = np.random.default_rng(3)
    t = np.array(target, np.float32)
    img = np.zeros((SIZE, SIZE, 3), np.float32)
    img[:] = t
    img += rng.normal(0, 1.6, img.shape)
    img += cloud(SIZE, SIZE, rng, 48, 2.2)[:, :, None]
    height = np.ones((SIZE, SIZE), np.float32)
    rough = np.full((SIZE, SIZE), 0.72 * 255.0, np.float32)
    courses, blocks = 12, 6
    ch, cw = SIZE / courses, SIZE / blocks
    # Paint-filled joints: horizontals are a soft shadow, verticals almost gone.
    for i in range(courses + 1):
        y = int(round(i * ch))
        y0, y1 = max(0, y - 2), min(SIZE, y + 3)
        img[y0:y1] *= 0.90
        height[y0:y1] = 0.74
    for r in range(courses):
        y0, y1 = int(r * ch), int((r + 1) * ch)
        for b in range(blocks + 1):
            x = int(round(b * cw))
            img[y0:y1, max(0, x) : min(SIZE, x + 1)] *= 0.985
            height[y0:y1, max(0, x) : min(SIZE, x + 1)] = 0.92
    return np.clip(img, 0, 255), height, rough


def standing_seam(target, n: int = 30) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    rng = np.random.default_rng(8)
    t = np.array(target, np.float32)
    img = np.zeros((SIZE, SIZE, 3), np.float32)
    img[:] = t
    img += rng.normal(0, 1.4, img.shape)
    height = np.ones((SIZE, SIZE), np.float32)
    rough = np.full((SIZE, SIZE), 0.36 * 255.0, np.float32)
    bw = SIZE / n
    for i in range(n):
        x = int(round(i * bw))
        img[:, x : x + 3] *= 0.82
        img[:, x + 3 : x + 7] *= 1.10
        img[:, x + 7 : x + 10] *= 0.96
        height[:, x : x + 3] = 0.50
        height[:, x + 3 : x + 7] = 1.12
        height[:, x + 7 : x + 10] = 0.88
    return np.clip(img, 0, 255), height, rough


def mosaic_field(n: int = 48) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    rng = np.random.default_rng(12)
    palette = np.array(
        [
            [140, 150, 140],
            [128, 140, 132],
            [156, 162, 154],
            [176, 178, 172],
            [112, 126, 118],
            [164, 168, 162],
            [88, 98, 92],
            [190, 192, 186],
            [120, 128, 124],
            [148, 154, 146],
            [72, 80, 76],
            [168, 172, 166],
        ],
        np.float32,
    )
    grout = np.array([238, 238, 234], np.float32)
    img = np.zeros((SIZE, SIZE, 3), np.float32)
    img[:] = grout
    height = np.full((SIZE, SIZE), 0.55, np.float32)
    rough = np.full((SIZE, SIZE), 0.20 * 255.0, np.float32)
    tw = SIZE / n
    gw = 2
    for r in range(n):
        for c in range(n):
            x0, y0 = int(c * tw) + gw, int(r * tw) + gw
            x1, y1 = int((c + 1) * tw) - gw, int((r + 1) * tw) - gw
            if x1 <= x0 or y1 <= y0:
                continue
            col = palette[rng.integers(0, len(palette))] + rng.normal(0, 3.0, 3)
            img[y0:y1, x0:x1] = np.clip(col, 0, 255)
            height[y0:y1, x0:x1] = 1.0
    return np.clip(img, 0, 255), height, rough


def acoustic_act() -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    rng = np.random.default_rng(9)
    t = np.array(COLORS["acoustic_ceiling"], np.float32)
    img = np.zeros((SIZE, SIZE, 3), np.float32)
    img[:] = t
    img += rng.normal(0, 2.2, img.shape)
    ys = rng.integers(0, SIZE, 28000)
    xs = rng.integers(0, SIZE, 28000)
    img[ys, xs] *= 0.72
    height = np.ones((SIZE, SIZE), np.float32)
    height[ys, xs] = 0.50
    g = 14
    bar = np.array([168, 168, 166], np.float32)
    img[:g, :] = bar
    img[-g:, :] = bar
    img[:, :g] = bar
    img[:, -g:] = bar
    height[:g, :] = 0.32
    height[-g:, :] = 0.32
    height[:, :g] = 0.32
    height[:, -g:] = 0.32
    rough = np.full((SIZE, SIZE), 0.94 * 255.0, np.float32)
    return np.clip(img, 0, 255), height, rough


def fine_terrazzo(target) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    rng = np.random.default_rng(6)
    t = np.array(target, np.float32)
    img = np.zeros((SIZE, SIZE, 3), np.float32)
    img[:] = t
    img += rng.normal(0, 2.4, img.shape)
    img += cloud(SIZE, SIZE, rng, 64, 4.0)[:, :, None]
    n = 420000
    ys = rng.integers(0, SIZE, n)
    xs = rng.integers(0, SIZE, n)
    chips = rng.choice(
        np.array([[28, 28, 30], [50, 48, 46], [70, 68, 64], [40, 42, 44], [22, 20, 20]], np.float32),
        size=n,
    )
    img[ys, xs] = np.clip(t - chips, 20, 255)
    # Soft specular wash.
    xx = np.linspace(0, 1, SIZE)
    yy = np.linspace(0, 1, SIZE)[:, None]
    img += np.clip(0.22 - ((xx - 0.72) ** 2 + (yy - 0.28) ** 2) * 3.5, 0, 1)[:, :, None] * 28
    height = np.ones((SIZE, SIZE), np.float32)
    height[ys, xs] = 0.94
    rough = np.full((SIZE, SIZE), 0.08 * 255.0, np.float32)
    rough -= np.clip(0.22 - ((xx - 0.72) ** 2 + (yy - 0.28) ** 2) * 3.5, 0, 1) * 40
    return np.clip(img, 0, 255), height, np.clip(rough, 0, 255)


def porcelain(target, grout_rgb, grout_px=3, mottling=10.0, tile_rough=0.18) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    rng = np.random.default_rng(21)
    t = np.array(target, np.float32)
    g = np.array(grout_rgb, np.float32)
    img = np.zeros((SIZE, SIZE, 3), np.float32)
    img[:] = g
    height = np.full((SIZE, SIZE), 0.28, np.float32)
    rough = np.full((SIZE, SIZE), 0.52 * 255.0, np.float32)
    tile_w, tile_h = 512, 256
    rows = SIZE // tile_h
    for r in range(rows):
        off = (tile_w // 2) if r % 2 else 0
        y0, y1 = r * tile_h + grout_px, (r + 1) * tile_h - grout_px
        x = -off
        while x < SIZE:
            if off and x > 0 and x + tile_w > SIZE:
                break
            col = np.clip(t + float(rng.normal(0, 4.0)), 0, 255)
            x0, x1 = x + grout_px, x + tile_w - grout_px
            coords = []
            if x0 < 0:
                coords.append((SIZE + x0, SIZE, y0, y1))
                coords.append((0, x1, y0, y1))
            else:
                coords.append((max(0, x0), min(SIZE, x1), y0, y1))
            for xa, xb, ya, yb in coords:
                if xb <= xa or yb <= ya:
                    continue
                sl = np.zeros((yb - ya, xb - xa, 3), np.float32)
                sl[:] = col
                sl += cloud(yb - ya, xb - xa, rng, 8, mottling)[:, :, None]
                sl += rng.normal(0, 1.2, sl.shape)
                img[ya:yb, xa:xb] = sl
                height[ya:yb, xa:xb] = 1.0
                # Soft edge bevel.
                img[ya : ya + 2, xa:xb] *= 1.04
                img[yb - 2 : yb, xa:xb] *= 0.97
                rough[ya:yb, xa:xb] = tile_rough * 255
            x += tile_w
    return np.clip(img, 0, 255), height, rough


def vinyl_plank(target) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    return porcelain(target, (148, 146, 140), grout_px=2, mottling=7.5, tile_rough=0.26)


def rubber_speckle(target) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    rng = np.random.default_rng(2)
    t = np.array(target, np.float32)
    img = np.zeros((SIZE, SIZE, 3), np.float32)
    img[:] = t
    img += rng.normal(0, 1.6, img.shape)
    n = 18000
    img[rng.integers(0, SIZE, n), rng.integers(0, SIZE, n)] = t * 0.62
    img[rng.integers(0, SIZE, n), rng.integers(0, SIZE, n)] = np.clip(t * 1.10, 0, 255)
    xx = np.linspace(0, 1, SIZE)
    yy = np.linspace(0, 1, SIZE)[:, None]
    spec = np.clip(0.28 - ((xx - 0.62) ** 2 * 1.6 + (yy - 0.32) ** 2 * 5.5), 0, 1)
    img += spec[:, :, None] * 58
    height = np.ones((SIZE, SIZE), np.float32)
    rough = np.full((SIZE, SIZE), 0.16 * 255.0, np.float32)
    rough -= spec * 50
    return np.clip(img, 0, 255), height, np.clip(rough, 0, 255)


def sawcut_concrete(target) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    rng = np.random.default_rng(4)
    t = np.array(target, np.float32)
    img = np.zeros((SIZE, SIZE, 3), np.float32)
    img[:] = t
    img += rng.normal(0, 3.2, img.shape)
    img += cloud(SIZE, SIZE, rng, 32, 3.5)[:, :, None]
    n = 50000
    img[rng.integers(0, SIZE, n), rng.integers(0, SIZE, n)] = t * 0.88
    height = np.ones((SIZE, SIZE), np.float32)
    rough = np.full((SIZE, SIZE), 0.30 * 255.0, np.float32)
    joint = t * 0.55
    step = SIZE // 3
    for i in range(1, 3):
        y = i * step
        img[y - 1 : y + 2] = joint
        height[y - 1 : y + 2] = 0.45
        x = int(i * step * 1.15) % SIZE
        img[:, x - 1 : x + 2] = joint
        height[:, x - 1 : x + 2] = 0.45
    return np.clip(img, 0, 255), height, rough


def aggregate(target, std: float = 9.0) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    rng = np.random.default_rng(10)
    t = np.array(target, np.float32)
    img = np.zeros((SIZE, SIZE, 3), np.float32)
    img[:] = t
    img += rng.normal(0, std, img.shape)
    n = 240000
    grit = rng.normal(0, 22, (n, 3))
    img[rng.integers(0, SIZE, n), rng.integers(0, SIZE, n)] = np.clip(t + grit, 0, 255)
    height = 0.80 + rng.random((SIZE, SIZE)).astype(np.float32) * 0.20
    rough = np.full((SIZE, SIZE), 0.78 * 255.0, np.float32)
    return np.clip(img, 0, 255), height, rough


def turf_from_src(target) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    rng = np.random.default_rng(13)
    src = load_pack("Grass001")
    img = tint_mean(src, target, contrast=0.70)
    lime = np.array([120, 148, 58], np.float32)
    thatch = np.array([118, 96, 52], np.float32)
    n = 28000
    img[rng.integers(0, SIZE, n), rng.integers(0, SIZE, n)] = lime
    n = 50000
    img[rng.integers(0, SIZE, n), rng.integers(0, SIZE, n)] = thatch
    yy = np.arange(SIZE)[:, None]
    mow = np.sin(yy / 22.0) * 4.0
    img += mow[:, :, None]
    height = 0.45 + rng.random((SIZE, SIZE)).astype(np.float32) * 0.55
    rough = np.full((SIZE, SIZE), 0.90 * 255.0, np.float32)
    return np.clip(img, 0, 255), height, rough


def carpet_heather(target) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    rng = np.random.default_rng(7)
    t = np.array(target, np.float32)
    img = np.zeros((SIZE, SIZE, 3), np.float32)
    img[:] = t
    xx = np.arange(SIZE)
    img += ((xx % 3) - 1.0)[None, :, None] * 4.5
    img += rng.normal(0, 10.0, img.shape)
    img += cloud(SIZE, SIZE, rng, 12, 14.0)[:, :, None]
    img += cloud(SIZE, SIZE, rng, 28, 8.0)[:, :, None]
    # Nearly invisible 24 in module.
    img[SIZE // 2] *= 0.985
    img[:, SIZE // 2] *= 0.985
    height = 0.88 + rng.random((SIZE, SIZE)).astype(np.float32) * 0.12
    rough = np.full((SIZE, SIZE), 0.94 * 255.0, np.float32)
    return np.clip(img, 0, 255), height, rough


def quiet_wood(target, seed: int = 1) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    rng = np.random.default_rng(seed)
    t = np.array(target, np.float32)
    img = np.zeros((SIZE, SIZE, 3), np.float32)
    img[:] = t
    streaks = rng.normal(0, 1.0, (1, SIZE, 1))
    img += np.repeat(np.repeat(streaks, SIZE, axis=0), 3, axis=2) * 2.6
    img += rng.normal(0, 1.1, img.shape)
    height = 0.96 + rng.normal(0, 0.015, (SIZE, SIZE)).astype(np.float32)
    rough = np.full((SIZE, SIZE), 0.40 * 255.0, np.float32)
    return np.clip(img, 0, 255), height, rough


def paint_fill(target, std: float = 1.4, rough_v: float = 0.4, sheen: bool = False) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    rng = np.random.default_rng(11)
    t = np.array(target, np.float32)
    img = np.zeros((SIZE, SIZE, 3), np.float32)
    img[:] = t
    img += rng.normal(0, std, img.shape)
    if sheen:
        xx = np.linspace(0, 1, SIZE)
        yy = np.linspace(0, 1, SIZE)[:, None]
        img += np.clip(0.16 - ((xx - 0.6) ** 2 * 3 + (yy - 0.3) ** 2 * 6), 0, 1)[:, :, None] * 18
    height = np.ones((SIZE, SIZE), np.float32)
    rough = np.full((SIZE, SIZE), rough_v * 255.0, np.float32)
    return np.clip(img, 0, 255), height, rough


def orange_peel(target) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    rng = np.random.default_rng(19)
    t = np.array(target, np.float32)
    img = np.zeros((SIZE, SIZE, 3), np.float32)
    img[:] = t
    img += rng.normal(0, 1.2, img.shape)
    img += cloud(SIZE, SIZE, rng, 80, 1.8)[:, :, None]
    height = 0.96 + rng.normal(0, 0.02, (SIZE, SIZE)).astype(np.float32)
    rough = np.full((SIZE, SIZE), 0.80 * 255.0, np.float32)
    return np.clip(img, 0, 255), height, rough


def square_tile(target, grout, n: int, gw: int, tile_std: float, grout_dark: bool) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    rng = np.random.default_rng(15)
    t = np.array(target, np.float32)
    g = np.array(grout, np.float32)
    img = np.zeros((SIZE, SIZE, 3), np.float32)
    img[:] = g
    height = np.full((SIZE, SIZE), 0.30, np.float32)
    rough = np.full((SIZE, SIZE), 0.48 * 255.0, np.float32)
    tw = SIZE / n
    for r in range(n):
        for c in range(n):
            x0, y0 = int(c * tw) + gw, int(r * tw) + gw
            x1, y1 = int((c + 1) * tw) - gw, int((r + 1) * tw) - gw
            if x1 <= x0 or y1 <= y0:
                continue
            col = np.clip(t + rng.normal(0, tile_std, 3), 0, 255)
            sl = np.zeros((y1 - y0, x1 - x0, 3), np.float32)
            sl[:] = col
            sl += rng.normal(0, 1.4, sl.shape)
            img[y0:y1, x0:x1] = sl
            height[y0:y1, x0:x1] = 1.0
            rough[y0:y1, x0:x1] = 0.16 * 255
            img[y0 : y0 + 2, x0:x1] *= 1.05
    return np.clip(img, 0, 255), height, rough


def brick_running(target) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    rng = np.random.default_rng(18)
    t = np.array(target, np.float32)
    mortar = np.array([214, 208, 196], np.float32)
    img = np.zeros((SIZE, SIZE, 3), np.float32)
    img[:] = mortar
    height = np.full((SIZE, SIZE), 0.32, np.float32)
    rough = np.full((SIZE, SIZE), 0.70 * 255.0, np.float32)
    courses, bricks = 18, 6
    ch, cw = SIZE / courses, SIZE / bricks
    gw = 4
    for r in range(courses):
        off = (cw / 2) if r % 2 else 0
        y0, y1 = int(r * ch) + gw, int((r + 1) * ch) - gw
        x = -off
        while x < SIZE:
            x0, x1 = int(x) + gw, int(x + cw) - gw
            col = np.clip(t + rng.normal(0, 5.0, 3) * np.array([1.0, 0.6, 0.5]), 0, 255)
            xa, xb = max(0, x0), min(SIZE, x1)
            if xb > xa and y1 > y0:
                img[y0:y1, xa:xb] = col
                img[y0:y1, xa:xb] += rng.normal(0, 2.0, (y1 - y0, xb - xa, 3))
                height[y0:y1, xa:xb] = 1.0
                rough[y0:y1, xa:xb] = 0.88 * 255
            x += cw
    return np.clip(img, 0, 255), height, rough


def brushed_metal(target, rough_v: float, vertical: bool = False) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    rng = np.random.default_rng(4)
    t = np.array(target, np.float32)
    img = np.zeros((SIZE, SIZE, 3), np.float32)
    img[:] = t
    if vertical:
        # Grain runs in Y (vertical extrusion).
        streaks = rng.normal(0, 1.0, (1, SIZE, 1))
        img += np.repeat(np.repeat(streaks, SIZE, axis=0), 3, axis=2) * 3.2
    else:
        streaks = rng.normal(0, 1.0, (SIZE, 1, 1))
        img += np.repeat(np.repeat(streaks, SIZE, axis=1), 3, axis=2) * 3.2
    img += rng.normal(0, 1.0, img.shape)
    height = 0.5 + rng.normal(0, 0.02, (SIZE, SIZE)).astype(np.float32)
    rough = np.full((SIZE, SIZE), rough_v * 255.0, np.float32)
    return np.clip(img, 0, 255), height, rough


def glass_preview() -> np.ndarray:
    """Pair-only preview of vision glass: cool tint, interior reflection, mullion grid."""
    img = np.zeros((SIZE, SIZE, 3), np.float32)
    yy = np.linspace(0, 1, SIZE)[:, None, None]
    upper = np.array([58, 68, 78], np.float32)
    lower = np.array([22, 24, 26], np.float32)
    img[:] = upper * (1 - np.clip((yy - 0.08) * 1.6, 0, 1)) + lower * np.clip((yy - 0.08) * 1.6, 0, 1)
    # Warm interior lights faintly in the dark glass.
    for cy, cx, rad, col in (
        (0.28, 0.22, 0.08, (90, 88, 70)),
        (0.30, 0.55, 0.07, (80, 78, 62)),
        (0.52, 0.40, 0.10, (40, 42, 38)),
        (0.70, 0.70, 0.09, (70, 68, 52)),
    ):
        yy2 = (np.linspace(0, 1, SIZE)[:, None] - cy) ** 2
        xx2 = (np.linspace(0, 1, SIZE)[None, :] - cx) ** 2
        blob = np.clip(1.0 - (yy2 + xx2) / (rad * rad), 0, 1)
        img += blob[:, :, None] * np.array(col, np.float32) * 0.35
    mullion = np.array([18, 18, 20], np.float32)
    for i in (0, 320, 640, 1008):
        img[i : i + 16, :] = mullion
    for j in (0, 248, 496, 744, 1008):
        img[:, j : j + 16] = mullion
    transom = np.array([150, 152, 154], np.float32)
    img[328:336, :] = transom
    return np.clip(img, 0, 255)


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
        if min(crop.size) < 4:
            print("tiny", name)
            continue
        crop = crop.resize((256, 256), Image.Resampling.LANCZOS)
        crop.save(SW / f"{name}.jpg", quality=92)
        print("swatch", name)


def patch_luau() -> None:
    text = LUAU.read_text(encoding="utf-8")
    for key, rgb in COLORS.items():
        text = re.sub(
            rf"({key} = \{{.*?color = Color3\.fromRGB)\(\d+, \d+, \d+\)",
            rf"\1({rgb[0]}, {rgb[1]}, {rgb[2]})",
            text,
            count=1,
            flags=re.S,
        )
    for key, r in ROUGH.items():
        text = re.sub(
            rf"({key} = \{{.*?roughness = )[0-9.]+",
            rf"\g<1>{r}",
            text,
            count=1,
            flags=re.S,
        )
    LUAU.write_text(text, encoding="utf-8")
    print("patched Materials.luau colors")


def render_captures() -> None:
    CAPTURE.mkdir(parents=True, exist_ok=True)
    for key, rgb in COLORS.items():
        if key == "glass":
            arr = glass_preview()
        else:
            path = OUT / f"{key}_color.png"
            if path.exists():
                arr = np.array(Image.open(path).convert("RGB"), np.float32)
            else:
                arr = np.zeros((SIZE, SIZE, 3), np.float32)
                arr[:] = rgb
        if key in ("maple", "racquetball_wood"):
            m = 140
            arr = arr[m : SIZE - m, m : SIZE - m]
        im = Image.fromarray(np.clip(np.rint(arr), 0, 255).astype(np.uint8)).resize(
            (900, 900), Image.Resampling.LANCZOS
        )
        im.save(CAPTURE / f"{key}.png")
    print("captures", len(COLORS))


def make_pairs() -> None:
    PAIRS.mkdir(parents=True, exist_ok=True)
    try:
        font = ImageFont.truetype("arialbd.ttf", 28)
    except OSError:
        font = ImageFont.load_default()
    h = 900
    for key in COLORS:
        ref = Image.open(SW / f"{key}.jpg").convert("RGB")
        build = Image.open(CAPTURE / f"{key}.png").convert("RGB")
        a = ref.resize((int(ref.width * h / ref.height), h), Image.Resampling.LANCZOS)
        b = build.resize((int(build.width * h / build.height), h), Image.Resampling.LANCZOS)
        sheet = Image.new("RGB", (a.width + b.width + 30, h + 50), "white")
        sheet.paste(a, (0, 50))
        sheet.paste(b, (a.width + 30, 50))
        g = ImageDraw.Draw(sheet)
        g.text((10, 10), f"REAL (reference photo) {key}", fill="black", font=font)
        g.text((a.width + 40, 10), "ROBLOX BUILD", fill="black", font=font)
        out = PAIRS / f"{key}.jpg"
        sheet.save(out, quality=88)
    print("pairs", len(COLORS))


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    crop_swatches()

    c, h, r = maple_strips(COLORS["maple"], 43, seed=5)
    write_set("maple", c, h, r, 5.0)
    c, h, r = maple_strips(COLORS["racquetball_wood"], 43, seed=6)
    write_set("racquetball_wood", c, h, r, 5.0)
    c, h, r = quiet_wood(COLORS["door_wood"], 2)
    write_set("door_wood", c, h, r)
    c, h, r = quiet_wood(COLORS["wood_cap_rail"], 3)
    write_set("wood_cap_rail", c, h, r)

    c, h, r = stacked_cmu(COLORS["painted_cmu"])
    write_set("painted_cmu", c, h, r, 4.0)
    c, h, r = standing_seam(COLORS["metal_panel"], 30)
    write_set("metal_panel", c, h, r, 7.0)
    c, h, r = mosaic_field(48)
    write_set("mosaic_green", c, h, r, 4.0)
    c, h, r = acoustic_act()
    write_set("acoustic_ceiling", c, h, r, 4.0)
    c, h, r = fine_terrazzo(COLORS["terrazzo"])
    write_set("terrazzo", c, h, r, 3.0)
    c, h, r = porcelain(COLORS["porcelain_tile"], (150, 146, 140), grout_px=3, mottling=9.0)
    write_set("porcelain_tile", c, h, r, 4.0)
    c, h, r = vinyl_plank(COLORS["vinyl"])
    write_set("vinyl", c, h, r, 3.5)
    c, h, r = rubber_speckle(COLORS["rubber"])
    write_set("rubber", c, h, r, 2.0)
    c, h, r = sawcut_concrete(COLORS["sealed_concrete"])
    write_set("sealed_concrete", c, h, r, 4.0)
    c, h, r = aggregate(COLORS["precast"], 11.0)
    write_set("precast", c, h, r, 5.0)
    c, h, r = turf_from_src(COLORS["turf"])
    write_set("turf", c, h, r, 6.0)
    c, h, r = carpet_heather(COLORS["carpet_tile"])
    write_set("carpet_tile", c, h, r, 3.0)
    c, h, r = square_tile(COLORS["ceramic_tile"], (248, 248, 244), n=6, gw=9, tile_std=1.2, grout_dark=False)
    write_set("ceramic_tile", c, h, r, 4.0)
    c, h, r = square_tile(COLORS["ceramic_floor_tile"], (150, 144, 134), n=5, gw=4, tile_std=1.1, grout_dark=True)
    write_set("ceramic_floor_tile", c, h, r, 4.0)
    c, h, r = brick_running(COLORS["brick"])
    write_set("brick", c, h, r, 5.0)

    c, h, r = orange_peel(COLORS["gypsum"])
    write_set("gypsum", c, h, r)
    c, h, r = paint_fill(COLORS["steel"], 1.1, 0.50)
    write_set("steel", c, h, r)
    c, h, r = brushed_metal(COLORS["mullion_aluminum"], 0.28, vertical=True)
    write_set("mullion_aluminum", c, h, r, 3.0)
    c, h, r = brushed_metal(COLORS["stainless"], 0.18, vertical=False)
    write_set("stainless", c, h, r, 3.0)
    c, h, r = paint_fill(COLORS["door_paint"], 1.2, 0.38)
    write_set("door_paint", c, h, r)
    c, h, r = paint_fill(COLORS["court_green_paint"], 1.0, 0.14, sheen=True)
    write_set("court_green_paint", c, h, r)
    c, h, r = paint_fill(COLORS["court_gold_paint"], 1.0, 0.16, sheen=True)
    write_set("court_gold_paint", c, h, r)
    c, h, r = paint_fill(COLORS["bleacher_green"], 1.0, 0.48)
    write_set("bleacher_green", c, h, r)
    c, h, r = paint_fill(COLORS["bleacher_gold"], 1.0, 0.42)
    write_set("bleacher_gold", c, h, r)
    c, h, r = paint_fill(COLORS["sign_paint"], 1.0, 0.36)
    write_set("sign_paint", c, h, r)

    patch_luau()
    render_captures()
    make_pairs()
    print("iterate_maps done")


if __name__ == "__main__":
    main()
