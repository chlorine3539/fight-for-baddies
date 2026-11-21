local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("RojoShared")
local Characters = require(Shared:WaitForChild("Config"):WaitForChild("Characters"))
local Areas = require(Shared:WaitForChild("Config"):WaitForChild("Areas"))

local CharacterSpawnService = {}
local activeCharacters = {}
local occupiedSpawns = {}
local characterFolder

local function createPart(model, name, size, position, color, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	if shape then
		part.Shape = shape
	end
	part.Parent = model
	return part
end

local function findFreeSpawn()
	local positions = Areas.StarterArea.CharacterSpawnPositions
	for index, position in ipairs(positions) do
		if not occupiedSpawns[index] then
			return index, position
		end
	end
	return nil, nil
end

local function isPlayerNear(player, part)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and (root.Position - part.Position).Magnitude <= 12
end

local function spawnCharacter(characterId, onTalk, onRecruit)
	if activeCharacters[characterId] then
		return
	end

	local character = Characters.ById[characterId]
	if not character then
		return
	end

	local spawnIndex, groundPosition = findFreeSpawn()
	if not spawnIndex then
		return
	end

	occupiedSpawns[spawnIndex] = characterId

	local model = Instance.new("Model")
	model.Name = "Character_" .. characterId
	model:SetAttribute("CharacterId", characterId)

	local bodyColor = character.color
	local torso = createPart(
		model,
		"Torso",
		Vector3.new(2, 2.8, 1),
		groundPosition + Vector3.new(0, 2.2, 0),
		bodyColor
	)
	createPart(
		model,
		"Head",
		Vector3.new(1.45, 1.45, 1.45),
		groundPosition + Vector3.new(0, 4.35, 0),
		Color3.fromRGB(245, 213, 190),
		Enum.PartType.Ball
	)
	createPart(
		model,
		"LeftArm",
		Vector3.new(0.65, 2.3, 0.65),
		groundPosition + Vector3.new(-1.3, 2.2, 0),
		bodyColor
	)
	createPart(
		model,
		"RightArm",
		Vector3.new(0.65, 2.3, 0.65),
		groundPosition + Vector3.new(1.3, 2.2, 0),
		bodyColor
	)
	createPart(
		model,
		"LeftLeg",
		Vector3.new(0.8, 1.6, 0.8),
		groundPosition + Vector3.new(-0.48, 0.8, 0),
		Color3.fromRGB(45, 48, 58)
	)
	createPart(
		model,
		"RightLeg",
		Vector3.new(0.8, 1.6, 0.8),
		groundPosition + Vector3.new(0.48, 0.8, 0),
		Color3.fromRGB(45, 48, 58)
	)
	model.PrimaryPart = torso

	local head = model:FindFirstChild("Head")
	local nameplate = Instance.new("BillboardGui")
	nameplate.Name = "Nameplate"
	nameplate.Adornee = head
	nameplate.Size = UDim2.fromOffset(190, 48)
	nameplate.StudsOffset = Vector3.new(0, 1.15, 0)
	nameplate.AlwaysOnTop = true
	nameplate.Parent = model

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.fromScale(1, 1)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = string.format("%s\n%s", character.displayName, character.rarity)
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.35
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.Parent = nameplate

	local talkPrompt = Instance.new("ProximityPrompt")
	talkPrompt.Name = "TalkPrompt"
	talkPrompt.ActionText = "Talk (+Love)"
	talkPrompt.ObjectText = character.displayName
	talkPrompt.KeyboardKeyCode = Enum.KeyCode.E
	talkPrompt.HoldDuration = 0
	talkPrompt.MaxActivationDistance = 10
	talkPrompt.RequiresLineOfSight = false
	talkPrompt.Parent = torso
	talkPrompt.Triggered:Connect(function(player)
		if isPlayerNear(player, torso) then
			onTalk(player, characterId)
		end
	end)

	local recruitPrompt = Instance.new("ProximityPrompt")
	recruitPrompt.Name = "RecruitPrompt"
	recruitPrompt.ActionText = "Recruit (" .. character.requiredLove .. " Love)"
	recruitPrompt.ObjectText = character.displayName
	recruitPrompt.KeyboardKeyCode = Enum.KeyCode.F
	recruitPrompt.HoldDuration = 0
	recruitPrompt.MaxActivationDistance = 10
	recruitPrompt.RequiresLineOfSight = false
	recruitPrompt.Parent = torso
	recruitPrompt.Triggered:Connect(function(player)
		if not isPlayerNear(player, torso) then
			return
		end
		if onRecruit(player, characterId) then
			if activeCharacters[characterId] == model then
				activeCharacters[characterId] = nil
				occupiedSpawns[spawnIndex] = nil
				model:Destroy()
				task.delay(Characters.RespawnDelaySeconds, function()
					spawnCharacter(characterId, onTalk, onRecruit)
				end)
			end
		end
	end)

	model.Parent = characterFolder
	activeCharacters[characterId] = model
end

function CharacterSpawnService.Start(onTalk, onRecruit)
	local existing = Workspace:FindFirstChild("LiveCharacters")
	if existing then
		existing:Destroy()
	end

	characterFolder = Instance.new("Folder")
	characterFolder.Name = "LiveCharacters"
	characterFolder.Parent = Workspace

	table.clear(activeCharacters)
	table.clear(occupiedSpawns)

	for _, characterId in ipairs(Characters.Order) do
		spawnCharacter(characterId, onTalk, onRecruit)
	end
end

return CharacterSpawnService
