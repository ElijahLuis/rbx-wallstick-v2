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
	local up = cameraCF.UpVector

	-- Get yaw-only LookVector by flattening onto XZ and projecting onto gravity plane
	local flatLook = Vector3.new(cameraCF.LookVector.X, 0, cameraCF.LookVector.Z)
	if flatLook.Magnitude < 1e-4 then
		flatLook = Vector3.zAxis -- Fallback for looking straight up/down
	end

	-- Project onto gravity-defined surface plane
	local forward = (flatLook - up * flatLook:Dot(up)).Unit
	local right = forward:Cross(up) -- Correct handedness for A/D

	-- Roblox input: Z+ is back (S), Z– is forward (W), so we negate forward
	local moveDirection = right * moveVector.X - forward * moveVector.Z

	return if moveDirection.Magnitude > 0 then moveDirection.Unit * moveVector.Magnitude else Vector3.zero
end

return GravityCamera
