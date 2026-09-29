# Architectural Layout Review: GMU RAC Floor-Plan Recreation

**Reviewer:** Gemini (Expert Architectural Planner & QA)  
**Date:** September 29, 2026  
**Scope:** Blueprint verification and spatial analysis of `blueprint/level1.json`, `blueprint/level2.json`, and supporting site data against authoritative user walkthrough (`docs/WALKTHROUGH.md`), user reviews (`docs/reviews/USER-*.md`), architectural contract documents (`docs/ARCHITECT_NOTES.md`), Perkins & Will life-safety plans (`Screenshot_2026-09-28_174411.jpg`, `174518.jpg`), native site plans (`reference/site_plan_native.png`), and building standards (`docs/RAC_DOSSIER.md`, `docs/BUILDING_PRIMER.md`).

---

## Executive Summary

A complete, mathematical coordinate-by-coordinate walk of the RAC blueprint data was performed against the authoritative user walkthrough, photographic evidence, and Perkins & Will construction drawings. While major programmatic masses (Competition RAC Gym, Linn Gym, and Cage Gym) are appropriately zoned, the circulation spine suffers from **nine critical discrepancies** that break navigation, violate life safety, and introduce severe game-breaking hazards:

1. **Main Stair Flight Trapping / 20-ft Void Drop:** The upper flight of the main stair (`stair_main`) ascends west into an exterior solid wall at `x = -102.7`, completely disconnected by a 24.2-ft open gap from the Level 2 landing door at `x = -78.5`.
2. **Main Entrance Door Displaced 41 Feet:** The main entrance door on `l1_w094` was offset to `x = -41.0` (in `south_vestibule`), leaving `lobby` at the grid origin `(0,0,0)` with zero exterior doors and breaking automated route verification across all 89 building rooms.
3. **Racquetball Courts Trapped in Dead-End Overlook:** Courts are placed north of Competition Gym at `z = -319.5..-279.5` ending in a dead-end wall, with Court 1 only accessible by walking through the active playing court of Court 2, directly contradicting the walkthrough and `ARCHITECT_NOTES.md` which locate them south of `corridor_l2`.
4. **Second Stair 10-ft Vertical Fall Hazard:** On Level 2, the corridor door into `stair_second` on wall `l2_w065` opens at `x = -322.5` directly over the intermediate landing (+10 ft), creating a 10-foot vertical drop rather than landing at the top flight (+20 ft at `x = -339.5`).
5. **113-ft Gaping Holes in Thin Link:** Corridor `thin_link` has full 113-ft open wall apertures into both the Competition Gym and Gym Foyer, eliminating acoustic and structural separation.
6. **Reversed Athletic Suite Order:** Athletic Training Room is misplaced 80 ft south past the second stair, reversing the walkthrough order (Turn Left -> Training Room -> Nutrition Vestibule -> Locker Room -> Stair).
7. **Over 18,000 sq ft of Polygon Overlaps & Sealed Rooms:** Fifteen room pairs overlap significantly in Level 1 (e.g. `addition` swallowing `cage_lower_reserved`, `stair_second`, and corridors; `south_gym` overlapping `stair_main`), and `cage_lower_reserved` has zero doors.
8. **Improper Interior Brick Partitions:** Interior walls in the lobby and Level 2 gallery were modeled in brick, violating the latest user instructions (2026-09-29 08:30/08:40) which mandate open cardio/lobby spaces and painted CMU/gypsum.
9. **Level 2 Overlook-to-Concourse Backtracking:** Inability to transition smoothly from the overlook to the upper west concourse without a 200-ft backtrack.

Below is the complete catalog of numbered problems with exact element IDs and concrete coordinates, followed by the corrected ordered routes for both levels and five open architectural questions.

---

## 1. Numbered Problems with Concrete Corrections

### Problem 1: Disconnected Main Stair (`stair_main`) Flight Trapping & Level 2 Void Drop
* **Severity:** Critical (Game-breaking / Life Safety)
* **Affected Element IDs:**
  * `blueprint/level1.json`: `stairs[id="stair_main"]`, flights `main_a`, `main_b`, landing `main_turn`
  * `blueprint/level2.json`: `rooms[id="stair_main"]`, `stairs[id="stair_main"]`, `walls[id="l2_w008"]`, `walls[id="l2_w010"]`, `voids[id="stair_main_upper"]`
