"""Download Esri World Imagery + USGS NAIP covering ~1200 ft around the RAC."""
from __future__ import annotations

import json
import math
from pathlib import Path

import numpy as np
import requests
from PIL import Image

from geo import inverse

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "reference" / "web" / "site"
OUT.mkdir(parents=True, exist_ok=True)

# Blueprint window: 1200 x 1200 ft, origin at south door.
X0, Z0, SPAN, PX = -500.0, -650.0, 1200.0, 2400
SCALE = SPAN / PX  # 0.5 ft/px


def sample_esri(px: int, py: int) -> Image.Image:
    corners = [inverse(x, z) for x in (X0, X0 + SPAN) for z in (Z0, Z0 + SPAN)]
    lats = [c[0] for c in corners]
    lons = [c[1] for c in corners]
    bbox = f"{min(lons)},{min(lats)},{max(lons)},{max(lats)}"
    url = "https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/export"
    params = {
        "bbox": bbox,
        "bboxSR": 4326,
        "imageSR": 4326,
        "size": f"{px},{py}",
        "format": "jpg",
        "f": "image",
        "transparent": "false",
    }
    r = requests.get(url, params=params, timeout=120)
    r.raise_for_status()
    path = OUT / "esri_export.jpg"
    path.write_bytes(r.content)
    (OUT / "esri_export.json").write_text(json.dumps({"url": url, "params": params, "bytes": len(r.content)}, indent=2))
    return Image.open(path).convert("RGB")


def warp_to_blueprint(src: Image.Image, out_name: str) -> None:
    """Nearest-neighbor sample geographic image into blueprint axes."""
    arr = np.asarray(src)
    h, w = arr.shape[:2]
    corners = [inverse(x, z) for x in (X0, X0 + SPAN) for z in (Z0, Z0 + SPAN)]
    lat_min, lat_max = min(c[0] for c in corners), max(c[0] for c in corners)
    lon_min, lon_max = min(c[1] for c in corners), max(c[1] for c in corners)
    xs = np.linspace(X0, X0 + SPAN, PX, endpoint=False)
    zs = np.linspace(Z0, Z0 + SPAN, PX, endpoint=False)
    out = np.zeros((PX, PX, 3), dtype=np.uint8)
    # Vectorized inverse is slow in python; batch by rows.
    for j, z in enumerate(zs):
        lats, lons = [], []
        for x in xs:
            lat, lon = inverse(x, z)
            lats.append(lat)
            lons.append(lon)
        col = ((np.array(lons) - lon_min) / (lon_max - lon_min) * (w - 1)).clip(0, w - 1).astype(int)
        row = ((lat_max - np.array(lats)) / (lat_max - lat_min) * (h - 1)).clip(0, h - 1).astype(int)
        out[j, :, :] = arr[row, col]
    Image.fromarray(out).save(OUT / out_name, quality=92)
    (OUT / "ortho_meta.json").write_text(
        json.dumps(
            {
                "x0": X0,
                "z0": Z0,
                "spanFt": SPAN,
                "px": PX,
                "ftPerPx": SCALE,
                "origin": "RAC south entrance door, blueprint axes",
                "trueNorthDeg": 10.43,
                "file": out_name,
            },
            indent=2,
        )
    )


def naip() -> None:
    url = "https://imagery.nationalmap.gov/arcgis/rest/services/USGSNAIPPlus/ImageServer/exportImage"
    corners = [inverse(x, z) for x in (X0, X0 + SPAN) for z in (Z0, Z0 + SPAN)]
    bbox = f"{min(c[1] for c in corners)},{min(c[0] for c in corners)},{max(c[1] for c in corners)},{max(c[0] for c in corners)}"
    params = {
        "bbox": bbox,
        "bboxSR": 4326,
        "imageSR": 4326,
        "size": "2048,2048",
        "format": "jpgpng",
        "f": "image",
    }
    r = requests.get(url, params=params, timeout=120)
    r.raise_for_status()
    (OUT / "naip_export.jpg").write_bytes(r.content)
    (OUT / "naip_export.json").write_text(json.dumps({"url": url, "params": params, "bytes": len(r.content)}, indent=2))


def main():
    print("fetch Esri", flush=True)
    img = sample_esri(2400, 2400)
    print("warp", img.size, flush=True)
    warp_to_blueprint(img, "ortho_blueprint.jpg")
    try:
        print("NAIP", flush=True)
        naip()
    except Exception as e:
        print("NAIP fail", e, flush=True)
    print("done", OUT)


if __name__ == "__main__":
    main()
