-- ServerScriptService.RACBuild
-- The edit-time RAC is the play building. This script does not construct a second model.

local Lighting = game:GetService("Lighting")
local Materials = require(game:GetService("ReplicatedStorage").RAC.Materials)

local function lighting()
	pcall(function()
		Lighting.Technology = Enum.Technology.Future
	end)
	-- Mid-afternoon. Keep sun honest outdoors; interiors come from fixtures + a small ambient fill.
	Lighting.ClockTime = 14
	Lighting.Brightness = 1.0
	Lighting.EnvironmentDiffuseScale = 0.22
	Lighting.EnvironmentSpecularScale = 0.18
	Lighting.ExposureCompensation = -0.15
	Lighting.Ambient = Color3.fromRGB(52, 52, 54)
	Lighting.OutdoorAmbient = Color3.fromRGB(96, 98, 94)
	Lighting.GlobalShadows = true
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere == nil then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = Lighting
	end
	atmosphere.Density = 0.18
	atmosphere.Offset = 0.08
	atmosphere.Haze = 0
	atmosphere.Glare = 0
	atmosphere.Color = Color3.fromRGB(198, 204, 210)
	atmosphere.Decay = Color3.fromRGB(160, 166, 172)
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	if bloom == nil then
		bloom = Instance.new("BloomEffect")
		bloom.Parent = Lighting
	end
	bloom.Intensity = 0.12
	bloom.Size = 12
	bloom.Threshold = 1.4
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
