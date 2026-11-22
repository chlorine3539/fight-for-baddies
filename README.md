# Fight For Baddies

## Requirements

- Git
- Roblox Studio
- [Rokit](https://github.com/rojo-rbx/rokit)
- [Rojo Studio plugin](https://rojo.space/docs/v7/getting-started/installation/)

## Setup

Clone the repository and install its pinned tools:

```sh
git clone https://github.com/chlorine3539/fight-for-baddies.git
cd fight-for-baddies
rokit install
```

Open the Roblox place configured in `default.project.json` in Studio and install the Rojo plugin.

## Synchronize with Roblox Studio

Start the Rojo server from the repository root:

```sh
rojo serve
```

In Studio, connect the Rojo plugin to the running server. Keep it running while working with the project files.

To stop synchronization, disconnect the plugin and stop the `rojo serve` process with `Ctrl+C`.

## Export Studio changes

To bring changes made in Studio back into the repository:

1. Save a place snapshot as `place.rbxl` in the repository root.
2. Preview the changes Rojo will export:

   ```sh
   rojo syncback . --input place.rbxl --dry-run --list
   ```

3. Review the preview, then apply it:

   ```sh
   rojo syncback . --input place.rbxl -y
   ```

4. Review the resulting source changes:

   ```sh
   git status
   git diff
   ```

Do not commit the `place.rbxl` snapshot.

## Build a place file

Build the project into a Roblox place file:

```sh
rojo build -o build/fight-for-baddies.rbxlx
```

The generated `build/` directory is ignored by Git.

## Contribute

Create a branch for your changes:

```sh
git switch -c <branch-name>
```

After editing, review and validate the changes:

```sh
git diff --check
git status
git diff
selene src tests
lune run tests/GameRules.test.luau
lune run tests/PlayerDataSchema.test.luau
rojo build -o build/fight-for-baddies.rbxlx
```

The same static checks run in CI for pull requests and pushes to `main`. CI never publishes a place or changes a live experience.

Gameplay changes also need a Studio multiplayer pass. Use the [Studio regression checklist](docs/StudioRegressionChecklist.md) and report each scenario as pass, fail, or unverified in the pull request description. Player-data behavior and its operational limits are documented in [Player data persistence](docs/PlayerDataPersistence.md); the conditional NPC pathfinding decision is recorded in [NPC pathfinding assessment](docs/NpcPathfindingAssessment.md).

Commit and push your branch, then open a pull request against `main`. Keep generated snapshots and build output out of commits.
