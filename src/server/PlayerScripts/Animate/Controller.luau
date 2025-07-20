--!strict
--[[
	@file Controller.luau
	@within PlayerScripts.Animate

	Initializes and syncs character animation between a director (controller) and performer.

	Responsibilities:
	- Loads the CharacterAnimate module
	- Binds animations to a humanoid performer
	- Exposes an emote trigger via the `PlayEmote` RemoteFunction
	- Allows re-binding to a different humanoid via `matchAnimate()`

	Dependencies:
	- CharacterAnimate module in SharedPackages
	- Expects to be parented under a model with a Humanoid and a PlayEmote RemoteFunction
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedPackages = ReplicatedStorage.SharedPackages
local CharacterAnimate = require(SharedPackages.CharacterAnimate)

local animate = script.Parent
local character = animate.Parent
local performer = character:WaitForChild("Humanoid")
local module = {} :: {
	matchAnimate: (Humanoid) -> (),
}

local controller: {
	playEmote: (string) -> any,
	cleanup: () -> (),
}?

function module.matchAnimate(director: Humanoid)
	if controller then
		controller.cleanup()
	end

	controller = CharacterAnimate.animate(animate, director, performer)
end

animate:WaitForChild("PlayEmote").OnInvoke = function(emote)
	if controller then
		return controller.playEmote(emote)
	end

	print(string.format('[Wallstick][PlayEmote] Attempted to play emote "%s" but no controller is active.', emote))
	return false
end

module.matchAnimate(performer)

return module
