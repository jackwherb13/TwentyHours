# 20 Hour Weeks

A Roblox horror game inside a **1:1 recreation of George Mason University's Recreation and Athletic Complex (RAC)** on the Fairfax campus. The building must match the real RAC in size, layout, materials, and circulation. Gameplay stays simple: survive a late-night "20 hour week" while **Coach** (fictional) patrols. The lure item is a **Geak Bar** (food). Never use a real person's name, face, or photo.

Full product bar: [`docs/SPEC.md`](docs/SPEC.md). Doc map: [`docs/INDEX.md`](docs/INDEX.md). How to change things: [`CONTRIBUTING.md`](CONTRIBUTING.md). Live board: [`docs/STATUS.md`](docs/STATUS.md).

## Setup

1. Install [Rokit](https://github.com/rojo-rbx/rokit), then from this repo:

   ```powershell
   rokit install
   ```

   That installs the pinned tools in `rokit.toml`: Rojo 7.7, StyLua, Selene, Lune, luau-lsp.

2. Python 3 with `shapely` and `pillow` (`pip install shapely pillow`). Used by `tools/verify_blueprint.py` and plan overlays.

3. Roblox Studio + the [Rojo plugin](https://rojo.space/docs/v7/getting-started/installation/) (`rojo plugin install`).

4. Open **only** `places/TwentyHours.rbxl`. Connect live sync:

   ```powershell
   rojo serve preview.project.json --port 34872
   ```

   `preview.project.json` maps `places/build.rbxm` into `Workspace.RAC`. After `tools/build_rac.ps1` writes that rbxm, Studio refreshes in a few seconds. Do not import models by hand. Do not place parts one MCP call at a time.

5. Reference photos live under `reference/` (git-ignored). Start with `reference/sheets/*.jpg`, then `thumbs/`, then crop `photos/` (2048px) only when you need a measurement.

## Pipeline

1. **Build** — `pwsh tools/build_rac.ps1` reads `blueprint/` JSON, emits `places/build.rbxm`, runs geometry QA. Never hand-edit the RAC model in Studio.
2. **Verify** — `pwsh tools/verify.ps1` (lint, types, tests, blueprint logic). Studio playtests and photo captures are separate (see `AGENTS.md`).
3. **Structure QA** — `pwsh tools/qa-loop.ps1` walks the building against `docs/WALKTHROUGH.md` until circulation and exterior match.
4. **Realism** — `pwsh tools/realism-loop.ps1` runs interior then exterior passes in `docs/passes/`. Judges score photo pairs; target ≥ 8 from each judge.
5. **Life** — cars, shuttle, people (`docs/passes/life.md`) after both realism chains finish.

## Where things live

| Path | What |
|---|---|
| `blueprint/` | Measured building data (feet). Geometry reads this; do not hard-code layout. |
| `src/ReplicatedStorage/RAC/Build/` | Shell builder (walls, floors, stairs, facade). |
| `src/ReplicatedStorage/RAC/Props/` | Prop modules (`kind` → PascalCase file). |
| `src/ReplicatedStorage/RAC/Site/` | Exterior, terrain, campus, markings. |
| `src/MaterialService/` + `art/materials/` | MaterialVariants and textures. |
| `docs/` | Spec, walkthrough, schema, reviews, status. |
| `tools/` | Build, verify, overlay, judge, agent loops. |
| `verification/` | Packets, screenshots, judge output (pngs git-ignored). |
| `places/TwentyHours.rbxl` | Shared Studio place. `places/build.rbxm` is the generated RAC. |

Units: **1 stud = 1 foot**. Origin = south main-entrance threshold, Level 1 floor. +X east, −Z north.

## Tools (everyday)

```powershell
pwsh -NoProfile -File tools/verify.ps1          # offline gate (must pass before claiming done)
pwsh -NoProfile -File tools/build_rac.ps1       # rebuild RAC → places/build.rbxm
python tools/verify_blueprint.py                # room reachability, overlaps, wall budget
python tools/render_plan.py                     # plan drawing from blueprint JSON
python tools/overlay.py                         # blueprint over site plan / OSM
lune run tools/check_geometry.luau places/build.rbxm blueprint
lune run tests/build.spec.luau
lune run tests/props.spec.luau
stylua --check src
selene src
rojo build default.project.json -o $env:TEMP\twentyhours-verify.rbxl
```

Judge a photo pair (needs APIs; skip in CI):

```powershell
pwsh tools/judge.ps1 -Mode plan -Images <overlays> -Out verification/.../judgement.json
```

CI runs the same offline steps as `verify.ps1` on GitHub Actions. It does **not** open Studio and does **not** use `reference/` media.

## Hard rules (short)

- Code in `src/` syncs via Rojo. Do not edit synced scripts only in Studio.
- Agents own listed paths only. Do not commit, stash, or checkout unless a human asks.
- Do not publish the place. Budget and realism rules are in `docs/SPEC.md` and `AGENTS.md`.
