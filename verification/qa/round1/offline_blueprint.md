# Offline blueprint vs WALKTHROUGH.md (QA round 1)

**Scope:** read-only comparison of *current* `blueprint/*.json` against `docs/WALKTHROUGH.md` (authoritative), user reviews `USER-2026-09-28-2345` through `USER-2026-09-29-1025`, and Gemini layout problems 1–9. Interior/layout defects are owned by **architect**. Site/canopy/facade defects are owned by **exterior**. `src/` was inspected only to interpret how a JSON field is built (desk logo, bleacher `extended`, `keypadCode`).

**Coordinate frame:** feet. `+X` east, `+Z` south, plan north = `-Z`. Origin is the south entrance threshold. Left/right are from walking **into the door facing north**, unless a step says otherwise.

**Live packet:** `level1.json` 61 rooms / 148 walls / 172 props / 3 stairs / elevation 0. `level2.json` 37 rooms (34 non-void) / 107 walls / 58 props / 3 stairs / 11 voids / 31 guards / elevation 20. `site.json` `trueNorthDeg` 10.43, levels 1 and 2 only.

**Verdict: FAIL the walkthrough, PASS the automated gates.** `verification/qa/round1/blueprint_check.txt` reports 0 overlaps, 60/61 L1 reachable, 33/34 L2 reachable, 3 stairs. `verification/qa/round1/build.txt` reports `Walkthrough check: PASS; 0 failures` and 24960 parts. Those gates do not test door-to-room identity, desk rotation, gym-door connections, overlook glass *span*, interior brick accents, bleacher walls, or lobby partitions. Several user-required items are still wrong in JSON.

---

## What the automated checkers actually assert

### `tools/verify_blueprint.py`

Prints room/wall counts, axis alignment, overlap count; then a door-graph reachability walk; then stair code (riser ≤ 7.75 in, tread ≥ 10 in, `n * rise ≈` floor-to-floor).

- Ignores rooms with `type == "void"`.
- `NEEDS_ACCESS` = gym, corridor, lobby, office, fitness, locker, restroom, racquetball, storage, support, stair. **Does not require** `construction` or `mechanical`. That is why `cage_lower_reserved` (0 doors) and `overlook_mechanical` (0 doors) do not fail the 60/61 and 33/34 lines.
- Overlap tolerance 4 sqft. Current: **0 overlaps**.
- Stair check uses the *parent* `rise`/`run`/`risers`, not per-flight polygons. It does not test whether a Level 2 door lands on the top flight.

Quoted current output:

```
level1: 61 rooms, 148 walls, 100% axis-aligned, 0 overlaps
level1: 60/61 rooms reachable, 0 dead doors
level2: 34 rooms, 107 walls, 100% axis-aligned, 0 overlaps
level2: 33/34 rooms reachable, 0 dead doors
stairs: 3 checked
```

### `tools/check_walkthrough.py`

Docstring: *“Walkthrough handedness and material presence. Not a visual pass.”* Exit 0 prints `Walkthrough check: PASS; 0 failures`. It checks only:

| Check | What it actually tests | Gap |
| --- | --- | --- |
| Main stair in entry bay | `stair_main` bbox has `sx0 < 10` and `sx1 > -2` | Does not require the stair on the **left** hallway |
| L1/L2 stair polygons match | bbox equality | Ignores missing L2 `stair_west` flights |
| Flight A dir `[0,-1]`, B `[-1,0]`, left turn (`ux*vz - uz*vx == -1`) | Directions only | Does not test L2 door vs top tread |
| Flight A longer N–S than E–W; run ≥ 10 in; 17×rise ≈ 10 ft; width ≥ 8 | Numbers on `main_a`/`main_b` | `stair_details.json` is not read |
| First-flight south edge `-28 ≤ z ≤ -15` | Setback from glass | Passes at `z = -25.5` |
| Upper flight west edge `x = -12.5` | Top at the L2 opening | Does not check `cardio_south` vs `main_stair_landing` |
| Lobby bbox contains 20×20 and covers `x=-10..10, z=-20..0` | **Bounding box**, not a rectangular room | L-shaped lobby still passes |
| `void_lobby` covers the same 20×20 bbox | Bbox again | Does not require glass-front strip only |
| Desk `shape=="u"`, `length≥20`, `room=="lobby"`, `at` in `x=-10..10, z=-16..-6` | No rotation, no GM field, no clearance to the left hall | 20 ft E–W U at `(0,-10)` **passes while spanning the full 20 ft bay** |
| ≥2 doors on `x=-78.5` whose center `z < -120`; trophy `z` south of those centers | Does **not** require `connection` to `competition_gym` | Foyer doors at `z≈-152/-142` satisfy it |
| Gym maple; vestibule porcelain; `corridor_entry_south` terrazzo | Floor strings | — |
| Overlook has a curtainwall or `material=="glass"` on `x=-78.5` whose **wall endpoints** satisfy `z0≤-250` and `z1≥-110` | Uses the **whole wall** `a→b`, not the opening | `l2_w017` is `z=-330..-92.5` with only **91.5 ft** of actual glass |
| Racquetball south of `corridor_l2`, 40×20, along the hall; `stair_second` west of courts and north of the hall | Room bboxes | Does not test glass back wall or white walls |
| Nutrition vestibule west of athletic hall, 10×10; locker shares the vestibule south wall | Bboxes | Does not test keypad on the door, fridge sign, or “door on the left” from inside |
| `Materials.luau` not bleached white; assigns `RAC_` variants | Source string | Not a layout check |

