# Offline blueprint vs WALKTHROUGH.md (round 2)

**Scope:** circulation and layout in `blueprint/*.json` only. `WALKTHROUGH.md` is authoritative. Every FAIL against the walkthrough is **critical**. Geometry QA (`blueprint_check.txt`: rooms reachable, no overlaps) is **not** a walkthrough pass.

**Coordinate frame used:** south glass on `z = 0`, `x` increasing east, walking **north** = decreasing `z`. Left/right are from that travel direction unless a step says otherwise.

**Verdict: FAIL.** The south-glass entrance, two-flight left-turn main stair, keypad/fridge locker sequence, racquetball-on-L2, basketball sign, L2 grade exit, cardio rail, and coaches suite exist, but the **order and handedness** of the L1 hall, the **20×20 entry**, the **desk**, the **locker door hand**, and the **L2 straight hall** do not match the user.

---

## Critical mismatches

### 1. Lobby is not a 20 × 20 double-height entry
| | |
|---|---|
| **Severity** | critical |
| **Owner** | architect |
| **Area** | L1 lobby / void |
| **Issue** | Walkthrough: open **20 × 20 ft** with **no second floor above**. Blueprint lobby is **20 ft E–W × 28 ft N–S** at the north (`x = -10…10`, `z = 0…-28`) and **28 ft** wide at the glass (`x = -18…10`). That is not 20×20. |
| **Evidence** | `docs/WALKTHROUGH.md` L9; `blueprint/level1.json` `lobby.polygon` L307–330; ceiling 32 L331–333. `level2.json` `void_lobby` L905–951 leaves a **5 × 12 ft** strip (`x = -10…-5`, `z = -28…-16`) **outside** the void, so L2 is not fully clear over the north-west corner of the lobby. |
| **Fix** | Shrink/reshape `lobby` to a **20×20** clear bay at the south door. Expand `void_lobby` to cover that entire rectangle. Do not let `cardio_south` / balcony occupy any of it. |

### 2. Reception desk: distance, length, raised counter
| | |
|---|---|
| **Severity** | critical |
| **Owner** | architect |
| **Area** | lobby desk |
| **Issue** | Walkthrough: **~10 ft inside**, long axis **perpendicular to the window**, **20–25 ft**, **raised counter** in a staff enclosure. Live prop is `length: 20` (floor of the range), `depth: 6`, `at: [-6.5, -17.5]`, `rotation: 270`. If 270 = N–S, the south end is at **`z ≈ -7.5` (7.5 ft from glass)**, not ~10 ft. No `raised` / transaction-top field. `structural_anchors.json` still has a **different** desk (`at [0,-10]`, `rotation: 90`, `size 16×3.6`, `nearEndDistanceToGlass: 2`) that contradicts `level1.json`. |
| **Evidence** | `WALKTHROUGH.md` L10, L76–77; `level1.json` `reception_desk` L4816–4826; `structural_anchors.json` L4–25; `ARCHITECT_NOTES.md` L12 (admits **8 ft** inside, not 10). |
| **Fix** | Single source of truth: 20–25 ft N–S enclosure, public frosted face to the east, south end **10 ft** from `z = 0`, raised counter + staff well. Sync or delete the stale anchor. |

### 3. Main stairs sit on the RIGHT of the gym hall, not the LEFT
| | |
|---|---|
| **Severity** | critical |
| **Owner** | architect |
| **Area** | `stair_main` vs `corridor_entry_south` |
| **Issue** | Walkthrough L1 route: along the left hallway, **on the left: the main stairs**. The northbound hall to the gym is `corridor_entry_south` at **`x = -78.5…-66.5`**. The stair volume is **`x = -66.5…-42.5`, `z = -60…-28`**. Walking **north** (to the gym), east is **right**. The stair is **east of the hall = RIGHT**. Walking **west** in `south_vestibule`, the stair is **north = also RIGHT**. |
| **Evidence** | `WALKTHROUGH.md` L39, L80–81; `level1.json` `stair_main` L500–524, `corridor_entry_south` L605–629; `stair_details.json` first flight L14–21. `ARCHITECT_NOTES.md` L12 describes this geometry and does not fix the hand. |
| **Fix** | Put the main stair **west of** the northbound hall (more negative `x` than the hall), so it reads **left** when walking from the door toward the volleyball gym. Keep two flights, square landing, left turn, +20 ft. |

