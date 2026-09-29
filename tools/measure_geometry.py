"""Refine scale, court sizes, and the OSM-to-blueprint rotation. Debug only."""

from __future__ import annotations

import json
import math
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "verification" / "M1"
FT = 3.280839895


def osm_pts():
	data = json.loads((ROOT / "reference" / "osm_rac_area.json").read_text(encoding="utf-8"))
	way = next(e for e in data["elements"] if e.get("id") == 112472416)
	g = way["geometry"]
	if g[0] == g[-1]:
		g = g[:-1]
	lat0 = sum(p["lat"] for p in g) / len(g)
	lon0 = sum(p["lon"] for p in g) / len(g)
	m_lat = 111320.0
	m_lon = 111320.0 * math.cos(math.radians(lat0))
	pts = np.array(
		[[(p["lon"] - lon0) * m_lon * FT, (p["lat"] - lat0) * m_lat * FT] for p in g],
		dtype=np.float64,
	)
	return pts, lat0, lon0


def rotate(pts, deg):
	a = math.radians(deg)
	c, s = math.cos(a), math.sin(a)
	R = np.array([[c, s], [-s, c]])
	return pts @ R.T


def to_bp(enu, theta_deg):
	"""theta = CCW rotation of building +X from true east. Returns x, z with +X building-east, +Z building-south."""
	a = math.radians(theta_deg)
	c, s = math.cos(a), math.sin(a)
	east, north = enu[:, 0], enu[:, 1]
	x = east * c + north * s
	z = east * s - north * c
	return np.stack([x, z], axis=1)


def edge_angles(pts):
	out = []
	for i, (a, b) in enumerate(zip(pts, np.roll(pts, -1, axis=0))):
		d = b - a
		L = float(np.linalg.norm(d))
		bearing = math.degrees(math.atan2(d[0], d[1]))  # clockwise from north
		out.append((i, L, bearing))
	return out


def axis_residual(pts):
	"""Weighted mean absolute degrees off the nearest axis, for edges > 20 ft."""
	num = den = 0.0
	for _, L, bearing in edge_angles(pts):
		if L < 20:
			continue
		# angle of the edge relative to nearest axis (0/90)
		a = bearing % 90
		off = min(a, 90 - a)
		num += off * L
		den += L
	return num / den if den else 99


def raster_iou(a_pts, b_pts, res=0.5):
	allp = np.vstack([a_pts, b_pts])
	minx, miny = allp.min(axis=0) - 1
	maxx, maxy = allp.max(axis=0) + 1
	w = int((maxx - minx) / res) + 3
	h = int((maxy - miny) / res) + 3

	def mask(pts):
		m = np.zeros((h, w), np.uint8)
		pix = np.stack([(pts[:, 0] - minx) / res, (pts[:, 1] - miny) / res], axis=1)
		cv2.fillPoly(m, [np.round(pix).astype(np.int32)], 1)
		return m

	A, B = mask(a_pts), mask(b_pts)
	inter = int(np.logical_and(A, B).sum())
	union = int(np.logical_or(A, B).sum())
	return inter / union if union else 0.0


def orthogonalize(pts, snap=0.5):
	"""Force each edge horizontal or vertical in an already near-axis frame. pts are Nx2."""
	p = pts.copy()
	n = len(p)
	# decide edge orientation from original
	horiz = []
	for i in range(n):
		a, b = p[i], p[(i + 1) % n]
		horiz.append(abs(b[0] - a[0]) >= abs(b[1] - a[1]))
	# assign each vertex's x from vertical edges and z from horizontal edges via averaging
	# simpler: walk and project each edge
	q = p.copy()
	for i in range(n):
		j = (i + 1) % n
		if horiz[i]:
			z = snap * round(((q[i, 1] + q[j, 1]) / 2) / snap)
			q[i, 1] = z
			q[j, 1] = z
		else:
			x = snap * round(((q[i, 0] + q[j, 0]) / 2) / snap)
			q[i, 0] = x
			q[j, 0] = x
	# a second pass resolves conflicts (vertex touched by both)
	for i in range(n):
		prev = (i - 1) % n
		# incoming edge orientation decides which coord this vertex keeps from that edge
		if horiz[prev]:
			q[i, 1] = snap * round(q[i, 1] / snap)
		else:
			q[i, 0] = snap * round(q[i, 0] / snap)
		if horiz[i]:
			q[i, 1] = snap * round(q[i, 1] / snap)
		else:
			q[i, 0] = snap * round(q[i, 0] / snap)
	# drop duplicate consecutive
	keep = [0]
	for i in range(1, n):
		if np.linalg.norm(q[i] - q[keep[-1]]) > 0.2:
			keep.append(i)
	q = q[keep]
	if np.linalg.norm(q[0] - q[-1]) < 0.2:
		q = q[:-1]
	return q


