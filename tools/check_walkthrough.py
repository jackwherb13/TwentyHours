"""Walkthrough handedness and material presence. Not a visual pass.

Run: python tools/check_walkthrough.py
Exit 1 on any failure. Prints one line per failure.
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BP = ROOT / "blueprint"


def load(name):
    return json.loads((BP / name).read_text(encoding="utf-8"))


def bbox(poly):
    xs = [p[0] for p in poly]
    zs = [p[1] for p in poly]
    return min(xs), max(xs), min(zs), max(zs)


def room(level, rid):
    for r in level["rooms"]:
        if r["id"] == rid:
            return r
    return None


fails = []


def check(ok, msg):
    if not ok:
        fails.append(msg)


l1 = load("level1.json")
l2 = load("level2.json")
by1 = {r["id"]: r for r in l1["rooms"]}
by2 = {r["id"]: r for r in l2["rooms"]}

stair = by1["stair_main"]
sx0, sx1, sz0, sz1 = bbox(stair["polygon"])
check(sx0 < 10 and sx1 > -2, f"main stair is not in the entry bay (x {sx0}..{sx1})")

main = next(s for s in l1["stairs"] if s["id"] == "stair_main")
l2main = next(s for s in l2["stairs"] if s["id"] == "stair_main")
check(bbox(l2main["polygon"]) == bbox(main["polygon"]), "level 2 stair polygon does not match level 1")
check(l2main.get("flights"), "level 2 stair_main has no flights")
by_flight = {f["id"]: f for f in main["flights"]}
a, b = by_flight["main_a"], by_flight["main_b"]
check(a["direction"] == [0, -1], f"first flight direction {a['direction']} is not north along the wall")
check(b["direction"] == [-1, 0], f"second flight direction {b['direction']} is not west")
ux, uz = a["direction"]
vx, vz = b["direction"]
check(ux * vz - uz * vx == -1, "main stair turn is not left")
ax0, ax1, az0, az1 = bbox(a["polygon"])
check(az1 - az0 >= ax1 - ax0 - 0.05, "first flight is not the long north-south run")
check(a.get("run", 0) >= 10 / 12 - 0.01, f"first flight run {a.get('run')} is under 10 in")
check(b.get("run", 0) >= 10 / 12 - 0.01, f"second flight run {b.get('run')} is under 10 in")
check(abs(a.get("rise", 0) * 17 - 10) < 0.05, f"first flight rise {a.get('rise')} does not total 10 ft")
check(a.get("width", 0) >= 8, f"first flight width {a.get('width')} is under 8 ft")
check(-48 <= az1 <= -30, f"first flight south edge z={az1} is not 30-48 ft from the glass")
bx0, bx1, bz0, bz1 = bbox(b["polygon"])
check(abs(bx0 - (-12.5)) < 0.05, f"upper flight does not reach the Level 2 door at x=-12.5 ({bx0})")

lobby = by1["lobby"]
lx0, lx1, lz0, lz1 = bbox(lobby["polygon"])
check(lx1 - lx0 >= 20 and lz1 - lz0 >= 20, f"lobby bbox {lx1 - lx0:.0f}x{lz1 - lz0:.0f} does not contain a 20 ft bay")
check(lx0 <= -10 and lx1 >= 10 and lz0 <= -20 and lz1 >= 0, "lobby does not cover the 20x20 bay x=-10..10 z=-20..0")

void = by2.get("void_lobby")
check(void is not None, "missing void_lobby")
if void:
    vx0, vx1, vz0, vz1 = bbox(void["polygon"])
    check(vx0 <= -10 and vx1 >= 10 and vz0 <= -20 and vz1 >= 0, "void_lobby misses the 20x20 bay")

desk = next((p for p in l1["props"] if p["id"] == "reception_desk"), None)
check(desk is not None, "missing reception desk")
if desk:
    # Round 3: 20-25 ft white U in the main room, with the 09:35 U shape.
    check(desk.get("shape") == "u", "desk is not the U-shaped main-room counter")
    check(desk.get("length", 0) >= 20, f"desk length {desk.get('length')} is under 20 ft")
    check(desk.get("room") == "lobby", "desk is not in the lobby")
    ax, az = desk["at"]
    check(-10 <= ax <= 10 and -16 <= az <= -6, f"desk at {desk['at']} is outside the open entry")

trophy = next(p for p in l1["props"] if p["id"] == "trophy_main")
doors = []
for w in l1["walls"]:
    a, b = w["a"], w["b"]
    if abs(a[0] + 78.5) < 0.05 and abs(b[0] + 78.5) < 0.05:
        for o in w.get("openings", []):
            if o.get("type") == "door":
                z0, z1 = sorted((a[1], b[1]))
                center = z0 + o["offset"] + o["width"] / 2
                if center < -120:
                    doors.append(center)
check(len(doors) >= 2, f"gym foyer doors missing ({doors})")
if doors:
    check(trophy["at"][1] > max(doors), f"trophy z={trophy['at'][1]} is not south of gym doors {doors}")

gym = by1["competition_gym"]
check(gym.get("floorMaterial") == "maple", f"gym floor is {gym.get('floorMaterial')}")
check(by1["south_vestibule"].get("floorMaterial") == "porcelain_tile", "vestibule floor is not porcelain")
check(by1["corridor_entry_south"].get("floorMaterial") == "terrazzo", "entry hall floor is not terrazzo")

overlook = by2["corridor_l2_overlook"]
ox0, ox1, oz0, oz1 = bbox(overlook["polygon"])
glass_z = []
for w in l2["walls"]:
    a, b = w["a"], w["b"]
    if abs(a[0] + 78.5) > 0.05 or abs(b[0] + 78.5) > 0.05:
        continue
    direction = 1 if b[1] >= a[1] else -1
    for o in w.get("openings", []):
        if o.get("type") != "curtainwall":
            continue
        s0 = a[1] + direction * o["offset"]
        s1 = a[1] + direction * (o["offset"] + o["width"])
        glass_z.append(tuple(sorted((s0, s1))))
    if w.get("material") == "glass":
        glass_z.append(tuple(sorted((a[1], b[1]))))
check(glass_z, "overlook has no gym glass")
if glass_z:
    covered = any(lo <= -270 and hi >= -100 for lo, hi in glass_z)
    check(covered, f"gym glass opening is not continuous along the overlook ({glass_z})")

hall2 = by2["corridor_l2"]
hx0, hx1, hz0, hz1 = bbox(hall2["polygon"])
check(oz0 >= -279.5 - 0.05, f"overlook still runs past the gym to z={oz0}")
for cid in ("racquetball_1", "racquetball_2"):
    rx0, rx1, rz0, rz1 = bbox(by2[cid]["polygon"])
    check(rz0 >= hz1 - 0.05, f"{cid} is not on the south (left) side of the L2 hall")
    check(rx1 <= hx1 and rx0 >= hx0 - 0.05, f"{cid} is not along corridor_l2")
    dims = sorted((round(rx1 - rx0, 1), round(rz1 - rz0, 1)))
    check(dims == [20.0, 40.0], f"{cid} dims {dims} are not 40x20")
stair2 = by2["stair_second"]
tx0, tx1, tz0, tz1 = bbox(stair2["polygon"])
r1 = bbox(by2["racquetball_1"]["polygon"])
check(tx1 <= r1[0] + 0.05, "down stair is not west of the racquetball courts")
check(tz0 <= hz0 + 0.05, "down stair is not on the right (north) of the L2 hall")

vest = by1["nutrition_vestibule"]
ath = by1["athletic_corridor"]
vx0, vx1, _, _ = bbox(vest["polygon"])
ax0, ax1, _, _ = bbox(ath["polygon"])
check(vx1 <= ax0 + 0.05, "nutrition vestibule is not west of the athletic hall")
check(abs((vx1 - vx0) - 10) < 0.2 and abs(bbox(vest["polygon"])[3] - bbox(vest["polygon"])[2] - 10) < 0.2, "vestibule is not 10x10")

locker = by1["locker_volleyball"]
# Facing west into the vestibule, left is south. The locker must own that south wall.
check(abs(bbox(locker["polygon"])[2] - bbox(vest["polygon"])[3]) < 0.2, "locker does not open on the south wall of the vestibule")

mats = (ROOT / "src/ReplicatedStorage/RAC/Materials.luau").read_text(encoding="utf-8")
check("part.Color = Color3.new(1, 1, 1)" not in mats and "Color3.fromRGB(255, 255, 255)" not in mats, "Materials bleaches color to white")
check('part.MaterialVariant = "RAC_" .. key' in mats, "Materials does not assign RAC_ variants")

for line in fails:
    print("FAIL", line)
print(f"Walkthrough check: {'FAIL' if fails else 'PASS'}; {len(fails)} failures")
sys.exit(1 if fails else 0)