### 4. First flight setback vs “along the hall,” and hall is not immediately the gym run
| | |
|---|---|
| **Severity** | critical |
| **Owner** | architect |
| **Area** | main stair setback / left hall |
| **Issue** | User 01:40: **immediately LEFT of the main door**, a hallway that **runs all the way** to the volleyball gym; stair **set back**; **first flight along the wall**. Immediate left is `south_vestibule` (EW along glass). The gym hall is a **second** NS leg (`corridor_entry_south`) starting **16 ft** inside. First flight south edge is **`z = -29` (29 ft from glass)** and runs **east**, i.e. **across** the plan, not along the NS gym hall. Setback itself is real; the “one left hallway with stairs on the left then gym” is not. |
| **Evidence** | `WALKTHROUGH.md` L37–39, L80–81; `south_vestibule` L562–597; flights in `level1.json` L4491–4544 / `stair_details.json` L14–38 (landing 7×7 at `x=-50…-43`, `z=-36…-29`). |
| **Fix** | One continuous left-side public hall from the door to the gym doors, stair opening on its left, first flight parallel to that hall wall, landing, left turn. |

### 5. L1 stop order is wrong: thin link vs gym doors vs trophy
| | |
|---|---|
| **Severity** | critical |
| **Owner** | architect |
| **Area** | corridor_entry_link / corridor_gym_east / thin_link |
| **Issue** | Required order walking from the entrance: **stairs → hall narrows → trophy RIGHT + first gym doors LEFT → further doors → immediately left, doorless thin hall → perpendicular hall**. Measured northbound (`z` decreasing): **trophy `z = -100`** (`trophy_main` in `corridor_entry_link`) → **thin_link `z = -132.5…-124.5`** → **gym doors `z ≈ -152` and `-141`** (`l1_w002` offsets 110 and 121 on wall from `z = -262`). Thin hall is **before** the gym doors, not after. Gym doors have **no `connection` array** (unlike other doors). |
| **Evidence** | `WALKTHROUGH.md` L40–43; `level1.json` `thin_link` L659–683; `trophy_main` L4879–4886; jerseys L4889–4906 at `z = -110` and `-90`; `l1_w002` L1608–1640. |
| **Fix** | Re-order along the northbound hall: narrow + trophy/jerseys on the **right**, gym leaf doors on the **left**, then further doors, then an **8 ft doorless** link on the **left** into the athletic NS hall. Tag gym doors `connection: [corridor_gym_east, competition_gym]`. |

### 6. Volleyball locker is not at the end of the perp hall; vestibule door is not on the LEFT
| | |
|---|---|
| **Severity** | critical |
| **Owner** | architect |
| **Area** | athletic_corridor / nutrition_vestibule / locker_volleyball |
| **Issue** | Walkthrough: perp hall; **left → training**; **at the end, just past the thin hall**, keypad locker; vestibule **only** the fridge; **door on the LEFT** into the locker. Training **is** west (left) of `athletic_corridor` (`x = -236.5…-205.5`, `z = -92.5…-62`) — that part matches. Nutrition vestibule is **east of the corridor** (`x = -193.5…-183.5`, `z = -102.5…-92.5`), **not at the end** (`corridor` runs to `z = -80` and `-180`). Thin link hits the corridor at **`z = -132.5`**; vestibule door is **~30 ft** north of that, mid-run. Vestibule→locker door is on the **south** wall near the **west** end (`l1_w090` offset 3). Entering from the corridor you face **east**; locker is **south = RIGHT**, not left. Keypad `15234` on the corridor door is present. Fridge prop has **no sign string** (sign lives only on a stale-ish anchor). |
| **Evidence** | `WALKTHROUGH.md` L44–47; `level1.json` rooms L686–791; `l1_w029` keypad door L2304–2317; `l1_w090` L3813–3838; `nutri_fridge` L5738–5745 (no `sign`); `structural_anchors.json` L40–50 `MATT CORSON NUTRITION STATION`. |
| **Fix** | Put keypad + 10×10 vestibule at the **end** of the athletic hall, just past the thin-link junction. Fridge only, signed **MATT CORSON NUTRITION STATION**. Locker door on the **left** from inside the vestibule. Keep code **15234**. |

