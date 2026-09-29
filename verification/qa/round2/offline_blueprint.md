# Round 2 offline blueprint vs walkthrough

Read-only check of `blueprint/*.json` against `docs/WALKTHROUGH.md` (authoritative), plus `docs/SPEC.md`, `docs/ARCHITECT_NOTES.md`, `docs/reviews/USER-2026-09-28-2345.md`, `docs/reviews/USER-2026-09-29-0140.md`, `verification/exterior/ROOF_HEIGHTS.md`, `verification/qa/round2/build.txt`, `verification/qa/round2/blueprint_check.txt`.

Coordinate convention in the JSON: **+x east, +z south, z = 0 is the south entrance glass, more negative z is north / into the building.** Walking away from the entrance is walking north (decreasing z). Left is west (−x). Units are feet. Level 2 elevation in `site.json` is **+20**.

`verification/qa/round2/blueprint_check.txt` reports 57/58 L1 rooms reachable, 0 dead doors, 32/32 L2 reachable. `build.txt` reports walkthrough check PASS. Those tools do **not** test stair flight direction, door placement vs the 20×20 lobby, or racquetball/stair adjacency. This file does.

`docs/ARCHITECT_NOTES.md` is **stale** in several places versus the live JSON (noted per item). Live `level1.json` / `level2.json` / `stair_details.json` win for “what the blueprint currently is.”

---

## 1. Main stair: two flights, first along wall, square landing, turn LEFT, L2 +20 ft, set back from entrance window

### What the walkthrough requires

Two flights, one small square landing, turn **left**, floor-to-floor **~20 ft**. First flight runs **along the wall** (user 01:40), not toward the glass. Volume **set back** from the entrance window. First flight then second to L2.

### What the JSON has

**L1 room `stair_main`** (`level1.json`): polygon `x = −106.0 … −78.5`, `z = −54.0 … −16.0` (27.5 × 38 ft). South edge of the well is **16 ft** north of the glass at `z = 0`.

**Flights** (same in `level1.json` `stairs[]` and `stair_details.json`):

| Flight | polygon | direction | risers | rise | run | elevations |
| --- | --- | --- | --- | --- | --- | --- |
| `main_a` | `x = −88.5…−80.5` (8 ft), `z = −44.0…−29.8` (14.2 ft) | `(0, −1)` **south, toward the glass** | 17 | 0.588235 ft | 0.8333 ft | 0 → 10 |
| `main_b` | `x = −102.7…−88.5` (14.2 ft), `z = −52.0…−44.0` (8 ft) | `(−1, 0)` **west** | 17 | 0.588235 ft | 0.8333 ft | 10 → 20 |
| landing `main_turn` | `x = −88.5…−80.5`, `z = −52.0…−44.0` | — | — | — | — | 10 |

Landing is **8 × 8 ft** (matches “small square landing”). Total rise **17 × 0.588235 × 2 = 20.00 ft**. Parent `fromLevel`/`toLevel` 1→2.

### Mismatches

1. **First flight faces the window, not “along the wall then left.”** Direction `(0, −1)` is south. User 01:40: the first flight was “starting the other way” and must run along/against the wall, then turn left. Climbing `main_a` walks **toward** `z = 0`. That is the same defect the user already flagged.

2. **Turn is a right turn, not left.** Walk south onto the landing, then `main_b` goes west. South then west is a **right** turn. A left turn from south is east. Architect notes (`ARCHITECT_NOTES.md` item 2) describe a different geometry that *would* be a left turn (first flight **east** along the south wall of the well, second **north**): first flight `z = −28…−36`, `x = −112…−96.5`. **That description is not what is in the JSON.** Live flights contradict both the walkthrough and the architect notes.

3. **Setback is only 16 ft at the well, 29.8 ft at the first tread.** User: move the stair back; architect notes claimed south edge at `z = −28` (28 ft). Live south edge is `z = −16`. First riser at `z = −29.8`. Better than sitting on the glass, still 12 ft closer than the notes.

