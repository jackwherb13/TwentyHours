--!strict
-- Offline Roblox ModuleScript loader shared by regression tests and the real build.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local Loader = {}

function Loader.new(warningHandler: ((any) -> ())?)
	-- GETIMPORT requires concrete globals, rather than metatable fallbacks.
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
	}
	env.warn = warningHandler or warn
	local function node(path)
		return setmetatable({ __path = path }, {
			__index = function(_, key)
				if key == "Parent" then
					return node(string.match(path, "^(.*)/[^/]+$"))
				end
				if key == "FindFirstChild" then
					return function(_, name)
						local child = path .. "/" .. name
						if fs.isDir(child) or fs.isFile(child .. ".luau") then
							return node(child)
						end
						return nil
					end
				end
				if key == "IsA" then
					return function(_, class)
						return class == "ModuleScript" and fs.isFile(path .. ".luau")
					end
				end
				return node(path .. "/" .. key)
			end,
		})
	end
	local cache = {}
	local function load(path)
		if cache[path] then
			return cache[path]
		end
		local e = table.clone(env)
		e.script = node(path)
		e.require = function(ref)
			return load(ref.__path)
		end
		local fn = luau.load(luau.compile(fs.readFile(path .. ".luau")), { debugName = path, environment = e })
		cache[path] = fn()
		return cache[path]
	end
	return { load = load, node = node }
end

return Loader
