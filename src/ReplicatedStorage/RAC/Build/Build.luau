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
local Build = {}
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
			for _, key in { "length", "bays", "rows", "text" } do
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
	end
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