4. **`level2.json` `stairs[]` for `stair_main` is a stale, conflicting polygon** with **no `flights` / `landings`:**
   - L2 stairs entry: `x = −78.5…−42.5`, `z = −32.0…0.0` (36 × 32 ft **on the entrance glass**).
   - L2 **room** `stair_main` matches L1 (`−106…−78.5`, `−54…−16`).
   - If any builder/path uses the L2 `stairs[]` polygon instead of L1 flights, the stair sits on the window (the 01:40 bug).

5. **Going vs parent `run`.** Parent `run` is **0.917 ft** (~11.0 in). Flight `run` is **0.8333 ft** (exactly 10.0 in). `verify_blueprint.py` checks the parent, not the flights.

### Matches

Two flights, one landing, +20 ft, 8 ft width on `main_a`, 8×8 landing.

---

## 2. Hallway immediately LEFT of the main door connecting to the volleyball gym

### Walkthrough

Enter the wrap-around glass at a **corner** into a **~20 × 20 ft** double-height lobby. Immediately **left** of the main door, a hallway runs all the way and connects to the volleyball/competition gym (wide glass wrap, ping-pong / vending).

### What the JSON has

**Lobby** `lobby`: `x = −10…10`, `z = −36…0` → **20 × 36 ft**, not 20 × 20. Double-height via L2 `void_lobby` over that polygon (and over `south_vestibule`).

**Main exterior door** is **not** in `lobby`. Wall `l1_w094` `a = (−97, 0)`, `b = (10, 0)` (107 ft south wall):

- curtainwall offset 1.5, width 48.5 → glass `x ≈ −95.5…−47`
- **door offset 50, width 12** → leaf **`x = −47…−35`**, center **`(−41.0, 0.0)`**
- curtainwall offset 62, width 43.5 → glass `x ≈ −35…8.5`

That door opens **`OUTSIDE` ↔ `south_vestibule`**, not `lobby`. `south_vestibule` is `x = −97…−10`, `z = −16…0` (87 × 16 ft). Lobby connects to the vestibule by a 12 ft opening at `(−10, −8)` (`l1_w021`).

Ping-pong / vending are in `south_vestibule` (`ping_pong_1` at `(−36, −4)`, `ping_pong_2` at `(−58, −4)`).

**Interior gym path** (excluding the bogus exterior shortcut through `competition_gym`’s north doors):

`south_vestibule` → opening at `(−72.5, −16)` → `corridor_entry_south` (`x = −78.5…−66.5`, `z = −80…−16`, 12 × 64) → `corridor_entry_link` (`z = −132.5…−80`) → `corridor_gym_east` (`z = −188…−132.5`) → 6 ft doors at `(−78.5, −152)` and `(−78.5, −142)` into `gym_foyer` → 113 ft opening on `z = −186` into `competition_gym` (`x = −193.5…−78.5`, `z = −279.5…−186`).

Connectivity exists. Graph also treats `competition_gym` as having **exterior** doors on the north wall `z = −279.5` at `x = −181.5` and `−94.5`, so a naive BFS from lobby to gym walks **outside**.

### Mismatches

1. **The public entrance is 31 ft west of the lobby**, in the vestibule, not in the 20×20 entry the walkthrough starts in. You do not “walk in → 20×20 with the desk.” You walk into `south_vestibule` at `x = −41`.

2. **Immediately left of that door (west, facing north) is more vestibule toward `x = −97` and `south_gym`**, not the gym hall. The gym-connecting hall (`corridor_entry_south` at `x ≈ −72`) is only ~6 ft west of the door center, but it is a **north** opening in the north wall of the vestibule, not a left-hand hallway along the glass.

3. **Lobby is 36 ft deep, not 20.** `z = 0…−36`.

4. **Architect notes** still describe the 20×20 at `x = −10…10`, `z = 0…−20` plus a north neck. Live lobby is `z = 0…−36` with no separate 20×20 cut; `lobby_north` is a disconnected piece at `z = −154.5…−124`, `x = −5…10`.