A PASS here means those predicates held, not that a person walking the building matches `WALKTHROUGH.md`.

---

## Walkthrough steps vs live JSON

### 1. Main entrance door — south smaller glass, origin `(0,0,0)`

**Live:** `l1_w096` `a=[-97,0] b=[10,0]` material brick, exterior, height 32.5. Openings: curtainwall `offset 3.5 width 80` (`x=-93.5..-13.5`, head 30), curtainwall `x=-10..-7`, **door `offset 91 width 12` center `(0.0, 0.0)` span `x=-6..6`**, curtainwall `x=7..10`. East curtain wall is `x=10` (no entrance door). Canopy roof in `site.json`: `x=-28..18, z=0..12`, height 15, type `canopy`.

**Match:** door is on the south glass at the origin. Gemini problem 2 is **fixed**.

**Residual:** the south wall object is still `material: "brick"` with glass as openings (builder paints leftover wall as brick piers). Facade list in `site.json` has no segment `(-97,0)→(10,0)`. Exterior canopy/stair/plaza are outside this JSON comparison (user 23:45 items 3–5).

### 2. Lobby 20×20 double-height, desk U 20–25 ft, GM logo, perpendicular to glass, in the entry room

**Live lobby** (L-shaped, 728 sqft, ceiling 32 gypsum, porcelain):

```
[[-10,-16], [-12.5,-16], [-12.5,-40], [2,-40], [2,-23.5], [10,-23.5], [10,0], [-10,0]]
bbox x=-12.5..10, z=-40..0
```

The clear south bay `x=-10..10, z=0..-16` is **20 × 16 ft**, not 20×20. The extra area is the stair notch north of `z=-16`. `void_lobby` covers `x=-97..10, z=0..-40` (the glass strip plus the notch), so there is no L2 slab over the entry. Ceiling 32 / glass head 30. Double-height: **yes**. Strict 20×20 rectangle: **no** (bbox trick makes the checker pass).

**Desk `reception_desk`:** `kind=front_desk`, `at=[0.0,-10.0]`, `rotation=180`, `room=lobby`, `length=20`, `depth=7.5`, `shape=u`. Four `office_chair` at `z=-14`. `lost_found` cabinet `[-6,-16]`. `ball_rental` cart `[5,-16]`. `FrontDesk.luau` draws a green **GM** plate on the U front when `shape=="u"`. Staff well + four stations exist in the prop, not as extra JSON.

**Rotation 180** keeps `length` on world **X** (east–west), **parallel** to the south glass, not perpendicular. The 20 ft bar centered at `x=0` spans `x≈-10..10` — the full lobby width. Front face (prop local `-Z`, after 180) sits near `z≈-6.8` (**6.8 ft** from the glass, not ~10 ft). West return sits on `l1_w026` (`x=-10`).

**Lobby partition:** `l1_w026` at `x=-10, z=-16..0`, painted_cmu, openings **2 ft** (`z=-15.5..-13.5`) and **5 ft** (`z=-5.5..-0.5`). User 08:30: lobby is **not** partitioned; it flows into the glass hall. Live: a CMU wall with a 5 ft slot in front of the desk is the only walkable left-hall connection.

### 3. Immediate LEFT hallway — glass wrap, ping-pong, vending, continuous to volleyball gym

**Live `south_vestibule`:** `x=-97..-10, z=-16..0` (87 × 16 ft), porcelain, ceiling 32. Ping-pong `(-36,-4)` and `(-58,-4)`. Vending `(-80,-3)` and `(-92,-3)`. South glass is the `l1_w096` curtainwall.

**Not one straight hall to the gym.** Path is an L: vestibule west → `corridor_south_link` (`x=-97..-78.5, z=-54..-16`) north → `corridor_entry_south` (`x=-78.5..-66.5, z=-80..-16`) → `corridor_entry_link` → `corridor_gym_east`. Architect notes accept the L. User 01:40 still wants a hall that “runs all the way down and connects to the gym.” Geometry forces the north turn; the **2 ft / 5 ft lobby wall** is the part that is not forced.

### 4. Public lockers down the LEFT hallway

**Live `public_locker`:** `x=-130..-97, z=-40..-16` (33 × 24 ft). Door `l1_w042` at `x=-97`, center `z=-20`, label `LOCKERS`. Off `corridor_south_link`, ~20 ft inside, west of the left hall. **Location matches.**

Entering west: right = north, left = south, straight = west.

| Fixture | JSON | Hand vs user |
| --- | --- | --- |
| Lockers | `pub_lock_n` `[-99,-33.5]` rot 90, count 10 | Near door, **north = right**. Match. |
| ~5 stalls left | `pub_stalls` `[-126.5,-28]` rot 270, stalls 5 | `z=-28` is **north of the door** (right/center), not south (left). |
| Sinks across from stalls | `pub_sinks` `[-118,-28]` rot 90, sinks 4 | Same centerline as stalls, not across a left-hand restroom. |
| Showers straight ahead | three stalls at `z=-37.5` (north wall), `x=-120/-116.5/-113` | **Right/north**, not west/straight. |

### 5. Main stair — two flights, first along wall, square landing, turn LEFT, +20 ft, set back from the window

**Live L1 `stairs[id=stair_main]`** (L2 polygon matches):

| Piece | Polygon | Dir | Risers | Rise | Run | Width | Elev |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `main_a` | `x=2..10, z=-40..-25.5` | `[0,-1]` north | 17 | 0.5882 ft (7.06 in) | 0.8529 ft (10.24 in) | 8 | 0→10 |
| `main_turn` | `x=2..10, z=-48..-40` (**8×8**) | — | — | — | — | — | 10 |
| `main_b` | `x=-12.5..2, z=-48..-40` | `[-1,0]` west | 17 | 0.5882 | 0.8529 | 8 | 10→20 |

