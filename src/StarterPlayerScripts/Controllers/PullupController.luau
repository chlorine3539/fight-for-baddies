local UIUtils = require(script.Parent.UIUtils)

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

local PullupController = {}
PullupController.__index = PullupController

function PullupController.new(context)
	local self = setmetatable({
		context = context,
		connections = {},
		isOnPullup = false,
		exitRequestPending = false,
		pullupPose = {
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
		},
		poseSimulationConnection = nil,
		hiddenCharacters = {},
		savedVisuals = {},
		playerWatches = {},
		destroyed = false,
	}, PullupController)

	self:_buildPanel()
	self:_watchPlayers()

	self:_track(context.EvTogglePullup.OnClientEvent:Connect(function(isOn)
		self.exitRequestPending = false
		self:_setPullupState(isOn)
		if isOn then
			if not self.pullupPose.active then
				local character = context.LocalPlayer.Character
				if not self:_startPullupPose(character) then
					task.spawn(function()
						local humanoid = character and character:WaitForChild("Humanoid", 5)
						if humanoid and context.LocalPlayer:GetAttribute("OnPullup") == true
							and not self.pullupPose.active and not self.destroyed then
							self:_startPullupPose(character)
						end
					end)
				end
			end
		else
			self:_stopPullupPose()
		end
	end))

	self:_track(context.LocalPlayer.CharacterAdded:Connect(function()
		self.exitRequestPending = false
		self:_stopPullupPose()
		self:_setPullupState(false)
	end))

	self:_track(context.LocalPlayer.CharacterRemoving:Connect(function()
		self:_stopPullupPose()
	end))

	self:_track(context.EvPullupAction.OnClientEvent:Connect(function(gainedPower)
		self:_setPullupPosePhase(true)
		context.HUD:ShowFloatingPopup("+" .. tostring(gainedPower) .. " Power 💪", Color3.fromRGB(255, 210, 65))
		local char = context.LocalPlayer.Character
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

			local tw = context.TweenService:Create(ring, TweenInfo.new(0.32), {
				Size = Vector3.new(0.08, 8.5, 8.5),
				Transparency = 1,
			})
			tw:Play()
			local completedConnection
			completedConnection = tw.Completed:Connect(function()
				completedConnection:Disconnect()
				ring:Destroy()
			end)
		end
	end))

	self:_track(context.UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if self.isOnPullup then
			if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.Space then
				self:_requestExitPullup()
				return
			end
			if not gameProcessed and (input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch) then
				context.EvPullupAction:FireServer()
			end
		end
	end))

	return self
end

function PullupController:_track(connection)
	table.insert(self.connections, connection)
	return connection
end

function PullupController:_buildPanel()
	local PullupPanel = Instance.new("Frame", self.context.ScreenGui)
	PullupPanel.AnchorPoint = Vector2.new(0.5, 0)
	PullupPanel.Size = UDim2.new(0.62, 0, 0, 86)
	PullupPanel.Position = UDim2.new(0.5, 0, 0.74, 0)
	PullupPanel.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
	PullupPanel.Visible = false
	UIUtils.addSizeConstraints(PullupPanel, 240, 320, 82, 92)

	local ppCorner = Instance.new("UICorner", PullupPanel)
	ppCorner.CornerRadius = UDim.new(0, 10)

	local PullupHint = Instance.new("TextLabel", PullupPanel)
	PullupHint.Size = UDim2.new(1, -12, 0, 26)
	PullupHint.Position = UDim2.new(0, 6, 0, 4)
	PullupHint.BackgroundTransparency = 1
	PullupHint.Font = Enum.Font.GothamSemibold
	PullupHint.TextSize = 12
	PullupHint.TextWrapped = true
	PullupHint.TextColor3 = Color3.fromRGB(255, 220, 110)
	PullupHint.Text = "Ekrana Tıklayarak Barfiks Çek!"
	UIUtils.addTextConstraints(PullupHint, 11, 14)

	local ExitPullupBtn = Instance.new("TextButton", PullupPanel)
	ExitPullupBtn.AnchorPoint = Vector2.new(0.5, 0)
	ExitPullupBtn.Size = UDim2.new(0.68, 0, 0, 44)
	ExitPullupBtn.Position = UDim2.new(0.5, 0, 0, 34)
	ExitPullupBtn.BackgroundColor3 = Color3.fromRGB(215, 65, 75)
	ExitPullupBtn.Font = Enum.Font.GothamBold
	ExitPullupBtn.TextSize = 12
	ExitPullupBtn.TextWrapped = true
	ExitPullupBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	ExitPullupBtn.Text = "Barfiksten İn (E / Space)"
	UIUtils.addSizeConstraints(ExitPullupBtn, 180, 260, 44, 52)
	UIUtils.addTextConstraints(ExitPullupBtn, 11, 14)

	local epCorner = Instance.new("UICorner", ExitPullupBtn)
	epCorner.CornerRadius = UDim.new(0, 8)

	self.pullupPanel = PullupPanel
	self:_track(ExitPullupBtn.MouseButton1Click:Connect(function()
		self:_requestExitPullup()
	end))
