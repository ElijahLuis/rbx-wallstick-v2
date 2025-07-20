--!strict
--[[
	@file init.luau
	@within PlayerScripts

	Initializes custom player and character script overrides.

	Responsibilities:
	- Clones and renames CharacterSounds module (RbxCharacterSounds)
	- Replaces default Animate script with a custom version
	- Injects GravityCameraModifier into the patched PlayerModule
	- Uses PlayerModulePackage.replace to override the default PlayerModule at runtime

	Dependencies:
	- Assumes GravityCameraModifier, Animate, and CharacterSounds modules are siblings in this folder
	- Requires PlayerModulePackage (in ServerPackages) to support camera patching
]]

local StarterPlayer = game:GetService("StarterPlayer")
local ServerScriptService = game:GetService("ServerScriptService")

local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
local StarterCharacterScripts = StarterPlayer:WaitForChild("StarterCharacterScripts")

local ServerPackages = ServerScriptService.ServerPackages
local PlayerModulePackage = require(ServerPackages.PlayerModule)

local ScriptOverrides = {}

function ScriptOverrides.setup()
	-- Replaces instance in parent folder if one with the same name already exists
	local function replaceIfExists(parent: Instance, instance: Instance)
		local found = parent:FindFirstChild(instance.Name)
		if found then
			found:Destroy()
		end
		instance.Parent = parent
	end

	-- Clone and patch the PlayerModule
	local patched = PlayerModulePackage.getCopy(true)
	local modifiers = require(patched:WaitForChild("Modifiers")) :: any
	modifiers.add(script:WaitForChild("GravityCameraModifier"))
	PlayerModulePackage.replace(patched)

	-- Rename CharacterSounds to avoid conflicts with Roblox loader
	local renamedCharacterSounds = script:WaitForChild("CharacterSounds"):Clone()
	renamedCharacterSounds.Name = "RbxCharacterSounds"

	-- Apply overrides to character and player script containers
	replaceIfExists(StarterCharacterScripts, script:WaitForChild("Animate"):Clone())
	replaceIfExists(StarterPlayerScripts, renamedCharacterSounds)
end

return ScriptOverrides
