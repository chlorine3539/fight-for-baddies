# Fight For Baddies

A Rojo-managed Roblox experience built around strength progression, NPC interactions, and arena duels.

## Requirements

- Roblox Studio
- [Rokit](https://github.com/rojo-rbx/rokit)
- Rojo 7.7.1 (pinned in `rokit.toml`)
- The [Rojo Studio plugin](https://rojo.space/docs/v7/getting-started/installation/)

Install the pinned tools from the repository root:

```sh
rokit install
```

## Project layout

```text
src/
├── Lighting/
├── ServerScriptService/
│   └── Main.server.luau
├── ServerStorage/
├── StarterGui/
├── StarterPlayerScripts/
│   └── Main.client.luau
├── TextChatService/
└── Workspace/
```

- `Main.server.luau` is the single authoritative server entry point. It creates the map, player stats, RemoteEvents, NPCs, pull-up station, and arena gameplay.
- `Main.client.luau` owns the HUD, input, NPC dialogue UI, and client-side feedback. Pull-up character motion and progression are handled by the server.
- Workspace model files and service configuration are exported from the Roblox Studio place.

Gameplay state changes are validated on the server. Client requests cannot choose a dialogue reward without a current server-issued NPC interaction, activate the pull-up station remotely, or damage arbitrary humanoids with an arena sword.

## Develop with live sync

From the repository root, start Rojo:

```sh
rojo serve
```

In Roblox Studio:

1. Open the place associated with this project.
2. Open the **Plugins** tab and connect using the **Rojo** plugin.
3. Keep the Rojo server running while editing source files; script changes sync into Studio.

## Export Studio changes back into source

Save a snapshot from Roblox Studio as `place.rbxl` in the repository root. The snapshot is ignored by Git.

Preview the syncback changes first:

```sh
rojo syncback . --input place.rbxl --dry-run --list
```

Apply the syncback only after reviewing the preview:

```sh
rojo syncback . --input place.rbxl -y
git status
```

Review the resulting source changes before committing them. Avoid committing the `place.rbxl` snapshot.

## Build

Build an XML place file:

```sh
rojo build -o build/fight-for-baddies.rbxlx
```

The `build/` directory is ignored by Git.

## Current limitations

- Player Power and Love are session-only; DataStore persistence has not been implemented.
- The arena is shared, so simultaneous duels are not isolated yet.
- NPC dialogue choices currently change Love and start a duel; there is not yet a branching dialogue or relationship system.
- Test multiplayer interactions in Studio with a local server and multiple test players before publishing.
