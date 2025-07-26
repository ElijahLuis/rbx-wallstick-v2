--!strict
--[[
    @module CFrameUtils
    Utility functions for quaternion-based CFrame math.
    Provides fromToRotation() and swingTwist() for aligning axes and
    decomposing rotations. Shared by Wallstick and GravityCameraModifier.
]]

local CFrameUtils = {}

local EPSILON = 1e-6

--[=[
    Calculates the rotation CFrame that aligns `from` with `to` using
    `CFrame.fromRotationBetweenVectors`. When the vectors are opposite,
    a `backupUnitAxis` may be supplied to specify the spin direction.
    Follows the recommendations from the Roblox Creator Hub.

    @within CFrameUtils
    @param from Vector3
    @param to Vector3
    @param backupUnitAxis Vector3?
    @return CFrame
]=]
function CFrameUtils.fromToRotation(from: Vector3, to: Vector3, backupUnitAxis: Vector3?): CFrame
	if from.Magnitude < EPSILON or to.Magnitude < EPSILON then
		return CFrame.identity
	end

	local dot = from:Dot(to)
	if dot < -0.99999 and backupUnitAxis then
		return CFrame.fromAxisAngle(backupUnitAxis, math.pi)
	end

	return CFrame.fromRotationBetweenVectors(from, to)
end

--[=[
    Splits a rotation into swing and twist components relative to a given axis.
    Useful for isolating roll around an axis. Based on standard quaternion
    decomposition techniques.

    @within CFrameUtils
    @param inputCF CFrame
    @param relativeUnitAxis Vector3
    @return CFrame -- swing
    @return CFrame -- twist
]=]
function CFrameUtils.swingTwist(inputCF: CFrame, relativeUnitAxis: Vector3): (CFrame, CFrame)
	local axis, theta = inputCF:ToAxisAngle()
	local w = math.cos(theta / 2)
	local v = math.sin(theta / 2) * axis

	local proj = v:Dot(relativeUnitAxis) * relativeUnitAxis
	local twist = CFrame.new(0, 0, 0, proj.X, proj.Y, proj.Z, w)

	local swing = inputCF * twist:Inverse()

	return swing, twist
end

return CFrameUtils
