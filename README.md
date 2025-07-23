# Roblox Wallstick V2
A modular, extensible wall-sticking system for Roblox characters.
Designed for custom gravity, surface traversal, and advanced camera behavior in non-traditional environments.

Originally created by [EgoMoose](https://github.com/EgoMoose). 
Modernized, and maintained by [Nejinumanuma](https://github.com/ElijahLuis).

## Features

- Wall-sticking and custom gravity orientation
- Camera realignment based on surface normals
- Client/server replication of gravity states
- Modular separation of core logic, character scripts, and camera modifiers
- Plug-and-play `PlayerModule` camera override support
- Rojo-compatible, clean dev structure with lint and formatting tooling

## Project Tree Map

### `demo/`
- `playground.rbxl` ~ custom test playground

### `lune/`
- `wally-install.luau`~ wally setup utility

### `src/client/`
- `clientEntry.client.luau` ~ entry point: binds wallstick on character spawn

#### `Wallstick/`
- `CharacterHelper.luau` ~ builds real and fake character models for physics sync
- `GravityCamera.luau` ~ handles surface-relative camera orientation
- `init.luau` ~ core wallstick logic
- `Replication.luau` ~ manages gravity state sync
- `RotationSpring.luau` ~ math helper for smooth rotation damping

### `src/server/`
- `init.server.luau` ~ creates collision groups and server-side logic

#### `PlayerScripts/`
- `Animate/` 
    - `Controller.luau` ~ syncs character animations and controls playback
    - `init.client.luau` ~ entry for Animate.Controller
    - `PlayEmote.model.json` ~ used by Controller.luau to allow emote playback

- `CharacterSounds/`
    - `Controller.luau` ~ manages 3D character audio
    - `init.client.luau` ~ entry for CharacterSounds.Controller
- `GravityCameraModifier.luau` ~ modifies camera to support spherical gravity environments
- `init.luau` ~ character and player script overrides

## Other Project Files
- `README.md` ~ you are here ⭐
- `.gitattributes` ~ text normalization
- `.gitignore` ~ reduces git clutter
- `cspell.json` ~ spell checker
- `default.project.json` ~ rojo sync config
- `LICENSE` ~ open source license
- `rokit.toml` ~ rokit config
- `selene.toml` ~ selene config
- `stylua.toml` ~ stylua config
- `wally.toml` ~ wally dependency config

## Setup

1. Install the required packages:
- [Rojo](https://rojo.space/docs/v7/getting-started/installation/)
- [Wally](https://github.com/UpliftGames/wally):

   ```bash
   wally install
   ```

2. Build your development place with [Rojo](https://rojo.space):

   ```bash
   rojo build default.project.json -o "game.rbxlx"
   ```

3. Add `src/server/init.server.luau` to `ServerScriptService` and ensure the `src/server/PlayerScripts` folder is copied alongside your other player scripts. The included `init.luau` clones Roblox's PlayerModule, injects `GravityCameraModifier`, and replaces the default module at runtime.

See the [Roblox Creator Hub](https://create.roblox.com/docs/reference/engine/classes/PlayerModule) for the latest documentation on extending PlayerModule.