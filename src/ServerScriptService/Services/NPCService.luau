-- ========================================================================
-- NPC SERVICE
-- Rarity roll, rig builder, burst effect and roaming NPC prompts/dialogue.
-- Dialogue validation and duel authorization stay on the server.
-- ========================================================================
local Debris = game:GetService("Debris")

local GameRules = require(script.Parent.Parent.Logic.GameRules)

local NPCService = {}

-- D) 6 NADİRLİKLİ NPC SİSTEMİ
local RARITIES = {
	{ Name = "Common",    Chance = 60.000, ReqPower = 0,     Color = Color3.fromRGB(185, 195, 205) },
	{ Name = "Rare",      Chance = 25.000, ReqPower = 100,   Color = Color3.fromRGB(65, 165, 255)  },
	{ Name = "Epic",      Chance = 10.000, ReqPower = 1000,  Color = Color3.fromRGB(175, 75, 255)  },
	{ Name = "Mythic",    Chance = 4.000,  ReqPower = 5000,  Color = Color3.fromRGB(255, 65, 115)  },
	{ Name = "Legendary", Chance = 0.999,  ReqPower = 15000, Color = Color3.fromRGB(255, 200, 45)  },
	{ Name = "Godly",     Chance = 0.001,  ReqPower = 50000, Color = Color3.fromRGB(255, 95, 245)  },
}

local REJECTION_LINES = {
	"Üzgünüm tatlım, bu güçle ancak uzaktan bakarsın.",
	"Biraz daha barfiks çekip gel, şu an hiç tipim değilsin!",
	"Auran çok zayıf, kalbimi kazanmak için çok erken.",
	"Senin seviyen bana yetmez, önce güçlenmelisin!",
	"Benim standartlarım çok yüksek canım, üzgünüm.",
	"Bu kadar az güçle karşıma çıkmaya nasıl cesaret ettin?",
	"Belki 1000 barfiks sonra tekrar konuşabiliriz.",
	"Tatlısın ama benim ligimde değilsin!",
	"Gücün yetmiyor, kalbim şimdilik kapalı.",
	"Önce kendini kanıtla, sonra kalbimi çalmayı dene!",
}

local NPC_INTERACTION_TIMEOUT = 30
local activeNPCData = {}
local pendingNPCInteractions = {}

local NPCFolder
local EvInteractNPC
local EvDialogueChoice
local EvNotify
local modFolder
local arenaService

local function rollRarity()
	return GameRules.rollRarity(math.random() * 100, RARITIES)
end

local function SpawnBurstEffect(pos, color)
	local holder = Instance.new("Part", modFolder)
	holder.Size = Vector3.new(1, 1, 1)
	holder.Position = pos
	holder.Anchored = true
	holder.CanCollide = false
	holder.Transparency = 1

	local pe = Instance.new("ParticleEmitter", holder)
	pe.Color = ColorSequence.new(color, Color3.fromRGB(255, 255, 255))
	pe.Size = NumberSequence.new(0.85, 0)
	pe.Speed = NumberRange.new(8, 16)
	pe.Lifetime = NumberRange.new(0.5, 0.9)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe:Emit(30)
	Debris:AddItem(holder, 1.2)
end

