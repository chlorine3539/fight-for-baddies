-- ========================================================================
-- ARENA SERVICE
-- Hidden duel arena shell, swords, duel lifecycle, server-side attacks,
-- readiness handshake and containment. All combat validation stays here.
-- ========================================================================
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local ArenaService = {}

-- C) GİZLİ YÜKSEK ARENA (HARİTADAN GÖRÜNMEZ)
local ARENA_CENTER = Vector3.new(0, 4500, 0)

-- A client sends an attack request only. Target selection, hit detection,
-- damage, hit windows and cooldowns all stay on this server.
local ARENA_RADIUS = 45
local ARENA_SLOT_SPACING = 120
local HITBOX_FORWARD = 4
local HITBOX_SIZE = Vector3.new(6, 5, 12)
local MAX_MELEE_DISTANCE = 9
local PLAYER_HIT_WINDOW = 0.26
local PLAYER_SWING_COOLDOWN = 0.5
local NPC_HIT_WINDOW = 0.26
local NPC_SWING_COOLDOWN = 1.1

local activeDuels = {} -- [player] = active duel record
local reservedArenaSlots = {} -- [slot] = player, freed only by duel cleanup

local ArenaFolder
local EvNotify
local EvArenaAttack
local EvArenaReady
local buildPlainRig
local spawnBurstEffect

local function reserveArenaSlot(player)
	for slot = 1, 16 do
		if reservedArenaSlots[slot] == nil then
			reservedArenaSlots[slot] = player
			return slot
		end
	end
	return nil
end

local function isAliveHumanoid(humanoid)
	return humanoid ~= nil and humanoid.Health > 0
end

local function isInsideDuelArena(hrp, center)
	if not hrp then return false end
	local offset = hrp.Position - center
	return math.abs(offset.Y) <= 30 and Vector2.new(offset.X, offset.Z).Magnitude <= ARENA_RADIUS
end

local function isMeleeTargetInReach(attackerModel, targetModel, targetHumanoid)
	if not isAliveHumanoid(targetHumanoid) then return false end
	local attackerHRP = attackerModel and attackerModel:FindFirstChild("HumanoidRootPart")
	local targetHRP = targetModel and targetModel:FindFirstChild("HumanoidRootPart")
	if not attackerHRP or not targetHRP then return false end
	if (attackerHRP.Position - targetHRP.Position).Magnitude > MAX_MELEE_DISTANCE then return false end

	local direction = targetHRP.Position - attackerHRP.Position
	direction.Y = 0
	if direction.Magnitude < 0.001 then
		direction = attackerHRP.CFrame.LookVector
		direction.Y = 0
	end
	if direction.Magnitude < 0.001 then return false end
	direction = direction.Unit

	local lookAt = Vector3.new(targetHRP.Position.X, attackerHRP.Position.Y, targetHRP.Position.Z)
	local hitCFrame = CFrame.new(attackerHRP.Position + direction * HITBOX_FORWARD, lookAt)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { targetModel }

	for _, part in ipairs(Workspace:GetPartBoundsInBox(hitCFrame, HITBOX_SIZE, params)) do
		if part:FindFirstAncestorOfClass("Model") == targetModel then
			return true
		end
	end
	return false
end

local function newSwingState()
	return { token = 0, hit = false, readyAt = 0 }
end

local function performMeleeSwing(duel, swingState, sword, attackerModel, targetModel, targetHumanoid, damage, hitWindow, cooldown)
	if not duel.active or os.clock() < swingState.readyAt then return false end

	swingState.readyAt = os.clock() + cooldown
	swingState.token += 1
	swingState.hit = false
	local token = swingState.token

	if sword and sword.Parent then
		local slash = Instance.new("StringValue")
		slash.Name = "toolanim"
		slash.Value = "Slash"
		slash.Parent = sword
		Debris:AddItem(slash, 0.2)
		local slashSFX = sword:FindFirstChild("SlashSFX", true)
		if slashSFX then slashSFX:Play() end
	end

	task.spawn(function()
		local deadline = os.clock() + hitWindow
		while duel.active and swingState.token == token and not swingState.hit and os.clock() < deadline do
			if isMeleeTargetInReach(attackerModel, targetModel, targetHumanoid) then
				swingState.hit = true
				if isAliveHumanoid(targetHumanoid) then
					targetHumanoid:TakeDamage(damage)
				end
				break
			end
			task.wait(0.04)
		end
	end)
	return true
