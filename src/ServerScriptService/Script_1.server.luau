-- ========================================================================
-- SERVER GAMEPLAY (ServerScriptService -> Script)
-- The shared map is built by ReplicatedStorage.WorldBuilder in both Studio
-- edit mode (via Command Bar) and server runtime.
-- ========================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local savedHumanoidMovement = {}

local WorldBuilder = require(ReplicatedStorage:WaitForChild("WorldBuilder"))
local world = WorldBuilder.Build()
local MapFolder = world.MapFolder
local GYM_POS = world.GYM_POS
local SpawnPad = world.SpawnPad
local TouchSound = world.TouchSound
local SpawnCrystal = world.SpawnCrystal
local SpawnRing = world.SpawnRing
local FlowingTextures = world.FlowingTextures
local DecorFolder = world.DecorFolder

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

------------------------------------------------------------------------
-- 8. NEHİR SU AKINTISI & SPAWN KRİSTALİ ANİMASYONU
------------------------------------------------------------------------
local crystalBasePos = SpawnCrystal.Position
local animTime = 0

RunService.Heartbeat:Connect(function(dt)
	animTime += dt
	for _, item in ipairs(FlowingTextures) do
		local tex = item.tex
		if tex and tex.Parent then
			tex.OffsetStudsU = (tex.OffsetStudsU + item.speedU * dt) % tex.StudsPerTileU
			tex.OffsetStudsV = (tex.OffsetStudsV + item.speedV * dt) % tex.StudsPerTileV
		end
	end
	local floatOffset = Vector3.new(0, math.sin(animTime * 2.2) * 0.85, 0)
	SpawnCrystal.CFrame = CFrame.new(crystalBasePos + floatOffset) * CFrame.Angles(0, animTime * 1.2, 0)
	SpawnRing.CFrame = CFrame.new(crystalBasePos + floatOffset) * CFrame.Angles(math.sin(animTime * 1.5) * 0.35, animTime * 1.8, math.rad(90))
end)

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

------------------------------------------------------------------------
-- 9. AĞLAR (REMOTE EVENTS), GİZLİ TUVALET, BARFİKS, NPC'LER VE ARENA
------------------------------------------------------------------------
local ModFolder = Instance.new("Folder", MapFolder)
ModFolder.Name = "SimulatorSystems"

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

-- A) GİZLİ TUVALET
local trees = DecorFolder:GetChildren()
local targetTree = trees[1]
local toiletPos = Vector3.new(-155, 0, -145)
if targetTree and targetTree:FindFirstChild("Trunk") then
	toiletPos = targetTree.Trunk.Position * Vector3.new(1, 0, 1) + Vector3.new(5.5, 0, 4.5)
end

local ToiletModel = Instance.new("Model", ModFolder)
ToiletModel.Name = "SecretForestToilet"

local function tPart(n, sz, cf, mat, col)
	local p = Instance.new("Part", ToiletModel)
	p.Name = n
	p.Size = sz
	p.CFrame = cf
	p.Anchored = true
	p.Material = mat
	p.Color = col
	return p
end

local tCF = CFrame.new(toiletPos) * CFrame.Angles(0, math.rad(35), 0)
tPart("CabinFloor", Vector3.new(6, 0.4, 6), tCF * CFrame.new(0, 0.2, 0), Enum.Material.WoodPlanks, Color3.fromRGB(92, 62, 40))
tPart("WallBack", Vector3.new(6, 8.5, 0.5), tCF * CFrame.new(0, 4.4, -2.75), Enum.Material.WoodPlanks, Color3.fromRGB(85, 58, 38))
tPart("WallLeft", Vector3.new(0.5, 8.5, 6), tCF * CFrame.new(-2.75, 4.4, 0), Enum.Material.WoodPlanks, Color3.fromRGB(85, 58, 38))
tPart("WallRight", Vector3.new(0.5, 8.5, 6), tCF * CFrame.new(2.75, 4.4, 0), Enum.Material.WoodPlanks, Color3.fromRGB(85, 58, 38))
tPart("Roof", Vector3.new(6.8, 0.6, 6.8), tCF * CFrame.new(0, 8.9, 0), Enum.Material.Grass, Color3.fromRGB(64, 145, 70))
tPart("DoorHalfOpen", Vector3.new(2.8, 8.2, 0.4), tCF * CFrame.new(-1.4, 4.3, 3.2) * CFrame.Angles(0, math.rad(-55), 0), Enum.Material.WoodPlanks, Color3.fromRGB(102, 70, 46))
tPart("ToiletBase", Vector3.new(1.8, 1.8, 2.2), tCF * CFrame.new(0, 1.1, -1.2), Enum.Material.SmoothPlastic, Color3.fromRGB(248, 250, 252))
tPart("ToiletTank", Vector3.new(2.0, 2.0, 0.9), tCF * CFrame.new(0, 2.7, -2.0), Enum.Material.SmoothPlastic, Color3.fromRGB(245, 248, 250))