### 7. L1 “straight down the hall” from locker to the second stair is a dogleg through the training room
| | |
|---|---|
| **Severity** | critical |
| **Owner** | architect |
| **Area** | locker → `stair_second` |
| **Issue** | Walkthrough: past the locker, **straight down the hall**, stairs up to L2, basketball on the left, L2 exit. `stair_second` is at **`x = -339.5…-305`, `z = -132.5…-92.5`**. Locker is at **`x = -193.5…-159.5`**. `west_link` (`x = -346.5…-236.5`, `z = -92.5…-80`) does **not** touch `athletic_corridor`. The graph path is **athletic_corridor → training_room → west_link → stair_second**. That is not a straight hall past the locker. |
| **Evidence** | `WALKTHROUGH.md` L48–49; `walkthrough_routes.json` L26–38 (skips `west_link`/`training_room`); `level1.json` `l1_w` training_room–west_link opening ~L2406–2414; `l1_w095` L3948–3974. |
| **Fix** | Continue the athletic / west public hall in a straight line from the locker to `stair_second`. Do not force players through the training room. |

### 8. Level 2 cannot keep gym LEFT then racquetball LEFT without a 90° turn
| | |
|---|---|
| **Severity** | critical |
| **Owner** | architect |
| **Area** | `corridor_l2_overlook` / `corridor_l2` / racquetball |
| **Issue** | Walkthrough L2: top of main stairs → **one hallway**, glass **LEFT** into volleyball, then **racquetball LEFT**, stairs **DOWN on RIGHT opposite**, basketball OFF LIMITS, L2 exit at grade. Architect **admits** a turn is required and that one straight line cannot keep both gym and courts on the left. After the turn onto `corridor_l2` (EW at `z = -92.5…-80`), the gym is **behind**, not on the left. Overlook glass on `l2_w002` only covers **`z = -262…-132.5`**; the south ~50 ft of `corridor_l2_overlook` (`z = -132.5…-80`) has **no** gym glass (team offices occupy that west side). |
| **Evidence** | `WALKTHROUGH.md` L15–23, L27–29, L67–68; `ARCHITECT_NOTES.md` L20–21, L27; `level2.json` `corridor_l2_overlook` L357–376, `corridor_l2` L438–463, `racquetball_*` L546–588 (20×40, south of hall = left when walking **west**), `l2_w002` curtainwall L1039–1061, `l2_w064` court doors L2391–2432. |
| **Fix** | Rebuild L2 public circulation so a walker leaving the main stair, traveling **away from the entrance glass**, has: gym glass continuously on the **left**, then racquetball on the **left**, second stair down on the **right** (run opposite the travel direction), then basketball, then grade exit. If the gym footprint must stay, rotate/move courts and the second stair to the **west side of the NS overlook**, not onto a separate EW hall. |

### 9. Ping-pong / vending are not “along the glass wrap” as a wide left hall in front of the stair
| | |
|---|---|
| **Severity** | critical |
| **Owner** | architect |
| **Area** | south_vestibule props |
| **Issue** | Walkthrough: **wide** left hall, ping-pong and vending **along the glass wrap**. `south_vestibule` is **16 ft** deep (`z = 0…-16`). Tables at `(-32,-8)` and `(-52,-8)` sit in the **middle** of that bay, not along `z = 0`. The continuation that actually reaches the gym is only **12 ft** wide. Stair is not in this glazed wrap (it starts 29 ft in). |
| **Evidence** | `WALKTHROUGH.md` L37–38; `level1.json` L562–597, L4829–4866; `ARCHITECT_NOTES.md` L12 (12 ft north leg). |
| **Fix** | Keep a **wide** glazed left hall from the door along the south glass, props on the glass line, then the same hall turning to the gym with the stair on the left. |

