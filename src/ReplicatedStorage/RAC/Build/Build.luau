--!strict
local Blueprint = require(script.Parent.Blueprint)
local Geometry = require(script.Parent.Geometry)
local Floors = require(script.Parent.Floors)
local Walls = require(script.Parent.Walls)
local Ceilings = require(script.Parent.Ceilings)
local Columns = require(script.Parent.Columns)
local Stairs = require(script.Parent.Stairs)
local Facade = require(script.Parent.Facade)
local Roofs = require(script.Parent.Roofs)
local PropRegistry = require(script.Parent.PropRegistry)
local Court = require(script.Parent.Court)
local LightingBuild = require(script.Parent.Lighting)
local Build = {}

local function levelOneY(data: any): number
	for _, level in data.levels do
		if level.level == 1 then
			return level.elevation + 0.2
		end
	end
	return 0.2
end
export type Stats = { parts: number, byCategory: { [string]: number } }
function Build.build(parent: Instance, raw: any): Stats
	local data = if raw == nil then Blueprint.load() else Blueprint.decode(raw)
	local previous = parent:FindFirstChild("RAC")
	if previous then
		previous:Destroy()
	end
	local model = Instance.new("Model")
	model.Name = "RAC"
	model.Parent = parent
	-- Building stays in blueprint coordinates. trueNorthDeg is metadata for geographic site context.
	model:SetAttribute("TrueNorthDeg", data.site.trueNorthDeg)
	local stats: Stats = { parts = 0, byCategory = {} }
	local function count(folder: Instance, category: string)
		local n = 0
		local function tally(item: Instance)
			if item:IsA("BasePart") then
				item.Anchored = true
				if item:IsA("MeshPart") then
					item.CollisionFidelity = Enum.CollisionFidelity.Box
				end
				n += 1
			end
		end
		tally(folder)
		for _, item in folder:GetDescendants() do
			tally(item)
		end
		stats.parts += n
		stats.byCategory[category] = (stats.byCategory[category] or 0) + n
	end
	local levels = Geometry.folder(model, "Levels")
	local props = Geometry.folder(model, "Props")
	for _, level in data.levels do
		local root = Geometry.folder(levels, tostring(level.level))
		local floors = Geometry.folder(root, "Floors")
		Floors.build(floors, level, data.site)
		count(floors, "Floors")
		Court.build(root, level)
		local courtFolder = root:FindFirstChild("Court")
		if courtFolder then
			count(courtFolder, "Court")
		end
		local walls = Geometry.folder(root, "Walls")
		Walls.build(walls, level, data)
		count(walls, "Walls")
		local ceilings = Geometry.folder(root, "Ceilings")
		Ceilings.build(ceilings, level)
		count(ceilings, "Ceilings")
		local columns = Geometry.folder(root, "Columns")
		Columns.build(columns, level)
		count(columns, "Columns")
		local stairs = Geometry.folder(root, "Stairs")
		Stairs.build(stairs, level, data)
		count(stairs, "Stairs")
		local levelProps = Geometry.folder(props, tostring(level.level))
		for _, prop in level.props do
			local cf = CFrame.new(prop.at[1], level.elevation, prop.at[2])
				* CFrame.Angles(0, math.rad(prop.rotation), 0)
			local opts: { [string]: any } = { room = prop.room }
			local extra = prop :: any
			for _, key in { "length", "bays", "rows", "text", "depth", "sign" } do
				if extra[key] ~= nil then
					opts[key] = extra[key]
				end
			end
			local instance = PropRegistry.build(prop.kind, cf, opts)
			instance:SetAttribute("BlueprintId", prop.id)
			instance:SetAttribute("Kind", prop.kind)
			instance:SetAttribute("Room", prop.room)
			instance.Parent = levelProps
		end
		count(levelProps, "Props")
	end
	local SOLID_KIND = {
		front_desk = true,
		office_desk = true,
		training_table = true,
		ping_pong_table = true,
		locker_bank_metal = true,
		locker_bank_wood = true,
		bench_locker = true,
		flat_bench = true,
		adjustable_bench = true,
		dumbbell_rack = true,
		kettlebell_rack = true,
		cable_machine = true,
		chest_press = true,
		lat_pulldown = true,
		leg_press = true,
		power_rack = true,
		treadmill = true,
		elliptical = true,
		rower = true,
		stair_climber = true,
		upright_bike = true,
		sink_counter = true,
		vending_machine = true,
		cubicle = true,
		industrial_fridge = true,
		ice_machine = true,
		supply_cabinet = true,
		trophy_case = true,
		shower_stall = true,
		toilet_partition = true,
		plate_tree = true,
	}
	for _, levelProps in props:GetChildren() do
		for _, instance in levelProps:GetChildren() do
			local kind = instance:GetAttribute("Kind")
			if type(kind) == "string" and SOLID_KIND[kind] then
				for _, d in instance:GetDescendants() do
					if d:IsA("BasePart") then
						local s = d.Size
						if math.min(s.X, s.Y, s.Z) >= 0.06 and s.X * s.Y * s.Z >= 0.45 then
							d.CanCollide = true
						end
					end
				end
			end
		end
	end
	local lightFolder = LightingBuild.build(model, data)
	count(lightFolder, "Lighting")
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Size = Vector3.new(4, 0.3, 4)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.CanCollide = true
	spawn.Duration = 0
	-- Clear bay east of the desk, inside the 20x20 entry, facing north.
	spawn.CFrame = CFrame.new(5, levelOneY(data), -8)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Color = Color3.fromRGB(196, 192, 180)
	spawn.Parent = model
	count(spawn, "Spawn")
	local site = Geometry.folder(model, "Site")
	local facade = Geometry.folder(site, "Facade")
	Facade.build(facade, data.site, data.levels)
	count(facade, "Facade")
	local roofs = Geometry.folder(site, "Roofs")
	Roofs.build(roofs, data.site)
	count(roofs, "Roofs")
	return stats
end
return Build
