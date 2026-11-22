local WorldEffectsController = {}
WorldEffectsController.__index = WorldEffectsController

function WorldEffectsController.new(context)
	local self = setmetatable({
		context = context,
		connections = {},
		tags = {},
		tagConnections = {},
		tagWatchConnections = {},
		destroyed = false,
	}, WorldEffectsController)

	task.spawn(function()
		self:_startWorldAnimation()
	end)
	task.spawn(function()
		self:_startNPCLabels()
	end)

	return self
end

function WorldEffectsController:_track(connection)
	table.insert(self.connections, connection)
	return connection
end

function WorldEffectsController:_startWorldAnimation()
	local mapFolder = workspace:WaitForChild("SimulatorBaseplateMap")
	local spawnFolder = mapFolder:WaitForChild("StartingPointHub")
	local crystal = spawnFolder:WaitForChild("SpawnFloatingCrystal")
	local halo = spawnFolder:WaitForChild("SpawnHaloRing")
	local riverFolder = mapFolder:WaitForChild("MountainFoothillRiver")
	local directions = {
		NorthRiver = Vector2.new(1, 0.25),
		SouthRiver = Vector2.new(-1, -0.25),
		EastRiver = Vector2.new(0.25, 1),
		WestRiver = Vector2.new(-0.25, -1),
	}
	local flows = {}
	for riverName, direction in pairs(directions) do
		local water = riverFolder:WaitForChild(riverName)
		for _, texture in ipairs(water:GetChildren()) do
			if texture:IsA("Texture") then
				local fast = texture.StudsPerTileU < 30
				table.insert(flows, {
					tex = texture,
					speedU = direction.X * (fast and 10 or 6),
					speedV = direction.Y * (fast and 4 or 6),
				})
			end
		end
	end

	if self.destroyed then return end
	local basePos = crystal.Position
	local elapsed = 0
	self:_track(self.context.RunService.RenderStepped:Connect(function(dt)
		elapsed += dt
		for _, flow in ipairs(flows) do
			local tex = flow.tex
			if tex.Parent then
				tex.OffsetStudsU = (tex.OffsetStudsU + flow.speedU * dt) % tex.StudsPerTileU
				tex.OffsetStudsV = (tex.OffsetStudsV + flow.speedV * dt) % tex.StudsPerTileV
			end
		end
		local floatOffset = Vector3.new(0, math.sin(elapsed * 2.2) * 0.85, 0)
		crystal.CFrame = CFrame.new(basePos + floatOffset) * CFrame.Angles(0, elapsed * 1.2, 0)
		halo.CFrame = CFrame.new(basePos + floatOffset)
			* CFrame.Angles(math.sin(elapsed * 1.5) * 0.35, elapsed * 1.8, math.rad(90))
	end))
end

function WorldEffectsController:_registerNPC(npc)
	local tags = self.tags
	if tags[npc] then return end
	local head = npc:FindFirstChild("Head")
	local tag = head and head:FindFirstChild("RarityTag")
	if not tag then
		if not self.tagWatchConnections[npc] then
			self.tagWatchConnections[npc] = self:_track(npc.DescendantAdded:Connect(function(descendant)
				if descendant.Name == "RarityTag" and descendant:IsA("BillboardGui") then
					self.tagWatchConnections[npc]:Disconnect()
					self.tagWatchConnections[npc] = nil
					self:_registerNPC(npc)
				end
			end))
		end
		return
	end
	tags[npc] = tag
	-- Streaming can temporarily unparent the head/tag without removing the NPC
	-- model; re-register when the tag comes back.
	self.tagConnections[npc] = self:_track(tag.AncestryChanged:Connect(function(_, parent)
		if parent then
			tags[npc] = tag
		else
			tags[npc] = nil
		end
	end))
end

function WorldEffectsController:_unregisterNPC(npc)
	if self.tagConnections[npc] then
		self.tagConnections[npc]:Disconnect()
		self.tagConnections[npc] = nil
	end
	if self.tagWatchConnections[npc] then
		self.tagWatchConnections[npc]:Disconnect()
		self.tagWatchConnections[npc] = nil
	end
	self.tags[npc] = nil
end

function WorldEffectsController:_startNPCLabels()
	local mapFolder = workspace:WaitForChild("SimulatorBaseplateMap")
	local systems = mapFolder:WaitForChild("SimulatorSystems")
	local npcFolder = systems:WaitForChild("RoamingNPCs")
	if self.destroyed then return end

	for _, npc in ipairs(npcFolder:GetChildren()) do
		self:_registerNPC(npc)
	end
	self:_track(npcFolder.ChildAdded:Connect(function(npc)
		self:_registerNPC(npc)
	end))
	self:_track(npcFolder.ChildRemoved:Connect(function(npc)
		self:_unregisterNPC(npc)
	end))

	local lastUpdate = 0
	self:_track(self.context.RunService.RenderStepped:Connect(function()
		local now = os.clock()
		if now - lastUpdate < 0.12 then return end
		lastUpdate = now

		local character = self.context.LocalPlayer.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local myPosition = hrp.Position
		for _, tag in pairs(self.tags) do
			local head = tag.Parent
			if head and head:IsA("BasePart") then
				local dist = (head.Position - myPosition).Magnitude
				local alpha = math.clamp(1 - ((dist - 5) / 35), 0, 1)
				local scale = 0.8 + alpha * 0.65
				local width = math.floor(110 * scale)
				if tag.Size.X.Offset ~= width then
					tag.Size = UDim2.new(0, width, 0, math.floor(28 * scale))
				end
			end
		end
	end))
end

function WorldEffectsController:Destroy()
	self.destroyed = true
	for _, connection in ipairs(self.connections) do
		connection:Disconnect()
	end
	table.clear(self.connections)
	table.clear(self.tags)
	table.clear(self.tagConnections)
	table.clear(self.tagWatchConnections)
end

return WorldEffectsController