Parent: 34 risers, total rise 20.00 ft, left-turn cross product `-1`. First-flight south edge `z=-25.5` (25.5 ft from glass). L2 opening `l2_w009` at `x=-12.5, z=-47..-41` into **`cardio_south`**, not `main_stair_landing`. Top of `main_b` is at `x=-12.5`. Gemini problem 1 (west well / 24 ft chasm) is **fixed**.

**Handedness conflict (still live):** walkthrough 22:40 puts the stair **on the left hallway, on the left**. Live stair is in the **entry bay on the east wall** (`x=2..10`) = **right** as you walk in. Later lines (“past the desk: large stairs”, 01:40 setback + along the wall) are what the architect implemented. `ARCHITECT_NOTES.md` states the lobby stair replaced the west well on purpose. The 22:40 left-hand requirement is **not** met.

### 6. Gym hall: trophy RIGHT, gym doors LEFT

Walking north on `corridor_entry_link` / `corridor_gym_east` (`x=-78.5..-66.5`):

- **Trophy right (east):** `trophy_main` `[-67.5,-108]`, jerseys at `z=-118` and `z=-96`. Match for side.
- **Doors on `x=-78.5`:** `l1_w031` `z=-186..-132.5`, door offsets 31 and 41 → centers **`z≈-152` and `z≈-142`**, 6 ft pairs, **no `connection` array**. Those z values sit in **`gym_foyer`** (`z=-177..-132.5`), not `competition_gym` (`z=-279.5..-186`).
- **Gym east wall has no doors.** `l1_w001`/`l1_w002`/`l1_w003`/`l1_w004` (`x=-78.5, z=-279.5..-186`) are solid. Interior gym access is one 8 ft opening `l1_w075` `offset 100` at `z=-186, x=-93.5..-85.5` (`thin_link` → `competition_gym`).
- `gym_foyer` graph: **only** `corridor_gym_east`. Dead-end maple room (5118 sqft).

Trophy is ~40 ft **south** of those foyer doors (order trophy then “gym doors” while walking north). Walkthrough presents them as the same narrowing. Hall width stays 12 ft (`corridor_entry_south` / `_link` / `_gym_east`); it never narrows.

### 7. `thin_link` 8 ft, no doors

**Live:** `x=-193.5..-78.5, z=-186..-177` → **115 × 9 ft** (not 8). Floor terrazzo.

- South long wall `l1_w112` `z=-177`: **solid** (Gemini’s 113 ft hole is gone).
- North long wall `l1_w075` `z=-186`: **8 ft opening into the gym** at the east end (not a 113 ft aperture, but it is a door/opening on the thin hall).
- East: 8 ft opening to `corridor_gym_east`. West: 8 ft opening to `athletic_corridor`.

Gemini problem 5 is **mostly fixed**. Residual: 9 ft width; gym opening on the north wall; walkthrough “no doors.”

### 8. Athletic corridor order: training → nutrition keypad 15234 → volleyball locker left → second stair

Walking **south** (`z` increasing) from `thin_link` (`z≈-181.5`) on `athletic_corridor` `x=-205.5..-193.5, z=-186..-80`:

| Order | Room | Bbox | Door |
| --- | --- | --- | --- |
| 1 | `training_room` | `x=-236.5..-205.5, z=-180..-150` (31×30) | `l1_w048` offset 13, center `(-205.5,-165)` |
| 2 | `nutrition_vestibule` | `x=-215.5..-205.5, z=-150..-140` (**10×10**) | `l1_w048` offset 32 width 6, center `(-205.5,-145)`, `keypadCode="15234"`, label `NUTRITION VESTIBULE` |
| 3 | `locker_volleyball` | `x=-239.5..-205.5, z=-140..-118` (34×22) | south wall of vestibule `l1_w116` center `(-209,-140)` |
| 4 | `corridor_locker_west` | `x=-305..-205.5, z=-118..-100` | 8 ft opening `l1_w048` offset 67, center `(-205.5,-109)` |
| 5 | `stair_second` | `x=-343.5..-305, z=-132.5..-92.5` | `l1_w059` opening center `(-305,-109)` |

Fridge `nutri_fridge` at `[-213.5,-147]` with `sign: "MATT CORSON NUTRITION STATION"`. Gemini problem 6 (training 80 ft south of the locker) is **fixed**.

Facing west into the vestibule, left = south: locker on the south wall **matches** the checker and the “door on the left.” Training is immediately at the thin-link junction (turn left → training), keypad is 20 ft further south, not “at the end just past the thin hall,” but the **order** is correct.

### 9. Linn gym down the RIGHT hallway past workout

**Live `south_gym`:** `x=-236.5..-97, z=-62..47` (139.5×109, notched for `public_locker`), maple, ceiling 39. Opening `l1_w077` at `z=-62, x≈-151.5` `team_support` → `south_gym`. `team_support` also opens to `athletic_corridor`. East wall of the building is `x=10`, so a literal eastbound “right hall” cannot exist; architect maps “right” to the workout path.

Workout path: `lobby` → `fitness_annex` (`x=-42.5..-12.5, z=-48..-16`) → 28 ft opening `l1_w108` → `corridor_wide` → `corridor_entry_south` → `team_support` → Linn. **Connected**, but Linn is the **west/south** mass, not down an east hall.

### 10. Coaches suite — past workout + squat racks on the RIGHT, glass entrance, cubicles, HEAD COACH

