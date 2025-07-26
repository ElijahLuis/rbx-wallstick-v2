--!strict
--[[
    @module CharacterRig
    Provides utilities to detect a character's rig type and expose
    rig-specific information through a profile table. This abstracts
    away R6 vs R15 differences so Wallstick can operate on either rig.
]]

export type RigProfile = {
	rigType: "R6" | "R15",
	jointsToReplicate: { [string]: Motor6D }?,
	rootPartName: string,
	torsoName: string,
	limbNames: { string },
	getRootCFrame: (character: Model) -> CFrame,
	getHipHeight: (humanoid: Humanoid) -> number,
}

local CharacterRig = {}

local function defaultHipHeight(humanoid: Humanoid): number
	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		-- Roblox documentation notes R6 has a fixed hip height of ~2
		return 2
	end
	return humanoid.HipHeight
end

function CharacterRig.detectRig(character: Model): RigProfile
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rigTypeEnum = humanoid and humanoid.RigType or Enum.HumanoidRigType.R15
	local rigType = if rigTypeEnum == Enum.HumanoidRigType.R6 then "R6" else "R15"

	local rootPartName = "HumanoidRootPart"
	local torsoName = if rigType == "R6" then "Torso" else "UpperTorso"

	local limbNames = if rigType == "R6" then { "Head", "Torso" } else { "Head", "UpperTorso", "LowerTorso" }

	local jointsToReplicate: { [string]: Motor6D } = {}
	local root = character:FindFirstChild(rootPartName) :: BasePart?
	if root then
		for _, child in root:GetChildren() do
			if child:IsA("Motor6D") and child.Part1 then
				if table.find(limbNames, child.Part1.Name) then
					jointsToReplicate[child.Part1.Name] = child
				end
			end
		end
	end

	local function getRootCFrame(char: Model): CFrame
		local rootPart = char:FindFirstChild(rootPartName)
		if rootPart and rootPart:IsA("BasePart") then
			return rootPart.CFrame
		end
		return CFrame.identity
	end

	return {
		rigType = rigType,
		jointsToReplicate = jointsToReplicate,
		rootPartName = rootPartName,
		torsoName = torsoName,
		limbNames = limbNames,
		getRootCFrame = getRootCFrame,
		getHipHeight = if humanoid
			then defaultHipHeight
			else function()
				return 2
			end,
	}
end

return CharacterRig
