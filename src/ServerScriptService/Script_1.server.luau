-- ========================================================================
-- TEK PARÇA BİRLEŞTİRİLMİŞ TAM OYUN SCRİPTİ (ServerScriptService -> Script)
-- ========================================================================
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

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
-- 7. OYUNCU EKONOMİSİ (POWER & LOVE)
------------------------------------------------------------------------
local function placeCharacterAtSpawn(character)
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if hrp then
		task.wait(0.05)
		hrp.CFrame = SpawnPad.CFrame + Vector3.new(0, 4, 0)
	end
end

local function setupPlayer(player)
	if not player:FindFirstChild("leaderstats") then
		local ls = Instance.new("Folder", player)
		ls.Name = "leaderstats"

		local power = Instance.new("NumberValue", ls)
		power.Name = "Power"
		power.Value = 0

		local love = Instance.new("NumberValue", ls)
		love.Name = "Love"
		love.Value = 10
	end

	player:SetAttribute("OnPullup", false)
	player:SetAttribute("InArena", false)

	if player.Character then
		task.spawn(placeCharacterAtSpawn, player.Character)
	end
	player.CharacterAdded:Connect(function(char)
		player:SetAttribute("OnPullup", false)
		player:SetAttribute("InArena", false)
		placeCharacterAtSpawn(char)
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end
Players.PlayerAdded:Connect(setupPlayer)

------------------------------------------------------------------------
-- 8. NEHİR SU AKINTISI & SPAWN KRİSTALİ ANİMASYONU
------------------------------------------------------------------------
local crystalBasePos = SpawnCrystal.Position
local animTime = 0

RunService.Heartbeat:Connect(function(dt)
	animTime += dt
	for _, item in ipairs(FlowingTextures) do
		local tex = item.tex
		if tex and tex.Parent then
			tex.OffsetStudsU = (tex.OffsetStudsU + item.speedU * dt) % tex.StudsPerTileU
			tex.OffsetStudsV = (tex.OffsetStudsV + item.speedV * dt) % tex.StudsPerTileV
		end
	end
	local floatOffset = Vector3.new(0, math.sin(animTime * 2.2) * 0.85, 0)
	SpawnCrystal.CFrame = CFrame.new(crystalBasePos + floatOffset) * CFrame.Angles(0, animTime * 1.2, 0)
	SpawnRing.CFrame = CFrame.new(crystalBasePos + floatOffset) * CFrame.Angles(math.sin(animTime * 1.5) * 0.35, animTime * 1.8, math.rad(90))
end)

local spawnDebounce = {}
SpawnPad.Touched:Connect(function(hit)
	local character = hit.Parent
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and not spawnDebounce[character] then
		spawnDebounce[character] = true
		TouchSound:Play()
		task.delay(1.5, function() spawnDebounce[character] = nil end)
	end
end)

------------------------------------------------------------------------
-- 9. AĞLAR (REMOTE EVENTS), GİZLİ TUVALET, BARFİKS, NPC'LER VE ARENA
------------------------------------------------------------------------
local ModFolder = Instance.new("Folder", MapFolder)
ModFolder.Name = "SimulatorSystems"

local oldNet = ReplicatedStorage:FindFirstChild("SimNet")
if oldNet then oldNet:Destroy() end

local NetFolder = Instance.new("Folder", ReplicatedStorage)
NetFolder.Name = "SimNet"

local EvInteractNPC = Instance.new("RemoteEvent", NetFolder)
EvInteractNPC.Name = "InteractNPC"

local EvDialogueChoice = Instance.new("RemoteEvent", NetFolder)
EvDialogueChoice.Name = "DialogueChoice"

local EvPullupAction = Instance.new("RemoteEvent", NetFolder)
EvPullupAction.Name = "PullupAction"

local EvTogglePullup = Instance.new("RemoteEvent", NetFolder)
EvTogglePullup.Name = "TogglePullup"

local EvNotify = Instance.new("RemoteEvent", NetFolder)
EvNotify.Name = "Notify"

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

FlushPrompt.Triggered:Connect(function(plr)
	FlushSFX:Play()
	EvNotify:FireClient(plr, "Secret", "Gizli tuvaleti buldun! (+5 Love)")
	local ls = plr:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Love") then
		ls.Love.Value += 5
	end
end)

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

local pullupCooldowns = {}
local savedMotorC0 = {}

local function applyPullupLimbPose(character, isHanging, isPulledUp)
	local animateScript = character:FindFirstChild("Animate")
	if animateScript then
		animateScript.Disabled = isHanging
	end

	local hum = character:FindFirstChildOfClass("Humanoid")
	if hum and isHanging then
		for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
			track:Stop(0)
		end
	end

	local torso = character:FindFirstChild("Torso")
	if torso then
		local rs = torso:FindFirstChild("Right Shoulder")
		local ls = torso:FindFirstChild("Left Shoulder")
		local rh = torso:FindFirstChild("Right Hip")
		local lh = torso:FindFirstChild("Left Hip")
		if rs and ls and rh and lh then
			if not savedMotorC0[character] then
				savedMotorC0[character] = { rs = rs.C0, ls = ls.C0, rh = rh.C0, lh = lh.C0 }
			end
			if isHanging then
				local armPitch = isPulledUp and math.rad(130) or math.rad(175)
				local legBend = isPulledUp and math.rad(25) or math.rad(10)
				TweenService:Create(rs, TweenInfo.new(0.11), { C0 = CFrame.new(1, 0.7, 0) * CFrame.Angles(armPitch, math.rad(90), 0) }):Play()
				TweenService:Create(ls, TweenInfo.new(0.11), { C0 = CFrame.new(-1, 0.7, 0) * CFrame.Angles(armPitch, math.rad(-90), 0) }):Play()
				TweenService:Create(rh, TweenInfo.new(0.11), { C0 = CFrame.new(1, -1, 0) * CFrame.Angles(-legBend, math.rad(90), 0) }):Play()
				TweenService:Create(lh, TweenInfo.new(0.11), { C0 = CFrame.new(-1, -1, 0) * CFrame.Angles(-legBend, math.rad(-90), 0) }):Play()
			else
				rs.C0 = savedMotorC0[character].rs
				ls.C0 = savedMotorC0[character].ls
				rh.C0 = savedMotorC0[character].rh
				lh.C0 = savedMotorC0[character].lh
				savedMotorC0[character] = nil
			end
		end
	else
		local rUA = character:FindFirstChild("RightUpperArm")
		local lUA = character:FindFirstChild("LeftUpperArm")
		local rLA = character:FindFirstChild("RightLowerArm")
		local lLA = character:FindFirstChild("LeftLowerArm")
		local rs = rUA and rUA:FindFirstChild("RightShoulder")
		local ls = lUA and lUA:FindFirstChild("LeftShoulder")
		local re = rLA and rLA:FindFirstChild("RightElbow")
		local le = lLA and lLA:FindFirstChild("LeftElbow")
		if rs and ls then
			if not savedMotorC0[character] then
				savedMotorC0[character] = {
					rs = rs.C0, ls = ls.C0,
					re = re and re.C0, le = le and le.C0
				}
			end
			if isHanging then
				local shoulderPitch = isPulledUp and math.rad(135) or math.rad(175)
				local elbowBend = isPulledUp and math.rad(65) or math.rad(8)
				TweenService:Create(rs, TweenInfo.new(0.11), { C0 = CFrame.new(rs.C0.Position) * CFrame.Angles(shoulderPitch, 0, math.rad(-6)) }):Play()
				TweenService:Create(ls, TweenInfo.new(0.11), { C0 = CFrame.new(ls.C0.Position) * CFrame.Angles(shoulderPitch, 0, math.rad(6)) }):Play()
				if re and le then
					TweenService:Create(re, TweenInfo.new(0.11), { C0 = CFrame.new(re.C0.Position) * CFrame.Angles(elbowBend, 0, 0) }):Play()
					TweenService:Create(le, TweenInfo.new(0.11), { C0 = CFrame.new(le.C0.Position) * CFrame.Angles(elbowBend, 0, 0) }):Play()
				end
			else
				rs.C0 = savedMotorC0[character].rs
				ls.C0 = savedMotorC0[character].ls
				if re and savedMotorC0[character].re then re.C0 = savedMotorC0[character].re end
				if le and savedMotorC0[character].le then le.C0 = savedMotorC0[character].le end
				savedMotorC0[character] = nil
			end
		end
	end
end

local function togglePlayerPullup(player, forceState)
	if player:GetAttribute("InArena") then return end
	local current = player:GetAttribute("OnPullup") == true
	local nextState = (forceState ~= nil) and forceState or (not current)
	if nextState == current then return end

	player:SetAttribute("OnPullup", nextState)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")

	if hrp and hum then
		if nextState then
			hum.WalkSpeed = 0
			hum.JumpPower = 0
			hum.AutoRotate = false
			hrp.Anchored = true
			hrp.CFrame = CFrame.new(GYM_POS + Vector3.new(0, 7.6, 0.25)) * CFrame.Angles(math.rad(6), 0, 0)
			applyPullupLimbPose(char, true, false)
			EvTogglePullup:FireClient(player, true)
		else
			applyPullupLimbPose(char, false, false)
			hrp.Anchored = false
			hum.AutoRotate = true
			hum.WalkSpeed = 16
			hum.JumpPower = 50
			hrp.CFrame = CFrame.new(GYM_POS + Vector3.new(0, 3.5, 5.5))
			EvTogglePullup:FireClient(player, false)
		end
	end
end

BarPrompt.Triggered:Connect(function(player)
	togglePlayerPullup(player)
end)

EvTogglePullup.OnServerEvent:Connect(function(player)
	togglePlayerPullup(player, false)
end)

EvPullupAction.OnServerEvent:Connect(function(player)
	if not player:GetAttribute("OnPullup") then return end
	local now = os.clock()
	if pullupCooldowns[player] and now - pullupCooldowns[player] < 0.26 then return end
	pullupCooldowns[player] = now

	local ls = player:FindFirstChild("leaderstats")
	if not ls then return end
	local power = ls.Power
	local love = ls.Love

	local baseGain = 1
	local loveBonus = love.Value * 0.01
	local totalGain = math.max(1, math.floor((baseGain + loveBonus) * 100) / 100)
	power.Value = math.floor((power.Value + totalGain) * 100) / 100

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then
		local upCF = CFrame.new(GYM_POS + Vector3.new(0, 9.4, 0.15)) * CFrame.Angles(math.rad(-8), 0, 0)
		local downCF = CFrame.new(GYM_POS + Vector3.new(0, 7.6, 0.25)) * CFrame.Angles(math.rad(6), 0, 0)
		applyPullupLimbPose(char, true, true)
		TweenService:Create(hrp, TweenInfo.new(0.11, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = upCF }):Play()
		task.delay(0.13, function()
			if player:GetAttribute("OnPullup") and hrp.Parent then
				applyPullupLimbPose(char, true, false)
				TweenService:Create(hrp, TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = downCF }):Play()
			end
		end)
	end

	EvPullupAction:FireClient(player, totalGain)
end)

