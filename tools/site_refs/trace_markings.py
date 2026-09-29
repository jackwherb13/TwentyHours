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


def zebra(ax, az, bx, bz, bar=2.0, gap=2.0, span=10.0):
    """Continental bars along a→b (across the street). span = bar length along the road."""
    dx, dz = bx - ax, bz - az
    length = math.hypot(dx, dz) or 1
    ux, uz = dx / length, dz / length
    px_, pz = -uz * span / 2, ux * span / 2
    feats = []
    t = 0.0
    on = True
    while t < length:
        step = bar if on else gap
        t1 = min(length, t + step)
        if on:
            mx, mz = ax + ux * (t + t1) / 2, az + uz * (t + t1) / 2
            feats.append(
                polyline(
                    "crosswalk",
                    "white",
                    1.8,
                    [(mx - px_, mz - pz), (mx + px_, mz + pz)],
                )
            )
        t = t1
        on = not on
    return feats


def triangle(cx, cz, yaw, length=22.0, width=10.0):
    c, s = math.cos(yaw), math.sin(yaw)
    tip = (cx + s * length / 2, cz + c * length / 2)
    left = (cx - s * length / 2 - c * width / 2, cz - c * length / 2 + s * width / 2)
    right = (cx - s * length / 2 + c * width / 2, cz - c * length / 2 - s * width / 2)
    return polyline("white_edge", "white", 0.4, [tip, left, right, tip])


def road_bundle(feats, center, src, half=11.0, yellow=0.5):
    """Yellow pair on the centerline, one white edge on each curb. No extra bike fan."""
    feats.append(polyline("double_yellow", "yellow", 0.333, offset_line(center, -yellow), src))
    feats.append(polyline("dashed_yellow", "yellow", 0.333, offset_line(center, yellow), src))
    feats.append(polyline("white_edge", "white", 0.333, offset_line(center, -half), src))
    feats.append(polyline("white_edge", "white", 0.333, offset_line(center, half), src))


