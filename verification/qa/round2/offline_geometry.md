# Round 2 offline geometry QA

Offline-only. Did not edit `blueprint/`, `src/`, or the RAC model. Source model: `places/build.rbxm`. Tools: `lune run tools/check_geometry.luau places/build.rbxm blueprint` (re-run this round, 0 issues), `verification/qa/gen1-round2/inspect_offline.luau`, ad-hoc Lune dumps, `python` on `blueprint/*.json` and `verification/exterior/terrain_grid.json`. `tools/side_by_side.py` was not executed (no new photo-station captures in this pass).

## Verdict

The automated geometry gate is **green and incomplete**. The build is **over the AGENTS 25k part budget**, materials are **partially applied**, stairs exist in JSON with a **Level 2 main-stair polygon mismatch**, and parking/roads exist as **site slabs vs lidar classification** with **bbox offset**, not as `blueprint/site.json` polylines.

## Part budget (issue)

From `verification/qa/round2/build.txt` (matches a live deserialize: 32323 BaseParts):

| Category    | Count |
|-------------|------:|
| Lighting    | 13255 |
| Props       |  8865 |
| Walls       |  4505 |
| Ceilings    |  2568 |
| SiteContext |  2389 |
| Stairs      |   297 |
| Court       |   206 |
| Floors      |   135 |
| Roofs       |    49 |
| Facade      |    41 |
| Columns     |    12 |
| Spawn       |     1 |
| **Total**   | **32323** |

- **AGENTS.md** hard rule: whole map **&lt; 25k** parts. **32323 exceeds that by 8323.** Treat as a required issue.
- **docs/SPEC.md** later says ≤40k (shell ≤12k, props ≤20k, exterior ≤6k + ≤4k neighbours). 32323 is under 40k but Lighting+Props alone (22120) already blow the 25k rule.
- Lighting folder is 13255 parts vs **1078 actual lights** (526 SurfaceLight, 552 PointLight). Fixtures are over-tessellated; 1485 Neon parts.
- `tests/build.spec.luau` still asserts `partCount < 25000`; this rbxm would fail that test.

## Geometry QA vs manager floating props

Re-run `tools/check_geometry.luau` on `places/build.rbxm`:

```
degenerate 0  doorBlocked 0  floating 0  zfight 0  intersect 0  gap 0
32323 parts checked, 0 issues
```

That matches `build.txt`. It does **not** contradict manager finding **7 floating props (Level 2 water fountain, treadmill)** (`docs/reviews/USER-2026-09-29-0230-manager-findings.md`).

Why the checker reports 0:

1. **`isHung` substring list** (`tools/check_geometry.luau` `HUNG`) treats names containing `rail`, `pad`, `board`, `cabinet`, `shelf`, `deck`, `cladding`, `grid`, etc. as hung, so they never get a support test.
2. Water fountains / treadmills are **explicitly not hung** when the path contains `.props.` plus `waterfountain`/`treadmill`, but **support is AABB-only**: any overlapping sibling at the same Y (pedestal, deck, other treadmill parts) counts as “supported.” Nested fountain bowls/aprons sit on each other; the model as a whole is not tested against the slab.
3. Skip `min.Y < 0.3` only excuses Level 1. L2 fountain **Pedestal/BackA/Trap** bottoms are **exactly 20.00** (L2 FF). Console/bowl parts sit at 21–25 ft by design. Checker cannot see “this assembly should rest on the floor” vs “this mesh is mid-air.”
4. Live dump: L1 fountain Pedestal at y=0; L2 fountain Pedestal at y=20. Treadmill part bottoms range **−0.06 … 24.96** (belt vs console). **150 treadmill parts** have bottoms between 0.4 and 19.7 ft — mostly L1 consoles (~4 ft), not a floating deck. Manager’s 7-count is still **open as a visual/assembly issue**; the tool is the wrong oracle.

**QA gap:** `check_geometry` floating = per-part AABB rest, not per-prop world-bottom vs room elevation. Do not treat “0 floating” as a close of manager item 5.

Walkthrough script: `Walkthrough check: PASS; 0 failures` in `build.txt`.

## Materials

`src/ReplicatedStorage/RAC/Materials.luau` defines maple, terrazzo, porcelain_tile, carpet_tile, rubber, sealed_concrete, ceramic_tile, vinyl, painted_cmu, brick, gypsum, glass, metal_panel, precast, acoustic_ceiling, mosaic_green. `apply()` sets `Material`, `Color`, `RACMaterial` / texture attributes, reflectance (maple 0.38), and `MaterialVariant = "RAC_" .. key` when `assetId` is set. `install()` would create MaterialVariants in MaterialService.

**In the rbxm:**

- **3846 / 32323** parts have `RACMaterial`. **29076** have empty `MaterialVariant`.
- **No MaterialVariant instances** inside `places/build.rbxm` (no MaterialService payload). Variants only work if Studio/Rojo supplies `src/MaterialService/RAC_*.model.json`. Offline rbxm + play-without-Rojo → **base materials + tint only**.
- Floor slabs **do** call apply: gym `competition_gym.Slab` is WoodPlanks / `RAC_maple` / rac=maple / color ≈ (232,204,156) / size 115×0.5×93.5. Counts: maple 9 slabs, terrazzo 24, porcelain 13, carpet 26, rubber 7, sealed_concrete 27+24 footprint, ceramic 5, painted_cmu 277, brick 156, metal_panel 2356, acoustic_ceiling 67, etc.
- **Court paint is not maple wood:** 206 court letter/line/apron parts tagged `RACMaterial=maple` are **SmoothPlastic, empty variant, reflectance 0.12**. Aprons (ApronNorth/South/East/West) are plastic, not Mason-green. Matches manager: gym reads grey-white unless the slab variant actually renders.
- Dominant materials by count: Metal 20866, SmoothPlastic 4837, Neon 1485, Concrete 1393, Glass 910, Rubber 881 — not the photo finishes.
- `mosaic_green` is defined in Materials.luau; **0 parts** in the rbxm use it.

