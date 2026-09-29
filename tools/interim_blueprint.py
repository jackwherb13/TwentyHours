"""Interim RAC blueprint traced by hand from reference/site_plan_native.png (scale bar: 140 px = 100 ft).

Major blocks only, so the builder can put a recognizable RAC on screen while M1 produces the measured version.
Output: blueprint_interim/{level1,level2,site}.json in docs/BLUEPRINT_SCHEMA.md format.
Walls are derived from room edges (shared edges merged); doors connect every room to circulation.
"""

import json
from collections import defaultdict
from pathlib import Path

FT_PER_PX = 100 / 140
ORIGIN_PX = (685, 470)  # east lobby facade = main entrance threshold
OUT = Path(__file__).resolve().parent.parent / "blueprint_interim"


def ft(px, py):
	return [round((px - ORIGIN_PX[0]) * FT_PER_PX * 2) / 2, round((py - ORIGIN_PX[1]) * FT_PER_PX * 2) / 2]


def rect(x0, y0, x1, y1):
	return [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]


# (id, name, type, polygon in plan px, floor, ceilingHeight, ceilingType, wallHeight)
ROOMS = [
	("competition_gym", "Competition Gym", "gym", rect(406, 184, 570, 392), "maple", 30, "open_joist", 34),
	("south_gym", "South Gym", "gym", rect(338, 490, 545, 655), "maple", 28, "open_joist", 32),
	("cage_construction", "Cage Gym + RAC Addition (construction)", "construction", rect(142, 152, 350, 452), "sealed_concrete", 28, "none", 30),
	("main_corridor", "Main Corridor", "corridor", rect(165, 452, 552, 490), "terrazzo", 10, "act_2x4", 14),
	("lobby", "Main Lobby", "lobby", [(570, 361), (685, 361), (685, 490), (552, 490), (552, 392), (570, 392)], "porcelain_tile", 26, "gypsum", 30),
	("office_wing", "Offices", "office", rect(570, 184, 668, 306), "carpet_tile", 9, "act_2x2", 12),
	("east_support", "Fitness Center", "fitness", rect(570, 306, 685, 361), "rubber", 12, "open_joist", 14),
	("weight_room", "Weight Room", "fitness", rect(480, 392, 552, 452), "rubber", 12, "open_joist", 14),
	("locker_men", "Men's Locker Room", "locker", rect(440, 392, 480, 452), "ceramic_tile", 9, "act_2x2", 12),
	("locker_women", "Women's Locker Room", "locker", rect(400, 392, 440, 452), "ceramic_tile", 9, "act_2x2", 12),
	("volleyball_locker", "Volleyball Locker Room", "locker", rect(350, 392, 400, 452), "ceramic_tile", 9, "act_2x2", 12),
	("restrooms", "Restrooms", "restroom", rect(350, 330, 406, 392), "ceramic_tile", 9, "act_2x2", 12),
	("racquetball_1", "Racquetball 1", "racquetball", rect(165, 490, 199, 537), "maple", 20, "gypsum", 22),
	("racquetball_2", "Racquetball 2", "racquetball", rect(199, 490, 233, 537), "maple", 20, "gypsum", 22),
	("racquetball_3", "Racquetball 3", "racquetball", rect(233, 490, 266, 537), "maple", 20, "gypsum", 22),
	("racquetball_4", "Racquetball 4", "racquetball", rect(266, 490, 300, 537), "maple", 20, "gypsum", 22),
	("west_restrooms", "Restrooms (West)", "restroom", rect(300, 490, 338, 537), "ceramic_tile", 9, "act_2x2", 12),
	("south_lobby", "South Lobby", "corridor", rect(545, 490, 625, 552), "porcelain_tile", 12, "act_2x4", 14),
	("entrance_vestibule", "Entrance Vestibule", "lobby", rect(625, 490, 685, 552), "porcelain_tile", 14, "gypsum", 16),
]
CIRCULATION = {"main_corridor", "lobby", "south_lobby", "entrance_vestibule"}
WALL_MAT = {"gym": "painted_cmu", "corridor": "painted_cmu", "lobby": "gypsum", "office": "gypsum", "fitness": "painted_cmu",
	"locker": "painted_cmu", "restroom": "painted_cmu", "racquetball": "gypsum", "construction": "painted_cmu"}

