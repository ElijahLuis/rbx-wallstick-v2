--!strict
--[[
        @module WallstickCharacterState

        Simple state tracker for wall-sticking characters. Currently exposes
        read-only flags for whether the real character's root part is anchored
        and whether the humanoid is in the Jumping state.

        Design Notes:
        - Only provides Get() method per user request. Future work may expose
          mutators or additional flags.
        - Uses direct property change connections on the real character and is
          cleaned up via Trove by the creator.
]]

local Trove = require(game:GetService("ReplicatedStorage").SharedPackages.Trove)
local CharacterHelper = require(script.Parent.CharacterHelper)

-- Class --
local StateClass = {}
StateClass.__index = StateClass
StateClass.ClassName = "WallstickCharacterState"

export type Flags = {
	isAnchored: boolean,
	isJumping: boolean,
}

export type WallstickCharacterState = typeof(setmetatable({}, StateClass)) & {
	trove: Trove.Trove,
	real: CharacterHelper.RealCharacter,
	flags: Flags,
}

function StateClass.new(trove: Trove.Trove, real: CharacterHelper.RealCharacter): WallstickCharacterState
	local self = setmetatable({}, StateClass) :: WallstickCharacterState

	self.trove = trove
	self.real = real
	self.flags = {
		isAnchored = real.rootPart.Anchored,
		isJumping = real.humanoid:GetState() == Enum.HumanoidStateType.Jumping,
	}

	self.trove:Add(real.rootPart:GetPropertyChangedSignal("Anchored"):Connect(function()
		self.flags.isAnchored = real.rootPart.Anchored
	end))

	self.trove:Add(real.humanoid.Jumping:Connect(function()
		self.flags.isJumping = true
	end))

	self.trove:Add(real.humanoid.StateChanged:Connect(function(_, newState)
		if newState ~= Enum.HumanoidStateType.Jumping then
			self.flags.isJumping = false
		end
	end))

	return self
end

function StateClass.Get(self: WallstickCharacterState): Flags
	return table.clone(self.flags)
end

return StateClass
