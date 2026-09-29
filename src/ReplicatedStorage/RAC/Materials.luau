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
		assetId = "rbxassetid://70913626816049",
		normalAssetId = "rbxassetid://109560427488914",
		roughnessAssetId = "rbxassetid://81939913346542",
	},
	racquetball_wood = {
		base = Enum.Material.WoodPlanks,
		color = Color3.fromRGB(228, 208, 176),
		texture = "art/materials/pbr/racquetball_wood_color.png",
		normal = "art/materials/pbr/racquetball_wood_normal.png",
		roughnessMap = "art/materials/pbr/racquetball_wood_roughness.png",
		studsPerTile = 8,
		roughness = 0.28,
		assetId = "rbxassetid://116569853781004",
		normalAssetId = "rbxassetid://135637467228533",
		roughnessAssetId = "rbxassetid://135017228687636",
	},
	terrazzo = {
		base = Enum.Material.Concrete,
		color = Color3.fromRGB(188, 178, 166),
		texture = "art/materials/pbr/terrazzo_color.png",
		normal = "art/materials/pbr/terrazzo_normal.png",
		roughnessMap = "art/materials/pbr/terrazzo_roughness.png",
		studsPerTile = 6,
		roughness = 0.14,
		assetId = "rbxassetid://104770104075728",
		normalAssetId = "rbxassetid://137724133031138",
		roughnessAssetId = "rbxassetid://105749773553007",
	},
	porcelain_tile = {
		base = Enum.Material.Marble,
		color = Color3.fromRGB(186, 174, 160),
		texture = "art/materials/pbr/porcelain_tile_color.png",
		normal = "art/materials/pbr/porcelain_tile_normal.png",
		roughnessMap = "art/materials/pbr/porcelain_tile_roughness.png",
		studsPerTile = 4,
		roughness = 0.22,
		assetId = "rbxassetid://128512379779770",
		normalAssetId = "rbxassetid://101716124313140",
		roughnessAssetId = "rbxassetid://101731058983269",
	},
	carpet_tile = {
		base = Enum.Material.Fabric,
		color = Color3.fromRGB(68, 67, 66),
		texture = "art/materials/pbr/carpet_tile_color.png",
		normal = "art/materials/pbr/carpet_tile_normal.png",
		roughnessMap = "art/materials/pbr/carpet_tile_roughness.png",
		studsPerTile = 4,
		roughness = 0.95,
		assetId = "rbxassetid://74796329562188",
		normalAssetId = "rbxassetid://114587835134293",
		roughnessAssetId = "rbxassetid://71963222800584",
	},
	rubber = {
		base = Enum.Material.Rubber,
		color = Color3.fromRGB(173, 164, 148),
		texture = "art/materials/pbr/rubber_color.png",
		normal = "art/materials/pbr/rubber_normal.png",
		roughnessMap = "art/materials/pbr/rubber_roughness.png",
		studsPerTile = 4,
		roughness = 0.9,
		assetId = "rbxassetid://117692672736298",
		normalAssetId = "rbxassetid://89419544766877",
		roughnessAssetId = "rbxassetid://85867308593380",
	},
	turf = {
		base = Enum.Material.Grass,
		color = Color3.fromRGB(77, 84, 47),
		texture = "art/materials/pbr/turf_color.png",
		normal = "art/materials/pbr/turf_normal.png",
		roughnessMap = "art/materials/pbr/turf_roughness.png",
		studsPerTile = 4,
		roughness = 0.9,
		assetId = "rbxassetid://104411270562423",
		normalAssetId = "rbxassetid://114625498002373",
		roughnessAssetId = "rbxassetid://116745525431241",
	},
	sealed_concrete = {
		base = Enum.Material.Concrete,
		color = Color3.fromRGB(184, 180, 172),
		texture = "art/materials/pbr/sealed_concrete_color.png",
		normal = "art/materials/pbr/sealed_concrete_normal.png",
		roughnessMap = "art/materials/pbr/sealed_concrete_roughness.png",
		studsPerTile = 8,
		roughness = 0.32,
		assetId = "rbxassetid://74678894630315",
		normalAssetId = "rbxassetid://126520269594823",
		roughnessAssetId = "rbxassetid://97810093348285",
	},
	ceramic_tile = {
		base = Enum.Material.CeramicTiles,
		color = Color3.fromRGB(232, 224, 210),
		texture = "art/materials/pbr/ceramic_tile_color.png",
		normal = "art/materials/pbr/ceramic_tile_normal.png",
		roughnessMap = "art/materials/pbr/ceramic_tile_roughness.png",
		studsPerTile = 2,
		roughness = 0.22,
		assetId = "rbxassetid://84618014660326",
		normalAssetId = "rbxassetid://109023032528121",
		roughnessAssetId = "rbxassetid://121074020038747",
	},
	ceramic_floor_tile = {
		base = Enum.Material.CeramicTiles,
		color = Color3.fromRGB(196, 180, 160),
		texture = "art/materials/pbr/ceramic_floor_tile_color.png",
		normal = "art/materials/pbr/ceramic_floor_tile_normal.png",
		roughnessMap = "art/materials/pbr/ceramic_floor_tile_roughness.png",
		studsPerTile = 2,
		roughness = 0.28,
		assetId = "rbxassetid://127415271197447",
		normalAssetId = "rbxassetid://108452738502579",
		roughnessAssetId = "rbxassetid://75346132703728",
	},
	vinyl = {
		base = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(184, 176, 164),
		texture = "art/materials/pbr/vinyl_color.png",
		normal = "art/materials/pbr/vinyl_normal.png",
		roughnessMap = "art/materials/pbr/vinyl_roughness.png",
		studsPerTile = 4,
		roughness = 0.4,
		assetId = "rbxassetid://134234081683536",
		normalAssetId = "rbxassetid://101716124313140",
		roughnessAssetId = "rbxassetid://135656615742126",
	},
	painted_cmu = {
		base = Enum.Material.Concrete,
		color = Color3.fromRGB(210, 206, 200),
		texture = "art/materials/pbr/painted_cmu_color.png",
		normal = "art/materials/pbr/painted_cmu_normal.png",
		roughnessMap = "art/materials/pbr/painted_cmu_roughness.png",
		studsPerTile = 8,
		roughness = 0.7,
		assetId = "rbxassetid://92941580594969",
		normalAssetId = "rbxassetid://74529868373378",
		roughnessAssetId = "rbxassetid://125304131314342",
	},
	brick = {
		base = Enum.Material.Brick,
		color = Color3.fromRGB(120, 84, 68),
		texture = "art/materials/pbr/brick_color.png",
		normal = "art/materials/pbr/brick_normal.png",
		roughnessMap = "art/materials/pbr/brick_roughness.png",
		studsPerTile = 4,
		roughness = 0.9,
		assetId = "rbxassetid://103061109995581",
		normalAssetId = "rbxassetid://106108670193376",
		roughnessAssetId = "rbxassetid://81739995864834",
	},
	gypsum = {
		base = Enum.Material.Plaster,
		color = Color3.fromRGB(220, 220, 222),
		texture = "art/materials/pbr/gypsum_color.png",
		normal = "art/materials/pbr/gypsum_normal.png",
		roughnessMap = "art/materials/pbr/gypsum_roughness.png",
		studsPerTile = 8,
		roughness = 0.8,
		assetId = "rbxassetid://85222956416542",
		normalAssetId = "rbxassetid://105148116380465",
		roughnessAssetId = "rbxassetid://79559158963357",
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
		assetId = "rbxassetid://79043471846642",
		normalAssetId = "rbxassetid://104216962863466",
		roughnessAssetId = "rbxassetid://78997218462553",
	},
	precast = {
		base = Enum.Material.Concrete,
		color = Color3.fromRGB(184, 170, 156),
		texture = "art/materials/pbr/precast_color.png",
		normal = "art/materials/pbr/precast_normal.png",
		roughnessMap = "art/materials/pbr/precast_roughness.png",
		studsPerTile = 8,
		roughness = 0.8,
		assetId = "rbxassetid://99575888977265",
		normalAssetId = "rbxassetid://126520269594823",
		roughnessAssetId = "rbxassetid://123287511894336",
	},
	acoustic_ceiling = {
		base = Enum.Material.Plaster,
		color = Color3.fromRGB(232, 230, 226),
		texture = "art/materials/pbr/acoustic_ceiling_color.png",
		normal = "art/materials/pbr/acoustic_ceiling_normal.png",
		roughnessMap = "art/materials/pbr/acoustic_ceiling_roughness.png",
		studsPerTile = 2,
		roughness = 0.95,
		assetId = "rbxassetid://117197068985658",
		normalAssetId = "rbxassetid://116430134125086",
		roughnessAssetId = "rbxassetid://115085183374551",
	},
	mosaic_green = {
		base = Enum.Material.CeramicTiles,
		color = Color3.fromRGB(168, 176, 162),
		texture = "art/materials/pbr/mosaic_green_color.png",
		normal = "art/materials/pbr/mosaic_green_normal.png",
		roughnessMap = "art/materials/pbr/mosaic_green_roughness.png",
		studsPerTile = 2,
		roughness = 0.2,
		assetId = "rbxassetid://137324631886451",
		normalAssetId = "rbxassetid://77153283278015",
		roughnessAssetId = "rbxassetid://116139697584259",
	},
	steel = {
		base = Enum.Material.Metal,
		color = Color3.fromRGB(48, 50, 52),
		texture = "art/materials/pbr/steel_color.png",
		normal = "art/materials/pbr/steel_normal.png",
		roughnessMap = "art/materials/pbr/steel_roughness.png",
		studsPerTile = 4,
		roughness = 0.45,
		assetId = "rbxassetid://84929693401011",
		normalAssetId = "rbxassetid://130950894419275",
		roughnessAssetId = "rbxassetid://74843447803064",
	},
	mullion_aluminum = {
		base = Enum.Material.Metal,
		color = Color3.fromRGB(168, 172, 176),
		texture = "art/materials/pbr/mullion_aluminum_color.png",
		normal = "art/materials/pbr/mullion_aluminum_normal.png",
		roughnessMap = "art/materials/pbr/mullion_aluminum_roughness.png",
		studsPerTile = 4,
		roughness = 0.32,
		assetId = "rbxassetid://130989339814482",
		normalAssetId = "rbxassetid://130950894419275",
		roughnessAssetId = "rbxassetid://81465425122790",
	},
	stainless = {
		base = Enum.Material.Metal,
		color = Color3.fromRGB(180, 184, 186),
		texture = "art/materials/pbr/stainless_color.png",
		normal = "art/materials/pbr/stainless_normal.png",
		roughnessMap = "art/materials/pbr/stainless_roughness.png",
		studsPerTile = 2,
		roughness = 0.22,
		assetId = "rbxassetid://72990424519590",
		normalAssetId = "rbxassetid://123915024152896",
		roughnessAssetId = "rbxassetid://110299002240225",
	},
	door_wood = {
		base = Enum.Material.Wood,
		color = Color3.fromRGB(122, 87, 48),
		texture = "art/materials/pbr/door_wood_color.png",
		normal = "art/materials/pbr/door_wood_normal.png",
		roughnessMap = "art/materials/pbr/door_wood_roughness.png",
		studsPerTile = 4,
		roughness = 0.55,
		assetId = "rbxassetid://138066740698256",
		normalAssetId = "rbxassetid://87900524753415",
		roughnessAssetId = "rbxassetid://133171298613584",
	},
	door_paint = {
		base = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(76, 81, 86),
		texture = "art/materials/pbr/door_paint_color.png",
		normal = "art/materials/pbr/door_paint_normal.png",
		roughnessMap = "art/materials/pbr/door_paint_roughness.png",
		studsPerTile = 4,
		roughness = 0.5,
		assetId = "rbxassetid://132359873076815",
		normalAssetId = "rbxassetid://133238565681457",
		roughnessAssetId = "rbxassetid://83553921069270",
	},
	wood_cap_rail = {
		base = Enum.Material.Wood,
		color = Color3.fromRGB(58, 48, 40),
		texture = "art/materials/pbr/wood_cap_rail_color.png",
		normal = "art/materials/pbr/wood_cap_rail_normal.png",
		roughnessMap = "art/materials/pbr/wood_cap_rail_roughness.png",
		studsPerTile = 4,
		roughness = 0.5,
		assetId = "rbxassetid://74187080825041",
		normalAssetId = "rbxassetid://87900524753415",
		roughnessAssetId = "rbxassetid://122408873463919",
	},
	court_green_paint = {
		base = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(28, 70, 40),
		texture = "art/materials/pbr/court_green_paint_color.png",
		normal = "art/materials/pbr/court_green_paint_normal.png",
		roughnessMap = "art/materials/pbr/court_green_paint_roughness.png",
		studsPerTile = 8,
		roughness = 0.18,
		assetId = "rbxassetid://125485406957073",
		normalAssetId = "rbxassetid://85560496249540",
		roughnessAssetId = "rbxassetid://102368861586649",
	},
	court_gold_paint = {
		base = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(214, 172, 44),
		texture = "art/materials/pbr/court_gold_paint_color.png",
		normal = "art/materials/pbr/court_gold_paint_normal.png",
		roughnessMap = "art/materials/pbr/court_gold_paint_roughness.png",
		studsPerTile = 8,
		roughness = 0.2,
		assetId = "rbxassetid://75766146048217",
		normalAssetId = "rbxassetid://133238565681457",
		roughnessAssetId = "rbxassetid://113811037210637",
	},
	bleacher_green = {
		base = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(30, 35, 31),
		texture = "art/materials/pbr/bleacher_green_color.png",
		normal = "art/materials/pbr/bleacher_green_normal.png",
		roughnessMap = "art/materials/pbr/bleacher_green_roughness.png",
		studsPerTile = 4,
		roughness = 0.55,
		assetId = "rbxassetid://138466907343999",
		normalAssetId = "rbxassetid://85560496249540",
		roughnessAssetId = "rbxassetid://79872805115337",
	},
	bleacher_gold = {
		base = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(160, 108, 32),
		texture = "art/materials/pbr/bleacher_gold_color.png",
		normal = "art/materials/pbr/bleacher_gold_normal.png",
		roughnessMap = "art/materials/pbr/bleacher_gold_roughness.png",
		studsPerTile = 4,
		roughness = 0.5,
		assetId = "rbxassetid://99197829933984",
		normalAssetId = "rbxassetid://133238565681457",
		roughnessAssetId = "rbxassetid://83553921069270",
	},
	sign_paint = {
		base = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(0, 70, 36),
		texture = "art/materials/pbr/sign_paint_color.png",
		normal = "art/materials/pbr/sign_paint_normal.png",
		roughnessMap = "art/materials/pbr/sign_paint_roughness.png",
		studsPerTile = 4,
		roughness = 0.4,
		assetId = "rbxassetid://130095255286681",
		normalAssetId = "rbxassetid://85560496249540",
		roughnessAssetId = "rbxassetid://128889279786109",
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
