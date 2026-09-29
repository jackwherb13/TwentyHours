# Offline blueprint QA — round 1

Independent check of `blueprint/` against `docs/WALKTHROUGH.md` (authoritative) and required user/manager fixes (2026-09-28 23:45, 23:47 desk, 2026-09-29 01:40, manager 02:30). No edits to blueprint, src, or the RAC model.

Convention: +X east, +Z south, north = −Z. Units feet. Level 1 floor = 0. Level 2 `elevation` = 20 (`blueprint/level2.json:2`).

## Tool runs

| Tool | Result |
| --- | --- |
| `python tools/verify_blueprint.py` | PASS. L1 56 rooms, 0 overlaps, 56/56 reachable. L2 32 rooms, 0 overlaps, **33/32 reachable** (count mismatch). Stairs: 3 checked. Matches `verification/qa/round1/blueprint_check.txt`. |
| `python tools/architect_route_check.py` | PASS. 4 routes, 107 apertures, 0 failures. |
| `verification/qa/round1/build.txt` | Geometry QA 0 issues; **SiteContext 0**. Live-build material/lighting/grass issues from manager 02:30 are **not** visible in JSON field presence. |

## What already matches (do not “fix” these)

- South entrance on the smaller glass, not the long east wall. Door on `l1_w070` `[-97, 0]→[10, 0]`, offset 94 ft → door ~`x = −3` to `3` at `z = 0`. East `x = 10` is glazing, no entrance door (`l1_w016`).
- Lobby double-height: `ceilingHeight` 32, `void_lobby` on L2. L2 plate set back: `cardio_south` / glass edge at `z = −16` (~16 ft from glass vs walkthrough ~15 ft).
- Main stair: two flights, square landing `7×7` at +10, first flight **east** `[1, 0]` along `z ≈ −17…−24` (17 ft in from glass), second flight **north** `[0, −1]`, left turn. Rise `20/34 = 0.588 ft = 7.06 in` ≤ 7.75 in. Total 20 ft.
- Hall left of door: `south_vestibule` `x = −97…−10`, `z = −16…0`, then `corridor_entry_south` / `corridor_entry_link` north to gym. Gym doors on east gym wall `l1_w002` (west side of hall = **left** walking north).
- L2 overlook `corridor_l2_overlook` `x = −78.5…−64.5`, `z = −262…−80`; gym west of corridor = **left** walking north. Curtainwall on `l2_w002`.
- Racquetball L2 only, 20×40, **south** of `corridor_l2` = **left** walking **west**. Second stair north of hall = **right** walking west; up-dir west so down faces back. `BASKETBALL — OFF LIMITS` on `l2_w065`. `LEVEL 2 EXIT AT GRADE` on `l2_w035` at `x = −351.5`. Terrain target `highThreshold [-351.5, 20, −102.5]`.
- Coaches suite north of east glazed bay; glass storefront `l1_w077` / `l1_w100`; nameplate `HEAD COACH`. Keypad `15234`, nutrition fridge.
- Every non-void room has `floorMaterial`, `ceilingHeight`, `ceilingType`, `wallFinish`.

---

## Issues

### 1. Reception desk not ~10 ft from the glass and faces the wrong way
- **Severity:** critical
- **Owner:** architect
- **Area:** lobby / `reception_desk`
- **Issue:** Walkthrough + 23:47: long axis perpendicular to the south window, **~10 ft inside**, 20–25 ft, counter facing the entry. Blueprint: `at [-6, -16]`, `rotation` 270, `length` 22 (`level1.json` ~4730–4738). Glass is `z = 0`, so the pivot is **16 ft** in, not 10. Schema: rotation 0 faces −Z; 270 faces **−X (west)**. Desk sits at `x = −6` in a room `x = −10…10`, so the public face is a **4 ft** slot against the west wall. Architect notes claim the counter faces east; JSON does not.
- **Evidence:** `blueprint/level1.json:4730-4738`; lobby polygon `level1.json:307-322`; `docs/WALKTHROUGH.md` entrance + 23:47; `docs/ARCHITECT_NOTES.md` lines 11, 30 (admits 10 ft vs 22 ft desk conflict).
- **Fix:** Place a 20–25 ft N–S desk with the **south end ~10 ft** from `z = 0` (pivot near `z = −20` if length is 22). Rotation **90** (face +X / east) if 0 is −Z. Deepen the lobby to ~32 ft (`z = 0` to `≈ −32`) so 10 ft setback + 22 ft desk + aisle fit. Do not leave the desk at `z = −16` facing west.

