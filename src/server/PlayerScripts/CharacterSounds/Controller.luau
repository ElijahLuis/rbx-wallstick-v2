--!strict
--[[
	@file Controller.luau
	@within PlayerScripts.CharacterSounds

	Initializes and manages character sound effects for all players.

	Responsibilities:
	- Hooks into each player’s character and sets up audio emitters using CharacterSounds
	- Cleans up on character removal or player leave
	- Supports custom sound emitters via `setPerformer(player, performer)`

	Dependencies:
	- CharacterSounds module in SharedPackages
	- Expects a Model character with sound sources in predefined locations
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedPackages = ReplicatedStorage.SharedPackages
local CharacterSounds = require(SharedPackages.CharacterSounds)

local CharacterSoundController = {} :: {
	setPerformer: (Player, Model?) -> (),
}

-- Private --

-- Types and state
type PlayerState = {
	performer: Model?,
	terminateSound: (() -> ())?,
	connections: { RBXScriptConnection },
}

local playerStates: { [Player]: PlayerState } = {}

-- Cleanup sound controller for player
local function terminateSound(player: Player)
	local state = playerStates[player]
	if state and state.terminateSound then
		state.terminateSound()
		state.terminateSound = nil
	end
end

-- Clean lifecycle handlers
local function characterRemoving(player: Player, _character: Model)
	terminateSound(player)
end

local function characterAdded(player: Player, character: Model)
	characterRemoving(player, character)

	local state = playerStates[player]
	if state then
		local performer = state.performer or character
		local controller = CharacterSounds.listen(performer, character)
		state.terminateSound = controller.cleanup
	end
end

-- Player lifecycle handlers
local function playerRemoving(player: Player)
	terminateSound(player)

	local state = playerStates[player]
	if state then
		for _, connection in state.connections do
			connection:Disconnect()
		end
	end

	playerStates[player] = nil
end

local function playerAdded(player: Player)
	playerRemoving(player) -- clean dangling state

	local state = {
		performer = nil,
		connections = {},
		terminateSound = nil,
	}

	if player.Character then
		characterAdded(player, player.Character)
	end

	table.insert(
		state.connections,
		player.CharacterAdded:Connect(function(character)
			characterAdded(player, character)
		end)
	)

	table.insert(
		state.connections,
		player.CharacterRemoving:Connect(function(character)
			characterRemoving(player, character)
		end)
	)

	playerStates[player] = state
end

-- Initialize sound handlers for all current players
for _, player in Players:GetPlayers() do
	task.spawn(playerAdded, player)
end

-- Connect future players
Players.PlayerAdded:Connect(playerAdded)
Players.PlayerRemoving:Connect(playerRemoving)

-- Public --

function CharacterSoundController.setPerformer(player: Player, performer: Model?)
	local state = playerStates[player]
	if state then
		state.performer = performer

		local character = player.Character
		if character then
			characterAdded(player, character)
		end
	end
end

return CharacterSoundController
