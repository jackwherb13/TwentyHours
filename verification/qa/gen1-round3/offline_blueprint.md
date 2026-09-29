# Round 3 offline blueprint QA

Independent review. Walkthrough (`docs/WALKTHROUGH.md`) is authoritative. No edits to `blueprint/`, `src/`, or the RAC model.

**verify_blueprint.py** (repo root, 2026-09-29): exit 0. **No `FAIL` lines.** Printed:

```
level1: 58 rooms, 147 walls, 100% axis-aligned, 0 overlaps
level1: 57/58 rooms reachable, 0 dead doors
level2: 32 rooms, 85 walls, 100% axis-aligned, 0 overlaps
level2: 32/32 rooms reachable, 0 dead doors
stairs: 3 checked
```

**`verification/qa/round3/blueprint_check.txt`:** same five lines; **no `FAIL`.** The 57/58 figure is `cage_lower_reserved` (type `construction`), which `verify_blueprint.py` does not treat as `NEEDS_ACCESS`.

**`verification/qa/round3/build.txt`:** walkthrough check PASS; building geometry PASS (0 degenerate/doorBlocked/floating/zfight/intersect/gap on 31913 building parts). Full-model QA: **7 doorBlocked**, **10 floating**, all under `RAC.Props`. No line containing `FAIL`. Per the reviewer brief, those are listed below as major because they are explicit QA defects.

---

## Issues

| Sev | Owner | Area | Issue | Evidence | Fix |
| --- | --- | --- | --- | --- | --- |
| **critical** | architect | L2 circulation | Racquetball courts are **not** on the walk from the gym overlook to the second stair / basketball exit. Walkthrough order after the overlook is: courts on the **left**, second stair **down on the right**, then basketball off-limits, then L2 grade exit. In `level2.json`, `racquetball_1/2` sit at **x ≈ −118.5…−78.5, z ≈ −319.5…−279.5** (north of the competition gym, west of the **north** end of `corridor_l2_overlook`). `corridor_l2` is an E–W hall at **z = −92.5…−80** (south end of the overlook). `stair_second` is at **x ≈ −339.5…−305, z ≈ −132.5…−92.5**; `cage_gym` / `basketball_approach` continue west. Walking **west** on `corridor_l2` puts the second stair on the **right** (north) correctly, but the courts are ~190 ft **north**, not on the left of that hall. `walkthrough_routes.json` L2 list is `overlook → corridor_l2 → racquetball_* → stair_second`, which is not a geometric walk. Architect notes already admit a turn is required so both gym and courts stay on the left; the JSON still does not place courts **between** overlook and `stair_second`. | `docs/WALKTHROUGH.md` L2 route + 23:00 racquetball; `level2.json` polygons for `corridor_l2_overlook`, `corridor_l2`, `racquetball_*`, `stair_second`, `cage_gym`; `docs/ARCHITECT_NOTES.md` §Circulation item 7 and “Conflicts” left-hand gym/courts. | Relocate the two 40×20 racquetball rooms onto the **south** side of the westbound L2 hall (left when walking west away from the overlook), immediately **before** `stair_second` on the right. Keep gym glass on the left while walking **north** on the overlook. Do not shrink the competition court (`x = −193.5…−78.5`) to fake a straight line; change the L2 hall / court cluster instead. Update `walkthrough_routes.json` so listed rooms are adjacent. |
| **major** | architect | Main stair treads | Parent stair `rise` 0.588 ft (7.06 in) × 34 = 20 ft, so **risers pass** `verify_blueprint.py` (threshold 7.75 in) and floor-to-floor is 20 ft with a +10 landing. **Flight `run` values do not meet the same script’s 10 in tread rule**, because the checker only reads the parent `run` (0.917 ft ≈ 11.0 in). `main_a` `run` = 0.706 ft ≈ **8.5 in**; `main_b` `run` = 0.588 ft ≈ **7.1 in**. First-flight polygon is only 12 ft along travel (17 × 0.706). Same 17/17 split on `stair_second` and `stair_west` in `stair_details.json`. | `blueprint/level1.json` `stairs[0].flights`; `blueprint/stair_details.json`; `tools/verify_blueprint.py` `check_stairs`; `HEIGHTS.md` 20/34 ft. | Lengthen each flight so **run ≥ 10 in** (prefer ~11 in): ~17 × 0.92 ft ≈ 15.6 ft of going per flight, keep 17+17 risers at 7.06 in, square landing ≥ 8 ft, left turn. Teach `verify_blueprint.py` to test **flight** `run`/`rise`, not only the parent. |
| **major** | architect | Stair vs notes | `ARCHITECT_NOTES.md` says the first flight **runs east** along the hall wall, then the second flight **runs north**. JSON/user 01:40: first flight **north** along the hall/gym wall (`main_a` direction `[0,−1]`, x −86.5…−80.5, z −22…−34), landing, **left (west)** second flight (`main_b` direction `[−1,0]`). JSON matches the walkthrough (“along the wall, left turn”) better than the notes. South edge of `main_a` is **z = −22** (22 ft from glass), notes say **29 ft**. | Walkthrough 01:40; notes §Circulation 2; `level1.json` flights. | Either move the first flight to an eastbound run (then left onto a northbound second flight) **or** rewrite the notes to match JSON. Keep two flights, one landing, left turn, setback from south glass. |
| **major** | architect | Reception / lobby | Desk exists in lobby, **length 22 ft** (in 20–25), **long axis N–S** (`rotation` 270, `longAxis [0,−1]`), perpendicular to **south** glass. `FrontDesk.luau` already builds a **raised** transaction top at 3.6 ft vs clerk at 2.5 ft. Remaining mismatch: walkthrough puts the desk **~10 ft inside** a **~20×20** double-height entry. Prop `at` is **(−6, −21)**; `structural_anchors.json` `centerDistanceToGlass` **21**, `nearEndDistanceToGlass` **10**. The 20×20 lobby box is x −10…10, z 0…−20; the desk center sits in the **west neck** (x −8…−1, z −20…−34). Architect notes lobby north wall **z = −28** and south end of desk **~8 ft** inside; JSON north wall **z = −34**, center 21 ft in. L2 `void_lobby` / cardio edge at **z = −16** is a ~16 ft (not 15 ft) setback. | Walkthrough entrance + 23:47 desk; `level1.json` `lobby` + `reception_desk`; `ARCHITECT_NOTES.md` lobby/`reception_desk`; `structural_anchors.json` `front_desk`. | Enlarge the double-height lobby so a 22 ft N–S desk with raised counter sits **fully in the entry**, public face to the east, **south end ~10 ft** from the south glass (center ~21 ft is OK if the 20×20 grows north). Align notes (8 ft vs 10 ft, z = −28 vs −34, 15 vs 16 ft L2 setback). Blueprint does not need a new `raised` flag if the builder keeps 3.6 ft / 2.5 ft. |
| **major** | exterior / builder | Build QA (props) | `build.txt` full-model QA: **doorBlocked** on `l1_w075` (BleacherBank Skirt/Carriage) and `l1_w111` (WallPad, WaterFountain); **floating** treadmill handrail drops (L1 y=2.72, L2 y=22.72) and ping-pong net clamps / folding rails. Building-only check is clean. No `FAIL` token, but these are the only automated defects in the round-3 build log. | `verification/qa/round3/build.txt` lines 17–36, 49. | Move/cut bleachers, pads, and fountains off door swings; seat treadmill/ping-pong parts on the floor (or exclude decorative subparts from the float test). |
| **minor** | architect | Access / empty | Only sealed occupiable-adjacent room: **`cage_lower_reserved`** (construction, no door/opening) — expected if the cage is L2-only. L1 rooms without props: `stair_main`, `stair_second`, `stair_west`, `addition`, `cage_lower_reserved`. L2: those stairs + **`mechanical_l2`**. No dead doors. `south_gym` is a full gym (140×109, z to **+47** past the entrance line); notes already ask if that wing should stay. Third stair `stair_west` is extra vs walkthrough (notes question). Racquetball **ceiling 16.5** under roof 36.7. | verify 57/58; room types; `HEIGHTS.md`; notes Questions. | Add a door only if L1 cage is meant to be entered; otherwise keep construction sealed. Fit out `mechanical_l2` or mark it explicitly unused. Confirm `south_gym` and `stair_west` with the user. |
| **minor** | architect | Docs vs JSON | `validate_blueprint.luau` still expects **16 ft** floor-to-floor; build is **20 ft** (`level2.json` `elevation`: 20). Overlay OSM still registered at old entrance pixel. `walkthrough_routes.json` “Desk fitness route” jumps `glazed_recreation` → `coach_suite` (rooms exist). | `ARCHITECT_NOTES.md` Conflicts; `HEIGHTS.md`. | Ignore 16 ft schema until its owner changes it; retarget overlay; optional intermediate rooms on the coach route. |

