--!strict
-- One stud = one foot. Local PNG paths are provenance, never Roblox content IDs.
local MaterialService = game:GetService("MaterialService")

export type MaterialDefinition = {
	base: Enum.Material,
	color: Color3,
	texture: string?,
	studsPerTile: number,
	roughness: number,
	assetId: string?,
}

local definitions: { [string]: MaterialDefinition } = {
	maple = {
		base = Enum.Material.WoodPlanks,
		color = Color3.fromRGB(232, 204, 156),
		texture = "art/materials/maple_court.png",
		studsPerTile = 18,
		roughness = 0.12,
		assetId = "rbxassetid://115379168184321",
	},
	terrazzo = {
		base = Enum.Material.Concrete,
		color = Color3.fromRGB(198, 190, 178),
		texture = "art/materials/terrazzo_corridor.png",
		studsPerTile = 8,
		roughness = 0.14,
		assetId = "rbxassetid://82792157361684",
	},
	porcelain_tile = {
		base = Enum.Material.Marble,
		color = Color3.fromRGB(186, 178, 168),
		texture = "art/materials/porcelain_tile_12x24.png",
		studsPerTile = 8,
		roughness = 0.22,
		assetId = "rbxassetid://139851902641009",
	},
	carpet_tile = {
		base = Enum.Material.Fabric,
		color = Color3.fromRGB(68, 70, 74),
		texture = "art/materials/carpet_tile_office.png",
		studsPerTile = 4,
		roughness = 0.95,
		assetId = "rbxassetid://112971278288310",
	},
	rubber = {
		base = Enum.Material.Rubber,
		color = Color3.fromRGB(34, 35, 36),
		texture = "art/materials/rubber_gym_floor.png",
		studsPerTile = 4,
		roughness = 0.9,
		assetId = "rbxassetid://77770454739238",
	},
	sealed_concrete = {
		base = Enum.Material.Concrete,
		color = Color3.fromRGB(176, 174, 166),
		texture = "art/materials/sealed_concrete.png",
		studsPerTile = 8,
		roughness = 0.32,
		assetId = "rbxassetid://132402981008958",
	},
	ceramic_tile = {
		base = Enum.Material.CeramicTiles,
		color = Color3.fromRGB(231, 228, 215),
		texture = "art/materials/ceramic_wall_tile.png",
		studsPerTile = 2,
		roughness = 0.22,
		assetId = "rbxassetid://100222343892181",
	},
	vinyl = {
		base = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(184, 176, 164),
		texture = "art/materials/terrazzo_corridor.png",
		studsPerTile = 4,
		roughness = 0.4,
		assetId = "rbxassetid://82792157361684",
	},
	painted_cmu = {
		base = Enum.Material.Concrete,
		color = Color3.fromRGB(232, 230, 224),
		texture = "art/materials/painted_cmu.png",
		studsPerTile = 4,
		roughness = 0.7,
		assetId = "rbxassetid://127160626359077",
	},
	brick = {
		base = Enum.Material.Brick,
		color = Color3.fromRGB(136, 69, 45),
		texture = "art/materials/brick_red.png",
		studsPerTile = 2,
		roughness = 0.9,
		assetId = "rbxassetid://102625076659678",
	},
	gypsum = {
		base = Enum.Material.Plaster,
		color = Color3.fromRGB(235, 233, 223),
		texture = nil,
		studsPerTile = 4,
		roughness = 0.8,
		assetId = nil,
	},
	glass = {
		base = Enum.Material.Glass,
		color = Color3.fromRGB(208, 225, 224),
		texture = nil,
		studsPerTile = 4,
		roughness = 0.08,
		assetId = nil,
	},
	metal_panel = {
		base = Enum.Material.Metal,
		color = Color3.fromRGB(145, 150, 153),
		texture = "art/materials/metal_panel_grey.png",
		studsPerTile = 4,
		roughness = 0.4,
		assetId = "rbxassetid://74124851272829",
	},
	precast = {
		base = Enum.Material.Concrete,
		color = Color3.fromRGB(179, 173, 158),
		texture = "art/materials/sealed_concrete.png",
		studsPerTile = 4,
		roughness = 0.8,
		assetId = "rbxassetid://132402981008958",
	},
	acoustic_ceiling = {
		base = Enum.Material.Plaster,
		color = Color3.fromRGB(236, 235, 225),
		texture = "art/materials/acoustic_ceiling_2x2.png",
		studsPerTile = 2,
		roughness = 0.95,
		assetId = "rbxassetid://125104498841691",
	},
	mosaic_green = {
		base = Enum.Material.CeramicTiles,
		color = Color3.fromRGB(168, 188, 165),
		texture = "art/materials/mosaic_green.png",
		studsPerTile = 2,
		roughness = 0.2,
		assetId = "rbxassetid://138590772740153",
	},
}

