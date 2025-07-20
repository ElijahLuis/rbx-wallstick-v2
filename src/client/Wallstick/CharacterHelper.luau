--!strict
-- Utility module that constructs and packages both real and fake character models for wall-sticking.
-- Adds physics-based control via AlignPosition and AlignOrientation, and manages collision groups and animation syncing.

local Players = game:GetService("Players")
local PlayerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts")
local RbxCharacterSounds = PlayerScripts:WaitForChild("RbxCharacterSounds")
local CharacterSoundsController = require(RbxCharacterSounds:WaitForChild("Controller")) :: any

local STRIP_CLASSES: { [string]: boolean } = {
	["Part"] = true,
	["MeshPart"] = true,
	["Motor6D"] = true,
	["Humanoid"] = true,
	["Attachment"] = true,
	["Decal"] = true,
}

export type WallstickCharacterState = "Freefall" | "Anchored" | "Rebounding" | "Transitioning"

-- Enum-like table describing wall-stick states
local WallstickCharacterState = {
	Freefall = "Freefall",
	Anchored = "Anchored",
	Rebounding = "Rebounding",
	Transitioning = "Transitioning",
}

local characterDataByPlayer: { [Player]: { state: WallstickCharacterState } } = {}

type BaseCharacter = {
	character: Model,
	rootPart: BasePart,
	humanoid: Humanoid,
}

export type RealCharacter = BaseCharacter & {
	alignPosition: AlignPosition,
	alignOrientation: AlignOrientation,
}

export type FakeCharacter = BaseCharacter & {
	alignOrientation: AlignOrientation,
}

local CharacterHelper = {}

-- Private --

function CharacterHelper.getData(player: Player)
	local data = characterDataByPlayer[player]
	if not data then
		data = { state = WallstickCharacterState.Freefall }
		characterDataByPlayer[player] = data
	end
	return data
end

function CharacterHelper.getState(player: Player): WallstickCharacterState
	return CharacterHelper.getData(player).state
end

function CharacterHelper.setState(player: Player, newState: WallstickCharacterState?)
	if not newState or not (WallstickCharacterState :: any)[newState] then
		newState = WallstickCharacterState.Freefall
	end

	local data = CharacterHelper.getData(player)
	if data.state ~= newState then
		print(`[Wallstick] {player.Name} state: {data.state} -> {newState}`)
		data.state = newState
	end
end

local function getCharacter(player: Player): Model?
	local character = player.Character
	local humanoid = character and character:WaitForChild("Humanoid")
	local root = humanoid and (humanoid :: Humanoid).RootPart

	if character and humanoid and root then
		return character
	end

	return nil
end

local function stripCopy(character: Model): Model
	local copy = nil
	local archivable = character.Archivable

	character.Archivable = true
	copy = character:Clone()
	character.Archivable = archivable

	for _, part in copy:GetDescendants() do
		if not STRIP_CLASSES[part.ClassName] then
			part:Destroy()
		elseif part:IsA("BasePart") then
			part.Transparency = 1
		end
	end

	local humanoid = copy:WaitForChild("Humanoid") :: Humanoid
	humanoid:ClearAllChildren()
	humanoid.MaxHealth = math.huge
	humanoid.Health = math.huge
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

	return copy
end

local function createFakeCharacter(player: Player): Model?
	local character = getCharacter(player)
	if not character then
		return nil
	end
	local copy = stripCopy(character)
	CharacterHelper.applyCollisionGroup(copy, "WallstickCollision")
	return copy
end

local function packageCharacter(character: Model?)
	local humanoid = character and character:FindFirstChild("Humanoid") :: Humanoid?
	local rootPart = humanoid and humanoid.RootPart

	assert(character and humanoid and rootPart, "Failed to package character.")

	return {
		character = character,
		humanoid = humanoid,
		rootPart = rootPart,
	}
end

local function applyAlignments(root: BasePart, attach: Attachment, includePosition: boolean)
	local alignments = {}

	if includePosition then
		local alignPosition = Instance.new("AlignPosition")
		alignPosition.Enabled = true
		alignPosition.MaxVelocity = 10_000_000
		alignPosition.Responsiveness = 200
		alignPosition.Position = Vector3.zero
		alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
		alignPosition.Attachment0 = attach
		alignPosition.Parent = root

		alignments.alignPosition = alignPosition
	end

	local alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Enabled = includePosition -- disable for fake
	alignOrientation.MaxTorque = 10_000_000
	alignOrientation.Responsiveness = 200
	alignOrientation.CFrame = CFrame.identity
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.Attachment0 = attach
	alignOrientation.Parent = root

	alignments.alignOrientation = alignOrientation

	return alignments
end

-- Public --

function CharacterHelper.applyCollisionGroup(character: Model, collisionGroup: string)
	local prevGroup = {}
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then
			prevGroup[part] = part.CollisionGroup
			part.CollisionGroup = collisionGroup
		end
	end

	return function()
		for part, group in prevGroup do
			part.CollisionGroup = group
		end
	end
end

-- Builds the real player character with full control. Includes AlignPosition/AlignOrientation for full wallstick movement.
function CharacterHelper.real(player: Player): RealCharacter
	local character = getCharacter(player)
	local packaged = packageCharacter(character) :: RealCharacter

	local rootAttach = packaged.rootPart:WaitForChild("RootAttachment") :: Attachment
	local alignments = applyAlignments(packaged.rootPart, rootAttach, true)

	packaged.alignPosition = alignments.alignPosition
	packaged.alignOrientation = alignments.alignOrientation

	return packaged
end

-- Builds invisible fake character for animation syncing or ghosting. Only AlignOrientation is applied, with position disabled.
function CharacterHelper.fake(player: Player): FakeCharacter
	local character = createFakeCharacter(player)
	local packaged = packageCharacter(character) :: FakeCharacter

	local rootAttach = packaged.rootPart:WaitForChild("RootAttachment") :: Attachment
	local alignments = applyAlignments(packaged.rootPart, rootAttach, false)

	packaged.alignOrientation = alignments.alignOrientation

	return packaged
end

function CharacterHelper.setMyPerformer(real: Model, fake: Model?)
	CharacterSoundsController.setPerformer(Players.LocalPlayer, fake)

	local animate = real:WaitForChild("Animate")
	local animateController = require(animate:WaitForChild("Controller")) :: any

	local humanoid = if fake then fake:WaitForChild("Humanoid") else real:WaitForChild("Humanoid")
	animateController.matchAnimate(humanoid)
end

-- Utility: prints all descendants of a character model for debugging purposes
--[[
function CharacterHelper.debug(character: Model)
        print("Character Debug:", character:GetFullName())
        for _, desc in character:GetDescendants() do
                print(`[{desc.ClassName}] {desc:GetFullName()}`)
        end
end
]]

CharacterHelper.WallstickCharacterState = WallstickCharacterState

return CharacterHelper
