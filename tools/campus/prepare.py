"""Build campus massing JSON + CampusData.luau from county GIS, OSM, 3DEP and lidar."""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "site"))
sys.path.insert(0, str(ROOT / "tools" / "site" / ".vendor"))

from prepare_site import C, S, SHIFT, inverse  # noqa: E402
from shapely.geometry import LineString, MultiPolygon, Polygon, box
from shapely.ops import unary_union
from shapely import make_valid

WEB = ROOT / "reference" / "web"
CAMPUS_WEB = WEB / "campus"
OUT = ROOT / "verification" / "campus"
MODULE = ROOT / "src" / "ReplicatedStorage" / "RAC" / "Site" / "Campus"
OUT.mkdir(parents=True, exist_ok=True)
MODULE.mkdir(parents=True, exist_ok=True)

FLOOR = 437.92408076682665
TRUE_NORTH = 10.43
# Fine exterior grid (live Heightfield / TerrainData.luau).
FINE = dict(x0=-418.5249, z0=-580.0041, step=4.0, nx=200, nz=200)
# Coarse campus grid, 16 ft, covering Globe east, Arena south, Field House west.
COARSE = dict(x0=-880.0, z0=-640.0, step=16.0, nx=112, nz=128)  # 1792 x 2048 ft

SKIP_NAMES = {
	"RECREATION AND ATHLETIC COMPLEX",
	"GEORGE MASON UNIVERSITY MAIN CAMPUS",
	"UNIVERSITY MALL BUILDING G1",
	"UNIVERSITY MALL SHOPPING CENTER",
}

FINISH = {
	"EAGLE BANK ARENA": ("precast", 88, "arena"),
	"MASON GLOBAL CENTER": ("brick", 68, "global"),
	"FIELD HOUSE": ("brick", 36, "fieldhouse"),
	"WEST PE MODULE": ("brick", 28, "westpe"),
	"PARKING DECK - MASON POND": ("precast", 42, "deck"),
	"PARKING DECK - SHENANDOAH": ("precast", 42, "deck"),
	"HARRIS THEATRE": ("brick", 42, "academic"),
	"CENTER FOR THE ARTS": ("brick", 48, "academic"),
	"PERFORMING ARTS BUILDING": ("brick", 48, "academic"),
	"STUDENT UNION I": ("brick", 52, "academic"),
	"MASON HALL": ("precast", 55, "academic"),
	"ROBINSON HALL A WING": ("brick", 55, "academic"),
	"AQUIA BUILDING": ("brick", 48, "academic"),
	"KRUG HALL": ("brick", 40, "academic"),
	"THOMPSON HALL": ("brick", 40, "academic"),
	"FINLEY BUILDING": ("brick", 36, "academic"),
	"EAST BUILDING": ("brick", 32, "academic"),
	"WEST BUILDING": ("brick", 32, "academic"),
	"FINE ARTS BUILDING": ("brick", 36, "academic"),
}


def grid_coordinates(lat, lon):
	from prepare_site import FT, LAT0, LON0

	e = (np.asarray(lon) - LON0) * 111320 * math.cos(math.radians(LAT0)) * FT
	n = (np.asarray(lat) - LAT0) * 111320 * FT
	return e * C - n * S + SHIFT[0], -e * S - n * C + SHIFT[1]


def rings_to_poly(rings):
	result = Polygon()
	for ring in rings:
		lat = [p[1] for p in ring]
		lon = [p[0] for p in ring]
		x, z = grid_coordinates(lat, lon)
		poly = make_valid(Polygon(np.column_stack((x, z))))
		if poly.is_empty:
			continue
		result = result.symmetric_difference(poly)
	return result


def osm_way_poly(el):
	geom = el.get("geometry") or []
	if len(geom) < 4:
		return None
	x, z = grid_coordinates([p["lat"] for p in geom], [p["lon"] for p in geom])
	poly = make_valid(Polygon(np.column_stack((x, z))))
	return None if poly.is_empty else poly


