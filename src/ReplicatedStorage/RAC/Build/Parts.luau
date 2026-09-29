--!strict
local Materials = require(script.Parent.Parent.Materials)
local Parts = {}
local alias: { [string]: string } = {
	acoustic = "acoustic_ceiling",
	mullion = "mullion_aluminum",
}
function Parts.box(parent: Instance, name: string, size: Vector3, cf: CFrame, finish: string, collide: boolean?): Part
	assert(size.X > 0 and size.Y > 0 and size.Z > 0, `Invalid size for {name}`)
	local key = alias[finish] or finish
	assert(Materials[key] ~= nil and key ~= "apply" and key ~= "install", `Unknown blueprint material {finish}`)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Anchored = true
	part.CanCollide = collide ~= false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	Materials.apply(part, key)
	if key == "glass" then
		part.Transparency = 0.78
	end
	part.Parent = parent
	return part
end
return Parts
