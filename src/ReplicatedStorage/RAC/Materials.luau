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
		base = Enum.Material.Wood,
		color = Color3.fromRGB(227, 202, 157),
		texture = "art/materials/maple_court.png",
		studsPerTile = 4,
		roughness = 0.18,
		assetId = nil,
	},
	terrazzo = {
		base = Enum.Material.Concrete,
		color = Color3.fromRGB(191, 187, 175),
		texture = "art/materials/terrazzo_corridor.png",
		studsPerTile = 4,
		roughness = 0.25,
		assetId = nil,
	},
	porcelain_tile = {
		base = Enum.Material.Marble,
		color = Color3.fromRGB(193, 189, 179),
		texture = "art/materials/porcelain_tile_12x24.png",
		studsPerTile = 4,
		roughness = 0.32,
		assetId = nil,
	},
	carpet_tile = {
		base = Enum.Material.Fabric,
		color = Color3.fromRGB(57, 65, 72),
		texture = "art/materials/carpet_tile_office.png",
		studsPerTile = 4,
		roughness = 0.95,
		assetId = nil,
	},
	rubber = {
		base = Enum.Material.Rubber,
		color = Color3.fromRGB(34, 35, 36),
		texture = "art/materials/rubber_gym_floor.png",
		studsPerTile = 4,
		roughness = 0.9,
		assetId = nil,
	},
	sealed_concrete = {
		base = Enum.Material.Concrete,
		color = Color3.fromRGB(168, 167, 160),
		texture = "art/materials/sealed_concrete.png",
		studsPerTile = 4,
		roughness = 0.45,
		assetId = nil,
	},
	ceramic_tile = {
		base = Enum.Material.CeramicTiles,
		color = Color3.fromRGB(231, 228, 215),
		texture = "art/materials/ceramic_wall_tile.png",
		studsPerTile = 2,
		roughness = 0.22,
		assetId = nil,
	},
	vinyl = {
		base = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(191, 187, 175),
		texture = "art/materials/terrazzo_corridor.png",
		studsPerTile = 4,
		roughness = 0.4,
		assetId = nil,
	},
	painted_cmu = {
		base = Enum.Material.Concrete,
		color = Color3.fromRGB(229, 228, 217),
		texture = "art/materials/painted_cmu.png",
		studsPerTile = 4,
		roughness = 0.7,
		assetId = nil,
	},
	brick = {
		base = Enum.Material.Brick,
		color = Color3.fromRGB(136, 69, 45),
		texture = "art/materials/brick_red.png",
		studsPerTile = 2,
		roughness = 0.9,
		assetId = nil,
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
		assetId = nil,
	},
	precast = {
		base = Enum.Material.Concrete,
		color = Color3.fromRGB(179, 173, 158),
		texture = "art/materials/sealed_concrete.png",
		studsPerTile = 4,
		roughness = 0.8,
		assetId = nil,
	},
	acoustic_ceiling = {
		base = Enum.Material.Plaster,
		color = Color3.fromRGB(236, 235, 225),
		texture = "art/materials/acoustic_ceiling_2x2.png",
		studsPerTile = 2,
		roughness = 0.95,
		assetId = nil,
	},
	mosaic_green = {
		base = Enum.Material.CeramicTiles,
		color = Color3.fromRGB(168, 188, 165),
		texture = "art/materials/mosaic_green.png",
		studsPerTile = 2,
		roughness = 0.2,
		assetId = nil,
	},
}

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

	local assetId = definition.assetId
	if assetId == nil or assetId == "" then
		return
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
	-- Albedo is already colored. White avoids applying the fallback tint twice.
	part.Color = Color3.new(1, 1, 1)
	part.MaterialVariant = variantName
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
}