**Live coaches block** (north of `z=-80`, east of the squat room):

- `coach_suite` `x=-28..2, z=-112..-80` (30×32), six cubicles, glass south wall `l1_w106` 27 ft curtainwall `x=-30.5..-3.5` plus door `corridor_wide` → `coach_head`.
- `coach_head` `x=-40..-28, z=-96..-80`, nameplate `HEAD COACH` at `[-34,-80.5]`.
- Ring of private offices: `coach_west`, `coach_west_n`, `coach_north`, `coach_east_*`.

**Squat racks** `rack_1`/`rack_2` are in `weight_room` `x=-66.5..-40, z=-124..-80`. Graph: `weight_room` ↔ `elevator` / `fitness_center` / `coach_west_n`. **Not** on the straight path lobby → annex → corridor_wide → glass suite. Walking north to coaches you do **not** pass the squat racks; they sit **west** of the suite. User 09:35: past workout **and squat**, coaches **on the right**.

### 11. Elevator between squat area and coaches

**Live `elevator`:** `x=-44..-36, z=-88..-80` (**8×8**), both levels. Doors: west to `weight_room` (`l1_w030`), east to `coach_head` (`l1_w071`), south to `corridor_wide` labeled `ELEVATOR` (`l1_w103`). **Matches.**

### 12. L2 overlook — walkable corridor, glass LEFT into volleyball gym

**Live `corridor_l2_overlook`:** `x=-78.5..-64.5, z=-279.5..-80` (**14 × 199.5 ft**), terrazzo (architect notes said sealed concrete). Walkable.

Glass: `l2_w017` `x=-78.5, z=-330..-92.5`, material **brick**, one curtainwall `offset 51.5 width 91.5` → actual glass **`z=-278.5..-187.0`**, head 9.5, mullions 5 ft. That covers the gym (`z=-279.5..-186`) only. The south **~107 ft** of the “overlook” (`z=-80..-187`) is brick on the gym side. Checker still passes because it uses wall endpoints `z=-330..-92.5`.

Arrival from the main stair is `stair_main` → `cardio_south` → `balcony` → `main_stair_landing` (`x=-78.5..-64.5, z=-80..-40`) → overlook. You walk the cardio deck before the gym glass.

### 13. Racquetball LEFT of L2 corridor (south of `corridor_l2`), light wood, white walls, glass

**Live:** both courts `z=-80..-60` (south of `corridor_l2` `z=-92.5..-80`), 40×20, maple, ceiling 16.5, `wallFinish=gypsum`. Hall wall `l2_w077` **glass** with dedicated doors at `x=-285` and `x=-245`, labels `RACQUETBALL`. No inter-court door. Gemini problem 3 is **fixed**.

Walking west: left = south = courts. Match.

### 14. Second stair RIGHT going DOWN

**Live well** `x=-343.5..-305, z=-132.5..-92.5` (north of `corridor_l2` = **right** when walking west).

| Piece | Polygon | Dir | Elev |
| --- | --- | --- | --- |
| `second_a` | `x=-335.5..-321, z=-123..-115` | `[-1,0]` west | 0→10 |
| `second_turn` | `x=-343.5..-335.5, z=-123..-115` (8×8) | — | 10 |
| `second_b` | `x=-343.5..-335.5, z=-115..-100.5` | `[0,1]` south | 10→20 |
| `second_bridge` | `x=-343.5..-335.5, z=-100.5..-92.5` | — | **20** |

L2 door `l2_w071` offset 8 width 4, span `x=-343.5..-339.5` at `z=-92.5`, center `x=-341.5` — on **`second_bridge` at +20**, not over the +10 landing. Gemini problem 4 is **fixed**.

Down from L2: first flight is north (reverse of `[0,1]`), then east. User “opposite the direction of travel” (westbound → down should read east) is only true of the **lower** flight.

`stair_details.json` still has the **old** straight-west pair (`second_a` `x=-320..-305.5`, `second_b` `x=-339.5..-325`, both `[-1,0]`). **Stale.** Live level JSON wins.

### 15. Basketball OFF LIMITS then L2 grade exit

- `basketball_approach` `x=-351.5..-343.5, z=-132.5..-92.5`.
- Door `l2_w078` `z=-132.5, x=-349.5..-345.5` label **`BASKETBALL — OFF LIMITS`** → `cage_gym`.
- Door `l2_w071` `z=-92.5` also labeled OFF LIMITS into the approach.
- Prop `bball_sign` `[-345,-128]` text `BASKETBALL — OFF LIMITS`.
- Grade exits: `l2_w022` at `x=-359.5, z=-88.5..-84.5` and `l2_w039` at `x=-351.5, z=-105.5..-99.5`, both `LEVEL 2 EXIT AT GRADE`. Prop `grade_sign` on `corridor_l2`.
- `cage_gym` is L2 only. `cage_lower_reserved` is construction, **0 doors** (intentional per notes).

**Match** for program and signage.

### 16. Third stair enclosed emergency

**Live `stair_west`:** `x=-357.5..-345, z=-80..-34`. L1 flights `west_a`/`west_b` dir `[0,1]`, 17+17, landing `west_turn` at +10, width 6, run 0.941 ft. Door from `corridor_office` `l1_w064`. Exterior door `l1_w066` at `x=-357.5`. `exit_sign` `stair_west_exit` at `[-342,-75]`. L2 copy has **no `flights` array** (polygon + parent rise only). Enclosed with a door and an exit sign: **yes**.

### 17. No third floor, no juice bar

