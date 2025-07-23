--!strict
--[[
        @class GravityVisualizer
        Studio-only helper that visualizes current and target up vectors on the local player.
        Draws green and red arrows from the HumanoidRootPart.
        Toggle with global `_G.WALLSTICK_DEBUG`.
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GravityCamera = require(ReplicatedStorage:WaitForChild("Wallstick"):WaitForChild("GravityCamera"))
local Trove = require(ReplicatedStorage:WaitForChild("SharedPackages"):WaitForChild("Trove"))
local DebugDraw = require(ReplicatedStorage:WaitForChild("Wallstick"):WaitForChild("Debug"):WaitForChild("DebugDraw"))

local LENGTH = 4

local GravityVisualizer = {}
GravityVisualizer.__index = GravityVisualizer

function GravityVisualizer.new()
	if not RunService:IsStudio() then
		return nil
	end
	if not (_G.WALLSTICK_DEBUG == true) then
		return nil
	end

	local self = setmetatable({}, GravityVisualizer)
	self._trove = Trove.new()

	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart
	self._root = root

       local currentArrow = DebugDraw.arrow(workspace.CurrentCamera, CFrame.identity, Color3.fromRGB(0, 255, 0), LENGTH)
       if currentArrow then
               currentArrow.Name = "CurrentUpVector"
               currentArrow.Adornee = root
               self._trove:Add(currentArrow)
               self._currentArrow = currentArrow
       end

       local targetArrow = DebugDraw.arrow(workspace.CurrentCamera, CFrame.identity, Color3.fromRGB(255, 0, 0), LENGTH)
       if targetArrow then
               targetArrow.Name = "TargetUpVector"
               targetArrow.Adornee = root
               self._trove:Add(targetArrow)
               self._targetArrow = targetArrow
       end

	local gui = Instance.new("BillboardGui")
	gui.Name = "GravityInfo"
	gui.Size = UDim2.fromOffset(120, 40)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	gui.AlwaysOnTop = true
	gui.Adornee = root
	gui.Parent = workspace.CurrentCamera
	self._trove:Add(gui)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSans
	label.Parent = gui
	self._label = label

	self._trove:Add(RunService.RenderStepped:Connect(function()
		self:_update()
	end))

	return self
end

function GravityVisualizer:_update()
	local origin = self._root.Position
	local upVector = GravityCamera.getUpVector()
	local targetVector = GravityCamera.getTargetUpVector()

	self._currentArrow.CFrame = CFrame.lookAt(origin, origin + upVector)
	self._currentArrow.Length = LENGTH

	self._targetArrow.CFrame = CFrame.lookAt(origin, origin + targetVector)
	self._targetArrow.Length = LENGTH

       local angle = math.deg(math.acos(math.clamp(upVector:Dot(targetVector), -1, 1)))
       self._label.Text = string.format("|u| %.2f\n∠ %.2f", upVector.Magnitude, angle)
end

function GravityVisualizer:Destroy()
	self._trove:Destroy()
end

return GravityVisualizer
