# QA round 1 — RAC 1:1 (independent review)

Place: **20 Hour Weeks** (Team Create, placeId 100200567955206). Edit + Play. Jay test was not used. No edits to `blueprint/`, `src/`, or the RAC model.

Automated: `verification/qa/round1/build.txt` — Walkthrough check **PASS**, 0 failures, 24960 parts, geometry 0 issues. `blueprint_check.txt` — L1 61 rooms / 0 overlaps / 60/61 reachable; L2 34 rooms / 0 overlaps / 33/34 reachable; 3 stairs. **No FAIL lines.** Those checkers only test bbox predicates and door-graph reachability; they do not test photos, lighting, or play.

Live model (Edit): 24960 BaseParts, 396 lights, Zone tags 205, `RAC.Lighting` present. ClockTime 14.

Play (this session): spawn HRP (5.00, 3.39, -8.01). Memory **4716 MB**. Heartbeat ~**59** FPS in a corridor. LogService: **0** Infinite yield, **0** errors, **132** hinge warnings. PathfindingService: lobby→L2 stair / overlook / training / racquetball / L2 exit = **Success**; lobby→cage = NoPath.

---

## A. Route walk (`docs/WALKTHROUGH.md`)

Captures: `verification/qa/round1/route/stepNN.png` (afternoon 14:37–14:50 files). Eye height ~5.5 ft unless noted. Play used `character_navigation`.

| Step | Should see | Result |
|---|---|---|
| 01 South entrance | Wide concrete stair + rails + ramp, thin black wedge canopy, glass wrap, door in the **south smaller glass** | **Fail exterior.** Door is on the south glass at (0,0,0) (correct). Approach is a tiled plaza. Stairs are 7×42-ft treads at **x=−41**. Canopy is a 104×18 slab at y=30.55. Extra grey door in the east pier. `step01.png`, `pairs/WEB_entrance_2.jpg` |
| 02 Walk in | 20×20 double-height, desk ~10 ft in, long U, GM logo, frosted panels | **Partial.** Desk is in the room, 20 ft U, 4 stations, ball rack. Front is a white bar with a **green stripe**, not IMG_0369. Stair well immediately to the right. `step02.png` |
| 03 Immediate LEFT hall | Wide hall, glass wrap on left, ping-pong + vending, continues toward the gym | **Pass circulation.** West glass hall, ping-pong, red vending, double-height. Then an L north. Play HRP (−49.35, 2.97, −8.05). `step03.png` |
| 04–05 Main stair | Two flights, square landing, turn LEFT, +20 ft, first flight along the wall, set back | **Pass geometry / walkable.** First flight north at x=6, z=−26→−40; 8×8 landing at +10; second flight west to y≈19.9 at x=−12. Rise 0.588 ft. Player climbed: landing y=12.97, L2 y=22.27. Dark, orange Pathfinding gizmos, avatar clipped the wall. `step04.png`, `step05.png` |
| 06 Gym hall | Narrows; trophy/jerseys on RIGHT; gym doors on LEFT | **Pass sides.** Trophy case on the right (`step06.png`). Double doors on the left (`step06b_gym_doors.png`). JSON connections go to `gym_foyer`; player still reached the court. |
| 07 Competition gym | Maple, green apron, gold lines, lived-in, bleachers both long sides retracted | **Fail materials / life.** Cream tile grid, pixel GM text, green apron, gold lines, net, retracted gold/green bleachers. Sky hole in the north roof. Play HRP (−135.42, 2.97, −231.37). `step07.png` |
| 08 L2 overlook | Walkable hall, **glass LEFT** into volleyball gym | **Pass circulation.** Play HRP (−71.58, 22.97, −179.12). Gym on the left through glass. Glass starts ~z=−187; south of that is solid CMU. `step08.png`, `step12_play_l2_overlook.png` |
| 09 After overlook | Racquetball on LEFT; second stair DOWN on RIGHT | **Partial.** Courts sit south of `corridor_l2` (left when walking west). Opaque grey RACQUETBALL door, not glass. Player reached (−244.27, 22.97, −86.01). `step13_racquetball.png` |
| 10 Training / locker | Green tables, ice, rehab; keypad 15234; fridge; locker left | **Partial.** Four green tables, ICE machine, ATHLETIC TAPE cabinet. Room nearly black. Pathfinding lobby→training Success. `step10.png` |
| 11 Straight → coaches | Workout on RIGHT, glass suite, cubicles, HEAD COACH | **Partial.** Cubicle rows exist and are arranged. Too dark to read. Glass entrance / HEAD COACH / elevator not confirmed in these shots. `step11.png` |
| Cardio L2 rail | Open cardio, horizontal wood-cap rail, no brick partition | **Pass rail / open.** Sparse black treadmills. No bag / TVs / free-weight wall in frame. `step09.png` |

---

## B. Exterior

