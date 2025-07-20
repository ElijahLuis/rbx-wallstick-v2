# Repo Guide: rbx-wallstick-v2

This repository contains a modular wall‑sticking system for Roblox. The files are
organized for use with Rojo and Wally packages.

## Layout
- `src/client` – client scripts. `clientEntry.client.luau` binds the wallstick logic when the character spawns. The `Wallstick` folder contains the main modules.
- `src/server` – server scripts. `init.server.luau` creates collision groups and bootstraps player scripts.
- `demo` – sample place file for quick testing.
- `lune/wally-install.luau` – helper script that runs Wally, generates a Rojo sourcemap and applies `wally-package-types`.

## Setup
1. Install tools from `rokit.toml` (Rojo, Wally, Stylua, Selene, etc.).
2. Run `lune lune/wally-install.luau` to install Wally dependencies and generate type information.
3. Build a place with Rojo: `rojo build default.project.json -o Wallstick.rbxl`.

## Development Notes
- Format Luau files with `stylua` (`stylua src`).
- Run `selene` for static analysis.
- `wally.lock` and package folders are ignored by Git – run Wally after cloning.

## Common Issues
- **StreamingEnabled** – `clientEntry.client.luau` asserts that `workspace.StreamingEnabled` is false. Disable it before running.
- **Context errors** – `Replication.send` and `Replication.listenServer` include asserts that enforce client vs. server usage. Ensure you call them from the correct environment.
- **Character packaging** – `CharacterHelper.real()` throws `"Failed to package character."` if the character lacks a Humanoid or `RootAttachment`.
- **PhysicsService groups** – the server script sets up `WallstickCollision` and `WallstickNoCollision`. If physics behaves incorrectly, verify these groups exist.

Keep this file updated with troubleshooting tips as you encounter new issues.

