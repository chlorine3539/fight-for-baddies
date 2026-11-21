local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Characters = require(
	ReplicatedStorage:WaitForChild("RojoShared"):WaitForChild("Config"):WaitForChild("Characters")
)

local DialogueService = {}
local DataService
local lastTalkAt = {}

function DialogueService.Init(dataService)
	DataService = dataService
end

function DialogueService.Talk(player, characterId)
	local character = Characters.ById[characterId]
	if not character then
		return
	end

	lastTalkAt[player] = lastTalkAt[player] or {}
	local now = os.clock()
	local previous = lastTalkAt[player][characterId] or 0
	if now - previous < Characters.TalkCooldownSeconds then
		DataService.Sync(player, "Give the conversation a moment before talking again.")
		return
	end

	lastTalkAt[player][characterId] = now
	local lines = character.dialogue
	local line = lines[math.random(1, #lines)]
	DataService.AddLove(
		player,
		Characters.TalkReward,
		string.format("%s: %s (+%d Love)", character.displayName, line, Characters.TalkReward)
	)
end

function DialogueService.Recruit(player, characterId)
	return DataService.TryRecruit(player, characterId)
end

function DialogueService.RemovePlayer(player)
	lastTalkAt[player] = nil
end

return DialogueService
