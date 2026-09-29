"""Fit the GMU site-plan image to OSM way 112472416 and measure the drawn courts.

Writes blueprint/calibration.json and debug images under verification/M1/.
"""

from __future__ import annotations

import json
import math
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "verification" / "M1"
OUT.mkdir(parents=True, exist_ok=True)
FT = 3.280839895


def osm_enu():
	data = json.loads((ROOT / "reference" / "osm_rac_area.json").read_text(encoding="utf-8"))
	way = next(e for e in data["elements"] if e.get("id") == 112472416)
	g = way["geometry"]
	if g[0] == g[-1]:
		g = g[:-1]
	lat0 = sum(p["lat"] for p in g) / len(g)
	lon0 = sum(p["lon"] for p in g) / len(g)
	m_lat = 111320.0
	m_lon = 111320.0 * math.cos(math.radians(lat0))
	# east, north in feet
	pts = np.array(
		[[(p["lon"] - lon0) * m_lon * FT, (p["lat"] - lat0) * m_lat * FT] for p in g],
		dtype=np.float64,
	)
	return pts, lat0, lon0, way


def longest_dark_run(gray, y0, y1, x0, x1, thresh=70):
	band = gray[y0:y1, x0:x1]
	best = None
	for i, row in enumerate(band):
		mask = row < thresh
		d = np.diff(mask.astype(np.int8))
		starts = list(np.where(d == 1)[0] + 1)
		ends = list(np.where(d == -1)[0] + 1)
		if mask[0]:
			starts = [0] + starts
		if mask[-1]:
			ends = ends + [len(mask)]
		for s, e in zip(starts, ends):
			if best is None or (e - s) > best[0]:
				best = (int(e - s), int(y0 + i), int(x0 + s), int(x0 + e))
	return best


def polygon_area(pts):
	x, y = pts[:, 0], pts[:, 1]
	return float(0.5 * abs(np.dot(x, np.roll(y, -1)) - np.dot(y, np.roll(x, -1))))


def principal_angle(pts):
	c = pts.mean(axis=0)
	d = pts - c
	cov = d.T @ d
	vals, vecs = np.linalg.eigh(cov)
	v = vecs[:, int(np.argmax(vals))]
	ang = math.degrees(math.atan2(v[1], v[0]))
	return ang


def raster_iou(a_pts, b_pts, res=1.0):
	"""IoU of two polygons rasterized on a 1-ft grid."""
	allp = np.vstack([a_pts, b_pts])
	minx, miny = allp.min(axis=0) - 2
	maxx, maxy = allp.max(axis=0) + 2
	w = int((maxx - minx) / res) + 1
	h = int((maxy - miny) / res) + 1

	def mask(pts):
		m = np.zeros((h, w), np.uint8)
		pix = np.stack([((pts[:, 0] - minx) / res), ((pts[:, 1] - miny) / res)], axis=1)
		cv2.fillPoly(m, [np.round(pix).astype(np.int32)], 1)
		return m

	A, B = mask(a_pts), mask(b_pts)
	inter = int(np.logical_and(A, B).sum())
	union = int(np.logical_or(A, B).sum())
	return inter / union if union else 0.0, inter, union


def contour_to_poly(cnt, eps_frac=0.008):
	peri = cv2.arcLength(cnt, True)
	approx = cv2.approxPolyDP(cnt, eps_frac * peri, True)
	return approx.reshape(-1, 2).astype(np.float64)