* **Defect Analysis:**
  In `level1.json`, flight `main_a` is oriented north (`direction: [0, -1]`), landing `main_turn` sits at `x = [-88.5, -80.5], z = [-52.0, -44.0]`, and flight `main_b` ascends WEST (`direction: [-1, 0]`) from `x = -88.5` to `x = -102.7` at `z = [-52.0, -44.0]`. Flight `main_b` reaches Level 2 finished floor (+20 ft) at `x = -102.7`, directly against solid exterior wall `l2_w010` (`x = -106.0`). Meanwhile, on Level 2, the only door/opening into `main_stair_landing` (`l2_w008`) is located at `x = -78.5`. There is a **24.2-foot chasm of open air** between the top step of flight `main_b` and the Level 2 landing door. An avatar walking up this stair walks off a 20-foot drop or is pinned against the west wall. Furthermore, `level2.json` contains a phantom stair entry with completely discordant coordinates `[[-78.5, -32.0], [-42.5, -32.0], ...]`.
* **Concrete Fix:**
  Align flights to match `ARCHITECT_NOTES.md` line 12 and the actual Level 2 opening:
  1. In `level1.json` under `stairs[id="stair_main"]`:
     * Move Flight `main_a` (Flight 1, climbing 0.0 to +10.0 ft) along the south wall, running EAST:
       `polygon: [[-104.5, -36.0], [-90.2, -36.0], [-90.2, -28.0], [-104.5, -28.0]]`, `direction: [1, 0]`, `risers: 17`, `rise: 0.588`, `run: 0.841`, `width: 8.0`, `baseElevation: 0.0`.
     * Move Landing `main_turn` to southeast corner at elevation +10.0 ft:
       `polygon: [[-90.2, -36.0], [-80.5, -36.0], [-80.5, -28.0], [-90.2, -28.0]]`, `elevation: 10.0`.
     * Move Flight `main_b` (Flight 2, climbing +10.0 to +20.0 ft) along the east wall, turning LEFT and running NORTH:
       `polygon: [[-88.5, -50.3], [-80.5, -50.3], [-80.5, -36.0], [-88.5, -36.0]]`, `direction: [0, -1]`, `risers: 17`, `rise: 0.588`, `run: 0.841`, `width: 8.0`, `baseElevation: 10.0`.
     * Top of Flight `main_b` lands at `z = -50.3..-54.0` at elevation +20.0 ft, directly adjacent to wall `l2_w008` (`x = -78.5, z = [-54.0, -40.0]`).
  2. In `level2.json`:
     * Update `stairs[id="stair_main"]` polygon from `[[-78.5, -32.0], [-42.5, -32.0], ...]` to match actual well: `polygon: [[-106.0, -54.0], [-78.5, -54.0], [-78.5, -16.0], [-106.0, -16.0]]`.
     * Update upper floor opening `stair_main_opening` void to match the flight boundaries: `polygon: [[-104.5, -36.0], [-80.5, -36.0], [-80.5, -28.0], [-104.5, -28.0]]`.

---

### Problem 2: Main Entrance Door Displaced 41 Feet & Unreachable Lobby
* **Severity:** Critical (Navigation & Verification Blocker)
* **Affected Element IDs:**
  * `blueprint/level1.json`: `walls[id="l1_w094"]`, `rooms[id="lobby"]`, `rooms[id="south_vestibule"]`, `props[id="reception_desk"]`
* **Defect Analysis:**
  Per `BLUEPRINT_SCHEMA.md` and `site.json`, the building origin `(0,0,0)` is the main entrance threshold at Level 1 finished floor. `lobby` covers `x = [-10.0, 10.0], z = [-36.0, 0.0]`. The front desk enclosure is centered at `(-4.0, -15.0)`. However, on south exterior wall `l1_w094` (`a=[-97.0, 0.0], b=[10.0, 0.0]`), the entrance door is set at `offset: 50.0, width: 12.0` (spanning `x = -47.0` to `-35.0`, center `x = -41.0`). This opens directly into `south_vestibule`, completely bypassing `lobby`! As a result, `lobby` has no exterior entrance door, avatars entering at the origin walk into a solid wall, and automated route testing fails across all 89 rooms because `LOW_ENTRANCE` cannot connect to `1:lobby`.
