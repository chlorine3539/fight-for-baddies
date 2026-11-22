-- ========================================================================
-- 2. İSTEMCİ SCRİPTİ (StarterPlayer -> StarterPlayerScripts -> LocalScript)
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

local isOnPullup = false

-- Tool input events only fire in client-side LocalScripts. Watch the arena
-- blade and forward only an attack request; the server resolves everything.
local characterConnections = {}
local swordConnections = {}

local function isHeldByLocalCharacter(tool)
	local character = LocalPlayer.Character
	return character ~= nil and tool.Parent ~= nil
		and tool:FindFirstAncestorOfClass("Model") == character
end

local function clearArenaSwordWatch()
	for _, connection in ipairs(swordConnections) do
		connection:Disconnect()
	end
	table.clear(swordConnections)
end

local function clearCharacterWatch()
	for _, connection in ipairs(characterConnections) do
		connection:Disconnect()
	end
	table.clear(characterConnections)
	clearArenaSwordWatch()
end

local function watchArenaSword(tool)
	clearArenaSwordWatch()
	if not tool:IsA("Tool") or tool.Name ~= "ArenaBlade" then return end

	table.insert(swordConnections, tool.Activated:Connect(function()
		if isHeldByLocalCharacter(tool) then
			EvArenaAttack:FireServer()
		end
	end))
	table.insert(swordConnections, tool.AncestryChanged:Connect(function()
		if not isHeldByLocalCharacter(tool) then
			clearArenaSwordWatch()
		end
	end))
end

local function bindArenaSwordWatch(character)
	clearCharacterWatch()
	if not character then return end
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") and child.Name == "ArenaBlade" then
			watchArenaSword(child)
			break
		end
	end
	table.insert(characterConnections, character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child.Name == "ArenaBlade" then
			watchArenaSword(child)
		end
	end))
end

