# Round 1 offline exterior QA — GMU RAC

Independent review. Did **not** edit `blueprint/`, `src/`, or the RAC model.

**Build this folder claims:** `verification/qa/round1/build.txt` — walkthrough PASS, 24960 parts, SiteContext 5812, geometry 0 issues. `tools/check_geometry.luau` still skips any path/name containing `slab` / `canopy` / `rail`, so **PASS is not exterior proof**.

**Stale pixels (do not close items from them):**
- `verification/qa/round1/pairs/` — WEB_entrance_1 is shot from **inside the lobby**; WEB_entrance_2 / IMG_0364 look at the **east curtain**, not the south door. Cameras did not match `photo_stations.json`.
- `verification/qa/round2-fix/` — older kit (ball trees, gapped canopy, tiled plaza).
- `verification/qa/round5/` and `round6/` — interior-heavy; used only as clues (west grade, interior “service yard” dumpsters). **Not this round’s evidence.**

Primary evidence is current code + blueprint + lidar samples (TerrainData / Heightfield, 2026-09-29).

---

## 1. Exterior photo stations (`blueprint/photo_stations.json`)

All listed stations are `confidence: estimated` (“not photographically solved”). Y is **not** on lidar (eye should be ~H.height+5.2). Several IMG_0362–0367 poses sit **north of z=0** (inside / behind the south wall).

`look_at = position + look * 40` (look left as authored; already ~unit).

| id | position [x,y,z] ft | look | look_at (pos+40·look) | note |
|---|---|---|---|---|
| IMG_0349 | -175, 6.0, 78 | 0.25, 0.08, -0.96 | -165.0, 9.2, 39.6 | service yard, south side |
| IMG_0350 | -55, 5.2, 158 | -0.287, 0.0, -0.958 | -66.48, 5.2, 119.68 | service ramp and brick |
| IMG_0351 | 15, 5.2, 98 | -1.0, 0.0, 0.0 | -25.0, 5.2, 98.0 | east service side, metal panel and brick |
| IMG_0352 | 25, 5.2, -62 | -1.0, 0.0, 0.0 | -15.0, 5.2, -62.0 | east lawn toward the entrance |
| IMG_0353 | -415, 5.2, -62 | 1.0, 0.0, 0.0 | -375.0, 5.2, -62.0 | west approach |
| IMG_0354 | -435, 5.2, -182 | 0.958, 0.0, 0.287 | -396.68, 5.2, -170.52 | rock swale west of the cage |
| IMG_0355 | -465, 5.2, -142 | 1.0, 0.0, 0.0 | -425.0, 5.2, -142.0 | swale and the west brick wall |
| IMG_0356 | 65, 5.2, 78 | -0.981, 0.0, -0.196 | 25.76, 5.2, 70.16 | road, east of the building |
| IMG_0357 | 45, 5.2, 118 | -0.447, 0.0, -0.894 | 27.12, 5.2, 82.24 | crosswalk south-east |
| IMG_0358 | -90, 4.0, -360 | 0.0, 0.12, 1.0 | -90.0, 8.8, -320.0 | “east road, metal-panel facade” — **XY is north of the gym, not east** |
| IMG_0359 | 75, 5.2, 38 | -0.928, 0.0, -0.371 | 37.88, 5.2, 23.16 | east road looking northwest |
| IMG_0360 | 55, 5.2, 138 | -0.371, 0.0, -0.928 | 40.16, 5.2, 100.88 | south-east corner from the road |
| IMG_0361 | -315, 5.2, 178 | 0.0, 0.0, -1.0 | -315.0, 5.2, 138.0 | south lawn looking north |
| IMG_0362 | 5, 5.2, -72 | -0.999, 0.05, 0.0 | -34.96, 7.2, -72.0 | “canopy from the east” but **z=-72 is inside** |
| IMG_0363 | 1, 5.2, -94 | -0.995, 0.10, 0.0 | -38.8, 9.2, -94.0 | “under the canopy” — **inside** |
| IMG_0364 | -62, 2.5, 46 | 0.45, 0.22, -0.86 | -44.0, 11.3, 11.6 | entrance curtain + canopy from the lawn |
| IMG_0365 | 9, 5.2, -112 | -0.981, 0.0, 0.196 | -30.24, 5.2, -104.16 | “entrance, oblique” — **z=-112 inside** |
| IMG_0366 | 3, 5.2, -62 | -0.957, 0.048, -0.287 | -35.28, 7.12, -73.48 | “entrance steps” — **z=-62 inside**; photo is from the **street** |
| IMG_0367 | -5, 5.2, -96 | -1.0, 0.0, 0.0 | -45.0, 5.2, -96.0 | “at the threshold, looking in” |
| IMG_0368 | -41, -1.2, 64 | 0.0, 0.28, -1.0 | -41.0, 10.0, 24.0 | canopy + RAC sign; Y is below grade |
| WEB_entrance_1 | -41, 1.5, 52 | 0.0, 0.22, -1.0 | -41.0, 10.3, 12.0 | south approach (best frontal) |
| WEB_entrance_2 | -41, 2.2, 70 | 0.0, 0.12, -1.0 | -41.0, 7.0, 30.0 | dusk ¾ of canopy / stair |
| WEB_entrance_left_pole | 78, 6.0, 42 | -0.82, 0.06, -0.57 | 45.2, 8.4, 19.2 | east wrap, metal panel, thin cantilever |

