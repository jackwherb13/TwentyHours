"""Draw the blueprint over the site plan and over the OSM outline.

Usage: python tools/overlay.py

Writes:
  verification/M1/overlay_site.png    rooms + footprint on site_plan_native.png
  verification/M1/overlay_osm.png     rooms + footprint against OSM way 112472416
  verification/M1/overlay_level1.png  labeled Level 1 plan
  verification/M1/overlay_level2.png  labeled Level 2 plan

Prints the footprint intersection-over-union versus the OSM outline.
"""

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_blueprint as bb

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "verification" / "M1"
COLORS = {
	"gym": (210, 160, 60),
	"corridor": (90, 90, 90),
	"lobby": (40, 110, 190),
	"office": (50, 140, 70),
	"fitness": (200, 100, 30),
	"locker": (130, 70, 170),
	"restroom": (30, 150, 160),
	"mechanical": (110, 110, 110),
	"stair": (80, 80, 180),
	"racquetball": (170, 60, 60),
	"construction": (190, 40, 40),
	"storage": (120, 100, 60),
	"void": (160, 160, 200),
	"support": (140, 140, 60),
}


def load(name):
	return json.loads((ROOT / "blueprint" / name).read_text(encoding="utf-8"))


def font(size, bold=False):
	name = "arialbd.ttf" if bold else "arial.ttf"
	return ImageFont.truetype(name, size)


def pixel_mapper(cal):
	scale = cal["scaleFtPerPx"]
	anchor = cal["pixelAnchor"]
	shift = cal["shift"]

	def to_px(x, z):
		px = anchor["px"] + (x - anchor["rawX"] + shift["x"]) / scale
		py = anchor["py"] + (z - anchor["rawZ"] + shift["z"]) / scale
		return (px, py)

	return to_px


def draw_poly(g, pts, fill, outline, width=2):
	if len(pts) >= 3:
		g.polygon(pts, fill=fill, outline=outline)
	if len(pts) >= 2 and width:
		g.line(pts + [pts[0]], fill=outline, width=width)


def overlay_site(level1, site, cal):
	im = Image.open(ROOT / "reference" / "site_plan_native.png").convert("RGBA")
	layer = Image.new("RGBA", im.size, (0, 0, 0, 0))
	g = ImageDraw.Draw(layer)
	to_px = pixel_mapper(cal)
	for room in level1["rooms"]:
		color = COLORS.get(room["type"], (80, 80, 80))
		pts = [to_px(x, z) for x, z in room["polygon"]]
		draw_poly(g, pts, color + (60,), color + (230,), 2)
	foot = [to_px(x, z) for x, z in site["footprint"]]
	g.line(foot + [foot[0]], fill=(0, 220, 255, 255), width=3)
	out = Image.alpha_composite(im, layer).convert("RGB")
	tag = ImageDraw.Draw(out)
	tag.rectangle((8, 8, 430, 52), fill=(255, 255, 255))
	tag.text((14, 12), "Level 1 rooms on site plan. Cyan = OSM footprint.", fill=(0, 0, 0), font=font(16, True))
	path = OUT / "overlay_site.png"
	out.save(path)
	return path


def overlay_osm(level1, site, raw_osm, iou):
	pts = [p for r in level1["rooms"] for p in r["polygon"]] + list(site["footprint"])
	xs = [p[0] for p in pts]
	zs = [p[1] for p in pts]
	x0, x1 = min(xs) - 20, max(xs) + 20
	z0, z1 = min(zs) - 20, max(zs) + 20
	scale = 2.4
	w, h = int((x1 - x0) * scale) + 40, int((z1 - z0) * scale) + 70
	im = Image.new("RGB", (w, h), "white")
	g = ImageDraw.Draw(im)

	def t(p):
		return (20 + (p[0] - x0) * scale, 46 + (p[1] - z0) * scale)

	raw = [t(p) for p in raw_osm]
	g.polygon(raw, outline=(220, 60, 60))
	g.line(raw + [raw[0]], fill=(220, 60, 60), width=2)
	for room in level1["rooms"]:
		color = COLORS.get(room["type"], (80, 80, 80))
		poly = [t(p) for p in room["polygon"]]
		g.polygon(poly, fill=tuple(min(255, c + 40) for c in color), outline=color)
	foot = [t(p) for p in site["footprint"]]
	g.line(foot + [foot[0]], fill=(0, 140, 180), width=3)
	g.text((16, 10), f"Red = OSM way 112472416. Cyan = orthogonal footprint. IoU {iou:.4f}.", fill="black", font=font(16, True))
	path = OUT / "overlay_osm.png"
	im.save(path)
	return path