rooms = []
for rid, name, typ, poly, floor, ch, ct, wh in ROOMS:
	rooms.append({"id": rid, "name": name, "type": typ, "polygon": [ft(*p) for p in poly], "floorMaterial": floor,
		"ceilingHeight": ch, "ceilingType": ct, "wallFinish": WALL_MAT.get(typ, "painted_cmu"), "_wallHeight": wh})

# --- walls: split every room edge at every breakpoint on the same line, then merge duplicates
edges = defaultdict(set)  # (axis, const, lo, hi) -> room ids
for r in rooms:
	pts = r["polygon"]
	for a, b in zip(pts, pts[1:] + pts[:1]):
		if a[1] == b[1]:
			edges[("h", a[1])].add((min(a[0], b[0]), max(a[0], b[0]), r["id"]))
		else:
			edges[("v", a[0])].add((min(a[1], b[1]), max(a[1], b[1]), r["id"]))

segments = []  # (axis, const, lo, hi, {room ids})
for (axis, c), spans in edges.items():
	cuts = sorted({v for lo, hi, _ in spans for v in (lo, hi)})
	for lo, hi in zip(cuts, cuts[1:]):
		owners = {rid for s0, s1, rid in spans if s0 <= lo and s1 >= hi}
		if owners and hi - lo >= 0.5:
			segments.append((axis, c, lo, hi, owners))

# merge collinear neighbours with the same owners
segments.sort(key=lambda s: (s[0], s[1], s[2]))
merged = []
for s in segments:
	if merged and merged[-1][0] == s[0] and merged[-1][1] == s[1] and merged[-1][3] == s[2] and merged[-1][4] == s[4]:
		merged[-1] = (s[0], s[1], merged[-1][2], s[3], s[4])
	else:
		merged.append(s)

byid = {r["id"]: r for r in rooms}
walls = []
for i, (axis, c, lo, hi, owners) in enumerate(merged):
	exterior = len(owners) == 1
	h = max(byid[o]["_wallHeight"] for o in owners)
	a, b = ([lo, c], [hi, c]) if axis == "h" else ([c, lo], [c, hi])
	mat = "brick" if exterior else WALL_MAT.get(byid[sorted(owners)[0]]["type"], "painted_cmu")
	walls.append({"id": f"w{i:03d}", "a": a, "b": b, "thickness": 1.33 if exterior else 0.67, "height": h,
		"material": mat, "exterior": exterior, "openings": [], "_owners": sorted(owners), "_len": hi - lo})

# --- doors: connect each non-circulation room to circulation (or its best neighbour) with one door
def add_door(w, width, kind="door"):
	off = max(1.0, (w["_len"] - width) / 2)
	if off + width > w["_len"] - 0.5:
		return False
	w["openings"].append({"type": kind, "offset": off, "width": width, "sill": 0, "head": 7.0 if width <= 6 else 8.0,
		"leaves": 2 if width >= 6 else 1, "tag": "RACDoor"})
	return True

connected = set(CIRCULATION)
shared = [w for w in walls if len(w["_owners"]) == 2]
for _ in range(4):
	for r in rooms:
		if r["id"] in connected:
			continue
		cands = [w for w in shared if r["id"] in w["_owners"] and (set(w["_owners"]) - {r["id"]}) & connected]
		cands.sort(key=lambda w: (0 if (set(w["_owners"]) - {r["id"]}) & CIRCULATION else 1, -w["_len"]))
		for w in cands:
			width = 6.0 if r["type"] in ("gym", "fitness") else 3.0
			if add_door(w, width):
				connected.add(r["id"])
				break
# circulation spaces open into each other
for w in shared:
	if set(w["_owners"]) <= CIRCULATION and not w["openings"]:
		add_door(w, min(12.0, w["_len"] - 2), "opening")

# exterior: main entrance curtain wall + doors on the east lobby facade, plus egress doors
east = [w for w in walls if w["exterior"] and "lobby" in w["_owners"] and w["a"][0] == w["b"][0] and w["a"][0] == 0]
for w in east:
	w["material"] = "glass"
	w["openings"].append({"type": "curtainwall", "offset": 0, "width": w["_len"], "sill": 0, "head": 24.0, "mullionSpacing": 5.0})
