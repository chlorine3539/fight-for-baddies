local TweenService = game:GetService("TweenService")

local UIUtils = require(script.Parent.UIUtils)

local HUDController = {}
HUDController.__index = HUDController

function HUDController.new(context)
	local self = setmetatable({
		context = context,
		connections = {},
		bannerToken = 0,
		destroyed = false,
	}, HUDController)

	local ScreenGui = context.ScreenGui

	-- SOL ORTA POWER & LOVE GUI PANELİ
	local StatsFrame = Instance.new("Frame", ScreenGui)
	StatsFrame.Size = UDim2.new(0.26, 0, 0, 78)
	StatsFrame.Position = UDim2.new(0.02, 8, 0.45, -39)
	StatsFrame.BackgroundColor3 = Color3.fromRGB(22, 24, 34)
	StatsFrame.BackgroundTransparency = 0.12
	UIUtils.addSizeConstraints(StatsFrame, 150, 220, 74, 86)

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
	PowerLbl.TextSize = 13
	PowerLbl.TextWrapped = true
	PowerLbl.TextXAlignment = Enum.TextXAlignment.Left
	PowerLbl.TextColor3 = Color3.fromRGB(255, 210, 75)
	PowerLbl.Text = "💪 Power: 0"
	UIUtils.addTextConstraints(PowerLbl, 11, 15)

	local LoveLbl = Instance.new("TextLabel", StatsFrame)
	LoveLbl.Size = UDim2.new(1, -16, 0, 30)
	LoveLbl.Position = UDim2.new(0, 10, 0, 38)
	LoveLbl.BackgroundTransparency = 1
	LoveLbl.Font = Enum.Font.GothamBold
	LoveLbl.TextSize = 13
	LoveLbl.TextWrapped = true
	LoveLbl.TextXAlignment = Enum.TextXAlignment.Left
	LoveLbl.TextColor3 = Color3.fromRGB(255, 115, 185)
	LoveLbl.Text = "❤️ Love: 10"
	UIUtils.addTextConstraints(LoveLbl, 11, 15)

	self.statsFrame = StatsFrame

	task.spawn(function()
		local ls = context.LocalPlayer:WaitForChild("leaderstats", 15)
		if not ls or self.destroyed then return end
		local pVal = ls:WaitForChild("Power")
		local lVal = ls:WaitForChild("Love")
		if self.destroyed then return end
		local function refresh()
			if self.destroyed then return end
			PowerLbl.Text = "💪 Power: " .. tostring(pVal.Value)
			LoveLbl.Text = "❤️ Love: " .. tostring(lVal.Value)
		end
		refresh()
		self:_track(pVal.Changed:Connect(refresh))
		self:_track(lVal.Changed:Connect(refresh))
	end)

	-- 2 SANİYELİK KIRMIZI RET & DURUM BİLDİRİMİ
	local BannerLabel = Instance.new("TextLabel", ScreenGui)
	BannerLabel.AnchorPoint = Vector2.new(0.5, 0)
	BannerLabel.Size = UDim2.new(0.62, 0, 0, 42)
	BannerLabel.Position = UDim2.new(0.5, 0, 0.1, 0)
	BannerLabel.BackgroundColor3 = Color3.fromRGB(22, 16, 22)
	BannerLabel.BackgroundTransparency = 1
	BannerLabel.TextTransparency = 1
	BannerLabel.TextStrokeTransparency = 1
	BannerLabel.Font = Enum.Font.GothamBold
	BannerLabel.TextSize = 13
	BannerLabel.TextWrapped = true
	BannerLabel.Text = ""
	UIUtils.addSizeConstraints(BannerLabel, 240, 520, 36, 52)
	UIUtils.addTextConstraints(BannerLabel, 11, 16)

	local BannerCorner = Instance.new("UICorner", BannerLabel)
	BannerCorner.CornerRadius = UDim.new(0, 8)

	self.bannerLabel = BannerLabel

	return self
end

function HUDController:_track(connection)
	table.insert(self.connections, connection)
	return connection
end

function HUDController:SetStatsVisible(visible)
	if self.statsFrame then
		self.statsFrame.Visible = visible
	end
end

function HUDController:ShowBanner(text, color, duration)
	if self.destroyed then return end
	self.bannerToken += 1
	local myToken = self.bannerToken
	local label = self.bannerLabel
	label.Text = text
	label.TextColor3 = color
	label.BackgroundTransparency = 0.35
	label.TextTransparency = 0
	label.TextStrokeTransparency = 0.25

	task.delay(duration or 2, function()
		if self.destroyed or self.bannerToken ~= myToken then return end
		TweenService:Create(label, TweenInfo.new(0.35), {
			TextTransparency = 1,
			TextStrokeTransparency = 1,
			BackgroundTransparency = 1,
		}):Play()
	end)
end

function HUDController:ShowFloatingPopup(text, color)
	if self.destroyed then return end
	local lbl = Instance.new("TextLabel", self.context.ScreenGui)
	lbl.AnchorPoint = Vector2.new(0.5, 0.5)
	lbl.Size = UDim2.new(0.42, 0, 0, 30)
	lbl.Position = UDim2.new(0.5 + (math.random(-8, 8) / 100), 0, 0.55, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 13
	lbl.TextWrapped = true
	lbl.TextColor3 = color
	lbl.TextStrokeTransparency = 0.25
	lbl.Text = text
	UIUtils.addSizeConstraints(lbl, 150, 240, 26, 38)
	UIUtils.addTextConstraints(lbl, 11, 15)

	local tw = TweenService:Create(lbl, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = lbl.Position - UDim2.new(0, 0, 0.12, 0),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	tw:Play()
	local completedConnection
	completedConnection = tw.Completed:Connect(function()
		completedConnection:Disconnect()
		lbl:Destroy()
	end)
end

function HUDController:HandleNotify(kind, message)
	if kind == "ArenaReadyRequest" then return end
	if kind == "Reject" then
		self:ShowBanner(message, Color3.fromRGB(255, 65, 75), 2)
	elseif kind == "LoveGain" then
		self:ShowBanner(message, Color3.fromRGB(255, 125, 190), 2)
		self:ShowFloatingPopup(message, Color3.fromRGB(255, 120, 195))
	elseif kind == "LoveLoss" then
		self:ShowBanner(message, Color3.fromRGB(255, 80, 80), 2)
	elseif kind == "ArenaWin" then
		self:ShowBanner(message, Color3.fromRGB(95, 255, 145), 2.5)
	elseif kind == "ArenaLose" then
		self:ShowBanner(message, Color3.fromRGB(255, 85, 85), 2.5)
	else
		self:ShowBanner(message, Color3.fromRGB(255, 225, 115), 2.2)
	end
end

function HUDController:Destroy()
	self.destroyed = true
	for _, connection in ipairs(self.connections) do
		connection:Disconnect()
	end
	table.clear(self.connections)
end

return HUDController
