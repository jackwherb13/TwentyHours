# Round 2 offline code QA — GMU RAC

Inspected `places/build.rbxm` (27698 BaseParts; `verification/qa/round2/build.txt` reports 27697 + 0 geometry issues), `src/ReplicatedStorage/RAC/Materials.luau`, builders under `src/ReplicatedStorage/RAC/Build` and `Site`, `tools/check_geometry.luau`, `src/ServerScriptService/RACBuild.server.luau`, `LightingController.server.luau`, `blueprint/site.json` + nested Scene/planimetrics, `src/ReplicatedStorage/RAC/Site/TerrainData.luau` (lidar grid), `blueprint/terrain_relationship.json`. Did not edit `blueprint/`, `src/`, or the RAC model. Lune inspection scripts: `verification/qa/round2/inspect_offline.luau`, `inspect_site.luau`, `sample_lidar.py`.

Geometry QA **PASS is not evidence of a correct building**. `tools/check_geometry.luau` treats any path containing `slab`, `level2`, `rail`, `pad`, `cabinet`, `shelf`, `canopy`, `grid`, etc. as hung and skips floating checks. Site dressing lives under `Site.Context.GroundSlab`, so **every county pavement/curb is exempt**. Treadmill `RailL`/`RailR` match `rail`. The checker also ignores Terrain voxels, MaterialVariants, lighting, and prop density. 0/0/0/0/0/0 is a logical false negative, not a clean model.

---

## Findings

### 1. Materials look grey — variants never live in the place file

| | |
|---|---|
| **Severity** | P0 |
| **Owner** | materials / builder (`Parts.luau`, `Materials.luau`, `RACBuild.server.luau`) |
| **Area** | Interior floors, walls, gym maple |
| **Issue** | Floors/walls call `Materials.apply`, which sets `MaterialVariant = "RAC_<key>"` and **`Color = (1,1,1)`**. Variants are parented to `MaterialService` at build time. The Lune loader’s `GetService` is a throwaway Folder; **MaterialService is not serialized in `places/build.rbxm`**. `Materials.install()` is only `pcall`’d from a Play server script, with a comment that variant writes need plugin capability — so Edit-mode (and likely Play) still shows untinted Wood/Concrete/Plaster. |
| **Evidence** | Gym slab `competition_gym`: `Material=Wood`, `MaterialVariant=RAC_maple`, `RACMaterial=maple`, **`Color=1,1,1`**. Counts: 6 maple slabs, 23 terrazzo, 26 carpet, 8 rubber, 271 painted_cmu walls, 2162 metal_panel. `RAC_Maple` (PascalCase in dead `Parts.finishes` table) = **0**. Missing variant on 24686/27698 parts (props/site). `art/materials/materials.spec.luau` still asserts `definition.assetId == nil`; production `Materials.luau` now has rbxassetids — the smoke test is stale and would fail. |
| **Fix** | (1) Persist MaterialVariants into the place (Rojo `MaterialService` instance, or bake `Texture`/`SurfaceAppearance` on each part). (2) Do not bleach `Color` to white unless the variant is actually present. (3) Align `Parts.finishes` names (`RAC_Maple`) with `RAC_maple`. (4) Repair `materials.spec.luau` to match current assetIds. (5) Close-up screenshots of maple / terrazzo / CMU after variants exist in Studio. |

### 2. Court paint fights the maple slab

| | |
|---|---|
| **Severity** | P1 |
| **Owner** | `Build/Court.luau` |
| **Area** | Competition gym |
| **Issue** | `Court.build` lays SmoothPlastic apron/playing-surface sheets on the maple slab and **clears `MaterialVariant`**. The glossy maple + Mason-green apron the user asked for is a plastic overlay, not the maple variant. If the overlay is misaligned or Z-fighting, the huge 115×147 ft white wood slab shows through (matches “grey-white gym”). |
| **Evidence** | `Court.luau` `sheet()`: `Parts.box(..., "maple")` then `Material = SmoothPlastic`, `MaterialVariant = ""`. Gym slab size 115×0.5×147. |
| **Fix** | Keep maple variant on the slab; paint only 0.02 ft non-colliding decals/parts with explicit maple/green/gold colors; verify no coplanar fight with the slab. |

### 3. Grass / terrain inside the building

