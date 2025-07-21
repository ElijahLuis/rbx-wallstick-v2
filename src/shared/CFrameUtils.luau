--!strict
--[[
    @module CFrameUtils
    Utility functions for quaternion-based CFrame math.
    Provides fromToRotation() and swingTwist() for aligning axes and
    decomposing rotations. Shared by Wallstick and GravityCameraModifier.
]]

local CFrameUtils = {}

--[=[
    Calculates the rotation CFrame that aligns one unit vector with another.
    Falls back to CFrame.fromAxisAngle when vectors are opposite to avoid
    gimbal lock. Inspired by the "Aligning CFrames" article on the
    Roblox Creator Hub.
]=]
function CFrameUtils.fromToRotation(from: Vector3, to: Vector3, backupUnitAxis: Vector3?): CFrame
	local dot = from:Dot(to)
	if dot < -0.99999 then
		return if backupUnitAxis
			then CFrame.fromAxisAngle(backupUnitAxis, math.pi)
			else CFrame.fromRotationBetweenVectors(from, to)
	end
	local qv = from:Cross(to)
	local qw = math.sqrt(from:Dot(from) * to:Dot(to)) + dot
	return CFrame.new(0, 0, 0, qv.X, qv.Y, qv.Z, qw)
end

--[=[
    Splits a rotation into swing and twist components relative to a given axis.
    Useful for isolating roll around an axis. Based on standard quaternion
    decomposition techniques.
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
