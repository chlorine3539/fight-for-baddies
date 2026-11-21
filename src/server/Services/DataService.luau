local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Characters = require(
	ReplicatedStorage:WaitForChild("RojoShared"):WaitForChild("Config"):WaitForChild("Characters")
)

local DataService = {}
local playerStates = {}
local stateRemote

local function makeSnapshot(state)
	local ownedCharacters = {}
	for characterId, isOwned in pairs(state.ownedCharacters) do
		if isOwned then
			table.insert(ownedCharacters, characterId)
		end
	end
	table.sort(ownedCharacters)

	return {
		love = state.love,
		ownedCharacters = ownedCharacters,
		equippedCompanion = state.equippedCompanion,
	}
end

function DataService.Init(remote)
	stateRemote = remote
end

function DataService.Initialize(player)
	if playerStates[player] then
		DataService.Sync(player, "Welcome back!")
		return
	end

	playerStates[player] = {
		love = 0,
		ownedCharacters = {},
		equippedCompanion = nil,
	}
	DataService.Sync(player, "Welcome! Talk to characters to earn Love.")
end

function DataService.Remove(player)
	playerStates[player] = nil
end

function DataService.GetState(player)
	return playerStates[player]
end

function DataService.Sync(player, message)
	local state = playerStates[player]
	if state and stateRemote then
		stateRemote:FireClient(player, makeSnapshot(state), message or "")
	end
end

function DataService.AddLove(player, amount, message)
	local state = playerStates[player]
	if not state then
		return false
	end

	state.love = math.max(0, state.love + amount)
	DataService.Sync(player, message)
	return true
end

function DataService.TryRecruit(player, characterId)
	local state = playerStates[player]
	local character = Characters.ById[characterId]
	if not state or not character then
		return false
	end

	if state.ownedCharacters[characterId] then
		DataService.Sync(player, character.displayName .. " is already in your collection.")
		return false
	end

	if state.love < character.requiredLove then
		local missing = character.requiredLove - state.love
		DataService.Sync(
			player,
			string.format("%s needs %d more Love.", character.displayName, missing)
		)
		return false
	end

	state.love -= character.requiredLove
	state.ownedCharacters[characterId] = true
	state.equippedCompanion = characterId
	DataService.Sync(
		player,
		string.format("%s joined you! They are now your companion.", character.displayName)
	)
	return true
end

function DataService.EquipCompanion(player, characterId)
	local state = playerStates[player]
	local character = Characters.ById[characterId]
	if not state or not character or not state.ownedCharacters[characterId] then
		return false
	end

	state.equippedCompanion = characterId
	DataService.Sync(player, character.displayName .. " is now your companion.")
	return true
end

function DataService.GetAttackDamage(player)
	local state = playerStates[player]
	local damage = 8
	if not state or not state.equippedCompanion then
		return damage
	end

	local character = Characters.ById[state.equippedCompanion]
	if character then
		damage += character.companionDamage
	end
	return damage
end

return DataService