`site.json` `levels` = `{1,0}` and `{2,20}` only. No room/prop id contains juice. **Match.**

### 18. L2 cardio OPEN (no brick partition), rail, treadmills, punching bag, TVs, free weights

**Live `cardio_south`:** `x=-42.5..-12.5, z=-48..-16` (30×32), rubber. West wall `l2_w015` is painted_cmu with a **30 ft opening** to `balcony` (wall is 32 ft — effectively open). No interior brick anywhere on L2.

- Rail: `cardio_rail` `[-42.5,-16]→[-12.5,-16]` and `gallery_rail` `[-64.5,-16]→[-42.5,-16]`, plus glass `l2_w064` height 3.5 at `z=-16`. **Match.**
- Treadmills: six in `cardio_south` at `z=-22` and `-30`.
- Heavy bag `l2_bag` `[-20,-38]`.
- TVs `l2_tv_1/2` at `x=-41` (west wall). Architect notes said **north** wall; user 09:35 did not specify the TV wall.
- Free weights `l2_weights` `[-40.5,-34]` on the west wall (perpendicular to the south glass). **Match.**
- Two benches `l2_bench_1/2` at `z=-40`. **Match.**

Gemini problem 8 gallery brick partitions: **fixed** (those ids are now glass rails or painted_cmu openings).

### 19. L1 lobby NOT partitioned

**Fail.** `l1_w026` still encloses the 20 ft bay from `south_vestibule` with 2 ft + 5 ft holes. `l1_w093` `z=-16, x=-42.5..-10` is a solid CMU wall between the glass hall and `fitness_annex` (flow to fitness is the 22 ft opening `l1_w023` at `x=-12.5` instead). User 08:30 is not met.

### 20. Interior brick ONLY at volleyball locker corridor accent

**Live interior brick count = 0** (L1 and L2). All 58 (L1) + 34 (L2) brick walls are `exterior: true`. Gemini’s lobby/gallery brick is gone. The required **accent at the volleyball locker corridor** (IMG_0339, 0340, 0372, 0373) is also gone. Over-corrected.

### 21. Bleachers BOTH long sides, RETRACTED

**Live:** `vb_bleach_e` `[-86,-232]` rot 90 length 60 rows 8; `vb_bleach_w` `[-186,-232]` rot 270. Gym polygon is **115 ft E–W × 93.5 ft N–S**. Long sides are **north `z=-279.5` and south `z=-186`**. These pivots sit on the **east and west (short) walls**. `BleacherBank.luau` defaults `extended=false` (closed). Retracted: **yes**. Long sides: **no**.

### 22. Dumpsters west of volleyball gym / service yard

**Live `service_yard`:** `x=-236.5..-193.5, z=-214..-186` (immediately west of the gym’s south edge). Dumpsters `(-220,-200)` and `(-210,-200)`. Door `l1_w146` label `SERVICE` at `(-215,-214)`. **Match.**

---

## Gemini layout problems 1–9 vs current JSON

| # | Original defect | Current JSON | Status |
| --- | --- | --- | --- |
| 1 | `main_b` to `x=-102.7`, 24 ft gap to L2 door at `x=-78.5` | Flights in the entry bay; top at `x=-12.5`; L2 opening on that wall | **Fixed** |
| 2 | Entrance door center `x=-41` into vestibule | Door center `(0,0)` span `x=-6..6` on `l1_w096` | **Fixed** |
| 3 | Racquetball north of gym `z=-319..-279`, inter-court door | South of `corridor_l2` at `z=-80..-60`, 40×20, separate glass doors | **Fixed** |
| 4 | L2 `stair_second` door at `x=-322.5` over +10 landing | Door center `x=-341.5` on `second_bridge` +20 | **Fixed** |
| 5 | `thin_link` 16 ft with 113 ft openings | 9×115 ft; south wall solid; one 8 ft gym opening | **Mostly fixed** (width 9, still a gym opening) |
| 6 | Training 80 ft south of locker | Southbound: training → nutrition → locker → west hall → stair | **Fixed** |
| 7 | >18k sqft overlaps; `cage_lower_reserved` sealed | 0 overlaps; cage lower still 0 doors but `type=construction` so the gate ignores it | **Overlaps fixed; sealed room kept on purpose** |
| 8 | Brick partitions in lobby / L2 gallery | 0 interior brick; cardio open to balcony; **lobby still has `l1_w026`** | **Gallery fixed; L1 lobby partition remains** |
| 9 | 200 ft backtrack from north end of overlook to `corridor_l2` | Overlook still N–S `z=-279.5..-80`; concourse still at south end `z=-92.5..-80`; 10 ft opening `l2_w018` | **Still true.** Architect notes accept the L. User walk “overlook then courts on the left” is a **turn at the south end**, or a backtrack if you walk the full glass. |

---

## Discrepancy catalog

### D1. “Gym doors on the left” do not enter the gym

- **Severity:** critical
- **Owner:** architect
- **Area:** `l1_w031` doors; `gym_foyer`; `competition_gym`; `l1_w002`
- **JSON:** gym east wall `x=-78.5, z=-279.5..-186` has **zero** doors. Pair at `l1_w031` offsets 31/41, centers `z≈-152/-142`, no `connection`, land in `gym_foyer` (`x=-193.5..-78.5, z=-177..-132.5`). Only interior gym opening: `l1_w075` 8 ft at `(-89.5,-186)`.
- **Walkthrough:** hall narrows; trophy right; **first set of doors into the volleyball gym** left.
- **Fix:** Put two leaf doors on `x=-78.5` through the gym east wall (centers roughly `z=-150` and `-160` or the photo stations), `connection: ["corridor_gym_east","competition_gym"]`. Either delete `gym_foyer` or cut it back so it does not swallow those openings. Do not leave a 5118 sqft maple dead-end.