-- C) GİZLİ YÜKSEK ARENA (HARİTADAN GÖRÜNMEZ)
local ARENA_CENTER = Vector3.new(0, 4500, 0)
local ArenaFolder = Instance.new("Folder", ModFolder)
ArenaFolder.Name = "HiddenDuelArena"

local function aPart(n, sh, sz, cf, mat, col, cc)
	local p = Instance.new("Part", ArenaFolder)
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

aPart("ArenaFloor", Enum.PartType.Cylinder, Vector3.new(2, 110, 110), CFrame.new(ARENA_CENTER) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Marble, Color3.fromRGB(42, 46, 56), true)
aPart("ArenaRingGold", Enum.PartType.Cylinder, Vector3.new(2.1, 86, 86), CFrame.new(ARENA_CENTER) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Neon, Color3.fromRGB(255, 195, 75), false)
aPart("ArenaInnerFloor", Enum.PartType.Cylinder, Vector3.new(2.15, 83, 83), CFrame.new(ARENA_CENTER) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Slate, Color3.fromRGB(58, 64, 78), true)
aPart("ArenaCeiling", Enum.PartType.Cylinder, Vector3.new(2, 116, 116), CFrame.new(ARENA_CENTER + Vector3.new(0, 45, 0)) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.SmoothPlastic, Color3.fromRGB(25, 28, 36), true)