local function BuildPlainRig(name, spawnPos, rarityInfo, isBoss)
	local npc = Instance.new("Model")
	npc.Name = name

	local hrp = Instance.new("Part", npc)
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(2, 2, 1)
	hrp.CFrame = CFrame.new(spawnPos)
	hrp.Transparency = 1
	hrp.CanCollide = false

	local torso = Instance.new("Part", npc)
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.CFrame = hrp.CFrame
	torso.Material = Enum.Material.SmoothPlastic
	torso.Color = Color3.fromRGB(225, 225, 225)
	torso.CanCollide = false

	local head = Instance.new("Part", npc)
	head.Name = "Head"
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.CFrame = hrp.CFrame * CFrame.new(0, 1.6, 0)
	head.Material = Enum.Material.SmoothPlastic
	head.Color = Color3.fromRGB(235, 235, 235)
	head.CanCollide = false

	local limbs = {
		{ "Left Arm",  Vector3.new(1, 2, 1), CFrame.new(-1.5, 0, 0) },
		{ "Right Arm", Vector3.new(1, 2, 1), CFrame.new(1.5, 0, 0)  },
		{ "Left Leg",  Vector3.new(1, 2, 1), CFrame.new(-0.5, -2, 0)},
		{ "Right Leg", Vector3.new(1, 2, 1), CFrame.new(0.5, -2, 0) },
	}
	for _, l in ipairs(limbs) do
		local p = Instance.new("Part", npc)
		p.Name = l[1]
		p.Size = l[2]
		p.CFrame = hrp.CFrame * l[3]
		p.Material = Enum.Material.SmoothPlastic
		p.Color = Color3.fromRGB(215, 215, 215)
		p.CanCollide = false
	end

	for _, part in ipairs(npc:GetChildren()) do
		if part:IsA("BasePart") and part ~= hrp then
			local w = Instance.new("WeldConstraint", hrp)
			w.Part0 = hrp
			w.Part1 = part
		end
	end

	local hum = Instance.new("Humanoid", npc)
	hum.WalkSpeed = isBoss and 15 or 11
	hum.HipHeight = 2
	npc.PrimaryPart = hrp

	local bb = Instance.new("BillboardGui", head)
	bb.Name = "RarityTag"
	bb.Size = UDim2.new(0, 110, 0, 28)
	bb.StudsOffset = Vector3.new(0, 1.9, 0)
	bb.MaxDistance = 55
	bb.AlwaysOnTop = false

	local lbl = Instance.new("TextLabel", bb)
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextScaled = true
	lbl.TextStrokeTransparency = 0.35
	lbl.TextColor3 = rarityInfo.Color
	lbl.Text = isBoss
		and ("⚔️ " .. rarityInfo.Name .. " Rakip")
		or ("[" .. rarityInfo.Name .. "]\nGüç: " .. rarityInfo.ReqPower)

	return npc, hum, hrp
end

NPCService.BuildPlainRig = BuildPlainRig
NPCService.SpawnBurstEffect = SpawnBurstEffect

