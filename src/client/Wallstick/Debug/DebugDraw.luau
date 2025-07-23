--!strict
--[[
    @class DebugDraw
    Utility helpers for visualizing vectors in Studio using ArrowHandleAdornment.
    Arrows respect ZIndex ordering and can auto-cleanup after a time to live.
]]

local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local OFFSET_STEP = 0.05
local nextZIndex = 0

local DebugDraw = {}

--[[
    Draws an arrow at the given world CFrame.
    @param parent Instance to parent the adornment to (e.g. workspace.CurrentCamera)
    @param cframe World-space CFrame for the arrow's origin and direction
    @param color Color3 of the arrow
    @param length Optional length; defaults to 1
    @param timeToLive Optional seconds before automatic removal
    @return ArrowHandleAdornment?
]]
function DebugDraw.arrow(parent: Instance, cframe: CFrame, color: Color3, length: number?, timeToLive: number?)
    if not RunService:IsStudio() then
        return nil
    end

    local index = nextZIndex
    nextZIndex += 1

    local arrow = Instance.new("ArrowHandleAdornment")
    arrow.AlwaysOnTop = true
    arrow.Thickness = 0.1
    arrow.Color3 = color
    arrow.Length = length or 1
    arrow.ZIndex = index

    local camera = Workspace.CurrentCamera
    local offset = camera and camera.CFrame.RightVector * OFFSET_STEP * index or Vector3.zero
    arrow.CFrame = cframe + offset

    arrow.Parent = parent

    if timeToLive then
        Debris:AddItem(arrow, timeToLive)
    end

    return arrow
end

--[[
    Draws an arrow from an origin and direction vector.
    @param origin World position
    @param direction Vector pointing toward arrow end
    @param color Color of the arrow
    @param scale Optional scale multiplier for direction length (default 1)
    @param timeToLive Optional seconds before automatic removal
    @return ArrowHandleAdornment?
]]
function DebugDraw.arrowFromVector(origin: Vector3, direction: Vector3, color: Color3, scale: number?, timeToLive: number?)
    if direction.Magnitude == 0 then
        return nil
    end
    local len = direction.Magnitude * (scale or 1)
    local cf = CFrame.lookAt(origin, origin + direction)
    return DebugDraw.arrow(Workspace.CurrentCamera, cf, color, len, timeToLive)
end

return DebugDraw
