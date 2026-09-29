"""Generate the M1 blueprint packet from the calibrated site-plan fit.

Coordinate frame (feet, snapped to 0.5):
  +X east, +Z south, origin = main-entrance exterior threshold (Level 1).
  Plan north (−Z) bears trueNorthDeg = 10.43° east of true north.
Rooms are clean rectangles on the wall grid measured off reference/site_plan_native.png.
The NW addition is one L-shaped construction zone and does not overlap the Cage.
"""

from __future__ import annotations

import json
import math
from pathlib import Path

import cv2
import numpy as np

ROOT = Path(__file__).resolve().parent.parent
BP = ROOT / "blueprint"
FT = 3.280839895

# Chosen scale: OSM north-wall length / its pixel length, which also lands every
# measured court within ±4% of regulation. See calibration() for the numbers.
S = 0.7088
THETA = -10.43  # CCW degrees, building +X relative to true east
TRUE_NORTH = 10.43  # compass bearing of blueprint −Z


def snap(v: float) -> float:
	return round(v * 2) / 2


def rect(x0, z0, x1, z1):
	x0, x1 = sorted((snap(x0), snap(x1)))
	z0, z1 = sorted((snap(z0), snap(z1)))
	return [[x0, z0], [x1, z0], [x1, z1], [x0, z1]]


def shoelace(poly):
	return sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(poly, poly[1:] + poly[:1])) / 2


def ccw(poly):
	p = [[snap(x), snap(z)] for x, z in poly]
	# drop consecutive duplicates
	out = [p[0]]
	for q in p[1:]:
		if q != out[-1]:
			out.append(q)
	if len(out) > 1 and out[0] == out[-1]:
		out = out[:-1]
	if shoelace(out) < 0:
		out = out[::-1]
	return out


def room(rid, name, rtype, poly, floor, ceil_h, ceil_t, finish="painted_cmu"):
	return {
		"id": rid,
		"name": name,
		"type": rtype,
		"polygon": ccw(poly),
		"floorMaterial": floor,
		"ceilingHeight": ceil_h,
		"ceilingType": ceil_t,
		"wallFinish": finish,
	}


def R(x0, z0, x1, z1, **kw):
	return room(poly=rect(x0, z0, x1, z1), **kw)


# ---------------------------------------------------------------------------
# Level 1 room grid. Numbers are the snapped pixel→foot conversion.
# Competition gym 115 × 147 ft holds a 94×50 court the long way (E–W) with
# bleacher margins on the north and south, matching the site-plan drawing.
# ---------------------------------------------------------------------------

def level1_rooms():
	rooms = []

	# NW addition: big box north of the cage plus the fenced strip down its west side.
	# One polygon, type construction. Shares edges with the cage, no area overlap.
	rooms.append(
		room(
			"addition",
			"RAC Addition",
			"construction",
			[
				[-374, 79.5],
				[-349, 79.5],
				[-349, -42],
				[-224, -42],
				[-224, -129],
				[-374, -129],
			],
			"sealed_concrete",
			24,
			"none",
			"metal_panel",
		)
	)

	rooms.append(R(-349, -42, -200.5, 79.5, rid="cage_gym", name="Cage Gym", rtype="gym", floor="maple", ceil_h=24, ceil_t="open_joist"))
	# 12 ft north–south link between the Cage and the Competition Gym.
	rooms.append(R(-200.5, -42, -188.5, 79.5, rid="corridor_west", name="West Link", rtype="corridor", floor="terrazzo", ceil_h=10, ceil_t="act_2x4"))

	rooms.append(R(-188.5, -107.5, -73.5, 39.5, rid="competition_gym", name="Competition Gym", rtype="gym", floor="maple", ceil_h=32, ceil_t="open_joist"))

	# Four regulation racquetball courts (40 × 20) opening south onto the concourse.
	rb = [
		("racquetball_1", -188.5, -168.5),
		("racquetball_2", -168.5, -148.5),
		("racquetball_3", -148.5, -128.5),
		("racquetball_4", -128.5, -108.5),
	]
	for i, (rid, x0, x1) in enumerate(rb, 1):
		rooms.append(R(x0, 39.5, x1, 79.5, rid=rid, name=f"Racquetball {i}", rtype="racquetball", floor="maple", ceil_h=20, ceil_t="act_2x2"))
	rooms.append(R(-108.5, 39.5, -88.5, 79.5, rid="group_exercise", name="Group Exercise", rtype="fitness", floor="rubber", ceil_h=12, ceil_t="act_2x2"))
	rooms.append(R(-88.5, 39.5, -73.5, 79.5, rid="corridor_link", name="Gym Link", rtype="corridor", floor="terrazzo", ceil_h=10, ceil_t="act_2x4"))

	# Main east–west concourse south of the gyms.
	rooms.append(R(-264.5, 79.5, -73.5, 114, rid="corridor_main", name="Main Concourse", rtype="corridor", floor="terrazzo", ceil_h=10, ceil_t="act_2x4"))

	# South wall is the orthogonal OSM edge (z=219), not the 4° site-plan kink (pixel y=652 → z=224).
	rooms.append(R(-231.5, 114, -94, 219, rid="south_gym", name="South Gym", rtype="gym", floor="maple", ceil_h=28, ceil_t="open_joist"))
	rooms.append(R(-264.5, 114, -231.5, 141, rid="mechanical_sw", name="Mechanical", rtype="mechanical", floor="sealed_concrete", ceil_h=12, ceil_t="none"))

	# Office wing, double-loaded on a 12 ft corridor. Stair at the west end.
	rooms.append(R(-352.5, 79.5, -340, 104, rid="office_nw", name="Office", rtype="office", floor="carpet_tile", ceil_h=9, ceil_t="act_2x2"))
	rooms.append(R(-340, 79.5, -312, 104, rid="office_n1", name="Office", rtype="office", floor="carpet_tile", ceil_h=9, ceil_t="act_2x2"))
	rooms.append(R(-312, 79.5, -288, 104, rid="office_n2", name="Office", rtype="office", floor="carpet_tile", ceil_h=9, ceil_t="act_2x2"))
	rooms.append(R(-288, 79.5, -264.5, 104, rid="office_n3", name="Office", rtype="office", floor="carpet_tile", ceil_h=9, ceil_t="act_2x2"))
	rooms.append(R(-340, 104, -264.5, 116, rid="corridor_office", name="Office Corridor", rtype="corridor", floor="carpet_tile", ceil_h=9, ceil_t="act_2x2"))
	rooms.append(R(-352.5, 104, -340, 141, rid="stair_west", name="West Stair", rtype="stair", floor="sealed_concrete", ceil_h=16, ceil_t="gypsum"))
	rooms.append(R(-340, 116, -312, 141, rid="restroom_office", name="Restroom", rtype="restroom", floor="ceramic_tile", ceil_h=9, ceil_t="gypsum"))
	rooms.append(R(-312, 116, -288, 141, rid="office_s1", name="Office", rtype="office", floor="carpet_tile", ceil_h=9, ceil_t="act_2x2"))
	rooms.append(R(-288, 116, -264.5, 141, rid="office_s2", name="Office", rtype="office", floor="carpet_tile", ceil_h=9, ceil_t="act_2x2"))

	# Northeast support core (lockers, restrooms, stair) off the Competition Gym.
	rooms.append(R(-73.5, -107.5, -55, -75, rid="restroom_ne_w", name="Restroom", rtype="restroom", floor="ceramic_tile", ceil_h=9, ceil_t="gypsum"))
	rooms.append(R(-55, -107.5, -40, -75, rid="restroom_ne_m", name="Restroom", rtype="restroom", floor="ceramic_tile", ceil_h=9, ceil_t="gypsum"))
	rooms.append(R(-40, -107.5, -0.5, -75, rid="stair_ne", name="Northeast Stair", rtype="stair", floor="sealed_concrete", ceil_h=16, ceil_t="gypsum"))
	rooms.append(R(-73.5, -75, -0.5, -47, rid="corridor_ne", name="Northeast Corridor", rtype="corridor", floor="terrazzo", ceil_h=10, ceil_t="act_2x4"))
	rooms.append(R(-73.5, -47, -37, -19, rid="locker_volleyball", name="Volleyball Locker Room", rtype="locker", floor="porcelain_tile", ceil_h=9, ceil_t="act_2x2"))
	rooms.append(R(-37, -47, -0.5, -19, rid="locker_general", name="Locker Room", rtype="locker", floor="porcelain_tile", ceil_h=9, ceil_t="act_2x2"))

	# East wing: lobby (curtain wall on the east), fitness, weight room.
	rooms.append(R(-73.5, -19, -0.5, 17.5, rid="lobby", name="Lobby", rtype="lobby", floor="porcelain_tile", ceil_h=32, ceil_t="gypsum"))
	rooms.append(R(-73.5, 17.5, -0.5, 66.5, rid="fitness_center", name="Fitness Center", rtype="fitness", floor="rubber", ceil_h=12, ceil_t="act_2x2"))
	rooms.append(R(-73.5, 66.5, -0.5, 102, rid="weight_room", name="Weight Room", rtype="fitness", floor="rubber", ceil_h=12, ceil_t="act_2x2"))
	return rooms


