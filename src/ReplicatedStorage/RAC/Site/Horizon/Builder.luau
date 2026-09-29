--!strict
-- Distant silhouettes + tree-mass blobs. Terrain voxels live in Horizon.Terrain (Studio).
local P = require(script.Parent.Parent.Primitives)
local Height = require(script.Parent.Height)
local Data = require(script.Parent.HorizonData)

local Horizon = {}

local function blob(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cf
	part.Anchored = true
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = material
	part.Color = color
	part.Parent = parent
	return part
end

function Horizon.build(parent: Instance): (Model, number)
	local previous = parent:FindFirstChild("Horizon")
	if previous then
		previous:Destroy()
	end
	local model = Instance.new("Model")
	model.Name = "Horizon"
	model.Parent = parent
	model:SetAttribute("Budget", 1500)
	model:SetAttribute("FogDensity", Data.fog.density)
	model:SetAttribute("FogOffset", Data.fog.offset)

	local sil = P.folder(model, "Silhouettes")
	local canopy = P.folder(model, "TreeMass")

	local function overBuilding(x: number, z: number): boolean
		return x >= -390 and x <= 30 and z >= -340 and z <= 70
	end

	for _, s in Data.silhouettes do
		local box = s.box
		if overBuilding(box.x, box.z) then
			continue
		end
		local ground = Height.at(box.x, box.z)
		blob(
			sil,
			s.id .. "Slab",
			Vector3.new(math.max(box.w, 12), s.height, math.max(box.d, 12)),
			CFrame.new(box.x, ground + s.height / 2, box.z) * CFrame.Angles(0, box.yaw, 0),
			Color3.fromRGB(168, 160, 148),
			Enum.Material.Concrete
		)
	end
	for i, t in Data.trees do
		if overBuilding(t.x, t.z) then
			continue
		end
		-- Every canopy is a distant mass. Keep half so the place stays under the part cap.
		if i % 2 == 0 then
			continue
		end
		local ground = Height.at(t.x, t.z)
		blob(
			canopy,
			`CanopySlab_{i}`,
			Vector3.new(t.r * 1.6, t.h, t.r * 1.6),
			CFrame.new(t.x, ground + t.h * 0.45, t.z),
			Color3.fromRGB(36, 62, 38),
			Enum.Material.SmoothPlastic
		)
	end

	local count = 0
	for _, item in model:GetDescendants() do
		if item:IsA("BasePart") then
			assert(item.Anchored, `Unanchored horizon part {item.Name}`)
			count += 1
		end
	end
	assert(count <= 1500, `Horizon exceeds 1500-part budget ({count})`)
	model:SetAttribute("PartCount", count)
	return model, count
end

return Horizon
