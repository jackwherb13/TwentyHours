"""Measure asphalt centerlines, roundabout, and stall paint from the warped ortho."""
from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image

WEB = Path("reference/web/site")
meta = json.loads((WEB / "ortho_meta.json").read_text())
img = np.asarray(Image.open(WEB / "ortho_blueprint.jpg")).astype(np.int16)
X0, Z0, S = meta["x0"], meta["z0"], meta["ftPerPx"]
gray = img.mean(axis=2)
r, g, b = img[:, :, 0], img[:, :, 1], img[:, :, 2]


def gxy(x, z):
    i = int((x - X0) / S)
    j = int((z - Z0) / S)
    if 0 <= j < gray.shape[0] and 0 <= i < gray.shape[1]:
        return float(gray[j, i])
    return 255.0


def rgb(x, z):
    i = int((x - X0) / S)
    j = int((z - Z0) / S)
    if 0 <= j < img.shape[0] and 0 <= i < img.shape[1]:
        return tuple(int(v) for v in img[j, i])
    return (0, 0, 0)


def is_asphalt(x, z):
    rr, gg, bb = rgb(x, z)
    v = (rr + gg + bb) / 3
    sat = max(rr, gg, bb) - min(rr, gg, bb)
    return 55 < v < 155 and sat < 45 and gg < 150


# --- Patriot Circle: for each x, find z of darkest asphalt band in [120, 230]
print("PATRIOT z(x)")
pat = []
for x in range(-470, 130, 15):
    scores = []
    for z in range(130, 240):
        s = sum(gxy(x, z + d) for d in range(-5, 6))
        if is_asphalt(x, z):
            scores.append((s, z))
    if scores:
        scores.sort()
        z = scores[0][1]
        pat.append((x, z, scores[0][0], rgb(x, z)))
        print(f"  x={x:4d} z={z:4d} g={scores[0][0]:.0f} {rgb(x,z)}")

# --- Campus Drive: for each z, find x of darkest asphalt in [-500, -400]
print("\nCAMPUS x(z)")
for z in range(-180, 200, 15):
    scores = []
    for x in range(-500, -400):
        s = sum(gxy(x + d, z) for d in range(-5, 6))
        if is_asphalt(x, z):
            scores.append((s, x))
    if scores:
        scores.sort()
        x = scores[0][1]
        print(f"  z={z:4d} x={x:4d} {rgb(x,z)}")

# --- Roundabout: grass disk (high G, mid brightness) near x 80-180, z 80-200
print("\nROUNDABOUT grass candidates")
best = None
for cz in range(90, 200, 2):
    for cx in range(80, 200, 2):
        rr, gg, bb = rgb(cx, cz)
        if gg > 140 and gg > rr + 10 and gg > bb + 20:
            # radius of green
            rad = 0
            for rad in range(20, 70):
                ring = [rgb(cx + int(rad * np.cos(t)), cz + int(rad * np.sin(t))) for t in np.linspace(0, 6.28, 16)]
                green = sum(1 for a, b, c in ring if b > 130 and b > a)
                if green < 8:
                    break
            if best is None or rad > best[0]:
                best = (rad, cx, cz)
print("best island", best)

# --- Stall white lines: local peaks along z rows in lot
print("\nSTALL peaks")
for z in range(250, 510, 2):
    peaks = []
    prev = 0
    for x in np.arange(-410, 50, 0.5):
        rr, gg, bb = rgb(x, z)
        v = (rr + gg + bb) / 3
        sat = max(rr, gg, bb) - min(rr, gg, bb)
        # white paint on asphalt
        if v > 165 and sat < 40:
            if not peaks or x - peaks[-1] > 4:
                peaks.append(x)
    if len(peaks) >= 10:
        diffs = np.diff(peaks)
        print(f"  z={z} n={len(peaks)} x0={peaks[0]:.0f} x1={peaks[-1]:.0f} med={np.median(diffs):.1f} first10={['%.0f'%p for p in peaks[:10]]}")
