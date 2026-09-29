# lobby-open (2026-09-29)

Level 2 gallery is an open cardio floor (no full-height brick partition on the east edge). Level 1 lobby opens into the glass hall and fitness annex; reception desk remains in the lobby.

## Files
- `blueprint/level1.json` — lobby polygon, partition openings
- `blueprint/level2.json` — glass rail, openings, treadmills, heavy bag, `gallery_rail_e`
- `src/ReplicatedStorage/RAC/Props/HeavyBag.luau` — Kit prop `heavy_bag`

## Tests
- `python tools/verify_blueprint.py` — exit 0, 0 FAIL
- `pwsh tools/build_rac.ps1` — 0 geometry issues
- `tests/props.spec.luau` — HeavyBag ok, 0 failures
- `pwsh tools/verify.ps1` — FAIL on other agents' files (stylua Build.luau/Scene.luau, selene Court.luau, blueprint schema trophy_main + L2 stair voids, luau-lsp Markings/Court). Owned files pass.

## Screenshots
- `verification/specialists/lobby-open/l1-lobby.png`
- `verification/specialists/lobby-open/l2-cardio.png`
