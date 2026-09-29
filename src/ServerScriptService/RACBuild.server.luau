-- ServerScriptService.RACBuild
-- The edit-time RAC is the play building. This script does not construct a second model.

local Lighting = game:GetService("Lighting")
local Materials = require(game:GetService("ReplicatedStorage").RAC.Materials)

local function lighting()
	pcall(function()
		Lighting.Technology = Enum.Technology.Future
	end)
	Lighting.ClockTime = 14
	Lighting.Brightness = 1.2
	Lighting.EnvironmentDiffuseScale = 0.35
	Lighting.EnvironmentSpecularScale = 0.25
	Lighting.ExposureCompensation = 0
	-- Interiors are lit by fixtures. Outdoor sun still lights the site.
	Lighting.Ambient = Color3.fromRGB(40, 40, 42)
	Lighting.OutdoorAmbient = Color3.fromRGB(110, 112, 108)
	Lighting.GlobalShadows = true
end

local function streamingOff()
	pcall(function()
		workspace.StreamingEnabled = false
	end)
end

local function clearInteriorTerrain()
	local terrain = workspace.Terrain
	local ok, err = pcall(function()
		local Carve = require(game:GetService("ReplicatedStorage").RAC.Site.Carve)
		print("Interior terrain carve blocks:", Carve.apply(terrain))
	end)
	if not ok then
		warn("Interior terrain carve failed: " .. tostring(err))
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
