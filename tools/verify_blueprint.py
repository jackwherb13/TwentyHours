"""Deterministic blueprint gate. Prints one line per failure with IDs and numbers; exit 1 on any failure.

Checks the problems that previously needed a manager review: rotation, overlaps, pixel-traced rooms,
fragmented walls, catch-all rooms. Run: python tools/verify_blueprint.py
"""

import json
import math
import sys
from itertools import combinations
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BP = ROOT / "blueprint"

MAX_ROOM_VERTS = 12
IRREGULAR_OK = {"lobby", "construction", "exterior", "canopy"}
MAX_WALLS = {"level1": 350, "level2": 200}
MIN_WALL_LEN = 2.0
AXIS_TOL_DEG = 1.0
AXIS_SHARE = 0.9
MAX_ROOM_SHARE = 0.35
OVERLAP_TOL_SQFT = 4.0

fails: list[str] = []


def area(poly):
	return abs(sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(poly, poly[1:] + poly[:1]))) / 2


def clip(subject, clipper):
	"""Sutherland-Hodgman; clipper must be convex. Good enough for the rectilinear rooms we require."""

	def inside(p, a, b):
		return (b[0] - a[0]) * (p[1] - a[1]) - (b[1] - a[1]) * (p[0] - a[0]) >= 0

	def inter(p, q, a, b):
		d = (p[0] - q[0]) * (a[1] - b[1]) - (p[1] - q[1]) * (a[0] - b[0])
		if d == 0:
			return q
		t = ((p[0] - a[0]) * (a[1] - b[1]) - (p[1] - a[1]) * (a[0] - b[0])) / d
		return (p[0] + t * (q[0] - p[0]), p[1] + t * (q[1] - p[1]))

	if sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(clipper, clipper[1:] + clipper[:1])) < 0:
		clipper = clipper[::-1]
	out = subject
	for a, b in zip(clipper, clipper[1:] + clipper[:1]):
		inp, out = out, []
		if not inp:
			break
		s = inp[-1]
		for e in inp:
			if inside(e, a, b):
				if not inside(s, a, b):
					out.append(inter(s, e, a, b))
				out.append(e)
			elif inside(s, a, b):
				out.append(inter(s, e, a, b))
			s = e
	return out


def convex(poly):
	sign = 0
	n = len(poly)
	for i in range(n):
		a, b, c = poly[i], poly[(i + 1) % n], poly[(i + 2) % n]
		z = (b[0] - a[0]) * (c[1] - b[1]) - (b[1] - a[1]) * (c[0] - b[0])
		if z:
			if sign and (z > 0) != (sign > 0):
				return False
			sign = z
	return True


def bbox_area(poly):
	xs = [p[0] for p in poly]
	zs = [p[1] for p in poly]
	return (max(xs) - min(xs)) * (max(zs) - min(zs))


def check_level(name):
	path = BP / f"{name}.json"
	if not path.exists():
		fails.append(f"{name}: missing {path.name}")
		return
	d = json.loads(path.read_text())
	rooms = [r for r in d.get("rooms", []) if r.get("type") != "void"]
	walls = d.get("walls", [])

	foot = bbox_area([p for r in rooms for p in r["polygon"]]) if rooms else 0
	for r in rooms:
		poly = r["polygon"]
		if len(poly) > MAX_ROOM_VERTS and r.get("type") not in IRREGULAR_OK:
			fails.append(f"{name}: room {r['id']} has {len(poly)} vertices (max {MAX_ROOM_VERTS}) - pixel-traced?")
		if foot and area(poly) > MAX_ROOM_SHARE * foot and r.get("type") not in ("construction",):
			fails.append(f"{name}: room {r['id']} covers {area(poly) / foot:.0%} of the level - catch-all room")
		if area(poly) < 20:
			fails.append(f"{name}: room {r['id']} is a sliver ({area(poly):.1f} sqft)")

	n_ov = 0
	for a, b in combinations(rooms, 2):
		pa, pb = [tuple(p) for p in a["polygon"]], [tuple(p) for p in b["polygon"]]
		if bbox_area(pa) == 0 or bbox_area(pb) == 0:
			continue
		xa = [p[0] for p in pa]
		xb = [p[0] for p in pb]
		za = [p[1] for p in pa]
		zb = [p[1] for p in pb]
		if max(xa) <= min(xb) or max(xb) <= min(xa) or max(za) <= min(zb) or max(zb) <= min(za):
			continue
		if convex(pb):
			ov = area(clip(pa, pb)) if len(clip(pa, pb)) > 2 else 0
		elif convex(pa):
			ov = area(clip(pb, pa)) if len(clip(pb, pa)) > 2 else 0
		else:
			ov = 0
		if ov > OVERLAP_TOL_SQFT:
			n_ov += 1
			if n_ov <= 15:
				fails.append(f"{name}: rooms {a['id']} and {b['id']} overlap by {ov:.0f} sqft")

	cap = MAX_WALLS.get(name, 300)
	if len(walls) > cap:
		fails.append(f"{name}: {len(walls)} walls (max {cap}) - merge collinear segments")
	short = [w for w in walls if math.dist(w["a"], w["b"]) < MIN_WALL_LEN]
	if short:
		fails.append(f"{name}: {len(short)} walls shorter than {MIN_WALL_LEN} ft (e.g. {short[0].get('id', short[0]['a'])})")

	lens = [math.dist(w["a"], w["b"]) for w in walls]
	total = sum(lens) or 1
	aligned = 0.0
	for w, length in zip(walls, lens):
		ang = math.degrees(math.atan2(w["b"][1] - w["a"][1], w["b"][0] - w["a"][0])) % 90
		if min(ang, 90 - ang) <= AXIS_TOL_DEG:
			aligned += length
	if walls and aligned / total < AXIS_SHARE:
		fails.append(f"{name}: only {aligned / total:.0%} of wall length is axis-aligned (need {AXIS_SHARE:.0%}) - rotate the blueprint")

	print(f"{name}: {len(rooms)} rooms, {len(walls)} walls, {aligned / total:.0%} axis-aligned, {n_ov} overlaps")


for level in ("level1", "level2"):
	check_level(level)
if not (BP / "site.json").exists():
	fails.append("site: missing site.json")
elif "trueNorthDeg" not in json.loads((BP / "site.json").read_text()):
	fails.append("site: site.json lacks trueNorthDeg")

for f in fails:
	print("FAIL", f)
sys.exit(1 if fails else 0)
