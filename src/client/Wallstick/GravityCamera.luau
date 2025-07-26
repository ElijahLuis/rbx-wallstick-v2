--!strict
--[[
	@class GravityCamera
	@module GravityCamera

	Provides a typed interface for controlling the camera under custom gravity conditions.
	This module wraps methods from the custom PlayerModule camera system (forked from EgoMoose's gravity controller).
	Requires a custom PlayerModule (forked from Roblox's default) with extended gravity support.

	Supports:
	- Custom "up" vectors for the camera (e.g., to match wall or ceiling surfaces)
	- Camera rotation synchronized to a moving "spin part" (e.g. rotating platform)
	- Gravity-aware movement vector calculation from input
	- Works with a modified PlayerModule that supports GetUpVector, SetTargetUpVector, SetSpinPart, etc.

	Relies on:
	- cameraModuleObject = Players.LocalPlayer.PlayerScripts.PlayerModule:GetCameras()
	- controlModuleObject = Players.LocalPlayer.PlayerScripts.PlayerModule:GetControls()
	- Custom camera scripts installed in PlayerScripts

	Important Concepts:
	- RotationType (Enum): determines whether the character orients relative to camera or movement direction
	- getMoveVector() transforms input based on camera orientation and corrected "up" axis
	- Default camera scripts must be replaced with custom gravity-compatible versions for this to work properly
]]

local Players = game:GetService("Players")

local playerModuleObject =
	require(Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")) :: any
local cameraModuleObject = playerModuleObject:GetCameras() :: any
local controlModuleObject = playerModuleObject:GetControls() :: any

local GravityCamera = {}

-- When the camera is looking straight up/down, the planar forward collapses.
-- Cache the last good one so movement never stalls.
local lastPlanarForward: Vector3 = Vector3.zAxis
local EPS = 1e-4

function GravityCamera.getUpVector(): Vector3
	return cameraModuleObject:GetUpVector()
end

function GravityCamera.setUpVector(target: Vector3)
	cameraModuleObject:SetTargetUpVector(target)
end

function GravityCamera.getSpinPart(): BasePart?
	return cameraModuleObject:GetSpinPart() :: BasePart?
end

function GravityCamera.setSpinPart(part: BasePart)
	cameraModuleObject:SetSpinPart(part)
end

function GravityCamera.getRotationType(): Enum.RotationType
	return cameraModuleObject:GetRotationType()
end

function GravityCamera.getMoveVector(cameraCF: CFrame, inputMove: Vector3?): Vector3
	local moveVector = inputMove or controlModuleObject:GetMoveVector() :: Vector3

	-- Gravity up for the current camera (i.e., local surface normal)
	local up = cameraCF.UpVector

	-- 1) Remove pitch: take the camera's look, strip the component along 'up'
	--    This gives us the yaw-only heading on the gravity plane.
	local flattened = cameraCF.LookVector - up * cameraCF.LookVector:Dot(up)

	local forward: Vector3
	if flattened.Magnitude > EPS then
		forward = flattened.Unit
		lastPlanarForward = forward
	else
		-- Camera is (nearly) parallel to 'up' → reuse last stable forward so we don't stall.
		forward = lastPlanarForward
	end

	-- 2) Build a right vector that’s tangent and with the correct handedness for Roblox WASD
	--    (A = left, D = right). Using forward:Cross(up) keeps A/D correct.
	local right = forward:Cross(up)
	if right.Magnitude <= EPS then
		-- Super edge case: if this ever collapses, rebuild from cached forward.
		right = lastPlanarForward:Cross(up)
	end
	right = right.Unit

	-- 3) Map WASD:
	--    - Roblox moveVector.Z: +1 is S (back), -1 is W (forward)
	--    - So we subtract forward * Z to keep W = forward
	local moveDirection = right * moveVector.X - forward * moveVector.Z

	-- Always return a direction with consistent magnitude relative to the input,
	-- never the (possibly shrunken) projected vector's magnitude.
	if moveDirection.Magnitude > 0 then
		return moveDirection.Unit * moveVector.Magnitude
	end
	return Vector3.zero
end

return GravityCamera