if LocalPlayer.Character then
	bindArenaSwordWatch(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(bindArenaSwordWatch)

-- Pull-up poses are evaluated on the client. Upgraded R15 rigs replace the
-- shoulder/elbow Motor6Ds with AnimationConstraints; their Transform is written
-- by the Animator each frame, so procedural layers must be applied in
-- PreSimulation and rebuilt from a saved base instead of accumulating.
local POSE_JOINTS = {
	["Right Shoulder"] = { side = 1, limb = "Shoulder", legacy = true },
	["Left Shoulder"] = { side = -1, limb = "Shoulder", legacy = true },
	["Right Hip"] = { side = 1, limb = "Hip", legacy = true },
	["Left Hip"] = { side = -1, limb = "Hip", legacy = true },
	["RightShoulder"] = { side = 1, limb = "Shoulder" },
	["LeftShoulder"] = { side = -1, limb = "Shoulder" },
	["RightElbow"] = { side = 1, limb = "Elbow" },
	["LeftElbow"] = { side = -1, limb = "Elbow" },
	["RightHip"] = { side = 1, limb = "Leg" },
	["LeftHip"] = { side = -1, limb = "Leg" },
}

local pullupPose = {
	active = false,
	character = nil,
	animator = nil,
	animateScript = nil,
	animateWasDisabled = false,
	joints = {},
	phase = "hang",
	phaseToken = 0,
	appliedToken = 0,
	phaseStartedAt = 0,
	deathConnection = nil,
}
local poseSimulationConnection = nil

local function legacyC0ForPose(config, isUp)
	if config.limb == "Shoulder" then
		local pitch = isUp and math.rad(130) or math.rad(175)
		return CFrame.new(config.side, 0.7, 0) * CFrame.Angles(pitch, math.rad(90 * config.side), 0)
	end
	local bend = isUp and math.rad(25) or math.rad(10)
	return CFrame.new(config.side, -1, 0) * CFrame.Angles(-bend, math.rad(90 * config.side), 0)
end

local function constraintOffsetForPose(config, isUp)
	if config.limb == "Shoulder" then
		local pitch = isUp and math.rad(135) or math.rad(175)
		return CFrame.Angles(pitch, 0, math.rad(-6 * config.side))
	elseif config.limb == "Elbow" then
		return CFrame.Angles(math.rad(isUp and 65 or 8), 0, 0)
	end
	return CFrame.Angles(math.rad(isUp and -25 or -10), 0, 0)
end

local stopPullupPose

local function applyPullupPoseFrame()
	local pose = pullupPose
	if not pose.active then return end
	if not pose.character or not pose.character.Parent then
		stopPullupPose()
		return
	end
	if pose.animator and pose.animator.EvaluationThrottled then return end
	pose.appliedToken = pose.phaseToken

	local isUp = pose.phase == "up"
	local alpha = math.clamp((os.clock() - pose.phaseStartedAt) / 0.11, 0, 1)
	alpha = alpha * alpha * (3 - 2 * alpha)
	for _, entry in ipairs(pose.joints) do
		local joint = entry.joint
		if not joint.Parent then
			stopPullupPose()
			return
		end
		if entry.usesC0 then
			joint.C0 = entry.baseC0:Lerp(legacyC0ForPose(entry.config, isUp), alpha)
		else
			-- The Animator owns the base Transform; layer only the procedural
			-- offset from identity so it cannot bake in an arbitrary idle pose
			-- or accumulate across frames.
			joint.Transform = CFrame.identity:Lerp(constraintOffsetForPose(entry.config, isUp), alpha)
		end
	end
end

stopPullupPose = function()
	if poseSimulationConnection then
		poseSimulationConnection:Disconnect()
		poseSimulationConnection = nil
	end
	local pose = pullupPose
	if pose.deathConnection then
		pose.deathConnection:Disconnect()
		pose.deathConnection = nil
	end
	if not pose.active then return end
	pose.active = false
	pose.phaseToken += 1
	for _, entry in ipairs(pose.joints) do
		if entry.joint.Parent then
			pcall(function()
				if entry.usesC0 then
					entry.joint.C0 = entry.baseC0
				else
					entry.joint.Transform = entry.restoreTransform
				end
			end)
		end
	end
	if pose.animateScript and pose.animateScript.Parent then
		pcall(function()
			pose.animateScript.Disabled = pose.animateWasDisabled
		end)
	end
	table.clear(pose.joints)
	pose.character = nil
	pose.animator = nil
	pose.animateScript = nil
end

local function startPullupPose(character)
	stopPullupPose()
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end

	local pose = pullupPose
	pose.active = true
	pose.character = character
	pose.animator = humanoid:FindFirstChildOfClass("Animator")
	pose.phase = "hang"
	pose.phaseToken += 1
	pose.appliedToken = 0
	pose.phaseStartedAt = os.clock()
	pose.deathConnection = humanoid.Died:Connect(stopPullupPose)

	local animateScript = character:FindFirstChild("Animate")
	pose.animateScript = animateScript
	if animateScript then
		pose.animateWasDisabled = animateScript.Disabled
		animateScript.Disabled = true
	end
	for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
		track:Stop(0)
	end

	for _, descendant in ipairs(character:GetDescendants()) do
		local config = POSE_JOINTS[descendant.Name]
		if config and (descendant:IsA("Motor6D") or descendant:IsA("AnimationConstraint")) then
			if config.legacy and descendant:IsA("Motor6D") then
				table.insert(pose.joints, {
					joint = descendant, config = config, usesC0 = true, baseC0 = descendant.C0,
				})
			else
				table.insert(pose.joints, {
					joint = descendant, config = config, usesC0 = false,
					restoreTransform = descendant.Transform,
				})
			end
		end
	end

	if not poseSimulationConnection then
		poseSimulationConnection = RunService.PreSimulation:Connect(function()
			local ok, err = pcall(applyPullupPoseFrame)
			if not ok then
				warn("[Simulator] pull-up pose error: " .. tostring(err))
				stopPullupPose()
			end
		end)
	end
	return true
end

local function setPullupPosePhase(isUp)
	if not pullupPose.active then return end
	pullupPose.phase = isUp and "up" or "hang"
	pullupPose.phaseToken += 1
	pullupPose.phaseStartedAt = os.clock()
	local token = pullupPose.phaseToken
	if isUp then
		task.spawn(function()
			while pullupPose.active and pullupPose.phaseToken == token
				and pullupPose.appliedToken < token do
				task.wait()
			end
			task.wait(0.13)
			if pullupPose.active and pullupPose.phaseToken == token then
				pullupPose.phase = "hang"
				pullupPose.phaseToken += 1
				pullupPose.phaseStartedAt = os.clock()
			end
		end)
	end
end

LocalPlayer.CharacterRemoving:Connect(function()
	stopPullupPose()
end)

-- Diğer oyuncuların barfiks çektiğini gizleme + NPC'lere yaklaştıkça yazıyı büyütme
RunService.RenderStepped:Connect(function()
	local myChar = LocalPlayer.Character
	local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local hide = plr:GetAttribute("OnPullup") == true
			for _, desc in ipairs(plr.Character:GetDescendants()) do
				if desc:IsA("BasePart") or desc:IsA("Decal") then
					if desc.Name ~= "HumanoidRootPart" then
						desc.LocalTransparencyModifier = hide and 1 or 0
					end
				elseif desc:IsA("BillboardGui") then
					desc.Enabled = not hide
				end
			end
		end
	end

	if myHRP then
		local mapFolder = workspace:FindFirstChild("SimulatorBaseplateMap")
		local sysFolder = mapFolder and mapFolder:FindFirstChild("SimulatorSystems")
		local npcFolder = sysFolder and sysFolder:FindFirstChild("RoamingNPCs")
		if npcFolder then
			for _, npc in ipairs(npcFolder:GetChildren()) do
				local head = npc:FindFirstChild("Head")
				local tag = head and head:FindFirstChild("RarityTag")
				if head and tag then
					local dist = (head.Position - myHRP.Position).Magnitude
					local alpha = math.clamp(1 - ((dist - 5) / 35), 0, 1)
					local scale = 0.8 + alpha * 0.65
					tag.Size = UDim2.new(0, math.floor(110 * scale), 0, math.floor(28 * scale))
				end
			end
		end
	end
end)

local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "SimulatorHUD"
ScreenGui.ResetOnSpawn = false

-- SOL ORTA POWER & LOVE GUI PANELİ
local StatsFrame = Instance.new("Frame", ScreenGui)
StatsFrame.Size = UDim2.new(0, 180, 0, 78)
StatsFrame.Position = UDim2.new(0, 16, 0.45, -39)
StatsFrame.BackgroundColor3 = Color3.fromRGB(22, 24, 34)
StatsFrame.BackgroundTransparency = 0.12

local stCorner = Instance.new("UICorner", StatsFrame)
stCorner.CornerRadius = UDim.new(0, 10)
local stStroke = Instance.new("UIStroke", StatsFrame)
stStroke.Color = Color3.fromRGB(255, 195, 75)
stStroke.Thickness = 1.5

local PowerLbl = Instance.new("TextLabel", StatsFrame)
PowerLbl.Size = UDim2.new(1, -16, 0, 30)
PowerLbl.Position = UDim2.new(0, 10, 0, 6)
PowerLbl.BackgroundTransparency = 1
PowerLbl.Font = Enum.Font.GothamBold
PowerLbl.TextSize = 14
PowerLbl.TextXAlignment = Enum.TextXAlignment.Left
PowerLbl.TextColor3 = Color3.fromRGB(255, 210, 75)
PowerLbl.Text = "💪 Power: 0"

local LoveLbl = Instance.new("TextLabel", StatsFrame)
LoveLbl.Size = UDim2.new(1, -16, 0, 30)
LoveLbl.Position = UDim2.new(0, 10, 0, 38)
LoveLbl.BackgroundTransparency = 1
LoveLbl.Font = Enum.Font.GothamBold
LoveLbl.TextSize = 14
LoveLbl.TextXAlignment = Enum.TextXAlignment.Left
LoveLbl.TextColor3 = Color3.fromRGB(255, 115, 185)
LoveLbl.Text = "❤️ Love: 10"

task.spawn(function()
	local ls = LocalPlayer:WaitForChild("leaderstats", 15)
	if ls then
		local pVal = ls:WaitForChild("Power")
		local lVal = ls:WaitForChild("Love")
		local function refresh()
			PowerLbl.Text = "💪 Power: " .. tostring(pVal.Value)
			LoveLbl.Text = "❤️ Love: " .. tostring(lVal.Value)
		end
		refresh()
		pVal.Changed:Connect(refresh)
		lVal.Changed:Connect(refresh)
	end
end)

-- BARFİKS KONTROL PANELİ (TIKLA & İN BUTONU)
local PullupPanel = Instance.new("Frame", ScreenGui)
PullupPanel.Size = UDim2.new(0, 260, 0, 72)
PullupPanel.Position = UDim2.new(0.5, -130, 0.78, 0)
PullupPanel.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
PullupPanel.Visible = false

local ppCorner = Instance.new("UICorner", PullupPanel)
ppCorner.CornerRadius = UDim.new(0, 10)

local PullupHint = Instance.new("TextLabel", PullupPanel)
PullupHint.Size = UDim2.new(1, -12, 0, 24)
PullupHint.Position = UDim2.new(0, 6, 0, 5)
PullupHint.BackgroundTransparency = 1
PullupHint.Font = Enum.Font.GothamSemibold
PullupHint.TextSize = 12
PullupHint.TextColor3 = Color3.fromRGB(255, 220, 110)
PullupHint.Text = "Ekrana Tıklayarak Barfiks Çek!"

local ExitPullupBtn = Instance.new("TextButton", PullupPanel)
ExitPullupBtn.Size = UDim2.new(0, 175, 0, 32)
ExitPullupBtn.Position = UDim2.new(0.5, -87, 0, 33)
ExitPullupBtn.BackgroundColor3 = Color3.fromRGB(215, 65, 75)
ExitPullupBtn.Font = Enum.Font.GothamBold
ExitPullupBtn.TextSize = 13
ExitPullupBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ExitPullupBtn.Text = "Barfiksten İn (E / Space)"

local epCorner = Instance.new("UICorner", ExitPullupBtn)
epCorner.CornerRadius = UDim.new(0, 8)

local exitRequestPending = false

local function setPullupState(isOn)
	isOnPullup = (isOn == true)
	PullupPanel.Visible = isOnPullup

	local mapFolder = workspace:FindFirstChild("SimulatorBaseplateMap")
	local sysFolder = mapFolder and mapFolder:FindFirstChild("SimulatorSystems")
	local station = sysFolder and sysFolder:FindFirstChild("GymPullupStation")
	local bar = station and station:FindFirstChild("PullupBar")
	local prompt = bar and bar:FindFirstChildOfClass("ProximityPrompt")
	if prompt then prompt.Enabled = not isOnPullup end
end

local function requestExitPullup()
	if not isOnPullup or exitRequestPending then return end
	exitRequestPending = true
	EvTogglePullup:FireServer(false)
	task.delay(1.5, function()
		exitRequestPending = false
	end)
end

ExitPullupBtn.MouseButton1Click:Connect(requestExitPullup)

EvTogglePullup.OnClientEvent:Connect(function(isOn)
	exitRequestPending = false
	setPullupState(isOn)
	if isOn then
		if not pullupPose.active then
			local character = LocalPlayer.Character
			if not startPullupPose(character) then
				task.spawn(function()
					local humanoid = character and character:WaitForChild("Humanoid", 5)
					if humanoid and LocalPlayer:GetAttribute("OnPullup") == true
						and not pullupPose.active then
						startPullupPose(character)
					end
				end)
			end
		end
	else
		stopPullupPose()
	end
end)

LocalPlayer.CharacterAdded:Connect(function()
	exitRequestPending = false
	stopPullupPose()
	setPullupState(false)
end)

-- 2 SANİYELİK KIRMIZI RET & DURUM BİLDİRİMİ
local BannerLabel = Instance.new("TextLabel", ScreenGui)
BannerLabel.Size = UDim2.new(0.46, 0, 0, 34)
BannerLabel.Position = UDim2.new(0.27, 0, 0.14, 0)
BannerLabel.BackgroundColor3 = Color3.fromRGB(22, 16, 22)
BannerLabel.BackgroundTransparency = 1
BannerLabel.TextTransparency = 1
BannerLabel.TextStrokeTransparency = 1
BannerLabel.Font = Enum.Font.GothamBold
BannerLabel.TextSize = 14
BannerLabel.TextWrapped = true
BannerLabel.Text = ""

local BannerCorner = Instance.new("UICorner", BannerLabel)
BannerCorner.CornerRadius = UDim.new(0, 8)

local bannerToken = 0
local function showBanner(text, color, duration)
	bannerToken += 1
	local myToken = bannerToken
	BannerLabel.Text = text
	BannerLabel.TextColor3 = color
	BannerLabel.BackgroundTransparency = 0.35
	BannerLabel.TextTransparency = 0
	BannerLabel.TextStrokeTransparency = 0.25

	task.delay(duration or 2, function()
		if bannerToken ~= myToken then return end
		TweenService:Create(BannerLabel, TweenInfo.new(0.35), {
			TextTransparency = 1,
			TextStrokeTransparency = 1,
			BackgroundTransparency = 1,
		}):Play()
	end)
end

local function spawnFloatingPopup(text, color)
	local lbl = Instance.new("TextLabel", ScreenGui)
	lbl.Size = UDim2.new(0, 150, 0, 26)
	lbl.Position = UDim2.new(0.5 + (math.random(-10, 10) / 100), -75, 0.56, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 15
	lbl.TextColor3 = color
	lbl.TextStrokeTransparency = 0.25
	lbl.Text = text

	local tw = TweenService:Create(lbl, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = lbl.Position - UDim2.new(0, 0, 0.13, 0),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	tw:Play()
	tw.Completed:Connect(function() lbl:Destroy() end)
end

-- 4 SEÇENEKLİ DİYALOG PENCERESİ
local DialogFrame = Instance.new("Frame", ScreenGui)
DialogFrame.Size = UDim2.new(0, 410, 0, 225)
DialogFrame.Position = UDim2.new(0.5, -205, 0.64, 0)
DialogFrame.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
DialogFrame.Visible = false

local dfCorner = Instance.new("UICorner", DialogFrame)
dfCorner.CornerRadius = UDim.new(0, 12)
local dfStroke = Instance.new("UIStroke", DialogFrame)
dfStroke.Color = Color3.fromRGB(255, 115, 175)
dfStroke.Thickness = 2

local TitleLbl = Instance.new("TextLabel", DialogFrame)
TitleLbl.Size = UDim2.new(1, -20, 0, 32)
TitleLbl.Position = UDim2.new(0, 10, 0, 8)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextSize = 15
TitleLbl.TextColor3 = Color3.fromRGB(255, 185, 215)
TitleLbl.Text = "Sohbet Seçeneğini Seç"

local currentNPC = nil
local choiceLabels = {
	"Soğuk davran (-Power/10 Love)",
	"Dostça konuş (+Power/10 Love)",
	"Etkileyici konuş (+Power/8 Love)",
	"Romantik konuş (+Power/5 Love)",
}

for idx = 1, 4 do
	local btn = Instance.new("TextButton", DialogFrame)
	btn.Size = UDim2.new(1, -22, 0, 36)
	btn.Position = UDim2.new(0, 11, 0, 44 + (idx - 1) * 42)
	btn.BackgroundColor3 = Color3.fromRGB(38, 42, 58)
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 12
	btn.TextColor3 = Color3.fromRGB(245, 245, 255)
	btn.Text = choiceLabels[idx]

	local bc = Instance.new("UICorner", btn)
	bc.CornerRadius = UDim.new(0, 8)

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(215, 75, 135) }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(38, 42, 58) }):Play()
	end)

	btn.MouseButton1Click:Connect(function()
		if currentNPC then
			EvDialogueChoice:FireServer(currentNPC, idx)
		end
		DialogFrame.Visible = false
		currentNPC = nil
	end)
