--!strict
local Materials = require(script.Parent.Parent.Materials)
local Parts = {}
local alias: { [string]: string } = { acoustic = "acoustic_ceiling" }
local finishes: { [string]: { material: Enum.Material, color: Color3 } } = {
	maple = { material = Enum.Material.WoodPlanks, color = Color3.fromRGB(232, 204, 156) },
	terrazzo = { material = Enum.Material.Concrete, color = Color3.fromRGB(198, 190, 178) },
	porcelain_tile = { material = Enum.Material.Marble, color = Color3.fromRGB(186, 178, 168) },
	ceramic_tile = { material = Enum.Material.CeramicTiles, color = Color3.fromRGB(231, 228, 215) },
	carpet_tile = { material = Enum.Material.Fabric, color = Color3.fromRGB(68, 70, 74) },
	rubber = { material = Enum.Material.Rubber, color = Color3.fromRGB(34, 35, 36) },
	sealed_concrete = { material = Enum.Material.Concrete, color = Color3.fromRGB(176, 174, 166) },
	vinyl = { material = Enum.Material.SmoothPlastic, color = Color3.fromRGB(184, 176, 164) },
	painted_cmu = { material = Enum.Material.Concrete, color = Color3.fromRGB(232, 230, 224) },
	brick = { material = Enum.Material.Brick, color = Color3.fromRGB(136, 69, 45) },
	gypsum = { material = Enum.Material.Plaster, color = Color3.fromRGB(235, 233, 223) },
	glass = { material = Enum.Material.Glass, color = Color3.fromRGB(208, 225, 224) },
	metal_panel = { material = Enum.Material.Metal, color = Color3.fromRGB(145, 150, 153) },
	precast = { material = Enum.Material.Concrete, color = Color3.fromRGB(179, 173, 158) },
	steel = { material = Enum.Material.Metal, color = Color3.fromRGB(43, 46, 48) },
	acoustic = { material = Enum.Material.Plaster, color = Color3.fromRGB(236, 235, 225) },
}
function Parts.box(parent: Instance, name: string, size: Vector3, cf: CFrame, finish: string, collide: boolean?): Part
	assert(size.X > 0 and size.Y > 0 and size.Z > 0, `Invalid size for {name}`)
	local look = finishes[finish]
	assert(look, `Unknown blueprint material {finish}`)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Anchored = true
	part.CanCollide = collide ~= false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	local key = alias[finish] or finish
	if Materials[key] ~= nil and key ~= "apply" then
		Materials.apply(part, key)
	else
		part.Material = look.material
		part.Color = look.color
		part.MaterialVariant = ""
	end
	if finish == "glass" then
		part.Transparency = 0.6
	end
	part.Parent = parent
	return part
end
return Parts
