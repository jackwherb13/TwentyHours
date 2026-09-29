# QA round 3 — independent review (TwentyHours.rbxl)

Studio: Roblox MCP **Place1** `a829f151-5bf0-4ef3-b7d0-727e4296c770` = `places/TwentyHours.rbxl` (not Jay test).  
Build log: 24570 parts, geometry QA 0 issues, walkthrough checker PASS, L1 60/61 reachable (`cage_lower_reserved` construction), L2 33/34 (`overlook_mechanical`).  
Play/nav numbers from `verification/navigation/REPORT.md` and `verification/readiness/REPORT.md` (same place, same day). Live Edit re-check: **Zone tags = 0**, **RAC.Lighting missing**, 1030 lights, canopy `TaperedCanopy` 107×1.5×24 at y=31.7, exterior treads y=−4.38…−0.88, 111 tree parts.

This reviewer did not edit `blueprint/`, `src/`, or the RAC model.

---

## A. Route walk (`docs/WALKTHROUGH.md`)

Eye-height / today’s Studio captures under `verification/qa/round3/route/` (round5 stills from this morning on the same place, plus live MCP).

| Step | Should see | Result |
|---|---|---|
| 01 Exterior south glass | Thin dark wedge canopy, wrap glass, wide concrete stair+ramp+rails, pines | **Fail.** Thick soffit, RAC letters on glass, green planter block, lollipop trees, treads below L1. `step01.png` |
| 02 Enter lobby | 20×20 double height, U desk ~20–25 ft ⊥ glass, GM logo, open to glass hall | **Partial.** Open-ish lobby, small 12 ft U, tiny GM plate, brown floor, stair crowding the glass. `step02.png` |
| 03 Left hallway | Wide hall, glass wrap on LEFT, ping-pong + vending, continues to gym | **Pass structure.** Glass left, ping-pong present, hall continues. Vending weak. `step03.png` |
| 04 Main stairs | Set back; flight 1 along wall → square landing → LEFT → L2 | **Fail siting.** Two-flight well exists in lobby but is against the glass; pathfinding cannot climb. `step02.png` |
| 05 Hall narrows | Trophy/jerseys RIGHT, VB gym doors LEFT | Not proven at trophy; gym is reachable by pathfinding on L1. |
| 06 Thin link → athletic hall | Doorless thin hall, then LEFT to training | Thin link in JSON is 8 ft with solid walls (Gemini P5 fixed). **Walk to training FAILS.** |
| 07 Training / nutrition / VB locker | Green tables; keypad 15234; fridge; locker | Training furnished-lite but **not enterable**. Nutrition keypad blocks (expected). Locker walkable. `step11.png` |
| 08 Past locker, second stair up | Connects to L2 basketball door + grade exit | Geometry present; **L1 cannot climb.** L2 door vs landing **z mismatch**. |
| 09 L2 cardio | Open floor, treadmill rows, heavy bag, horizontal rail over lobby | Rail + some machines + TVs. **No bag.** Partition `l2_w064` still in JSON. `step10.png` |
| 10 L2 overlook | Walk away from entrance; **VB gym LEFT through glass** | **Critical fail.** Glass looks into empty CMU + another balcony. `step08.png` `step09.png` |
| 11 Racquetball LEFT | Two 40×20, light wood, white, glass backs | Courts exist on south of `corridor_l2`, wood+glass. **Fountain inside court.** `step12.png` |
| 12 Stair down RIGHT | Opposite travel | Door exists; alignment unsafe (see issues). |
| 13 Basketball OFF LIMITS then L2 exit at grade | Exact signage; door to high ground | Sign is only **BASKETBALL**. Hall is blank CMU. `step13.png` `step14.png` |

Any missing / wrong-side / unwalkable step is **critical**. Overlook content and L1→L2 climb fail that bar.

---

## B. Exterior

Pairs in `verification/qa/round3/pairs/` (`WEB_entrance_1/2`, `WEB_entrance_left_pole`, `IMG_0364/0368/0369`, `WEB_vb_gym_overlook`).