for i = 1, 16 do
	local ang = (i / 16) * math.pi * 2
	local pos = ARENA_CENTER + Vector3.new(math.cos(ang) * 53, 22.5, math.sin(ang) * 53)
	aPart("ArenaWall_" .. i, Enum.PartType.Block, Vector3.new(24, 45, 3), CFrame.new(pos) * CFrame.Angles(0, -ang + math.pi / 2, 0), Enum.Material.Concrete, Color3.fromRGB(36, 40, 50), true)
	if i % 2 == 0 then
		local torch = aPart("ArenaTorch_" .. i, Enum.PartType.Ball, Vector3.new(2.5, 2.5, 2.5), CFrame.new(ARENA_CENTER + Vector3.new(math.cos(ang) * 49, 16, math.sin(ang) * 49)), Enum.Material.Neon, Color3.fromRGB(255, 140, 50), false)
		local l = Instance.new("PointLight", torch)
		l.Color = Color3.fromRGB(255, 150, 60)
		l.Range = 45
		l.Brightness = 1.5
	end
end

local function giveArenaSword(targetModel, damageValue)
	local tool = Instance.new("Tool")
	tool.Name = "ArenaBlade"
	tool.RequiresHandle = true

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.4, 0.4, 4.4)
	handle.Material = Enum.Material.Neon
	handle.Color = Color3.fromRGB(110, 220, 255)
	handle.CanCollide = false
	handle.Parent = tool

	local slashSFX = Instance.new("Sound", handle)
	slashSFX.SoundId = "rbxassetid://12222216"
	slashSFX.Volume = 0.7

	local swingCD = false
	tool.Activated:Connect(function()
		if swingCD then return end
		swingCD = true
		slashSFX:Play()
		local str = Instance.new("StringValue", tool)
		str.Name = "toolanim"
		str.Value = "Slash"
		Debris:AddItem(str, 0.2)
		task.delay(0.45, function() swingCD = false end)
	end)

	local hitCD = {}
	handle.Touched:Connect(function(hit)
		local victimChar = hit.Parent
		if not victimChar or victimChar == targetModel then return end
		local hum = victimChar:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 and not hitCD[victimChar] then
			hitCD[victimChar] = true
			hum:TakeDamage(damageValue)
			task.delay(0.4, function() hitCD[victimChar] = nil end)
		end
	end)

	tool.Parent = targetModel
	return tool
end

-- D) 6 NADİRLİKLİ NPC SİSTEMİ
local NPCFolder = Instance.new("Folder", ModFolder)
NPCFolder.Name = "RoamingNPCs"

