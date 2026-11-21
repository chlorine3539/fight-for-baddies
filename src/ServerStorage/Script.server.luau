-- Bu Script'i ServerScriptService içine yerleştir (Normal Script olmalı, LocalScript DEĞİL)
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Eski harita ve varsayılan parçaları temizle
for _, obj in ipairs(Workspace:GetChildren()) do
	if obj.Name == "Baseplate" or obj:IsA("SpawnLocation") or obj.Name == "SimulatorBaseplateMap" then
		obj:Destroy()
	end
end

local MapFolder = Instance.new("Folder")
MapFolder.Name = "SimulatorBaseplateMap"
MapFolder.Parent = Workspace

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

local Sky = Instance.new("Sky")
Sky.Name = "CleanSimulatorSky"
Sky.CelestialBodiesShown = true
Sky.SunAngularSize = 20
Sky.StarCount = 800
Sky.Parent = Lighting

local Atmosphere = Instance.new("Atmosphere")
Atmosphere.Density = 0.22
Atmosphere.Offset = 0.1
Atmosphere.Color = Color3.fromRGB(195, 220, 242)
Atmosphere.Decay = Color3.fromRGB(130, 170, 210)
Atmosphere.Glare = 0.1
Atmosphere.Haze = 0.4
Atmosphere.Parent = Lighting

local SunRays = Instance.new("SunRaysEffect")
SunRays.Intensity = 0.06
SunRays.Spread = 0.6
SunRays.Parent = Lighting

local BASE_SIZE = 512
local BASE_THICKNESS = 16

local Baseplate = Instance.new("Part")
Baseplate.Name = "SimulatorBaseplate"
Baseplate.Size = Vector3.new(BASE_SIZE, BASE_THICKNESS, BASE_SIZE)
Baseplate.Position = Vector3.new(0, -BASE_THICKNESS / 2, 0) -- Üst yüzeyi Y = 0
Baseplate.Anchored = true
Baseplate.CanCollide = true
Baseplate.Material = Enum.Material.Grass
Baseplate.Color = Color3.fromRGB(96, 166, 98)
Baseplate.TopSurface = Enum.SurfaceType.Smooth
Baseplate.BottomSurface = Enum.SurfaceType.Smooth
Baseplate.Parent = MapFolder

local GridTexture = Instance.new("Texture")
GridTexture.Name = "SubtleGrid"
GridTexture.Face = Enum.NormalId.Top
GridTexture.Texture = "rbxassetid://6372755229"
GridTexture.StudsPerTileU = 16
GridTexture.StudsPerTileV = 16
GridTexture.Transparency = 0.9
GridTexture.Color3 = Color3.fromRGB(240, 248, 240)
GridTexture.Parent = Baseplate

local borderThickness = 3.5
local borderHeight = 1.6
local wallHeight = 45

local borderConfigs = {
	{
		pos = Vector3.new(0, borderHeight / 2, BASE_SIZE / 2 + borderThickness / 2),
		size = Vector3.new(BASE_SIZE + borderThickness * 2, borderHeight, borderThickness),
		wallPos = Vector3.new(0, wallHeight / 2, BASE_SIZE / 2 + borderThickness / 2),
		wallSize = Vector3.new(BASE_SIZE + borderThickness * 2, wallHeight, borderThickness),
	},
	{
		pos = Vector3.new(0, borderHeight / 2, -BASE_SIZE / 2 - borderThickness / 2),
		size = Vector3.new(BASE_SIZE + borderThickness * 2, borderHeight, borderThickness),
		wallPos = Vector3.new(0, wallHeight / 2, -BASE_SIZE / 2 - borderThickness / 2),
		wallSize = Vector3.new(BASE_SIZE + borderThickness * 2, wallHeight, borderThickness),
	},
	{
		pos = Vector3.new(BASE_SIZE / 2 + borderThickness / 2, borderHeight / 2, 0),
		size = Vector3.new(borderThickness, borderHeight, BASE_SIZE),
		wallPos = Vector3.new(BASE_SIZE / 2 + borderThickness / 2, wallHeight / 2, 0),
		wallSize = Vector3.new(borderThickness, wallHeight, BASE_SIZE),
	},
	{
		pos = Vector3.new(-BASE_SIZE / 2 - borderThickness / 2, borderHeight / 2, 0),
		size = Vector3.new(borderThickness, borderHeight, BASE_SIZE),
		wallPos = Vector3.new(-BASE_SIZE / 2 - borderThickness / 2, wallHeight / 2, 0),
		wallSize = Vector3.new(borderThickness, wallHeight, BASE_SIZE),
	},
}

