--!strict
--[[
        @module WallstickCharacterState

       Simple state tracker for wall-sticking characters. Currently exposes
       read-only state for whether the real character's root part is anchored
       and whether the humanoid is in the Jumping state.

        Design Notes:
       - Only provides Get() method per user request. Future work may expose
         mutators or additional state fields.
        - Uses direct property change connections on the real character and is
          cleaned up via Trove by the creator.
]]

local Trove = require(game:GetService("ReplicatedStorage").SharedPackages.Trove)
local CharacterHelper = require(script.Parent.CharacterHelper)

-- Class --
local StateClass = {}
StateClass.__index = StateClass
StateClass.ClassName = "WallstickCharacterState"

export type State = {
	isAnchored: boolean,
	isJumping: boolean,
}

export type WallstickCharacterState = typeof(setmetatable({}, StateClass)) & {
	trove: Trove.Trove,
	real: CharacterHelper.RealCharacter,
	state: State,
}

function StateClass.new(trove: Trove.Trove, real: CharacterHelper.RealCharacter): WallstickCharacterState
	local self = setmetatable({}, StateClass) :: WallstickCharacterState

	self.trove = trove
	self.real = real

	assert(real.humanoid:IsA("Humanoid"), "Invalid Humanoid")
	assert(real.rootPart:IsA("BasePart"), "Invalid RootPart")

	self.state = {
		isAnchored = real.rootPart.Anchored,
		isJumping = real.humanoid:GetState() == Enum.HumanoidStateType.Jumping,
	}

	self.trove:Add(real.rootPart:GetPropertyChangedSignal("Anchored"):Connect(function()
		self.state.isAnchored = real.rootPart.Anchored
		print("[StateTracker] Anchored changed:", real.rootPart.Anchored)
	end))

	self.trove:Add(real.humanoid.Jumping:Connect(function()
		self.state.isJumping = true
		print("[StateTracker] Jump START")
	end))

	self.trove:Add(real.humanoid.StateChanged:Connect(function(_, newState)
		if newState ~= Enum.HumanoidStateType.Jumping then
			if self.state.isJumping then
				print("[StateTracker] Jump END \226\134\146 New State:", newState.Name)
			end
			self.state.isJumping = false
		end
	end))

	return self
end

function StateClass.Get(self: WallstickCharacterState): State
	return table.clone(self.state)
end

return StateClass
