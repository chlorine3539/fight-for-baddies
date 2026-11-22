-- ========================================================================
-- SECRET SERVICE
-- Secret forest toilet model, prompt and one-time Love reward.
-- ========================================================================
local SecretService = {}

function SecretService.Start(context)
	local ModFolder = context.ModFolder
	local DecorFolder = context.DecorFolder
	local EvNotify = context.EvNotify

	-- A) GİZLİ TUVALET
	local trees = DecorFolder:GetChildren()
	local targetTree = trees[1]
	local toiletPos = Vector3.new(-155, 0, -145)
	if targetTree and targetTree:FindFirstChild("Trunk") then
		toiletPos = targetTree.Trunk.Position * Vector3.new(1, 0, 1) + Vector3.new(5.5, 0, 4.5)
	end

	local ToiletModel = Instance.new("Model", ModFolder)
	ToiletModel.Name = "SecretForestToilet"

	local function tPart(n, sz, cf, mat, col)
		local p = Instance.new("Part", ToiletModel)
		p.Name = n
		p.Size = sz
		p.CFrame = cf
		p.Anchored = true
		p.Material = mat
		p.Color = col
		return p
	end

	local tCF = CFrame.new(toiletPos) * CFrame.Angles(0, math.rad(35), 0)
	tPart("CabinFloor", Vector3.new(6, 0.4, 6), tCF * CFrame.new(0, 0.2, 0), Enum.Material.WoodPlanks, Color3.fromRGB(92, 62, 40))
	tPart("WallBack", Vector3.new(6, 8.5, 0.5), tCF * CFrame.new(0, 4.4, -2.75), Enum.Material.WoodPlanks, Color3.fromRGB(85, 58, 38))
	tPart("WallLeft", Vector3.new(0.5, 8.5, 6), tCF * CFrame.new(-2.75, 4.4, 0), Enum.Material.WoodPlanks, Color3.fromRGB(85, 58, 38))
	tPart("WallRight", Vector3.new(0.5, 8.5, 6), tCF * CFrame.new(2.75, 4.4, 0), Enum.Material.WoodPlanks, Color3.fromRGB(85, 58, 38))
	tPart("Roof", Vector3.new(6.8, 0.6, 6.8), tCF * CFrame.new(0, 8.9, 0), Enum.Material.Grass, Color3.fromRGB(64, 145, 70))
	tPart("DoorHalfOpen", Vector3.new(2.8, 8.2, 0.4), tCF * CFrame.new(-1.4, 4.3, 3.2) * CFrame.Angles(0, math.rad(-55), 0), Enum.Material.WoodPlanks, Color3.fromRGB(102, 70, 46))
	tPart("ToiletBase", Vector3.new(1.8, 1.8, 2.2), tCF * CFrame.new(0, 1.1, -1.2), Enum.Material.SmoothPlastic, Color3.fromRGB(248, 250, 252))
	tPart("ToiletTank", Vector3.new(2.0, 2.0, 0.9), tCF * CFrame.new(0, 2.7, -2.0), Enum.Material.SmoothPlastic, Color3.fromRGB(245, 248, 250))

	local tSeat = Instance.new("Seat", ToiletModel)
	tSeat.Size = Vector3.new(1.7, 0.3, 1.8)
	tSeat.CFrame = tCF * CFrame.new(0, 2.1, -1.1)
	tSeat.Anchored = true
	tSeat.Material = Enum.Material.SmoothPlastic
	tSeat.Color = Color3.fromRGB(235, 240, 245)

	local FlushPrompt = Instance.new("ProximityPrompt", tSeat)
	FlushPrompt.ActionText = "Sifonu Çek"
	FlushPrompt.ObjectText = "Gizli Orman Tuvaleti"
	FlushPrompt.MaxActivationDistance = 8

	local FlushSFX = Instance.new("Sound", tSeat)
	FlushSFX.SoundId = "rbxassetid://9114221735"
	FlushSFX.Volume = 0.8

	local toiletRewards = {}
	FlushPrompt.Triggered:Connect(function(plr)
		if plr:GetAttribute("DataRestricted") then return end
		local ls = plr:FindFirstChild("leaderstats")
		local love = ls and ls:FindFirstChild("Love")
		if not love then return end

		if toiletRewards[plr.UserId] then
			EvNotify:FireClient(plr, "Secret", "Bu gizli ödülü zaten aldın.")
			return
		end

		toiletRewards[plr.UserId] = true
		FlushSFX:Play()
		love.Value += 5
		EvNotify:FireClient(plr, "Secret", "Gizli tuvaleti buldun! (+5 Love)")
	end)
end

return SecretService
