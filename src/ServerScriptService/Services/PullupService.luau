-- ========================================================================
-- PULLUP SERVICE
-- Gym station, pull-up entry/exit/repetitions and cooldown.
-- ========================================================================
local TweenService = game:GetService("TweenService")

local PullupService = {}

local pullupCooldowns = {}

function PullupService.Start(context)
	local GYM_POS = context.GYM_POS
	local ModFolder = context.ModFolder
	local EvTogglePullup = context.EvTogglePullup
	local EvPullupAction = context.EvPullupAction
	local savedHumanoidMovement = context.savedHumanoidMovement

	-- B) BARFİKS ALANI (TAM ANİMASYONLU VE GİRİŞ/ÇIKIŞ GARANTİLİ)
	local PullupFolder = Instance.new("Model", ModFolder)
	PullupFolder.Name = "GymPullupStation"

	local function gPart(n, sh, sz, cf, mat, col, cc)
		local p = Instance.new("Part", PullupFolder)
		p.Name = n
		p.Shape = sh
		p.Size = sz
		p.CFrame = cf
		p.Anchored = true
		p.CanCollide = cc
		p.Material = mat
		p.Color = col
		return p
	end

	gPart("GymMat", Enum.PartType.Block, Vector3.new(18, 0.4, 14), CFrame.new(GYM_POS + Vector3.new(0, 0.2, 0)), Enum.Material.SmoothPlastic, Color3.fromRGB(48, 56, 68), true)
	gPart("GymTrim", Enum.PartType.Block, Vector3.new(18.6, 0.3, 14.6), CFrame.new(GYM_POS + Vector3.new(0, 0.15, 0)), Enum.Material.Neon, Color3.fromRGB(255, 175, 65), false)
	gPart("LeftPost", Enum.PartType.Cylinder, Vector3.new(11.5, 0.9, 0.9), CFrame.new(GYM_POS + Vector3.new(-5.5, 5.75, 0)) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Metal, Color3.fromRGB(60, 65, 75), true)
	gPart("RightPost", Enum.PartType.Cylinder, Vector3.new(11.5, 0.9, 0.9), CFrame.new(GYM_POS + Vector3.new(5.5, 5.75, 0)) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Metal, Color3.fromRGB(60, 65, 75), true)

	local PullupBar = gPart("PullupBar", Enum.PartType.Cylinder, Vector3.new(11.6, 0.5, 0.5), CFrame.new(GYM_POS + Vector3.new(0, 11.2, 0)), Enum.Material.Metal, Color3.fromRGB(225, 185, 85), false)

	local BarPrompt = Instance.new("ProximityPrompt", PullupBar)
	BarPrompt.ActionText = "Barfiks Çek"
	BarPrompt.ObjectText = "Güç İstasyonu"
	BarPrompt.MaxActivationDistance = 14
	BarPrompt.RequiresLineOfSight = false

	local function togglePlayerPullup(player, forceState)
		local current = player:GetAttribute("OnPullup") == true
		local nextState = forceState == nil and not current or forceState == true

		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		if nextState then
			-- Arena and pending-duel restrictions only prevent entering the station.
			if player:GetAttribute("InArena") or player:GetAttribute("DuelPending") then return end
			if current then
				EvTogglePullup:FireClient(player, true)
				return
			end
			if not hrp or not humanoid or humanoid.Health <= 0 then return end
			if (hrp.Position - GYM_POS).Magnitude > 18 then return end

			savedHumanoidMovement[character] = {
				WalkSpeed = humanoid.WalkSpeed,
				JumpPower = humanoid.JumpPower,
				JumpHeight = humanoid.JumpHeight,
				AutoRotate = humanoid.AutoRotate,
				PlatformStand = humanoid.PlatformStand,
			}

			player:SetAttribute("OnPullup", true)
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
			humanoid.JumpHeight = 0
			humanoid.AutoRotate = false
			hrp.Anchored = true
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
			hrp.CFrame = CFrame.new(GYM_POS + Vector3.new(0, 7.6, 0.25)) * CFrame.Angles(math.rad(6), 0, 0)
			EvTogglePullup:FireClient(player, true)
			humanoid.Died:Connect(function()
				if player.Parent and player:GetAttribute("OnPullup") == true then
					togglePlayerPullup(player, false)
				end
			end)
			return
		end

		-- Exit is idempotent and is never blocked by DuelPending. Recover an
		-- anchored character near the station even if its attribute got out of sync.
		local isAtStation = hrp and hrp.Anchored and (hrp.Position - GYM_POS).Magnitude <= 18
		if not current and not isAtStation then
			EvTogglePullup:FireClient(player, false)
			return
		end

		player:SetAttribute("OnPullup", false)
		if hrp then
			hrp.Anchored = false
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
			if not player:GetAttribute("InArena") then
				hrp.CFrame = CFrame.new(GYM_POS + Vector3.new(0, 3.5, 5.5))
			end
		end

		local saved = character and savedHumanoidMovement[character]
		if humanoid then
			humanoid.PlatformStand = saved and saved.PlatformStand or false
			humanoid.AutoRotate = saved and saved.AutoRotate
			if humanoid.AutoRotate == nil then humanoid.AutoRotate = true end
			humanoid.WalkSpeed = saved and saved.WalkSpeed or 16
			humanoid.JumpPower = saved and saved.JumpPower or 50
			humanoid.JumpHeight = saved and saved.JumpHeight or 7.2
			if humanoid.Health > 0 then
				humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end
		if character then
			savedHumanoidMovement[character] = nil
		end
		EvTogglePullup:FireClient(player, false)
	end
	BarPrompt.Triggered:Connect(function(player)
		togglePlayerPullup(player, true)
	end)

	-- The client can request an exit only; it cannot remotely enter the station.
	EvTogglePullup.OnServerEvent:Connect(function(player)
		togglePlayerPullup(player, false)
	end)

	EvPullupAction.OnServerEvent:Connect(function(player)
		if player:GetAttribute("OnPullup") ~= true or player:GetAttribute("InArena") then return end

		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local ls = player:FindFirstChild("leaderstats")
		local power = ls and ls:FindFirstChild("Power")
		local love = ls and ls:FindFirstChild("Love")

		if not hrp or not humanoid or humanoid.Health <= 0 or not hrp.Anchored
			or (hrp.Position - GYM_POS).Magnitude > 18
			or not power or not love then
			togglePlayerPullup(player, false)
			return
		end

		local now = os.clock()
		if pullupCooldowns[player] and now - pullupCooldowns[player] < 0.26 then return end
		pullupCooldowns[player] = now

		local baseGain = 1
		local loveBonus = love.Value * 0.01
		local totalGain = math.max(1, math.floor((baseGain + loveBonus) * 100) / 100)
		power.Value = math.floor((power.Value + totalGain) * 100) / 100

		local upCF = CFrame.new(GYM_POS + Vector3.new(0, 9.4, 0.15)) * CFrame.Angles(math.rad(-8), 0, 0)
		local downCF = CFrame.new(GYM_POS + Vector3.new(0, 7.6, 0.25)) * CFrame.Angles(math.rad(6), 0, 0)
		TweenService:Create(hrp, TweenInfo.new(0.11, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = upCF }):Play()
		task.delay(0.13, function()
			if player.Parent and player:GetAttribute("OnPullup") == true and hrp.Parent and hrp.Anchored then
				TweenService:Create(hrp, TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = downCF }):Play()
			end
		end)

		EvPullupAction:FireClient(player, totalGain)
	end)
end

function PullupService.Cleanup(player)
	pullupCooldowns[player] = nil
end

return PullupService
