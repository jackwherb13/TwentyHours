# Blueprint schema

This file is the packet next to the JSON. The field names and enums are the contract in
`docs/BLUEPRINT_SCHEMA.md`. Builders should read that file. Nothing here renames or replaces it.

Units are feet (1 stud = 1 ft). Plan coordinates are `[x, z]`: +X east, +Z south. North is −Z.
The building grid is the X/Z axes. `site.json` `trueNorthDeg` is the compass bearing of blueprint −Z
(plan north). It is for OSM context later. It is not applied to rooms or walls.

Coordinates are snapped to 0.5 ft. Polygons are counter-clockwise and do not repeat the closing point.
A room polygon has at most 12 vertices. `lobby`, `construction`, `exterior`, and `canopy` may be irregular.
The only non-rectangular room in this packet is the RAC Addition, one L-shaped construction zone.

## blueprint/level1.json, blueprint/level2.json

```json
{
  "level": 1,
  "elevation": 0,
  "rooms": [
    {
      "id": "competition_gym",
      "name": "Competition Gym",
      "type": "gym",
      "polygon": [[0, 0], [10, 0], [10, 20], [0, 20]],
      "floorMaterial": "maple",
      "ceilingHeight": 32,
      "ceilingType": "open_joist",
      "wallFinish": "painted_cmu"
    }
  ],
  "walls": [
    {
      "id": "w_0001",
      "a": [0, 0],
      "b": [10, 0],
      "thickness": 0.67,
      "height": 12,
      "material": "painted_cmu",
      "exterior": false,
      "openings": [
        {"type": "door", "offset": 2.0, "width": 3.0, "sill": 0, "head": 7.0, "leaves": 1, "tag": "RACDoor"}
      ]
    }
  ],
  "columns": [{"id": "c1", "at": [5, 5], "size": [1.5, 1.5], "height": 32}],
  "stairs": [
    {"id": "stair_ne", "polygon": [[0, 0], [6, 0], [6, 12], [0, 12]], "fromLevel": 1, "toLevel": 2, "direction": [1, 0], "risers": 28, "rise": 0.571, "run": 0.917, "width": 6}
  ],
  "voids": [{"id": "void_competition", "polygon": [[0, 0], [10, 0], [10, 20], [0, 20]]}],
  "props": [{"id": "desk_lobby", "kind": "front_desk", "at": [4, 8], "rotation": 180, "room": "lobby"}]
}
```

`type` is one of `gym`, `corridor`, `lobby`, `office`, `fitness`, `locker`, `restroom`, `support`,
`mechanical`, `stair`, `storage`, `racquetball`, `construction`, `void`.

`floorMaterial` is one of `maple`, `terrazzo`, `porcelain_tile`, `carpet_tile`, `rubber`,
`sealed_concrete`, `ceramic_tile`, `vinyl`.

`ceilingType` is one of `act_2x2`, `act_2x4`, `gypsum`, `open_joist`, `none`.
`ceilingHeight` is feet above that level's finished floor. A `void` room is open to the level below
and is repeated in `voids`. Void rooms are not given walls.

`material` on a wall is one of `painted_cmu`, `brick`, `gypsum`, `glass`, `metal_panel`, `precast`.
Thickness is 0.67 ft for 8 inch CMU, 0.4 ft for a stud partition, and 1.33 ft for an exterior wall.
Wall height is the taller adjacent ceiling. An exterior wall is at least 18 ft so a one-story room
still has a parapet. One wall is one straight run. Collinear pieces that bound the same rooms are merged.
Every wall is at least 2 ft.

An opening's `offset` is the distance from `a` along `a→b` to the start of the opening, not the center.
`type` is `door`, `window`, `opening`, or `curtainwall`. `sill` and `head` are feet above the level floor.
Doors carry `leaves`. The entrance curtain wall carries `mullionSpacing`. A door or cased `opening` is how
rooms connect. A window or curtain wall does not.

`props[].kind` uses the snake_case kinds in `docs/BLUEPRINT_SCHEMA.md`. The pivot is the bottom center, facing −Z.

## blueprint/site.json

```json
{
  "units": "ft",
  "trueNorthDeg": 10.43,
  "origin": {"desc": "main entrance exterior threshold, L1 finished floor", "lat": 38.830638, "lon": -77.312464},
  "footprint": [[0, 0], [10, 0], [10, 10], [0, 10]],
  "levels": [{"level": 1, "elevation": 0}, {"level": 2, "elevation": 16}],
  "facade": [{"a": [0, 0], "b": [10, 0], "style": "brick", "height": 32, "base": 0}],
  "roofs": [{"polygon": [[0, 0], [10, 0], [10, 10], [0, 10]], "height": 36, "type": "flat", "overhang": 2}],
  "calibration": "calibration.json"
}
```

Facade `style` is `brick`, `precast_band`, `metal_panel`, `curtain_wall`, or `sunshade_fins`.
Roof `type` is `flat` or `canopy`. Roof `height` is feet above Level 1 finished floor.
The footprint is OSM way 112472416 rotated onto the building axes and snapped. It is the size ground truth.
The fenced addition sits outside that outline.

## blueprint/calibration.json

The fit of `reference/site_plan_native.png` to the OSM outline: `scaleFtPerPx`, `thetaDeg`, `shift`,
`trueNorthDeg`, the pixel anchor, the scale-bar measurement, and a `courts` array. Each court has
`measuredFt`, `regulationFt`, and `error` as a fraction (0.04 is +4%). `osm.iouOrthogonalVsRaw` is the
footprint against the rotated OSM ring.

## blueprint/photo_stations.json

```json
{
  "stations": [
    {
      "id": "IMG_0364",
      "file": "reference/photos/IMG_0364.jpg",
      "position": [40.0, 5.2, 20.0],
      "look": [-1.0, 0.05, 0.0],
      "fovVertical": 55,
      "room": "exterior",
      "note": "entrance curtain wall"
    }
  ]
}
```

`position` is `[x, y, z]` in feet. `y` is eye height, 5.2. `look` is a unit vector in blueprint axes
(+X east, +Y up, +Z south). `fovVertical` is 55 for a portrait iPhone main camera. One station per
photograph of the building. The Perkins&Will screenshots are drawings, not camera views.

## Heights

`blueprint/HEIGHTS.md` cites the photograph behind every height in the JSON.
`tools/validate_blueprint.luau` checks this shape. `python tools/verify_blueprint.py` checks overlaps,
wall length, axis alignment, and that rooms are reachable through doors.
