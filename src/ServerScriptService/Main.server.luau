-- ========================================================================
-- SERVER GAMEPLAY ENTRY POINT
-- Owns the SimNet remote contract and starts the focused server services.
-- The exported Workspace map is the source of truth in edit mode and at runtime.
-- ========================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = script:WaitForChild("Services")
local WorldService = require(Services:WaitForChild("WorldService"))
local PlayerDataService = require(Services:WaitForChild("PlayerDataService"))
local SecretService = require(Services:WaitForChild("SecretService"))
local PullupService = require(Services:WaitForChild("PullupService"))
local ArenaService = require(Services:WaitForChild("ArenaService"))
local NPCService = require(Services:WaitForChild("NPCService"))

-- 9. AĞLAR (REMOTE EVENTS) — names and count are the client contract.
local oldNet = ReplicatedStorage:FindFirstChild("SimNet")
if oldNet then oldNet:Destroy() end

local NetFolder = Instance.new("Folder", ReplicatedStorage)
NetFolder.Name = "SimNet"

local EvInteractNPC = Instance.new("RemoteEvent", NetFolder)
EvInteractNPC.Name = "InteractNPC"

local EvDialogueChoice = Instance.new("RemoteEvent", NetFolder)
EvDialogueChoice.Name = "DialogueChoice"

local EvPullupAction = Instance.new("RemoteEvent", NetFolder)
EvPullupAction.Name = "PullupAction"

local EvTogglePullup = Instance.new("RemoteEvent", NetFolder)
EvTogglePullup.Name = "TogglePullup"

local EvNotify = Instance.new("RemoteEvent", NetFolder)
EvNotify.Name = "Notify"

local EvArenaAttack = Instance.new("RemoteEvent", NetFolder)
EvArenaAttack.Name = "ArenaAttack"

local EvArenaReady = Instance.new("RemoteEvent", NetFolder)
EvArenaReady.Name = "ArenaReady"

local context = {
	EvInteractNPC = EvInteractNPC,
	EvDialogueChoice = EvDialogueChoice,
	EvPullupAction = EvPullupAction,
	EvTogglePullup = EvTogglePullup,
	EvNotify = EvNotify,
	EvArenaAttack = EvArenaAttack,
	EvArenaReady = EvArenaReady,
	savedHumanoidMovement = {},

	WorldService = WorldService,
	PlayerDataService = PlayerDataService,
	SecretService = SecretService,
	PullupService = PullupService,
	ArenaService = ArenaService,
	NPCService = NPCService,
}

-- The map is the source of truth: wait for its exported children first.
local world = WorldService.Start()
for key, value in pairs(world) do
	context[key] = value
end

-- Cross-wire before any service can receive a client request.
NPCService.SetArenaService(ArenaService)

PlayerDataService.Start(context)
SecretService.Start(context)
PullupService.Start(context)
ArenaService.Start(context)
NPCService.Start(context)

Players.PlayerRemoving:Connect(function(player)
	ArenaService.FinishForPlayer(player)
	PullupService.Cleanup(player)
	NPCService.Cleanup(player)
	PlayerDataService.Cleanup(player)
end)