def measure_scale(gray):
	"""Find the 0–100 ft scale bar by the row with ticks. Returns (x0, x1, y, ft_per_px)."""
	h, w = gray.shape
	# The bar is a long dark horizontal stroke near the bottom-left.
	best = None
	for y in range(h - 180, h - 20):
		row = gray[y, 40:450]
		mask = row < 80
		d = np.diff(mask.astype(np.int8))
		starts = list(np.where(d == 1)[0] + 1)
		ends = list(np.where(d == -1)[0] + 1)
		if mask[0]:
			starts = [0] + starts
		if mask[-1]:
			ends = ends + [len(mask)]
		for s, e in zip(starts, ends):
			if 80 < (e - s) < 200:
				score = e - s
				if best is None or score > best[0]:
					best = (score, y, 40 + s, 40 + e)
	return best


def main():
	im = cv2.imread(str(ROOT / "reference" / "site_plan_native.png"))
	gray = cv2.cvtColor(im, cv2.COLOR_BGR2GRAY)
	bar = measure_scale(gray)
	print("scale bar px", bar, "ft/px", 100 / bar[0] if bar else None)

	# zoom the bar
	if bar:
		_, y, x0, x1 = bar
		crop = im[y - 25 : y + 25, x0 - 30 : x1 + 30]
		cv2.imwrite(str(OUT / "dbg_scalebar.png"), cv2.resize(crop, None, fx=3, fy=3, interpolation=cv2.INTER_NEAREST))

	pts, lat0, lon0 = osm_pts()
	print("search theta for minimum axis residual")
	best = None
	for k in range(-200, 200):
		th = k / 10  # degrees
		bp = to_bp(pts, th)
		res = axis_residual(bp)
		if best is None or res < best[0]:
			best = (res, th)
	print("best theta", best)

	# finer
	center = best[1]
	best = None
	for k in range(-50, 51):
		th = center + k / 100
		bp = to_bp(pts, th)
		res = axis_residual(bp)
		if best is None or res < best[0]:
			best = (res, th)
	print("fine theta", best)
	theta = best[1]
	bp = to_bp(pts, theta)
	print("bp bbox", bp.min(0), bp.max(0), "size", bp.max(0) - bp.min(0))
	for i, L, bearing in edge_angles(bp):
		if L > 15:
			print(f"  bp edge {i}: {L:.1f} ft  atan2(dz,dx)={math.degrees(math.atan2(bp[(i+1)%len(bp),1]-bp[i,1], bp[(i+1)%len(bp),0]-bp[i,0])):.2f}")

	orth = orthogonalize(bp, 0.5)
	print("orth verts", len(orth), "iou", round(raster_iou(bp, orth, 0.5), 4))
	print("orth", np.round(orth, 1).tolist())

	# plot OSM in blueprint frame
	pad = 20
	scale = 1.6
	xs, zs = bp[:, 0], bp[:, 1]
	W = int((xs.max() - xs.min() + 2 * pad) * scale)
	H = int((zs.max() - zs.min() + 2 * pad) * scale)
	canvas = Image.new("RGB", (W, H), "white")
	dr = ImageDraw.Draw(canvas)

	def tx(p):
		return ((p[0] - xs.min() + pad) * scale, (p[1] - zs.min() + pad) * scale)

	dr.polygon([tx(p) for p in bp], outline="black", fill=(230, 230, 230))
	dr.polygon([tx(p) for p in orth], outline="red")
	for i, p in enumerate(bp):
		dr.text(tx(p), str(i), fill="blue")
	canvas.save(OUT / "dbg_osm_bp.png")
	print("lat", lat0, "lon", lon0, "theta", theta)


if __name__ == "__main__":
	main()
