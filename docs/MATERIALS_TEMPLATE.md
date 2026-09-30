# RAC material template

Single catalog every building part must use. Builder lookups (`floorMaterial`, `wallFinish`, `ceilingType` aliases, court paint, rails, signs) resolve only to these keys via `src/ReplicatedStorage/RAC/Materials.luau`. Color maps are CC0 ambientCG PBR, tinted to `data/inventory.json` photo samples. Photos are the color/scale/gloss reference, not the texture source.

1 stud = 1 ft. `StudsPerTile` is the real-world tile of the downloaded map after tint.

| name | used on | swatch | color map | variant | StudsPerTile | RGB | roughness | source photo | CC0 pack |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| maple | competition gym floor | art/materials/swatches/maple.jpg | art/materials/pbr/maple_color.png | RAC_maple | 8 | 210,186,158 | 0.14 | IMG_0332 | generated 2.25 in strip |
| racquetball_wood | racquetball / squash courts | art/materials/swatches/racquetball_wood.jpg | art/materials/pbr/racquetball_wood_color.png | RAC_racquetball_wood | 8 | 210,186,158 | 0.22 | IMG_0332 | generated 2.25 in strip |
| court_green_paint | gym apron, keys, logo field | art/materials/swatches/court_green_paint.jpg | art/materials/pbr/court_green_paint_color.png | RAC_court_green_paint | 8 | 22,52,36 | 0.14 | IMG_0334 | generated enamel |
| court_gold_paint | gym lines, GEORGE/MASON, logo ring | art/materials/swatches/court_gold_paint.jpg | art/materials/pbr/court_gold_paint_color.png | RAC_court_gold_paint | 8 | 198,176,80 | 0.16 | IMG_0334 | generated enamel |
| terrazzo | corridor floors | art/materials/swatches/terrazzo.jpg | art/materials/pbr/terrazzo_color.png | RAC_terrazzo | 6 | 140,132,122 | 0.08 | IMG_0314 | generated fine chip |
| porcelain_tile | lobby / hall 12×24 floors | art/materials/swatches/porcelain_tile.jpg | art/materials/pbr/porcelain_tile_color.png | RAC_porcelain_tile | 4 | 176,166,154 | 0.20 | IMG_0316 | generated 12×24 running bond |
| carpet_tile | office floors | art/materials/swatches/carpet_tile.jpg | art/materials/pbr/carpet_tile_color.png | RAC_carpet_tile | 4 | 78,76,74 | 0.94 | IMG_0324 | generated heather loop |
| rubber | fitness flooring | art/materials/swatches/rubber.jpg | art/materials/pbr/rubber_color.png | RAC_rubber | 4 | 184,176,160 | 0.16 | IMG_0318 | generated speckle |
| turf | lawn / turf strip | art/materials/swatches/turf.jpg | art/materials/pbr/turf_color.png | RAC_turf | 4 | 80,82,50 | 0.90 | IMG_0364 | Grass001 tinted |
| ceramic_tile | locker / shower walls | art/materials/swatches/ceramic_tile.jpg | art/materials/pbr/ceramic_tile_color.png | RAC_ceramic_tile | 2 | 168,154,128 | 0.16 | IMG_0379 | generated 4 in square |
| ceramic_floor_tile | locker / shower floors | art/materials/swatches/ceramic_floor_tile.jpg | art/materials/pbr/ceramic_floor_tile_color.png | RAC_ceramic_floor_tile | 2 | 168,158,144 | 0.26 | IMG_0378 | generated square |
| vinyl | support floors | art/materials/swatches/vinyl.jpg | art/materials/pbr/vinyl_color.png | RAC_vinyl | 4 | 176,166,154 | 0.28 | IMG_0316 | generated 12×24 plank |
| sealed_concrete | mechanical, footprint fill | art/materials/swatches/sealed_concrete.jpg | art/materials/pbr/sealed_concrete_color.png | RAC_sealed_concrete | 8 | 208,198,180 | 0.30 | IMG_0365 | generated sawcut slab |
| painted_cmu | interior walls | art/materials/swatches/painted_cmu.jpg | art/materials/pbr/painted_cmu_color.png | RAC_painted_cmu | 8 | 200,196,188 | 0.72 | IMG_0314 | generated stacked 8×16 |
| gypsum | office partitions / gypsum ceilings | art/materials/swatches/gypsum.jpg | art/materials/pbr/gypsum_color.png | RAC_gypsum | 8 | 200,200,202 | 0.80 | IMG_0314 | generated orange-peel |
| brick | interior accent walls + exterior brick | art/materials/swatches/brick.jpg | art/materials/pbr/brick_color.png | RAC_brick | 4 | 110,68,56 | 0.88 | IMG_0349 | generated running bond |
| metal_panel | exterior grey panels, fins | art/materials/swatches/metal_panel.jpg | art/materials/pbr/metal_panel_color.png | RAC_metal_panel | 4 | 136,142,150 | 0.36 | IMG_0359 | generated standing seam |
| precast | precast band, parapet | art/materials/swatches/precast.jpg | art/materials/pbr/precast_color.png | RAC_precast | 8 | 178,167,157 | 0.78 | IMG_0349 | generated exposed aggregate |
| acoustic_ceiling | 2×2 / 2×4 ACT (grid is separate T-bar) | art/materials/swatches/acoustic_ceiling.jpg | art/materials/pbr/acoustic_ceiling_color.png | RAC_acoustic_ceiling | 2 | 186,184,178 | 0.94 | IMG_0314 | generated ACT |
| steel | exposed joists / deck paint | art/materials/swatches/steel.jpg | art/materials/pbr/steel_color.png | RAC_steel | 4 | 208,204,198 | 0.50 | IMG_0332 | generated painted steel |
| glass | curtain wall, interior glass | art/materials/swatches/glass.jpg | — | — | 4 | 40,48,52 | 0.06 | IMG_0365 | Roblox Glass |
| mullion_aluminum | window / curtain-wall mullions | art/materials/swatches/mullion_aluminum.jpg | art/materials/pbr/mullion_aluminum_color.png | RAC_mullion_aluminum | 4 | 22,22,24 | 0.28 | IMG_0316 | generated dark bronze |
| door_wood | wood doors | art/materials/swatches/door_wood.jpg | art/materials/pbr/door_wood_color.png | RAC_door_wood | 4 | 198,188,177 | 0.42 | IMG_0324 | generated quiet maple |
| door_paint | hollow-metal door paint | art/materials/swatches/door_paint.jpg | art/materials/pbr/door_paint_color.png | RAC_door_paint | 4 | 100,98,86 | 0.38 | IMG_0339 | generated greige enamel |
| stainless | rail posts, stainless trim | art/materials/swatches/stainless.jpg | art/materials/pbr/stainless_color.png | RAC_stainless | 2 | 196,196,192 | 0.18 | IMG_0369 | generated brushed metal |
| mosaic_green | locker-entry mosaic | art/materials/swatches/mosaic_green.jpg | art/materials/pbr/mosaic_green_color.png | RAC_mosaic_green | 2 | 134,138,128 | 0.20 | IMG_0340 | generated 0.5 in tesserae |
| wood_cap_rail | balcony wood cap | art/materials/swatches/wood_cap_rail.jpg | art/materials/pbr/wood_cap_rail_color.png | RAC_wood_cap_rail | 4 | 186,160,120 | 0.36 | IMG_0369 | generated quiet maple |
| bleacher_green | bleacher seats (green bays) | art/materials/swatches/bleacher_green.jpg | art/materials/pbr/bleacher_green_color.png | RAC_bleacher_green | 4 | 32,42,38 | 0.48 | IMG_0332 | generated enamel |
| bleacher_gold | bleacher seats (gold bays) | art/materials/swatches/bleacher_gold.jpg | art/materials/pbr/bleacher_gold_color.png | RAC_bleacher_gold | 4 | 196,148,42 | 0.42 | IMG_0332 | generated enamel |
| sign_paint | door / room signs | art/materials/swatches/sign_paint.jpg | art/materials/pbr/sign_paint_color.png | RAC_sign_paint | 4 | 50,62,56 | 0.36 | IMG_0316 | generated hunter enamel |

## Builder mapping

- Room `floorMaterial` → same key (`maple`, `terrazzo`, `porcelain_tile`, `carpet_tile`, `rubber`, `ceramic_tile`, `vinyl`, `sealed_concrete`). Locker/restroom `ceramic_tile` floors map to `ceramic_floor_tile`.
- Room `wallFinish` → `painted_cmu`, `gypsum`, `ceramic_tile`, `brick`.
- Ceiling `act_2x2` / `act_2x4` → `acoustic_ceiling` (alias `acoustic`); `gypsum` → `gypsum`; `open_joist` deck/joists → `metal_panel` / `steel`.
- Court sheets → `court_green_paint`, `court_gold_paint`.
- Glazing → `glass` + `mullion_aluminum`.
- Guardrail → `stainless` bars, `wood_cap_rail` cap.

Normal and roughness maps live next to each color map (`*_normal.png`, `*_roughness.png`) and are assigned on the MaterialVariant after Studio upload.

License: ambientCG CC0. Process: `python art/materials/process_pbr.py`.