vest = [w for w in walls if w["exterior"] and "entrance_vestibule" in w["_owners"] and w["a"][0] == w["b"][0]]
for w in vest:
	add_door(w, 6.0)
for rid in ("main_corridor", "south_gym", "competition_gym"):
	ext = sorted([w for w in walls if w["exterior"] and rid in w["_owners"]], key=lambda w: -w["_len"])
	if ext:
		add_door(ext[0], 6.0)
# clerestory windows high on long exterior gym walls
for w in walls:
	if w["exterior"] and any(byid[o]["type"] == "gym" for o in w["_owners"]) and w["_len"] > 60:
		n = int(w["_len"] // 20)
		for k in range(n):
			w["openings"].append({"type": "window", "offset": 4 + k * 20, "width": 12.0, "sill": 20.0, "head": 26.0})
		w["openings"].sort(key=lambda o: o["offset"])
		# drop windows that collide with a door
		keep = []
		for o in w["openings"]:
			if all(o is p or o["offset"] >= p["offset"] + p["width"] + 0.5 or o["offset"] + o["width"] + 0.5 <= p["offset"]
				or (o["type"] == "window" and p["type"] == "window") for p in w["openings"]):
				keep.append(o)
		w["openings"] = keep

# --- props (kinds from the schema; missing kinds render as placeholders until their modules land)
props = []
def prop(kind, px, py, rot, room, **kw):
	props.append({"id": f"p{len(props):03d}", "kind": kind, "at": ft(px, py), "rotation": rot, "room": room, **kw})

prop("front_desk", 640, 420, 90, "lobby")
for i, y in enumerate(range(200, 380, 30)):
	prop("bleacher_bank", 412, y + 12, 90, "competition_gym", opts={"rows": 12, "length": 20})
prop("basketball_hoop_ceiling", 488, 190, 0, "competition_gym")
prop("basketball_hoop_ceiling", 488, 386, 180, "competition_gym")
prop("scoreboard", 488, 186, 0, "competition_gym")
for x in (365, 395, 425, 455, 485, 515):
	prop("bleacher_bank", x, 496, 0, "south_gym", opts={"rows": 8, "length": 20})
for i in range(4):
	prop("power_rack", 488 + i * 16, 400, 0, "weight_room")
	prop("flat_bench", 490 + i * 16, 425, 0, "weight_room")
for i in range(5):
	prop("treadmill", 580 + i * 20, 312, 0, "east_support")
	prop("elliptical", 580 + i * 20, 340, 0, "east_support")
prop("vending_machine", 300, 455, 0, "main_corridor")
prop("trash_bin", 330, 455, 0, "main_corridor")
prop("recycle_bin", 336, 455, 0, "main_corridor")
for i in range(3):
	prop("locker_bank_wood", 356, 400 + i * 16, 90, "volleyball_locker")

for w in walls:
	del w["_owners"], w["_len"]
for r in rooms:
	del r["_wallHeight"]

OUT.mkdir(exist_ok=True)
json.dump({"level": 1, "elevation": 0, "rooms": rooms, "walls": walls, "columns": [], "stairs": [], "voids": [], "props": props},
	open(OUT / "level1.json", "w"), indent=1)
json.dump({"level": 2, "elevation": 16, "rooms": [], "walls": [], "columns": [], "stairs": [], "voids": [{"id": "all_open", "polygon": [ft(142, 152), ft(685, 152), ft(685, 655), ft(142, 655)]}], "props": []},
	open(OUT / "level2.json", "w"), indent=1)
foot = [ft(142, 152), ft(685, 152), ft(685, 655), ft(142, 655)]
json.dump({"units": "ft", "trueNorthDeg": 0, "origin": {"desc": "east lobby facade (interim)"}, "footprint": foot,
	"levels": [{"level": 1, "elevation": 0}, {"level": 2, "elevation": 16}], "facade": [], "roofs": [], "props": []},
	open(OUT / "site.json", "w"), indent=1)
print(f"rooms={len(rooms)} walls={len(walls)} doors={sum(len(w['openings']) for w in walls)} props={len(props)}")
