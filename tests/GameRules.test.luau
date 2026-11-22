-- Small standalone checks for the deterministic server rules.
-- Run with: lune run tests/GameRules.test.luau

local GameRules = require("../src/ServerScriptService/Logic/GameRules")

local failures = 0
local total = 0

local function expect(label, condition)
	total += 1
	if condition then
		return
	end
	failures += 1
	print("FAIL: " .. label)
end

local rarities = {
	{ Name = "Common" },
	{ Name = "Rare", Chance = 25 },
	{ Name = "Epic", Chance = 10 },
	{ Name = "Mythic", Chance = 4 },
	{ Name = "Legendary", Chance = 0.999 },
	{ Name = "Godly", Chance = 0.001 },
}
rarities[1].Chance = 60

expect("rarity lower bound", GameRules.rollRarity(0, rarities).Name == "Common")
expect("rarity first boundary", GameRules.rollRarity(60, rarities).Name == "Common")
expect("rarity second tier", GameRules.rollRarity(60.001, rarities).Name == "Rare")
expect("rarity third tier", GameRules.rollRarity(85.001, rarities).Name == "Epic")
expect("rarity fourth tier", GameRules.rollRarity(95.001, rarities).Name == "Mythic")
expect("rarity fifth tier", GameRules.rollRarity(99.001, rarities).Name == "Legendary")
expect("rarity final tier", GameRules.rollRarity(99.9995, rarities).Name == "Godly")

expect("love delta choice 1", GameRules.loveDelta(1, 100) == -10)
expect("love delta choice 2", GameRules.loveDelta(2, 100) == 10)
expect("love delta choice 3", GameRules.loveDelta(3, 80) == 10)
expect("love delta choice 4", GameRules.loveDelta(4, 40) == 8)
expect("love delta minimum loss", GameRules.loveDelta(1, 5) == -1)
expect("love delta invalid choice", GameRules.loveDelta(5, 100) == nil)
expect("love floor at zero", GameRules.clampLove(3, -10) == 0)
expect("love gain clamps normally", GameRules.clampLove(3, 5) == 8)

expect("pullup gain at zero love", GameRules.pullupPowerGain(0) == 1)
expect("pullup gain at fifty love", GameRules.pullupPowerGain(50) == 1.5)
expect("pullup gain at hundred love", GameRules.pullupPowerGain(100) == 2)
expect("round power", GameRules.roundPower(1.239) == 1.23)
expect("arena bonus minimum", GameRules.arenaBonusLove(10) == 5)
expect("arena bonus scaled", GameRules.arenaBonusLove(100) == 12)

expect("boss health", GameRules.bossMaxHealth(1000, 100) == 175)
expect("player sword damage", GameRules.playerSwordDamage(175) == 43)
expect("player sword damage minimum", GameRules.playerSwordDamage(25) == 25)
expect("boss sword damage", GameRules.bossSwordDamage(0.65) == 11)
expect("boss sword damage minimum", GameRules.bossSwordDamage(0.1) == 8)
expect("known rarity multiplier", GameRules.rarityMultiplier("Mythic") == 0.88)
expect("unknown rarity multiplier", GameRules.rarityMultiplier("Unknown") == 0.75)

expect("first action allowed", GameRules.canAct(10, nil, 0.26) == true)
expect("cooldown blocks early action", GameRules.canAct(10.2, 10, 0.26) == false)
expect("cooldown allows later action", GameRules.canAct(10.3, 10, 0.26) == true)
expect("swing ready in past", GameRules.isReady(5, 4.9) == true)
expect("swing blocked in future", GameRules.isReady(5, 5.1) == false)

expect("dialogue choice one", GameRules.isValidDialogueChoice(1) == true)
expect("dialogue choice four", GameRules.isValidDialogueChoice(4) == true)
expect("dialogue choice zero", GameRules.isValidDialogueChoice(0) == false)
expect("dialogue choice five", GameRules.isValidDialogueChoice(5) == false)
expect("dialogue choice fractional", GameRules.isValidDialogueChoice(1.5) == false)
expect("dialogue choice string", GameRules.isValidDialogueChoice("1") == false)
expect("dialogue choice nil", GameRules.isValidDialogueChoice(nil) == false)

-- Compare the extracted rules against the formulas they replaced across wide
-- input ranges so the refactor cannot silently change rewards or tuning.
local function refLoveDelta(choice, power)
	if choice == 1 then return -math.max(1, math.floor(power / 10)) end
	local divisor = ({ [2] = 10, [3] = 8, [4] = 5 })[choice]
	return divisor and math.max(1, math.floor(power / divisor)) or nil
end

for choice = 1, 4 do
	for power = 0, 1000, 7 do
		expect("love delta equivalence " .. choice .. "/" .. power,
			GameRules.loveDelta(choice, power) == refLoveDelta(choice, power))
	end
end

for love = 0, 100 do
	expect("pullup gain equivalence " .. love,
		GameRules.pullupPowerGain(love) == math.max(1, math.floor((1 + love * 0.01) * 100) / 100))
end

for power = 0, 1000, 3 do
	expect("arena bonus equivalence " .. power,
		GameRules.arenaBonusLove(power) == math.max(5, math.floor(power * 0.12)))
end

for reqPower = 0, 50000, 137 do
	for playerPower = 0, 100000, 331 do
		local maxHP = math.floor(100 + (reqPower * 0.05) + (playerPower * 0.25))
		expect("boss health equivalence " .. reqPower .. "/" .. playerPower,
			GameRules.bossMaxHealth(reqPower, playerPower) == maxHP)
		expect("player damage equivalence " .. reqPower .. "/" .. playerPower,
			GameRules.playerSwordDamage(maxHP) == math.max(25, math.floor(maxHP / 4)))
	end
end

for _, name in ipairs({ "Common", "Rare", "Epic", "Mythic", "Legendary", "Godly", "Unknown" }) do
	local multipliers = { Common = 0.65, Rare = 0.75, Epic = 0.82, Mythic = 0.88, Legendary = 0.92, Godly = 0.95 }
	expect("rarity multiplier equivalence " .. name,
		GameRules.rarityMultiplier(name) == (multipliers[name] or 0.75))
end

local sample = 0
while sample <= 100 do
	local acc = 0
	local expected = rarities[1]
	for _, info in ipairs(rarities) do
		acc += info.Chance
		if sample <= acc then
			expected = info
			break
		end
	end
	expect("rarity roll equivalence " .. sample, GameRules.rollRarity(sample, rarities) == expected)
	sample += 0.137
end

if failures > 0 then
	error(failures .. " of " .. total .. " GameRules checks failed")
end

print("GameRules: " .. total .. " checks passed")
