# Blueprint schema (authoritative contract between blueprint producers and the builder)

Units: feet (1 stud = 1 ft). Plan coordinates are `[x, z]`: +X east, +Z south (Roblox world axes; north = −Z).
Blueprint space is axis-aligned to the building grid; `site.json.trueNorthDeg` rotates it to geographic north.
Heights are relative to the level's `elevation` (finished floor). All coordinates snapped to 0.5 ft.

## blueprint/level1.json, blueprint/level2.json
```json
{
  "level": 1,
  "elevation": 0,
  "rooms": [
    {
      "id": "competition_gym",            // unique snake_case
      "name": "Competition Gym",
      "type": "gym",                      // gym|corridor|lobby|office|fitness|locker|restroom|support|mechanical|stair|storage|racquetball|construction|void
      "polygon": [[x,z], ...],            // CCW, no repeated closing point, rectilinear unless truly angled
      "floorMaterial": "maple",           // maple|terrazzo|porcelain_tile|carpet_tile|rubber|sealed_concrete|ceramic_tile|vinyl
      "ceilingHeight": 32,                // ft above this level's floor
      "ceilingType": "open_joist",        // act_2x2|act_2x4|gypsum|open_joist|none
      "wallFinish": "painted_cmu"         // default finish for walls bounding this room
    }
  ],
  "walls": [
    {
      "id": "w_0001",
      "a": [x,z], "b": [x,z],             // centerline endpoints
      "thickness": 0.67,                  // ft (8" CMU = 0.67, stud partition = 0.4, exterior = 1.33)
      "height": 12,                       // ft above level floor (to structure or ceiling)
      "material": "painted_cmu",          // painted_cmu|brick|gypsum|glass|metal_panel|precast
      "exterior": false,
      "openings": [
        {"type": "door", "offset": 10.0, "width": 3.0, "sill": 0, "head": 7.0, "leaves": 1, "tag": "RACDoor"},
        {"type": "window", "offset": 20.0, "width": 6.0, "sill": 3.0, "head": 7.0},
        {"type": "opening", "offset": 30.0, "width": 8.0, "sill": 0, "head": 8.0},
        {"type": "curtainwall", "offset": 0, "width": 40.0, "sill": 0, "head": 24.0, "mullionSpacing": 5.0}
      ]                                   // offset = distance from a along a→b to the opening's start
    }
  ],
  "columns": [{"id": "c1", "at": [x,z], "size": [1.5, 1.5], "height": 30}],
  "stairs": [{"id": "s1", "polygon": [[x,z],...], "fromLevel": 1, "toLevel": 2, "direction": [0,-1], "risers": 24, "rise": 0.583, "run": 0.917, "width": 5}],
  "voids": [{"id": "v1", "polygon": [[x,z],...]}],   // "open to below" areas on upper levels (no floor slab)
  "props": [{"id": "p1", "kind": "power_rack", "at": [x,z], "rotation": 0, "room": "weight_room"}]
}
```

## blueprint/site.json
```json
{
  "units": "ft", "trueNorthDeg": 11.2,
  "origin": {"desc": "main entrance exterior threshold, L1 finished floor", "lat": 38.83, "lon": -77.31},
  "footprint": [[x,z],...],
  "levels": [{"level": 1, "elevation": 0}, {"level": 2, "elevation": 16}],
  "facade": [{"a": [x,z], "b": [x,z], "style": "brick|precast_band|metal_panel|curtain_wall|sunshade_fins", "height": 30, "base": 0}],
  "roofs": [{"polygon": [[x,z],...], "height": 34, "type": "flat|canopy", "overhang": 0}],
  "calibration": "calibration.json"
}
```

## Prop kinds (builder + prop library contract)
`kind` values used in `props` and implemented in `src/ReplicatedStorage/RAC/Props/<Kind>.luau` (PascalCase file,
snake_case kind): power_rack, flat_bench, adjustable_bench, dumbbell_rack, kettlebell_rack, plate_tree, lifting_platform,
cable_machine, leg_press, lat_pulldown, chest_press, treadmill, elliptical, stair_climber, upright_bike, rower,
wall_mirror, wall_tv, water_fountain, trash_bin, recycle_bin, bleacher_bank, basketball_hoop_ceiling, volleyball_standard,
wall_pad, scoreboard, banner, flag, locker_bank_wood, locker_bank_metal, bench_locker, front_desk, cubicle, office_desk,
office_chair, mail_slots, wall_clock, fire_extinguisher_cabinet, exit_sign, troffer_2x4, troffer_2x2, high_bay_light,
downlight, door_single, door_double, toilet_partition, urinal, sink_counter, shower_stall, vending_machine, bulletin_board, training_table, ping_pong_table, trophy_case, jersey_frame, industrial_fridge, keypad_door, squash_court.
Each prop module returns `{ kind = "...", size = Vector3 (ft, bounding box), build = function(cf: CFrame, opts: {[string]: any}?): Model }`.
Model pivot = bottom-center of the bounding box, facing −Z.
