# Heights

Feet. Elevations are above the Level 1 finished floor. The origin is the south entrance threshold. A room's `ceilingHeight` is above that level's own floor.

## Floor to floor — 20 ft

Level 2 is at +20 ft. The walkthrough measured the main stair as two flights, about 34 risers at 7 inches, and that count wins over the older 16 ft reading of the curtain wall. `tools/validate_blueprint.luau` still checks for 16 ft. That failure is the validator, not the building.

Each stair is 34 risers at 20/34 ft, split into two flights of 17. The main stair turns left on a landing at +10. The second stair and the west egress stair are straight runs with the same mid landing.

## Roofs above Level 1

Lidar (`verification/exterior/ROOF_HEIGHTS.md`) and the occupied floor disagree on the low wings. A roof near 25 ft cannot cover a floor at 20 ft plus a ceiling. Gym roofs follow the lidar. Occupied two-story roofs sit at 33.2 ft.

| Roof | Height |
| --- | --- |
| Competition gym | 33.7 |
| South gym | 40.2 |
| Cage | 45.8 |
| Racquetball | 36.7 |
| Two-story wings | 33.2 |
| South entrance canopy | 15, with a wedge soffit under the slab |

Competition gym ceiling is 32.5. South gym ceiling is 39. Cage ceiling is 24.5. Racquetball ceiling is 16.5, which is below the 20 ft floor-to-floor; the roof above it is still 36.7. Lobby and the south glass are double-height, ceiling 32, glass head 30.

## Doors and corridors

Doors are head 7, sill 0. Cased openings are head 9. Corridor ceilings are 10 ft acoustic tile except the double-height entry. Office ceilings are about 9 to 10 ft. Level 2 corridor ceilings are 10 ft, including the gym overlook.
