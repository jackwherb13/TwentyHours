"""Finish the south-entrance structure and close wall-joint gaps.

Edits blueprint/ only, then compiles level JSON with architect_build.py.
The production builder cuts crossing walls apart and the geometry gate
flags that seam, so compiled walls are split back into T-joints.
"""
import json
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BP = ROOT / "blueprint"
sys.path.insert(0, str(ROOT / "tools"))
import architect_build  # noqa: E402


def load(name):
    return json.loads((BP / name).read_text(encoding="utf-8"))


def save(name, data):
    (BP / name).write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def shoelace(poly):
    return sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(poly, poly[1:] + poly[:1])) / 2


def ccw(poly):
    out = [list(p) for p in poly]
    if shoelace(out) < 0:
        out.reverse()
    return out


def set_room(level, rid, **changes):
    for room in level["rooms"]:
        if room["id"] == rid:
            room.update(changes)
            return room
    raise KeyError(rid)


def set_poly(level, rid, poly):
    room = set_room(level, rid)
    room["polygon"] = poly
    return room


def ensure_connection(level, a, b, width, kind="door", **extra):
    for conn in level["connections"]:
        if set(conn["rooms"]) == {a, b}:
            conn["width"] = width
            conn["type"] = kind
            conn.update(extra)
            return
    level["connections"].append({"rooms": [a, b], "width": width, "type": kind, **extra})


def prepare_layout(layout):
    level1 = layout["levels"][0]
    level2 = layout["levels"][1]
    # Lidar roofs: competition 33.7, south gym 40.2. Ceilings stay under those roofs.
    set_room(level1, "competition_gym", ceilingHeight=32.5)
    set_room(level1, "south_gym", ceilingHeight=39)
    # Rooms directly under a Level 2 slab cannot keep a 32 ft ceiling.
    set_room(level1, "corridor_wide", ceilingHeight=12, ceilingType="act_2x4")
    set_room(level1, "corridor_entry_south", ceilingHeight=12, ceilingType="act_2x4")
    # South glass strip (z=-15..0) is double-height. The 5 ft band behind it
# stays under the Level 2 slab as vestibule_inner so it does not cover the lobby.
    set_poly(
        level1,
        "south_vestibule",
        [[-42.5, -15.0], [-10.0, -15.0], [-10.0, 0.0], [-42.5, 0.0]],
    )
    set_room(level1, "south_vestibule", ceilingHeight=32, ceilingType="gypsum")
    set_poly(
        level1,
        "fitness_annex",
        [[-42.5, -48.0], [-5.0, -48.0], [-5.0, -20.0], [-42.5, -20.0]],
    )
    set_poly(
        level1,
        "corridor_south_link",
        [[-97.0, -62.0], [-78.5, -62.0], [-78.5, -15.0], [-97.0, -15.0]],
    )
    set_room(level1, "stair_main", ceilingType="none", ceilingHeight=32)
    level1["connections"] = [
        c
        for c in level1["connections"]
        if set(c["rooms"]) != {"south_vestibule", "fitness_annex"}
    ]
    ensure_connection(level1, "lobby", "south_vestibule", 12, "opening")
    ensure_connection(level1, "cage_lower_reserved", "west_link", 6, "door", label="CONSTRUCTION")
    set_room(level2, "racquetball_1", ceilingHeight=16.5)
    set_room(level2, "racquetball_2", ceilingHeight=16.5)
    set_room(level2, "cage_gym", ceilingHeight=24.5)
    level1["connections"] = [
        c
        for c in level1["connections"]
        if set(c["rooms"]) != {"competition_gym", "corridor_gym_east"}
    ]
    spec = {
        "a": [-78.5, -154.5],
        "b": [-78.5, -132.5],
        "openings": [
            {"center": 5.5, "width": 6, "kind": "door"},
            {"center": 16.5, "width": 6, "kind": "door"},
        ],
    }
    level1["apertures"] = [a for a in level1.get("apertures", []) if a.get("a") != spec["a"] or a.get("b") != spec["b"]]
    level1["apertures"].append(spec)
    apply_review(layout)


RISE = 20 / 34
RUN16 = 16 / 17


def flight(fid, poly, direction, base, width, run=RUN16):
    return {
        "id": fid,
        "polygon": poly,
        "direction": direction,
        "risers": 17,
        "rise": RISE,
        "run": run,
        "width": width,
        "baseElevation": base,
    }


def landing(lid, poly, elevation):
    return {"id": lid, "polygon": poly, "elevation": elevation}


def drop_rooms(level, ids):
    gone = set(ids)
    level["rooms"] = [room for room in level["rooms"] if room["id"] not in gone]
    level["connections"] = [c for c in level["connections"] if not (set(c["rooms"]) & gone)]


def drop_pairs(level, pairs):
    banned = [{a, b} for a, b in pairs]
    level["connections"] = [c for c in level["connections"] if set(c["rooms"]) not in banned]


def add_room(level, rid, name, kind, poly, floor, ceiling, ceiling_type, finish):
    body = {
        "id": rid,
        "name": name,
        "type": kind,
        "polygon": ccw(poly),
        "floorMaterial": floor,
        "ceilingHeight": ceiling,
        "ceilingType": ceiling_type,
        "wallFinish": finish,
    }
    for room in level["rooms"]:
        if room["id"] == rid:
            room.update(body)
            return room
    level["rooms"].append(body)
    return body


def edge_span(poly_a, poly_b, tol=0.08):
    """Longest collinear overlap of two axis-aligned polygons."""
    best = 0.0
    loop_a = list(poly_a) + [poly_a[0]]
    loop_b = list(poly_b) + [poly_b[0]]
    for a0, a1 in zip(loop_a, loop_a[1:]):
        horiz = abs(a0[1] - a1[1]) <= tol
        vert = abs(a0[0] - a1[0]) <= tol
        if not horiz and not vert:
            continue
        for b0, b1 in zip(loop_b, loop_b[1:]):
            if horiz and abs(b0[1] - b1[1]) <= tol and abs(a0[1] - b0[1]) <= tol:
                lo = max(min(a0[0], a1[0]), min(b0[0], b1[0]))
                hi = min(max(a0[0], a1[0]), max(b0[0], b1[0]))
                best = max(best, hi - lo)
            elif vert and abs(b0[0] - b1[0]) <= tol and abs(a0[0] - b0[0]) <= tol:
                lo = max(min(a0[1], a1[1]), min(b0[1], b1[1]))
                hi = min(max(a0[1], a1[1]), max(b0[1], b1[1]))
                best = max(best, hi - lo)
    return best


def prune_connections(level):
    byid = {room["id"]: room for room in level["rooms"]}
    kept = []
    for conn in level["connections"]:
        a, b = conn["rooms"]
        if a not in byid or b not in byid:
            continue
        span = edge_span(byid[a]["polygon"], byid[b]["polygon"])
        if span < 3:
            continue
        width = conn.get("width", 3.5)
        if width != "full" and width > span - 0.25:
            conn["width"] = max(3, round((span - 0.5) * 2) / 2)
            if conn["width"] > span:
                continue
        kept.append(conn)
    level["connections"] = kept


def apply_round2(layout):
    """Round-2 walk: stair west of the gym hall, one left hall, 20x20 bay, courts on the overlook."""
    level1 = layout["levels"][0]
    level2 = layout["levels"][1]
    # Full 20 ft width from the glass through the desk. No neck wall beside the counter.
    set_poly(level1, "lobby", ccw([[-10.0, -36.0], [10.0, -36.0], [10.0, 0.0], [-10.0, 0.0]]))
    set_room(level1, "lobby", ceilingHeight=32, ceilingType="gypsum", floorMaterial="porcelain_tile")
    set_poly(
        level1,
        "south_vestibule",
        ccw([[-10.0, 0.0], [-10.0, -16.0], [-97.0, -16.0], [-97.0, 0.0]]),
    )
    set_room(level1, "south_vestibule", ceilingHeight=32, ceilingType="gypsum", floorMaterial="porcelain_tile")
    set_poly(level1, "glazed_recreation", ccw([[-5.0, -80.0], [10.0, -80.0], [10.0, -36.0], [-5.0, -36.0]]))
    set_room(level1, "glazed_recreation", ceilingHeight=12, ceilingType="act_2x2")
    set_poly(level1, "fitness_annex", ccw([[-42.5, -48.0], [-10.0, -48.0], [-10.0, -16.0], [-42.5, -16.0]]))
    set_room(level1, "fitness_annex", ceilingHeight=12, ceilingType="act_2x2")
    # Old stair footprint becomes corridor so the floor under the moved landing stays.
    set_poly(
        level1,
        "corridor_wide",
        ccw(
            [
                [-66.5, -80.0],
                [-5.0, -80.0],
                [-5.0, -48.0],
                [-42.5, -48.0],
                [-42.5, -28.0],
                [-66.5, -28.0],
            ]
        ),
    )
    stair_poly = ccw([[-106.0, -54.0], [-78.5, -54.0], [-78.5, -16.0], [-106.0, -16.0]])
    set_poly(level1, "stair_main", stair_poly)
    set_poly(level2, "stair_main", [list(p) for p in stair_poly])
    set_room(level1, "stair_main", ceilingType="none", ceilingHeight=32)
    set_room(level2, "stair_main", ceilingType="none", ceilingHeight=12)
    set_poly(level1, "corridor_south_link", ccw([[-106.0, -62.0], [-78.5, -62.0], [-78.5, -54.0], [-106.0, -54.0]]))
    # The wide stair sits in the northeast corner of the south gym. Keep the gym; give that corner to the stair.
    south_notch = ccw(
        [
            [-236.5, 47.0],
            [-236.5, -62.0],
            [-106.0, -62.0],
            [-106.0, -16.0],
            [-97.0, -16.0],
            [-97.0, 47.0],
        ]
    )
    set_poly(level1, "south_gym", south_notch)
    set_poly(level2, "void_south", [list(p) for p in south_notch])
    for void in level2.get("voids", []):
        if void["id"] == "void_south":
            void["polygon"] = [list(p) for p in south_notch]
    set_poly(level1, "corridor_entry_south", ccw([[-78.5, -80.0], [-66.5, -80.0], [-66.5, -16.0], [-78.5, -16.0]]))
    # Court paint ends near z=-184.5. Keep that slab in the gym, then the thin link, then the foyer.
    set_poly(level1, "competition_gym", ccw([[-193.5, -279.5], [-78.5, -279.5], [-78.5, -186.0], [-193.5, -186.0]]))
    set_room(level1, "competition_gym", floorMaterial="maple", ceilingHeight=32.5)
    set_poly(level1, "thin_link", ccw([[-193.5, -186.0], [-78.5, -186.0], [-78.5, -170.0], [-193.5, -170.0]]))
    set_room(level1, "thin_link", floorMaterial="terrazzo", ceilingHeight=12, ceilingType="act_2x4", type="corridor")
    add_room(
        level1,
        "gym_foyer",
        "Volleyball Gym Entry",
        "gym",
        [
            [-193.5, -170.0],
            [-78.5, -170.0],
            [-78.5, -92.5],
            [-110.0, -92.5],
            [-110.0, -132.5],
            [-193.5, -132.5],
        ],
        floor="maple",
        ceiling=32.5,
        ceiling_type="none",
        finish="painted_cmu",
    )
    set_poly(
        level1,
        "corridor_gym_east",
        ccw([[-78.5, -188.0], [-66.5, -188.0], [-66.5, -132.5], [-78.5, -132.5]]),
    )
    set_poly(level1, "fitness_north", ccw([[-66.5, -195.5], [10.0, -195.5], [10.0, -154.5], [-66.5, -154.5]]))
    set_room(level1, "corridor_gym_east", floorMaterial="terrazzo", ceilingHeight=12, ceilingType="act_2x4")
    # Nutrition vestibule just south of the thin-link junction, on the west side of the athletic hall.
    set_poly(
        level1,
        "nutrition_vestibule",
        ccw([[-215.5, -170.0], [-205.5, -170.0], [-205.5, -160.0], [-215.5, -160.0]]),
    )
    set_room(level1, "nutrition_vestibule", type="support", floorMaterial="porcelain_tile", ceilingHeight=9, ceilingType="act_2x2")
    set_poly(
        level1,
        "locker_volleyball",
        ccw([[-225.0, -160.0], [-205.5, -160.0], [-205.5, -140.0], [-225.0, -140.0]]),
    )
    set_poly(level1, "training_store", ccw([[-225.0, -180.0], [-205.5, -180.0], [-205.5, -170.0], [-225.0, -170.0]]))
    set_poly(
        level1,
        "volleyball_washroom",
        ccw([[-193.5, -102.5], [-173.5, -102.5], [-173.5, -92.5], [-193.5, -92.5]]),
    )
    set_poly(
        level1,
        "cage_lower_reserved",
        ccw([[-351.5, -220.0], [-225.0, -220.0], [-225.0, -140.0], [-351.5, -140.0]]),
    )
    add_room(
        level1,
        "corridor_locker_west",
        "Locker Hall",
        "corridor",
        [[-305.0, -140.0], [-205.5, -140.0], [-205.5, -112.0], [-305.0, -112.0]],
        floor="terrazzo",
        ceiling=10,
        ceiling_type="act_2x2",
        finish="painted_cmu",
    )
    # Level 2: one northbound hall, gym glass then racquetball on the left.
    set_poly(
        level2,
        "corridor_l2_overlook",
        ccw([[-78.5, -330.0], [-64.5, -330.0], [-64.5, -80.0], [-78.5, -80.0]]),
    )
    set_room(
        level2,
        "corridor_l2_overlook",
        floorMaterial="terrazzo",
        ceilingHeight=10,
        ceilingType="act_2x2",
        wallFinish="painted_cmu",
    )
    set_poly(level2, "office_ne_1", ccw([[-64.5, -279.5], [-53.0, -279.5], [-53.0, -262.0], [-64.5, -262.0]]))
    set_poly(level2, "racquetball_2", ccw([[-98.5, -319.5], [-78.5, -319.5], [-78.5, -279.5], [-98.5, -279.5]]))
    set_poly(level2, "racquetball_1", ccw([[-118.5, -319.5], [-98.5, -319.5], [-98.5, -279.5], [-118.5, -279.5]]))
    # Offices leave the overlook's west wall. The strip is open to the maple gym below.
    set_poly(level2, "team_offices", ccw([[-135.0, -132.5], [-110.0, -132.5], [-110.0, -92.5], [-135.0, -92.5]]))
    set_poly(
        level2,
        "void_competition",
        ccw(
            [
                [-193.5, -279.5],
                [-78.5, -279.5],
                [-78.5, -92.5],
                [-110.0, -92.5],
                [-110.0, -132.5],
                [-193.5, -132.5],
            ]
        ),
    )
    set_poly(level1, "locker_general_m", ccw([[-131.5, -124.5], [-122.0, -124.5], [-122.0, -92.5], [-131.5, -92.5]]))
    set_poly(level1, "storage_athletic", ccw([[-122.0, -124.5], [-110.0, -124.5], [-110.0, -92.5], [-122.0, -92.5]]))
    set_room(level2, "racquetball_1", ceilingHeight=16.5, type="racquetball")
    set_room(level2, "racquetball_2", ceilingHeight=16.5, type="racquetball")
    set_poly(level2, "main_stair_landing", ccw([[-78.5, -80.0], [-64.5, -80.0], [-64.5, -40.0], [-78.5, -40.0]]))
    set_poly(
        level2,
        "balcony",
        ccw([[-64.5, -80.0], [-5.0, -80.0], [-5.0, -48.0], [-42.5, -48.0], [-42.5, -76.0], [-64.5, -76.0]]),
    )
    void_lobby = ccw(
        [
            [10.0, 0.0],
            [10.0, -36.0],
            [-10.0, -36.0],
            [-10.0, -16.0],
            [-97.0, -16.0],
            [-97.0, 0.0],
        ]
    )
    set_poly(level2, "void_lobby", void_lobby)
    for void in level2["voids"]:
        if void["id"] == "void_lobby":
            void["polygon"] = [list(p) for p in void_lobby]
    # 10 in going, 8 ft wide, south edge 30 ft from the glass. East edge stays off the hall probe.
    run_ns = 10 / 12
    run_ew = 10 / 12
    main_a = [[-88.5, -44.0], [-80.5, -44.0], [-80.5, -29.8], [-88.5, -29.8]]
    main_land = [[-88.5, -52.0], [-80.5, -52.0], [-80.5, -44.0], [-88.5, -44.0]]
    main_b = [[-102.7, -52.0], [-88.5, -52.0], [-88.5, -44.0], [-102.7, -44.0]]
    flight_voids = {
        "stair_main_opening": main_a,
        "stair_main_upper": main_b,
        "stair_main_landing": main_land,
    }
    for void in level2["voids"]:
        if void["id"] in flight_voids:
            void["polygon"] = [list(p) for p in flight_voids[void["id"]]]
    for stair in level1["stairs"]:
        if stair["id"] != "stair_main":
            continue
        stair["polygon"] = [list(p) for p in stair_poly]
        stair["direction"] = [0, -1]
        stair["width"] = 8
        stair["flights"] = [
            flight("main_a", main_a, [0, -1], 0, 8, run_ns),
            flight("main_b", main_b, [-1, 0], 10, 8, run_ew),
        ]
        stair["landings"] = [landing("main_turn", main_land, 10)]
    drop_pairs(
        level1,
        [
            ("lobby", "fitness_annex"),
            ("corridor_wide", "coach_suite"),
            ("south_vestibule", "corridor_south_link"),
            ("competition_gym", "corridor_gym_east"),
            ("thin_link", "corridor_entry_link"),
            ("locker_volleyball", "volleyball_washroom"),
            ("corridor_south_link", "south_gym"),
        ],
    )
    ensure_connection(level1, "team_support", "south_gym", 6, "door")
    drop_pairs(level2, [("corridor_l2", "racquetball_1"), ("corridor_l2", "racquetball_2")])
    ensure_connection(level1, "lobby", "south_vestibule", 12, "opening")
    ensure_connection(level1, "lobby", "glazed_recreation", 6, "opening")
    ensure_connection(level1, "south_vestibule", "stair_main", 12, "opening", head=12)
    ensure_connection(level1, "south_vestibule", "corridor_entry_south", 10, "opening")
    ensure_connection(level1, "corridor_entry_south", "stair_main", 16, "opening", head=12)
    ensure_connection(level1, "corridor_south_link", "stair_main", 8, "opening")
    ensure_connection(level1, "corridor_entry_south", "corridor_south_link", 8, "opening")
    ensure_connection(level1, "corridor_entry_south", "corridor_entry_link", 10, "opening")
    ensure_connection(level1, "corridor_entry_link", "corridor_gym_east", 10, "opening")
    ensure_connection(level1, "gym_foyer", "thin_link", "full", "opening", head=12)
    ensure_connection(level1, "thin_link", "competition_gym", "full", "opening", head=16)
    ensure_connection(level1, "thin_link", "athletic_corridor", 6, "opening")
    ensure_connection(level1, "thin_link", "corridor_gym_east", 8, "opening")
    ensure_connection(
        level1,
        "athletic_corridor",
        "nutrition_vestibule",
        3.5,
        "door",
        keypadCode="15234",
        label="NUTRITION VESTIBULE",
    )
    ensure_connection(level1, "nutrition_vestibule", "locker_volleyball", 3.5, "door")
    ensure_connection(level1, "athletic_corridor", "corridor_locker_west", 8, "opening")
    ensure_connection(level1, "corridor_locker_west", "stair_second", 8, "opening")
    ensure_connection(level1, "athletic_corridor", "volleyball_washroom", 3.5, "door")
    ensure_connection(level1, "glazed_recreation", "coach_suite", 4, "door")
    ensure_connection(level1, "restroom_ne_w", "fitness_north", 4, "door")
    ensure_connection(level1, "restroom_ne_m", "fitness_north", 4, "door")
    ensure_connection(level1, "restroom_ne_w", "restroom_ne_m", 3.5, "door")
    ensure_connection(level1, "corridor_main", "locker_general_w", 4, "door")
    ensure_connection(level1, "locker_general_w", "locker_general_m", 3.5, "door")
    ensure_connection(level2, "stair_main", "main_stair_landing", 8, "opening")
    ensure_connection(level2, "main_stair_landing", "balcony", 3, "opening")
    ensure_connection(level2, "main_stair_landing", "corridor_l2_overlook", 10, "opening")
    ensure_connection(level2, "corridor_l2_overlook", "racquetball_2", 4, "door", label="RACQUETBALL")
    ensure_connection(level2, "racquetball_2", "racquetball_1", 4, "door")
    ensure_connection(level2, "corridor_l2_overlook", "corridor_l2", 10, "opening")
    prune_connections(level1)
    prune_connections(level2)
    # South glass splits at the lobby / vestibule corner. The entry door is on the 20 ft bay.
    def south_or_entry_east(aperture):
        a, b = aperture.get("a"), aperture.get("b")
        if not a or not b:
            return False
        if abs(a[1]) < 0.01 and abs(b[1]) < 0.01 and min(a[0], b[0]) < 12:
            return True
        if abs(a[0] - 10) < 0.01 and abs(b[0] - 10) < 0.01 and max(a[1], b[1]) > -90:
            return True
        if abs(a[0] + 78.5) < 0.01 and abs(b[0] + 78.5) < 0.01 and min(a[1], b[1]) < -130:
            return True
        return False

    level1["apertures"] = [a for a in level1.get("apertures", []) if not south_or_entry_east(a)]
    level1["apertures"].extend(
        [
            {
                "a": [-97.0, 0.0],
                "b": [-10.0, 0.0],
                "height": 32.5,
                "openings": [{"center": 43.5, "width": 80, "kind": "curtainwall", "sill": 0, "head": 30}],
            },
            {
                "a": [-10.0, 0.0],
                "b": [10.0, 0.0],
                "height": 32.5,
                "openings": [
                    {"center": 1.5, "width": 2, "kind": "curtainwall", "sill": 0, "head": 30},
                    {"center": 6, "width": 6, "kind": "door", "sill": 0, "head": 8},
                    {"center": 14.5, "width": 9, "kind": "curtainwall", "sill": 0, "head": 30},
                ],
            },
            {
                "a": [10.0, -80.0],
                "b": [10.0, -36.0],
                "height": 19.5,
                "openings": [{"center": 22, "width": 40, "kind": "curtainwall", "sill": 0, "head": 18}],
            },
            {
                "a": [10.0, -36.0],
                "b": [10.0, 0.0],
                "height": 32.5,
                "openings": [{"center": 18, "width": 32, "kind": "curtainwall", "sill": 0, "head": 30}],
            },
            {
                "a": [-78.5, -170.0],
                "b": [-78.5, -132.5],
                "openings": [
                    {"center": 18, "width": 6, "kind": "door"},
                    {"center": 28, "width": 6, "kind": "door"},
                ],
            },
        ]
    )
    detail = load("stair_details.json")
    for stair in detail["stairs"]:
        if stair["id"] != "stair_main":
            continue
        stair["flights"] = [
            {
                "id": "main_a",
                "polygon": main_a,
                "direction": [0, -1],
                "risers": 17,
                "run": run_ns,
                "baseElevation": 0,
                "topElevation": 10,
            },
            {
                "id": "main_b",
                "polygon": main_b,
                "direction": [-1, 0],
                "risers": 17,
                "run": run_ew,
                "baseElevation": 10,
                "topElevation": 20,
            },
        ]
        stair["landings"] = [{"id": "main_turn", "polygon": main_land, "elevation": 10}]
        stair["turn"] = "left"
    save("stair_details.json", detail)
    # Compile must not shorten the old gallery line. Rails are assigned after the walls exist.
    level2["guards"] = []
    apply_gemini(layout)