local RARITIES = {
	{ Name = "Common",    Chance = 60.000, ReqPower = 0,     Color = Color3.fromRGB(185, 195, 205) },
	{ Name = "Rare",      Chance = 25.000, ReqPower = 100,   Color = Color3.fromRGB(65, 165, 255)  },
	{ Name = "Epic",      Chance = 10.000, ReqPower = 1000,  Color = Color3.fromRGB(175, 75, 255)  },
	{ Name = "Mythic",    Chance = 4.000,  ReqPower = 5000,  Color = Color3.fromRGB(255, 65, 115)  },
	{ Name = "Legendary", Chance = 0.999,  ReqPower = 15000, Color = Color3.fromRGB(255, 200, 45)  },
	{ Name = "Godly",     Chance = 0.001,  ReqPower = 50000, Color = Color3.fromRGB(255, 95, 245)  },
}

local REJECTION_LINES = {
	"Üzgünüm tatlım, bu güçle ancak uzaktan bakarsın.",
	"Biraz daha barfiks çekip gel, şu an hiç tipim değilsin!",
	"Auran çok zayıf, kalbimi kazanmak için çok erken.",
	"Senin seviyen bana yetmez, önce güçlenmelisin!",
	"Benim standartlarım çok yüksek canım, üzgünüm.",
	"Bu kadar az güçle karşıma çıkmaya nasıl cesaret ettin?",
	"Belki 1000 barfiks sonra tekrar konuşabiliriz.",
	"Tatlısın ama benim ligimde değilsin!",
	"Gücün yetmiyor, kalbim şimdilik kapalı.",
	"Önce kendini kanıtla, sonra kalbimi çalmayı dene!",
}

local function rollRarity()
	local r = math.random() * 100
	local acc = 0
	for _, info in ipairs(RARITIES) do
		acc += info.Chance
		if r <= acc then
			return info
		end
	end
	return RARITIES[1]
end

local function spawnBurstEffect(pos, color)
	local holder = Instance.new("Part", ModFolder)
	holder.Size = Vector3.new(1, 1, 1)
	holder.Position = pos
	holder.Anchored = true
	holder.CanCollide = false
	holder.Transparency = 1

	local pe = Instance.new("ParticleEmitter", holder)
	pe.Color = ColorSequence.new(color, Color3.fromRGB(255, 255, 255))
	pe.Size = NumberSequence.new(0.85, 0)
	pe.Speed = NumberRange.new(8, 16)
	pe.Lifetime = NumberRange.new(0.5, 0.9)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe:Emit(30)
	Debris:AddItem(holder, 1.2)
end

local function buildPlainRig(name, spawnPos, rarityInfo, isBoss)
	local npc = Instance.new("Model")
	npc.Name = name

	local hrp = Instance.new("Part", npc)
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(2, 2, 1)
	hrp.CFrame = CFrame.new(spawnPos)
	hrp.Transparency = 1
	hrp.CanCollide = false

	local torso = Instance.new("Part", npc)
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.CFrame = hrp.CFrame
	torso.Material = Enum.Material.SmoothPlastic
	torso.Color = Color3.fromRGB(225, 225, 225)
	torso.CanCollide = false

	local head = Instance.new("Part", npc)
	head.Name = "Head"
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.CFrame = hrp.CFrame * CFrame.new(0, 1.6, 0)
	head.Material = Enum.Material.SmoothPlastic
	head.Color = Color3.fromRGB(235, 235, 235)
	head.CanCollide = false

	local limbs = {
		{ "Left Arm",  Vector3.new(1, 2, 1), CFrame.new(-1.5, 0, 0) },
		{ "Right Arm", Vector3.new(1, 2, 1), CFrame.new(1.5, 0, 0)  },
		{ "Left Leg",  Vector3.new(1, 2, 1), CFrame.new(-0.5, -2, 0)},
		{ "Right Leg", Vector3.new(1, 2, 1), CFrame.new(0.5, -2, 0) },
	}
	for _, l in ipairs(limbs) do
		local p = Instance.new("Part", npc)
		p.Name = l[1]
		p.Size = l[2]
		p.CFrame = hrp.CFrame * l[3]
		p.Material = Enum.Material.SmoothPlastic
		p.Color = Color3.fromRGB(215, 215, 215)
		p.CanCollide = false
	end

	for _, part in ipairs(npc:GetChildren()) do
		if part:IsA("BasePart") and part ~= hrp then
			local w = Instance.new("WeldConstraint", hrp)
			w.Part0 = hrp
			w.Part1 = part
		end
	end

	local hum = Instance.new("Humanoid", npc)
	hum.WalkSpeed = isBoss and 15 or 11
	hum.HipHeight = 2
	npc.PrimaryPart = hrp

	local bb = Instance.new("BillboardGui", head)
	bb.Name = "RarityTag"
	bb.Size = UDim2.new(0, 110, 0, 28)
	bb.StudsOffset = Vector3.new(0, 1.9, 0)
	bb.MaxDistance = 55
	bb.AlwaysOnTop = false

	local lbl = Instance.new("TextLabel", bb)
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextScaled = true
	lbl.TextStrokeTransparency = 0.35
	lbl.TextColor3 = rarityInfo.Color
	lbl.Text = isBoss
		and ("⚔️ " .. rarityInfo.Name .. " Rakip")
		or ("[" .. rarityInfo.Name .. "]\nGüç: " .. rarityInfo.ReqPower)

	return npc, hum, hrp
end

