# Round 1 offline code QA

Independent, read-only. No edits to `blueprint/`, `src/`, or the RAC model.

**Sources:** current `src/` + `places/build.rbxm` (Walkthrough PASS, 24960 parts, geometry 0 issues in `verification/qa/round1/build.txt`) + Studio play reports from 2026-09-29 10:21 (`verification/navigation/REPORT.md`, `verification/readiness/REPORT.md`, `verification/readiness/STATS.md`) + manager notes (`docs/reviews/USER-2026-09-29-0230-manager-findings.md`, `docs/reviews/USER-2026-09-29-1025-playtest-findings.md`).

**Important:** the Lune walkthrough/geometry PASS is not a playtest. 10:21 Play still had every L1→L2 path fail, `Zone=0`, Lighting infinite yield, FPS ~41, memory ~5 GB. Several of those are still in the current code; a few manager hypotheses are **not** true of this rbxm.

Grep (requested): `CanCollide = false` (22 in src), `WaitForChild("Lighting")` (1: LightingController), `CollectionService` (Tags, Lighting, NavBootstrap, NavCheck, DoorService, RACSystems, RACUtil, RACProps), `PathfindingModifier` (Tags.luau only).

---

## 1. MATERIALS

### 1.1 Maple gym floor reads grey-white (manager)

| | |
|---|---|
| **Severity** | critical |
| **Owner** | materials |
| **Area** | competition gym floor / `RAC_maple` |

**What the builder does (assignment is real).** `Floors.luau` writes `room.floorMaterial` onto each slab via `Parts.box` → `Materials.apply`. `competition_gym` is `"maple"` (`blueprint/level1.json` line 27). Current rbxm:

- `RAC.Levels.1.Floors.competition_gym.Slab`: `Material=WoodPlanks`, `MaterialVariant=RAC_maple`, `RACMaterial=maple`, `Color≈(220,196,164)`, `Reflectance=0.38`, `CanCollide=true`, size `115 × 0.5 × 93.5`.
- All 119 floor slabs have a non-empty `MaterialVariant`.
- Counts: maple 7, terrazzo 21, painted_cmu 296, gypsum 180, rubber 12, carpet_tile 27, brick 41 (mostly facade).

`Materials.apply` (`src/ReplicatedStorage/RAC/Materials.luau` 418–442) sets base, color, attributes, then `part.MaterialVariant = "RAC_" .. key`. Variants also live in `src/MaterialService/RAC_*.model.json` (Rojo → MaterialService). `RACBuild.server.luau` 89–92 calls `Materials.install()` inside `pcall` because “MaterialVariant writes need plugin capability.”

**Why it still looks wrong.** The committed albedo `art/materials/pbr/maple_color.png` is nearly white / bleached blonde, not gym maple. Tinted by `(220,196,164)` and `Reflectance=0.38` it reads grey-white under Future lighting. `studsPerTile=8` (MATERIALS.md asked for 4). Court paint sits 0.02–0.05 ft above the slab (`Court.luau` 25–26, 121–122): Mason-green apron + gold lines + 5×7 glyph logo, all `SmoothPlastic` / `RAC_court_*_paint`, `CanCollide=false`. In-bounds wood is mostly covered; leftover maple is the washed albedo.

`verification/qa/round1/materials/gym_maple_close.png` shows a **square grey grid** in the foreground plus mint/gold court. That grid is not the plank colormap (stale capture and/or variant not bound in that session). Either way the live maple does not read as glossy hardwood.

**Fix:** Replace `maple_color.png` with a warm, contrasty maple; drop reflectance to ~0.08–0.15; `studsPerTile` 4; keep apron/lines as thin overlays, not a fill. Re-apply in Play (not only Edit `install()`). Close-up at 3 ft must show grain.

### 1.2 Other keyed finishes are assigned