end

local function aPart(parent, n, sh, sz, cf, mat, col, cc)
	local p = Instance.new("Part", parent)
	p.Name = n
	p.Shape = sh
	p.Size = sz
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = cc
	p.Material = mat
	p.Color = col
	return p
end

local function buildArenaShell(center, parent, slotLabel)
	aPart(parent, "ArenaFloor_" .. slotLabel, Enum.PartType.Cylinder, Vector3.new(110, 2, 110), CFrame.new(center), Enum.Material.Marble, Color3.fromRGB(42, 46, 56), true)
	aPart(parent, "ArenaRingGold", Enum.PartType.Cylinder, Vector3.new(86, 2.1, 86), CFrame.new(center), Enum.Material.Neon, Color3.fromRGB(255, 195, 75), false)
	aPart(parent, "ArenaInnerFloor", Enum.PartType.Cylinder, Vector3.new(83, 2.15, 83), CFrame.new(center), Enum.Material.Slate, Color3.fromRGB(58, 64, 78), true)
	aPart(parent, "ArenaCeiling", Enum.PartType.Cylinder, Vector3.new(116, 2, 116), CFrame.new(center + Vector3.new(0, 45, 0)), Enum.Material.SmoothPlastic, Color3.fromRGB(25, 28, 36), true)

	for i = 1, 16 do
		local ang = (i / 16) * math.pi * 2
		local pos = center + Vector3.new(math.cos(ang) * 53, 22.5, math.sin(ang) * 53)
		aPart(parent, "ArenaWall_" .. i, Enum.PartType.Block, Vector3.new(24, 45, 3), CFrame.new(pos) * CFrame.Angles(0, -ang + math.pi / 2, 0), Enum.Material.Concrete, Color3.fromRGB(36, 40, 50), true)
		if i % 2 == 0 then
			local torch = aPart(parent, "ArenaTorch_" .. i, Enum.PartType.Ball, Vector3.new(2.5, 2.5, 2.5), CFrame.new(center + Vector3.new(math.cos(ang) * 49, 16, math.sin(ang) * 49)), Enum.Material.Neon, Color3.fromRGB(255, 140, 50), false)
			local l = Instance.new("PointLight", torch)
			l.Color = Color3.fromRGB(255, 150, 60)
			l.Range = 45
			l.Brightness = 1.5
		end
	end
end

local function giveArenaSword(holderModel)
	local tool = Instance.new("Tool")
	tool.Name = "ArenaBlade"
	tool.RequiresHandle = true

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.4, 0.4, 4.4)
	handle.Material = Enum.Material.Neon
	handle.Color = Color3.fromRGB(110, 220, 255)
	handle.CanCollide = false
	handle.CanTouch = true
	handle.Massless = true
	handle.Parent = tool

	local slashSFX = Instance.new("Sound", handle)
	slashSFX.Name = "SlashSFX"
	slashSFX.SoundId = "rbxassetid://12222216"
	slashSFX.Volume = 0.7

	tool.Parent = holderModel
	return tool
end

