--!strict
-- Apply owned exterior specifications to a copy; never rewrite interior JSON.
local Prepare = {}

local function clone(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for k, v in value do
		result[k] = clone(v)
	end
	return result
end

-- Scene.luau is a JSON long-string. The offline loader has no HttpService.
local function decodeJson(text: string): any
	local i = 1
	local n = #text
	local function skip()
		while i <= n do
			local c = string.sub(text, i, i)
			if c == " " or c == "\n" or c == "\r" or c == "\t" then
				i += 1
			else
				return
			end
		end
	end
	local function parseString(): string
		i += 1
		local out = {}
		while i <= n do
			local c = string.sub(text, i, i)
			if c == '"' then
				i += 1
				return table.concat(out)
			elseif c == "\\" then
				local e = string.sub(text, i + 1, i + 1)
				assert(e ~= "u", "Scene JSON unicode escapes are not decoded")
				local map = { n = "\n", r = "\r", t = "\t", ['"'] = '"', ["\\"] = "\\", ["/"] = "/" }
				table.insert(out, map[e] or e)
				i += 2
			else
				table.insert(out, c)
				i += 1
			end
		end
		error("Unterminated Scene JSON string")
	end
	local parseValue: () -> any
	parseValue = function(): any
		skip()
		local c = string.sub(text, i, i)
		if c == "{" then
			i += 1
			skip()
			local obj = {}
			if string.sub(text, i, i) == "}" then
				i += 1
				return obj
			end
			while true do
				skip()
				assert(string.sub(text, i, i) == '"', "Scene JSON object key")
				local key = parseString()
				skip()
				assert(string.sub(text, i, i) == ":", "Scene JSON colon")
				i += 1
				obj[key] = parseValue()
				skip()
				local sep = string.sub(text, i, i)
				if sep == "}" then
					i += 1
					return obj
				end
				assert(sep == ",", "Scene JSON object comma")
				i += 1
			end
		elseif c == "[" then
			i += 1
			skip()
			local arr = {}
			if string.sub(text, i, i) == "]" then
				i += 1
				return arr
			end
			while true do
				table.insert(arr, parseValue())
				skip()
				local sep = string.sub(text, i, i)
				if sep == "]" then
					i += 1
					return arr
				end
				assert(sep == ",", "Scene JSON array comma")
				i += 1
			end
		elseif c == '"' then
			return parseString()
		elseif c == "t" then
			assert(string.sub(text, i, i + 3) == "true", "Scene JSON true")
			i += 4
			return true
		elseif c == "f" then
			assert(string.sub(text, i, i + 4) == "false", "Scene JSON false")
			i += 5
			return false
		elseif c == "n" then
			assert(string.sub(text, i, i + 3) == "null", "Scene JSON null")
			i += 4
			return nil
		end
		local start = i
		if c == "-" then
			i += 1
		end
		while string.match(string.sub(text, i, i), "%d") do
			i += 1
		end
		if string.sub(text, i, i) == "." then
			i += 1
			while string.match(string.sub(text, i, i), "%d") do
				i += 1
			end
		end
		local exp = string.sub(text, i, i)
		if exp == "e" or exp == "E" then
			i += 1
			local sign = string.sub(text, i, i)
			if sign == "+" or sign == "-" then
				i += 1
			end
			while string.match(string.sub(text, i, i), "%d") do
				i += 1
			end
		end
		local num = tonumber(string.sub(text, start, i - 1))
		assert(num ~= nil, "Scene JSON number")
		return num
	end
	skip()
	return parseValue()
end

-- blueprint/site.json is rewritten without the nested site, and a thick
-- "canopy" roof is put back over the door. Roads, stairs and trees stay in
-- Scene. The entrance wedge is built by Exterior, so that roof is dropped.
local function attachScene(data: any)
	local roofs = {}
	for _, roof in data.site.roofs or {} do
		if roof.type ~= "canopy" then
			table.insert(roofs, roof)
		end
	end
	data.site.roofs = roofs
	local nested = data.site.site
	if not nested or not nested.planimetric then
		local loaded = require(script.Parent.Scene)
		local payload = if type(loaded) == "string" then decodeJson(loaded) else loaded
		data.site.site = payload.site
		if data.site.props == nil then
			data.site.props = payload.props
		end
		nested = data.site.site
	end
	if nested and nested.terrain and data.site.footprint then
		nested.terrain.padPolygons = { clone(data.site.footprint) }
	end
	return nested
end

function Prepare.apply(raw: any): any
	local data = clone(raw)
	local site = attachScene(data)
	if not site or not site.exteriorWallOverrides then
		return data
	end
	for _, level in data.levels do
		if level.level == 1 then
			for _, override in site.exteriorWallOverrides do
				for i, wall in level.walls do
					if wall.id == override.id then
						assert(wall.exterior, "Site override attempted to change an interior wall")
						level.walls[i] = clone(override)
					end
				end
			end
		end
	end
	return data
end
return Prepare
