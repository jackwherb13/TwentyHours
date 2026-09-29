--!strict
-- Read-only diagnosis of wall-gap reports against the actual built solids.
-- Does not suppress or replace the required check_geometry gate.
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local process = require("@lune/process")
local roots = roblox.deserializeModel(fs.readFile(process.args[1] or "verification/M1/build.rbxm"))
local boxes = {}
local function path(p)
	local names = {}
	while p do table.insert(names,1,p.Name);p=p.Parent end
	return table.concat(names,".")
end
for _,root in roots do
	for _,p in root:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < .95 then
			local s=p.Size;local cf=p.CFrame;local r,u,l=cf.RightVector,cf.UpVector,cf.LookVector
			local h=roblox.Vector3.new(math.abs(r.X)*s.X+math.abs(u.X)*s.Y+math.abs(l.X)*s.Z,math.abs(r.Y)*s.X+math.abs(u.Y)*s.Y+math.abs(l.Y)*s.Z,math.abs(r.Z)*s.X+math.abs(u.Z)*s.Y+math.abs(l.Z)*s.Z)/2
			local lo=cf.Position-h;local hi=cf.Position+h
			table.insert(boxes,{path=path(p),min={lo.X,lo.Y,lo.Z},max={hi.X,hi.Y,hi.Z},wall=string.find(string.lower(p.Name),"wall",1,true)~=nil,solid=p.CanCollide})
		end
	end
end
local function overlap(a,b,k)return math.min(a.max[k],b.max[k])-math.max(a.min[k],b.min[k]) end
local walls={};for _,b in boxes do if b.wall then table.insert(walls,b) end end
local result={coveredGaps={},uncoveredGaps={},note="Full gap AABB coverage by a third solid is recorded; required checker is unchanged."}
for i,a in walls do
	for j=i+1,#walls do
		local b=walls[j]
		if overlap(a,b,2)<=1 then continue end
		local gx=math.max(a.min[1]-b.max[1],b.min[1]-a.max[1]);local gz=math.max(a.min[3]-b.max[3],b.min[3]-a.max[3])
		local axis=if gz<0 and gx>.05 and gx<1.5 and overlap(a,b,3)>.3 then 1 elseif gx<0 and gz>.05 and gz<1.5 and overlap(a,b,1)>.3 then 3 else nil
		if not axis then continue end
		local lo,hi={},{}
		for k=1,3 do
			lo[k]=if k==axis then math.min(a.max[k],b.max[k]) else math.max(a.min[k],b.min[k])
			hi[k]=if k==axis then math.max(a.min[k],b.min[k]) else math.min(a.max[k],b.max[k])
		end
		local covering=nil
		for _,c in boxes do
			if c==a or c==b or not c.solid then continue end
			local contains=true
			for k=1,3 do if c.min[k]>lo[k]+.025 or c.max[k]<hi[k]-.025 then contains=false end end
			if contains then covering=c.path;break end
		end
		local record={a=a.path,b=b.path,min=lo,max=hi,covering=covering}
		table.insert(if covering then result.coveredGaps else result.uncoveredGaps,record)
	end
end
fs.writeFile("verification/M1/geometry_gap_audit.json",serde.encode("json",result,true))
print(`Gap audit: {#result.coveredGaps} completely filled by another solid; {#result.uncoveredGaps} require investigation. Required gate remains authoritative.`)
