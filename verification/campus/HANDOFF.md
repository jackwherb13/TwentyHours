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
| origin `[x0, z0]` | `-1504, -1504` |
| step | **16 ft** |
| size | 188 × 188 cells (3008 × 3008 ft) |
| extent | x ∈ [-1504, 1504], z ∈ [-1504, 1504] |
| source | USGS 3DEP 1 m (meters NAVD88 → ft − floor datum) |

This box covers PV Lot (west), Angel Cabrera Global Center, EagleBank Arena, Field House, RAC Field, Mason Pond / Shenandoah decks, nearby residence halls, Campus Dr / Patriot Cir / Mason Pond Dr / Ox Rd / Global Ln / Banister Creek Ct.

## Horizon grid (owned by Horizon)

Live module: `src/ReplicatedStorage/RAC/Site/Horizon/HorizonData.luau` sampled by `Horizon/Height.luau`.

| | |
|---|---|
| origin `[x0, z0]` | `-6784, -6784` |
| step | **32 ft** |
| size | 424 × 424 cells (13568 × 13568 ft, ~1 mile beyond campus) |
| source | USGS 3DEP ImageServer 1/3″ (meters NAVD88 → ft − floor datum), blended onto campus 16 ft |

## Blend rule (no seam)

`Campus.Height.at(x,z)`:

1. If `(x,z)` is inside the fine rectangle, return **`Heightfield.height`** (the exterior 4 ft lidar field).
2. Otherwise bilinear-sample the 16 ft coarse DEM.

`Horizon.Height.at(x,z)`:

1. If inside the campus 16 ft box, return `Campus.Height.at`.
2. Otherwise bilinear-sample the 32 ft horizon DEM.

`Campus.Terrain.build` writes the coarse voxels first, then **calls `Site.Terrain.build`** so the overlap is bit-identical to the exterior agent. Do not resample the 4 ft grid from the 16 ft grid.

`Horizon.Terrain.build` writes 32 ft voxels **outside** the campus box, then calls `Campus.Terrain.build`.

Coarse cells whose centers fall in the fine rectangle were filled from the fine field during `tools/campus/prepare.py` (2500 blend cells) so a coarse-only sample also matches.

## How the site builder should call campus + horizon

`Site.Builder` is owned by the exterior agent. When integrating:

```luau
local Campus = require(script.Parent.Campus.Builder)
local Horizon = require(script.Parent.Horizon.Builder)
local campusModel, n = Campus.build(site) -- Model named "Campus"
local horizonModel, hn = Horizon.build(site) -- Model named "Horizon"
```

`Site.Builder` already requires `Campus.Builder`. **One-line wiring still needed:** after `Campus.build(grounded)`, add `Horizon.build(grounded)` (or `Horizon.build(context)`).

Edit-mode terrain + fog (Lighting is not in this folder):

```luau
require(game.ReplicatedStorage.RAC.Site.Horizon.Terrain).build(workspace.Terrain)
-- Atmosphere: density 0.28, offset 220, color (0.72, 0.76, 0.80) from Horizon model attributes FogDensity / FogOffset
```

Offline preview (does not touch `places/build.rbxm`):

`lune run tools/campus/build_preview.luau`

## What campus / horizon does not build

- The RAC shell, entrance, fine pavement, trees, and 4 ft DEM (exterior).
- Interiors of neighbour buildings.
- Lane paint / curbs inside the 800 ft fine box (those stay county hardscape).
- Lighting/Atmosphere instances (manager wires fog from Horizon attributes).