### 2. Lobby is 20×28, not the 20×20 double-height room — and still too small for the desk spec
- **Severity:** major
- **Owner:** architect
- **Area:** `lobby`
- **Issue:** Walkthrough: “about 20 × 20 ft” with no L2 above. JSON bbox `x −10…10` (20), `z −28…0` (28). 23:47 wants a **bigger** entry to hold a 20–25 ft perpendicular desk; 20×20 cannot hold a 22 ft N–S desk 10 ft off the glass. Current 28 ft depth is a compromise that still fails the 10 ft rule (issue 1).
- **Evidence:** `level1.json:303-327`; WALKTHROUGH main entrance; USER 23:47.
- **Fix:** Treat 23:47 as the size driver: entry room ≥ ~20 ft wide × ~32 ft deep, fully voided on L2, desk as in issue 1. Keep ~20 ft east–west if that matches the small south glass bay.

### 3. Desk / west opening conflict (architect’s own note)
- **Severity:** major
- **Owner:** architect
- **Area:** lobby west wall
- **Issue:** Notes: desk cannot sit 10 ft off the glass because “the north opening is in the middle of that wall.” Lobby west wall `l1_w017` `[-10, -28]→[-10, 0]`. A 22 ft desk 10 ft in occupies roughly `z = −32…−10` — it needs a deeper room and a west wall without a mid-span opening through the desk.
- **Evidence:** `ARCHITECT_NOTES.md:30`; `level1.json:1923-1929`.
- **Fix:** Move the vestibule / stair opening to the **west** of a deeper lobby (into `south_vestibule`) so the desk enclosure is a solid west edge of the 20×~32 room.

### 4. Main-stair first flight is set back, but L2 JSON stairs have no flights
- **Severity:** major
- **Owner:** architect
- **Area:** `stair_main` / `level2.json` stairs
- **Issue:** L1 stair matches the two-flight left-turn brief (`level1.json` stair_main; `stair_details.json:5-41`). L2 copies only a straight parent: `direction [0,-1]`, `risers 34`, `run 0.917`, **no `flights` / `landings`**. Builder that reads L2 stairs will draw a single 20 ft straight run, which is exactly the 23:45 / 01:40 failure mode.
- **Evidence:** `level2.json` stair objects (verify dump: keys id, polygon, fromLevel, toLevel, direction, width, risers, rise, run only).
- **Fix:** Duplicate `flights` + `landings` from L1 / `stair_details.json` onto L2 stair records (same polygons, elevations 0/10/20). Keep rise 0.588 ft.

### 5. L2 cardio / balcony guard is 3.5 ft **glass**, not horizontal rail; guards missing from level JSON
- **Severity:** major
- **Owner:** architect
- **Area:** L2 open edge `z = −16`, balcony
- **Issue:** 23:45 #1 + 01:40 #3: horizontal-rail guard (IMG_0343/0369/0370). `level2.json` has **no `guards` array**. Cardio south edge is wall `l2_w054` `[-42.5,-16]→[-10,-16]`, `material: glass`, `height: 3.5`. Architect notes: “Balcony rails stay 3.5 ft glass.” That contradicts the user. Guards exist only in `architect_layout.json:6122-6166`.
- **Evidence:** `l2_w054`; `ARCHITECT_NOTES.md:45`; USER-2026-09-28-2345 item 1/8; USER-2026-09-29-0140 item 3.
- **Fix:** Put `guards[]` on `level2.json` with horizontal-rail style along every drop: cardio `z = −16` `x ≈ −42.5…−10`, balcony/gallery edges `gallery_guard_1…4`. Do not use glass as the gym-overlook **and** the cardio rail; overlook glass stays on `x = −78.5`, rails elsewhere.

