--!strict
-- CollectionService tags, zone volumes, door lock state, spawns, and Coach patrol points.
local CollectionService = game:GetService("CollectionService")
local Blueprint = require(script.Parent.Blueprint)
local Geometry = require(script.Parent.Geometry)

local Tags = {}

local PATROL_TYPES: { [string]: boolean } = {
	corridor = true,
	lobby = true,
	gym = true,
	fitness = true,
	racquetball = true,
	stair = true,
}

local KEY_ROOMS = {
	"lobby",
	"competition_gym",
	"south_gym",
	"fitness_center",
	"training_room",
	"locker_volleyball",
	"public_locker",
	"racquetball_1",
	"basketball_approach",
	"cage_gym",
	"stair_main",
}

local function addTag(inst: Instance, tag: string)
	pcall(function()
		CollectionService:AddTag(inst, tag)
		inst:AddTag(tag)
	end)
end

local function bounds(poly: Blueprint.Polygon): (number, number, number, number)
	local x0, x1 = math.huge, -math.huge
	local z0, z1 = math.huge, -math.huge
	for _, p in poly do
		x0 = math.min(x0, p[1])
		x1 = math.max(x1, p[1])
		z0 = math.min(z0, p[2])
		z1 = math.max(z1, p[2])
	end
	return x0, x1, z0, z1
end

local function centroid(poly: Blueprint.Polygon): (number, number)
	local x0, x1, z0, z1 = bounds(poly)
	local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
	if Geometry.contains(poly, cx, cz) then
		return cx, cz
	end
	for _, r in Geometry.rectangles(poly) do
		if r.w * r.d > 4 then
			return r.x + r.w / 2, r.z + r.d / 2
		end
	end
	return cx, cz
end

local function marker(parent: Instance, name: string, pos: Vector3, color: Color3): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = Vector3.new(1.5, 0.2, 1.5)
	p.CFrame = CFrame.new(pos)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Transparency = 1
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

local function ensurePrompt(doorPart: BasePart)
	if doorPart:FindFirstChildOfClass("ProximityPrompt") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ProximityPrompt"
	prompt.ActionText = "Open"
	prompt.ObjectText = "Door"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = doorPart
end

local function prepareLeaves(model: Model)
	for _, inst in model:GetDescendants() do
		if inst:IsA("BasePart") and (inst.Name == "Door" or string.sub(inst.Name, 1, 5) == "Door_") then
			inst.Name = "Door"
			if inst:GetAttribute("OpenAngle") == nil then
				inst:SetAttribute("OpenAngle", 90)
			end
			ensurePrompt(inst)
		end
	end
end

local function passThrough(parent: Instance, label: string)
	local ok, modifier = pcall(function()
		return Instance.new("PathfindingModifier")
	end)
	if not ok then
		return
	end
	if typeof(modifier) ~= "Instance" then
		return
	end
	modifier.Name = "PathfindingModifier"
	pcall(function()
		modifier.PassThrough = true
		modifier.Label = label
	end)
	modifier.Parent = parent
end

local function modelPos(m: Model): Vector3?
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			local ok, cf = pcall(function()
				return d.CFrame
			end)
			if ok and cf then
				return cf.Position
			end
		end
	end
	return nil
end

local function findDoorAt(model: Model, x: number, z: number, _elevation: number): Model?
	local best: Model? = nil
	local bestD = 6
	for _, inst in model:GetDescendants() do
		if
			inst:IsA("Model") and (inst.Name == "DoorSingle" or inst.Name == "DoorDouble" or inst.Name == "KeypadDoor")
		then
			local p = modelPos(inst)
			if p then
				local d = (Vector3.new(p.X, 0, p.Z) - Vector3.new(x, 0, z)).Magnitude
				if d < bestD then
					bestD = d
					best = inst
				end
			end
		end
	end
	return best
end