---

## 2. What `site.json` actually contains

`blueprint/site.json` is **footprint + brick facade + roofs only**. No roads, lots, trees, dumpsters, stairs, or hardscape.

| item | in site.json | where it actually lives |
|---|---|---|
| Canopy | One `type: "canopy"` roof, height **15 ft**, polygon x=-28..18, z=0..12 (near the **door / origin**, 46×12 ft) | `Prepare.luau` **drops** `type=="canopy"`. `Exterior.luau` rebuilds a different canopy (soffit **30.55**, depth 18, span world x≈-96..8) |
| Entrance stairs / ramp | **Absent** | Sidecar `terrain_relationship.json` `entranceExteriorStair` (14 risers, 0.5 ft, width 48, toe `[0,-7,27]`) **and** `Scene.luau` `entrance` (10 risers × 7 in, width 42, **x=-41**) |
| Roads / roundabout | Absent | `Scene.site.roads = []`. `Builder` therefore never calls `Hardscape.luau`. Pavement = Fairfax 4 ft **planimetric patches** in `CountyHardscape` |
| Parking lots | Absent | Same planimetric raster + `Campus.Builder` AABB `LotSlab`s + `Markings` stall polylines |
| Trees | Absent | `Scene.site.trees` 112 lidar maxima (103 deciduous / 9 pine). `verification/exterior/lidar_trees.json` has 135 |
| Dumpsters / service yard | Absent | Hardcoded in `Exterior.luau` at **(-128, 58)** (south of Linn gym). No `site_dumpster` props |
| South glass | Facade array is **all `brick`**. There is **no** south segment `(-97,0)→(10,0)` | L1 wall `l1_w096` `(-97,0)→(10,0)`: brick with 80 ft curtain + **12 ft door at x=-6..6** + 3 ft sidelights. East wrap: `l1_w025` `(10,-23.5)→(10,0)` curtainwall. `Scene.exteriorWallOverrides = []` |

`Scene.luau` `entrance` (authoritative for Exterior):

```
x=-41, z=0, width=42, landingDepth=14, risers=10, rise=7/12, run=1.15,
canopyHeight=24.2, canopyDepth=32, canopyWidth=118, columnRadius=0.85,
glassCorner=[10,0], glassReturnEnd=[10,-24], rotationDeg=-90
source: "South glass l1_w070 at z=0, x=-97..10 … east ramp"
```

(`l1_w070` in `level1.json` is an **interior coaches wall**, not the south glass. Comment is stale.)

---

## 3. Lidar / Heightfield vs FFE (ft above L1)

Grid: `TerrainData` x0=-418.52, z0=-580.00, step=4, 200×200. Datum: NAVD88 437.924 from “ground 30 ft south of south door + ten 7-inch risers” (`dem_provenance.json`). `Heightfield.height` is **not** raw lidar:

- Inside footprint pad → **-0.4** (roof returns discarded).
- West L2 strip → clamp **20** for 16 ft, then blend to raw.
- South corridor **x∈(-104,18), z∈[-1,160)** → `max(raw, designed stair)`: 0 to z=14, -4.083 at z=22.2, then blend toward `max(raw,-6.5)` out to z=160.

| location | xz | raw lidar | Heightfield.height | Δ | material (1 grass / 2 asphalt / 3 concrete) |
|---|---|---:|---:|---:|---|
| Door sill (origin) | 0, 0 | -2.03 | **0.00** | +2.03 | 3 |
| Exterior stair center (code) | -41, 0 | -2.71 | **0.00** | +2.71 | 3 |
| Stair toe (7×7 in design) | -41, 22 | -4.79 | -3.98 | +0.80 | 5 |
| `terrain_relationship` toe | 0, 27 | -6.08 | -4.17 | +1.91 | 3 |
| IMG_0366/0368 curb (street at stair) | -41, 32 | -6.02 | -4.26 | +1.76 | 3 |
| South road under lift | -41, 100 | **-10.82** | **-5.79** | **+5.03** | 2 |
| Lift box edge | -41, 160 | -10.09 | -10.09 | 0 | 3 |
| Roundabout island (markings) | **147, 147** | **-16.03** | **-16.03** | 0 | **1 grass** |
| Roundabout ring | 147, 177 | -15.89 | -15.89 | 0 | **1 grass** |
| Double-yellow end | 82, 158 | -13.86 | -13.86 | 0 | 1 |
| East lot | 120, -50 | -1.08 | -1.08 | 0 | 2 |
| East lot (far) | 180, -200 | -4.43 | -4.43 | 0 | 3 |
| West L2 door (on pad) | -351.5, -102.5 | -1.50 | **-0.40** | +1.10 | 3 (inside pad) |
| West L2 16 ft out | -367.5, -102.5 | **+27.26** | **20.00** | **-7.26** | 2 |
| West L2 40 ft out | -391.5, -102.5 | +27.07 | +27.07 | 0 | 2 |
| Code dumpster | -128, 58 | -2.42 | -0.80 | +1.62 | **1 grass** |
| Service yard pad | -160, 64 | +0.22 | +0.22 | 0 | 1 |

**Roads do not sit on raw lidar near the building.** The south walk is raised as much as **5 ft** above classified ground, then at z=160 the designed floor disappears and Patriot Circle / the island sit **13–16 ft below L1 on grass voxels**. County slabs drape `H.height` (the lifted surface), so pavement follows the mesa, not the LAZ.

Terrain material grid (40k cells): grass 9919, asphalt 13389, concrete 16485, rock 148, ground 59. **943 asphalt cells have a grass 4-neighbor**; only **9** grass cells have ≥3 asphalt neighbors (the only ones `Terrain.luau` reclassifies). Grass inside lots is still the default.

---

## 4. Findings