def level2_rooms():
	"""Upper floor. Gyms and the lobby well are voids. Racquetball is 20 ft, so nothing sits on it."""
	rooms = []
	rooms.append(room("void_competition", "Open to Competition Gym", "void", rect(-188.5, -107.5, -73.5, 39.5), "maple", 0, "none"))
	rooms.append(room("void_south", "Open to South Gym", "void", rect(-231.5, 114, -94, 219), "maple", 0, "none"))
	rooms.append(room("void_cage", "Open to Cage", "void", rect(-349, -42, -200.5, 79.5), "maple", 0, "none"))
	rooms.append(room("void_lobby", "Lobby Well", "void", rect(-58, -19, -0.5, 17.5), "porcelain_tile", 0, "none"))

	# Addition upper floor — still one construction zone, north of the cage void.
	rooms.append(
		room(
			"addition_l2",
			"RAC Addition",
			"construction",
			rect(-374, -129, -224, -42),
			"sealed_concrete",
			12,
			"none",
			"metal_panel",
		)
	)

	rooms.append(R(-40, -107.5, -0.5, -75, rid="stair_ne", name="Northeast Stair", rtype="stair", floor="sealed_concrete", ceil_h=10, ceil_t="gypsum"))
	rooms.append(R(-352.5, 104, -340, 141, rid="stair_west", name="West Stair", rtype="stair", floor="sealed_concrete", ceil_h=10, ceil_t="gypsum"))
	# Above the Level 1 restrooms, on the competition-gym east wall. IMG_0336 is this window band.
	# Racquetball is 20 ft clear, so Level 2 does not sit on those courts.
	rooms.append(R(-73.5, -107.5, -40, -75, rid="corridor_l2_gym", name="Gym Viewing", rtype="corridor", floor="terrazzo", ceil_h=10, ceil_t="act_2x4"))

	rooms.append(R(-73.5, -75, -0.5, -47, rid="corridor_l2_north", name="Upper Northeast Corridor", rtype="corridor", floor="terrazzo", ceil_h=10, ceil_t="act_2x4"))
	rooms.append(R(-73.5, -47, -58, -19, rid="corridor_l2_ne", name="Upper Corridor", rtype="corridor", floor="terrazzo", ceil_h=10, ceil_t="act_2x4"))
	rooms.append(R(-58, -47, -0.5, -19, rid="mechanical_l2", name="Mechanical", rtype="mechanical", floor="sealed_concrete", ceil_h=10, ceil_t="none"))
	rooms.append(R(-73.5, -19, -58, 17.5, rid="balcony", name="Lobby Balcony", rtype="lobby", floor="porcelain_tile", ceil_h=12, ceil_t="gypsum"))
	rooms.append(R(-73.5, 17.5, -58, 102, rid="corridor_l2_east", name="Upper East Corridor", rtype="corridor", floor="terrazzo", ceil_h=10, ceil_t="act_2x4"))
	rooms.append(R(-58, 17.5, -0.5, 66.5, rid="conference", name="Conference", rtype="office", floor="carpet_tile", ceil_h=10, ceil_t="act_2x2"))
	rooms.append(R(-58, 66.5, -0.5, 102, rid="office_l2_east", name="Office", rtype="office", floor="carpet_tile", ceil_h=9, ceil_t="act_2x2"))

	# Viewing concourse — same footprint as the Level 1 main concourse, windows into the gyms.
	rooms.append(R(-264.5, 79.5, -73.5, 114, rid="corridor_l2", name="Upper Concourse", rtype="corridor", floor="terrazzo", ceil_h=10, ceil_t="act_2x4"))
	rooms.append(R(-108.5, 39.5, -73.5, 79.5, rid="lounge_l2", name="Gym Viewing", rtype="lobby", floor="terrazzo", ceil_h=10, ceil_t="act_2x2"))

	rooms.append(R(-352.5, 79.5, -340, 104, rid="office_l2_nw", name="Office", rtype="office", floor="carpet_tile", ceil_h=9, ceil_t="act_2x2"))
	rooms.append(R(-340, 79.5, -312, 104, rid="office_l2_n1", name="Office", rtype="office", floor="carpet_tile", ceil_h=9, ceil_t="act_2x2"))
	rooms.append(R(-312, 79.5, -288, 104, rid="office_l2_n2", name="Office", rtype="office", floor="carpet_tile", ceil_h=9, ceil_t="act_2x2"))
	rooms.append(R(-288, 79.5, -264.5, 104, rid="office_l2_n3", name="Office", rtype="office", floor="carpet_tile", ceil_h=9, ceil_t="act_2x2"))
	rooms.append(R(-340, 104, -264.5, 116, rid="corridor_l2_office", name="Upper Office Corridor", rtype="corridor", floor="carpet_tile", ceil_h=9, ceil_t="act_2x2"))
	rooms.append(R(-340, 116, -312, 141, rid="restroom_l2", name="Restroom", rtype="restroom", floor="ceramic_tile", ceil_h=9, ceil_t="gypsum"))
	rooms.append(R(-312, 116, -288, 141, rid="office_l2_s1", name="Office", rtype="office", floor="carpet_tile", ceil_h=9, ceil_t="act_2x2"))
	rooms.append(R(-288, 116, -264.5, 141, rid="office_l2_s2", name="Office", rtype="office", floor="carpet_tile", ceil_h=9, ceil_t="act_2x2"))
	rooms.append(R(-264.5, 114, -231.5, 141, rid="storage_l2", name="Storage", rtype="storage", floor="sealed_concrete", ceil_h=9, ceil_t="act_2x2"))
	return rooms


