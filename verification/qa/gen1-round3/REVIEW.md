# QA round 3 — independent review (TwentyHours.rbxl)

Place: **TwentyHours.rbxl** (Studio `Place1` / `a829f151-5bf0-4ef3-b7d0-727e4296c770`). Reviewer did not edit `blueprint/`, `src/`, or the RAC model.

**Verdict: FAIL.** Do not show this build to the user as a RAC match.

Automated `blueprint_check.txt`: **0 FAIL lines** (57/58 L1 reachable; sealed construction room). `build.txt`: walkthrough script PASS; building geometry 0 issues on 31913 parts; full-model QA **7 doorBlocked + 10 floating** on `RAC.Props`. Those logs do not test photos, lighting, site grade, or walkthrough *order*.

Offline notes: `offline_blueprint.md`, `offline_exterior.md`.

---

## A. Route walk (`docs/WALKTHROUGH.md`)

Playtest (`character_navigation`, Client) plus eye-height cameras. Captures in `verification/qa/round3/route/`.

| Step | Should see | Result |
|---|---|---|
| 01 Approach south entrance | Wide concrete stair + rails + ramp, thin dark wedge canopy, glass wrapping corner | **FAIL** thick dual canopy with gap over doors, shallow tiled plaza, ball trees, RAC letter stack, cube shrubs. `pairs/WEB_entrance_2.jpg`, MCP `WEB_entrance_2` / `qa_r3_step01_approach` |
| 02 Threshold | 20×20 double-height, desk ~10 ft in | **FAIL** lobby is a bright washed slot; desk is a small white bar. `step04_play_lobby.png` |
| 03 Desk | 20–25 ft, perp to glass, frosted + raised counter, staff inside | **FAIL** four white cabinet doors, long face parallel to south glass, west neck. `step03.png`, `pairs/IMG_0369.jpg` |
| 04 Immediate LEFT hall | Wide glazed hall all the way to volleyball gym, ping-pong/vending | **PASS existence** ping-pong + vending on south glass, hall continues. `step05.png`, `step06_play_pingpong.png` |
| 05 Main stair on LEFT | Two flights, first along wall, square landing, turn LEFT, +20 ft, set back | **PARTIAL** two flights + landing + ~20 ft rise (`step07.png`). First flight runs **north** at x=−83.5, south edge z=−22. Playtest **clipped through** the stair brick. `step20_play_stair_clip.png` |
| 06 Hall narrows, trophy RIGHT, gym doors LEFT | Order along northbound hall | **PARTIAL** gym doors left, dark trophy box at end, jersey **on the floor**. `step08.png` dim |
| 07 Training room | Green tables, ice, tape, rehab, board, desk | **FAIL** black tables in a black room. `step11.png` |
| 08 Locker keypad 15234, fridge sign, door LEFT | — | **PASS signage** fridge `MATT CORSON NUTRITION STATION`, keypad 15234. `step12.png` |
| 09 Stair past locker to basketball + L2 exit | Signs | **PASS signs** `BASKETBALL — OFF LIMITS`, `LEVEL 2 EXIT AT GRADE`. `step18.png`, `step19.png` |
| 10 L2 overlook, gym LEFT through glass | Walkable corridor | **PASS existence** play at (−71, 23, −180), glass left, green apron visible. `step15_play_overlook.png`. Gym dark, floor dark. `step16.png` |
| 11 Racquetball LEFT then stair DOWN RIGHT | Courts on the L2 walk | **FAIL** courts are north of the gym, not on `corridor_l2`. `step17_play_l2hall.png` black brick |
| 12 Workout RIGHT then coaches glass | Cubicles, HEAD COACH | **PARTIAL** glass + cubicles + `HEAD COACH` text; suite pitch black. `step13_coaches.png` |

Playtest spawn at LobbySpawn (5, 0.2, −8). Navigation to ping-pong hall and L2 overlook succeeded. Navigation toward coaches put the avatar **inside the stair wall**. Camera in play is third-person from outside the glass.

---

## B. Exterior pairs (`verification/qa/round3/pairs/`)

Stations from `blueprint/photo_stations.json`. `python tools/side_by_side.py`.

| Pair | Notes |
|---|---|
| WEB_entrance_1/2 | Canopy too thick, gapped over doors; stairs a plaza; ball trees |
| WEB_entrance_left_pole | Glass wrap + ping-pong visible (good); grass at plaza |
| IMG_0364 / 0368 | Same entrance problems |
| IMG_0369 | Desk not frosted, not photo composition |
| IMG_0344 / WEB_vb_gym_overlook | Overlook glass exists; gym dark, not maple-bright |
| IMG_0323 | Coaches glass exists; interior black |
| parking_aerial_build.png | Checker lots, grass, no stalls, dual canopy |

Terrain voxels: lobby/entry/gym at FFE = **Concrete** (interior grass from `M1/user0140/hall-north.png` not reproduced at those samples). East lot asphalt only at **y = −20…−8**, empty at y = 0. Roads still sit in a hole relative to the building.

---

## C. Building sense

- Stairs: main and second have real risers to ~21.5 ft; going is too short (7–8.5 in). Exterior stair is a shallow plaza. Player can clip the main stair wall. Sky leak in the stair well.
- Upper floors: gym void + overlook glass exist and are walkable.
- Railings: stair rails exist; cardio south edge **not visually confirmed** this round (Studio UI ate the PrintWindow).
- Doors: graph-reachable; 7 prop-blocked swings.
- Windows: south wrap OK; overlook OK; racquetball not on the required hall.
- Lighting: 24655 fixtures; gym/training/coaches/L2 west still black; lobby blown white.
- Clipping: avatar through stair brick; floating treadmill/ping-pong parts.
- Empty rooms: gym, training, halls, dark offices.
- Part count 43362 > 40k SPEC budget.

---

## User / manager checklist (re-checked)

| Item | Status |
|---|---|
| L2 gym-overlook hall | **Exists and walkable** (was missing). Photo/lighting still fail |
| Interior stairs match walkthrough | Rise OK; setback/first-flight/clip FAIL |
| Exterior entrance stair | Present, not photo-matched |
| Roads too low | **Still**; lots at y ≈ −8…−20 |
| Canopy thin wedge | **FAIL** thick dual slab + door gap |
| Stray elements | RAC letters, cube shrubs, hydrant |
| Trees | **FAIL** balls + wedge pines |
| Functions as a building | Overlook/left hall better; racquetball order, lighting, clip FAIL |
| South smaller glass entrance | **KEPT** |
| Reception desk size/orient/counter | **FAIL** vs IMG_0369 / 23:47 |
| Stair too close / first flight along wall | **Still** ~22 ft, northbound first flight |
| Missing left hall to gym | **Built** (quality remaining) |
| L2 cardio rail | **Unverified** this round |
| Coaches suite glass + cubicles + HEAD COACH | **Present**, black, not photo-matched |
| Interiors fully built / 90% | **FAIL** |
| Parking kit, no grass in lots | **FAIL** |
| Materials applied | Maple variant assigned; render still dark tiled wood |
| Grass inside building | Not in lobby/gym samples; lots still grassy |
| Lighting | **FAIL** |
| Floating props | **10** (worse than manager’s 7) |

Machine-readable copy: `ISSUES_REVIEW.json`.
