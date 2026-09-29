--!strict
local Parts = {}
local finishes: { [string]: { material: Enum.Material, color: Color3, variant: string? } } = {
	maple = { material = Enum.Material.WoodPlanks, color = Color3.fromRGB(214, 176, 124), variant = "RAC_Maple" },
	terrazzo = { material = Enum.Material.Marble, color = Color3.fromRGB(220, 217, 207), variant = "RAC_Terrazzo" },
	porcelain_tile = {
		material = Enum.Material.Slate,
		color = Color3.fromRGB(210, 210, 204),
		variant = "RAC_PorcelainTile",
	},
	ceramic_tile = { material = Enum.Material.Slate, color = Color3.fromRGB(225, 224, 214) },
	carpet_tile = { material = Enum.Material.Fabric, color = Color3.fromRGB(65, 67, 65), variant = "RAC_CarpetTile" },
	rubber = { material = Enum.Material.Rubber, color = Color3.fromRGB(22, 22, 24), variant = "RAC_Rubber" },
	sealed_concrete = { material = Enum.Material.Concrete, color = Color3.fromRGB(157, 158, 153) },
	vinyl = { material = Enum.Material.SmoothPlastic, color = Color3.fromRGB(191, 187, 170) },
	painted_cmu = {
		material = Enum.Material.Concrete,
		color = Color3.fromRGB(232, 230, 221),
		variant = "RAC_PaintedCMU",
	},
	brick = { material = Enum.Material.Brick, color = Color3.fromRGB(111, 69, 52), variant = "RAC_Brick" },
	gypsum = { material = Enum.Material.Plaster, color = Color3.fromRGB(237, 235, 227) },
	glass = { material = Enum.Material.Glass, color = Color3.fromRGB(180, 205, 210) },
	metal_panel = { material = Enum.Material.Metal, color = Color3.fromRGB(118, 123, 126) },
	precast = { material = Enum.Material.Concrete, color = Color3.fromRGB(201, 195, 180) },
	steel = { material = Enum.Material.Metal, color = Color3.fromRGB(43, 46, 48) },
	acoustic = { material = Enum.Material.Plaster, color = Color3.fromRGB(226, 225, 216), variant = "RAC_AcousticTile" },
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
	part.Material = look.material
	part.Color = look.color
	part.MaterialVariant = look.variant or ""
	if finish == "glass" then
		part.Transparency = 0.6
	end
	part.Parent = parent
	return part
end
return Parts
