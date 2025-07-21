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

local RunService = game:GetService("RunService")
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
		isJumping = false,
	}

	self.trove:Add(real.rootPart:GetPropertyChangedSignal("Anchored"):Connect(function()
		self.state.isAnchored = real.rootPart.Anchored
		print("[StateTracker] Anchored changed:", real.rootPart.Anchored)
	end))

	local lastY = real.rootPart.Position.Y
	local isJumping = false

	self.trove:Add(RunService.Heartbeat:Connect(function()
		local velocity = real.rootPart.Velocity
		local verticalSpeed = velocity.Y

		-- Detect jump by checking for sudden upward movement
		if verticalSpeed > 2 and not isJumping then
			isJumping = true
			self.state.isJumping = true
			print("[StateTracker] Jump START (Velocity Triggered)")
		end

		-- Reset jump once vertical speed drops or falls
		if isJumping and verticalSpeed <= 0 then
			isJumping = false
			self.state.isJumping = false
			print("[StateTracker] Jump END (Velocity Dropped)")
		end
	end))

	return self
end

function StateClass.Get(self: WallstickCharacterState): State
	return table.clone(self.state)
end

return StateClass
