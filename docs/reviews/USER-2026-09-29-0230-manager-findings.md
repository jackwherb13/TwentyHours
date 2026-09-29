# Manager findings from the architect's verification screenshots (2026-09-29 02:30) — treat as REQUIRED, same as user items

Screens: verification/M1/user0140/*.png
1. **Materials are not applied.** The competition/volleyball gym floor renders grey-white instead of bright glossy maple with the Mason-green apron
   and gold lines; corridors, lobby, walls all read as flat grey plaster. The builder must actually apply src/ReplicatedStorage/RAC/Materials.luau +
   art/materials textures (MaterialVariants or Textures/SurfaceAppearance with correct studsPerTile) per room floorMaterial / wallFinish.
   Verify with close-up screenshots of each material.
2. **Grass/terrain inside the building** (hall-north.png: grass tufts in a corridor). Terrain must be cleared under the whole footprint
   (and under every slab/void) and grass decoration disabled there. No terrain may poke through any floor.
3. **Lighting inside is wrong**: some spaces nearly black (stair-from-hall.png), others flat. Place the real fixtures (high bays, troffers,
   downlights) with sensible brightness; Future lighting; no pitch-black interiors in daytime.
4. **Rooms still read as empty / scattered props** (coaches.png). Layouts must be arranged like a real space (cubicle rows, desks against
   walls, chairs at desks), not scattered objects.
5. **7 floating prop parts** (Level 2 water fountain, treadmill) — fix.
