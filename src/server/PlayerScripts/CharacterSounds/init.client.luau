--!strict
--[[
	@file init.client.luau
	@within PlayerScripts.CharacterSounds

	Entry point for character sound initialization.
	Requires and executes the CharacterSounds.Controller module in the same folder.

	Responsibilities:
	- Loads and runs the CharacterSounds.Controller script, which handles per-player audio emitter logic
]]

local CharacterSoundController = require(script:WaitForChild("Controller"))
