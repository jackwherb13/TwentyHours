# 20 Hour Weeks — RAC build status board

Maintained by the manager (Claude). One place to see what's done, what's running, and what's open.
Last updated: 2026-09-29 08:45

## Pipeline (in order)
1. Structure QA loop (`tools/qa-loop.ps1`) — independent Grok reviewer walks docs/WALKTHROUGH.md in Studio + exterior photo pairs +
   building-sense + verify gate → fixers (architect-grok, exterior-grok) → repeat. **Gen 2, round 2 running.**
2. Realism chains (`tools/realism-loop.ps1`): interior (9 passes, `docs/passes/interior.md`) and exterior (6 passes, `docs/passes/exterior.md`),
   each pass reviewed + judged (≥ 8) — **parked until structure QA passes/finishes**.
3. Life chain (cars, traffic, Mason shuttle, people; `docs/passes/life.md`) — **parked until both realism chains finish**.

## Running now
| Agent | Job | Owns |
|---|---|---|
| QA reviewer (Grok) | round 2 review | read-only |
| lobby-open (Grok) | open L2 cardio area (no brick partition, treadmills, punching bag, rail); open L1 lobby | blueprint lobby areas |
| less-brick (Grok) | queued after lobby-open: interior brick only where photos show it | wall materials |
| site-markings (Grok) | aerial + street-level references; trace and build lane/stall/crosswalk markings, curbs, islands | Site/Markings/ |
| gemini-layout (Antigravity) | spatial review of plan vs walkthrough → coordinate fixes | docs/reviews/GEMINI_LAYOUT_REVIEW.md |

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
