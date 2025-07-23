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
    Draws an arrow relative to the given adornee part.
    @param adorneePart BasePart that the adornment attaches to
    @param localCFrame CFrame relative to the part for the arrow's origin and direction
    @param color Color3 of the arrow
    @param length Optional length; defaults to 1
    @param timeToLive Optional seconds before automatic removal
    @return ArrowHandleAdornment?
]]
function DebugDraw.arrow(adorneePart: BasePart, localCFrame: CFrame, color: Color3, length: number?, timeToLive: number?)
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

    local offsetVec = Vector3.zero
    local camera = Workspace.CurrentCamera
    if camera then
        local worldOffset = camera.CFrame.RightVector * OFFSET_STEP * index
        offsetVec = adorneePart.CFrame:VectorToObjectSpace(worldOffset)
    end

    arrow.CFrame = localCFrame + offsetVec
    arrow.Adornee = adorneePart
    arrow.Parent = adorneePart

    if timeToLive then
        Debris:AddItem(arrow, timeToLive)
    end

    return arrow
end

--[[
    Draws an arrow from an origin and direction vector.
    Automatically attaches to the closest planet in `workspace.Planets`.
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

    local planetsFolder = Workspace:FindFirstChild("Planets")
    local closestPart: BasePart? = nil
    local closestDist = math.huge
    if planetsFolder then
        for _, obj in ipairs(planetsFolder:GetChildren()) do
            if obj:IsA("BasePart") then
                local dist = (obj.Position - origin).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestPart = obj
                end
            end
        end
    end
    if not closestPart then
        return nil
    end

    local len = direction.Magnitude * (scale or 1)
    local worldCF = CFrame.lookAt(origin, origin + direction)
    local localCF = closestPart.CFrame:ToObjectSpace(worldCF)

    return DebugDraw.arrow(closestPart, localCF, color, len, timeToLive)
end

return DebugDraw
