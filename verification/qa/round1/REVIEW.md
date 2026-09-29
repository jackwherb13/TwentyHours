# QA round 1 — RAC 1:1 (independent review)

Place: **TwentyHours.rbxl** (Workspace parent). Edit + playtest. No edits to `blueprint/`, `src/`, or the RAC model.

Automated: `verification/qa/round1/build.txt` — **6 FAIL** (walkthrough). `blueprint_check.txt` — L1 57/58 reachable (construction excluded), L2 32/32, 3 stairs.

Live model (execute_luau): 7366 level parts, 8840 props, 5194 site, 966 lights, 33237 parts in play.

---

## A. Route walk (`docs/WALKTHROUGH.md`)

Captures: `verification/qa/round1/route/stepNN_*.png`. Eye height ~5.5 ft unless noted. Playtest: `character_navigation` to the glazed hall, competition gym, and L2 overlook all **succeeded**. Console: `Infinite yield` on `CoachVillainRemotes`.

| Step | Should see | Result |
|---|---|---|
| 01 South entrance | Wide concrete stair, ramp, thin black wedge canopy, glass wrap, south smaller glass is the door | **Fail.** Tiled plaza, thick black slab canopy, small door in brick pier, blob trees. `step01_entrance.png` |
| 02 Walk in | 20×20 double-height, desk ~10 ft in, long axis ⊥ glass | **Fail volume.** Desk exists (frosted, white top, ~22 ft N–S). A CMU wall fills the room; lobby slab 7×14. `step02_lobby.png` |
| 03 Immediate LEFT hall | Wide hall, glass wrap on left, ping-pong + vending, continues to gym | **Partial.** West glazed hall with ping-pong and a red vending unit. Then an L north to the gym. `step03_left_hall.png` |
| 04–05 Main stair | Two flights, small square landing, turn LEFT, +20 ft, set back, first flight along the wall | **Partial.** Live treads: first flight **north** at x=−83.5, z=−22→−34; landing 6×6 at +10; second **west** to +20. Risers 7.06 in. Width **6 ft**. JSON still says east then north. `step04_stair.png` |
| 06 Gym hall | Narrows; trophy/jerseys on RIGHT; gym doors on LEFT | **Partial.** White gym doors on the left. No trophy case. Brick dead-end. `step06_gym_hall.png` |
| 07 Competition gym | Maple, green apron, gold lines, lived-in | **Fail.** Dark; floor grey/teal tiles. Playtest: teal court, character clips bleachers. `step07_gym.png`, `materials/gym_maple_close.png` |
| 08 L2 overlook | Walkable hall, **glass LEFT** into volleyball gym | **Exists and walkable.** Glass on left. View through glass is blown-out white/teal, not maple. `step08_l2_overlook.png`, `step12_play_l2_overlook.png` |
| 09 After overlook | Racquetball on LEFT; second stair DOWN on RIGHT | Live `racquetball_1` slab at (−108.5, 19.75, −299.5) 20×40 (past gym). JSON still at z=−80 (FAIL). Second stair treads west along z=−108, L1 x=−306 → L2 x=−339. |
| 10 Training / locker | Green tables, ice, rehab; keypad 15234; fridge; locker left | Training tables present, **room nearly black**. Ice/whiteboard not readable. `step10_training.png` |
| 11 Straight → coaches | Workout on RIGHT, glass suite, cubicles, HEAD COACH | Glass door + cubicle rows exist. Floor reads tile. Empty. `step11_coaches.png` |
| Cardio L2 rail | Horizontal rail at open edge | **Present.** `step09_cardio_rail.png` |

---

## B. Exterior

Pairs: `verification/qa/round1/pairs/WEB_entrance_1.jpg`, `WEB_entrance_2.jpg`, `IMG_0358.jpg`, `IMG_0364.jpg` (real | build). Builds from Studio camera stations in `blueprint/photo_stations.json`.

- **Entrance / canopy / stairs:** still wrong vs WEB_entrance_1/2 and IMG_0364–0368.
- **Roads:** IMG_0358 is a grey plaza and faceted terrain, no two-lane asphalt.
- **Parking:** `building/parking_aerial.png` — grass inside lots.
- **Trees:** stacked discs + cones.
- **South smaller glass as main door:** origin is south (correct). Brick pier still owns the door.

---

## C. Building sense

- Stairs **do** connect L1↔L2 with 34 × 7.06 in risers and landings (main, second, west).
- L2 overlook is a real corridor.
- Terrain **under** the building at y=0 (raycast grid).
- Lighting: gym/training black; lobby/offices blown white.
- Materials: variants exist (`RAC_maple` etc.) but the gym does not look like maple.
- Collision: avatar in bleachers.
- Guards: cardio rail yes; other voids incomplete.

---

## User / manager required items (re-check)

| Item | Status |
|---|---|
| L2 gym-overlook hall | Built and walkable; view through glass still wrong |
| Main stair two flights / left / +20 | Live geometry matches; 6 ft wide; JSON FAIL |
| Exterior stairs/ramp | Still plaza |
| Roads on lidar | Still wrong |
| Thin wedge canopy | Still thick black slab |
| Stray elements | RAC letters, giant poster, bleacher clip |
| Trees | Still discs |
| Functions as a building | Circulation improved; dark/empty/terrain remain |
| South entrance | Yes, small glass |
| Reception desk 20–25 ft ⊥ glass | Live desk OK; lobby wall hides it; JSON FAIL |
| Stair set back / first flight along wall | ~22 ft setback; first flight north |
| Hall left of door to gym | Exists as L, not one straight run |
| L2 cardio rail | Present |
| Coaches suite | Present, empty |
| Lived-in interiors / 90% photos | Fail |
| Parking lots / no grass | Fail |
| Materials applied | Fail (gym) |
| Terrain/grass indoors | Fail (terrain at y=0) |
| Lighting | Fail (gym, training) |
| 7 floating props | Not fully re-counted this round |

---

## Verdict

**Do not show this to the user as done.** Highest-priority remaining: maple gym, interior light, terrain carve, canopy, entrance stair, roads/parking grade, trees. Full issue list: `ISSUES_REVIEW.json`.