def obb_box(poly: Polygon) -> dict:
	rect = poly.minimum_rotated_rectangle
	coords = np.array(rect.exterior.coords[:4])
	edges = [coords[(i + 1) % 4] - coords[i] for i in range(4)]
	long = max(edges, key=lambda e: float(np.linalg.norm(e)))
	yaw = math.atan2(long[0], long[1])  # rotation about Y from +Z
	c = coords.mean(axis=0)
	w = float(np.linalg.norm(edges[0]))
	d = float(np.linalg.norm(edges[1]))
	if w < d:
		w, d = d, w
		yaw += math.pi / 2
	return {
		"x": round(float(c[0]), 2),
		"z": round(float(c[1]), 2),
		"w": round(w, 2),
		"d": round(d, 2),
		"yaw": round(yaw, 4),
	}


def split_boxes(poly: Polygon, budget: int = 6) -> list[dict]:
	poly = make_valid(poly.simplify(3.0, preserve_topology=True))
	if poly.is_empty:
		return []
	parts = [poly] if poly.geom_type == "Polygon" else [g for g in poly.geoms if g.area > 80]
	out = []

	def rec(g: Polygon, depth: int):
		if g.area < 80 or len(out) >= budget:
			return
		b = obb_box(g)
		obb_area = b["w"] * b["d"]
		if obb_area <= g.area * 1.28 or depth == 0 or min(b["w"], b["d"]) < 24:
			out.append(b)
			return
		# Split along the long axis of the OBB.
		cx, cz, w, d, yaw = b["x"], b["z"], b["w"], b["d"], b["yaw"]
		ux, uz = math.sin(yaw), math.cos(yaw)
		cut = LineString(
			[(cx - ux * 0.1 - uz * d, cz - uz * 0.1 + ux * d), (cx + ux * 0.1 + uz * d, cz + uz * 0.1 - ux * d)]
		).buffer(0.2)
		left = make_valid(g.difference(cut))
		chunks = []
		if not left.is_empty:
			chunks = [left] if left.geom_type == "Polygon" else list(left.geoms)
		chunks = [c for c in chunks if c.area > 80]
		if len(chunks) < 2:
			out.append(b)
			return
		for c in chunks[:2]:
			rec(c, depth - 1)

	for p in parts:
		rec(p, 2)
	return out[:budget]


def load_osm_elements():
	els = []
	for name in ("osm_campus.json",):
		path = CAMPUS_WEB / name
		if path.exists():
			els.extend(json.loads(path.read_text(encoding="utf-8")).get("elements", []))
	for name in ("osm_rac_area.json", "osm_area.json"):
		path = ROOT / "reference" / name
		if path.exists():
			try:
				els.extend(json.loads(path.read_text(encoding="utf-8")).get("elements", []))
			except Exception:
				pass
	return els


def lidar_heights(buildings: list[dict]) -> None:
	laz = WEB / "rac_lidar_2022.laz"
	if not laz.exists():
		print("No LAZ; using typical heights", flush=True)
		return
	try:
		import laspy
		from rasterio.warp import transform
	except Exception as exc:
		print("laspy unavailable", exc, flush=True)
		return
	from shapely.geometry import Point
	from shapely import contains_xy

	polys = []
	for b in buildings:
		poly = Polygon()
		# rebuild from stored rings in building record
		poly = b["_poly"]
		polys.append(poly)
	bounds = unary_union(polys).bounds
	maxz = [[] for _ in buildings]
	with laspy.open(laz) as reader:
		for points in reader.chunk_iterator(800000):
			x = np.asarray(points.x)
			y = np.asarray(points.y)
			cls = np.asarray(points.classification)
			keep = cls == 6
			if not keep.any():
				continue
			x, y = x[keep], y[keep]
			z = np.asarray(points.z)[keep] * 1.000002
			lon, lat = transform("EPSG:6593", "EPSG:4326", x.tolist(), y.tolist())
			bx, bz = grid_coordinates(lat, lon)
			inside = (bx > bounds[0] - 20) & (bx < bounds[2] + 20) & (bz > bounds[1] - 20) & (bz < bounds[3] + 20)
			if not inside.any():
				continue
			bx, bz, z = bx[inside], bz[inside], z[inside]
			rel = z - FLOOR
			for i, poly in enumerate(polys):
				hit = contains_xy(poly, bx, bz)
				if hit.any():
					vals = rel[hit]
					vals = vals[vals > 8]
					if len(vals):
						maxz[i].append(float(np.percentile(vals, 90)))
	for i, b in enumerate(buildings):
		if maxz[i]:
			b["height"] = round(min(120, max(12, float(np.median(maxz[i])))), 1)
			b["heightSource"] = "USGS LPC VA_NorthernVA_B22 class 1/6 90th percentile"
		else:
			b["heightSource"] = "typical campus massing (no lidar returns in footprint)"


