-- ServerScriptService.RACBuild
-- The edit-time RAC is the play building. This script does not construct a second model.

local Lighting = game:GetService("Lighting")
local Materials = require(game:GetService("ReplicatedStorage").RAC.Materials)

local function lighting()
	pcall(function()
		Lighting.Technology = Enum.Technology.Future
	end)
	Lighting.ClockTime = 14
	Lighting.Brightness = 2.2
	Lighting.EnvironmentDiffuseScale = 0.45
	Lighting.EnvironmentSpecularScale = 0.35
	Lighting.Ambient = Color3.fromRGB(150, 152, 148)
	Lighting.OutdoorAmbient = Color3.fromRGB(180, 184, 180)
	Lighting.GlobalShadows = true
end

local function streamingOff()
	pcall(function()
		workspace.StreamingEnabled = false
	end)
end

local function clearInteriorTerrain()
	local terrain = workspace.Terrain
	local boxes = {
		-- Training room, including the ceiling where grass was showing.
		{ Vector3.new(-221, 8, -77), Vector3.new(40, 18, 40) },
		-- Left hall from the south glass to the gym doors.
		{ Vector3.new(-80, 8, -70), Vector3.new(50, 20, 150) },
		-- South lobby and the glass bay.
		{ Vector3.new(-20, 8, -14), Vector3.new(40, 36, 36) },
	}
	for _, box in boxes do
		pcall(function()
			terrain:FillBlock(CFrame.new(box[1]), box[2], Enum.Material.Air)
		end)
	end
end

lighting()
streamingOff()
clearInteriorTerrain()

local Players = game:GetService("Players")
local rac = workspace:WaitForChild("RAC")
local lobby = rac:WaitForChild("LobbySpawn")
if lobby:IsA("SpawnLocation") then
	lobby.Enabled = true
	lobby.Neutral = true
	lobby.Duration = 0
end
for _, child in workspace:GetChildren() do
	if child:IsA("SpawnLocation") and child ~= lobby then
		child:Destroy()
	end
end

local function claim(player: Player)
	if lobby:IsA("SpawnLocation") then
		player.RespawnLocation = lobby
	end
	player.CharacterAdded:Connect(function(character)
		local root = character:WaitForChild("HumanoidRootPart")
		-- Default place spawn sits on the threshold. Stand inside the south lobby, facing north.
		root.CFrame = CFrame.new(lobby.Position + Vector3.new(0, 3.2, 0))
	end)
end
Players.PlayerAdded:Connect(claim)
for _, player in Players:GetPlayers() do
	claim(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = CFrame.new(lobby.Position + Vector3.new(0, 3.2, 0))
	end
end

-- MaterialVariant writes need plugin capability. Edit installs them; Play keeps that copy.
pcall(function()
	Materials.install()
end)

local parts = 0
for _, inst in rac:GetDescendants() do
	if inst:IsA("BasePart") then
		parts += 1
	end
end
print(string.format("RAC play building: %d parts (same model as Edit).", parts))