def labeled_plan(level_name):
	d = load(f"{level_name}.json")
	pts = [p for r in d["rooms"] for p in r["polygon"]]
	x0, z0 = min(p[0] for p in pts) - 8, min(p[1] for p in pts) - 8
	x1, z1 = max(p[0] for p in pts) + 8, max(p[1] for p in pts) + 8
	scale = 2.3
	im = Image.new("RGB", (int((x1 - x0) * scale) + 30, int((z1 - z0) * scale) + 70), "white")
	g = ImageDraw.Draw(im)
	label = font(11)
	title = font(18, True)

	def t(p):
		return (16 + (p[0] - x0) * scale, 40 + (p[1] - z0) * scale)

	for room in d["rooms"]:
		color = COLORS.get(room["type"], (220, 220, 220))
		fill = tuple(min(255, c + 50) for c in color)
		g.polygon([t(p) for p in room["polygon"]], fill=fill, outline=(40, 40, 40))
	for wall in d["walls"]:
		g.line([t(wall["a"]), t(wall["b"])], fill=(15, 15, 15), width=2)
		ax, az = wall["a"]
		bx, bz = wall["b"]
		length = max(((bx - ax) ** 2 + (bz - az) ** 2) ** 0.5, 1e-6)
		ux, uz = (bx - ax) / length, (bz - az) / length
		for opening in wall.get("openings", []):
			s = opening.get("offset", 0)
			e = s + opening.get("width", 3)
			color = (30, 90, 220) if opening.get("type") in ("window", "curtainwall") else (200, 40, 30)
			g.line([t((ax + ux * s, az + uz * s)), t((ax + ux * e, az + uz * e))], fill=color, width=3)
	small = font(9)
	for room in d["rooms"]:
		xs = [p[0] for p in room["polygon"]]
		zs = [p[1] for p in room["polygon"]]
		w, h = max(xs) - min(xs), max(zs) - min(zs)
		if w * h < 120:
			continue
		c = t(((min(xs) + max(xs)) / 2, (min(zs) + max(zs)) / 2))
		if min(w, h) < 22:
			text = room["id"].replace("racquetball_", "RB").replace("office_", "Off ").replace("restroom", "RR")
			g.text((c[0] - 18, c[1] - 6), text[:12], fill="black", font=small)
		else:
			text = f"{room.get('name', room['id'])[:18]}\n{w:.0f} x {h:.0f}"
			g.multiline_text((c[0] - 32, c[1] - 12), text, fill="black", font=label)
	n_rooms = sum(1 for r in d["rooms"] if r["type"] != "void")
	g.text((16, 8), f"{level_name}   {n_rooms} rooms   {len(d['walls'])} walls   red=door  blue=window", fill="black", font=title)
	g.line([(16, im.height - 18), (16 + 50 * scale, im.height - 18)], fill="black", width=3)
	g.text((16, im.height - 36), "50 ft", fill="black", font=label)
	path = OUT / f"overlay_{level_name}.png"
	im.save(path)
	return path


def main():
	OUT.mkdir(parents=True, exist_ok=True)
	level1 = load("level1.json")
	site = load("site.json")
	cal = load("calibration.json")
	raw, _orth, _lat, _lon = bb.footprint_from_osm()
	iou = bb.raster_iou(raw, np.array(site["footprint"], dtype=np.float64), 0.5)
	overlay_site(level1, site, cal)
	overlay_osm(level1, site, raw.tolist(), iou)
	labeled_plan("level1")
	labeled_plan("level2")
	print(f"footprint IoU vs OSM {iou:.4f}")
	for court in cal["courts"]:
		print(court["name"], court["measuredFt"], "vs", court["regulationFt"], "err", court["error"])


if __name__ == "__main__":
	main()