* **Concrete Fix:**
  * On wall `l1_w094`, change the door opening:
    ```json
    {
      "type": "door",
      "offset": 91.0,
      "width": 12.0,
      "sill": 0,
      "head": 9.0,
      "leaves": 2,
      "tag": "RACDoor",
      "connection": ["OUTSIDE", "lobby"]
    }
    ```
    This places the 12-ft entrance opening from `x = -6.0` to `x = 6.0` at `z = 0.0`, centered exactly on `(0,0,0)`.
  * Entering avatars step straight into `lobby`, facing the 20-ft reception desk at `(-4.0, -15.0)` 10 feet ahead, with the wide glass hallway (`south_vestibule`) immediately to their left.

---

### Problem 3: Level 2 Racquetball Courts Misplaced into Dead-End Overlook with Inter-Court Single Point of Failure
* **Severity:** High (Walkthrough Order / Architectural Logic Violation)
* **Affected Element IDs:**
  * `blueprint/level2.json`: `rooms[id="racquetball_1"]`, `rooms[id="racquetball_2"]`, `rooms[id="corridor_l2_overlook"]`, `rooms[id="corridor_l2"]`, `walls[id="l2_w019"]`, `walls[id="l2_w030"]`, `walls[id="l2_w072"]`
* **Defect Analysis:**
  The walkthrough explicitly specifies the Level 2 route: walk along the overlook looking left into Competition Gym -> turn west -> pass two racquetball courts on the LEFT -> pass `stair_second` on the RIGHT -> reach Cage Gym (off limits) -> reach Level 2 exit at grade. `ARCHITECT_NOTES.md` line 17 explicitly specifies the courts south of `corridor_l2` at `x = -265..-225` and `-305..-265, z = -80..-60`.
  In `level2.json`, however, the courts were left north of Competition Gym at `z = [-319.5, -279.5]`. The overlook dead-ends at `z = -330.0` with no egress west. Worse, Court 1 has no corridor door; its only entrance is `Wall l2_w030` cut directly through the playing sidewall of Court 2! To reach Cage Gym or Stair 2, a player must walk 240 feet north to the dead end, walk through both courts, backtrack 240 feet south, and then walk west.
* **Concrete Fix:**
  1. Relocate both racquetball courts to the south side of `corridor_l2`:
     * `racquetball_2`: `polygon: [[-265.0, -80.0], [-225.0, -80.0], [-225.0, -60.0], [-265.0, -60.0]]` (40×20 ft, ceiling 16.5 ft).
     * `racquetball_1`: `polygon: [[-305.0, -80.0], [-265.0, -80.0], [-265.0, -60.0], [-305.0, -60.0]]` (40×20 ft, ceiling 16.5 ft).
  2. Create dedicated doors on the north wall of each court along `z = -80.0`:
     * Door to `racquetball_2`: on wall `z = -80.0`, `offset: 18.0, width: 4.0` (span `x = -247.0..-243.0`, tag `RACDoor`).
     * Door to `racquetball_1`: on wall `z = -80.0`, `offset: 18.0, width: 4.0` (span `x = -287.0..-283.0`, tag `RACDoor`).
  3. Delete inter-court door on `l2_w030`.
  4. Terminate `corridor_l2_overlook` at `z = -279.5` (northern boundary of `void_competition`), and convert the abandoned north bays (`x = [-118.5, -78.5], z = [-330.0, -279.5]`) into structural mechanical/void space.

---

### Problem 4: Stair Second (`stair_second`) Level 2 Door Drops 10 Feet onto Intermediate Landing
* **Severity:** High (Physical Collision / Life Safety)
* **Affected Element IDs:**
  * `blueprint/level2.json`: `walls[id="l2_w065"]`, `rooms[id="stair_second"]`, `stairs[id="stair_second"]`, flights `second_a`, `second_b`, landing `second_turn`
* **Defect Analysis:**
  In `stair_second`, flight `second_a` ascends west from `x = -305.5` to `x = -320.0` (elevation 0.0 to 10.0 ft). Landing `second_turn` sits at `x = [-325.0, -320.0]` at elevation +10.0 ft. Flight `second_b` ascends west from `x = -325.0` to `x = -339.5` (elevation 10.0 to 20.0 ft). Top of stair at Level 2 is at `x = -339.5`.
  However, on Level 2, corridor wall `l2_w065` (`a=[-345.0, -92.5], b=[-305.0, -92.5]`) places the door into `stair_second` at `offset: 20.5, width: 4.0`. The door center is `-345.0 + 20.5 + 2.0 = -322.5`. At `x = -322.5`, the stair is at elevation +10.0 ft! Opening this door from Level 2 (elevation +20.0 ft) drops the avatar 10 feet vertically into mid-air onto the landing.
