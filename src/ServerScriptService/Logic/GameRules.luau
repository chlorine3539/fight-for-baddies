-- ========================================================================
-- PURE GAME RULES
-- Deterministic server-side rules shared by gameplay services and tests.
-- This module has no Roblox globals so it can run under a plain Luau runtime.
-- ========================================================================

local GameRules = {}

local CHOICE_DIVISORS = {
	[1] = 10,
	[2] = 10,
	[3] = 8,
	[4] = 5,
}

local RARITY_MULTIPLIERS = {
	Common = 0.65,
	Rare = 0.75,
	Epic = 0.82,
	Mythic = 0.88,
	Legendary = 0.92,
	Godly = 0.95,
}

function GameRules.rollRarity(sample, rarities)
	local accumulated = 0
	for _, info in ipairs(rarities) do
		accumulated += info.Chance
		if sample <= accumulated then
			return info
		end
	end
	return rarities[1]
end

function GameRules.rarityMultiplier(name)
	return RARITY_MULTIPLIERS[name] or 0.75
end

function GameRules.loveDelta(choiceIndex, power)
	local divisor = CHOICE_DIVISORS[choiceIndex]
	if not divisor then
		return nil
	end
	local magnitude = math.max(1, math.floor(power / divisor))
	return choiceIndex == 1 and -magnitude or magnitude
end

function GameRules.clampLove(love, delta)
	return math.max(0, love + delta)
end

function GameRules.pullupPowerGain(love)
	return math.max(1, math.floor((1 + love * 0.01) * 100) / 100)
end

function GameRules.roundPower(value)
	return math.floor(value * 100) / 100
end

function GameRules.arenaBonusLove(power)
	return math.max(5, math.floor(power * 0.12))
end

function GameRules.bossMaxHealth(reqPower, playerPower)
	return math.floor(100 + (reqPower * 0.05) + (playerPower * 0.25))
end

function GameRules.playerSwordDamage(bossMaxHealth)
	return math.max(25, math.floor(bossMaxHealth / 4))
end

function GameRules.bossSwordDamage(multiplier)
	return math.max(8, math.floor(18 * multiplier))
end

function GameRules.canAct(now, lastActedAt, cooldown)
	return lastActedAt == nil or now - lastActedAt >= cooldown
end

function GameRules.isReady(now, readyAt)
	return now >= readyAt
end

function GameRules.isValidDialogueChoice(value)
	return type(value) == "number"
		and value % 1 == 0
		and value >= 1
		and value <= 4
end

return GameRules