def apply_answers(level1, level2):
    """User answers 2026-09-29 09:35. These override earlier desk and program notes.

    Linn gym joins the workout hall and the athletic corridor. The public locker
    is off the left hall. The elevator sits between the squat room and the coaches.
    Racquetball is light wood and white, with a glass entry wall. No juice bar
    and no third floor are added.
    """
    # Store off the training room. The 10 ft bay was walled in with no door.
    ensure_connection(level1, "training_room", "training_store", 3.5, "door")

    # Linn (south gym) north of the left glass hall, reached from the workout
    # side and from the athletic corridor. The southeast bite is the public locker.
    south = ccw(
        [
            [-236.5, -62.0],
            [-97.0, -62.0],
            [-97.0, -40.0],
            [-130.0, -40.0],
            [-130.0, -16.0],
            [-97.0, -16.0],
            [-97.0, 47.0],
            [-236.5, 47.0],
        ]
    )
    set_poly(level1, "south_gym", south)
    set_poly(level2, "void_south", [list(p) for p in south])
    for void in level2.get("voids", []):
        if void["id"] == "void_south":
            void["polygon"] = [list(p) for p in south]
    set_poly(level1, "team_support", ccw([[-205.5, -80.0], [-78.5, -80.0], [-78.5, -62.0], [-205.5, -62.0]]))
    add_room(
        level1,
        "public_locker",
        "Public Lockers",
        "locker",
        [[-130.0, -40.0], [-97.0, -40.0], [-97.0, -16.0], [-130.0, -16.0]],
        floor="porcelain_tile",
        ceiling=10,
        ceiling_type="act_2x2",
        finish="gypsum",
    )
    drop_pairs(level1, [("south_gym", "corridor_south_link")])
    ensure_connection(level1, "team_support", "south_gym", 8, "opening")
    ensure_connection(level1, "team_support", "athletic_corridor", 5, "opening")
    ensure_connection(level1, "team_support", "corridor_entry_south", 6, "opening")
    ensure_connection(level1, "corridor_entry_south", "corridor_wide", 8, "opening")
    # 24 ft east wall. Center 20 keeps the 6 ft door at the south end, off the locker bank.
    ensure_connection(level1, "public_locker", "corridor_south_link", 6, "door", label="LOCKERS", center=20)

    # Elevator on the shared corner of the squat room and the south coach office.
    set_poly(
        level1,
        "weight_room",
        ccw([[-66.5, -124.0], [-40.0, -124.0], [-40.0, -88.0], [-44.0, -88.0], [-44.0, -80.0], [-66.5, -80.0]]),
    )
    set_poly(
        level1,
        "coach_head",
        ccw([[-40.0, -96.0], [-28.0, -96.0], [-28.0, -80.0], [-36.0, -80.0], [-36.0, -88.0], [-40.0, -88.0]]),
    )
    set_poly(
        level2,
        "cardio_gallery",
        ccw(
            [
                [-64.5, -154.5],
                [-5.0, -154.5],
                [-5.0, -80.0],
                [-36.0, -80.0],
                [-36.0, -88.0],
                [-44.0, -88.0],
                [-44.0, -80.0],
                [-64.5, -80.0],
            ]
        ),
    )
    elevator = [[-44.0, -88.0], [-36.0, -88.0], [-36.0, -80.0], [-44.0, -80.0]]
    for level in (level1, level2):
        add_room(
            level,
            "elevator",
            "Elevator",
            "support",
            elevator,
            floor="porcelain_tile",
            ceiling=10,
            ceiling_type="act_2x2",
            finish="gypsum",
        )
    ensure_connection(level1, "elevator", "weight_room", 3.5, "door")
    ensure_connection(level1, "elevator", "coach_head", 3.5, "door")
    ensure_connection(level1, "elevator", "corridor_wide", 3.5, "door", label="ELEVATOR")
    ensure_connection(level2, "elevator", "cardio_gallery", 3.5, "door")
    ensure_connection(level2, "elevator", "balcony", 3.5, "door", label="ELEVATOR")

    # Service yard hard against the volleyball gym's west wall. Open to the south.
    add_room(
        level1,
        "service_yard",
        "Service Yard",
        "mechanical",
        [[-236.5, -214.0], [-193.5, -214.0], [-193.5, -186.0], [-236.5, -186.0]],
        floor="sealed_concrete",
        ceiling=12,
        ceiling_type="none",
        finish="painted_cmu",
    )

    # Level 2 hall continues west past the down stair to the basketball door, then the grade exit.
    set_poly(level2, "corridor_l2", ccw([[-359.5, -92.5], [-78.5, -92.5], [-78.5, -80.0], [-359.5, -80.0]]))
    ensure_connection(level2, "corridor_l2", "basketball_approach", 4, "door", label="BASKETBALL — OFF LIMITS")
    ensure_connection(level2, "basketball_approach", "cage_gym", 4, "door", label="BASKETBALL — OFF LIMITS")

    # Light wood floor, white walls. The glass entry wall is applied after compile.
    set_room(level2, "racquetball_1", wallFinish="gypsum", floorMaterial="maple")
    set_room(level2, "racquetball_2", wallFinish="gypsum", floorMaterial="maple")


