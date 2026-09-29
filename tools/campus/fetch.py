"""Fetch Fairfax planimetrics, OSM, NAIP ortho, and 3DEP DEM for the 3000 ft campus + 1 mi horizon."""
from __future__ import annotations

import json
import sys
from pathlib import Path

import requests

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "site"))
from prepare_site import inverse  # noqa: E402

WEB = ROOT / "reference" / "web"
CAMPUS_WEB = WEB / "campus"
CAMPUS_WEB.mkdir(parents=True, exist_ok=True)
OUT = ROOT / "verification" / "campus"
OUT.mkdir(parents=True, exist_ok=True)

# ~3,000 x 3,000 ft around the RAC entrance (origin).
CAMPUS_CORNERS = [(-1500, -1500), (1500, 1500)]
# ~1 mile (5280 ft) beyond the campus box.
HORIZON_CORNERS = [(-6780, -6780), (6780, 6780)]


def bbox_from_corners(corners):
	lats, lons = [], []
	for x in (corners[0][0], corners[1][0]):
		for z in (corners[0][1], corners[1][1]):
			lat, lon = inverse(x, z)
			lats.append(lat)
			lons.append(lon)
	return [min(lons), min(lats), max(lons), max(lats)]


BBOX = bbox_from_corners(CAMPUS_CORNERS)
HBBOX = bbox_from_corners(HORIZON_CORNERS)
(OUT / "bbox.json").write_text(
	json.dumps(
		{
			"bbox4326": BBOX,
			"horizonBbox4326": HBBOX,
			"buildingFrameFt": CAMPUS_CORNERS,
			"horizonFrameFt": HORIZON_CORNERS,
		},
		indent=2,
	)
	+ "\n"
)

SERVICES = {
	"Buildings": "https://services1.arcgis.com/ioennV6PpG5Xodq0/ArcGIS/rest/services/Buildings/FeatureServer/0",
	"Driveways_and_Parking_Lots": "https://services1.arcgis.com/ioennV6PpG5Xodq0/ArcGIS/rest/services/Driveways_and_Parking_Lots/FeatureServer/0",
	"Roadways_and_Bridges": "https://services1.arcgis.com/ioennV6PpG5Xodq0/ArcGIS/rest/services/Roadways_and_Bridges/FeatureServer/0",
	"Impervious": "https://services1.arcgis.com/ioennV6PpG5Xodq0/ArcGIS/rest/services/2023_Countywide_Impervious/FeatureServer/0",
}


def query_layer(name: str, url: str, bbox) -> dict:
	features = []
	offset = 0
	exceeded = False
	while True:
		params = {
			"f": "json",
			"where": "1=1",
			"geometry": ",".join(map(str, bbox)),
			"geometryType": "esriGeometryEnvelope",
			"inSR": 4326,
			"outSR": 4326,
			"spatialRel": "esriSpatialRelIntersects",
			"outFields": "*",
			"returnGeometry": "true",
			"resultRecordCount": 2000,
			"resultOffset": offset,
		}
		r = requests.get(url + "/query", params=params, timeout=90)
		r.raise_for_status()
		data = r.json()
		batch = data.get("features", [])
		features.extend(batch)
		exceeded = bool(data.get("exceededTransferLimit"))
		if not batch or not exceeded:
			break
		offset += len(batch)
		if offset > 20000:
			break
	out = {"features": features, "exceededTransferLimit": exceeded}
	path = CAMPUS_WEB / f"{name}_features.json"
	path.write_text(json.dumps(out))
	print(name, len(features), "exceeded", exceeded, flush=True)
	return out


def fetch_osm(bbox, dest_name: str) -> dict:
	south, west, north, east = bbox[1], bbox[0], bbox[3], bbox[2]
	query = f"""
[out:json][timeout:120];
(
  way["building"]({south},{west},{north},{east});
  way["building:part"]({south},{west},{north},{east});
  way["leisure"~"pitch|track|sports_centre|stadium"]({south},{west},{north},{east});
  way["amenity"="parking"]({south},{west},{north},{east});
  way["highway"]({south},{west},{north},{east});
  way["natural"="water"]({south},{west},{north},{east});
  way["waterway"]({south},{west},{north},{east});
  way["landuse"~"forest|meadow|grass|farmland"]({south},{west},{north},{east});
  relation["building"]({south},{west},{north},{east});
);
out geom;
"""
	r = requests.post("https://overpass-api.de/api/interpreter", data={"data": query}, timeout=180)
	r.raise_for_status()
	data = r.json()
	(CAMPUS_WEB / dest_name).write_text(json.dumps(data))
	print("OSM", dest_name, len(data.get("elements", [])), flush=True)
	return data


