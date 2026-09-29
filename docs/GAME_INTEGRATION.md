# Gameplay integration (RAC tags, folders, spawns)

The builder (`RAC.Build.Build`) finishes with `Tags.apply`. Gameplay scripts should **not** hard-code wall IDs. Find rooms, doors, and spawns through CollectionService tags and the folders below.

## Folders

| Path | Role |
| --- | --- |
| `workspace.RAC` | Built building. Destroy/rebuild is idempotent. |
| `workspace.RAC.Zones.<roomId>` | Model per room. Attribute `id`, `name`, `type`, `level`. Child `Volume` parts fill the room (invisible, `CanCollide = false`). |
| `workspace.RAC.Lighting` | `MasterMode` StringValue plus one folder per lit room with `Mode`. Used by `LightingController`. |
| `workspace.RAC.Lighting.<roomId>` | Lights parented here; each Light has attribute `Zone = roomId` and tag `NormalLight` or `EmergencyLight`. |
| `workspace.RAC.Spawns` | Alternate `SpawnLocation`s (`GymFoyerSpawn`, `FitnessSpawn`, `CardioSpawn`). `Enabled = false` so they do not steal the default spawn. |
| `workspace.RAC.LobbySpawn` | Default spawn (south lobby, facing north). Tag `RACSpawn`. |
| `workspace.CoachVillainPatrolPoints` | Sibling of `RAC` (same parent). `BasePart` children; `CoachVillainServer.pickPatrol` picks a random part position. Regenerated from current rooms (corridors, lobby, gyms, fitness, racquetball, stairs, walkthrough keys). |

`RACSystems` looks for `workspace.RAC.HorrorGameplay.Speakers` (optional). Tag pickups `RACKeyPickup`.

## CollectionService tags

| Tag | Instance | Attributes |
| --- | --- | --- |
| `Zone` | Room model and each volume part | `id` (snake_case), `name`, `type` (blueprint room type), `level` (1 or 2) |
| `RACZone` | Room model | same |
| `RACDoor` | Door **model** (`DoorSingle` / `DoorDouble`) | See doors |
| `RACSpawn` | `SpawnLocation` | `id` of the room |
| `RACPatrolPoint` | Patrol marker part | `Room`, `level` |
| `RACStair` | Stair group | — |
| `NormalLight` / `EmergencyLight` | `Light` objects | `Zone` |
| `RACKeyPickup` | Pickup part | `KeyName` (default `StaffKey`) |

## Doors (`DoorService`)

Tag the **model**. Each leaf is a `BasePart` named `Door` with:

- child `Hinge` (anchored; local Y is the pivot)
- `ProximityPrompt`
- attribute `OpenAngle` (degrees; negative = opposite swing)
- optional `Sounds/Open`, `Sounds/Close`, `Sounds/Locked`

Model attributes:

| Attribute | Meaning |
| --- | --- |
| `Locked` | Boolean. True on the nutrition keypad door and the basketball OFF LIMITS door. |
| `KeypadCode` / `Code` | `"15234"` on the nutrition vestibule door. `DoorService` does not read this; gameplay should unlock when the player submits the code (`model:SetAttribute("Locked", false)`). |
| `OffLimits` | True on the L2 basketball approach door. |
| `RequiresKey` / `KeyName` | Staff-key doors (unset by the builder). |
| `OpenTime`, `AutoClose`, `AutoCloseDelay` | Tween / autoclose. |
| `IsOpen` | Runtime. Do not author. |

Pathfinding: each door model has a `PathfindingModifier` with `PassThrough = true`, `Label = "Door"`. Stair groups have `Label = "Stairs"`. Coach agent costs should treat `Door` and `Stairs` as 1.

## Finding a room at runtime

```lua
local CollectionService = game:GetService("CollectionService")
local function zone(id)
	for _, inst in CollectionService:GetTagged("Zone") do
		if inst:GetAttribute("id") == id then
			return inst
		end
	end
end
```

Volume parts are queryable (`CanQuery = true`) so a ray or `GetPartBoundsInBox` can recover `id`.

Walkthrough keys used by `NavCheck`: `lobby`, `competition_gym`, `south_gym`, `fitness_center`, `training_room`, `locker_volleyball`, `public_locker`, `racquetball_1`, `basketball_approach`, `cage_gym`, `stair_main` (L2 exit / main stair).

## Nav check

`ServerScriptService.NavCheck` is **off** unless `workspace.RAC:SetAttribute("NavCheck", true)` or the script attribute `Enabled = true`. In a playtest it computes `PathfindingService` paths between every pair of those rooms and prints `[NavCheck] PASS|FAIL` plus coordinates.

## Coach

`CoachVillainServer` still looks up `workspace.Jay` and `workspace.CoachVillainPatrolPoints`. Rebuild the RAC after layout changes so patrol markers match the new rooms. Do not keep the old blockout folder.