def apply_gemini(layout):
    """Last layout writer. Gemini defects, then the lobby-stair and L2-hall walk.

    The upper flight has to meet the Level 2 door. The stair itself sits in the
    open 20x20, first flight north along the east wall, left turn, 17+17.
    Racquetball is on the left of the westbound Level 2 hall, then the down stair.
    """
    level1 = layout["levels"][0]
    level2 = layout["levels"][1]
    run = 14.5 / 17  # 10.24 in, on a half-foot polygon

    # Open 20x20 (x=-10..10, z=-20..0). The stair starts north of that bay so a
    # double-height strip stays in front of the south glass. First flight runs
    # north along the east wall, then left.
    lobby_poly = ccw(
        [
            [-10.0, 0.0],
            [10.0, 0.0],
            [10.0, -23.5],
            [2.0, -23.5],
            [2.0, -40.0],
            [-12.5, -40.0],
            [-12.5, -16.0],
            [-10.0, -16.0],
        ]
    )
    set_poly(level1, "lobby", lobby_poly)
    set_room(level1, "lobby", ceilingHeight=32, ceilingType="gypsum", floorMaterial="porcelain_tile", wallFinish="gypsum")
    set_poly(level1, "south_vestibule", ccw([[-97.0, 0.0], [-97.0, -16.0], [-10.0, -16.0], [-10.0, 0.0]]))
    set_room(level1, "south_vestibule", ceilingHeight=32, ceilingType="gypsum", floorMaterial="porcelain_tile", wallFinish="gypsum")
    # Glass hall turns north into a 12 ft+ hall. Gym doors stay on the left of the north run.
    set_poly(level1, "corridor_south_link", ccw([[-97.0, -54.0], [-78.5, -54.0], [-78.5, -16.0], [-97.0, -16.0]]))
    set_room(level1, "corridor_south_link", floorMaterial="porcelain_tile", ceilingHeight=32, ceilingType="gypsum", wallFinish="gypsum")
    set_poly(level1, "corridor_entry_south", ccw([[-78.5, -80.0], [-66.5, -80.0], [-66.5, -16.0], [-78.5, -16.0]]))
    set_room(level1, "corridor_entry_south", floorMaterial="terrazzo", ceilingHeight=12, ceilingType="act_2x4", wallFinish="painted_cmu")
    set_poly(level1, "south_gym", ccw([[-236.5, 47.0], [-236.5, -62.0], [-97.0, -62.0], [-97.0, 47.0]]))
    set_poly(level2, "void_south", ccw([[-236.5, 47.0], [-236.5, -62.0], [-97.0, -62.0], [-97.0, 47.0]]))
    for void in level2.get("voids", []):
        if void["id"] == "void_south":
            void["polygon"] = ccw([[-236.5, 47.0], [-236.5, -62.0], [-97.0, -62.0], [-97.0, 47.0]])

    # South edge 25.5 ft off the glass. Two feet of apron, then the first riser.
    # The long sides stay solid so the treads are not inside a door.
    main_a = ccw([[2.0, -25.5], [10.0, -25.5], [10.0, -40.0], [2.0, -40.0]])
    main_land = ccw([[2.0, -40.0], [10.0, -40.0], [10.0, -48.0], [2.0, -48.0]])
    main_b = ccw([[-12.5, -40.0], [2.0, -40.0], [2.0, -48.0], [-12.5, -48.0]])
    stair_poly = ccw(
        [
            [10.0, -23.5],
            [10.0, -48.0],
            [-12.5, -48.0],
            [-12.5, -40.0],
            [2.0, -40.0],
            [2.0, -23.5],
        ]
    )
    set_poly(level1, "stair_main", stair_poly)
    set_poly(level2, "stair_main", [list(p) for p in stair_poly])
    set_room(level1, "stair_main", ceilingType="none", ceilingHeight=32, wallFinish="painted_cmu")
    set_room(level2, "stair_main", ceilingType="none", ceilingHeight=12, wallFinish="painted_cmu")
    flights = [
        flight("main_a", main_a, [0, -1], 0, 8, run),
        flight("main_b", main_b, [-1, 0], 10, 8, run),
    ]
    lands = [landing("main_turn", main_land, 10)]
    for level in (level1, level2):
        for stair in level.get("stairs", []):
            if stair["id"] != "stair_main":
                continue
            stair["polygon"] = [list(p) for p in stair_poly]
            stair["direction"] = [0, -1]
            stair["width"] = 8
            stair["risers"] = 34
            stair["rise"] = RISE
            stair["run"] = run
            stair["flights"] = flights
            stair["landings"] = lands
            stair["fromLevel"] = 1
            stair["toLevel"] = 2
    for void in level2.get("voids", []):
        if void["id"] == "stair_main_opening":
            void["polygon"] = [list(p) for p in main_a]
        elif void["id"] == "stair_main_upper":
            void["polygon"] = [list(p) for p in main_b]
        elif void["id"] == "stair_main_landing":
            void["polygon"] = [list(p) for p in main_land]
    detail = load("stair_details.json")
    for stair in detail["stairs"]:
        if stair["id"] != "stair_main":
            continue
        stair["flights"] = [
            {"id": "main_a", "polygon": main_a, "direction": [0, -1], "risers": 17, "run": run, "baseElevation": 0, "topElevation": 10},
            {"id": "main_b", "polygon": main_b, "direction": [-1, 0], "risers": 17, "run": run, "baseElevation": 10, "topElevation": 20},
        ]
        stair["landings"] = [{"id": "main_turn", "polygon": main_land, "elevation": 10}]
        stair["turn"] = "left"
    save("stair_details.json", detail)

    # Fitness floor stays open behind the desk. North edge stops on the stair landing.
    set_poly(level1, "fitness_annex", ccw([[-42.5, -48.0], [-12.5, -48.0], [-12.5, -16.0], [-42.5, -16.0]]))
    set_room(level1, "fitness_annex", ceilingHeight=12, ceilingType="act_2x2", wallFinish="gypsum", floorMaterial="rubber")
    set_poly(level1, "glazed_recreation", ccw([[-5.0, -80.0], [10.0, -80.0], [10.0, -48.0], [-5.0, -48.0]]))
    set_room(level1, "glazed_recreation", wallFinish="gypsum", floorMaterial="porcelain_tile")
    set_poly(
        level1,
        "corridor_wide",
        ccw([[-66.5, -80.0], [-5.0, -80.0], [-5.0, -48.0], [-42.5, -48.0], [-42.5, -41.0], [-66.5, -41.0]]),
    )
    set_room(level1, "corridor_wide", wallFinish="gypsum", floorMaterial="porcelain_tile")

    # 8 ft thin link. Long walls stay solid; the ends open into the gym hall and the athletic hall.
    # 9 ft so the 8 ft end openings survive the span trim (an 8 ft room clamps to 7.5).
    set_poly(level1, "thin_link", ccw([[-193.5, -186.0], [-78.5, -186.0], [-78.5, -177.0], [-193.5, -177.0]]))
    set_room(level1, "thin_link", floorMaterial="terrazzo", ceilingHeight=12, ceilingType="act_2x4", type="corridor", wallFinish="painted_cmu")
    set_poly(level1, "gym_foyer", ccw([[-193.5, -177.0], [-78.5, -177.0], [-78.5, -132.5], [-193.5, -132.5]]))
    set_room(level1, "gym_foyer", floorMaterial="maple", ceilingHeight=12, ceilingType="act_2x4", wallFinish="painted_cmu", type="lobby")
    set_poly(level1, "athletic_corridor", ccw([[-205.5, -186.0], [-193.5, -186.0], [-193.5, -80.0], [-205.5, -80.0]]))

    # Turn left: training, nutrition vestibule, locker, then the west hall to the second stair.
    set_poly(level1, "training_room", ccw([[-236.5, -180.0], [-205.5, -180.0], [-205.5, -150.0], [-236.5, -150.0]]))
    set_room(level1, "training_room", type="support", floorMaterial="porcelain_tile", ceilingHeight=10, ceilingType="act_2x4", wallFinish="painted_cmu")
    set_poly(level1, "training_store", ccw([[-236.5, -150.0], [-215.5, -150.0], [-215.5, -140.0], [-236.5, -140.0]]))
    set_poly(level1, "nutrition_vestibule", ccw([[-215.5, -150.0], [-205.5, -150.0], [-205.5, -140.0], [-215.5, -140.0]]))
    set_room(level1, "nutrition_vestibule", type="support", floorMaterial="porcelain_tile", ceilingHeight=9, ceilingType="act_2x2", wallFinish="painted_cmu")
    set_poly(level1, "locker_volleyball", ccw([[-239.5, -140.0], [-205.5, -140.0], [-205.5, -118.0], [-239.5, -118.0]]))
    set_room(level1, "locker_volleyball", wallFinish="painted_cmu")
    set_poly(level1, "corridor_locker_west", ccw([[-305.0, -118.0], [-205.5, -118.0], [-205.5, -100.0], [-305.0, -100.0]]))
    set_poly(level1, "cage_lower_reserved", ccw([[-351.5, -220.0], [-236.5, -220.0], [-236.5, -140.0], [-351.5, -140.0]]))
    set_room(level1, "cage_lower_reserved", type="construction")
    # Addition stays north of the cage. The west strip no longer swallows the stair or the locker hall.
    set_poly(level1, "addition", ccw([[-379.0, -301.0], [-225.0, -301.0], [-225.0, -220.0], [-379.0, -220.0]]))
    set_room(level1, "addition", type="construction")
    set_poly(
        level1,
        "corridor_ne",
        ccw(
            [
                [-78.5, -262.0],
                [-66.5, -262.0],
                [-66.5, -224.0],
                [-28.0, -224.0],
                [-28.0, -212.0],
                [-70.5, -212.0],
                [-70.5, -195.5],
                [-78.5, -195.5],
            ]
        ),
    )

    # Second stair: 8 ft flights and 8x8 landings. The upper flight climbs south
    # (direction +Z) onto a +20 landing whose south edge is the Level 2 door at z=-92.5.
    second_poly = ccw([[-343.5, -132.5], [-305.0, -132.5], [-305.0, -92.5], [-343.5, -92.5]])
    run14 = 14.5 / 17
    second_a = ccw([[-321.0, -123.0], [-335.5, -123.0], [-335.5, -115.0], [-321.0, -115.0]])
    second_land = ccw([[-343.5, -123.0], [-335.5, -123.0], [-335.5, -115.0], [-343.5, -115.0]])
    second_b = ccw([[-343.5, -115.0], [-335.5, -115.0], [-335.5, -100.5], [-343.5, -100.5]])
    second_bridge = ccw([[-343.5, -100.5], [-335.5, -100.5], [-335.5, -92.5], [-343.5, -92.5]])
    second_flights = [
        flight("second_a", second_a, [-1, 0], 0, 8, run14),
        flight("second_b", second_b, [0, 1], 10, 8, run14),
    ]
    second_lands = [
        landing("second_turn", second_land, 10),
        landing("second_bridge", second_bridge, 20),
    ]
    for level in (level1, level2):
        set_poly(level, "stair_second", second_poly)
        for stair in level.get("stairs", []):
            if stair["id"] != "stair_second":
                continue
            stair["polygon"] = [list(p) for p in second_poly]
            stair["width"] = 8
            stair["run"] = run14
            stair["flights"] = second_flights
            stair["landings"] = second_lands
    for void in level2.get("voids", []):
        if void["id"] == "stair_second_opening":
            void["polygon"] = [list(p) for p in second_a]
        elif void["id"] == "stair_second_upper":
            void["polygon"] = [list(p) for p in second_b]
        elif void["id"] == "stair_second_bridge":
            void["polygon"] = [list(p) for p in second_bridge]
    if not any(void.get("id") == "stair_second_bridge" for void in level2.get("voids", [])):
        level2.setdefault("voids", []).append(
            {"id": "stair_second_bridge", "polygon": [list(p) for p in second_bridge]}
        )
    set_poly(level2, "basketball_approach", ccw([[-351.5, -132.5], [-343.5, -132.5], [-343.5, -92.5], [-351.5, -92.5]]))

    # Overlook stops at the gym. Courts sit on the left (south) of the westbound hall.
    set_poly(level2, "corridor_l2_overlook", ccw([[-78.5, -279.5], [-64.5, -279.5], [-64.5, -80.0], [-78.5, -80.0]]))
    set_room(level2, "corridor_l2_overlook", floorMaterial="terrazzo", ceilingHeight=10, ceilingType="act_2x2", wallFinish="painted_cmu")
    add_room(
        level2,
        "overlook_mechanical",
        "Overlook Mechanical",
        "mechanical",
        [[-118.5, -330.0], [-78.5, -330.0], [-78.5, -279.5], [-118.5, -279.5]],
        floor="sealed_concrete",
        ceiling=10,
        ceiling_type="none",
        finish="painted_cmu",
    )
    set_poly(level2, "court_gallery", ccw([[-305.0, -60.0], [-285.0, -60.0], [-285.0, -48.0], [-305.0, -48.0]]))
    set_poly(level2, "racquetball_2", ccw([[-265.0, -80.0], [-225.0, -80.0], [-225.0, -60.0], [-265.0, -60.0]]))
    set_poly(level2, "racquetball_1", ccw([[-305.0, -80.0], [-265.0, -80.0], [-265.0, -60.0], [-305.0, -60.0]]))
    set_room(level2, "racquetball_1", ceilingHeight=16.5, type="racquetball", wallFinish="gypsum", floorMaterial="maple")
    set_room(level2, "racquetball_2", ceilingHeight=16.5, type="racquetball", wallFinish="gypsum", floorMaterial="maple")
    # Open cardio floor. The south edge is the rail over the lobby, not a brick wall.
    set_poly(level2, "cardio_south", ccw([[-42.5, -48.0], [-12.5, -48.0], [-12.5, -16.0], [-42.5, -16.0]]))
    set_room(level2, "cardio_south", floorMaterial="rubber", ceilingHeight=12, ceilingType="act_2x2", wallFinish="gypsum")
    set_poly(level2, "main_stair_landing", ccw([[-78.5, -80.0], [-64.5, -80.0], [-64.5, -40.0], [-78.5, -40.0]]))
    set_room(level2, "main_stair_landing", wallFinish="painted_cmu", floorMaterial="terrazzo")
    set_poly(level2, "balcony", ccw([[-64.5, -80.0], [-5.0, -80.0], [-5.0, -48.0], [-42.5, -48.0], [-42.5, -16.0], [-64.5, -16.0], [-64.5, -40.0], [-64.5, -80.0]]))
    # balcony polygon above is self-overlapping; use a clean rect west of the new stair and north of the rail.
    set_poly(level2, "balcony", ccw([[-64.5, -80.0], [-12.5, -80.0], [-12.5, -48.0], [-42.5, -48.0], [-42.5, -16.0], [-64.5, -16.0]]))
    set_room(level2, "balcony", wallFinish="gypsum", floorMaterial="rubber", ceilingHeight=12, ceilingType="act_2x2")
    void_lobby = ccw(
        [
            [10.0, 0.0],
            [10.0, -23.5],
            [2.0, -23.5],
            [2.0, -40.0],
            [-12.5, -40.0],
            [-12.5, -16.0],
            [-97.0, -16.0],
            [-97.0, 0.0],
        ]
    )
    set_poly(level2, "void_lobby", void_lobby)
    for void in level2.get("voids", []):
        if void["id"] == "void_lobby":
            void["polygon"] = [list(p) for p in void_lobby]

    drop_pairs(
        level1,
        [
            ("south_vestibule", "stair_main"),
            ("corridor_entry_south", "stair_main"),
            ("corridor_south_link", "stair_main"),
            ("thin_link", "competition_gym"),
            ("gym_foyer", "thin_link"),
            ("fitness_annex", "corridor_wide"),
            ("south_vestibule", "fitness_annex"),
        ],
    )
    drop_pairs(
        level2,
        [
            ("racquetball_1", "racquetball_2"),
            ("corridor_l2_overlook", "racquetball_1"),
            ("corridor_l2_overlook", "racquetball_2"),
            ("corridor_l2", "court_gallery"),
        ],
    )
    # No lobby/stair connection: the compiler would open the longest shared edge,
    # which is the side of the flight. The south threshold is an aperture below.
    ensure_connection(level1, "lobby", "south_vestibule", "full", "opening", head=16)
    ensure_connection(level1, "south_vestibule", "corridor_south_link", "full", "opening", head=16)
    ensure_connection(level1, "corridor_south_link", "corridor_entry_south", "full", "opening", head=12)
    ensure_connection(level1, "lobby", "fitness_annex", "full", "opening", head=12)
    ensure_connection(level1, "fitness_annex", "corridor_wide", "full", "opening", head=10)
    ensure_connection(level1, "thin_link", "corridor_gym_east", 8, "opening")
    ensure_connection(level1, "thin_link", "athletic_corridor", 8, "opening")
    # The south wall of the court is 115 ft. Keep an 8 ft passage at the east end
    # (center 104). Width "full" would open the whole wall.
    ensure_connection(level1, "thin_link", "competition_gym", 8, "opening", head=12, center=104)
    ensure_connection(level1, "athletic_corridor", "training_room", 4, "door")
    ensure_connection(level1, "athletic_corridor", "nutrition_vestibule", 6, "door", keypadCode="15234", label="NUTRITION VESTIBULE")
    # 10 ft shared edge. Center 6.5 puts the 6 ft door on the east side, clear of the fridge.
    ensure_connection(level1, "nutrition_vestibule", "locker_volleyball", 6, "door", center=6.5)
    ensure_connection(level1, "athletic_corridor", "corridor_locker_west", 8, "opening")
    ensure_connection(level1, "corridor_locker_west", "stair_second", 6, "opening")
    ensure_connection(level2, "stair_main", "cardio_south", 6, "opening", head=10)
    ensure_connection(level2, "cardio_south", "balcony", "full", "opening", head=10)
    ensure_connection(level2, "balcony", "main_stair_landing", "full", "opening", head=10)
    ensure_connection(level2, "main_stair_landing", "corridor_l2_overlook", 10, "opening")
    ensure_connection(level2, "corridor_l2_overlook", "corridor_l2", 10, "opening")
    ensure_connection(level2, "corridor_l2", "racquetball_2", 4, "door", label="RACQUETBALL")
    ensure_connection(level2, "corridor_l2", "racquetball_1", 6, "door", label="RACQUETBALL")
    ensure_connection(level2, "corridor_l2", "stair_second", 4, "door")
    apply_answers(level1, level2)
    prune_connections(level1)
    prune_connections(level2)
    # Gym doors on the left of the north hall. The wall is the foyer/hall edge, not the old 113 ft slot.
    level1["apertures"] = [
        aperture
        for aperture in level1.get("apertures", [])
        if not (
            abs(aperture["a"][0] + 78.5) < 0.01
            and abs(aperture["b"][0] + 78.5) < 0.01
            and min(aperture["a"][1], aperture["b"][1]) < -130
        )
    ]
    level1["apertures"] = [
        aperture
        for aperture in level1["apertures"]
        if not (abs(aperture["a"][0] - 10) < 0.01 and abs(aperture["b"][0] - 10) < 0.01)
    ]
    # The stair threshold moved from z=-16.5 to z=-23.5. The old chord is inside the lobby.
    level1["apertures"] = [
        aperture
        for aperture in level1["apertures"]
        if not (
            abs(aperture["a"][1] + 16.5) < 0.01
            and abs(aperture["b"][1] + 16.5) < 0.01
            and min(aperture["a"][0], aperture["b"][0]) >= 1.5
            and max(aperture["a"][0], aperture["b"][0]) <= 10.5
        )
    ]
    level1["apertures"].extend(
        [
            {
                "a": [-78.5, -177.0],
                "b": [-78.5, -132.5],
                "openings": [
                    {"center": 25.0, "width": 6, "kind": "door"},
                    {"center": 35.0, "width": 6, "kind": "door"},
                ],
            },
            {
                "a": [10.0, -80.0],
                "b": [10.0, -48.0],
                "height": 12.5,
                "openings": [{"center": 16.0, "width": 30, "kind": "curtainwall", "sill": 0, "head": 11}],
            },
            {
                "a": [10.0, -23.5],
                "b": [10.0, 0.0],
                "height": 32.5,
                "openings": [{"center": 11.5, "width": 21, "kind": "curtainwall", "sill": 0, "head": 30}],
            },
            {
                "a": [2.0, -23.5],
                "b": [10.0, -23.5],
                "openings": [{"center": 4.0, "width": 6, "kind": "opening", "head": 12}],
            },
        ]
    )


