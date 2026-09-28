-- ServerScriptService.DoorService
-- Server-authoritative hinged doors. Tag models with CollectionService "RACDoor".
--
-- Model attributes (set these on the Door MODEL, then duplicate freely):
--   Locked          boolean
--   RequiresKey     boolean
--   KeyName         string   tool name, or a child of Player.Keys / Backpack / Character
--   OpenTime        number   seconds
--   AutoClose       boolean
--   AutoCloseDelay  number   seconds
--   IsOpen          boolean  (runtime, do not author)
--
-- Each leaf is a part named "Door" with:
--   child part "Hinge" (anchored, placed on the hinge edge; its local Y is the pivot)
--   attribute OpenAngle (degrees, default 90; use negative to swing the other way)
--   ProximityPrompt
--   Sounds/Open, Sounds/Close, Sounds/Locked   (optional SoundId)
--
-- Hinge formula: door.CFrame = hingeClosedCF * CFrame.Angles(0, rad, 0) * hingeToDoor
-- The hinge part itself never moves. Rotation is around that hinge's origin and local Y.

local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local DoorService = {}

local busy = {}
local tokens = {}

local function soundOn(doorPart, name)
	local folder = doorPart:FindFirstChild("Sounds")
	if not folder then
		return
	end
	local sound = folder:FindFirstChild(name)
	if sound and sound:IsA("Sound") and sound.SoundId ~= "" then
		sound:Play()
	end
end

local function hasKey(player, keyName)
	if keyName == nil or keyName == "" then
		return false
	end
	local function scan(container)
		return container ~= nil and container:FindFirstChild(keyName) ~= nil
	end
	return scan(player:FindFirstChild("Backpack")) or scan(player.Character) or scan(player:FindFirstChild("Keys"))
end

local function leavesOf(model)
	local list = {}
	for _, inst in model:GetDescendants() do
		if inst:IsA("BasePart") and inst.Name == "Door" then
			table.insert(list, inst)
		end
	end
	return list
end

local function capture(doorPart)
	if doorPart:GetAttribute("Captured") then
		return
	end
	local hinge = doorPart:FindFirstChild("Hinge")
	if not hinge or not hinge:IsA("BasePart") then
		warn("RAC door leaf missing Hinge: " .. doorPart:GetFullName())
		return
	end
	doorPart:SetAttribute("Captured", true)
	doorPart:SetAttribute("_HingeX", hinge.CFrame.Position.X)
	doorPart:SetAttribute("_HingeY", hinge.CFrame.Position.Y)
	doorPart:SetAttribute("_HingeZ", hinge.CFrame.Position.Z)
	local rx, ry, rz = hinge.CFrame:ToOrientation()
	doorPart:SetAttribute("_HingeRx", rx)
	doorPart:SetAttribute("_HingeRy", ry)
	doorPart:SetAttribute("_HingeRz", rz)
	local rel = hinge.CFrame:ToObjectSpace(doorPart.CFrame)
	local rpx, rpy, rpz = rel:ToOrientation()
	doorPart:SetAttribute("_RelX", rel.Position.X)
	doorPart:SetAttribute("_RelY", rel.Position.Y)
	doorPart:SetAttribute("_RelZ", rel.Position.Z)
	doorPart:SetAttribute("_RelRx", rpx)
	doorPart:SetAttribute("_RelRy", rpy)
	doorPart:SetAttribute("_RelRz", rpz)
end

local function hingeCF(doorPart)
	return CFrame.new(
		doorPart:GetAttribute("_HingeX"),
		doorPart:GetAttribute("_HingeY"),
		doorPart:GetAttribute("_HingeZ")
	) * CFrame.fromOrientation(
		doorPart:GetAttribute("_HingeRx"),
		doorPart:GetAttribute("_HingeRy"),
		doorPart:GetAttribute("_HingeRz")
	)
end

local function relCF(doorPart)
	return CFrame.new(doorPart:GetAttribute("_RelX"), doorPart:GetAttribute("_RelY"), doorPart:GetAttribute("_RelZ"))
		* CFrame.fromOrientation(
			doorPart:GetAttribute("_RelRx"),
			doorPart:GetAttribute("_RelRy"),
			doorPart:GetAttribute("_RelRz")
		)