| key | applied? | notes |
|---|---|---|
| terrazzo | yes (21) | corridors |
| painted_cmu | yes (296) | default interior remap of brick |
| gypsum | yes (180) | lobby / offices / entry gypsum override |
| rubber | yes (12) | fitness / cardio slabs |
| carpet_tile | yes (27) | offices |
| porcelain / ceramic_floor_tile | via Floors locker/restroom remap | `Floors.luau` 22–26 |

Not a “materials never applied” bug. Visual miss is albedo + lighting + court overlay, not a missing `Materials.apply` call.

---

## 2. LIGHTING

### 2.1 `workspace.RAC.Lighting` exists now; WaitForChild is still unsafe

| | |
|---|---|
| **Severity** | major (was critical at 10:21) |
| **Owner** | lighting / game-integration |
| **Area** | LightingController infinite yield |

**Builder:** `Build.luau` 175 calls `Lighting.build(model, data)`. `Lighting.luau` 142–171 does `Geometry.folder(model, "Lighting")` (direct child of RAC), writes `MasterMode`, per-room folders, housing Parts + `SpotLight` named `Lamp`. Current rbxm: `RAC.Lighting` Folder, 94 children, `MasterMode="normal"`, 334 SpotLights. `build.txt`: Lighting 334 parts.

**Controller:** `src/ServerScriptService/LightingController.server.luau` 18–19:

```lua
local rac = workspace:WaitForChild("RAC")
local lightingFolder = rac:WaitForChild("Lighting")  -- no timeout
```

10:21 console: `Infinite yield possible on 'Workspace.RAC:WaitForChild("Lighting")'`. That build was 24570 parts; this one is 24960 and **does** contain Lighting. The yield still happens if RAC is present without that child for ≥5 s (Rojo swap, old model, script order).

**Fallback:** `NavBootstrap.server.luau` 8–17 creates an **empty** Lighting + MasterMode if missing. That unblocks WaitForChild but does not restore fixtures. `Lights.luau` is a legacy per-level grid and returns immediately if `RAC.Lighting` already has >1 children (67–77).

**Fix:** `WaitForChild("Lighting", 10)` and warn; keep NavBootstrap. Do not treat an empty fallback folder as success. Confirm Play console is clean on the current rbxm.

### 2.2 Fixture brightness / Future

| | |
|---|---|
| **Severity** | critical |
| **Owner** | lighting |
| **Area** | interior Future lighting |

`Lighting.luau` TUNE (22–27): high_bay `brightness=6, range=48, angle=100`; troffer 2x4 `1.4/24`; 2x2 `1.1/18`; downlight `0.9/16`. All `Shadows=false`. Gym fixtures at `floorY+22` (`Lighting.luau` 116–117), cap 16, spacing 28. rbxm: 16 gym spots, brightness 6, parent Y=22, tagged `NormalLight`.

`RACBuild.server.luau` 7–19: `Technology=Future` (pcall), ClockTime 14, Brightness 1.0, EnvironmentDiffuse 0.22, ExposureCompensation −0.35, Ambient (52,52,54). That combination leaves a 32.5 ft gym and interior rooms dark (readiness step07/step10) while the glass lobby blows out.

check_perf: 396 lights, 0 with shadows. PointLight 22 + SurfaceLight 40 are mostly prop glints (`Treadmill` screen, etc.), not room lighting.

**Fix:** Future-tuned intensities (high-bays well above 6, or SurfaceLights on the housing facing down). Raise interior ambient or per-zone fill. Do not clip the lobby. Daytime interiors must read maple / tables at eye height.

---

## 3. TERRAIN

### 3.1 Carve exists; grass decoration is never disabled; Studio still hit Terrain at y=0

| | |
|---|---|
| **Severity** | critical |
| **Owner** | terrain |
| **Area** | voxels / grass under footprint |