| | |
|---|---|
| **Severity** | P0 |
| **Owner** | `Site/Terrain.luau`, `RACBuild.server.luau` `clearInteriorTerrain` |
| **Area** | Interior footprint, north hall |
| **Issue** | Voxel terrain is the only grass *inside* rooms; the rbxm has 898 Grass parts, all tree crowns (`Landscape.luau` `leaf`/`pine`). Lidar classification still has **grass (code 1) inside the building bbox** (178 samples vs 1617 concrete). `TerrainBuilder.insidePad` lowers pad voxels to y=−1.5 and material 3, but 4-stud `WriteVoxels` snapping plus roof-classified lidar can still poke occupancy through 0.5 ft slabs. `clearInteriorTerrain` only `FillBlock`s **three hardcoded boxes** (training, left hall, south lobby) — not the full `padPolygons` / footprint. Terrain is not in the rbxm, so this only shows in Studio after `Terrain.build`. |
| **Evidence** | `TerrainData.luau` `materials` row sample + `sample_lidar.py` building bbox `{1:178, 2:81, 3:1617}`. `RACBuild.server.luau` lines 26–41. Manager hall-north grass tufts. |
| **Fix** | Fill Air (or keep occupancy 0) for every voxel whose (x,z) is in `padPolygons` **and** a generous inset of every slab AABB, full height through the roof. Delete the three-box hack. Re-run Studio screenshots of north hall / training room looking at the floor. |

### 4. Lighting is structurally wrong, not just “too dark”

| | |
|---|---|
| **Severity** | P0 |
| **Owner** | `Build/Lights.luau`, `LightingController.server.luau`, fixture props |
| **Area** | Stairs, corridors, whole interior |
| **Issue** | (a) **No `workspace.RAC.Lighting` folder**. `LightingController` `WaitForChild("Lighting")` never resolves on this model (`inspect`: `root Lighting nil`). Lights live at `Levels.{1,2}.Lights.Lights`. (b) Only **388 Light instances** (384 SurfaceLight, 4 PointLight) for the whole RAC. High-bays 36, troffer 2x2 144, 2x4 70, downlight 96. (c) SurfaceLight brightness **0.25–4**, range **3–56**. The **0.25/3** lights are cardio **screens** (`Rower` 0.25/3, bikes/ellipticals ~0.35–0.45), not fixtures — they still emit. Stair/lobby downlights are 2.4/24 but placed at `floorY+11` and `floorY+22` **per level**. Level 2 stair rooms therefore get cans at **Y≈31 and 42**, above the stair volume; mid-flight stays black (matches stair-from-hall). (d) Rooms with min plan dimension &lt; 6 ft skip fixtures entirely. (e) `RACBuild` sets Future + ClockTime 14; fog is set in `Terrain.build` (FogStart 520). |
| **Evidence** | `inspect_site.luau` light dump; `Lights.luau` scatter; `LightingController.server.luau` lines 18–19; `Rower.luau` / `Downlight.luau` / `HighBayLight.luau`. Nested folder `Lights/Lights`. |
| **Fix** | Parent real fixtures under `RAC.Lighting.<Zone>` with `MasterMode` or delete the controller. Place stair lights along the flight (every ~8 ft of going), not two magic Ys. Raise corridor troffer brightness/range for Future. Do not skip small rooms that are occupied. Ignore equipment screens as room lighting. |

### 5. Empty / sparse rooms — not a screenshot-only complaint

| | |
|---|---|
| **Severity** | P0 |
| **Owner** | architect props in `blueprint/level1.json` + `level2.json`, `Build.luau` prop loop |
| **Area** | Offices, lockers, gyms, corridors, stairs |
| **Issue** | Prop models are counted by `Room` attribute. Dozens of programmed rooms have **0–3 props**. Stairs have **zero** furniture/signage. Private coach offices have 2 (desk+chair pattern). `south_gym`, `cage_gym`, `fitness_north` have 2. Construction rooms `addition` / `cage_lower_reserved` are empty sealed_concrete boxes. Lights are not counted as props. This matches “empty rooms / scattered cubicles”. |
| **Evidence** | `inspect_site.luau` SPARSE list (coach_*, locker_*, racquetball_*, corridor_*, stair_*, south_gym, fitness_north, …). Blueprint check only proves graph connectivity (`blueprint_check.txt`: 56+32 rooms reachable), not furnishing. |
| **Fix** | Per-room prop budgets from photos (IMG_0323–0327 offices; gym equipment density; lockers banks). Layout in rows, not scatter. Lived-in extras (bags, carts, bins) as additional kinds. |

