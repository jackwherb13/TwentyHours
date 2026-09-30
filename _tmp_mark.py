import json
from collections import Counter

with open(r"tools/site_refs/markings.json", encoding="utf-8") as f:
    m = json.load(f)
print("keys", m.keys() if isinstance(m, dict) else type(m), "len" if not isinstance(m, dict) else "")
if isinstance(m, dict):
    for k,v in m.items():
        if isinstance(v, list):
            print(k, "list", len(v), "sample", str(v[0])[:200] if v else None)
        elif isinstance(v, dict):
            print(k, "dict", list(v.keys())[:20])
        else:
            print(k, type(v).__name__, v)
    feats = m.get("features") or m.get("markings") or []
else:
    feats = m
print("n features", len(feats))
kinds = Counter()
colors = Counter()
xs, zs = [], []
offgrid = Counter()
# TerrainData bounds
x0,z0,step,n = -418.5249, -580.0041, 4, 200
xmax, zmax = x0+n*step, z0+n*step
print("grid xz", x0, xmax, z0, zmax)
for feat in feats:
    kind = feat.get("kind") or feat.get("type")
    kinds[kind] += 1
    colors[feat.get("color")] += 1
    pts = feat.get("points") or feat.get("polyline") or []
    if not pts and "a" in feat:
        pts = [feat["a"], feat["b"]]
    for p in pts:
        xs.append(p[0]); zs.append(p[1])
        if p[0] < x0 or p[0] > xmax or p[1] < z0 or p[1] > zmax:
            offgrid[kind] += 1
print("kinds", dict(kinds))
print("colors", dict(colors))
if xs:
    print("bbox", min(xs), max(xs), min(zs), max(zs))
print("offgrid vertex counts by kind", dict(offgrid))

# stall bbox
stalls = [f for f in feats if (f.get("kind") or f.get("type"))=="stall"]
if stalls:
    sxs, szs = [], []
    for f in stalls:
        for p in f.get("points") or []:
            sxs.append(p[0]); szs.append(p[1])
    print("stall bbox", min(sxs), max(sxs), min(szs), max(szs), "n", len(stalls))

islands = [f for f in feats if (f.get("kind") or f.get("type"))=="island"]
print("islands", len(islands))
for i,f in enumerate(islands[:8]):
    pts = f.get("points") or []
    print(" island", i, "n", len(pts), "first", pts[0] if pts else None, "color", f.get("color"))

dy = [f for f in feats if (f.get("kind") or f.get("type"))=="double_yellow"]
print("double_yellow", len(dy))
for i,f in enumerate(dy):
    pts = f.get("points") or []
    print(" dy", i, "n", len(pts), "start", pts[0], "end", pts[-1] if pts else None)
