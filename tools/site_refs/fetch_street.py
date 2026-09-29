"""Download open street-level stills of RAC-area roads into reference/web/site."""
from pathlib import Path
import json
import requests

OUT = Path("reference/web/site")
OUT.mkdir(parents=True, exist_ok=True)
index = []

# Wikimedia / public campus photos (no people as textures; we only index)
urls = [
    (
        "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/George_Mason_University_Fairfax_campus.jpg/1280px-George_Mason_University_Fairfax_campus.jpg",
        "wiki_gmu_campus.jpg",
        "GMU Fairfax campus aerial-oblique",
        "campus overview including roads",
    ),
]
headers = {"User-Agent": "TwentyHoursRAC/1.0 (research recreation; local build)"}
for url, name, loc, shows in urls:
    try:
        r = requests.get(url, headers=headers, timeout=60)
        r.raise_for_status()
        (OUT / name).write_bytes(r.content)
        index.append({"file": name, "url": url, "location": loc, "heading": "varies", "shows": shows})
        print("ok", name, len(r.content))
    except Exception as e:
        print("fail", name, e)

# Mapillary vector tile discovery (unauthenticated metadata often 401)
try:
    r = requests.get(
        "https://tiles.mapillary.com/maps/vtp/mly1_public/2/14/4674/6274",
        timeout=30,
        headers=headers,
    )
    (OUT / "mapillary_tile_status.json").write_text(
        json.dumps({"status": r.status_code, "bytes": len(r.content)}, indent=2)
    )
    print("mapillary", r.status_code)
except Exception as e:
    print("mapillary fail", e)

# Copy existing Esri export as street-context aerial
index.append(
    {
        "file": "esri_export.jpg",
        "url": "https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/export",
        "location": "RAC 1200ft window",
        "heading": "nadir",
        "shows": "Patriot Circle, Campus Dr, Mason Pond Dr, Banister lots, roundabout",
    }
)
index.append(
    {
        "file": "ortho_blueprint.jpg",
        "url": "warped from esri_export.jpg",
        "location": "blueprint frame, origin south door",
        "heading": "plan north = 10.43 deg east of true north",
        "shows": "same, axes aligned to RAC grid",
    }
)
(OUT / "INDEX.md").write_text(
    "# RAC surroundings reference\n\n"
    + "\n".join(
        f"- `{e['file']}` — {e['location']}. Heading: {e['heading']}. {e['shows']}. Source: {e['url']}"
        for e in index
    )
    + "\n\nStreet-level: Mapillary public tiles returned "
    + "auth-walled status (see mapillary_tile_status.json). "
    + "Crosswalk style taken from Esri nadir (continental/ladder bars at Patriot Circle roundabout) "
    + "and from RAC site photos IMG_0356–0360 (bike lanes + white bars on Campus Dr / Patriot Cir).\n"
)
print("index", len(index))