### 10. Fitness “behind the desk” vs “workout on the RIGHT” then coaches
| | |
|---|---|
| **Severity** | critical |
| **Owner** | architect |
| **Area** | fitness_annex / glazed_recreation / coach_suite |
| **Issue** | 22:50: **behind the desk** = selectorized, **partition**, then **squat racks**. 01:40: **straight from the main door**, workout **on the RIGHT**, then **glass coaches suite**, cubicles, **HEAD COACH**. Selectorized + racks are in **`fitness_annex`** (`x = -42.5…-5`, mostly **west / left** of the door, `z = -16…-48`). There is **no partition prop**. The north/east bay `glazed_recreation` (`x = -5…10`, `z = -80…-28`) has cardio bits and a **glass door at `z = -80`** into `coach_suite` (`l1_w079`) — that **right-side** coaches move is closer to 01:40. Two different workout floors; the partition sequence is missing. Head-coach plate exists (`head_plate` text `HEAD COACH` at `[-26.5,-88]`). |
| **Evidence** | `WALKTHROUGH.md` L51–54, L83–84; `level1.json` annex machines L4978–5040; `l1_w079` L3526–3561; `l1_w103` also opens **corridor_wide → coach_suite** from the **south** of the suite (second entrance, not “straight from the main door”); `head_plate` L5399–5407; cubicles L5110+. |
| **Fix** | One readable sequence from the door: desk → weights behind it with a real partition then racks; **right** of the northbound path = workout; **straight on** = glass storefront into cubicles + private offices + HEAD COACH. Remove or hide the extra south door from `corridor_wide` if it breaks “straight ahead.” |

### 11. Stale anchors vs live level JSON
| | |
|---|---|
| **Severity** | critical |
| **Owner** | architect |
| **Area** | `structural_anchors.json` vs `level1.json` |
| **Issue** | Checkers that still read anchors will place the desk on the wrong rotation/distance and the trophy at `[-68,-143]` in `corridor_gym_east` instead of `trophy_main` at `[-72,-100]`. That is a circulation/prop conflict inside the blueprint set. |
| **Evidence** | `structural_anchors.json` L4–37 vs `level1.json` L4816–4886. |
| **Fix** | Make `level1.json` / `level2.json` the only live geometry; rewrite anchors to match or drop them from the build. |

---

## What does match (not a pass overall)

These items **agree** with the walkthrough and should not be undone while fixing the FAILs.