### 6. Racquetball is on the left only after a forced west turn — not on the northbound L2 route
- **Severity:** major
- **Owner:** architect
- **Area:** L2 circulation
- **Issue:** Walkthrough L2 (walking **away from the entrance** = north): overlook, then courts **on the left**, then second stair **on the right**. Courts are at `x = −285…−245`, `z = −80…−40`; overlook is `x = −78.5…−64.5`. A northbound walker never has courts on the left. Notes admit: “One straight line cannot keep both the gym and the racquetball courts on the left without cutting the competition gym.” `walkthrough_routes.json` L2 list jumps `corridor_l2_overlook` → `racquetball_2` and **omits** `corridor_l2`.
- **Evidence:** room bboxes (this audit); `ARCHITECT_NOTES.md:20-21, 26-27`; `walkthrough_routes.json:40-53`; WALKTHROUGH L2 steps 1–3.
- **Fix:** Either (a) get a user confirm of the north-then-west dogleg, and put `2:corridor_l2` in the route, or (b) shift courts to the **west side of the northbound overlook** (left while still facing north). Do not silently skip the hall in the route file.

### 7. “Hallway immediately left of the main door all the way to the gym” is a dogleg, 12 ft, and not the same room
- **Severity:** major
- **Owner:** architect
- **Area:** L1 entry hall
- **Issue:** 01:40 #2: hallway **immediately left** of the main door, continuous to the volleyball gym. Built path: west along `south_vestibule` (16 ft deep, 87 ft long, ping-pong at `z = −8`) then **north** in `corridor_entry_south` **12 ft** wide (`x = −78.5…−66.5`). Walkthrough 22:40 also wants that left hall **wide** with glass on the left the whole way. After the vestibule, the outer glass is the **south** wall, not the left wall of the northbound gym hall. `corridor_entry_south` is `type: corridor`, terrazzo, ceiling 12 — not double-height glass wrap.
- **Evidence:** `south_vestibule` bbox `x −97…−10, z −16…0`; `corridor_entry_south` `x −78.5…−66.5, z −80…−16`; USER 01:40 #2; WALKTHROUGH L1 route 1–3.
- **Fix:** Make a continuous public hall from the door’s left jamb to the gym doors, glass on the outer side for the south leg, width staying “really wide” until the documented narrow-down at the trophy case (`corridor_entry_link` / gym doors). Keep order: vestibule → stair → trophy on right → gym doors on left.

### 8. Entrance canopy does not cover the south glass wrap
- **Severity:** major
- **Owner:** architect (massing) / exterior (build)
- **Area:** south entrance canopy
- **Issue:** 23:45 #5: thin dark wedge cantilever over the wrap-around glass. `site.json` canopy polygon `x = −28…18`, `z = 0…12`, height 15, type canopy. South glass runs **`x = −97…10`**. West ~69 ft of glass (and the corner toward `x = −97`) has **no** canopy. `architect_constraints.json` canopy polygon is in an old coordinate frame (`z = 142…197`) and is not the live site record.
- **Evidence:** `site.json:529-551`; `l1_w070` `[-97,0]–[10,0]`; USER-2026-09-28-2345 #5; WEB_entrance_2.
- **Fix:** Canopy over the **full** south entrance glass (at least `x ≈ −97…10`) plus east wrap at `x = 10`, `z = 0…~−20`. Wedge soffit, dark metal, ~15 ft height as in HEIGHTS.md.

### 9. Coaches suite is on the east (right); 22:50 weights are behind the desk (west) — two “straight ahead” stories
- **Severity:** major
- **Owner:** architect
- **Area:** coaches vs fitness
- **Issue:** 01:40 #4: straight from the door, workout **on the right**, then interior-glass coaches suite. That matches `glazed_recreation` (east, `x −5…10, z −80…−28`) → `coach_suite` (`x −28…2, z −112…−80`) with glass on `l1_w077`/`l1_w100`. 22:50: **behind the front desk** = selectorized machines, then partition, then squat racks (`weight_room` `x −66.5…−40, z −124…−80` is **west / left**). Both exist; “straight ahead” is therefore a T: east to coaches, west to weights. Cubicles: only **4** `cubicle` props in L1 for a “bigger office area with many offices.”
- **Evidence:** room bboxes; L1 prop kinds (`cubicle`: 4); USER 01:40 #4; WALKTHROUGH 22:50; IMG_0323–0327.
- **Fix:** Keep coaches on the right with a full glass wall+door. Fill `coach_suite` with cubicle **rows** (not four loose desks). Keep weights behind the desk as a separate left/behind-desk floor. Do not make the user walk through coaches to reach the gym hall.

