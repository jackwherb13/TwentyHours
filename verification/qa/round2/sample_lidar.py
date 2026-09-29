import re
from collections import Counter
from pathlib import Path

text = Path("src/ReplicatedStorage/RAC/Site/TerrainData.luau").read_text(encoding="utf-8")
m = re.search(r"x0=([-\d.]+), z0=([-\d.]+), step=(\d+), nx=(\d+), nz=(\d+)", text)
x0, z0, step, nx, nz = (float(m.group(1)), float(m.group(2)), float(m.group(3)), int(m.group(4)), int(m.group(5)))
print("grid", x0, z0, step, nx, nz)
mm = re.search(r"materials=\{(.*?)\n pad=", text, re.S)
if not mm:
    mm = re.search(r"materials=\{(.*?)\}", text, re.S)
blob = mm.group(1) if mm else ""
rows = re.findall(r'"([0-9]+)"', blob)
print("mat rows", len(rows), "len0", len(rows[0]) if rows else 0)


def sample(x, z):
    i = int((x - x0) / step)
    j = int((z - z0) / step)
    if j < 0 or j >= len(rows) or i < 0 or i >= len(rows[j]):
        return None
    return rows[j][i]


c = Counter()
for row in rows:
    c.update(row)
print("global", dict(c))
c2 = Counter()
for x in range(-350, 20, 8):
    for z in range(-270, 50, 8):
        v = sample(x, z)
        if v:
            c2[v] += 1
print("building bbox", dict(c2))
c3 = Counter()
for x in range(-400, 200, 8):
    for z in range(-580, -300, 8):
        v = sample(x, z)
        if v:
            c3[v] += 1
print("south bbox", dict(c3))
# codes: 1 Grass 2 Asphalt 3 Concrete 4 Rock 5 Ground
print("legend 1=Grass 2=Asphalt 3=Concrete 4=Rock 5=Ground")
