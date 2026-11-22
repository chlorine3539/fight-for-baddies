-- ========================================================================
-- PLAYER DATA SERVICE
-- Leaderstats, attributes, spawn placement and saved movement state.
-- ========================================================================
local Players = game:GetService("Players")

local PlayerDataService = {}

local contextRef

function PlayerDataService.Start(context)
	contextRef = context

	local SpawnPad = context.SpawnPad
	local TouchSound = context.TouchSound
	local savedHumanoidMovement = context.savedHumanoidMovement

	-- 7. OYUNCU EKONOMİSİ (POWER & LOVE)
	------------------------------------------------------------------------
	local function placeCharacterAtSpawn(character)
		local hrp = character:WaitForChild("HumanoidRootPart", 5)
		if hrp then
			task.wait(0.05)
			hrp.CFrame = SpawnPad.CFrame + Vector3.new(0, 4, 0)
		end
	end

	local function setupPlayer(player)
		if not player:FindFirstChild("leaderstats") then
			local ls = Instance.new("Folder", player)
			ls.Name = "leaderstats"

			local power = Instance.new("NumberValue", ls)
			power.Name = "Power"
			power.Value = 0

			local love = Instance.new("NumberValue", ls)
			love.Name = "Love"
			love.Value = 10
		end

		player:SetAttribute("OnPullup", false)
		player:SetAttribute("InArena", false)
		player:SetAttribute("DuelPending", false)

		if player.Character then
			task.spawn(placeCharacterAtSpawn, player.Character)
		end
		player.CharacterAdded:Connect(function(char)
			player:SetAttribute("OnPullup", false)
			player:SetAttribute("InArena", false)
			player:SetAttribute("DuelPending", false)
			savedHumanoidMovement[char] = nil
			placeCharacterAtSpawn(char)
		end)
	end

	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end
	Players.PlayerAdded:Connect(setupPlayer)

	-- River textures and spawn visuals are animated locally by the client; the
	-- server keeps only gameplay collision, prompts, sounds and rewards.
	local spawnDebounce = {}
	SpawnPad.Touched:Connect(function(hit)
		local character = hit.Parent
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and not spawnDebounce[character] then
			spawnDebounce[character] = true
			TouchSound:Play()
			task.delay(1.5, function() spawnDebounce[character] = nil end)
		end
	end)
end

function PlayerDataService.Cleanup(player)
	local character = player.Character
	if character then
		contextRef.savedHumanoidMovement[character] = nil
	end
end

return PlayerDataService