for i, cfg in ipairs(borderConfigs) do
	local trim = Instance.new("Part")
	trim.Name = "StoneBorder_" .. i
	trim.Size = cfg.size
	trim.Position = cfg.pos
	trim.Anchored = true
	trim.CanCollide = true
	trim.Material = Enum.Material.Concrete
	trim.Color = Color3.fromRGB(215, 220, 226)
	trim.Parent = MapFolder

	local barrier = Instance.new("Part")
	barrier.Name = "InvisibleWall_" .. i
	barrier.Size = cfg.wallSize
	barrier.Position = cfg.wallPos
	barrier.Anchored = true
	barrier.Transparency = 1
	barrier.CanCollide = true
	barrier.Parent = MapFolder
end

local SpawnFolder = Instance.new("Folder")
SpawnFolder.Name = "StartingPointHub"
SpawnFolder.Parent = MapFolder

local HUB_CENTER = Vector3.new(0, 0, 165)

local Plaza = Instance.new("Part")
Plaza.Name = "StartingPlazaWhite"
Plaza.Shape = Enum.PartType.Cylinder
Plaza.Size = Vector3.new(0.8, 86, 86)
Plaza.CFrame = CFrame.new(HUB_CENTER + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90))
Plaza.Anchored = true
Plaza.CanCollide = true
Plaza.Material = Enum.Material.Marble
Plaza.Color = Color3.fromRGB(244, 246, 248)
Plaza.Parent = SpawnFolder

local InnerPlaza = Instance.new("Part")
InnerPlaza.Name = "InnerPlazaWhite"
InnerPlaza.Shape = Enum.PartType.Cylinder
InnerPlaza.Size = Vector3.new(0.84, 72, 72)
InnerPlaza.CFrame = CFrame.new(HUB_CENTER + Vector3.new(0, 0.42, 0)) * CFrame.Angles(0, 0, math.rad(90))
InnerPlaza.Anchored = true
InnerPlaza.CanCollide = false
InnerPlaza.Material = Enum.Material.SmoothPlastic
InnerPlaza.Color = Color3.fromRGB(252, 253, 255)
InnerPlaza.Parent = SpawnFolder

local SpawnPad = Instance.new("SpawnLocation")
SpawnPad.Name = "StartingPointSpawn"
SpawnPad.Size = Vector3.new(16, 0.8, 16)
SpawnPad.CFrame = CFrame.new(HUB_CENTER + Vector3.new(0, 1.2, -24))
SpawnPad.Anchored = true
SpawnPad.CanCollide = true
SpawnPad.Material = Enum.Material.Marble
SpawnPad.Color = Color3.fromRGB(232, 235, 240)
SpawnPad.Duration = 0
SpawnPad.Enabled = true
SpawnPad.Parent = SpawnFolder

local TouchSound = Instance.new("Sound")
TouchSound.Name = "SpawnChimeSFX"
TouchSound.SoundId = "rbxassetid://4612375233"
TouchSound.Volume = 0.35
TouchSound.Parent = SpawnPad

-- SADE BÜYÜK FISKİYE
local FountainModel = Instance.new("Model")
FountainModel.Name = "GrandFountain"
FountainModel.Parent = SpawnFolder