* **Concrete Fix:**
  * Move the door on wall `l2_w065` from `offset: 20.5` to `offset: 3.5, width: 4.0`:
    * Spans `x = -341.5` to `x = -337.5` along `z = -92.5`.
    * Centers on `x = -339.5`, matching the top landing of flight `second_b` at elevation +20.0 ft with a zero-step level threshold.

---

### Problem 5: Thin Link (`thin_link`) Missing North and South Walls (113-Foot Open Gaps)
* **Severity:** High (Spatial / Acoustic Enclosure Failure)
* **Affected Element IDs:**
  * `blueprint/level1.json`: `rooms[id="thin_link"]`, `walls[id="l1_w074"]`, `walls[id="l1_w110"]`
* **Defect Analysis:**
  Walkthrough step 4 defines `thin_link` as "a thinner hallway with no doors that leads to a perpendicular hallway". `ARCHITECT_NOTES.md` specifies an 8-ft wide corridor (`115 x 8`). In `level1.json`, however, `thin_link` was built 16 ft wide (`z = [-186.0, -170.0]`), and both its north wall (`l1_w074`) and south wall (`l1_w110`) contain a **113-foot wide continuous opening** (`offset: 1.0, width: 113.0`). This leaves the entire corridor open to the Competition Gym and south locker foyer, destroying the sense of a discrete hallway.
* **Concrete Fix:**
  1. Remove the 113-ft openings from `l1_w074` and `l1_w110`.
  2. Rebuild `l1_w074` along `z = -186.0` as a solid 8" painted CMU exterior gym enclosure wall.
  3. Rebuild `l1_w110` along `z = -178.0` as a solid 8" painted CMU wall.
  4. Redefine `thin_link` polygon to 8 ft clear width: `polygon: [[-193.5, -186.0], [-78.5, -186.0], [-78.5, -178.0], [-193.5, -178.0]]`.
  5. Retain openings strictly at ends:
     * East: wall `l1_w025` at `x = -78.5`, `offset: 4.0, width: 8.0` from `corridor_gym_east`.
     * West: wall `l1_w039` at `x = -193.5`, `offset: 2.0, width: 6.0` into `athletic_corridor`.

---

### Problem 6: Reversed Athletic Suite Order along `athletic_corridor`
* **Severity:** High (Circulation & Gameplay Sequence Violation)
* **Affected Element IDs:**
  * `blueprint/level1.json`: `rooms[id="training_room"]`, `rooms[id="nutrition_vestibule"]`, `rooms[id="locker_volleyball"]`, `rooms[id="corridor_locker_west"]`, `walls[id="l1_w043"]`, `walls[id="l1_w045"]`, `walls[id="l1_w115"]`, props `train_t1..train_recycle`
* **Defect Analysis:**
  Walkthrough step 5 dictates: enter `athletic_corridor` from `thin_link` -> turn left (south) -> Training Room -> at end of hall, keypad door (15234) into Nutrition Vestibule with industrial fridge -> door on left into Volleyball Locker Room -> past locker room, continue straight to stairs up to Level 2.
  In `level1.json`, `training_room` was placed 80 feet south at `z = [-92.5, -62.0]`, past `corridor_locker_west` (which leads to Stair 2). Meanwhile, `nutrition_vestibule` and `locker_volleyball` were placed at `z = [-170.0, -140.0]`. To visit the training room and then the locker room, the player must walk south past the stairs, enter the training room, backtrack north to the locker room, and then walk south again. Furthermore, the Perkins & Will drawings (`Screenshot_2026-09-28_174411.jpg`) confirm the athletic training room sits at the north corner adjacent to the gym.
* **Concrete Fix:**
  Reorder spaces along the west wall of `athletic_corridor` (`x = -205.5`):
  1. `training_room`: relocate to `polygon: [[-236.5, -180.0], [-205.5, -180.0], [-205.5, -150.0], [-236.5, -150.0]]` (31×30 ft). Door on wall `l1_w043` at `offset: 4.0, width: 4.0` (span `z = -176.0..-172.0`).
  2. `nutrition_vestibule`: relocate to `polygon: [[-215.5, -150.0], [-205.5, -150.0], [-205.5, -140.0], [-215.5, -140.0]]` (10×10 ft). Keypad door on wall `l1_w043` at `offset: 35.0, width: 3.5` (span `z = -146.5..-143.0`, tag `keypad_door`, code `15234`).
  3. `locker_volleyball`: relocate to `polygon: [[-239.5, -140.0], [-205.5, -140.0], [-205.5, -118.0], [-239.5, -118.0]]` (34×22 ft). Entered via south door in `nutrition_vestibule` on wall `z = -140.0` at `offset: 3.0, width: 3.5`.
  4. Continue straight south on `athletic_corridor` to `z = -126.0`, opening directly west into `corridor_locker_west` (`x = [-305.0, -205.5], z = [-126.0, -112.0]`), which leads straight into `stair_second` at `x = -305.0`.
  5. Translate all `training_room` props in Z by `-88.0 ft` to match new room bounds.