`Site/Terrain.luau` 128 calls `Carve.apply` after WriteVoxels. `RACBuild.server.luau` 41–53 runs the same carve at Play/Edit. `Carve.luau` FillBlock Air on rooms/walls/footprint, then WriteVoxels occupancy 0 on a 4-stud grid (−4..44 Y). `CarveData.luau` footprint matches the RAC outline (gym, lobby `(10,0)`, west to −357.5). `check_footprint_air.luau` only asserts Lune mock FillBlock counts — it never reads Studio Terrain.

10:21 / round1 ISSUES: raycasts inside the building hit `Workspace.Terrain` at y=0; `hall-north_manager.png` grass tufts in a corridor. No script sets grass decoration off (`Decorate` / `GrassLength` grep is empty except Banner copy). 4-stud voxels plus Grass blades from neighbor cells will poke through 0.5 ft slabs.

Site Builder subtracts LotSlab/PavementSlab from floor plates (`Builder.luau` 84+; build.txt “Site ground kept off the floor plates: 87”). That is **parts**, not Terrain.

**Fix:** After carve, `Carve.audit` in Studio must be 0 fails. Widen the wipe margin. Disable grass decoration on indoor/under-slab Grass. Re-raycast a grid; zero Terrain hits above y=−1 in rooms.

---

## 4. STAIRS

### 4.1 Perf does **not** kill treads/landings (manager hypothesis rejected)

| | |
|---|---|
| **Severity** | info (not a bug in current rbxm) |
| **Owner** | perf |
| **Area** | `Perf.luau` tiny CanCollide |

`Perf.luau` 200–216: `tiny = minAxis < 0.5`; `CanCollide=false` only if `(trim or tiny) and not structural and not furniture`. `isStructural` is true for `.stairs.` and names `tread`/`riser`/`landing` (152–171). Tread size Y=0.12 **is** tiny, but path is `RAC.Levels.1.Stairs.…`.

rbxm: **102/102 treads CanCollide=true**; landings `main_turn` / `second_turn` / `west_turn` size Y=0.4, CanCollide=true. Floors.THICKNESS=0.5 is not `< 0.5`, so slabs stay solid.

Do **not** chase this as the L1→L2 failure.

### 4.2 Rise 0.588 ft is walkable for a Humanoid; PathfindingService still cannot climb it

| | |
|---|---|
| **Severity** | critical |
| **Owner** | stairs / tags |
| **Area** | L1→L2 (every 10:21 pair failed) |

Blueprint: `rise=0.588235`, `run=0.8529`, `width=8`, 17+17, landing at elev 10 (`level1.json` 5296–5384). rbxm `main_a`: 17 treads, width 8, run 0.853, rise 0.588, first Y=0.528. Default Humanoid HipHeight ~2 can step 0.588 ft. `check_perf` MAX_STEP=1.5, MAX_RISER=0.9 — **PASS**.

PathfindingService does not walk 0.12 ft treads as a ramp. Tags therefore emit `PathfindingModifier` (PassThrough, Label=`Stairs`) and a `PathfindingLink` (`Tags.luau` 335–346, 452–486). rbxm has 5 PathfindingLinks + 111 PathfindingModifiers.

**Bugs in the links/modifiers:**

1. Stair groups are **Folders** (`Geometry.folder`, `Geometry.luau` 95–99). Roblox PathfindingModifier must be parented to a **BasePart or Model**. A modifier on `stair_main` (Folder) does not apply to descendant treads.
2. `LandingRail_*` contains the substring `"landing"`, so it is treated as walkable (`Tags.luau` 429–437). `stair_second` StairLink **top** is `LandingRail_2` at `(-335.5, 23, -96.5)`, size `0.12×0.12×8` — a handrail in the air, not a tread. Agents cannot stand there.
3. `stair_main` link is Tread_1 `(6, 0.53, -25.93)` → main_b Tread_17 `(-12.07, 19.94, -44)` (reasonable geometrically) but still on a Folder.
4. 10:21 L2 sample `stair_main_L2 = (-1.2, 25, -28.8)` sits in the stair **well / void_lobby**, not on L2 floor. NavCheck’s own SAMPLE (`NavCheck.server.luau` 22–23) is better (`(6,5,-24.2)` / `(-16,25,-44)`) but still unused when Zone tags were 0.
5. Down L2→L1 often passed (jump/drop, AgentJumpHeight=16). Up never did. Matches broken climb links.

