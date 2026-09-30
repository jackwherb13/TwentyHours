import json, math, re
from collections import Counter

with open(r"verification/exterior/terrain_grid.json", encoding="utf-8") as f:
    g = json.load(f)
H, M = g["heights"], g["materials"]
td_x0, td_z0, step, nx, nz = -418.5249, -580.0041, 4.0, 200, 200

def samp(x, z):
    u = max(0, min(nx - 1.001, (x - td_x0) / step - 0.5))
    v = max(0, min(nz - 1.001, (z - td_z0) / step - 0.5))
    i0, j0 = int(math.floor(u)), int(math.floor(v))
    a, b = u - i0, v - j0
    i1, j1 = min(i0 + 1, nx - 1), min(j0 + 1, nz - 1)
    h = H[j0][i0]*(1-a)*(1-b)+H[j0][i1]*a*(1-b)+H[j1][i0]*(1-a)*b+H[j1][i1]*a*b
    return h, M[j0][i0], i0, j0

# Heightfield mimic
def inside_pad(x,z):
    # ray even-odd on footprint from site.json
    poly = [(-97,0),(-97,47),(-236.5,47),(-236.5,-34),(-357.5,-34),(-357.5,-81.5),(-346.5,-81.5),(-346.5,-87),(-351.5,-87),(-351.5,-220),(-225,-220),(-225,-180),(-193.5,-180),(-193.5,-279.5),(-4.5,-279.5),(-4.5,-195.5),(10,-195.5),(10,0)]
    inside=False
    j=len(poly)-1
    for i,p in enumerate(poly):
        b=poly[j]
        if ((p[1]>z)!=(b[1]>z)) and x < (b[0]-p[0])*(z-p[1])/(b[1]-p[1])+p[0]:
            inside = not inside
        j=i
    return inside

def hfield(x,z):
    if inside_pad(x,z):
        return -0.4, "pad"
    raw,_m,_,_ = samp(x,z)
    def westPad(doorX,z0,z1):
        if z<z0 or z>z1 or x>doorX+1.5 or x<doorX-40:
            return None
        dist=doorX-x
        if dist<=16:
            return 20.0
        t=max(0,min(1,(dist-16)/24))
        return 20*(1-t)+raw*t
    west = westPad(-351.5,-116,-88) or westPad(-359.5,-100,-72)
    if west is not None:
        return west, "west"
    h=raw
    note="raw"
    if x>-14 and x<20 and z>=-1 and z<35:
        flightStart=6.65; toe=30.2; drop=11*(7/12)
        walk=0.0
        if z>flightStart:
            t=max(0,min(1,(z-flightStart)/(toe-flightStart)))
            walk=-drop*t
        h=max(raw, walk-0.95)
        note="flight"
    return h, note

pts = [
    ("door",0,0),("toe",0,30.2),("apron",0,32.2),("curb_z34",0,34),
    ("street40",0,40),("WEB1",0,62),("patriot20_193",20,193.5),
    ("rbt_island",147,147),("rbt_ring",147,183),("rbt_outer",147,210),
    ("east_stall_80_30",80,30),("east_stall_70_40",70,40),("east_lot_120_20",120,20),
    ("east_lot_100_-20",100,-20),("east_road_78_40",78,40),
    ("IMG0358_-90_-360",-90,-360),("campus_dr_155_-457",155,-457),
    ("west_door",-351.5,-102.5),("west_out8",-359.5,-102.5),("west_out16",-367.5,-102.5),
    ("west_out24",-375.5,-102.5),("west_out40",-391.5,-102.5),
    ("dump",-204.5,-252),("linn_south",-175,58),("linn_court",-128,58),
    ("lotK_edge",-200,218),("SE_10_0",10,0),("south_glass_-40_0",-40,0),
    ("stair_east_14_30",14.75,30.2),("hydrant",19.15,31.6),
]
print("%-22s %14s %7s %4s %7s %s" % ("name","xz","raw","mat","H.height","note"))
for n,x,z in pts:
    raw,mat,_,_ = samp(x,z)
    hh,note = hfield(x,z)
    print("%-22s (%6.1f,%7.1f) %7.2f %3d %7.2f %s" % (n,x,z,raw,mat,hh,note))

# stall cells material
with open(r"tools/site_refs/markings.json",encoding="utf-8") as f:
    mk=json.load(f)
stall_mat=Counter()
on_grid=0; off=0
xmax,zmax=td_x0+nx*step, td_z0+nz*step
for feat in mk["features"]:
    if feat["kind"]!="stall":
        continue
    pts=feat["points"]
    mx=sum(p[0] for p in pts)/len(pts)
    mz=sum(p[1] for p in pts)/len(pts)
    if mx<td_x0 or mx>xmax or mz<td_z0 or mz>zmax:
        off+=1
        stall_mat["offgrid"]+=1
        continue
    on_grid+=1
    _h,m,_,_=samp(mx,mz)
    stall_mat[m]+=1
print("stalls on_grid",on_grid,"off",off,"mat",dict(stall_mat))

# island 0 roundabout
isl=mk["features"]
for feat in isl:
    if feat["kind"]=="island":
        pts=feat["points"]
        mx=sum(p[0] for p in pts)/len(pts); mz=sum(p[1] for p in pts)/len(pts)
        raw,mat,_,_=samp(mx,mz)
        hh,note=hfield(mx,mz)
        print("island centroid",mx,mz,"raw",raw,"mat",mat,"H",hh,note,"npts",len(pts))