end

EvInteractNPC.OnClientEvent:Connect(function(npcModel, rarityName)
	currentNPC = npcModel
	TitleLbl.Text = "💬 " .. rarityName .. " Karakterle Konuşuyorsun"
	DialogFrame.Size = UDim2.new(0, 370, 0, 200)
	DialogFrame.Visible = true
	TweenService:Create(DialogFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 410, 0, 225),
	}):Play()
end)

-- TIKLAMA, E VE SPACE TUŞU GİRDİLERİ
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if isOnPullup then
		if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.Space then
			requestExitPullup()
			return
		end
		if not gameProcessed and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			EvPullupAction:FireServer()
		end
	end
end)

EvPullupAction.OnClientEvent:Connect(function(gainedPower)
	setPullupPosePhase(true)
	spawnFloatingPopup("+" .. tostring(gainedPower) .. " Power 💪", Color3.fromRGB(255, 210, 65))
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then
		local ring = Instance.new("Part", workspace)
		ring.Shape = Enum.PartType.Cylinder
		ring.Size = Vector3.new(0.15, 1.8, 1.8)
		ring.CFrame = hrp.CFrame * CFrame.Angles(0, 0, math.rad(90))
		ring.Anchored = true
		ring.CanCollide = false
		ring.Material = Enum.Material.Neon
		ring.Color = Color3.fromRGB(255, 195, 65)
		ring.Transparency = 0.3

		local tw = TweenService:Create(ring, TweenInfo.new(0.32), {
			Size = Vector3.new(0.08, 8.5, 8.5),
			Transparency = 1,
		})
		tw:Play()
		tw.Completed:Connect(function() ring:Destroy() end)
	end
end)

