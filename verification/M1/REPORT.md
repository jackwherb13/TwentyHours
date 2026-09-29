# M1 Blueprint — measured building data

The packet is `blueprint/level1.json`, `blueprint/level2.json`, and `blueprint/site.json`, in the shape documented by `docs/BLUEPRINT_SCHEMA.md` and restated in `blueprint/SCHEMA.md`. `tools/build_blueprint.py` regenerates it. Coordinates are feet, snapped to 0.5, on the building axes (+X east, +Z south). `site.json` `trueNorthDeg` is 10.43: plan north points 10.43° east of true north.

## Done when

**`python tools/verify_blueprint.py` prints no FAIL lines.** It prints:

```
level1: 31 rooms, 100 walls, 100% axis-aligned, 0 overlaps
level1: 30/31 rooms reachable, 0 dead doors
level2: 22 rooms, 71 walls, 100% axis-aligned, 0 overlaps
level2: 21/22 rooms reachable, 0 dead doors
```

Exit code 0. The one unreachable room on each level is the RAC Addition (`type: construction`). Mechanical rooms are reached by doors. Level 1 has an exterior door (`RACDoor` on the lobby east wall, plus a west stair exit). Level 1 has 100 walls, under the 350 cap. Level 2 has 71. No wall is under 2 ft.

**Court check within ±4%.** Scale is 0.7088 ft per pixel on `reference/site_plan_native.png`. Numbers are in `blueprint/calibration.json`.

| Check | Measured | Regulation | Error |
|---|---|---|---|
| Competition gym, east–west | 133 px = 94.27 ft | 94 ft | +0.29% |
| Competition gym, north–south | 71 px = 50.32 ft | 50 ft | +0.65% |
| South gym full court, north–south | 137.5 px = 97.46 ft | 94 ft | +3.68% |
| South gym full court, width | 69.6 px = 49.33 ft | 50 ft | −1.34% |
| South gym cross court | 115.0 px = 81.51 ft | 84 ft | −2.96% |
| Scale bar, row 625, x=164 to 308 | 144 px = 102.07 ft | 100 ft | +2.07% |

The largest miss is the south full-court length, +3.68%, inside the ±4% band. Using the OSM north-wall scale of 0.7132 ft/px would have pushed that court past 4%, so the packet uses 0.7088.

**Footprint IoU versus OSM ≥ 0.92.** `python tools/overlay.py` prints `footprint IoU vs OSM 0.9887`. The same figure is `blueprint/calibration.json` `osm.iouOrthogonalVsRaw`. The footprint is OSM way 112472416 rotated by −10.43° and squared onto the axes. The red OSM ring and the cyan footprint are `verification/M1/overlay_osm.png`.

**Every room visible on the site plan is in `level1.json`.** The overlay is `verification/M1/overlay_site.png` (rooms drawn on `reference/site_plan_native.png`) and the labeled plan is `verification/M1/overlay_level1.png`.

| Site plan | Room id |
|---|---|
| Red-dashed NW box and west fence | `addition` (one L, `construction`) |
| Two cage courts | `cage_gym` (one gym) |
| Competition gym | `competition_gym` (115 × 147 ft) |
| Four courts under that gym | `racquetball_1` … `racquetball_4`, each 20 × 40 ft |
| Group room and link beside them | `group_exercise`, `corridor_link` |
| Long east–west concourse | `corridor_main` |
| South gym, three courts | `south_gym` (138 × 105 ft) |
| Yellow office wing | `office_nw`, `office_n1`–`office_n3`, `office_s1`, `office_s2`, `corridor_office`, `restroom_office`, `stair_west` |
| East curtain-wall block | `lobby` |
| Yellow rooms south of the lobby | `fitness_center`, `weight_room` |
| Orange core east of the gym | `restroom_ne_w`, `restroom_ne_m`, `stair_ne`, `corridor_ne`, `locker_volleyball`, `locker_general` |
| Narrow link, cage to competition gym | `corridor_west` |
| Service room at the office/south-gym corner | `mechanical_sw` |

The potential-new-parking callout is not a room. The cage's two courts are one gym. The small bays drawn inside that rectangle stay inside `cage_gym` so the addition and the cage do not overlap and the cage stays one rectangle. The addition shares edges with the cage and has no door into it.

**Level 2 rooms from the drawings are in `level2.json`.** Labeled plan: `verification/M1/overlay_level2.png`. The life-safety sheet `reference/photos/Screenshot_2026-09-28_174529.jpg` shows the three gyms open to below, an upper office wing, east rooms, stairs, and the addition as its own area. In the packet:

- Voids: `void_competition`, `void_south`, `void_cage`, `void_lobby` (also `type: void` rooms).
- Addition: `addition_l2`, one construction rectangle over the new box. The future rooms and courts on that sheet stay inside the fence.
- Existing upper floor: `corridor_l2`, `corridor_l2_north`, `corridor_l2_ne`, `corridor_l2_east`, `corridor_l2_gym`, `corridor_l2_office`, `lounge_l2`, `balcony`, `conference`, `office_l2_east`, the west office row, `restroom_l2`, `storage_l2`, `mechanical_l2`, `stair_ne`, `stair_west`.

`corridor_l2_gym` is the upper window band on the competition gym's east wall (`reference/photos/IMG_0336.jpg`). Racquetball is 20 ft clear, so Level 2 does not sit on those courts.

**`blueprint/HEIGHTS.md` cites a photograph for every height.** Floor-to-floor 16 ft is the two-story curtain wall in IMG_0364 and the mezzanine glass in IMG_0336. Door heads are 7 ft (IMG_0314, IMG_0320). Corridor ceilings are 10 ft 2×4 tile (IMG_0314). Offices are 9 ft 2×2 (IMG_0323). The competition gym is 32 ft to the joists, roof 36 (IMG_0332, IMG_0336). South gym 28 / roof 32, cage 24 / roof 28, racquetball 20 / roof 22, lobby 32 / roof 36, canopy 16 (IMG_0364), fitness and weight 12. The precast band is 4 ft tall with its base at 12 ft (IMG_0349, IMG_0364). Wall heights in the JSON are the taller adjacent ceiling, and exterior walls are at least 18 ft.

**`lune run tools/validate_blueprint.luau` passes.** Exit code 0, no output. It checks the enums and required fields in `blueprint/SCHEMA.md`, 0.5 ft snapping, counter-clockwise polygons, racquetball at 40 × 20, openings inside their walls, stair rise and run, `trueNorthDeg`, facade styles, roof heights, court errors within ±4%, and the stored OSM IoU at or above 0.92.

## Other artifacts

- `blueprint/photo_stations.json`: 77 stations, one per `reference/photos/IMG_*.jpg` (IMG_0314–IMG_0382, with IMG_0337 as frames `IMG_0337_f000`–`f009`; there is no IMG_0317). Eye height 5.2 ft, vertical FOV 55°. The Perkins&Will screenshots are drawings, so they have no camera station.
- Plan views: `verification/M1/overlay_level1.png`, `verification/M1/overlay_level2.png`, `verification/M1/overlay_site.png`, `verification/M1/overlay_osm.png`, `verification/M1/packet.png`.
- Stage log: `verification/M1/PROGRESS.md`.

## verify.ps1

`pwsh tools/verify.ps1` exits 1. The blueprint steps pass: `blueprint geometry`, `blueprint schema`, selene, rojo build, `build.spec.luau`, `props.spec.luau`, and prop geometry. It fails `stylua --check` and `luau-lsp analyze` in `src/ReplicatedStorage/RAC/Site/` (line length, and a Color3 passed where an `Enum.Material` is required). That folder is outside this milestone.

`places/build.rbxm` is older than `blueprint/level1.json`, so the script did not run the built-building geometry check.

## Studio

Studio instance `Place1` (place title TwentyHours-preview), edit mode. Console before play had no script errors.

Play ran for 22 seconds, then stopped. Console during play:

- `RAC opening out of range on GymWestGlass` and `SquashSplit` — wall names that are not in this blueprint. The place is a previous 939-part build.
- `RAC blockout ready. 939 parts.`
- Infinite yield on `Workspace.RAC:WaitForChild("Lighting")` (`LightingController` line 19) and on `ReplicatedStorage:WaitForChild("CoachVillainRemotes")` (`CoachVillainServer` line 68 and `CoachVillainClient` line 11).

An aerial capture from (40, 300, 250) looking at (−190, 0, −50) shows that grey massing. The Studio tool returned the image and did not write a file, so there is no `verification/M1` path for it. Photo-station pairs against this blueprint were not taken. The place has not been rebuilt from these JSON files.

## Limits

The northeast core is restrooms, a stair, a corridor, and two locker rooms, which is coarser than every bay on the site plan. The office wing is a double-loaded corridor, not every furniture partition. The addition is one fenced zone on each level. The south gym's south wall is the squared OSM edge at z=219. The entrance wall centerline is x=−0.5, so the exterior face lands about 0.2 ft east of the origin.

STATUS: DONE
