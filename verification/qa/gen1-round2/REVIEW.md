# QA round 2 — independent review (TwentyHours.rbxl)

Place: **TwentyHours.rbxl** (Studio id used). Reviewer did not edit `blueprint/`, `src/`, or the RAC model.

**Verdict: FAIL.** Do not show this build to the user as a RAC match.

Automated `blueprint_check.txt` has **zero FAIL lines** (rooms reachable). `build.txt` reports 0 geometry issues on 27697 parts. Those logs do not test walkthrough order, materials, lighting, terrain, or photos.

Offline notes: `offline_blueprint.md`, `offline_code.md`.

---

## A. Route walk (`docs/WALKTHROUGH.md`)

Eye-height camera (~5.5 ft) plus playtest (`character_navigation`). Captures in `verification/qa/round2/route/`.

| Step | Should see | Result |
|---|---|---|
| 01 Approach south entrance | Wide concrete stair + rails + ramp, thin dark wedge canopy, glass wrapping corner | **FAIL** thick Neon canopy, fat black columns, grass on landing. `step01.png`, `pairs/WEB_entrance_1.jpg` |
| 02 Threshold | 20×20 double-height, desk ~10 ft in | **FAIL** lobby 20×28; desk ~8 ft; spawn on desk. `step23_play_desk.png` |
| 03 Desk | 20–25 ft, perp to glass, frosted + raised counter, staff inside | **FAIL** white cabinets, no frost, walk-on. `step04.png` / `step05.png` |
| 04 Immediate LEFT hall | Wide glazed hall all the way to volleyball gym, ping-pong/vending on glass | **PARTIAL** ping-pong on south glass (`step21_glass_wrap.png`, `step22_play_pingpong.png` standing on table). Gym is a second 12 ft NS hall |
| 05 Main stair on LEFT | Two flights, first along wall, square landing, turn LEFT, +20 ft | **FAIL** stair east of gym hall = RIGHT; first flight runs east; rise ~20 ft is real. `step08.png` |
| 06 Hall narrows, trophy RIGHT, gym doors LEFT | Order along northbound hall | **FAIL** trophy then thin_link then gym doors. `step19_gym_doors.png` grey tile |
| 07 Training room | Green tables, ice, tape, rehab, board, desk | **PARTIAL** green tables only. `step11.png` |
| 08 Locker keypad 15234, fridge sign, door LEFT | — | **FAIL** vestibule mid-corridor, locker hand wrong, camera in wall |
| 09 Stair past locker to basketball + L2 exit | Straight hall | **FAIL** dogleg through training; `step18_basketball.png` no OFF LIMITS sign |
| 10 L2 overlook, gym LEFT through glass | Walkable corridor | **PASS-ish** glass + gym view `step16_l2_overlook.png`; then forced 90° turn; court not maple |
| 11 Racquetball LEFT | Glass-back courts | **FAIL** brick tunnel `step17_l2_west.png` |
| 12 Stair DOWN on RIGHT, opposite | — | Not visually confirmed as opposite-direction flight from this hall |
| 13 Workout RIGHT then coaches glass | Cubicles, HEAD COACH | **PARTIAL** cubicles `step12.png`; weights also west of door |

Playtest: navigation to lobby and vestibule succeeded; avatar clipped onto desk and ping-pong.

---

## B. Exterior pairs (`verification/qa/round2/pairs/`)

Stations from `blueprint/photo_stations.json`. `python tools/side_by_side.py`.

| Pair | Notes |
|---|---|
| WEB_entrance_1/2 | Canopy too thick; columns Neon; grass on stair; trees discs |
| WEB_entrance_left_pole | Glass wrap + ping-pong visible (good); terrain grass at plaza; cylinder tree |
| IMG_0364–0368 | Same entrance problems; stations estimated |
| IMG_0349 | Station aims at south gym/entrance, not service yard |
| parking_aerial.png | Grass in pavement, stacked pines, checker asphalt |

Roads/hardscape: county slabs Y min **−22 ft** vs FFE 0; **0 LotSlab**; south lidar majority grass. Roundabout/road still too low and grassy.

---

## C. Building sense

- Stairs: interior main stair has real risers to ~21.5 ft; L2 Stairs folder empty (meshes live on L1). Exterior stair is a shallow plaza.
- Upper floors: gym void + overlook glass exist; lobby void incomplete.
- Railings: cardio south edge has a rail (`step13.png`); not photo-matched.
- Doors: graph-reachable; several do not match walkthrough sides.
- Windows: south glass wrap OK; overlook OK; racquetball not glazed to hall.
- Lighting: Future intended; interiors black or blown white.
- Clipping: grass through floors/lots; player on props.
- Empty rooms: gym, halls, offices, racquetball hall.

---

## User / manager checklist (re-checked)

| Item | Status |
|---|---|
| L2 gym-overlook hall | Exists, not the full walkthrough hall |
| Interior stairs match walkthrough | Rise OK, hand and first-flight direction FAIL |
| Exterior entrance stair | Present, not photo-matched; grass on treads |
| Roads too low | Still; Y −22 |
| Canopy thin wedge | FAIL thick Neon |
| Stray elements | Neon columns, disc trees, grass cubes |
| Trees | FAIL stacked discs |
| Functions as a building | Circulation handedness FAIL; clip-through props |
| South smaller glass entrance | KEPT (correct) |
| Reception desk size/orient/counter | Orientation OK; size low-end; frost/counter/distance FAIL |
| Stair too close / first flight along wall | Setback 29 ft; flight runs east not along hall |
| Hall left of door to gym | Not one continuous hall |
| L2 cardio rail | Present, weak |
| Coaches suite | Cubicles yes; path/glass entrance weak |
| Interiors 90% / lived-in | FAIL |
| Parking lots complete, no grass | FAIL |
| Materials applied | Names set, look grey-white |
| Grass in building | Still in hall-north |
| Lighting | Still wrong |
| 7 floating props | Checker blind; treadmill/fountain still off floor |

---

## Evidence index

- `verification/qa/round2/route/` — 26 captures
- `verification/qa/round2/pairs/` — WEB_entrance_*, IMG_0349, IMG_0364–0368, parking_aerial
- `verification/qa/round2/building/` — gym_maple, hall-north, stair-from-hall
- Machine-readable: `ISSUES_REVIEW.json`
