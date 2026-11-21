local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function getRemote(folder, name)
	local remote = folder:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end
	return remote
end

local remotes = ReplicatedStorage:FindFirstChild("GameRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "GameRemotes"
	remotes.Parent = ReplicatedStorage
end

local stateRemote = getRemote(remotes, "StateUpdate")
local requestStateRemote = getRemote(remotes, "RequestState")
local attackRemote = getRemote(remotes, "Attack")
local equipRemote = getRemote(remotes, "EquipCompanion")

local Services = script.Parent:WaitForChild("Services")
local DataService = require(Services:WaitForChild("DataService"))
local DialogueService = require(Services:WaitForChild("DialogueService"))
local CharacterSpawnService = require(Services:WaitForChild("CharacterSpawnService"))
local CombatService = require(Services:WaitForChild("CombatService"))

DataService.Init(stateRemote)
DialogueService.Init(DataService)

Players.PlayerAdded:Connect(DataService.Initialize)
Players.PlayerRemoving:Connect(function(player)
	DataService.Remove(player)
	DialogueService.RemovePlayer(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	DataService.Initialize(player)
end

requestStateRemote.OnServerEvent:Connect(function(player)
	DataService.Sync(player, "")
end)

equipRemote.OnServerEvent:Connect(function(player, characterId)
	if typeof(characterId) == "string" then
		DataService.EquipCompanion(player, characterId)
	end
end)

CharacterSpawnService.Start(DialogueService.Talk, DialogueService.Recruit)
CombatService.Start(attackRemote, DataService)
