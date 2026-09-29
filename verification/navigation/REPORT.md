# Navigation / gameplay tags

## Studio results 2026-09-29

Studio: MCP `list_roblox_studios` **Place1** (`a829f151-5bf0-4ef3-b7d0-727e4296c770`), window `places/TwentyHours.rbxl`. Rebuilt with `pwsh tools/build_rac.ps1` (24570 parts, geometry QA 0 issues) then Rojo sync.

### NavCheck script vs PathfindingService

`workspace.RAC:SetAttribute("NavCheck", true)` then play. `NavCheck.server.luau` printed **missing zone** for every KEY id (`lobby` … `stair_main`). `CollectionService:GetTagged("Zone")` count = **0** in Play. Report StringValue stayed `# NavCheck` with **pass=0 fail=0**.

**Likely owner:** Tags / game-integration (`Tags.luau`). Zone volumes are not CollectionService-tagged `Zone` with `id` on the live model, so the stock script never samples rooms.

Attribute turned **false** after stop.

### PathfindingService pair matrix (manual, same agent settings)

Endpoints from the table below (hip ~+5 ft). `CreatePath` AgentRadius=2, AgentHeight=6, AgentCanJump=true, AgentJumpHeight=16, AgentMaxSlope=45, Costs Door=1 Stairs=1.

**pass=58 fail=74** (132 directed pairs).

#### PASS (58)

lobby → competition_gym, south_gym, fitness_center, locker_volleyball, public_locker, stair_main_L1  
competition_gym → lobby, south_gym, fitness_center, locker_volleyball, public_locker, stair_main_L1  
south_gym → public_locker  
fitness_center → lobby, competition_gym, south_gym, locker_volleyball, public_locker, stair_main_L1  
locker_volleyball → lobby, competition_gym, south_gym, fitness_center, public_locker, stair_main_L1  
public_locker → south_gym  
stair_main_L1 → lobby, competition_gym, south_gym, fitness_center, locker_volleyball, public_locker  
stair_main_L2 → lobby, competition_gym, south_gym, fitness_center, training_room, locker_volleyball, public_locker, stair_main_L1, racquetball_1, basketball_approach  
racquetball_1 → lobby, competition_gym, south_gym, fitness_center, training_room, locker_volleyball, public_locker, stair_main_L1, stair_main_L2, basketball_approach  
basketball_approach → lobby, competition_gym, south_gym, fitness_center, public_locker, stair_main_L1

#### FAIL (74) with coordinates and likely owner

**A. No L1 → L2 climb** (`stair_main` / stair modifiers). Paths from L1 rooms to `stair_main_L2`, `racquetball_1`, `basketball_approach`, `cage_gym` are NoPath. Down from L2 to L1 often succeeds.

| pair | from | to | owner |
| --- | --- | --- | --- |
| lobby → stair_main_L2 | (-1.2,5.0,-16.5) | (-1.2,25.0,-28.8) | stairs / Tags PathfindingModifier Stairs |
| lobby → racquetball_1 | (-1.2,5.0,-16.5) | (-285.0,25.0,-70.0) | stairs |
| lobby → basketball_approach | (-1.2,5.0,-16.5) | (-347.5,25.0,-112.5) | stairs |
| lobby → cage_gym | (-1.2,5.0,-16.5) | (-288.2,25.0,-156.2) | stairs + locked Cage door |
| competition_gym → stair_main_L2 / racquetball_1 / basketball_approach / cage_gym | (-136.0,5.0,-232.8) | L2 pts | stairs / Cage door |
| fitness_center → same L2 set | (-35.8,5.0,-139.2) | L2 pts | stairs / Cage door |
| locker_volleyball → same L2 set | (-222.5,5.0,-129.0) | L2 pts | stairs / Cage door |
| stair_main_L1 → stair_main_L2 / racquetball_1 / basketball_approach / cage_gym | (-1.2,5.0,-28.8) | L2 pts | stairs / Cage door |
| south_gym → all L2 | (-166.8,5.0,-7.5) | L2 pts | south_gym isolation + stairs |
| public_locker → all L2 | (-113.5,5.0,-28.0) | L2 pts | locker door one-way + stairs |
| basketball_approach → stair_main_L2 | (-347.5,25.0,-112.5) | (-1.2,25.0,-28.8) | L2 corridor / doors |
| basketball_approach → racquetball_1 | (-347.5,25.0,-112.5) | (-285.0,25.0,-70.0) | L2 corridor / OFF LIMITS door |

**B. `training_room` isolated on L1.** Every path *from* training_room fails. Every L1 path *to* training_room fails. `stair_main_L2 → training_room` and `racquetball_1 → training_room` PASS (drop from L2). Sample: lobby → training_room from=(-1.2,5.0,-16.5) to=(-221.0,5.0,-165.0). **Owner:** architect / doors / props (blocked door or colliding furniture at training room).

**C. `cage_gym` fully isolated.** All 11 directed pairs involving cage_gym FAIL. Sample: basketball_approach → cage_gym from=(-347.5,25.0,-112.5) to=(-288.2,25.0,-156.2); cage_gym → lobby from=(-288.2,25.0,-156.2) to=(-1.2,5.0,-16.5). **Owner:** Tags / doors — basketball OFF LIMITS door needs `PathfindingModifier` PassThrough for AI; geometry may also seal the gym.

**D. One-way L1 doors.** south_gym → lobby / competition_gym / fitness_center / locker / stair_main_L1 FAIL; reverse from those rooms to south_gym PASS. public_locker → lobby / competition_gym / fitness / locker / stair FAIL; reverse often PASS. **Owner:** doors (CanCollide closed leaves, missing Door cost/PassThrough).

**E. south_gym outbound almost empty** except public_locker. from=(-166.8,5.0,-7.5). **Owner:** south gym doors / interior.

### Built-in NavCheck console

```
[NavCheck] missing zone lobby
… (all 11 KEY ids)
[NavCheck] done pass=0 fail=0
Infinite yield possible on 'Workspace.RAC:WaitForChild("Lighting")'  — LightingController (other agent)
```

## Key-room sample points (blueprint AABB centers, hip ~+5 ft)

| room | level | xyz (ft) |
| --- | --- | --- |
| lobby | 1 | (-1.2, 5.0, -16.5) |
| competition_gym | 1 | (-136.0, 5.0, -232.8) |
| south_gym | 1 | (-166.8, 5.0, -7.5) |
| fitness_center | 1 | (-35.8, 5.0, -139.2) |
| training_room | 1 | (-221.0, 5.0, -165.0) |
| locker_volleyball | 1 | (-222.5, 5.0, -129.0) |
| public_locker | 1 | (-113.5, 5.0, -28.0) |
| stair_main | 1 | (-1.2, 5.0, -28.8) |
| stair_main | 2 | (-1.2, 25.0, -28.8) |
| racquetball_1 | 2 | (-285.0, 25.0, -70.0) |
| basketball_approach | 2 | (-347.5, 25.0, -112.5) |
| cage_gym | 2 | (-288.2, 25.0, -156.2) |

## Blockers owned vs not

Owned (this report only): Studio playtest evidence. Code owners of failures: Tags (Zone tags + door PassThrough), stairs, architect/doors for training_room, basketball OFF LIMITS door for cage_gym.

## verify.ps1 (this agent)

Reports-only ownership. Failures in other agents' luau/geometry/materials ignored.
