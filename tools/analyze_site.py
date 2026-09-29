"""Explore the site-plan image and OSM footprint. Writes debug images under verification/M1/."""

from __future__ import annotations

import json
import math
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "verification" / "M1"
OUT.mkdir(parents=True, exist_ok=True)

FT = 3.280839895


def osm_feet():
	data = json.loads((ROOT / "reference" / "osm_rac_area.json").read_text(encoding="utf-8"))
	way = next(e for e in data["elements"] if e.get("id") == 112472416)
	g = way["geometry"]
	if g[0] == g[-1]:
		g = g[:-1]
	lat0 = sum(p["lat"] for p in g) / len(g)
	lon0 = sum(p["lon"] for p in g) / len(g)
	m_lat = 111320.0
	m_lon = 111320.0 * math.cos(math.radians(lat0))
	pts = [((p["lon"] - lon0) * m_lon * FT, (p["lat"] - lat0) * m_lat * FT) for p in g]
	return np.array(pts, dtype=np.float64), lat0, lon0


def main():
	im = cv2.imread(str(ROOT / "reference" / "site_plan_native.png"), cv2.IMREAD_COLOR)
	print("image", im.shape, im.dtype)
	hsv = cv2.cvtColor(im, cv2.COLOR_BGR2HSV)
	# yellow program areas
	yellow = cv2.inRange(hsv, (15, 80, 80), (40, 255, 255))
	# orange (lockers / support)
	orange = cv2.inRange(hsv, (8, 80, 80), (18, 255, 255))
	# white addition box (high value, low sat) inside the drawing — too broad, restrict later
	white = cv2.inRange(hsv, (0, 0, 200), (180, 40, 255))
	# dark lines
	gray = cv2.cvtColor(im, cv2.COLOR_BGR2GRAY)
	dark = (gray < 80).astype(np.uint8) * 255

	cv2.imwrite(str(OUT / "dbg_yellow.png"), yellow)
	cv2.imwrite(str(OUT / "dbg_orange.png"), orange)
	cv2.imwrite(str(OUT / "dbg_white.png"), white)
	cv2.imwrite(str(OUT / "dbg_dark.png"), dark)

	# scale bar lives in the bottom ~80 px, left half. Find a long horizontal dark run.
	h, w = gray.shape
	band = gray[h - 90 : h - 10, 0 : w // 2]
	cv2.imwrite(str(OUT / "dbg_scaleband.png"), band)
	# row with the longest dark run
	best = None
	for i, row in enumerate(band):
		mask = row < 60
		# runs
		d = np.diff(mask.astype(np.int8))
		starts = list(np.where(d == 1)[0] + 1)
		ends = list(np.where(d == -1)[0] + 1)
		if mask[0]:
			starts = [0] + starts
		if mask[-1]:
			ends = ends + [len(mask)]
		for s, e in zip(starts, ends):
			if best is None or (e - s) > best[0]:
				best = (e - s, i, s, e)
	print("longest dark run in scale band: len, row, start, end", best)

	# connected components of yellow
	n, labels, stats, cent = cv2.connectedComponentsWithStats(yellow, 8)
	print("yellow components", n - 1)
	order = np.argsort(-stats[1:, cv2.CC_STAT_AREA])
	for k in order[:12]:
		i = k + 1
		x, y, ww, hh, area = stats[i]
		print(f"  yel {i}: area {area} bbox ({x},{y}) {ww}x{hh} cent {cent[i]}")

	n, labels, stats, cent = cv2.connectedComponentsWithStats(orange, 8)
	print("orange components", n - 1)
	order = np.argsort(-stats[1:, cv2.CC_STAT_AREA])
	for k in order[:15]:
		i = k + 1
		x, y, ww, hh, area = stats[i]
		if area < 30:
			continue
		print(f"  org {i}: area {area} bbox ({x},{y}) {ww}x{hh}")

	# Save a small color-quantized preview so we can see regions
	small = cv2.resize(im, (im.shape[1], im.shape[0]), interpolation=cv2.INTER_NEAREST)
	cv2.imwrite(str(OUT / "dbg_site.png"), small)

	pts, lat0, lon0 = osm_feet()
	np.save(OUT / "osm_feet.npy", pts)
	print("osm centroid lat/lon", lat0, lon0)
	print("saved", OUT)


if __name__ == "__main__":
	main()