local FOUNTAIN_POS = HUB_CENTER + Vector3.new(0, 0.8, 8)

local BasinRim = Instance.new("Part")
BasinRim.Name = "BasinRim"
BasinRim.Shape = Enum.PartType.Cylinder
BasinRim.Size = Vector3.new(3.2, 32, 32)
BasinRim.CFrame = CFrame.new(FOUNTAIN_POS + Vector3.new(0, 1.6, 0)) * CFrame.Angles(0, 0, math.rad(90))
BasinRim.Anchored = true
BasinRim.CanCollide = true
BasinRim.Material = Enum.Material.Marble
BasinRim.Color = Color3.fromRGB(236, 239, 243)
BasinRim.Parent = FountainModel

local BasinWater = Instance.new("Part")
BasinWater.Name = "BasinWater"
BasinWater.Shape = Enum.PartType.Cylinder
BasinWater.Size = Vector3.new(2.6, 28.5, 28.5)
BasinWater.CFrame = CFrame.new(FOUNTAIN_POS + Vector3.new(0, 1.8, 0)) * CFrame.Angles(0, 0, math.rad(90))
BasinWater.Anchored = true
BasinWater.CanCollide = false
BasinWater.Material = Enum.Material.Glass
BasinWater.Transparency = 0.3
BasinWater.Reflectance = 0.15
BasinWater.Color = Color3.fromRGB(115, 185, 220)
BasinWater.Parent = FountainModel

local Pillar1 = Instance.new("Part")
Pillar1.Name = "PillarBottom"
Pillar1.Shape = Enum.PartType.Cylinder
Pillar1.Size = Vector3.new(7, 6, 6)
Pillar1.CFrame = CFrame.new(FOUNTAIN_POS + Vector3.new(0, 4.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
Pillar1.Anchored = true
Pillar1.CanCollide = true
Pillar1.Material = Enum.Material.Marble
Pillar1.Color = Color3.fromRGB(240, 242, 246)
Pillar1.Parent = FountainModel

local MidTier = Instance.new("Part")
MidTier.Name = "MidTier"
MidTier.Shape = Enum.PartType.Cylinder
MidTier.Size = Vector3.new(2, 16, 16)
MidTier.CFrame = CFrame.new(FOUNTAIN_POS + Vector3.new(0, 8.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
MidTier.Anchored = true
MidTier.CanCollide = true
MidTier.Material = Enum.Material.Marble
MidTier.Color = Color3.fromRGB(236, 239, 243)
MidTier.Parent = FountainModel

local MidWater = Instance.new("Part")
MidWater.Name = "MidWater"
MidWater.Shape = Enum.PartType.Cylinder
MidWater.Size = Vector3.new(1.6, 14, 14)
MidWater.CFrame = CFrame.new(FOUNTAIN_POS + Vector3.new(0, 8.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
MidWater.Anchored = true
MidWater.CanCollide = false
MidWater.Material = Enum.Material.Glass
MidWater.Transparency = 0.3
MidWater.Reflectance = 0.15
MidWater.Color = Color3.fromRGB(125, 192, 225)
MidWater.Parent = FountainModel

local Pillar2 = Instance.new("Part")
Pillar2.Name = "PillarTop"
Pillar2.Shape = Enum.PartType.Cylinder
Pillar2.Size = Vector3.new(5.5, 3.8, 3.8)
Pillar2.CFrame = CFrame.new(FOUNTAIN_POS + Vector3.new(0, 11.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
Pillar2.Anchored = true
Pillar2.CanCollide = true
Pillar2.Material = Enum.Material.Marble
Pillar2.Color = Color3.fromRGB(240, 242, 246)
Pillar2.Parent = FountainModel

local TopCrown = Instance.new("Part")
TopCrown.Name = "TopCrown"
TopCrown.Shape = Enum.PartType.Ball
TopCrown.Size = Vector3.new(3.8, 3.8, 3.8)
TopCrown.Position = FOUNTAIN_POS + Vector3.new(0, 14.8, 0)
TopCrown.Anchored = true
TopCrown.CanCollide = false
TopCrown.Material = Enum.Material.Marble
TopCrown.Color = Color3.fromRGB(235, 240, 245)
TopCrown.Parent = FountainModel

-- Fıskiye Su Partikülleri
local TopSpoutAtt = Instance.new("Attachment")
TopSpoutAtt.Position = Vector3.new(0, 1.6, 0)
TopSpoutAtt.Parent = TopCrown

local MainJetVFX = Instance.new("ParticleEmitter")
MainJetVFX.Name = "FountainTopJet"
MainJetVFX.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 235, 248)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(245, 250, 255)),
})
MainJetVFX.Size = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.6),
	NumberSequenceKeypoint.new(0.5, 1.0),
	NumberSequenceKeypoint.new(1, 0.25),
})
MainJetVFX.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.25),
	NumberSequenceKeypoint.new(0.8, 0.5),
	NumberSequenceKeypoint.new(1, 1),
})
MainJetVFX.Lifetime = NumberRange.new(1.4, 2.0)
MainJetVFX.Rate = 70
MainJetVFX.Speed = NumberRange.new(14, 19)
MainJetVFX.SpreadAngle = Vector2.new(25, 25)
MainJetVFX.Acceleration = Vector3.new(0, -28, 0)
MainJetVFX.EmissionDirection = Enum.NormalId.Top
MainJetVFX.LightEmission = 0.05
MainJetVFX.Parent = TopSpoutAtt