end

function PullupController:_setPullupState(isOn)
	self.isOnPullup = (isOn == true)
	self.pullupPanel.Visible = self.isOnPullup

	local mapFolder = workspace:FindFirstChild("SimulatorBaseplateMap")
	local sysFolder = mapFolder and mapFolder:FindFirstChild("SimulatorSystems")
	local station = sysFolder and sysFolder:FindFirstChild("GymPullupStation")
	local bar = station and station:FindFirstChild("PullupBar")
	local prompt = bar and bar:FindFirstChildOfClass("ProximityPrompt")
	if prompt then prompt.Enabled = not self.isOnPullup end
end

function PullupController:_requestExitPullup()
	if not self.isOnPullup or self.exitRequestPending then return end
	self.exitRequestPending = true
	self.context.EvTogglePullup:FireServer(false)
	task.delay(1.5, function()
		self.exitRequestPending = false
	end)
end

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

function PullupController:_applyPullupPoseFrame()
	local pose = self.pullupPose
	if not pose.active then return end
	if not pose.character or not pose.character.Parent then
		self:_stopPullupPose()
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
			self:_stopPullupPose()
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

function PullupController:_stopPullupPose()
	if self.poseSimulationConnection then
		self.poseSimulationConnection:Disconnect()
		self.poseSimulationConnection = nil
	end
	local pose = self.pullupPose
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

function PullupController:_startPullupPose(character)
	self:_stopPullupPose()
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end

	local pose = self.pullupPose
	pose.active = true
	pose.character = character
	pose.animator = humanoid:FindFirstChildOfClass("Animator")
	pose.phase = "hang"
	pose.phaseToken += 1
	pose.appliedToken = 0
	pose.phaseStartedAt = os.clock()
	pose.deathConnection = humanoid.Died:Connect(function()
		self:_stopPullupPose()
	end)

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

	if not self.poseSimulationConnection then
		self.poseSimulationConnection = self.context.RunService.PreSimulation:Connect(function()
			local ok, err = pcall(function()
				self:_applyPullupPoseFrame()
			end)
			if not ok then
				warn("[Simulator] pull-up pose error: " .. tostring(err))
				self:_stopPullupPose()
			end
		end)
	end
	return true
end

function PullupController:_setPullupPosePhase(isUp)
	local pose = self.pullupPose
	if not pose.active then return end
	pose.phase = isUp and "up" or "hang"
	pose.phaseToken += 1
	pose.phaseStartedAt = os.clock()
	local token = pose.phaseToken
	if isUp then
		task.spawn(function()
			while pose.active and pose.phaseToken == token
				and pose.appliedToken < token do
				task.wait()
			end
			task.wait(0.13)
			if pose.active and pose.phaseToken == token then
				pose.phase = "hang"
				pose.phaseToken += 1
				pose.phaseStartedAt = os.clock()
			end
		end)
	end
end

function PullupController:_restoreVisual(instance)
	local saved = self.savedVisuals[instance]
	if not saved then return end
	if saved.transparency ~= nil then
		instance.LocalTransparencyModifier = saved.transparency
	end
	if saved.enabled ~= nil then
		instance.Enabled = saved.enabled
	end
	self.savedVisuals[instance] = nil
