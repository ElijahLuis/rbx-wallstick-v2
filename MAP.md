# Project Map
Comprehensive map of the rbx-wallstick system created by EgoMoose.
Mapping, additional documentation, and modernization by Nejinumanuma.

# Project Tree
- `.vscode`
    - `selene.yml` -- custom config for Selene linter
    - `settings.json` -- for VSCode Stylua extension
- `demo`
    - `playground.rbxl` -- custom playground created by EgoMoose
- `lune`
    -`wally-install.luau`-- wally setup utility
- `src`
    - `client`
        - `Wallstick`
            - `CharacterHelper.luau` -- constructs real and fake character models
            - `GravityCamera.luau` -- custom camera for custom gravity
            - `init.luau` -- wallstick logic
            - `Replication.luau` -- client/server replication logic
            - `RotationSpring.luau` -- rotation math and logic
        - `clientEntry.client.luau` -- starts and binds wallstick to character
    - `server`
        - `PlayerScripts`
            - `Animate`
                - `Controller.luau` -- syncs character animations
                - `init.client.luau` -- runs Animate.Controller
                - `PlayEmote.model.json` -- used by Controller.luau to allow emote playback
            - `Character Sounds`
                - `Controller.luau` -- sets up sound emitters
                - `init.client.luau` -- runs CharacterSounds.Controller
            - `GravityCameraModifier.luau` -- modifies camera to support spherical gravity environments
            - `init.luau` -- character and player script overrides
        - `init.server.luau` -- sets up serverside wallstick env and collision groups

# Other Project Files
- `MAP.md` -- this file
- `.gitattributes`
- `.gitignore`
- `cspell.json`
- `default.project.json` -- tells rojo what folders to sync
- `LICENSE`
- `README.md` --
- `rokit.toml`
- `selene.toml`
- `stylua.toml`
- `wally.lock`
- `wally.toml`