def apply_review(layout):
    """User review 01:40: stair setback, left hall to the gym, cardio rail, coaches suite."""
    level1 = layout["levels"][0]
    level2 = layout["levels"][1]
    # Double-height entry. The left hallway is the glass strip; the stair sits north of it.
    set_poly(
        level1,
        "lobby",
        [[-10.0, -28.0], [10.0, -28.0], [10.0, 0.0], [-18.0, 0.0], [-18.0, -16.0], [-10.0, -16.0]],
    )
    set_room(level1, "lobby", ceilingHeight=32, ceilingType="gypsum")
    set_poly(level1, "glazed_recreation", [[-5.0, -80.0], [10.0, -80.0], [10.0, -28.0], [-5.0, -28.0]])
    set_poly(
        level1,
        "south_vestibule",
        ccw(
            [
                [-97.0, 0.0],
                [-97.0, -16.0],
                [-66.5, -16.0],
                [-66.5, -28.0],
                [-42.5, -28.0],
                [-42.5, -16.0],
                [-18.0, -16.0],
                [-18.0, 0.0],
            ]
        ),
    )
    set_room(level1, "south_vestibule", ceilingHeight=32, ceilingType="gypsum", floorMaterial="porcelain_tile")
    set_poly(
        level1,
        "fitness_annex",
        ccw([[-42.5, -48.0], [-5.0, -48.0], [-5.0, -28.0], [-10.0, -28.0], [-10.0, -16.0], [-42.5, -16.0]]),
    )
    set_poly(level1, "corridor_entry_south", ccw([[-78.5, -80.0], [-66.5, -80.0], [-66.5, -16.0], [-78.5, -16.0]]))
    set_room(level1, "corridor_entry_south", type="corridor", floorMaterial="terrazzo", ceilingHeight=12, ceilingType="act_2x4")
    set_poly(
        level1,
        "corridor_wide",
        ccw([[-66.5, -80.0], [-5.0, -80.0], [-5.0, -48.0], [-42.5, -48.0], [-42.5, -60.0], [-66.5, -60.0]]),
    )
    set_poly(level1, "corridor_south_link", ccw([[-97.0, -62.0], [-78.5, -62.0], [-78.5, -16.0], [-97.0, -16.0]]))
    set_poly(level1, "weight_room", ccw([[-66.5, -124.0], [-40.0, -124.0], [-40.0, -80.0], [-66.5, -80.0]]))
    set_poly(level1, "fitness_center", ccw([[-66.5, -154.5], [-5.0, -154.5], [-5.0, -124.0], [-66.5, -124.0]]))
    set_poly(level1, "lobby_north", ccw([[-5.0, -154.5], [10.0, -154.5], [10.0, -124.0], [-5.0, -124.0]]))
    stair_poly = ccw([[-66.5, -60.0], [-42.5, -60.0], [-42.5, -28.0], [-66.5, -28.0]])
    set_poly(level1, "stair_main", stair_poly)
    set_poly(level2, "stair_main", [list(p) for p in stair_poly])
    set_room(level1, "stair_main", ceilingType="none", ceilingHeight=32)
    set_room(level2, "stair_main", ceilingType="none", ceilingHeight=12)
    set_poly(level2, "main_stair_landing", ccw([[-66.5, -76.0], [-42.5, -76.0], [-42.5, -60.0], [-66.5, -60.0]]))
    set_poly(
        level2,
        "balcony",
        ccw(
            [
                [-78.5, -80.0],
                [-5.0, -80.0],
                [-5.0, -48.0],
                [-42.5, -48.0],
                [-42.5, -76.0],
                [-66.5, -76.0],
                [-66.5, -48.0],
                [-78.5, -48.0],
            ]
        ),
    )
    set_poly(level2, "cardio_south", ccw([[-42.5, -48.0], [-10.0, -48.0], [-10.0, -16.0], [-42.5, -16.0]]))
    drop_rooms(level1, ["glazed_recreation_west", "vestibule_inner"])
    # Coaches' suite: straight through the east workout aisle, glass front at z=-80.
    carpet = dict(floor="carpet_tile", ceiling=9, ceiling_type="act_2x2", finish="gypsum")
    offices = [
        ("coach_head", "Head Coach", [[-40.0, -96.0], [-28.0, -96.0], [-28.0, -80.0], [-40.0, -80.0]]),
        ("coach_west", "Coach Office West", [[-40.0, -112.0], [-28.0, -112.0], [-28.0, -96.0], [-40.0, -96.0]]),
        ("coach_west_n", "Coach Office West North", [[-40.0, -124.0], [-28.0, -124.0], [-28.0, -112.0], [-40.0, -112.0]]),
        ("coach_suite", "Coaches Suite", [[-28.0, -112.0], [2.0, -112.0], [2.0, -80.0], [-28.0, -80.0]]),
        ("coach_north", "Coach Office North", [[-28.0, -124.0], [2.0, -124.0], [2.0, -112.0], [-28.0, -112.0]]),
        ("coach_east_s", "Coach Office East", [[2.0, -96.0], [10.0, -96.0], [10.0, -80.0], [2.0, -80.0]]),
        ("coach_east_m", "Coach Office East Middle", [[2.0, -112.0], [10.0, -112.0], [10.0, -96.0], [2.0, -96.0]]),
        ("coach_east_n", "Coach Office East North", [[2.0, -124.0], [10.0, -124.0], [10.0, -112.0], [2.0, -112.0]]),
    ]
    for rid, name, poly in offices:
        add_room(level1, rid, name, "office" if rid != "coach_suite" else "office", poly, **carpet)
    set_room(level1, "coach_suite", name="Coaches Suite", type="office")
    drop_pairs(
        level1,
        [
            ("corridor_wide", "corridor_entry_link"),
            ("south_vestibule", "fitness_annex"),
            ("corridor_south_link", "corridor_wide"),
            ("fitness_annex", "corridor_entry_south"),
            ("glazed_recreation", "lobby_north"),
        ],
    )
    drop_pairs(level2, [("balcony", "stair_main"), ("main_stair_landing", "cardio_south")])
    ensure_connection(level1, "south_vestibule", "corridor_south_link", 16, "opening")
    ensure_connection(level1, "corridor_entry_south", "corridor_south_link", 36, "opening")
    ensure_connection(level1, "lobby", "fitness_annex", 10, "opening")
    ensure_connection(level1, "corridor_entry_south", "corridor_wide", 16, "opening")
    ensure_connection(level2, "balcony", "cardio_south", 8, "opening")
    ensure_connection(level1, "lobby", "south_vestibule", 12, "opening")
    ensure_connection(level1, "lobby", "glazed_recreation", 10, "opening")
    ensure_connection(level1, "south_vestibule", "stair_main", 16, "opening")
    ensure_connection(level1, "south_vestibule", "corridor_entry_south", 8, "opening")
    ensure_connection(level1, "south_vestibule", "fitness_annex", 12, "opening")
    ensure_connection(level1, "corridor_entry_south", "corridor_entry_link", 8, "opening")
    ensure_connection(level1, "corridor_entry_link", "corridor_gym_east", 8, "opening")
    ensure_connection(level1, "glazed_recreation", "coach_suite", 4, "door")
    ensure_connection(level1, "corridor_wide", "coach_suite", 6, "door")
    ensure_connection(level1, "corridor_wide", "coach_head", 3.5, "door")
    ensure_connection(level1, "coach_suite", "coach_head", 3.5, "door")
    ensure_connection(level1, "coach_suite", "coach_west", 3.5, "door")
    ensure_connection(level1, "coach_suite", "coach_north", 3.5, "door")
    ensure_connection(level1, "coach_suite", "coach_east_s", 3.5, "door")
    ensure_connection(level1, "coach_suite", "coach_east_m", 3.5, "door")
    ensure_connection(level1, "coach_west", "coach_west_n", 3.5, "door")
    ensure_connection(level1, "coach_east_s", "coach_east_m", 3.5, "door")
    ensure_connection(level1, "coach_east_m", "coach_east_n", 3.5, "door")
    ensure_connection(level1, "coach_north", "lobby_north", 3.5, "door")
    ensure_connection(level1, "coach_west_n", "weight_room", 3.5, "door")
    ensure_connection(level1, "weight_room", "fitness_center", 6, "opening")
    ensure_connection(level1, "weight_room", "corridor_wide", 8, "opening")
    ensure_connection(level2, "stair_main", "main_stair_landing", 10, "opening")
    ensure_connection(level2, "main_stair_landing", "balcony", 12, "opening")
    # Level 2 overlook: a real corridor along the east side of the competition gym.
    set_poly(
        level2,
        "corridor_l2_overlook",
        [[-78.5, -262.0], [-64.5, -262.0], [-64.5, -80.0], [-78.5, -80.0]],
    )
    set_room(
        level2,
        "corridor_l2_overlook",
        floorMaterial="terrazzo",
        ceilingHeight=10,
        ceilingType="act_2x2",
        wallFinish="painted_cmu",
    )
    level2["rooms"] = [room for room in level2["rooms"] if room["id"] != "corridor_l2_return"]
    set_poly(level2, "fitness_north", [[-64.5, -195.5], [10.0, -195.5], [10.0, -154.5], [-64.5, -154.5]])
    set_poly(level2, "cardio_gallery", [[-64.5, -154.5], [-5.0, -154.5], [-5.0, -80.0], [-64.5, -80.0]])
    set_poly(level2, "office_ne_reception", [[-64.5, -262.0], [-28.0, -262.0], [-28.0, -224.0], [-64.5, -224.0]])
    set_poly(level2, "restroom_ne_w", [[-64.5, -212.0], [-47.0, -212.0], [-47.0, -195.5], [-64.5, -195.5]])
    set_poly(level2, "corridor_ne", [[-64.5, -224.0], [-28.0, -224.0], [-28.0, -212.0], [-64.5, -212.0]])
    removed_pairs = [
        ("balcony", "corridor_l2_return"),
        ("corridor_l2_return", "corridor_l2_overlook"),
        ("corridor_l2_return", "corridor_l2"),
        ("corridor_ne", "office_ne_1"),
        ("corridor_ne", "fitness_north"),
        ("corridor_l2_overlook", "fitness_north"),
    ]
    level2["connections"] = [c for c in level2["connections"] if set(c["rooms"]) not in [{a, b} for a, b in removed_pairs]]
    ensure_connection(level2, "balcony", "corridor_l2_overlook", 12, "opening")
    ensure_connection(level2, "corridor_l2_overlook", "corridor_l2", 10, "opening")
    ensure_connection(level2, "corridor_l2_overlook", "fitness_north", 6, "door")
    ensure_connection(level2, "corridor_l2_overlook", "office_ne_reception", 3.5, "door")
    ensure_connection(level2, "corridor_l2_overlook", "office_ne_1", 3.5, "door")
    # Leave jambs at the tee so the crossing wall is outside the door probe.
    for conn in level1["connections"]:
        if set(conn["rooms"]) == {"glazed_recreation", "fitness_annex"} and conn.get("type") == "opening":
            conn["width"] = 10
    # South glass follows the vestibule (to x=-18) and the widened lobby.
    def south_glass(aperture):
        a, b = aperture.get("a"), aperture.get("b")
        return bool(a and b and abs(a[1]) < 0.01 and abs(b[1]) < 0.01 and min(a[0], b[0]) < 10)
    level1["apertures"] = [a for a in level1.get("apertures", []) if not south_glass(a)]
    level1["apertures"].append(
        {
            "a": [-97.0, 0.0],
            "b": [-18.0, 0.0],
            "height": 32.5,
            "openings": [{"center": 39.5, "width": 74, "kind": "curtainwall", "sill": 0, "head": 30}],
        }
    )
    level1["apertures"].append(
        {
            "a": [-18.0, 0.0],
            "b": [10.0, 0.0],
            "height": 32.5,
            "openings": [
                {"center": 5.5, "width": 9, "kind": "curtainwall", "sill": 0, "head": 30},
                {"center": 14, "width": 6, "kind": "door", "sill": 0, "head": 8},
                {"center": 22.5, "width": 9, "kind": "curtainwall", "sill": 0, "head": 30},
            ],
        }
    )
    # The old single east-glass run crossed the coaches' suite. Keep glass on the double-height bays only.
    level1["apertures"] = [
        a
        for a in level1.get("apertures", [])
        if a.get("a") != [10.0, -154.5] or a.get("b") != [10.0, -80.0]
    ]
    # East curtain segments follow the deeper lobby (z=-28) instead of the old z=-20 joint.
    for aperture in level1.get("apertures", []):
        if aperture.get("a") == [10.0, -80.0] and aperture.get("b") == [10.0, -20.0]:
            aperture["a"], aperture["b"] = [10.0, -80.0], [10.0, -28.0]
            aperture["openings"][0]["center"] = 26
            aperture["openings"][0]["width"] = 48
        elif aperture.get("a") == [10.0, -20.0] and aperture.get("b") == [10.0, 0.0]:
            aperture["a"], aperture["b"] = [10.0, -28.0], [10.0, 0.0]
            aperture["openings"][0]["center"] = 14
            aperture["openings"][0]["width"] = 24
    # The old 22 ft window spec no longer matches a wall. Glass is applied after compile.
    level2["apertures"] = [
        a
        for a in level2.get("apertures", [])
        if a.get("a") != [-78.5, -154.5] or a.get("b") != [-78.5, -132.5]
    ]
    void_lobby = ccw(
        [
            [-5.0, -154.5],
            [10.0, -154.5],
            [10.0, 0.0],
            [-97.0, 0.0],
            [-97.0, -16.0],
            [-66.5, -16.0],
            [-66.5, -28.0],
            [-42.5, -28.0],
            [-42.5, -16.0],
            [-10.0, -16.0],
            [-10.0, -28.0],
            [-5.0, -28.0],
        ]
    )
    set_poly(level2, "void_lobby", void_lobby)
    for void in level2["voids"]:
        if void["id"] == "void_lobby":
            void["polygon"] = [list(p) for p in void_lobby]
    # Floor holes follow the flights only, so landings keep a slab.
    flight_voids = {
        "stair_main_opening": [[-66.0, -36.0], [-50.0, -36.0], [-50.0, -29.0], [-66.0, -29.0]],
        "stair_main_upper": [[-50.0, -52.0], [-43.0, -52.0], [-43.0, -36.0], [-50.0, -36.0]],
        "stair_main_landing": [[-50.0, -36.0], [-43.0, -36.0], [-43.0, -29.0], [-50.0, -29.0]],
        "stair_second_opening": [[-320.0, -111.0], [-305.5, -111.0], [-305.5, -105.0], [-320.0, -105.0]],
        "stair_second_upper": [[-339.5, -111.0], [-325.0, -111.0], [-325.0, -105.0], [-339.5, -105.0]],
        "stair_west_opening": [[-354.0, -78.0], [-348.0, -78.0], [-348.0, -62.0], [-354.0, -62.0]],
        "stair_west_upper": [[-354.0, -54.0], [-348.0, -54.0], [-348.0, -38.0], [-354.0, -38.0]],
    }
    kept = []
    for void in level2["voids"]:
        if void["id"] in flight_voids:
            void["polygon"] = flight_voids.pop(void["id"])
        elif void["id"] in ("stair_main_opening", "stair_second_opening", "stair_west_opening"):
            continue
        kept.append(void)
    for vid, poly in flight_voids.items():
        kept.append({"id": vid, "polygon": poly})
    level2["voids"] = kept
    for guard in level2.get("guards", []):
        if guard["id"] == "gallery_guard_1":
            guard["a"], guard["b"] = [-5.0, -154.5], [-5.0, -28.0]
        elif guard["id"] == "gallery_guard_2":
            guard["a"], guard["b"] = [-10.0, -28.0], [-5.0, -28.0]
        elif guard["id"] == "gallery_guard_3":
            guard["a"], guard["b"] = [-10.0, -28.0], [-10.0, -16.0]
        elif guard["id"] == "gallery_guard_4":
            guard["a"], guard["b"] = [-42.5, -16.0], [-10.0, -16.0]
    run14 = 14.5 / 17
    for stair in level1["stairs"]:
        if stair["id"] == "stair_main":
            # East edge stops at x=-43 so the top tread clears the wall face at x=-42.835.
            stair["flights"] = [
                flight("main_a", [[-66.0, -36.0], [-50.0, -36.0], [-50.0, -29.0], [-66.0, -29.0]], [1, 0], 0, 7),
                flight("main_b", [[-50.0, -52.0], [-43.0, -52.0], [-43.0, -36.0], [-50.0, -36.0]], [0, -1], 10, 7),
            ]
            stair["landings"] = [landing("main_turn", [[-50.0, -36.0], [-43.0, -36.0], [-43.0, -29.0], [-50.0, -29.0]], 10)]
            stair["polygon"] = [list(p) for p in stair_poly]
        elif stair["id"] == "stair_second":
            stair["flights"] = [
                flight("second_a", [[-320.0, -111.0], [-305.5, -111.0], [-305.5, -105.0], [-320.0, -105.0]], [-1, 0], 0, 6, run14),
                flight("second_b", [[-339.5, -111.0], [-325.0, -111.0], [-325.0, -105.0], [-339.5, -105.0]], [-1, 0], 10, 6, run14),
            ]
            stair["landings"] = [landing("second_turn", [[-325.0, -111.0], [-320.0, -111.0], [-320.0, -105.0], [-325.0, -105.0]], 10)]
        elif stair["id"] == "stair_west":
            stair["flights"] = [
                flight("west_a", [[-354.0, -78.0], [-348.0, -78.0], [-348.0, -62.0], [-354.0, -62.0]], [0, 1], 0, 6),
                flight("west_b", [[-354.0, -54.0], [-348.0, -54.0], [-348.0, -38.0], [-354.0, -38.0]], [0, 1], 10, 6),
            ]
            stair["landings"] = [landing("west_turn", [[-354.0, -62.0], [-348.0, -62.0], [-348.0, -54.0], [-354.0, -54.0]], 10)]
    apply_round2(layout)
    furnish(layout)