def sample_dem(xs, zs):
	import rasterio
	from rasterio.warp import transform

	lats, lons = [], []
	for x, z in zip(xs, zs):
		lat, lon = inverse(float(x), float(z))
		lats.append(lat)
		lons.append(lon)
	e, n = transform("EPSG:4326", "EPSG:26918", lons, lats)
	with rasterio.open(WEB / "rac_3dep_1m.tif") as ds:
		vals = np.array([s[0] for s in ds.sample(zip(e, n))], dtype=float)
	return vals * (1 / 0.3048) - FLOOR


def parse_fine_heights():
	text = (ROOT / "src/ReplicatedStorage/RAC/Site/TerrainData.luau").read_text(encoding="utf-8")
	# rows are quoted comma lists of hundredths
	rows = []
	in_rows = False
	for line in text.splitlines():
		if line.strip().startswith("rows={"):
			in_rows = True
			continue
		if in_rows:
			if line.strip().startswith("},"):
				break
			if '"' in line:
				body = line.split('"')[1]
				rows.append([int(v) / 100.0 for v in body.split(",") if v])
	arr = np.array(rows, dtype=float)
	assert arr.shape == (FINE["nz"], FINE["nx"]), arr.shape
	return arr


def coarse_grid(fine, roads, pads):
	x0, z0, step, nx, nz = (COARSE[k] for k in ("x0", "z0", "step", "nx", "nz"))
	cx = x0 + step * (np.arange(nx) + 0.5)
	cz = z0 + step * (np.arange(nz) + 0.5)
	xx, zz = np.meshgrid(cx, cz)
	h = sample_dem(xx.ravel(), zz.ravel()).reshape(nz, nx)
	# Blend: overwrite cells whose center is inside the fine grid.
	fx0, fz0, fs, fnx, fnz = (FINE[k] for k in ("x0", "z0", "step", "nx", "nz"))
	ui = (xx - fx0) / fs - 0.5
	vj = (zz - fz0) / fs - 0.5
	inside = (ui >= 0) & (ui < fnx - 1) & (vj >= 0) & (vj < fnz - 1)
	i0 = np.floor(ui).astype(int)
	j0 = np.floor(vj).astype(int)
	a = ui - i0
	b = vj - j0
	fine_h = (
		fine[np.clip(j0, 0, fnz - 1), np.clip(i0, 0, fnx - 1)] * (1 - a) * (1 - b)
		+ fine[np.clip(j0, 0, fnz - 1), np.clip(i0 + 1, 0, fnx - 1)] * a * (1 - b)
		+ fine[np.clip(j0 + 1, 0, fnz - 1), np.clip(i0, 0, fnx - 1)] * (1 - a) * b
		+ fine[np.clip(j0 + 1, 0, fnz - 1), np.clip(i0 + 1, 0, fnx - 1)] * a * b
	)
	h = np.where(inside, fine_h, h)
	materials = np.ones((nz, nx), dtype=np.uint8)
	from shapely import contains_xy

	if roads is not None and not roads.is_empty:
		materials[contains_xy(roads, xx, zz)] = 2
	if pads is not None and not pads.is_empty:
		materials[contains_xy(pads, xx, zz)] = 3
	return h, materials, inside


def field_markings(poly: Polygon, sport: str) -> list[dict]:
	b = obb_box(poly)
	cx, cz, w, d, yaw = b["x"], b["z"], b["w"], b["d"], b["yaw"]
	# Local +Z is long axis of OBB (yaw).
	marks = []

	def local(lx, lz):
		s, c = math.sin(yaw), math.cos(yaw)
		return [round(cx + s * lz + c * lx, 2), round(cz + c * lz - s * lx, 2)]

	hw, hd = w / 2, d / 2
	# Sidelines and goal lines.
	for lx in (-hw + 1, hw - 1):
		marks.append({"a": local(lx, -hd + 1), "b": local(lx, hd - 1), "w": 0.4})
	for lz in (-hd + 1, hd - 1):
		marks.append({"a": local(-hw + 1, lz), "b": local(hw - 1, lz), "w": 0.4})
	# Midline
	marks.append({"a": local(-hw + 1, 0), "b": local(hw - 1, 0), "w": 0.4})
	if sport in ("american_football", "football"):
		for yds in range(-40, 50, 10):
			lz = yds * (d / 120.0)
			if abs(lz) < hd - 4:
				marks.append({"a": local(-hw + 4, lz), "b": local(hw - 4, lz), "w": 0.3})
	else:
		# soccer-ish center circle as 8-gon
		r = min(30, hw * 0.25)
		pts = [local(r * math.sin(k * math.pi / 4), r * math.cos(k * math.pi / 4)) for k in range(8)]
		for a, bpt in zip(pts, pts[1:] + pts[:1]):
			marks.append({"a": a, "b": bpt, "w": 0.3})
	return marks