### 10. Exterior stairs, roundabout grade, parking, trees, grass-in-building (still required, not in this packet)
- **Severity:** major (live site) / not in interior JSON
- **Owner:** exterior
- **Area:** site / terrain
- **Issue:** 23:45 #3–4, #7; 01:40 #7; manager 02:30 #2. `build.txt` **SiteContext 0**. `site.json` has footprint, facade, roofs, canopy — **no** entry stair, ramp, roundabout, parking stalls, or trees. `terrain_relationship.json` only states a linear grade from `[0,0,0]` to `[-351.5, 20, -102.5]`. Architect notes: this pass does not build exterior stairs/roundabout/trees; Exterior.luau unused.
- **Evidence:** `build.txt:9`; `ARCHITECT_NOTES.md:31`; USER 23:45 #3–7; USER 01:40 #7; manager 02:30 #2.
- **Fix:** Exterior owner: lidar-based roads/hardscape, wide entry stair+handrails+ramp (WEB_entrance_1/2, IMG_0364–0368), parking with connected aisles and **no grass in lots**, terrain cleared under the full footprint, L2 west door at grade 20.

### 11. Manager 02:30 materials / lighting / empty rooms / floating props
- **Severity:** major (build) / minor (blueprint fields)
- **Owner:** exterior/builder for apply; architect for prop layout density
- **Area:** whole interior
- **Issue:** JSON **has** maple/terrazzo/porcelain/etc. on every room (this audit: L1/L2 missing-field list empty). Manager screens still show grey plaster and dark stairs — that is **builder apply**, not missing schema fields. Coaches still “scattered” (4 cubicles). Floating props were a live-build list (L2 fountain/treadmill); geometry QA now reports floating 0 — re-verify in Studio, not JSON.
- **Evidence:** manager 02:30; room material fields; L1 Counter cubicle=4; `build.txt` floating 0.
- **Fix:** Builder must bind `Materials.luau` + `art/materials` per `floorMaterial`/`wallFinish`. Architect: denser cubicle/training-room layouts. Lighting is a builder pass (fixtures per HEIGHTS.md / notes).

### 12. Racquetball clear height 16.5 ft vs 20 ft court
- **Severity:** minor (possibly major if user expects a real court)
- **Owner:** architect
- **Area:** `racquetball_1`, `racquetball_2`
- **Issue:** User: 40×20 racquetball on L2. Plan size 20×40 is correct. `ceilingHeight` **16.5** (`level2` rooms; notes table). Standard court is 20 ft clear. Roof 36.7 would allow ~16.7 ft if L2 is at 20. Notes ask the user; until answered this is a known shortfall.
- **Evidence:** L2 room ceil 16.5; `HEIGHTS.md` racquetball; WALKTHROUGH 23:00 #3.
- **Fix:** Raise court ceiling to 20 ft (roof already 36.7) or get user sign-off on 16.5.

### 13. `verify_blueprint.py` L2 reachable 33/32
- **Severity:** minor
- **Owner:** architect (tool or extra node)
- **Area:** connectivity accounting
- **Issue:** 32 rooms listed, 33 marked reachable. Suggests a phantom room (stair counted twice, or HIGH_EXIT). Gate still exits 0.
- **Evidence:** tool stdout; `blueprint_check.txt:3-4`.
- **Fix:** Make the denominator include voids/stairs consistently; fail on mismatch.

### 14. Gym doors lack `connection` tags
- **Severity:** minor
- **Owner:** architect
- **Area:** `l1_w002`
- **Issue:** Two 6 ft doors, offsets 110 and 121 on `[-78.5,-262]→[-78.5,-132.5]`, no `connection` array. Route check still passed; other gym-adjacent openings do have connections.
- **Evidence:** audit dump of `l1_w002`.
- **Fix:** Tag `["corridor_gym_east","competition_gym"]`.

### 15. South glass wall host material is `brick`, not glass
- **Severity:** minor
- **Owner:** architect
- **Area:** `l1_w070`, `l1_w016`
- **Issue:** Walkthrough: whole entrance front is glass wrapping the corner. Openings are curtainwall head 30, but wall `material` is `brick`, thickness 0.28 on the east piece. Risk the builder draws brick with punched glass instead of a glass wall with mullions.
- **Evidence:** `level1.json:1888-1918`, `3240-3285`.
- **Fix:** `material: glass` (or metal_panel mullion) on the south/east entrance runs; keep brick only on opaque returns.