local MidSpoutAtt = Instance.new("Attachment")
MidSpoutAtt.Position = Vector3.new(0.8, 0, 0)
MidSpoutAtt.Parent = MidWater

local MidCascadeVFX = Instance.new("ParticleEmitter")
MidCascadeVFX.Name = "MidWaterCascade"
MidCascadeVFX.Color = ColorSequence.new(Color3.fromRGB(215, 240, 250))
MidCascadeVFX.Size = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.5),
	NumberSequenceKeypoint.new(1, 0.2),
})
MidCascadeVFX.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.3),
	NumberSequenceKeypoint.new(1, 1),
})
MidCascadeVFX.Lifetime = NumberRange.new(1.0, 1.5)
MidCascadeVFX.Rate = 50
MidCascadeVFX.Speed = NumberRange.new(7, 10)
MidCascadeVFX.SpreadAngle = Vector2.new(75, 75)
MidCascadeVFX.Acceleration = Vector3.new(0, -24, 0)
MidCascadeVFX.EmissionDirection = Enum.NormalId.Right
MidCascadeVFX.Parent = MidSpoutAtt

local BasinSplashAtt = Instance.new("Attachment")
BasinSplashAtt.Position = Vector3.new(1.3, 0, 0)
BasinSplashAtt.Parent = BasinWater

local SplashVFX = Instance.new("ParticleEmitter")
SplashVFX.Name = "BasinWaterSplash"
SplashVFX.Color = ColorSequence.new(Color3.fromRGB(240, 248, 255))
SplashVFX.Size = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.4),
	NumberSequenceKeypoint.new(1, 0),
})
SplashVFX.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.35),
	NumberSequenceKeypoint.new(1, 1),
})
SplashVFX.Lifetime = NumberRange.new(0.6, 1.1)
SplashVFX.Rate = 35
SplashVFX.Speed = NumberRange.new(3, 5)
SplashVFX.SpreadAngle = Vector2.new(60, 60)
SplashVFX.Acceleration = Vector3.new(0, -15, 0)
SplashVFX.EmissionDirection = Enum.NormalId.Right
SplashVFX.Parent = BasinSplashAtt

local WaterSound = Instance.new("Sound")
WaterSound.Name = "FountainWaterSFX"
WaterSound.SoundId = "rbxassetid://9114221735"
WaterSound.Volume = 0.7
WaterSound.Looped = true
WaterSound.RollOffMode = Enum.RollOffMode.InverseTapered
WaterSound.RollOffMinDistance = 15
WaterSound.RollOffMaxDistance = 130
WaterSound.Parent = TopCrown
WaterSound:Play()

