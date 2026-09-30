--!strict
-- Read-only dump of places/build.rbxm for QA. Does not modify the model.
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local file = "places/build.rbxm"
local ok, rootsOrErr = pcall(function()
	return roblox.deserializeModel(fs.readFile(file))
end)
if not ok then
	print("deserializeModel failed", rootsOrErr)
	ok, rootsOrErr = pcall(function()
		return { (roblox :: any).deserializePlace(fs.readFile(file)) }
	end)
end
assert(ok, tostring(rootsOrErr))
local models = rootsOrErr :: { any }
local rac = models[1]
for _, m in models do
	if m.Name == "RAC" then
		rac = m
		break
	end
end
print("root", rac.ClassName, rac.Name, "children", #rac:GetChildren())

local function matStr(p: any): string
	local okm, m = pcall(function()
		return tostring(p.Material)
	end)
	return if okm then m else "?"
end

local function varStr(p: any): string
	local okv, v = pcall(function()
		return tostring(p.MaterialVariant)
	end)
	return if okv then v else ""
end

local function tagsOf(inst: any): string
	local okt, t = pcall(function()
		return inst:GetTags()
	end)
	if not okt or type(t) ~= "table" then
		return "-"
	end
	local out = {}
	for _, name in t do
		table.insert(out, tostring(name))
	end
	table.sort(out)
	return table.concat(out, ",")
end

local function dumpPart(p: any)
	local pos = p.CFrame.Position
	local col = p.Color
	print(
		string.format(
			"%s | %s pos=(%.2f,%.2f,%.2f) size=(%.2f,%.2f,%.2f) mat=%s var=%s color=%.3f,%.3f,%.3f collide=%s query=%s tags=%s racMat=%s racZone=%s",
			p:GetFullName(),
			p.ClassName,
			pos.X,
			pos.Y,
			pos.Z,
			p.Size.X,
			p.Size.Y,
			p.Size.Z,
			matStr(p),
			varStr(p),
			col.R,
			col.G,
			col.B,
			tostring(p.CanCollide),
			tostring(p.CanQuery),
			tagsOf(p),
			tostring(p:GetAttribute("RACMaterial")),
			tostring(p:GetAttribute("RAC_Zone"))
		)
	)
end

local counts: { [string]: number } = {}
local lights = 0
local spotLights = 0
local pointLights = 0
local surfaceLights = 0
local zoneAttr = 0
local zoneTag = 0
local racZoneTag = 0
local maple = 0
local mapleVariant = 0
local mapleWhite = 0
local brick = 0
local grass = 0
local tinyNoCollideStairs = 0
local lightingFolder = false
local lightingKids = 0
local masterMode = ""
local pathMods = 0
local pathLinks = 0
local keypadDoors = 0
local doorSingles = 0
local doorDoubles = 0
local lockedDoors = 0
local offLimits = 0
local keypadCode = 0
local pine = 0
local shade = 0
local dumpsters = 0
local colliders = 0
local parts = 0
local instances = 0
local treadCollide = 0
local treadNoCollide = 0
local treadMinY = math.huge
local slabMaple = 0
local courtGreen = 0
local courtGold = 0

local KEY = {
	TaperedCanopy = true,
	ReturnCanopy = true,
	LandingSlab = true,
	ApronSlab = true,
	RampRun = true,
	SupportColumn = true,
	RACLetters = true,
	DumpsterBody = true,
	LobbySpawn = true,
	FrontCounter = true,
	TransactionCounter = true,
}

local fountainN = 0
local treadmillN = 0
local cubicleN = 0
local frontDeskN = 0

for _, d in rac:GetDescendants() do
	instances += 1
	local cls = d.ClassName
	counts[cls] = (counts[cls] or 0) + 1
	if d:IsA("BasePart") then
		parts += 1
		if d.CanCollide then
			colliders += 1
		end
	end
	if cls == "SpotLight" then
		spotLights += 1
		lights += 1
	elseif cls == "PointLight" then
		pointLights += 1
		lights += 1
	elseif cls == "SurfaceLight" then
		surfaceLights += 1
		lights += 1
	elseif string.find(cls, "Light", 1, true) and cls ~= "Lighting" then
		lights += 1
	end
	if d.Name == "Lighting" and (cls == "Folder" or cls == "Model") then
		lightingFolder = true
		lightingKids = #d:GetChildren()
		local master = d:FindFirstChild("MasterMode")
		if master then
			pcall(function()
				masterMode = tostring((master :: any).Value)
			end)
		end
		print("LIGHTING_FOLDER parent", d.Parent and d.Parent.Name, "class", cls, "children", lightingKids, "MasterMode", masterMode)
	end
	if d.ClassName == "PathfindingModifier" then
		pathMods += 1
		if pathMods <= 8 then
			print(
				"PATHMOD",
				d:GetFullName(),
				"PassThrough",
				tostring((d :: any).PassThrough),
				"Label",
				tostring((d :: any).Label)
			)
		end
	end
	if d.ClassName == "PathfindingLink" then
		pathLinks += 1
		print("PATHLINK", d:GetFullName())
	end
	if d:GetAttribute("RAC_Zone") == true then
		zoneAttr += 1
	end
	local tagListOk, tagList = pcall(function()
		return d:GetTags()
	end)
	if tagListOk and type(tagList) == "table" then
		for _, t in tagList do
			if t == "Zone" then
				zoneTag += 1
			elseif t == "RACZone" then
				racZoneTag += 1
			end
		end
	end
	local name = d.Name
	if KEY[name] or string.sub(name, 1, 10) == "StairTread" then
		if d:IsA("BasePart") then
			dumpPart(d)
		else
			print("MODEL", d:GetFullName(), d.ClassName, #d:GetChildren())
		end
	end
	if name == "PineCanopy" then
		pine += 1
	elseif name == "ShadeCanopy" then
		shade += 1
	elseif name == "DumpsterBody" then
		dumpsters += 1
	elseif name == "KeypadDoor" then
		keypadDoors += 1
	elseif name == "DoorSingle" then
		doorSingles += 1
	elseif name == "DoorDouble" then
		doorDoubles += 1
	elseif name == "WaterFountain" then
		fountainN += 1
		if d:IsA("Model") or d:IsA("Folder") then
			local low = math.huge
			local high = -math.huge
			local any: any = nil
			for _, p in d:GetDescendants() do
				if p:IsA("BasePart") then
					any = p
					local y = p.CFrame.Position.Y
					low = math.min(low, y - p.Size.Y / 2)
					high = math.max(high, y + p.Size.Y / 2)
				end
			end
			if any then
				print(
					string.format(
						"FOUNTAIN %s bottom=%.2f top=%.2f pos=(%.2f,%.2f,%.2f)",
						d:GetFullName(),
						low,
						high,
						any.CFrame.Position.X,
						any.CFrame.Position.Y,
						any.CFrame.Position.Z
					)
				)
			end
		end
	elseif name == "Treadmill" then
		treadmillN += 1
		if treadmillN <= 10 and (d:IsA("Model") or d:IsA("Folder")) then
			local low = math.huge
			local any: any = nil
			for _, p in d:GetDescendants() do
				if p:IsA("BasePart") then
					any = p
					local y = p.CFrame.Position.Y
					low = math.min(low, y - p.Size.Y / 2)
				end
			end
			if any then
				print(
					string.format(
						"TREADMILL %s bottom=%.2f pos=(%.2f,%.2f,%.2f)",
						d:GetFullName(),
						low,
						any.CFrame.Position.X,
						any.CFrame.Position.Y,
						any.CFrame.Position.Z
					)
				)
			end
		end
	elseif name == "Cubicle" then
		cubicleN += 1
	elseif name == "FrontDesk" then
		frontDeskN += 1
		if d:IsA("Model") or d:IsA("Folder") then
			print("FRONTDESK", d:GetFullName(), "children", #d:GetChildren(), "len", d:GetAttribute("length"))
			for _, p in d:GetDescendants() do
				if p:IsA("BasePart") and (p.Name == "FrontCounter" or p.Name == "TransactionCounter" or p.Name == "LeftReturn") then
					dumpPart(p)
				end
			end
		end
	end
	if d:GetAttribute("Locked") == true then
		lockedDoors += 1
		print(
			"LOCKED",
			d:GetFullName(),
			"OffLimits",
			tostring(d:GetAttribute("OffLimits")),
			"KeypadCode",
			tostring(d:GetAttribute("KeypadCode")),
			"DoorLink",
			tostring(d:GetAttribute("RAC_DoorLink")),
			"tags",
			tagsOf(d)
		)
	end
	if d:GetAttribute("OffLimits") == true then
		offLimits += 1
	end
	if type(d:GetAttribute("KeypadCode")) == "string" then
		keypadCode += 1
	end
	if d:GetAttribute("RAC_StairLink") == true then
		print("STAIRLINK_ATTR", d:GetFullName())
	end
	if d:IsA("BasePart") then
		local variant = varStr(d)
		local racMat = d:GetAttribute("RACMaterial")
		if racMat == "maple" or variant == "RAC_maple" or string.find(string.lower(name), "maple", 1, true) then
			maple += 1
			if variant == "RAC_maple" then
				mapleVariant += 1
			end
			local col = d.Color
			if col.R > 0.95 and col.G > 0.95 and col.B > 0.95 then
				mapleWhite += 1
			end
			if maple <= 6 then
				dumpPart(d)
			end
		end
		if racMat == "maple" and name == "Slab" then
			slabMaple += 1
		end
		if racMat == "court_green_paint" then
			courtGreen += 1
		end
		if racMat == "court_gold_paint" then
			courtGold += 1
		end
		local mat = matStr(d)
		if string.find(string.lower(mat), "brick", 1, true) or string.find(string.lower(variant), "brick", 1, true) then
			brick += 1
		end
		if string.find(string.lower(mat), "grass", 1, true) then
			grass += 1
			if grass <= 8 then
				dumpPart(d)
			end
		end
		local path = string.lower(d:GetFullName())
		local size = d.Size
		local minAx = math.min(size.X, size.Y, size.Z)
		if string.find(path, "stair", 1, true) then
			if string.find(string.lower(name), "tread", 1, true) then
				if d.CanCollide then
					treadCollide += 1
				else
					treadNoCollide += 1
					if treadNoCollide <= 6 then
						dumpPart(d)
					end
				end
				local top = d.CFrame.Position.Y + size.Y / 2
				treadMinY = math.min(treadMinY, top)
			end
			if d.CanCollide == false and minAx < 0.5 then
				tinyNoCollideStairs += 1
			end
		end
	end
end

print("COUNTS")
local keys = {}
for k in counts do
	table.insert(keys, k)
end
table.sort(keys)
for _, k in keys do
	print(k, counts[k])
end

print("SUMMARY")
print("instances", instances, "parts", parts, "colliders", colliders)
print("lights", lights, "spot", spotLights, "point", pointLights, "surface", surfaceLights)
print("zoneAttr RAC_Zone", zoneAttr, "GetTags Zone", zoneTag, "GetTags RACZone", racZoneTag)
print("lightingFolder", lightingFolder, "lightingKids", lightingKids, "MasterMode", masterMode)
print("pathMods", pathMods, "pathLinks", pathLinks)
print("doors single", doorSingles, "double", doorDoubles, "keypadModel", keypadDoors, "locked", lockedDoors, "offLimits", offLimits, "keypadCodeAttr", keypadCode)
print("mapleParts", maple, "mapleVariant", mapleVariant, "mapleWhite", mapleWhite, "slabMaple", slabMaple)
print("courtGreen", courtGreen, "courtGold", courtGold, "brickParts", brick, "grassParts", grass)
print("tinyNoCollideStairs", tinyNoCollideStairs, "treadCollide", treadCollide, "treadNoCollide", treadNoCollide, "treadMinTopY", treadMinY)
print("trees pine", pine, "shade", shade, "dumpsters", dumpsters)
print("fountains", fountainN, "treadmills", treadmillN, "cubicles", cubicleN, "frontDesks", frontDeskN)

print("CHILDREN")
for _, c in rac:GetChildren() do
	print("CHILD", c.Name, c.ClassName, #c:GetChildren())
end

local zones = rac:FindFirstChild("Zones")
if zones then
	print("ZONES", #zones:GetChildren())
	local n = 0
	for _, z in zones:GetChildren() do
		n += 1
		if n <= 12 or z.Name == "lobby" or z.Name == "training_room" or z.Name == "cage_gym" or z.Name == "stair_main" then
			print(
				"ZONE",
				z.Name,
				z.ClassName,
				"id",
				tostring(z:GetAttribute("id")),
				"level",
				tostring(z:GetAttribute("level")),
				"RAC_Zone",
				tostring(z:GetAttribute("RAC_Zone")),
				"tags",
				tagsOf(z),
				"vols",
				#z:GetChildren()
			)
		end
	end
else
	print("ZONES missing")
end

-- Sample a few door leaves for CanCollide
local leafDump = 0
for _, d in rac:GetDescendants() do
	if d:IsA("Model") and (d.Name == "DoorSingle" or d.Name == "DoorDouble" or d.Name == "KeypadDoor") then
		local locked = d:GetAttribute("Locked")
		local code = d:GetAttribute("KeypadCode")
		local clear = 0
		local solidLeaf = 0
		local solidOther = 0
		for _, p in d:GetDescendants() do
			if p:IsA("BasePart") and p.CanCollide then
				if p.Name == "Door" or string.sub(p.Name, 1, 5) == "Door_" then
					solidLeaf += 1
				else
					solidOther += 1
				end
			end
			if p:IsA("BasePart") and p:GetAttribute("RAC_ClearOpening") == true then
				clear += 1
			end
		end
		if locked == true or type(code) == "string" or leafDump < 6 then
			print(
				string.format(
					"DOOR %s locked=%s code=%s off=%s clearAttr=%d solidLeaf=%d solidOther=%d tags=%s pfmod=%s",
					d:GetFullName(),
					tostring(locked),
					tostring(code),
					tostring(d:GetAttribute("OffLimits")),
					clear,
					solidLeaf,
					solidOther,
					tagsOf(d),
					tostring(d:FindFirstChild("PathfindingModifier") ~= nil)
				)
			)
			leafDump += 1
		end
	end
end

-- Main stair first treads
local levels = rac:FindFirstChild("Levels")
if levels then
	for _, lf in levels:GetChildren() do
		local stairs = lf:FindFirstChild("Stairs")
		if stairs then
			for _, st in stairs:GetChildren() do
				print("STAIR_GROUP", st:GetFullName(), "linkAttr", tostring(st:GetAttribute("RAC_StairLink")), "tags", tagsOf(st))
				local n = 0
				for _, p in st:GetDescendants() do
					if p:IsA("BasePart") and string.find(string.lower(p.Name), "tread", 1, true) then
						n += 1
						if n <= 3 or n >= 30 then
							dumpPart(p)
						end
					end
					if p:IsA("BasePart") and string.find(string.lower(p.Name), "main_turn", 1, true) then
						dumpPart(p)
					end
				end
				print("STAIR_TREADS", st.Name, n)
			end
		end
	end
end