---

### Problem 7: Severe Polygon Overlaps (>18,000 sq ft) and Sealed Rooms in Level 1
* **Severity:** Medium-High (Geometric Integrity / Rendering Glitches)
* **Affected Element IDs:**
  * `blueprint/level1.json`: `addition`, `cage_lower_reserved`, `corridor_ne`, `office_ne_reception`, `restroom_ne_w`, `restroom_ne_m`, `gym_foyer`, `locker_general_w`, `locker_general_m`, `storage_athletic`, `south_gym`, `stair_main`
* **Defect Analysis:**
  A polygon intersection audit reveals 15 severe overlapping room polygons totaling over 18,000 sq ft:
  * `addition` (`z = [-301.0, -92.5]`) overlaps `cage_lower_reserved` by 10,120 sq ft, `corridor_locker_west` by 2,240 sq ft, and `stair_second` by 1,380 sq ft.
  * `corridor_ne` swallows 2,164 sq ft of northeast offices and restrooms.
  * `gym_foyer` is an oversized catch-all polygon that completely swallows `locker_general_w` (896 sq ft), `storage_athletic` (384 sq ft), `locker_general_m` (304 sq ft), and `volleyball_washroom` (200 sq ft).
  * `south_gym` overlaps `stair_main` by 342 sq ft because the stairwell notch was not subtracted from the gym floor.
  * `cage_lower_reserved` is completely sealed with 0 doors, failing connectivity checks.
* **Concrete Fix:**
  1. Trim `addition` south boundary to `z = -220.0`: `polygon: [[-379.0, -301.0], [-225.0, -301.0], [-225.0, -220.0], [-379.0, -220.0]]`.
  2. Dissolve `gym_foyer` into distinct corridor circulation (`corridor_main`) and discrete locker room envelopes.
  3. Restrict `corridor_ne` to clean corridor polygons: `[[-78.5, -262.0], [-66.5, -262.0], [-66.5, -195.5], [-78.5, -195.5]]` and east-west leg `[[-66.5, -224.0], [-28.0, -224.0], [-28.0, -212.0], [-66.5, -212.0]]`.
  4. Boolean subtract `stair_main` notch `[[-106.0, -54.0], [-78.5, -54.0], [-78.5, -16.0], [-106.0, -16.0]]` cleanly from `south_gym`.
  5. Provide a construction/service door on wall `l1_w146` for `cage_lower_reserved` or classify its type as `construction`.

---

### Problem 8: Prohibited Brick Partitions in Lobby and Level 2 Gallery
* **Severity:** Medium (User Directive Non-Compliance / Visual Realism)
* **Affected Element IDs:**
  * `blueprint/level1.json`: `walls[id="l1_w105"]`, `walls[id="l1_w106"]`, `walls[id="l1_w036"]`
  * `blueprint/level2.json`: `walls[id="l2_w009"]`, `walls[id="l2_w014"]`, `walls[id="l2_w015"]`, `walls[id="l2_w054"]`, `walls[id="l2_w060"]`, `walls[id="l2_w070"]`, `walls[id="l2_w084"]`
* **Defect Analysis:**
  User reviews on 2026-09-29 (08:30 and 08:40) explicitly state:
  * "Level 2 lobby/gallery area: NO brick partition. Remove the brick partition wall(s) in the Level 2 lobby area. That area is an OPEN cardio floor... and the guardrail along the open edge over the lobby... Nothing walling it off from the balcony edge."
  * "Level 1 lobby is NOT partitioned off... open space flowing into the wide glass hall and the fitness area behind the desk... with the reception desk standing in it."
  * "Far less brick inside the building. Interior walls are mostly painted CMU and gypsum. Keep brick ONLY where a photo shows interior brick: accent walls/portals near volleyball locker corridor (IMG_0339, 0340, 0372, 0373)."
  Currently, multiple walls in the lobby, gallery, and cardio areas are assigned `material: "brick"`, and interior partition walls segment the ground-floor fitness floor.