def write_luau(data: dict, h, materials) -> None:
	nx, nz = COARSE["nx"], COARSE["nz"]
	ymin = math.floor((float(h.min()) - 8) / 4) * 4
	ymax = math.ceil((float(h.max()) + 8) / 4) * 4
	lines = [
		"--!strict",
		"-- Generated by tools/campus/prepare.py. Do not edit by hand.",
		"return {",
		f"\tfine = {{ x0 = {FINE['x0']}, z0 = {FINE['z0']}, step = {FINE['step']}, nx = {FINE['nx']}, nz = {FINE['nz']} }},",
		f"\tx0 = {COARSE['x0']}, z0 = {COARSE['z0']}, step = {COARSE['step']}, nx = {nx}, nz = {nz}, yMin = {ymin}, yMax = {ymax},",
		"\trows = {",
	]
	for row in h:
		lines.append('\t\t"' + ",".join(str(int(round(v * 100))) for v in row) + '",')
	lines += ["\t},", "\tmaterials = {"]
	for row in materials:
		lines.append('\t\t"' + "".join(str(int(v)) for v in row) + '",')
	lines.append("\t},")
	# Compact buildings without shapely objects.
	payload = []
	for b in data["buildings"]:
		payload.append(
			{
				"id": b["id"],
				"name": b["name"],
				"kind": b["kind"],
				"finish": b["finish"],
				"height": b["height"],
				"ground": b["ground"],
				"levels": b.get("levels", 1),
				"boxes": b["boxes"],
				"windowSill": b.get("windowSill", 4),
				"windowHead": b.get("windowHead", 10),
			}
		)
	def luau(value, indent=1):
		pad = "\t" * indent
		if isinstance(value, dict):
			parts = []
			for k, v in value.items():
				parts.append(f"{pad}\t{k} = {luau(v, indent+1)}")
			return "{\n" + ",\n".join(parts) + f",\n{pad}}}"
		if isinstance(value, (list, tuple)):
			if not value:
				return "{}"
			if all(isinstance(x, (int, float)) and not isinstance(x, bool) for x in value):
				return "{" + ", ".join(str(round(float(x), 4) if isinstance(x, float) else int(x)) for x in value) + "}"
			inner = ",\n".join(pad + "\t" + luau(v, indent + 1) for v in value)
			return "{\n" + inner + f",\n{pad}}}"
		if isinstance(value, bool):
			return "true" if value else "false"
		if isinstance(value, float):
			return str(round(value, 4))
		if isinstance(value, int):
			return str(value)
		if value is None:
			return "nil"
		return json.dumps(str(value))

	lines.append("\tbuildings = " + luau(payload) + ",")
	lines.append("\tfields = " + luau(data["fields"]) + ",")
	lines.append("\tdecks = " + luau(data["decks"]) + ",")
	lines.append("\troads = " + luau(data["roads"]) + ",")
	lines.append("}")
	(MODULE / "CampusData.luau").write_text("\n".join(lines) + "\n", encoding="utf-8")


