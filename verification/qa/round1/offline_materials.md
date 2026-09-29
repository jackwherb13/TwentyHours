# Offline QA — materials, lighting, props, exterior (round 1)

Independent audit. No edits to `blueprint/`, `src/`, or the RAC model. Evidence from source, `places/build.rbxm` (14714 parts, `verification/qa/round1/build.txt`), and `lune` inspect (`verification/qa/round1/inspect_build.luau`).

**Verdict:** Manager items 1–4 still open. Item 5 (7 floating parts) is **not reproduced** on the current rbxm (`check_geometry`: 0 floating).

---

## How floors/walls get materials (builders)

`Floors.build` passes `room.floorMaterial` into `Parts.box`. `Walls.build` uses **`wall.material`**, not `room.wallFinish`. `Ceilings.build` maps `act_2x2`/`act_2x4` → finish `"acoustic"`, `gypsum` → `"gypsum"`. Footprint fill uses `"sealed_concrete"`.

`Parts.luau` is a **separate** finish table. It sets `part.Material` + a **string** `MaterialVariant` (`RAC_Maple`, `RAC_Terrazzo`, …). It does **not** `require` `Materials.luau`. Repo-wide grep: **`Materials.apply` is never called** except the offline smoke test `art/materials/materials.spec.luau`.

`Materials.luau`: all `assetId = nil`, so even `apply()` would only set base material + color + attributes and **return before creating a ColorMap**. Variant names also disagree (`RAC_maple` vs Parts `RAC_Maple`).

`Build/README.md` still documents texture-backed variants as Studio-owner work. That is the grey gym floor.

`places/build.rbxm` slabs:

| Count | Part | Roblox material | MaterialVariant |
|------:|------|-----------------|-----------------|
| 6 | Slab | WoodPlanks | `RAC_Maple` |
| 23 | Slab | Marble | `RAC_Terrazzo` |
| 12 | Slab | Slate | `RAC_PorcelainTile` |
| 26 | Slab | Fabric | `RAC_CarpetTile` |
| 8 | Slab | Rubber | `RAC_Rubber` |
| 5 | Slab | Slate | *(empty — ceramic_tile)* |
| 29 | Slab | Concrete | *(empty — sealed_concrete)* |
| 13 | FootprintSlab | Concrete | *(empty)* |

14211 / 14714 parts have empty `MaterialVariant`. Competition gym slab: `WoodPlanks` + `RAC_Maple` + tan `Color3(0.84, 0.69, 0.49)`, size 115×0.5×147. No `MaterialService` ColorMap → default wood grain / grey-tan, not `art/materials/maple_court.png`. No Mason-green apron or gold lines in the blueprint builder (those exist only in legacy `Modules/RACProps.luau`, which this pipeline does not run).

---

## Room schedule: `floorMaterial` vs what the builder does

Key: **applied** = `Parts.finishes[floorMaterial]` exists; **texture** = PNG via `Materials.apply` (never); **variant string** = Parts table.

### Level 1 (56 rooms)

| id | floorMaterial | wallFinish (unused by Walls) | Parts floor result | props |
|---|---|---|---|---|
| competition_gym | maple | painted_cmu | WoodPlanks + `RAC_Maple` (no map) | 9 (no pads, no court paint, no lights) |
| south_gym | maple | painted_cmu | same | hoop + scoreboard |
| office_ne_1…5, office_ne_reception | carpet_tile | gypsum | Fabric + `RAC_CarpetTile` | desk+chair |
| restroom_ne_w/m, volleyball_washroom | ceramic_tile | painted_cmu | Slate, **no variant** | partition+sink |
| fitness_north | rubber | gypsum | Rubber + `RAC_Rubber` | 1 treadmill |
| lobby, lobby_north, glazed_recreation, south_vestibule, corridor_wide, training_room, nutrition_vestibule, lockers, team_support | porcelain_tile | gypsum or painted_cmu | Slate + `RAC_PorcelainTile` | sparse |
| fitness_center, weight_room, fitness_annex | rubber | gypsum | Rubber + `RAC_Rubber` | cardio/racks (thin) |
| corridors (gym_east, entry_*, thin_link, athletic, main, west, office, service, ne) | terrazzo | mostly painted_cmu | Marble + `RAC_Terrazzo` | mostly 1 trash_bin |
| stair_main, stair_second, stair_west, storage_athletic, training_store, mechanical_sw, addition, cage_lower_reserved | sealed_concrete | painted_cmu | Concrete, **no variant** | stairs empty |

Coach block: `coach_head/west/west_n/north/east_*` = carpet + desk+chair only. `coach_suite` = 4 cubicles + board/mail/clock/nameplate, **no chairs at cubicles**.