local tSeat = Instance.new("Seat", ToiletModel)
tSeat.Size = Vector3.new(1.7, 0.3, 1.8)
tSeat.CFrame = tCF * CFrame.new(0, 2.1, -1.1)
tSeat.Anchored = true
tSeat.Material = Enum.Material.SmoothPlastic
tSeat.Color = Color3.fromRGB(235, 240, 245)

local FlushPrompt = Instance.new("ProximityPrompt", tSeat)
FlushPrompt.ActionText = "Sifonu Çek"
FlushPrompt.ObjectText = "Gizli Orman Tuvaleti"
FlushPrompt.MaxActivationDistance = 8

local FlushSFX = Instance.new("Sound", tSeat)
FlushSFX.SoundId = "rbxassetid://9114221735"
FlushSFX.Volume = 0.8

local toiletRewards = {}
FlushPrompt.Triggered:Connect(function(plr)
	local ls = plr:FindFirstChild("leaderstats")
	local love = ls and ls:FindFirstChild("Love")
	if not love then return end

	if toiletRewards[plr.UserId] then
		EvNotify:FireClient(plr, "Secret", "Bu gizli ödülü zaten aldın.")
		return
	end

	toiletRewards[plr.UserId] = true
	FlushSFX:Play()
	love.Value += 5
	EvNotify:FireClient(plr, "Secret", "Gizli tuvaleti buldun! (+5 Love)")
end)

-- B) BARFİKS ALANI (TAM ANİMASYONLU VE GİRİŞ/ÇIKIŞ GARANTİLİ)
local PullupFolder = Instance.new("Model", ModFolder)
PullupFolder.Name = "GymPullupStation"

local function gPart(n, sh, sz, cf, mat, col, cc)
	local p = Instance.new("Part", PullupFolder)
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

gPart("GymMat", Enum.PartType.Block, Vector3.new(18, 0.4, 14), CFrame.new(GYM_POS + Vector3.new(0, 0.2, 0)), Enum.Material.SmoothPlastic, Color3.fromRGB(48, 56, 68), true)
gPart("GymTrim", Enum.PartType.Block, Vector3.new(18.6, 0.3, 14.6), CFrame.new(GYM_POS + Vector3.new(0, 0.15, 0)), Enum.Material.Neon, Color3.fromRGB(255, 175, 65), false)
gPart("LeftPost", Enum.PartType.Cylinder, Vector3.new(11.5, 0.9, 0.9), CFrame.new(GYM_POS + Vector3.new(-5.5, 5.75, 0)) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Metal, Color3.fromRGB(60, 65, 75), true)
gPart("RightPost", Enum.PartType.Cylinder, Vector3.new(11.5, 0.9, 0.9), CFrame.new(GYM_POS + Vector3.new(5.5, 5.75, 0)) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Metal, Color3.fromRGB(60, 65, 75), true)

local PullupBar = gPart("PullupBar", Enum.PartType.Cylinder, Vector3.new(11.6, 0.5, 0.5), CFrame.new(GYM_POS + Vector3.new(0, 11.2, 0)), Enum.Material.Metal, Color3.fromRGB(225, 185, 85), false)

local BarPrompt = Instance.new("ProximityPrompt", PullupBar)
BarPrompt.ActionText = "Barfiks Çek"
BarPrompt.ObjectText = "Güç İstasyonu"
BarPrompt.MaxActivationDistance = 14
BarPrompt.RequiresLineOfSight = false

local pullupCooldowns = {}
local savedMotorC0 = {}

