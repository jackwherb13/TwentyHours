--!strict
-- One stud = one foot. Local PNG paths are provenance, never Roblox content IDs.
-- Template: docs/MATERIALS_TEMPLATE.md. Builder parts use only these keys.
local MaterialService = game:GetService("MaterialService")

export type MaterialDefinition = {
	base: Enum.Material,
	color: Color3,
	texture: string?,
	normal: string?,
	roughnessMap: string?,
	studsPerTile: number,
	roughness: number,
	assetId: string?,
	normalAssetId: string?,
	roughnessAssetId: string?,
}

local definitions: { [string]: MaterialDefinition } = {
	maple = {
		base = Enum.Material.WoodPlanks,
		color = Color3.fromRGB(220, 196, 164),
		texture = "art/materials/pbr/maple_color.png",
		normal = "art/materials/pbr/maple_normal.png",
		roughnessMap = "art/materials/pbr/maple_roughness.png",
		studsPerTile = 8,
		roughness = 0.12,
		assetId = "rbxassetid://115379168184321",
		normalAssetId = nil,
		roughnessAssetId = nil,
	},
	racquetball_wood = {
		base = Enum.Material.WoodPlanks,
		color = Color3.fromRGB(228, 208, 176),
		texture = "art/materials/pbr/racquetball_wood_color.png",
		normal = "art/materials/pbr/racquetball_wood_normal.png",
		roughnessMap = "art/materials/pbr/racquetball_wood_roughness.png",
		studsPerTile = 8,
		roughness = 0.28,
		assetId = nil,
		normalAssetId = nil,
		roughnessAssetId = nil,
	},
	terrazzo = {
		base = Enum.Material.Concrete,
		color = Color3.fromRGB(188, 178, 166),
		texture = "art/materials/pbr/terrazzo_color.png",
		normal = "art/materials/pbr/terrazzo_normal.png",
		roughnessMap = "art/materials/pbr/terrazzo_roughness.png",
		studsPerTile = 6,
		roughness = 0.14,
		assetId = "rbxassetid://82792157361684",
		normalAssetId = nil,
		roughnessAssetId = nil,
	},
	porcelain_tile = {
		base = Enum.Material.Marble,
		color = Color3.fromRGB(186, 174, 160),
		texture = "art/materials/pbr/porcelain_tile_color.png",
		normal = "art/materials/pbr/porcelain_tile_normal.png",
		roughnessMap = "art/materials/pbr/porcelain_tile_roughness.png",
		studsPerTile = 4,
		roughness = 0.22,
		assetId = "rbxassetid://139851902641009",
		normalAssetId = nil,
		roughnessAssetId = nil,
	},
	carpet_tile = {
		base = Enum.Material.Fabric,
		color = Color3.fromRGB(68, 67, 66),
		texture = "art/materials/pbr/carpet_tile_color.png",
		normal = "art/materials/pbr/carpet_tile_normal.png",
		roughnessMap = "art/materials/pbr/carpet_tile_roughness.png",
		studsPerTile = 4,
		roughness = 0.95,
		assetId = "rbxassetid://112971278288310",
		normalAssetId = nil,
		roughnessAssetId = nil,
	},
	rubber = {
		base = Enum.Material.Rubber,
		color = Color3.fromRGB(173, 164, 148),
		texture = "art/materials/pbr/rubber_color.png",
		normal = "art/materials/pbr/rubber_normal.png",
		roughnessMap = "art/materials/pbr/rubber_roughness.png",
		studsPerTile = 4,
		roughness = 0.9,
		assetId = "rbxassetid://77770454739238",
		normalAssetId = nil,
		roughnessAssetId = nil,
	},
	turf = {
		base = Enum.Material.Grass,
		color = Color3.fromRGB(77, 84, 47),
		texture = "art/materials/pbr/turf_color.png",
		normal = "art/materials/pbr/turf_normal.png",
		roughnessMap = "art/materials/pbr/turf_roughness.png",
		studsPerTile = 4,
		roughness = 0.9,
		assetId = nil,
		normalAssetId = nil,
		roughnessAssetId = nil,
	},
	sealed_concrete = {
		base = Enum.Material.Concrete,
		color = Color3.fromRGB(184, 180, 172),
		texture = "art/materials/pbr/sealed_concrete_color.png",
		normal = "art/materials/pbr/sealed_concrete_normal.png",
		roughnessMap = "art/materials/pbr/sealed_concrete_roughness.png",
		studsPerTile = 8,
		roughness = 0.32,
		assetId = "rbxassetid://132402981008958",
		normalAssetId = nil,
		roughnessAssetId = nil,
	},
	ceramic_tile = {
		base = Enum.Material.CeramicTiles,
		color = Color3.fromRGB(232, 224, 210),
		texture = "art/materials/pbr/ceramic_tile_color.png",
		normal = "art/materials/pbr/ceramic_tile_normal.png",
		roughnessMap = "art/materials/pbr/ceramic_tile_roughness.png",
		studsPerTile = 2,
		roughness = 0.22,
		assetId = "rbxassetid://100222343892181",
		normalAssetId = nil,
		roughnessAssetId = nil,
	},
	ceramic_floor_tile = {
		base = Enum.Material.CeramicTiles,
		color = Color3.fromRGB(196, 180, 160),
		texture = "art/materials/pbr/ceramic_floor_tile_color.png",
		normal = "art/materials/pbr/ceramic_floor_tile_normal.png",
		roughnessMap = "art/materials/pbr/ceramic_floor_tile_roughness.png",
		studsPerTile = 2,
		roughness = 0.28,
		assetId = nil,
		normalAssetId = nil,
		roughnessAssetId = nil,
	},
	vinyl = {
		base = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(184, 176, 164),
		texture = "art/materials/pbr/vinyl_color.png",
		normal = "art/materials/pbr/vinyl_normal.png",
		roughnessMap = "art/materials/pbr/vinyl_roughness.png",
		studsPerTile = 4,
		roughness = 0.4,
		assetId = "rbxassetid://82792157361684",
		normalAssetId = nil,
		roughnessAssetId = nil,
	},
	painted_cmu = {
		base = Enum.Material.Concrete,
		color = Color3.fromRGB(210, 206, 200),
		texture = "art/materials/pbr/painted_cmu_color.png",
		normal = "art/materials/pbr/painted_cmu_normal.png",
		roughnessMap = "art/materials/pbr/painted_cmu_roughness.png",
		studsPerTile = 8,
		roughness = 0.7,
		assetId = "rbxassetid://127160626359077",
		normalAssetId = nil,
		roughnessAssetId = nil,
	},
	brick = {
		base = Enum.Material.Brick,
		color = Color3.fromRGB(120, 84, 68),
		texture = "art/materials/pbr/brick_color.png",
		normal = "art/materials/pbr/brick_normal.png",
		roughnessMap = "art/materials/pbr/brick_roughness.png",
		studsPerTile = 4,
		roughness = 0.9,
		assetId = "rbxassetid://102625076659678",
		normalAssetId = nil,
		roughnessAssetId = nil,
	},
	gypsum = {
		base = Enum.Material.Plaster,
		color = Color3.fromRGB(220, 220, 222),
		texture = "art/materials/pbr/gypsum_color.png",
		normal = "art/materials/pbr/gypsum_normal.png",
		roughnessMap = "art/materials/pbr/gypsum_roughness.png",
		studsPerTile = 8,
		roughness = 0.8,
		assetId = nil,
		normalAssetId = nil,
		roughnessAssetId = nil,
	},
	glass = {
		base = Enum.Material.Glass,
		color = Color3.fromRGB(208, 225, 224),
		texture = nil,
		normal = nil,
		roughnessMap = nil,
		studsPerTile = 4,
		roughness = 0.08,
		assetId = nil,
		normalAssetId = nil,
		roughnessAssetId = nil,
	},
	metal_panel = {
		base = Enum.Material.Metal,
		color = Color3.fromRGB(145, 150, 153),
		texture = "art/materials/pbr/metal_panel_color.png",
		normal = "art/materials/pbr/metal_panel_normal.png",
		roughnessMap = "art/materials/pbr/metal_panel_roughness.png",
		studsPerTile = 4,
		roughness = 0.4,
		assetId = "rbxassetid://74124851272829",
		normalAssetId = nil,
		roughnessAssetId = nil,
	},
	precast = {
		base = Enum.Material.Concrete,
		color = Color3.fromRGB(184, 170, 156),
		texture = "art/materials/pbr/precast_color.png",
		normal = "art/materials/pbr/precast_normal.png",
		roughnessMap = "art/materials/pbr/precast_roughness.png",
		studsPerTile = 8,
		roughness = 0.8,
		assetId = "rbxassetid://132402981008958",
		normalAssetId = nil,
		roughnessAssetId = nil,
	},
	acoustic_ceiling = {
		base = Enum.Material.Plaster,
		color = Color3.fromRGB(232, 230, 226),
		texture = "art/materials/pbr/acoustic_ceiling_color.png",
		normal = "art/materials/pbr/acoustic_ceiling_normal.png",
		roughnessMap = "art/materials/pbr/acoustic_ceiling_roughness.png",
		studsPerTile = 2,
		roughness = 0.95,
		assetId = "rbxassetid://125104498841691",
		normalAssetId = nil,
		roughnessAssetId = nil,
	},
	mosaic_green = {
		base = Enum.Material.CeramicTiles,
		color = Color3.fromRGB(168, 176, 162),
		texture = "art/materials/pbr/mosaic_green_color.png",
		normal = "art/materials/pbr/mosaic_green_normal.png",
		roughnessMap = "art/materials/pbr/mosaic_green_roughness.png",
		studsPerTile = 2,
		roughness = 0.2,
		assetId = "rbxassetid://138590772740153",
		normalAssetId = nil,
		roughnessAssetId = nil,
	},
	steel = {
		base = Enum.Material.Metal,
		color = Color3.fromRGB(48, 50, 52),
		texture = "art/materials/pbr/steel_color.png",
		normal = "art/materials/pbr/steel_normal.png",
		roughnessMap = "art/materials/pbr/steel_roughness.png",
		studsPerTile = 4,
		roughness = 0.45,
		assetId = nil,
		normalAssetId = nil,
		roughnessAssetId = nil,
	},
	mullion_aluminum = {
		base = Enum.Material.Metal,
		color = Color3.fromRGB(168, 172, 176),
		texture = "art/materials/pbr/mullion_aluminum_color.png",
		normal = "art/materials/pbr/mullion_aluminum_normal.png",
		roughnessMap = "art/materials/pbr/mullion_aluminum_roughness.png",
		studsPerTile = 4,
		roughness = 0.32,
		assetId = nil,
		normalAssetId = nil,
		roughnessAssetId = nil,
	},
	stainless = {
		base = Enum.Material.Metal,
		color = Color3.fromRGB(180, 184, 186),
		texture = "art/materials/pbr/stainless_color.png",
		normal = "art/materials/pbr/stainless_normal.png",
		roughnessMap = "art/materials/pbr/stainless_roughness.png",
		studsPerTile = 2,
		roughness = 0.22,
		assetId = nil,
		normalAssetId = nil,
		roughnessAssetId = nil,
	},
	door_wood = {
		base = Enum.Material.Wood,
		color = Color3.fromRGB(122, 87, 48),
		texture = "art/materials/pbr/door_wood_color.png",
		normal = "art/materials/pbr/door_wood_normal.png",
		roughnessMap = "art/materials/pbr/door_wood_roughness.png",
		studsPerTile = 4,
		roughness = 0.55,
		assetId = nil,
		normalAssetId = nil,
		roughnessAssetId = nil,
	},
	door_paint = {
		base = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(76, 81, 86),
		texture = "art/materials/pbr/door_paint_color.png",
		normal = "art/materials/pbr/door_paint_normal.png",
		roughnessMap = "art/materials/pbr/door_paint_roughness.png",
		studsPerTile = 4,
		roughness = 0.5,
		assetId = nil,
		normalAssetId = nil,
		roughnessAssetId = nil,
	},
	wood_cap_rail = {
		base = Enum.Material.Wood,
		color = Color3.fromRGB(58, 48, 40),
		texture = "art/materials/pbr/wood_cap_rail_color.png",
		normal = "art/materials/pbr/wood_cap_rail_normal.png",
		roughnessMap = "art/materials/pbr/wood_cap_rail_roughness.png",
		studsPerTile = 4,
		roughness = 0.5,
		assetId = nil,
		normalAssetId = nil,
		roughnessAssetId = nil,
	},
	court_green_paint = {
		base = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(28, 70, 40),
		texture = "art/materials/pbr/court_green_paint_color.png",
		normal = "art/materials/pbr/court_green_paint_normal.png",
		roughnessMap = "art/materials/pbr/court_green_paint_roughness.png",
		studsPerTile = 8,
		roughness = 0.18,
		assetId = nil,
		normalAssetId = nil,
		roughnessAssetId = nil,
	},
	court_gold_paint = {
		base = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(214, 172, 44),
		texture = "art/materials/pbr/court_gold_paint_color.png",
		normal = "art/materials/pbr/court_gold_paint_normal.png",
		roughnessMap = "art/materials/pbr/court_gold_paint_roughness.png",
		studsPerTile = 8,
		roughness = 0.2,
		assetId = nil,
		normalAssetId = nil,
		roughnessAssetId = nil,
	},
	bleacher_green = {
		base = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(30, 35, 31),
		texture = "art/materials/pbr/bleacher_green_color.png",
		normal = "art/materials/pbr/bleacher_green_normal.png",
		roughnessMap = "art/materials/pbr/bleacher_green_roughness.png",
		studsPerTile = 4,
		roughness = 0.55,
		assetId = nil,
		normalAssetId = nil,
		roughnessAssetId = nil,
	},
	bleacher_gold = {
		base = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(160, 108, 32),
		texture = "art/materials/pbr/bleacher_gold_color.png",
		normal = "art/materials/pbr/bleacher_gold_normal.png",
		roughnessMap = "art/materials/pbr/bleacher_gold_roughness.png",
		studsPerTile = 4,
		roughness = 0.5,
		assetId = nil,
		normalAssetId = nil,
		roughnessAssetId = nil,
	},
	sign_paint = {
		base = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(0, 70, 36),
		texture = "art/materials/pbr/sign_paint_color.png",
		normal = "art/materials/pbr/sign_paint_normal.png",
		roughnessMap = "art/materials/pbr/sign_paint_roughness.png",
		studsPerTile = 4,
		roughness = 0.4,
		assetId = nil,
		normalAssetId = nil,
		roughnessAssetId = nil,
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
	if definition.normalAssetId and definition.normalAssetId ~= "" then
		variant.NormalMap = definition.normalAssetId
	end
	if definition.roughnessAssetId and definition.roughnessAssetId ~= "" then
		variant.RoughnessMap = definition.roughnessAssetId
	end
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
	part:SetAttribute("RACRoughness", definition.roughness)
	if key == "maple" or key == "racquetball_wood" then
		part.Reflectance = 0.38
	elseif key == "terrazzo" or key == "court_green_paint" or key == "court_gold_paint" then
		part.Reflectance = 0.22
	elseif key == "porcelain_tile" or key == "ceramic_tile" or key == "mosaic_green" then
		part.Reflectance = 0.14
	elseif key == "sealed_concrete" or key == "stainless" then
		part.Reflectance = 0.1
	else
		part.Reflectance = 0
	end
	ensureVariant(key)
	if definition.assetId ~= nil and definition.assetId ~= "" then
		part.MaterialVariant = "RAC_" .. key
	end
end

return {
	maple = definitions.maple,
	racquetball_wood = definitions.racquetball_wood,
	terrazzo = definitions.terrazzo,
	porcelain_tile = definitions.porcelain_tile,
	carpet_tile = definitions.carpet_tile,
	rubber = definitions.rubber,
	turf = definitions.turf,
	sealed_concrete = definitions.sealed_concrete,
	ceramic_tile = definitions.ceramic_tile,
	ceramic_floor_tile = definitions.ceramic_floor_tile,
	vinyl = definitions.vinyl,
	painted_cmu = definitions.painted_cmu,
	brick = definitions.brick,
	gypsum = definitions.gypsum,
	glass = definitions.glass,
	metal_panel = definitions.metal_panel,
	precast = definitions.precast,
	acoustic_ceiling = definitions.acoustic_ceiling,
	mosaic_green = definitions.mosaic_green,
	steel = definitions.steel,
	mullion_aluminum = definitions.mullion_aluminum,
	stainless = definitions.stainless,
	door_wood = definitions.door_wood,
	door_paint = definitions.door_paint,
	wood_cap_rail = definitions.wood_cap_rail,
	court_green_paint = definitions.court_green_paint,
	court_gold_paint = definitions.court_gold_paint,
	bleacher_green = definitions.bleacher_green,
	bleacher_gold = definitions.bleacher_gold,
	sign_paint = definitions.sign_paint,
	apply = apply,
	install = install,
}
