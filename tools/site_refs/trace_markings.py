"""Trace RAC-area road and parking markings into tools/site_refs/markings.json."""
from __future__ import annotations

import json
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
WEB = ROOT / "reference" / "web" / "site"
OUT = ROOT / "tools" / "site_refs"
VERIFY = ROOT / "verification" / "site_markings"
VERIFY.mkdir(parents=True, exist_ok=True)

meta = json.loads((WEB / "ortho_meta.json").read_text())
X0, Z0, S, PX = meta["x0"], meta["z0"], meta["ftPerPx"], meta["px"]
IMG = np.asarray(Image.open(WEB / "ortho_blueprint.jpg"))


def ft(i, j):
    return X0 + i * S, Z0 + j * S


def px(x, z):
    return int((x - X0) / S), int((z - Z0) / S)


def polyline(kind, color, width, points, source="esri_world_imagery"):
    return {
        "kind": kind,
        "color": color,
        "width": width,
        "points": [[round(p[0], 2), round(p[1], 2)] for p in points],
        "source": source,
    }


def circle_pts(cx, cz, r, n=48):
    return [
        (cx + r * math.cos(t), cz + r * math.sin(t))
        for t in [i * 2 * math.pi / n for i in range(n + 1)]
    ]


def offset_line(pts, dist):
    out = []
    for i, (x, z) in enumerate(pts):
        if i == 0:
            dx, dz = pts[1][0] - x, pts[1][1] - z
        elif i == len(pts) - 1:
            dx, dz = x - pts[i - 1][0], z - pts[i - 1][1]
        else:
            dx, dz = pts[i + 1][0] - pts[i - 1][0], pts[i + 1][1] - pts[i - 1][1]
        L = math.hypot(dx, dz) or 1
        out.append((x - dz / L * dist, z + dx / L * dist))
    return out


def dashed(pts, dash=10, gap=10):
    segs = []
    for a, b in zip(pts, pts[1:]):
        dx, dz = b[0] - a[0], b[1] - a[1]
        length = math.hypot(dx, dz)
        if length < 1:
            continue
        ux, uz = dx / length, dz / length
        t = 0.0
        on = True
        while t < length:
            span = dash if on else gap
            t1 = min(length, t + span)
            if on:
                segs.append([(a[0] + ux * t, a[1] + uz * t), (a[0] + ux * t1, a[1] + uz * t1)])
            t = t1
            on = not on
    return segs


def zebra(ax, az, bx, bz, n=8, bar=1.5, gap=1.5):
    dx, dz = bx - ax, bz - az
    length = math.hypot(dx, dz)
    ux, uz = dx / length, dz / length
    px_, pz = -uz, ux
    feats = []
    t = 0.0
    on = True
    while t < length:
        span = bar if on else gap
        t1 = min(length, t + span)
        if on:
            mx, mz = ax + ux * (t + t1) / 2, az + uz * (t + t1) / 2
            feats.append(
                polyline(
                    "crosswalk",
                    "white",
                    8.0,
                    [(mx - px_ * 0.75, mz - pz * 0.75), (mx + px_ * 0.75, mz + pz * 0.75)],
                )
            )
        t = t1
        on = not on
    return feats


def stall_row(x0, z0, n, pitch, length, heading="s", skip=None):
    skip = set(skip or [])
    hz = 1 if heading == "s" else -1
    feats = []
    for i in range(n + 1):
        if i in skip:
            continue
        x = x0 + i * pitch
        feats.append(
            polyline(
                "stall",
                "white",
                0.333,
                [(x, z0), (x, z0 + hz * length)],
            )
        )
    return feats


def accessible_symbol(x, z):
    return polyline("symbol", "blue", 4.0, [(x - 2, z), (x + 2, z)])


