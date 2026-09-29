"""Retry OSM via alternate Overpass mirrors."""
from __future__ import annotations

import json
from pathlib import Path

import requests

ROOT = Path(__file__).resolve().parents[2]
CAMPUS_WEB = ROOT / "reference" / "web" / "campus"
bboxj = json.loads((ROOT / "verification" / "campus" / "bbox.json").read_text())


def fetch(bbox, dest: str) -> None:
	south, west, north, east = bbox[1], bbox[0], bbox[3], bbox[2]
	query = f"""[out:json][timeout:120];
(
  way["building"]({south},{west},{north},{east});
  way["leisure"~"pitch|track"]({south},{west},{north},{east});
  way["amenity"="parking"]({south},{west},{north},{east});
  way["highway"]({south},{west},{north},{east});
  way["landuse"~"forest|meadow|grass"]({south},{west},{north},{east});
  way["natural"~"wood|water"]({south},{west},{north},{east});
);
out geom;
"""
	urls = [
		"https://overpass.kumi.systems/api/interpreter",
		"https://overpass.private.coffee/api/interpreter",
	]
	headers = {"User-Agent": "TwentyHoursCampus/1.0"}
	for url in urls:
		try:
			r = requests.post(url, data={"data": query}, timeout=180, headers=headers)
			print(dest, url, r.status_code, len(r.content), flush=True)
			if r.status_code == 200:
				data = r.json()
				(CAMPUS_WEB / dest).write_text(json.dumps(data))
				print("saved", dest, len(data.get("elements", [])), flush=True)
				return
		except Exception as exc:
			print("fail", url, exc, flush=True)
	raise SystemExit(f"OSM failed for {dest}")


if __name__ == "__main__":
	fetch(bboxj["bbox4326"], "osm_campus.json")
	fetch(bboxj["horizonBbox4326"], "osm_horizon.json")
