--!strict
-- Low-detail campus massing around the RAC. Site.Builder can call Campus.Builder.build.
local P = require(script.Parent.Parent.Primitives)
local Height = require(script.Parent.Height)
local Data = require(script.Parent.CampusData)

local Campus = {}

local finishes: { [string]: { Enum.Material | Color3 } } = {
	brick = { Enum.Material.Brick, Color3.fromRGB(118, 74, 54) },
	precast = { Enum.Material.Concrete, Color3.fromRGB(214, 210, 198) },
	metal = { Enum.Material.Metal, Color3.fromRGB(132, 138, 141) },
	glass = { Enum.Material.Glass, Color3.fromRGB(140, 168, 172) },
	turf = { Enum.Material.Grass, Color3.fromRGB(62, 112, 52) },
	asphalt = { Enum.Material.Asphalt, Color3.fromRGB(58, 61, 62) },
	paint = { Enum.Material.SmoothPlastic, Color3.fromRGB(236, 236, 228) },
}

local function painted(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	finish: string,
	collide: boolean?
): Part
	local look = finishes[finish]
	assert(look, `Unknown campus finish {finish}`)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Anchored = true
	part.CanCollide = collide == true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = look[1] :: Enum.Material
	part.Color = look[2] :: Color3
	if finish == "glass" then
		part.Transparency = 0.45
		part.Reflectance = 0.08
	end
	part.Parent = parent
	return part
end

local function yawFrame(x: number, y: number, z: number, yaw: number): CFrame
	return CFrame.new(x, y, z) * CFrame.Angles(0, yaw, 0)
end

local function instanceWindows(
	template: BasePart,
	parent: Instance,
	box: any,
	ground: number,
	sill: number,
	head: number
)
	local w, d = box.w, box.d
	local band = math.clamp(head - sill, 2, 8)
	local faces = {
		{ w, Vector3.new(0, 0, d / 2 + 0.12) },
		{ w, Vector3.new(0, 0, -(d / 2 + 0.12)) },
		{ d, Vector3.new(w / 2 + 0.12, 0, 0) },
		{ d, Vector3.new(-(w / 2 + 0.12), 0, 0) },
	}
	local y = ground + sill + band / 2
	for i, face in faces do
		local length = (face[1] :: number) - 6
		if length < 8 then
			continue
		end
		local pane = template:Clone()
		pane.Name = `WindowBand_{i}`
		pane.Size = Vector3.new(length, band, 0.28)
		local offset = face[2] :: Vector3
		pane.CFrame = yawFrame(box.x, y, box.z, box.yaw) * CFrame.new(offset)
		if i >= 3 then
			pane.CFrame = yawFrame(box.x, y, box.z, box.yaw) * CFrame.new(offset) * CFrame.Angles(0, math.pi / 2, 0)
		end
		pane.Parent = parent
	end
end

local function massBuilding(parent: Folder, b: any, windowTemplate: BasePart)
	local folder = P.folder(parent, b.id)
	folder:SetAttribute("CampusName", b.name)
	local ground = b.ground :: number
	local height = b.height :: number
	for _, box in b.boxes do
		local y = ground + height / 2
		painted(
			folder,
			"MassSlab",
			Vector3.new(math.max(box.w, 4), height, math.max(box.d, 4)),
			yawFrame(box.x, y, box.z, box.yaw),
			b.finish,
			true
		)
		painted(
			folder,
			"RoofSlab",
			Vector3.new(math.max(box.w, 4) + 1.5, 1.2, math.max(box.d, 4) + 1.5),
			yawFrame(box.x, ground + height + 0.6, box.z, box.yaw),
			if b.kind == "arena" then "metal" else "precast",
			true
		)
		instanceWindows(windowTemplate, folder, box, ground, b.windowSill, b.windowHead)
	end
end

