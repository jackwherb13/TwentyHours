"""Fetch Fairfax planimetrics, OSM, NAIP ortho, and facade stills for the 1600 ft campus."""
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

# 1600 x 1600 ft box, plus a collar so EagleBank Arena and the Globe sit inside.
CORNERS = [(-900, -800), (900, 1400)]
lats, lons = [], []
for x in (CORNERS[0][0], CORNERS[1][0]):
	for z in (CORNERS[0][1], CORNERS[1][1]):
		lat, lon = inverse(x, z)
		lats.append(lat)
		lons.append(lon)
BBOX = [min(lons), min(lats), max(lons), max(lats)]
(OUT / "bbox.json").write_text(json.dumps({"bbox4326": BBOX, "buildingFrameFt": CORNERS}, indent=2) + "\n")

SERVICES = {
	"Buildings": "https://services1.arcgis.com/ioennV6PpG5Xodq0/ArcGIS/rest/services/Buildings/FeatureServer/0",
	"Driveways_and_Parking_Lots": "https://services1.arcgis.com/ioennV6PpG5Xodq0/ArcGIS/rest/services/Driveways_and_Parking_Lots/FeatureServer/0",
	"Roadways_and_Bridges": "https://services1.arcgis.com/ioennV6PpG5Xodq0/ArcGIS/rest/services/Roadways_and_Bridges/FeatureServer/0",
	"Impervious": "https://services1.arcgis.com/ioennV6PpG5Xodq0/ArcGIS/rest/services/2023_Countywide_Impervious/FeatureServer/0",
}


def query_layer(name: str, url: str) -> dict:
	params = {
		"f": "json",
		"where": "1=1",
		"geometry": ",".join(map(str, BBOX)),
		"geometryType": "esriGeometryEnvelope",
		"inSR": 4326,
		"outSR": 4326,
		"spatialRel": "esriSpatialRelIntersects",
		"outFields": "*",
		"returnGeometry": "true",
		"resultRecordCount": 2000,
	}
	r = requests.get(url + "/query", params=params, timeout=90)
	r.raise_for_status()
	data = r.json()
	path = CAMPUS_WEB / f"{name}_features.json"
	path.write_text(json.dumps(data))
	print(name, len(data.get("features", [])), data.get("exceededTransferLimit"), flush=True)
	return data


def fetch_osm() -> dict:
	south, west, north, east = BBOX[1], BBOX[0], BBOX[3], BBOX[2]
	query = f"""
[out:json][timeout:90];
(
  way["building"]({south},{west},{north},{east});
  way["building:part"]({south},{west},{north},{east});
  way["leisure"~"pitch|track|sports_centre|stadium"]({south},{west},{north},{east});
  way["amenity"="parking"]({south},{west},{north},{east});
  way["highway"]({south},{west},{north},{east});
  relation["building"]({south},{west},{north},{east});
);
out geom;
"""
	r = requests.post("https://overpass-api.de/api/interpreter", data={"data": query}, timeout=120)
	r.raise_for_status()
	data = r.json()
	(CAMPUS_WEB / "osm_campus.json").write_text(json.dumps(data))
	print("OSM elements", len(data.get("elements", [])), flush=True)
	return data


def fetch_ortho() -> None:
	url = "https://imagery.nationalmap.gov/arcgis/rest/services/USGSNAIPPlus/ImageServer"
	params = {
		"f": "json",
		"bbox": ",".join(map(str, BBOX)),
		"bboxSR": 4326,
		"imageSR": 4326,
		"size": "1600,1600",
		"format": "jpgpng",
		"pixelType": "U8",
		"interpolation": "RSP_BilinearInterpolation",
		"adjustAspectRatio": "false",
	}
	r = requests.get(url + "/exportImage", params=params, timeout=90)
	r.raise_for_status()
	meta = r.json()
	(CAMPUS_WEB / "ortho_export.json").write_text(json.dumps(meta, indent=2))
	href = meta.get("href")
	if not href:
		print("ORTHO missing href", meta, flush=True)
		return
	img = requests.get(href, timeout=90)
	img.raise_for_status()
	(CAMPUS_WEB / "campus_ortho.jpg").write_bytes(img.content)
	print("ORTHO", len(img.content), flush=True)


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
		+ "\n".join(
			f"- `{row.get('file')}` — {row.get('note')} — {row.get('url')}" for row in index
		)
		+ "\n\nStreet-level colour notes (from public photos / Street View knowledge):\n"
		"- EagleBank Arena: white precast / metal panels, dark glass entries, circular plan.\n"
		"- Angel Cabrera Global Center: tan brick + glass (former Mason Inn), 5–6 stories.\n"
		"- Field House: brown brick, low gym volume, metal roof.\n"
		"- West PE Module: brown brick matching the RAC, grey metal roof.\n"
		"- Parking decks: grey poured concrete, open spandrels, steel rails.\n"
		"- RAC Field: bermuda/rye turf, white NCAA soccer/lacrosse lines.\n"
	)
	return index


def main() -> None:
	for name, url in SERVICES.items():
		try:
			query_layer(name, url)
		except Exception as exc:
			print("GIS fail", name, exc, flush=True)
	try:
		fetch_osm()
	except Exception as exc:
		print("OSM fail", exc, flush=True)
	try:
		fetch_ortho()
	except Exception as exc:
		print("ORTHO fail", exc, flush=True)
	fetch_stills()


if __name__ == "__main__":
	main()
