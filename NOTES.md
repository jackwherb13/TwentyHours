# Studio export notes

Read-only export from the open place **Jay test** (placeId `93984353199927`) on 2026-09-28. The Studio place was not modified.

`default.project.json` maps only `ReplicatedStorage.RAC`, `ServerScriptService`, and `StarterPlayer.StarterPlayerScripts`. Each of those services has `$ignoreUnknownInstances: true`, and so does the `RAC` folder, so a later `rojo serve` will not delete Studio instances this project does not own.

`src/StarterPlayer/LocalScript.client.luau` is on disk and is **not** in the project tree.

## Exported scripts

Line counts are `source.split("\n")` on the repo file, which matches Studio's script length (a trailing empty line counts). Repo and Studio matched for every file.

| File | Class | Lines |
| --- | --- | ---: |
| `src/ServerScriptService/CoachVillainServer.server.luau` | Script (Legacy) | 641 |
| `src/ServerScriptService/DoorService.server.luau` | Script (Legacy) | 241 |
| `src/ServerScriptService/LightingController.server.luau` | Script (Legacy) | 154 |
| `src/ServerScriptService/RACBuild.server.luau` | Script (Legacy) | 81 |
| `src/ServerScriptService/RACSystems.server.luau` | Script (Legacy) | 87 |
| `src/StarterPlayer/StarterPlayerScripts/CoachVillainClient.client.luau` | LocalScript | 182 |
| `src/StarterPlayer/StarterPlayerScripts/SprintController.client.luau` | LocalScript | 164 |
| `src/StarterPlayer/LocalScript.client.luau` | LocalScript | 43 |
| `src/ReplicatedStorage/RAC/Modules/RACConfig.luau` | ModuleScript | 44 |
| `src/ReplicatedStorage/RAC/Modules/RACUtil.luau` | ModuleScript | 562 |
| `src/ReplicatedStorage/RAC/Modules/RACArchitecture.luau` | ModuleScript | 568 |
| `src/ReplicatedStorage/RAC/Modules/RACProps.luau` | ModuleScript | 360 |
| `src/ReplicatedStorage/RAC/Modules/BuildAll.luau` | ModuleScript | 55 |

Non-script instances under `ReplicatedStorage.RAC`, written so the tree can be rebuilt:

| File | Instance |
| --- | --- |
| `src/ReplicatedStorage/RAC/init.meta.json` | Folder `RAC` |
| `src/ReplicatedStorage/RAC/Modules/init.meta.json` | Folder `Modules` |
| `src/ReplicatedStorage/RAC/PA.model.json` | RemoteEvent `PA` |

`ReplicatedStorage.RAC` has no other children. `PA` has no attributes and no children.

## LocalScript directly under StarterPlayer

`StarterPlayer.LocalScript` is parented to `StarterPlayer`, not `StarterPlayerScripts`. Its source header calls it `StarterPlayer.StarterPlayerScripts.PAClient` (PA subtitles). **LocalScripts parented directly under StarterPlayer do not run.** It was exported as `src/StarterPlayer/LocalScript.client.luau` and left where it is. It is not mapped in `default.project.json`, so Rojo will not move it.

## Not exported

Skipped on purpose:

| Instance | Class | Lines | Why |
| --- | --- | ---: | --- |
| `Workspace.Script` | Script | 2 | `print("Hello world!")` |
| `Workspace.Jay.Sounds.Folder.Script` | Script | 2 | `print("Hello world!")` |
| `Workspace.RecreationComplex.ProceduralGeneration` | ModuleScript | 447 | Procedural shell generator. Has a child folder `Dependencies`. |
| `...ProceduralGeneration.Dependencies.GeometryPrimitives` | ModuleScript | 2888 | Dependency of the shell generator |
| `...ProceduralGeneration.Dependencies.SmartObject` | ModuleScript | 58 | Dependency of the shell generator |
| `...ProceduralGeneration.Dependencies.ConstructiveSolidGeometry` | ModuleScript | 264 | Dependency of the shell generator |
| `...ProceduralGeneration.Dependencies.MathUtils` | ModuleScript | 185 | Dependency of the shell generator |

Present in the place, not represented in this Rojo project (geometry, audio, and remotes outside `ReplicatedStorage.RAC`):

- `ReplicatedStorage.CoachVillainRemotes` (Folder) with RemoteEvents `ChaseStarted`, `ChaseEnded`, `CatchStarted`
- `SoundService.CoachVillainJumpscareSFX`, `SoundService.CoachVillainChaseMusicTrack`, `SoundService.CoachVillainChaseDrone` (Sound)
- `Workspace.Jay` (character model; see below)
- `Workspace.RecreationComplex` (procedural shell; see below)
- `Workspace.CoachVillainPatrolPoints` (empty Folder)
- `Workspace.Baseplate` (Part), `Workspace.Terrain`, `Workspace.Camera`
- `StarterPlayer.StarterCharacterScripts` (empty), `ServerStorage` (empty), `StarterGui` (empty), `ReplicatedFirst` (empty)

No other `Script`, `LocalScript`, or `ModuleScript` instances were found in the place.

## Workspace

- **Jay** — `Model`, attribute `State = "IDLE"`, `PrimaryPart` is `HumanoidRootPart`. 30 direct children, 60 descendants, **28 BaseParts**. `WorldPivot` position about `(-29.64, 2.24, -29.64)`. Also contains `Sounds/Folder/Script` (the second Hello world script).
- **CoachVillainPatrolPoints** — `Folder`, 0 children.
- **RecreationComplex** — `ProceduralModel` (AI-generated shell, not the RAC blockout). `Size` property `60, 25, 40`. `WorldPivot` position about `(-82.95, 12.50, 99.81)`. 2 direct children (`ProceduralGeneration`, `Generated`), **92 descendants**, about **80 BaseParts** (door, windows, roof, walls under `Generated.RecreationComplex`).
- **workspace.RAC** — **does not exist** in this place. No parts and no bounding box. `BuildAll` / `RACBuild` create `workspace.RAC` when the builder runs; it is not saved in the place right now.