### 16. Canopy vs wrap: east curtain wall still reads as the “big glass”
- **Severity:** minor
- **Owner:** architect
- **Area:** east facade `x = 10`
- **Issue:** 23:20: entrance is the **smaller** glass, and that section should be **longer** than previously drawn. South glass is 107 ft (`−97` to `10`) — long. East wall at `x = 10` still has 48+24 ft curtainwall on `l1_w016` plus more brick bays. Confirm the south bay is the visually dominant entrance and the east wall is secondary wrap, not a second lobby.
- **Evidence:** WALKTHROUGH 23:20; `l1_w016`, `l1_w070`.
- **Fix:** Lengthen/emphasize south glazing under the canopy; keep east as wrap-only (already no door).

### 17. `stair_west` extra egress
- **Severity:** minor
- **Owner:** architect
- **Area:** west office
- **Issue:** Third stair, not a walkthrough stop. 23:45 #6 stray elements. Notes already ask whether to keep it.
- **Evidence:** `stair_details.json:79-115`; `ARCHITECT_NOTES.md:37`.
- **Fix:** User call: keep as egress or delete from both floors.

### 18. South gym wing past the entrance line (`z = +47`)
- **Severity:** minor
- **Owner:** architect
- **Area:** `south_gym` / `void_south`
- **Issue:** `south_gym` / void to `z = +47` while entrance glass is `z = 0`. Notes question this. Can read as a volume south of the door the user never described.
- **Evidence:** L2 `void_south` bbox `z −62…47`; `ARCHITECT_NOTES.md:39`.
- **Fix:** Confirm against photos/OSM; clip south of `z = 0` if it is not the real gym.

---

## Required-fix checklist

| Source | Item | Blueprint status |
| --- | --- | --- |
| WT | South glass entrance + wrap | Partial (door south; host brick; canopy short) |
| WT | Lobby ~20×20 double height | Fail size (20×28); void OK |
| WT / 23:47 | Desk 20–25 ft, ⊥ window, ~10 ft in | Fail (16 ft in, rot 270) |
| WT / 23:00 / 01:40 | Main stair 2 flights, left, set back, along wall | L1 OK; L2 flights missing |
| WT | L2 +20 ft, risers ≤7.75 in | Pass (20 ft, 7.06 in) |
| WT / 23:45 | L2 overlook, gym on LEFT walking away | Pass (northbound) |
| WT | Racquetball left after overlook | Fail on northbound; pass after west turn |
| WT | Second stair down on right | Pass if walking west on `corridor_l2` |
| WT | Basketball OFF LIMITS | Pass label |
| WT | L2 exit at grade | JSON door + terrain target; exterior grade not in this packet |
| 01:40 | Hall left of door to gym | Path exists; not one wide glass hall |
| 01:40 | L2 cardio horizontal rail | Fail (3.5 glass; no level2 guards) |
| 01:40 | Coaches glass suite + HEAD COACH | Partial (glass+plate; weak cubicles) |
| 23:45 | Exterior stair, roundabout lidar, canopy, trees, parking | Not in interior blueprint; SiteContext 0 |
| 02:30 | Materials applied, no grass, lighting, layout, floaters | Fields present; apply is builder |

## Coordinates (quick map)

| Piece | x | z | notes |
| --- | --- | --- | --- |
| South glass | −97 → 10 | 0 | door offset 94 |
| Lobby | −10 → 10 | −28 → 0 | 20×28, ceil 32 |
| Desk pivot | −6 | −16 | rot 270, L=22 |
| South vestibule | −97 → −10 | −16 → 0 | left of door |
| Stair flight 1 | −66 → −50 | −24 → −17 | dir east, +0→10 |
| Landing | −50 → −43 | −24 → −17 | +10 |
| Stair flight 2 | −50 → −43 | −40 → −24 | dir north, +10→20 |
| Gym | −193.5 → −78.5 | −279.5 → −132.5 | |
| Overlook | −78.5 → −64.5 | −262 → −80 | |
| Racquetball | −285 → −245 | −80 → −40 | |
| Stair 2 | −339.5 → −305 | −132.5 → −92.5 | |
| Cage gym | −351.5 → −225 | −220 → −92.5 | |
| L2 exit | −351.5 | −102.5 | grade +20 |
| Coach suite | −28 → 2 | −112 → −80 | |
| Canopy | −28 → 18 | 0 → 12 | too short west |

End of round-1 offline blueprint QA.