**Fix:** Emit each stair as a Model. Parent PassThrough modifiers to treads (or the Model). Exclude `LandingRail*` from the walkable-name test; pin link attachments to first/last **Tread_*** plus landing slabs named `*_turn`. Place L2 samples on the landing slab, not in the well. Re-run the 132-pair matrix; L1→L2 must pass both ways.

Rail posts/stringers under `.stairs.` also keep CanCollide (width 8 is enough for AgentRadius=2 on the flight itself).

---

## 5. TAGS / ZONES

### 5.1 Current rbxm has Zone tags; 10:21 Play did not see them

| | |
|---|---|
| **Severity** | major (re-test in Play) |
| **Owner** | tags |
| **Area** | CollectionService `Zone` |

`Tags.apply` (`Tags.luau` 221–261) creates `RAC.Zones.<id>` Models, `id`/`level` attributes, `addTag(..., "Zone")` via CollectionService, `Instance:AddTag`, and `RAC_Zone` / `RAC_Tag_Zone` attributes. Volume parts are CanCollide=false, CanQuery=true.

Current rbxm: 95 zone models, 205 instances with GetTags() `Zone`, lobby/stair_main tagged `Zone`+`RACZone`, `id` set. Tags 160 parts in `build.txt`. NavCheck KEY rooms exist as zone ids (`stair_main` is one zone with `level=1` only — L2 is inferred in NavCheck 57–58 from `level==2`, which this model never sets on a second volume).

10:21: `CollectionService:GetTagged("Zone")` count = **0**, `[NavCheck] missing zone …` for every KEY id, pass=0 fail=0. Possible: that build predates tag serialization, or Rojo/Play dropped CollectionService tags.

**Safety net:** `NavBootstrap.server.luau` 28–31 re-tags any descendant with `RAC_Zone==true`. That should make Zone≠0 in Play on **this** rbxm. Re-measure; if still 0, CollectionService is not ingesting rbxm tags and NavBootstrap is not running or not seeing attributes.

`Tags.apply` also sets `rac:SetAttribute("NavCheck", false)` (492), so NavCheck stays off unless a tester flips it.

**Fix:** Confirm GetTagged("Zone") in Play after NavBootstrap. Keep attributes as the source of truth. Add a level-2 volume (or attribute) for `stair_main` so NavCheck’s L1/L2 split works.

---

## 6. COLLISION / PATHFINDING / DOORS

### 6.1 Unlocked leaves are cleared; keypad doors are walk-through; OffLimits stay solid

| | |
|---|---|
| **Severity** | major |
| **Owner** | doors / tags |
| **Area** | door CanCollide vs locks |

`Tags.luau` 301–317: OffLimits leaves keep CanCollide and get PassThrough + `PathfindingLink`; everyone else, including **keypad Locked** doors, gets `CanCollide=false` + `RAC_ClearOpening`. NavBootstrap 47–49 re-clears those.

rbxm: 79 door models, 2 OffLimits (`l2_w078`, `l2_w071` basketball), 194 leaves no-collide, 30 still colliding. Nutrition keypad `15234` on `l1_w048.Opening_2`: Locked true, **cleared 3 / collide 0**. Players and agents walk through without the code. Readiness called nutrition “keypad lock expected”; the geometry does not lock.

**Fix:** Treat keypad/Locked like OffLimits (solid leaves + Door link/PassThrough for AI, prompt for the code). Do not clear Locked openings.

### 6.2 `findDoorAt` misses clustered 3.5 ft doors

| | |
|---|---|
| **Severity** | major |
| **Owner** | tags |
| **Area** | leftover colliding leaves |

