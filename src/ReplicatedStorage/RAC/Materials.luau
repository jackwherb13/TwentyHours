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
		color = Color3.fromRGB(216, 185, 138),
		texture = "art/materials/pbr/maple_color.png",
		normal = "art/materials/pbr/maple_normal.png",
		roughnessMap = "art/materials/pbr/maple_roughness.png",
		studsPerTile = 6,
		roughness = 0.2,
		assetId = "rbxassetid://91544688527461",
		normalAssetId = "rbxassetid://109560427488914",
		roughnessAssetId = "rbxassetid://81939913346542",
	},
	racquetball_wood = {
		base = Enum.Material.WoodPlanks,
		color = Color3.fromRGB(210, 186, 158),
		texture = "art/materials/pbr/racquetball_wood_color.png",
		normal = "art/materials/pbr/racquetball_wood_normal.png",
		roughnessMap = "art/materials/pbr/racquetball_wood_roughness.png",
		studsPerTile = 8,
		roughness = 0.22,
		assetId = "rbxassetid://88316057526797",
		normalAssetId = "rbxassetid://135637467228533",
		roughnessAssetId = "rbxassetid://135017228687636",
	},
	terrazzo = {
		base = Enum.Material.Concrete,
		color = Color3.fromRGB(140, 132, 122),
		texture = "art/materials/pbr/terrazzo_color.png",
		normal = "art/materials/pbr/terrazzo_normal.png",
		roughnessMap = "art/materials/pbr/terrazzo_roughness.png",
		studsPerTile = 6,
		roughness = 0.08,
		assetId = "rbxassetid://121202771874633",
		normalAssetId = "rbxassetid://137724133031138",
		roughnessAssetId = "rbxassetid://105749773553007",
	},
	porcelain_tile = {
		base = Enum.Material.Marble,
		color = Color3.fromRGB(176, 166, 154),
		texture = "art/materials/pbr/porcelain_tile_color.png",
		normal = "art/materials/pbr/porcelain_tile_normal.png",
		roughnessMap = "art/materials/pbr/porcelain_tile_roughness.png",
		studsPerTile = 4,
		roughness = 0.2,
		assetId = "rbxassetid://135542603987924",
		normalAssetId = "rbxassetid://132467663009224",
		roughnessAssetId = "rbxassetid://104376880127220",
	},
	carpet_tile = {
		base = Enum.Material.Fabric,
		color = Color3.fromRGB(78, 76, 74),
		texture = "art/materials/pbr/carpet_tile_color.png",
		normal = "art/materials/pbr/carpet_tile_normal.png",
		roughnessMap = "art/materials/pbr/carpet_tile_roughness.png",
		studsPerTile = 4,
		roughness = 0.94,
		assetId = "rbxassetid://126209511063633",
		normalAssetId = "rbxassetid://114587835134293",
		roughnessAssetId = "rbxassetid://71963222800584",
	},
	rubber = {
		base = Enum.Material.Rubber,
		color = Color3.fromRGB(184, 176, 160),
		texture = "art/materials/pbr/rubber_color.png",
		normal = "art/materials/pbr/rubber_normal.png",
		roughnessMap = "art/materials/pbr/rubber_roughness.png",
		studsPerTile = 4,
		roughness = 0.16,
		assetId = "rbxassetid://93777295951772",
		normalAssetId = "rbxassetid://89419544766877",
		roughnessAssetId = "rbxassetid://85867308593380",
	},
	turf = {
		base = Enum.Material.Grass,
		color = Color3.fromRGB(80, 82, 50),
		texture = "art/materials/pbr/turf_color.png",
		normal = "art/materials/pbr/turf_normal.png",
		roughnessMap = "art/materials/pbr/turf_roughness.png",
		studsPerTile = 4,
		roughness = 0.9,
		assetId = "rbxassetid://110434921324962",
		normalAssetId = "rbxassetid://84763308048041",
		roughnessAssetId = "rbxassetid://106388111640017",
	},
	sealed_concrete = {
		base = Enum.Material.Concrete,
		color = Color3.fromRGB(208, 198, 180),
		texture = "art/materials/pbr/sealed_concrete_color.png",
		normal = "art/materials/pbr/sealed_concrete_normal.png",
		roughnessMap = "art/materials/pbr/sealed_concrete_roughness.png",
		studsPerTile = 8,
		roughness = 0.3,
		assetId = "rbxassetid://118939598501809",
		normalAssetId = "rbxassetid://126520269594823",
		roughnessAssetId = "rbxassetid://97810093348285",
	},
	ceramic_tile = {
		base = Enum.Material.CeramicTiles,
		color = Color3.fromRGB(168, 154, 128),
		texture = "art/materials/pbr/ceramic_tile_color.png",
		normal = "art/materials/pbr/ceramic_tile_normal.png",
		roughnessMap = "art/materials/pbr/ceramic_tile_roughness.png",
		studsPerTile = 2,
		roughness = 0.16,
		assetId = "rbxassetid://126184103626009",
		normalAssetId = "rbxassetid://109023032528121",
		roughnessAssetId = "rbxassetid://121074020038747",
	},
	ceramic_floor_tile = {
		base = Enum.Material.CeramicTiles,
		color = Color3.fromRGB(142, 132, 118),
		texture = "art/materials/pbr/ceramic_floor_tile_color.png",
		normal = "art/materials/pbr/ceramic_floor_tile_normal.png",
		roughnessMap = "art/materials/pbr/ceramic_floor_tile_roughness.png",
		studsPerTile = 2,
		roughness = 0.26,
		assetId = "rbxassetid://132181993186941",
		normalAssetId = "rbxassetid://108452738502579",
		roughnessAssetId = "rbxassetid://75346132703728",
	},
	vinyl = {
		base = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(176, 166, 154),
		texture = "art/materials/pbr/vinyl_color.png",
		normal = "art/materials/pbr/vinyl_normal.png",
		roughnessMap = "art/materials/pbr/vinyl_roughness.png",
		studsPerTile = 4,
		roughness = 0.28,
		assetId = "rbxassetid://137016261479465",
		normalAssetId = "rbxassetid://132467663009224",
		roughnessAssetId = "rbxassetid://71157329938638",
	},
	painted_cmu = {
		base = Enum.Material.Concrete,
		color = Color3.fromRGB(200, 196, 188),
		texture = "art/materials/pbr/painted_cmu_color.png",
		normal = "art/materials/pbr/painted_cmu_normal.png",
		roughnessMap = "art/materials/pbr/painted_cmu_roughness.png",
		studsPerTile = 8,
		roughness = 0.72,
		assetId = "rbxassetid://73914010132661",
		normalAssetId = "rbxassetid://74529868373378",
		roughnessAssetId = "rbxassetid://125304131314342",
	},
	brick = {
		base = Enum.Material.Brick,
		color = Color3.fromRGB(110, 68, 56),
		texture = "art/materials/pbr/brick_color.png",
		normal = "art/materials/pbr/brick_normal.png",
		roughnessMap = "art/materials/pbr/brick_roughness.png",
		studsPerTile = 4,
		roughness = 0.88,
		assetId = "rbxassetid://71061751380163",
		normalAssetId = "rbxassetid://106108670193376",
		roughnessAssetId = "rbxassetid://81739995864834",
	},
	gypsum = {
		base = Enum.Material.Plaster,
		color = Color3.fromRGB(200, 200, 202),
		texture = "art/materials/pbr/gypsum_color.png",
		normal = "art/materials/pbr/gypsum_normal.png",
		roughnessMap = "art/materials/pbr/gypsum_roughness.png",
		studsPerTile = 8,
		roughness = 0.8,
		assetId = "rbxassetid://83085234647184",
		normalAssetId = "rbxassetid://105148116380465",
		roughnessAssetId = "rbxassetid://79559158963357",
	},
	glass = {
		base = Enum.Material.Glass,
		color = Color3.fromRGB(40, 48, 52),
		texture = nil,
		normal = nil,
		roughnessMap = nil,
		studsPerTile = 4,
		roughness = 0.06,
		assetId = nil,
		normalAssetId = nil,
		roughnessAssetId = nil,
	},
	metal_panel = {
		base = Enum.Material.Metal,
		color = Color3.fromRGB(136, 142, 150),
		texture = "art/materials/pbr/metal_panel_color.png",
		normal = "art/materials/pbr/metal_panel_normal.png",
		roughnessMap = "art/materials/pbr/metal_panel_roughness.png",
		studsPerTile = 4,
		roughness = 0.36,
		assetId = "rbxassetid://119546250161432",
		normalAssetId = "rbxassetid://130950894419275",
		roughnessAssetId = "rbxassetid://78997218462553",
	},
	precast = {
		base = Enum.Material.Concrete,
		color = Color3.fromRGB(178, 167, 157),
		texture = "art/materials/pbr/precast_color.png",
		normal = "art/materials/pbr/precast_normal.png",
		roughnessMap = "art/materials/pbr/precast_roughness.png",
		studsPerTile = 8,
		roughness = 0.78,
		assetId = "rbxassetid://140362294900296",
		normalAssetId = "rbxassetid://126520269594823",
		roughnessAssetId = "rbxassetid://103731185018538",
	},
	acoustic_ceiling = {
		base = Enum.Material.Plaster,
		color = Color3.fromRGB(186, 184, 178),
		texture = "art/materials/pbr/acoustic_ceiling_color.png",
		normal = "art/materials/pbr/acoustic_ceiling_normal.png",
		roughnessMap = "art/materials/pbr/acoustic_ceiling_roughness.png",
		studsPerTile = 2,
		roughness = 0.94,
		assetId = "rbxassetid://74504063907005",
		normalAssetId = "rbxassetid://96924420037546",
		roughnessAssetId = "rbxassetid://110866543862913",
	},
	mosaic_green = {
		base = Enum.Material.CeramicTiles,
		color = Color3.fromRGB(134, 138, 128),
		texture = "art/materials/pbr/mosaic_green_color.png",
		normal = "art/materials/pbr/mosaic_green_normal.png",
		roughnessMap = "art/materials/pbr/mosaic_green_roughness.png",
		studsPerTile = 2,
		roughness = 0.2,
		assetId = "rbxassetid://116682509188652",
		normalAssetId = "rbxassetid://77153283278015",
		roughnessAssetId = "rbxassetid://116139697584259",
	},
	steel = {
		base = Enum.Material.Metal,
		color = Color3.fromRGB(208, 204, 198),
		texture = "art/materials/pbr/steel_color.png",
		normal = "art/materials/pbr/steel_normal.png",
		roughnessMap = "art/materials/pbr/steel_roughness.png",
		studsPerTile = 4,
		roughness = 0.5,
		assetId = "rbxassetid://124080354635515",
		normalAssetId = "rbxassetid://130950894419275",
		roughnessAssetId = "rbxassetid://74843447803064",
	},
	mullion_aluminum = {
		base = Enum.Material.Metal,
		color = Color3.fromRGB(22, 22, 24),
		texture = "art/materials/pbr/mullion_aluminum_color.png",
		normal = "art/materials/pbr/mullion_aluminum_normal.png",
		roughnessMap = "art/materials/pbr/mullion_aluminum_roughness.png",
		studsPerTile = 4,
		roughness = 0.28,
		assetId = "rbxassetid://79237438772328",
		normalAssetId = "rbxassetid://96715336119497",
		roughnessAssetId = "rbxassetid://120577523437453",
	},
	stainless = {
		base = Enum.Material.Metal,
		color = Color3.fromRGB(196, 196, 192),
		texture = "art/materials/pbr/stainless_color.png",
		normal = "art/materials/pbr/stainless_normal.png",
		roughnessMap = "art/materials/pbr/stainless_roughness.png",
		studsPerTile = 2,
		roughness = 0.18,
		assetId = "rbxassetid://91470726429340",
		normalAssetId = "rbxassetid://110244039569304",
		roughnessAssetId = "rbxassetid://134128261887917",
	},
	door_wood = {
		base = Enum.Material.Wood,
		color = Color3.fromRGB(198, 188, 177),
		texture = "art/materials/pbr/door_wood_color.png",
		normal = "art/materials/pbr/door_wood_normal.png",
		roughnessMap = "art/materials/pbr/door_wood_roughness.png",
		studsPerTile = 4,
		roughness = 0.42,
		assetId = "rbxassetid://75146815085481",
		normalAssetId = "rbxassetid://87900524753415",
		roughnessAssetId = "rbxassetid://133171298613584",
	},
	door_paint = {
		base = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(100, 98, 86),
		texture = "art/materials/pbr/door_paint_color.png",
		normal = "art/materials/pbr/door_paint_normal.png",
		roughnessMap = "art/materials/pbr/door_paint_roughness.png",
		studsPerTile = 4,
		roughness = 0.38,
		assetId = "rbxassetid://136989871078767",
		normalAssetId = "rbxassetid://133238565681457",
		roughnessAssetId = "rbxassetid://83553921069270",
	},
	wood_cap_rail = {
		base = Enum.Material.Wood,
		color = Color3.fromRGB(186, 160, 120),
		texture = "art/materials/pbr/wood_cap_rail_color.png",
		normal = "art/materials/pbr/wood_cap_rail_normal.png",
		roughnessMap = "art/materials/pbr/wood_cap_rail_roughness.png",
		studsPerTile = 4,
		roughness = 0.36,
		assetId = "rbxassetid://92874150765104",
		normalAssetId = "rbxassetid://87900524753415",
		roughnessAssetId = "rbxassetid://122408873463919",
	},
	court_green_paint = {
		base = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(22, 52, 36),
		texture = "art/materials/pbr/court_green_paint_color.png",
		normal = "art/materials/pbr/court_green_paint_normal.png",
		roughnessMap = "art/materials/pbr/court_green_paint_roughness.png",
		studsPerTile = 8,
		roughness = 0.14,
		assetId = "rbxassetid://130890933128176",
		normalAssetId = "rbxassetid://85560496249540",
		roughnessAssetId = "rbxassetid://102368861586649",
	},
	court_gold_paint = {
		base = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(198, 176, 80),
		texture = "art/materials/pbr/court_gold_paint_color.png",
		normal = "art/materials/pbr/court_gold_paint_normal.png",
		roughnessMap = "art/materials/pbr/court_gold_paint_roughness.png",
		studsPerTile = 8,
		roughness = 0.16,
		assetId = "rbxassetid://81202424403635",
		normalAssetId = "rbxassetid://133238565681457",
		roughnessAssetId = "rbxassetid://113811037210637",
	},
	bleacher_green = {
		base = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(32, 42, 38),
		texture = "art/materials/pbr/bleacher_green_color.png",
		normal = "art/materials/pbr/bleacher_green_normal.png",
		roughnessMap = "art/materials/pbr/bleacher_green_roughness.png",
		studsPerTile = 4,
		roughness = 0.48,
		assetId = "rbxassetid://94239505522923",
		normalAssetId = "rbxassetid://85560496249540",
		roughnessAssetId = "rbxassetid://79872805115337",
	},
	bleacher_gold = {
		base = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(196, 148, 42),
		texture = "art/materials/pbr/bleacher_gold_color.png",
		normal = "art/materials/pbr/bleacher_gold_normal.png",
		roughnessMap = "art/materials/pbr/bleacher_gold_roughness.png",
		studsPerTile = 4,
		roughness = 0.42,
		assetId = "rbxassetid://86868049965059",
		normalAssetId = "rbxassetid://133238565681457",
		roughnessAssetId = "rbxassetid://83553921069270",
	},
	sign_paint = {
		base = Enum.Material.SmoothPlastic,
		color = Color3.fromRGB(50, 62, 56),
		texture = "art/materials/pbr/sign_paint_color.png",
		normal = "art/materials/pbr/sign_paint_normal.png",
		roughnessMap = "art/materials/pbr/sign_paint_roughness.png",
		studsPerTile = 4,
		roughness = 0.36,
		assetId = "rbxassetid://74747854863990",
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
		-- Rewriting ColorMap on a place-authored variant makes Play re-upload the texture pack and fail.
		if variant.StudsPerTile ~= definition.studsPerTile then
			variant.StudsPerTile = definition.studsPerTile
		end
	else
		variant = Instance.new("MaterialVariant")
		variant.Name = variantName
		variant.BaseMaterial = definition.base
		variant.ColorMap = assetId
		if definition.normalAssetId and definition.normalAssetId ~= "" then
			variant.NormalMap = definition.normalAssetId
		end
		if definition.roughnessAssetId and definition.roughnessAssetId ~= "" then
			variant.RoughnessMap = definition.roughnessAssetId
		end
		variant.StudsPerTile = definition.studsPerTile
		variant.Parent = MaterialService
	end
	variant:SetAttribute("RACRoughness", definition.roughness)
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
	if definition.assetId ~= nil and definition.assetId ~= "" then
		part.Color = Color3.fromRGB(254, 254, 254)
	else
		part.Color = definition.color
	end
	part:SetAttribute("RACMaterial", key)
	part:SetAttribute("RACTexturePath", definition.texture)
	part:SetAttribute("RACStudsPerTile", definition.studsPerTile)
	part:SetAttribute("RACRoughness", definition.roughness)
	if key == "maple" or key == "court_green_paint" or key == "court_gold_paint" then
		part.Reflectance = 0.1
	elseif key == "racquetball_wood" then
		part.Reflectance = 0.08
	elseif key == "terrazzo" or key == "rubber" then
		part.Reflectance = 0.28
	elseif
		key == "porcelain_tile"
		or key == "vinyl"
		or key == "ceramic_tile"
		or key == "mosaic_green"
		or key == "stainless"
		or key == "sealed_concrete"
	then
		part.Reflectance = 0.12
	elseif key == "glass" then
		part.Reflectance = 0.35
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