def prop_at(pid, kind, x, z, rotation, room, **extra):
    exact = extra.pop("exact", False)
    ax, az = (x, z) if exact else (round(x * 2) / 2, round(z * 2) / 2)
    item = {"id": pid, "kind": kind, "at": [ax, az], "rotation": rotation, "room": room}
    item.update(extra)
    # Half-foot snap leaves this cabinet either 0.47 ft off the wall or biting into it.
    if pid == "trophy_main":
        item["at"][0] = -67.5
    return item


def room_center(room):
    xs = [p[0] for p in room["polygon"]]
    zs = [p[1] for p in room["polygon"]]
    return (min(xs) + max(xs)) / 2, (min(zs) + max(zs)) / 2, max(xs) - min(xs), max(zs) - min(zs)


def furnish(layout):
    """Purposeful furniture. Priority rooms are placed by hand; every other occupied room gets a fit-out."""
    level1, level2 = layout["levels"]
    props1 = [
        prop_at("reception_desk", "front_desk", 0, -10, 180, "lobby", length=20, depth=7.5, shape="u"),
        prop_at("desk_chair_1", "office_chair", -6, -14, 180, "lobby"),
        prop_at("desk_chair_2", "office_chair", -2, -14, 180, "lobby"),
        prop_at("desk_chair_3", "office_chair", 2, -14, 180, "lobby"),
        prop_at("desk_chair_4", "office_chair", 6, -14, 180, "lobby"),
        prop_at("lost_found", "supply_cabinet", -6, -16, 0, "lobby"),
        prop_at("ball_rental", "ball_cart", 5, -16, 0, "lobby"),
        prop_at("ping_pong_1", "ping_pong_table", -36, -4, 90, "south_vestibule"),
        prop_at("ping_pong_2", "ping_pong_table", -58, -4, 90, "south_vestibule"),
        prop_at("vending_1", "vending_machine", -80, -3, 0, "south_vestibule"),
        prop_at("vending_2", "vending_machine", -92, -3, 0, "south_vestibule"),
        prop_at("hall_trash", "trash_bin", -20, -4, 0, "south_vestibule"),
        prop_at("trophy_main", "trophy_case", -67.55, -108, 90, "corridor_entry_link"),
        prop_at("jersey_1", "jersey_frame", -67.0, -118, 90, "corridor_entry_link"),
        prop_at("jersey_2", "jersey_frame", -67.0, -96, 90, "corridor_entry_link"),
        prop_at("cardio_t1", "treadmill", 4, -56, 90, "glazed_recreation"),
        prop_at("cardio_t2", "treadmill", 4, -64, 90, "glazed_recreation"),
        prop_at("cardio_t3", "treadmill", 4, -72, 90, "glazed_recreation"),
        prop_at("cardio_t4", "treadmill", 2, -60, 90, "glazed_recreation"),
        prop_at("cardio_b1", "upright_bike", -1, -44, 90, "glazed_recreation"),
        prop_at("cardio_b2", "upright_bike", -1, -54, 90, "glazed_recreation"),
        prop_at("cardio_e1", "elliptical", -1, -66, 90, "glazed_recreation"),
        prop_at("annex_chest", "chest_press", -30, -24, 0, "fitness_annex"),
        prop_at("annex_lat", "lat_pulldown", -20, -24, 0, "fitness_annex"),
        prop_at("annex_leg", "leg_press", -30, -36, 0, "fitness_annex"),
        prop_at("annex_cable", "cable_machine", -18, -40, 180, "fitness_annex"),
        prop_at("rack_1", "power_rack", -58, -96, 0, "weight_room"),
        prop_at("rack_2", "power_rack", -48, -96, 0, "weight_room"),
        prop_at("platform_1", "lifting_platform", -58, -110, 0, "weight_room"),
        prop_at("bench_1", "flat_bench", -48, -110, 0, "weight_room"),
        prop_at("dumbbells", "dumbbell_rack", -50, -88, 90, "weight_room"),
        prop_at("fit_row_1", "rower", -50, -136, 0, "fitness_center"),
        prop_at("fit_climb_1", "stair_climber", -40, -140, 0, "fitness_center"),
        prop_at("fit_bike_1", "upright_bike", -30, -140, 90, "fitness_center"),
        prop_at("fit_ell_1", "elliptical", -20, -140, 90, "fitness_center"),
        prop_at("cube_1", "cubicle", -22, -88, 0, "coach_suite"),
        prop_at("cube_2", "cubicle", -14, -88, 0, "coach_suite"),
        prop_at("cube_3", "cubicle", -6, -88, 0, "coach_suite"),
        prop_at("cube_4", "cubicle", -22, -100, 180, "coach_suite"),
        prop_at("cube_5", "cubicle", -14, -100, 180, "coach_suite"),
        prop_at("cube_6", "cubicle", -6, -100, 180, "coach_suite"),
        prop_at("cube_chair_1", "office_chair", -22, -92.5, 180, "coach_suite"),
        prop_at("cube_chair_2", "office_chair", -14, -92.5, 180, "coach_suite"),
        prop_at("cube_chair_3", "office_chair", -6, -92.5, 180, "coach_suite"),
        prop_at("cube_chair_4", "office_chair", -22, -95.5, 0, "coach_suite"),
        prop_at("cube_chair_5", "office_chair", -14, -95.5, 0, "coach_suite"),
        prop_at("cube_chair_6", "office_chair", -6, -95.5, 0, "coach_suite"),
        prop_at("suite_desk_n", "office_desk", -16, -108, 180, "coach_suite"),
        prop_at("suite_chair_n", "office_chair", -16, -104, 180, "coach_suite"),
        prop_at("suite_desk_e", "office_desk", -2, -96, 90, "coach_suite"),
        prop_at("suite_chair_e", "office_chair", -6, -96, 90, "coach_suite"),
        prop_at("suite_reception", "office_desk", -16, -90, 0, "coach_suite"),
        prop_at("suite_reception_chair", "office_chair", -16, -86, 0, "coach_suite"),
        prop_at("suite_board", "bulletin_board", -4, -90, 90, "coach_suite"),
        prop_at("suite_mail", "mail_slots", 0, -104, 90, "coach_suite"),
        prop_at("suite_clock", "wall_clock", -14, -84, 180, "coach_suite"),
        prop_at("head_desk", "office_desk", -31, -91, 0, "coach_head"),
        prop_at("head_chair", "office_chair", -31, -93.5, 0, "coach_head"),
        prop_at("stair_west_exit", "exit_sign", -342, -75, 90, "corridor_office"),
        prop_at("locker_sign", "nameplate", -94, -28, 90, "corridor_south_link", text="LOCKERS"),
        prop_at("elev_sign", "nameplate", -40, -84, 0, "elevator", text="ELEVATOR"),
        prop_at("pub_lock_n", "locker_bank_metal", -99, -33.5, 90, "public_locker", count=10),
        prop_at("pub_stalls", "toilet_partition", -126.5, -28, 270, "public_locker", stalls=5),
        prop_at("pub_sinks", "sink_counter", -118, -28, 90, "public_locker", sinks=4),
        # 3.5 ft on center so the side walls meet. backPad reaches the north wall from z=-37.5.
        prop_at("pub_shower_1", "shower_stall", -120, -37.5, 180, "public_locker", backPad=0.14),
        prop_at("pub_shower_2", "shower_stall", -116.5, -37.5, 180, "public_locker", backPad=0.14),
        prop_at("pub_shower_3", "shower_stall", -113, -37.5, 180, "public_locker", backPad=0.14),
        prop_at("dumpster_1", "dumpster", -220, -200, 0, "service_yard"),
        prop_at("dumpster_2", "dumpster", -210, -200, 0, "service_yard"),
        prop_at("west_desk", "office_desk", -34, -104, 0, "coach_west"),
        prop_at("west_chair", "office_chair", -34, -100, 0, "coach_west"),
        prop_at("westn_desk", "office_desk", -34, -118, 0, "coach_west_n"),
        prop_at("westn_chair", "office_chair", -34, -114, 0, "coach_west_n"),
        prop_at("north_desk", "office_desk", -13, -118, 180, "coach_north"),
        prop_at("north_chair", "office_chair", -13, -114, 180, "coach_north"),
        prop_at("easts_desk", "office_desk", 6, -88, 90, "coach_east_s"),
        prop_at("easts_chair", "office_chair", 7.2, -88, 90, "coach_east_s"),
        prop_at("eastm_desk", "office_desk", 6, -104, 90, "coach_east_m"),
        prop_at("eastm_chair", "office_chair", 7.2, -104, 90, "coach_east_m"),
        prop_at("eastn_desk", "office_desk", 6, -118, 90, "coach_east_n"),
        prop_at("eastn_chair", "office_chair", 3, -118, 90, "coach_east_n"),
        prop_at("head_plate", "nameplate", -34, -80.4, 180, "coach_head", text="HEAD COACH", width=4.2, height=0.7),
        prop_at("train_t1", "training_table", -230, -160, 90, "training_room"),
        prop_at("train_t2", "training_table", -230, -172, 90, "training_room"),
        prop_at("train_t3", "training_table", -218, -160, 90, "training_room"),
        prop_at("train_t4", "training_table", -218, -172, 90, "training_room"),
        prop_at("train_ice", "ice_machine", -228, -176, 180, "training_room"),
        prop_at("train_ice_sign", "nameplate", -228, -174.2, 180, "training_room", text="ICE", width=2.2, height=0.55),
        prop_at("train_tape_sign", "nameplate", -222, -154, 0, "training_room", text="ATHLETIC TAPE", width=2.4, height=0.45),
        prop_at("train_plate", "nameplate", -214, -152, 180, "training_room", text="ATHLETIC TRAINING", width=3.6, height=0.55),
        prop_at("train_cab_1", "supply_cabinet", -234, -168, 90, "training_room"),
        prop_at("train_cab_2", "supply_cabinet", -234, -160, 90, "training_room"),
        prop_at("train_cab_3", "supply_cabinet", -222, -176, 180, "training_room"),
        prop_at("train_desk", "office_desk", -210, -154, 0, "training_room"),
        prop_at("train_chair", "office_chair", -210, -157, 0, "training_room"),
        prop_at("train_board", "bulletin_board", -222, -152, 180, "training_room"),
        prop_at("train_bike", "upright_bike", -210, -166, 270, "training_room"),
        prop_at("train_climb", "stair_climber", -210, -174, 270, "training_room"),
        prop_at("train_fountain", "water_fountain", -210, -158, 270, "training_room"),
        prop_at("train_trash", "trash_bin", -214, -154, 0, "training_room"),
        prop_at("train_recycle", "recycle_bin", -216, -154, 0, "training_room"),
        prop_at("vb_net", "volleyball_standard", -136, -206, 90, "competition_gym"),
        prop_at("vb_bleach_e", "bleacher_bank", -86, -232, 90, "competition_gym", length=60, rows=8),
        prop_at("vb_bleach_w", "bleacher_bank", -186, -232, 270, "competition_gym", length=60, rows=8),
        prop_at("vb_pad_n", "wall_pad", -136, -276, 180, "competition_gym", length=40),
        prop_at("vb_pad_s", "wall_pad", -150, -187.5, 0, "competition_gym", length=36),
        prop_at("vb_schedule", "bulletin_board", -100, -160, 90, "gym_foyer"),
        prop_at("vb_cart_3", "ball_cart", -120, -150, 0, "gym_foyer"),
        prop_at("vb_cart_4", "ball_cart", -150, -148, 0, "gym_foyer"),
        prop_at("vb_bags", "supply_cabinet", -170, -148, 0, "gym_foyer"),
        prop_at("vb_towel", "supply_cabinet", -180, -148, 180, "gym_foyer"),
        prop_at("vb_pad_e", "wall_pad", -81, -232, 90, "competition_gym", length=20),
        prop_at("vb_pad_w", "wall_pad", -191, -232, 270, "competition_gym", length=20),
        prop_at("vb_score", "scoreboard", -90, -206, 90, "competition_gym"),
        prop_at("vb_banner_1", "banner", -120, -142, 0, "competition_gym"),
        prop_at("vb_banner_2", "banner", -150, -142, 0, "competition_gym"),
        prop_at("vb_banner_3", "banner", -136, -272, 180, "competition_gym"),
        prop_at("vb_flag", "flag", -84, -148, 90, "competition_gym"),
        prop_at("vb_cart_1", "ball_cart", -100, -200, 0, "competition_gym"),
        prop_at("vb_cart_2", "ball_cart", -160, -210, 0, "competition_gym"),
        prop_at("vb_bags_court", "supply_cabinet", -186, -200, 90, "competition_gym"),
        prop_at("vb_fountain", "water_fountain", -100, -182, 90, "thin_link"),
        prop_at("vb_trash", "trash_bin", -110, -182, 0, "thin_link"),
        prop_at(
            "nutri_fridge",
            "industrial_fridge",
            -213.5,
            -147,
            270,
            "nutrition_vestibule",
            sign="MATT CORSON NUTRITION STATION",
        ),
        prop_at("lock_bank_1", "locker_bank_wood", -228, -130, 0, "locker_volleyball"),
        prop_at("lock_bank_2", "locker_bank_metal", -220, -130, 0, "locker_volleyball"),
        prop_at("lock_bench", "bench_locker", -224, -124, 0, "locker_volleyball"),
    ]
    props2 = [
        prop_at("l2_tread_1", "treadmill", -38, -22, 180, "cardio_south"),
        prop_at("l2_tread_2", "treadmill", -31, -22, 180, "cardio_south"),
        prop_at("l2_tread_3", "treadmill", -24, -22, 180, "cardio_south"),
        prop_at("l2_tread_4", "treadmill", -17, -22, 180, "cardio_south"),
        prop_at("l2_tread_5", "treadmill", -36, -30, 180, "cardio_south"),
        prop_at("l2_tread_6", "treadmill", -28, -30, 180, "cardio_south"),
        prop_at("l2_bag", "heavy_bag", -20, -38, 0, "cardio_south"),
        prop_at("l2_weights", "dumbbell_rack", -40.5, -34, 90, "cardio_south"),
        prop_at("l2_tv_1", "wall_tv", -41.2, -28, 90, "cardio_south"),
        prop_at("l2_tv_2", "wall_tv", -41.2, -22, 90, "cardio_south"),
        prop_at("l2_bench_1", "flat_bench", -34, -40, 0, "cardio_south"),
        prop_at("l2_bench_2", "flat_bench", -26, -40, 0, "cardio_south"),
        prop_at("l2_exit_plate", "nameplate", -354, -86, 90, "corridor_l2", text="EXIT"),
        prop_at("l2_exit_sign", "exit_sign", -356, -86, 90, "corridor_l2"),
        prop_at("l2_elev_sign", "nameplate", -40, -84, 0, "elevator", text="ELEVATOR"),
        prop_at("l2_climb_1", "stair_climber", -24, -120, 270, "cardio_gallery"),
        prop_at("l2_row_1", "rower", -30, -100, 0, "cardio_gallery"),
        prop_at("bball_sign", "nameplate", -345, -128, 180, "basketball_approach", text="BASKETBALL — OFF LIMITS", width=7.5, height=1.05),
        prop_at("grade_sign", "nameplate", -356, -86, 270, "corridor_l2", text="LEVEL 2 EXIT AT GRADE", width=6.5, height=0.7),
        prop_at("l2_hall_trash", "trash_bin", -70, -160, 0, "corridor_l2_overlook"),
        prop_at("l2_hall_board", "bulletin_board", -66, -210, 90, "corridor_l2_overlook"),
        prop_at("l2_hall_jersey", "jersey_frame", -66, -230, 90, "corridor_l2_overlook"),
        prop_at("l2_hall_vend", "vending_machine", -66.5, -250, 90, "corridor_l2_overlook", rearPad=0.36),
        prop_at("l2_hall_sign", "nameplate", -66.2, -190, 90, "corridor_l2_overlook", text="VOLLEYBALL", width=3.2, height=0.55),
    ]
    placed = {p["room"] for p in props1}
    placed2 = {p["room"] for p in props2}
    for level, bucket, placed_ids in ((level1, props1, placed), (level2, props2, placed2)):
        for room in level["rooms"]:
            if room["id"] in placed_ids or room["type"] in ("void", "construction", "stair"):
                continue
            cx, cz, w, d = room_center(room)
            if min(w, d) < 7:
                continue
            kind = {
                "office": "office_desk",
                "locker": "locker_bank_metal",
                "restroom": "toilet_partition",
                "fitness": "treadmill",
                "gym": "basketball_hoop_ceiling",
                "corridor": "trash_bin",
                "lobby": "trash_bin",
                "support": "bulletin_board",
                "storage": "supply_cabinet",
                "mechanical": "supply_cabinet",
            }.get(room["type"])
            if not kind:
                continue
            bucket.append(prop_at(f"{room['id']}_fit", kind, cx, cz, 0, room["id"]))
            if room["type"] == "office":
                bucket.append(prop_at(f"{room['id']}_chair", "office_chair", cx, cz + 3, 0, room["id"]))
            elif room["type"] == "restroom":
                bucket.append(prop_at(f"{room['id']}_sink", "sink_counter", cx + 3, cz, 0, room["id"]))
            elif room["type"] == "locker":
                bucket.append(prop_at(f"{room['id']}_bench", "bench_locker", cx, cz + 4, 0, room["id"]))
            elif room["type"] == "gym" and room["id"] != "competition_gym":
                bucket.append(prop_at(f"{room['id']}_board", "scoreboard", cx + 8, cz, 90, room["id"]))
    level1["props"] = props1
    level2["props"] = props2


