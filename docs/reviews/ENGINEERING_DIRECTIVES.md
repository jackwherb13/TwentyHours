# Engineering directives from the manager (how to fix the problems that keep failing QA)

These are HOW-TO instructions. They override earlier approaches that did not work.

## Materials (architect) — root cause: textures never reach Roblox
1. Upload every texture in art/materials/*.png with the Roblox_Studio MCP (`upload_image` / `store_image`) and record the returned asset ids
   in art/materials/assets.json.
2. Author MaterialVariants as Rojo files so they sync into MaterialService: add `MaterialService` to preview.project.json and default.project.json
   (`"$ignoreUnknownInstances": true`, `$path`: `src/MaterialService`) and create one `src/MaterialService/RAC_<name>.model.json` per material:
   `{"className":"MaterialVariant","properties":{"BaseMaterial":"WoodPlanks","ColorMap":"rbxassetid://<id>","StudsPerTile":<real tile size ft>,
   "Name":"RAC_maple"}}` (plus NormalMap/RoughnessMap only if you have them).
3. In the builder, set `part.Material = base` and `part.MaterialVariant = "RAC_<name>"` and a realistic `part.Color` tint
   (NOT white (1,1,1) — maple ~#D8B98A glossy, terrazzo ~#B8B0A4, porcelain ~#AFA79C, carpet ~#44464A, painted CMU ~#E8E6E0).
   Court graphics (green apron, gold lines, lettering) = separate thin painted parts/decals ON the floor, offset 0.02 ft, never coplanar.
4. Verify with close-up screen_captures of each material; the judge must see maple wood grain in the gym.

## Terrain inside the building (exterior owns terrain, architect owns footprint)
- Terrain carving must be computed from the blueprint, not hard-coded boxes: for every room polygon + wall + slab, FillBlock Air from
  (floor - 1 ft) up to roof height; do this in the Site terrain script after writing voxels, and disable grass decoration under the footprint.
  Under parking lots and roads: write Asphalt/Concrete voxels (never Grass) and put hardscape parts on top.
- Add an automated check (lune or Studio execute_luau): sample Terrain:ReadVoxels over the footprint; any non-Air voxel above floor-1 ft = FAIL.

## Lighting (architect)
- Add Build/Lighting.luau that places fixtures from room data automatically: gyms = high_bay_light every ~20 ft at joist height; corridors/offices/
  lockers/training = troffer_2x4 / troffer_2x2 on the ACT grid every ~8 ft; lobby/double-height = downlights + pendants; stairs = wall packs at
  each landing. Put them in workspace.RAC.Lighting (LightingController expects that folder). SurfaceLight brightness ~1.5-3, range 16-40.
- Lighting service: Future, ExposureCompensation ~0, Ambient dark-neutral (~40,40,42) so interiors are lit by fixtures, not ambient.

## Collisions (architect)
- Furniture/fixture bodies that a player should not walk through (desks, counters, tables, racks, machines, lockers, benches) get
  CanCollide = true on their main body part (keep trim CanCollide false). Spawn location must be on open floor in the entry, not on props.

## Exterior specifics
- Canopy: thin dark wedge — ~1.5 ft at the glass tapering to ~0.3 ft at the tip, matte dark grey (not Neon), slender round columns, soffit dark with
  a few downlights; wraps the glass corner per WEB_entrance_2 / WEB_entrance_left_pole.
- Roads/lots: build hardscape on the terrain height sampled at each vertex (terrain_grid.json), asphalt voxels below, curbs 6 in high,
  stall stripes 4 in wide white, 9x18 ft stalls, 24 ft aisles, lot entrances connected to roads.
- Trees: 3-4 good templates (deciduous: trunk + 3-5 overlapping irregular ball/mesh clusters with slight color variation; pine: trunk + stacked
  cones, not discs), random rotation/scale 0.8-1.2, placed at lidar tree positions.
