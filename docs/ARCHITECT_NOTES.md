# RAC structure — architect notes

Status: Levels 1 and 2 are a walkable structure. There is no third floor. Rooms have a purpose fit-out. No real people, jersey names, or photographed faces. Round-2 screenshots are in verification/qa/round2/. Photo-match judges were not re-run.

The main entrance is the smaller south glass front, under the dark canopy. The long east curtain wall is glazing, not the entrance. Level 2 is at +20 ft. The 2026-09-29 09:35 answers in `docs/WALKTHROUGH.md` win where an older paragraph below still names a coordinate.

## Circulation

Walking north is away from the south glass. Left is west. Right, in this plan, is the workout path (the glass is the east limit, so the right hallway cannot continue past x = 10).

1. South threshold into the double-height lobby (the open 20 × 20 at x = −10…10, z = 0…−20, plus the stair notch). The reception desk is the long white U in that room, at (−2, −12), rotation 180, length 12, depth 6. The GM mark is on the south face. Four stations sit inside the U, with a lost-and-found cabinet and a ball cart. The south door and the stair threshold stay clear of the counter.
2. The main stair is inside that same 20 × 20, set back from the glass. Flight `main_a` runs north along the east side (x = 2…10, z = −33…−18.5, 17 risers). The 8 × 8 landing is at +10. Flight `main_b` turns left and runs west, and its top meets the Level 2 door at x = −12.5, elevation +20. Rise is 20/34 ft, run is 14.5/17 ft, width 8. Gemini's west-well coordinates (x = −112…−78.5) are the old well. The lobby stair replaced them on purpose. x = −12.5 is still the Level 2 arrival.
3. Immediately left of the main door, `south_vestibule` is the glass hallway. It runs west along the south glass, with ping-pong and vending, then turns north through `corridor_south_link` and `corridor_entry_south`. That path is still an L. Public lockers are off `corridor_south_link` (lockers on the right as you enter, five stalls on the left, sinks across from the stalls, showers ahead). The volleyball locker with keypad 15234 stays deep in the athletic suite.
4. Straight ahead through the workout (`fitness_annex`, `corridor_wide`, the squat racks in `weight_room`) is the right-hand path. The coaches' suite is past the squat racks, on the right. The elevator is the 8 × 8 between the squat room and the head coach's office. Linn gym (`south_gym`) is reached from that workout hall through `team_support`, and `team_support` also opens into the athletic corridor. The head coach's door carries a nameplate that reads HEAD COACH.
5. The public hall along the east side of the competition gym has the gym doors on the left. The trophy case is on the right where the hall narrows. A doorless link continues into the north–south athletic corridor. `thin_link` is an 8 ft hall, not a 113 ft opening.
6. Training is north of the nutrition vestibule, which is north of the volleyball locker. Order, walking south: training, nutrition, locker, west hall, second stair. The training store door is on the shared wall with training. Keypad 15234 and the fridge name are fictional.
7. The second stair is two flights with an 8 × 8 mid landing. The Level 2 door is 3 ft wide and lands on the upper landing, west of the upper-flight void.
8. On Level 2, leave the main stair onto the landing, then the balcony, then the overlook. The overlook ends at z = −279.5. It is still a turn: the overlook runs north–south at x = −78.5…−64.5, and `corridor_l2` runs east–west from that corner. Walking west after the turn: both racquetball courts on the left (south), light wood floors, white walls, glass on the hall side; then `stair_second` on the right; then the basketball door signed BASKETBALL — OFF LIMITS; then the grade exit on the west wall at x = −359.5. The basketball gym is entered on Level 2. `cage_lower_reserved` stays construction, with no public door.
9. `stair_west` is the third stair. It is enclosed, with a door from `corridor_office` and an exit sign. It is not an open well. There is no third floor and no juice bar.
10. Level 2 cardio (`cardio_south`) is open to the lobby, with a rail at z = −16, 3.5 ft high. TVs are on the north wall, free weights are along the west wall (perpendicular to the south glass), and two benches sit in the room.
11. The service yard is west of the volleyball gym, x = −236.5…−193.5, z = −214…−186, with two dumpsters and a SERVICE door.