* **Concrete Fix:**
  1. In `level1.json`: Remove partition walls `l1_w105` and `l1_w106` that enclose `fitness_annex` from `corridor_wide`, unifying the open selectorized fitness floor behind the front desk.
  2. In `level2.json`: Remove partition walls `l2_w014`, `l2_w060`, and `l2_w084` to open the cardio floor completely to the balcony guardrail.
  3. Change material from `brick` to `painted_cmu` or `gypsum` on walls `l2_w009`, `l2_w015`, `l2_w054`, and `l2_w070`. Maintain horizontal guardrails along `z = -16.0` and `x = -5.0`.

---

### Problem 9: Level 2 Overlook Circulation Jog vs Direct Concourse Flow
* **Severity:** Medium (Circulation Efficiency & Wayfinding)
* **Affected Element IDs:**
  * `blueprint/level2.json`: `rooms[id="corridor_l2_overlook"]`, `rooms[id="corridor_l2"]`, `walls[id="l2_w020"]`
* **Defect Analysis:**
  `corridor_l2_overlook` extends north along `x = [-78.5, -64.5]` from `z = -80.0` to `z = -279.5`. The cross-building concourse `corridor_l2` connects at the south end (`z = [-92.5, -80.0]`). If an avatar walks north to enjoy the competition gym overlook, they reach `z = -279.5` and are forced to turn around and walk 200 feet south to access the racquetball courts, Cage Gym, and Level 2 Exit.
* **Concrete Fix:**
  * At the south end of `corridor_l2_overlook` (`z = [-92.5, -80.0]`), establish a dedicated viewing station with full 9.5-ft glazed curtain wall opening into `void_competition`.
  * Ensure opening on wall `l2_w020` (`offset: 1.0, width: 10.0`) provides an immediate, unencumbered 10-ft wide westward transition onto `corridor_l2`.

---

## 2. Corrected Ordered Route with Coordinates

Below is the verified, physically continuous route through the RAC on both levels, providing concrete coordinates, directions of travel, and doorway locations.

```
LEVEL 1 ROUTE:
[0.0, 0.0] LOW_ENTRANCE -> [0.0, -15.0] 1:lobby (Desk) -> [-50.0, -10.0] 1:south_vestibule (Ping-Pong)
  -> [-88.5, -32.0] 1:stair_main (Flight 1 Base) -> [-72.5, -48.0] 1:corridor_entry_south
  -> [-72.5, -108.0] 1:corridor_entry_link (Trophy Case / Gym Doors) -> [-136.0, -174.0] 1:thin_link
  -> [-199.5, -174.0] 1:athletic_corridor -> [-221.0, -165.0] 1:training_room (Green Tables)
  -> [-210.5, -145.0] 1:nutrition_vestibule (Fridge) -> [-222.0, -129.0] 1:locker_volleyball
  -> [-305.5, -108.0] 1:stair_second (Flight 1 Base)

LEVEL 2 ROUTE:
[-80.5, -52.0] 2:stair_main (Flight 2 Top) -> [-71.5, -60.0] 2:main_stair_landing
  -> [-35.0, -64.0] 2:balcony (Cardio Rail) -> [-71.5, -180.0] 2:corridor_l2_overlook (Gym Overlook)
  -> [-150.0, -86.0] 2:corridor_l2 (Upper Concourse) -> [-245.0, -70.0] 2:racquetball_2
  -> [-285.0, -70.0] 2:racquetball_1 -> [-339.5, -108.0] 2:stair_second (Flight 2 Top)
  -> [-345.0, -112.0] 2:basketball_approach -> [-300.0, -150.0] 2:cage_gym ("OFF LIMITS")
  -> [-351.5, -102.5] HIGH_EXIT (At-Grade Exterior Exit)
```