| Step | Result | Evidence |
|---|---|---|
| Enter on **smaller south glass**, not east curtain | PASS | `l1_w071` `(-97,0)→(10,0)` door offset 90 (door at `x ≈ -7`) `level1.json` L3290–3337; east `l1_w016` glass only, no entry door L1920–1950; `site.json` origin L4–5. |
| Glass wrap on south + east corner | PASS (glazing present) | South 107 ft curtain + door; east head-30 curtain `l1_w016`. Canopy/RAC letters are exterior, not this check. |
| L2 floor-to-floor **+20 ft**, **34 risers ~7 in**, **two flights, one square landing, turn LEFT**, second flight **north** | PASS | `site.json` levels L87–95; `stair_details.json` L6–40 rise `20/34`, `turn: left`, flight A `[1,0]`, flight B `[0,-1]`. |
| Main stair **set back** from glass (not in the curtain bay) | PASS vs 01:40 setback only | First flight `z = -29…-36` (`stair_details.json` L16). Round-1 “against the glass” is **fixed in JSON**. Handedness still FAIL (#3). |
| Ping-pong + vending exist in south vestibule | PASS as props | `level1.json` L4829–4866. Placement vs glass still FAIL (#9). |
| Trophy case + jersey frames on hall | PASS as kinds | L4879–4906. Side/order still FAIL (#5). |
| Gym doors on **left** of northbound hall | PASS handedness | `l1_w002` on `x = -78.5` (west side of hall). Order vs thin_link still FAIL (#5). |
| Keypad **15234** on nutrition door | PASS | `l1_w029` L2317. |
| Vestibule 10×10, fridge present, generic locker (no dedication) | PASS as rooms | `nutrition_vestibule` L740–764; locker L767–791. Sign + door hand FAIL (#6). |
| Training room left of athletic hall, green tables | PASS | `training_room` L713–737; `train_t1…t4` L5410–5447. |
| Racquetball **L2 only**, **40×20**, left when walking **west** on `corridor_l2` | PASS local | `level2.json` L546–588; no L1 racquetball rooms. Global L2 path FAIL (#8). |
| Second stair **right** of westbound L2 hall; up-direction west so **down faces back** | PASS local | `stair_details.json` L43–77 `direction [-1,0]`; volume north of `corridor_l2`. |
| **BASKETBALL — OFF LIMITS** then **LEVEL 2 EXIT AT GRADE** | PASS | `level2.json` L2466–2477, L1729–1737; `terrain_relationship.json` high door `[-351.5, -102.5]` at elev 20, continuous slope L15–45. |
| Cardio open edge **horizontal rail** at `z = -16` | PASS | `level2.json` `cardio_rail` L3618–3628; `cardio_south` south edge `z = -16` L303–323. ~16 ft setback vs written **~15 ft** — within a foot. |
| Coaches cubicles + HEAD COACH plate + glass | PASS as program | `coach_suite` / `coach_head` L1374–1479; plate L5399–5407; curtain on `l1_w079`/`l1_w103`. Sequence vs door FAIL (#10). |
| Blueprint connectivity (schema) | PASS for the checker | `verification/qa/round2/blueprint_check.txt`: 56/56 and 32/32 reachable. Does **not** encode left/right or walkthrough order. |

---

## Ambiguities (flagged, not invented)

1. **Wide left hall vs thinner hall just inside** (`WALKTHROUGH.md` L37 vs L52). Keep **order** of ping-pong/vending → stairs → trophy/gym → thin link → training/locker if geometry conflicts. Current plan splits this into vestibule + 12 ft NS hall and **reverses** thin vs gym.
2. **Squash vs racquetball:** 23:00 says racquetball 40×20 on L2. Modelled as racquetball. Do not put courts on L1.
3. **“Three switchbacks”** superseded by two flights / one landing. Current stair geometry follows the correction; **placement/hand** do not.
4. **`stair_west`:** not a walkthrough stop (`ARCHITECT_NOTES.md` L17, L36). Leave as egress unless it blocks the second-stair route.
5. **`structural_anchors.json` vs `level*.json`:** treat `level1.json` / `level2.json` / `stair_details.json` as the built plan; anchors are inconsistent.

---

## Suggested owner split

| Owner | Fail IDs |
|---|---|
| **architect** | 1–11 (all circulation/rooms/props in JSON) |
| **exterior** | none in this offline **circulation** pass. South door location is correct in plan; canopy, wide exterior stair/ramp, and grade mesh remain exterior photo-match (round 1 issues) and are out of this file unless they move the **LOW_ENTRANCE** point. |

---

## Bottom line

Do **not** treat `blueprint_check.txt` or `build.txt` PASS as walkthrough compliance. Rebuild the **left-hand L1 public hall** (door → glass wrap + rec → stair on left → trophy/gym → thin link → training/locker/keypad → straight to second stair) and the **single L2 hall** (overlook glass left → racquetball left → down-stair right → basketball → grade exit). Fix lobby **20×20**, desk **10 ft / 20–25 ft / raised counter**, locker **left-hand** door, and fridge **sign**. Until those land in JSON, round-2 blueprint circulation is **FAIL**.
