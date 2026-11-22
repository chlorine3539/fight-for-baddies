# NPC pathfinding assessment (Phase 9)

PathfindingService was **not** added. Phase 9 is conditional and requires a reproduced navigation problem first.

## Current behavior

Roaming NPCs still choose random destinations within the saved map bounds and call `Humanoid:MoveTo()`. Destinations are recomputed every 3–6 seconds, not every frame. When an NPC is destroyed, a stop flag ends its movement loop at the next wake-up and cancels its pending respawn timer; pending dialogue interactions are also cleared.

## Deferred with reason

Roblox Studio is not available in this environment, so NPC movement cannot be observed against the actual saved map and arena geometry, and the intended maximum NPC population cannot be exercised. There is therefore no reproducible case of an NPC getting stuck, repeatedly failing `MoveTo`, or being unable to navigate around an obstacle. Adding PathfindingService now would violate the plan's condition and could introduce unnecessary per-NPC path computation.

## What to record in Studio

Before changing the movement system, run the local test place and record:

- the map locations where an NPC stalls or repeatedly fails to reach a destination;
- whether the stall happens with a single NPC or only at the intended maximum population;
- how often recomputation occurs and whether any movement tasks remain after an NPC is destroyed;
- whether the problem materially blocks dialogue access or gameplay.

## Criteria for adding pathfinding later

Only add PathfindingService if a reproduced issue is material. Any implementation must use bounded recomputation, waypoint handling, a fallback when no path exists, no per-frame path calls, and deterministic task cleanup on NPC destruction. Re-run the NPC movement and full regression checklist after that change.
