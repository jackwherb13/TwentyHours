"""Print room boxes and which L1 rooms have no door. Owned by the architect pass."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
layout = json.loads((ROOT / "blueprint" / "architect_layout.json").read_text(encoding="utf-8"))
for level in layout["levels"]:
    print(f"=== L{level['level']} elev {level['elevation']} rooms {len(level['rooms'])}")
    for room in level["rooms"]:
        xs = [p[0] for p in room["polygon"]]
        zs = [p[1] for p in room["polygon"]]
        print(
            f"  {room['id']:24} {room['type']:12} "
            f"x {min(xs):7.1f}..{max(xs):7.1f} w {max(xs)-min(xs):6.1f} "
            f"z {min(zs):7.1f}..{max(zs):7.1f} d {max(zs)-min(zs):6.1f} "
            f"ceil {room['ceilingHeight']}"
        )
