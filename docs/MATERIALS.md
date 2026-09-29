# RAC material and branding handoff

All twelve material PNGs are generated photographic color/albedo assets, normalized to 1024×1024 RGB. Generation used the built-in image tool; exact final prompts and original paths are in `art/materials/generation.json`. Photos were inspected through `reference/sheets/photos_00.jpg` through `photos_04.jpg` for visual guidance only. No reference photograph, person, dedication, or real person's name is embedded in the assets.

One stud equals one foot. **studsPerTile is the physical side length of the entire square texture repeat**, not the size of an individual tile visible inside it. Sizes below are nominal production mappings from the task's tile dimensions and visual evidence; they are not new measured blueprint geometry. Contact sheets cannot establish exact manufacturer products or calibrated colors. Photographic lighting and render lighting will differ.

| Schema key | PNG under art/materials/ | Reference IMG_ | Repeat (ft) | Pattern / finish | Roughness target |
|---|---|---|---:|---|---:|
| maple | maple_court.png | 0332–0336 | 4 | Pale maple, roughly 3-inch strips, glossy varnish | .18 |
| terrazzo | terrazzo_corridor.png | 0314, 0339, 0343 | 4 | Warm grey-beige fine aggregate | .25 |
| porcelain_tile | porcelain_tile_12x24.png | 0316, 0319, 0329 | 4 | 12×24-inch tile, four courses, running bond | .32 |
| carpet_tile | carpet_tile_office.png | 0324, 0326 | 4 | Four nominal 24-inch charcoal/blue-grey carpet tiles | .95 |
| rubber | rubber_gym_floor.png | 0318, 0328 | 4 | Four 24-inch black rubber tiles, fine flecks | .90 |
| sealed_concrete | sealed_concrete.png | No close-up; inferred utility finish | 4 | Neutral sealed concrete, unjointed | .45 |
| ceramic_tile | ceramic_wall_tile.png | 0379–0381 | 2 | Six by six grid of 4-inch warm white tiles | .22 |
| vinyl | terrazzo_corridor.png | No distinct confirmed vinyl reference | 4 | Explicit speckled fallback; shares terrazzo color map | .40 |
| painted_cmu | painted_cmu.png | 0314, 0341 | 4 | Six courses of 8×16-inch off-white blocks | .70 |
| brick | brick_red.png | 0339, 0340, 0349 | 2 | Red-brown running bond; 8-inch nominal width, eight approx. 3-inch courses | .90 |
| gypsum | None; native Plaster | 0319, 0323 | 4 (unused) | Uniform off-white; texture=nil avoids false block joints | .80 |
| glass | None; native Glass | 0318, 0328, 0329 | 4 (unused) | Native glass; builder owns transparency | .08 |
| metal_panel | metal_panel_grey.png | 0352, 0358 | 4 | Horizontal grey ribs; generated seven-rib repeat, approx. 6.9-inch pitch | .40 |
| precast | sealed_concrete.png | 0349, 0350 | 4 | Concrete color-map fallback for exterior precast | .80 |
| acoustic_ceiling | acoustic_ceiling_2x2.png | 0319, 0323 | 2 | Single 24-inch white fissured mineral tile; builder supplies grid | .95 |
| mosaic_green (extra finish) | mosaic_green.png | 0340 | 2 | 24×24 array of approx. one-inch green/white tesserae | .20 |

`Materials.luau` exports these keyed records plus `Materials.apply(part, key)`. All `assetId` values are nil. Before upload, apply sets the Roblox base material, fallback color, clears stale MaterialVariant, and records RACMaterial/RACTexturePath/RACStudsPerTile/RACRoughness attributes. Unknown keys raise an error before changing the part. It does not change anchoring, collision, transparency, dimensions or other geometry.

The Studio owner can set e.g. `Materials.maple.assetId = "rbxassetid://<uploaded-color-map>"` and call apply again. It creates/reuses `MaterialService.RAC_maple`, assigns BaseMaterial, ColorMap and StudsPerTile, then applies the variant with white part tint to preserve albedo colors. No uploads or Studio actions were performed here. Roughness is a target scalar stored as metadata, **not an applied Roblox PBR roughness map**. The Studio owner must supply roughness/normal maps and validate orientation, scale, glass transparency and lighting. No reflectance trick or baked court-light reflections are used to simulate varnish.

Branding assets in `art/branding/`: `gm_logo.png` (green/gold GM-style monogram, transparent), `volleyball_wordmark.png` (green VOLLEYBALL, transparent), and `locker_room_sign.png` (white VOLLEYBALL / LOCKER / ROOM on opaque green). These are generated recreations, not traced official vector masters. All are 1024×1024; keep wordmark aspect ratio when applying. The sign contains no personal dedication. Final prompts are in `art/branding/generation.json`.

Offline reproduction and QA:

```powershell
python art/materials/check_textures.py --prepare
python art/materials/check_textures.py
lune run art/materials/materials.spec.luau
pwsh -NoProfile -File tools/verify.ps1
```

The preparation mode requires the original generated PNG paths in generation.json; ordinary checks use the committed workspace PNGs only. Pillow and NumPy are required. Preparation resizes, crops the incomplete brick course, and applies a 32-pixel cosine border correction to match opposite edges. The checker writes 2048×2048 2×2 repeats, `qa/PACKET.png`, and `qa/seams.json`. It requires edge RGB mean absolute error ≤2/255 and 95th percentile ≤6/255, and checks repair-band gradients against interior feature contrast. This numerical check supplements visual repeat inspection; it is not proof of in-game photo matching.

Verification: all 12 texture seam checks pass (both edge MAE and p95 are 0 after correction). All three branding size/alpha checks pass. `stylua --check` and Selene on Materials.luau pass, as does the offline Lune material test. The requested repo-wide verify.ps1 run passed Rojo, build/props tests, and Luau analysis. It failed formatting in other-owned Build/Facade.luau and unused-variable warnings in Props/FrontDesk.luau, TrashBin.luau, ExitSign.luau and RecycleBin.luau; these were left untouched. Full output is in `art/materials/verify.log` and checkpoints in `art/materials/PROGRESS.md`.

The initial blueprint check failed because blueprint/level1.json, level2.json and site.json were absent; render_plan.py consequently had no levels to render. Those files belong to other agents. Studio console, play tests and photo-station screenshots were intentionally not run under this task's offline-only restriction. Offline review images: `art/materials/qa/PACKET.png`, twelve `qa/*_2x2.png` repeats, and `art/branding/PACKET.png`.