local function applyPullupLimbPose(character, isHanging, isPulledUp)
	local animateScript = character:FindFirstChild("Animate")
	if animateScript then
		local saved = savedHumanoidMovement[character]
		if isHanging then
			if saved and saved.AnimateDisabled == nil then
				saved.AnimateDisabled = animateScript.Disabled
			end
			animateScript.Disabled = true
		else
			animateScript.Disabled = saved and saved.AnimateDisabled or false
		end
	end

	local hum = character:FindFirstChildOfClass("Humanoid")
	if hum and isHanging then
		for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
			track:Stop(0)
		end
	end

	local function findMotor6D(jointName)
		for _, descendant in ipairs(character:GetDescendants()) do
			if descendant:IsA("Motor6D") and descendant.Name == jointName then
				return descendant
			end
		end
		return nil
	end

	local torso = character:FindFirstChild("Torso")
	if torso then
		local rs = torso:FindFirstChild("Right Shoulder")
		local ls = torso:FindFirstChild("Left Shoulder")
		local rh = torso:FindFirstChild("Right Hip")
		local lh = torso:FindFirstChild("Left Hip")
		if rs and ls and rh and lh then
			if not savedMotorC0[character] then
				savedMotorC0[character] = { rs = rs.C0, ls = ls.C0, rh = rh.C0, lh = lh.C0 }
			end
			if isHanging then
				local armPitch = isPulledUp and math.rad(130) or math.rad(175)
				local legBend = isPulledUp and math.rad(25) or math.rad(10)
				TweenService:Create(rs, TweenInfo.new(0.11), { C0 = CFrame.new(1, 0.7, 0) * CFrame.Angles(armPitch, math.rad(90), 0) }):Play()
				TweenService:Create(ls, TweenInfo.new(0.11), { C0 = CFrame.new(-1, 0.7, 0) * CFrame.Angles(armPitch, math.rad(-90), 0) }):Play()
				TweenService:Create(rh, TweenInfo.new(0.11), { C0 = CFrame.new(1, -1, 0) * CFrame.Angles(-legBend, math.rad(90), 0) }):Play()
				TweenService:Create(lh, TweenInfo.new(0.11), { C0 = CFrame.new(-1, -1, 0) * CFrame.Angles(-legBend, math.rad(-90), 0) }):Play()
			else
				rs.C0 = savedMotorC0[character].rs
				ls.C0 = savedMotorC0[character].ls
				rh.C0 = savedMotorC0[character].rh
				lh.C0 = savedMotorC0[character].lh
				savedMotorC0[character] = nil
			end
		end
	else
		-- R15 Motor6Ds are attached to the torso parts, not the limb parts.
		local rs = findMotor6D("RightShoulder")
		local ls = findMotor6D("LeftShoulder")
		local re = findMotor6D("RightElbow")
		local le = findMotor6D("LeftElbow")
		if rs and ls then
			if not savedMotorC0[character] then
				savedMotorC0[character] = {
					rs = rs.C0, ls = ls.C0,
					re = re and re.C0, le = le and le.C0
				}
			end
			if isHanging then
				local shoulderPitch = isPulledUp and math.rad(135) or math.rad(175)
				local elbowBend = isPulledUp and math.rad(65) or math.rad(8)
				TweenService:Create(rs, TweenInfo.new(0.11), { C0 = CFrame.new(rs.C0.Position) * CFrame.Angles(shoulderPitch, 0, math.rad(-6)) }):Play()
				TweenService:Create(ls, TweenInfo.new(0.11), { C0 = CFrame.new(ls.C0.Position) * CFrame.Angles(shoulderPitch, 0, math.rad(6)) }):Play()
				if re and le then
					TweenService:Create(re, TweenInfo.new(0.11), { C0 = CFrame.new(re.C0.Position) * CFrame.Angles(elbowBend, 0, 0) }):Play()
					TweenService:Create(le, TweenInfo.new(0.11), { C0 = CFrame.new(le.C0.Position) * CFrame.Angles(elbowBend, 0, 0) }):Play()
				end
			else
				rs.C0 = savedMotorC0[character].rs
				ls.C0 = savedMotorC0[character].ls
				if re and savedMotorC0[character].re then re.C0 = savedMotorC0[character].re end
				if le and savedMotorC0[character].le then le.C0 = savedMotorC0[character].le end
				savedMotorC0[character] = nil
			end
		end
	end
end

