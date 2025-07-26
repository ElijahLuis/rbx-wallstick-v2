--!strict
--[[
	@module RotationSpring

	Implements a critically-damped spring system for smooth and realistic rotational transitions.

	Docs & license can be found at https://github.com/Fraktality/spr
	Graph: https://www.desmos.com/calculator/rzvw27ljh9
	Copyright (c) 2024 Fractality. All rights reserved.
	Released under the MIT license.
	
	Features:
	- Supports underdamped, overdamped, and critically damped rotational motion
	- High-precision axis-angle math for accurate and stable rotation
	- Built-in sleep detection to reduce unnecessary updates
	- Uses Orthonormalization to maintain numerical stability

	Usage:
	- Call `RotationSpring.new(...)` with desired damping, frequency, and CFrame values
	- `step(dt)` returns the updated CFrame but does **not** apply it.
	- Access or update spring state with `getPosition()`, `setVelocity()`, and `setGoal(...)`
	- Optionally check if the spring is at rest via `canSleep()`

	Note:
	- The system returns a rotated CFrame, but does not apply it to an object.
	- Use in conjunction with render step or heartbeat updates for smooth motion.
]]

local pi = math.pi
local exp = math.exp
local sin = math.sin
local cos = math.cos
local max = math.max
local sqrt = math.sqrt
local atan2 = math.atan2

local SLEEP_ROTATION_DIFF = math.rad(0.01) -- rad
local SLEEP_ROTATION_VELOCITY = math.rad(0.1) -- rad/s

-- Class

local RotationSpringClass = {}
RotationSpringClass.__index = RotationSpringClass
RotationSpringClass.ClassName = "RotationSpring"

export type RotationSpring = typeof(setmetatable(
	{} :: {
		dampingRatio: number,
		frequency: number,
		position: CFrame,
		velocity: Vector3,
		goal: CFrame,
	},
	RotationSpringClass
))

--[[
        Creates a new RotationSpring.
        @within RotationSpring
        @param dampingRatio number -- How quickly the spring settles (1 = critically damped)
        @param frequency number -- Natural frequency in Hz (before conversion to rad/s)
        @param position CFrame -- Initial rotation
        @param goal CFrame -- Target rotation
        @return RotationSpring
]]

function RotationSpringClass.new(dampingRatio: number, frequency: number, position: CFrame, goal: CFrame)
	local self = setmetatable({}, RotationSpringClass) :: RotationSpring

	self.dampingRatio = dampingRatio
	self.frequency = frequency

	self.goal = goal:Orthonormalize()
	self.position = position:Orthonormalize()
	self.velocity = Vector3.zero

	return self
end

-- Private --

-- Evaluate dot products in high precision
local function dot(v0: Vector3, v1: Vector3)
	return v0.X * v1.X + v0.Y * v1.Y + v0.Z * v1.Z
end

local function areRotationsClose(c0: CFrame, c1: CFrame)
	local rx = dot(c0.XVector, c1.XVector)
	local ry = dot(c0.YVector, c1.YVector)
	local rz = dot(c0.ZVector, c1.ZVector)
	local trace = rx + ry + rz
	return trace > 1 + 2 * cos(SLEEP_ROTATION_DIFF)
end

local function angleDiff(c0: CFrame, c1: CFrame)
	local x = dot(c0.XVector, c1.XVector)
	local y = dot(c0.YVector, c1.YVector)
	local z = dot(c0.ZVector, c1.ZVector)
	local w = x + y + z - 1
	return atan2(sqrt(max(0, 1 - w * w * 0.25)), w * 0.5)
end

-- gives approx. 21% accuracy improvement over CFrame.fromAxisAngle near poles
local function fromAxisAngle(axis: Vector3, angle: number)
	local c = cos(angle)
	local s = sin(angle)
	local x, y, z = axis.X, axis.Y, axis.Z

	local mxy = x * y * (1 - c)
	local myz = y * z * (1 - c)
	local mzx = z * x * (1 - c)

	local rx = Vector3.new(x * x * (1 - c) + c, mxy + z * s, mzx - y * s)
	local ry = Vector3.new(mxy - z * s, y * y * (1 - c) + c, myz + x * s)
	local rz = Vector3.new(mzx + y * s, myz - x * s, z * z * (1 - c) + c)

	return CFrame.fromMatrix(Vector3.zero, rx, ry, rz):Orthonormalize()
end

local function rotateAxis(r0: Vector3, c1: CFrame)
	local c0 = CFrame.identity
	local mag = r0.Magnitude
	if mag > 1e-6 then -- threshold to treat rotation as significant
		c0 = fromAxisAngle(r0.Unit, mag)
	end
	return c0 * c1
end

-- axis * angle difference between two cframes
local function axisAngleDiff(c0: CFrame, c1: CFrame)
	-- use native axis (stable enough)
	local axis = (c0 * c1:Inverse()):ToAxisAngle()

	-- use full-precision angle calculation to minimize truncation
	local angle = angleDiff(c0, c1)
	return axis.Unit * angle
