-- ServerScriptService.RACSystems
-- Creates the PA remote and a server BindableFunction.
--
-- During a playtest, server command bar:
--   game.ReplicatedStorage.RAC.Announce:Invoke("The recreation center is now closed.")
--
-- Other server scripts can Invoke the same BindableFunction.
-- Put a Sound named Voice under workspace.RAC.HorrorGameplay.Speakers.<any> and set SoundId
-- if you want the line to also play in the building. Subtitles show either way.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local racFolder = ReplicatedStorage:FindFirstChild("RAC")
if not racFolder then
	racFolder = Instance.new("Folder")
	racFolder.Name = "RAC"
	racFolder.Parent = ReplicatedStorage
end

local remote = racFolder:FindFirstChild("PA")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "PA"
	remote.Parent = racFolder
end

local bindable = racFolder:FindFirstChild("Announce")
if bindable then
	bindable:Destroy()
end
bindable = Instance.new("BindableFunction")
bindable.Name = "Announce"
bindable.Parent = racFolder

bindable.OnInvoke = function(message)
	message = tostring(message or "")
	remote:FireAllClients(message)
	local rac = workspace:FindFirstChild("RAC")
	if not rac then
		return message
	end
	local speakers = rac:FindFirstChild("HorrorGameplay") and rac.HorrorGameplay:FindFirstChild("Speakers")
	if speakers then
		for _, inst in speakers:GetDescendants() do
			if inst:IsA("Sound") and inst.SoundId ~= "" then
				inst:Play()
			end
		end
	end
	return message
end

-- Staff key and any later pickups. Tag a BasePart "RACKeyPickup".
-- Attribute KeyName (default StaffKey). Child Tool named Template is cloned into the backpack.
local CollectionService = game:GetService("CollectionService")

local function hookKey(part)
	if not part:IsA("BasePart") or part:GetAttribute("KeyHooked") then
		return
	end
	part:SetAttribute("KeyHooked", true)
	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		return
	end
	prompt.Triggered:Connect(function(player)
		local keyName = part:GetAttribute("KeyName") or "StaffKey"
		local backpack = player:FindFirstChild("Backpack")
		local character = player.Character
		if (backpack and backpack:FindFirstChild(keyName)) or (character and character:FindFirstChild(keyName)) then
			prompt.ActionText = "Already have " .. keyName
			return
		end
		local template = part:FindFirstChild("Template")
		if template and template:IsA("Tool") and backpack then
			local clone = template:Clone()
			clone.Name = keyName
			clone.Parent = backpack
			prompt.ActionText = "Took " .. keyName
		end
	end)
end

for _, inst in CollectionService:GetTagged("RACKeyPickup") do
	hookKey(inst)
end
CollectionService:GetInstanceAddedSignal("RACKeyPickup"):Connect(hookKey)
