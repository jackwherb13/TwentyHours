# Navigation / gameplay tags

## Studio PathfindingService

Connected Studio instances were `Place1` and `rac_round4.rbxl`. The lock is **TwentyHours.rbxl only**, so no playtest and no PathfindingService pair matrix was run. Enable `workspace.RAC:SetAttribute("NavCheck", true)` in that place after `pwsh tools/build_rac.ps1`, then play ≥20s and copy `[NavCheck]` lines here.

`NavCheck.server.luau` is off unless that attribute or the script `Enabled` attribute is true.

## Key-room sample points (blueprint AABB centers, hip ~+5 ft)

Used as path endpoints once NavCheck runs. `stair_main` exists on both levels (L2 is the walkthrough “L2 exit / main stair”).

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

Owned: door `PathfindingModifier` PassThrough, stair modifiers, zone volumes, patrol folder, locked nutrition (`Code=15234`) and basketball OFF LIMITS doors. Geometry gaps/z-fights in props/site/court are other agents.

Likely Studio failures (report with coordinates if they appear):

- L1 ↔ L2 pairs that do not use a stair (agent must climb `stair_main` / `stair_second` / `stair_west`).
- `cage_gym` behind the locked basketball door at `basketball_approach` (~(-347.5, 25, -112.5)); PassThrough should still allow AI paths.
- Nutrition vestibule keypad door is off the listed pair set but locked for players.

## verify.ps1 (this agent)

Owned: `stylua`/`selene`/`luau-lsp` on Tags.luau, NavCheck.server.luau, Build.luau (Tags require + apply). `tests/build.spec.luau` PASS.

Ignored (other agents): stylua Site/Heightfield/Scene/HorizonData; building geometry (dumpster/front desk/markings/showers); material template; leftover luau-lsp outside Tags/NavCheck.