local function togglePlayerPullup(player, forceState)
	local current = player:GetAttribute("OnPullup") == true
	local nextState = forceState == nil and not current or forceState == true

	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if nextState then
		-- Arena and pending-duel restrictions only prevent entering the station.
		if player:GetAttribute("InArena") or player:GetAttribute("DuelPending") then return end
		if current then
			EvTogglePullup:FireClient(player, true)
			return
		end
		if not hrp or not humanoid or humanoid.Health <= 0 then return end
		if (hrp.Position - GYM_POS).Magnitude > 18 then return end

		savedHumanoidMovement[character] = {
			WalkSpeed = humanoid.WalkSpeed,
			JumpPower = humanoid.JumpPower,
			JumpHeight = humanoid.JumpHeight,
			AutoRotate = humanoid.AutoRotate,
			PlatformStand = humanoid.PlatformStand,
			AnimateDisabled = nil,
		}
		local animateScript = character:FindFirstChild("Animate")
		if animateScript then
			savedHumanoidMovement[character].AnimateDisabled = animateScript.Disabled
		end

		player:SetAttribute("OnPullup", true)
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
		humanoid.AutoRotate = false
		hrp.Anchored = true
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		hrp.CFrame = CFrame.new(GYM_POS + Vector3.new(0, 7.6, 0.25)) * CFrame.Angles(math.rad(6), 0, 0)
		pcall(applyPullupLimbPose, character, true, false)
		EvTogglePullup:FireClient(player, true)
		return
	end

	-- Exit is idempotent and is never blocked by DuelPending. Recover an
	-- anchored character near the station even if its attribute got out of sync.
	local isAtStation = hrp and hrp.Anchored and (hrp.Position - GYM_POS).Magnitude <= 18
	if not current and not isAtStation then
		EvTogglePullup:FireClient(player, false)
		return
	end

	player:SetAttribute("OnPullup", false)
	if hrp then
		hrp.Anchored = false
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		if not player:GetAttribute("InArena") then
			hrp.CFrame = CFrame.new(GYM_POS + Vector3.new(0, 3.5, 5.5))
		end
	end

	local saved = character and savedHumanoidMovement[character]
	if humanoid then
		humanoid.PlatformStand = saved and saved.PlatformStand or false
		humanoid.AutoRotate = saved and saved.AutoRotate
		if humanoid.AutoRotate == nil then humanoid.AutoRotate = true end
		humanoid.WalkSpeed = saved and saved.WalkSpeed or 16
		humanoid.JumpPower = saved and saved.JumpPower or 50
		humanoid.JumpHeight = saved and saved.JumpHeight or 7.2
		if humanoid.Health > 0 then
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end
	if character then
		pcall(applyPullupLimbPose, character, false, false)
		savedHumanoidMovement[character] = nil
	end
	EvTogglePullup:FireClient(player, false)
end
BarPrompt.Triggered:Connect(function(player)
	togglePlayerPullup(player, true)
end)

-- The client can request an exit only; it cannot remotely enter the station.
EvTogglePullup.OnServerEvent:Connect(function(player)
	togglePlayerPullup(player, false)
end)

EvPullupAction.OnServerEvent:Connect(function(player)
	if player:GetAttribute("OnPullup") ~= true or player:GetAttribute("InArena") then return end

	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local ls = player:FindFirstChild("leaderstats")
	local power = ls and ls:FindFirstChild("Power")
	local love = ls and ls:FindFirstChild("Love")

	if not hrp or not humanoid or humanoid.Health <= 0 or not hrp.Anchored
		or (hrp.Position - GYM_POS).Magnitude > 18
		or not power or not love then
		togglePlayerPullup(player, false)
		return
	end

	local now = os.clock()
	if pullupCooldowns[player] and now - pullupCooldowns[player] < 0.26 then return end
	pullupCooldowns[player] = now

	local baseGain = 1
	local loveBonus = love.Value * 0.01
	local totalGain = math.max(1, math.floor((baseGain + loveBonus) * 100) / 100)
	power.Value = math.floor((power.Value + totalGain) * 100) / 100

	local upCF = CFrame.new(GYM_POS + Vector3.new(0, 9.4, 0.15)) * CFrame.Angles(math.rad(-8), 0, 0)
	local downCF = CFrame.new(GYM_POS + Vector3.new(0, 7.6, 0.25)) * CFrame.Angles(math.rad(6), 0, 0)
	applyPullupLimbPose(character, true, true)
	TweenService:Create(hrp, TweenInfo.new(0.11, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = upCF }):Play()
	task.delay(0.13, function()
		if player.Parent and player:GetAttribute("OnPullup") == true and hrp.Parent and hrp.Anchored then
			applyPullupLimbPose(character, true, false)
			TweenService:Create(hrp, TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = downCF }):Play()
		end
	end)

	EvPullupAction:FireClient(player, totalGain)