def fetch_ortho(bbox, size: str, dest: str) -> None:
	url = "https://imagery.nationalmap.gov/arcgis/rest/services/USGSNAIPPlus/ImageServer"
	params = {
		"f": "json",
		"bbox": ",".join(map(str, bbox)),
		"bboxSR": 4326,
		"imageSR": 4326,
		"size": size,
		"format": "jpgpng",
		"pixelType": "U8",
		"interpolation": "RSP_BilinearInterpolation",
		"adjustAspectRatio": "false",
	}
	r = requests.get(url + "/exportImage", params=params, timeout=120)
	r.raise_for_status()
	meta = r.json()
	(CAMPUS_WEB / (dest.replace(".jpg", "") + "_export.json")).write_text(json.dumps(meta, indent=2))
	href = meta.get("href")
	if not href:
		print("ORTHO missing href", dest, meta, flush=True)
		return
	img = requests.get(href, timeout=120)
	img.raise_for_status()
	(CAMPUS_WEB / dest).write_bytes(img.content)
	print("ORTHO", dest, len(img.content), flush=True)


def fetch_dem(bbox, size: str, dest: str) -> None:
	url = "https://elevation.nationalmap.gov/arcgis/rest/services/3DEPElevation/ImageServer"
	params = {
		"f": "json",
		"bbox": ",".join(map(str, bbox)),
		"bboxSR": 4326,
		"imageSR": 4326,
		"size": size,
		"format": "tiff",
		"pixelType": "F32",
		"interpolation": "RSP_BilinearInterpolation",
		"adjustAspectRatio": "false",
		"noData": "-9999",
	}
	r = requests.get(url + "/exportImage", params=params, timeout=180)
	r.raise_for_status()
	meta = r.json()
	(CAMPUS_WEB / (dest.replace(".tif", "") + "_export.json")).write_text(json.dumps(meta, indent=2))
	href = meta.get("href")
	if not href:
		print("DEM missing href", dest, meta, flush=True)
		return
	img = requests.get(href, timeout=180)
	img.raise_for_status()
	(CAMPUS_WEB / dest).write_bytes(img.content)
	print("DEM", dest, len(img.content), flush=True)


STILLS = [
	(
		"eaglebank_arena.jpg",
		"https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/Patriot_Center.jpg/1280px-Patriot_Center.jpg",
		"EagleBank Arena (Patriot Center) west facade, Wikimedia Commons",
	),
	(
		"global_center.jpg",
		"https://www.gmu.edu/sites/g/files/zskgkc261/files/styles/large/public/2022-03/global-center.jpg",
		"Angel Cabrera Global Center, GMU public photo (may 404; logged)",
	),
]


def fetch_stills() -> list[dict]:
	index = []
	for name, url, note in STILLS:
		dest = CAMPUS_WEB / name
		try:
			r = requests.get(url, timeout=30, headers={"User-Agent": "TwentyHoursCampus/1.0"})
			if r.status_code == 200 and r.content[:3] in (b"\xff\xd8\xff", b"\x89PN"):
				dest.write_bytes(r.content)
				index.append({"file": name, "url": url, "note": note, "bytes": len(r.content)})
				print("STILL", name, len(r.content), flush=True)
			else:
				index.append({"file": name, "url": url, "note": note, "status": r.status_code})
				print("STILL fail", name, r.status_code, flush=True)
		except Exception as exc:
			index.append({"file": name, "url": url, "note": note, "error": str(exc)})
			print("STILL error", name, exc, flush=True)
	(CAMPUS_WEB / "INDEX.md").write_text(
		"# Campus facade references\n\n"
		+ "\n".join(f"- `{row.get('file')}` — {row.get('note')} — {row.get('url')}" for row in index)
		+ "\n\nStreet-level colour notes (from public photos / Street View knowledge):\n"
		"- EagleBank Arena: white precast / metal panels, dark glass entries, octagonal plan.\n"
		"- Angel Cabrera Global Center (the Globe): tan brick + glass (former Mason Inn), 5–6 stories.\n"
		"- Field House: brown brick, low gym volume, metal roof.\n"
		"- West PE Module: brown brick matching the RAC, grey metal roof.\n"
		"- PV Lot General: asphalt west of the RAC / West PE Module.\n"
		"- Parking decks: grey poured concrete, open spandrels, steel rails.\n"
		"- RAC Field: bermuda/rye turf, white NCAA soccer/lacrosse lines.\n"
		"- Horizon: mixed suburban Fairfax forest, Route 123, University Mall to the east.\n"
	)
	return index


def main() -> None:
	for name, url in SERVICES.items():
		try:
			query_layer(name, url, BBOX)
		except Exception as exc:
			print("GIS fail", name, exc, flush=True)
	try:
		fetch_osm(BBOX, "osm_campus.json")
	except Exception as exc:
		print("OSM fail", exc, flush=True)
	try:
		fetch_osm(HBBOX, "osm_horizon.json")
	except Exception as exc:
		print("OSM horizon fail", exc, flush=True)
	try:
		fetch_ortho(BBOX, "2048,2048", "campus_ortho.jpg")
	except Exception as exc:
		print("ORTHO fail", exc, flush=True)
	try:
		fetch_ortho(HBBOX, "1024,1024", "horizon_ortho.jpg")
	except Exception as exc:
		print("HORIZON ORTHO fail", exc, flush=True)
	try:
		fetch_dem(HBBOX, "512,512", "horizon_3dep.tif")
	except Exception as exc:
		print("DEM fail", exc, flush=True)
	fetch_stills()


if __name__ == "__main__":
	main()
