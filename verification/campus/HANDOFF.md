# Campus ↔ exterior terrain handoff

Coordinate frame is the same as the exterior agent: **RAC south entrance door = (0,0,0)**, +X east, +Z south, 1 stud = 1 ft, `trueNorthDeg = 10.43`. Geographic conversion is `tools/site/prepare_site.py` (`geo` / `inverse` / `SHIFT`).

## Fine grid (owned by Site / exterior)

Live module: `src/ReplicatedStorage/RAC/Site/TerrainData.luau` sampled by `Heightfield.luau`.

| | |
|---|---|
| origin `[x0, z0]` | `-418.5249, -580.0041` |
| step | **4 ft** |
| size | 200 × 200 cells (800 × 800 ft) |
| extent | x ∈ [-418.5, 381.5], z ∈ [-580.0, 220.0] |
| source | USGS LPC VA_NorthernVA_B22 classified ground, floor datum 437.92 ft NAVD88 |

Edit-mode writer: `Site.Terrain.build(workspace.Terrain)`.

## Coarse grid (owned by Campus)

Live module: `src/ReplicatedStorage/RAC/Site/Campus/CampusData.luau` sampled by `Campus/Height.luau`.

| | |
|---|---|
| origin `[x0, z0]` | `-880, -640` |
| step | **16 ft** |
| size | 112 × 128 cells (1792 × 2048 ft) |
| extent | x ∈ [-880, 912], z ∈ [-640, 1408] |
| source | USGS 3DEP 1 m (meters NAVD88 → ft − floor datum) |

This box covers EagleBank Arena (~z 1165), Mason Pond / Global Center, Field House, West PE Module, RAC Field, and the Mason Pond parking deck.

## Blend rule (no seam)

`Campus.Height.at(x,z)`:

1. If `(x,z)` is inside the fine rectangle, return **`Heightfield.height`** (the exterior 4 ft lidar field).
2. Otherwise bilinear-sample the 16 ft coarse DEM.

`Campus.Terrain.build` writes the coarse voxels first, then **calls `Site.Terrain.build`** so the overlap is bit-identical to the exterior agent. Do not resample the 4 ft grid from the 16 ft grid.

Coarse cells whose centers fall in the fine rectangle were filled from the fine field during `tools/campus/prepare.py` (2500 blend cells) so a coarse-only sample also matches.

## How the site builder should call campus

`Site.Builder` is owned by the exterior agent. When integrating:

```luau
local Campus = require(script.Parent.Campus.Builder)
local campusModel, n = Campus.build(site) -- Model named "Campus"
```

Offline preview (does not touch `places/build.rbxm`):

`lune run tools/campus/build_preview.luau`

Edit-mode terrain:

```luau
require(game.ReplicatedStorage.RAC.Site.Campus.Terrain).build(workspace.Terrain)
```

## What campus does not build

- The RAC shell, entrance, fine pavement, trees, and 4 ft DEM (exterior).
- Interiors of neighbour buildings.
- Lane paint / curbs inside the 800 ft fine box (those stay county hardscape).