# Door pairs: (room_a, room_b or "OUTSIDE", width, type). The opening is centered
# on the longest shared edge. OUTSIDE doors are added explicitly.
DOOR_PAIRS_L1 = [
	("lobby", "competition_gym", 6, "door"),
	("lobby", "fitness_center", 8, "opening"),
	("lobby", "locker_volleyball", 3, "door"),
	("lobby", "locker_general", 3, "door"),
	("fitness_center", "weight_room", 6, "opening"),
	("weight_room", "corridor_main", 5, "door"),
	("competition_gym", "corridor_link", 6, "door"),
	("competition_gym", "corridor_ne", 5, "door"),
	("competition_gym", "corridor_west", 6, "door"),
	("corridor_link", "corridor_main", 5, "door"),
	("corridor_link", "group_exercise", 4, "door"),
	("group_exercise", "corridor_main", 4, "door"),
	("racquetball_1", "corridor_main", 3, "door"),
	("racquetball_2", "corridor_main", 3, "door"),
	("racquetball_3", "corridor_main", 3, "door"),
	("racquetball_4", "corridor_main", 3, "door"),
	("cage_gym", "corridor_main", 6, "door"),
	("cage_gym", "corridor_west", 4, "door"),
	("corridor_west", "corridor_main", 4, "door"),
	("south_gym", "corridor_main", 8, "door"),
	("mechanical_sw", "corridor_main", 3, "door"),
	("corridor_office", "corridor_main", 3, "door"),
	("corridor_office", "stair_west", 4, "door"),
	("corridor_office", "office_n1", 3, "door"),
	("corridor_office", "office_n2", 3, "door"),
	("corridor_office", "office_n3", 3, "door"),
	("corridor_office", "restroom_office", 3, "door"),
	("corridor_office", "office_s1", 3, "door"),
	("corridor_office", "office_s2", 3, "door"),
	("office_nw", "stair_west", 3, "door"),
	("corridor_ne", "stair_ne", 5, "door"),
	("corridor_ne", "restroom_ne_w", 3, "door"),
	("corridor_ne", "restroom_ne_m", 3, "door"),
	("corridor_ne", "locker_volleyball", 3, "door"),
	("corridor_ne", "locker_general", 3, "door"),
	("corridor_ne", "competition_gym", 0, "skip"),  # listed above
]

DOOR_PAIRS_L2 = [
	("stair_ne", "corridor_l2_north", 5, "door"),
	("stair_ne", "corridor_l2_gym", 4, "door"),
	("corridor_l2_gym", "corridor_l2_north", 4, "door"),
	("corridor_l2_north", "corridor_l2_ne", 4, "door"),
	("corridor_l2_north", "mechanical_l2", 3, "door"),
	("corridor_l2_ne", "balcony", 5, "opening"),
	("balcony", "corridor_l2_east", 5, "opening"),
	("corridor_l2_east", "corridor_l2", 5, "door"),
	("corridor_l2_east", "conference", 3, "door"),
	("corridor_l2_east", "office_l2_east", 3, "door"),
	("conference", "office_l2_east", 3, "door"),
	("corridor_l2", "lounge_l2", 6, "opening"),
	("corridor_l2", "corridor_l2_office", 3, "door"),
	("corridor_l2", "storage_l2", 3, "door"),
	("corridor_l2_office", "stair_west", 4, "door"),
	("corridor_l2_office", "office_l2_n1", 3, "door"),
	("corridor_l2_office", "office_l2_n2", 3, "door"),
	("corridor_l2_office", "office_l2_n3", 3, "door"),
	("corridor_l2_office", "restroom_l2", 3, "door"),
	("corridor_l2_office", "office_l2_s1", 3, "door"),
	("corridor_l2_office", "office_l2_s2", 3, "door"),
	("office_l2_nw", "stair_west", 3, "door"),
]

# Explicit openings that are not a door centered on a shared room edge.
# (p, q, width, type, sill, head, extra)
L1_EXTRAS = [
	((-0.5, -8), (-0.5, 4), 6, "door", 0, 7, {"leaves": 2, "tag": "RACDoor"}),
	((-0.5, -19), (-0.5, 17.5), 32, "curtainwall", 0, 28, {"mullionSpacing": 5}),
	((-0.5, 22), (-0.5, 60), 24, "window", 3, 10, None),
	((-0.5, 70), (-0.5, 98), 16, "window", 3, 10, None),
	# Competition-gym clerestory on the north exterior wall (IMG_0332). The south wall is racquetball.
	((-170, -107.5), (-100, -107.5), 40, "window", 22, 30, None),
	((-200, 219), (-130, 219), 40, "window", 18, 26, None),
	((-120, 219), (-100, 219), 4, "door", 0, 7, {"leaves": 1, "tag": "Service"}),
	((-352.5, 110), (-352.5, 130), 3, "door", 0, 7, {"leaves": 1}),
]

# Level 2 windows into the double-height gyms (IMG_0336, the upper glass band).
L2_EXTRAS = [
	((-73.5, -100), (-73.5, -80), 16, "window", 3, 8, None),
	((-73.5, -70), (-73.5, -50), 16, "window", 3, 8, None),
	((-73.5, -44), (-73.5, -22), 16, "window", 3, 8, None),
	((-73.5, -14), (-73.5, 12), 20, "window", 3, 8, None),
	((-73.5, 20), (-73.5, 36), 12, "window", 3, 8, None),
	((-100, 39.5), (-78, 39.5), 16, "window", 3, 8, None),
	((-210, 114), (-120, 114), 40, "window", 3, 8, None),
]


def edges_of(poly):
	return list(zip(poly, poly[1:] + poly[:1]))


