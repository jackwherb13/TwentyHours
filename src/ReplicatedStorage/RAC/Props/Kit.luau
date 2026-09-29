--!strict
-- Shared helpers for prop modules. Every prop module builds through a Kit builder so props are
-- consistent (anchored, sensible collision, named parts) and testable offline with Lune.
-- Units: feet (1 stud = 1 ft). Local coordinates: origin = bottom-center of the prop, front faces -Z.

local Kit = {}

export type Builder = {
	model: Model,
	base: CFrame,
	box: (
		self: Builder,
		name: string,
		size: Vector3,
		at: CFrame,
		color: Color3,
		material: Enum.Material?,
		collide: boolean?
	) -> Part,
	cyl: (
		self: Builder,
		name: string,
		length: number,
		diameter: number,
		at: CFrame,
		color: Color3,
		material: Enum.Material?
	) -> Part,
	ball: (self: Builder, name: string, diameter: number, at: CFrame, color: Color3, material: Enum.Material?) -> Part,
	wedge: (
		self: Builder,
		name: string,
		size: Vector3,
		at: CFrame,
		color: Color3,
		material: Enum.Material?
	) -> WedgePart,
	decal: (self: Builder, part: BasePart, face: Enum.NormalId, texture: string) -> Decal,
	light: (
		self: Builder,
		part: BasePart,
		face: Enum.NormalId,
		brightness: number,
		range: number,
		color: Color3?
	) -> SurfaceLight,
	done: (self: Builder) -> Model,
}

-- Mason / RAC palette sampled from reference photos (tweak here, not in props).
Kit.Color = {
	MasonGreen = Color3.fromRGB(0, 82, 45),
	MasonGold = Color3.fromRGB(255, 205, 0),
	BleacherGreen = Color3.fromRGB(28, 64, 48),
	BleacherGold = Color3.fromRGB(214, 170, 30),
	SteelBlack = Color3.fromRGB(30, 31, 34),
	SteelGrey = Color3.fromRGB(120, 124, 130),
	Chrome = Color3.fromRGB(200, 204, 208),
	RubberBlack = Color3.fromRGB(22, 22, 24),
	Upholstery = Color3.fromRGB(26, 26, 28),
	Maple = Color3.fromRGB(214, 176, 124),
	WoodLocker = Color3.fromRGB(176, 136, 88),
	OffWhite = Color3.fromRGB(236, 234, 228),
	Beige = Color3.fromRGB(200, 188, 168),
	DoorWood = Color3.fromRGB(190, 140, 84),
	FrameGrey = Color3.fromRGB(150, 150, 146),
	Glass = Color3.fromRGB(180, 205, 210),
	Screen = Color3.fromRGB(12, 14, 18),
}

local function makePart(
	className: string,
	b: any,
	name: string,
	size: Vector3,
	at: CFrame,
	color: Color3,
	material: Enum.Material?,
	collide: boolean?
): any
	local p: any = Instance.new(className :: any)
	p.Name = name
	p.Size = size
	p.CFrame = b.base * at
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = collide == true
	p.CastShadow = size.Magnitude > 1.5
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = b.model
	return p
end

--[[
	Create a builder. `base` is the world CFrame of the prop's bottom-center; `name` names the Model.
	Local `at` CFrames passed to box/cyl/... are relative to `base`.
]]
function Kit.new(name: string, base: CFrame): Builder
	local model = Instance.new("Model")
	model.Name = name
	local b: any = { model = model, base = base }

	function b.box(self, n, size, at, color, material, collide)
		return makePart("Part", self, n, size, at, color, material, collide)
	end

	-- Cylinder along the local X axis of `at` (Roblox cylinder convention).
	function b.cyl(self, n, length, diameter, at, color, material)
		local p = makePart("Part", self, n, Vector3.new(length, diameter, diameter), at, color, material, false)
		p.Shape = Enum.PartType.Cylinder
		return p
	end

	function b.ball(self, n, diameter, at, color, material)
		local p = makePart("Part", self, n, Vector3.new(diameter, diameter, diameter), at, color, material, false)
		p.Shape = Enum.PartType.Ball
		return p
	end

	function b.wedge(self, n, size, at, color, material)
		return makePart("WedgePart", self, n, size, at, color, material, false)
	end

	function b.decal(_self, part, face, texture)
		local d = Instance.new("Decal")
		d.Face = face
		d.Texture = texture
		d.Parent = part
		return d
	end

	function b.light(_self, part, face, brightness, range, color)
		local l = Instance.new("SurfaceLight")
		l.Face = face
		l.Brightness = brightness
		l.Range = range
		l.Color = color or Color3.fromRGB(255, 250, 240)
		l.Shadows = false
		l.Parent = part
		return l
	end

	function b.done(self)
		return self.model
	end

	return b :: Builder
end

-- Convenience: CFrame at local position (x, y, z) in feet.
function Kit.at(x: number, y: number, z: number): CFrame
	return CFrame.new(x, y, z)
end

-- Convenience: CFrame for a cylinder whose axis runs along local Y (vertical post) at (x, y, z).
function Kit.vertical(x: number, y: number, z: number): CFrame
	return CFrame.new(x, y, z) * CFrame.Angles(0, 0, math.rad(90))
end

-- Convenience: cylinder axis along local Z at (x, y, z).
function Kit.alongZ(x: number, y: number, z: number): CFrame
	return CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(90), 0)
end

return Kit
