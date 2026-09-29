# Interior brick inventory (2026-09-29)

Builder mapping (`Walls.luau` `interiorFinish`):
- Glass stays glass.
- Interior (`exterior: false`) walls with `material: brick` stay brick (locker-corridor accents only).
- All other interior faces, including the inside of envelope walls, use the adjacent room `wallFinish` (painted_cmu ranks above gypsum). Envelope `material: brick` is unchanged for Facade.

## Blueprint interior brick after this change (keep)

| id | photos | rooms |
|----|--------|--------|
| `l1_w042` | IMG_0339 brick portal / concourse opening | athletic_corridor / corridor_main |
| `l1_w043` | IMG_0340, IMG_0372, IMG_0373 locker-corridor portals | athletic_corridor / locker_volleyball / corridor_locker_west |
| `l1_w117` | IMG_0340 volleyball locker north surround | locker_volleyball / corridor_locker_west |
| `l1_w121` | IMG_0339 / IMG_0372 locker-bank doors on concourse | corridor_main / locker_general_w |

## Previously appearing as interior brick

Every `material: brick` wall in `level1.json` / `level2.json` was `exterior: true` (56 on L1, 33 on L2). `interiorFinish` returned that brick on the interior face. Those interiors now follow `wallFinish` (gyms/corridors/lockers/stairs/support = `painted_cmu`; offices/lobby/fitness = `gypsum`). Exterior skin is out of scope.

No room had `wallFinish: brick`.

Offline `places/build.rbxm` after rebuild: 16 brick `WallSegment`s, all on the four ids above (`l1_w042` 5, `l1_w043` 6, `l1_w117` 1, `l1_w121` 4). Lobby volume: 0 brick segments. Envelope interiors are painted_cmu/gypsum.

Studio `Workspace.RAC` did not pick up the new rbxm during this session (still 121 brick segments, exploded children); Rojo live view was stale/overexposed. Before/after PNGs are window captures plus MCP lobby views.