end)

-- C) GİZLİ YÜKSEK ARENA (HARİTADAN GÖRÜNMEZ)
local ARENA_CENTER = Vector3.new(0, 4500, 0)
local ArenaFolder = Instance.new("Folder", ModFolder)
ArenaFolder.Name = "HiddenDuelArena"

local function aPart(n, sh, sz, cf, mat, col, cc)
	local p = Instance.new("Part", ArenaFolder)
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

aPart("ArenaFloor", Enum.PartType.Cylinder, Vector3.new(2, 110, 110), CFrame.new(ARENA_CENTER) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Marble, Color3.fromRGB(42, 46, 56), true)
aPart("ArenaRingGold", Enum.PartType.Cylinder, Vector3.new(2.1, 86, 86), CFrame.new(ARENA_CENTER) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Neon, Color3.fromRGB(255, 195, 75), false)
aPart("ArenaInnerFloor", Enum.PartType.Cylinder, Vector3.new(2.15, 83, 83), CFrame.new(ARENA_CENTER) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Slate, Color3.fromRGB(58, 64, 78), true)
aPart("ArenaCeiling", Enum.PartType.Cylinder, Vector3.new(2, 116, 116), CFrame.new(ARENA_CENTER + Vector3.new(0, 45, 0)) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.SmoothPlastic, Color3.fromRGB(25, 28, 36), true)

for i = 1, 16 do
	local ang = (i / 16) * math.pi * 2
	local pos = ARENA_CENTER + Vector3.new(math.cos(ang) * 53, 22.5, math.sin(ang) * 53)
	aPart("ArenaWall_" .. i, Enum.PartType.Block, Vector3.new(24, 45, 3), CFrame.new(pos) * CFrame.Angles(0, -ang + math.pi / 2, 0), Enum.Material.Concrete, Color3.fromRGB(36, 40, 50), true)
	if i % 2 == 0 then
		local torch = aPart("ArenaTorch_" .. i, Enum.PartType.Ball, Vector3.new(2.5, 2.5, 2.5), CFrame.new(ARENA_CENTER + Vector3.new(math.cos(ang) * 49, 16, math.sin(ang) * 49)), Enum.Material.Neon, Color3.fromRGB(255, 140, 50), false)
		local l = Instance.new("PointLight", torch)
		l.Color = Color3.fromRGB(255, 150, 60)
		l.Range = 45
		l.Brightness = 1.5
	end
end

local function giveArenaSword(holderModel, damageValue, opponentModel)
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
	slashSFX.SoundId = "rbxassetid://12222216"
	slashSFX.Volume = 0.7

	local swingCooldown = false
	local swingActive = false
	local hasHitThisSwing = false

	tool.Activated:Connect(function()
		if swingCooldown or tool.Parent ~= holderModel then return end
		local attackerHumanoid = holderModel:FindFirstChildOfClass("Humanoid")
		local opponentHumanoid = opponentModel and opponentModel:FindFirstChildOfClass("Humanoid")
		if not attackerHumanoid or attackerHumanoid.Health <= 0 or not opponentHumanoid or opponentHumanoid.Health <= 0 then return end

		swingCooldown = true
		swingActive = true
		hasHitThisSwing = false
		slashSFX:Play()
		local animation = Instance.new("StringValue")
		animation.Name = "toolanim"
		animation.Value = "Slash"
		animation.Parent = tool
		Debris:AddItem(animation, 0.2)

		task.delay(0.28, function()
			swingActive = false
		end)
		task.delay(0.45, function()
			swingCooldown = false
		end)
	end)

	handle.Touched:Connect(function(hit)
		if not swingActive or hasHitThisSwing or tool.Parent ~= holderModel then return end
		local victimModel = hit:FindFirstAncestorOfClass("Model")
		if victimModel ~= opponentModel then return end

		local attackerHumanoid = holderModel:FindFirstChildOfClass("Humanoid")
		local victimHumanoid = opponentModel and opponentModel:FindFirstChildOfClass("Humanoid")
		if not attackerHumanoid or attackerHumanoid.Health <= 0 or not victimHumanoid or victimHumanoid.Health <= 0 then return end

		hasHitThisSwing = true
		victimHumanoid:TakeDamage(damageValue)
	end)

	tool.Parent = holderModel
	return tool
