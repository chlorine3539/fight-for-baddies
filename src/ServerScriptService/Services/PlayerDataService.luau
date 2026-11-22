-- ========================================================================
-- PLAYER DATA SERVICE
-- Leaderstats, attributes, spawn placement, saved movement state, and
-- versioned Power/Love persistence. All DataStore work stays on the server.
-- ========================================================================
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local PlayerDataSchema = require(script.Parent.Parent.Logic.PlayerDataSchema)

local PlayerDataService = {}

-- Deliberately isolated from any production DataStore. Rename only after an
-- isolated test-place round trip confirms the schema and save policy.
local DATA_STORE_NAME = "FightForBaddies_PlayerData_Test"
local AUTOSAVE_INTERVAL = 120
local MAX_ATTEMPTS = 4
local BACKOFF = { 0.5, 1, 2 }
local SHUTDOWN_GRACE_SECONDS = 8

-- Studio is allowed to fall back to session-only play when DataStore access is
-- unavailable. Published servers keep the strict restricted-state policy.
local STUDIO_SESSION_FALLBACK = RunService:IsStudio()

local contextRef
local dataStore
local sessions = {}
local shuttingDown = false

local function warnFor(player, label, err)
	warn("[PlayerData] " .. label .. " for " .. tostring(player and player.UserId or "?") .. ": " .. tostring(err))
end

local function notifyRestricted(player)
	if contextRef and contextRef.EvNotify then
		contextRef.EvNotify:FireClient(player, "DataRestricted", "İlerleme verisi yüklenemedi. Lütfen tekrar katılın.")
	end
end

local function retry(label, player, fn)
	local lastErr
	for attempt = 1, MAX_ATTEMPTS do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastErr = result
		if attempt < MAX_ATTEMPTS then
			task.wait(BACKOFF[attempt])
		end
	end
	warnFor(player, label, lastErr)
	return false, lastErr
end

local function setRestricted(player)
	player:SetAttribute("DataLoaded", false)
	player:SetAttribute("DataRestricted", true)
	player:SetAttribute("DataPersistent", false)
	notifyRestricted(player)
end

local function allowStudioSessionOnly(player, state, label, err)
	state.sessionOnly = true
	state.loaded = false
	player:SetAttribute("DataLoaded", false)
	player:SetAttribute("DataRestricted", false)
	player:SetAttribute("DataPersistent", false)
	if err then
		warnFor(player, label, err)
	end
	if contextRef and contextRef.EvNotify then
		contextRef.EvNotify:FireClient(player, "DataSessionOnly", "Veri kaydı kullanılamıyor; ilerleme bu oturumda geçerli.")
	end
end

local function placeCharacterAtSpawn(character, spawnPad)
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if hrp and spawnPad and spawnPad.Parent then
		task.wait(0.05)
		hrp.CFrame = spawnPad.CFrame + Vector3.new(0, 4, 0)
	end
end

local function getLeaderstats(player)
	local ls = player:FindFirstChild("leaderstats")
	if not ls then
		return nil, nil
	end
	return ls:FindFirstChild("Power"), ls:FindFirstChild("Love")
end

local function snapshot(player)
	local power, love = getLeaderstats(player)
	local data = PlayerDataSchema.fromValues(power and power.Value, love and love.Value)
	if not data then
		warnFor(player, "invalid snapshot", "Power/Love values failed validation")
		return nil
	end
	return data
end

local function loadPlayer(player, state)
	if not dataStore then
		if STUDIO_SESSION_FALLBACK then
			allowStudioSessionOnly(player, state, "DataStoreService unavailable", "isolated Studio session")
		else
			setRestricted(player)
		end
		return
	end

	local key = PlayerDataSchema.keyFor(player.UserId)
	if not key then
		if STUDIO_SESSION_FALLBACK then
			allowStudioSessionOnly(player, state, "invalid key", player.UserId)
		else
			setRestricted(player)
		end
		return
	end

	local ok, result = retry("load", player, function()
		return dataStore:GetAsync(key)
	end)
	if not ok then
		if STUDIO_SESSION_FALLBACK then
			allowStudioSessionOnly(player, state, "load failed", result)
		else
			setRestricted(player)
		end
		return
	end

	local data
	if result == nil then
		data = PlayerDataSchema.newDefault()
	else
		data = PlayerDataSchema.deserialize(result)
	end
	if not data then
		if STUDIO_SESSION_FALLBACK then
			allowStudioSessionOnly(player, state, "invalid stored data", "schema rejected stored value")
		else
			setRestricted(player)
		end
		return
	end

	local power, love = getLeaderstats(player)
	if power then
		power.Value = data.power
	end
	if love then
		love.Value = data.love
	end

	state.loaded = true
	state.dirty = false
	player:SetAttribute("DataLoaded", true)
	player:SetAttribute("DataRestricted", false)
	player:SetAttribute("DataPersistent", true)