| Topic | Result |
|---|---|
| Entrance stair/ramp | Rails exist; treads **below L1** (y down to −4.38). Not WEB_entrance / IMG_0364–0368 grade. |
| Canopy | 107×24 ft slab at y≈31, not a thin dark wedge. |
| Glass wrap | South+east curtain exists; entrance is on the **south** smaller glass (correction kept). |
| Facade | Brick envelope; interior brick still reads through glass. |
| Roads/roundabout vs lidar | Still low vs building; from L2 cardio the plaza sits in a hole. `site.json` has no lots. |
| Trees | 111 lollipop/sphere stacks. |
| Parking | Not real GMU lots (aisles, stalls, islands, lights, no grass in asphalt). |
| Dumpsters | Two green boxes **inside a CMU room**, not a west service yard. |

---

## C. Building sense

- **Stairs:** Main rise 7.06 in (legal) but unclimbable in Play. `stair_second` L2 door at z=−92.5 vs landing z=−111.
- **Support / rails:** L2 cardio has a horizontal rail. Overlook glass has no gym beyond it (void reads as a second building).
- **Doors:** Graph is connected in JSON; Play doors/props block training, cage, some one-way gym/locker paths.
- **Windows:** Overlook windows do not face the gym.
- **Stray:** Floating gym meshes; fountain in racquetball; indoor dumpsters; green entrance cube.
- **Empty rooms:** Coaches dark; overlook empty; gym dark with junk in the air.
- **Lighting:** Fixtures exist as parts; **no `RAC.Lighting` folder**; infinite yield; gym underexposed.
- **Materials:** Maple close-up is plausible; `racquetball_wood` throws; halls/lobby not porcelain/terrazzo.

---

## User / manager checklist (re-checked)

| Item | Status |
|---|---|
| 23:45 L2 gym overlook walkable + gym LEFT | **Still broken** (hall yes, gym view no) |
| Interior stairs two flights / second stair after RB | JSON yes; **Play cannot climb**; L2 second-stair door offset |
| Exterior stair+ramp | **Still broken** (too low) |
| Roads on lidar | **Still broken** |
| Thin wedge canopy | **Still broken** |
| Stray elements | **Still broken** |
| Trees | **Still broken** |
| Functions as a building | **Still broken** (nav, overlook, training) |
| South smaller glass entrance | **Kept** |
| Desk 20–25 ft U, counter, GM, in entry | **Still broken** (12 ft U) |
| 01:40 stair too close + along wall then left | Too close **still**; direction roughly matches notes |
| Left hall to gym | **Mostly there** |
| L2 cardio rail | **Present**; bag/openness incomplete |
| Coaches + HEAD COACH | Suite shell; **plate/fit-out fail** |
| Lived-in / AT room | **Still thin**; AT not walkable |
| Judges ≥8 | **Fail** |
| Parking real, no grass in lots | **Fail** |
| Mgr materials | Maple partial; apply **errors**; halls grey/brown |
| Grass in building | Not seen in lobby/gym this round |
| Lighting | **Folder missing**; brightness uneven |
| Empty/scattered | **Still** |
| Floating props | Gym blobs + fountain; prior 7 not fully gone |
| 08:30 no L2/L1 brick partitions | Cardio rail open-ish; **brick piers remain**; `l2_w064` remains |
| 08:40 less interior brick | **Still too much brick** |
| Site markings | **Fail** |
| Playtest climb / zones / Lighting yield / FPS | **All still fail** (41 FPS, ~5 GB) |
| 09:35 Linn right / 3rd stair / coaches right / no L3 / RB wood+glass / no juice / elevator / L2 basketball / public lockers / desk / cardio / dumpsters west | Mostly in JSON; **desk, dumpsters, climb, overlook** fail in world |
| 09:40 bleachers both sides retracted | Visible-ish in gym shot; lighting hides them |
| Gemini P1–P3, P5–P7 | **Fixed in JSON** |
| Gemini P4 stair_second | **Still high** (z) |
| Gemini P8 brick/open | **Partial** |

---

## Offline vs live

Do not send the architect back to Gemini’s west stair well or x=−41 entrance door. Those are gone. The live failures are **overlook content**, **climb/tags/lighting folder**, **desk size**, **canopy/grade/trees**, **training blockage**, **stair_second door z**, **interior brick**, **stray props**.

Full machine list: `verification/qa/round3/ISSUES_REVIEW.json`.