### 6. “0 floating” vs 7 floating props — checker is blind

| | |
|---|---|
| **Severity** | P1 |
| **Owner** | `tools/check_geometry.luau`, prop kits (`Treadmill`, `WaterFountain`) |
| **Area** | Level 2 cardio / fountains |
| **Issue** | Hung-name heuristic (see intro) zeroes the floating bucket. Treadmill `Deck` sits at local Y=0.42 (bottom ~0.33 ft) with no feet to the floor. Fountain `Apron` bottom **1.80 ft**; `BackA` does reach Y=0 but is a 0.08 ft wall plate — basins still read as wall-hung with a gap if the wall isn’t flush. L2 copies sit at Y+20. |
| **Evidence** | `check_geometry.luau` `HUNG` list + `if b.hung or b.min[2] < 0.3`. `Treadmill.luau` Deck `Kit.at(0, 0.42, 0.45)`. Fountain dump: `Apron y=2.15 bottom=1.80`, L2 `Apron y=22.15 bottom=21.80`. |
| **Fix** | Check floating on **model AABB** vs floor slab, excluding only ceiling-mounted classes by attribute not substring. Add treadmill feet / fountain pedestal to Y=0. Re-open the 7 manager parts. |

### 7. Parking lots still grass; roads sit on raw lidar (too low)

| | |
|---|---|
| **Severity** | P0 |
| **Owner** | `Site/CountyHardscape.luau`, `Site/Terrain.luau`, lidar materials |
| **Area** | Exterior lots / Patriot Circle |
| **Issue** | With `planimetric` present, **`Hardscape.build` never runs** (`Site/Builder.luau`). `LotSlab`/`PavementSlab` counts in the rbxm are **0**. County patches are asphalt/concrete boxes 0.28 ft thick on `Heightfield.height`. Lidar **south bbox (z −580..−300) is majority grass (1279 vs 885 asphalt)**. Thin asphalt parts cannot hide grass voxels. County `grounded()` **drops any sample with height &gt; 8 ft**, so pavement near the building/roof lidar is missing. County Y stats: slabs **min −22.26, avg −1.24, max 27.19** vs FFE 0 — roads 20+ ft below the entrance. User item: roundabout too low vs lidar *and* vs the building; those are not the same datum. `terrain_relationship.json` FFE transect is 0 at the door and +20 at the west wing — hardscape does not stair-step to landings. |
| **Evidence** | `inspect_site.luau` county n=1401; `sample_lidar.py` south bbox; `CountyHardscape.luau` `centerY = H.height + 0.08`; `Builder.luau` planimetric branch. Nested `site.roads`/`areas` = 0 (OSM empty); parking is county patches + inferred stall markings only. |
| **Fix** | Classify voxels under parking/road polygons as Asphalt before WriteVoxels. Drape pavement to lidar **but clamp relative to building FFE / entrance landing** so the drop-off at the door is the stair, not a 20 ft cliff. Restore drive-aisle connectivity, islands, and lights (`site_lamp` props exist but lots still read as lawn). |

### 8. Trees are stacked Grass cylinders

| | |
|---|---|
| **Severity** | P1 |
| **Owner** | `Site/Landscape.luau` |
| **Area** | Site vegetation |
| **Issue** | 112 trees. Deciduous = 8 horizontal Grass discs; pine = 8 overlapping discs. Unnatural “plate stack” / pine shelves. Species is “template inferred, not surveyed” in Scene JSON. |
| **Evidence** | `Landscape.luau` `disc()` + `tree()`; inspect `trees 112`, `Crown` 896, Grass 898. |
| **Fix** | Replace with MeshParts / a small tree kit (trunk + irregular crown, or pine cones), or at least ellipsoid unions, not 8 cylinders. |

### 9. Entrance canopy is a thick Neon wedge; roof canopy was stripped

