-- Swaps the coach (Workspace.Jay, and any model named Dan) for the ST·J trainer.
--
-- Rojo syncs assets/characters/StJTrainer.rbxm into ReplicatedStorage.Characters.
-- That file is produced once in Studio: Avatar > Import 3D on
-- assets/source/StJTrainer.fbx (Rig Type R15), then right-click the model,
-- Save to File, and commit it as assets/characters/StJTrainer.rbxm.
-- Rojo cannot import an FBX; it can only sync the saved model.
--
-- The instance keeps its name, so CoachVillainServer still finds "Jay".
-- Scripts, prompts, sounds, attributes and tags on the old model are kept.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TARGET_NAMES = { Jay = true, Dan = true }
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

local function isA(inst, classes)
	for _, className in classes do
		if inst:IsA(className) then
			return true
		end
	end
	return false
end

local function feetOffset(model)
	local root = model:FindFirstChild("HumanoidRootPart")
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if root and humanoid then
		return root.Size.Y / 2 + humanoid.HipHeight
	end
	local cf, size = model:GetBoundingBox()
	return size.Y / 2 + (cf.Position.Y - model:GetPivot().Position.Y)
end

local function ready()
	ReplicatedStorage:SetAttribute("CharacterSwapReady", true)
end

local characters = ReplicatedStorage:FindFirstChild("Characters")
local template = characters and characters:FindFirstChild("StJTrainer")
if template == nil or not template:IsA("Model") then
	warn("[ReplaceCharacter] ReplicatedStorage.Characters.StJTrainer is missing. " ..
		"Import assets/source/StJTrainer.fbx in Studio and save it as assets/characters/StJTrainer.rbxm.")
	ready()
	return
end

local function swap(old)
	if not old:IsA("Model") or CollectionService:HasTag(old, SWAPPED_TAG) or not old.Parent then
		return
	end
	local oldHumanoid = old:FindFirstChildOfClass("Humanoid")
	if not oldHumanoid then
		return
	end

	local new = template:Clone()
	new.Name = old.Name
	new:SetAttribute("StJBody", true)
	CollectionService:AddTag(new, SWAPPED_TAG)

	local newHumanoid = new:FindFirstChildOfClass("Humanoid")
	local newRoot = new:FindFirstChild("HumanoidRootPart")
	if not newHumanoid or not newRoot then
		new:Destroy()
		warn("[ReplaceCharacter] StJTrainer has no Humanoid or HumanoidRootPart")
		return
	end

	for _, prop in HUMANOID_PROPERTIES do
		pcall(function()
			newHumanoid[prop] = oldHumanoid[prop]
		end)
	end
	for _, child in oldHumanoid:GetChildren() do
		if not child:IsA("Animator") and not child:IsA("HumanoidDescription") and not child:IsA("NumberValue") then
			child.Parent = newHumanoid
		end
	end

	local oldRoot = old:FindFirstChild("HumanoidRootPart")
	local base = if oldRoot then oldRoot.CFrame else old:GetPivot()
	local targetRoot = base * CFrame.new(0, feetOffset(new) - feetOffset(old), 0)
	new:PivotTo(targetRoot * newRoot.CFrame:ToObjectSpace(new:GetPivot()))
	if oldRoot then
		newRoot.Anchored = oldRoot.Anchored
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
		elseif child.Name == "Animate" then
			local templateAnimate = new:FindFirstChild("Animate")
			if templateAnimate then
				templateAnimate:Destroy()
			end
			child.Parent = new
		elseif not isA(child, APPEARANCE_CLASSES) and not child:IsA("BasePart") then
			child.Parent = new
		end
	end

	local parent = old.Parent
	old:Destroy()
	new.Parent = parent
end

for _, inst in workspace:GetDescendants() do
	if TARGET_NAMES[inst.Name] then
		swap(inst)
	end
end
workspace.DescendantAdded:Connect(function(inst)
	if TARGET_NAMES[inst.Name] then
		task.defer(swap, inst)
	end
end)

ready()
