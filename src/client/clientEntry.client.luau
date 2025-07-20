--!strict
--[[
	@file clientEntry.client.luau

	Client bootstrap script for Wallstick character support.

	Responsibilities:
	- Initializes WallstickClass and binds it to the player's character
	- Performs local raycasting to detect surfaces and apply wall-sticking logic
	- Applies camera tilt/spin (if enabled) during surface transitions
	- Uses a fallback to reset to terrain if falling too far
	- Disconnects and cleans up Wallstick when the character dies

	Requires:
	- Wallstick module in ReplicatedStorage
	- RaycastHelper module in SharedPackages
	- Workspace must not have StreamingEnabled
	- Expects `workspace:WaitForChild("Wallstick")` container for attachment parts
]]

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedPackages = ReplicatedStorage.SharedPackages
local RaycastHelper = require(SharedPackages.RaycastHelper)
local WallstickClass = require(ReplicatedStorage.Wallstick)
local Replication = require(ReplicatedStorage.Wallstick.Replication)

-- Excludes parts belonging to player's limbs and accessories
local function ignoreCharacterParts(result: RaycastResult): boolean
	local hit = result.Instance :: BasePart
	local accessory = hit:FindFirstAncestorWhichIsA("Accessory")
	local character = (accessory or hit).Parent
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")

	if character and humanoid then
		local isLimb = humanoid:GetLimb(hit) ~= Enum.Limb.Unknown
		return not (accessory or isLimb)
	end

	return true
end

-- Called on character spawn
local function onCharacterAdded(character: Model)
	local wallstick = WallstickClass.new({
		parent = workspace:WaitForChild("Wallstick"),
		origin = CFrame.new(2000, 0, 0),
		retainWorldVelocity = true,
		camera = {
			tilt = true,
			spin = true,
		},
	})

	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	if not humanoid.RootPart then
		return
	end
	local hrp = humanoid.RootPart :: BasePart

	local rayParams = RaycastHelper.params({
		filterType = Enum.RaycastFilterType.Exclude,
		instances = { character },
	})

	local simulationConnection = RunService.PreSimulation:Connect(function(_dt)
		-- failsafe: if falling too far (into the void), reset to terrain
		if wallstick:getFallDistance() < -50 then
			wallstick:set(workspace.Terrain, Vector3.yAxis)
			return
		end

		-- adjust raycast based on rig type
		local hipHeight = (humanoid.RigType == Enum.HumanoidRigType.R6) and 2 or humanoid.HipHeight
		local hrpCF = hrp.CFrame

		local result = RaycastHelper.raycast({
			origin = hrpCF.Position,
			direction = -(hipHeight + hrp.Size.Y / 2 + 0.1) * hrpCF.YVector,
			filter = ignoreCharacterParts,
			rayParams = rayParams,
		})

		if result then
			local stickPart = (result.Instance :: BasePart).AssemblyRootPart
			local stickNormal = stickPart.CFrame:VectorToObjectSpace(result.Normal)

			wallstick:setAndPivot(stickPart, stickNormal, result.Position)
		end
	end)

	humanoid.Died:Wait()
	simulationConnection:Disconnect()
	wallstick:Destroy()
end

-- Runtime checks
assert(
	not workspace.StreamingEnabled,
	"Wallstick does not support StreamingEnabled. Please disable it in Workspace properties."
)

-- Handle current and new players
if localPlayer.Character then
	onCharacterAdded(localPlayer.Character)
end

localPlayer.CharacterAdded:Connect(onCharacterAdded)

Replication.listenClient()