def main():
    feats = []
    src = "esri_world_imagery_z19_warped_blueprint"

    # --- Patriot Circle / Mason Pond Dr (south of RAC, ~z=155–175) ---
    # Centerline from west Campus Dr merge through south frontage to roundabout.
    patriot = [
        (-480, 188),
        (-400, 180),
        (-300, 174),
        (-180, 172),
        (-80, 176),
        (20, 188),
        (70, 198),
        (100, 208),
    ]
    feats.append(polyline("double_yellow", "yellow", 0.333, offset_line(patriot, -0.55), src))
    feats.append(polyline("dashed_yellow", "yellow", 0.333, offset_line(patriot, 0.55), src))
    # bike lanes both sides, ~5 ft from edge of ~36 ft roadway
    feats.append(polyline("bike_lane", "white", 0.333, offset_line(patriot, -14), src))
    feats.append(polyline("bike_lane", "white", 0.333, offset_line(patriot, 14), src))
    feats.append(polyline("white_edge", "white", 0.333, offset_line(patriot, -18), src))
    feats.append(polyline("white_edge", "white", 0.333, offset_line(patriot, 18), src))


    # --- Campus Drive west of RAC (north-south, x~-430) ---
    campus = [(-492, -160), (-490, -40), (-488, 40), (-478, 140), (-460, 190)]
    feats.append(polyline("dashed_yellow", "yellow", 0.333, campus, src))
    feats.append(polyline("bike_lane", "white", 0.333, offset_line(campus, -12), src))
    feats.append(polyline("bike_lane", "white", 0.333, offset_line(campus, 12), src))
    feats.append(polyline("white_edge", "white", 0.333, offset_line(campus, -16), src))
    feats.append(polyline("white_edge", "white", 0.333, offset_line(campus, 16), src))

    # --- East RAC drive / Banister Creek approach (north-south, x~20) ---
    east = [(48, -200), (52, -80), (80, 40), (110, 120), (125, 165)]
    feats.append(polyline("double_yellow", "yellow", 0.333, offset_line(east, -0.55), src))
    feats.append(polyline("dashed_yellow", "yellow", 0.333, offset_line(east, 0.55), src))


    # --- Mason Pond Dr east of roundabout ---
    pond = [(175, 148), (240, 142), (320, 138), (420, 155), (520, 185)]
    feats.append(polyline("double_yellow", "yellow", 0.333, offset_line(pond, -0.55), src))
    feats.append(polyline("dashed_yellow", "yellow", 0.333, offset_line(pond, 0.55), src))
    feats.append(polyline("white_edge", "white", 0.333, offset_line(pond, -14), src))
    feats.append(polyline("white_edge", "white", 0.333, offset_line(pond, 14), src))

    # --- North loop (Patriot Circle north of RAC, z~-230) ---
    north = [(-40, -248), (20, -246), (55, -210), (48, -150), (40, -80)]
    feats.append(polyline("double_yellow", "yellow", 0.333, offset_line(north, -0.55), src))
    feats.append(polyline("dashed_yellow", "yellow", 0.333, offset_line(north, 0.55), src))
    feats.append(polyline("white_edge", "white", 0.333, offset_line(north, -12), src))
    feats.append(polyline("white_edge", "white", 0.333, offset_line(north, 12), src))

    # --- Roundabout at Patriot Circle / Mason Pond (center ~110, 95) ---
    cx, cz, r_island, r_paint = 136.0, 158.0, 42.0, 46.0
    feats.append(polyline("island", "concrete", 2.0, circle_pts(cx, cz, r_island), src))
    feats.append(polyline("white_edge", "white", 0.333, circle_pts(cx, cz, r_paint), src))
    feats.append(polyline("dashed_white", "white", 0.333, circle_pts(cx, cz, 62), src))
    # splitter islands as short curb loops at 4 approaches
    for ang, rad in [(math.pi * 0.05, 70), (math.pi * 0.55, 70), (math.pi * 1.05, 68), (math.pi * 1.55, 70)]:
        ix = cx + math.cos(ang) * rad
        iz = cz + math.sin(ang) * rad
        feats.append(polyline("island", "concrete", 1.5, circle_pts(ix, iz, 8, 16), src))

    # Crosswalks at roundabout (ladder / continental from street photos)
    feats += zebra(78, 210, 108, 198)
    feats += zebra(148, 95, 172, 108)
    feats += zebra(178, 155, 198, 138)
    feats += zebra(72, 128, 92, 112)
    feats += zebra(110, 198, 140, 208)
    feats += zebra(-486, -48, -444, -46)
    feats += zebra(12, -252, 48, -250)

    # Stop / yield bars
    feats.append(polyline("stop_bar", "white", 1.5, [(70, 200), (100, 188)], src))
    feats.append(polyline("stop_bar", "white", 1.5, [(68, 122), (90, 108)], src))
    feats.append(polyline("stop_bar", "white", 1.5, [(170, 160), (192, 142)], src))
    feats.append(polyline("stop_bar", "white", 1.5, [(-10, 188), (22, 194)], src))

    # Turn arrows (simple chevrons)
    def arrow(x, z, yaw):
        c, s = math.cos(yaw), math.sin(yaw)
        tip = (x + 6 * s, z + 6 * c)
        left = (x - 3 * c, z + 3 * s)
        right = (x + 3 * c, z - 3 * s)
        feats.append(polyline("arrow", "white", 1.0, [left, tip, right], src))

    arrow(40, 155, 0.4)
    arrow(140, 90, -1.2)
    arrow(-20, 150, 1.2)
    arrow(90, 50, 3.0)

    # RAC drop-off / ADA stalls east of south entrance (~x=40, z=20)
    feats += stall_row(48, 22, 6, 9, 18, heading="s")
    feats.append(accessible_symbol(52.5, 31))
    feats.append(accessible_symbol(61.5, 31))

    feats += stall_row(78, 58, 5, 9, 18, heading="s")

    # --- South RAC lot (Banister Creek Ct / Lot K-ish) ---
    # Measured from warped Esri: north curb of first stall row ~z=268
    # 9 ft pitch, 18 ft stall, 24 ft aisle, landscape islands.
    # Row A: single-loaded against north curb, cars face south.
    pitch = 9.0
    x_lot = -388.0
    n_full = 46
    island_a = set(range(17, 22)) | set(range(31, 36))
    feats += stall_row(x_lot, 306, n_full, pitch, 18, "s", island_a)
    feats += stall_row(x_lot, 330, n_full, pitch, 18, "s", island_a)
    island_c = set(range(15, 21)) | set(range(29, 35))
    feats += stall_row(x_lot, 372, n_full, pitch, 18, "s", island_c)
    feats += stall_row(x_lot, 396, n_full, pitch, 18, "s", island_c)
    island_e = set(range(14, 19)) | set(range(28, 34))
    feats += stall_row(x_lot, 446, n_full, pitch, 18, "s", island_e)
    feats += stall_row(x_lot, 470, n_full, pitch, 18, "s", island_e)
    # East bay: west-facing stalls along the lot's east aisle
    # East bay stalls omitted: they shared faces with the last 9-ft module.

    # Landscape islands (rectangles as curb loops)
    def rect(x, z, w, d):
        return polyline(
            "island",
            "concrete",
            0.5,
            [(x, z), (x + w, z), (x + w, z + d), (x, z + d), (x, z)],
            src,
        )

    feats.append(rect(-240, 316, 36, 22))
    feats.append(rect(-116, 316, 36, 22))
    feats.append(rect(-258, 356, 40, 22))
    feats.append(rect(-132, 356, 40, 22))
    feats.append(rect(-270, 430, 40, 22))
    feats.append(rect(-144, 430, 45, 22))

    # ADA stalls at east end of north row
    feats.append(accessible_symbol(x_lot + 43 * pitch + 4.5, 307))
    feats.append(accessible_symbol(x_lot + 44 * pitch + 4.5, 307))
    feats.append(polyline("stall", "blue", 0.333, [(x_lot + 43 * pitch, 298), (x_lot + 45 * pitch, 298)], src))



    # Bike symbols along Patriot Circle
    for x, z in [(-300, 170), (-120, 168), (0, 182)]:
        feats.append(polyline("symbol", "white", 3.0, [(x - 2, z), (x + 2, z)], src))

    data = {
        "crs": "blueprint_ft",
        "origin": "RAC south entrance door",
        "trueNorthDeg": 10.43,
        "ortho": {
            "file": "reference/web/site/ortho_blueprint.jpg",
            "x0": X0,
            "z0": Z0,
            "ftPerPx": S,
        },
        "features": feats,
        "counts": {
            "features": len(feats),
            "stalls_approx": sum(1 for f in feats if f["kind"] == "stall") // 3,
        },
    }
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "markings.json").write_text(json.dumps(data, indent=2))
    print("features", len(feats), "written", OUT / "markings.json")

    # Overlay for judges
    overlay = Image.open(WEB / "ortho_blueprint.jpg").convert("RGB")
    draw = ImageDraw.Draw(overlay)
    colors = {
        "yellow": (240, 200, 40),
        "white": (250, 250, 245),
        "blue": (50, 90, 200),
        "concrete": (200, 180, 140),
    }
    for f in feats:
        pts = [px(p[0], p[1]) for p in f["points"]]
        if len(pts) < 2:
            continue
        col = colors.get(f["color"], (255, 0, 255))
        w = 2 if f["kind"] in ("island", "crosswalk", "stop_bar") else 1
        draw.line(pts, fill=col, width=max(1, w))
    overlay.save(VERIFY / "overlay_full.jpg", quality=90)
    # zoomed lot + roundabout
    i0, j0 = px(-430, -40)
    i1, j1 = px(220, 520)
    overlay.crop((min(i0, i1), min(j0, j1), max(i0, i1), max(j0, j1))).save(
        VERIFY / "overlay_lot_roundabout.jpg", quality=90
    )
    i0, j0 = px(-500, -260)
    i1, j1 = px(-250, 180)
    overlay.crop((min(i0, i1), min(j0, j1), max(i0, i1), max(j0, j1))).save(
        VERIFY / "overlay_campus_dr.jpg", quality=90
    )
    print("overlays", VERIFY)


if __name__ == "__main__":
    main()