-
	local WaterFolder = Instance.new("Folder")
WaterFolder.Name = "MountainFoothillRiver"
WaterFolder.Parent = MapFolder

local RIVER_Y = -2.2
local INNER_EDGE = BASE_SIZE / 2 + borderThickness
local OUTER_EDGE = 680
local TOTAL_SPAN = OUTER_EDGE * 2

local RiverBed = Instance.new("Part")
RiverBed.Name = "RiverBed"
RiverBed.Size = Vector3.new(TOTAL_SPAN, 4, TOTAL_SPAN)
RiverBed.Position = Vector3.new(0, -10, 0)
RiverBed.Anchored = true
RiverBed.CanCollide = true
RiverBed.Material = Enum.Material.Sand
RiverBed.Color = Color3.fromRGB(165, 160, 145)
RiverBed.Parent = WaterFolder

local riverWidth = OUTER_EDGE - INNER_EDGE
local riverMidOffset = INNER_EDGE + riverWidth / 2

local riverSegments = {
	{
		name = "NorthRiver",
		pos = Vector3.new(0, RIVER_Y, -riverMidOffset),
		size = Vector3.new(TOTAL_SPAN, 6, riverWidth),
		flowDir = Vector2.new(1, 0.25),
	},
	{
		name = "SouthRiver",
		pos = Vector3.new(0, RIVER_Y, riverMidOffset),
		size = Vector3.new(TOTAL_SPAN, 6, riverWidth),
		flowDir = Vector2.new(-1, -0.25),
	},
	{
		name = "EastRiver",
		pos = Vector3.new(riverMidOffset, RIVER_Y, 0),
		size = Vector3.new(riverWidth, 6, INNER_EDGE * 2),
		flowDir = Vector2.new(0.25, 1),
	},
	{
		name = "WestRiver",
		pos = Vector3.new(-riverMidOffset, RIVER_Y, 0),
		size = Vector3.new(riverWidth, 6, INNER_EDGE * 2),
		flowDir = Vector2.new(-0.25, -1),
	},
}

local FlowingTextures = {}

for _, seg in ipairs(riverSegments) do
	local waterPart = Instance.new("Part")
	waterPart.Name = seg.name
	waterPart.Size = seg.size
	waterPart.Position = seg.pos
	waterPart.Anchored = true
	waterPart.CanCollide = false
	waterPart.Material = Enum.Material.Glass
	waterPart.Transparency = 0.22
	waterPart.Reflectance = 0.25
	waterPart.Color = Color3.fromRGB(78, 165, 205)
	waterPart.Parent = WaterFolder

	local flowTex1 = Instance.new("Texture")
	flowTex1.Name = "WaterFlowLayer1"
	flowTex1.Face = Enum.NormalId.Top
	flowTex1.Texture = "rbxassetid://6372755229"
	flowTex1.StudsPerTileU = 45
	flowTex1.StudsPerTileV = 45
	flowTex1.Transparency = 0.78
	flowTex1.Color3 = Color3.fromRGB(215, 242, 255)
	flowTex1.Parent = waterPart
	table.insert(FlowingTextures, { tex = flowTex1, speedU = seg.flowDir.X * 6, speedV = seg.flowDir.Y * 6 })

	local flowTex2 = Instance.new("Texture")
	flowTex2.Name = "WaterFlowLayer2"
	flowTex2.Face = Enum.NormalId.Top
	flowTex2.Texture = "rbxassetid://6372755229"
	flowTex2.StudsPerTileU = 22
	flowTex2.StudsPerTileV = 70
	flowTex2.Transparency = 0.85
	flowTex2.Color3 = Color3.fromRGB(245, 252, 255)
	flowTex2.Parent = waterPart
	table.insert(FlowingTextures, { tex = flowTex2, speedU = seg.flowDir.X * 10, speedV = seg.flowDir.Y * 4 })

	local mistAtt = Instance.new("Attachment")
	mistAtt.Position = Vector3.new(0, seg.size.Y / 2 + 0.2, 0)
	mistAtt.Parent = waterPart

	local streamParticles = Instance.new("ParticleEmitter")
	streamParticles.Name = "RiverMistParticles"
	streamParticles.Color = ColorSequence.new(Color3.fromRGB(235, 248, 255))
	streamParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	streamParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.75),
		NumberSequenceKeypoint.new(1, 1),
	})
	streamParticles.Lifetime = NumberRange.new(3, 5)
	streamParticles.Rate = 8
	streamParticles.Speed = NumberRange.new(4, 8)
	streamParticles.Acceleration = Vector3.new(seg.flowDir.X * 4, 0.2, seg.flowDir.Y * 4)
	streamParticles.Parent = mistAtt