The Level 2 route the checker walks is `main_stair_landing → balcony → corridor_l2_overlook → corridor_l2 → racquetball → stair_second → basketball_approach → cage_gym → HIGH_EXIT`. The turn from the overlook onto `corridor_l2` remains. One straight line cannot keep both the gym and the racquetball courts on the left without cutting the competition gym.

## Conflicts and resolutions

- Floor-to-floor. Level 2 stays at +20 ft. The stair rise is 20/34 ft.
- Entrance. An earlier fit put the entrance on the east curtain wall. The 23:20 correction puts it on the south glass, x = −97 to 10 at z = 0. The east wall stays at x = 10, full height, with no entrance door.
- Main stair. "Three switchbacks" was replaced by two flights, one landing, turn left.
- Left-hand gym and left-hand racquetball. Resolved by the north turn described above. The competition gym stays x = −193.5 to −78.5. Its east–west court length is not reduced.
- Lidar roofs near 25 ft cannot cover a floor at 20 ft. Gym and racquetball roofs follow the lidar. Other occupied roofs are 33.2 ft. See `blueprint/HEIGHTS.md`.
- Racquetball ceiling is 16.5 ft under a 36.7 ft roof. The clear height and the roof are both recorded. They are not the same number.
- The reception desk is the U in item 1. The older 20 ft north–south bar at (−4, −15), rotation 270, is retired.
- Main stair run is 14.5/17 ft (about 10.2 in) on both flights (17 + 17), landing 8 ft square. The old 0.917 ft going belonged to the west well.
- Racquetball is on the south side of `corridor_l2`, immediately before `stair_second`. `walkthrough_routes.json` is not owned here; the route agent still needs listed rooms to sit on that hall.
- Site context in the built model includes the entry canopy, the RAC letters, the trees, and the exterior rails. Geometry QA counts those parts.
- `tools/overlay.py` still registers OSM at the old entrance pixel (672, 336). Footprint IoU against OSM is not a check of this plan.

## Questions answered 2026-09-29 09:35

- `stair_west` stays. It is the enclosed third stair, with a door and an exit sign.
- Racquetball ceilings stay 16.5 ft. Floors are maple. Walls are gypsum. The hall-side wall is glass.
- Linn gym stays, notched for the public locker, and connects to the workout hall and the athletic corridor.
- No third floor. No juice bar. The cage has no public door on Level 1.
- The room-size table below is an earlier fit. Do not quote it as current area. Gemini's addition rectangle and the 10120 sq ft cage figure were not recomputed; overlap on both levels is 0. `l1_w105` and `l1_w106` in that review were painted CMU, not brick.

## What the builder has to know

`Stairs.luau` builds `flights` and `landings` when those fields are present, and the old straight flight when they are not. `Build.luau` passes `length`, `bays`, and `depth` through to the front desk. `Roofs.luau` adds a steel wedge under a canopy, inset 0.15 ft at each end so the wedge does not share a face with a wall. `Materials.apply` paints floors and walls from the uploaded ColorMaps. `Lights.build` places high-bays, 2×4 troffers, and downlights. `Court.build` paints the maple court, the green apron, and the gold lines. Play uses the same RAC model and spawns at `LobbySpawn` inside the south lobby, facing north. `validate_blueprint.luau`, `check_geometry.luau`, `architect_build.py`, `architect_route_check.py`, and `Exterior.luau` were not edited.

Joint stems that meet on a through-wall are 0.28 ft thick so the geometry check does not call the joint a gap and the door leaf does not land on its kickplate. Gallery and cardio edges listed in `level2.json` `guards` are horizontal rails. The overlook glass is a curtain wall on x = −78.5 from about z = −261 to −133.5, head 9.5, mullions at 5 ft. There is no guard across that glass.

## Detail briefs

Finishes already stored on each room are the ones to build. Lighting is recessed in acoustic-tile rooms, open high-bay in gyms, and a gypsum soffit with downlights in the double-height lobby. Do not invent people or dedications. Photo references are the sheets already in `reference/`.

Walkthrough rooms, beyond the table:

- `lobby` — open 20 × 20 plus the stair notch. Ceiling 32 gypsum. Desk `reception_desk` at (−2, −12), rotation 180, shape U, length 12, depth 6. White counter, GM mark on the south face. South curtain wall to head 30.
- `south_vestibule`, `glazed_recreation`, `glazed_recreation_west` — double-height, glass on the south, ping-pong and vending in the recreation hall. IMG_0331.
- `stair_main` — two flights, left turn, 8 × 8 landing at +10, inside the lobby 20 × 20. First flight north (x = 2…10, z = −33…−18.5), second flight west, top at x = −12.5. Sealed concrete. IMG_0371.
- `corridor_l2_overlook` — sealed concrete, 10 ft 2×2 tile. Black-mullion glass on the west, one horizontal mullion near rail height, looking onto the wood court. IMG_0344, IMG_0345, WEB_vb_gym_overlook.
- `balcony` and the gallery guards — horizontal rails, including the cardio edge at z = −16. IMG_0343. Do not run a guard across the stair.
- `racquetball_1`, `racquetball_2` — 40 × 20, Level 2 only, ceiling 16.5, maple floor, gypsum walls, glass on the hall side at z = −80. South of `corridor_l2`, then the down stair. No courts on Level 1.
- `competition_gym` — maple, ceiling 32.5, roof 33.7. Court about 94 × 50. Green keys visible from the overlook.
- `cage_gym` — door label `BASKETBALL - OFF LIMITS`. Ceiling 24.5, roof 45.8.
- `basketball_approach` — door label `LEVEL 2 EXIT AT GRADE`.
- `nutrition_vestibule` — keypad 15234, one glass-door fridge signed `MATT CORSON NUTRITION STATION`. Both are fictional.
- `locker_volleyball` — generic locker sign. No dedication.
- `training_room` — athletic training. Green treatment tables, ice machine, supply cabinets, desk, and a board.
- `addition` — construction only. One north gate labeled `CONSTRUCTION`. No finished interior.

Every other room uses the row below. Fixture, prop, and signage passes should follow the room type and must not add a named person.

