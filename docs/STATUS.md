# 20 Hour Weeks — RAC build status board

Maintained by the manager (Claude). One place to see what's done, what's running, and what's open.
Last updated: 2026-09-29 20:10

## PAUSED (user, 2026-09-29 20:10) - resume when the 3D scan arrives
Nothing is running: all Grok agents, QA/realism loops, the materials loop and Rojo were stopped on purpose.

State at pause:
- `main` = last verified build (verify.ps1 PASSED, 0 geometry issues, 24,883 parts). Both round-1 fixers finished: exterior (door-centred
  stair, tapered canopy, roads/lots on lidar with stall paint, real tree shapes, dumpster yard) and building (maple planks, lighting,
  gym envelope, coaches' glass, public lockers). Neither was re-checked by a QA reviewer (Studio was down).
- Known wrong, top priority: the L1 lobby must be ONE open hall with the desk ~25-30 ft in under the balcony
  (docs/reviews/USER-2026-09-29-1905-lobby-open.md, WALKTHROUGH "Lobby is one open space"). The architect had started this when paused;
  its unverified edits are on branch `wip/lobby-open-2026-09-29` (not merged).
- Materials: every map on disk matches its uploaded asset; judge scores 1-7 (most need another pass). Prompt ready: .grok-loop/agents/materials-fresh.txt.
- Room spec for 27 spaces: docs/ROOM_REFERENCES.md (+70 images in reference/web/rooms/, git-ignored).
- Astra (Codex) usage resets 2026-10-04 19:55.

Resume plan with the scan:
1. Put the scan in reference/scan/ (git-ignored). Align it to the blueprint frame (origin = south entrance threshold, 1 stud = 1 ft,
   +X east, -Z north, L2 = +20 ft) using the entrance door and two building corners.
2. Derive the L1/L2 walls, openings, stair and slab edges from the scan; it replaces the photo/walkthrough estimates for geometry
   (the walkthrough still decides names, signage and the route order). Rebuild blueprint/ from it, starting with the lobby.
3. Add a scan-vs-build deviation check to verify.ps1 (e.g. wall positions within 1 ft) as ground truth for QA.
4. Restart: `pwsh tools/detach.ps1 -Name rojo -Command "rojo serve preview.project.json --port 34872"`, open "20 Hour Weeks" in Studio
   (sign in yourself), then the QA loop (tools/qa-loop.ps1) and the materials loop.

**Restart note:** the pipeline now runs detached (tools/detach.ps1; logs .grok-loop/detached/) so it survives Claude Code sessions ending. Studio: '20 Hour Weeks' (placeId 100200567955206), Rojo on :34872.

Recently done: open L1 lobby + open L2 cardio area (treadmills, heavy bag, rail) - lobby-open job, 08:44

Doc map: [INDEX.md](INDEX.md). How to land changes: [../CONTRIBUTING.md](../CONTRIBUTING.md).

## Pipeline (in order)

| # | Phase | Driver | State |
|---|---|---|---|
| 1 | Structure QA | `tools/qa-loop.ps1` — independent Grok reviewer walks `docs/WALKTHROUGH.md` in Studio + exterior photo pairs + building-sense + verify gate → fixers (architect-grok, exterior-grok) → repeat | **Gen 2, round 2 running** |
| 2 | Realism chains | `tools/realism-loop.ps1`: interior (9 passes, `docs/passes/interior.md`) and exterior (6 passes, `docs/passes/exterior.md`), each pass reviewed + judged (≥ 8) | **Parked until structure QA passes** |
| 3 | Life chain | cars, traffic, Mason shuttle, people (`docs/passes/life.md`) | **Parked until both realism chains finish** |

## Running now

| Agent | Job | Owns |
|---|---|---|
| QA reviewer (Grok) | round 2 review | read-only |
| architect-grok | QA round 2 fixes + Gemini structural review + less interior brick | blueprint/ |
| exterior-grok | QA round 2 exterior fixes (27 items) | Site/ |
| site-markings (Grok) | aerial + street-level references; trace and build lane/stall/crosswalk markings, curbs, islands | Site/Markings/ |
| gemini-layout (Antigravity) | spatial review of plan vs walkthrough → coordinate fixes | docs/reviews/GEMINI_LAYOUT_REVIEW.md |
| material-library (Grok) | one material template from high-quality PBR textures matched to photos; check_materials in verify; judged >= 8 | MaterialService, Materials.luau, art/materials |
| world-extent (Grok) | done: low-detail campus (PV Lot, Angel Cabrera Global Center, EagleBank) + horizon, wired into Site.Builder | Site/Campus, Site/Horizon |
| repo-organizer (Grok) | README, docs index, CONTRIBUTING, GitHub Actions CI, cleanup candidates, GitHub issues/milestones | README, .github/, docs/INDEX |
| roblox-readiness (Grok) | perf post-pass, check_perf gate, walkability, Studio play-test stats | Build/Perf.luau, tools/check_perf.luau |
| game-integration (Grok) | zone/door/spawn tags, patrol points, pathfinding checks across the building | Build/Tags.luau, NavCheck |

## Done (verified, committed)

- Toolchain, Rojo live sync into places/TwentyHours.rbxl, verify gate (lint, types, tests, blueprint logic, geometry, stairs)
- Blueprint from walkthrough + drawings + site plan + lidar: south glass entrance, glass hall with ping-pong to the gym, 2-flight main stair
  (left turn) to L2 at +20 ft, L2 overlook with gym on the left, racquetball, second stair, BASKETBALL — OFF LIMITS, L2 exit at grade,
  reception enclosure, coaches' suite (HEAD COACH), training room, nutrition vestibule (15234, fridge sign)
- 58+ prop modules, textures + MaterialVariants (uploaded), lighting module, research dossier + building primer, campus massing
- Exterior: terrain from lidar, entrance stair/ramp, thin canopy, trees, basic hardscape

## Open issues (tracked by QA every round)

- User reviews: docs/reviews/USER-*.md (all re-checked each round)
- Interior lighting too dark in gym/training/coaches; maple should be brighter/glossier
- Parking lot layout + road/lot markings (site-markings working on it); roads/lots vs floor grade
- Interior brick → painted CMU/gypsum (less-brick)
- Codex/GPT (Astra) unavailable until Oct 4 (usage limit) — Gemini + Grok cover judging/reviews