end

local RiverSound = Instance.new("Sound")
RiverSound.Name = "RiverFlowSFX"
RiverSound.SoundId = "rbxassetid://9114221735"
RiverSound.Volume = 0.35
RiverSound.Looped = true
RiverSound.RollOffMode = Enum.RollOffMode.InverseTapered
RiverSound.RollOffMinDistance = 40
RiverSound.RollOffMaxDistance = 260
RiverSound.Parent = Baseplate
RiverSound:Play()

local MountainFolder = Instance.new("Folder")
MountainFolder.Name = "DetailedSlipperyMountains"
MountainFolder.Parent = MapFolder

local SLIPPERY_PHYSICS = PhysicalProperties.new(
	1.0,
	0.0,
	0.0,
	100.0,
	1.0
)

local function applySlipperyRock(part, material, color)
	part.Anchored = true
	part.CanCollide = true
	part.Material = material
	part.Color = color
	part.CustomPhysicalProperties = SLIPPERY_PHYSICS
end

local function createDetailedMountain(position, width, height, depth, rotationY, seed)
	local localRng = Random.new(seed)
	local mtnModel = Instance.new("Model")
	mtnModel.Name = "DetailedMountain"

	local baseCFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(rotationY), 0)

	local lowerHeight = height * 0.45
	local lowerFront = Instance.new("Part")
	lowerFront.Name = "LowerSlopeFront"
	lowerFront.Shape = Enum.PartType.Wedge
	lowerFront.Size = Vector3.new(depth * 1.15, lowerHeight, width * 1.15)
	lowerFront.CFrame = baseCFrame * CFrame.new(0, lowerHeight / 2 - 12, 0)
	applySlipperyRock(lowerFront, Enum.Material.Slate, Color3.fromRGB(92, 108, 102))
	lowerFront.Parent = mtnModel

	local lowerBack = Instance.new("Part")
	lowerBack.Name = "LowerSlopeBack"
	lowerBack.Shape = Enum.PartType.Wedge
	lowerBack.Size = Vector3.new(depth * 1.15, lowerHeight, width * 1.15)
	lowerBack.CFrame = baseCFrame * CFrame.new(0, lowerHeight / 2 - 12, 0) * CFrame.Angles(0, math.pi, 0)
	applySlipperyRock(lowerBack, Enum.Material.Slate, Color3.fromRGB(82, 98, 92))
	lowerBack.Parent = mtnModel

	local mainFront = Instance.new("Part")
	mainFront.Name = "MainPeakFront"
	mainFront.Shape = Enum.PartType.Wedge
	mainFront.Size = Vector3.new(depth, height, width)
	mainFront.CFrame = baseCFrame * CFrame.new(0, height / 2 - 10, 0)
	applySlipperyRock(mainFront, Enum.Material.Rock, Color3.fromRGB(108, 118, 122))
	mainFront.Parent = mtnModel

	local mainBack = Instance.new("Part")
	mainBack.Name = "MainPeakBack"
	mainBack.Shape = Enum.PartType.Wedge
	mainBack.Size = Vector3.new(depth, height, width)
	mainBack.CFrame = baseCFrame * CFrame.new(0, height / 2 - 10, 0) * CFrame.Angles(0, math.pi, 0)
	applySlipperyRock(mainBack, Enum.Material.Rock, Color3.fromRGB(95, 105, 110))
	mainBack.Parent = mtnModel

	for ridgeIdx = 1, 2 do
		local sideSign = (ridgeIdx == 1) and 1 or -1
		local ridgeH = height * localRng:NextNumber(0.55, 0.72)
		local ridgeW = width * localRng:NextNumber(0.45, 0.6)
		local ridgeD = depth * localRng:NextNumber(0.55, 0.7)
		local offsetX = sideSign * width * 0.26
		local offsetZ = localRng:NextNumber(-18, 18)

		local ridgeF = Instance.new("Part")
		ridgeF.Name = "SideRidgeFront_" .. ridgeIdx
		ridgeF.Shape = Enum.PartType.Wedge
		ridgeF.Size = Vector3.new(ridgeD, ridgeH, ridgeW)
		ridgeF.CFrame = baseCFrame * CFrame.new(offsetZ, ridgeH / 2 - 10, offsetX) * CFrame.Angles(0, math.rad(sideSign * 14), 0)
		applySlipperyRock(ridgeF, Enum.Material.Slate, Color3.fromRGB(100, 112, 114))
		ridgeF.Parent = mtnModel

		local ridgeB = Instance.new("Part")
		ridgeB.Name = "SideRidgeBack_" .. ridgeIdx
		ridgeB.Shape = Enum.PartType.Wedge
		ridgeB.Size = Vector3.new(ridgeD, ridgeH, ridgeW)
		ridgeB.CFrame = baseCFrame * CFrame.new(offsetZ, ridgeH / 2 - 10, offsetX) * CFrame.Angles(0, math.pi + math.rad(sideSign * 14), 0)
		applySlipperyRock(ridgeB, Enum.Material.Slate, Color3.fromRGB(88, 100, 102))
		ridgeB.Parent = mtnModel
	end

	local snowRatio = 0.30
	local snowH = height * snowRatio
	local snowW = width * snowRatio
	local snowD = depth * snowRatio

	local snowFront = Instance.new("Part")
	snowFront.Name = "SnowPeakFront"
	snowFront.Shape = Enum.PartType.Wedge
	snowFront.Size = Vector3.new(snowD, snowH, snowW)
	snowFront.CFrame = baseCFrame * CFrame.new(0, height - snowH / 2 - 9.8, 0)
	applySlipperyRock(snowFront, Enum.Material.Snow, Color3.fromRGB(238, 244, 250))
	snowFront.Parent = mtnModel

	local snowBack = Instance.new("Part")
	snowBack.Name = "SnowPeakBack"
	snowBack.Shape = Enum.PartType.Wedge
	snowBack.Size = Vector3.new(snowD, snowH, snowW)
	snowBack.CFrame = baseCFrame * CFrame.new(0, height - snowH / 2 - 9.8, 0) * CFrame.Angles(0, math.pi, 0)
	applySlipperyRock(snowBack, Enum.Material.Snow, Color3.fromRGB(226, 234, 244))
	snowBack.Parent = mtnModel

	mtnModel.Parent = MountainFolder
