# 📘 AGENTS.MD — Codex Internal Brain & Guide

Codex’s internal guide and memory store. Use this file as your **brain**. Always check this file **first** before reading logs, modules, or runtime scripts. It tracks architectural decisions, file purposes, naming conventions, and known quirks. Update this as the project evolves.

---

## 👤 Agent Profile: Codex

- **Role**: Collaborative code interpreter, fixer, and refiner  
- **Objective**: Maintain Wallstick’s functionality, structure, extensibility, and clarity  
- **Rules**:  
  - Document and reflect on file purposes as you read them  
  - Log assumptions, patterns, and exceptions in one place  
  - Prioritize modularity, maintainability, and developer empathy  
  - Reference this file before executing any structural change or inference  

---

## 🧠 Primary Directive

Treat this file as your **core mental model**. If you’re unsure how to proceed, start here. Log discoveries and decisions that affect code behavior, especially in:

- Character sync logic  
- Gravity/camera overrides  
- Replication layers  
- Compatibility between R6 and R15 rigs  

---

## 🔧 Purpose of This Project

You are assisting in the modernization of the **rbx-wallstick** module — a wall-walking system forked from EgoMoose and refactored for modern Roblox compatibility.

### Project Priorities:
- R6 & R15 support  
- Clean, typed, modular code  
- Gravity-aware movement and camera  
- Seamless replication & dev experience  

---

## 🧭 File Purposes

### `src/client/Wallstick/init.luau`
- **Purpose**: Core Wallstick logic — binds surfaces, maintains state, handles player integration
- **Hooks into**: CharacterHelper, Replication
- **Notes**: Depends on `clientEntry.client.luau` for initialization
  - `_trySendReplication` now sends torso/head offsets for smoother remote animation

### `src/server/init.server.luau`
- **Purpose**: Server bootstrap — sets up collision groups, player script overrides, replication listener  
- **Runtime Checks**: Includes try/catch-style logic for collision group setup  

### `PlayerScripts/GravityCameraModifier.luau`
- **Purpose**: Injects camera patch into PlayerModule for surface-relative alignment
- **Hooked via**: `PlayerScripts/init.luau`
- **Note**: Works in tandem with GravityCamera.luau, should remain lightweight

### `src/client/Wallstick/CharacterHelper.luau`
- **Purpose**: Packages real and fake character models, applies alignment attachments
- **Dependencies**: PlayerScripts, CharacterSoundsController

### `src/client/Wallstick/GravityCamera.luau`
- **Purpose**: Wrapper API around PlayerModule camera with gravity-aware helpers
- **Dependencies**: Modified PlayerModule in PlayerScripts

### `src/client/Wallstick/RotationSpring.luau`
- **Purpose**: Critically damped rotational spring used for smooth camera tilt

### `src/client/Wallstick/Replication.luau`
- **Purpose**: Network layer for syncing part offsets across clients and server
- **Notes**: Uses TypedRemote for typed events
  - Now replicates head and torso offsets in addition to root part
  - Limb data throttled via `REPLICATE_DEBOUNCE_TIME`

### `src/shared/CFrameUtils.luau`
- **Purpose**: Shared math helpers providing `fromToRotation()` and `swingTwist()`
  for quaternion conversions used by Wallstick and GravityCameraModifier

### `src/client/clientEntry.client.luau`
- **Purpose**: Client bootstrap; spawns Wallstick on character spawn and performs raycast checks
### `src/server/PlayerScripts/init.luau`
- **Purpose**: Replaces default PlayerModule and Character scripts with custom versions

### `src/server/PlayerScripts/Animate/init.client.luau`
- **Purpose**: Loads animation controller on client

### `src/server/PlayerScripts/Animate/Controller.luau`
- **Purpose**: Binds animations from SharedPackages.CharacterAnimate to performer humanoid

### `src/server/PlayerScripts/CharacterSounds/init.client.luau`
- **Purpose**: Loads CharacterSounds controller for audio emitters

### `src/server/PlayerScripts/CharacterSounds/Controller.luau`
- **Purpose**: Manages per-player sound emitters and cleanup

### `src/server/PlayerScripts/Animate/PlayEmote.model.json`
- **Purpose**: Declares `PlayEmote` BindableFunction instance used by Animate.Controller
- **Dependencies**: Consume via `Animate/Controller.luau`
- **Notes**: Keep in sync with any server-side emote triggers

*(Add more as modules are documented)*
---

## 📂 File Access Priority

Codex, always reference files in this order:

1. `Agents.md` (this file – your brain)  
2. Entry modules like `init.luau`  
3. Camera and physics patches (e.g. GravityCameraModifier)  
4. Replication, CharacterSync, and utility layers  
5. Logs and test scripts (read-only context)

---

## 🛠️ Naming Conventions

| Type              | Convention         | Example                    |
|------------------|--------------------|----------------------------|
| Files/Modules     | UpperCamelCase     | `GravityCamera.luau`       |
| Functions         | lowerCamelCase     | `replaceIfExists()`        |
| Locals (private)  | snake_case         | `prev_spin_part`           |
| Constants         | SCREAMING_SNAKE_CASE | `MAX_SPEED`            |

---

## 🧪 Testing Notes (TBD)

- Placeholder for dev playground observations  
- Noticed weird camera jitter after switching planets — traced to spring logic? (track fix later)  

---

## 💡 Future Codex To-Do

- [ ] Review: Are fake characters needed for local-only physics, or could we replicate real characters directly?  
- [x] Finalize GravityCameraModifier.luau documentation
- [ ] Improve replication fidelity across all character parts, not just HumanoidRootPart  
- [ ] Ensure compatibility with both R6 and R15 rigs  
- [ ] Map and fix desync bugs between real/fake characters  

---

## 📓 Logs

Historical solutions have moved to [logs/Changelog.md](logs/Changelog.md).

---