end

-- D) 6 NADİRLİKLİ NPC SİSTEMİ
local NPCFolder = Instance.new("Folder", ModFolder)
NPCFolder.Name = "RoamingNPCs"

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

local function rollRarity()
	local r = math.random() * 100
	local acc = 0
	for _, info in ipairs(RARITIES) do
		acc += info.Chance
		if r <= acc then
			return info
		end
	end
	return RARITIES[1]
end

local function spawnBurstEffect(pos, color)
	local holder = Instance.new("Part", ModFolder)
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

local function buildPlainRig(name, spawnPos, rarityInfo, isBoss)
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

-- E) ARENA DÜELLO BAŞLATICI
local function startArenaDuel(player, rarityInfo)
	if player:GetAttribute("InArena") or player:GetAttribute("DuelPending") ~= true then return false end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local ls = player:FindFirstChild("leaderstats")
	if not (hrp and hum and hum.Health > 0 and ls) then return false end

	player:SetAttribute("InArena", true)
	player:SetAttribute("DuelPending", false)
	local returnCF = hrp.CFrame

	local slotOffset = Vector3.new((player.UserId % 5) * 4, 3, -24)
	hrp.CFrame = CFrame.new(ARENA_CENTER + slotOffset, ARENA_CENTER + Vector3.new(0, 3, 24))

	local pPower = math.max(10, ls.Power.Value)
	local rarityMult = { Common = 0.65, Rare = 0.75, Epic = 0.82, Mythic = 0.88, Legendary = 0.92, Godly = 0.95 }
	local mult = rarityMult[rarityInfo.Name] or 0.75

	local bossMaxHP = math.floor(100 + (rarityInfo.ReqPower * 0.05) + (pPower * 0.25))
	local playerSwordDmg = math.max(25, math.floor(bossMaxHP / 4))
	local bossSwordDmg = math.max(8, math.floor(18 * mult))

	local bossPos = ARENA_CENTER + Vector3.new(0, 3, 24)
	local bossNPC, bossHum, bossHRP = buildPlainRig("ArenaRival_" .. player.Name, bossPos, rarityInfo, true)
	bossHum.MaxHealth = bossMaxHP
	bossHum.Health = bossMaxHP
	bossNPC.Parent = ArenaFolder
	spawnBurstEffect(bossPos, rarityInfo.Color)

	local playerSword = giveArenaSword(char, playerSwordDmg, bossNPC)
	hum:EquipTool(playerSword)
	local bossSword = giveArenaSword(bossNPC, bossSwordDmg, char)
	bossHum:EquipTool(bossSword)

	EvNotify:FireClient(player, "ArenaStart", rarityInfo.Name .. " rakiple düello başladı! Kılıcınla saldır!")

	local ended = false
	local function finishDuel(won)
		if ended then return end
		ended = true
		if playerSword and playerSword.Parent then playerSword:Destroy() end
		if bossNPC and bossNPC.Parent then
			spawnBurstEffect(bossHRP.Position, rarityInfo.Color)
			bossNPC:Destroy()
		end
		player:SetAttribute("InArena", false)
		player:SetAttribute("DuelPending", false)
		if player.Parent and player.Character == char and hrp and hrp.Parent then
			hrp.CFrame = returnCF
		end
		if won then
			local bonusLove = math.max(5, math.floor(pPower * 0.12))
			ls.Love.Value += bonusLove
			if player.Parent then EvNotify:FireClient(player, "ArenaWin", "Düelloyu kazandın! (+" .. bonusLove .. " Love)") end
		else
			if player.Parent then EvNotify:FireClient(player, "ArenaLose", "Düelloyu kaybettin! Gücünü artırıp tekrar dene.") end
		end
	end

	task.spawn(function()
		while not ended and bossNPC.Parent and bossHum.Health > 0 and hum.Health > 0 do
			if hrp and hrp.Parent then
				bossHum:MoveTo(hrp.Position)
				if (bossHRP.Position - hrp.Position).Magnitude <= 7 then
					bossSword:Activate()
				end
			end
			task.wait(0.35)
		end
	end)

	bossHum.Died:Connect(function() finishDuel(true) end)
	hum.Died:Connect(function()
		task.wait(0.2)
		finishDuel(false)
	end)
	task.delay(60, function() finishDuel(false) end)
	return true