end

local mtnRng = Random.new(204)
local mountainCount = 26
for i = 1, mountainCount do
	local angle = (i / mountainCount) * math.pi * 2
	local distance = mtnRng:NextNumber(415, 550)
	local x = math.cos(angle) * distance
	local z = math.sin(angle) * distance
	local width = mtnRng:NextNumber(170, 270)
	local height = mtnRng:NextNumber(165, 295)
	local depth = mtnRng:NextNumber(150, 230)
	local rotY = math.deg(-angle) + 90
	createDetailedMountain(Vector3.new(x, 0, z), width, height, depth, rotY, i * 17)
end

local DecorFolder = Instance.new("Folder")
DecorFolder.Name = "SimulatorTrees"
DecorFolder.Parent = MapFolder

local function createTexturedTree(position, scale)
	local treeModel = Instance.new("Model")
	treeModel.Name = "SimulatorTree"

	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Size = Vector3.new(2.5 * scale, 10 * scale, 2.5 * scale)
	trunk.Position = position + Vector3.new(0, 5 * scale, 0)
	trunk.Anchored = true
	trunk.CanCollide = true
	trunk.Material = Enum.Material.Wood
	trunk.Color = Color3.fromRGB(115, 78, 52)
	trunk.Parent = treeModel

	local leafColors = {
		Color3.fromRGB(68, 152, 74),
		Color3.fromRGB(78, 168, 84),
		Color3.fromRGB(58, 138, 65),
	}

	local layers = {
		{ offset = Vector3.new(0, 11 * scale, 0), size = Vector3.new(11 * scale, 5 * scale, 11 * scale) },
		{ offset = Vector3.new(0, 15 * scale, 0), size = Vector3.new(8.5 * scale, 4.5 * scale, 8.5 * scale) },
		{ offset = Vector3.new(0, 18.5 * scale, 0), size = Vector3.new(5.5 * scale, 4 * scale, 5.5 * scale) },
	}

	for i, layer in ipairs(layers) do
		local leaves = Instance.new("Part")
		leaves.Name = "Leaves_" .. i
		leaves.Size = layer.size
		leaves.Position = position + layer.offset
		leaves.Anchored = true
		leaves.CanCollide = false
		leaves.Material = Enum.Material.Grass
		leaves.Color = leafColors[i]
		leaves.Parent = treeModel
	end

	treeModel.Parent = DecorFolder