### Level 2 (35 rooms)

Maple: `racquetball_1/2` (each a **water_fountain** only), `cage_gym` (hoop+scoreboard). Rubber cardio galleries. Terrazzo corridors + trash. Carpet offices desk+chair. Stairs/voids/mechanical empty. `void_*` sealed_concrete (void rooms skipped for slabs; holes).

`wallFinish` is stored but **never read** by Walls/Floors/Ceilings. Wall color comes from `level.walls[].material` (L1: 51 painted_cmu, 29 brick, 26 gypsum).

Ceiling ACT uses Parts key `"acoustic"` → `RAC_AcousticTile`; Materials key is `acoustic_ceiling`. Mismatch.

---

## Issues

### MAT-01 — Materials.luau / art textures never applied
- **severity:** critical
- **owner:** builder
- **area:** materials
- **issue:** Gym/corridor/lobby/walls read as untextured Roblox bases. `Materials.apply` unused; all `assetId` nil; Parts variant names (`RAC_Maple`) ≠ Materials (`RAC_maple`).
- **evidence:** `src/ReplicatedStorage/RAC/Build/Parts.luau`; `Materials.luau` lines 157–160 early return; rbxm gym slab WoodPlanks+`RAC_Maple`; 14211 empty variants; manager hall/gym greys.
- **fix:** Call `Materials.apply(part, key)` from `Parts.box` (and site primitives where relevant). Upload PNGs, set `assetId`, align names (`RAC_maple` vs `RAC_Maple`). Add court apron/lines as decals or extra parts. Apply `room.wallFinish` on interior faces.

### MAT-02 — ceramic_tile / sealed_concrete / gypsum / vinyl have no variant in Parts
- **severity:** major
- **owner:** builder
- **area:** materials
- **issue:** Restroom ceramic (5 slabs) and utility concrete (29+13) are bare Slate/Concrete. Gypsum plaster has no texture (OK if intended). Vinyl unused.
- **evidence:** Parts.luau finishes table; rbxm floor counts.
- **fix:** Add variants + `Materials.apply` for ceramic_tile, sealed_concrete; map ACT to `acoustic_ceiling`.

### LIT-01 — No architectural lighting in blueprint; stairs unlit
- **severity:** critical
- **owner:** architect (placement) / builder (emit)
- **area:** lighting
- **issue:** Zero `troffer_2x4`, `troffer_2x2`, `high_bay_light`, `downlight` in `level1.json`/`level2.json` props. Stair rooms have **no props**. rbxm: 34 SurfaceLights, all equipment screens / cubicle task / fridge / trophy / scoreboard — **none** are ceiling fixtures. `RAC.Lighting` folder is nil in the rbxm. Stairs `ceilingType: none` + no lights → pitch black with GlobalShadows (manager `stair-from-hall.png`).
- **evidence:** prop kind counters; inspect `-- lights by host --`; `Build.luau` places props at `level.elevation` only; HighBay/Troffer modules exist but are never registered in JSON.
- **fix:** Emit grid of high-bays in open-joist gyms, 2x4 troffers on ACT rooms, downlights in gypsum/lobby, wall/stair lights on flights. Wire `LightingController` zones. Future lighting is set only in unused `BuildAll.luau`.

### LIT-02 — Dual build pipeline
- **severity:** major
- **owner:** builder
- **area:** process
- **issue:** `ServerScriptService/RACBuild.server.luau` still runs `Modules/BuildAll` (old RACArchitecture + RACProps courts at hardcoded coords). Blueprint `Build.build` is only `tools/build_rac.luau`. Studio Play can show a different building than `places/build.rbxm`.
- **evidence:** RACBuild.server.luau lines 36–57 vs tools/build_rac.luau.
- **fix:** Point Play/build at blueprint `Build.build` + Site.Builder; do not mix pipelines.

### TER-01 — Grass/terrain under footprint not carved; site context not built
- **severity:** critical
- **owner:** site
- **area:** terrain / exterior
- **issue:** `Terrain.luau` writes DEM materials (Grass/Asphalt/…) with **no footprint Air carve**. `Builder.build` requires `rawSite.site`; `build_rac` passes `data.site` (flat `blueprint/site.json`), so **`if not rawSite.site then return 0`**. `SiteContext 0` in build.txt. Exterior/Landscape/Hardscape never run. Grass voxels can poke through slabs (manager hall-north.png). No grass **parts** in rbxm (voxels are Studio-only).
- **evidence:** `Site/Builder.luau` 8–10; `tools/build_rac.luau` 58; site.json keys: units, footprint, facade, roofs — **no** `entrance`, `trees`, `roads`, `planimetric`, `terrain.padPolygons`.
- **fix:** Pass the nested/full site payload (or drop the extra `.site`). Carve Air (or Concrete pad) under footprint + voids. Disable grass decoration inside the building.