-- E) ARENA DÜELLO BAŞLATICI
function ArenaService.StartDuel(player, rarityInfo)
	if player:GetAttribute("InArena") or player:GetAttribute("DuelPending") ~= true then return false end
	if activeDuels[player] then return false end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local ls = player:FindFirstChild("leaderstats")
	if not (hrp and hum and hum.Health > 0 and ls and ls.Power and ls.Love) then return false end
	local slot = reserveArenaSlot(player)
	if not slot then
		EvNotify:FireClient(player, "Reject", "Arena şu anda dolu; biraz sonra tekrar dene.")
		return false
	end

	local slotCenter = ARENA_CENTER + Vector3.new((slot - 1) * ARENA_SLOT_SPACING, 0, 0)
	local returnCF = hrp.CFrame
	local duel, finishDuel
	local arenaShell, bossNPC, bossHum, bossHRP, playerSword, bossSword

	local ok, err = pcall(function()
		player:SetAttribute("InArena", true)
		player:SetAttribute("DuelPending", false)
		if slot ~= 1 then
			arenaShell = Instance.new("Model", ArenaFolder)
			arenaShell.Name = "DuelArena_" .. slot
			buildArenaShell(slotCenter, arenaShell, slot)
		end
		hrp.CFrame = CFrame.new(slotCenter + Vector3.new(0, 3, -24), slotCenter + Vector3.new(0, 3, 24))

		local pPower = math.max(10, ls.Power.Value)
		local rarityMult = { Common = 0.65, Rare = 0.75, Epic = 0.82, Mythic = 0.88, Legendary = 0.92, Godly = 0.95 }
		local mult = rarityMult[rarityInfo.Name] or 0.75
		local bossMaxHP = math.floor(100 + (rarityInfo.ReqPower * 0.05) + (pPower * 0.25))
		local playerSwordDmg = math.max(25, math.floor(bossMaxHP / 4))
		local bossSwordDmg = math.max(8, math.floor(18 * mult))

		local bossPos = slotCenter + Vector3.new(0, 3, 24)
		bossNPC, bossHum, bossHRP = buildPlainRig("ArenaRival_" .. player.Name, bossPos, rarityInfo, true)
		bossHum.MaxHealth = bossMaxHP
		bossHum.Health = bossMaxHP
		bossNPC.Parent = ArenaFolder
		spawnBurstEffect(bossPos, rarityInfo.Color)

		playerSword = giveArenaSword(char)
		hum:EquipTool(playerSword)
		bossSword = giveArenaSword(bossNPC)
		bossHum:EquipTool(bossSword)

		duel = {
			player = player,
			character = char,
			center = slotCenter,
			slot = slot,
			ready = false,
			arenaShell = arenaShell,
			opponent = bossNPC,
			playerSword = playerSword,
			bossSword = bossSword,
			playerDamage = playerSwordDmg,
			npcDamage = bossSwordDmg,
			playerSwing = newSwingState(),
			npcSwing = newSwingState(),
			connections = {},
			active = true,
			startMessage = rarityInfo.Name .. " rakiple düello başladı! Kılıcınla saldır!",
			bonusLove = math.max(5, math.floor(pPower * 0.12)),
		}
		activeDuels[player] = duel

		finishDuel = function(won)
			if not duel.active then return end
			duel.active = false
			for _, connection in ipairs(duel.connections) do
				connection:Disconnect()
			end
			table.clear(duel.connections)
			activeDuels[player] = nil
			if reservedArenaSlots[slot] == player then
				reservedArenaSlots[slot] = nil
			end

			if duel.playerSword and duel.playerSword.Parent then duel.playerSword:Destroy() end
			if duel.opponent and duel.opponent.Parent then
				if bossHRP and bossHRP.Parent then
					spawnBurstEffect(bossHRP.Position, rarityInfo.Color)
				end
				duel.opponent:Destroy()
			end
			if duel.arenaShell and duel.arenaShell.Parent then duel.arenaShell:Destroy() end

			player:SetAttribute("InArena", false)
			player:SetAttribute("DuelPending", false)
			if player.Parent and player.Character == char and hrp.Parent then
				hrp.CFrame = returnCF
			end

			if won then
				if player.Parent and ls.Parent == player then
					ls.Love.Value += duel.bonusLove
					EvNotify:FireClient(player, "ArenaWin", "Düelloyu kazandın! (+" .. duel.bonusLove .. " Love)")
				end
			elseif player.Parent then
				EvNotify:FireClient(player, "ArenaLose", "Düelloyu kaybettin! Gücünü artırıp tekrar dene.")
			end
		end
		duel.finish = finishDuel

		local function track(connection)
			table.insert(duel.connections, connection)
		end
		track(bossHum.Died:Connect(function() finishDuel(true) end))
		track(hum.Died:Connect(function() finishDuel(false) end))
		track(char.AncestryChanged:Connect(function(_, parent)
			if parent == nil then finishDuel(false) end
		end))
		track(player.CharacterAdded:Connect(function(newCharacter)
			if newCharacter ~= char then finishDuel(false) end
		end))
	end)

	if not ok then
		if duel then
			for _, connection in ipairs(duel.connections) do
				connection:Disconnect()
			end
		end
		if activeDuels[player] == duel then activeDuels[player] = nil end
		if reservedArenaSlots[slot] == player then reservedArenaSlots[slot] = nil end
		if playerSword and playerSword.Parent then playerSword:Destroy() end
		if bossNPC and bossNPC.Parent then bossNPC:Destroy() end
		if arenaShell and arenaShell.Parent then arenaShell:Destroy() end
		player:SetAttribute("InArena", false)
		player:SetAttribute("DuelPending", false)
		if player.Parent and player.Character == char and hrp.Parent then hrp.CFrame = returnCF end
		warn("[Simulator] arena setup failed: " .. tostring(err))
		return false
	end

	-- The client confirms its locally streamed arena floor before combat begins.
	EvNotify:FireClient(player, "ArenaReadyRequest", slot)
	task.delay(12, function()
		if duel.active and not duel.ready then finishDuel(false) end
	end)

	-- Server-side containment keeps each duel in its reserved slot.
	task.spawn(function()
		while duel.active do
			if hrp.Parent and player.Character == char
				and not isInsideDuelArena(hrp, slotCenter) then
				hrp.CFrame = CFrame.new(slotCenter + Vector3.new(0, 3, -24), slotCenter + Vector3.new(0, 3, 24))
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.AssemblyAngularVelocity = Vector3.zero
			end
			task.wait(0.12)
		end
	end)

	-- The NPC uses the same server-side hit logic on its own independent cooldown.
	task.spawn(function()
		local nextMoveAt = 0
		while duel.active and duel.ready and bossNPC.Parent
			and isAliveHumanoid(hum) and isAliveHumanoid(bossHum) do
			if hrp.Parent and isInsideDuelArena(hrp, slotCenter)
				and isInsideDuelArena(bossHRP, slotCenter) then
				if os.clock() >= nextMoveAt then
					bossHum:MoveTo(hrp.Position)
					nextMoveAt = os.clock() + 0.35
				end
				if (bossHRP.Position - hrp.Position).Magnitude <= 7 then
					performMeleeSwing(duel, duel.npcSwing, bossSword, bossNPC, char, hum,
						duel.npcDamage, NPC_HIT_WINDOW, NPC_SWING_COOLDOWN)
				end
			end
			task.wait(0.12)
		end
	end)

	return true