local function massDeck(parent: Folder, b: any)
	local folder = P.folder(parent, b.id)
	folder:SetAttribute("CampusName", b.name)
	local ground = b.ground :: number
	local levels = math.clamp(b.levels :: number, 3, 5)
	local story = (b.height :: number) / levels
	for _, box in b.boxes do
		for level = 0, levels - 1 do
			local y = ground + level * story + 0.45
			painted(
				folder,
				`DeckSlab_{level}`,
				Vector3.new(math.max(box.w, 4), 0.9, math.max(box.d, 4)),
				yawFrame(box.x, y, box.z, box.yaw),
				"precast",
				true
			)
		end
		-- Open spandrel rails as thin bands between slabs.
		for level = 1, levels - 1 do
			local y = ground + level * story - story / 2
			painted(
				folder,
				`DeckRail_{level}`,
				Vector3.new(math.max(box.w, 4) + 0.4, 1.1, math.max(box.d, 4) + 0.4),
				yawFrame(box.x, y, box.z, box.yaw),
				"metal",
				false
			)
		end
		-- Exterior stair mass on the long side, clear of the floor plates.
		painted(
			folder,
			"DeckStairSlab",
			Vector3.new(10, story * (levels - 1), 14),
			yawFrame(box.x, ground + story * (levels - 1) / 2, box.z, box.yaw) * CFrame.new(box.w / 2 + 12, 0, 0),
			"precast",
			true
		)
	end
end

local function massField(parent: Folder, field: any)
	local folder = P.folder(parent, field.id)
	local box = field.box
	local y = Height.at(box.x, box.z)
	painted(
		folder,
		"TurfSlab",
		Vector3.new(math.max(box.w, 8), 0.35, math.max(box.d, 8)),
		yawFrame(box.x, y + 0.18, box.z, box.yaw),
		"turf",
		true
	)
	for i, mark in field.markings do
		local a, b = mark.a, mark.b
		local ax, az = a[1], a[2]
		local bx, bz = b[1], b[2]
		local mx, mz = (ax + bx) / 2, (az + bz) / 2
		local len = math.max(0.4, math.sqrt((bx - ax) ^ 2 + (bz - az) ^ 2))
		local yaw = math.atan2(bx - ax, bz - az)
		painted(
			folder,
			`LineSlab_{i}`,
			Vector3.new(mark.w or 0.4, 0.08, len),
			yawFrame(mx, Height.at(mx, mz) + 0.85, mz, yaw),
			"paint",
			false
		)
	end
end

function Campus.build(parent: Instance): (Model, number)
	local previous = parent:FindFirstChild("Campus")
	if previous then
		previous:Destroy()
	end
	local model = Instance.new("Model")
	model.Name = "Campus"
	model.Parent = parent
	model:SetAttribute("TrueNorthDeg", 10.43)
	model:SetAttribute("Origin", "RAC south entrance door")
	model:SetAttribute("Budget", 4000)

	local kit = P.folder(model, "Templates")
	local windowTemplate =
		painted(kit, "WindowTemplate", Vector3.new(8, 6, 0.28), CFrame.new(0, -50, 0), "glass", false)
	windowTemplate.Transparency = 0.45

	local masses = P.folder(model, "Buildings")
	local decks = P.folder(model, "ParkingDecks")
	local fields = P.folder(model, "Fields")
	local roads = P.folder(model, "Roads")

	for _, b in Data.buildings do
		if b.kind == "deck" then
			massDeck(decks, b)
		else
			massBuilding(masses, b, windowTemplate)
		end
	end
	for _, field in Data.fields do
		massField(fields, field)
	end
	for _, patch in Data.roads do
		local x = patch.x + patch.w / 2
		local z = patch.z + patch.d / 2
		local y = Height.at(x, z)
		painted(
			roads,
			"RoadSlab",
			Vector3.new(patch.w - 1, 0.28, patch.d - 1),
			CFrame.new(x, y + 0.1, z),
			"asphalt",
			true
		)
	end

	local count = 0
	for _, item in model:GetDescendants() do
		if item:IsA("BasePart") then
			assert(item.Anchored, `Unanchored campus part {item.Name}`)
			count += 1
		end
	end
	-- Template is not in the visible budget.
	count -= 1
	assert(count <= 4000, `Campus exceeds 4000-part neighbour budget ({count})`)
	model:SetAttribute("PartCount", count)
	return model, count
end

return Campus
