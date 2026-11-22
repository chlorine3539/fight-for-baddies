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
├── ServerScriptService/
│   └── Script_1.server.luau
├── StarterGui/
├── StarterPlayerScripts/
│   └── LocalScript.client.luau
├── TextChatService/
└── Workspace/
```

- The server script owns map generation, player stats, RemoteEvents, the pull-up station, NPC interactions, and arena duels.
- The client script owns the HUD, input, dialogue UI, and visual feedback. Character movement and pull-up rewards are server-authoritative.
- Duplicate server implementations and embedded client-source injection have been removed.

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