### Partial match

A continuous interior corridor from the south glass zone to the gym **does** exist (`south_vestibule` → `corridor_entry_*` → `gym_foyer` / `competition_gym`). Ping-pong/vending exist. That is the 01:40 “missing left hallway” item at the room-graph level, but **not** at the door-placement / 20×20-entry level.

---

## 3. L2 hallway with gym overlook on LEFT walking away from the entrance

### Walkthrough

Top of the big stairs → L2 hall with glass on the **left** looking into the volleyball gym, walking **away** from the entrance (north). User 22:40 correction: gym on the left.

### What the JSON has

`main_stair_landing`: `x = −78.5…−64.5`, `z = −80…−40`.

`corridor_l2_overlook`: `x = −78.5…−64.5` (14 ft wide), `z = −330…−80` (250 ft long). West face `x = −78.5`.

`competition_gym` west of that line: `x = −193.5…−78.5`, `z = −279.5…−186`.

Overlook glass: wall `l2_w018` `a = (−78.5, −279.5)`, `b = (−78.5, −92.5)`, curtainwall offset 1, width **185**, head 9.5, mullions 5 ft. Covers the gym + `gym_foyer` void.

Walking north (away from glass): gym is **west = left**. Neighbors of the overlook include `racquetball_2`, `corridor_l2`, `main_stair_landing`.

### Match

Overlook corridor exists, is walkable from `stair_main` → `main_stair_landing` → overlook, glass on the left into the competition gym. This is the 23:45 user item 1 at blueprint level.

### Caveats (not full fails)

- To also put racquetball on the left **and** the second stair on the right in one straight walk, the plan turns west onto `corridor_l2` at `z = −80…−92.5` (`ARCHITECT_NOTES.md` §7–8). That west hall does **not** look into the gym. User’s L2 list is a single sequence; the JSON is an L then a west leg.
- Architect notes still say overlook is `sealed_concrete`; live `corridor_l2_overlook.floorMaterial` is **`terrazzo`**.

---

## 4. Second stair down after racquetball courts on the RIGHT

### Walkthrough

After the overlook: **two racquetball courts on the LEFT**. On the **RIGHT**: second stairs **down**, opposite the direction of travel. Then basketball OFF LIMITS, then L2 exit at grade.

### What the JSON has

**Racquetball** (Level 2 only, 40 × 20, maple, ceiling 16.5):

- `racquetball_2`: `x = −98.5…−78.5`, `z = −319.5…−279.5` (door from overlook, label `RACQUETBALL`)
- `racquetball_1`: `x = −118.5…−98.5`, `z = −319.5…−279.5` (door from court 2)

They sit **north of the gym**, west of the **north end of the overlook** (`z ≈ −280…−320`), **not** on `corridor_l2`.

**`corridor_l2`**: `x = −345.0…−78.5`, `z = −92.5…−80` (266.5 × 12.5), the east–west hall at the **south** end of the overlook.

**`stair_second` L2 room**: `x = −339.5…−305.0`, `z = −132.5…−92.5`. North of `corridor_l2` at the **west** end. Walking **west** on `corridor_l2`, the stair is on the **right** (north). Flights run **west** (`direction (−1, 0)`), so walking **down** is east, back toward the courts’ x-range — “opposite direction” if travel was west.

Graph: `racquetball_2` → `corridor_l2_overlook` → `corridor_l2` → `stair_second` (must reverse ~200 ft south along the overlook, then ~226 ft west). Straight-line gap from court door `(−78.5, ~−300)` to stair `(−320, −105)` is on the order of **230 ft**, not “then the stair.”

Architect notes claim courts at `racquetball_2` `x = −265…−225`, `racquetball_1` `x = −305…−265`, `z = −80…−60`, south of `corridor_l2`, immediately east of `stair_second`. **Live polygons are not that.** Notes are leftover.

### Mismatch

**Racquetball is not on the same hall as `stair_second`.** You cannot walk away from the entrance, pass courts on the left, and immediately have the down-stair on the right. Courts are on the overlook’s north end; the second stair is on the far west of `corridor_l2`. Sequence exists only if you U-turn.

