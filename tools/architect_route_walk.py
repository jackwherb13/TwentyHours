"""Walk the authored routes on the compiled door graph and check the stair flights.

Prints each resolved path, including rooms the waypoint list skips.
Exits 1 if a waypoint is unreachable or a walkthrough stair/overlook fact fails.
"""
import collections
import json
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BP = ROOT / "blueprint"


def read(name):
    return json.loads((BP / name).read_text(encoding="utf-8"))


def inside(poly, p):
    x, z = p
    yes = False
    for a, b in zip(poly, poly[1:] + poly[:1]):
        if (a[1] > z) != (b[1] > z) and x < (b[0] - a[0]) * (z - a[1]) / (b[1] - a[1]) + a[0]:
            yes = not yes
    return yes


def graph_of(levels):
    graph = collections.defaultdict(set)
    def add(a, b):
        graph[a].add(b)
        graph[b].add(a)
    for d in levels:
        n = d["level"]
        rooms = [r for r in d["rooms"] if r["type"] not in ("void", "construction")]
        def at(p, rooms=rooms, n=n):
            return next((f"{n}:{r['id']}" for r in rooms if inside(r["polygon"], p)), None)
        for w in d["walls"]:
            length = math.dist(w["a"], w["b"])
            ux, uz = (w["b"][0] - w["a"][0]) / length, (w["b"][1] - w["a"][1]) / length
            for o in w["openings"]:
                if o["type"] not in ("door", "opening"):
                    continue
                t = o["offset"] + o["width"] / 2
                x, z = w["a"][0] + ux * t, w["a"][1] + uz * t
                eps = w["thickness"] / 2 + 1
                a, b = at((x - uz * eps, z + ux * eps)), at((x + uz * eps, z - ux * eps))
                if a and b and a != b:
                    add(a, b)
                elif n == 1 and (a == "1:lobby" or b == "1:lobby"):
                    add("LOW_ENTRANCE", a or b)
                elif n == 2 and (a == "2:basketball_approach" or b == "2:basketball_approach"):
                    add("HIGH_EXIT", a or b)
    for stair in levels[0]["stairs"]:
        add(f"1:{stair['id']}", f"2:{stair['id']}")
    return graph


def path(graph, a, b):
    q = collections.deque([[a]])
    seen = {a}
    while q:
        p = q.popleft()
        if p[-1] == b:
            return p
        for nxt in sorted(graph[p[-1]]):
            if nxt in ("LOW_ENTRANCE", "HIGH_EXIT") and nxt != b:
                continue
            if nxt not in seen:
                seen.add(nxt)
                q.append(p + [nxt])
    return None


def stair_facts(level1):
    fails = []
    by_id = {s["id"]: s for s in level1["stairs"]}
    main = by_id["stair_main"]
    flights = main.get("flights") or []
    if len(flights) != 2 or [f["risers"] for f in flights] != [17, 17]:
        fails.append("main stair is not two flights of 17 risers")
    else:
        u, v = flights[0]["direction"], flights[1]["direction"]
        if u[0] * v[1] - u[1] * v[0] != -1:
            fails.append("main stair does not turn left")
        if abs(main["rise"] * main["risers"] - 20) > 0.001:
            fails.append("main stair does not rise 20 ft")
        landings = main.get("landings") or []
        if not any(abs(l["elevation"] - 10) < 0.05 for l in landings):
            fails.append("main stair has no mid landing")
    for sid in ("stair_second", "stair_west"):
        stair = by_id[sid]
        flights = stair.get("flights") or []
        if len(flights) != 2 or sum(f["risers"] for f in flights) != 34:
            fails.append(f"{sid} does not connect the floors in two flights")
        if abs(stair["rise"] * stair["risers"] - 20) > 0.001:
            fails.append(f"{sid} rise does not total 20 ft")
    return fails


def overlook_facts(level2):
    fails = []
    room = next(r for r in level2["rooms"] if r["id"] == "corridor_l2_overlook")
    xs = [p[0] for p in room["polygon"]]
    zs = [p[1] for p in room["polygon"]]
    if max(xs) - min(xs) < 10 or max(zs) - min(zs) < 100:
        fails.append("overlook corridor is not a walkable run along the gym")
    glass = 0
    for wall in level2["walls"]:
        if abs(wall["a"][0] + 78.5) > 0.05 or abs(wall["b"][0] + 78.5) > 0.05:
            continue
        for opening in wall["openings"]:
            if opening.get("type") == "curtainwall":
                glass += opening["width"]
    if glass < 100:
        fails.append("overlook glass toward the competition gym is missing")
    return fails


def main():
    levels = [read("level1.json"), read("level2.json")]
    fails = []
    if levels[1]["elevation"] != 20:
        fails.append("Level 2 elevation is not 20")
    fails.extend(stair_facts(levels[0]))
    fails.extend(overlook_facts(levels[1]))
    graph = graph_of(levels)
    for route in read("walkthrough_routes.json")["routes"]:
        stitched = []
        print(route["id"])
        for a, b in zip(route["rooms"], route["rooms"][1:]):
            walked = path(graph, a, b)
            if not walked:
                fails.append(f"no route {a} -> {b}")
                print(f"  FAIL {a} -> {b}")
                continue
            stitched.extend(walked if not stitched else walked[1:])
        if stitched:
            print("  " + " -> ".join(stitched))
    if fails:
        for item in fails:
            print("FAIL", item)
        return 1
    print("Route walk PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
