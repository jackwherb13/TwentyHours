-- ReplicatedStorage.RAC.Modules.BuildAll
-- The hand-coded blockout is retired. Play instances the RAC built by tools/build_rac.ps1.

local BuildAll = {}

function BuildAll.run()
	local existing = workspace:FindFirstChild("RAC")
	if existing then
		return existing
	end
	warn("RAC blockout is retired. Build the building with tools/build_rac.ps1.")
	return nil
end

return BuildAll
