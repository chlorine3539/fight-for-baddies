# Studio multiplayer regression checklist

Run in a local Roblox Studio test place through Rojo. Do not publish or upload the place, change live experience settings, or use production DataStores. Persistence currently uses the isolated `FightForBaddies_PlayerData_Test` store; do not point it at a production store for these checks. Record each row as **pass**, **fail**, or **unverified** in the PR description, with a short note for failures.

| Scenario | Steps | Expected result |
| --- | --- | --- |
| Spawn | Join with two players and respawn once. | Both players spawn on the saved map pad, leaderstats start at Power 0 / Love 10, and state attributes are cleared. |
| Pull-up | Trigger the gym bar, perform reps, then leave via the client exit control. | Character rises/falls through the saved pose, Power increases according to Love, the prompt and movement state return on exit and on respawn. |
| NPC dialogue | Approach a roaming NPC and choose each of the four dialogue options. | Only the server-issued interaction is accepted; the matching Turkish line appears, Love changes by the expected amount and never goes below zero, and the duel begins only after a valid choice. |
| Secret toilet reward | Use the hidden toilet interaction once with a low-Power and once with a qualifying player. | Low-Power players are rejected with the Turkish message; qualifying players receive the intended reward once, without a duplicate from repeated prompts. |
| Combat | Start a duel and land sword hits while moving and jumping. | Only server-validated hits reduce boss health, damage/cooldown values match tuning, and the client cannot hit through walls or from outside melee reach. |
| Duel isolation | Start duels in two different arenas at the same time. | Each pair stays in its reserved slot, arena shells do not overlap, and finishing or timing out one duel leaves the other unaffected. |
| Death/respawn | Die during a duel and again during a pull-up session. | Duel state, prompts, poses, movement state, and reserved slots are released; the respawned player cannot act on stale arena state. |
| Timeout | Begin a duel but do not send the arena-ready confirmation. | The duel ends after the server timeout with no rewards, and its slot is released for the next player. |
| Player departure | Leave the game during a duel, dialogue prompt, or pull-up session. | Cleanup runs without errors, opponent/arena instances are removed, and the next player can start a fresh duel. |
| Persistence round trip | In an isolated test place, earn Power/Love, leave, rejoin, and inspect leaderstats. | The same values return, starting values remain 0/10 for a new key, and no rewards are applied before load completes. |
| Persistence failure | Force load/save failures in the test place with a valid stored record. | Retries are bounded, rewards stay blocked while restricted, and a failed save never replaces valid stored data with session defaults. |
| Saved map integrity | Open the place after a Rojo build and inspect the Workspace. | `SimulatorBaseplateMap` and its original assets remain present; no runtime-generated replacement map appears. |

Static checks cannot replace this list. A change that touches gameplay, remotes, cleanup, or the map should be re-tested in Studio before being marked verified.
