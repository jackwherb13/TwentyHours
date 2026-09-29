# QA round 2 — independent review

Place used: **rac_round4.rbxl** (complete `Workspace.RAC`). Connected studios were `Place1` = TwentyHours-preview (slabs only) and `rac_round4.rbxl`. User asked for TwentyHours.rbxl / never Jay test; this is the live built RAC.

No edits to `blueprint/`, `src/`, or the model.

Automated: `build.txt` walkthrough PASS, geometry 0 issues, **32323 parts**. `blueprint_check.txt`: L1 57/58 reachable, L2 32/32, 0 dead doors, 3 stairs. Those tools do not catch stair direction, racquetball order, or lidar.

Playtest: spawn (5, 3, −8) → west hall (−39, 3, −8) → gym approach (−90, 3, −140) → main stair (−84, 3, −30) → landing (−84, **10.1**, −40) → L2 (−83, **23**, −52) → overlook (−71, **23**, −179). Console: `Interior terrain carve blocks: 369`.

---

## A. Route walk (`docs/WALKTHROUGH.md`)

Eye ~5.5 ft. Captures in `verification/qa/round2/route/`.

| Step | Should see | Result |
| --- | --- | --- |
| 01 South entrance | Wide concrete stair + rails + ramp, thin dark wedge canopy, glass wrap, small south glass is the door | **Fail.** Thick white soffit, grass, night sky, trees under the slab. `step00_web_entrance_2.png`, `step01.png` |
| 02 Walk in | 20×20 double-height, desk ~10 ft in, long axis ⊥ south glass, stairs beyond | **Partial desk, fail volume.** Desk ~22 ft, frosted, white top, N–S. CMU walls pinch the room; no stair in view. `step02_lobby.png` |
| 03 Immediate LEFT hall | Wide hall, glass on left, ping-pong + vending, runs to gym | **Partial.** Ping-pong visible west through glass; playtest walked west then to gym. Not one straight glass hall. `step03.png` |
| 04–05 Main stair | Two flights, square landing, turn LEFT, +20 ft, first flight along the wall, set back | **Connects** (playtest +10 then +20, risers 7.06 in). JSON first flight still south; live treads climb north at x=−84.5. Not in the entry volume. `step04_stair.png` (overexposed overlook misfile — use playtest coords) |
| 06 Gym hall | Narrows; trophy/jerseys RIGHT; gym doors LEFT | **Partial.** Trophy case exists, no jerseys, blown white. `step06_trophy.png` |
| 07 Competition gym | Maple, green apron, gold lines, lived-in | **Maple/apron/lines yes** in close-up. Dark, lockers on the apron, trees in the volume. `step07_gym.png`, `materials/gym_maple_close.png` |
| 08 L2 overlook | Walkable hall, **glass LEFT** into volleyball gym | **Exists and walkable.** Gym through west glass. Hall nearly black. `step08_l2_overlook.png` |
| 09 After overlook | Racquetball LEFT; second stair DOWN RIGHT | **Fail order.** Courts at z≈−300 on the overlook north; `stair_second` still at x≈−320 |
| 10 Training / locker | Green tables, ice, rehab; keypad 15234; fridge; locker left | Tables + cabinet. White-out. Keypad text exists in DM. `step10_training.png` |
| 11 Coaches | Workout on RIGHT, glass suite, cubicles, HEAD COACH | Glass + cubicle rows. Empty, blown. Text `HEAD COACH` exists. `step11_coaches.png` |
| Cardio L2 rail | Horizontal rail at open edge | **Not visible** in `step09_cardio_rail.png` though 1065 guard parts exist |

---

## B. Exterior

Pairs: `verification/qa/round2/pairs/` (WEB_entrance_1/2, left_pole, IMG_0364/0368/0349/0358/0369, gym, coaches, overlook).

- **Canopy:** 12 ft thick wedge at y=31, 118 ft long. Fail.
- **Stairs/ramp:** 42 ft treads that descend to y=−6. Fail vs photos.
- **Roads/roundabout:** approach y=−6.24; building floats over trees. Fail vs lidar.
- **Parking:** grey field, grass at the edge, stalls not readable. Fail.
- **Trees:** faceted blobs. Fail.
- **South smaller glass as door:** held (spawn south). Composition still wrong.

---

## C. Building sense

- Stairs **do** connect L1↔L2 with 34 × 7.06 in risers and a landing (playtested).
- L2 overlook is a real corridor; gym on the left walking north.
- Upper floors exist; cardio rail not proven at the drop.
- Doors: 0 dead in the checker; `cage_lower_reserved` unreachable (construction).
- Lighting unusable (black / white).
- Terrain/trees under slabs.
- 32323 parts.

---

## User / manager required items (re-check)

| Item | Status |
| --- | --- |
| L2 gym-overlook hall | **Built and walkable**; view/lighting still wrong |
| Main stair two flights / left / +20 | **Walkable**; JSON and lobby placement still wrong |
| Exterior stairs/ramp | **Still wrong** (drops below L1) |
| Roads on lidar | **Still wrong** (~6 ft low) |
| Thin wedge canopy | **Still wrong** (12×118×32) |
| Stray elements | Lockers in gym, dual canopy, trees in volume |
| Trees | **Still wrong** |
| Functions as a building | Circulation improved; lighting/terrain/empty remain |
| South entrance | **Yes** |
| Reception desk 20–25 ft ⊥ glass | **Mostly yes** (~22 ft N–S, counter on top) |
| Stair set back / first along wall | Set back ~30 ft at first tread; not in the 20×20 |
| Hall left of door to gym | Path exists as an L, not one hall |
| L2 cardio rail | **Not shown** at the open edge |
| Coaches suite | Glass + cubicles; empty |
| Lived-in / 90% photos | **Fail** |
| Parking / no grass | **Fail** |
| Materials applied | Maple close-up **improved**; walls/court plastic remain |
| Terrain/grass indoors | **Fail** (trees under/through) |
| Lighting | **Fail** |
| 7 floating props | Checker 0; visual not closed |

---

## Severity counts

See `ISSUES_REVIEW.json`: **11 critical**, **6 major**, **3 minor**.

Not ready for the user. Architect: lobby/stair JSON, L2 racquetball order, lighting, life, terrain carve. Exterior: canopy, grade, trees, parking.
