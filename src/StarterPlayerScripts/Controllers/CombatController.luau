local CombatController = {}
CombatController.__index = CombatController

function CombatController.new(context)
	local self = setmetatable({
		context = context,
		connections = {},
		characterConnections = {},
		swordConnections = {},
		destroyed = false,
	}, CombatController)

	if context.LocalPlayer.Character then
		self:_bindArenaSwordWatch(context.LocalPlayer.Character)
	end
	self:_track(context.LocalPlayer.CharacterAdded:Connect(function(character)
		self:_bindArenaSwordWatch(character)
	end))

	return self
end

function CombatController:_track(connection)
	table.insert(self.connections, connection)
	return connection
end

function CombatController:_isHeldByLocalCharacter(tool)
	local character = self.context.LocalPlayer.Character
	return character ~= nil and tool.Parent ~= nil
		and tool:FindFirstAncestorOfClass("Model") == character
end

function CombatController:_clearArenaSwordWatch()
	for _, connection in ipairs(self.swordConnections) do
		connection:Disconnect()
	end
	table.clear(self.swordConnections)
end

function CombatController:_clearCharacterWatch()
	for _, connection in ipairs(self.characterConnections) do
		connection:Disconnect()
	end
	table.clear(self.characterConnections)
	self:_clearArenaSwordWatch()
end

function CombatController:_watchArenaSword(tool)
	self:_clearArenaSwordWatch()
	if not tool:IsA("Tool") or tool.Name ~= "ArenaBlade" then return end

	table.insert(self.swordConnections, tool.Activated:Connect(function()
		if self:_isHeldByLocalCharacter(tool) then
			self.context.EvArenaAttack:FireServer()
		end
	end))
	table.insert(self.swordConnections, tool.AncestryChanged:Connect(function()
		if not self:_isHeldByLocalCharacter(tool) then
			self:_clearArenaSwordWatch()
		end
	end))
end

function CombatController:_bindArenaSwordWatch(character)
	self:_clearCharacterWatch()
	if not character then return end
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") and child.Name == "ArenaBlade" then
			self:_watchArenaSword(child)
			break
		end
	end
	table.insert(self.characterConnections, character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child.Name == "ArenaBlade" then
			self:_watchArenaSword(child)
		end
	end))
end

function CombatController:HandleNotify(kind, message)
	if kind ~= "ArenaReadyRequest" or self.destroyed then return end
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
		if floor and not self.destroyed then
			self.context.EvArenaReady:FireServer(slot)
		end
	end)
end

function CombatController:Destroy()
	self.destroyed = true
	for _, connection in ipairs(self.connections) do
		connection:Disconnect()
	end
	table.clear(self.connections)
	self:_clearCharacterWatch()
end

return CombatController
