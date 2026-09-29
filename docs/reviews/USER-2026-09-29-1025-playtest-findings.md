# Playtest findings (manager, from the Studio test run 2026-09-29 10:21) — REQUIRED, same weight as user items

Evidence: verification/navigation/REPORT.md and verification/readiness/REPORT.md ("Studio results 2026-09-29").

1. **Nobody can get upstairs.** PathfindingService: 58/132 key-room pairs pass; EVERY Level 1 → Level 2 path fails (lobby → stair_main_L2,
   racquetball_1, basketball_approach, cage_gym = NoPath). The character_navigation walk got stuck at the main stair, the training room and the
   nutrition vestibule. Likely cause to check FIRST: `Build/Perf.luau` sets CanCollide=false on parts < 0.5 ft — stair treads/landings/thin floor
   slabs may have lost collision. Stairs, landings, floors, ramps and door thresholds must keep CanCollide=true (and CanQuery=true for pathfinding).
   Also check stair riser/tread geometry against Humanoid step height, and add PathfindingModifier/PathfindingLink on stairs if needed.
   Fix until every key-room pair in verification/navigation/REPORT.md passes both ways.
2. **Zone tags are not on the live model** (CollectionService Zone count = 0 in Play). Tags.luau must run in the build that is synced to Studio
   (build.rbxm) and tag the zone parts so they survive serialization (CollectionService tags serialize in rbxm).
3. **LightingController infinite yield on RAC.Lighting**: the lighting build must create workspace.RAC.Lighting (or LightingController must look
   where the fixtures actually are). No console errors or infinite yields allowed.
4. **Performance**: AverageFPS ~41 and memory ~5 GB in Play with 32.5k parts. Find what uses the memory (horizon terrain voxels? textures?
   SurfaceLights?) and bring it down; target ≥ 60 FPS on this laptop and memory well under 2 GB. Measure again and record the numbers.
