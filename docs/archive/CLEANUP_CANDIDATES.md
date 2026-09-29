# Cleanup candidates

Audit date: 2026-09-29. **Do not delete these files** until a human confirms. Evidence is from repo search (`require` / callers) and `git ls-files`. Generated rbxm/png under gitignore are listed only when still tracked.

## Hand-coded RAC blockout (retired)

`src/ReplicatedStorage/RAC/Modules/` still ships the original layout:

| File | Evidence |
|---|---|
| `RACArchitecture.luau` | No `require` from `src/` outside this folder. `BuildAll.run` warns that the blockout is retired. MILESTONES.md M2 says replace/retire this layout. |
| `RACProps.luau` | Same: only required by itself / Architecture. New props live in `src/ReplicatedStorage/RAC/Props/`. |
| `BuildAll.luau` | Returns existing `workspace.RAC` or warns. `RACBuild.server.luau` no longer calls it (reads `workspace.RAC` from the preview rbxm). |
| `RACUtil.luau` | Callers: `RACArchitecture` and `RACProps` only. |
| `RACConfig.luau` | Callers: Architecture/Props/Util comments. `MASON_BRANDING` is documented in MILESTONES.md M5; the new builder should keep that flag somewhere before this folder is removed. |

Keep until branding/config is copied into the data-driven builder.

## Interim blueprint

| Path | Evidence |
|---|---|
| `blueprint_interim/level1.json`, `level2.json`, `site.json` | Produced by `tools/interim_blueprint.py`. Live builder uses `blueprint/`. Several `tools/site/*.py` still *read* `blueprint_interim/` (`prepare_site.py`, `process_lidar.py`, `prepare_county.py`, `align_roofs.py`, `tools/site/build_preview.luau`). Retire those scripts together with this folder, or retarget them at `blueprint/`. |

## One-shot / superseded scripts

| Path | Evidence |
|---|---|
| `tools/interim_blueprint.py` | Writes only `blueprint_interim/`. |
| `tools/build_blueprint.py` | Early blueprint generator; current source of truth is `blueprint/` plus architect tools. Confirm no agent task still calls it. |
| `tools/preview_massing.luau` | Massing preview; live path is `build_rac.luau` → `places/build.rbxm`. |
| `tools/site/.vendor/` | Vendored numpy/scipy/shapely/laspy (thousands of files, `git ls-files`). CI installs shapely/pillow from pip. Huge; likely accidental commit. |

## Tracked generated / preview artifacts

`.gitignore` already ignores `places/*.rbxm` and `verification/**/*.png`. These are still tracked:

| Path | Evidence |
|---|---|
| `verification/M1/build.rbxm` | Generated M1 preview; not required by `verify.ps1`. |
| `verification/M1/baseline/*.json` | Snapshot of an old blueprint; useful as history, not loaded by the builder. |
| `tests/fixtures/build_geometry.rbxm`, `tests/fixtures/build.log` | Fixture leftovers; tests load `tests/fixtures/mini/` and generated luau. Confirm before dropping. |

`places/build.rbxm`, `build_preview.rbxm`, `massing_preview.rbxm`, `props_preview.rbxm` are git-ignored local outputs of the build/preview tools.

## NOTES.md

Root `NOTES.md` describes the old `workspace.RAC` / `BuildAll` world. Superseded by README + STATUS. Safe to archive once humans agree.
