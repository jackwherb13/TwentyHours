--!strict
-- Wall nameplate. Text is a title, never a real person's name.
-- Pivot is the bottom center. The lettered face points -Z.
local Kit = require(script.Parent.Kit)

local Nameplate = {
	kind = "nameplate",
	size = Vector3.new(1.6, 0.45, 0.08),
}

function Nameplate.build(cf: CFrame, opts: { [string]: any }?): Model
	local b = Kit.new("NameplateSign", cf)
	local plate = b:box(
		"Plate",
		Vector3.new(1.5, 0.36, 0.06),
		Kit.at(0, 0.22, 0),
		Color3.fromRGB(24, 28, 26),
		Enum.Material.Metal,
		false
	)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Sign"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 48
	gui.LightInfluence = 0.2
	gui.Parent = plate
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Text = if opts and type(opts.text) == "string" then opts.text else "HEAD COACH"
	label.TextColor3 = Color3.fromRGB(255, 204, 0)
	label.TextScaled = true
	label.Parent = gui
	return b:done()
end

return Nameplate