-- E) ARENA DÜELLO BAŞLATICI
local function startArenaDuel(player, rarityInfo)
	if player:GetAttribute("InArena") then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local ls = player:FindFirstChild("leaderstats")
	if not (hrp and hum and ls) then return end

	player:SetAttribute("InArena", true)
	local returnCF = hrp.CFrame

	local slotOffset = Vector3.new((player.UserId % 5) * 4, 3, -24)
	hrp.CFrame = CFrame.new(ARENA_CENTER + slotOffset, ARENA_CENTER + Vector3.new(0, 3, 24))

	local pPower = math.max(10, ls.Power.Value)
	local rarityMult = { Common = 0.65, Rare = 0.75, Epic = 0.82, Mythic = 0.88, Legendary = 0.92, Godly = 0.95 }
	local mult = rarityMult[rarityInfo.Name] or 0.75

	local bossMaxHP = math.floor(100 + (rarityInfo.ReqPower * 0.05) + (pPower * 0.25))
	local playerSwordDmg = math.max(25, math.floor(bossMaxHP / 4))
	local bossSwordDmg = math.max(8, math.floor(18 * mult))

	local playerSword = giveArenaSword(char, playerSwordDmg)
	hum:EquipTool(playerSword)

	local bossPos = ARENA_CENTER + Vector3.new(0, 3, 24)
	local bossNPC, bossHum, bossHRP = buildPlainRig("ArenaRival_" .. player.Name, bossPos, rarityInfo, true)
	bossHum.MaxHealth = bossMaxHP
	bossHum.Health = bossMaxHP
	bossNPC.Parent = ArenaFolder
	spawnBurstEffect(bossPos, rarityInfo.Color)

	local bossSword = giveArenaSword(bossNPC, bossSwordDmg)
	bossHum:EquipTool(bossSword)

	EvNotify:FireClient(player, "ArenaStart", rarityInfo.Name .. " rakiple düello başladı! Kılıcınla saldır!")

	local ended = false
	local function finishDuel(won)
		if ended then return end
		ended = true
		if playerSword and playerSword.Parent then playerSword:Destroy() end
		if bossNPC and bossNPC.Parent then
			spawnBurstEffect(bossHRP.Position, rarityInfo.Color)
			bossNPC:Destroy()
		end
		player:SetAttribute("InArena", false)
		if hrp and hrp.Parent then
			hrp.CFrame = returnCF
		end
		if won then
			local bonusLove = math.max(5, math.floor(pPower * 0.12))
			ls.Love.Value += bonusLove
			EvNotify:FireClient(player, "ArenaWin", "Düelloyu kazandın! (+" .. bonusLove .. " Love)")
		else
			EvNotify:FireClient(player, "ArenaLose", "Düelloyu kaybettin! Gücünü artırıp tekrar dene.")
		end
	end

	task.spawn(function()
		while not ended and bossNPC.Parent and bossHum.Health > 0 and hum.Health > 0 do
			if hrp and hrp.Parent then
				bossHum:MoveTo(hrp.Position)
				if (bossHRP.Position - hrp.Position).Magnitude <= 7 then
					bossSword:Activate()
				end
			end
			task.wait(0.35)
		end
	end)

	bossHum.Died:Connect(function() finishDuel(true) end)
	hum.Died:Connect(function()
		task.wait(0.2)
		finishDuel(false)
	end)
	task.delay(60, function() finishDuel(false) end)
end

-- F) DİYALOG SEÇENEKLERİ VE NPC DOĞUM YÖNETİMİ
local activeNPCData = {}

EvDialogueChoice.OnServerEvent:Connect(function(player, npcModel, choiceIndex)
	local info = activeNPCData[npcModel]
	if not info or not npcModel or not npcModel.Parent then return end

	local ls = player:FindFirstChild("leaderstats")
	if not ls then return end
	local pPower = ls.Power.Value
	local pLove = ls.Love

	if pPower < info.ReqPower then return end

	local deltaLove = 0
	if choiceIndex == 1 then
		deltaLove = -math.max(1, math.floor(pPower / 10))
		pLove.Value = math.max(0, pLove.Value + deltaLove)
		EvNotify:FireClient(player, "LoveLoss", "Yanlış cevap! (" .. deltaLove .. " Love)")
	elseif choiceIndex == 2 then
		deltaLove = math.max(1, math.floor(pPower / 10))
		pLove.Value += deltaLove
		EvNotify:FireClient(player, "LoveGain", "Güzel sohbet! (+" .. deltaLove .. " Love)")
	elseif choiceIndex == 3 then
		deltaLove = math.max(1, math.floor(pPower / 8))
		pLove.Value += deltaLove
		EvNotify:FireClient(player, "LoveGain", "Etkileyici sözler! (+" .. deltaLove .. " Love)")
	elseif choiceIndex == 4 then
		deltaLove = math.max(1, math.floor(pPower / 5))
		pLove.Value += deltaLove
		EvNotify:FireClient(player, "LoveGain", "Kalbinden vurdun! (+" .. deltaLove .. " Love)")
	end

	task.delay(0.6, function()
		if player and player.Parent then
			startArenaDuel(player, info)
		end
	end)
end)