local function ensureVariant(key: string): string?
	local definition = definitions[key]
	local assetId = definition.assetId
	if assetId == nil or assetId == "" then
		return nil
	end
	local variantName = "RAC_" .. key
	local existing = MaterialService:FindFirstChild(variantName)
	assert(existing == nil or existing:IsA("MaterialVariant"), "RAC material name collision: " .. variantName)
	local variant: MaterialVariant
	if existing and existing:IsA("MaterialVariant") then
		variant = existing
	else
		variant = Instance.new("MaterialVariant")
		variant.Name = variantName
	end
	variant.BaseMaterial = definition.base
	variant.ColorMap = assetId
	variant.StudsPerTile = definition.studsPerTile
	variant:SetAttribute("RACRoughness", definition.roughness)
	variant.Parent = MaterialService
	return variantName
end

local function install()
	for key in definitions do
		ensureVariant(key)
	end
end

local function apply(part: BasePart, key: string)
	local definition = definitions[key]
	assert(definition ~= nil, "Unknown RAC material: " .. key)
	part.Material = definition.base
	part.MaterialVariant = ""
	part.Color = definition.color
	part:SetAttribute("RACMaterial", key)
	part:SetAttribute("RACTexturePath", definition.texture)
	part:SetAttribute("RACStudsPerTile", definition.studsPerTile)
	-- Scalar metadata for the Studio PBR workflow; Roblox needs a roughness map.
	part:SetAttribute("RACRoughness", definition.roughness)
	-- Gloss by finish: maple court, terrazzo corridors, porcelain lobby.
	if key == "maple" then
		part.Reflectance = 0.38
	elseif key == "terrazzo" then
		part.Reflectance = 0.22
	elseif key == "porcelain_tile" then
		part.Reflectance = 0.14
	elseif key == "sealed_concrete" then
		part.Reflectance = 0.1
	else
		part.Reflectance = 0
	end
	-- Rojo syncs RAC_* into MaterialService. Naming the variant here is enough;
	-- creating one from a play script lacks the Plugin capability.
	if definition.assetId ~= nil and definition.assetId ~= "" then
		part.MaterialVariant = "RAC_" .. key
	end
end

-- Entries remain mutable so the Studio owner can supply uploaded asset IDs.
return {
	maple = definitions.maple,
	terrazzo = definitions.terrazzo,
	porcelain_tile = definitions.porcelain_tile,
	carpet_tile = definitions.carpet_tile,
	rubber = definitions.rubber,
	sealed_concrete = definitions.sealed_concrete,
	ceramic_tile = definitions.ceramic_tile,
	vinyl = definitions.vinyl,
	painted_cmu = definitions.painted_cmu,
	brick = definitions.brick,
	gypsum = definitions.gypsum,
	glass = definitions.glass,
	metal_panel = definitions.metal_panel,
	precast = definitions.precast,
	acoustic_ceiling = definitions.acoustic_ceiling,
	mosaic_green = definitions.mosaic_green,
	apply = apply,
	install = install,
}