end

-- Public Getters --

--[=[
        Returns the damping ratio.
        @within RotationSpring
        @param self RotationSpring
        @return number
]=]
function RotationSpringClass.getDampingRatio(self: RotationSpring)
	return self.dampingRatio
end

--[=[
        Returns the natural frequency in Hz.
        @within RotationSpring
        @param self RotationSpring
        @return number
]=]
function RotationSpringClass.getFrequency(self: RotationSpring)
	return self.frequency
end

--[=[
        Returns the current position CFrame.
        @within RotationSpring
        @param self RotationSpring
        @return CFrame
]=]
function RotationSpringClass.getPosition(self: RotationSpring)
	return self.position
end

--[=[
        Returns the current angular velocity.
        @within RotationSpring
        @param self RotationSpring
        @return Vector3
]=]
function RotationSpringClass.getVelocity(self: RotationSpring)
	return self.velocity
end

--[=[
        Returns the goal rotation.
        @within RotationSpring
        @param self RotationSpring
        @return CFrame
]=]
function RotationSpringClass.getGoal(self: RotationSpring)
	return self.goal
end

-- Public Setters --
--[=[
        Sets the damping ratio.
        @within RotationSpring
        @param self RotationSpring
        @param dampingRatio number
]=]
function RotationSpringClass.setDampingRatio(self: RotationSpring, dampingRatio: number)
	self.dampingRatio = dampingRatio
end

--[=[
        Sets the natural frequency in Hz.
        @within RotationSpring
        @param self RotationSpring
        @param frequency number
]=]
function RotationSpringClass.setFrequency(self: RotationSpring, frequency: number)
	self.frequency = frequency
end

--[=[
        Sets the current position of the spring.
        @within RotationSpring
        @param self RotationSpring
        @param position CFrame
]=]
function RotationSpringClass.setPosition(self: RotationSpring, position: CFrame)
	self.position = position
end

--[=[
        Sets the current angular velocity.
        @within RotationSpring
        @param self RotationSpring
        @param velocity Vector3
]=]
function RotationSpringClass.setVelocity(self: RotationSpring, velocity: Vector3)
	self.velocity = velocity
end

--[=[
        Sets the target rotation.
        @within RotationSpring
        @param self RotationSpring
        @param goal CFrame
]=]
function RotationSpringClass.setGoal(self: RotationSpring, goal: CFrame)
	self.goal = goal
end

-- Lifecycle --
--[=[
        Determines if the spring is at rest.
        @within RotationSpring
        @param self RotationSpring
        @return boolean
]=]
function RotationSpringClass.canSleep(self: RotationSpring)
	local sleepP = areRotationsClose(self.position, self.goal)
	local sleepV = self.velocity.Magnitude < SLEEP_ROTATION_VELOCITY
	return sleepP and sleepV
end

--[=[
        Advances the spring simulation by `dt` seconds.
        @within RotationSpring
        @param self RotationSpring
        @param dt number
        @return CFrame -- new position
]=]
function RotationSpringClass.step(self: RotationSpring, dt: number)
	local d = self.dampingRatio
	local TAU = 2 * pi
	local f = self.frequency * TAU
	local g = self.goal
	local p0 = self.position
	local v0 = self.velocity

	local offset = axisAngleDiff(p0, g)
	-- clamp input for sqrt below to avoid NaN when `d` drifts slightly
	-- outside expected range due to floating-point error
	local decay = exp(-d * f * dt)

	local pt: CFrame -- new position
	local vt: Vector3 -- new velocity

	if d == 1 then
		-- critically damped
		pt = rotateAxis((offset * (1 + f * dt) + v0 * dt) * decay, g)
		vt = (v0 * (1 - dt * f) - offset * (dt * f * f)) * decay
	elseif d < 1 then
		-- underdamped
		-- slight overflows can occur if d > 1 due to float rounding
		-- wrap sqrt input to avoid NaN when value dips below 0
		local c = sqrt(max(0, 1 - d * d))

		local i = cos(dt * f * c)
		local j = sin(dt * f * c)

		local y = j / (f * c)
		local z = j / c

		pt = rotateAxis((offset * (i + z * d) + v0 * y) * decay, g)
		vt = (v0 * (i - z * d) - offset * (z * f)) * decay
	else
		-- overdamped
		-- same overflow protection as underdamped branch
		local c = sqrt(max(0, d * d - 1))

		local r1 = -f * (d + c)
		local r2 = -f * (d - c)

		local co2 = (v0 - offset * r1) / (2 * f * c)
		local co1 = offset - co2

		local e1 = co1 * exp(r1 * dt)
		local e2 = co2 * exp(r2 * dt)

		pt = rotateAxis(e1 + e2, g)
		vt = e1 * r1 + e2 * r2
	end

	self.position = pt
	self.velocity = vt

	return pt
end

--

return RotationSpringClass
