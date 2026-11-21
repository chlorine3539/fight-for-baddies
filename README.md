# Roblox Experience

A small Roblox RPG prototype built with Rojo.

## Run locally

1. Install the tools listed in `rokit.toml` with Rokit.
2. Open the project directory and run `rojo serve`.
3. Open the place in Roblox Studio and connect using the Rojo plugin.
4. Press Play to test the starter area.

You can also build a place file with `rojo build -o build/experience.rbxlx`.

## Phase one gameplay

- Three placeholder characters spawn in the starter area.
- Press **E** near a character to talk and earn Love.
- Press **F** near a character to spend the required Love and recruit them.
- Recruited characters appear in the collection panel. Select one to equip it.
- Press **Q** or use the **Attack** button near a training dummy.
- Defeating a dummy awards Love. An equipped companion increases attack damage.

## Prototype limitations

- Player currency and recruited characters are stored in server memory only. Progress resets when the server shuts down; DataStore persistence is not included yet.
- Characters and enemies use simple blockout geometry. Animations, production art, advanced combat, PvP, quests, and additional areas are intentionally out of scope for this first playable slice.
- The game systems are server-authoritative for Love rewards, recruitment, companion equipment, enemy health, and damage.
