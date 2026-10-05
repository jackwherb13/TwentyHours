-- Builds the ST·J trainer from StJMesh and swaps it onto a Dan model.
-- Mesh parts are real instances, so the result is visible in Studio without pressing Play.

local AssetService = game:GetService("AssetService")
local CollectionService = game:GetService("CollectionService")

local SWAPPED_TAG = "StJTrainerSwapped"

local BODY_PARTS = {
	HumanoidRootPart = true,
	Head = true,
	UpperTorso = true,
	LowerTorso = true,
	Torso = true,
	LeftUpperArm = true,
	LeftLowerArm = true,
	LeftHand = true,
	RightUpperArm = true,
	RightLowerArm = true,
	RightHand = true,
	LeftUpperLeg = true,
	LeftLowerLeg = true,
	LeftFoot = true,
	RightUpperLeg = true,
	RightLowerLeg = true,
	RightFoot = true,
	["Left Arm"] = true,
	["Right Arm"] = true,
	["Left Leg"] = true,
	["Right Leg"] = true,
}

local APPEARANCE_CLASSES = {
	"Humanoid",
	"Accessory",
	"Shirt",
	"Pants",
	"ShirtGraphic",
	"BodyColors",
	"CharacterMesh",
}

local PART_CHILD_CLASSES = {
	"ProximityPrompt",
	"ClickDetector",
	"BillboardGui",
	"SurfaceGui",
	"Dialog",
	"Sound",
	"ParticleEmitter",
	"PointLight",
	"SpotLight",
	"BaseScript",
	"ModuleScript",
}

local HUMANOID_PROPERTIES = {
	"DisplayName",
	"DisplayDistanceType",
	"NameDisplayDistance",
	"HealthDisplayType",
	"HealthDisplayDistance",
	"MaxHealth",
	"Health",
	"WalkSpeed",
	"UseJumpPower",
	"JumpPower",
	"JumpHeight",
	"AutoRotate",
	"AutoJumpEnabled",
	"BreakJointsOnDeath",
	"RequiresNeck",
}

local B64 = {}
do
	local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	for i = 1, #alphabet do
		B64[string.byte(alphabet, i)] = i - 1
	end
end