Partial: two 40×20 L2-only courts; stair on the right of the west hall; down-direction opposes westbound travel; `BASKETBALL — OFF LIMITS` on `l2_w071` cage door; `LEVEL 2 EXIT AT GRADE` on `l2_w040` at `(−351.5, −102.5)` `OUTSIDE` ↔ `basketball_approach`.

---

## 5. Stair near volleyball locker to basketball door + L2 exit

### Walkthrough

Past the locker, straight down the hall: stairs up to L2. At the top, **left**: basketball OFF LIMITS door, then Level 2 exit at grade.

### What the JSON has (L1)

`locker_volleyball`: `x = −225.0…−205.5`, `z = −160.0…−140.0` (19.5 × 20).

Door graph: `locker_volleyball` → `nutrition_vestibule` → `athletic_corridor` → `corridor_locker_west` (`x = −305.0…−205.5`, `z = −140.0…−112.0`) → **`stair_second`**.

`stair_second` L1 flights: two 17-riser runs west, mid landing `x = −325…−320`, `z = −111…−105` (5 × 6 ft, **not** square 8×8). Width **6** (main is 8). Rise 0.588235 ft.

L2: `stair_second` neighbors **only** `corridor_l2`. `basketball_approach` is `x = −351.5…−339.5`, `z = −132.5…−92.5`, west of the stair well, but the graph connects approach to `corridor_l2` and `cage_gym`, **not directly to `stair_second`**. Top-out is onto `corridor_l2` at `z = −92.5`; then west into `basketball_approach` (also a `corridor_l2` neighbor).

Cage door: 6 ft, label `BASKETBALL — OFF LIMITS`. Exit door: 6 ft, `LEVEL 2 EXIT AT GRADE`.

### Match (with nits)

This is the walkthrough’s “locker hall stair.” It does connect L1 lockers to L2 basketball + high exit. Not “straight down the hall” in a single axis: locker at `x ≈ −215`, stair at `x ≈ −320` via a west hall at `z ≈ −112…−140`. At the top, basketball is **west**, not strictly “on the left” unless facing north (left = west). If you face west up the stair, basketball is ahead, not left.

`stair_west` (`x = −357.5…−345`, `z = −80…−34`) is a third stair the walkthrough never names (architect question still open).

---

## 6. Reception desk: in entry, 20–25 ft, long axis perpendicular to entrance window, raised counter

### Walkthrough / 23:47 / 23:45 item 9

In the front entry you walk into; ~20–25 ft; long axis **perpendicular** to the entrance glass; raised transaction counter; staff inside; ~10 ft from the glass.

### What the JSON has

`level1.json` prop `reception_desk`:

```
kind: front_desk
at: (−6.0, −21.0)
rotation: 270
room: lobby
length: 22
bays: 5
depth: 6
```

`structural_anchors.json` `front_desk`: same `at`, `rotation` 270, `longAxis (0, −1)` (north–south), `nearEndDistanceToGlass: 10`, `centerDistanceToGlass: 21`, `size [22, 3.6, 6]`.

South end if length 22 is N–S about center `z = −21`: **`z ≈ −10`** (10 ft inside the glass). 22 ft is inside 20–25. Perpendicular to south glass: yes.

### Mismatches

1. **Desk is in `lobby` (`x = −10…10`) but the entrance door is at `x = −41`.** The room you actually walk into is `south_vestibule`. The desk is ~35 ft **east** of the door, not “in the front entry room you walk into.”

2. **No explicit raised-counter field.** Raised top is implied only by `kind: front_desk` + architect notes (frosted bays, white transaction top). JSON does not store counter height.

3. **Lobby width is 20 ft; desk depth 6 at `x = −6`.** Fits, but the 20×20 “bigger entry” the user asked for is still the 20×36 lobby east of the real door.

### Partial match

Size, orientation, and ~10 ft setback from **south glass** match if the entrance were in `lobby`. They do not match the door that is actually drawn.