end

local function savePlayer(player, state)
	if not state or not state.loaded or not dataStore then
		return
	end
	if state.saving then
		state.pending = true
		return
	end
	if not state.dirty then
		return
	end

	local key = PlayerDataSchema.keyFor(player.UserId)
	local data = snapshot(player)
	if not key or not data then
		return
	end

	state.saving = true
	state.dirty = false

	task.spawn(function()
		local ok = retry("save", player, function()
			dataStore:UpdateAsync(key, function(current)
				return PlayerDataSchema.applySave(current, data)
			end)
		end)
		state.saving = false
		if ok then
			state.lastSaved = os.clock()
		end

		if state.pending then
			state.pending = false
			state.dirty = true
			if state.loaded then
				task.spawn(savePlayer, player, state)
			end
		elseif state.leaving then
			sessions[player] = nil
		end
	end)
end

local function setupPlayer(player)
	if sessions[player] then
		return
	end

	local context = contextRef
	local SpawnPad = context.SpawnPad
	local savedHumanoidMovement = context.savedHumanoidMovement
	local state = { loaded = false, sessionOnly = false, dirty = false, saving = false, pending = false, leaving = false, connections = {} }
	sessions[player] = state

	local ls = player:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("Folder", player)
		ls.Name = "leaderstats"
	end
	local power = ls:FindFirstChild("Power")
	if not power then
		power = Instance.new("NumberValue", ls)
		power.Name = "Power"
		power.Value = 0
	end
	local love = ls:FindFirstChild("Love")
	if not love then
		love = Instance.new("NumberValue", ls)
		love.Name = "Love"
		love.Value = 10
	end

	player:SetAttribute("OnPullup", false)
	player:SetAttribute("InArena", false)
	player:SetAttribute("DuelPending", false)
	player:SetAttribute("DataPersistent", false)
	setRestricted(player)

	local function markDirty()
		if state.loaded then
			state.dirty = true
		end
	end
	table.insert(state.connections, power.Changed:Connect(markDirty))
	table.insert(state.connections, love.Changed:Connect(markDirty))

	if player.Character then
		task.spawn(placeCharacterAtSpawn, player.Character, SpawnPad)
	end
	table.insert(state.connections, player.CharacterAdded:Connect(function(char)
		player:SetAttribute("OnPullup", false)
		player:SetAttribute("InArena", false)
		player:SetAttribute("DuelPending", false)
		savedHumanoidMovement[char] = nil
		placeCharacterAtSpawn(char, SpawnPad)
	end))

	task.spawn(loadPlayer, player, state)
end

function PlayerDataService.Start(context)
	contextRef = context

	local ok, store = pcall(function()
		return DataStoreService:GetDataStore(DATA_STORE_NAME)
	end)
	if ok then
		dataStore = store
	else
		warnFor(nil, "DataStoreService unavailable", store)
	end

	local SpawnPad = context.SpawnPad
	local TouchSound = context.TouchSound
	local spawnDebounce = {}

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end
	Players.PlayerAdded:Connect(setupPlayer)

	-- River textures and spawn visuals are animated locally by the client; the
	-- server keeps only gameplay collision, prompts, sounds and rewards.
	SpawnPad.Touched:Connect(function(hit)
		local character = hit.Parent
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and not spawnDebounce[character] then
			spawnDebounce[character] = true
			TouchSound:Play()
			task.delay(1.5, function() spawnDebounce[character] = nil end)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			if not shuttingDown then
				for player, state in pairs(sessions) do
					if state.loaded and not state.leaving then
						task.spawn(savePlayer, player, state)
					end
				end
			end
		end
	end)

	game:BindToClose(function()
		shuttingDown = true
		local entries = {}
		for player, state in pairs(sessions) do
			table.insert(entries, { player, state })
		end
		for _, entry in ipairs(entries) do
			local player, state = entry[1], entry[2]
			if state.loaded then
				state.leaving = true
				state.pending = true
				state.dirty = true
				savePlayer(player, state)
			end
		end

		local deadline = os.clock() + SHUTDOWN_GRACE_SECONDS
		while os.clock() < deadline do
			local active = false
			for _, state in pairs(sessions) do
				if state.saving or state.pending or state.leaving then
					active = true
					break
				end
			end
			if not active then
				break
			end
			task.wait(0.2)
		end
	end)
end

function PlayerDataService.Cleanup(player)
	local state = sessions[player]
	if not state then
		return
	end

	local character = player.Character
	if character then
		contextRef.savedHumanoidMovement[character] = nil
	end

	state.leaving = true
	state.pending = true
	state.dirty = true
	for _, connection in ipairs(state.connections) do
		connection:Disconnect()
	end
	table.clear(state.connections)

	if state.loaded then
		task.spawn(savePlayer, player, state)
	else
		sessions[player] = nil
	end
end

return PlayerDataService