### D2. Lobby partitioned from the left glass hall; desk spans the 20 ft bay east–west

- **Severity:** critical
- **Owner:** architect
- **Area:** `lobby`, `l1_w026`, `reception_desk`
- **JSON:** `l1_w026` `x=-10, z=-16..0`, openings **2 ft** and **5 ft**. Desk `at=[0,-10]`, `rotation=180`, `length=20`, `depth=7.5`, `shape=u` → bar along **X**, front ~`z=-6.8`.
- **Walkthrough / 08:30 / 09:35:** open lobby flowing into the glass hall; desk **in** the room, long axis **perpendicular** to the window, 20–25 ft, ~10 ft inside, GM on the front (U builder already has GM).
- **Fix:** Remove or open `l1_w026` to a ≥12 ft cased opening (or no wall). Rotate the U to **90 or 270** so `length` runs N–S (perpendicular to `z=0`). Keep south end of the enclosure ~10 ft from the glass (`z≈-10` to the public face). Cap `length` at ~20–25 **without** occupying `x=-10` and `x=10` at once. Preserve 3–4 stations, lost & found, ball cart.

### D3. Entry is not a 20×20 clear bay

- **Severity:** major
- **Owner:** architect
- **Area:** `lobby`, `void_lobby`, `stair_main`
- **JSON:** south clear rectangle is **20×16** (`z=0..-16`). Full polygon is an L 22.5×40 bbox (728 sqft) including the stair. Checker passes on bbox.
- **Walkthrough:** open **20×20** with no L2 above.
- **Fix:** Make a rectangular `x=-10..10, z=0..-20` (or `0..-16` plus a documented 4 ft if the stair setback needs it) that is empty of CMU. Keep `void_lobby` over that whole rectangle. Stair may share the room but must not steal the south 20×20.

### D4. Bleachers on the short sides

- **Severity:** major
- **Owner:** architect
- **Area:** `vb_bleach_e`, `vb_bleach_w`, `competition_gym`
- **JSON:** gym `x=-193.5..-78.5` (115), `z=-279.5..-186` (93.5). Bleachers at `x=-86` and `x=-186`, `z=-232`, rot 90/270, length 60, rows 8, `extended` omitted → closed.
- **User 09:40:** both **long** sides, **retracted**.
- **Fix:** Move banks to `z≈-186` (rot 0 or 180) and `z≈-279.5` (opposite), length ~80–100 along the 115 ft walls. Leave `extended` unset/false.

### D5. Public locker fixture handedness

- **Severity:** major
- **Owner:** architect
- **Area:** `public_locker` props
- **JSON:** door `(-97,-20)` facing west. Lockers `(-99,-33.5)` north. Stalls `(-126.5,-28)`. Sinks `(-118,-28)`. Showers `z=-37.5` north wall.
- **User 09:35:** lockers **right**, ~5 stalls **left** with sinks across, showers **straight ahead**.
- **Fix:** Keep lockers on the north wall near the door. Move stalls to the **south** wall (`z≈-18`), sinks facing them, showers to the **west** wall (`x≈-128`).

### D6. Overlook glass is only the north 91.5 ft; south 107 ft is brick

- **Severity:** major
- **Owner:** architect
- **Area:** `l2_w017`, `corridor_l2_overlook`
- **JSON:** curtainwall `z=-278.5..-187` on a brick wall `z=-330..-92.5`. Overlook room starts at `z=-80`.
- **Walkthrough / 23:45 item 1:** walkable L2 hall, **glass on the left into the gym** as you leave the entrance side.
- **Fix:** Either (a) start the overlook room at `z≈-186` so you are not walking 100 ft of brick branded as “overlook,” or (b) glaze `x=-78.5` from `z=-186` through the void over `gym_foyer`/`thin_link` down to `z≈-133` as `ARCHITECT_NOTES.md` already specified (`z=-261..-133.5`). Checker must use opening span, not wall endpoints.

### D7. Squat racks are not on the path to the coaches suite

- **Severity:** major
- **Owner:** architect
- **Area:** `weight_room`, `coach_suite`, `corridor_wide`, `elevator`
- **JSON:** suite glass at `z=-80, x≈-30..-3`. Racks at `(-58,-96)` and `(-48,-96)` inside `weight_room`. Graph path to coaches does not go through `weight_room`.
- **User 01:40 / 09:35:** straight past workout **on the right**, past squat racks, coaches on the right, glass entry.
- **Fix:** Open `weight_room` to `corridor_wide` on the north side of the annex so the northbound right-hand path is annex (machines) → racks → elevator/suite glass. Do not require walking through `elevator` or `coach_west_n` to see a squat rack.

### D8. No interior brick accent at the volleyball locker corridor

- **Severity:** major
- **Owner:** architect
- **Area:** walls around `nutrition_vestibule` / `locker_volleyball` / `athletic_corridor` (`l1_w048`, `l1_w116`, portals)
- **JSON:** 0 interior brick walls. User 08:40: brick **only** where photos show it — locker-corridor accents.
- **Fix:** Paint the locker portal/vestibule jambs `brick` (not the whole corridor, not the lobby). Keep everything else painted_cmu / gypsum.

### D9. Main stair is on the right of the entry, not on the left hallway

