-- ========================================================================
-- Client entry point. Controllers own one responsibility each; this script
-- only creates their shared context and dispatches the Notify remote.
-- ========================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local NetFolder = ReplicatedStorage:WaitForChild("SimNet")
local EvInteractNPC = NetFolder:WaitForChild("InteractNPC")
local EvDialogueChoice = NetFolder:WaitForChild("DialogueChoice")
local EvPullupAction = NetFolder:WaitForChild("PullupAction")
local EvTogglePullup = NetFolder:WaitForChild("TogglePullup")
local EvNotify = NetFolder:WaitForChild("Notify")
local EvArenaAttack = NetFolder:WaitForChild("ArenaAttack")
local EvArenaReady = NetFolder:WaitForChild("ArenaReady")

local HUDController = require(script.Parent.Controllers.HUDController)
local WorldEffectsController = require(script.Parent.Controllers.WorldEffectsController)
local CombatController = require(script.Parent.Controllers.CombatController)
local PullupController = require(script.Parent.Controllers.PullupController)
local DialogueController = require(script.Parent.Controllers.DialogueController)

local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "SimulatorHUD"
ScreenGui.ResetOnSpawn = false

local context = {
	Players = Players,
	LocalPlayer = LocalPlayer,
	RunService = RunService,
	TweenService = TweenService,
	UserInputService = UserInputService,
	ScreenGui = ScreenGui,
	EvInteractNPC = EvInteractNPC,
	EvDialogueChoice = EvDialogueChoice,
	EvPullupAction = EvPullupAction,
	EvTogglePullup = EvTogglePullup,
	EvNotify = EvNotify,
	EvArenaAttack = EvArenaAttack,
	EvArenaReady = EvArenaReady,
}

local hud = HUDController.new(context)
context.HUD = hud
local worldEffects = WorldEffectsController.new(context)
local combat = CombatController.new(context)
local pullup = PullupController.new(context)
local dialogue = DialogueController.new(context)
local controllers = { hud, worldEffects, combat, pullup, dialogue }

local notifyConnection = EvNotify.OnClientEvent:Connect(function(kind, message)
	hud:HandleNotify(kind, message)
	combat:HandleNotify(kind, message)
end)

local ancestryConnection
local cleanedUp = false
local function cleanup()
	if cleanedUp then return end
	cleanedUp = true
	notifyConnection:Disconnect()
	if ancestryConnection then
		ancestryConnection:Disconnect()
	end
	for _, controller in ipairs(controllers) do
		controller:Destroy()
	end
	ScreenGui:Destroy()
end

ancestryConnection = script.AncestryChanged:Connect(function(_, parent)
	if parent == nil then
		cleanup()
	end
end)
