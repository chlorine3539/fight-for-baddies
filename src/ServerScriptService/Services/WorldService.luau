-- ========================================================================
-- WORLD SERVICE
-- The exported Workspace map is the source of truth in edit mode and at runtime.
-- ========================================================================
local Workspace = game:GetService("Workspace")

local WorldService = {}

function WorldService.Start()
	local MapFolder = Workspace:WaitForChild("SimulatorBaseplateMap")
	local SpawnFolder = MapFolder:WaitForChild("StartingPointHub")
	local SpawnPad = SpawnFolder:WaitForChild("StartingPointSpawn")
	local TouchSound = SpawnPad:WaitForChild("SpawnChimeSFX")
	local DecorFolder = MapFolder:WaitForChild("SimulatorTrees")

	local Baseplate = MapFolder:WaitForChild("SimulatorBaseplate")
	local RiverSound = Baseplate:FindFirstChildOfClass("Sound")
	if RiverSound then
		RiverSound.Looped = true
		RiverSound:Play()
	end

	local GYM_POS = Vector3.new(-68, 0, 130)

	local ModFolder = Instance.new("Folder", MapFolder)
	ModFolder.Name = "SimulatorSystems"

	local ArenaFolder = Instance.new("Folder", ModFolder)
	ArenaFolder.Name = "HiddenDuelArena"

	local NPCFolder = Instance.new("Folder", ModFolder)
	NPCFolder.Name = "RoamingNPCs"

	return {
		MapFolder = MapFolder,
		SpawnFolder = SpawnFolder,
		SpawnPad = SpawnPad,
		TouchSound = TouchSound,
		DecorFolder = DecorFolder,
		Baseplate = Baseplate,
		ModFolder = ModFolder,
		ArenaFolder = ArenaFolder,
		NPCFolder = NPCFolder,
		GYM_POS = GYM_POS,
	}
end

return WorldService
