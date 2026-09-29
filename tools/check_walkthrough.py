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
hall = by1["corridor_entry_south"]
sx0, sx1, sz0, sz1 = bbox(stair["polygon"])
hx0, hx1, hz0, hz1 = bbox(hall["polygon"])
check(sx1 <= hx0 + 0.05, f"main stair is not west of the gym hall (stair x to {sx1}, hall x from {hx0})")

flights = {f["id"]: f for f in (l1["stairs"][0]["flights"] if l1["stairs"] else [])}
main = next(s for s in l1["stairs"] if s["id"] == "stair_main")
by_flight = {f["id"]: f for f in main["flights"]}
a, b = by_flight["main_a"], by_flight["main_b"]
check(a["direction"] == [0, -1], f"first flight direction {a['direction']} is not north along the hall")
check(b["direction"] == [-1, 0], f"second flight direction {b['direction']} is not west")
ux, uz = a["direction"]
vx, vz = b["direction"]
check(ux * vz - uz * vx == -1, "main stair turn is not left")
ax0, ax1, az0, az1 = bbox(a["polygon"])
check(az1 - az0 >= ax1 - ax0, "first flight is not the long north-south run")

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
    length = desk.get("length", 16)
    south = desk["at"][1] + length / 2
    check(abs(south - (-10)) <= 1, f"desk south end z={south} is not 10 ft from the glass")
    check(20 <= length <= 25, f"desk length {length} is outside 20-25 ft")
    check(desk["rotation"] == 270, f"desk rotation {desk['rotation']} does not run north-south")

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
    z0, z1 = sorted((a[1], b[1]))
    if any(o.get("type") == "curtainwall" for o in w.get("openings", [])):
        glass_z.append((z0, z1))
    if w.get("material") == "glass":
        glass_z.append((z0, z1))
check(glass_z, "overlook has no gym glass")
if glass_z:
    covered = any(z0 <= -250 and z1 >= -110 for z0, z1 in glass_z)
    check(covered, f"gym glass is not continuous along the overlook ({glass_z})")

for cid in ("racquetball_1", "racquetball_2"):
    rx0, rx1, rz0, rz1 = bbox(by2[cid]["polygon"])
    check(rx1 <= ox0 + 0.05, f"{cid} is not on the left (west) of the overlook")
    check(rz1 <= -270, f"{cid} is not past the gym glass")
    dims = sorted((round(rx1 - rx0, 1), round(rz1 - rz0, 1)))
    check(dims == [20.0, 40.0], f"{cid} dims {dims} are not 20x40")

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
