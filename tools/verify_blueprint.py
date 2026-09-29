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
		try:
			from shapely.geometry import Polygon

			ov = Polygon(pa).buffer(0).intersection(Polygon(pb).buffer(0)).area
		except ImportError:
			ov = area(clip(pa, pb)) if convex(pb) and len(clip(pa, pb)) > 2 else 0
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


def point_in(poly, x, z):
	inside = False
	n = len(poly)
	for i in range(n):
		(x1, z1), (x2, z2) = poly[i], poly[(i + 1) % n]
		if (z1 > z) != (z2 > z) and x < (x2 - x1) * (z - z1) / (z2 - z1) + x1:
			inside = not inside
	return inside


def room_at(rooms, x, z):
	for r in rooms:
		if point_in(r["polygon"], x, z):
			return r["id"]
	return "OUTSIDE"


NEEDS_ACCESS = {"gym", "corridor", "lobby", "office", "fitness", "locker", "restroom", "racquetball", "storage", "support", "stair"}


def check_connectivity(name):
	"""Logic check: build a room graph from door/opening entries and require every occupiable room to be reachable
	from outside (L1) or from a stair (L2). Catches sealed rooms, missing doors, and doors that open into walls."""
	path = BP / f"{name}.json"
	if not path.exists():
		return
	d = json.loads(path.read_text())
	rooms = [r for r in d.get("rooms", []) if r.get("type") not in ("void",)]
	edges: dict[str, set[str]] = {r["id"]: set() for r in rooms}
	edges["OUTSIDE"] = set()
	dead = 0
	for w in d.get("walls", []):
		(ax, az), (bx, bz) = w["a"], w["b"]
		length = math.dist(w["a"], w["b"])
		if length == 0:
			continue
		ux, uz = (bx - ax) / length, (bz - az) / length
		nx, nz = -uz, ux
		for o in w.get("openings", []):
			if o.get("type") not in ("door", "opening"):
				continue
			m = o.get("offset", 0) + o.get("width", 3) / 2
			cx, cz = ax + ux * m, az + uz * m
			off = w.get("thickness", 0.67) / 2 + 1.0
			r1 = room_at(rooms, cx + nx * off, cz + nz * off)
			r2 = room_at(rooms, cx - nx * off, cz - nz * off)
			if r1 == r2:
				dead += 1
				if dead <= 5:
					fails.append(f"{name}: door on wall {w.get('id')} at offset {o.get('offset')} has the same space ({r1}) on both sides")
				continue
			edges[r1].add(r2)
			edges[r2].add(r1)
	start = ["OUTSIDE"] if name == "level1" else [r["id"] for r in rooms if r.get("type") == "stair"]
	if not start:
		fails.append(f"{name}: no stair rooms - upper level unreachable")
		return
	seen, todo = set(start), list(start)
	while todo:
		for nxt in edges.get(todo.pop(), ()):
			if nxt not in seen:
				seen.add(nxt)
				todo.append(nxt)
	cut = [r["id"] for r in rooms if r.get("type") in NEEDS_ACCESS and r["id"] not in seen]
	for rid in cut[:15]:
		fails.append(f"{name}: room {rid} is not reachable through any door from {'the entrance' if name == 'level1' else 'a stair'}")
	if name == "level1" and not edges["OUTSIDE"]:
		fails.append("level1: no exterior doors - building has no entrance")
	outside = 1 if "OUTSIDE" in seen else 0
	print(f"{name}: {len(seen) - outside}/{len(rooms)} rooms reachable, {dead} dead doors")


def check_stairs():
	"""Stairs must physically connect their levels with code-legal steps (rise <= 7.75 in, run >= 10 in)."""
	elev = {}
	for n, lv in ((1, "level1"), (2, "level2")):
		p = BP / f"{lv}.json"
		if p.exists():
			elev[n] = json.loads(p.read_text()).get("elevation", 0)
	stairs = []
	for lv in ("level1", "level2"):
		p = BP / f"{lv}.json"
		if p.exists():
			stairs += json.loads(p.read_text()).get("stairs", [])
	seen = set()
	for s in stairs:
		if s.get("id") in seen:
			continue
		seen.add(s.get("id"))
		a, b = s.get("fromLevel"), s.get("toLevel")
		if a not in elev or b not in elev:
			fails.append(f"stairs: {s.get('id')} connects unknown levels {a}->{b}")
			continue
		need = abs(elev[b] - elev[a])
		rise, run, n = s.get("rise", 0), s.get("run", 0), s.get("risers", 0)
		if rise > 0.646 + 1e-6:
			fails.append(f"stairs: {s.get('id')} riser {rise * 12:.1f} in > 7.75 in")
		if run < 0.833 - 1e-6:
			fails.append(f"stairs: {s.get('id')} tread {run * 12:.1f} in < 10 in")
		if n and rise and abs(n * rise - need) > 0.5 and not s.get("partial"):
			fails.append(f"stairs: {s.get('id')} climbs {n * rise:.1f} ft but levels {a}->{b} are {need:.1f} ft apart")
	print(f"stairs: {len(seen)} checked")


for level in ("level1", "level2"):
	check_level(level)
	check_connectivity(level)
check_stairs()
if not (BP / "site.json").exists():
	fails.append("site: missing site.json")
elif "trueNorthDeg" not in json.loads((BP / "site.json").read_text()):
	fails.append("site: site.json lacks trueNorthDeg")

for f in fails:
	print("FAIL", f)
sys.exit(1 if fails else 0)
