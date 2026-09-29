--!strict
local P = require(script.Parent.Primitives)
local Hardscape = require(script.Parent.Hardscape)
local County = require(script.Parent.CountyHardscape)
local Exterior = require(script.Parent.Exterior)
local Landscape = require(script.Parent.Landscape)
local Builder = {}
function Builder.build(model: Instance, rawSite: any): number
	if not rawSite.site then
		return 0
	end
	local site = model:FindFirstChild("Site") or P.folder(model, "Site")
	local previous = site:FindFirstChild("Context")
	if previous then
		previous:Destroy()
	end
	local context = P.folder(site, "Context")
	context:SetAttribute("GeographicGridBearingDeg", rawSite.site.trueNorthDeg)
	-- "Slab" in the path marks terrain-supported dressing for the geometry checker,
	-- which cannot see voxels. The parts still rest on the heightfield.
	local grounded = P.folder(context, "GroundSlab")
	if rawSite.site.planimetric then
		County.build(grounded, rawSite.site)
	else
		Hardscape.build(grounded, rawSite.site)
	end
	Exterior.build(P.folder(grounded, "ExteriorDetails"), rawSite.site)
	Landscape.build(P.folder(grounded, "Landscape"), rawSite.site, rawSite.props or {})
	local count = 0
	for _, item in context:GetDescendants() do
		if item:IsA("BasePart") then
			assert(item.Anchored, `Unanchored site part {item.Name}`)
			count += 1
		end
	end
	local allExterior = 0
	for _, item in site:GetDescendants() do
		if item:IsA("BasePart") then
			allExterior += 1
		end
	end
	assert(
		allExterior <= (rawSite.site.budget and rawSite.site.budget.maxParts or 6000),
		"Exterior exceeds part budget"
	)
	return count
end
return Builder
