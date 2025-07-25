# Changelog

This file tracks historical solutions previously stored in `AGENTS.md`.

---

## [2025-07-26]

- **Symptoms reported by user:** Searching codebase for deprecated classes
- **Issue identified:** `ignoreCharacterParts` only inspected immediate parents while `_updateCollisionGeometry` still used `FindPartsInRegion3WithIgnoreList`.
- **Methods used:** Reviewed Roblox Creator Hub docs for `GetPartBoundsInBox` and rewrote the filter to climb the ancestor chain for a `Humanoid` check.
- **Solution implemented:** Replaced the region query with `workspace:GetPartBoundsInBox` using `OverlapParams` and updated `ignoreCharacterParts` to skip any parts belonging to a model that contains a `Humanoid`.
- **Why this solution was effective:** Eliminated false collisions with characters and removed deprecated API warnings.

## [2025-07-21]

- **Symptoms reported by user:** Character limb positions were inconsistent across clients.
- **Issue identified:** Limb offsets were not being replicated by the network layer.
- **Methods used:** Extended the Replication module to include limb data and updated `_trySendReplication` logic.
- **Solution implemented:** Broadcast torso and head offsets with each replication cycle.
- **Why this solution was effective:** Improved animation accuracy across clients by synchronizing additional character parts.

## [2025-07-20]

- **Symptoms reported by user:** Runtime crashes when the game started; errors from GravityCameraModifier and TransparencyController.
- **Issue identified:** `fromToRotation` and `swingTwist` functions were defined after they were called. TransparencyController referenced `self.lastTransparency` before initialization and called `Update(dt)` with a nil argument.
- **Methods used:** Reviewed stack traces, inspected Lua order requirements, and traced incorrect parameter usage.
- **Solution implemented:** Moved function declarations above their usage, provided a fallback for `lastTransparency`, and corrected the `Update(dt)` call. Documented module responsibilities and verified project structure.
- **Why this solution was effective:** Prevented nil function references, avoided arithmetic errors, and ensured stable initialization.