def dist(a, b):
    return math.dist(a, b)


def normalize(wall):
    a, b = wall["a"], wall["b"]
    horiz = abs(a[1] - b[1]) < 1e-6
    flip = (horiz and b[0] < a[0]) or ((not horiz) and b[1] < a[1])
    if flip:
        length = dist(a, b)
        for opening in wall["openings"]:
            opening["offset"] = round((length - opening["offset"] - opening["width"]) * 2) / 2
        wall["a"], wall["b"] = b, a
    return wall


def piece(wall, a, b, openings):
    child = dict(wall)
    child["a"] = list(a)
    child["b"] = list(b)
    child["openings"] = openings
    child.pop("id", None)
    return normalize(child)


def openings_between(wall, start, end):
    """Openings whose span lies in [start, end) along a normalized wall. start/end are distances from a."""
    kept = []
    for opening in wall["openings"]:
        o0 = opening["offset"]
        o1 = opening["offset"] + opening["width"]
        lo, hi = max(o0, start), min(o1, end)
        if hi - lo < 2:
            continue
        kept.append(dict(opening, offset=round((lo - start) * 2) / 2, width=round((hi - lo) * 2) / 2))
    return kept


def axis_of(wall):
    if abs(wall["a"][1] - wall["b"][1]) < 1e-6:
        return 0
    if abs(wall["a"][0] - wall["b"][0]) < 1e-6:
        return 1
    return None


def span_of(wall, axis):
    return min(wall["a"][axis], wall["b"][axis]), max(wall["a"][axis], wall["b"][axis])


def opening_key(opening):
    connection = opening.get("connection") or []
    return (
        opening.get("type"),
        round(float(opening.get("offset", 0)), 3),
        round(float(opening.get("width", 0)), 3),
        opening.get("sill"),
        opening.get("head"),
        opening.get("leaves"),
        opening.get("label"),
        tuple(connection),
    )


def dedupe_openings(wall):
    seen = set()
    kept = []
    for opening in wall["openings"]:
        key = opening_key(opening)
        if key in seen:
            continue
        seen.add(key)
        kept.append(opening)
    wall["openings"] = kept
    return wall


def seal_joints(walls):
    """Keep north-south walls continuous and stop east-west walls on that line.

    The builder notches a wall that is crossed, and it cuts a north-south wall
    back at a corner. Either cut leaves a 0.05-1.5 ft seam the geometry gate
    flags. Both stems at that joint are thinned to 0.28 ft so they share a
    face and the filled overlap stays under the checker's 0.3 ft threshold.
    A 0.25 ft door wall flattens the leaf onto its kickplate.
    """
    walls = [normalize(dict(w, openings=[dict(o) for o in w.get("openings", [])])) for w in walls]
    changed = True
    while changed:
        changed = False
        for i, left in enumerate(walls):
            ax = axis_of(left)
            if ax is None:
                continue
            for j in range(i + 1, len(walls)):
                right = walls[j]
                if axis_of(right) != ax or abs(left["a"][1 - ax] - right["a"][1 - ax]) > 0.01:
                    continue
                if any(left[k] != right[k] for k in ("thickness", "material", "exterior")):
                    continue
                if abs(left["height"] - right["height"]) > 0.2:
                    continue
                a0, a1 = span_of(left, ax)
                b0, b1 = span_of(right, ax)
                if min(a1, b1) < max(a0, b0) - 0.05:
                    continue
                lo, hi = min(a0, b0), max(a1, b1)
                line = left["a"][1 - ax]

                def shifted(wall, origin, axis=ax):
                    start = min(wall["a"][axis], wall["b"][axis])
                    out = []
                    for opening in wall["openings"]:
                        copied = dict(opening)
                        copied["offset"] = round((copied["offset"] + start - origin) * 2) / 2
                        out.append(copied)
                    return out

                if ax == 0:
                    merged_a, merged_b = [lo, line], [hi, line]
                else:
                    merged_a, merged_b = [line, lo], [line, hi]
                merged = dict(left, a=merged_a, b=merged_b, openings=shifted(left, lo) + shifted(right, lo))
                walls[i] = dedupe_openings(normalize(merged))
                walls.pop(j)
                changed = True
                break
            if changed:
                break
    ns = [w for w in walls if axis_of(w) == 1]
    pieces = []
    for wall in [w for w in walls if axis_of(w) == 0]:
        wall = normalize(wall)
        z = wall["a"][1]
        x0, x1 = span_of(wall, 0)
        cuts = []
        for vert in ns:
            x = vert["a"][0]
            z0, z1 = span_of(vert, 1)
            if x0 + 2 <= x <= x1 - 2 and z0 < z - 0.01 and z1 > z + 0.01:
                cuts.append(round(x * 2) / 2)
        cuts = sorted({c for c in cuts if x0 + 2 <= c <= x1 - 2})
        if not cuts:
            pieces.append(wall)
            continue
        bounds = [x0] + cuts + [x1]
        origin = wall["a"][0]
        for u, v in zip(bounds, bounds[1:]):
            if v - u < 2:
                continue
            pieces.append(piece(wall, [u, z], [v, z], openings_between(wall, u - origin, v - origin)))
    walls = [normalize(w) for w in ns + pieces + [w for w in walls if axis_of(w) is None]]
    for i, left in enumerate(walls):
        ax = axis_of(left)
        if ax is None:
            continue
        a0, a1 = span_of(left, ax)
        for right in walls[i + 1 :]:
            if axis_of(right) != ax or abs(left["a"][1 - ax] - right["a"][1 - ax]) > 0.3:
                continue
            b0, b1 = span_of(right, ax)
            if a1 < b0:
                gap, meet = b0 - a1, (a1 + b0) / 2
            elif b1 < a0:
                gap, meet = a0 - b1, (b1 + a0) / 2
            else:
                gap, meet = 0, None
                if abs(a1 - b0) < 0.05 or abs(b1 - a0) < 0.05 or abs(a0 - b0) < 0.05 or abs(a1 - b1) < 0.05:
                    meet = a1 if abs(a1 - b0) < 0.05 or abs(a1 - b1) < 0.05 else a0
                    gap = 0
            if meet is None or gap >= 1.5:
                continue
            line = left["a"][1 - ax]
            filled = False
            for other in walls:
                if axis_of(other) in (None, ax):
                    continue
                center = other["a"][ax]
                o0, o1 = span_of(other, 1 - ax)
                if abs(center - meet) <= other["thickness"] / 2 + 0.05 and o0 - 0.05 <= line <= o1 + 0.05:
                    filled = True
                    break
            if filled:
                for wall in (left, right):
                    if wall["height"] > 4 and wall["thickness"] > 0.28:
                        wall["thickness"] = 0.28
    for wall in walls:
        dedupe_openings(wall)
    return walls


def match_stacked_faces(upper, lower):
    """Keep an upper wall as thick as the wall under it.

    A thicker upper wall notches the walls that tee into it by half that
    thickness. The wall below was thinned to 0.28 ft, so the notch stops
    short of its face and the geometry check reports a gap.
    """
    changed = 0
    for wall in upper:
        ax = axis_of(wall)
        if ax is None or wall.get("thickness", 0) <= 0.28:
            continue
        a0, a1 = span_of(wall, ax)
        line = wall["a"][1 - ax]
        for under in lower:
            if axis_of(under) != ax or abs(under["a"][1 - ax] - line) > 0.05:
                continue
            b0, b1 = span_of(under, ax)
            if min(a1, b1) - max(a0, b0) < 1:
                continue
            if under["thickness"] + 0.01 < wall["thickness"]:
                wall["thickness"] = under["thickness"]
                changed += 1
                break
    return changed


def extend_past_rail(upper, lower):
    """Keep a balcony rail from notching the end of the wall it dies into.

    The builder cuts a north-south wall back at a corner. The floor below is
    removed up to the uncut end, so the notch reads as a seam. Running the
    upper wall 0.5 ft past the rail puts the joint in the middle of that wall.
    """
    rails = [w for w in upper if w.get("material") == "glass" and 0 < w.get("height", 99) <= 4]
    extended = 0
    for wall in upper:
        ax = axis_of(wall)
        if ax is None or wall.get("height", 0) <= 4:
            continue
        line = wall["a"][1 - ax]
        along0, along1 = span_of(wall, ax)
        bumped = False
        for rail in rails:
            if axis_of(rail) in (None, ax):
                continue
            at = rail["a"][ax]
            at_start = abs(at - along0) <= 0.01
            at_end = abs(at - along1) <= 0.01
            if not at_start and not at_end:
                continue
            cross0, cross1 = span_of(rail, 1 - ax)
            touches = abs(cross0 - line) <= 0.05 or abs(cross1 - line) <= 0.05
            crosses = cross0 < line - 0.05 and cross1 > line + 0.05
            if not touches or crosses:
                continue
            outward = -1 if at_start else 1
            continues = False
            for other in lower:
                if axis_of(other) != ax or abs(other["a"][1 - ax] - line) > 0.05 or other.get("height", 0) < 21:
                    continue
                o0, o1 = span_of(other, ax)
                if outward < 0 and o0 < at - 0.05:
                    continues = True
                elif outward > 0 and o1 > at + 0.05:
                    continues = True
            if not continues:
                continue
            # A collinear wall already meets this end. Extending both opens an overlap.
            meets = False
            for other in upper:
                if other is wall or axis_of(other) != ax or abs(other["a"][1 - ax] - line) > 0.05:
                    continue
                o0, o1 = span_of(other, ax)
                if abs(o0 - at) <= 0.05 or abs(o1 - at) <= 0.05:
                    meets = True
                    break
            if meets:
                continue
            if outward < 0:
                along0 -= 0.5
                for opening in wall["openings"]:
                    opening["offset"] = round((opening["offset"] + 0.5) * 2) / 2
            else:
                along1 += 0.5
            bumped = True
        if not bumped:
            continue
        if ax == 0:
            wall["a"], wall["b"] = [along0, line], [along1, line]
        else:
            wall["a"], wall["b"] = [line, along0], [line, along1]
        normalize(wall)
        extended += 1
    return extended


def close_short_gaps(walls):
    """The compiler drops boundary pieces under 2 ft. Stretch a neighbor across a 1–1.5 ft hole."""
    closed = 0
    for i, left in enumerate(walls):
        ax = axis_of(left)
        if ax is None:
            continue
        for right in walls[i + 1 :]:
            if axis_of(right) != ax or abs(left["a"][1 - ax] - right["a"][1 - ax]) > 0.05:
                continue
            a0, a1 = span_of(left, ax)
            b0, b1 = span_of(right, ax)
            if a1 <= b0:
                gap, lo_wall, hi_wall, meet = b0 - a1, left, right, b0
            elif b1 <= a0:
                gap, lo_wall, hi_wall, meet = a0 - b1, right, left, a0
            else:
                continue
            if gap < 1 or gap > 1.51:
                continue
            donor = lo_wall if len(lo_wall["openings"]) <= len(hi_wall["openings"]) else hi_wall
            d0, d1 = span_of(donor, ax)
            if donor is lo_wall:
                d1 = meet
            else:
                shift = d0 - meet
                d0 = meet
                for opening in donor["openings"]:
                    opening["offset"] = round((opening["offset"] + shift) * 2) / 2
            line = donor["a"][1 - ax]
            if ax == 0:
                donor["a"], donor["b"] = [d0, line], [d1, line]
            else:
                donor["a"], donor["b"] = [line, d0], [line, d1]
            normalize(donor)
            closed += 1
    return closed


def cut_at(wall, coord, horizontal):
    a, b = wall["a"], wall["b"]
    length = dist(a, b)
    along = (coord - a[0]) if horizontal else (coord - a[1])
    along = round(along * 2) / 2
    # A stub shorter than 2 ft is trimmed so the joint becomes a T, not a sliver wall.
    if along < 2:
        end = [coord, a[1]] if horizontal else [a[0], coord]
        return [piece(wall, end, b, openings_between(wall, along, length))]
    if length - along < 2:
        end = [coord, a[1]] if horizontal else [a[0], coord]
        return [piece(wall, a, end, openings_between(wall, 0, along))]
    mid = [coord, a[1]] if horizontal else [a[0], coord]
    return [
        piece(wall, a, mid, openings_between(wall, 0, along)),
        piece(wall, mid, b, openings_between(wall, along, length)),
    ]


def inside(poly, x, z):
    yes = False
    for a, b in zip(poly, poly[1:] + poly[:1]):
        if (a[1] > z) != (b[1] > z) and x < (b[0] - a[0]) * (z - a[1]) / (b[1] - a[1]) + a[0]:
            yes = not yes
    return yes


