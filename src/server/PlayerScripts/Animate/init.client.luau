--!strict
--[[
	@file init.client.luau
	@within PlayerScripts.Animate

	Entry point for character animation initialization.
	Requires and executes the Controller module in the same folder.

	Responsibilities:
	- Loads and runs the Animate.Controller script, which sets up animation syncing and emote handling
]]

local AnimateController = require(script:WaitForChild("Controller"))
