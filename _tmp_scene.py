import json, re, math
from collections import Counter

# Parse Scene.luau embedded JSON
text = open(r"src/ReplicatedStorage/RAC/Site/Scene.luau", encoding="utf-8").read()
m = re.search(r"return \[=\[(.*)\]=\]", text, re.S)
assert m, "no json"
data = json.loads(m.group(1))
site = data["site"]
print("keys", sorted(site.keys()))
print("roads", site.get("roads"))
print("areas", type(site.get("areas")), len(site.get("areas") or []))
print("trees", len(site.get("trees") or []))
print("fences", len(site.get("fences") or []))
print("details", site.get("details"))
print("budget", site.get("budget"))
print("crosswalks", site.get("crosswalks"))
print("props" in data, "props count", len(data.get("props") or []))

ent = site.get("entrance")
print("\nENTRANCE", json.dumps(ent, indent=2)[:2000] if ent else None)

plan = site.get("planimetric")
if plan:
    print("\nPLANIMETRIC keys", plan.keys())
    patches = plan.get("patches") or []
    print("patches", len(patches))
    mats = Counter(p.get("material") for p in patches)
    print("patch materials", dict(mats))
    area = Counter()
    for p in patches:
        area[p.get("material")] += p.get("w",0)*p.get("d",0)
    print("patch area ft2", {k: round(v,1) for k,v in area.items()})
    print("curbs", len(plan.get("curbs") or []))
    print("markings", len(plan.get("markings") or []))
    # bbox
    xs, zs = [], []
    for p in patches:
        xs += [p["x"], p["x"]+p["w"]]
        zs += [p["z"], p["z"]+p["d"]]
    print("patch bbox", min(xs), max(xs), min(zs), max(zs))
    asph = [p for p in patches if p.get("material")=="asphalt"]
    if asph:
        print("asphalt bbox", min(p["x"] for p in asph), max(p["x"]+p["w"] for p in asph), min(p["z"] for p in asph), max(p["z"]+p["d"] for p in asph))
        print("asphalt n", len(asph), "mean w,d", sum(p["w"] for p in asph)/len(asph), sum(p["d"] for p in asph)/len(asph))

# trees
trees = site.get("trees") or []
sp = Counter(t.get("species") for t in trees)
print("\nTREE species", dict(sp))
hs = [t["height"] for t in trees]
print("tree height min/med/max", min(hs), sorted(hs)[len(hs)//2], max(hs))
print("tree sample", trees[0])
print("pines", [t["at"] for t in trees if t.get("species")=="pine"][:10], "n", sp.get("pine"))

# fences
for i,f in enumerate(site.get("fences") or []):
    print("fence", i, "pts", len(f.get("points") or []), "h", f.get("height"), "first", f.get("points",[None])[0])

# site props
props = data.get("props") or []
kinds = Counter(p.get("kind") for p in props)
print("\nSCENE PROPS kinds", dict(kinds))
site_props = [p for p in props if str(p.get("id","")).startswith("site_") or str(p.get("kind","")).startswith("site_")]
print("site_*", len(site_props))
for p in site_props[:30]:
    print(" ", p.get("id"), p.get("kind"), p.get("at"), p.get("rotation"))

# terrain pad
t = site.get("terrain") or {}
print("\nterrain keys", t.keys() if isinstance(t, dict) else type(t))

# dump entrance related
for k in ["entrance","serviceYard","dumpsters","lots","parking"]:
    if k in site:
        print(k, str(site[k])[:400])

json.dump({"entrance": ent, "n_trees": len(trees), "species": dict(sp), "plan_keys": list(plan.keys()) if plan else None, "n_patches": len(patches) if plan else 0, "prop_kinds": dict(kinds)}, open("_tmp_scene_summary.json","w"))
print("wrote summary")
