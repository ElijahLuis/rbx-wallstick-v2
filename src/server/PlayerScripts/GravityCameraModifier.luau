--!strict
--[[
	@file GravityCameraModifier.luau
	@within PlayerScripts
	@function cameraObject:Update
	@param dt number

	Modifies the Roblox PlayerModule camera to support spherical gravity environments.

	Responsibilities:
	- Overrides core camera modules (e.g., BaseCamera, Poppercam, VehicleCamera) to align with custom up vectors
	- Applies spherical gravity by calculating interpolated up vectors and twist rotation
	- Ensures stable camera orientation on curved surfaces (e.g., planets)
	- Adds helper functions for tracking and setting gravity direction, rotation rate, and spin reference part

	Dependencies:
	- Assumes standard PlayerModule structure is intact
	- Overrides behavior in: CameraModule, BaseCamera, Poppercam, ZoomController, VehicleCameraCore
	- Uses `CameraUtils` for angle math, rotation type override, and input locking
]]

local UserGameSettings = UserSettings():GetService("UserGameSettings")

local GravityState = {
	transitionRate = 1,
	upCFrame = CFrame.identity,
	upVector = CFrame.identity.YVector,
	targetUpVector = CFrame.identity.YVector,
	twistCFrame = CFrame.identity,
	spinPart = workspace.Terrain,
	prevSpinPart = workspace.Terrain,
	prevSpinCFrame = workspace.Terrain.CFrame,
}

-- Gravity core (internal logic)
local function calculateUpStep(_dt: number)
	if not workspace.CurrentCamera then
		return
	end
	local axis = workspace.CurrentCamera.CFrame.RightVector

	local sphericalArc = fromToRotation(GravityState.upVector, GravityState.targetUpVector, axis)
	local transitionCF = CFrame.new():Lerp(sphericalArc, GravityState.transitionRate)

	GravityState.upVector = transitionCF * GravityState.upVector
	GravityState.upCFrame = transitionCF * GravityState.upCFrame
end

local function calculateSpinStep(_dt: number, inVehicle: boolean)
	local theta = 0

	if inVehicle then
		theta = 0
	elseif GravityState.spinPart == GravityState.prevSpinPart then
		local rotation = GravityState.spinPart.CFrame.Rotation
		local prevRotation = GravityState.prevSpinCFrame.Rotation

		local delta = prevRotation:ToObjectSpace(rotation)
		local spinAxis = delta:VectorToObjectSpace(prevRotation:VectorToObjectSpace(GravityState.upVector))

		local _swing, twist = swingTwist(delta, spinAxis)
		local deltaAxis, _deltaTheta = delta:ToAxisAngle()
		local _twistAxis, twistTheta = twist:ToAxisAngle()

		theta = math.sign(deltaAxis:Dot(spinAxis)) * twistTheta
	end

	GravityState.twistCFrame = CFrame.fromEulerAnglesYXZ(0, theta, 0)

	GravityState.prevSpinPart = GravityState.spinPart
	GravityState.prevSpinCFrame = GravityState.spinPart.CFrame
end

-- Utility (math support)
local function fromToRotation(from: Vector3, to: Vector3, backupUnitAxis: Vector3?)
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

local function swingTwist(inputCF: CFrame, relativeUnitAxis: Vector3)
	local axis, theta = inputCF:ToAxisAngle()
	local w, v = math.cos(theta / 2), math.sin(theta / 2) * axis

	local proj = v:Dot(relativeUnitAxis) * relativeUnitAxis
	local twist = CFrame.new(0, 0, 0, proj.X, proj.Y, proj.Z, w)

	local swing = inputCF * twist:Inverse()

	return swing, twist
end