Manager item 1 (materials not applied) remains **partially true**: attributes exist on floors/walls; **court graphics, most props, canopy (SmoothPlastic), and missing MaterialService in the rbxm** still fail the photo bar.

## Stairs in blueprint JSON

`verification/qa/round2/blueprint_check.txt`: `stairs: 3 checked`. Graph only (reachability). It does **not** check flight run/rise, landing continuity, or L1/L2 polygon agreement (`verify_blueprint.py` same gap as gen1-round3).

**Level 1** (`blueprint/level1.json` `stairs[]` + `blueprint/stair_details.json`): three stairs, each two 17-riser flights + mid landing, total 34 risers, rise **0.588235… ft** (7.06 in), 34×rise = **20 ft** = L2 elevation. Widths 8 / 6 / 6 ft. Runs ~0.83–0.85 ft/tread.

| id | L1 polygon (xz) | flights |
|----|-----------------|---------|
| stair_main | (−106,−54)…(−78.5,−16) | main_a, main_b + main_turn @ 10 ft |
| stair_second | (−339.5,−132.5)…(−305,−92.5) | second_a/b + second_turn |
| stair_west | (−357.5,−80)…(−345,−34) | west_a/b + west_turn |

**Level 2** lists the same three ids but **no `flights` / `landings`**. `stair_second` and `stair_west` polygons match L1. **`stair_main` L2 polygon is (−78.5,−32)…(−42.5, 0) — shifted ~36 ft east of the L1 well (−106…−78.5).** That is a blueprint defect: L2 opening is not over the L1 stair. Build has 297 Stair-category parts (477 if counting named children); Y span about −0.5 … 30.1 ft.

IBC-ish rise is fine; **L2 main stair hole is not**.

## Parking / roads vs lidar

`blueprint/site.json` has **no `roads` or parking areas** (keys: units, trueNorthDeg, origin, footprint, levels, facade, roofs, calibration). Roads/parking come from county GIS baked into terrain + Site.Context slabs.

`verification/exterior/terrain_grid.json`:

- Grid: x0=−592, z0=−448, 200×200, step **4 ft**, cell centers, trueNorthDeg **10.43** (matches site.json).
- Heights −31.91 … 28.84 ft vs L1 datum (NAVD88 437.92; method: ground 30 ft south of entrance + 10×7 in risers — not a surveyed threshold).
- Classification: VGIN RGB + county road/sidewalk polygons. sourceCounts: Roadways_and_Bridges **1**, Driveways_and_Parking_Lots **23**, Buildings 2, impervious 66.
- Cell classes (40k cells): **1** 21203 (veg), **2** 9229 (asphalt/road/parking, 23%), **3** 9282 (walk/pad), **4** 148 (swale), **5** 138.
- Class-2 bbox (cell centers): x **[−590, 206]**, z **[−446, 350]**.

Build Site.Context:

- **1002 LotSlab** (Asphalt), aabb x **[−418.4, 381.4]**, z **[−579.9, 219.9]**, y **[−22.6, 27.3]**.
- **395 PavementSlab**, same xz envelope, y **[−18, 27]**.
- **0 trees** named `Tree_*/Trunk` in this rbxm (lidar_trees.json exists on disk but is not in the model).
- **0 grass BaseParts** in the rbxm (manager grass-in-corridor is Terrain/decoration in Studio, not these parts).

**Misalignment:** lot/pavement box is shifted **~+170 ft in X and ~−130 ft in Z** relative to class-2 lidar/county mask, and extends farther +X / −Z than the 4 ft grid. Same true-north, different origin/crop. Cannot claim parking lots sit on classified asphalt without a cell-by-cell overlay (not run: would need sampling LotSlab centers against `materials[]`).

`tools/side_by_side.py`: `python tools/side_by_side.py <reference.jpg> <build.png> <out.jpg> [label]` — 900 px height, REAL vs ROBLOX BUILD. Use for entrance/parking photos (IMG_0356–0360, IMG_0364–0368) after Studio captures; not used this round.

## Blueprint check (context)

```
level1: 58 rooms, 146 walls, 100% axis-aligned, 0 overlaps
level1: 57/58 rooms reachable, 0 dead doors
level2: 32 rooms, 103 walls, 100% axis-aligned, 0 overlaps
level2: 32/32 rooms reachable, 0 dead doors
stairs: 3 checked
```

57/58 is expected `cage_lower_reserved` (construction). Not a geometry pass.

Empty rooms in rbxm (no prop with Room attribute): `addition`, `mechanical_l2`, `cage_lower_reserved`, plus false-positive `FootprintSlab`.

## Open issues (offline)

1. **32323 parts &gt; 25k AGENTS budget** — Lighting 13255 is the main overbuild.
2. **Geometry QA 0 floating ≠ manager 7 floating props** — hung-name and intra-assembly support hide fountain/treadmill problems.
3. **Materials incomplete** — floor variants named but not serialized; court/aprons SmoothPlastic; rbxm has no MaterialService; mosaic_green unused.
4. **L2 `stair_main` polygon does not overlay L1 stair well.**
5. **Parking/roads not in site.json;** LotSlab vs terrain class-2 bbox offset; no trees in build.
6. Canopy still SmoothPlastic; manager lighting/empty-rooms need Studio, not this dump.

`verification/qa/round2/reviewer.json` / `reviewer.err` are empty this round.