---

## 7. Coaches office suite past workout equipment

### Walkthrough (01:40)

Straight from the main door, workout equipment on the **right**, then coaches’ suite: interior **glass** entrance, open cubicles, private offices around, nameplate **HEAD COACH**.

### What the JSON has

Fitness on the east bay:

- `glazed_recreation`: `x = −5…10`, `z = −80…−36` (15 × 44)
- `fitness_annex`: `x = −42.5…−10`, `z = −48…−16` (selectorized machines: `annex_chest`, `annex_lat`, `annex_leg`, `annex_cable`)
- `corridor_wide` / `weight_room` further north with racks at the weight room

**`coach_suite`** cubicle core: `x = −28…2`, `z = −112…−80` (30 × 32). Private offices:

| id | polygon |
| --- | --- |
| `coach_head` | `x = −40…−28`, `z = −96…−80` |
| `coach_west` | `x = −40…−28`, `z = −112…−96` |
| `coach_west_n` | `x = −40…−28`, `z = −124…−112` |
| `coach_north` | `x = −28…2`, `z = −124…−112` |
| `coach_east_s` | `x = 2…10`, `z = −96…−80` |
| `coach_east_m` | `x = 2…10`, `z = −112…−96` |
| `coach_east_n` | `x = 2…10`, `z = −124…−112` |

Entrance: **4 ft door** `glazed_recreation` → `coach_suite` at `(−1.5, −80)` (`l1_w102`). A second 3.5 ft door `corridor_wide` → `coach_head` at `(−34.2, −80)`.

Nameplate `head_plate`, `kind: nameplate`, `text: "HEAD COACH"`, `at (−29, −88)`, room `coach_head`. Cubicle props in `coach_suite`.

### Mismatches

1. **Storefront is a 4 ft opaque door, not an interior glass wall + glass door.** No curtainwall/glass opening on the suite south wall in the JSON.

2. **“Straight from the main door”** only works from `lobby`/`glazed_recreation` (north). From the real door at `(−41, 0)` you are west of the annex; the suite is northeast, past `fitness_annex` / `corridor_wide`, not dead ahead.

3. Door into `coach_head` from `corridor_wide` bypasses the suite glass narrative.

### Partial match

Suite exists north of the east workout bay, cubicles + perimeter offices, HEAD COACH plate, on the desk-fitness walkthrough route (`1:lobby` → `1:glazed_recreation` → `1:coach_suite` → `1:coach_head`).

---

## 8. Entrance on SOUTH smaller glass

### Walkthrough (23:20)

Main entrance is **not** the long east curtain wall. It is the **smaller south glass**, which should be **longer** than an earlier drawing. Canopy, wide stairs, 20×20 double-height belong there. East wall remains glazing, not the door.

### What the JSON has

`site.json` origin: “Main entrance SOUTH-facing smaller glass frontage.” Footprint south edge `x = −97…10` at `z = 0` (**107 ft**).

`level1.json` `l1_w094`: that full 107 ft is **curtainwall + 12 ft door** (see §2). Corner wrap: `l1_w020` `x = 10`, `z = −36…0`, curtainwall width 32, head 30.

**East long wall** `site.facade` last segment: `(10, −195.5) → (10, 0)`, **`style: brick`, height 33.5** — **not glass**. Interior `l1_w020` only glasses the south 36 ft of `x = 10`.

**`site.facade` has no south segment at `z = 0`.** Facade jumps from `(−97, 0) → (−97, 47)` (brick, south gym) to later `(10, −195.5) → (10, 0)` (brick). The 107 ft entrance glass exists only on the **room wall** `l1_w094`, not on the site facade list.

No entrance door on `x = 10`. Good vs the 23:20 correction.

### Mismatches

1. South “smaller” glass is **107 ft of curtainwall**, i.e. the entire south public front, not a small bay that was lengthened a bit. Door sits in the **middle-west** of that run (`x = −47…−35`), not in the 20 ft lobby bay (`x = −10…10`).

