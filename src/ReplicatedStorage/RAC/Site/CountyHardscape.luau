--!strict
local P = require(script.Parent.Primitives)
local H = require(script.Parent.Heightfield)
local G = require(script.Parent.Parent.Build.Geometry)
local County = {}
-- Lidar inside the footprint is the roof. Pavement draped on it cuts through the floors.
local function onBuilding(site: any, x: number, z: number): boolean
	local pads = if site.terrain then site.terrain.padPolygons else nil
	if not pads then
		return false
	end
	for _, polygon in pads do
		if G.contains(polygon, x, z) then
			return true
		end
	end
	return false
end
function County.build(parent: Instance, site: any)
	local source = site.planimetric
	local ground = P.folder(parent, "CountyPavement")
	for _, q in source.patches do
		local x, z = q.x + q.w / 2, q.z + q.d / 2
		if onBuilding(site, x, z) then
			continue
		end
		local gx = (H.height(x + q.w / 2, z) - H.height(x - q.w / 2, z)) / q.w
		local gz = (H.height(x, z + q.d / 2) - H.height(x, z - q.d / 2)) / q.d
		local right = Vector3.new(1, gx, 0).Unit
		local back = Vector3.new(0, gz, 1)
		local up = back:Cross(right).Unit
		back = right:Cross(up).Unit
		local thickness = 0.28
		-- Top face sits on the lidar sample. A negative offset buried Patriot Circle.
		local centerY = H.height(x, z) + 0.08 - up.Y * thickness / 2
		P.box(
			ground,
			"CountySurfaceSlab",
			Vector3.new(math.max(0.4, q.w - 0.15), thickness, math.max(0.4, q.d - 0.15)),
			CFrame.fromMatrix(Vector3.new(x, centerY, z), right, up, back),
			q.material,
			true
		)
	end
end
return County
