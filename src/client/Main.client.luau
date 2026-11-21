local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("GameRemotes")
local stateRemote = remotes:WaitForChild("StateUpdate")
local requestStateRemote = remotes:WaitForChild("RequestState")
local attackRemote = remotes:WaitForChild("Attack")
local equipRemote = remotes:WaitForChild("EquipCompanion")

local Characters = require(
	ReplicatedStorage:WaitForChild("RojoShared"):WaitForChild("Config"):WaitForChild("Characters")
)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GameHUD"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "StatusPanel"
panel.Position = UDim2.fromOffset(18, 18)
panel.Size = UDim2.fromOffset(330, 238)
panel.BackgroundColor3 = Color3.fromRGB(24, 27, 36)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = panel

local panelPadding = Instance.new("UIPadding")
panelPadding.PaddingTop = UDim.new(0, 12)
panelPadding.PaddingBottom = UDim.new(0, 10)
panelPadding.PaddingLeft = UDim.new(0, 12)
panelPadding.PaddingRight = UDim.new(0, 12)
panelPadding.Parent = panel

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "Status"
statusLabel.Size = UDim2.new(1, 0, 0, 28)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Love: 0   |   Companion: None"
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 15
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = panel

local collectionTitle = Instance.new("TextLabel")
collectionTitle.Size = UDim2.new(1, 0, 0, 22)
collectionTitle.Position = UDim2.fromOffset(0, 34)
collectionTitle.BackgroundTransparency = 1
collectionTitle.Text = "Your companions"
collectionTitle.TextColor3 = Color3.fromRGB(210, 218, 232)
collectionTitle.Font = Enum.Font.GothamSemibold
collectionTitle.TextSize = 13
collectionTitle.TextXAlignment = Enum.TextXAlignment.Left
collectionTitle.Parent = panel

local collectionList = Instance.new("ScrollingFrame")
collectionList.Name = "Collection"
collectionList.Position = UDim2.fromOffset(0, 60)
collectionList.Size = UDim2.new(1, 0, 0, 104)
collectionList.BackgroundColor3 = Color3.fromRGB(33, 37, 48)
collectionList.BackgroundTransparency = 0.1
collectionList.BorderSizePixel = 0
collectionList.ScrollBarThickness = 4
collectionList.CanvasSize = UDim2.fromOffset(0, 0)
collectionList.Parent = panel

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 6)
listCorner.Parent = collectionList

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 5)
listPadding.PaddingBottom = UDim.new(0, 5)
listPadding.PaddingLeft = UDim.new(0, 5)
listPadding.PaddingRight = UDim.new(0, 5)
listPadding.Parent = collectionList

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = collectionList

local messageLabel = Instance.new("TextLabel")
messageLabel.Name = "Message"
messageLabel.Position = UDim2.fromOffset(0, 172)
messageLabel.Size = UDim2.new(1, 0, 0, 48)
messageLabel.BackgroundTransparency = 1
messageLabel.Text = "Walk up to a character. Press E to talk and F to recruit."
messageLabel.TextColor3 = Color3.fromRGB(190, 205, 225)
messageLabel.Font = Enum.Font.Gotham
messageLabel.TextSize = 12
messageLabel.TextWrapped = true
messageLabel.TextXAlignment = Enum.TextXAlignment.Left
messageLabel.TextYAlignment = Enum.TextYAlignment.Top
messageLabel.Parent = panel

local attackButton = Instance.new("TextButton")
attackButton.Name = "AttackButton"
attackButton.AnchorPoint = Vector2.new(0.5, 1)
attackButton.Position = UDim2.new(0.5, 0, 1, -24)
attackButton.Size = UDim2.fromOffset(190, 46)
attackButton.BackgroundColor3 = Color3.fromRGB(174, 70, 70)
attackButton.BorderSizePixel = 0
attackButton.Text = "ATTACK  [Q]"
attackButton.TextColor3 = Color3.fromRGB(255, 255, 255)
attackButton.Font = Enum.Font.GothamBold
attackButton.TextSize = 15
attackButton.Parent = screenGui

local attackCorner = Instance.new("UICorner")
attackCorner.CornerRadius = UDim.new(0, 9)
attackCorner.Parent = attackButton

local function attack()
	attackRemote:FireServer()
end

attackButton.Activated:Connect(attack)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Q then
		attack()
	end
end)

local function rebuildCollection(state)
	for _, child in ipairs(collectionList:GetChildren()) do
		if child:IsA("TextButton") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	local owned = state.ownedCharacters or {}
	if #owned == 0 then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, -4, 0, 30)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "No companions yet. Talk to someone!"
		emptyLabel.TextColor3 = Color3.fromRGB(165, 175, 190)
		emptyLabel.Font = Enum.Font.Gotham
		emptyLabel.TextSize = 12
		emptyLabel.Parent = collectionList
	else
		for index, characterId in ipairs(owned) do
			local character = Characters.ById[characterId]
			local displayName = character and character.displayName or characterId
			local isEquipped = state.equippedCompanion == characterId

			local button = Instance.new("TextButton")
			button.Name = "Equip_" .. characterId
			button.Size = UDim2.new(1, -4, 0, 30)
			button.LayoutOrder = index
			button.BackgroundColor3 = isEquipped and Color3.fromRGB(62, 111, 91) or Color3.fromRGB(55, 62, 78)
			button.BorderSizePixel = 0
			button.Text = isEquipped and (displayName .. "  •  Equipped") or ("Equip " .. displayName)
			button.TextColor3 = Color3.fromRGB(245, 247, 250)
			button.Font = Enum.Font.GothamSemibold
			button.TextSize = 12
			button.Parent = collectionList

			local buttonCorner = Instance.new("UICorner")
			buttonCorner.CornerRadius = UDim.new(0, 5)
			buttonCorner.Parent = button

			button.Activated:Connect(function()
				equipRemote:FireServer(characterId)
			end)
		end
	end

	task.defer(function()
		collectionList.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 10)
	end)
end

stateRemote.OnClientEvent:Connect(function(state, message)
	local companionName = "None"
	if state.equippedCompanion then
		local companion = Characters.ById[state.equippedCompanion]
		companionName = companion and companion.displayName or state.equippedCompanion
	end

	statusLabel.Text = string.format("Love: %d   |   Companion: %s", state.love or 0, companionName)
	if message and message ~= "" then
		messageLabel.Text = message
	end
	rebuildCollection(state)
end)

requestStateRemote:FireServer()