2. **Site facade vs interior walls disagree:** site draws the east wall as brick; L1 draws south + SE corner as glass. Overlay/exterior passes that read `site.facade` will miss the entrance glass.

3. User: east curtain wall stays glass (not the door). Site still codes the long east wall as brick.

---

## 9. Stair risers ≤ 7.75 in

IBC-style cap used by `verify_blueprint.py`: rise ≤ 0.646 ft (7.75 in), tread ≥ 0.833 ft (10 in).

| Stair | `rise` | inches | `risers` | `n × rise` | parent `run` | flight `run` |
| --- | --- | --- | --- | --- | --- | --- |
| `stair_main` | 0.588235 ft | **7.059 in** | 34 | 20.00 ft | 0.917 ft (11.0 in) | **0.8333 ft (10.0 in)** |
| `stair_second` | 0.588235 ft | **7.059 in** | 34 | 20.00 ft | 0.917 ft | **0.8529 ft (10.24 in)** |
| `stair_west` | 0.588235 ft | **7.059 in** | 34 | 20.00 ft | 0.917 ft | **0.9412 ft (11.29 in)** |

All risers **pass** 7.75 in. 34 × 7.059 in = 20.00 ft matches `site.levels[1].elevation = 20` and the walkthrough “big gap.”

`south_gym` roof lidar ~40 ft and lobby lidar ~25.5 ft (`ROOF_HEIGHTS.md`) still disagree with a 20 ft occupied L2 + ceiling; that is a roof/section issue, not a riser fail. Architect notes already say ignore `validate_blueprint.luau` 16 ft.

### Pass

Risers are legal. Main-stair **flight** treads are exactly 10 in (minimum). Do not treat parent `run` 0.917 as the built going.

---

## 10. Rooms without access, dead doors

`blueprint_check.txt`: L1 **57/58** reachable, **0** dead doors; L2 **32/32**, 0 dead.

Recomputed from wall openings:

**Unreachable occupiable-ish room:** `cage_lower_reserved` (L1, type `construction`, `x = −351.5…` cage undercroft). Not in `NEEDS_ACCESS` for the verifier, so it does not FAIL the script, but it is the 1/58. No door into it from the public graph.

**Dead doors (same space both sides):** none.

**Exterior doors (L1):**

| wall | at | rooms | width | label |
| --- | --- | --- | --- | --- |
| `l1_w094` | (−41.0, 0.0) | OUTSIDE / `south_vestibule` | 12 | (none) |
| `l1_w065` | (−357.5, −72.0) | OUTSIDE / `stair_west` | 4 | |
| `l1_w073` | (−181.5, −279.5), (−94.5, −279.5) | `competition_gym` / OUTSIDE | 6+6 | |
| `l1_w079` | (−221.5, 47.0), (−111.5, 47.0) | OUTSIDE / `south_gym` | 6+6 | |
| `l1_w146` | (−302.0, −301.0) | `addition` / OUTSIDE | 6 | `CONSTRUCTION` |

**L2 exterior:** `l2_w040` (−351.5, −102.5) OUTSIDE / `basketball_approach`, 6 ft, `LEVEL 2 EXIT AT GRADE`.

### Issues that are not “dead doors” but are access problems

1. **`competition_gym` opens to OUTSIDE** on the north wall. That is a second public entrance the walkthrough never describes, and it makes lobby→gym “reachable” via the lawn.

2. **`lobby` is not on `OUTSIDE`.** The building’s named lobby is interior-only. Spawn/walkthrough `LOW_ENTRANCE` → `1:lobby` skips the actual door room unless the route goes `south_vestibule` first (`walkthrough_routes.json` does include vestibule on the long L1 route, but “Desk fitness route” is `lobby` → `glazed_recreation` → coaches and never uses the exterior door).

3. **`stair_second` L2 does not door directly into `basketball_approach`.** Fine if `corridor_l2` is the landing, but it is an extra room in between.

4. **`cage_lower_reserved`:** sealed construction volume under the cage. Flag as no access.

