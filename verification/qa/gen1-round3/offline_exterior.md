# Round 3 offline exterior QA — GMU RAC

Independent review. Did **not** edit `blueprint/`, `src/`, or the RAC model.

Sources: `docs/WALKTHROUGH.md`, `docs/reviews/USER-2026-09-28-2345.md` items 3–7, `docs/reviews/USER-2026-09-29-0140.md` item 7, `verification/exterior/ROOF_HEIGHTS.md`, `src/ReplicatedStorage/RAC/Site/{Exterior,CountyHardscape,Terrain,Landscape,Builder,Hardscape}.luau`, Scene JSON (planimetrics + entrance), `blueprint/terrain_relationship.json`, `blueprint/photo_stations.json`, round 2-fix stills (latest exterior captures; round 3 folder is interior-only), `verification/qa/round3/build.txt`, `tools/side_by_side.py` (not run this pass — no new exterior pairs). `verification/M1/user0140/` is interior stills only.

Round 3 build: 43362 parts, SiteContext 2554. Geometry QA on the building is 0 issues; that checker still skips any path containing `slab`/`canopy`/`rail`, so **PASS is not exterior proof**.

---

## Findings

| severity | owner | area | issue | evidence | fix |
|---|---|---|---|---|---|
| **critical** | exterior | parking lots / voxels | Terrain under lots is still lidar **grass**, not asphalt. `Terrain.luau` maps `materials` codes 1=Grass, 2=Asphalt and only force-concretes a **hardcoded stair box** `abs(x)<34 and z in (-1,64)`. It never paints county parking polygons. County `LotSlab` parts are 0.5 ft thick on the heightfield, so grass blades grow through the pavement. Round 2-fix aerial still shows lawn inside the east/south lots and checkerboard 4-stud cells. | `Terrain.luau` L9–75; `CountyHardscape.luau` thickness 0.5; `verification/qa/round2-fix/parking_aerial.png`; USER 01:40 #7. | Before `WriteVoxels`, classify every cell whose (x,z) is in an asphalt planimetric patch (or road polygon) as Asphalt occupancy 1. Fill lots as a **continuous** asphalt volume, not 0.5 ft lids. |
| **critical** | exterior | roads / roundabout height | Hardscape still drapes `centerY = H.height + 0.08 - up.Y * thickness/2` and **drops any patch with `hy > 8`**. Patriot Circle / roundabout therefore sit on raw lidar **or vanish** near the building. Round 1 playtest still shows the south road in a grass trench with the plaza hovering above. User: roundabout/road too LOW vs lidar **and** vs FFE 0. `terrain_relationship.json` door=0, west L2=+20; county does not clamp to landings. Scene `roads: []` so `Hardscape.build` never runs when planimetrics exist. | `CountyHardscape.luau` L31–47, `hy > 8` skip; `Builder.luau` planimetric branch; `verification/qa/round1-fix/roundabout.png`; USER 23:45 #4. | Drape to lidar **then clamp** so south road meets the stair toe (~−drop), not a 20 ft cliff; do not skip hy>8 near the pad. Restore a connected roundabout crown + island + curb on the **lidar surface**. |
| **critical** | exterior | parking kit (aisles, stripes, curbs, islands, poles) | User asked for connected drive aisles, 9×18 stall paint, curbs, islands, light poles, **no grass in lots**. Code: stall paint is **per-cell** on the largest 4-ft patches (`length>=18`, max 10 stalls/cell, cap 320), not a lot-wide aisle layout. Curbs are simplified county edges, skipped if `hy>8` or in the entrance AABB. **No island meshes.** Landscape builds only **8** `site_lamp` poles with **dark unlit globes**. Aerial: empty grey fields, grass fingers, no stall grid, no lot lights. Round 1 `stall_stripes.png` is a couple of white/yellow ticks on a floating slab. | `CountyHardscape.luau` L137–207; `Landscape.luau` L171–184 (`site_lamp` ×8); Scene props; `parking_aerial.png`; `round1-fix/stall_stripes.png`. | One lot polygon → one asphalt body + 24 ft aisles + 9×18 stripes + 6 in curbs + planted islands + working poles. Do not stripe 4-ft raster cells. |
| **critical** | exterior | entrance canopy | Photos (`WEB_entrance_2`, `IMG_0364`): **one** thin dark metal wedge, continuous over the south glass, wrapping the corner, square charcoal columns, soffit cans. Build: **two** spans with an **18 ft gap** over the door (`spanCanopy(lo,-9)` and `(9,hi)`), 0.3 ft soffit **plus 1.2 ft wedge** (1.5 ft at the glass, not 0.25–0.5), corner plate 28×0.3×projection, **0.38 ft round poles** (JSON `columnRadius` 0.85 unused). Round 2-fix `canopy_profile.png` still reads as a thick black slab, not a dying-out wedge. Scene `canopyHeight` 24.2 vs hardcoded soffit 23.1. | `Exterior.luau` L242–337; Scene entrance; `WEB_entrance_2.jpg`; `IMG_0364.jpg`; `round2-fix/canopy_profile.png`; USER 23:45 #5. | One continuous matte wedge, lip ~0.3 ft, glass wrap on the corner, photo-matched square columns, soffit lights on a grid. Delete the door gap and dual-span hack. |
| **major** | exterior | entrance stairs / ramp | Code now builds 8–10 concrete treads, three pipe rails, cheek wall + shrubs, 1:12 east ramp with stems. Still wrong vs `WEB_entrance_1/2` and `IMG_0364–0368`: plaza/apron already near FFE so the flight reads as a **shallow tiled platform**; rails are 0.22 ft tubes not photo profiles; hydrant sits on the apron; ramp stems look like floating concrete fins; grass voxels still at the cheek (`Terrain` stair box is world `abs(x)<34` while the entrance frame is `rotationDeg -90` at (0,0) so **local stair X is world −Z**, and the hardcoded box does not follow the flight). Round 2-fix `stairs_ramp.png`: treads exist but plaza is coplanar, hydrant, thin rails, grass left of stairs. | `Exterior.luau` L51–240, L383–400; `Terrain.luau` L72–74; `round2-fix/stairs_ramp.png`; `WEB_entrance_2.jpg`. | Lock landing top to FFE 0; drop plaza to lidar so **~8–10 risers actually rise**; cheek walls + planted bed **beside** treads not on them; match rail section; concrete voxels under stair+ramp in **entrance local space**; hydrant only if photos show it. |
| **major** | exterior | trees | Disc stacks are gone. Current kit is 5 SmoothPlastic **balls** (deciduous) or 3×6 **WedgePart cones** (pine) on a bark cylinder. Round 2-fix `trees_close.png`: toy blobs + faceted pine, grass at the trunk on the plaza. User: natural trunk+canopy / pines as in photos. 112 lidar trees, species “template inferred”. | `Landscape.luau` `crown`/`coneTier`; `trees_close.png`; USER 23:45 #7. | MeshPart / Mesh trees (or at least noisy ellipsoids + branch mass). Keep lidar XY. Keep the 42 ft entrance keep-out. |
| **major** | exterior | stray / non-photo parts | Entrance adds RAC **block letters** on the glass, a **red hydrant on the stair apron**, 3 pipe **bike racks on the west landing**, 8 `ApproachSlab` strips, `RampStem` fins, `CheekShrub` boxes. Canopy soffit lamps skip `|lz|<10` (dark over the door). Light globes are black balls. `details` in Scene is `[]` so sunshade/HVAC in Exterior never run. None of the letter / hydrant-on-treads / plaza bike-pipe pile match `WEB_entrance_*` / `IMG_0364` (bikes are on the **east** stair, hydrant not on the landing). | `Exterior.luau` L361–406; `Landscape.luau` LightGlobe; Scene `details: []`; `stairs_ramp.png`. | Inventory every `Entrance` child against WEB/IMG photos. Keep: stair, ramp, rails, thin canopy, one/two columns, soffit cans, east bike cluster. Remove letter mash, apron hydrant, west pipe racks unless photo-placed. |
| **minor** | exterior | round 3 capture gap | Round 3 QA folder has **no** exterior stills (no aerial, canopy, stair, lot, tree). `tools/side_by_side.py` was not used. `photo_stations.json` interior cameras are “estimated”. Cannot close USER 23:45 #3–7 from this round’s pixels. | `verification/qa/round3/` listing vs `round2-fix/*.png`. | After the voxel/canopy/stair pass: capture + `side_by_side.py` for WEB_entrance_1/2, IMG_0364–0368, parking aerial, roundabout, trees. |