### Level 1 Detailed Route Steps
1. **LOW_ENTRANCE `[0.0, 0.0]`:** Exterior entrance threshold under the black cantilevered canopy. Enter through the 12-ft entrance doorway on south wall `l1_w094` (`offset: 91.0, width: 12.0`, span `x = [-6.0, 6.0]`).
2. **`1:lobby` `[0.0, -15.0]`:** Enter the 20×20 ft double-height lobby (`x = [-10.0, 10.0], z = [-20.0, 0.0]`, ceiling 32.0 ft). Reception desk enclosure `reception_desk` sits at `[-4.0, -15.0]` (rotation 270, 20 ft long, depth 6 ft, perpendicular to the glass). To the right (east) is the open selectorized fitness center (`fitness_center`, `fitness_annex`).
3. **`1:south_vestibule` `[-50.0, -10.0]`:** Turn LEFT (west) through the open structural boundary at `x = -10.0`. Walk down the wide glazed hallway (`x = [-97.0, -10.0], z = [-16.0, 0.0]`) with floor-to-ceiling exterior wrap glass on your left (`z = 0.0`), ping-pong tables and vending machines along the hall.
4. **`1:stair_main` (Base) `[-104.5, -32.0]`:** At `x = -90.0`, pass through the 12-ft opening on wall `l1_w104` (`offset: 3.0, width: 12.0`) into the main stair hall. First flight `main_a` begins at `x = -104.5, z = -32.0`, climbing EAST (`direction: [1, 0]`) up to landing `main_turn` at `[-85.5, -32.0]` (+10 ft).
5. **`1:corridor_entry_south` `[-72.5, -48.0]`:** Continuing north past the stair opening via wall `l1_w104` (`offset: 19.5, width: 10.0`), enter the 12-ft wide terrazzo corridor (`x = [-78.5, -66.5], z = [-80.0, -16.0]`).
6. **`1:corridor_entry_link` & Trophy Case `[-72.5, -108.0]`:** Continue north past `z = -80.0`. Hallway narrows. On the RIGHT (east wall `l1_w069`) is the lit trophy case `trophy_main` at `[-67.55, -108.0]` with Mason jersey frames. On the LEFT (west wall `l1_w026`) are double doors into the competition volleyball gym at `z = -145.0` and `z = -155.0`.
7. **`1:thin_link` `[-136.0, -174.0]`:** At `z = -178.0`, on the LEFT, pass through doorless opening on wall `l1_w025` (`offset: 4.0, width: 8.0`) into the 8-ft wide thin hallway (`x = [-193.5, -78.5], z = [-178.0, -170.0]`). Walk west 115 ft between solid walls with no doors.
8. **`1:athletic_corridor` `[-199.5, -174.0]`:** Pass through doorless opening on wall `l1_w039` (`offset: 2.0, width: 6.0`) into the perpendicular north-south corridor (`x = [-205.5, -193.5]`).
9. **`1:training_room` `[-221.0, -165.0]`:** Turn LEFT (south). Immediately on the right (west wall `l1_w043` at `offset: 4.0`) enter the Athletic Training Room (`x = [-236.5, -205.5], z = [-180.0, -150.0]`) fitted with green treatment tables (`train_t1..train_t4`), taping stations, and ice machine.
10. **`1:nutrition_vestibule` `[-210.5, -145.0]`:** Continue south along `athletic_corridor`. At `z = -145.0`, access the keypad door on wall `l1_w043` (code `15234`) into the 10×10 ft vestibule containing industrial glass-door fridge `nutri_fridge` ("MATT CORSON NUTRITION STATION").
11. **`1:locker_volleyball` `[-222.0, -129.0]`:** Pass through the door on the LEFT (south wall of vestibule at `z = -140.0`) into the volleyball team locker room (`x = [-239.5, -205.5], z = [-140.0, -118.0]`, wood locker banks, whiteboard).
12. **`1:stair_second` (Base) `[-305.5, -108.0]`:** Exit back to `athletic_corridor`, walk south to `z = -120.0`, turn right (west) into `corridor_locker_west`, and proceed straight west to `x = -305.0`. Enter opening on wall `l1_w057` into `stair_second`. Flight `second_a` begins at `x = -305.5`, climbing WEST (`[-1, 0]`) up to Level 2.

---