5. **`lobby_north`** is reachable through other east rooms, but it is not a “neck” of the entrance lobby (it sits at `z = −124…−154.5`). Easy to misread as the double-height neck from the notes.

No dead (double-sided) doors in the wall openings.

---

## Cross-cutting JSON contradictions (affect several items)

| Topic | `ARCHITECT_NOTES.md` / `stair_details` evidence text | Live `level1.json` / `level2.json` |
| --- | --- | --- |
| Main first flight | East along south wall, `z = −28…−36`, `x = −112…−96.5`, then north | South `(0,−1)` `z = −29.8…−44`, then west |
| Main well | `x = −112…−78.5`, `z = −52…−28` | `x = −106…−78.5`, `z = −54…−16` |
| Desk | `(−4, −15)`, rot 270, length 20 | `(−6, −21)`, length 22 |
| Racquetball | South of `corridor_l2`, `x = −305…−225`, `z = −80…−60` | North of gym, `x = −118.5…−78.5`, `z = −319.5…−279.5` |
| L2 `stairs[]` `stair_main` | (notes match L1 well) | Polygon on the glass `z = 0…−32`, `x = −78.5…−42.5`, **no flights** |
| Site south glass | Implied | Missing from `site.facade` |

`walkthrough_routes.json` L2 route lists `racquetball_2` then `racquetball_1` then `stair_second` as consecutive rooms; the door graph requires `corridor_l2_overlook` and `corridor_l2` in between. The route file hides that U-turn.

---

## Scoreboard vs the 10 asked items

| # | Item | Verdict |
| --- | --- | --- |
| 1 | Main stair two flights, along wall, square landing, **left**, +20, set back | **FAIL** direction (south, then west = right turn). Landing 8×8 and +20 **OK**. Setback 16 ft well / 30 ft first tread. L2 `stairs[]` polygon still on the glass. |
| 2 | Hall immediately left of main door to VB gym | **FAIL** as drawn: door is in vestibule at `x = −41`, not lobby. **PASS** that a west/north corridor eventually reaches the gym. |
| 3 | L2 overlook, gym on left walking away | **PASS** (`corridor_l2_overlook` at `x = −78.5`, glass 185 ft). |
| 4 | After racquetball, second stair on right | **FAIL** adjacency. Courts on north overlook; stair on west `corridor_l2`. |
| 5 | Locker-side stair to basketball + L2 exit | **PASS** with a west hall (`corridor_locker_west`) and top-out onto `corridor_l2` not directly into `basketball_approach`. |
| 6 | Reception 20–25 ft, perpendicular, raised, in entry | **PARTIAL**: 22 ft, N–S, ~10 ft from glass, in `lobby`. Not in the room the exterior door enters. Raised counter not a field. |
| 7 | Coaches suite past equipment | **PARTIAL**: suite + HEAD COACH exist north of `glazed_recreation`. Entrance is a 4 ft door, not glass storefront. Not straight from the real main door. |
| 8 | Entrance on south smaller glass | **PARTIAL**: door is on `z = 0`, not on east wall. South glass is 107 ft; site facade omits it and bricks the east wall. Door not in the 20×20 lobby bay. |
| 9 | Risers ≤ 7.75 in | **PASS** (7.059 in × 34 = 20 ft). |
| 10 | Rooms without access, dead doors | **PASS** dead doors (0). **Note** `cage_lower_reserved` unreachable; gym has extra exterior doors. |

Highest-priority blueprint fixes if the next round is still layout: (a) rebuild `stair_main` flights to run along the wall and **turn left**, delete the L2 stale `stairs[]` polygon; (b) put the 12 ft entrance in the south face of `lobby` and keep the left-hand vestibule hall to the gym; (c) put racquetball on the L2 hall the user walks, immediately before `stair_second` on the right, or change the walkthrough (user document wins); (d) glass storefront into `coach_suite`; (e) add the south curtain wall to `site.facade` and stop calling the long east wall brick-only if it is glass.