function Tags.apply(rac: Model, data: Blueprint.Data): Folder
	local zones = Geometry.folder(rac, "Zones")
	local spawns = Geometry.folder(rac, "Spawns")
	local roomIndex: { [string]: { room: Blueprint.Room, level: Blueprint.Level, x: number, z: number } } = {}

	for _, level in data.levels do
		for _, room in level.rooms do
			if room.type == "void" then
				continue
			end
			local cx, cz = centroid(room.polygon)
			roomIndex[room.id] = { room = room, level = level, x = cx, z = cz }
			local group = Instance.new("Model")
			group.Name = room.id
			group.Parent = zones
			group:SetAttribute("id", room.id)
			group:SetAttribute("name", room.name)
			group:SetAttribute("type", room.type)
			group:SetAttribute("level", level.level)
			addTag(group, "Zone")
			addTag(group, "RACZone")
			for _, r in Geometry.rectangles(room.polygon) do
				local h = math.max(room.ceilingHeight, 8)
				local vol = Instance.new("Part")
				vol.Name = "Volume"
				vol.Size = Vector3.new(r.w, h, r.d)
				vol.CFrame = CFrame.new(r.x + r.w / 2, level.elevation + h / 2, r.z + r.d / 2)
				vol.Anchored = true
				vol.CanCollide = false
				vol.CanTouch = false
				vol.CanQuery = true
				vol.Transparency = 1
				vol.CastShadow = false
				vol.Material = Enum.Material.SmoothPlastic
				vol:SetAttribute("id", room.id)
				vol:SetAttribute("name", room.name)
				vol:SetAttribute("type", room.type)
				vol:SetAttribute("level", level.level)
				vol.Parent = group
				addTag(vol, "Zone")
			end
		end
	end

	for _, level in data.levels do
		for _, wall in level.walls do
			local cf = Geometry.frame(wall.a, wall.b, level.elevation)
			for _, o in wall.openings do
				if o.type ~= "door" then
					continue
				end
				local mid = cf * CFrame.new(o.offset + o.width / 2, o.sill, 0)
				local door = findDoorAt(rac, mid.Position.X, mid.Position.Z, level.elevation)
				if not door then
					continue
				end
				addTag(door, "RACDoor")
				if o.tag and o.tag ~= "RACDoor" then
					addTag(door, o.tag)
				end
				door:SetAttribute("Locked", false)
				door:SetAttribute("RequiresKey", false)
				door:SetAttribute("OpenTime", 0.45)
				door:SetAttribute("AutoClose", true)
				door:SetAttribute("AutoCloseDelay", 4)
				door:SetAttribute("IsOpen", false)
				local extra = o :: any
				local code = extra.keypadCode
				local label = extra.label
				if type(code) == "string" and code ~= "" then
					door:SetAttribute("Locked", true)
					door:SetAttribute("KeypadCode", code)
					door:SetAttribute("Code", code)
				end
				if type(label) == "string" and string.find(string.upper(label), "OFF LIMITS", 1, true) then
					door:SetAttribute("Locked", true)
					door:SetAttribute("OffLimits", true)
				end
				prepareLeaves(door)
				passThrough(door, "Door")
			end
		end
	end

	-- Any leftover door models still get prompts/hinges.
	for _, inst in rac:GetDescendants() do
		if
			inst:IsA("Model") and (inst.Name == "DoorSingle" or inst.Name == "DoorDouble" or inst.Name == "KeypadDoor")
		then
			addTag(inst, "RACDoor")
			prepareLeaves(inst)
			if inst:FindFirstChild("PathfindingModifier") == nil then
				passThrough(inst, "Door")
			end
		end
	end

	local levelsFolder = rac:FindFirstChild("Levels")
	if levelsFolder then
		for _, levelFolder in levelsFolder:GetChildren() do
			local stairs = levelFolder:FindFirstChild("Stairs")
			if stairs then
				for _, stair in stairs:GetChildren() do
					passThrough(stair, "Stairs")
					addTag(stair, "RACStair")
				end
			end
		end
	end

	local lobbySpawn = rac:FindFirstChild("LobbySpawn")
	if lobbySpawn and lobbySpawn:IsA("BasePart") then
		addTag(lobbySpawn, "RACSpawn")
		lobbySpawn:SetAttribute("id", "lobby")
	end

	local alts = {
		{ id = "gym_foyer", name = "GymFoyerSpawn" },
		{ id = "fitness_center", name = "FitnessSpawn" },
		{ id = "cardio_gallery", name = "CardioSpawn" },
	}
	for _, alt in alts do
		local info = roomIndex[alt.id]
		if info then
			local spawn = Instance.new("SpawnLocation")
			spawn.Name = alt.name
			spawn.Size = Vector3.new(4, 0.3, 4)
			spawn.Anchored = true
			spawn.Neutral = true
			spawn.Enabled = false
			spawn.Duration = 0
			spawn.CanCollide = true
			spawn.CFrame = CFrame.new(info.x, info.level.elevation + 0.2, info.z)
			spawn.Material = Enum.Material.SmoothPlastic
			spawn.Color = Color3.fromRGB(196, 192, 180)
			spawn.Transparency = 1
			spawn:SetAttribute("id", alt.id)
			spawn.Parent = spawns
			addTag(spawn, "RACSpawn")
		end
	end

	local parent = rac.Parent
	local host: Instance = rac
	if parent and (parent.Name == "Workspace" or parent.ClassName == "Workspace") then
		host = parent
	end
	local old = host:FindFirstChild("CoachVillainPatrolPoints")
	if old then
		old:Destroy()
	end
	if parent and parent ~= host then
		local stray = parent:FindFirstChild("CoachVillainPatrolPoints")
		if stray then
			stray:Destroy()
		end
	end
	local patrol = Instance.new("Folder")
	patrol.Name = "CoachVillainPatrolPoints"
	patrol.Parent = host
	local n = 0
	for id, info in roomIndex do
		if PATROL_TYPES[info.room.type] or table.find(KEY_ROOMS, id) then
			n += 1
			local p = marker(
				patrol,
				`Patrol_{info.level.level}_{id}`,
				Vector3.new(info.x, info.level.elevation + 5, info.z),
				Color3.fromRGB(180, 40, 40)
			)
			p:SetAttribute("Room", id)
			p:SetAttribute("level", info.level.level)
			addTag(p, "RACPatrolPoint")
		end
	end
	patrol:SetAttribute("Count", n)

	rac:SetAttribute("NavCheck", false)
	return zones
end

return Tags