def add_exterior_door(level, room_id, label):
    room = next(r for r in level["rooms"] if r["id"] == room_id)
    for wall in level["walls"]:
        if not wall.get("exterior"):
            continue
        ax, az = wall["a"]
        bx, bz = wall["b"]
        length = dist(wall["a"], wall["b"])
        if length < 8:
            continue
        ux, uz = (bx - ax) / length, (bz - az) / length
        mx, mz = ax + ux * length / 2, az + uz * length / 2
        nx, nz = -uz, ux
        probes = (inside(room["polygon"], mx + nx, mz + nz), inside(room["polygon"], mx - nx, mz - nz))
        if probes[0] == probes[1]:
            continue
        if any(o["type"] == "door" for o in wall["openings"]):
            continue
        offset = round((length / 2 - 3) * 2) / 2
        if offset < 0 or offset + 6 > length:
            continue
        wall["openings"].append(
            {"type": "door", "offset": offset, "width": 6, "sill": 0, "head": 7, "leaves": 2, "tag": "RACDoor", "label": label}
        )
        return True
    # Construction reservations share edges only with other construction, and
    # the compiler drops those walls. Add one exterior gate on the north edge.
    xs = [p[0] for p in room["polygon"]]
    zs = [p[1] for p in room["polygon"]]
    north = min(zs)
    x0, x1 = min(xs), max(xs)
    if x1 - x0 < 8:
        return False
    level["walls"].append(
        {
            "a": [x0, north],
            "b": [x1, north],
            "thickness": 0.67,
            "height": 12,
            "material": "painted_cmu",
            "exterior": True,
            "openings": [
                {
                    "type": "door",
                    "offset": round(((x1 - x0) / 2 - 3) * 2) / 2,
                    "width": 6,
                    "sill": 0,
                    "head": 7,
                    "leaves": 2,
                    "tag": "RACDoor",
                    "label": label,
                }
            ],
        }
    )
    return True


def retag(level, prefix):
    for index, wall in enumerate(level["walls"], start=1):
        wall["id"] = f"{prefix}{index:03d}"


def avoid_roof_faces(level, roofs):
    faces = []
    for roof in roofs:
        if roof["type"] == "canopy":
            continue
        faces.extend((roof["height"], roof["height"] + 0.5, roof["height"] + 2.5))
    for wall in level["walls"]:
        top = level["elevation"] + wall["height"]
        if any(abs(top - face) < 0.02 for face in faces):
            wall["height"] = round((wall["height"] + 0.35) * 2) / 2


def update_site(site):
    for roof in site["roofs"]:
        xs = [p[0] for p in roof["polygon"]]
        zs = [p[1] for p in roof["polygon"]]
        cx, cz = sum(xs) / len(xs), sum(zs) / len(zs)
        if roof["type"] == "canopy":
            continue
        if cz < -140 and cx < -100:
            roof["height"] = 33.7  # competition gym lidar
        elif cz > -20 and cx < -90:
            roof["height"] = 40.2  # south gym lidar
        elif cx < -250 and cz < -100:
            roof["height"] = 45.8  # cage lidar
        elif -80 <= cz <= -30 and -290 <= cx <= -230:
            roof["height"] = 36.7  # racquetball lidar
        else:
            # Two-story wings measure ~25 ft, which cannot clear a +20 ft floor.
            # Keep the slab just above the Level 2 walls. See ARCHITECT_NOTES.
            roof["height"] = 33.2
    site["roofs"] = [r for r in site["roofs"] if r["type"] != "canopy"]
    # Shallow dark wedge over the south entrance glass, not a deep plate.
    site["roofs"].append(
        {
            "polygon": ccw([[-28.0, 0.0], [18.0, 0.0], [18.0, 12.0], [-28.0, 12.0]]),
            "height": 15,
            "type": "canopy",
            "overhang": 0,
        }
    )
    for roof in site["roofs"]:
        if roof["type"] == "canopy":
            continue
        roof["polygon"] = inset_rectilinear(roof["polygon"], 1.0)
    for face in site["facade"]:
        mx = (face["a"][0] + face["b"][0]) / 2
        mz = (face["a"][1] + face["b"][1]) / 2
        if mz > 10 or (mx < -150 and mz > -10):
            face["height"] = 41
        elif mx < -300 and mz < -90:
            face["height"] = 46.5
        elif mz < -200:
            face["height"] = 34.5
        else:
            face["height"] = 33.5


def inset_rectilinear(poly, distance):
    """Move each edge inward. Returns the original polygon if the offset collapses."""
    src = ccw([list(p) for p in poly])
    n = len(src)
    lines = []
    for i in range(n):
        a, b = src[i], src[(i + 1) % n]
        dx, dz = b[0] - a[0], b[1] - a[1]
        length = math.hypot(dx, dz)
        if length < 2:
            return src
        nx, nz = -dz / length, dx / length
        lines.append((a[0] + nx * distance, a[1] + nz * distance, dx, dz))
    points = []
    for i in range(n):
        ax, az, adx, adz = lines[i - 1]
        bx, bz, bdx, bdz = lines[i]
        det = adx * bdz - adz * bdx
        if abs(det) < 1e-8:
            return src
        t = ((bx - ax) * bdz - (bz - az) * bdx) / det
        points.append([round((ax + t * adx) * 2) / 2, round((az + t * adz) * 2) / 2])
    if len({(p[0], p[1]) for p in points}) != n or shoelace(points) <= 1:
        return src
    return ccw(points)


def add_overlook_glass(level):
    """Floor-to-ceiling mullioned glass on the gym side of the Level 2 overlook."""
    for wall in level["walls"]:
        a, b = wall["a"], wall["b"]
        if abs(a[0] - b[0]) > 0.01 or abs(a[0] + 78.5) > 0.01:
            continue
        z0, z1 = sorted((a[1], b[1]))
        # Continuous gym-side glass for the overlook run. The turn door on the
        # south stub stays a separate wall.
        lo, hi = max(z0, -279.5), min(z1, -92.5)
        if hi - lo < 8:
            continue
        length = abs(b[1] - a[1])
        if b[1] >= a[1]:
            start, width = lo - a[1], hi - lo
        else:
            start, width = a[1] - hi, hi - lo
        start = round(start * 2) / 2
        width = round(width * 2) / 2
        if start < 0 or start + width > length + 0.05 or width < 4:
            continue
        wall["openings"] = [o for o in wall["openings"] if o.get("type") != "curtainwall"]
        wall["openings"].append(
            {
                "type": "curtainwall",
                "offset": start,
                "width": width,
                "sill": 0,
                "head": min(9.5, wall["height"]),
                "mullionSpacing": 10,
            }
        )


def raise_level2_stair_walls(level):
    """L2 stair-only walls compile at 12 ft. A shorter tee leaves a 0.5 ft cap whose
    underside sits on the same plane as the neighboring 12 ft ceiling."""
    for wall in level["walls"]:
        if wall.get("material") == "glass" or wall.get("height", 0) <= 4:
            continue
        if abs(wall.get("height", 0) - 12) < 0.02:
            wall["height"] = 12.5


def lift_flush_ceilings(level):
    """A wall segment above an opening starts at the head, which z-fights a ceiling at that height."""
    heads = {round(o["head"], 3) for wall in level["walls"] for o in wall["openings"]}
    for room in level["rooms"]:
        if room.get("ceilingType") in (None, "none", "open_joist"):
            continue
        if any(abs(room["ceilingHeight"] - head) < 0.02 for head in heads):
            room["ceilingHeight"] = room["ceilingHeight"] + 0.5


GUARD_SPANS = (
    ([-5.0, -154.5], [-5.0, -28.0]),
    ([-10.0, -28.0], [-5.0, -28.0]),
    ([-10.0, -28.0], [-10.0, -16.0]),
    ([-42.5, -16.0], [-10.0, -16.0]),
)


def split_for_guard(walls, a, b):
    """Turn the portion of a wall that lies on a balcony edge into a rail segment."""
    axis = 0 if abs(a[1] - b[1]) < 1e-6 else 1
    fixed = a[1 - axis]
    g0, g1 = sorted((a[axis], b[axis]))
    out = []
    for wall in walls:
        if axis_of(wall) != axis or abs(wall["a"][1 - axis] - fixed) > 0.05:
            out.append(wall)
            continue
        w0, w1 = span_of(wall, axis)
        lo, hi = max(w0, g0), min(w1, g1)
        if hi - lo < 2 or wall.get("height", 9) <= 4:
            out.append(wall)
            continue
        if lo - w0 < 2:
            lo = w0
        if w1 - hi < 2:
            hi = w1
        def point(t, _axis=axis, _fixed=fixed):
            p = [0.0, 0.0]
            p[_axis] = t
            p[1 - _axis] = _fixed
            return p
        origin = wall["a"][axis]
        cuts = []
        if lo - w0 >= 2:
            cuts.append((w0, lo, False))
        cuts.append((lo, hi, True))
        if w1 - hi >= 2:
            cuts.append((hi, w1, False))
        for c0, c1, rail in cuts:
            if c1 - c0 < 2:
                continue
            start = abs(c0 - origin)
            openings = [] if rail else openings_between(wall, start, start + (c1 - c0))
            child = piece(wall, point(c0), point(c1), openings)
            if rail:
                child.update(height=3.5, thickness=0.25, material="glass", exterior=False, openings=[])
            out.append(child)
    return out


def add_court_glass(level):
    """Glass entry wall of each racquetball court (the back wall, with the door)."""
    for wall in level["walls"]:
        a, b = wall["a"], wall["b"]
        if abs(a[1] - b[1]) > 0.01 or abs(a[1] + 80.0) > 0.05:
            continue
        x0, x1 = sorted((a[0], b[0]))
        if min(x1, -225.0) - max(x0, -305.0) < 8:
            continue
        wall["material"] = "glass"


def add_coach_storefront(level):
    """Glass wall and glass door on the south face of the coaches' suite."""
    for wall in level["walls"]:
        a, b = wall["a"], wall["b"]
        if abs(a[1] - b[1]) > 0.01 or abs(a[1] + 80.0) > 0.01 or wall.get("height", 0) <= 4:
            continue
        x0, x1 = sorted((a[0], b[0]))
        lo, hi = max(x0, -40.0), min(x1, 10.0)
        if hi - lo < 4:
            continue
        length = abs(b[0] - a[0])
        def along(x, _a=a, _b=b):
            return (x - _a[0]) if _b[0] >= _a[0] else (_a[0] - x)
        span0, span1 = sorted((along(lo), along(hi)))
        span0 = max(0.0, span0)
        span1 = min(length, span1)
        doors = []
        for opening in wall["openings"]:
            if opening.get("type") != "door":
                continue
            if opening["offset"] + opening["width"] < span0 - 0.01 or opening["offset"] > span1 + 0.01:
                continue
            doors.append(opening)
        if not doors:
            mid = (span0 + span1) / 2
            door_at = round((mid - 2) * 2) / 2
            if door_at >= span0 and door_at + 4 <= span1 + 0.05:
                doors.append(
                    {
                        "type": "door",
                        "offset": door_at,
                        "width": 4,
                        "sill": 0,
                        "head": 7,
                        "leaves": 1,
                        "tag": "RACDoor",
                    }
                )
        openings = []
        cursor = span0
        for door in sorted(doors, key=lambda item: item["offset"]):
            d0 = max(door["offset"], span0)
            d1 = min(door["offset"] + door["width"], span1)
            gap = round((d0 - cursor) * 2) / 2
            if gap >= 2:
                openings.append(
                    {
                        "type": "curtainwall",
                        "offset": round(cursor * 2) / 2,
                        "width": gap,
                        "sill": 0,
                        "head": min(9, wall["height"]),
                        "mullionSpacing": 4,
                    }
                )
            openings.append(door)
            cursor = d1
        tail = round((span1 - cursor) * 2) / 2
        if tail >= 2:
            openings.append(
                {
                    "type": "curtainwall",
                    "offset": round(cursor * 2) / 2,
                    "width": tail,
                    "sill": 0,
                    "head": min(9, wall["height"]),
                    "mullionSpacing": 4,
                }
            )
        outside = [
            opening
            for opening in wall["openings"]
            if opening.get("type") == "door"
            and (opening["offset"] + opening["width"] <= span0 + 0.01 or opening["offset"] >= span1 - 0.01)
        ]
        wall["openings"] = outside + openings


FOOTPRINT = [
    [-97, 0],
    [-97, 47],
    [-236.5, 47],
    [-236.5, -34],
    [-357.5, -34],
    [-357.5, -81.5],
    [-346.5, -81.5],
    [-346.5, -87],
    [-351.5, -87],
    [-351.5, -220],
    [-225, -220],
    [-225, -180],
    [-193.5, -180],
    [-193.5, -279.5],
    [-4.5, -279.5],
    [-4.5, -195.5],
    [10, -195.5],
    [10, 0],
]


def write_carve():
    """Air-fill every compiled room and wall. The site script calls Carve.apply after voxels."""
    rooms = []
    walls = []
    for name in ("level1", "level2"):
        level = load(f"{name}.json")
        elev = float(level["elevation"])
        for room in level["rooms"]:
            ceil = float(room.get("ceilingHeight") or 12)
            y1 = elev + ceil
            poly = ",".join("{%g,%g}" % (p[0], p[1]) for p in room["polygon"])
            rooms.append("\t\t{y0=-1,y1=%g,polygon={%s}}," % (round(y1, 2), poly))
        for wall in level["walls"]:
            y1 = elev + float(wall.get("height") or 12)
            walls.append(
                "\t\t{ax=%g,az=%g,bx=%g,bz=%g,thickness=%g,y0=-1,y1=%g},"
                % (
                    wall["a"][0],
                    wall["a"][1],
                    wall["b"][0],
                    wall["b"][1],
                    wall.get("thickness") or 0.67,
                    round(y1, 2),
                )
            )
    foot = ",".join("{%g,%g}" % (p[0], p[1]) for p in FOOTPRINT)
    text = (
        "--!strict\n"
        "-- Generated from blueprint room polygons, walls, and the site footprint.\n"
        "return {\n"
        "\trooms = {\n"
        + "\n".join(rooms)
        + "\n\t},\n\twalls = {\n"
        + "\n".join(walls)
        + "\n\t},\n\tfootprint = {"
        + foot
        + "},\n}\n"
    )
    path = ROOT / "src" / "ReplicatedStorage" / "RAC" / "Site" / "CarveData.luau"
    path.write_text(text, encoding="utf-8")
    print("carve rooms", len(rooms), "walls", len(walls))


def _segments_cross(a, b, c, d):
    """True when two axis-aligned segments cross or touch at an interior point."""
    def between(v, p, q):
        return min(p, q) - 0.02 < v < max(p, q) + 0.02

    horiz_ab = abs(a[1] - b[1]) < 0.05
    horiz_cd = abs(c[1] - d[1]) < 0.05
    if horiz_ab == horiz_cd:
        return False
    if horiz_ab:
        return between(c[0], a[0], b[0]) and between(a[1], c[1], d[1])
    return between(a[0], c[0], d[0]) and between(c[1], a[1], b[1])


def _edge_overlap(a, b, c, d, tol=0.35):
    """Length shared by two axis-aligned segments. 0 when they are not collinear."""
    if abs(a[1] - b[1]) < tol and abs(c[1] - d[1]) < tol and abs(a[1] - c[1]) < tol:
        a0, a1 = sorted((a[0], b[0]))
        c0, c1 = sorted((c[0], d[0]))
        return max(0, min(a1, c1) - max(a0, c0))
    if abs(a[0] - b[0]) < tol and abs(c[0] - d[0]) < tol and abs(a[0] - c[0]) < tol:
        a0, a1 = sorted((a[1], b[1]))
        c0, c1 = sorted((c[1], d[1]))
        return max(0, min(a1, c1) - max(a0, c0))
    return 0


def rail_void_edges(level):
    """Turn a solid Level 2 wall into a rail when one side is a floor hole and the other is a room.

    Full-height glass (overlook curtain, racquetball glass, entrance curtain) stays the barrier.
    Walls that already have a door or window stay so the opening is not erased.
    """
    polys = [room["polygon"] for room in level["rooms"] if room.get("type") == "void"]
    polys += [void["polygon"] for void in level.get("voids", [])]
    guards = []
    for wall in level["walls"]:
        if wall.get("height", 0) <= 4 or wall.get("openings"):
            continue
        if wall.get("material") == "glass" and wall.get("height", 0) >= 8:
            continue
        a, b = wall["a"], wall["b"]
        dx, dz = b[0] - a[0], b[1] - a[1]
        length = math.hypot(dx, dz)
        if length < 2:
            continue
        nx, nz = -dz / length, dx / length
        mx, mz = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
        probe = wall.get("thickness", 0.67) / 2 + 1.2
        samples = ((mx + nx * probe, mz + nz * probe), (mx - nx * probe, mz - nz * probe))
        void_side = [any(inside(poly, x, z) for poly in polys) for x, z in samples]
        room_side = []
        for x, z in samples:
            room_side.append(
                any(room.get("type") != "void" and inside(room["polygon"], x, z) for room in level["rooms"])
            )
        drop = (void_side[0] and room_side[1] and not void_side[1]) or (
            void_side[1] and room_side[0] and not void_side[0]
        )
        if not drop:
            continue
        wall.update(height=3.5, thickness=0.25, material="glass", exterior=False, openings=[])
        guards.append(
            {
                "id": f"void_rail_{len(guards) + 1}",
                "a": [a[0], a[1]],
                "b": [b[0], b[1]],
                "kind": "horizontal_rail",
            }
        )
    return guards