return function(PlayerModule: any)
	------------
	local cameraUtils = require(PlayerModule.CameraModule.CameraUtils) :: any

	function cameraUtils.GetAngleBetweenXZVectors(v1: Vector3, v2: Vector3): number
		v1 = GravityState.upCFrame:VectorToObjectSpace(v1)
		v2 = GravityState.upCFrame:VectorToObjectSpace(v2)

		return math.atan2(v2.X * v1.Z - v2.Z * v1.X, v2.X * v1.X + v2.Z * v1.Z)
	end

	local currentRotationType = UserGameSettings.RotationType
	local unmodifiedSetRotationTypeOverride = cameraUtils.setRotationTypeOverride
	function cameraUtils.setRotationTypeOverride(...)
		unmodifiedSetRotationTypeOverride(...)
		currentRotationType = UserGameSettings.RotationType
		UserGameSettings.RotationType = Enum.RotationType.MovementRelative
	end

	local unmodifiedRestoreRotationType = cameraUtils.restoreRotationType
	function cameraUtils.restoreRotationType(...)
		unmodifiedRestoreRotationType(...)
		currentRotationType = UserGameSettings.RotationType
		UserGameSettings.RotationType = Enum.RotationType.MovementRelative
	end

	------------
	local poppercam = require(PlayerModule.CameraModule.Poppercam) :: any
	local zoomController = require(PlayerModule.CameraModule.ZoomController) :: any

	function poppercam:Update(
		renderDt: number,
		desiredCameraCFrame: CFrame,
		desiredCameraFocus: CFrame,
		_cameraController: any
	)
		local rotatedFocus = desiredCameraFocus * (desiredCameraCFrame - desiredCameraCFrame.Position)
		local extrapolation = self.focusExtrapolator:Step(renderDt, rotatedFocus)
		local zoom = zoomController.Update(renderDt, rotatedFocus, extrapolation)
		return rotatedFocus * CFrame.new(0, 0, zoom), desiredCameraFocus
	end

	------------
	local baseCamera = require(PlayerModule.CameraModule.BaseCamera) :: any

	local max_y = math.rad(80)
	local min_y = math.rad(-80)

	function baseCamera:CalculateNewLookCFrameFromArg(suppliedLookVector: Vector3?, rotateInput: Vector2): CFrame
		local currLookVector: Vector3 = suppliedLookVector or self:GetCameraLookVector()
		currLookVector = GravityState.upCFrame:VectorToObjectSpace(currLookVector)

		local currPitchAngle = math.asin(currLookVector.Y)
		local yTheta = math.clamp(rotateInput.Y, -max_y + currPitchAngle, -min_y + currPitchAngle)
		local constrainedRotateInput = Vector2.new(rotateInput.X, yTheta)
		local startCFrame = CFrame.new(Vector3.zero, currLookVector)
		local newLookCFrame = CFrame.Angles(0, -constrainedRotateInput.X, 0)
			* startCFrame
			* CFrame.Angles(-constrainedRotateInput.Y, 0, 0)

		return newLookCFrame
	end

	------------
	local vehicleCameraCore = require(PlayerModule.CameraModule.VehicleCamera.VehicleCameraCore) :: any
	local setTransform = vehicleCameraCore.setTransform

	function vehicleCameraCore:setTransform(transform: CFrame)
		transform = GravityState.upCFrame:ToObjectSpace(transform.Rotation) + transform.Position
		return setTransform(self, transform)
	end

	-- Gravity Camera API --

	local cameraObject = require(PlayerModule.CameraModule) :: any

	function cameraObject:GetUpVector(): Vector3
		return GravityState.upVector
	end

	function cameraObject:GetTargetUpVector(): Vector3
		return GravityState.targetUpVector
	end

	function cameraObject:SetTargetUpVector(target: Vector3)
		GravityState.targetUpVector = target
	end

	function cameraObject:GetSpinPart(): BasePart
		return GravityState.spinPart
	end

	function cameraObject:SetSpinPart(part: BasePart)
		GravityState.spinPart = part
	end

	function cameraObject:GetTransitionRate(): number
		return GravityState.transitionRate
	end

	function cameraObject:SetTransitionRate(rate: number)
		GravityState.transitionRate = math.clamp(rate, 0, 1)
	end

	function cameraObject:GetRotationType(): Enum.RotationType
		return currentRotationType
	end

	-- Gravity Camera Core Loop
	local cameraInput = require(PlayerModule.CameraModule.CameraInput) :: any

	function cameraObject:Update(dt: number)
		if not self.activeCameraController then
			return
		end

		self.activeCameraController:UpdateMouseBehavior()

		local newCameraCFrame, newCameraFocus = self.activeCameraController:Update(dt)
		local isMouseLocked = self.activeCameraController:GetIsMouseLocked()
		local lockOffset = isMouseLocked and self.activeCameraController:GetMouseLockOffset() or Vector3.zero

		-- Update gravity-based orientation
		calculateUpStep(dt)
		calculateSpinStep(dt, self:ShouldUseVehicleCamera())

		-- Reconstruct camera CFrame with spherical alignment
		local fixedCameraFocus = CFrame.new(newCameraFocus.Position)
		local camRotation = GravityState.upCFrame
			* GravityState.twistCFrame
			* fixedCameraFocus:ToObjectSpace(newCameraCFrame)

		local adjustedLockOffset = -newCameraCFrame:VectorToWorldSpace(lockOffset)
			+ camRotation:VectorToWorldSpace(lockOffset)

		newCameraFocus = fixedCameraFocus + adjustedLockOffset
		newCameraCFrame = newCameraFocus * camRotation

		-- Occlusion module (optional post-processing)
		if self.activeOcclusionModule then
			newCameraCFrame, newCameraFocus = self.activeOcclusionModule:Update(dt, newCameraCFrame, newCameraFocus)
		end

		-- Apply final camera transform
		local currentCamera = workspace.CurrentCamera :: Camera
		if not currentCamera then
			task.spawn(function()
				while not workspace.CurrentCamera do
					task.wait()
				end
				workspace.CurrentCamera.CFrame = newCameraCFrame
				workspace.CurrentCamera.Focus = newCameraFocus
			end)
			return
		end
		currentCamera.CFrame = newCameraCFrame
		currentCamera.Focus = newCameraFocus

		-- Sync controller state with new camera transform
		self.activeCameraController.lastCameraTransform = newCameraCFrame
		self.activeCameraController.lastCameraFocus = newCameraFocus

		-- Transparency update based on new camera distance
		if self.activeTransparencyController then
			self.activeTransparencyController:Update(dt)
		end

		-- Reset camera input
		if cameraInput.getInputEnabled() then
			cameraInput.resetInputForFrameEnd()
		end
	end
end