def shared_edge(pa, pb, tol=0.2):
	"""Longest overlapping collinear boundary between two polygons, as (a, b) with a→b."""
	best = None
	for a, b in edges_of(pa):
		horiz = abs(a[1] - b[1]) < tol
		for c, d in edges_of(pb):
			if horiz:
				if abs(c[1] - d[1]) > tol or abs(c[1] - a[1]) > tol:
					continue
				lo, hi = overlap_1d(a[0], b[0], c[0], d[0])
				if hi - lo < 2:
					continue
				seg = ((lo, a[1]), (hi, a[1]))
			else:
				if abs(a[0] - b[0]) > tol or abs(c[0] - d[0]) > tol or abs(c[0] - a[0]) > tol:
					continue
				lo, hi = overlap_1d(a[1], b[1], c[1], d[1])
				if hi - lo < 2:
					continue
				seg = ((a[0], lo), (a[0], hi))
			length = math.dist(seg[0], seg[1])
			if best is None or length > best[0]:
				best = (length, seg)
	return None if best is None else best[1]


def overlap_1d(a0, a1, b0, b1):
	lo = max(min(a0, a1), min(b0, b1))
	hi = min(max(a0, a1), max(b0, b1))
	return lo, hi


def collect_segments(rooms):
	"""Room-boundary segments split at every T-junction, then collinear runs merged."""
	raw = []
	for r in rooms:
		if r["type"] == "void":
			continue
		for a, b in edges_of(r["polygon"]):
			raw.append((a, b, r["id"]))

	# split
	pts_on = []
	for a, b, _ in raw:
		pts_on.append([a, b])
	for i, (a, b, _) in enumerate(raw):
		ax, az = a
		bx, bz = b
		horiz = abs(az - bz) < 1e-6
		for c, d, _ in raw:
			for p in (c, d):
				if horiz and abs(p[1] - az) < 1e-6 and min(ax, bx) - 1e-6 < p[0] < max(ax, bx) - 1e-6:
					pts_on[i].append(p)
				elif (not horiz) and abs(p[0] - ax) < 1e-6 and min(az, bz) - 1e-6 < p[1] < max(az, bz) - 1e-6:
					pts_on[i].append(p)

	pieces = []  # (a, b) canonical, set of room ids
	for (a, b, rid), pts in zip(raw, pts_on):
		horiz = abs(a[1] - b[1]) < 1e-6
		pts = sorted(set((snap(p[0]), snap(p[1])) for p in pts), key=(lambda p: p[0]) if horiz else (lambda p: p[1]))
		for p, q in zip(pts, pts[1:]):
			if math.dist(p, q) < 0.2:
				continue
			key = (p, q) if (p < q) else (q, p)
			pieces.append((key, rid))

	# group identical centerlines
	from collections import defaultdict

	groups = defaultdict(set)
	for key, rid in pieces:
		groups[key].add(rid)

	# merge collinear touching segments that bound the same room set
	# represent as horizontal (z, x0, x1) or vertical (x, z0, z1)
	horiz = defaultdict(list)  # (z, frozenset rooms) -> [ (x0,x1) ]
	vert = defaultdict(list)
	for (a, b), rids in groups.items():
		fr = frozenset(rids)
		if abs(a[1] - b[1]) < 1e-6:
			x0, x1 = sorted((a[0], b[0]))
			horiz[(a[1], fr)].append((x0, x1))
		else:
			z0, z1 = sorted((a[1], b[1]))
			vert[(a[0], fr)].append((z0, z1))

	def merge_intervals(iv):
		iv = sorted(iv)
		out = []
		for a, b in iv:
			if out and a <= out[-1][1] + 0.6:
				out[-1] = (out[-1][0], max(out[-1][1], b))
			else:
				out.append((a, b))
		return out

	segs = []  # (a, b, frozenset rooms)
	for (z, fr), iv in horiz.items():
		for x0, x1 in merge_intervals(iv):
			if x1 - x0 >= 2:
				segs.append(((x0, z), (x1, z), fr))
	for (x, fr), iv in vert.items():
		for z0, z1 in merge_intervals(iv):
			if z1 - z0 >= 2:
				segs.append(((x, z0), (x, z1), fr))
	return segs


def wall_height(rooms_by_id, rids, exterior):
	heights = [rooms_by_id[r]["ceilingHeight"] for r in rids if rooms_by_id[r]["type"] != "void"]
	if exterior:
		return max(heights + [18])
	return max(heights) if heights else 10


def build_walls(rooms, extra_openings, extras=()):
	by_id = {r["id"]: r for r in rooms}
	segs = collect_segments(rooms)
	walls = []
	for i, (a, b, rids) in enumerate(segs):
		exterior = len(rids) == 1
		# east facade of the entrance wing is metal panel / curtain wall; south and west are brick
		if exterior:
			horiz = abs(a[1] - b[1]) < 1e-6
			if any(by_id[r]["type"] == "construction" for r in rids):
				material = "metal_panel"
			elif not horiz and abs(a[0] - (-0.5)) < 0.2:
				material = "metal_panel"
			elif not horiz and a[0] < -300:
				material = "brick"
			elif horiz and a[1] > 180:
				material = "brick"
			else:
				material = "brick"
			thickness = 1.33
		else:
			# office partitions are studs; everything else is 8" CMU
			offs = [by_id[r]["type"] for r in rids]
			if offs.count("office") + offs.count("corridor") == len(offs) and "corridor" in offs and "office" in offs:
				material, thickness = "gypsum", 0.4
			else:
				material, thickness = "painted_cmu", 0.67
		h = wall_height(by_id, rids, exterior)
		# a gym wall beside a low room still runs up to the gym structure
		if any(by_id[r]["type"] == "gym" for r in rids):
			h = max(h, max(by_id[r]["ceilingHeight"] for r in rids))
		walls.append(
			{
				"id": f"w_{i+1:04d}",
				"a": [a[0], a[1]],
				"b": [b[0], b[1]],
				"thickness": thickness,
				"height": h,
				"material": material,
				"exterior": exterior,
				"openings": [],
				"_rooms": sorted(rids),
			}
		)
	place_openings(walls, rooms, extra_openings, extras)
	for w in walls:
		w.pop("_rooms", None)
	return walls