end

function PullupController:_applyVisualHidden(instance)
	if instance:IsA("BillboardGui") then
		if self.savedVisuals[instance] == nil then
			self.savedVisuals[instance] = { enabled = instance.Enabled }
		end
		instance.Enabled = false
	elseif (instance:IsA("BasePart") or instance:IsA("Decal"))
		and instance.Name ~= "HumanoidRootPart" then
		if self.savedVisuals[instance] == nil then
			self.savedVisuals[instance] = { transparency = instance.LocalTransparencyModifier }
		end
		instance.LocalTransparencyModifier = 1
	end
end

function PullupController:_setCharacterHidden(character, hide)
	if not character then return end
	if self.hiddenCharacters[character] == hide then return end
	self.hiddenCharacters[character] = hide
	for _, descendant in ipairs(character:GetDescendants()) do
		if hide then
			self:_applyVisualHidden(descendant)
		else
			self:_restoreVisual(descendant)
		end
	end
end

function PullupController:_unbindWatchedCharacter(watch)
	for _, connection in ipairs(watch.characterConnections) do
		connection:Disconnect()
	end
	table.clear(watch.characterConnections)
	if watch.character then
		self:_setCharacterHidden(watch.character, false)
		self.hiddenCharacters[watch.character] = nil
		watch.character = nil
	end
end

function PullupController:_bindWatchedCharacter(player, character)
	local watch = self.playerWatches[player]
	if not watch then return end
	self:_unbindWatchedCharacter(watch)
	watch.character = character
	self:_setCharacterHidden(character, player:GetAttribute("OnPullup") == true)
	table.insert(watch.characterConnections, self:_track(player:GetAttributeChangedSignal("OnPullup"):Connect(function()
		self:_setCharacterHidden(character, player:GetAttribute("OnPullup") == true)
	end)))
	table.insert(watch.characterConnections, self:_track(character.DescendantAdded:Connect(function(descendant)
		if self.hiddenCharacters[character] then
			self:_applyVisualHidden(descendant)
		end
	end)))
	table.insert(watch.characterConnections, self:_track(character.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			self:_unbindWatchedCharacter(watch)
		end
	end)))
	table.insert(watch.characterConnections, self:_track(character.DescendantRemoving:Connect(function(descendant)
		self.savedVisuals[descendant] = nil
	end)))
end

function PullupController:_stopWatchingPlayer(player)
	local watch = self.playerWatches[player]
	if not watch then return end
	for _, connection in ipairs(watch.playerConnections) do
		connection:Disconnect()
	end
	table.clear(watch.playerConnections)
	self:_unbindWatchedCharacter(watch)
	self.playerWatches[player] = nil
end

function PullupController:_watchPlayer(player)
	if player == self.context.LocalPlayer then return end
	self:_stopWatchingPlayer(player)
	local watch = { character = nil, playerConnections = {}, characterConnections = {} }
	self.playerWatches[player] = watch
	table.insert(watch.playerConnections, self:_track(player.CharacterAdded:Connect(function(character)
		self:_bindWatchedCharacter(player, character)
	end)))
	if player.Character then
		self:_bindWatchedCharacter(player, player.Character)
	end
end

function PullupController:_watchPlayers()
	for _, player in ipairs(self.context.Players:GetPlayers()) do
		self:_watchPlayer(player)
	end
	self:_track(self.context.Players.PlayerAdded:Connect(function(player)
		self:_watchPlayer(player)
	end))
	self:_track(self.context.Players.PlayerRemoving:Connect(function(player)
		self:_stopWatchingPlayer(player)
	end))
end

function PullupController:Destroy()
	self.destroyed = true
	self:_setPullupState(false)
	self:_stopPullupPose()
	for player in pairs(self.playerWatches) do
		self:_stopWatchingPlayer(player)
	end
	for _, connection in ipairs(self.connections) do
		connection:Disconnect()
	end
	table.clear(self.connections)
	table.clear(self.hiddenCharacters)
	table.clear(self.savedVisuals)
end

return PullupController