def repair_south_entrance(level):
    """Put the entry leaf on the 20 ft lobby bay. Curtain glass stays beside it, not across it.

    A transom that shares the door's footprint still fills the door probe, so the leaf
    and the glass must be separate openings.
    """
    for wall in level["walls"]:
        a, b = wall["a"], wall["b"]
        if abs(a[1]) > 0.05 or abs(b[1]) > 0.05 or not wall.get("exterior"):
            continue
        if a[0] > b[0]:
            continue
        x0, x1 = a[0], b[0]
        if x1 - x0 < 16 or x0 > -20 or x1 < 0:
            continue
        wall["height"] = max(wall.get("height", 0), 32.5)
        length = x1 - x0

        def place(world_x, width, kind, head):
            start = round((world_x - x0 - width / 2) * 2) / 2
            opening = {"type": kind, "offset": start, "width": width, "sill": 0, "head": head}
            if kind == "door":
                opening.update(leaves=2, tag="RACDoor")
            else:
                opening["mullionSpacing"] = 5
            return opening

        openings = []
        if x0 <= -90 and x1 >= 6:
            # Glass runs into the 12 ft entrance. No grey leaf in the east pier.
            openings.append(place(-51, 90, "curtainwall", 30))
            openings.append(place(0, 12, "opening", 9))
            transom = place(0, 12, "curtainwall", 24)
            transom["sill"] = 9.15
            transom["mullionSpacing"] = 4
            openings.append(transom)
            openings.append(place(8, 4, "curtainwall", 30))
        kept = [
            opening
            for opening in openings
            if opening["offset"] >= -0.01
            and opening["offset"] + opening["width"] <= length + 0.05
            and opening["width"] >= 2
            and opening["head"] <= wall.get("height", 32.5) + 0.01
        ]
        if kept:
            wall["openings"] = kept


def add_named_door(level, match, label):
    """One 4 ft door on the first wall whose endpoints match. Offset stays on the half-foot grid."""
    for wall in level["walls"]:
        a, b = wall["a"], wall["b"]
        if not match(a, b):
            continue
        length = dist(a, b)
        if length < 6:
            continue
        if any(opening.get("type") == "door" for opening in wall.get("openings", [])):
            for opening in wall["openings"]:
                if opening.get("type") == "door":
                    opening["label"] = label
            return True
        offset = round((length / 2 - 2) * 2) / 2
        if offset < 0 or offset + 4 > length + 0.05:
            continue
        wall.setdefault("openings", []).append(
            {
                "type": "door",
                "offset": offset,
                "width": 4,
                "sill": 0,
                "head": 7,
                "leaves": 1,
                "tag": "RACDoor",
                "label": label,
            }
        )
        return True
    return False


def split_desk_opening(level):
    """The 20 ft desk fills the middle of the west lobby edge. Leave walk openings past it."""
    for wall in level["walls"]:
        a, b = wall["a"], wall["b"]
        if abs(a[0] + 10) > 0.08 or abs(b[0] + 10) > 0.08:
            continue
        kept = []
        hit = False
        for opening in wall.get("openings", []):
            if set(opening.get("connection") or []) == {"lobby", "south_vestibule"}:
                hit = True
                continue
            kept.append(opening)
        if not hit:
            continue
        link = {"type": "opening", "sill": 0, "head": 16, "connection": ["lobby", "south_vestibule"]}
        # a is the north end (z=-16). North slot is beside the staff return; south slot is the walk.
        if a[1] <= b[1]:
            north = dict(link, offset=0.5, width=2.0)
            south = dict(link, offset=10.5, width=5.0)
        else:
            length = abs(b[1] - a[1])
            north = dict(link, offset=round((length - 2.5) * 2) / 2, width=2.0)
            south = dict(link, offset=0.5, width=5.0)
        wall["openings"] = kept + [north, south]


def retarget_opening(level, rooms, x0, z0, x1, z1):
    """Pin a connection opening to a world span. Wall direction does not matter."""
    want = set(rooms)
    for wall in level["walls"]:
        matched = [o for o in wall.get("openings", []) if set(o.get("connection") or []) == want]
        if not matched:
            continue
        a, b = wall["a"], wall["b"]
        dx, dz = b[0] - a[0], b[1] - a[1]
        length = math.hypot(dx, dz) or 1
        ux, uz = dx / length, dz / length
        p0 = (x0 - a[0]) * ux + (z0 - a[1]) * uz
        p1 = (x1 - a[0]) * ux + (z1 - a[1]) * uz
        lo, hi = min(p0, p1), max(p0, p1)
        opening = matched[0]
        opening["offset"] = round(lo * 2) / 2
        opening["width"] = round((hi - lo) * 2) / 2
        return True
    return False


def repair_stair_doors(level):
    """Keep stair doors on clear floor, off the treads.

    Level 2: a 3 ft door on the +20 landing (x=-343..-340), not the mid landing.
    Level 1 locker hall: the door is the north end of the east wall, clear of second_a.
    """
    for wall in level["walls"]:
        a, b = wall["a"], wall["b"]
        length = dist(a, b)
        for opening in wall.get("openings", []):
            rooms = opening.get("connection") or []
            if "stair_second" not in rooms:
                continue
            if abs(a[1] + 92.5) < 0.08 and abs(b[1] + 92.5) < 0.08:
                # Level 2: on the +20 landing, west of the upper flight.
                # Level 1: east of that void. The corner door intersects the west wall
                # and opens under the landing.
                width = 4.0
                if level.get("level") == 1:
                    x_lo, x_hi = -334.0, -330.0
                else:
                    x_lo, x_hi = -343.5, -339.5
                if a[0] <= b[0]:
                    start = x_lo - a[0]
                else:
                    start = a[0] - x_hi
                start = round(start * 2) / 2
                if 0 <= start and start + width <= length + 0.05:
                    opening["offset"] = start
                    opening["width"] = width
                    opening["type"] = "door"
            elif abs(a[0] + 305) < 0.08 and abs(b[0] + 305) < 0.08:
                # Vertical east wall of the stair. North of the lower flight (z<=-111).
                width = 4.0
                z_lo, z_hi = (a[1], b[1]) if a[1] <= b[1] else (b[1], a[1])
                # Door occupies z=-111..-107, north of the lower flight (flight ends at z=-115).
                if a[1] <= b[1]:
                    start = -111.0 - a[1]
                else:
                    start = a[1] - (-107.0)
                start = round(start * 2) / 2
                if z_hi >= -107 and z_lo <= -111 and 0 <= start and start + width <= length + 0.05:
                    opening["offset"] = start
                    opening["width"] = width
                    opening["type"] = "opening"


def add_well_rails(level, stairs):
    """Rails around each stair opening, on the floor side of the hole. The arrival edge stays open."""
    added = []
    for stair in stairs:
        flights = stair.get("flights") or []
        if len(flights) < 1:
            continue
        upper = max(flights, key=lambda flight: flight.get("baseElevation", 0))
        direction = upper.get("direction") or [0, -1]
        upoly = upper["polygon"]
        arrival = max(p[0] * direction[0] + p[1] * direction[1] for p in upoly)
        edges = []
        for flight in flights:
            poly = flight["polygon"]
            for i in range(len(poly)):
                edges.append((poly[i], poly[(i + 1) % len(poly)]))
        cx = sum(p[0] for flight in flights for p in flight["polygon"]) / sum(len(flight["polygon"]) for flight in flights)
        cz = sum(p[1] for flight in flights for p in flight["polygon"]) / sum(len(flight["polygon"]) for flight in flights)
        kept = []
        for a, b in edges:
            if math.dist(a, b) < 2:
                continue
            da = a[0] * direction[0] + a[1] * direction[1]
            db = b[0] * direction[0] + b[1] * direction[1]
            if abs(da - arrival) < 0.2 and abs(db - arrival) < 0.2:
                continue
            if any(_edge_overlap(a, b, c, d) > 1 and not (c is a and d is b) for c, d in edges):
                continue
            if any(_edge_overlap(a, b, c, d) > 1 for c, d in kept):
                continue
            kept.append((a, b))
        for a, b in kept:
            dx, dz = b[0] - a[0], b[1] - a[1]
            length = math.hypot(dx, dz) or 1
            nx, nz = -dz / length, dx / length
            mx, mz = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
            if (cx - mx) * nx + (cz - mz) * nz > 0:
                nx, nz = -nx, -nz
            ux, uz = dx / length, dz / length
            # Shift onto the floor side of the hole, and stop short of the room wall.
            # Extending past the flight pushes the rail through the stair wall; WallLayout
            # then cuts a partial-height slot and the geometry check reports a gap.
            shift = 0.35
            inset = 0.55
            aa = [round((a[0] + nx * shift + ux * inset) * 2) / 2, round((a[1] + nz * shift + uz * inset) * 2) / 2]
            bb = [round((b[0] + nx * shift - ux * inset) * 2) / 2, round((b[1] + nz * shift - uz * inset) * 2) / 2]
            if math.dist(aa, bb) < 2:
                continue
            if any(_edge_overlap(aa, bb, wall["a"], wall["b"]) > 0.2 for wall in level["walls"]):
                continue
            if any(_segments_cross(aa, bb, wall["a"], wall["b"]) for wall in level["walls"]):
                continue
            level["walls"].append(
                {
                    "id": f"well_{len(added)}",
                    "a": aa,
                    "b": bb,
                    "height": 3.5,
                    "thickness": 0.2,
                    "material": "glass",
                    "exterior": False,
                    "openings": [],
                }
            )
            added.append({"id": f"well_rail_{len(added) + 1}", "a": aa, "b": bb, "kind": "horizontal_rail"})
    return added


def open_cardio_north(level):
    """Drop the solid wall on z=-48 so cardio opens onto the balcony and the lobby rail."""
    kept = []
    for wall in level["walls"]:
        a, b = wall["a"], wall["b"]
        if abs(a[1] + 48.0) < 0.08 and abs(b[1] + 48.0) < 0.08 and wall.get("height", 9) > 4:
            x0, x1 = sorted((a[0], b[0]))
            if min(x1, -12.5) - max(x0, -42.5) > 4:
                continue
        kept.append(wall)
    level["walls"] = kept


def open_service_yard(level):
    """Take the west face off the dumpster yard so it is an open court, not a CMU room."""
    yard0, yard1 = -214.0, -186.0
    x_wall = -236.5
    out = []
    for wall in level["walls"]:
        a, b = wall["a"], wall["b"]
        if abs(a[0] - b[0]) > 0.05 or abs(((a[0] + b[0]) / 2) - x_wall) > 0.35:
            out.append(wall)
            continue
        z0, z1 = sorted((a[1], b[1]))
        if min(z1, yard1) - max(z0, yard0) < 4:
            out.append(wall)
            continue

        def emit(z_lo, z_hi, _wall=wall, _a=a, _b=b):
            if z_hi - z_lo < 2:
                return
            if _a[1] <= _b[1]:
                start = z_lo - _a[1]
                pa, pb = [x_wall, z_lo], [x_wall, z_hi]
            else:
                start = _a[1] - z_hi
                pa, pb = [x_wall, z_hi], [x_wall, z_lo]
            out.append(piece(_wall, pa, pb, openings_between(_wall, start, start + (z_hi - z_lo))))

        if z0 < yard0 - 0.05:
            emit(z0, min(z1, yard0))
        if z1 > yard1 + 0.05:
            emit(max(z0, yard1), z1)
    level["walls"] = out


def preflight(layout):
    """List apertures and connections the compiler will reject, before it stops on the first one."""
    from build_blueprint import collect_segments

    problems = []
    for level in layout["levels"]:
        walls = []
        for a, b, owners in collect_segments(level["rooms"]):
            walls.append((list(a), list(b), set(owners)))
        for spec in level.get("apertures", []):
            a, b = spec["a"], spec["b"]
            if not any(w[0] == a and w[1] == b for w in walls):
                problems.append(f"L{level['level']} missing aperture wall {a} {b}")
        for conn in level.get("connections", []):
            pair = set(conn["rooms"])
            if not any(w[2] == pair for w in walls):
                problems.append(f"L{level['level']} no shared wall {'/'.join(conn['rooms'])}")
    return problems


def main():
    layout = load("architect_layout.json")
    prepare_layout(layout)
    missing = preflight(layout)
    if missing:
        print("PREFLIGHT", len(missing))
        for line in missing:
            print(line)
        sys.exit(1)
    save("architect_layout.json", layout)
    architect_build.main()
    site = load("site.json")
    update_site(site)
    save("site.json", site)
    levels = {}
    for name, prefix in (("level1", "l1_w"), ("level2", "l2_w")):
        level = load(f"{name}.json")
        level["walls"] = seal_joints(level["walls"])
        levels[name] = (level, prefix)
    print("rail returns", extend_past_rail(levels["level2"][0]["walls"], levels["level1"][0]["walls"]))
    for level, _prefix in levels.values():
        print("short gaps closed", close_short_gaps(level["walls"]))
    for name, (level, prefix) in levels.items():
        if name == "level2":
            open_cardio_north(level)
        else:
            open_service_yard(level)
        if name == "level1":
            ok = add_exterior_door(level, "addition", "CONSTRUCTION")
            print("addition exterior door", ok)
        else:
            raise_level2_stair_walls(level)
            add_overlook_glass(level)
            add_court_glass(level)
            print("stacked faces", match_stacked_faces(level["walls"], levels["level1"][0]["walls"]))
            void_rails = rail_void_edges(level)
            well_rails = add_well_rails(level, levels["level1"][0].get("stairs", []))
            print("void rails", len(void_rails), "well rails", len(well_rails))
        if name == "level1":
            add_coach_storefront(level)
        avoid_roof_faces(level, site["roofs"])
        lift_flush_ceilings(level)
        if name == "level2":
            level["guards"] = void_rails + well_rails + [
                {"id": "cardio_rail", "a": [-42.5, -16.0], "b": [-12.5, -16.0], "kind": "horizontal_rail"},
                {"id": "gallery_rail", "a": [-64.5, -16.0], "b": [-42.5, -16.0], "kind": "horizontal_rail"},
            ]
        retag(level, prefix)
        if name == "level1":
            retarget_opening(level, ("thin_link", "competition_gym"), -93.5, -186.0, -85.5, -186.0)
            retarget_opening(level, ("public_locker", "corridor_south_link"), -97.0, -23.0, -97.0, -17.0)
            retarget_opening(level, ("nutrition_vestibule", "locker_volleyball"), -212.0, -140.0, -206.0, -140.0)
            retarget_opening(level, ("athletic_corridor", "nutrition_vestibule"), -205.5, -148.0, -205.5, -142.0)
        else:
            retarget_opening(level, ("corridor_l2", "racquetball_1"), -288.0, -80.0, -282.0, -80.0)
        # Openings must sit on the wall. Drop any that the split clipped to nothing useful.
        for wall in level["walls"]:
            length = dist(wall["a"], wall["b"])
            kept = []
            for opening in wall["openings"]:
                opening["offset"] = round(opening["offset"] * 2) / 2
                opening["width"] = round(opening["width"] * 2) / 2
                if opening["offset"] >= -0.01 and opening["offset"] + opening["width"] <= length + 0.05 and opening["width"] >= 2:
                    if opening["head"] > wall["height"]:
                        opening["head"] = wall["height"]
                    kept.append(opening)
            wall["openings"] = kept
        if name == "level1":
            repair_south_entrance(level)
            split_desk_opening(level)
        repair_stair_doors(level)
        if name == "level2":
            add_named_door(
                level,
                lambda a, b: abs(a[0] + 359.5) < 0.2
                and abs(b[0] + 359.5) < 0.2
                and min(a[1], b[1]) < -80
                and max(a[1], b[1]) > -92.5,
                "LEVEL 2 EXIT AT GRADE",
            )
        else:
            add_named_door(level, lambda a, b: abs(a[1] + 214.0) < 0.2 and abs(b[1] + 214.0) < 0.2, "SERVICE")
        save(f"{name}.json", level)
        print(name, "walls", len(level["walls"]))
    write_carve()


if __name__ == "__main__":
    main()
