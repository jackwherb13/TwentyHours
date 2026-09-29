# QA round 1 — independent review (TwentyHours.rbxl)

Place: `places/TwentyHours.rbxl` (Studio listed as Place1; Workspace parent is TwentyHours.rbxl). Jay test was not used. No edits to `blueprint/`, `src/`, or the RAC model.

**Verdict: do not ship.** Circulation bones of the walkthrough exist. Almost every user/manager required visual fix is still broken.

Automated: `blueprint_check.txt` has **0 FAIL lines**. `build.txt`: 14714 parts, geometry QA 0 issues, **SiteContext 0**. `verify_blueprint.py` L2 **33/32** reachable.

---

## A. Route walk (`docs/WALKTHROUGH.md`)

Eye-height camera (Play character_navigation reached lobby coords, but Play rendering is not the Edit building — see issues). Captures: `verification/qa/round1/route/`.

| Step | Should see | Seen | File |
| --- | --- | --- | --- |
| 01 Approach south glass | Wrap glass, dark wedge canopy, wide stairs+ramp, trees | Glass wrap yes. Thick grey slab canopy. No wide stairs. Grass in plaza. | `step01.png` |
| 02 Canopy / door | Thin dark cantilever, glass wrapping corner, RAC sign | Grey slab; small white door on brick bay; one-step stoop | `step02.png` |
| 03–04 Enter lobby | 20×20 double height; 20–25 ft desk ~10 ft in, perpendicular, staff well | Double-height void yes. Thin west-side counter, not an enclosure | `step04.png` |
| 05 Left hall | Wide hall left of door, glass wrap, ping-pong/vending, continuous to gym | Hall + ping-pong + vending exist. Grass through floor. Stair on right of westbound view | `step05.png` |
| 06–07 Main stair | Two flights, square landing, turn LEFT, +20 ft, set back from glass | Two flights + left/north second flight. Still in the glass bay. Dim | `step06.png`, `step07.png` (stale buffer on some hashes) |
| 08 L2 overlook | Walk away from entrance; gym **LEFT** through glass | **Yes** — glass on left, court below (grey). Corridor is real and walkable | `step08.png`, `step15.png` |
| 09 Gym floor | Maple, green apron, gold lines, bleachers, banners | Grey empty floor, net, scraps of green pads | `step09.png` |
| 10 Coaches | Straight past workout (right); glass suite; cubicles | Glass storefront yes; empty | `step10.png` |
| 11 Training | Green tables, ice, cabinets, rehab | Tables only | `step11.png` |
| 12–13 Play | Walk the building | HUD “939 parts”; grey outdoor field | `step12_playtest_spawn.png`, `step13_playtest_fp.png` |

**Critical route failures:** exterior stairs missing; canopy wrong; desk wrong; grass blocking the left hall as a real interior; Play mode not the RAC; gym not recognizable.

**Not a miss:** L2 overlook corridor **does exist** (user 23:45 #1 is no longer “hallway does not exist”). Gym is on the left walking north.

---

## B. Exterior

Pairs in `verification/qa/round1/pairs/` via `tools/side_by_side.py`.

| Pair | Result |
| --- | --- |
| `WEB_entrance_1.jpg` | No wide stair/ramp; no trees; canopy slab |
| `WEB_entrance_2.jpg` | Canopy is a thick grey bar, not a thin dark wedge; no RAC blade sign |
| `WEB_entrance_left_pole.jpg` | Same; no pole/trees |
| `IMG_0364.jpg` / `IMG_0368.jpg` | Stairs/ramp/handrails missing |
| `IMG_0344.jpg` | Overlook glass exists; court grey/empty |
| `WEB_vb_gym_interior.jpg` | Not maple |
| `aerial_site.png` | No parking, no roundabout, grass in hardscape, no trees |

Roads: `RAC.Site` = Facade + Roofs only. Lidar terrain exists around the building; lots are not asphalt.

---

## C. Building sense

| Check | Status |
| --- | --- |
| Stairs connect with risers ≤7.75 in | L1 main: 34 risers × 0.588 ft = **7.06 in**, two flights, landing +10. Pass on numbers |
| Upper floors supported | L2 slabs present; gym void under overlook |
| Rails at drops | Cardio south edge has horizontal rails (`step16_cardio_rail.png`) |
| Doors lead somewhere | Blueprint 0 dead doors |
| Windows | South/east glass; gym overlook intentional |
| Floating | Disk QA 0; live props look scattered |
| Rooms without access | 56/56 L1; L2 33/32 count bug |
| Lighting | Fail — 34 lights, black stair |
| Clipping / grass | Fail — terrain through floors |

---

## User / manager re-check (required)

| Item | Still broken? | Sev |
| --- | --- | --- |
| 23:45 #1 L2 gym overlook hall | Hall **exists**; gym left. Court still wrong | critical (materials) |
| 23:45 #2 interior stairs match walkthrough | Topology yes; too close to glass | critical |
| 23:45 #3 exterior stairs | Yes broken | critical |
| 23:45 #4 roads/roundabout low | No roads built | critical |
| 23:45 #5 canopy wedge | Yes broken | critical |
| 23:45 #6 stray elements | Scattered gym/fitness | major |
| 23:45 #7 trees | None | major |
| 23:45 #8 real building | Circulation skeleton only | critical |
| South smaller glass entrance | Kept | — |
| 23:47 reception desk | Yes broken | critical |
| 01:40 #1 stair back + first flight along wall | Flight direction ok; still in glass | critical |
| 01:40 #2 hall left to gym | Partial (dogleg + grass) | major |
| 01:40 #3 L2 cardio rail | **Mostly fixed** visually | minor (JSON risk) |
| 01:40 #4 coaches suite | Glass yes; empty | major |
| 01:40 #5 interiors / gym / AT room | Yes broken | critical |
| 01:40 #6 90% photos | Fail | major |
| 01:40 #7 parking lots | Missing | critical |
| Mgr materials | Grey gym | critical |
| Mgr grass in building | Yes | critical |
| Mgr lighting | Yes | critical |
| Mgr empty/scattered | Yes | major |
| Mgr 7 floating | **Not reproduced** on `places/build.rbxm` | — |

---

## Owners

- **architect:** materials, lighting, desk, stair setback, gym/training/coaches fit-out, grass carve is shared with exterior but interiors are architect’s floor plates.
- **exterior:** stairs/ramp, canopy, roads, parking, trees, terrain under footprint.

Full issue list: `ISSUES_REVIEW.json`. Offline notes: `offline_blueprint.md`, `offline_materials.md`.
