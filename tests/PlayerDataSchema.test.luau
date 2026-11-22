-- Standalone checks for the server-only player data schema.
-- Run with: lune run tests/PlayerDataSchema.test.luau

local PlayerDataSchema = require("../src/ServerScriptService/Logic/PlayerDataSchema")

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

local defaults = PlayerDataSchema.newDefault()
expect("default version", defaults.version == 1)
expect("default power", defaults.power == 0)
expect("default love", defaults.love == 10)

expect("key for user", PlayerDataSchema.keyFor(123) == "v1_123")
expect("key rejects fraction", PlayerDataSchema.keyFor(1.5) == nil)
expect("key rejects zero", PlayerDataSchema.keyFor(0) == nil)
expect("key rejects string", PlayerDataSchema.keyFor("123") == nil)

expect("valid values", PlayerDataSchema.fromValues(12.345, 20) ~= nil)
expect("valid values are rounded", PlayerDataSchema.equals(PlayerDataSchema.fromValues(12.345, 20), { version = 1, power = 12.35, love = 20 }))
expect("negative power rejected", PlayerDataSchema.fromValues(-1, 10) == nil)
expect("negative love rejected", PlayerDataSchema.fromValues(0, -1) == nil)
expect("nan power rejected", PlayerDataSchema.fromValues(0 / 0, 10) == nil)
expect("infinite love rejected", PlayerDataSchema.fromValues(0, math.huge) == nil)
expect("string power rejected", PlayerDataSchema.fromValues("0", 10) == nil)
expect("unreasonable power rejected", PlayerDataSchema.fromValues(PlayerDataSchema.MAX_POWER + 1, 10) == nil)
expect("unreasonable love rejected", PlayerDataSchema.fromValues(0, PlayerDataSchema.MAX_LOVE + 1) == nil)

expect("deserialize valid", PlayerDataSchema.deserialize({ version = 1, power = 4.25, love = 7 }) ~= nil)
expect("deserialize rounds", PlayerDataSchema.equals(PlayerDataSchema.deserialize({ version = 1, power = 4.255, love = 7 }), { version = 1, power = 4.26, love = 7 }))
expect("deserialize rejects wrong version", PlayerDataSchema.deserialize({ version = 2, power = 1, love = 2 }) == nil)
expect("deserialize rejects missing version", PlayerDataSchema.deserialize({ power = 1, love = 2 }) == nil)
expect("deserialize rejects string", PlayerDataSchema.deserialize("bad") == nil)
expect("deserialize rejects nil", PlayerDataSchema.deserialize(nil) == nil)

expect("save creates first record", PlayerDataSchema.equals(PlayerDataSchema.applySave(nil, defaults), defaults))
expect("save replaces valid record", PlayerDataSchema.equals(
	PlayerDataSchema.applySave({ version = 1, power = 1, love = 2 }, { version = 1, power = 3, love = 4 }),
	{ version = 1, power = 3, love = 4 }
))
expect("save cancels malformed record", PlayerDataSchema.applySave({ version = 1, power = -1, love = 2 }, defaults) == nil)
expect("save cancels wrong version", PlayerDataSchema.applySave({ version = 2, power = 1, love = 2 }, defaults) == nil)
expect("save cancels malformed input", PlayerDataSchema.applySave(nil, { version = 1, power = math.huge, love = 2 }) == nil)

expect("equals rejects mismatched power", PlayerDataSchema.equals(defaults, { version = 1, power = 1, love = 10 }) == false)
expect("equals rejects nil", PlayerDataSchema.equals(defaults, nil) == false)

if failures > 0 then
	error(failures .. " of " .. total .. " PlayerDataSchema checks failed")
end

print("PlayerDataSchema: " .. total .. " checks passed")
