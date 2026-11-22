local UIUtils = require(script.Parent.UIUtils)

local DialogueController = {}
DialogueController.__index = DialogueController

function DialogueController.new(context)
	local self = setmetatable({
		context = context,
		connections = {},
		currentNPC = nil,
		dialogueChoiceSent = false,
		destroyed = false,
	}, DialogueController)

	self:_buildDialog()
	return self
end

function DialogueController:_track(connection)
	table.insert(self.connections, connection)
	return connection
end

function DialogueController:_buildDialog()
	local ScreenGui = self.context.ScreenGui

	-- 4 SEÇENEKLİ DİYALOG PENCERESİ
	local DialogFrame = Instance.new("Frame", ScreenGui)
	DialogFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	DialogFrame.Size = UDim2.new(0.88, 0, 0, 248)
	DialogFrame.Position = UDim2.new(0.5, 0, 0.58, 0)
	DialogFrame.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
	DialogFrame.Visible = false
	UIUtils.addSizeConstraints(DialogFrame, 300, 430, 238, 260)

	local dfCorner = Instance.new("UICorner", DialogFrame)
	dfCorner.CornerRadius = UDim.new(0, 12)
	local dfStroke = Instance.new("UIStroke", DialogFrame)
	dfStroke.Color = Color3.fromRGB(255, 115, 175)
	dfStroke.Thickness = 2

	local TitleLbl = Instance.new("TextLabel", DialogFrame)
	TitleLbl.Size = UDim2.new(1, -16, 0, 38)
	TitleLbl.Position = UDim2.new(0, 8, 0, 6)
	TitleLbl.BackgroundTransparency = 1
	TitleLbl.Font = Enum.Font.GothamBold
	TitleLbl.TextSize = 13
	TitleLbl.TextScaled = true
	TitleLbl.TextWrapped = true
	TitleLbl.TextColor3 = Color3.fromRGB(255, 185, 215)
	TitleLbl.Text = "Sohbet Seçeneğini Seç"
	UIUtils.addTextConstraints(TitleLbl, 11, 15)

	local choiceLabels = {
		"Soğuk davran (-Power/10 Love)",
		"Dostça konuş (+Power/10 Love)",
		"Etkileyici konuş (+Power/8 Love)",
		"Romantik konuş (+Power/5 Love)",
	}

	for idx = 1, 4 do
		local btn = Instance.new("TextButton", DialogFrame)
		btn.Size = UDim2.new(1, -18, 0, 44)
		btn.Position = UDim2.new(0, 9, 0, 48 + (idx - 1) * 48)
		btn.BackgroundColor3 = Color3.fromRGB(38, 42, 58)
		btn.Font = Enum.Font.GothamMedium
		btn.TextSize = 12
		btn.TextScaled = true
		btn.TextWrapped = true
		btn.TextColor3 = Color3.fromRGB(245, 245, 255)
		btn.Text = choiceLabels[idx]
		UIUtils.addSizeConstraints(btn, 220, 400, 44, 52)
		UIUtils.addTextConstraints(btn, 11, 14)

		local bc = Instance.new("UICorner", btn)
		bc.CornerRadius = UDim.new(0, 8)

		self:_track(btn.MouseEnter:Connect(function()
			self.context.TweenService:Create(btn, TweenInfo.new(0.15), {
				BackgroundColor3 = Color3.fromRGB(215, 75, 135),
			}):Play()
		end))
		self:_track(btn.MouseLeave:Connect(function()
			self.context.TweenService:Create(btn, TweenInfo.new(0.15), {
				BackgroundColor3 = Color3.fromRGB(38, 42, 58),
			}):Play()
		end))

		self:_track(btn.MouseButton1Click:Connect(function()
			if self.destroyed or self.dialogueChoiceSent then return end
			self.dialogueChoiceSent = true
			if self.currentNPC then
				self.context.EvDialogueChoice:FireServer(self.currentNPC, idx)
			end
			self:_setDialogVisible(false)
			task.delay(1, function()
				self.dialogueChoiceSent = false
			end)
		end))
	end

	self.dialogFrame = DialogFrame
	self.titleLabel = TitleLbl

	self:_track(self.context.EvInteractNPC.OnClientEvent:Connect(function(npcModel, rarityName)
		self.currentNPC = npcModel
		self.dialogueChoiceSent = false
		TitleLbl.Text = "💬 " .. rarityName .. " Karakterle Konuşuyorsun"
		self:_setDialogVisible(true)
		local targetSize = UDim2.new(0.88, 0, 0, 248)
		DialogFrame.Size = UDim2.new(0.78, 0, 0, 232)
		self.context.TweenService:Create(DialogFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = targetSize,
		}):Play()
	end))
end

function DialogueController:_setDialogVisible(visible)
	self.dialogFrame.Visible = visible
	self.context.HUD:SetStatsVisible(not visible)
	if not visible then
		self.currentNPC = nil
	end
end

function DialogueController:Destroy()
	self.destroyed = true
	for _, connection in ipairs(self.connections) do
		connection:Disconnect()
	end
	table.clear(self.connections)
	self.currentNPC = nil
end

return DialogueController