def shark_teeth(ax, az, bx, bz, toward_sign=1, n=7, depth=2.2):
    dx, dz = bx - ax, bz - az
    length = math.hypot(dx, dz) or 1
    ux, uz = dx / length, dz / length
    px_, pz = -uz * toward_sign, ux * toward_sign
    feats = []
    for i in range(n):
        t = (i + 0.5) / n * length
        base = (ax + ux * t, az + uz * t)
        tip = (base[0] + px_ * depth, base[1] + pz * depth)
        left = (base[0] - ux * 1.1, base[1] - uz * 1.1)
        right = (base[0] + ux * 1.1, base[1] + uz * 1.1)
        feats.append(polyline("stop_bar", "white", 0.8, [left, tip, right, left]))
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

    # Coordinates read off 25-ft grids on ortho_blueprint.jpg (origin = south door).

    # Patriot Circle continues west past Campus Dr (toward Ox Road).
    patriot = [
        (-600, 184),
        (-540, 185),
        (-500, 186),
        (-460, 187),
        (-400, 187),
        (-340, 188),
        (-280, 189),
        (-220, 189),
        (-160, 190),
        (-100, 192),
        (-40, 193),
        (20, 194),
        (55, 180),
        (82, 158),
    ]
    road_bundle(feats, patriot, src, half=7, yellow=0.5)

    # Campus Drive: shift east onto the asphalt (was in the west verge).
    campus_w = [
        (-438, -360),
        (-453, -280),
        (-463, -220),
        (-466, -180),
        (-465, -140),
        (-464, -90),
        (-463, -40),
        (-462, 10),
        (-460, 55),
        (-458, 100),
        (-454, 135),
    ]
    road_bundle(feats, campus_w, src, half=7, yellow=0.5)
    # East lane around the teardrop (yellow only to avoid edge z-fight).
    feats.append(
        polyline(
            "bike_lane",
            "yellow",
            0.333,
            [(-448, -192), (-432, -168), (-428, -148), (-440, -128)],
            src,
        )
    )

    # Mason Pond Dr follows the south-bending asphalt, not a straight ENE chord.
    pond = [(220, 144), (280, 148), (350, 158), (430, 172), (510, 188)]
    road_bundle(feats, pond, src, half=8, yellow=0.5)

    # Inner planted island only (not the circulating disk). Outer white = curb.
    cx, cz = 147.0, 147.0
    feats.append(polyline("island", "concrete", 1.2, circle_pts(cx, cz, 30, 36), src))
    feats.append(polyline("white_edge", "white", 0.333, circle_pts(cx, cz, 36, 36), src))
    feats.append(polyline("dashed_white", "white", 0.333, circle_pts(cx, cz, 58, 36), src))
    feats.append(triangle(142, 98, math.pi, 28, 12))
    feats.append(triangle(98, 146, math.pi / 2, 28, 12))
    feats.append(triangle(134, 192, 0.0, 28, 12))
    feats.append(triangle(192, 144, -math.pi / 2, 28, 12))
    feats += zebra(128, 76, 156, 80, bar=2.4, gap=2.0, span=16)
    feats += zebra(90, 136, 98, 156, bar=2.4, gap=2.0, span=16)
    feats += zebra(110, 186, 140, 194, bar=2.4, gap=2.0, span=16)
    feats += zebra(194, 126, 210, 148, bar=2.4, gap=2.0, span=16)
    feats += zebra(-462, -58, -452, -56, bar=2.0, gap=2.0, span=8)
    feats += zebra(-468, -178, -452, -176, bar=2.0, gap=2.0, span=8)
    feats += zebra(-466, 186, -440, 189, bar=2.0, gap=2.0, span=10)

    feats += shark_teeth(124, 102, 158, 106, toward_sign=1, n=5, depth=2.0)
    feats += shark_teeth(102, 132, 106, 156, toward_sign=1, n=5, depth=2.0)
    feats += shark_teeth(114, 178, 144, 186, toward_sign=-1, n=5, depth=2.0)
    feats += shark_teeth(182, 128, 196, 150, toward_sign=-1, n=5, depth=2.0)

    # South plaza walk on the concrete to the roundabout (one path, 8–10 ft).
    feats.append(polyline("symbol", "white", 0.5, [(-8, 8), (20, 16), (50, 36), (76, 62)], src))

    # Small paved stall pocket NW of the circle, stalls perpendicular to the aisle.
    feats += stall_row(58, 28, 5, 9, 18, heading="s")
    feats.append(accessible_symbol(62.5, 37))

    # Equipment yard tight to the dark gym roof (small tan pad, not the shrub bed).
    feats.append(
        polyline(
            "white_edge",
            "white",
            0.4,
            [(-328, 30), (-304, 32), (-300, 50), (-326, 52), (-328, 30)],
            src,
        )
    )

    # East driveway throat only — do not continue into the woods.
    feats.append(polyline("bike_lane", "yellow", 0.333, [(88, 70), (62, 28), (55, 12)], src))

    # --- Banister / Lot K: stall paint and islands from 25-ft lot grid ---
    pitch = 9.0
    x_lot = -405.0
    n_full = 47

    def skips(*ranges):
        s = set()
        for a, b in ranges:
            ia = int(round((a - x_lot) / pitch))
            ib = int(round((b - x_lot) / pitch))
            s.update(range(min(ia, ib), max(ia, ib) + 1))
        return s

    feats += stall_row(x_lot, 272, n_full, pitch, 18, "s")
    skip_b = skips((-262, -225), (-198, -155), (-52, -12))
    feats += stall_row(x_lot, 304, n_full, pitch, 18, "s", skip_b)
    feats += stall_row(x_lot, 328, n_full, pitch, 18, "s", skip_b)
    skip_c = skips((-255, -200), (-135, -72), (-18, 18))
    feats += stall_row(x_lot, 400, n_full, pitch, 18, "s", skip_c)
    skip_d = skips((-242, -205), (-210, -175), (-20, 16))
    feats += stall_row(x_lot, 436, n_full, pitch, 18, "s", skip_d)
    feats += stall_row(x_lot, 460, n_full, pitch, 18, "s", skip_d)

    def rect(x, z, w, d):
        return polyline(
            "island",
            "concrete",
            0.5,
            [(x, z), (x + w, z), (x + w, z + d), (x, z + d), (x, z)],
            src,
        )

    # Island boxes sized to mulch/curb, not canopy drip.
    # Pads ~2 stalls wide × stall depth, on the mulch.
    feats.append(rect(-254, 306, 30, 20))
    feats.append(rect(-178, 304, 34, 20))
    feats.append(rect(-38, 306, 28, 20))
    feats.append(rect(-234, 424, 28, 20))
    feats.append(rect(-168, 426, 28, 20))
    feats.append(rect(-10, 426, 26, 20))

    # ADA: ISA + 8 ft hatched access aisle at the NE corner.
    feats.append(accessible_symbol(-8, 281))
    feats.append(accessible_symbol(1, 281))
    for k in range(6):
        t = 272 + k * 3.0
        feats.append(polyline("symbol", "blue", 0.25, [(-7, t), (2, t + 2.2)], src))

    feats.append(polyline("white_edge", "white", 0.333, [(38, 272), (38, 490)], src))
    feats.append(polyline("white_edge", "white", 0.333, [(38, 255), (88, 208)], src))

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
        if f["kind"] == "island" and len(pts) >= 3:
            draw.polygon(pts, outline=(110, 90, 55), fill=(130, 108, 70))
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
