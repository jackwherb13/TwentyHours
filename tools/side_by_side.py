"""Compose reference | build side-by-side images for judging.

Usage: python tools/side_by_side.py <reference.jpg> <build.png> <out.jpg> [label]
Both images are scaled to the same height (900 px) with labels, so a vision judge compares like with like.
"""

import sys

from PIL import Image, ImageDraw, ImageFont

ref_path, build_path, out_path = sys.argv[1:4]
label = sys.argv[4] if len(sys.argv) > 4 else ""
H = 900
font = ImageFont.truetype("arialbd.ttf", 28)


def fit(path):
	im = Image.open(path).convert("RGB")
	return im.resize((int(im.width * H / im.height), H))


a, b = fit(ref_path), fit(build_path)
sheet = Image.new("RGB", (a.width + b.width + 30, H + 50), "white")
sheet.paste(a, (0, 50))
sheet.paste(b, (a.width + 30, 50))
g = ImageDraw.Draw(sheet)
g.text((10, 10), f"REAL (reference photo) {label}", fill="black", font=font)
g.text((a.width + 40, 10), "ROBLOX BUILD", fill="black", font=font)
sheet.save(out_path, quality=88)
print(out_path)