| Room | Level | Type | Size ft | Floor | Ceiling | Walls |
| --- | --- | --- | --- | --- | --- | --- |
| `competition_gym` | 1 | gym | 115 x 147 | maple | 32.5 open_joist | painted_cmu |
| `south_gym` | 1 | gym | 140 x 109 | maple | 39 open_joist | painted_cmu |
| `office_ne_1` | 1 | office | 26 x 18 | carpet_tile | 9.5 act_2x2 | gypsum |
| `office_ne_2` | 1 | office | 25 x 18 | carpet_tile | 9.5 act_2x2 | gypsum |
| `office_ne_3` | 1 | office | 24 x 18 | carpet_tile | 9.5 act_2x2 | gypsum |
| `office_ne_4` | 1 | office | 24 x 25 | carpet_tile | 9.5 act_2x2 | gypsum |
| `office_ne_5` | 1 | office | 24 x 25 | carpet_tile | 9.5 act_2x2 | gypsum |
| `office_ne_reception` | 1 | office | 38 x 38 | carpet_tile | 9.5 act_2x2 | gypsum |
| `restroom_ne_w` | 1 | restroom | 24 x 16 | ceramic_tile | 9.5 gypsum | painted_cmu |
| `restroom_ne_m` | 1 | restroom | 42 x 16 | ceramic_tile | 9.5 gypsum | painted_cmu |
| `fitness_north` | 1 | fitness | 88 x 41 | rubber | 12 act_2x2 | gypsum |
| `lobby` | 1 | lobby | 20 x 28 | porcelain_tile | 32 gypsum | gypsum |
| `lobby_north` | 1 | lobby | 15 x 74 | porcelain_tile | 32 gypsum | gypsum |
| `fitness_center` | 1 | fitness | 62 x 34 | rubber | 12 act_2x2 | gypsum |
| `weight_room` | 1 | fitness | 62 x 40 | rubber | 12 act_2x2 | gypsum |
| `corridor_gym_east` | 1 | corridor | 12 x 22 | terrazzo | 10 act_2x4 | painted_cmu |
| `corridor_entry_link` | 1 | corridor | 12 x 52 | terrazzo | 10 act_2x4 | painted_cmu |
| `glazed_recreation` | 1 | lobby | 15 x 52 | porcelain_tile | 32 gypsum | gypsum |
| `stair_main` | 1 | stair | 33.5 x 24 | sealed_concrete | 32 none | painted_cmu |
| `fitness_annex` | 1 | fitness | 38 x 28 | rubber | 12 act_2x2 | gypsum |
| `south_vestibule` | 1 | lobby | 32 x 15 | porcelain_tile | 32 gypsum | gypsum |
| `corridor_entry_south` | 1 | lobby | 36 x 16 | porcelain_tile | 12 act_2x4 | gypsum |
| `glazed_recreation_west` | 1 | lobby | 18 x 15 | porcelain_tile | 32 gypsum | gypsum |
| `corridor_south_link` | 1 | corridor | 18 x 47 | terrazzo | 10 act_2x4 | painted_cmu |
| `thin_link` | 1 | corridor | 115 x 8 | terrazzo | 10 act_2x4 | painted_cmu |
| `athletic_corridor` | 1 | corridor | 12 x 100 | terrazzo | 10 act_2x4 | painted_cmu |
| `training_room` | 1 | support | 31 x 30 | porcelain_tile | 10 act_2x4 | painted_cmu |
| `nutrition_vestibule` | 1 | support | 10 x 10 | porcelain_tile | 9.5 act_2x4 | painted_cmu |
| `locker_volleyball` | 1 | locker | 34 x 22 | porcelain_tile | 9.5 act_2x2 | painted_cmu |
| `volleyball_washroom` | 1 | restroom | 24 x 10 | ceramic_tile | 9.5 gypsum | painted_cmu |
| `locker_general_w` | 1 | locker | 28 x 32 | porcelain_tile | 9.5 act_2x2 | painted_cmu |
| `locker_general_m` | 1 | locker | 28 x 32 | porcelain_tile | 9.5 act_2x2 | painted_cmu |
| `storage_athletic` | 1 | storage | 25 x 32 | sealed_concrete | 10 none | painted_cmu |
| `corridor_main` | 1 | corridor | 115 x 12 | terrazzo | 10 act_2x4 | painted_cmu |
| `team_support` | 1 | support | 96 x 18 | porcelain_tile | 10 act_2x4 | painted_cmu |
| `stair_second` | 1 | stair | 34 x 40 | sealed_concrete | 32 none | painted_cmu |
| `training_store` | 1 | storage | 20 x 88 | sealed_concrete | 10 none | painted_cmu |
| `west_link` | 1 | corridor | 110 x 12 | terrazzo | 10 act_2x4 | painted_cmu |
| `corridor_office` | 1 | corridor | 76 x 10 | terrazzo | 10 act_2x4 | painted_cmu |
| `stair_west` | 1 | stair | 12 x 46 | sealed_concrete | 32 none | painted_cmu |
| `office_w1` | 1 | office | 28 x 36 | carpet_tile | 9.5 act_2x2 | gypsum |
| `office_w2` | 1 | office | 24 x 36 | carpet_tile | 9.5 act_2x2 | gypsum |
| `office_w3` | 1 | office | 24 x 36 | carpet_tile | 9.5 act_2x2 | gypsum |
| `mechanical_sw` | 1 | mechanical | 33 x 28 | sealed_concrete | 12 none | painted_cmu |
| `corridor_service` | 1 | corridor | 33 x 18 | terrazzo | 10 act_2x4 | painted_cmu |
| `corridor_ne` | 1 | corridor | 50 x 66 | terrazzo | 10 act_2x4 | painted_cmu |
| `addition` | 1 | construction | 154 x 208 | sealed_concrete | 24 none | painted_cmu |
| `cage_lower_reserved` | 1 | construction | 126 x 128 | sealed_concrete | 24 none | painted_cmu |
| `corridor_wide` | 1 | lobby | 74 x 32 | porcelain_tile | 12 act_2x4 | gypsum |
| `vestibule_inner` | 1 | lobby | 32 x 5 | porcelain_tile | 12 act_2x4 | gypsum |
| `office_ne_1` | 2 | office | 26 x 18 | carpet_tile | 9.5 act_2x2 | gypsum |
| `office_ne_2` | 2 | office | 25 x 18 | carpet_tile | 9.5 act_2x2 | gypsum |
| `office_ne_3` | 2 | office | 24 x 18 | carpet_tile | 9.5 act_2x2 | gypsum |
| `office_ne_4` | 2 | office | 24 x 25 | carpet_tile | 9.5 act_2x2 | gypsum |
| `office_ne_5` | 2 | office | 24 x 25 | carpet_tile | 9.5 act_2x2 | gypsum |
| `office_ne_reception` | 2 | office | 36 x 38 | carpet_tile | 9.5 act_2x2 | gypsum |
| `restroom_ne_w` | 2 | restroom | 18 x 16 | ceramic_tile | 9.5 gypsum | painted_cmu |
| `restroom_ne_m` | 2 | restroom | 42 x 16 | ceramic_tile | 9.5 gypsum | painted_cmu |
| `fitness_north` | 2 | fitness | 74 x 41 | rubber | 12 act_2x2 | gypsum |
| `stair_main` | 2 | stair | 33.5 x 24 | sealed_concrete | 12 none | painted_cmu |
| `cardio_gallery` | 2 | fitness | 60 x 74 | rubber | 12 act_2x2 | gypsum |
| `cardio_south` | 2 | fitness | 32 x 33 | rubber | 12 act_2x2 | gypsum |
| `main_stair_landing` | 2 | corridor | 36 x 16 | terrazzo | 10 act_2x4 | painted_cmu |
| `corridor_l2_overlook` | 2 | corridor | 14 x 182 | sealed_concrete | 10 act_2x2 | painted_cmu |
| `team_meeting` | 2 | support | 58 x 40 | porcelain_tile | 10 act_2x4 | painted_cmu |
| `team_offices` | 2 | office | 56 x 40 | carpet_tile | 9.5 act_2x2 | gypsum |
| `corridor_l2` | 2 | corridor | 266 x 12 | terrazzo | 10 act_2x4 | painted_cmu |
| `stair_second` | 2 | stair | 34 x 40 | sealed_concrete | 12 none | painted_cmu |
| `athletic_upper` | 2 | corridor | 12 x 88 | terrazzo | 10 act_2x4 | painted_cmu |
| `upper_store` | 2 | storage | 20 x 88 | sealed_concrete | 10 none | painted_cmu |
| `racquetball_1` | 2 | racquetball | 40 x 20 | maple | 16.5 gypsum | painted_cmu |
| `racquetball_2` | 2 | racquetball | 40 x 20 | maple | 16.5 gypsum | painted_cmu |
| `office_l2_w1` | 2 | office | 20 x 32 | carpet_tile | 9.5 act_2x2 | gypsum |
| `office_l2_w2` | 2 | office | 20 x 32 | carpet_tile | 9.5 act_2x2 | gypsum |
| `court_gallery` | 2 | corridor | 20 x 32 | terrazzo | 10 act_2x4 | painted_cmu |
| `stair_west` | 2 | stair | 12 x 46 | sealed_concrete | 12 none | painted_cmu |
| `mechanical_l2` | 2 | mechanical | 48 x 6 | sealed_concrete | 12 none | painted_cmu |
| `upper_service` | 2 | corridor | 60 x 14 | terrazzo | 10 act_2x4 | painted_cmu |
| `basketball_approach` | 2 | corridor | 12 x 40 | terrazzo | 10 act_2x4 | painted_cmu |
| `void_competition` | 2 | void | 115 x 147 | sealed_concrete | 0 none | painted_cmu |
| `void_south` | 2 | void | 140 x 109 | sealed_concrete | 0 none | painted_cmu |
| `corridor_ne` | 2 | corridor | 36 x 12 | terrazzo | 10 act_2x4 | painted_cmu |
| `cage_gym` | 2 | gym | 126 x 128 | maple | 24.5 open_joist | painted_cmu |
| `void_lobby` | 2 | void | 107 x 154 | sealed_concrete | 0 none | painted_cmu |
| `balcony` | 2 | corridor | 74 x 32 | terrazzo | 10 act_2x4 | painted_cmu |
