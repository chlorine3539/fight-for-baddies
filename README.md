# Fight For Baddies

A Rojo-managed Roblox experience focused on strength progression, NPC interactions, and arena duels.

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
├── ReplicatedStorage/
│   └── WorldBuilder.luau
├── ServerScriptService/
│   └── Script_1.server.luau
├── StarterGui/
├── StarterPlayerScripts/
│   └── LocalScript.client.luau
├── TextChatService/
└── Workspace/
```

- `ReplicatedStorage/WorldBuilder.luau` creates the visible map and lighting. It is shared by edit mode and server runtime.
- The server script owns player stats, RemoteEvents, the pull-up station, NPC interactions, and arena duels.
- The client script owns the HUD, input, dialogue UI, and visual feedback. Character movement and pull-up rewards are server-authoritative.
- Duplicate server implementations and embedded client-source injection have been removed.

## Show the map while editing in Studio

The map is generated from code. To create a saved copy that is visible without pressing Test:

1. Start `rojo serve` from the repository root and connect the Rojo plugin in Studio so `ReplicatedStorage.WorldBuilder` is synced.
2. Disconnect the Rojo plugin and stop `rojo serve` before generating the map. This prevents live sync from treating the newly generated Workspace objects as untracked instances.
3. In Studio, open **View → Command Bar** and run:

   ```lua
   require(game:GetService("ReplicatedStorage"):WaitForChild("WorldBuilder")).Build()
   ```

4. Save a place snapshot as `place.rbxl` in the repository root.
5. Export the generated Workspace objects into the Rojo project:

   ```sh
   rojo syncback . --input place.rbxl --dry-run --list
   ```

   Review the preview, then apply it:

   ```sh
   rojo syncback . --input place.rbxl -y
   git status
   ```

6. Restart `rojo serve` and reconnect the plugin. The generated map is now part of `src/Workspace` and remains visible in edit mode.

The server calls the same builder when a play session starts. It replaces the saved `SimulatorBaseplateMap` with a fresh copy, so the edit-mode map is not duplicated during testing.

## Live development

Start Rojo from the repository root:

```sh
rojo serve
```

Open the place in Roblox Studio, connect with the Rojo plugin, and keep the Rojo server running while editing source files.

## Export Studio changes

Save a Studio snapshot as `place.rbxl` in the repository root. Preview the syncback first:

```sh
rojo syncback . --input place.rbxl --dry-run --list
```

Apply only after reviewing the preview:

```sh
rojo syncback . --input place.rbxl -y
git status
```

Review the source changes before committing them. Do not commit the `place.rbxl` snapshot.

## Build

```sh
rojo build -o build/fight-for-baddies.rbxlx
```

The `build/` directory is ignored by Git.

## Current limitations

- Power and Love are session-only; DataStore persistence is not implemented.
- The arena is shared, so simultaneous duels are not isolated.
- NPC dialogue choices currently affect Love and start a duel; branching relationships are not implemented.
- Test the pull-up station, NPC interactions, and combat in a multi-player Studio session before publishing.