### EXT-01 — Parking, trees, roads, canopy, entrance stairs absent in production model
- **severity:** critical
- **owner:** site / architect
- **area:** exterior
- **issue:** `Exterior.luau` implements landing, treads, apron, rails, ramp, tapered canopy, RAC sign, soffit PointLights — **dead code** until Builder gets a site with `entrance`. `Landscape.luau` trees/fences skipped. `CountyHardscape` needs `planimetric`. `blueprint/site.json` has none of this; county parking lives in `blueprint_interim/site.json` only.
- **evidence:** SiteContext 0; Site children in rbxm = Facade, Roofs only; grep of blueprint/site.json for trees/roads/entrance: none.
- **fix:** Merge exterior spec into the site the builder actually loads; then run Exterior/Landscape/County.

### PROP-01 — Empty / sparse rooms; coaches and training not lived-in
- **severity:** major
- **owner:** architect
- **area:** props
- **issue:** L1 122 props, L2 48. Pattern is desk+chair or a single trash_bin. `coach_suite` cubicles lack chairs/desks-at-walls. Private coach offices are two parts. Training: 4 tables + ice + 2 cabinets + desk — no taping tables, towels, kits, wall pads. Nutrition vestibule: fridge only. Gym: 1 volleyball_standard, 2 bleachers, 2 banners, cart, fountain, trash — **no wall_pad, no court lines, no high-bays**. south_gym/cage_gym: hoop+scoreboard. fitness_north: 1 treadmill. Stairs/addition/cage_lower/voids empty.
- **evidence:** prop lists above; manager coaches.png.
- **fix:** Layout furniture against walls; chairs at every desk/cubicle; densify training and gym (pads, standards both sides, balls, chairs on sideline).

### PROP-02 — Seven floating prop parts (manager) — not reproduced
- **severity:** minor (stale?)
- **owner:** builder
- **area:** props
- **issue:** Manager: L2 water fountain + treadmill floating. Current `tools/check_geometry.luau places/build.rbxm`: **floating 0**. Props pivot at floor (`Kit` origin bottom-center; fountain comment: “blueprint props have no elevation”). Lune AABB Position inspect failed (no default Position in rbxm deserializer) so visual Studio check still needed.
- **evidence:** `verification/qa/round1/build.txt` lines 16–21.
- **fix:** Re-verify in Studio at L2 cardio/racquetball. If still floating, snap `at` Y to slab top (`elevation`) and keep hung list from hiding fountain/treadmill.

### PROP-03 — Racquetball courts used as fountain rooms
- **severity:** minor
- **owner:** architect
- **area:** props
- **issue:** `racquetball_1/2` maple floors with only `water_fountain`. No squash/racquet props (`SquashCourt.luau` unused).
- **evidence:** L2 prop dump.
- **fix:** Place court kit or retag rooms.

---

## Lighting placement (how it actually works)

1. Blueprint props at `CFrame.new(x, level.elevation, z)` — lights would sit on the floor unless the prop module offsets Y internally (HighBay/Troffer do).
2. Fixture modules exist (`Props/HighBayLight`, `Troffer2x2`, `Troffer2x4`, `Downlight`) with downward `SurfaceLight` (high-bay brightness 2.5 range 40; 2x4 brightness 1.5 range 24; downlight 1.5/18). **Not in JSON.**
3. Kit `b:light` → `SurfaceLight`, Shadows = false.
4. Legacy `RACArchitecture` lighting zones + `LightingController` are unused by blueprint build.
5. Exterior soffit PointLights only if Exterior runs.

---

## Geometry QA (`places/build.rbxm`)

`lune run tools/check_geometry.luau` via `tools/build_rac.luau`: degenerate 0, doorBlocked 0, floating 0, zfight 0, intersect 0, gap 0. **Does not** check materials, lights, terrain, or empty rooms.

---

## Manager re-check

| Manager item | Status |
|---|---|
| Materials not applied (grey gym) | **Open** (MAT-01) |
| Grass inside building | **Open** as terrain/site-skip (TER-01); no grass parts in rbxm |
| Lighting wrong / dark stairs | **Open** (LIT-01) |
| Empty/scattered props | **Open** (PROP-01) |
| 7 floating parts | **Not in current rbxm** (PROP-02) |

---

## Suggested owners

- **builder:** MAT-01, MAT-02, LIT-02, Parts→Materials wiring, Play pipeline
- **architect:** LIT-01 fixture JSON, PROP-01/03 layouts, site JSON completeness for entrance
- **site:** TER-01, EXT-01, Builder payload, footprint carve
