--!strict
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local ok, models = pcall(function()
	return roblox.deserializeModel(fs.readFile("places/build.rbxm"))
end)
if not ok then
	print("deserializeModel failed", models)
	ok, models = pcall(function()
		return { (roblox :: any).deserializePlace(fs.readFile("places/build.rbxm")) }
	end)
end
assert(ok, tostring(models))
local rac = models[1]
print("root", rac.ClassName, rac.Name)

local function dump(p: any)
	local pos = p.CFrame.Position
	print(string.format("%s | %s pos=(%.2f,%.2f,%.2f) size=(%.2f,%.2f,%.2f) color=%.2f,%.2f,%.2f mat=%s",
		p:GetFullName(), p.ClassName, pos.X, pos.Y, pos.Z, p.Size.X, p.Size.Y, p.Size.Z,
		p.Color.R, p.Color.G, p.Color.B, tostring(p.Material)))
end

local names = {
	TaperedCanopy=true, ReturnCanopy=true, LandingSlab=true, ApronSlab=true, RampRun=true,
	RampLanding=true, RampToe=true, SupportColumn=true, RACLetters=true, DumpsterBody=true,
	DumpsterLid=true, ServiceAsphalt=true, YardScreen=true, Hydrant=true, LightPole=true,
	LotIslandSlab=true, LotAisle=true, CurbIslandSlab=true, Trunk=true, Crown=true,
	CanopyFascia=true, SoffitLight=true, EntryBed=true, StairHandrail=true,
}
local counts: {[string]: number} = {}
local nParts = 0
local siteParts = 0
local trees, pines, crowns, trunks = 0,0,0,0
local lotSlabs, pavSlabs, roadSlabs, stallStripes, dumpsters = 0,0,0,0,0
local curbs, islands, treads = 0,0,0
for _, d in rac:GetDescendants() do
	if d:IsA("BasePart") then
		nParts += 1
		local n = d.Name
		counts[n] = (counts[n] or 0) + 1
		if names[n] or string.sub(n,1,10)=="StairTread" then
			if (counts[n] or 0) <= 6 then
				dump(d)
			end
		end
		local path = d:GetFullName()
		if string.find(path, "Site", 1, true) then
			siteParts += 1
		end
		if n == "Trunk" then trunks += 1 end
		if n == "Crown" then crowns += 1 end
		if string.find(path, "PineCanopy", 1, true) and d.Parent and d.Parent.Name == "PineCanopy" then
			-- skip
		end
		if d.Parent and d.Parent.Name == "PineCanopy" then pines += 1 end
		if d.Parent and d.Parent.Name == "ShadeCanopy" then trees += 1 end
		if n == "LotSlab" then lotSlabs += 1 end
		if n == "PavementSlab" then pavSlabs += 1 end
		if n == "RoadSlab" then roadSlabs += 1 end
		if n == "StallStripe" or n == "StallStripeSlab" then stallStripes += 1 end
		if n == "DumpsterBody" then dumpsters += 1 end
		if n == "Curb" then curbs += 1 end
		if n == "LotIslandSlab" or n == "CurbIslandSlab" then islands += 1 end
		if string.sub(n,1,10)=="StairTread" then treads += 1 end
	end
end
print("nParts", nParts, "siteParts", siteParts)
print("treads", treads, "lotSlabs", lotSlabs, "pavSlabs", pavSlabs, "roadSlabs", roadSlabs)
print("stallStripes", stallStripes, "dumpsters", dumpsters, "curbs", curbs, "islands", islands)
print("trunks", trunks, "crowns", crowns, "pineCanopy children parts", pines, "shadeCanopy children parts", trees)

-- folder names under Site
local function walk(inst: any, depth: number)
	if depth > 3 then return end
	local nP = 0
	for _, c in inst:GetDescendants() do
		if c:IsA("BasePart") then nP += 1 end
	end
	print(string.rep("  ", depth)..inst.Name, inst.ClassName, "kids", #inst:GetChildren(), "parts", nP)
	if depth < 2 then
		for _, c in inst:GetChildren() do
			walk(c, depth+1)
		end
	end
end
for _, c in rac:GetChildren() do
	if c.Name == "Site" or c.Name == "Levels" then
		walk(c, 0)
	end
end

-- top name counts
local items = {}
for k,v in counts do table.insert(items, {k,v}) end
table.sort(items, function(a,b) return a[2] > b[2] end)
print("TOP NAMES")
for i=1,40 do
	if items[i] then print(items[i][1], items[i][2]) end
end
