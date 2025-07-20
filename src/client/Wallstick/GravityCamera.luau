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

	-- Extract rotation matrix components from camera's CFrame
	local _, _, _, 
		rightX, rightY, rightZ, -- Right vector
		_, upY, upZ, -- Up vector (partial)
		_, _, lookZ -- Look vector (partial)
		= cameraCF:GetComponents()

	-- Determine quadrant flip based on upY sign (typically 1 or -1)
	local quadrantSign = math.sign(upY)

	-- Choose basis vectors based on camera tilt, protecting against gimbal lock when looking straight up/down (upZ = ±1)
	local cameraRight, cameraForward
	if upZ > -1 and upZ < 1 then
		-- Normal orientation: use camera's forward and right
		cameraForward = lookZ  -- Z axis
		cameraRight = rightZ   -- X axis, but projected
	else
		-- Extreme tilt: fallback to horizontal plane projection
		cameraForward = rightX
		cameraRight = -rightY * math.sign(upZ)
	end

	-- Normalize combined influence of forward and right axes
	local magnitude = math.sqrt(cameraForward * cameraForward + cameraRight * cameraRight)
	local normForward = cameraForward / magnitude
	local normRight = cameraRight / magnitude

	-- Project input move direction onto custom basis
	local worldX = (normForward * moveVector.X * quadrantSign + normRight * moveVector.Z)
	local worldZ = (normForward * moveVector.Z - normRight * moveVector.X * quadrantSign)

	return Vector3.new(worldX, 0, worldZ)
end

return GravityCamera