end

local function targetCF(doorPart, angleDeg)
	local hinge = hingeCF(doorPart)
	return hinge * CFrame.Angles(0, math.rad(angleDeg), 0) * relCF(doorPart)
end

local function setPrompts(model, enabled, text)
	for _, doorPart in leavesOf(model) do
		local prompt = doorPart:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Enabled = enabled
			if text then
				prompt.ActionText = text
			end
		end
	end
end

local function tweenLeaf(doorPart, angleDeg, duration)
	local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(doorPart, info, { CFrame = targetCF(doorPart, angleDeg) })
	tween:Play()
	return tween
end

local function playLeafSound(model, soundName)
	for _, doorPart in leavesOf(model) do
		soundOn(doorPart, soundName)
		break
	end
end

function DoorService.close(model)
	if busy[model] then
		return
	end
	busy[model] = true
	tokens[model] = (tokens[model] or 0) + 1
	local duration = model:GetAttribute("OpenTime") or 0.45
	setPrompts(model, false, "Close")
	playLeafSound(model, "Close")
	local remaining = 0
	for _, doorPart in leavesOf(model) do
		if doorPart:GetAttribute("Captured") then
			remaining += 1
			local tween = tweenLeaf(doorPart, 0, duration)
			tween.Completed:Connect(function()
				remaining -= 1
				if remaining <= 0 then
					model:SetAttribute("IsOpen", false)
					busy[model] = false
					setPrompts(model, true, "Open")
				end
			end)
		end
	end
	if remaining == 0 then
		busy[model] = false
	end
end

function DoorService.open(model)
	if busy[model] then
		return
	end
	busy[model] = true
	tokens[model] = (tokens[model] or 0) + 1
	local myToken = tokens[model]
	local duration = model:GetAttribute("OpenTime") or 0.45
	setPrompts(model, false, "Open")
	playLeafSound(model, "Open")
	local remaining = 0
	for _, doorPart in leavesOf(model) do
		if doorPart:GetAttribute("Captured") then
			remaining += 1
			local angle = doorPart:GetAttribute("OpenAngle") or 90
			local tween = tweenLeaf(doorPart, angle, duration)
			tween.Completed:Connect(function()
				remaining -= 1
				if remaining <= 0 then
					model:SetAttribute("IsOpen", true)
					busy[model] = false
					setPrompts(model, true, "Close")
					if model:GetAttribute("AutoClose") then
						local delayTime = model:GetAttribute("AutoCloseDelay") or 4
						task.delay(delayTime, function()
							if tokens[model] == myToken and model.Parent and model:GetAttribute("IsOpen") then
								DoorService.close(model)
							end
						end)
					end
				end
			end)
		end
	end
	if remaining == 0 then
		busy[model] = false
	end
end

local function onTriggered(model, player)
	if busy[model] then
		return
	end
	local locked = model:GetAttribute("Locked")
	local requiresKey = model:GetAttribute("RequiresKey")
	local keyName = model:GetAttribute("KeyName") or ""
	if locked or requiresKey then
		if not (requiresKey and hasKey(player, keyName)) then
			playLeafSound(model, "Locked")
			setPrompts(model, true, if requiresKey then "Needs " .. keyName else "Locked")
			return
		end
	end
	if model:GetAttribute("IsOpen") then
		DoorService.close(model)
	else
		DoorService.open(model)
	end
end

local function hook(model)
	if model:GetAttribute("Hooked") then
		return
	end
	model:SetAttribute("Hooked", true)
	for _, doorPart in leavesOf(model) do
		capture(doorPart)
		local prompt = doorPart:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Triggered:Connect(function(player)
				onTriggered(model, player)
			end)
		end
	end
end

for _, model in CollectionService:GetTagged("RACDoor") do
	hook(model)
end
CollectionService:GetInstanceAddedSignal("RACDoor"):Connect(hook)

return DoorService
