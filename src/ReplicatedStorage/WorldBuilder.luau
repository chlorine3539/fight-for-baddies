-- Shared world builder for the live game and Roblox Studio edit mode.
-- In Studio's Command Bar, run:
-- require(game:GetService("ReplicatedStorage"):WaitForChild("WorldBuilder")).Build()

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local WorldBuilder = {}

function WorldBuilder.Build()
	-- Eski harita ve varsayılan parçaları temizle
	for _, obj in ipairs(Workspace:GetChildren()) do
		if obj.Name == "Baseplate" or obj:IsA("SpawnLocation") or obj.Name == "SimulatorBaseplateMap" then
			obj:Destroy()
		end
	end
	
	local MapFolder = Instance.new("Folder")
	MapFolder.Name = "SimulatorBaseplateMap"
	MapFolder.Parent = Workspace
	
	------------------------------------------------------------------------
	-- 1. ATMOSFER AYARLARI
	------------------------------------------------------------------------
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Sky") or child:IsA("Atmosphere") or child:IsA("SunRaysEffect") or child:IsA("BloomEffect") or child:IsA("ColorCorrectionEffect") then
			child:Destroy()
		end
	end
	
	Lighting.ClockTime = 10.5
	Lighting.GeographicLatitude = 35
	Lighting.Brightness = 2.0
	Lighting.Ambient = Color3.fromRGB(145, 152, 160)
	Lighting.OutdoorAmbient = Color3.fromRGB(160, 168, 178)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 250, 240)
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.35
	
	local Sky = Instance.new("Sky", Lighting)
	Sky.Name = "CleanSimulatorSky"
	Sky.CelestialBodiesShown = true
	Sky.SunAngularSize = 20
	Sky.StarCount = 800
	
	local Atmosphere = Instance.new("Atmosphere", Lighting)
	Atmosphere.Density = 0.22
	Atmosphere.Offset = 0.1
	Atmosphere.Color = Color3.fromRGB(195, 220, 242)
	Atmosphere.Decay = Color3.fromRGB(130, 170, 210)
	Atmosphere.Glare = 0.1
	Atmosphere.Haze = 0.4
	
	local SunRays = Instance.new("SunRaysEffect", Lighting)
	SunRays.Intensity = 0.06
	SunRays.Spread = 0.6
	
	------------------------------------------------------------------------
	-- 2. ÇİM BASEPLATE VE TAŞ SINIR
	------------------------------------------------------------------------
	local BASE_SIZE = 512
	local BASE_THICKNESS = 16
	
	local Baseplate = Instance.new("Part", MapFolder)
	Baseplate.Name = "SimulatorBaseplate"
	Baseplate.Size = Vector3.new(BASE_SIZE, BASE_THICKNESS, BASE_SIZE)
	Baseplate.Position = Vector3.new(0, -BASE_THICKNESS / 2, 0)
	Baseplate.Anchored = true
	Baseplate.CanCollide = true
	Baseplate.Material = Enum.Material.Grass
	Baseplate.Color = Color3.fromRGB(96, 166, 98)
	Baseplate.TopSurface = Enum.SurfaceType.Smooth
	Baseplate.BottomSurface = Enum.SurfaceType.Smooth
	
	local GridTexture = Instance.new("Texture", Baseplate)
	GridTexture.Name = "SubtleGrid"
	GridTexture.Face = Enum.NormalId.Top
	GridTexture.Texture = "rbxassetid://6372755229"
	GridTexture.StudsPerTileU = 16
	GridTexture.StudsPerTileV = 16
	GridTexture.Transparency = 0.9
	GridTexture.Color3 = Color3.fromRGB(240, 248, 240)
	
	local borderThickness = 3.5
	local borderHeight = 1.6
	local wallHeight = 45
	
	local borderConfigs = {
		{ pos = Vector3.new(0, borderHeight / 2, BASE_SIZE / 2 + borderThickness / 2), size = Vector3.new(BASE_SIZE + borderThickness * 2, borderHeight, borderThickness), wallPos = Vector3.new(0, wallHeight / 2, BASE_SIZE / 2 + borderThickness / 2), wallSize = Vector3.new(BASE_SIZE + borderThickness * 2, wallHeight, borderThickness) },
		{ pos = Vector3.new(0, borderHeight / 2, -BASE_SIZE / 2 - borderThickness / 2), size = Vector3.new(BASE_SIZE + borderThickness * 2, borderHeight, borderThickness), wallPos = Vector3.new(0, wallHeight / 2, -BASE_SIZE / 2 - borderThickness / 2), wallSize = Vector3.new(BASE_SIZE + borderThickness * 2, wallHeight, borderThickness) },
		{ pos = Vector3.new(BASE_SIZE / 2 + borderThickness / 2, borderHeight / 2, 0), size = Vector3.new(borderThickness, borderHeight, BASE_SIZE), wallPos = Vector3.new(BASE_SIZE / 2 + borderThickness / 2, wallHeight / 2, 0), wallSize = Vector3.new(borderThickness, wallHeight, BASE_SIZE) },
		{ pos = Vector3.new(-BASE_SIZE / 2 - borderThickness / 2, borderHeight / 2, 0), size = Vector3.new(borderThickness, borderHeight, BASE_SIZE), wallPos = Vector3.new(-BASE_SIZE / 2 - borderThickness / 2, wallHeight / 2, 0), wallSize = Vector3.new(borderThickness, wallHeight, BASE_SIZE) },
	}
	
	for i, cfg in ipairs(borderConfigs) do
		local trim = Instance.new("Part", MapFolder)
		trim.Name = "StoneBorder_" .. i
		trim.Size = cfg.size
		trim.Position = cfg.pos
		trim.Anchored = true
		trim.CanCollide = true
		trim.Material = Enum.Material.Concrete
		trim.Color = Color3.fromRGB(215, 220, 226)
	
		local barrier = Instance.new("Part", MapFolder)
		barrier.Name = "InvisibleWall_" .. i
		barrier.Size = cfg.wallSize
		barrier.Position = cfg.wallPos
		barrier.Anchored = true
		barrier.Transparency = 1
		barrier.CanCollide = true
	end
	
	------------------------------------------------------------------------
	-- 3. STARTING POINT HUB
	------------------------------------------------------------------------
	local SpawnFolder = Instance.new("Folder", MapFolder)
	SpawnFolder.Name = "StartingPointHub"
	
	local HUB_CENTER = Vector3.new(0, 0, 165)
	local GYM_POS = Vector3.new(-68, 0, 130)
	
	local function makeHubPart(name, shape, size, cframe, material, color, canCollide, transparency)
		local p = Instance.new("Part", SpawnFolder)
		p.Name = name
		p.Shape = shape
		p.Size = size
		p.CFrame = cframe
		p.Anchored = true
		p.CanCollide = canCollide
		p.Material = material
		p.Color = color
		p.Transparency = transparency or 0
		return p
	end
	
	makeHubPart("OuterGraniteStep", Enum.PartType.Cylinder, Vector3.new(0.6, 94, 94), CFrame.new(HUB_CENTER + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Slate, Color3.fromRGB(72, 80, 90), true)
	makeHubPart("MainMarblePlaza", Enum.PartType.Cylinder, Vector3.new(1.0, 88, 88), CFrame.new(HUB_CENTER + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Marble, Color3.fromRGB(242, 244, 248), true)
	makeHubPart("GoldOuterRing", Enum.PartType.Cylinder, Vector3.new(1.06, 74, 74), CFrame.new(HUB_CENTER + Vector3.new(0, 0.53, 0)) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Metal, Color3.fromRGB(218, 178, 92), false)
	makeHubPart("InnerMarblePlaza", Enum.PartType.Cylinder, Vector3.new(1.1, 71, 71), CFrame.new(HUB_CENTER + Vector3.new(0, 0.55, 0)) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Marble, Color3.fromRGB(250, 251, 254), false)
	
	for i = 0, 3 do
		local rot = math.rad(i * 45)
		makeHubPart("FloorLine_" .. i, Enum.PartType.Block, Vector3.new(70, 0.08, 1.4), CFrame.new(HUB_CENTER + Vector3.new(0, 1.12, 0)) * CFrame.Angles(0, rot, 0), Enum.Material.Metal, Color3.fromRGB(212, 175, 95), false)
	end
	
	makeHubPart("CenterPedestalBase", Enum.PartType.Cylinder, Vector3.new(0.7, 28, 28), CFrame.new(HUB_CENTER + Vector3.new(0, 1.35, 0)) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Slate, Color3.fromRGB(68, 76, 86), true)
	makeHubPart("CenterNeonTrim", Enum.PartType.Cylinder, Vector3.new(0.74, 24.5, 24.5), CFrame.new(HUB_CENTER + Vector3.new(0, 1.37, 0)) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Neon, Color3.fromRGB(120, 215, 255), false)
	
	local SpawnPad = Instance.new("SpawnLocation", SpawnFolder)
	SpawnPad.Name = "StartingPointSpawn"
	SpawnPad.Shape = Enum.PartType.Cylinder
	SpawnPad.Size = Vector3.new(0.8, 23, 23)
	SpawnPad.CFrame = CFrame.new(HUB_CENTER + Vector3.new(0, 1.4, 0)) * CFrame.Angles(0, 0, math.rad(90))
	SpawnPad.Anchored = true
	SpawnPad.CanCollide = true
	SpawnPad.Material = Enum.Material.Marble
	SpawnPad.Color = Color3.fromRGB(245, 248, 252)
	SpawnPad.Duration = 0
	SpawnPad.Enabled = true
	
	local TouchSound = Instance.new("Sound", SpawnPad)
	TouchSound.Name = "SpawnChimeSFX"
	TouchSound.SoundId = "rbxassetid://4612375233"
	TouchSound.Volume = 0.35
	
	local RingSegments = 16
	local ArchRadius = 38
	for i = 1, RingSegments do
		local ang = (i / RingSegments) * math.pi * 2
		local nextAng = ((i + 1) / RingSegments) * math.pi * 2
		local p1 = HUB_CENTER + Vector3.new(math.cos(ang) * ArchRadius, 17, math.sin(ang) * ArchRadius)
		local p2 = HUB_CENTER + Vector3.new(math.cos(nextAng) * ArchRadius, 17, math.sin(nextAng) * ArchRadius)
		local mid = (p1 + p2) / 2
		local len = (p2 - p1).Magnitude + 0.6
	
		makeHubPart("UpperCrownBeam_" .. i, Enum.PartType.Block, Vector3.new(2.6, 1.6, len), CFrame.lookAt(mid, p2), Enum.Material.Marble, Color3.fromRGB(242, 245, 249), true)
		makeHubPart("UpperGoldTrim_" .. i, Enum.PartType.Block, Vector3.new(2.8, 0.35, len), CFrame.lookAt(mid + Vector3.new(0, 0.9, 0), p2 + Vector3.new(0, 0.9, 0)), Enum.Material.Metal, Color3.fromRGB(218, 178, 92), false)
	end
	
	local pillarAngles = { 28, 62, 118, 152, 208, 242, 298, 332 }
	for idx, deg in ipairs(pillarAngles) do
		local rad = math.rad(deg)
		local pos = HUB_CENTER + Vector3.new(math.cos(rad) * ArchRadius, 0, math.sin(rad) * ArchRadius)
	
		makeHubPart("PillarBase_" .. idx, Enum.PartType.Block, Vector3.new(3.6, 2.2, 3.6), CFrame.new(pos + Vector3.new(0, 1.8, 0)) * CFrame.Angles(0, -rad, 0), Enum.Material.Slate, Color3.fromRGB(72, 80, 90), true)
		makeHubPart("PillarShaft_" .. idx, Enum.PartType.Cylinder, Vector3.new(13.5, 2.3, 2.3), CFrame.new(pos + Vector3.new(0, 9.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Marble, Color3.fromRGB(244, 246, 250), true)
		makeHubPart("PillarCap_" .. idx, Enum.PartType.Block, Vector3.new(3.4, 1.4, 3.4), CFrame.new(pos + Vector3.new(0, 16.2, 0)) * CFrame.Angles(0, -rad, 0), Enum.Material.Marble, Color3.fromRGB(238, 241, 246), true)
	
		local lantern = makeHubPart("PillarLantern_" .. idx, Enum.PartType.Ball, Vector3.new(2.2, 2.2, 2.2), CFrame.new(pos + Vector3.new(0, 19.2, 0)), Enum.Material.Neon, Color3.fromRGB(255, 226, 155), false)
		local light = Instance.new("PointLight", lantern)
		light.Color = Color3.fromRGB(255, 220, 145)
		light.Brightness = 1.2
		light.Range = 28
	end
	
	local gateAngles = { 0, 90, 180, 270 }
	for gIdx, gDeg in ipairs(gateAngles) do
		for side = -1, 1, 2 do
			local offsetRad = math.rad(gDeg + side * 12)
			local pPos = HUB_CENTER + Vector3.new(math.cos(offsetRad) * 41.5, 0, math.sin(offsetRad) * 41.5)
			makeHubPart("PlanterBox_" .. gIdx .. "_" .. side, Enum.PartType.Block, Vector3.new(4.2, 2.4, 4.2), CFrame.new(pPos + Vector3.new(0, 1.8, 0)) * CFrame.Angles(0, -offsetRad, 0), Enum.Material.Marble, Color3.fromRGB(236, 240, 245), true)
			makeHubPart("PlanterBush_" .. gIdx .. "_" .. side, Enum.PartType.Ball, Vector3.new(4.6, 3.4, 4.6), CFrame.new(pPos + Vector3.new(0, 3.8, 0)), Enum.Material.Grass, Color3.fromRGB(72, 162, 82), false)
		end
	end
	
	local SpawnCrystal = makeHubPart("SpawnFloatingCrystal", Enum.PartType.Ball, Vector3.new(2.2, 2.2, 2.2), CFrame.new(HUB_CENTER + Vector3.new(0, 13.5, 0)), Enum.Material.Neon, Color3.fromRGB(165, 232, 255), false, 0.25)
	local SpawnRing = makeHubPart("SpawnHaloRing", Enum.PartType.Cylinder, Vector3.new(0.25, 6.5, 6.5), CFrame.new(HUB_CENTER + Vector3.new(0, 13.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Neon, Color3.fromRGB(218, 185, 105), false, 0.2)
	
	local AuraAtt = Instance.new("Attachment", SpawnPad)
	AuraAtt.Position = Vector3.new(0.5, 0, 0)
	local SpawnAuraVFX = Instance.new("ParticleEmitter", AuraAtt)
	SpawnAuraVFX.Name = "SpawnMagicSparkles"
	SpawnAuraVFX.Color = ColorSequence.new(Color3.fromRGB(160, 230, 255), Color3.fromRGB(255, 235, 175))
	SpawnAuraVFX.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(0.5, 0.55), NumberSequenceKeypoint.new(1, 0) })
	SpawnAuraVFX.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	SpawnAuraVFX.Lifetime = NumberRange.new(2.0, 3.2)
	SpawnAuraVFX.Rate = 24
	SpawnAuraVFX.Speed = NumberRange.new(2.5, 5.0)
	SpawnAuraVFX.SpreadAngle = Vector2.new(80, 80)
	SpawnAuraVFX.Acceleration = Vector3.new(0, 1.2, 0)
	SpawnAuraVFX.EmissionDirection = Enum.NormalId.Right
	SpawnAuraVFX.LightEmission = 0.6
	
	------------------------------------------------------------------------
	-- 4. DAĞ ETEĞİNDE AKINTILI SU KUŞAĞI
	------------------------------------------------------------------------
	local WaterFolder = Instance.new("Folder", MapFolder)
	WaterFolder.Name = "MountainFoothillRiver"
	
	local RIVER_Y = -2.2
	local INNER_EDGE = BASE_SIZE / 2 + borderThickness
	local OUTER_EDGE = 680
	local TOTAL_SPAN = OUTER_EDGE * 2
	
	local RiverBed = Instance.new("Part", WaterFolder)
	RiverBed.Name = "RiverBed"
	RiverBed.Size = Vector3.new(TOTAL_SPAN, 4, TOTAL_SPAN)
	RiverBed.Position = Vector3.new(0, -10, 0)
	RiverBed.Anchored = true
	RiverBed.CanCollide = true
	RiverBed.Material = Enum.Material.Sand
	RiverBed.Color = Color3.fromRGB(165, 160, 145)
	
	local riverWidth = OUTER_EDGE - INNER_EDGE
	local riverMidOffset = INNER_EDGE + riverWidth / 2
	local riverSegments = {
		{ name = "NorthRiver", pos = Vector3.new(0, RIVER_Y, -riverMidOffset), size = Vector3.new(TOTAL_SPAN, 6, riverWidth), flowDir = Vector2.new(1, 0.25) },
		{ name = "SouthRiver", pos = Vector3.new(0, RIVER_Y, riverMidOffset), size = Vector3.new(TOTAL_SPAN, 6, riverWidth), flowDir = Vector2.new(-1, -0.25) },
		{ name = "EastRiver", pos = Vector3.new(riverMidOffset, RIVER_Y, 0), size = Vector3.new(riverWidth, 6, INNER_EDGE * 2), flowDir = Vector2.new(0.25, 1) },
		{ name = "WestRiver", pos = Vector3.new(-riverMidOffset, RIVER_Y, 0), size = Vector3.new(riverWidth, 6, INNER_EDGE * 2), flowDir = Vector2.new(-0.25, -1) },
	}
	
	local FlowingTextures = {}
	for _, seg in ipairs(riverSegments) do
		local waterPart = Instance.new("Part", WaterFolder)
		waterPart.Name = seg.name
		waterPart.Size = seg.size
		waterPart.Position = seg.pos
		waterPart.Anchored = true
		waterPart.CanCollide = false
		waterPart.Material = Enum.Material.Glass
		waterPart.Transparency = 0.22
		waterPart.Reflectance = 0.25
		waterPart.Color = Color3.fromRGB(78, 165, 205)
	
		local flowTex1 = Instance.new("Texture", waterPart)
		flowTex1.Face = Enum.NormalId.Top
		flowTex1.Texture = "rbxassetid://6372755229"
		flowTex1.StudsPerTileU = 45
		flowTex1.StudsPerTileV = 45
		flowTex1.Transparency = 0.78
		flowTex1.Color3 = Color3.fromRGB(215, 242, 255)
		table.insert(FlowingTextures, { tex = flowTex1, speedU = seg.flowDir.X * 6, speedV = seg.flowDir.Y * 6 })
	
		local flowTex2 = Instance.new("Texture", waterPart)
		flowTex2.Face = Enum.NormalId.Top
		flowTex2.Texture = "rbxassetid://6372755229"
		flowTex2.StudsPerTileU = 22
		flowTex2.StudsPerTileV = 70
		flowTex2.Transparency = 0.85
		flowTex2.Color3 = Color3.fromRGB(245, 252, 255)
		table.insert(FlowingTextures, { tex = flowTex2, speedU = seg.flowDir.X * 10, speedV = seg.flowDir.Y * 4 })
	
		local mistAtt = Instance.new("Attachment", waterPart)
		mistAtt.Position = Vector3.new(0, seg.size.Y / 2 + 0.2, 0)
		local streamParticles = Instance.new("ParticleEmitter", mistAtt)
		streamParticles.Color = ColorSequence.new(Color3.fromRGB(235, 248, 255))
		streamParticles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 0) })
		streamParticles.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.75), NumberSequenceKeypoint.new(1, 1) })
		streamParticles.Lifetime = NumberRange.new(3, 5)
		streamParticles.Rate = 8
		streamParticles.Speed = NumberRange.new(4, 8)
		streamParticles.Acceleration = Vector3.new(seg.flowDir.X * 4, 0.2, seg.flowDir.Y * 4)
	end
	
	local RiverSound = Instance.new("Sound", Baseplate)
	RiverSound.SoundId = "rbxassetid://9114221735"
	RiverSound.Volume = 0.35
	RiverSound.Looped = true
	RiverSound.RollOffMode = Enum.RollOffMode.InverseTapered
	RiverSound.RollOffMinDistance = 40
	RiverSound.RollOffMaxDistance = 260
	RiverSound:Play()
	
	------------------------------------------------------------------------
	-- 5. KAYGAN DAĞLAR
	------------------------------------------------------------------------
	local MountainFolder = Instance.new("Folder", MapFolder)
	MountainFolder.Name = "DetailedSlipperyMountains"
	local SLIPPERY_PHYSICS = PhysicalProperties.new(1.0, 0.0, 0.0, 100.0, 1.0)
	
	local function applySlipperyRock(part, material, color)
		part.Anchored = true
		part.CanCollide = true
		part.Material = material
		part.Color = color
		part.CustomPhysicalProperties = SLIPPERY_PHYSICS
	end
	
	local function createDetailedMountain(position, width, height, depth, rotationY, seed)
		local localRng = Random.new(seed)
		local mtnModel = Instance.new("Model", MountainFolder)
		mtnModel.Name = "DetailedMountain"
		local baseCFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(rotationY), 0)
	
		local lowerHeight = height * 0.45
		local lowerFront = Instance.new("Part", mtnModel)
		lowerFront.Shape = Enum.PartType.Wedge
		lowerFront.Size = Vector3.new(depth * 1.15, lowerHeight, width * 1.15)
		lowerFront.CFrame = baseCFrame * CFrame.new(0, lowerHeight / 2 - 12, 0)
		applySlipperyRock(lowerFront, Enum.Material.Slate, Color3.fromRGB(92, 108, 102))
	
		local lowerBack = Instance.new("Part", mtnModel)
		lowerBack.Shape = Enum.PartType.Wedge
		lowerBack.Size = Vector3.new(depth * 1.15, lowerHeight, width * 1.15)
		lowerBack.CFrame = baseCFrame * CFrame.new(0, lowerHeight / 2 - 12, 0) * CFrame.Angles(0, math.pi, 0)
		applySlipperyRock(lowerBack, Enum.Material.Slate, Color3.fromRGB(82, 98, 92))
	
		local mainFront = Instance.new("Part", mtnModel)
		mainFront.Shape = Enum.PartType.Wedge
		mainFront.Size = Vector3.new(depth, height, width)
		mainFront.CFrame = baseCFrame * CFrame.new(0, height / 2 - 10, 0)
		applySlipperyRock(mainFront, Enum.Material.Rock, Color3.fromRGB(108, 118, 122))
	
		local mainBack = Instance.new("Part", mtnModel)
		mainBack.Shape = Enum.PartType.Wedge
		mainBack.Size = Vector3.new(depth, height, width)
		mainBack.CFrame = baseCFrame * CFrame.new(0, height / 2 - 10, 0) * CFrame.Angles(0, math.pi, 0)
		applySlipperyRock(mainBack, Enum.Material.Rock, Color3.fromRGB(95, 105, 110))
	
		for ridgeIdx = 1, 2 do
			local sideSign = (ridgeIdx == 1) and 1 or -1
			local ridgeH = height * localRng:NextNumber(0.55, 0.72)
			local ridgeW = width * localRng:NextNumber(0.45, 0.6)
			local ridgeD = depth * localRng:NextNumber(0.55, 0.7)
			local offsetX = sideSign * width * 0.26
			local offsetZ = localRng:NextNumber(-18, 18)
	
			local ridgeF = Instance.new("Part", mtnModel)
			ridgeF.Shape = Enum.PartType.Wedge
			ridgeF.Size = Vector3.new(ridgeD, ridgeH, ridgeW)
			ridgeF.CFrame = baseCFrame * CFrame.new(offsetZ, ridgeH / 2 - 10, offsetX) * CFrame.Angles(0, math.rad(sideSign * 14), 0)
			applySlipperyRock(ridgeF, Enum.Material.Slate, Color3.fromRGB(100, 112, 114))
	
			local ridgeB = Instance.new("Part", mtnModel)
			ridgeB.Shape = Enum.PartType.Wedge
			ridgeB.Size = Vector3.new(ridgeD, ridgeH, ridgeW)
			ridgeB.CFrame = baseCFrame * CFrame.new(offsetZ, ridgeH / 2 - 10, offsetX) * CFrame.Angles(0, math.pi + math.rad(sideSign * 14), 0)
			applySlipperyRock(ridgeB, Enum.Material.Slate, Color3.fromRGB(88, 100, 102))
		end
	
		local snowRatio = 0.30
		local snowH, snowW, snowD = height * snowRatio, width * snowRatio, depth * snowRatio
	
		local snowFront = Instance.new("Part", mtnModel)
		snowFront.Shape = Enum.PartType.Wedge
		snowFront.Size = Vector3.new(snowD, snowH, snowW)
		snowFront.CFrame = baseCFrame * CFrame.new(0, height - snowH / 2 - 9.8, 0)
		applySlipperyRock(snowFront, Enum.Material.Snow, Color3.fromRGB(238, 244, 250))
	
		local snowBack = Instance.new("Part", mtnModel)
		snowBack.Shape = Enum.PartType.Wedge
		snowBack.Size = Vector3.new(snowD, snowH, snowW)
		snowBack.CFrame = baseCFrame * CFrame.new(0, height - snowH / 2 - 9.8, 0) * CFrame.Angles(0, math.pi, 0)
		applySlipperyRock(snowBack, Enum.Material.Snow, Color3.fromRGB(226, 234, 244))
	end
	
	local mtnRng = Random.new(204)
	for i = 1, 26 do
		local angle = (i / 26) * math.pi * 2
		local distance = mtnRng:NextNumber(415, 550)
		createDetailedMountain(Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance), mtnRng:NextNumber(170, 270), mtnRng:NextNumber(165, 295), mtnRng:NextNumber(150, 230), math.deg(-angle) + 90, i * 17)
	end
	
	------------------------------------------------------------------------
	-- 6. AĞAÇLAR (SPAWN VE BARFİKS ALANINDAN TEMİZLENMİŞ)
	------------------------------------------------------------------------
	local DecorFolder = Instance.new("Folder", MapFolder)
	DecorFolder.Name = "SimulatorTrees"
	
	local function createTexturedTree(position, scale)
		local treeModel = Instance.new("Model", DecorFolder)
		treeModel.Name = "SimulatorTree"
	
		local trunk = Instance.new("Part", treeModel)
		trunk.Name = "Trunk"
		trunk.Size = Vector3.new(2.5 * scale, 10 * scale, 2.5 * scale)
		trunk.Position = position + Vector3.new(0, 5 * scale, 0)
		trunk.Anchored = true
		trunk.CanCollide = true
		trunk.Material = Enum.Material.Wood
		trunk.Color = Color3.fromRGB(115, 78, 52)
	
		local leafColors = { Color3.fromRGB(68, 152, 74), Color3.fromRGB(78, 168, 84), Color3.fromRGB(58, 138, 65) }
		local layers = {
			{ offset = Vector3.new(0, 11 * scale, 0), size = Vector3.new(11 * scale, 5 * scale, 11 * scale) },
			{ offset = Vector3.new(0, 15 * scale, 0), size = Vector3.new(8.5 * scale, 4.5 * scale, 8.5 * scale) },
			{ offset = Vector3.new(0, 18.5 * scale, 0), size = Vector3.new(5.5 * scale, 4 * scale, 5.5 * scale) },
		}
	
		for i, layer in ipairs(layers) do
			local leaves = Instance.new("Part", treeModel)
			leaves.Name = "Leaves_" .. i
			leaves.Size = layer.size
			leaves.Position = position + layer.offset
			leaves.Anchored = true
			leaves.CanCollide = false
			leaves.Material = Enum.Material.Grass
			leaves.Color = leafColors[i]
		end
	end
	
	local rng = Random.new(42)
	for i = 1, 42 do
		local angle = (i / 42) * math.pi * 2
		local radius = rng:NextNumber(135, 235)
		local pos = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		if (pos - HUB_CENTER).Magnitude > 64 and (pos - GYM_POS).Magnitude > 35 then
			createTexturedTree(pos, rng:NextNumber(0.85, 1.45))
		end
	end
	
	------------------------------------------------------------------------

	return {
		MapFolder = MapFolder,
		GYM_POS = GYM_POS,
		SpawnPad = SpawnPad,
		TouchSound = TouchSound,
		SpawnCrystal = SpawnCrystal,
		SpawnRing = SpawnRing,
		FlowingTextures = FlowingTextures,
		DecorFolder = DecorFolder,
	}
end

return WorldBuilder