def place_openings(walls, rooms, pairs, extras=()):
	by_id = {r["id"]: r for r in rooms}

	def add_on_segment(p, q, width, typ, sill, head, extra=None):
		# find the wall containing segment midpoint
		mx, mz = (p[0] + q[0]) / 2, (p[1] + q[1]) / 2
		best = None
		for w in walls:
			ax, az = w["a"]
			bx, bz = w["b"]
			length = math.dist(w["a"], w["b"])
			# distance from point to segment
			vx, vz = bx - ax, bz - az
			t = ((mx - ax) * vx + (mz - az) * vz) / (length * length)
			if t < -0.02 or t > 1.02:
				continue
			cx, cz = ax + t * vx, az + t * vz
			if math.hypot(cx - mx, cz - mz) > 0.6:
				continue
			# how much of [p,q] lies on this wall
			if best is None or length > best[0]:
				best = (length, w, t)
		if best is None:
			print("  NO WALL for opening", typ, "at", p, q)
			return False
		_, w, _ = best
		ax, az = w["a"]
		bx, bz = w["b"]
		length = math.dist(w["a"], w["b"])
		ux, uz = (bx - ax) / length, (bz - az) / length
		# opening start is the end of [p,q] closer to a
		def dist_a(pt):
			return (pt[0] - ax) * ux + (pt[1] - az) * uz

		d0, d1 = sorted((dist_a(p), dist_a(q)))
		# center the requested width on the shared run, clamped to the wall
		center = (d0 + d1) / 2
		width = min(width, d1 - d0 - 0.5, length - 1)
		if width < 2:
			width = min(3, d1 - d0)
		start = center - width / 2
		start = max(0.5, min(start, length - width - 0.25))
		start = snap(start)
		width = snap(width)
		if start + width > length:
			width = snap(length - start)
		if width < 2:
			return False
		op = {"type": typ, "offset": start, "width": width, "sill": sill, "head": min(head, w["height"])}
		if extra:
			op.update(extra)
		# don't stack two doors on the same spot
		for existing in w["openings"]:
			if abs(existing["offset"] - op["offset"]) < 1 and existing["type"] == op["type"]:
				return True
		w["openings"].append(op)
		return True

	for a, b, width, typ in pairs:
		if typ == "skip" or width <= 0:
			continue
		if b == "OUTSIDE":
			continue
		seg = shared_edge(by_id[a]["polygon"], by_id[b]["polygon"])
		if seg is None:
			print(f"  no shared edge {a} / {b}")
			continue
		head = 7.0 if typ == "door" else 8.0
		extra = {"leaves": 2} if width >= 5 and typ == "door" else ({"leaves": 1} if typ == "door" else None)
		add_on_segment(seg[0], seg[1], width, typ, 0, head, extra)

	for p, q, width, typ, sill, head, extra in extras:
		add_on_segment(p, q, width, typ, sill, head, extra)


def columns_for(rooms):
	cols = []
	n = 1

	def grid(rid, step, inset, height, size):
		nonlocal n
		r = next(x for x in rooms if x["id"] == rid)
		xs = [p[0] for p in r["polygon"]]
		zs = [p[1] for p in r["polygon"]]
		x0, x1 = min(xs) + inset, max(xs) - inset
		z0, z1 = min(zs) + inset, max(zs) - inset
		x = x0
		while x <= x1 + 0.1:
			z = z0
			while z <= z1 + 0.1:
				cols.append({"id": f"c{n}", "at": [snap(x), snap(z)], "size": size, "height": height})
				n += 1
				z += step
			x += step

	grid("competition_gym", 28, 10, 32, [1.5, 1.5])
	grid("south_gym", 30, 8, 28, [1.5, 1.5])
	grid("cage_gym", 32, 8, 24, [1.0, 1.0])
	return cols


def stairs_for(rooms, level):
	out = []
	for rid, direction in (("stair_ne", [1, 0]), ("stair_west", [0, 1])):
		r = next(x for x in rooms if x["id"] == rid)
		out.append(
			{
				"id": rid,
				"polygon": r["polygon"],
				"fromLevel": 1,
				"toLevel": 2,
				"direction": direction,
				"risers": 28,
				"rise": 0.571,
				"run": 0.917,
				"width": 6,
			}
		)
	return out


def props_for():
	"""Anchors only — the prop library builds the meshes. Pivot is bottom-center, facing −Z."""
	return [
		{"id": "desk_lobby", "kind": "front_desk", "at": [-30, 4], "rotation": 180, "room": "lobby"},
		{"id": "hoop_comp_w", "kind": "basketball_hoop_ceiling", "at": [-160, -34], "rotation": 90, "room": "competition_gym"},
		{"id": "hoop_comp_e", "kind": "basketball_hoop_ceiling", "at": [-102, -34], "rotation": -90, "room": "competition_gym"},
		{"id": "bleacher_comp_n", "kind": "bleacher_bank", "at": [-131, -80], "rotation": 0, "room": "competition_gym"},
		{"id": "bleacher_comp_s", "kind": "bleacher_bank", "at": [-131, 16], "rotation": 180, "room": "competition_gym"},
		{"id": "vb_comp", "kind": "volleyball_standard", "at": [-131, -34], "rotation": 90, "room": "competition_gym"},
		{"id": "hoop_south_1", "kind": "basketball_hoop_ceiling", "at": [-200, 169], "rotation": 0, "room": "south_gym"},
		{"id": "hoop_south_2", "kind": "basketball_hoop_ceiling", "at": [-165, 169], "rotation": 0, "room": "south_gym"},
		{"id": "hoop_south_3", "kind": "basketball_hoop_ceiling", "at": [-130, 169], "rotation": 0, "room": "south_gym"},
		{"id": "hoop_cage", "kind": "basketball_hoop_ceiling", "at": [-275, 20], "rotation": 90, "room": "cage_gym"},
		{"id": "rack_weight", "kind": "power_rack", "at": [-40, 84], "rotation": 0, "room": "weight_room"},
		{"id": "tread_fit", "kind": "treadmill", "at": [-20, 40], "rotation": 90, "room": "fitness_center"},
		{"id": "ext_lobby", "kind": "fire_extinguisher_cabinet", "at": [-70, 2], "rotation": 90, "room": "lobby"},
		{"id": "clock_office", "kind": "wall_clock", "at": [-300, 110], "rotation": 180, "room": "corridor_office"},
	]


def footprint_from_osm():
	data = json.loads((ROOT / "reference" / "osm_rac_area.json").read_text(encoding="utf-8"))
	way = next(e for e in data["elements"] if e.get("id") == 112472416)
	g = way["geometry"]
	if g[0] == g[-1]:
		g = g[:-1]
	lat0 = sum(p["lat"] for p in g) / len(g)
	lon0 = sum(p["lon"] for p in g) / len(g)
	m_lat = 111320.0
	m_lon = 111320.0 * math.cos(math.radians(lat0))
	enu = np.array([[(p["lon"] - lon0) * m_lon * FT, (p["lat"] - lat0) * m_lat * FT] for p in g], dtype=np.float64)
	a = math.radians(THETA)
	c, s = math.cos(a), math.sin(a)
	east, north = enu[:, 0], enu[:, 1]
	raw = np.stack([east * c + north * s, east * s - north * c], axis=1)
	ent_x = (672 - 407) * S - 21.18
	ent_z = (336 - 184) * S - 164.65
	bp = raw - np.array([ent_x + 0.5, ent_z])
	orth = orthogonalize(bp)
	return bp, orth, lat0, lon0


