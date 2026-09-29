# Play-test / walkthrough evidence

## Studio results 2026-09-29

Studio: **Place1** (`a829f151-5bf0-4ef3-b7d0-727e4296c770`) = `places/TwentyHours.rbxl`. Rebuild `pwsh tools/build_rac.ps1` PASS (24570 parts, 0 geometry issues). Lock `.grok-loop/studio.lock` held as `studio-tests` during the session; deleted at end.

Spawn HumanoidRootPart ≈ (5.0, 3.3, -8.0). Walk used MCP `character_navigation` speed 2.

### Walkthrough waypoints

| Stop | X | Y | Z | result | end HRP |
|---|---:|---:|---:|---|---|
| lobby | -2.6 | 3 | -16.4 | PASS | (-2.0, 3.0, -17.2) |
| south_vestibule | -53.5 | 3 | -8.0 | PASS | (-52.70, 2.97, -7.99) |
| stair_main L1 | -0.2 | 3 | -30.2 | PASS (floor, did not climb) | (0.16, 2.97, -30.86) |
| corridor_entry_south | -72.5 | 3 | -48.0 | PASS | |
| corridor_gym_east | -72.5 | 3 | -160.3 | PASS | |
| competition_gym | -136.0 | 3 | -232.8 | PASS | (-135.38, 2.97, -232.21) |
| thin_link | -136.0 | 3 | -182.0 | PASS | |
| athletic_corridor | -199.5 | 3 | -133.0 | PASS | (-199.43, 2.97, -133.74) |
| training_room | -221.0 | 3 | -165.0 | **FAIL stuck** | stayed (-199.43, 2.97, -133.74) |
| nutrition_vestibule | -210.5 | 3 | -145.0 | **FAIL no route** (keypad lock expected) | from locker (-221.71, 2.97, -128.96) |
| locker_volleyball | -222.5 | 3 | -129.0 | PASS | (-221.71, 2.97, -128.96) |
| L2 balcony | -39.8 | 23 | -48.0 | **FAIL no route** from L1 stair | (0.16, 2.97, -30.86) |
| L2 overlook | -71.5 | 23 | -179.8 | not attempted (blocked by L2 climb) | |
| L2 corridor | -219.0 | 23 | -86.3 | not attempted | |
| racquetball_1 | -285.0 | 23 | -70.0 | not attempted | |
| L2 stair_second | -324.3 | 23 | -112.5 | not attempted | |
| basketball_approach | -347.5 | 23 | -112.5 | not attempted | |

### Stuck / fall points

No falls (Y stayed ~3.0 on L1; Health 100).

1. **training_room** — `character_navigation` “Can not find a route”. Character at **(-199.43, 2.97, -133.74)** athletic_corridor. Capture id `walk_stuck_training_room` (overexposed corridor + brick wall + trash can). **Owner:** architect / doors / props (same isolation as PathfindingService).
2. **nutrition_vestibule** — no route from locker. **(-221.71, 2.97, -128.96)**. Capture `walk_stuck_nutrition`. **Owner:** game-integration keypad lock (code 15234) — expected for players.
3. **stair_main L1 → L2 balcony** — no route to y=23. Character **(0.16, 2.97, -30.86)**. Capture `walk_stuck_stair_main` (lobby desk / glass, not a visible stair flight at that AABB). **Owner:** stairs + PathfindingService cannot climb; waypoint may not sit on treads.

### FPS / memory / draw calls (Play, FrameRateManager)

Workspace descendants: **33972** instances, **32531** BaseParts (RAC play log: 32510 parts). Physics FPS 60. VideoMemoryInMB 27876 (GPU budget, not process RSS).

| Location | HRP | AverageFPS | Batches (draw proxy) | Memory MB (Stats:GetTotalMemoryUsageMb) |
|---|---|---:|---:|---:|
| lobby | (-2.0, 3.0, -17.2) | 41.0 | 177 | 5056 |
| competition_gym | (-135.3, 3.0, -232.2) | 41.0 | 146 | 5055 |
| locker_volleyball | (-221.7, 3.0, -129.0) | 41.0 | 97 | 5057 |

Heartbeats ~0.16 ms. RenderAverage ~16.7 ms. AverageQualityLevel ~17. Draw-call API name is `Batches` on FrameRateManager (177 / 146 / 97).

L2 stats not captured: character could not path the stair.

### Console

- `[NavCheck] missing zone …` for all KEY rooms (Tags).
- `Infinite yield possible on 'Workspace.RAC:WaitForChild("Lighting")'` — LightingController, other agent.
- Assistant dump error on StatsItem.Value — our probe, not game code.

### Offline (prior)

`tools/check_perf.luau` previously PASS. Stair risers 0.588 ft. Doors ≥ 3.5 ft.

## Studio lock

Created `.grok-loop/studio.lock` (`studio-tests`). Deleted at end of task.