| | |
|---|---|
| **Severity** | P1 |
| **Owner** | `Site/Exterior.luau`, `Site/Prepare.luau`, `Build/Roofs.luau` |
| **Area** | South glass |
| **Issue** | Photos: thin dark metal cantilever. Build: **WedgePart Neon** 118×**2.2**×32 ft at Y=24.2 plus CornerCanopy 28×2.2×18, plus Neon columns. `Prepare.attachScene` **drops every `roof.type == "canopy"`** so `Roofs.build` never emits a canopy (inspect: 0 roof parts named Canopy; 8 flat roofs only). Dual systems (Exterior Neon vs Roofs steel soffit) diverge. |
| **Evidence** | `inspect_site.luau` EXT_CANOPY CFrames; `Exterior.luau` `canopyWedge` Material=Neon, `thick = 2.2`; `Prepare.luau` lines 146–156. |
| **Fix** | One canopy: thin (~0.25–0.5 ft) dark metal/wedge matching WEB_entrance_2, glass wrap, no Neon. Columns matte charcoal Metal not Neon. |

### 10. Stray / non-physical elements

| | |
|---|---|
| **Severity** | P2 |
| **Owner** | Exterior + lighting + architecture leftovers |
| **Area** | Entrance, fixtures, dual codepaths |
| **Issue** | 1081 Neon parts (canopy, columns, soffit lamps, LED emitters). Transparent `RACSign` glass + SurfaceGui. `LightingController` / `RACArchitecture` still assume a zoned `RAC.Lighting` tree that this builder does not create. `Lights` nested twice. Bike-rack pipes west of stair. Equipment SurfaceLights (range 3) pollute interiors. |
| **Evidence** | neon=1081; `Exterior.luau` RACSign Transparency=1; no Lighting child on RAC. |
| **Fix** | Neon only on actual emitters. Delete unused architecture lighting API or implement it. Inventory every Entrance child against WEB_entrance photos. |

### 11. Entrance stairs vs blueprint

| | |
|---|---|
| **Severity** | P1 |
| **Owner** | `Site/Exterior.luau`, `blueprint/site.json` `entrance` |
| **Area** | South stair / ramp |
| **Issue** | Blueprint: width 42, 10 risers, rise 7 in, run 1.15, rotationDeg −90, landingDepth 14. Exterior samples lidar at the foot and builds treads from that. If lidar at the probe is well below FFE 0, the flight becomes a long ramp-stair that still won’t match WEB_entrance_1/2 (wide concrete + rails). Interior `Stairs.build` only fills `Levels.1.Stairs` (306 parts); **Level 2 Stairs folder is empty** — L2 connections are the same L1 meshes, which is OK only if flights actually reach elevation 20. |
| **Evidence** | `site.json` entrance block; `inspect_site.luau` stairs L1=306 L2=0. Not re-measured against photos in this pass. |
| **Fix** | Lock top of exterior stair to FFE 0 / glass sill; match photo tread count and rail profile. Confirm interior two-flight main stair (user 01:40) independently of geometry QA. |

---

## User / manager complaint matrix

| Complaint | Status | Notes |
|---|---|---|
| Materials not applied (grey floors) | **Open / confirmed in rbxm** | White color + missing MaterialService |
| Grass inside building | **Open / confirmed in code + lidar** | 178 grass cells in footprint; 3-box clear |
| Lighting wrong | **Open / confirmed** | No Lighting folder; L2 stair lights at Y 31–42; 0.25/3 parasite lights |
| Empty rooms | **Open / confirmed** | Large SPARSE set |
| 7 floating props | **Open; QA cannot see them** | Hung substring; treadmill deck 0.33 ft up |
| Parking grass | **Open / confirmed** | South lidar 59% grass; no LotSlab |
| Roads too low | **Open / confirmed** | County Y min −22 vs FFE 0 |
| Trees unnatural | **Open / confirmed** | 8 Grass discs × 112 |
| Canopy wrong | **Open / confirmed** | 2.2 ft Neon; blueprint canopy roofs stripped |
| Stray elements | **Open** | Neon structure, dead Lighting API |

## What actually passed

- Blueprint graph: 56+32 rooms, 0 overlaps, 0 dead doors (`blueprint_check.txt`).
- Offline geometry checker: 0 reported issues — **do not treat as visual QA**.
- Floor *keys* are applied (`RACMaterial` on slabs). The failure is runtime appearance, not missing `floorMaterial` in JSON.
- County planimetric patches are asphalt/concrete (1075/455), not grass *parts* — the grass is **voxels + tree meshes**.
- `Materials.luau` assetIds exist; they are just not installed into the saved place.