EvNotify.OnClientEvent:Connect(function(kind, message)
	if kind == "Reject" then
		showBanner(message, Color3.fromRGB(255, 65, 75), 2)
	elseif kind == "LoveGain" then
		showBanner(message, Color3.fromRGB(255, 125, 190), 2)
		spawnFloatingPopup(message, Color3.fromRGB(255, 120, 195))
	elseif kind == "LoveLoss" then
		showBanner(message, Color3.fromRGB(255, 80, 80), 2)
	elseif kind == "ArenaWin" then
		showBanner(message, Color3.fromRGB(95, 255, 145), 2.5)
	elseif kind == "ArenaLose" then
		showBanner(message, Color3.fromRGB(255, 85, 85), 2.5)
	elseif kind == "ArenaReadyRequest" then
		-- Arena shells are server-created; wait for the locally streamed floor
		-- before telling the server combat can start.
		task.spawn(function()
			local slot = message
			local map = workspace:WaitForChild("SimulatorBaseplateMap", 8)
			local systems = map and map:WaitForChild("SimulatorSystems", 8)
			local arenaRoot = systems and systems:WaitForChild("HiddenDuelArena", 8)
			local container = arenaRoot and (slot == 1 and arenaRoot
				or arenaRoot:WaitForChild("DuelArena_" .. tostring(slot), 8))
			local floor = container and container:WaitForChild("ArenaFloor_" .. tostring(slot), 8)
			if floor then
				EvArenaReady:FireServer(slot)
			end
		end)
	else
		showBanner(message, Color3.fromRGB(255, 225, 115), 2.2)
	end
end)