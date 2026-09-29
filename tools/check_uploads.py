"""Fail when a PBR map on disk differs from the one uploaded to Roblox (Studio would silently show the old texture).

art/materials/assets.json records, per material, the sha256 of each map at upload time ("sha256": {"file": ..., "normal": ..., "roughness": ...}).

  python tools/check_uploads.py                 # check; exit 1 on any stale/unrecorded map
  python tools/check_uploads.py --record maple  # after uploading maple's maps and writing the new ids, record their hashes
  python tools/check_uploads.py --record all

To fix a FAIL: serve art/materials/pbr over http (python -m http.server), upload the changed maps with the Studio MCP
upload_image tool, write the new rbxassetid values into art/materials/assets.json, src/ReplicatedStorage/RAC/Materials.luau and
src/MaterialService/RAC_<name>.model.json, then run --record <name>.
"""

import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "art/materials/assets.json"
KINDS = ("file", "normal", "roughness")


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    assets = json.loads(ASSETS.read_text(encoding="utf-8"))
    if len(sys.argv) >= 3 and sys.argv[1] == "--record":
        keys = list(assets) if sys.argv[2] == "all" else sys.argv[2:]
        for key in keys:
            entry = assets[key]
            entry["sha256"] = {k: sha(ROOT / entry[k]) for k in KINDS if entry.get(k) and (ROOT / entry[k]).exists()}
            print(f"recorded {key}")
        ASSETS.write_text(json.dumps(assets, indent=2) + "\n", encoding="utf-8")
        return 0

    stale = []
    for key, entry in assets.items():
        recorded = entry.get("sha256", {})
        for kind in KINDS:
            rel = entry.get(kind)
            if not rel or not (ROOT / rel).exists():
                continue
            if recorded.get(kind) != sha(ROOT / rel):
                stale.append(f"{key}.{kind} ({rel})")
    if stale:
        print(f"FAIL {len(stale)} PBR maps changed since upload (Studio still shows the old ones):")
        for s in stale:
            print(f"  {s}")
        print("Upload them via Studio MCP upload_image, update the ids, then: python tools/check_uploads.py --record <material>")
        return 1
    print(f"ok all PBR maps of {len(assets)} materials match their uploaded versions")
    return 0


if __name__ == "__main__":
    sys.exit(main())