def orthogonalize(pts):
	"""Snap a near-axis polygon onto the axes. Edges within 8° of H/V are forced."""
	p = pts.copy()
	n = len(p)
	horiz = []
	for i in range(n):
		d = p[(i + 1) % n] - p[i]
		ang = abs(math.degrees(math.atan2(d[1], d[0]))) % 180
		ang = min(ang, 180 - ang)
		horiz.append(ang < 45)
	q = p.copy()
	for _ in range(4):
		for i in range(n):
			j = (i + 1) % n
			if horiz[i]:
				z = snap((q[i, 1] + q[j, 1]) / 2)
				q[i, 1] = z
				q[j, 1] = z
			else:
				x = snap((q[i, 0] + q[j, 0]) / 2)
				q[i, 0] = x
				q[j, 0] = x
	keep = [0]
	for i in range(1, n):
		if abs(q[i, 0] - q[keep[-1], 0]) > 0.2 or abs(q[i, 1] - q[keep[-1], 1]) > 0.2:
			keep.append(i)
	q = q[keep]
	poly = [[snap(x), snap(z)] for x, z in q]
	out = [poly[0]]
	for pt in poly[1:]:
		if pt != out[-1]:
			out.append(pt)
	if len(out) > 2 and out[0] == out[-1]:
		out = out[:-1]
	# drop collinear
	cleaned = []
	m = len(out)
	for i in range(m):
		a, b, c = out[(i - 1) % m], out[i], out[(i + 1) % m]
		cross = (b[0] - a[0]) * (c[1] - b[1]) - (b[1] - a[1]) * (c[0] - b[0])
		if abs(cross) > 1e-6:
			cleaned.append(b)
	return ccw(cleaned)


def raster_iou(a_pts, b_pts, res=0.5):
	a_pts = np.asarray(a_pts, dtype=np.float64)
	b_pts = np.asarray(b_pts, dtype=np.float64)
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


def facade_and_roofs(foot):
	facade = []
	for a, b in edges_of(foot):
		horiz = abs(a[1] - b[1]) < 1e-6
		length = math.dist(a, b)
		if length < 2:
			continue
		if not horiz and abs(max(a[0], b[0]) - (-0.5)) < 2 and min(a[1], b[1]) < 20 and max(a[1], b[1]) > -20:
			style = "curtain_wall"
		elif not horiz and a[0] > -30:
			style = "metal_panel"
		elif horiz and a[1] > 150:
			style = "sunshade_fins"
		else:
			style = "brick"
		if style == "curtain_wall":
			height = 32
		elif style == "sunshade_fins":
			height = 32
		elif style == "metal_panel":
			height = 36
		else:
			height = 32
		facade.append({"a": a, "b": b, "style": style, "height": height, "base": 0})
	# precast band is the light horizontal course on the brick facades — recorded on the long south and west runs
	for seg in list(facade):
		if seg["style"] == "brick" and math.dist(seg["a"], seg["b"]) > 80:
			facade.append({**seg, "style": "precast_band", "height": 4, "base": 12})
	# Heights are feet above Level 1. Two stories: 16 ft floor-to-floor, then the upper ceiling, then structure.
	# Racquetball stays single-story (20 ft clear). The lobby and competition gym are open to 32.
	roofs = [
		{"polygon": rect(-188.5, -107.5, -73.5, 39.5), "height": 36, "type": "flat", "overhang": 2},
		{"polygon": rect(-188.5, 39.5, -108.5, 79.5), "height": 22, "type": "flat", "overhang": 1},
		{"polygon": rect(-108.5, 39.5, -73.5, 79.5), "height": 28, "type": "flat", "overhang": 1},
		{"polygon": rect(-349, -42, -200.5, 79.5), "height": 28, "type": "flat", "overhang": 1},
		{"polygon": rect(-200.5, -42, -188.5, 79.5), "height": 14, "type": "flat", "overhang": 0},
		{"polygon": rect(-374, -129, -224, -42), "height": 36, "type": "flat", "overhang": 1},
		{"polygon": rect(-352.5, 79.5, -264.5, 141), "height": 28, "type": "flat", "overhang": 1},
		{"polygon": rect(-264.5, 114, -231.5, 141), "height": 28, "type": "flat", "overhang": 0},
		{"polygon": rect(-264.5, 79.5, -73.5, 114), "height": 28, "type": "flat", "overhang": 1},
		{"polygon": rect(-231.5, 114, -94, 219), "height": 32, "type": "flat", "overhang": 2},
		{"polygon": rect(-73.5, -107.5, -0.5, -19), "height": 28, "type": "flat", "overhang": 1},
		{"polygon": rect(-73.5, -19, -0.5, 17.5), "height": 36, "type": "flat", "overhang": 1},
		{"polygon": rect(-73.5, 17.5, -0.5, 102), "height": 28, "type": "flat", "overhang": 1},
		{"polygon": rect(0, -8, 22, 18), "height": 16, "type": "canopy", "overhang": 0},
	]
	return facade, roofs


def calibration(bp_osm, orth, iou):
	# Competition court pixel box measured on site_plan_native.png (line centers).
	comp_len_px, comp_wid_px = 557 - 424, 323 - 252  # 133 x 71, length E–W
	south_len_px = 647.7 - 510.2  # full court, N–S
	south_wid_px = 473.6 - 404.0
	cross_px = 614.7 - 499.7  # 84 ft cross-court length
	bar_px = 144  # 0 to 100 ft tick, y=625, x=164..308 at threshold 70

	def err(measured, regulation):
		return round((measured - regulation) / regulation, 4)

	comp_l, comp_w = comp_len_px * S, comp_wid_px * S
	south_l, south_w = south_len_px * S, south_wid_px * S
	cross = cross_px * S
	bar_ft = bar_px * S
	return {
		"trueNorthDeg": TRUE_NORTH,
		"trueNorthDef": "Compass bearing of blueprint -Z (plan north). Plan north points 10.43 degrees east of true north. Geographic east/north map into the pre-shift frame by x = E*cos(theta) + N*sin(theta), z = E*sin(theta) - N*cos(theta), theta=-10.43 deg.",
		"thetaDeg": THETA,
		"scaleFtPerPx": S,
		"pixelAnchor": {"px": 407, "py": 184, "rawX": -21.18, "rawZ": -164.65, "note": "NW corner of the OSM north wall, which is the competition-gym north wall on the site plan"},
		"entrance": {"px": 672, "py": 336, "note": "Center of the east curtain-wall opening on the site plan. The snapped wall centerline is x=-0.5. The exterior face of the 1.33 ft wall is about x=0.2, within one snap of the origin threshold."},
		"shift": {"x": round((672 - 407) * S - 21.18 + 0.5, 4), "z": round((336 - 184) * S - 164.65, 4)},
		"scaleBar": {
			"px": bar_px,
			"labeledFt": 100,
			"measuredFtAtScale": round(bar_ft, 2),
			"error": err(bar_ft, 100),
			"where": "site_plan_native.png row 625, x=164 to 308",
		},
		"courts": [
			{
				"name": "competition_gym",
				"drawing": "regulation, length east-west",
				"px": [comp_len_px, comp_wid_px],
				"measuredFt": [round(comp_l, 2), round(comp_w, 2)],
				"regulationFt": [94, 50],
				"error": [err(comp_l, 94), err(comp_w, 50)],
			},
			{
				"name": "south_gym_full",
				"drawing": "regulation, length north-south",
				"px": [round(south_len_px, 1), round(south_wid_px, 1)],
				"measuredFt": [round(south_l, 2), round(south_w, 2)],
				"regulationFt": [94, 50],
				"error": [err(south_l, 94), err(south_w, 50)],
			},
			{
				"name": "south_gym_cross",
				"drawing": "cross court, length north-south",
				"px": [round(cross_px, 1)],
				"measuredFt": [round(cross, 2)],
				"regulationFt": [84],
				"error": [err(cross, 84)],
			},
		],
		"osm": {
			"way": 112472416,
			"iouOrthogonalVsRaw": round(iou, 4),
			"note": "Footprint is the OSM outline rotated onto the building axes and snapped to 0.5 ft. The 4-degree kink in the south wing is squared off.",
		},
	}