local function spawnSingleRoamingNPC()
	if #NPCFolder:GetChildren() >= 20 then return end

	local rarityInfo = rollRarity()
	local rx = math.random(-130, 130)
	local rz = math.random(-130, 90)
	local spawnPos = Vector3.new(rx, 3.5, rz)

	local npc, hum, hrp = BuildPlainRig("NPC_" .. rarityInfo.Name, spawnPos, rarityInfo, false)
	npc.Parent = NPCFolder
	activeNPCData[npc] = rarityInfo
	SpawnBurstEffect(spawnPos, rarityInfo.Color)

	local prompt = Instance.new("ProximityPrompt", hrp)
	prompt.ActionText = "Konuş"
	prompt.ObjectText = rarityInfo.Name
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false

	prompt.Triggered:Connect(function(player)
		if player:GetAttribute("DataRestricted") then return end
		if player:GetAttribute("InArena") or player:GetAttribute("OnPullup") or player:GetAttribute("DuelPending") then return end
		local character = player.Character
		local playerHRP = character and character:FindFirstChild("HumanoidRootPart")
		local playerHumanoid = character and character:FindFirstChildOfClass("Humanoid")
		local npcHRP = npc:FindFirstChild("HumanoidRootPart")
		local ls = player:FindFirstChild("leaderstats")
		local power = ls and ls:FindFirstChild("Power")
		if not playerHRP or not playerHumanoid or playerHumanoid.Health <= 0 or not npcHRP
			or (playerHRP.Position - npcHRP.Position).Magnitude > 18 or not power then
			return
		end

		if power.Value < rarityInfo.ReqPower then
			local msg = REJECTION_LINES[math.random(1, #REJECTION_LINES)]
				.. " (Gereken Güç: " .. rarityInfo.ReqPower .. ")"
			EvNotify:FireClient(player, "Reject", msg)
		else
			pendingNPCInteractions[player] = {
				npc = npc,
				expiresAt = os.clock() + NPC_INTERACTION_TIMEOUT,
			}
			EvInteractNPC:FireClient(player, npc, rarityInfo.Name, rarityInfo.ReqPower)
		end
	end)

	local movementStopped = false
	npc.Destroying:Connect(function()
		movementStopped = true
		activeNPCData[npc] = nil
		for player, pending in pairs(pendingNPCInteractions) do
			if pending.npc == npc then
				pendingNPCInteractions[player] = nil
			end
		end
	end)

	task.spawn(function()
		while not movementStopped and npc.Parent and hum.Health > 0 do
			local wx = math.clamp(hrp.Position.X + math.random(-35, 35), -145, 145)
			local wz = math.clamp(hrp.Position.Z + math.random(-35, 35), -145, 105)
			hum:MoveTo(Vector3.new(wx, 3.5, wz))
			task.wait(math.random(3, 6))
		end
	end)

	task.delay(120, function()
		if not movementStopped and npc and npc.Parent then
			SpawnBurstEffect(hrp.Position, rarityInfo.Color)
			activeNPCData[npc] = nil
			npc:Destroy()
			task.wait(0.3)
			spawnSingleRoamingNPC()
		end
	end)
end

function NPCService.SetArenaService(arena)
	arenaService = arena
end

function NPCService.Start(context)
	NPCFolder = context.NPCFolder
	EvInteractNPC = context.EvInteractNPC
	EvDialogueChoice = context.EvDialogueChoice
	EvNotify = context.EvNotify
	modFolder = context.ModFolder

	-- F) DİYALOG SEÇENEKLERİ VE NPC DOĞUM YÖNETİMİ
	EvDialogueChoice.OnServerEvent:Connect(function(player, npcModel, choiceIndex)
		if player:GetAttribute("DataRestricted") then return end
		if typeof(npcModel) ~= "Instance" or not npcModel:IsA("Model") then return end
		if not GameRules.isValidDialogueChoice(choiceIndex) then return end
		if player:GetAttribute("InArena") or player:GetAttribute("OnPullup") or player:GetAttribute("DuelPending") then return end

		local pending = pendingNPCInteractions[player]
		if not pending or pending.npc ~= npcModel or os.clock() > pending.expiresAt then
			pendingNPCInteractions[player] = nil
			return
		end

		local info = activeNPCData[npcModel]
		if not info or npcModel.Parent ~= NPCFolder then return end

		local character = player.Character
		local playerHRP = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local npcHRP = npcModel:FindFirstChild("HumanoidRootPart")
		local ls = player:FindFirstChild("leaderstats")
		local power = ls and ls:FindFirstChild("Power")
		local love = ls and ls:FindFirstChild("Love")
		if not playerHRP or not humanoid or humanoid.Health <= 0 or not npcHRP
			or (playerHRP.Position - npcHRP.Position).Magnitude > 18
			or not power or not love or power.Value < info.ReqPower then
			return
		end

		local deltaLove = GameRules.loveDelta(choiceIndex, power.Value)
		if not deltaLove then return end

		-- Consume the server-issued interaction before changing any player state.
		pendingNPCInteractions[player] = nil
		player:SetAttribute("DuelPending", true)

		if choiceIndex == 1 then
			love.Value = GameRules.clampLove(love.Value, deltaLove)
			EvNotify:FireClient(player, "LoveLoss", "Yanlış cevap! (" .. deltaLove .. " Love)")
		else
			love.Value += deltaLove
			if choiceIndex == 2 then
				EvNotify:FireClient(player, "LoveGain", "Güzel sohbet! (+" .. deltaLove .. " Love)")
			elseif choiceIndex == 3 then
				EvNotify:FireClient(player, "LoveGain", "Etkileyici sözler! (+" .. deltaLove .. " Love)")
			else
				EvNotify:FireClient(player, "LoveGain", "Kalbinden vurdun! (+" .. deltaLove .. " Love)")
			end
		end

		task.delay(0.6, function()
			if not player.Parent then return end
			if player:GetAttribute("DuelPending") ~= true or player:GetAttribute("InArena") then return end
			if not arenaService.StartDuel(player, info) then
				player:SetAttribute("DuelPending", false)
			end
		end)
	end)

	for i = 1, 20 do
		task.delay(i * 0.15, spawnSingleRoamingNPC)
	end
end

function NPCService.Cleanup(player)
	pendingNPCInteractions[player] = nil
end

return NPCService