`findDoorAt` (`Tags.luau` 201–218) picks the nearest DoorSingle/Double/KeypadDoor within 6 ft using the first descendant part’s CFrame (jamb, not leaf center). Office doors on `l1_w014/015/018/084/086/087` remain fully colliding (3 leaves each). Those block 3.5 ft office/restroom openings for AgentRadius=2.

Training-room door `l1_w048.Opening_1` **was** cleared (not in the colliding set). Isolation of `training_room` is then AgentRadius vs a 4 ft single leaf + frames, and/or furniture in `SOLID_KIND`, not a locked leaf.

**Fix:** Bind each opening to the door parented under that `Opening_*` folder (do not search 6 ft globally). AgentRadius 2 cannot fit 3.5–4 ft singles unless PassThrough on the **Model** is honored (Costs Door=1 is already set in NavCheck).

### 6.3 Bleachers

| | |
|---|---|
| **Severity** | major |
| **Owner** | props |
| **Area** | bleacher clip / pathfinding |

`Build.luau` 155–170 forces CanCollide=true on large `bleacher_bank` parts. `BleacherBank.luau` 166–172 `Carriage` is a solid box `length × stackH × ~3.4`. Playtest: character clips into gym bleachers. Pathfinding treats the box as a wall along the court.

**Fix:** Collide only decks/frames; trim/rails off. CollisionFidelity already Box on meshes (none in this rbxm).

### 6.4 cage_gym / OFF LIMITS

OffLimits doors have DoorLinks (e.g. `l2_w078` at z=−132.5, attachments ±4.5 ft at y=25). 10:21: every cage_gym pair failed. Same Folder/link reliability issue as stairs, plus solid 4 ft leaves and AgentRadius=2.

---

## 7. PROPS

### 7.1 L2 water fountain / treadmill “floating” — not in this rbxm

| | |
|---|---|
| **Severity** | info (stale manager item) |
| **Owner** | props |
| **Area** | floating props |

No `water_fountain` in `blueprint/level2.json`. rbxm: 2 fountains, both L1 (`train_fountain` minY≈0, `vb_fountain` minY≈0). 12 treadmills: L2 cardio_south `l2_tread_1..6` minY=19.94 on elevation 20 (slight embed, not float); L1 fitness minY≈−0.06. `cardio_south` polygon covers z=−16..−48 (`level2.json` 327–347). Pivot is floor (`Build.luau` 83, Kit bottom-center).

Re-count floaters in Studio if any remain; current authored props sit on slabs.

### 7.2 Front desk

| | |
|---|---|
| **Severity** | minor |
| **Owner** | props |
| **Area** | lobby desk |

Blueprint: `shape="u"`, `length=20`, `depth=7.5`, `at=[0,-10]`, rotation 180 (`level1.json` 5648–5657). `FrontDesk.luau` `buildU` (19–154) when `opts.shape=="u"`. rbxm: U (FrontCounter + LeftReturn + RightReturn), bbox X −10.07..10.07 (**20.15 ft**), Z −13.45..−6.20 (south end **6.2 ft** from glass at z=0, not ~10 ft). GM mark is a SurfaceGui TextLabel `"GM"` (`FrontDesk.luau` 92–113), **not** `art/branding/gm_logo.png`.

**Fix:** Shift pivot so the south end is ~10 ft from the glass; use the branding PNG on MarkPlate.

---

## 8. BRICK

| | |
|---|---|
| **Severity** | info (by design, plus two interior accents) |
| **Owner** | architect / walls |
| **Area** | interior brick |

`Walls.luau` 178–257 `interiorFinish`: envelope brick is **not** used on the interior face except `lockerAccent` (`x∈[-250,-190]`, `z∈[-150,-95]`, lines 180–192). Otherwise brick → `painted_cmu`, or room `wallFinish` (gypsum wins in lobby/south_vestibule). Exterior brick is Facade cladding (`Materials.apply` `"brick"`).

