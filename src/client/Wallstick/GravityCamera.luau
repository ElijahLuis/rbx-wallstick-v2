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

-- stylua: ignore
function GravityCamera.getMoveVector(cameraCF: CFrame, inputMove: Vector3?): Vector3
       local moveVector = inputMove or controlModuleObject:GetMoveVector() :: Vector3

       -- Project camera look vector onto the plane defined by the camera's up vector
       local forward = (cameraCF.LookVector - cameraCF.UpVector * cameraCF.LookVector:Dot(cameraCF.UpVector)).Unit

       -- Right vector is orthogonal to both forward and up
       local right = forward:Cross(cameraCF.UpVector)

       -- Combine right/forward basis with input move vector
       return right * moveVector.X + forward * moveVector.Z
end

return GravityCamera
