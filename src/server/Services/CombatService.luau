local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Areas = require(
	ReplicatedStorage:WaitForChild("RojoShared"):WaitForChild("Config"):WaitForChild("Areas")
)

local CombatService = {}
local enemyFolder
local enemies = {}
local lastAttackAt = {}

local function updateEnemyLabel(info)
	if info.healthLabel then
		info.healthLabel.Text = string.format("%s  %d/%d", info.definition.name, info.health, info.definition.health)
	end
end

local function spawnEnemy(definition, respawnDelay)
	local enemy = Instance.new("Part")
	enemy.Name = "TrainingDummy"
	enemy.Size = Vector3.new(3, 4, 2)
	enemy.Position = definition.position
	enemy.Anchored = true
	enemy.CanCollide = false
	enemy.Material = Enum.Material.Neon
	enemy.Color = Color3.fromRGB(210, 85, 85)
	enemy.Parent = enemyFolder

	local info = {
		definition = definition,
		health = definition.health,
		healthLabel = nil,
	}
	enemies[enemy] = info
	enemy:SetAttribute("Health", info.health)
	enemy:SetAttribute("MaxHealth", definition.health)

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HealthDisplay"
	billboard.Adornee = enemy
	billboard.Size = UDim2.fromOffset(190, 40)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = enemy

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 235, 235)
	label.TextStrokeTransparency = 0.3
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.Parent = billboard
	info.healthLabel = label
	updateEnemyLabel(info)
end

local function findNearestEnemy(position, maxDistance)
	local nearestEnemy
	local nearestDistance = maxDistance

	for enemy in pairs(enemies) do
		if enemy.Parent then
			local distance = (enemy.Position - position).Magnitude
			if distance < nearestDistance then
				nearestEnemy = enemy
				nearestDistance = distance
			end
		end
	end

	return nearestEnemy
end

function CombatService.Start(attackRemote, dataService)
	local existing = Workspace:FindFirstChild("LiveEnemies")
	if existing then
		existing:Destroy()
	end

	enemyFolder = Instance.new("Folder")
	enemyFolder.Name = "LiveEnemies"
	enemyFolder.Parent = Workspace
	table.clear(enemies)

	local area = Areas.StarterArea
	for _, definition in ipairs(area.Enemies) do
		spawnEnemy(definition)
	end

	attackRemote.OnServerEvent:Connect(function(player)
		local now = os.clock()
		local previous = lastAttackAt[player] or 0
		if now - previous < area.AttackCooldownSeconds then
			return
		end
		lastAttackAt[player] = now

		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end

		local enemy = findNearestEnemy(root.Position, area.AttackRange)
		if not enemy then
			dataService.Sync(player, "No enemy in range. Move closer to a training dummy.")
			return
		end

		local info = enemies[enemy]
		if not info then
			return
		end

		local damage = dataService.GetAttackDamage(player)
		info.health = math.max(0, info.health - damage)
		enemy:SetAttribute("Health", info.health)

		if info.health <= 0 then
			local definition = info.definition
			enemies[enemy] = nil
			enemy:Destroy()
			dataService.AddLove(
				player,
				area.EnemyLoveReward,
				string.format("Training dummy defeated! +%d Love.", area.EnemyLoveReward)
			)
			task.delay(area.EnemyRespawnSeconds, function()
				if enemyFolder and enemyFolder.Parent then
					spawnEnemy(definition)
				end
			end)
		else
			updateEnemyLabel(info)
			dataService.Sync(player, string.format("Hit for %d damage.", damage))
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastAttackAt[player] = nil
	end)
end

return CombatService