| severity | owner | area | issue | evidence | fix |
|---|---|---|---|---|---|
| **critical** | exterior | entrance stairs / ramp (user 23:45 #3) | Stair does not match WEB_entrance_1/2 or IMG_0364–0368. Photos: pale concrete, **~8–9 risers**, 3–4 silver pipe rails, cheek planter, **asphalt drop-off + yellow curb at the toe** (IMG_0366/0368). Code: **hardcoded 7 treads** (`Exterior.luau` `n=7`) ignoring Scene `risers=10` and sidecar **14**. Rise 7×0.583=**4.08 ft**. Rails are 0.22 ft cylinders. Ramp is on **local +Z = west**; Scene source string says **east ramp**. Heightfield holds z≤14 at Y=0 so the flight reads as a shallow platform on a lifted terrace, not a stair up from the street. | `Exterior.luau` L51–80, L161–238; `Scene` entrance; `terrain_relationship.json` `entranceExteriorStair`; IMG_0365 (8–9 treads), IMG_0366 (curb at toe); H.height(-41,22)=-3.98 vs raw -4.79 | Recenter the flight on the **origin door** (see next row). Use **8–10 × 7 in** (or surveyed) from **raw lidar at the curb** (~-6 ft at z≈30) up to FFE 0. Match rail count/section. Put the 1:12 ramp on the **east** of the stair (Scene + WEB_entrance_1 right side). Do not lift 160 ft of terrain to make the treads vanish. |
| **critical** | exterior | south door vs stair/canopy (user: south smaller glass) | Origin and `l1_w096` door are at **x=-6..6** (12 ft pair, offset 91 on the south wall). Exterior `entrance.x=-41` (midpoint of x=-97..10). Canopy span is world **x≈-96..8** (the **whole** south wall). Stairs 42 ft wide sit on the 80 ft west curtain, **~41 ft west of the door**. `site.json` canopy stub (x=-28..18, height 15) was nearer the door and is discarded. User 23:20: entrance is the **smaller south glass**, and that glass should be **longer** than a 12 ft hole. `site.facade` has no south curtain_wall; south skin is brick. | `level1.json` `l1_w096`; `Scene.entrance.x=-41`; `Exterior.luau` `zGlassWest/East`; `Prepare.luau` drops canopy roofs; WEB_entrance_2 doors under canopy center with RAC on the **east** glass (IMG_0368) | Move Exterior entrance to **x=0** (door). Widen the south storefront (user: longer small glass) so it is not a 12 ft punch in brick. Canopy over that glass **and** the east wrap `[10,0]→[10,-24]`. Keep the long **east** curtain as the big glass, not the entry. Add a south `curtain_wall` facade segment. |
| **critical** | exterior | canopy (user 23:45 #5) | Photos: **one** thin dark metal **roof** cantilever, knife edge, grey soffit with a recessed light well, **square** charcoal columns ~3–4 ft, glass wrapping the SE corner (WEB_entrance_2, WEB_entrance_left_pole, IMG_0364–0368). Code: soffit **hardcoded 30.55 ft** (JSON `canopyHeight` **24.2**, lidar lobby/vestibule roof **25.54 / 25.73** in `ROOF_HEIGHTS.md`) so the wedge sits **~5 ft above the measured roof**. Depth **18** vs JSON **32**. `canopyRise` 1.4 + plate 0.35 = **1.75 ft** at the glass, not a dying-out knife. Supports are **round** poles r=0.7; `columnRadius` 0.85 unused. SpanCanopy is now one piece (door-gap hack is gone) but it is still a separate flying slab, not the roof plane. | `Exterior.luau` L240–311; Scene entrance; `ROOF_HEIGHTS.md`; WEB_entrance_2 / IMG_0364 | Soffit ≈ **24.2** (below lidar roof 25.5). One continuous charcoal wedge = the lobby roof cantilever, lip ~0.3 ft, depth ~30 ft, wrap the east corner. **Square** columns on photo stations (two bays). Soffit cans + the rectangular well in IMG_0365. Delete the 30.55 hack. |
| **critical** | exterior | roundabout / roads on lidar (user 23:45 #4) | Patriot Circle is **too low vs the building** because (1) Heightfield **raises** x∈(-104,18), z<160 by up to **5 ft** above LAZ, (2) at z=160 that lift **stops**, (3) the roundabout island at **(147, 147)** is raw **-16.0 ft and material 1 (grass)**, (4) `CountyHardscape.inEntrance` **skips** pavement in a ~78×66 ft box around the stair so the IMG_0366 drop-off has **no asphalt slab**, (5) `Scene.roads=[]` so `Hardscape.build` never runs, (6) `Terrain.luau` force-paints **concrete** for `x>-104..<18, z>-1..<40` and `x>-68..<-14, z>=40..<92` — the street in IMG_0366 becomes a concrete terrace. County slabs are **0.5 ft** on `H.height` (the lifted mesh), so the roundabout is a grass pit ~16 ft below L1 while the plaza is a mesa at ~-5. | Heightfield L90–104; County L24–37, L45–47; Terrain L87–97; samples above; IMG_0356/0358 (real asphalt + double yellow + white dash + curb); markings `double_yellow` z=157..193 and `island` 117..177, 117..177 | **Drape every road/lot on raw bilinear lidar.** Limit the designed south profile to the **stair envelope** (z≈0–30), not 160 ft. Classify the roundabout / Patriot Circle cells **asphalt**. Do not `inEntrance`-skip the drop-off; that lane is asphalt with a yellow curb in IMG_0366. Restore a connected crown + island + curb on the **lidar surface**. Campus `RoadSlab` 0.28 ft boxes must use the same height. |
| **critical** | exterior | parking lots (user 01:40 #7, 09:40) | Lots are 4 ft raster lids, not real lots. County: 1075 asphalt patches (147664 ft²) as 0.5 ft `LotSlab`s + one AABB `LotSlab` 0.45 ft over merged fields; **fake** 24×28 `LotAisle` tongues; stall paint in `MarkingSlab` is built at **Y=height+1.8** then **destroyed** (`Builder.luau` L314–318) and replaced by `Markings`. Terrain under lots is still mostly the material grid — 943 grass/asphalt edges, 9-cell fill. `Campus.massLot` is **one yawed box at the center’s height** (can spear L2; `keepGroundOffFloors` then cuts). Markings have **212** stall polylines (bbox x=-405..103, **z=28..478**) — z>220 is **off the 800 ft site grid** and will clamp. No GMU lot names, no real aisle graph, islands are 8×18 boxes with a shrub. User: connected drive aisles, 9×18 paint, curbs, islands, poles, signs, **no grass inside lots**. | `CountyHardscape.luau` L31–61, L137–348; `Terrain.luau` L17–34; `Campus/Builder.luau` `massLot`; `Markings/init.luau`; `tools/site_refs/markings.json`; USER 01:40 #7 | Paint every planimetric parking polygon **asphalt occupancy 1** (not 0.5 ft lids). Build each real lot from county polygons + ortho (GMU Parking map). 24 ft aisles, 9×18 stalls from markings (clip to grid), 6 in curbs, planted islands, working poles. Delete per-cell striping and fake tongues. |
| **major** | exterior | trees (user 23:45 #7) | Lidar XY is used (112 of 135; 3 skipped in the south keep-out box). Crowns are **SmoothPlastic WedgeParts** (deciduous: 2×5 wedges; pine: 3×3) on a bark cylinder, height clamped 18–36. Not trunk + layered canopy / real pines. `index % 5 == 0` forces extra pines. Species is “template inferred”. | `Landscape.luau` L39–93, L99–139; `lidar_trees.json`; IMG_0356/0358 real street trees | MeshPart (or noisy ellipsoids + branch mass). Keep lidar XY, 42–56 ft entrance keep-out, skip pad/asphalt. |
| **major** | exterior | surroundings / markings (user 08:40) | Aerial paint **exists** (314 features: 3 double-yellow, 14 white edge, 2 bike, 42 crosswalk, 20 stop bar, 212 stall, 7 island) draped at height+0.12 + per-kind lift. Roundabout island is in the file **but on grass at -16 ft**. Scene has **one** OSM crosswalk at `[155.5,-457]` (Campus Drive, north) and `Hardscape` never runs. IMG_0356/0358 show double yellow, dashed white, bike-ish edge, concrete curb, sidewalk — those roads need **asphalt voxels + curb**, not paint on lawn. Several islands/stalls at z=300–446 are **outside** the heightfield. | `markings.json`; `Markings/init.luau`; Scene `crosswalks`; IMG_0356–0358 | Keep the extracted paint. Put it on asphalt that exists. Clip features to the DEM. Build Patriot Circle as a real roundabout (island curb + truck apron) at lidar, not a grass bowl with a yellow polyline. |
| **major** | exterior | dumpsters / service yard (user 09:35 #12) | User: dumpsters **west of the volleyball gym**. Code: one dumpster + fence + precast brow at **(-128, 58)**, south of the Linn gym (z=47 wall). That **does** match **IMG_0349–0351** (brick court, precast fins, green dumpster, chain-link). Volleyball west wall is x=-193.5, z=-180..-279 — that strip is inside the cage pad. Round 5/6 `service_yard.png` is an **interior** CMU room with two green boxes (architect/props), not this yard. Grass voxels at the coded pad (`mat=1` at -128,58); Terrain only asphalts `x>-224..<-96, z>46..<86` if the cell was grass. | `Exterior.luau` L456–501; IMG_0349; WALKTHROUGH 09:35 #12 | Keep/finish the **south Linn** court to match IMG_0349 (asphalt voxels, precast fins, fence, dumpster). **Also** place the west-of-volleyball yard the user asked for (loading between competition gym and cage / west brick). Do not treat interior dumpsters as this item. |
| **major** | exterior | west L2 grade exit | `terrain_relationship.json` high door **(-351.5, -102.5) at Y=20**. Raw lidar **1.5 ft outside the wall is +26.4 to +27.3**. `Heightfield` returns **-0.4** at the door (inside pad) and **20** for 16 ft out, then blends — a 7 ft cut into the hill with no retaining wall in Exterior. Round 6 `grade_exit_outside.png` (clue) shows a floating concrete bar in front of the door. | Heightfield L57–74; samples; `terrain_relationship.json` `gradeLanding` | Landing polygon at **Y=20** as specified. Terrain outside the wall must meet that sill; if lidar is +27, add a **retaining / cheek** (photos) rather than a 7 ft unexplained cut. Do not leave pad height -0.4 at the L2 door. |
| **minor** | exterior | stray / photo extras | **Keep (they are in photos):** vertical RAC letters (IMG_0368), hydrant at the **street curb** (IMG_0366/0368), east planter wall + hedge, west red bed (IMG_0364), bike hoops at the stair. **Fix/remove:** west pipe rack pile if it isn’t in the frontal photos; `RampStem` fins if the ramp is on grade; `ApproachSlab` grey terrace that eats the lawn in WEB_entrance_1; round unlit globes. `details=[]` so Exterior HVAC/sunshade never run (good until photo-placed). | `Exterior.luau` L312–438; IMG_0364/0366/0368 | Inventory Entrance children against WEB/IMG. Do **not** delete RAC letters or the curb hydrant. |
| **minor** | exterior | capture / station quality | Round 1 pairs used the wrong cameras. IMG_0358 / IMG_0362–0367 stations are estimated and several are inside the footprint. Cannot close user items from this folder’s JPGs. | `pairs/WEB_entrance_1.jpg`; station table | Recapture with the cameras in §6. Recalibrate Y to H.height+5.2. |

---

## 5. User-required matrix (exterior only)

| Required item | Status | Notes |
|---|---|---|
| 3. Wide concrete stair + handrails + ramp matching WEB/IMG | **Open** | 7 treads, wrong X, west ramp, lifted plaza. Photos want 8–10 risers from the **street**. |
| 4. Roundabout/road on real lidar, not too low vs building | **Open** | South mesa +5 ft; island **-16 ft grass**. Not on LAZ continuously. |
| 5. Thin dark wedge cantilever, glass wrapping corner | **Open** | Continuous span now, but soffit 30.55, round poles, not the roof. |
| 7. Trees: trunk + layered canopy / pines | **Open** | Wedge stacks, not meshes. Lidar XY OK. |
| Parking: aisles, 9×18, curbs, islands, poles, signs; **no grass in lots** | **Open** | Raster lids + markings; grass still in the material grid. |
| Surroundings: lane lines, crosswalks, curbs, sidewalks from aerial | **Partial** | Markings polylines exist; many sit on grass / off-grid. Curbs from simplified county edges. |
| Dumpsters west of volleyball gym | **Open** | South Linn court exists (photo-true); west-of-VB yard does not. |
| Main entrance on SOUTH smaller glass | **Partial** | Origin is south (correct) but Exterior is 41 ft west on the long south curtain; door JSON is 12 ft at x=0. |

---

## 6. Studio cameras to capture this round

Use `fovVertical=55`. After placing, set **Y = Heightfield.height(x,z)+5.2** if the JSON Y is underground or inside a slab. `look_at` below is `position + 40 * look`.

### A. Photo-match (must recapture; round1 pairs are invalid)

| id | camera_position | look_at | why |
|---|---|---|---|
| WEB_entrance_1 | -41, 1.5, 52 | -41.0, 10.3, 12.0 | frontal stair + canopy + lawn |
| WEB_entrance_2 | -41, 2.2, 70 | -41.0, 7.0, 30.0 | wedge profile, square column, wrap |
| WEB_entrance_left_pole | 78, 6.0, 42 | 45.2, 8.4, 19.2 | east metal panel, thin cantilever, wrap |
| IMG_0364 | -62, 2.5, 46 | -44.0, 11.3, 11.6 | west lawn, red bed, bikes, knife edge |
| IMG_0368 | -41, 5.0, 64 | -41.0, 16.2, 24.0 | RAC letters, hydrant, curb, stair (lift JSON Y) |
| IMG_0349 | -175, 6.0, 78 | -165.0, 9.2, 39.6 | south service court / dumpster |
| IMG_0356 | 65, 5.2, 78 | 25.76, 5.2, 70.16 | east road, trees, curbs |
| IMG_0358 | **do not use JSON xz** | — | station is north of the gym; shoot from the **east road** looking at the metal-panel gym (photo) |

**IMG_0365 / 0366 JSON poses are inside the building.** Use street-side stand-ins:

| id | camera_position (suggested) | look_at | why |
|---|---|---|---|
| IMG_0365_street | 8, 5.2, 28 | -20, 12, 8 | oblique stair + soffit well |
| IMG_0366_street | 12, 5.2, 36 | -20, 14, 8 | stair + hydrant + yellow curb + wrap (the real photo) |

### B. Grade / parking / trees (not in photo_stations)

| id | camera_position | look_at | why |
|---|---|---|---|
| south_stair_toe | -41, 1.0, 34 | -41, 8, 8 | prove rise from curb to door |
| roundabout_island | 147, -10, 147 | -41, 8, 0 | island vs building FFE (expect -16 grass pit today) |
| patriot_dy | 20, -3, 193 | -41, 5, 80 | double-yellow on grass vs asphalt |
| parking_aerial | -40, 180, -40 | -40, 0, -40 | lots, grass, aisles, paint (look down) |
| east_lot_eye | 160, 5, -80 | 80, 2, -80 | stall stripes / poles at eye height |
| trees_close | 80, 5, 40 | 20, 8, 0 | wedge vs real canopy |
| west_L2_grade | -375, 25, -102.5 | -351.5, 22, -102.5 | lidar +27 vs sill 20 |
| dumpster_south | -128, 5, 80 | -128, 4, 58 | coded yard vs IMG_0349 |
| dumpster_west_vb | -220, 5, -160 | -193, 4, -180 | missing west-of-volleyball yard |

Pair with `tools/side_by_side.py` against `reference/photos/WEB_entrance_*.jpg` and `IMG_0364.jpg`–`IMG_0368.jpg`. Do not reuse `verification/qa/round1/pairs/*_build.png`.

---

## 7. What the current code already improved (do not regress)

- Canopy is one span (no 18 ft door gap), SmoothPlastic charcoal, not Neon.
- Stair / ramp / rails / cheek / planter / RAC letters / hydrant / bikes exist in `Exterior.luau`.
- County `hy>8` cull that deleted the roundabout is **gone**.
- `Builder` destroys County’s Y=+1.8 `MarkingSlab` and drapes `Markings` at ~0.02 ft above slab.
- Trees are wedges, not Grass discs; entrance keep-out exists.
- SiteContext 5812 is under the 6000 RAC-site budget (campus/horizon have separate caps).

None of that closes the user items in §5.

---

## 8. Owner split

| owner | this round |
|---|---|
| **exterior** | All rows in §4. TerrainData/Heightfield south lift + west pad, County, Markings drape, Landscape trees, Exterior entrance/canopy/yard. |
| architect (not this report’s fix, but blocks photo-match) | `l1_w096` 12 ft door vs 80 ft curtain; `site.facade` all brick; no south curtain_wall skin; origin vs Exterior x=-41. |
| campus | AABB `LotSlab` / `RoadSlab` on coarse height; can overlap county lots and L2 doors. |
