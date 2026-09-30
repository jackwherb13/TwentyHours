import json, math
from collections import Counter

with open(r"verification/exterior/terrain_grid.json", "r", encoding="utf-8") as f:
    g = json.load(f)
meta = g["meta"]
print("META GRID", json.dumps(meta.get("grid"), indent=2))
print("datum", meta.get("floorDatumFtNAVD88"))
print("datumMethod", meta.get("floorDatumMethod"))
print("hmin/max", meta.get("heightMinFt"), meta.get("heightMaxFt"))
print("classification", meta.get("classification"))
print("highSide", meta.get("highSideExit"))

H = g["heights"]
M = g["materials"]
grid = meta["grid"]
x0, z0, step, nx, nz = grid["x0"], grid["z0"], grid["step"], grid["nx"], grid["nz"]
print("grid x0,z0,step,nx,nz", x0, z0, step, nx, nz)
print("heights rows", len(H), "cols", len(H[0]))

def bilinear(H, x0, z0, x, z):
    u = max(0, min(nx - 1.001, (x - x0) / step - 0.5))
    v = max(0, min(nz - 1.001, (z - z0) / step - 0.5))
    i0, j0 = int(math.floor(u)), int(math.floor(v))
    a, b = u - i0, v - j0
    i1, j1 = min(i0 + 1, nx - 1), min(j0 + 1, nz - 1)
    h = (
        H[j0][i0] * (1 - a) * (1 - b)
        + H[j0][i1] * a * (1 - b)
        + H[j1][i0] * (1 - a) * b
        + H[j1][i1] * a * b
    )
    m = M[j0][i0]
    return h, m, i0, j0

td_x0, td_z0 = -418.5249, -580.0041

pts = [
    ("door_sill", 0, 0),
    ("flight_start", 0, 6.65),
    ("stair_mid", 0, 18),
    ("stair_toe_30.2", 0, 30.2),
    ("apron_34", 0, 34),
    ("street_40", 0, 40),
    ("WEB1_cam_0_62", 0, 62),
    ("south_lawn_80", 0, 80),
    ("south_road_100", 0, 100),
    ("south_road_160", 0, 160),
    ("patriot_dy_20_193", 20, 193.5),
    ("roundabout_island", 147, 147),
    ("roundabout_ring_177", 147, 177),
    ("roundabout_ring_183", 147, 183),
    ("east_lot_120_-50", 120, -50),
    ("east_lot_80_20", 80, 20),
    ("east_lot_160_-80", 160, -80),
    ("east_lot_180_-200", 180, -200),
    ("west_L2_door", -351.5, -102.5),
    ("west_L2_8ft", -359.5, -102.5),
    ("west_L2_16ft", -367.5, -102.5),
    ("west_L2_40ft", -391.5, -102.5),
    ("dumpster", -204.5, -252),
    ("yard_-203_-252", -203, -252),
    ("yard_-209_-252", -209, -252),
    ("IMG_0349", -175, 78),
    ("old_dumpster", -128, 58),
    ("SE_corner_10_0", 10, 0),
    ("east_glass_10_-12", 10, -12),
    ("east_glass_10_-24", 10, -24),
    ("WEB2_cam", 36, 68),
    ("WEB_pole", 78, 40),
    ("IMG_0364_cam", -28, 52),
    ("IMG_0368_cam", 22, 58),
    ("lotK_-200_300", -200, 300),
    ("lotK_-360_268", -360, 268),
    ("east_lot_120_30", 120, 30),
    ("south_lot_-80_80", -80, 80),
    ("west_lot_-280_-40", -280, -40),
]

print("loc                          xz              metaH  metaM     tdH  tdM")
for name, x, z in pts:
    hm, mm, _, _ = bilinear(H, x0, z0, x, z)
    ht, mt, _, _ = bilinear(H, td_x0, td_z0, x, z)
    print("%-26s (%7.1f,%7.1f)  %7.2f  %3d   %7.2f  %3d" % (name, x, z, hm, mm, ht, mt))

c = Counter()
for row in M:
    c.update(row)
print("material counts", dict(c), "total", sum(c.values()))

asphalt_grass_edge = 0
grass_3asphalt = 0
for j in range(1, nz - 1):
    for i in range(1, nx - 1):
        if M[j][i] == 2:
            neigh = [M[j][i - 1], M[j][i + 1], M[j - 1][i], M[j + 1][i]]
            if 1 in neigh:
                asphalt_grass_edge += 1
        if M[j][i] == 1:
            neigh = [M[j][i - 1], M[j][i + 1], M[j - 1][i], M[j + 1][i]]
            if neigh.count(2) >= 3:
                grass_3asphalt += 1
print("asphalt cells with grass 4-neigh", asphalt_grass_edge)
print("grass cells with >=3 asphalt neigh", grass_3asphalt)

# height at origin vs roundabout delta
h_door, _, _, _ = bilinear(H, td_x0, td_z0, 0, 0)
h_r, _, _, _ = bilinear(H, td_x0, td_z0, 147, 147)
h_ring, _, _, _ = bilinear(H, td_x0, td_z0, 147, 177)
h_pat, _, _, _ = bilinear(H, td_x0, td_z0, 20, 193.5)
print("door-roundabout island dH", h_r - h_door)
print("door-ring dH", h_ring - h_door)
print("door-patriot dH", h_pat - h_door)