end

-- F) DİYALOG SEÇENEKLERİ VE NPC DOĞUM YÖNETİMİ
local activeNPCData = {}
local pendingNPCInteractions = {}
local NPC_INTERACTION_TIMEOUT = 30

EvDialogueChoice.OnServerEvent:Connect(function(player, npcModel, choiceIndex)
	if typeof(npcModel) ~= "Instance" or not npcModel:IsA("Model") then return end
	if typeof(choiceIndex) ~= "number" or choiceIndex % 1 ~= 0 or choiceIndex < 1 or choiceIndex > 4 then return end
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

	-- Consume the server-issued interaction before changing any player state.
	pendingNPCInteractions[player] = nil
	player:SetAttribute("DuelPending", true)

	local deltaLove = 0
	if choiceIndex == 1 then
		deltaLove = -math.max(1, math.floor(power.Value / 10))
		love.Value = math.max(0, love.Value + deltaLove)
		EvNotify:FireClient(player, "LoveLoss", "Yanlış cevap! (" .. deltaLove .. " Love)")
	elseif choiceIndex == 2 then
		deltaLove = math.max(1, math.floor(power.Value / 10))
		love.Value += deltaLove
		EvNotify:FireClient(player, "LoveGain", "Güzel sohbet! (+" .. deltaLove .. " Love)")
	elseif choiceIndex == 3 then
		deltaLove = math.max(1, math.floor(power.Value / 8))
		love.Value += deltaLove
		EvNotify:FireClient(player, "LoveGain", "Etkileyici sözler! (+" .. deltaLove .. " Love)")
	else
		deltaLove = math.max(1, math.floor(power.Value / 5))
		love.Value += deltaLove
		EvNotify:FireClient(player, "LoveGain", "Kalbinden vurdun! (+" .. deltaLove .. " Love)")
	end

	task.delay(0.6, function()
		if not player.Parent then return end
		if player:GetAttribute("DuelPending") ~= true or player:GetAttribute("InArena") then return end
		if not startArenaDuel(player, info) then
			player:SetAttribute("DuelPending", false)
		end
	end)
end)

local function spawnSingleRoamingNPC()
	if #NPCFolder:GetChildren() >= 20 then return end

	local rarityInfo = rollRarity()
	local rx = math.random(-130, 130)
	local rz = math.random(-130, 90)
	local spawnPos = Vector3.new(rx, 3.5, rz)

	local npc, hum, hrp = buildPlainRig("NPC_" .. rarityInfo.Name, spawnPos, rarityInfo, false)
	npc.Parent = NPCFolder
	activeNPCData[npc] = rarityInfo
	spawnBurstEffect(spawnPos, rarityInfo.Color)

	local prompt = Instance.new("ProximityPrompt", hrp)
	prompt.ActionText = "Konuş"
	prompt.ObjectText = rarityInfo.Name
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false

	prompt.Triggered:Connect(function(player)
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

	npc.Destroying:Connect(function()
		activeNPCData[npc] = nil
		for player, pending in pairs(pendingNPCInteractions) do
			if pending.npc == npc then
				pendingNPCInteractions[player] = nil
			end
		end
	end)

	task.spawn(function()
		while npc.Parent and hum.Health > 0 do
			local wx = math.clamp(hrp.Position.X + math.random(-35, 35), -145, 145)
			local wz = math.clamp(hrp.Position.Z + math.random(-35, 35), -145, 105)
			hum:MoveTo(Vector3.new(wx, 3.5, wz))
			task.wait(math.random(3, 6))
		end
	end)

	task.delay(120, function()
		if npc and npc.Parent then
			spawnBurstEffect(hrp.Position, rarityInfo.Color)
			activeNPCData[npc] = nil
			npc:Destroy()
			task.wait(0.3)
			spawnSingleRoamingNPC()
		end
	end)
end

for i = 1, 20 do
	task.delay(i * 0.15, spawnSingleRoamingNPC)
end

Players.PlayerRemoving:Connect(function(player)
	pullupCooldowns[player] = nil
	pendingNPCInteractions[player] = nil
	local character = player.Character
	if character then
		savedHumanoidMovement[character] = nil
		savedMotorC0[character] = nil
	end
end)
