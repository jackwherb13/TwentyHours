"""Set owned roof/facade heights from the USGS roof table and place the south entrance.

Does not edit level JSON. Glass wall overrides stay in the nested site section.
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent / ".vendor"))
sys.modules["pyproj"] = None
import numpy as np
from shapely.geometry import Point, Polygon

ROOT = Path(__file__).resolve().parents[2]
SITE = ROOT / "blueprint_interim" / "site.json"
LEVEL = ROOT / "blueprint_interim" / "level1.json"

LIDAR = {
    "competition_gym": 33.73,
    "south_gym": 40.24,
    "main_corridor": 25.96,
    "office_wing": 25.34,
    "east_support": 25.49,
    "weight_room": 24.48,
    "locker_men": 24.44,
    "locker_women": 24.46,
    "volleyball_locker": 24.46,
    "restrooms": 24.37,
    "racquetball_1": 36.69,
    "racquetball_2": 36.76,
    "racquetball_3": 36.76,
    "racquetball_4": 36.77,
    "west_restrooms": 28.2,
    "south_lobby": 25.57,
    "entrance_vestibule": 25.73,
    "cage_construction": 45.78,
}


def nearest_height(mid, roofs):
    best = None
    for roof in roofs:
        polygon = Polygon(roof["polygon"])
        distance = polygon.distance(Point(mid))
        if distance > 18:
            continue
        rank = (distance, -roof["height"])
        if best is None or rank < best[0]:
            best = (rank, roof["height"])
    return None if best is None else best[1]


def align_facades(facades, roofs):
    groups = {}
    for index, face in enumerate(facades):
        groups.setdefault((tuple(face["a"]), tuple(face["b"])), []).append(index)
    for indexes in groups.values():
        faces = [facades[i] for i in indexes]
        if all(face["base"] >= 20 for face in faces):
            for face in faces:
                if face["base"] >= 20:
                    face["base"] = 23.6
                    face["height"] = 2.5
                    face["source"] = "south/east glass fascia at lidar vestibule roof 25.7 ft"
            continue
        a, b = faces[0]["a"], faces[0]["b"]
        mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
        target = nearest_height(mid, roofs)
        if target is None:
            continue
        ordered = sorted(indexes, key=lambda i: facades[i]["base"])
        cap = facades[ordered[-1]]
        current = cap["base"] + cap["height"]
        if abs(current - target) < 1.25:
            continue
        if cap["height"] <= 3.5 and len(ordered) >= 2:
            body = facades[ordered[-2]]
            cap["base"] = round(target - cap["height"], 2)
            body["height"] = round(cap["base"] - body["base"], 2)
            if body["height"] < 2:
                body["height"] = 2
                cap["base"] = round(body["base"] + body["height"], 2)
        else:
            cap["height"] = round(max(2, target - cap["base"]), 2)
        cap["source"] = f"top aligned to lidar roof {target:.2f} ft above L1"


def main():
    data = json.loads(SITE.read_text(encoding="utf-8"))
    level = json.loads(LEVEL.read_text(encoding="utf-8"))
    rooms = {room["id"]: room for room in level["rooms"]}
    by_source = {}
    for roof in data["roofs"]:
        key = roof.get("source", "").split(" ")[0]
        by_source[key] = roof
        if key in LIDAR:
            roof["height"] = LIDAR[key]
            roof["source"] = f"{key} USGS 2022 lidar roof {LIDAR[key]:.2f} ft above L1; parapet added by builder"
    if "cage_construction" not in by_source:
        polygon = rooms["cage_construction"]["polygon"]
        ring = np.array(polygon, dtype=float)
        center = ring.mean(axis=0)
        inset = center + (ring - center) * 0.985
        data["roofs"].append(
            {
                "polygon": np.round(inset, 2).tolist(),
                "height": LIDAR["cage_construction"],
                "type": "flat",
                "overhang": 0,
                "source": "cage_construction USGS 2022 lidar roof 45.78 ft above L1; parapet added by builder",
            }
        )
    align_facades(data["facade"], data["roofs"])
    for detail in data["site"]["details"]:
        if detail["kind"] != "hvac":
            continue
        detail["y"] = round(nearest_height(detail["at"], data["roofs"]) or detail["y"], 2)
    entrance = data["site"]["entrance"]
    entrance.update(
        {
            "x": -21.5,
            "z": 58.5,
            "width": 40,
            "landingDepth": 14,
            "risers": 10,
            "rise": 7 / 12,
            "run": 1.15,
            "canopyHeight": 24.2,
            "canopyDepth": 34,
            "canopyWidth": 52,
            "columnRadius": 0.85,
            "returnCanopyDepth": 16,
            "rotationDeg": -90,
            "source": "South glass w034. Ten 7-inch risers. Square columns and wedge soffit from IMG_0364-0368 and WEB_entrance_2. Lidar vestibule roof 25.73.",
        }
    )
    for override in data["site"]["exteriorWallOverrides"]:
        override["height"] = 24
        for opening in override["openings"]:
            if opening["type"] == "curtainwall":
                opening["head"] = 24
    shrubs = {
        "site_shrub_0": [-64.0, 66.0],
        "site_shrub_1": [-80.0, 66.0],
        "site_shrub_2": [-58.0, 78.0],
    }
    for prop in data["props"]:
        if prop["id"] in shrubs:
            prop["at"] = shrubs[prop["id"]]
            prop["rotation"] = 0
            prop["source"] = "IMG_0364 planting west of the south stair; kept off the treads"
    data["facade"] = [face for face in data["facade"] if not (face.get("style") == "metal_panel" and face.get("base", 0) >= 20)]
    for fence in data["site"]["fences"]:
        if fence["id"] == "construction":
            fence["points"] = [[-394, -234], [-232, -234], [-232, -6], [-394, -6], [-394, -234]]
            fence["source"] = "Cage addition perimeter, offset outside the floor plate so the fence is not inside the gym"
    SITE.write_text(json.dumps(data, indent=1) + "\n", encoding="utf-8")
    print("aligned roofs", len(data["roofs"]), "facades", len(data["facade"]))


if __name__ == "__main__":
    main()