local function spawnSingleRoamingNPC()
	if #NPCFolder:GetChildren() >= 20 then return end

	local rarityInfo = rollRarity()
	local rx = math.random(-130, 130)
	local rz = math.random(-130, 90)
	local spawnPos = Vector3.new(rx, 3.5, rz)

	local npc, hum, hrp = buildPlainRig("NPC_" .. rarityInfo.Name, spawnPos, rarityInfo, false)
	npc.Parent = NPCFolder
	activeNPCData[npc] = rarityInfo
	spawnBurstEffect(spawnPos, rarityInfo.Color)

	local prompt = Instance.new("ProximityPrompt", hrp)
	prompt.ActionText = "Konuş"
	prompt.ObjectText = rarityInfo.Name
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false

	prompt.Triggered:Connect(function(player)
		if player:GetAttribute("InArena") or player:GetAttribute("OnPullup") then return end
		local ls = player:FindFirstChild("leaderstats")
		if not ls then return end

		if ls.Power.Value < rarityInfo.ReqPower then
			local msg = REJECTION_LINES[math.random(1, #REJECTION_LINES)]
				.. " (Gereken Güç: " .. rarityInfo.ReqPower .. ")"
			EvNotify:FireClient(player, "Reject", msg)
		else
			EvInteractNPC:FireClient(player, npc, rarityInfo.Name, rarityInfo.ReqPower)
		end
	end)

	task.spawn(function()
		while npc.Parent and hum.Health > 0 do
			local wx = math.clamp(hrp.Position.X + math.random(-35, 35), -145, 145)
			local wz = math.clamp(hrp.Position.Z + math.random(-35, 35), -145, 105)
			hum:MoveTo(Vector3.new(wx, 3.5, wz))
			task.wait(math.random(3, 6))
		end
	end)

	task.delay(120, function()
		if npc and npc.Parent then
			spawnBurstEffect(hrp.Position, rarityInfo.Color)
			activeNPCData[npc] = nil
			npc:Destroy()
			task.wait(0.3)
			spawnSingleRoamingNPC()
		end
	end)
end

for i = 1, 20 do
	task.delay(i * 0.15, spawnSingleRoamingNPC)
end

------------------------------------------------------------------------
-- 10. İSTEMCİ ARAYÜZÜ ENJEKSİYONU (TEK DOSYA DESTEĞİ)
------------------------------------------------------------------------
local CLIENT_SOURCE = [[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local NetFolder = ReplicatedStorage:WaitForChild("SimNet")
local EvInteractNPC = NetFolder:WaitForChild("InteractNPC")
local EvDialogueChoice = NetFolder:WaitForChild("DialogueChoice")
local EvPullupAction = NetFolder:WaitForChild("PullupAction")
local EvTogglePullup = NetFolder:WaitForChild("TogglePullup")
local EvNotify = NetFolder:WaitForChild("Notify")

RunService.RenderStepped:Connect(function()
	local myChar = LocalPlayer.Character
	local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local hide = plr:GetAttribute("OnPullup") == true
			for _, desc in ipairs(plr.Character:GetDescendants()) do
				if desc:IsA("BasePart") or desc:IsA("Decal") then
					if desc.Name ~= "HumanoidRootPart" then
						desc.LocalTransparencyModifier = hide and 1 or 0
					end
				elseif desc:IsA("BillboardGui") then
					desc.Enabled = not hide
				end
			end
		end
	end

	if myHRP then
		local mapFolder = workspace:FindFirstChild("SimulatorBaseplateMap")
		local sysFolder = mapFolder and mapFolder:FindFirstChild("SimulatorSystems")
		local npcFolder = sysFolder and sysFolder:FindFirstChild("RoamingNPCs")
		if npcFolder then
			for _, npc in ipairs(npcFolder:GetChildren()) do
				local head = npc:FindFirstChild("Head")
				local tag = head and head:FindFirstChild("RarityTag")
				if head and tag then
					local dist = (head.Position - myHRP.Position).Magnitude
					local alpha = math.clamp(1 - ((dist - 5) / 35), 0, 1)
					local scale = 0.8 + alpha * 0.65
					tag.Size = UDim2.new(0, math.floor(110 * scale), 0, math.floor(28 * scale))
				end
			end
		end
	end
end)

local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "SimulatorHUD"
ScreenGui.ResetOnSpawn = false

local StatsFrame = Instance.new("Frame", ScreenGui)
StatsFrame.Size = UDim2.new(0, 175, 0, 76)
StatsFrame.Position = UDim2.new(0, 16, 0.45, -38)
StatsFrame.BackgroundColor3 = Color3.fromRGB(22, 24, 34)
StatsFrame.BackgroundTransparency = 0.15

local stCorner = Instance.new("UICorner", StatsFrame)
stCorner.CornerRadius = UDim.new(0, 10)
local stStroke = Instance.new("UIStroke", StatsFrame)
stStroke.Color = Color3.fromRGB(255, 195, 75)
stStroke.Thickness = 1.5

local PowerLbl = Instance.new("TextLabel", StatsFrame)
PowerLbl.Size = UDim2.new(1, -16, 0, 30)
PowerLbl.Position = UDim2.new(0, 10, 0, 6)
PowerLbl.BackgroundTransparency = 1
PowerLbl.Font = Enum.Font.GothamBold
PowerLbl.TextSize = 14
PowerLbl.TextXAlignment = Enum.TextXAlignment.Left
PowerLbl.TextColor3 = Color3.fromRGB(255, 210, 75)
PowerLbl.Text = "💪 Power: 0"

local LoveLbl = Instance.new("TextLabel", StatsFrame)
LoveLbl.Size = UDim2.new(1, -16, 0, 30)
LoveLbl.Position = UDim2.new(0, 10, 0, 38)
LoveLbl.BackgroundTransparency = 1
LoveLbl.Font = Enum.Font.GothamBold
LoveLbl.TextSize = 14
LoveLbl.TextXAlignment = Enum.TextXAlignment.Left
LoveLbl.TextColor3 = Color3.fromRGB(255, 115, 185)
LoveLbl.Text = "❤️ Love: 10"

task.spawn(function()
	local ls = LocalPlayer:WaitForChild("leaderstats", 15)
	if ls then
		local pVal = ls:WaitForChild("Power")
		local lVal = ls:WaitForChild("Love")
		local function refresh()
			PowerLbl.Text = "💪 Power: " .. tostring(pVal.Value)
			LoveLbl.Text = "❤️ Love: " .. tostring(lVal.Value)
		end
		refresh()
		pVal.Changed:Connect(refresh)
		lVal.Changed:Connect(refresh)
	end
end)

local PullupPanel = Instance.new("Frame", ScreenGui)
PullupPanel.Size = UDim2.new(0, 260, 0, 68)
PullupPanel.Position = UDim2.new(0.5, -130, 0.80, 0)
PullupPanel.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
PullupPanel.Visible = false

local ppCorner = Instance.new("UICorner", PullupPanel)
ppCorner.CornerRadius = UDim.new(0, 10)

local PullupHint = Instance.new("TextLabel", PullupPanel)
PullupHint.Size = UDim2.new(1, -12, 0, 24)
PullupHint.Position = UDim2.new(0, 6, 0, 4)
PullupHint.BackgroundTransparency = 1
PullupHint.Font = Enum.Font.GothamSemibold
PullupHint.TextSize = 12
PullupHint.TextColor3 = Color3.fromRGB(255, 220, 110)
PullupHint.Text = "Ekrana Tıklayarak Barfiks Çek!"

local ExitPullupBtn = Instance.new("TextButton", PullupPanel)
ExitPullupBtn.Size = UDim2.new(0, 150, 0, 30)
ExitPullupBtn.Position = UDim2.new(0.5, -75, 0, 32)
ExitPullupBtn.BackgroundColor3 = Color3.fromRGB(215, 65, 75)
ExitPullupBtn.Font = Enum.Font.GothamBold
ExitPullupBtn.TextSize = 13
ExitPullupBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ExitPullupBtn.Text = "Barfiksten İn (E)"

local epCorner = Instance.new("UICorner", ExitPullupBtn)
epCorner.CornerRadius = UDim.new(0, 8)

ExitPullupBtn.MouseButton1Click:Connect(function()
	EvTogglePullup:FireServer()
end)

EvTogglePullup.OnClientEvent:Connect(function(isOn)
	PullupPanel.Visible = isOn
end)

local BannerLabel = Instance.new("TextLabel", ScreenGui)
BannerLabel.Size = UDim2.new(0.46, 0, 0, 34)
BannerLabel.Position = UDim2.new(0.27, 0, 0.14, 0)
BannerLabel.BackgroundColor3 = Color3.fromRGB(22, 16, 22)
BannerLabel.BackgroundTransparency = 1
BannerLabel.TextTransparency = 1
BannerLabel.TextStrokeTransparency = 1
BannerLabel.Font = Enum.Font.GothamBold
BannerLabel.TextSize = 14
BannerLabel.TextWrapped = true
BannerLabel.Text = ""

local BannerCorner = Instance.new("UICorner", BannerLabel)
BannerCorner.CornerRadius = UDim.new(0, 8)

local bannerToken = 0
local function showBanner(text, color, duration)
	bannerToken += 1
	local myToken = bannerToken
	BannerLabel.Text = text
	BannerLabel.TextColor3 = color
	BannerLabel.BackgroundTransparency = 0.35
	BannerLabel.TextTransparency = 0
	BannerLabel.TextStrokeTransparency = 0.25

	task.delay(duration or 2, function()
		if bannerToken ~= myToken then return end
		TweenService:Create(BannerLabel, TweenInfo.new(0.35), {
			TextTransparency = 1,
			TextStrokeTransparency = 1,
			BackgroundTransparency = 1,
		}):Play()
	end)
end

local function spawnFloatingPopup(text, color)
	local lbl = Instance.new("TextLabel", ScreenGui)
	lbl.Size = UDim2.new(0, 150, 0, 26)
	lbl.Position = UDim2.new(0.5 + (math.random(-10, 10) / 100), -75, 0.56, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 15
	lbl.TextColor3 = color
	lbl.TextStrokeTransparency = 0.25
	lbl.Text = text

	local tw = TweenService:Create(lbl, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = lbl.Position - UDim2.new(0, 0, 0.13, 0),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	tw:Play()
	tw.Completed:Connect(function() lbl:Destroy() end)
end

local DialogFrame = Instance.new("Frame", ScreenGui)
DialogFrame.Size = UDim2.new(0, 410, 0, 225)
DialogFrame.Position = UDim2.new(0.5, -205, 0.64, 0)
DialogFrame.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
DialogFrame.Visible = false

local dfCorner = Instance.new("UICorner", DialogFrame)
dfCorner.CornerRadius = UDim.new(0, 12)
local dfStroke = Instance.new("UIStroke", DialogFrame)
dfStroke.Color = Color3.fromRGB(255, 115, 175)
dfStroke.Thickness = 2

local TitleLbl = Instance.new("TextLabel", DialogFrame)
TitleLbl.Size = UDim2.new(1, -20, 0, 32)
TitleLbl.Position = UDim2.new(0, 10, 0, 8)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextSize = 15
TitleLbl.TextColor3 = Color3.fromRGB(255, 185, 215)
TitleLbl.Text = "Sohbet Seçeneğini Seç"

local currentNPC = nil
local choiceLabels = {
	"1. [Diyalog Seçeneği 1 - Sonra Düzenlenecek] (-1/10 Güç Love)",
	"2. [Diyalog Seçeneği 2 - Sonra Düzenlenecek] (+1/10 Güç Love)",
	"3. [Diyalog Seçeneği 3 - Sonra Düzenlenecek] (+1/8 Güç Love)",
	"4. [Diyalog Seçeneği 4 - Sonra Düzenlenecek] (+1/5 Güç Love)",
}

for idx = 1, 4 do
	local btn = Instance.new("TextButton", DialogFrame)
	btn.Size = UDim2.new(1, -22, 0, 36)
	btn.Position = UDim2.new(0, 11, 0, 44 + (idx - 1) * 42)
	btn.BackgroundColor3 = Color3.fromRGB(38, 42, 58)
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 12
	btn.TextColor3 = Color3.fromRGB(245, 245, 255)
	btn.Text = choiceLabels[idx]

	local bc = Instance.new("UICorner", btn)
	bc.CornerRadius = UDim.new(0, 8)

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(215, 75, 135) }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(38, 42, 58) }):Play()
	end)

	btn.MouseButton1Click:Connect(function()
		if currentNPC then
			EvDialogueChoice:FireServer(currentNPC, idx)
		end
		DialogFrame.Visible = false
		currentNPC = nil
	end)
end

EvInteractNPC.OnClientEvent:Connect(function(npcModel, rarityName)
	currentNPC = npcModel
	TitleLbl.Text = "💬 " .. rarityName .. " Karakterle Konuşuyorsun"
	DialogFrame.Size = UDim2.new(0, 370, 0, 200)
	DialogFrame.Visible = true
	TweenService:Create(DialogFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 410, 0, 225),
	}):Play()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if LocalPlayer:GetAttribute("OnPullup") then
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			EvPullupAction:FireServer()
		elseif input.KeyCode == Enum.KeyCode.E then
			EvTogglePullup:FireServer()
		end
	end
end)

