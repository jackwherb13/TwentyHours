--!strict
local Parts = require(script.Parent.Parts)
local PropRegistry = {}
-- Dynamic module names are intentionally resolved at runtime, after IsA validation.
local runtimeRequire: any = require
local cache: { [string]: any } = {}

function PropRegistry.build(kind: string, cf: CFrame, opts: { [string]: any }?): Model
	local library = script.Parent.Parent:FindFirstChild("Props")
	local name = string.gsub("_" .. kind, "_([a-z0-9])", string.upper)
	local module = if library then library:FindFirstChild(name) else nil
	if module and module:IsA("ModuleScript") then
		local prop = cache[kind]
		if not prop then
			prop = runtimeRequire(module)
			cache[kind] = prop
		end
		return prop.build(cf, opts)
	end
	warn(`Missing prop kind: {kind}`)
	local model = Instance.new("Model")
	model.Name = "MISSING_" .. kind
	local part = Parts.box(model, model.Name, Vector3.new(2, 2, 2), cf * CFrame.new(0, 1, 0), "steel", false)
	part.Color = Color3.fromRGB(255, 128, 0)
	return model
end
return PropRegistry
