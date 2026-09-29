"""Fit Patriot Circle centerline and stall pitches from the warped ortho."""
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


def at(x, z):
    i = int((x - X0) / S)
    j = int((z - Z0) / S)
    if 0 <= j < gray.shape[0] and 0 <= i < gray.shape[1]:
        return gray[j, i]
    return 255


def is_asphalt(x, z):
    v = at(x, z)
    return 70 < v < 145


# Patriot Circle: scan z for darkest band at each x from -480 to 80
print("PATRIOT center z per x")
for x in range(-480, 120, 20):
    best_z, best = None, 1e9
    for z in range(120, 230, 1):
        v = sum(at(x, z + d) for d in range(-4, 5))
        if v < best and is_asphalt(x, z):
            best, best_z = v, z
    print(x, best_z, at(x, best_z) if best_z else None)

print("\nROUNDABOUT dark ring: scan")
for z in range(40, 200, 5):
    xs = [x for x in range(40, 220, 2) if is_asphalt(x, z)]
    if xs:
        print("z", z, "x", min(xs), max(xs), "n", len(xs))

print("\nSTALL white peaks at candidate z")
# white: high gray relative to neighbors in x
for z in range(260, 500, 4):
    i0 = int((-400 - X0) / S)
    i1 = int((40 - X0) / S)
    j = int((z - Z0) / S)
    row = gray[j, i0:i1]
    # local peaks
    peaks = []
    for k in range(2, len(row) - 2):
        if row[k] > 150 and row[k] > row[k - 1] and row[k] > row[k + 1] and row[k] - np.median(row[max(0,k-8):k+8]) > 25:
            peaks.append(X0 + (i0 + k) * S)
    if len(peaks) > 8:
        diffs = np.diff(peaks)
        print(f"z={z} peaks={len(peaks)} x0={peaks[0]:.0f} x1={peaks[-1]:.0f} medpitch={np.median(diffs):.1f}")