- **Severity:** major (authoritative 22:40 vs later “past the desk” — report, do not silently pick)
- **Owner:** architect
- **Area:** `stair_main` `x=2..10, z=-48..-23.5`
- **JSON:** east wall of the 20 ft bay, first flight north along `x=10`.
- **Walkthrough 22:40:** along the **left** hall, stairs on the **left**. 01:40: set back, first flight along the wall, turn left — implemented here.
- **Fix:** Manager/user call. If 22:40 still wins, move the well to the **west** side of the left hall (`south_vestibule` / `corridor_south_link`). Keep two flights, 8×8 landing, left turn, +20, top at a real L2 door. If “past the desk in the 20×20” wins, document that 22:40 is superseded in `WALKTHROUGH.md` so QA stops failing it.

### D10. `thin_link` is 9 ft and has a gym opening

- **Severity:** minor
- **Owner:** architect
- **Area:** `thin_link`, `l1_w075`
- **JSON:** width 9.0 ft; 8 ft opening to `competition_gym` at `x=-93.5..-85.5, z=-186`.
- **Walkthrough:** thinner hall, **no doors**, 8 ft in the notes.
- **Fix:** Set `z=-186..-178` (8 ft). Remove `l1_w075`’s gym opening if D1 puts real gym doors on the public hall.

### D11. Unlabeled 24×25 ft bay west of `fitness_annex`

- **Severity:** major
- **Owner:** architect
- **Area:** `x=-66.5..-42.5, z=-41..-16` bounded by `l1_w039`, `l1_w038`, `l1_w110`, `l1_w136`
- **JSON:** no room polygon covers it. `l1_w110`/`l1_w039` marked exterior brick.
- **User 23:45 item 8:** no pointless spaces.
- **Fix:** Assign it as a room (extension of `corridor_wide` / `fitness_annex`) or delete the walls and merge the floor.

### D12. L2 `stair_west` has no flights; `stair_details.json` disagrees with live `stair_second`

- **Severity:** minor
- **Owner:** architect
- **Area:** `level2.json` `stairs[id=stair_west]`; `blueprint/stair_details.json`
- **JSON:** L2 west stair is polygon + `rise/run/risers` only. `stair_details.json` `second_*` still `x=-320..-339.5` at `z=-111..-105`, dir west/west. Live second stair turns south on `second_b`.
- **Fix:** Copy live L1 flights onto the L2 west stair. Rewrite `stair_details.json` from live `level1.json` (or stop shipping it). `HEIGHTS.md` still says the second stair is a straight run — update it.

### D13. `void_competition` room polygon ≠ `voids[]` entry

- **Severity:** minor
- **Owner:** architect
- **Area:** L2 `void_competition`
- **JSON:** room is L-shaped to `z=-92.5` with a notch at `x=-110`. `voids[]` is a rectangle `z=-279.5..-132.5`.
- **Fix:** One polygon. Builder/void rails should match the room.

### D14. Overlook-to-concourse is still an L / backtrack (Gemini 9)

- **Severity:** minor (accepted in `ARCHITECT_NOTES.md`)
- **Owner:** architect
- **Area:** `corridor_l2_overlook` south end `z=-80`; `corridor_l2`; `l2_w018` 10 ft opening
- **Walkthrough:** after the overlook, racquetball on the left — implies one walk, not 200 ft back from `z=-279.5`.
- **Fix:** If the L stays, put a clear “turn west” at `z=-80` (already the 10 ft opening) and do not extend the overlook room north of the gym unless there is a west exit at the north end. Do not claim a straight concourse.

### D15. Keypad is a `RACDoor` with `keypadCode`, not `keypad_door`

- **Severity:** minor
- **Owner:** architect (builder already reads `keypadCode` in `Walls.luau` for a sign)
- **Area:** `l1_w048` nutrition door
- **JSON:** `tag: RACDoor`, `keypadCode: "15234"`, width 6. `KeypadDoor.luau` exists as a prop kind but is unused.
- **Fix:** Keep code 15234. Prefer `tag`/`kind` that actually instances the keypad hardware, or confirm `Walls.luau` draws a pad from `keypadCode` alone. Width 3.5–4 ft is enough for a single leaf.

### D16. Companion files are stale

- **Severity:** minor
- **Owner:** architect
- **Area:** `architect_constraints.json` (old positive-z custom rooms / `void_lobby` in a different frame); `ARCHITECT_NOTES.md` desk `(-2,-12)` length 12 (live is `(0,-10)` length 20); `architect_layout.json` not re-checked here
- **Fix:** Stop treating constraints/notes coordinates as current. Either regenerate them from `level1.json`/`level2.json` or mark them historical.

---

## Inventories (current JSON)

### Rooms with 0 doors / openings

| Level | Id | Type | Why the gate ignores it |
| --- | --- | --- | --- |
| 1 | `cage_lower_reserved` | construction | not in `NEEDS_ACCESS` |
| 2 | `overlook_mechanical` | mechanical | not in `NEEDS_ACCESS` |

`service_yard` has the SERVICE door to OUTSIDE only (no interior door). `addition` has CONSTRUCTION to OUTSIDE only.

### Interior brick walls

**None.** Exterior brick wall ids:

**L1 (58):** `l1_w003,005,007,008,013,016,020,021,025,027,032,034,036,038,039,040,044,046,047,051,052,054,056,057,058,060,061,062,066,073,074,076,080,081,088,090,096,104,110,111,114,119,121,123,124,125,126,128,129,132,133,134,136,143,144,145,146,147`

**L2 (34):** `l2_w004,007,008,010,011,016,017,022,030,034,036,039,040,041,042,043,044,046,054,056,057,058,062,065,069,073,074,079,081,084,085,086,087,088`