local function decode(data: string): string
	local out = table.create(#data * 3 / 4)
	local n = 0
	local bytes = table.create(#data)
	local count = 0
	for i = 1, #data do
		local value = B64[string.byte(data, i)]
		if value ~= nil then
			count += 1
			bytes[count] = value
		end
	end
	local i = 1
	while i <= count do
		local a = bytes[i]
		local b = bytes[i + 1]
		local c = bytes[i + 2]
		local d = bytes[i + 3]
		i += 4
		if a == nil then
			break
		end
		n += 1
		out[n] = string.char(bit32.bor(bit32.lshift(a, 2), bit32.rshift(b or 0, 4)))
		if c ~= nil then
			n += 1
			out[n] = string.char(bit32.band(bit32.bor(bit32.lshift(b or 0, 4), bit32.rshift(c, 2)), 255))
		end
		if d ~= nil then
			n += 1
			out[n] = string.char(bit32.band(bit32.bor(bit32.lshift(c or 0, 6), d), 255))
		end
	end
	return table.concat(out)
end

local function isA(inst: Instance, classes: { string }): boolean
	for _, className in classes do
		if inst:IsA(className) then
			return true
		end
	end
	return false
end

local function readParts(blob: string)
	local count, at = string.unpack("<H", blob)
	local parts = table.create(count)
	for _ = 1, count do
		local nameLen
		nameLen, at = string.unpack("<B", blob, at)
		local name = string.sub(blob, at, at + nameLen - 1)
		at += nameLen
		local nv, nt
		nv, nt, at = string.unpack("<HH", blob, at)
		local verts = table.create(nv)
		for v = 1, nv do
			local x, y, z
			x, y, z, at = string.unpack("<fff", blob, at)
			verts[v] = Vector3.new(x, y, z)
		end
		local cols = table.create(nv)
		for v = 1, nv do
			local r, g, b
			r, g, b, at = string.unpack("<BBB", blob, at)
			cols[v] = Color3.fromRGB(r, g, b)
		end
		local tris = table.create(nt)
		for t = 1, nt do
			local a, b, c
			a, b, c, at = string.unpack("<HHH", blob, at)
			tris[t] = { a + 1, b + 1, c + 1 }
		end
		table.insert(parts, { name = name, verts = verts, cols = cols, tris = tris })
	end
	return parts
end

local function meshPart(part): MeshPart
	local editable = AssetService:CreateEditableMesh()
	local ids = table.create(#part.verts)
	local colorOf = {}
	local function colorId(color: Color3): number
		local key = string.format("%d,%d,%d", color.R * 255, color.G * 255, color.B * 255)
		local existing = colorOf[key]
		if existing then
			return existing
		end
		local id = editable:AddColor(color, 1)
		colorOf[key] = id
		return id
	end
	for i, position in part.verts do
		ids[i] = editable:AddVertex(position)
	end
	for _, tri in part.tris do
		local face = editable:AddTriangle(ids[tri[1]], ids[tri[2]], ids[tri[3]])
		for _, index in tri do
			editable:SetVertexFaceColor(ids[index], face, colorId(part.cols[index]))
		end
	end
	local mesh = AssetService:CreateMeshPartAsync(Content.fromObject(editable))
	editable:Destroy()
	mesh.Name = part.name
	mesh.DoubleSided = true
	mesh.PivotOffset = CFrame.new()
	mesh.CanCollide = part.name ~= "Head"
	return mesh
end

local cached: { any }? = nil

local function parts()
	if cached == nil then
		local source = require(script.Parent.StJMesh)
		cached = readParts(decode(source))
	end
	return cached
end

local Build = {}

function Build.model(): Model
	local model = Instance.new("Model")
	model.Name = "StJTrainer"
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Transparency = 1
	root.CanCollide = false
	root.Parent = model
	model.PrimaryPart = root
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = model
	humanoid.RigType = Enum.HumanoidRigType.R15
	for _, part in parts() do
		local mesh = meshPart(part)
		mesh.CFrame = CFrame.new()
		mesh.Parent = model
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = mesh
		weld.Parent = mesh
	end
	model:SetAttribute("StJBody", true)
	return model
end

function Build.swap(old: Model)
	if CollectionService:HasTag(old, SWAPPED_TAG) or old:GetAttribute("StJBody") then
		return
	end
	local oldHumanoid = old:FindFirstChildOfClass("Humanoid")
	if not oldHumanoid then
		return
	end
	local new = Build.model()
	new.Name = old.Name
	CollectionService:AddTag(new, SWAPPED_TAG)
	local newHumanoid = new:FindFirstChildOfClass("Humanoid") :: Humanoid
	local newRoot = new:FindFirstChild("HumanoidRootPart") :: BasePart
	for _, prop in HUMANOID_PROPERTIES do
		pcall(function()
			(newHumanoid :: any)[prop] = (oldHumanoid :: any)[prop]
		end)
	end
	for _, child in oldHumanoid:GetChildren() do
		if not child:IsA("Animator") and not child:IsA("HumanoidDescription") and not child:IsA("NumberValue") then
			child.Parent = newHumanoid
		end
	end
	local oldRoot = old:FindFirstChild("HumanoidRootPart") :: BasePart?
	if oldRoot then
		newRoot.CFrame = oldRoot.CFrame
		newRoot.Anchored = oldRoot.Anchored
	else
		new:PivotTo(old:GetPivot())
	end
	for _, mesh in new:GetChildren() do
		if mesh:IsA("MeshPart") then
			mesh.CFrame = newRoot.CFrame
			mesh.Anchored = newRoot.Anchored
		end
	end
	for name, value in old:GetAttributes() do
		if new:GetAttribute(name) == nil then
			new:SetAttribute(name, value)
		end
	end
	for _, tag in CollectionService:GetTags(old) do
		CollectionService:AddTag(new, tag)
	end
	for _, child in old:GetChildren() do
		if BODY_PARTS[child.Name] and child:IsA("BasePart") then
			local target = new:FindFirstChild(child.Name) or newRoot
			for _, grandchild in child:GetChildren() do
				if isA(grandchild, PART_CHILD_CLASSES) then
					grandchild.Parent = target
				end
			end
		elseif not isA(child, APPEARANCE_CLASSES) and not child:IsA("BasePart") then
			child.Parent = new
		end
	end
	local parent = old.Parent
	old:Destroy()
	new.Parent = parent
end

return Build