### Level 2 Detailed Route Steps
1. **`2:stair_main` (Top) `[-80.5, -52.0]`:** Arrive at the top landing of flight `main_b` at elevation +20.0 ft.
2. **`2:main_stair_landing` `[-71.5, -60.0]`:** Step east through opening on wall `l2_w008` (`x = -78.5, offset: 3.0, width: 8.0`) onto the landing concourse (`x = [-78.5, -64.5], z = [-80.0, -40.0]`).
3. **`2:balcony` `[-35.0, -64.0]`:** Step southeast onto the open cardio balcony (`x = [-64.5, -5.0], z = [-80.0, -48.0]`). Walk along the horizontal wood-cap guardrails overlooking the double-height entrance lobby below (`z = -16.0`, `x = -5.0`).
4. **`2:corridor_l2_overlook` `[-71.5, -180.0]`:** Walk NORTH along the sealed concrete overlook corridor (`x = [-78.5, -64.5], z = [-279.5, -80.0]`). On your LEFT (west wall `l2_w018`) is continuous floor-to-ceiling glass looking down into the Competition Volleyball Gym (maple court, GM center logo, bleachers opposite).
5. **`2:corridor_l2` `[-150.0, -86.0]`:** Transition west through the 10-ft opening on wall `l2_w020` onto the main upper concourse (`x = [-345.0, -78.5], z = [-92.5, -80.0]`), heading WEST (`[-1, 0]`).
6. **`2:racquetball_2` `[-245.0, -70.0]`:** Walking west, on your LEFT (south wall `z = -80.0`), enter the first 40×20 ft racquetball court through its dedicated door at `x = -245.0`.
7. **`2:racquetball_1` `[-285.0, -70.0]`:** Still walking west, on your LEFT, enter the second 40×20 ft racquetball court through its dedicated door at `x = -285.0`.
8. **`2:stair_second` (Top) `[-339.5, -108.0]`:** Further west, on your RIGHT (north wall `l2_w065`), pass the door at `offset: 3.5, width: 4.0` (`x = -339.5`). This door enters the top landing of `stair_second` at elevation +20.0 ft. Stairs lead DOWN to the east (opposite to travel direction) back to Level 1.
9. **`2:basketball_approach` `[-345.0, -112.0]`:** Continue west past the stairs into `basketball_approach` (`x = [-351.5, -339.5], z = [-132.5, -92.5]`).
10. **`2:cage_gym` ("OFF LIMITS") `[-300.0, -150.0]`:** On the north wall, door on `l2_w071` carries prominent signage: **"BASKETBALL — OFF LIMITS"**, opening into the 14,300 sq ft Cage practice facility with active BAPC construction barriers.
11. **`HIGH_EXIT` `[-351.5, -102.5]`:** At the far west end of `basketball_approach`, exterior double doors on wall `l2_w040` (`offset: 27.0, width: 6.0`) carry sign **"LEVEL 2 EXIT AT GRADE"**. Step directly outside onto the elevated west terrain at grade elevation +20.0 ft.

---

## 3. Open Questions for the User

1. **Linn Gym South Extension (`south_gym`) vs Site Boundary:**  
   In `blueprint/level1.json`, `south_gym` extends south to `z = +47.0`, projecting 47 feet past the main entrance threshold at `z = 0.0`. On native site drawings, the rec gym wing does sit south of the entrance plaza, but should this southern bay remain modeled as active maple court surface (fitting 3 full cross-courts), or should the southern 30 ft be reserved for storage, bleacher stacking, and MEP circulation?
2. **Racquetball vs Squash Court Markings:**  
   The walkthrough designates both Level 2 courts as 40×20 ft racquetball courts, while official GMU Rec literature still lists "2 squash + 1 racquetball" and mentions a 2026 functional training conversion. Should both courts be modeled with regulation racquetball red lines and glass back doors, or should one court feature international squash markings (tin and high out-of-bounds line)?
3. **Double-Height Lounge: Juice Bar Counter vs Vending Fit-out:**  
   The 2009 EwingCole drawings and 2016 facility tour document a branded Freshens smoothie/juice bar counter in the double-height glazed lounge, while the recent walkthrough emphasizes ping-pong tables and vending machines. Should we include a decommissioned/functional juice bar millwork counter in `glazed_recreation`, or strictly ping-pong tables and vending banks?
4. **Coaches' Suite Secondary Secure Access:**  
   The coaches' office suite currently opens south into the open fitness floor (`corridor_wide` / `glazed_recreation` via wall `l1_w102`). Does athletic staff have a card-swipe door connecting the coaches' suite directly to the east public corridor (`corridor_gym_east`) or north locker corridor for direct gym access?
5. **Role of Southwest Egress Stair (`stair_west`):**  
   The secondary stair at the southwest corner (`stair_west`, `x = -357.5..-345.0, z = -80.0..-34.0`) connects the Level 1 office suite to the Level 2 upper service area. Should this stair remain fully walkable for player navigation and evasion during gameplay, or be locked/alarmed as a strictly non-walkthrough emergency egress?
