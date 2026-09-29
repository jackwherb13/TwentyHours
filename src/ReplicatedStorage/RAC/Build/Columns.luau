--!strict
local Blueprint = require(script.Parent.Blueprint)
local Parts = require(script.Parent.Parts)
local Columns = {}
function Columns.build(parent: Instance, level: Blueprint.Level)
	for _, c in level.columns do
		Parts.box(
			parent,
			c.id,
			Vector3.new(c.size[1], c.height, c.size[2]),
			CFrame.new(c.at[1], level.elevation + c.height / 2, c.at[2]),
			"painted_cmu"
		)
	end
end
return Columns
