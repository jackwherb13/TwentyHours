-- ServerScriptService.LightingController
--
-- workspace.RAC.Lighting.MasterMode  (StringValue)
--   "zoned"      use each zone's Mode (default)
--   "normal"     force all normal lights on
--   "blackout"   all lights off
--   "emergency"  normal off, emergency on
--   "flicker"    all normal lights flicker, emergency on
--
-- workspace.RAC.Lighting.<Zone>.Mode (StringValue)
--   "normal" | "off" | "emergency" | "flicker"
--
-- PointLights are tagged NormalLight or EmergencyLight and parented under the zone folder.
-- Change Mode during play to run horror beats without editing parts.

local CollectionService = game:GetService("CollectionService")

local rac = workspace:WaitForChild("RAC")
local lightingFolder = rac:WaitForChild("Lighting")

local flickerToken = 0

local function lightsIn(zoneName)
	local normal = {}
	local emergency = {}
	local function consider(light)
		if not light:IsA("Light") then
			return
		end
		local zone = light:GetAttribute("Zone")
		if zoneName ~= "*" and zone ~= zoneName then
			return
		end
		if CollectionService:HasTag(light, "EmergencyLight") then
			table.insert(emergency, light)
		else
			table.insert(normal, light)
		end
	end
	for _, inst in lightingFolder:GetDescendants() do
		consider(inst)
	end
	return normal, emergency
end

local function applyZone(zoneName, mode)
	local normal, emergency = lightsIn(zoneName)
	if mode == "off" or mode == "blackout" then
		for _, l in normal do
			l.Enabled = false
		end
		for _, l in emergency do
			l.Enabled = false
		end
	elseif mode == "emergency" then
		for _, l in normal do
			l.Enabled = false
		end
		for _, l in emergency do
			l.Enabled = true
		end
	elseif mode == "flicker" then
		for _, l in emergency do
			l.Enabled = true
		end
		for _, l in normal do
			l.Enabled = true
		end
	else
		for _, l in normal do
			l.Enabled = true
		end
		for _, l in emergency do
			l.Enabled = false
		end
	end
end

local function currentModes()
	local master = lightingFolder:FindFirstChild("MasterMode")
	local masterMode = if master and master:IsA("StringValue") then master.Value else "zoned"
	return masterMode
end

local function applyAll()
	flickerToken += 1
	local masterMode = currentModes()
	if masterMode ~= "zoned" then
		applyZone("*", masterMode)
		if masterMode == "flicker" then
			local token = flickerToken
			task.spawn(function()
				while token == flickerToken do
					for _, light in CollectionService:GetTagged("NormalLight") do
						if light:IsA("Light") then
							light.Enabled = math.random() > 0.25
						end
					end
					task.wait(0.08 + math.random() * 0.2)
				end
			end)
		end
		return
	end

	local anyFlicker = false
	for _, child in lightingFolder:GetChildren() do
		if child:IsA("Folder") then
			local modeValue = child:FindFirstChild("Mode")
			local mode = if modeValue and modeValue:IsA("StringValue") then modeValue.Value else "normal"
			applyZone(child.Name, mode)
			if mode == "flicker" then
				anyFlicker = true
			end
		end
	end
	if anyFlicker then
		local token = flickerToken
		task.spawn(function()
			while token == flickerToken do
				for _, child in lightingFolder:GetChildren() do
					local modeValue = child:FindFirstChild("Mode")
					if child:IsA("Folder") and modeValue and modeValue.Value == "flicker" then
						for _, inst in child:GetDescendants() do
							if inst:IsA("Light") and CollectionService:HasTag(inst, "NormalLight") then
								inst.Enabled = math.random() > 0.25
							end
						end
					end
				end
				task.wait(0.08 + math.random() * 0.22)
			end
		end)
	end
end

local function watch(valueObject)
	valueObject.Changed:Connect(function()
		applyAll()
	end)
end

local master = lightingFolder:WaitForChild("MasterMode")
watch(master)
for _, child in lightingFolder:GetChildren() do
	if child:IsA("Folder") then
		local mode = child:FindFirstChild("Mode")
		if mode then
			watch(mode)
		end
	end
end

applyAll()