rbxm interior wall brick: **2 parts** — `l1_w051` (−239.5, 9.75, −129) and `l1_w044` (−193.5, 9.75, −117.7), locker corridor. Facade: 39 brick cladding panels. Gym interior is painted_cmu, not the red brick in the stale gym close-up.

---

## 9. RAILINGS / GUARDS

| | |
|---|---|
| **Severity** | minor / watch |
| **Owner** | architect / walls |
| **Area** | L2 guards |

No `Guards.luau`. Rails come from:

1. `level2.json` `"guards"` (void_rail_1…, well_rail_*, cardio at z=−16).
2. `Walls.onGuard` + short glass walls (`Walls.luau` 73–94, 143–176, 266–270) → `buildHorizontalRail` (posts, bars, wood cap).
3. `Stairs.luau` flight handrails (74–104, 260–290) and landing-edge rails (171–178).

`l2_w064` is glass, height 3.5, a=−64.5/−16, b=−12.5/−16 — the cardio edge. rbxm: 145 `RailCap`/`RailBar` parts. Guards in JSON do **nothing** unless a matching wall exists (`onGuard` only inspects walls). Keep a wall (even 3.5 ft glass) on every open edge.

---

## 10. PERF

| | |
|---|---|
| **Severity** | critical (memory/FPS) / budgets OK |
| **Owner** | perf / terrain / lighting |
| **Area** | 60 FPS / &lt;2 GB |

`tools/check_perf.luau` on this rbxm: **PASS**.

| bucket | count | budget |
|---|---:|---:|
| whole | 24960 | 40000 |
| shell | 8593 | 12000 |
| props | 10463 | 20000 |
| exterior | 4447 | 6000 |
| campus | 1372 | 6000 |
| horizon | 85 | 1500 |
| lights | 396 (0 shadows) | — |

`Perf.apply` ran (`PerfApplied=true`, collide 4136→3393). Play (10:21): 32531 BaseParts, AverageFPS **41.0** everywhere, `GetTotalMemoryUsageMb` **~5056**, physics 60. Extra instances vs rbxm = Terrain voxels, MaterialService, characters, Studio.

Part budget is not the FPS/memory problem. Likely: lidar WriteVoxels, Future + 334 spots, ~30 PBR maps, SiteContext 5812. `check_perf` does not measure memory.

**Fix:** Measure RSS vs GPU. Thin DEM under the footprint (already supposed to be Air). StreamingEnabled is set Persistent on RAC (`Perf.luau` 258–261) which **prevents** streaming the building. Do not Persistent the whole map. Target ≥60 FPS, memory well under 2 GB, re-record STATS.md.

---

## 11. CoachVillainRemotes WaitForChild

| | |
|---|---|
| **Severity** | minor (current code) / major if leftover folder |
| **Owner** | game-integration |
| **Area** | Coach remotes |

Current:

```lua
-- CoachVillainServer.server.luau 68–74 and CoachVillainClient.client.luau 11–17
local remotes = ReplicatedStorage:FindFirstChild("CoachVillainRemotes")
if remotes == nil then return end
local ChaseStarted = remotes:WaitForChild("ChaseStarted")  -- infinite if folder empty
```

`CoachVillainRemotes` is **not** in `default.project.json` / `preview.project.json`. Missing folder → silent return (Coach AI off, no yield). Empty leftover folder in Team Create → WaitForChild yield (matches older round1 REVIEW.md). 10:21 console cited Lighting, not this.

**Fix:** Author the folder + three remotes under `src/ReplicatedStorage`, or `WaitForChild(..., 5)` and bail.

---

## 12. NavBootstrap / NavCheck

| | |
|---|---|
| **Severity** | major |
| **Owner** | tags / stairs |
| **Area** | play nav |

