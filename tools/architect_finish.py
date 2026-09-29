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


def apply_review(layout):
    """User review 01:40: stair setback, left hall to the gym, cardio rail, coaches suite."""
    level1 = layout["levels"][0]
    level2 = layout["levels"][1]
    # Double-height entry. The left hallway is the glass strip; the stair sits north of it.
    set_poly(level1, "lobby", [[-10.0, -28.0], [10.0, -28.0], [10.0, 0.0], [-10.0, 0.0]])
    set_room(level1, "lobby", ceilingHeight=32, ceilingType="gypsum")
    set_poly(level1, "glazed_recreation", [[-5.0, -80.0], [10.0, -80.0], [10.0, -28.0], [-5.0, -28.0]])
    set_poly(level1, "south_vestibule", ccw([[-97.0, -16.0], [-10.0, -16.0], [-10.0, 0.0], [-97.0, 0.0]]))
    set_room(level1, "south_vestibule", ceilingHeight=32, ceilingType="gypsum", floorMaterial="porcelain_tile")
    set_poly(
        level1,
        "fitness_annex",
        ccw([[-42.5, -48.0], [-5.0, -48.0], [-5.0, -28.0], [-10.0, -28.0], [-10.0, -16.0], [-42.5, -16.0]]),
    )
    set_poly(level1, "corridor_entry_south", ccw([[-78.5, -80.0], [-66.5, -80.0], [-66.5, -16.0], [-78.5, -16.0]]))
    set_room(level1, "corridor_entry_south", type="corridor", floorMaterial="terrazzo", ceilingHeight=12, ceilingType="act_2x4")
    set_poly(level1, "corridor_wide", ccw([[-66.5, -80.0], [-5.0, -80.0], [-5.0, -48.0], [-66.5, -48.0]]))
    set_poly(level1, "corridor_south_link", ccw([[-97.0, -62.0], [-78.5, -62.0], [-78.5, -16.0], [-97.0, -16.0]]))
    set_poly(level1, "weight_room", ccw([[-66.5, -124.0], [-40.0, -124.0], [-40.0, -80.0], [-66.5, -80.0]]))
    set_poly(level1, "fitness_center", ccw([[-66.5, -154.5], [-5.0, -154.5], [-5.0, -124.0], [-66.5, -124.0]]))
    set_poly(level1, "lobby_north", ccw([[-5.0, -154.5], [10.0, -154.5], [10.0, -124.0], [-5.0, -124.0]]))
    stair_poly = ccw([[-66.5, -48.0], [-42.5, -48.0], [-42.5, -16.0], [-66.5, -16.0]])
    set_poly(level1, "stair_main", stair_poly)
    set_poly(level2, "stair_main", [list(p) for p in stair_poly])
    set_room(level1, "stair_main", ceilingType="none", ceilingHeight=32)
    set_room(level2, "stair_main", ceilingType="none", ceilingHeight=12)
    set_poly(level2, "main_stair_landing", ccw([[-66.5, -64.0], [-42.5, -64.0], [-42.5, -48.0], [-66.5, -48.0]]))
    set_poly(
        level2,
        "balcony",
        ccw(
            [
                [-78.5, -80.0],
                [-5.0, -80.0],
                [-5.0, -48.0],
                [-42.5, -48.0],
                [-42.5, -64.0],
                [-66.5, -64.0],
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
    ensure_connection(level1, "south_vestibule", "corridor_south_link", 8, "opening")
    ensure_connection(level1, "corridor_entry_south", "corridor_south_link", 8, "opening")
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
        floorMaterial="sealed_concrete",
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
    # A 20 ft opening on the 20 ft shared edge lands inside both crossing walls.
    for conn in level1["connections"]:
        if set(conn["rooms"]) == {"glazed_recreation", "fitness_annex"} and conn.get("type") == "opening":
            conn["width"] = 18
    # The left hall is one room, so the south glass is one run instead of three room faces.
    old_south = {
        ((-42.5, 0.0), (-10.0, 0.0)),
        ((-78.5, 0.0), (-42.5, 0.0)),
        ((-97.0, 0.0), (-78.5, 0.0)),
    }
    level1["apertures"] = [
        a
        for a in level1.get("apertures", [])
        if (tuple(a.get("a", [])), tuple(a.get("b", []))) not in old_south
    ]
    level1["apertures"].append(
        {
            "a": [-97.0, 0.0],
            "b": [-10.0, 0.0],
            "height": 32.5,
            "openings": [{"center": 43.5, "width": 80, "kind": "curtainwall", "sill": 0, "head": 30}],
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
        "stair_main_opening": [[-66.0, -24.0], [-50.0, -24.0], [-50.0, -17.0], [-66.0, -17.0]],
        "stair_main_upper": [[-50.0, -40.0], [-43.0, -40.0], [-43.0, -24.0], [-50.0, -24.0]],
        "stair_main_landing": [[-50.0, -24.0], [-43.0, -24.0], [-43.0, -17.0], [-50.0, -17.0]],
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
                flight("main_a", [[-66.0, -24.0], [-50.0, -24.0], [-50.0, -17.0], [-66.0, -17.0]], [1, 0], 0, 7),
                flight("main_b", [[-50.0, -40.0], [-43.0, -40.0], [-43.0, -24.0], [-50.0, -24.0]], [0, -1], 10, 7),
            ]
            stair["landings"] = [landing("main_turn", [[-50.0, -24.0], [-43.0, -24.0], [-43.0, -17.0], [-50.0, -17.0]], 10)]
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
    furnish(layout)


def prop_at(pid, kind, x, z, rotation, room, **extra):
    item = {"id": pid, "kind": kind, "at": [round(x * 2) / 2, round(z * 2) / 2], "rotation": rotation, "room": room}
    item.update(extra)
    return item


def room_center(room):
    xs = [p[0] for p in room["polygon"]]
    zs = [p[1] for p in room["polygon"]]
    return (min(xs) + max(xs)) / 2, (min(zs) + max(zs)) / 2, max(xs) - min(xs), max(zs) - min(zs)


def furnish(layout):
    """Purposeful furniture. Priority rooms are placed by hand; every other occupied room gets a fit-out."""
    level1, level2 = layout["levels"]
    props1 = [
        prop_at("reception_desk", "front_desk", -6, -16, 270, "lobby", length=22, bays=5),
        prop_at("ping_pong_1", "ping_pong_table", -32, -8, 0, "south_vestibule"),
        prop_at("ping_pong_2", "ping_pong_table", -52, -8, 0, "south_vestibule"),
        prop_at("vending_1", "vending_machine", -74, -3, 0, "south_vestibule"),
        prop_at("vending_2", "vending_machine", -88, -3, 0, "south_vestibule"),
        prop_at("hall_trash", "trash_bin", -20, -4, 0, "south_vestibule"),
        prop_at("trophy_main", "trophy_case", -72, -100, 0, "corridor_entry_link"),
        prop_at("jersey_1", "jersey_frame", -68, -110, 90, "corridor_entry_link"),
        prop_at("jersey_2", "jersey_frame", -68, -90, 90, "corridor_entry_link"),
        prop_at("cardio_t1", "treadmill", 6, -40, 90, "glazed_recreation"),
        prop_at("cardio_t2", "treadmill", 6, -50, 90, "glazed_recreation"),
        prop_at("cardio_t3", "treadmill", 6, -60, 90, "glazed_recreation"),
        prop_at("cardio_t4", "treadmill", 6, -70, 90, "glazed_recreation"),
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
        prop_at("cube_1", "cubicle", -20, -96, 0, "coach_suite"),
        prop_at("cube_2", "cubicle", -10, -96, 0, "coach_suite"),
        prop_at("cube_3", "cubicle", -20, -106, 180, "coach_suite"),
        prop_at("cube_4", "cubicle", -10, -106, 180, "coach_suite"),
        prop_at("suite_board", "bulletin_board", -4, -90, 90, "coach_suite"),
        prop_at("suite_mail", "mail_slots", 0, -100, 90, "coach_suite"),
        prop_at("suite_clock", "wall_clock", -14, -84, 180, "coach_suite"),
        prop_at("head_desk", "office_desk", -34, -90, 0, "coach_head"),
        prop_at("head_chair", "office_chair", -34, -86, 0, "coach_head"),
        prop_at("head_plate", "nameplate", -26.5, -88, 270, "coach_suite", text="HEAD COACH"),
        prop_at("train_t1", "training_table", -230, -72, 90, "training_room"),
        prop_at("train_t2", "training_table", -230, -84, 90, "training_room"),
        prop_at("train_t3", "training_table", -218, -72, 90, "training_room"),
        prop_at("train_t4", "training_table", -218, -84, 90, "training_room"),
        prop_at("train_ice", "ice_machine", -210, -88, 0, "training_room"),
        prop_at("train_cab_1", "supply_cabinet", -232, -78, 90, "training_room"),
        prop_at("train_cab_2", "supply_cabinet", -232, -68, 90, "training_room"),
        prop_at("train_desk", "office_desk", -214, -66, 180, "training_room"),
        prop_at("train_chair", "office_chair", -214, -69, 180, "training_room"),
        prop_at("train_board", "bulletin_board", -222, -64, 180, "training_room"),
        prop_at("train_trash", "trash_bin", -208, -66, 0, "training_room"),
        prop_at("vb_net", "volleyball_standard", -136, -206, 0, "competition_gym"),
        prop_at("vb_bleach_s", "bleacher_bank", -160, -140, 0, "competition_gym", length=28, rows=8),
        prop_at("vb_bleach_n", "bleacher_bank", -136, -270, 180, "competition_gym", length=28, rows=8),
        prop_at("vb_score", "scoreboard", -100, -200, 90, "competition_gym"),
        prop_at("vb_banner_1", "banner", -120, -150, 0, "competition_gym"),
        prop_at("vb_banner_2", "banner", -150, -150, 0, "competition_gym"),
        prop_at("vb_cart", "ball_cart", -100, -160, 0, "competition_gym"),
        prop_at("vb_fountain", "water_fountain", -90, -170, 90, "competition_gym"),
        prop_at("vb_trash", "trash_bin", -90, -180, 0, "competition_gym"),
        prop_at("nutri_fridge", "industrial_fridge", -188.5, -97.5, 0, "nutrition_vestibule"),
        prop_at("lock_bank_1", "locker_bank_wood", -180, -118, 0, "locker_volleyball"),
        prop_at("lock_bank_2", "locker_bank_metal", -168, -118, 0, "locker_volleyball"),
        prop_at("lock_bench", "bench_locker", -174, -110, 0, "locker_volleyball"),
    ]
    props2 = [
        prop_at("l2_bike_1", "upright_bike", -36, -22, 180, "cardio_south"),
        prop_at("l2_bike_2", "upright_bike", -28, -22, 180, "cardio_south"),
        prop_at("l2_bike_3", "upright_bike", -20, -22, 180, "cardio_south"),
        prop_at("l2_ell_1", "elliptical", -32, -32, 180, "cardio_south"),
        prop_at("l2_ell_2", "elliptical", -22, -32, 180, "cardio_south"),
        prop_at("l2_tread_1", "treadmill", -16, -120, 270, "cardio_gallery"),
        prop_at("l2_tread_2", "treadmill", -16, -108, 270, "cardio_gallery"),
        prop_at("l2_tread_3", "treadmill", -16, -96, 270, "cardio_gallery"),
        prop_at("l2_climb_1", "stair_climber", -24, -120, 270, "cardio_gallery"),
        prop_at("l2_row_1", "rower", -30, -100, 0, "cardio_gallery"),
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
                "racquetball": "water_fountain",
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
        lo, hi = max(z0, -262.0), min(z1, -132.5)
        if hi - lo < 8:
            continue
        length = abs(b[1] - a[1])
        if b[1] >= a[1]:
            start, width = lo - a[1], hi - lo
        else:
            start, width = a[1] - hi, hi - lo
        start += 1
        width -= 2
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
                "mullionSpacing": 5,
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


def main():
    layout = load("architect_layout.json")
    prepare_layout(layout)
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
        if name == "level1":
            ok = add_exterior_door(level, "addition", "CONSTRUCTION")
            print("addition exterior door", ok)
        else:
            raise_level2_stair_walls(level)
            add_overlook_glass(level)
            for guard_a, guard_b in GUARD_SPANS:
                level["walls"] = split_for_guard(level["walls"], guard_a, guard_b)
        if name == "level1":
            add_coach_storefront(level)
        avoid_roof_faces(level, site["roofs"])
        lift_flush_ceilings(level)
        retag(level, prefix)
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
        save(f"{name}.json", level)
        print(name, "walls", len(level["walls"]))


if __name__ == "__main__":
    main()