Pairs: `verification/qa/round1/pairs/` (WEB_entrance_1, WEB_entrance_2, WEB_entrance_left_pole, IMG_0364, IMG_0358). Stations from `blueprint/photo_stations.json`; IMG_0358’s authored pose is north of the gym (not the east road in the photo).

- **Entrance / canopy / stairs:** still wrong vs WEB_entrance_1/2 and IMG_0364–0368. Door on the south glass is the one correct piece.
- **Roads:** IMG_0358 is white/grey faceted terrain and a flying concrete mass, not Patriot Circle asphalt on lidar.
- **Parking:** `building/parking_aerial.png` — checkerboard slabs, blob trees, no readable stall field.
- **Trees:** WedgePart crowns (`building/trees_close.png`).
- **South smaller glass as main door:** origin is south (correct). Stairs/canopy still live 41 ft west on the long curtain.

---

## C. Building sense

- Stairs **do** connect L1↔L2 with 34 × 7.06 in risers and landings (main, second, west). A player climbed main. Landing is tight (clip).
- L2 overlook is a real corridor.
- Terrain under the building at y≈−2 Concrete (carve 389 blocks). Hall sample this session: 0 Grass. Decoration disable still missing in source.
- Lighting: gym/training/coaches/stair dark; lobby under-lit.
- Materials: variants exist (`RAC_maple` etc.) but the gym does not look like maple. TexturePack upload failed in console.
- Collision: 132 missing-hinge warnings; keypad doors walk-through; 64 colliding leaves.
- Guards: cardio wood-cap rail present.
- North gym/cage: flying slab in the IMG_0358 view.

---

## User / manager required items (re-check)

| Item | Status |
|---|---|
| L2 gym-overlook hall | Built and walkable; gym on LEFT. Glass only 91.5 ft of the hall |
| Main stair two flights / left / +20 | Live geometry matches; player climbed. Tight, dark, in the 20×20 |
| Exterior stairs/ramp | Still plaza + 41-ft offset |
| Roads on lidar | Still wrong |
| Thin wedge canopy | Still a high rectangular slab |
| Stray elements | Pathfinding gizmos, sky swatches, flying north slab |
| Trees | Still wedges |
| Functions as a building | Circulation works L1–L2; dark/empty/materials remain |
| South entrance | Yes, small glass at (0,0,0) |
| Reception desk 20–25 ft U | Size/U/stations yes; no frosted panels / GM logo |
| Stair set back / first flight along wall | Along wall yes; still in the entry bay |
| Hall left of door to gym | West glass hall + L north; player reached gym |
| L2 cardio rail | Present, open, sparse equipment |
| Coaches suite | Cubicles; dark; entrance/plate unverified |
| Lived-in interiors / 90% photos | Fail |
| Parking lots / no grass | Fail |
| Materials applied | Fail (gym) |
| Terrain/grass indoors | Carve present; terrain still at y=−2 |
| Lighting | Fail (rooms); infinite yield **gone** |
| 7 floating props | Not fully re-counted; gizmos/slab remain |
| L2 no brick partition (08:30) | Pass (open cardio) |
| L1 lobby not partitioned (08:30) | Improved; stair well still eats volume |
| Less interior brick (08:40) | Pass (only l1_w044, l1_w051) |
| Surroundings markings (08:40) | Fail |
| Dumpsters west of VB gym (09:35) | Fail (south of Linn) |
| Cannot get upstairs (10:21) | **Pass this session** |
| Zone tags = 0 (10:21) | **Pass (205)** |
| Lighting WaitForChild (10:21) | **Pass (0 infinite yield)** |
| Memory / FPS (10:21) | Memory still ~4.7 GB; FPS ~59 in a corridor |

---

## Gemini layout problems 1–9 vs live JSON

1. Main-stair void drop — **fixed** (top at x=−12.5, player arrived).
2. Entrance door 41 ft — **fixed** (door at origin). Exterior stair still at x=−41.
3. Racquetball north of gym — **fixed** (south of `corridor_l2`).
4. `stair_second` 10-ft drop — JSON door now on the +20 landing (not visually walked).
5. `thin_link` 113-ft openings — **fixed** (9×115 slab, solid sides).
6. Athletic suite order — **fixed** in JSON (training → nutrition 15234 → locker → second stair).
7. Polygon overlaps — **fixed** (0).
8. Brick partitions lobby/gallery — **fixed** (open cardio; 2 brick walls at lockers only).
9. Overlook backtrack — player walked overlook → racquetball; PathfindingService still NoPath on that pair.

---

## Verdict

**Do not show this to the user as done.** Circulation is now a real building you can walk (south door, left glass hall, two-flight stair, L2 gym-on-left overlook, racquetball). Photo match and materials are not. Highest-priority remaining: maple gym, interior light, entrance stair/canopy, roads/parking on lidar, trees, lived-in interiors, memory. Full issue list: `ISSUES_REVIEW.json`.
