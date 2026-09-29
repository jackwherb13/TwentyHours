"""Build campus massing JSON + CampusData.luau + HorizonData.luau from GIS, OSM, 3DEP."""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "site"))
sys.path.insert(0, str(ROOT / "tools" / "site" / ".vendor"))

from prepare_site import C, S, SHIFT, inverse  # noqa: E402
from shapely.geometry import LineString, Polygon, box
from shapely.ops import unary_union
from shapely import make_valid

WEB = ROOT / "reference" / "web"
CAMPUS_WEB = WEB / "campus"
OUT = ROOT / "verification" / "campus"
MODULE = ROOT / "src" / "ReplicatedStorage" / "RAC" / "Site" / "Campus"
HMODULE = ROOT / "src" / "ReplicatedStorage" / "RAC" / "Site" / "Horizon"
OUT.mkdir(parents=True, exist_ok=True)
MODULE.mkdir(parents=True, exist_ok=True)
HMODULE.mkdir(parents=True, exist_ok=True)

FLOOR = 437.92408076682665
TRUE_NORTH = 10.43
FINE = dict(x0=-418.5249, z0=-580.0041, step=4.0, nx=200, nz=200)
# 16 ft over ~3,000 x 3,000 ft around the RAC.
COARSE = dict(x0=-1504.0, z0=-1504.0, step=16.0, nx=188, nz=188)
# 32 ft over ~1 mile beyond the campus box.
HORIZON = dict(x0=-6784.0, z0=-6784.0, step=32.0, nx=424, nz=424)

SKIP_NAMES = {
	"RECREATION AND ATHLETIC COMPLEX",
	"GEORGE MASON UNIVERSITY MAIN CAMPUS",
	"UNIVERSITY MALL BUILDING G1",
	"UNIVERSITY MALL SHOPPING CENTER",
}

