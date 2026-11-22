-- ========================================================================
-- PLAYER DATA SCHEMA
-- Versioned, server-only player data rules. This module has no Roblox
-- globals so load validation and save transforms can be tested with Lune.
-- ========================================================================
local PlayerDataSchema = {}

PlayerDataSchema.VERSION = 1
PlayerDataSchema.KEY_PREFIX = "v1_"
PlayerDataSchema.MAX_POWER = 1e9
PlayerDataSchema.MAX_LOVE = 1e6

local function isFiniteNumber(value)
	return type(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
end

local function round(value)
	return math.floor(value * 100 + 0.5) / 100
end

function PlayerDataSchema.newDefault()
	return {
		version = PlayerDataSchema.VERSION,
		power = 0,
		love = 10,
	}
end

function PlayerDataSchema.keyFor(userId)
	if type(userId) ~= "number" or userId % 1 ~= 0 or userId <= 0 then
		return nil
	end
	return PlayerDataSchema.KEY_PREFIX .. tostring(userId)
end

function PlayerDataSchema.fromValues(power, love)
	if not isFiniteNumber(power) or not isFiniteNumber(love) then
		return nil
	end
	if power < 0 or power > PlayerDataSchema.MAX_POWER then
		return nil
	end
	if love < 0 or love > PlayerDataSchema.MAX_LOVE then
		return nil
	end
	return {
		version = PlayerDataSchema.VERSION,
		power = round(power),
		love = round(love),
	}
end

function PlayerDataSchema.deserialize(value)
	if type(value) ~= "table" or value.version ~= PlayerDataSchema.VERSION then
		return nil
	end
	return PlayerDataSchema.fromValues(value.power, value.love)
end

function PlayerDataSchema.applySave(current, nextData)
	-- Never write malformed session data or replace malformed/foreign-version
	-- stored data with defaults. A nil transform result cancels UpdateAsync.
	local validated = PlayerDataSchema.deserialize(nextData)
	if validated == nil then
		return nil
	end
	if current == nil then
		return validated
	end
	if PlayerDataSchema.deserialize(current) == nil then
		return nil
	end
	return validated
end

function PlayerDataSchema.equals(a, b)
	return type(a) == "table"
		and type(b) == "table"
		and a.version == b.version
		and a.power == b.power
		and a.love == b.love
end

return PlayerDataSchema
