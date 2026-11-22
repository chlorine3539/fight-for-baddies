# Player data persistence (Phase 8)

Power and Love are saved with a versioned, server-only schema. The client never reads or writes a DataStore.

## Store and schema

- Store: `FightForBaddies_PlayerData_Test` (intentionally isolated from production).
- Key: `v1_<UserId>`; a future schema version gets a new prefix instead of reading old records.
- Value: `{ version = 1, power = number, love = number }`.
- New players start at Power `0` and Love `10`, matching the session-only behavior.
- Values are rejected if they are non-numeric, NaN/infinite, negative, or unreasonably large, and are rounded to two decimals.

## Load behavior

On join, leaderstats are created with the default values but the player is immediately marked `DataLoaded = false` and `DataRestricted = true`. A missing record becomes the default schema. A present record is validated before being applied. Load errors are retried four times with bounded backoff (0.5s, 1s, 2s).

If loading fails or the stored record is invalid, the defaults remain visible. On a published server, the player stays restricted and receives a Turkish notification; pull-up, NPC dialogue, arena, and secret-toilet rewards are ignored. No save is attempted for that player, so defaults cannot overwrite an existing record.

In Roblox Studio only, unavailable DataStore access falls back to session-only play: `DataLoaded = false`, `DataPersistent = false`, and `DataRestricted = false`. This lets the gameplay checklist run without DataStore API access. Session-only progress is never saved because `state.loaded` remains false; published servers never use this fallback and keep the strict restricted-state policy.

## Save behavior

`UpdateAsync` writes only after a successful load. Value changes mark the session dirty; saves run on a 120-second autosave interval, on `PlayerRemoving`, and on `BindToClose`. A per-player saving flag prevents overlapping writes, and a final save is queued if a save is already in flight. The transform cancels rather than replacing a malformed or foreign-version stored record. Save errors use the same bounded retry policy; shutdown waits up to eight seconds for pending saves.

## Limitations and recovery

- The one-time secret-toilet reward is still session-only; only Power and Love persist.
- Studio session-only play intentionally does not persist Power or Love.
- Rejoining is the recovery action for a transient load failure. An invalid stored record is left untouched and needs manual correction in the isolated test place.
- This phase assumes a single server per experience and does not implement cross-server migration.
- Studio round-trip and failure-injection tests are still unverified; see [the regression checklist](StudioRegressionChecklist.md).
- Do not rename the store to a production DataStore until the isolated test-place round trip succeeds.
