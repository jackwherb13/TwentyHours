# RAC material template

Single catalog every building part must use. Builder lookups (`floorMaterial`, `wallFinish`, `ceilingType` aliases, court paint, rails, signs) resolve only to these keys via `src/ReplicatedStorage/RAC/Materials.luau`. Color maps are CC0 ambientCG PBR, tinted to `data/inventory.json` photo samples. Photos are the color/scale/gloss reference, not the texture source.

1 stud = 1 ft. `StudsPerTile` is the real-world tile of the downloaded map after tint.

| name | used on | swatch | color map | variant | StudsPerTile | RGB | roughness | source photo | CC0 pack |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| maple | competition gym floor | art/materials/swatches/maple.jpg | art/materials/pbr/maple_color.png | RAC_maple | 8 | 220,196,164 | 0.12 | IMG_0332 | WoodFloor051 |
| racquetball_wood | racquetball / squash courts | art/materials/swatches/racquetball_wood.jpg | art/materials/pbr/racquetball_wood_color.png | RAC_racquetball_wood | 8 | 228,208,176 | 0.28 | IMG_0332 | WoodFloor062 |
| court_green_paint | gym apron, keys, logo field | art/materials/swatches/court_green_paint.jpg | art/materials/pbr/court_green_paint_color.png | RAC_court_green_paint | 8 | 28,70,40 | 0.18 | IMG_0334 | Paint001 |
| court_gold_paint | gym lines, GEORGE/MASON, logo ring | art/materials/swatches/court_gold_paint.jpg | art/materials/pbr/court_gold_paint_color.png | RAC_court_gold_paint | 8 | 214,172,44 | 0.20 | IMG_0332 | Paint002 |
| terrazzo | corridor floors | art/materials/swatches/terrazzo.jpg | art/materials/pbr/terrazzo_color.png | RAC_terrazzo | 6 | 188,178,166 | 0.14 | IMG_0314 | Terrazzo001 |
| porcelain_tile | lobby / hall 12×24 floors | art/materials/swatches/porcelain_tile.jpg | art/materials/pbr/porcelain_tile_color.png | RAC_porcelain_tile | 4 | 186,180,172 | 0.22 | IMG_0316 | generated 12×24 running bond |
| carpet_tile | office floors | art/materials/swatches/carpet_tile.jpg | art/materials/pbr/carpet_tile_color.png | RAC_carpet_tile | 4 | 68,67,66 | 0.95 | IMG_0324 | Carpet008 |
| rubber | fitness flooring | art/materials/swatches/rubber.jpg | art/materials/pbr/rubber_color.png | RAC_rubber | 4 | 173,164,148 | 0.90 | IMG_0318 | Rubber002 |
| turf | fitness turf strip | art/materials/swatches/turf.jpg | art/materials/pbr/turf_color.png | RAC_turf | 4 | 77,84,47 | 0.90 | IMG_0364 | Grass001 |
| ceramic_tile | locker / shower walls | art/materials/swatches/ceramic_tile.jpg | art/materials/pbr/ceramic_tile_color.png | RAC_ceramic_tile | 2 | 232,224,210 | 0.22 | IMG_0379 | Tiles107 |
| ceramic_floor_tile | locker / shower floors | art/materials/swatches/ceramic_floor_tile.jpg | art/materials/pbr/ceramic_floor_tile_color.png | RAC_ceramic_floor_tile | 2 | 196,180,160 | 0.28 | IMG_0378 | Tiles001 |
| vinyl | support floors | art/materials/swatches/vinyl.jpg | art/materials/pbr/vinyl_color.png | RAC_vinyl | 4 | 184,176,164 | 0.40 | IMG_0316 | Tiles002 |
| sealed_concrete | mechanical, footprint fill | art/materials/swatches/sealed_concrete.jpg | art/materials/pbr/sealed_concrete_color.png | RAC_sealed_concrete | 8 | 184,180,172 | 0.32 | IMG_0365 | Concrete034 |
| painted_cmu | interior walls | art/materials/swatches/painted_cmu.jpg | art/materials/pbr/painted_cmu_color.png | RAC_painted_cmu | 8 | 210,206,200 | 0.70 | IMG_0314 | Bricks093 |
| gypsum | office partitions / gypsum ceilings | art/materials/swatches/gypsum.jpg | art/materials/pbr/gypsum_color.png | RAC_gypsum | 8 | 220,220,222 | 0.80 | IMG_0314 | Plaster003 |
| brick | interior accent walls + exterior brick | art/materials/swatches/brick.jpg | art/materials/pbr/brick_color.png | RAC_brick | 4 | 120,84,68 | 0.90 | IMG_0349 | Bricks059 |
| metal_panel | exterior grey panels, fins | art/materials/swatches/metal_panel.jpg | art/materials/pbr/metal_panel_color.png | RAC_metal_panel | 4 | 145,150,153 | 0.40 | IMG_0359 | Metal032 |
| precast | precast band, parapet | art/materials/swatches/precast.jpg | art/materials/pbr/precast_color.png | RAC_precast | 8 | 184,170,156 | 0.80 | IMG_0349 | Concrete034 |
| acoustic_ceiling | 2×2 / 2×4 ACT (grid is separate T-bar) | art/materials/swatches/acoustic_ceiling.jpg | art/materials/pbr/acoustic_ceiling_color.png | RAC_acoustic_ceiling | 2 | 208,206,200 | 0.95 | IMG_0339 | generated ACT |
| steel | exposed joists / deck paint | art/materials/swatches/steel.jpg | art/materials/pbr/steel_color.png | RAC_steel | 4 | 48,50,52 | 0.45 | IMG_0332 | Metal032 |
| glass | curtain wall, interior glass | — | — | — | 4 | 208,225,224 | 0.08 | IMG_0368 | Roblox Glass |
| mullion_aluminum | window / curtain-wall mullions | art/materials/swatches/mullion_aluminum.jpg | art/materials/pbr/mullion_aluminum_color.png | RAC_mullion_aluminum | 4 | 48,50,54 | 0.32 | IMG_0316 | brushed metal |
| door_wood | wood doors | art/materials/swatches/door_wood.jpg | art/materials/pbr/door_wood_color.png | RAC_door_wood | 4 | 122,87,48 | 0.55 | IMG_0329 | Wood051 |
| door_paint | hollow-metal door paint | art/materials/swatches/door_paint.jpg | art/materials/pbr/door_paint_color.png | RAC_door_paint | 4 | 76,81,86 | 0.50 | IMG_0378 | Paint002 |
| stainless | rail posts, stainless trim | art/materials/swatches/stainless.jpg | art/materials/pbr/stainless_color.png | RAC_stainless | 2 | 180,184,186 | 0.22 | IMG_0329 | Metal021 |
| mosaic_green | locker-entry mosaic | art/materials/swatches/mosaic_green.jpg | art/materials/pbr/mosaic_green_color.png | RAC_mosaic_green | 2 | 168,176,162 | 0.20 | IMG_0340 | Tiles023 |
| wood_cap_rail | balcony wood cap | art/materials/swatches/wood_cap_rail.jpg | art/materials/pbr/wood_cap_rail_color.png | RAC_wood_cap_rail | 4 | 168,132,88 | 0.50 | IMG_0369 | Wood051 |
| bleacher_green | bleacher seats (green bays) | art/materials/swatches/bleacher_green.jpg | art/materials/pbr/bleacher_green_color.png | RAC_bleacher_green | 4 | 30,35,31 | 0.55 | IMG_0332 | Paint001 |
| bleacher_gold | bleacher seats (gold bays) | art/materials/swatches/bleacher_gold.jpg | art/materials/pbr/bleacher_gold_color.png | RAC_bleacher_gold | 4 | 160,108,32 | 0.50 | IMG_0332 | Paint002 |
| sign_paint | door / room signs | art/materials/swatches/sign_paint.jpg | art/materials/pbr/sign_paint_color.png | RAC_sign_paint | 4 | 0,70,36 | 0.40 | IMG_0339 | Paint001 |

## Builder mapping

- Room `floorMaterial` → same key (`maple`, `terrazzo`, `porcelain_tile`, `carpet_tile`, `rubber`, `ceramic_tile`, `vinyl`, `sealed_concrete`). Locker/restroom `ceramic_tile` floors map to `ceramic_floor_tile`.
- Room `wallFinish` → `painted_cmu`, `gypsum`, `ceramic_tile`, `brick`.
- Ceiling `act_2x2` / `act_2x4` → `acoustic_ceiling` (alias `acoustic`); `gypsum` → `gypsum`; `open_joist` deck/joists → `metal_panel` / `steel`.
- Court sheets → `court_green_paint`, `court_gold_paint`.
- Glazing → `glass` + `mullion_aluminum`.
- Guardrail → `stainless` bars, `wood_cap_rail` cap.

Normal and roughness maps live next to each color map (`*_normal.png`, `*_roughness.png`) and are assigned on the MaterialVariant after Studio upload.

License: ambientCG CC0. Process: `python art/materials/process_pbr.py`.