end

local rng = Random.new(42)
for i = 1, 42 do
	local angle = (i / 42) * math.pi * 2
	local radius = rng:NextNumber(135, 235)
	local x = math.cos(angle) * radius
	local z = math.sin(angle) * radius
	local pos = Vector3.new(x, 0, z)

	if (pos - HUB_CENTER).Magnitude > 58 then
		local scale = rng:NextNumber(0.85, 1.45)
		createTexturedTree(pos, scale)
	end
end

local function placeCharacterAtSpawn(character)
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if hrp then
		task.wait(0.05)
		hrp.CFrame = SpawnPad.CFrame + Vector3.new(0, 4, 0)
	end
end

local function setupPlayer(player)
	if player.Character then
		task.spawn(placeCharacterAtSpawn, player.Character)
	end
	player.CharacterAdded:Connect(placeCharacterAtSpawn)
end

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end
Players.PlayerAdded:Connect(setupPlayer)

RunService.Heartbeat:Connect(function(dt)
	for _, item in ipairs(FlowingTextures) do
		local tex = item.tex
		if tex and tex.Parent then
			tex.OffsetStudsU = (tex.OffsetStudsU + item.speedU * dt) % tex.StudsPerTileU
			tex.OffsetStudsV = (tex.OffsetStudsV + item.speedV * dt) % tex.StudsPerTileV
		end
	end
end)

local crownTween = TweenService:Create(
	TopCrown,
	TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ Position = TopCrown.Position + Vector3.new(0, 0.55, 0) }
)
crownTween:Play()

local waterRippleTween = TweenService:Create(
	BasinWater,
	TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ Position = BasinWater.Position + Vector3.new(0, 0.14, 0) }
)
waterRippleTween:Play()

local spawnDebounce = {}
SpawnPad.Touched:Connect(function(hit)
	local character = hit.Parent
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and not spawnDebounce[character] then
		spawnDebounce[character] = true
		TouchSound:Play()
		task.delay(1.5, function()
			spawnDebounce[character] = nil
		end)
	end
end)