def comparison_image(buildings, fields, decks, h):
	ortho_path = CAMPUS_WEB / "campus_ortho.jpg"
	x0, z0, step, nx, nz = (COARSE[k] for k in ("x0", "z0", "step", "nx", "nz"))
	width, height = 1600, 1600
	x1, z1 = x0 + nx * step, z0 + nz * step

	def px(x, z):
		u = (x - x0) / (x1 - x0) * (width - 1)
		v = (z - z0) / (z1 - z0) * (height - 1)
		return (int(u), int(v))

	if ortho_path.exists():
		src = np.asarray(Image.open(ortho_path).convert("RGB"))
		bbox = json.loads((OUT / "bbox.json").read_text())["bbox4326"]
		west, south, east, north = bbox
		from prepare_site import FT, LAT0, LON0

		yy, xx = np.mgrid[0:height, 0:width]
		wx = x0 + xx / (width - 1) * (x1 - x0) - SHIFT[0]
		wz = z0 + yy / (height - 1) * (z1 - z0) - SHIFT[1]
		e = wx * C - wz * S
		n = -wx * S - wz * C
		lats = LAT0 + n / (111320 * FT)
		lons = LON0 + e / (111320 * math.cos(math.radians(LAT0)) * FT)
		u = (lons - west) / (east - west) * (src.shape[1] - 1)
		v = (north - lats) / (north - south) * (src.shape[0] - 1)
		from scipy.ndimage import map_coordinates

		rgb = np.stack(
			[map_coordinates(src[:, :, k].astype(float), [v, u], order=1, mode="nearest") for k in range(3)],
			axis=2,
		)
		left = Image.fromarray(np.uint8(np.clip(rgb, 0, 255)))
	else:
		left = Image.new("RGB", (width, height), (40, 70, 40))
	right = left.copy()
	draw = ImageDraw.Draw(right, "RGBA")
	for b in buildings:
		for boxp in b["boxes"]:
			s, c = math.sin(boxp["yaw"]), math.cos(boxp["yaw"])
			hw, hd = boxp["w"] / 2, boxp["d"] / 2
			cx, cz = boxp["x"], boxp["z"]
			corners = []
			for lx, lz in ((-hw, -hd), (hw, -hd), (hw, hd), (-hw, hd)):
				corners.append(px(cx + s * lz + c * lx, cz + c * lz - s * lx))
			color = (200, 180, 140, 160) if b["kind"] != "deck" else (150, 150, 155, 180)
			if b["kind"] == "arena":
				color = (230, 230, 225, 180)
			draw.polygon(corners, fill=color, outline=(20, 20, 20, 255))
	for f in fields:
		poly = [px(p[0], p[1]) for p in f["polygon"]]
		if len(poly) >= 3:
			draw.polygon(poly, fill=(40, 120, 50, 120), outline=(240, 240, 240, 255))
	pair = Image.new("RGB", (width * 2 + 40, height + 60), (250, 250, 250))
	pair.paste(left, (10, 50))
	pair.paste(right, (width + 30, 50))
	td = ImageDraw.Draw(pair)
	td.text((12, 12), "LEFT NAIP ortho (reference)   RIGHT campus massing in RAC building frame  +X east +Z south", fill=(0, 0, 0))
	pair.save(OUT / "plan_comparison.png")
	# Heightfield preview
	shade = np.uint8((h - h.min()) / max(h.max() - h.min(), 0.01) * 255)
	Image.fromarray(shade).resize((800, 800)).save(OUT / "coarse_height.png")