end

function ArenaService.FinishForPlayer(player)
	local duel = activeDuels[player]
	if duel then duel.finish(false) end
end

function ArenaService.Start(context)
	ArenaFolder = context.ArenaFolder
	EvNotify = context.EvNotify
	EvArenaAttack = context.EvArenaAttack
	EvArenaReady = context.EvArenaReady
	buildPlainRig = context.NPCService.BuildPlainRig
	spawnBurstEffect = context.NPCService.SpawnBurstEffect

	-- Slot 1 uses the original arena shell; extra concurrent duels get their own
	-- shell created on demand and destroyed by the matching duel cleanup.
	buildArenaShell(ARENA_CENTER, ArenaFolder, 1)

	EvArenaReady.OnServerEvent:Connect(function(player, slot)
		local duel = activeDuels[player]
		if not duel or not duel.active or duel.ready then return end
		if typeof(slot) ~= "number" or slot ~= duel.slot then return end
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if character ~= duel.character or not isInsideDuelArena(hrp, duel.center) then return end
		duel.ready = true
		EvNotify:FireClient(player, "ArenaStart", duel.startMessage)
		task.delay(60, function()
			if duel.active then duel.finish(false) end
		end)
	end)

	-- Attack requests carry no target, damage, cooldown or position information.
	EvArenaAttack.OnServerEvent:Connect(function(player)
		local duel = activeDuels[player]
		if not duel or not duel.active or not duel.ready then return end

		local character = player.Character
		if character ~= duel.character then return end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local opponentHumanoid = duel.opponent and duel.opponent:FindFirstChildOfClass("Humanoid")
		if not isAliveHumanoid(humanoid) or not isAliveHumanoid(opponentHumanoid) then return end

		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not isInsideDuelArena(hrp, duel.center) then return end
		if character:FindFirstChildOfClass("Tool") ~= duel.playerSword then return end
		if duel.playerSword.Parent ~= character then return end

		performMeleeSwing(duel, duel.playerSwing, duel.playerSword, character, duel.opponent,
			opponentHumanoid, duel.playerDamage, PLAYER_HIT_WINDOW, PLAYER_SWING_COOLDOWN)
	end)
end

return ArenaService
