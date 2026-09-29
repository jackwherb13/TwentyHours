-- Offline test for every prop module in src/ReplicatedStorage/RAC/Props (run: lune run tests/props.spec.luau).
-- Loads each module with Roblox globals from @lune/roblox, builds it at the origin, and checks the contract in
-- docs/BLUEPRINT_SCHEMA.md. Also writes places/props_preview.rbxm (all props in a row) for a quick look in Studio.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local DIR = "src/ReplicatedStorage/RAC/Props"
local MAX_PARTS = 600

local env = {
	Instance = roblox.Instance,
	Vector3 = roblox.Vector3,
	Vector2 = roblox.Vector2,
	CFrame = roblox.CFrame,
	Color3 = roblox.Color3,
	BrickColor = roblox.BrickColor,
	Enum = roblox.Enum,
	UDim2 = roblox.UDim2,
	UDim = roblox.UDim,
	NumberRange = roblox.NumberRange,
	NumberSequence = roblox.NumberSequence,
	ColorSequence = roblox.ColorSequence,
	math = math,
	string = string,
	table = table,
	ipairs = ipairs,
	pairs = pairs,
	type = type,
	typeof = typeof,
	tostring = tostring,
	tonumber = tonumber,
	error = error,
	assert = assert,
	pcall = pcall,
	select = select,
	setmetatable = setmetatable,
	getmetatable = getmetatable,
	unpack = table.unpack,
	print = print,
	warn = print,
}

local cache: { [string]: any } = {}
local function load(name: string): any
	if cache[name] then
		return cache[name]
	end
	local src = fs.readFile(`{DIR}/{name}.luau`)
	local e = table.clone(env) -- plain copy: Luau's GETIMPORT fast path ignores __index on custom environments
	-- Props require siblings as require(script.Parent.X); emulate with a script stub.
	local parent = setmetatable({}, {
		__index = function(_, k)
			return { __module = k }
		end,
	})
	e.script = { Parent = parent }
	e.require = function(ref)
		return load(ref.__module)
	end
	local fn = luau.load(luau.compile(src), { debugName = name, environment = e })
	cache[name] = fn()
	return cache[name]
end

local failures = {}
local count = 0
local all = roblox.Instance.new("Model")
all.Name = "PropsPreview"
local x = 0

for _, file in fs.readDir(DIR) do
	local name = string.match(file, "^(.+)%.luau$")
	if not name or name == "Kit" or string.sub(name, 1, 1) == "_" then
		continue
	end
	count += 1
	local ok, err = pcall(function()
		local m = load(name)
		assert(type(m) == "table", "module must return a table")
		assert(type(m.kind) == "string" and string.match(m.kind, "^[a-z0-9_]+$"), "kind must be snake_case")
		assert(typeof(m.size) == "Vector3", "size must be a Vector3")
		assert(type(m.build) == "function", "build must be a function")
		local model = m.build(roblox.CFrame.new(x + m.size.X / 2, 0, 0), nil)
		assert(model and model.ClassName == "Model", "build must return a Model")
		local parts = 0
		local minY, maxY = math.huge, -math.huge
		local minX, maxX = math.huge, -math.huge
		local minZ, maxZ = math.huge, -math.huge
		for _, d in model:GetDescendants() do
			if d:IsA("BasePart") then
				parts += 1
				assert(d.Anchored, `part {d.Name} is not anchored`)
				local p, s = d.CFrame.Position, d.Size
				local r = math.max(s.X, s.Y, s.Z) / 2
				local h = s.Y / 2
				minY, maxY = math.min(minY, p.Y - h), math.max(maxY, p.Y + h)
				minX, maxX = math.min(minX, p.X - r), math.max(maxX, p.X + r)
				minZ, maxZ = math.min(minZ, p.Z - r), math.max(maxZ, p.Z + r)
			end
		end
		assert(parts > 0, "model has no parts")
		assert(parts <= MAX_PARTS, `too many parts ({parts} > {MAX_PARTS})`)
		assert(minY > -0.6, `prop extends below its base (minY={minY})`)
		assert(maxY <= m.size.Y * 1.2 + 0.5, `prop taller than declared size ({maxY} > {m.size.Y})`)
		local w, dpt = maxX - minX, maxZ - minZ
		assert(w <= math.max(m.size.X, m.size.Z) * 1.5 + 1, `prop wider than declared size ({w})`)
		assert(dpt <= math.max(m.size.X, m.size.Z) * 1.5 + 1, `prop deeper than declared size ({dpt})`)
		model.Parent = all
		x += m.size.X + 3
		print(string.format("ok   %-26s %-24s parts=%3d size=%s", name, m.kind, parts, tostring(m.size)))
	end)
	if not ok then
		table.insert(failures, `{name}: {err}`)
		print(`FAIL {name}: {err}`)
	end
end

if count > 0 then
	fs.writeDir("places")
	fs.writeFile("places/props_preview.rbxm", roblox.serializeModel({ all }))
end
print(`{count} prop modules, {#failures} failures`)
if #failures > 0 then
	process.exit(1)
end
