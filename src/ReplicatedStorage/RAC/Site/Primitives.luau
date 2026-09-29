--!strict
local P = {}
local palette: { [string]: { Enum.Material | Color3 } } = {
	asphalt = { Enum.Material.Asphalt, Color3.fromRGB(58, 61, 62) },
	concrete = { Enum.Material.Concrete, Color3.fromRGB(188, 184, 168) },
	dark = { Enum.Material.Metal, Color3.fromRGB(45, 48, 51) },
	metal = { Enum.Material.Metal, Color3.fromRGB(153, 159, 161) },
	white = { Enum.Material.SmoothPlastic, Color3.fromRGB(228, 228, 211) },
	yellow = { Enum.Material.SmoothPlastic, Color3.fromRGB(231, 185, 45) },
	bark = { Enum.Material.Wood, Color3.fromRGB(94, 81, 65) },
	-- SmoothPlastic: Grass material sprouts blades on the part itself.
	leaf = { Enum.Material.SmoothPlastic, Color3.fromRGB(62, 90, 46) },
	pine = { Enum.Material.SmoothPlastic, Color3.fromRGB(34, 62, 40) },
	shrub = { Enum.Material.SmoothPlastic, Color3.fromRGB(48, 70, 42) },
	barberry = { Enum.Material.SmoothPlastic, Color3.fromRGB(118, 42, 38) },
	grass = { Enum.Material.SmoothPlastic, Color3.fromRGB(87, 108, 49) },
	green = { Enum.Material.Metal, Color3.fromRGB(29, 64, 46) },
	rock = { Enum.Material.Rock, Color3.fromRGB(113, 118, 119) },
	glass = { Enum.Material.Glass, Color3.fromRGB(133, 161, 158) },
}
function P.folder(parent: Instance, name: string): Folder
	local f = Instance.new("Folder")
	f.Name, f.Parent = name, parent
	return f
end
function P.box(parent: Instance, name: string, size: Vector3, cf: CFrame, finish: string, collide: boolean?): Part
	assert(math.min(size.X, size.Y, size.Z) >= 0.01, `Sliver {name}`)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame = name, size, cf
	p.Anchored, p.CanCollide = true, collide == true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	local material = palette[finish]
	assert(material, `Unknown site finish {finish}`)
	p.Material, p.Color = material[1] :: Enum.Material, material[2] :: Color3
	if finish == "glass" then
		p.Transparency, p.Reflectance = 0.45, 0.12
	end
	p.Parent = parent
	return p
end
function P.beam(
	parent: Instance,
	name: string,
	a: Vector3,
	b: Vector3,
	width: number,
	depth: number,
	finish: string,
	collide: boolean?
): Part
	return P.box(
		parent,
		name,
		Vector3.new(width, depth, (b - a).Magnitude),
		CFrame.lookAt((a + b) / 2, b),
		finish,
		collide
	)
end
function P.pole(
	parent: Instance,
	name: string,
	at: Vector3,
	height: number,
	radius: number,
	finish: string,
	collide: boolean?
): Part
	local p = P.box(
		parent,
		name,
		Vector3.new(height, radius * 2, radius * 2),
		CFrame.new(at + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		finish,
		collide
	)
	p.Shape = Enum.PartType.Cylinder
	return p
end
return P
