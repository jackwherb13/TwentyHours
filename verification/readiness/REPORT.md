# Play-test / walkthrough evidence

## Studio lock
Created `.grok-loop/studio.lock` for this agent. Deleted at end of task.

## Place
MCP `list_roblox_studios` returned:
- Place1 (`a829f151-5bf0-4ef3-b7d0-727e4296c770`)
- rac_round4.rbxl (`04633932-b121-4e09-822e-7deed167c4ea`)

`TwentyHours.rbxl` was not connected. Per STUDIO LOCK / shared-place rules, no play, no `character_navigation`, no captures on those other files.

## Offline walkability (substitutes for the character walk)

`tools/check_perf.luau places/build.rbxm blueprint` → **PASS**.

Walkthrough route rooms (docs/WALKTHROUGH.md / blueprint/walkthrough_routes.json) checked via blueprint:

- Stair risers 0.588 ft (17 per flight, 34 total, 20 ft floor-to-floor). Under 0.9 ft. Default Humanoid HipHeight 2 can step them.
- Door openings in level JSON: none under 3 ft (typical 3.5–6 ft).
- No named ramp over 35°.
- No interior 2 ft floor-cell holes in colliding Floor parts.

## Stuck / fall points
Not observed in a live character. Report after `TwentyHours.rbxl` is attached:

Planned waypoints (centroid X, Y eye, Z):

| Stop | X | Y | Z |
|---|---:|---:|---:|
| lobby | -2.6 | 3 | -16.4 |
| south_vestibule | -53.5 | 3 | -8.0 |
| stair_main L1 | -0.2 | 3 | -30.2 |
| corridor_entry_south | -72.5 | 3 | -48.0 |
| corridor_gym_east | -72.5 | 3 | -160.3 |
| competition_gym | -136.0 | 3 | -232.8 |
| thin_link | -136.0 | 3 | -182.0 |
| athletic_corridor | -199.5 | 3 | -133.0 |
| training_room | -221.0 | 3 | -165.0 |
| nutrition_vestibule | -210.5 | 3 | -145.0 |
| locker_volleyball | -222.5 | 3 | -129.0 |
| L2 balcony | -39.8 | 23 | -48.0 |
| L2 overlook | -71.5 | 23 | -179.8 |
| L2 corridor | -219.0 | 23 | -86.3 |
| racquetball_1 | -285.0 | 23 | -70.0 |
| L2 stair_second | -324.3 | 23 | -112.5 |
| basketball_approach | -347.5 | 23 | -112.5 |

## FPS / memory / draw calls
Unavailable without the shared place. Offline part budget is under SPEC.

## Other agents
`tests/build.spec.luau` currently errors in `Tags.apply` (`GetPivot is not a valid member of DoorSingle`) — owned by the Tags agent, not this pass. `Perf.apply` ran successfully before that call on the mini fixture.