def photo_stations():
	"""Estimated cameras. Eye height 5.2 ft. Portrait iPhone main camera, ~55° vertical FOV.
	Look is a unit vector in blueprint axes (+X east, +Y up, +Z south)."""

	def cam(pid, pos, look, room, note):
		l = np.array(look, dtype=float)
		l = l / np.linalg.norm(l)
		return {
			"id": pid,
			"file": f"reference/photos/{pid}.jpg",
			"position": [round(pos[0], 1), 5.2, round(pos[1], 1)],
			"look": [round(float(l[0]), 3), round(float(l[1]), 3), round(float(l[2]), 3)],
			"fovVertical": 55,
			"room": room,
			"note": note,
		}

	# (id, xz, look xyz, room, note)
	rows = [
		("IMG_0314", (-160, 96), (1, -0.05, 0), "corridor_main", "long terrazzo corridor, looking east"),
		("IMG_0315", (-220, 96), (1, -0.05, 0), "corridor_main", "same concourse further west"),
		("IMG_0316", (-140, 100), (1, 0, 0.2), "corridor_main", "corridor with lockers and a glass wall"),
		("IMG_0318", (-70, 40), (1, 0, 0), "fitness_center", "through the glass into the fitness floor"),
		("IMG_0319", (-120, 90), (0, 0, 1), "corridor_main", "corridor junction, tile floor"),
		("IMG_0320", (-100, 90), (0, 0, -1), "corridor_main", "double doors into a gym"),
		("IMG_0321", (-90, 70), (-1, 0, 0), "corridor_link", "gym doors at the end of the link"),
		("IMG_0322", (-80, 55), (-1, 0, 0), "corridor_link", "sidelight windows into the competition gym"),
		("IMG_0323", (-300, 90), (0, 0, 1), "office_n2", "office reception, clock and mail slots"),
		("IMG_0324", (-310, 110), (1, 0, 0), "corridor_office", "office corridor"),
		("IMG_0325", (-300, 112), (1, -0.2, 0), "corridor_office", "office ceiling, looking along the suite"),
		("IMG_0326", (-280, 90), (0, 0, 1), "office_n3", "cubicles"),
		("IMG_0327", (-320, 88), (-1, 0, 0), "office_n1", "cubicle workstations"),
		("IMG_0328", (-40, 8), (1, 0, 0.3), "lobby", "lobby toward the fitness glass"),
		("IMG_0329", (-36, 6), (1, 0, 0), "lobby", "front desk and the lower soffit at the balcony edge"),
		("IMG_0330", (-20, 10), (-1, 0, 0), "lobby", "lobby looking back toward the curtain wall"),
		("IMG_0331", (-180, 96), (1, 0, 0), "corridor_main", "brick accent wall in the concourse"),
		("IMG_0332", (-150, -20), (1, 0.1, 0), "competition_gym", "bleachers and clerestory, looking east"),
		("IMG_0333", (-140, -10), (0, 0.15, -1), "competition_gym", "court and north wall"),
		("IMG_0334", (-120, -40), (0, 0.2, 1), "competition_gym", "court, joists, high-bays"),
		("IMG_0335", (-160, -50), (1, 0.15, 0), "competition_gym", "across the court"),
		("IMG_0336", (-110, 0), (-1, 0.1, 0), "competition_gym", "bleachers and scoreboard side"),
		("IMG_0338", (-200, 100), (0, 0, 1), "corridor_main", "concourse toward the south gym"),
		("IMG_0339", (-150, 100), (1, 0, 0), "corridor_main", "brick pier in the concourse"),
		("IMG_0340", (-50, -30), (0, 0, 1), "locker_volleyball", "mosaic tile wall at the locker room"),
		("IMG_0341", (-170, 90), (0, 0, -1), "corridor_main", "corridor"),
		("IMG_0342", (-190, 88), (1, 0, 0), "corridor_main", "corridor"),
		("IMG_0343", (-210, 96), (-1, 0, 0), "corridor_main", "corridor looking west"),
		("IMG_0344", (-130, -60), (0, 0.3, 1), "competition_gym", "up at joists and the clerestory"),
		("IMG_0345", (-150, 10), (0, 0.2, -1), "competition_gym", "court from the baseline"),
		("IMG_0346", (-250, 90), (1, 0, 0), "corridor_main", "west end of the concourse"),
		("IMG_0347", (-100, 40), (0, 0, -1), "group_exercise", "studio"),
		("IMG_0348", (-330, 110), (0, 0, 1), "corridor_office", "office corridor, west end"),
		# Exterior. Cameras stand outside the walls.
		("IMG_0349", (-80, 250), (0, 0, -1), "exterior", "service yard, south side"),
		("IMG_0350", (-40, 260), (-0.3, 0, -1), "exterior", "service ramp and brick"),
		("IMG_0351", (30, 200), (-1, 0, 0), "exterior", "east service side, metal panel and brick"),
		("IMG_0352", (40, 40), (-1, 0, 0), "exterior", "east lawn toward the entrance"),
		("IMG_0353", (-400, 40), (1, 0, 0), "exterior", "west approach"),
		("IMG_0354", (-420, -80), (1, 0, 0.3), "exterior", "rock swale west of the cage"),
		("IMG_0355", (-450, -40), (1, 0, 0), "exterior", "swale and the west brick wall"),
		("IMG_0356", (80, 180), (-1, 0, -0.2), "exterior", "road, east of the building"),
		("IMG_0357", (60, 220), (-0.5, 0, -1), "exterior", "crosswalk south-east"),
		("IMG_0358", (100, 80), (-1, 0, 0), "exterior", "east road, metal-panel facade"),
		("IMG_0359", (90, 140), (-1, 0, -0.4), "exterior", "east road looking northwest"),
		("IMG_0360", (70, 240), (-0.4, 0, -1), "exterior", "south-east corner from the road"),
		("IMG_0361", (-300, 280), (0, 0, -1), "exterior", "south lawn looking north"),
		("IMG_0362", (20, 30), (-1, 0.05, 0), "exterior", "entrance canopy from the east"),
		("IMG_0363", (16, 8), (-1, 0.1, 0), "exterior", "under the canopy toward the doors"),
		("IMG_0364", (40, 20), (-1, 0.05, 0), "exterior", "entrance curtain wall and canopy, from the lawn"),
		("IMG_0365", (24, -10), (-1, 0, 0.2), "exterior", "entrance, oblique"),
		("IMG_0366", (18, 40), (-1, 0.05, -0.3), "exterior", "entrance steps"),
		("IMG_0367", (10, 6), (-1, 0, 0), "exterior", "at the threshold, looking in"),
		("IMG_0368", (30, -20), (-0.8, 0, 0.4), "exterior", "canopy and RAC sign from the north-east"),
		("IMG_0369", (-24, 2), (0, 0.1, 1), "lobby", "lobby from just inside the doors"),
		("IMG_0370", (-28, 8), (1, 0, 0), "lobby", "front desk"),
		("IMG_0371", (-60, -40), (0, 0, 1), "corridor_ne", "northeast corridor"),
		("IMG_0372", (-50, -60), (1, 0, 0), "corridor_ne", "northeast corridor"),
		("IMG_0373", (-30, -60), (0, 0, -1), "stair_ne", "stair"),
		("IMG_0374", (-100, 50), (0, 0, 1), "corridor_link", "link toward the concourse"),
		("IMG_0375", (-60, -32), (1, 0, 0), "locker_volleyball", "locker room entry"),
		("IMG_0376", (-55, -34), (0, 0, 1), "locker_volleyball", "wood lockers"),
		("IMG_0377", (-50, -36), (-1, 0, 0), "locker_volleyball", "all-americans board wall"),
		("IMG_0378", (-70, -30), (1, 0, 0), "locker_volleyball", "door with the volleyball mark"),
		("IMG_0379", (-45, -28), (0, 0, -1), "locker_volleyball", "showers"),
		("IMG_0380", (-40, -40), (1, 0, 0), "locker_general", "second locker room"),
		("IMG_0381", (-30, -36), (0, 0, 1), "locker_general", "locker banks"),
		("IMG_0382", (-55, -30), (-1, 0, 0), "restroom_ne_w", "restroom"),
	]
	stations = [cam(*row) for row in rows]
	# Video frames of the competition gym, a slow pan.
	for i in range(10):
		ang = -0.8 + i * 0.18
		stations.append(
			cam(
				f"IMG_0337_f{i:03d}",
				(-140, -30),
				(math.sin(ang), 0.05, -math.cos(ang)),
				"competition_gym",
				"video frame, pan across the competition gym",
			)
		)
	return stations


