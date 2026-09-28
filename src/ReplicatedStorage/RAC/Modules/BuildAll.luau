-- ReplicatedStorage.RAC.Modules.BuildAll
-- Edit-mode builder. Command bar:
--   require(game.ReplicatedStorage.RAC.Modules.BuildAll).run()
--
-- Destroys workspace.RAC only. Does not touch ReplicatedStorage.RAC (these modules live there).
-- Run it again after you edit room rectangles. Then press Play.

local Config = require(script.Parent.RACConfig)
local Architecture = require(script.Parent.RACArchitecture)
local Props = require(script.Parent.RACProps)

local BuildAll = {}

function BuildAll.run()
	local old = workspace:FindFirstChild("RAC")
	if old then
		old:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = "RAC"
	model.Parent = workspace
	model:SetAttribute("ScaleStudsPerFoot", Config.STUD_PER_FOOT)
	model:SetAttribute("IncludeEstimated", Config.INCLUDE_ESTIMATED)

	local built = Architecture.build(model, Config)
	Props.build(built, Config)

	pcall(function()
		-- selene: allow(incorrect_standard_library_use)
		workspace.StreamingEnabled = true
	end)
	pcall(function()
		game.Lighting.Technology = Enum.Technology.Future
	end)
	game.Lighting.ClockTime = 15.5
	game.Lighting.Brightness = 2
	game.Lighting.EnvironmentDiffuseScale = 0.4
	game.Lighting.GlobalShadows = true

	local parts = 0
	for _, inst in model:GetDescendants() do
		if inst:IsA("BasePart") then
			parts += 1
		end
	end
	print(
		string.format(
			"RAC blockout ready. %d parts. 1 stud = 1 foot. Spawn is LobbySpawn. Red neon post is 6 ft. Estimated rooms: %s",
			parts,
			tostring(Config.INCLUDE_ESTIMATED)
		)
	)
	return model
end

return BuildAll