---

## Circulation checklist (walkthrough vs JSON)

| Check | Result |
| --- | --- |
| Main entrance south (small glass, not long east curtain) | **OK** — lobby on z = 0, x −10…10; east wall x = 10 is glazing. |
| Immediately left of door: hall to gym | **OK** — `south_vestibule` west along south glass, then north hall east of stair (`corridor_entry_south` west edge x = −78.5); gym doors on the left when walking north. |
| Main stair: two flights, first along wall, left turn | **OK in JSON** (north then west). **Conflicts with notes** (east then north). Landing at +10. |
| L2 overlook, gym on LEFT walking away from entrance | **OK** — overlook x −78.5…−64.5, gym west of x = −78.5, travel −z (north). |
| Racquetball on left after overlook, then second stair down on right | **FAIL** — courts at north gym; second stair on west E–W hall. |
| Basketball off limits | **OK** — `cage_gym` door label `BASKETBALL — OFF LIMITS`. |
| L2 exit at grade | **OK** — `basketball_approach` `LEVEL 2 EXIT AT GRADE`; `terrain_relationship.json` high threshold (−351.5, 20, −102.5). |
| Reception 20–25 ft, long axis ⊥ entrance window, raised counter | **Mostly OK** — 22 ft, N–S vs south glass, raised in `FrontDesk.luau`; **position** mostly in lobby neck, not the 20×20. |
| Risers ≤ 7.75 in, landings, ~20 ft FTF | **Risers/FTF/landing OK**; **flight treads short**. |

---

## What is not a fail

- Axis-aligned walls, zero room overlaps, zero dead doors, L2 fully reachable.
- Construction `cage_lower_reserved` unreachable from L1.
- Props-only float/block in `build.txt` does not fail the building geometry command.
- 16 ft vs 20 ft in `validate_blueprint.luau` is a known stale check (`HEIGHTS.md`).