def level_doc(level, elevation, rooms, walls, columns, stairs, props, voids=None):
	return {
		"level": level,
		"elevation": elevation,
		"rooms": rooms,
		"walls": walls,
		"columns": columns,
		"stairs": stairs,
		"voids": voids or [],
		"props": props,
	}


def voids_of(rooms):
	return [{"id": r["id"], "polygon": r["polygon"]} for r in rooms if r["type"] == "void"]


def main():
	BP.mkdir(parents=True, exist_ok=True)
	l1 = level1_rooms()
	l2 = level2_rooms()
	walls1 = build_walls(l1, DOOR_PAIRS_L1, L1_EXTRAS)
	walls2 = build_walls(l2, DOOR_PAIRS_L2, L2_EXTRAS)
	cols1 = columns_for(l1)
	stairs1 = stairs_for(l1, 1)
	stairs2 = stairs_for(l2, 2)
	props1 = props_for()

	bp_osm, orth, lat0, lon0 = footprint_from_osm()
	iou = raster_iou(bp_osm, np.array(orth), 0.5)
	print(f"footprint verts {len(orth)}  IoU vs OSM {iou:.4f}")

	facade, roofs = facade_and_roofs(orth)
	cal = calibration(bp_osm, orth, iou)
	site = {
		"units": "ft",
		"trueNorthDeg": TRUE_NORTH,
		"origin": {
			"desc": "main entrance exterior threshold, L1 finished floor",
			"lat": round(lat0, 6),
			"lon": round(lon0, 6),
		},
		"footprint": orth,
		"levels": [{"level": 1, "elevation": 0}, {"level": 2, "elevation": 16}],
		"facade": facade,
		"roofs": roofs,
		"calibration": "calibration.json",
	}

	doc1 = level_doc(1, 0, l1, walls1, cols1, stairs1, props1, [])
	# Level 2 voids are the open-to-below polygons; rooms of type void stay in rooms[] too
	# so render_plan labels them. The schema also has a voids array — fill both.
	doc2 = level_doc(2, 16, l2, walls2, [], stairs2, [], voids_of(l2))

	(BP / "level1.json").write_text(json.dumps(doc1, indent=2) + "\n")
	(BP / "level2.json").write_text(json.dumps(doc2, indent=2) + "\n")
	(BP / "site.json").write_text(json.dumps(site, indent=2) + "\n")
	(BP / "calibration.json").write_text(json.dumps(cal, indent=2) + "\n")
	stations = photo_stations()
	(BP / "photo_stations.json").write_text(json.dumps({"stations": stations}, indent=2) + "\n")
	photo_dir = ROOT / "reference" / "photos"
	have = {p.stem for p in photo_dir.glob("IMG_*.jpg")}
	station_ids = {s["id"] for s in stations}
	missing = sorted(have - station_ids)
	dangling = sorted(station_ids - have)
	if missing or dangling:
		print("PHOTO STATIONS missing", missing, "dangling", dangling)

	print(f"L1 rooms {len(l1)} walls {len(walls1)} openings {sum(len(w['openings']) for w in walls1)}")
	print(f"L2 rooms {len(l2)} walls {len(walls2)}")
	short = [w["id"] for w in walls1 if math.dist(w["a"], w["b"]) < 2]
	print("short L1", short)
	for c in cal["courts"]:
		print(c["name"], c["measuredFt"], "err", c["error"])
	print("scale bar", cal["scaleBar"])


if __name__ == "__main__":
	main()
