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
local Lights = require(script.Parent.Lights)
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
		for _, item in folder:GetDescendants() do
			if item:IsA("BasePart") then
				item.Anchored = true
				if item:IsA("MeshPart") then
					item.CollisionFidelity = Enum.CollisionFidelity.Box
				end
				n += 1
			end
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
		Court.build(floors, level)
		count(floors, "Floors")
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
			for _, key in { "length", "bays", "rows", "text", "depth" } do
				if extra[key] ~= nil then
					opts[key] = extra[key]
				end
			end
			local instance = PropRegistry.build(prop.kind, cf, opts)
			instance:SetAttribute("BlueprintId", prop.id)
			instance:SetAttribute("Room", prop.room)
			instance.Parent = levelProps
		end
		count(levelProps, "Props")
		local lights = Geometry.folder(root, "Lights")
		Lights.build(lights, level)
		count(lights, "Lights")
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Size = Vector3.new(4, 0.3, 4)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.CanCollide = true
	spawn.Duration = 0
	-- South lobby, a few feet inside the glass, facing north.
	spawn.CFrame = CFrame.new(-2, levelOneY(data), -6)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Color = Color3.fromRGB(196, 192, 180)
	spawn.Parent = model
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
