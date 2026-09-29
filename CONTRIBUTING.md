# Contributing

For Derek and Jackson (humans) and any coding agent. The RAC is generated from `blueprint/` + builder code. Treat Studio as a viewer and playtester.

## Ownership

Each agent task lists **YOU OWN**. Create or edit only those paths. Never move, rename, or delete another agent's files. Do not `git commit`, `stash`, `checkout`, or rewrite history unless a human explicitly asks.

Humans: keep PRs small and inside one area (blueprint, Build/, Site/, Props/, docs, tools). If two people need Studio, follow the Studio lock below.

## Verify gate

Before claiming done:

```powershell
pwsh -NoProfile -File tools/verify.ps1
```

Everything **you** own must pass. Failures in files you do not own: report them and leave them. Do not "fix" another agent's tree to make the gate green.

CI (`.github/workflows/verify.yml`) runs the same offline steps on push/PR. It never opens Studio and never needs `reference/` media.

Studio checks (MCP): console clean, ≥20 s playtest, photo stations vs `reference/photos/` when your milestone requires it. See `AGENTS.md`.

## Studio lock

- Place: **`places/TwentyHours.rbxl` only**.
- Rebuild with `pwsh tools/build_rac.ps1`. Never hand-edit the RAC model.
- Live sync: `rojo serve preview.project.json --port 34872` so `places/build.rbxm` appears as `Workspace.RAC`.
- One writer at a time on the place file. If the place is locked (`places/TwentyHours.rbxl.lock`), wait.
- Do not publish the place to Roblox.

## Blueprint and code

- Geometry comes from `blueprint/` JSON (schema: `docs/BLUEPRINT_SCHEMA.md`). Walkthrough wins on circulation.
- `--!strict` on new Luau. No `wait()`; use `task.*`. Anchor static parts.
- 1 stud = 1 ft. Origin = south entrance threshold, L1 floor.
- No real people. Villain is **Coach**. Distraction is the **Geak Bar**. Generic locker-room signage only.

## Reviews and QA

User notes in `docs/reviews/USER-*.md` stay required until a later user note supersedes them. Structure QA (`tools/qa-loop.ps1`) re-checks those items every round. Realism judges: both must score ≥ 8.

## Adding GitHub issues

Use labels `structure`, `interior`, `exterior`, `perf`, `gameplay`. One milestone per pipeline phase (Structure QA, Realism interior, Realism exterior, Life, Gameplay). Link the review file in the issue body. Dedupe against open issues first.