---

## User-required matrix (exterior only)

| Required fix | Status | Notes |
|---|---|---|
| Wide concrete stair + handrails + ramp matching WEB/IMG | **Open** | Geometry exists; rise vs plaza and rail/cheek profile still fail photos. |
| Roundabout/road on real lidar ground, not too low | **Open** | Thin draped slabs + grass voxels; `hy>8` cull; `roads: []`. |
| Thin dark wedge canopy over wrapping glass | **Open** | 1.5 ft at glass, gap over door, skinny round posts. |
| Natural trees | **Open** | Balls + wedge pines, not meshes. |
| Parking: connected aisles, stripes, curbs, islands, poles, **no grass in lots** | **Open** | Voxel grass + per-cell paint + 8 dark poles + 0 islands. |
| Remove stray non-real elements | **Open** | RAC letters, apron hydrant, west pipe racks, ramp stems. |

## What improved since round 2 code QA

- Canopy is SmoothPlastic charcoal, not Neon; thickness reduced from 2.2 ft to soffit 0.3 + wedge 1.2.
- Stair/ramp/rails/cheek exist in `Exterior.luau`.
- Trees are balls/wedges, not Grass discs.
- County patches are named `LotSlab` / `PavementSlab` (0.5 ft) instead of missing entirely.
- 8 `site_lamp` props exist in Scene.

None of that closes the user items above.

## Roof / lidar (context, not a new interior issue)

`ROOF_HEIGHTS.md`: lobby/entrance_vestibule ~25.5–25.7 ft above L1. Canopy soffit at ~23.1 is below that roof, which is plausible. Do not use roof lidar to drape parking (`hy>8` skip is the wrong hammer).