FINISH = {
	"EAGLE BANK ARENA": ("precast", 88, "arena"),
	"EAGLEBANK ARENA": ("precast", 88, "arena"),
	"MASON GLOBAL CENTER": ("brick", 68, "global"),
	"ANGEL CABRERA GLOBAL CENTER": ("brick", 68, "global"),
	"FIELD HOUSE": ("brick", 36, "fieldhouse"),
	"WEST PE MODULE": ("brick", 28, "westpe"),
	"PARKING DECK - MASON POND": ("precast", 42, "deck"),
	"PARKING DECK - SHENANDOAH": ("precast", 42, "deck"),
	"HARRIS THEATRE": ("brick", 42, "academic"),
	"CENTER FOR THE ARTS": ("brick", 48, "academic"),
	"PERFORMING ARTS BUILDING": ("brick", 48, "academic"),
	"STUDENT UNION I": ("brick", 52, "academic"),
	"STUDENT UNION II": ("brick", 52, "academic"),
	"MASON HALL": ("precast", 55, "academic"),
	"ROBINSON HALL A WING": ("brick", 55, "academic"),
	"ROBINSON HALL B WING": ("brick", 55, "academic"),
	"AQUIA BUILDING": ("brick", 48, "academic"),
	"KRUG HALL": ("brick", 40, "academic"),
	"THOMPSON HALL": ("brick", 40, "academic"),
	"FINLEY BUILDING": ("brick", 36, "academic"),
	"EAST BUILDING": ("brick", 32, "academic"),
	"WEST BUILDING": ("brick", 32, "academic"),
	"FINE ARTS BUILDING": ("brick", 36, "academic"),
	"JOHNSON CENTER": ("brick", 62, "academic"),
	"FENWICK LIBRARY": ("brick", 70, "academic"),
	"ENGINEERING BUILDING": ("brick", 48, "academic"),
	"NORTON HALL": ("brick", 40, "academic"),
	"DAVID KING HALL": ("brick", 48, "academic"),
	"ENTERPRISE HALL": ("brick", 52, "academic"),
	"EXPLORATORY HALL": ("brick", 55, "academic"),
	"INNOVATION HALL": ("brick", 48, "academic"),
	"RESEARCH HALL": ("brick", 48, "academic"),
	"MUSIC/THEATER BUILDING": ("brick", 44, "academic"),
	"CONCERT HALL": ("brick", 50, "academic"),
	"DE LASKI BUILDING": ("brick", 40, "academic"),
	"NORTHEAST MODULE": ("brick", 28, "academic"),
	"AQUATIC AND FITNESS CENTER": ("brick", 42, "academic"),
	"SKYLINE FITNESS": ("brick", 36, "academic"),
	"DOMINION HALL": ("brick", 48, "residence"),
	"WHETSTONE HALL": ("brick", 48, "residence"),
	"HAMILTON": ("brick", 40, "residence"),
	"ADAMS": ("brick", 40, "residence"),
	"JEFFERSON": ("brick", 40, "residence"),
	"KENNEDY": ("brick", 40, "residence"),
	"LINCOLN": ("brick", 40, "residence"),
	"ROOSEVELT": ("brick", 40, "residence"),
	"TRUMAN": ("brick", 40, "residence"),
	"WASHINGTON": ("brick", 40, "residence"),
	"WILSON": ("brick", 40, "residence"),
	"NORTHERN NECK": ("brick", 44, "residence"),
	"POTOMAC HEIGHTS": ("brick", 55, "residence"),
	"WHITLACK": ("brick", 40, "residence"),
	"COMMONWEALTH HALL": ("brick", 40, "residence"),
	"LIBERTY SQUARE": ("brick", 48, "residence"),
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


def osm_way_line(el):
	geom = el.get("geometry") or []
	if len(geom) < 2:
		return None
	x, z = grid_coordinates([p["lat"] for p in geom], [p["lon"] for p in geom])
	line = make_valid(LineString(np.column_stack((x, z))))
	return None if line.is_empty else line


def obb_box(poly: Polygon) -> dict:
	rect = poly.minimum_rotated_rectangle
	coords = np.array(rect.exterior.coords[:4])
	edges = [coords[(i + 1) % 4] - coords[i] for i in range(4)]
	long = max(edges, key=lambda e: float(np.linalg.norm(e)))
	yaw = math.atan2(long[0], long[1])
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


def split_boxes(poly: Polygon, budget: int = 5) -> list[dict]:
	poly = make_valid(poly.simplify(4.0, preserve_topology=True))
	if poly.is_empty:
		return []
	parts = [poly] if poly.geom_type == "Polygon" else [g for g in poly.geoms if g.area > 80]
	out = []

	def rec(g: Polygon, depth: int):
		if g.area < 80 or len(out) >= budget:
			return
		b = obb_box(g)
		obb_area = b["w"] * b["d"]
		if obb_area <= g.area * 1.32 or depth == 0 or min(b["w"], b["d"]) < 28:
			out.append(b)
			return
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


def load_osm_elements(name="osm_campus.json"):
	els = []
	path = CAMPUS_WEB / name
	if path.exists():
		els.extend(json.loads(path.read_text(encoding="utf-8")).get("elements", []))
	if name == "osm_campus.json":
		for extra in ("osm_rac_area.json", "osm_area.json"):
			p = ROOT / "reference" / extra
			if p.exists():
				try:
					els.extend(json.loads(p.read_text(encoding="utf-8")).get("elements", []))
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
	from shapely import contains_xy

	polys = [b["_poly"] for b in buildings]
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
			b["heightSource"] = "USGS LPC VA_NorthernVA_B22 class 6 90th percentile"
		else:
			b["heightSource"] = "typical campus massing (no lidar returns in footprint)"


def sample_dem_local(xs, zs):
	import rasterio
	from rasterio.warp import transform

	lats, lons = [], []
	for x, z in zip(xs, zs):
		lat, lon = inverse(float(x), float(z))
		lats.append(lat)
		lons.append(lon)
	e, n = transform("EPSG:4326", "EPSG:26918", lons, lats)
	path = WEB / "rac_3dep_1m.tif"
	with rasterio.open(path) as ds:
		vals = np.array([s[0] for s in ds.sample(zip(e, n))], dtype=float)
		nodata = ds.nodata
	out = vals * (1 / 0.3048) - FLOOR
	if nodata is not None:
		out = np.where(vals == nodata, np.nan, out)
	out = np.where(np.isfinite(vals) & (np.abs(vals) < 1e6), out, np.nan)
	return out


def sample_dem_horizon(xs, zs):
	tif = CAMPUS_WEB / "horizon_3dep.tif"
	if not tif.exists():
		return sample_dem_local(xs, zs)
	import rasterio

	lats, lons = [], []
	for x, z in zip(xs, zs):
		lat, lon = inverse(float(x), float(z))
		lats.append(lat)
		lons.append(lon)
	with rasterio.open(tif) as ds:
		# ImageServer export is usually EPSG:4326
		vals = np.array([s[0] for s in ds.sample(zip(lons, lats))], dtype=float)
		nodata = ds.nodata
	# 3DEP ImageServer is typically meters NAVD88
	out = vals * (1 / 0.3048) - FLOOR
	if nodata is not None:
		out = np.where(vals == nodata, np.nan, out)
	out = np.where(np.isfinite(vals) & (np.abs(vals) < 1e6) & (vals > -100) & (vals < 800), out, np.nan)
	local = sample_dem_local(xs, zs)
	return np.where(np.isfinite(out), out, local)


def parse_fine_heights():
	text = (ROOT / "src/ReplicatedStorage/RAC/Site/TerrainData.luau").read_text(encoding="utf-8")
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


def bilinear_fine(fine, xx, zz):
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
	return fine_h, inside


def classify_naip(ortho_path, bbox, xx, zz):
	"""1 grass, 2 asphalt, 3 concrete, 6 leafy, 7 water."""
	from prepare_site import FT, LAT0, LON0
	from scipy.ndimage import map_coordinates

	nz, nx = xx.shape
	mats = np.ones((nz, nx), dtype=np.uint8)
	if not ortho_path.exists() or not bbox:
		return mats
	src = np.asarray(Image.open(ortho_path).convert("RGB"))
	west, south, east, north = bbox
	wx = xx - SHIFT[0]
	wz = zz - SHIFT[1]
	e = wx * C - wz * S
	n = -wx * S - wz * C
	lats = LAT0 + n / (111320 * FT)
	lons = LON0 + e / (111320 * math.cos(math.radians(LAT0)) * FT)
	u = (lons - west) / (east - west) * (src.shape[1] - 1)
	v = (north - lats) / (north - south) * (src.shape[0] - 1)
	rgb = np.stack(
		[map_coordinates(src[:, :, k].astype(float), [v, u], order=1, mode="nearest") for k in range(3)],
		axis=2,
	)
	r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
	mx = np.maximum(np.maximum(r, g), b)
	mn = np.minimum(np.minimum(r, g), b)
	sat = (mx - mn) / np.maximum(mx, 1)
	# Water: darker blue-green
	water = (b > g + 8) & (b > r + 12) & (mx < 140)
	forest = (g > r + 12) & (g > b + 8) & (g < 110)
	field = (g > r + 6) & (g > 90) & (sat > 0.18)
	pave = (sat < 0.12) & (mx < 170) & (mx > 40)
	conc = (sat < 0.14) & (mx >= 170)
	mats[field] = 1
	mats[forest] = 6
	mats[pave] = 2
	mats[conc] = 3
	mats[water] = 7
	return mats


def coarse_grid(fine, roads, pads):
	x0, z0, step, nx, nz = (COARSE[k] for k in ("x0", "z0", "step", "nx", "nz"))
	cx = x0 + step * (np.arange(nx) + 0.5)
	cz = z0 + step * (np.arange(nz) + 0.5)
	xx, zz = np.meshgrid(cx, cz)
	h = sample_dem_local(xx.ravel(), zz.ravel()).reshape(nz, nx)
	from scipy.ndimage import gaussian_filter

	nanmask = ~np.isfinite(h)
	if nanmask.any():
		fill = np.nanmedian(h)
		h = np.where(nanmask, fill, h)
	h = gaussian_filter(h, 0.6)
	fine_h, inside = bilinear_fine(fine, xx, zz)
	h = np.where(inside, fine_h, h)
	bbox = json.loads((OUT / "bbox.json").read_text()).get("bbox4326")
	materials = classify_naip(CAMPUS_WEB / "campus_ortho.jpg", bbox, xx, zz)
	from shapely import contains_xy

	if roads is not None and not roads.is_empty:
		materials[contains_xy(roads, xx, zz)] = 2
	if pads is not None and not pads.is_empty:
		materials[contains_xy(pads, xx, zz)] = 3
	return h, materials, inside


def horizon_grid(fine, campus_h, campus_origin):
	x0, z0, step, nx, nz = (HORIZON[k] for k in ("x0", "z0", "step", "nx", "nz"))
	cx = x0 + step * (np.arange(nx) + 0.5)
	cz = z0 + step * (np.arange(nz) + 0.5)
	xx, zz = np.meshgrid(cx, cz)
	print("horizon DEM sample...", flush=True)
	h = sample_dem_horizon(xx.ravel(), zz.ravel()).reshape(nz, nx)
	from scipy.ndimage import gaussian_filter

	nanmask = ~np.isfinite(h)
	if nanmask.any():
		h = np.where(nanmask, np.nanmedian(h), h)
	h = gaussian_filter(h, 0.9)
	fine_h, inside_fine = bilinear_fine(fine, xx, zz)
	h = np.where(inside_fine, fine_h, h)
	# Stamp campus coarse so the overlap matches.
	cx0, cz0, cs, cnx, cnz = (COARSE[k] for k in ("x0", "z0", "step", "nx", "nz"))
	ui = (xx - cx0) / cs - 0.5
	vj = (zz - cz0) / cs - 0.5
	incamp = (ui >= 0) & (ui < cnx - 1) & (vj >= 0) & (vj < cnz - 1)
	i0 = np.floor(ui).astype(int)
	j0 = np.floor(vj).astype(int)
	a = ui - i0
	b = vj - j0
	ch = (
		campus_h[np.clip(j0, 0, cnz - 1), np.clip(i0, 0, cnx - 1)] * (1 - a) * (1 - b)
		+ campus_h[np.clip(j0, 0, cnz - 1), np.clip(i0 + 1, 0, cnx - 1)] * a * (1 - b)
		+ campus_h[np.clip(j0 + 1, 0, cnz - 1), np.clip(i0, 0, cnx - 1)] * (1 - a) * b
		+ campus_h[np.clip(j0 + 1, 0, cnz - 1), np.clip(i0 + 1, 0, cnx - 1)] * a * b
	)
	h = np.where(incamp, ch, h)
	hbbox = json.loads((OUT / "bbox.json").read_text()).get("horizonBbox4326")
	materials = classify_naip(CAMPUS_WEB / "horizon_ortho.jpg", hbbox, xx, zz)
	return h, materials, incamp


def field_markings(poly: Polygon, sport: str) -> list[dict]:
	b = obb_box(poly)
	cx, cz, w, d, yaw = b["x"], b["z"], b["w"], b["d"], b["yaw"]
	marks = []

	def local(lx, lz):
		s, c = math.sin(yaw), math.cos(yaw)
		return [round(cx + s * lz + c * lx, 2), round(cz + c * lz - s * lx, 2)]

	hw, hd = w / 2, d / 2
	for lx in (-hw + 1, hw - 1):
		marks.append({"a": local(lx, -hd + 1), "b": local(lx, hd - 1), "w": 0.4})
	for lz in (-hd + 1, hd - 1):
		marks.append({"a": local(-hw + 1, lz), "b": local(hw - 1, lz), "w": 0.4})
	marks.append({"a": local(-hw + 1, 0), "b": local(hw - 1, 0), "w": 0.4})
	if sport in ("american_football", "football"):
		for yds in range(-40, 50, 10):
			lz = yds * (d / 120.0)
			if abs(lz) < hd - 4:
				marks.append({"a": local(-hw + 4, lz), "b": local(hw - 4, lz), "w": 0.3})
	else:
		r = min(30, hw * 0.25)
		pts = [local(r * math.sin(k * math.pi / 4), r * math.cos(k * math.pi / 4)) for k in range(8)]
		for a, bpt in zip(pts, pts[1:] + pts[:1]):
			marks.append({"a": a, "b": bpt, "w": 0.3})
	return marks


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


def write_height_block(h, materials, meta, extra_lines):
	nx, nz = meta["nx"], meta["nz"]
	ymin = math.floor((float(np.nanmin(h)) - 12) / 4) * 4
	ymax = math.ceil((float(np.nanmax(h)) + 12) / 4) * 4
	lines = [
		"--!strict",
		"-- Generated by tools/campus/prepare.py. Do not edit by hand.",
		"return {",
		f"\tfine = {{ x0 = {FINE['x0']}, z0 = {FINE['z0']}, step = {FINE['step']}, nx = {FINE['nx']}, nz = {FINE['nz']} }},",
		f"\tcampus = {{ x0 = {COARSE['x0']}, z0 = {COARSE['z0']}, step = {COARSE['step']}, nx = {COARSE['nx']}, nz = {COARSE['nz']} }},",
		f"\tx0 = {meta['x0']}, z0 = {meta['z0']}, step = {meta['step']}, nx = {nx}, nz = {nz}, yMin = {ymin}, yMax = {ymax},",
		"\trows = {",
	]
	for row in h:
		lines.append('\t\t"' + ",".join(str(int(round(float(v) * 100))) for v in row) + '",')
	lines += ["\t},", "\tmaterials = {"]
	for row in materials:
		lines.append('\t\t"' + "".join(str(int(v)) for v in row) + '",')
	lines.append("\t},")
	lines.extend(extra_lines)
	lines.append("}")
	return "\n".join(lines) + "\n", ymin, ymax


def parking_stalls(lot_box: dict, n: int = 8) -> list[dict]:
	cx, cz, w, d, yaw = lot_box["x"], lot_box["z"], lot_box["w"], lot_box["d"], lot_box["yaw"]
	long = max(w, d)
	short = min(w, d)
	# Merged long stall stripes parallel to the short axis.
	stripes = []
	count = max(3, min(n, int(long / 36)))
	for i in range(1, count):
		t = i / count
		off = (t - 0.5) * long
		if w >= d:
			lx, lz = off, 0
			sw, sd = 0.35, short - 6
		else:
			lx, lz = 0, off
			sw, sd = short - 6, 0.35
		s, c = math.sin(yaw), math.cos(yaw)
		stripes.append(
			{
				"x": round(cx + s * lz + c * lx, 2),
				"z": round(cz + c * lz - s * lx, 2),
				"w": round(max(sw, 0.3), 2),
				"d": round(max(sd, 0.3), 2),
				"yaw": yaw,
			}
		)
	return stripes


def lane_segments(line: LineString, width=0.35) -> list[dict]:
	coords = list(line.simplify(18).coords)
	segs = []
	for a, b in zip(coords, coords[1:]):
		ax, az = a
		bx, bz = b
		dx, dz = bx - ax, bz - az
		length = math.hypot(dx, dz)
		if length < 24:
			continue
		yaw = math.atan2(dx, dz)
		segs.append(
			{
				"x": round((ax + bx) / 2, 2),
				"z": round((az + bz) / 2, 2),
				"len": round(length, 2),
				"w": width,
				"yaw": round(yaw, 4),
			}
		)
	return segs


def comparison_image(buildings, fields, lots, h):
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
		from scipy.ndimage import map_coordinates

		yy, xx = np.mgrid[0:height, 0:width]
		wx = x0 + xx / (width - 1) * (x1 - x0) - SHIFT[0]
		wz = z0 + yy / (height - 1) * (z1 - z0) - SHIFT[1]
		e = wx * C - wz * S
		n = -wx * S - wz * C
		lats = LAT0 + n / (111320 * FT)
		lons = LON0 + e / (111320 * math.cos(math.radians(LAT0)) * FT)
		u = (lons - west) / (east - west) * (src.shape[1] - 1)
		v = (north - lats) / (north - south) * (src.shape[0] - 1)
		rgb = np.stack(
			[map_coordinates(src[:, :, k].astype(float), [v, u], order=1, mode="nearest") for k in range(3)],
			axis=2,
		)
		left = Image.fromarray(np.uint8(np.clip(rgb, 0, 255)))
	else:
		left = Image.new("RGB", (width, height), (40, 70, 40))
	right = left.copy()
	draw = ImageDraw.Draw(right, "RGBA")
	for lot in lots:
		boxp = lot["box"]
		s, c = math.sin(boxp["yaw"]), math.cos(boxp["yaw"])
		hw, hd = boxp["w"] / 2, boxp["d"] / 2
		cx, cz = boxp["x"], boxp["z"]
		corners = [px(cx + s * lz + c * lx, cz + c * lz - s * lx) for lx, lz in ((-hw, -hd), (hw, -hd), (hw, hd), (-hw, hd))]
		draw.polygon(corners, fill=(50, 50, 52, 140), outline=(30, 30, 30, 255))
	for b in buildings:
		for boxp in b["boxes"]:
			s, c = math.sin(boxp["yaw"]), math.cos(boxp["yaw"])
			hw, hd = boxp["w"] / 2, boxp["d"] / 2
			cx, cz = boxp["x"], boxp["z"]
			corners = [px(cx + s * lz + c * lx, cz + c * lz - s * lx) for lx, lz in ((-hw, -hd), (hw, -hd), (hw, hd), (-hw, hd))]
			color = (200, 180, 140, 160) if b["kind"] != "deck" else (150, 150, 155, 180)
			if b["kind"] == "arena":
				color = (230, 230, 225, 180)
			if b["kind"] == "global":
				color = (180, 140, 90, 180)
			draw.polygon(corners, fill=color, outline=(20, 20, 20, 255))
	for f in fields:
		poly = [px(p[0], p[1]) for p in f["polygon"]]
		if len(poly) >= 3:
			draw.polygon(poly, fill=(40, 120, 50, 120), outline=(240, 240, 240, 255))
	pair = Image.new("RGB", (width * 2 + 40, height + 60), (250, 250, 250))
	pair.paste(left, (10, 50))
	pair.paste(right, (width + 30, 50))
	td = ImageDraw.Draw(pair)
	td.text(
		(12, 12),
		"LEFT NAIP ortho   RIGHT low-detail campus (RAC, PV Lot, Globe, EagleBank Arena)  +X east +Z south",
		fill=(0, 0, 0),
	)
	pair.save(OUT / "plan_comparison.png")
	shade = np.uint8((h - h.min()) / max(h.max() - h.min(), 0.01) * 255)
	Image.fromarray(shade).resize((800, 800)).save(OUT / "coarse_height.png")


def horizon_comparison(silhouettes, trees, hh):
	ortho = CAMPUS_WEB / "horizon_ortho.jpg"
	x0, z0, step, nx, nz = (HORIZON[k] for k in ("x0", "z0", "step", "nx", "nz"))
	width, height = 1024, 1024
	x1, z1 = x0 + nx * step, z0 + nz * step

	def px(x, z):
		u = (x - x0) / (x1 - x0) * (width - 1)
		v = (z - z0) / (z1 - z0) * (height - 1)
		return (int(u), int(v))

	if ortho.exists():
		src = np.asarray(Image.open(ortho).convert("RGB"))
		bbox = json.loads((OUT / "bbox.json").read_text()).get("horizonBbox4326")
		west, south, east, north = bbox
		from prepare_site import FT, LAT0, LON0
		from scipy.ndimage import map_coordinates

		yy, xx = np.mgrid[0:height, 0:width]
		wx = x0 + xx / (width - 1) * (x1 - x0) - SHIFT[0]
		wz = z0 + yy / (height - 1) * (z1 - z0) - SHIFT[1]
		e = wx * C - wz * S
		n = -wx * S - wz * C
		lats = LAT0 + n / (111320 * FT)
		lons = LON0 + e / (111320 * math.cos(math.radians(LAT0)) * FT)
		u = (lons - west) / (east - west) * (src.shape[1] - 1)
		v = (north - lats) / (north - south) * (src.shape[0] - 1)
		rgb = np.stack(
			[map_coordinates(src[:, :, k].astype(float), [v, u], order=1, mode="nearest") for k in range(3)],
			axis=2,
		)
		left = Image.fromarray(np.uint8(np.clip(rgb, 0, 255)))
	else:
		left = Image.new("RGB", (width, height), (50, 80, 50))
	right = left.copy()
	draw = ImageDraw.Draw(right, "RGBA")
	cx0, cz0 = COARSE["x0"], COARSE["z0"]
	cx1 = cx0 + COARSE["nx"] * COARSE["step"]
	cz1 = cz0 + COARSE["nz"] * COARSE["step"]
	draw.rectangle([px(cx0, cz0), px(cx1, cz1)], outline=(255, 220, 40, 255), width=2)
	for s in silhouettes:
		b = s["box"]
		hw, hd = b["w"] / 2, b["d"] / 2
		sn, c = math.sin(b["yaw"]), math.cos(b["yaw"])
		corners = [
			px(b["x"] + sn * lz + c * lx, b["z"] + c * lz - sn * lx)
			for lx, lz in ((-hw, -hd), (hw, -hd), (hw, hd), (-hw, hd))
		]
		draw.polygon(corners, fill=(160, 150, 140, 160), outline=(20, 20, 20, 200))
	for t in trees:
		r = int(max(2, t["r"] / ((x1 - x0) / width)))
		draw.ellipse([px(t["x"] - t["r"], t["z"] - t["r"]), px(t["x"] + t["r"], t["z"] + t["r"])], fill=(30, 80, 40, 120))
	pair = Image.new("RGB", (width * 2 + 30, height + 50), (250, 250, 250))
	pair.paste(left, (8, 40))
	pair.paste(right, (width + 22, 40))
	ImageDraw.Draw(pair).text((10, 10), "LEFT NAIP ~1 mi  RIGHT horizon silhouettes + tree masses (campus box in yellow)", fill=(0, 0, 0))
	pair.save(OUT / "horizon_comparison.png")
	shade = np.uint8((hh - hh.min()) / max(hh.max() - hh.min(), 0.01) * 255)
	Image.fromarray(shade).resize((800, 800)).save(OUT / "horizon_height.png")


def campus_extent_poly():
	x0, z0 = COARSE["x0"], COARSE["z0"]
	x1 = x0 + COARSE["nx"] * COARSE["step"]
	z1 = z0 + COARSE["nz"] * COARSE["step"]
	return box(x0, z0, x1, z1)


def main():
	buildings_json = json.loads((CAMPUS_WEB / "Buildings_features.json").read_text(encoding="utf-8"))
	parking_json = json.loads((CAMPUS_WEB / "Driveways_and_Parking_Lots_features.json").read_text(encoding="utf-8"))
	road_json = json.loads((CAMPUS_WEB / "Roadways_and_Bridges_features.json").read_text(encoding="utf-8"))
	site = json.loads((ROOT / "blueprint" / "site.json").read_text(encoding="utf-8"))
	rac = make_valid(Polygon(site["footprint"])).buffer(8)
	camp = campus_extent_poly()

	buildings = []
	pads = []
	for feat in buildings_json["features"]:
		attr = feat["attributes"]
		name = (attr.get("NAME") or "UNNAMED").upper().strip()
		poly = rings_to_poly(feat["geometry"].get("rings", []))
		if poly.is_empty or poly.area < 500:
			continue
		if name in SKIP_NAMES:
			continue
		if not camp.intersects(poly):
			continue
		if rac.intersects(poly) and "WEST PE" not in name:
			continue
		if name in {"UNNAMED", "?"} and poly.area < 2500:
			continue
		spec = FINISH.get(name)
		if spec is None:
			# Fuzzy match
			spec = ("brick", 36, "academic")
			for key, val in FINISH.items():
				if key in name or name in key:
					spec = val
					break
			if "HALL" in name or "HOUSE" in name or "SQUARE" in name:
				if spec[2] == "academic" and name not in FINISH:
					spec = ("brick", 42, "residence")
			if "PARKING DECK" in name or "PARKING GARAGE" in name:
				spec = ("precast", 42, "deck")
		kind = spec[2]
		if "PARKING DECK" in name:
			kind = "deck"
		buildings.append(
			{
				"id": f"b{attr['OBJECTID']}",
				"name": name.title(),
				"kind": kind,
				"finish": spec[0],
				"height": spec[1],
				"ground": 0.0,
				"levels": 4 if kind == "deck" else max(1, round(spec[1] / 12)),
				"boxes": split_boxes(poly, 4 if kind != "arena" else 1),
				"windowSill": 18 if kind == "arena" else 4,
				"windowHead": 36 if kind == "arena" else 10,
				"_poly": poly,
			}
		)
		pads.append(poly)

	osm = load_osm_elements()
	fields = []
	lots = []
	named_highways = []
	for el in osm:
		tags = el.get("tags") or {}
		leisure = tags.get("leisure")
		if leisure in ("pitch", "track") or tags.get("sport") in ("american_football", "soccer", "lacrosse"):
			poly = osm_way_poly(el)
			if poly is None or poly.area < 800:
				continue
			if rac.intersects(poly) or not camp.intersects(poly):
				continue
			coords = [
				[round(x, 1), round(z, 1)]
				for x, z in poly.exterior.coords[:-1][:: max(1, len(poly.exterior.coords) // 16)]
			]
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
		if tags.get("amenity") == "parking" or tags.get("parking") == "surface":
			poly = osm_way_poly(el)
			if poly is None or poly.area < 4000:
				continue
			if rac.intersects(poly) or not camp.intersects(poly):
				continue
			hits_field = False
			for field in fields:
				if poly.intersects(Polygon([(p[0], p[1]) for p in field["polygon"]])):
					hits_field = True
					break
			if hits_field:
				continue
			nm = (tags.get("name") or "").lower()
			kind = "pv" if "pv" in nm else "lot"
			boxp = obb_box(poly)
			if max(boxp["w"], boxp["d"]) > 360 or boxp["w"] * boxp["d"] > 85000:
				continue
			lots.append(
				{
					"id": f"p{el.get('id')}",
					"name": tags.get("name") or "Parking",
					"kind": kind,
					"box": boxp,
					"stripes": parking_stalls(boxp, 10 if kind == "pv" else 6),
				}
			)
		hwy = tags.get("highway")
		if hwy in ("primary", "secondary", "tertiary", "residential", "unclassified"):
			line = osm_way_line(el)
			if line is None:
				continue
			nm = (tags.get("name") or "").lower()
			keep_names = (
				"campus drive",
				"patriot circle",
				"mason pond",
				"ox road",
				"ox rd",
				"route 123",
				"global",
				"banister",
				"university drive",
				"shenandoah",
			)
			if any(k in nm for k in keep_names) or hwy in ("primary", "secondary"):
				clip = line.intersection(camp)
				if not clip.is_empty:
					named_highways.append(clip)

	print("lidar heights...", flush=True)
	lidar_heights(buildings)
	for b in buildings:
		c = b["_poly"].centroid
		try:
			b["ground"] = round(float(sample_dem_local([c.x], [c.y])[0]), 2)
		except Exception:
			b["ground"] = 0.0
		if b["kind"] == "deck":
			b["levels"] = 4
		if b["kind"] in ("academic", "residence"):
			b["height"] = min(b["height"], 72)
		if b["kind"] == "arena":
			b["height"] = max(b["height"], 70)
			# Force a near-square so the builder can octagon it.
			if b["boxes"]:
				bb = b["boxes"][0]
				s = max(bb["w"], bb["d"]) * 0.92
				bb["w"], bb["d"] = s, s
		del b["_poly"]

	def overlaps_field(boxp):
		for field in fields:
			fb = field["box"]
			if abs(fb["x"] - boxp["x"]) < (fb["w"] + boxp["w"]) * 0.35 and abs(fb["z"] - boxp["z"]) < (fb["d"] + boxp["d"]) * 0.35:
				return True
		return False

	lots = [lot for lot in lots if not overlaps_field(lot["box"])]

	# County parking lots as asphalt pads if OSM missed PV Lot.
	for feat in parking_json["features"]:
		poly = rings_to_poly(feat["geometry"].get("rings", []))
		if poly.is_empty or poly.area < 8000:
			continue
		if rac.intersects(poly) or not camp.intersects(poly):
			continue
		boxp = obb_box(poly)
		# Skip if already covered.
		dup = False
		for lot in lots:
			if abs(lot["box"]["x"] - boxp["x"]) < 40 and abs(lot["box"]["z"] - boxp["z"]) < 40:
				dup = True
				break
		if dup:
			continue
		if overlaps_field(boxp):
			continue
		if max(boxp["w"], boxp["d"]) > 360 or boxp["w"] * boxp["d"] > 85000:
			continue
		attr = feat.get("attributes") or {}
		nm = str(attr.get("NAME") or attr.get("LOT_NAME") or "Parking lot")
		kind = "pv" if "pv" in nm.lower() or (boxp["x"] < -80 and abs(boxp["z"]) < 400) else "lot"
		lots.append(
			{
				"id": f"c{attr.get('OBJECTID', len(lots))}",
				"name": nm,
				"kind": kind,
				"box": boxp,
				"stripes": parking_stalls(boxp, 10 if kind == "pv" else 5),
			}
		)

	road_shapes = []
	for feat in list(road_json["features"]) + list(parking_json["features"]):
		poly = rings_to_poly(feat["geometry"].get("rings", []))
		if not poly.is_empty:
			road_shapes.append(poly)
	roads = unary_union(road_shapes).buffer(0) if road_shapes else Polygon()
	fx0, fz0 = FINE["x0"], FINE["z0"]
	fx1, fz1 = fx0 + FINE["nx"] * FINE["step"], fz0 + FINE["nz"] * FINE["step"]
	fine_box = box(fx0, fz0, fx1, fz1)

	def in_fine(boxp):
		return fine_box.intersects(box(boxp["x"] - boxp["w"] / 2, boxp["z"] - boxp["d"] / 2, boxp["x"] + boxp["w"] / 2, boxp["z"] + boxp["d"] / 2))

	lots = [lot for lot in lots if not in_fine(lot["box"]) and not rac.intersects(box(lot["box"]["x"] - 4, lot["box"]["z"] - 4, lot["box"]["x"] + 4, lot["box"]["z"] + 4))]
	fields = [f for f in fields if not in_fine(f["box"])]
	outer = make_valid(roads.difference(fine_box)) if not roads.is_empty else Polygon()
	road_patches = []
	if not outer.is_empty:
		minx, minz, maxx, maxz = outer.bounds
		cs = 64.0
		x = math.floor(minx / cs) * cs
		while x < maxx and len(road_patches) < 420:
			z = math.floor(minz / cs) * cs
			while z < maxz and len(road_patches) < 420:
				cell = box(x, z, x + cs, z + cs)
				if outer.intersects(cell) and cell.intersection(outer).area > cs * cs * 0.32:
					road_patches.append({"x": x, "z": z, "w": cs, "d": cs})
				z += cs
			x += cs

	lanes = []
	for line in named_highways:
		geoms = [line] if line.geom_type == "LineString" else list(getattr(line, "geoms", []))
		for g in geoms:
			if g.geom_type != "LineString":
				continue
			# Drop segments inside the fine box (county markings live there).
			clip = g.difference(fine_box)
			parts = [clip] if clip.geom_type == "LineString" else list(getattr(clip, "geoms", []))
			for p in parts:
				if p.geom_type == "LineString":
					lanes.extend(lane_segments(p))
	lanes = lanes[:180]

	print("coarse DEM...", flush=True)
	fine = parse_fine_heights()
	pad_union = unary_union(pads) if pads else Polygon()
	h, materials, inside = coarse_grid(fine, roads, pad_union)

	payload = []
	for b in buildings:
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
	data = {
		"buildings": payload,
		"fields": fields,
		"lots": lots,
		"lanes": lanes,
		"roads": road_patches,
	}
	extra = [
		"\tbuildings = " + luau(payload) + ",",
		"\tfields = " + luau(fields) + ",",
		"\tlots = " + luau(lots) + ",",
		"\tlanes = " + luau(lanes) + ",",
		"\troads = " + luau(road_patches) + ",",
	]
	text, ymin, ymax = write_height_block(h, materials, COARSE, extra)
	(MODULE / "CampusData.luau").write_text(text, encoding="utf-8")
	comparison_image(payload, fields, lots, h)

	# Horizon silhouettes: OSM buildings outside campus, inside horizon, large only.
	print("horizon grid...", flush=True)
	hh, hmats, incamp = horizon_grid(fine, h, COARSE)
	horizon_osm = load_osm_elements("osm_horizon.json")
	if not horizon_osm:
		horizon_osm = osm
	hx0, hz0 = HORIZON["x0"], HORIZON["z0"]
	hx1 = hx0 + HORIZON["nx"] * HORIZON["step"]
	hz1 = hz0 + HORIZON["nz"] * HORIZON["step"]
	hring = box(hx0, hz0, hx1, hz1).difference(camp.buffer(80))
	silhouettes = []
	trees = []
	for el in horizon_osm:
		tags = el.get("tags") or {}
		if tags.get("building"):
			poly = osm_way_poly(el)
			if poly is None or poly.area < 6000:
				continue
			if not hring.intersects(poly):
				continue
			b = obb_box(poly)
			if min(b["w"], b["d"]) < 30:
				continue
			silhouettes.append(
				{
					"id": f"h{el.get('id')}",
					"box": b,
					"height": 28 if poly.area < 20000 else 42,
					"finish": "precast",
				}
			)
		if tags.get("landuse") in ("forest",) or tags.get("natural") in ("wood",):
			poly = osm_way_poly(el)
			if poly is None or not hring.intersects(poly):
				continue
			c = poly.centroid
			r = min(180, math.sqrt(poly.area) * 0.25)
			if r > 40:
				trees.append({"x": round(c.x, 1), "z": round(c.y, 1), "r": round(r, 1), "h": 40})
	# Tree blobs from leafy cells, clustered.
	leaf = np.argwhere(hmats == 6)
	rng = np.random.default_rng(20)
	if len(leaf):
		pick = leaf[rng.choice(len(leaf), size=min(80, len(leaf)), replace=False)]
		for j, i in pick:
			x = HORIZON["x0"] + (i + 0.5) * HORIZON["step"]
			z = HORIZON["z0"] + (j + 0.5) * HORIZON["step"]
			if camp.buffer(120).covers(box(x - 1, z - 1, x + 1, z + 1)):
				continue
			trees.append({"x": round(float(x), 1), "z": round(float(z), 1), "r": 48.0, "h": 36})
	silhouettes = silhouettes[:40]
	trees = trees[:90]
	hextra = [
		"\tsilhouettes = " + luau(silhouettes) + ",",
		"\ttrees = " + luau(trees) + ",",
		"\tfog = { density = 0.28, offset = 220, color = {0.72, 0.76, 0.80}, haze = 0.55, glares = 0.12 },",
	]
	htext, hymin, hymax = write_height_block(hh, hmats, HORIZON, hextra)
	(HMODULE / "HorizonData.luau").write_text(htext, encoding="utf-8")
	horizon_comparison(silhouettes, trees, hh)

	(OUT / "campus.json").write_text(
		json.dumps(
			{
				"buildingCount": len(payload),
				"names": [b["name"] for b in payload],
				"fieldCount": len(fields),
				"lotCount": len(lots),
				"laneCount": len(lanes),
				"roadPatches": len(road_patches),
				"coarse": COARSE,
				"horizon": HORIZON,
				"fine": FINE,
				"heightMin": float(h.min()),
				"heightMax": float(h.max()),
				"blendCells": int(inside.sum()),
				"horizonBlendCells": int(incamp.sum()),
				"silhouettes": len(silhouettes),
				"trees": len(trees),
				"horizonY": [hymin, hymax],
			},
			indent=2,
		)
		+ "\n"
	)
	print(
		"buildings",
		len(payload),
		"fields",
		len(fields),
		"lots",
		len(lots),
		"lanes",
		len(lanes),
		"roads",
		len(road_patches),
		"blend",
		int(inside.sum()),
		"silhouettes",
		len(silhouettes),
		"trees",
		len(trees),
		flush=True,
	)


if __name__ == "__main__":
	main()
