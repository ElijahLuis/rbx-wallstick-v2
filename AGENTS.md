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

### `src/server/init.server.luau`
- **Purpose**: Server bootstrap — sets up collision groups, player script overrides, replication listener  
- **Runtime Checks**: Includes try/catch-style logic for collision group setup  

### `PlayerScripts/GravityCameraModifier.luau`
- **Purpose**: Injects camera patch into PlayerModule for surface-relative alignment  
- **Hooked via**: `PlayerScripts/init.luau`  
- **Note**: Works in tandem with GravityCamera.luau, should remain lightweight  

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
- [ ] Finalize GravityCameraModifier.luau documentation  
- [ ] Improve replication fidelity across all character parts, not just HumanoidRootPart  
- [ ] Ensure compatibility with both R6 and R15 rigs  
- [ ] Map and fix desync bugs between real/fake characters  

---

## 📓 Logs:

Use this section to track meaningful discoveries, design choices, or bugs/fixes Codex encounters. Timestamp when possible. Entries should be brief but specific.

---

### [2025-07-19] TransparencyController crash on nil part transparency
- Symptom: Runtime error thrown by `TransparencyController` when targeting nil or missing parts.
- Fix: Added fallback logic to skip parts that return `nil` or have no `Transparency` property.

---