EvPullupAction.OnClientEvent:Connect(function(gainedPower)
	spawnFloatingPopup("+" .. tostring(gainedPower) .. " Power 💪", Color3.fromRGB(255, 210, 65))
	local char = LocalPlayer.Character
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

		local tw = TweenService:Create(ring, TweenInfo.new(0.32), {
			Size = Vector3.new(0.08, 8.5, 8.5),
			Transparency = 1,
		})
		tw:Play()
		tw.Completed:Connect(function() ring:Destroy() end)
	end
end)

EvNotify.OnClientEvent:Connect(function(kind, message)
	if kind == "Reject" then
		showBanner(message, Color3.fromRGB(255, 65, 75), 2)
	elseif kind == "LoveGain" then
		showBanner(message, Color3.fromRGB(255, 125, 190), 2)
		spawnFloatingPopup(message, Color3.fromRGB(255, 120, 195))
	elseif kind == "LoveLoss" then
		showBanner(message, Color3.fromRGB(255, 80, 80), 2)
	elseif kind == "ArenaWin" then
		showBanner(message, Color3.fromRGB(95, 255, 145), 2.5)
	elseif kind == "ArenaLose" then
		showBanner(message, Color3.fromRGB(255, 85, 85), 2.5)
	else
		showBanner(message, Color3.fromRGB(255, 225, 115), 2.2)
	end
end)
]]

local sps = StarterPlayer:FindFirstChild("StarterPlayerScripts")
if sps and not sps:FindFirstChild("AutoSimulatorClient") then
	local ok, ls = pcall(function()
		local s = Instance.new("LocalScript")
		s.Name = "AutoSimulatorClient"
		s.Source = CLIENT_SOURCE
		s.Parent = sps
		return s
	end)
	if ok and ls then
		for _, plr in ipairs(Players:GetPlayers()) do
			local ps = plr:FindFirstChild("PlayerScripts")
			if ps and not ps:FindFirstChild("AutoSimulatorClient") then
				ls:Clone().Parent = ps
			end
		end
	end
end