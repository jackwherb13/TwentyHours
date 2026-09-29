--!strict
-- Apply owned exterior specifications to a copy; never rewrite interior JSON.
local Prepare = {}
local function clone(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for k, v in value do
		result[k] = clone(v)
	end
	return result
end
function Prepare.apply(raw: any): any
	local data = clone(raw)
	local site = data.site.site
	if not site or not site.exteriorWallOverrides then
		return data
	end
	for _, level in data.levels do
		if level.level == 1 then
			for _, override in site.exteriorWallOverrides do
				for i, wall in level.walls do
					if wall.id == override.id then
						assert(wall.exterior, "Site override attempted to change an interior wall")
						level.walls[i] = clone(override)
					end
				end
			end
		end
	end
	return data
end
return Prepare
