"""Print paint-pixel stats and sample coordinates from the warped ortho."""
from pathlib import Path
import json
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "reference" / "web" / "site"
meta = json.loads((OUT / "ortho_meta.json").read_text())
img = np.asarray(Image.open(OUT / "ortho_blueprint.jpg"))
h, w = img.shape[:2]
x0, z0, s = meta["x0"], meta["z0"], meta["ftPerPx"]
r, g, b = img[:, :, 0].astype(int), img[:, :, 1].astype(int), img[:, :, 2].astype(int)
mx = np.maximum(np.maximum(r, g), b)
mn = np.minimum(np.minimum(r, g), b)
# yellow: g and r high, b lower
yellow = (r > 140) & (g > 120) & (b < 110) & (r > b + 30) & (g > b + 15)
white = (mx > 200) & ((mx - mn) < 35) & (r.astype(int) + g + b > 540)
print("size", w, h, "yellow", int(yellow.sum()), "white", int(white.sum()))
# origin pixel
print("origin px", (0 - x0) / s, (0 - z0) / s)

def dump_mask(mask, name, step=40):
    ys, xs = np.where(mask)
    if len(xs) == 0:
        print(name, "empty")
        return
    print(name, "bbox ft", x0 + xs.min() * s, z0 + ys.min() * s, x0 + xs.max() * s, z0 + ys.max() * s, "n", len(xs))

dump_mask(yellow, "yellow")
dump_mask(white, "white")
# parking south: z>50 (south of door), x -400 to 50
j0 = int((80 - z0) / s)
j1 = int((350 - z0) / s)
i0 = int((-400 - x0) / s)
i1 = int((80 - x0) / s)
crop = img[j0:j1, i0:i1]
Image.fromarray(crop).save(OUT / "crop_south_lot.jpg", quality=90)
print("south crop", crop.shape)
# roundabout region
j0 = int((20 - z0) / s)
j1 = int((220 - z0) / s)
i0 = int((-50 - x0) / s)
i1 = int((250 - x0) / s)
Image.fromarray(img[j0:j1, i0:i1]).save(OUT / "crop_roundabout.jpg", quality=90)
# west lots
j0 = int((-120 - z0) / s)
j1 = int((80 - z0) / s)
i0 = int((-500 - x0) / s)
i1 = int((-280 - x0) / s)
Image.fromarray(img[j0:j1, i0:i1]).save(OUT / "crop_west.jpg", quality=90)
