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

local GYM_POS = Vector3.new(-68, 0, 130)
local isOnPullup = false
local pullupProgress = 0
local targetProgress = 0

-- Tüm Motor6D eklemlerini isme göre hızlı bulma yardımcısı
local function getJoint(char, jointName)
	for _, desc in ipairs(char:GetDescendants()) do
		if desc:IsA("Motor6D") and desc.Name == jointName then
			return desc
		end
	end
	return nil
end

-- Her fizik karesinde Animator'ı ezip kol/bacak/gövde barfiks animasyonunu oynat
RunService.Stepped:Connect(function(_, dt)
	local char = LocalPlayer.Character
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")

	-- Prompt'u barfiksteyken gizle ki E tuşu tekrar barfikse sokmasın
	local mapFolder = workspace:FindFirstChild("SimulatorBaseplateMap")
	local sysFolder = mapFolder and mapFolder:FindFirstChild("SimulatorSystems")
	local pullupStation = sysFolder and sysFolder:FindFirstChild("GymPullupStation")
	local bar = pullupStation and pullupStation:FindFirstChild("PullupBar")
	local prompt = bar and bar:FindFirstChild("PullupBarPrompt")
	if prompt then
		prompt.Enabled = not isOnPullup
	end

	if isOnPullup and hrp and hum then
		-- Varsayılan animasyonları durdur
		for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
			track:Stop(0)
		end

		-- Yumuşak yukarı-aşağı geçiş
		pullupProgress = pullupProgress + (targetProgress - pullupProgress) * math.clamp(dt * 18, 0, 1)
		if targetProgress > 0.5 and pullupProgress > 0.9 then
			targetProgress = 0
		end

		-- Gövdeyi barın altında yukarı çek ve geri sal
		local yPos = 7.7 + (pullupProgress * 1.85)
		local zPos = 0.25 - (pullupProgress * 0.1)
		local bodyPitch = math.rad(4 - pullupProgress * 12)
		hrp.CFrame = CFrame.new(GYM_POS + Vector3.new(0, yPos, zPos)) * CFrame.Angles(bodyPitch, 0, 0)

		-- R15 Eklemleri (Transform üzerinden kesin çalışır)
		local rShoulder = getJoint(char, "RightShoulder")
		local lShoulder = getJoint(char, "LeftShoulder")
		local rElbow = getJoint(char, "RightElbow")
		local lElbow = getJoint(char, "LeftElbow")
		local rHip = getJoint(char, "RightHip")
		local lHip = getJoint(char, "LeftHip")
		local rKnee = getJoint(char, "RightKnee")
		local lKnee = getJoint(char, "LeftKnee")

		if rShoulder and lShoulder then
			-- Kolları 175 derece yukarı bara uzat, çekerken 125 dereceye indir
			local shoulderAngle = math.rad(175 - pullupProgress * 50)
			local elbowAngle = math.rad(10 + pullupProgress * 85)
			local kneeAngle = math.rad(15 + pullupProgress * 30)

			rShoulder.Transform = CFrame.Angles(shoulderAngle, 0, math.rad(-8))
			lShoulder.Transform = CFrame.Angles(shoulderAngle, 0, math.rad(8))
			if rElbow then rElbow.Transform = CFrame.Angles(elbowAngle, 0, 0) end
			if lElbow then lElbow.Transform = CFrame.Angles(elbowAngle, 0, 0) end
			if rHip then rHip.Transform = CFrame.Angles(kneeAngle, 0, 0) end
			if lHip then lHip.Transform = CFrame.Angles(kneeAngle, 0, 0) end
			if rKnee then rKnee.Transform = CFrame.Angles(-kneeAngle * 1.4, 0, 0) end
			if lKnee then lKnee.Transform = CFrame.Angles(-kneeAngle * 1.4, 0, 0) end
		else
			-- R6 Eklemleri
			local rs = getJoint(char, "Right Shoulder")
			local ls = getJoint(char, "Left Shoulder")
			local rh = getJoint(char, "Right Hip")
			local lh = getJoint(char, "Left Hip")
			if rs and ls then
				local armAng = math.rad(175 - pullupProgress * 55)
				local legAng = math.rad(15 + pullupProgress * 25)
				rs.Transform = CFrame.Angles(0, 0, armAng)
				ls.Transform = CFrame.Angles(0, 0, -armAng)
				if rh then rh.Transform = CFrame.Angles(0, 0, -legAng) end
				if lh then lh.Transform = CFrame.Angles(0, 0, legAng) end
			end
		end
	else
		pullupProgress = 0
		targetProgress = 0
	end
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

local function requestExitPullup()
	if not isOnPullup then return end
	isOnPullup = false
	PullupPanel.Visible = false
	EvTogglePullup:FireServer(false)
end

ExitPullupBtn.MouseButton1Click:Connect(requestExitPullup)

EvTogglePullup.OnClientEvent:Connect(function(isOn)
	isOnPullup = (isOn == true)
	PullupPanel.Visible = isOnPullup
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
	"1. [Diyalog Seçeneği 1 - Sonra Düzenlenecek] (-1/10 Güç Love)",
	"2. [Diyalog Seçeneği 2 - Sonra Düzenlenecek] (+1/10 Güç Love)",
	"3. [Diyalog Seçeneği 3 - Sonra Düzenlenecek] (+1/8 Güç Love)",
	"4. [Diyalog Seçeneği 4 - Sonra Düzenlenecek] (+1/5 Güç Love)",
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
			targetProgress = 1
			EvPullupAction:FireServer()
		end
	end
end)

EvPullupAction.OnClientEvent:Connect(function(gainedPower)
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
	else
		showBanner(message, Color3.fromRGB(255, 225, 115), 2.2)
	end
end)