def main():
	buildings_json = json.loads((CAMPUS_WEB / "Buildings_features.json").read_text(encoding="utf-8"))
	parking_json = json.loads((CAMPUS_WEB / "Driveways_and_Parking_Lots_features.json").read_text(encoding="utf-8"))
	road_json = json.loads((CAMPUS_WEB / "Roadways_and_Bridges_features.json").read_text(encoding="utf-8"))
	site = json.loads((ROOT / "blueprint" / "site.json").read_text(encoding="utf-8"))
	rac = make_valid(Polygon(site["footprint"])).buffer(8)

	buildings = []
	pads = []
	for feat in buildings_json["features"]:
		attr = feat["attributes"]
		name = (attr.get("NAME") or "UNNAMED").upper().strip()
		poly = rings_to_poly(feat["geometry"].get("rings", []))
		if poly.is_empty or poly.area < 400:
			continue
		if name in SKIP_NAMES or (name in {"UNNAMED", "?"} and poly.area < 8000):
			continue
		if rac.intersects(poly) and "WEST PE" not in name:
			# Neighbour massing skips the detailed RAC.
			continue
		spec = FINISH.get(name, ("brick", 36, "academic"))
		kind = spec[2]
		if "PARKING DECK" in name:
			kind = "deck"
		centroid = poly.centroid
		buildings.append(
			{
				"id": f"b{attr['OBJECTID']}",
				"name": name.title(),
				"kind": kind,
				"finish": spec[0],
				"height": spec[1],
				"ground": 0.0,
				"levels": 4 if kind == "deck" else max(1, round(spec[1] / 12)),
				"boxes": split_boxes(poly),
				"windowSill": 4 if kind != "arena" else 18,
				"windowHead": 10 if kind != "arena" else 36,
				"_poly": poly,
			}
		)
		pads.append(poly)

	# OSM names fill gaps (West PE already in county).
	osm = load_osm_elements()
	fields = []
	for el in osm:
		tags = el.get("tags") or {}
		leisure = tags.get("leisure")
		if leisure in ("pitch", "track") or tags.get("sport") in ("american_football", "soccer", "lacrosse"):
			poly = osm_way_poly(el)
			if poly is None or poly.area < 800:
				continue
			if rac.intersects(poly):
				continue
			coords = [[round(x, 1), round(z, 1)] for x, z in poly.exterior.coords[:-1][:: max(1, len(poly.exterior.coords) // 16)]]
			sport = tags.get("sport") or "field"
			fields.append(
				{
					"id": f"f{el.get('id')}",
					"name": tags.get("name") or sport,
					"sport": sport,
					"polygon": coords,
					"box": obb_box(poly),
					"markings": field_markings(poly, sport),
				}
			)

	print("lidar heights...", flush=True)
	lidar_heights(buildings)
	for b in buildings:
		c = b["_poly"].centroid
		try:
			b["ground"] = round(float(sample_dem([c.x], [c.y])[0]), 2)
		except Exception:
			b["ground"] = 0.0
		if b["kind"] == "deck":
			b["levels"] = 4
		if b["kind"] == "academic":
			b["height"] = min(b["height"], 72)
		if b["kind"] == "arena":
			b["height"] = max(b["height"], 70)
		del b["_poly"]

	decks = [b for b in buildings if b["kind"] == "deck"]
	massing = [b for b in buildings if b["kind"] != "deck"]

	road_shapes = []
	for feat in list(road_json["features"]) + list(parking_json["features"]):
		poly = rings_to_poly(feat["geometry"].get("rings", []))
		if not poly.is_empty:
			road_shapes.append(poly)
	roads = unary_union(road_shapes).buffer(0) if road_shapes else Polygon()
	# Coarse road patches outside the fine 800 ft grid, 32 ft cells, budget.
	fx0, fz0 = FINE["x0"], FINE["z0"]
	fx1, fz1 = fx0 + FINE["nx"] * FINE["step"], fz0 + FINE["nz"] * FINE["step"]
	fine_box = box(fx0, fz0, fx1, fz1)
	outer = make_valid(roads.difference(fine_box)) if not roads.is_empty else Polygon()
	road_patches = []
	if not outer.is_empty:
		minx, minz, maxx, maxz = outer.bounds
		cs = 48.0
		x = math.floor(minx / cs) * cs
		while x < maxx and len(road_patches) < 280:
			z = math.floor(minz / cs) * cs
			while z < maxz and len(road_patches) < 280:
				cell = box(x, z, x + cs, z + cs)
				if outer.intersects(cell) and cell.intersection(outer).area > cs * cs * 0.35:
					road_patches.append({"x": x, "z": z, "w": cs, "d": cs})
				z += cs
			x += cs

	print("coarse DEM...", flush=True)
	fine = parse_fine_heights()
	pad_union = unary_union(pads) if pads else Polygon()
	h, materials, inside = coarse_grid(fine, roads, pad_union)
	data = {
		"buildings": massing + decks,
		"fields": fields,
		"decks": [{"id": d["id"], "levels": d["levels"]} for d in decks],
		"roads": road_patches,
	}
	write_luau(data, h, materials)
	comparison_image(data["buildings"], fields, decks, h)
	(OUT / "campus.json").write_text(
		json.dumps(
			{
				"buildingCount": len(data["buildings"]),
				"names": [b["name"] for b in data["buildings"]],
				"fieldCount": len(fields),
				"roadPatches": len(road_patches),
				"coarse": COARSE,
				"fine": FINE,
				"heightMin": float(h.min()),
				"heightMax": float(h.max()),
				"blendCells": int(inside.sum()),
			},
			indent=2,
		)
		+ "\n"
	)
	print(
		"buildings",
		len(data["buildings"]),
		"fields",
		len(fields),
		"roads",
		len(road_patches),
		"blend",
		int(inside.sum()),
		flush=True,
	)


if __name__ == "__main__":
	main()
