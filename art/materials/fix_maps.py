"""Flatten noisy CC0 maps and add RAC-scale CMU / metal ribs / carpet."""
from pathlib import Path
import numpy as np
from PIL import Image, ImageFilter

OUT = Path("art/materials/pbr")
SW = Path("art/materials/swatches")
PHOTO = Path("reference/photos")


def load(name):
    return np.array(Image.open(OUT / name).convert("RGB"))


def save(name, arr):
    Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8)).save(OUT / name)


def flatten(arr, mix=0.55, target=None):
    a = arr.astype(np.float32)
    mean = a.reshape(-1, 3).mean(axis=0)
    t = np.array(target if target is not None else mean, dtype=np.float32)
    flat = np.broadcast_to(t, a.shape).copy()
    return flat * mix + a * (1 - mix)


def cmu(target, size=1024, courses=12, blocks=6):
    img = np.zeros((size, size, 3), np.float32)
    img[:] = target
    rng = np.random.default_rng(3)
    img += rng.normal(0, 3.5, img.shape)
    ch, cw = size / courses, size / blocks
    grout = np.array([188, 184, 176], np.float32)
    t = max(2, int(size * 0.008))
    for i in range(courses + 1):
        y = int(round(i * ch))
        img[max(0, y - t) : min(size, y + t), :] = grout
    for r in range(courses):
        off = (cw / 2) if r % 2 else 0
        y0, y1 = int(r * ch), int((r + 1) * ch)
        for b in range(blocks + 2):
            x = int(round(b * cw + off)) % size
            img[y0:y1, max(0, x - t) : min(size, x + t)] = grout
    return np.clip(img, 0, 255)


def ribs(base, n=8):
    a = base.astype(np.float32)
    h, w, _ = a.shape
    band = h // n
    for i in range(n):
        y = i * band
        a[y : y + 6] *= 0.82
        a[y + 6 : y + 10] *= 1.08
    return np.clip(a, 0, 255)


def carpet(target, size=1024):
    rng = np.random.default_rng(7)
    img = np.zeros((size, size, 3), np.float32)
    img[:] = target
    noise = rng.normal(0, 8, (size, size, 3))
    # directional loop pile
    for x in range(size):
        img[:, x] += (x % 3 - 1) * 2.5
    img += noise
    seam = 4
    img[size // 2 - seam : size // 2 + seam] *= 0.92
    img[:, size // 2 - seam : size // 2 + seam] *= 0.92
    return np.clip(img, 0, 255)


def rubber_solid(target, size=1024):
    rng = np.random.default_rng(2)
    img = np.zeros((size, size, 3), np.float32)
    img[:] = target
    img += rng.normal(0, 2.2, img.shape)
    return np.clip(img, 0, 255)


def paint(target, size=1024, std=2.0):
    rng = np.random.default_rng(11)
    img = np.zeros((size, size, 3), np.float32)
    img[:] = target
    img += rng.normal(0, std, img.shape)
    return np.clip(img, 0, 255)


save("painted_cmu_color.png", cmu((210, 206, 200)))
metal = flatten(load("metal_panel_color.png"), 0.35, (145, 150, 153))
save("metal_panel_color.png", ribs(metal, 8))
save("carpet_tile_color.png", carpet((68, 67, 66)))
save("rubber_color.png", rubber_solid((173, 164, 148)))
save("gypsum_color.png", paint((220, 220, 222), std=1.2))
save("court_green_paint_color.png", paint((28, 70, 40), std=1.0))
save("court_gold_paint_color.png", paint((214, 172, 44), std=1.0))
save("door_paint_color.png", paint((76, 81, 86), std=1.4))
save("bleacher_green_color.png", paint((30, 35, 31), std=1.0))
save("bleacher_gold_color.png", paint((160, 108, 32), std=1.0))
save("sign_paint_color.png", paint((0, 70, 36), std=1.0))
save("stainless_color.png", flatten(load("metal_panel_color.png"), 0.5, (180, 184, 186)))
save("steel_color.png", paint((48, 50, 52), std=1.5))
save("mullion_aluminum_color.png", paint((40, 42, 44), std=1.2))
terr = flatten(load("terrazzo_color.png"), 0.45, (188, 178, 166))
save("terrazzo_color.png", terr)
maple = flatten(load("maple_color.png"), 0.25, (228, 210, 180))
save("maple_color.png", maple)
print("fixed maps")