Material counts: L1 gypsum 27 / painted_cmu 63 / brick 58. L2 gypsum 16 / brick 34 / painted_cmu 27 / glass 30.

### Stair flights (live `level1.json`; L2 `stair_main` and `stair_second` match)

| Stair | Flight | Polygon | Dir | Risers | Rise ft | Run ft | Width | Base |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `stair_main` | `main_a` | `x=2..10, z=-40..-25.5` | `[0,-1]` | 17 | 0.5882 | 0.8529 | 8 | 0 |
| `stair_main` | `main_turn` | `x=2..10, z=-48..-40` | — | — | — | — | 8×8 | 10 |
| `stair_main` | `main_b` | `x=-12.5..2, z=-48..-40` | `[-1,0]` | 17 | 0.5882 | 0.8529 | 8 | 10 |
| `stair_second` | `second_a` | `x=-335.5..-321, z=-123..-115` | `[-1,0]` | 17 | 0.5882 | 0.8529 | 8 | 0 |
| `stair_second` | `second_turn` | `x=-343.5..-335.5, z=-123..-115` | — | — | — | — | 8×8 | 10 |
| `stair_second` | `second_b` | `x=-343.5..-335.5, z=-115..-100.5` | `[0,1]` | 17 | 0.5882 | 0.8529 | 8 | 10 |
| `stair_second` | `second_bridge` | `x=-343.5..-335.5, z=-100.5..-92.5` | — | — | — | — | — | 20 |
| `stair_west` | `west_a` | `x=-354..-348, z=-78..-62` | `[0,1]` | 17 | 0.5882 | 0.9412 | 6 | 0 |
| `stair_west` | `west_turn` | `x=-354..-348, z=-62..-54` | — | — | — | — | 6×8 | 10 |
| `stair_west` | `west_b` | `x=-354..-348, z=-54..-38` | `[0,1]` | 17 | 0.5882 | 0.9412 | 6 | 10 |

L2 `stair_west`: no `flights`. All parent totals 34 × 0.5882 = 20.00 ft. Code-legal risers/treads.

### Reception desk prop

```
{"id":"reception_desk","kind":"front_desk","at":[0.0,-10.0],"rotation":180,"room":"lobby","length":20,"depth":7.5,"shape":"u"}
```

GM mark is built in `FrontDesk.luau` `buildU`, not a separate blueprint prop.

### L2 guards (31)

Horizontal rails: `void_rail_1` `[-12.5,-40]→[-12.5,-16]`; `void_rail_2..10` around competition/south/cage voids; `well_rail_1..19` around the three wells; **`cardio_rail` `[-42.5,-16]→[-12.5,-16]`**; **`gallery_rail` `[-64.5,-16]→[-42.5,-16]`**. Plus 3.5 ft glass walls `l2_w014`, `l2_w059`, `l2_w064`, `l2_w089..094` on well edges.

### Voids (`level2.json` `voids` + void-typed rooms)

| Id | `voids[]` polygon | Room polygon if different |
| --- | --- | --- |
| `void_competition` | `x=-193.5..-78.5, z=-279.5..-132.5` | L-shape continues to `z=-92.5` with notch `x=-110` |
| `void_south` | matches `south_gym` including locker notch | same |
| `void_lobby` | glass strip + lobby/stair notch `x=-97..10, z=0..-40` | same |
| `stair_main_opening` | `main_a` | — |
| `stair_main_upper` | `main_b` | — |
| `stair_main_landing` | `main_turn` | — |
| `stair_second_opening` | `second_a` | — |
| `stair_second_upper` | `second_b` | — |
| `stair_second_bridge` | `second_bridge` | — |
| `stair_west_opening` | `west_a` | — |
| `stair_west_upper` | `west_b` | — |

L1 `voids`: `[]`.

### What already matches (do not re-litigate)

South entrance at `(0,0)` on the small glass; L2 at +20; two-flight left-turn main stair in the entry bay with 8×8 landing and 7.06 in / 10.24 in steps; ping-pong and vending in `south_vestibule`; public lockers *located* on the left hall; athletic order training → 15234 → fridge vestibule → locker south door → second stair; elevator 8×8 between squat and head coach; coaches glass + cubicles + `HEAD COACH`; racquetball 40×20 maple/gypsum/glass south of `corridor_l2`; second-stair L2 door on the +20 landing, well north of the hall; basketball L2-only with OFF LIMITS + grade exit; enclosed `stair_west` + exit sign; no L3; no juice; L2 cardio open with rail, six treadmills, bag, two TVs, weights, two benches; dumpsters in `service_yard` west of the gym; 0 room overlaps; 0 dead doors.

---

## Playtest note (out of JSON scope)

`USER-2026-09-29-1025` (nobody can get upstairs, PathfindingService, `CanCollide` on thin treads) is a **builder/nav** issue. Stair JSON rise/run is legal. Do not treat a JSON PASS as a Studio stair PASS.

---

## Suggested architect order

1. Real gym doors on `x=-78.5` into `competition_gym`; kill or shrink `gym_foyer` (D1).
2. Open `l1_w026`; rotate/move the U desk so it is perpendicular and does not wall off the left hall (D2, D3).
3. Bleachers to the long walls, still closed (D4).
4. Public locker fixture layout (D5).
5. Overlook glass span vs room start (D6).
6. Workout → squat → coaches sequence (D7).
7. Brick accents at the locker portal only (D8).
8. User call on stair left-vs-entry (D9).
9. Then the minors (thin_link width, unlabeled bay, stale `stair_details.json` / notes).