def main():
	im = cv2.imread(str(ROOT / "reference" / "site_plan_native.png"), cv2.IMREAD_COLOR)
	hi = cv2.imread(str(ROOT / "reference" / "site_plan_hi.png"), cv2.IMREAD_COLOR)
	print("native", im.shape, "hi", None if hi is None else hi.shape)
	gray = cv2.cvtColor(im, cv2.COLOR_BGR2GRAY)
	h, w = gray.shape

	# Scale bar: bottom-left. Try several bands.
	for name, box in {
		"bottom90": (h - 90, h - 5, 0, w // 2),
		"bottom140": (h - 140, h - 20, 0, int(w * 0.55)),
		"bottom200": (h - 200, h - 40, 0, int(w * 0.6)),
	}.items():
		run = longest_dark_run(gray, *box)
		print("scale", name, run)

	# North-arrow crop
	cv2.imwrite(str(OUT / "dbg_se_corner.png"), im[h - 180 : h, w - 220 : w])
	cv2.imwrite(str(OUT / "dbg_sw_corner.png"), im[h - 180 : h, 0:280])
	cv2.imwrite(str(OUT / "dbg_scale_zone.png"), im[h - 160 : h, 0:420])

	hsv = cv2.cvtColor(im, cv2.COLOR_BGR2HSV)
	# building fills: yellow program, orange support, near-white plan paper inside the footprint
	yellow = cv2.inRange(hsv, (15, 60, 80), (45, 255, 255))
	orange = cv2.inRange(hsv, (5, 60, 80), (18, 255, 255))
	# court paper is light grey/white with black lines — include low-sat bright pixels that are NOT satellite
	paper = cv2.inRange(hsv, (0, 0, 185), (180, 55, 255))
	# satellite is green/brown; exclude it by requiring the pixel is not strongly green
	building = cv2.bitwise_or(yellow, orange)
	building = cv2.bitwise_or(building, paper)
	# knock out the legend / scale text by keeping the central mass
	k = cv2.getStructuringElement(cv2.MORPH_RECT, (5, 5))
	building = cv2.morphologyEx(building, cv2.MORPH_CLOSE, k, iterations=2)
	building = cv2.morphologyEx(building, cv2.MORPH_OPEN, k, iterations=1)
	cv2.imwrite(str(OUT / "dbg_building_mask.png"), building)

	n, labels, stats, cent = cv2.connectedComponentsWithStats(building, 8)
	# largest component that is not the whole image border
	order = np.argsort(-stats[1:, cv2.CC_STAT_AREA])
	print("building components", n - 1)
	for k_i in order[:8]:
		i = int(k_i + 1)
		x, y, ww, hh, area = stats[i]
		print(f"  cc {i}: area {area} bbox ({x},{y}) {ww}x{hh}")

	i = int(order[0] + 1)
	mask = (labels == i).astype(np.uint8) * 255
	cnts, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
	cnt = max(cnts, key=cv2.contourArea)
	poly = contour_to_poly(cnt, 0.01)
	print("footprint verts", len(poly), "area_px", cv2.contourArea(cnt))

	vis = im.copy()
	cv2.drawContours(vis, [poly.astype(np.int32)], -1, (0, 0, 255), 2)
	cv2.imwrite(str(OUT / "dbg_footprint.png"), vis)

	# Court lines: dark pixels inside the two gym rectangles. We'll locate them by hand-tuned
	# search after printing the yellow component bboxes (the gyms).
	nY, labY, stY, cY = cv2.connectedComponentsWithStats(yellow, 8)
	print("yellow", nY - 1)
	order = np.argsort(-stY[1:, cv2.CC_STAT_AREA])
	for k_i in order[:15]:
		i = int(k_i + 1)
		x, y, ww, hh, area = stY[i]
		if area < 80:
			continue
		print(f"  yel {i}: area {area} bbox ({x},{y}) {ww}x{hh} cent {cY[i]}")

	pts, lat0, lon0, way = osm_enu()
	print("osm verts", len(pts), "area_sqft", round(polygon_area(pts), 1))
	print("osm bbox", pts.min(0), pts.max(0), "size", pts.max(0) - pts.min(0))
	print("osm principal angle deg (east,north)", round(principal_angle(pts), 2))
	print("osm centroid", lat0, lon0)
	# edge lengths
	for i, (a, b) in enumerate(zip(pts, np.roll(pts, -1, axis=0))):
		L = np.linalg.norm(b - a)
		ang = math.degrees(math.atan2(b[1] - a[1], b[0] - a[0]))
		if L > 15:
			print(f"  edge {i}: {L:.1f} ft  bearing {ang:.1f}")

	np.save(OUT / "osm_enu.npy", pts)
	(OUT / "osm_pts.json").write_text(json.dumps({"lat0": lat0, "lon0": lon0, "pts_east_north_ft": pts.round(2).tolist()}, indent=2))

	# save poly
	(OUT / "site_poly_px.json").write_text(json.dumps(poly.round(1).tolist()))
	print("wrote debug")


if __name__ == "__main__":
	main()