**NavBootstrap** (`src/ServerScriptService/NavBootstrap.server.luau`): WaitForChild RAC; create empty Lighting; restore `Zone` from `RAC_Zone`; restore light tags from `RAC_Light`; force tread/landing/bridge/turn CanCollide; re-clear `RAC_ClearOpening`; rebuild StairLink if `RAC_StairLink` and no child named StairLink. If Lune already wrote a dummy `StairLink`, bootstrap **skips** (61–62) and will not repair bad attachments (`stair_second` → rail).

**NavCheck** (`NavCheck.server.luau`): off unless `RAC.NavCheck==true` (Tags bakes false). Waits 8 s, then GetTagged("Zone"). 10:21 Zone=0 → pass=0 fail=0 and no path matrix from the script. Manual PathfindingService 58/132. AgentRadius=2, AgentHeight=6, Costs Door=1 Stairs=1 — too fat for 3.5–4 ft singles if PassThrough is ignored.

**Fix:** After Zone restore, run NavCheck on the current rbxm. Repair StairLink even if a broken instance exists. Lower AgentRadius to ~1.2 or guarantee PassThrough on door **Models**.

---

## Manager 10:21 checklist vs current code

| Manager item | Offline verdict |
|---|---|
| Nobody upstairs; Perf killed treads | **Treads still collide.** Climb fails because PathfindingService + Folder modifiers + bad StairLink + L2 sample in the well. |
| Zone=0 | **rbxm has 205 Zone tags + RAC_Zone.** Re-test Play; NavBootstrap should restore if CS drops them. |
| Lighting infinite yield | **Lighting folder is in this rbxm.** WaitForChild still has no timeout. |
| FPS 41 / ~5 GB | **Part budget PASS.** Memory/FPS still fail; Persistent RAC + Terrain + Future. |
| Maple not applied | **Variant is applied; albedo is white; court overlay + reflectance.** |
| Grass indoors | **Carve exists; decoration never disabled; Studio y=0 hits still reported.** |
| 7 floating L2 fountain/treadmill | **Not in current rbxm.** |
| Automated walkthrough PASS | **Offline only.** Not a playtest. |

---

## Grep index (src)

**CanCollide = false:** CoachVillainServer (448, 454), NavBootstrap (48, RAC_ClearOpening), Exterior (158, 305, 315, 322), CountyHardscape (343), Horizon/Builder (15), Site/Terrain plate (126), RACProps hoop (86, 107), Landscape wedge (33), Facade (89), Court paint (26), Lighting housing (67), Tags markers/volumes/leaves (77, 132, 249, 313), Perf tiny/trim (215).

**WaitForChild("Lighting"):** `LightingController.server.luau:19` only.

**CollectionService:** Tags (add Zone/RACDoor/RACStair/RACSpawn), Lighting (NormalLight), NavBootstrap (restore Zone/lights), NavCheck (GetTagged Zone), DoorService (RACDoor), LightingController (NormalLight/EmergencyLight), RACSystems (RACKeyPickup), RACUtil, RACProps.

**PathfindingModifier:** `Tags.luau` 169–185 (create), 179 (name), 329 (door leftover), plus PathfindingLink for OffLimits (116–167) and stairs (452–486).

---

## Suggested fix order

1. Stairs: Model not Folder; StairLink on treads only; exclude LandingRail from walkable names; L2 samples on slabs. Re-path L1↔L2.
2. Maple albedo + reflectance; verify variant in Play.
3. Future fixture brightness; timeout on Lighting WaitForChild.
4. Terrain wipe + no grass decoration; audit y=0.
5. Keypad doors solid; findDoorAt binds Opening folder; AgentRadius.
6. Confirm Zone count in Play after NavBootstrap.
7. Perf: stop Persistent-on-whole-RAC; memory pass &lt;2 GB, FPS ≥60.
8. Desk PNG + 10 ft setback; bleacher collision.

Automated `build.txt` PASS does not close any of 1–7 until a new Studio play matrix matches.
