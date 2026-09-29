"""Render a one-image review packet: labeled plan of each level + checker summary.

Usage: python tools/render_plan.py [out.png]   (default verification/packet.png)
The manager reviews this single image instead of logs, sessions, or raw JSON.
"""

import json
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "verification" / "packet.png"
COLORS = {
	"gym": (222, 184, 120), "corridor": (215, 215, 215), "circulation": (215, 215, 215), "lobby": (170, 205, 235),
	"office": (190, 220, 180), "fitness": (245, 170, 120), "locker": (200, 170, 230), "support": (230, 230, 190),
	"mechanical": (180, 180, 180), "construction": (250, 200, 200), "stair": (160, 160, 220), "restroom": (170, 230, 230),
}
SCALE = 2.2
font = ImageFont.truetype("arial.ttf", 12)
bold = ImageFont.truetype("arialbd.ttf", 18)


def render(level):
	d = json.loads((ROOT / "blueprint" / f"{level}.json").read_text())
	pts = [p for r in d["rooms"] for p in r["polygon"]] + [w[k] for w in d["walls"] for k in ("a", "b")]
	x0, z0 = min(p[0] for p in pts), min(p[1] for p in pts)
	x1, z1 = max(p[0] for p in pts), max(p[1] for p in pts)
	im = Image.new("RGB", (int((x1 - x0) * SCALE) + 60, int((z1 - z0) * SCALE) + 90), "white")
	g = ImageDraw.Draw(im)

	def t(p):
		return (30 + (p[0] - x0) * SCALE, 50 + (p[1] - z0) * SCALE)

	for r in d["rooms"]:
		g.polygon([t(p) for p in r["polygon"]], fill=COLORS.get(r.get("type"), (235, 235, 235)), outline=(110, 110, 110))
	for w in d["walls"]:
		g.line([t(w["a"]), t(w["b"])], fill=(15, 15, 15), width=2)
		for o in w.get("openings", []):
			ax, az = w["a"]
			bx, bz = w["b"]
			length = max(((bx - ax) ** 2 + (bz - az) ** 2) ** 0.5, 1e-6)
			ux, uz = (bx - ax) / length, (bz - az) / length
			s = o.get("offset", 0)
			e = s + o.get("width", 3)
			color = (40, 120, 255) if o.get("type") in ("window", "curtainwall") else (230, 60, 40)
			g.line([t((ax + ux * s, az + uz * s)), t((ax + ux * e, az + uz * e))], fill=color, width=4)
	for r in d["rooms"]:
		xs = [p[0] for p in r["polygon"]]
		zs = [p[1] for p in r["polygon"]]
		if (max(xs) - min(xs)) * (max(zs) - min(zs)) > 500:
			c = t(((min(xs) + max(xs)) / 2, (min(zs) + max(zs)) / 2))
			label = f"{r.get('name', r['id'])[:20]}\n{max(xs) - min(xs):.0f}x{max(zs) - min(zs):.0f}"
			g.multiline_text((c[0] - 35, c[1] - 12), label, fill="black", font=font)
	g.text((30, 12), f"{level.upper()}  rooms={len(d['rooms'])} walls={len(d['walls'])}  red=door blue=window", fill="black", font=bold)
	g.line([(30, im.height - 20), (30 + 100 * SCALE, im.height - 20)], fill="black", width=4)
	g.text((30, im.height - 38), "100 ft", fill="black", font=font)
	return im


levels = [lv for lv in ("level1", "level2") if (ROOT / "blueprint" / f"{lv}.json").exists()]
panels = [render(lv) for lv in levels]
check = subprocess.run([sys.executable, str(ROOT / "tools" / "verify_blueprint.py")], capture_output=True, text=True).stdout
lines = check.strip().splitlines()[:30]
W = sum(p.width for p in panels) + 20 * len(panels)
H = max(p.height for p in panels) + 20 + 16 * len(lines)
sheet = Image.new("RGB", (W, H), "white")
x = 0
for p in panels:
	sheet.paste(p, (x, 0))
	x += p.width + 20
ImageDraw.Draw(sheet).multiline_text((30, max(p.height for p in panels) + 5), "\n".join(lines), fill=(150, 0, 0), font=font)
sheet.thumbnail((2400, 2400))
OUT.parent.mkdir(parents=True, exist_ok=True)
sheet.save(OUT)
print(OUT)
