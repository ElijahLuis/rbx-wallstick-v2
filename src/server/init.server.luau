--!strict
--[[
	@file init.server.luau
	@within Server

	Initializes Wallstick server-side environment and collision groups.

	Responsibilities:
	- Sets up custom collision groups used for wall-sticking behavior
	- Initializes Wallstick folder in Workspace to store runtime objects
	- Bootstraps PlayerScripts (for custom camera and character behavior)
	- Starts Replication listener for server-to-client updates

	Dependencies:
	- Requires PlayerScripts module (for patching client-side behavior)
	- Requires Replication module (for handling server communication)
	- Assumes ReplicatedStorage.Wallstick.Replication exists
]]

local PhysicsService = game:GetService("PhysicsService") :: PhysicsService

local PlayerScripts = require(script.PlayerScripts)
local Replication = require(game.ReplicatedStorage.Wallstick.Replication)

-- Helpers
local function tryRegisterCollisionGroup(name: string)
	pcall(function()
		PhysicsService:RegisterCollisionGroup(name)
	end)
end

local function setupCollisions()
	tryRegisterCollisionGroup("WallstickCollision")
	tryRegisterCollisionGroup("WallstickNoCollision")

	for _, group in PhysicsService:GetRegisteredCollisionGroups() do
		PhysicsService:CollisionGroupSetCollidable(group.name, "WallstickCollision", false)
		PhysicsService:CollisionGroupSetCollidable(group.name, "WallstickNoCollision", false)
	end

	PhysicsService:CollisionGroupSetCollidable("WallstickCollision", "WallstickCollision", true)
end

-- Kicks off server-side setup for Wallstick system
local function initialize()
	PlayerScripts.setup()
	setupCollisions()

	local wallstickFolder = Instance.new("Folder")
	wallstickFolder.Name = "Wallstick"
	wallstickFolder.Parent = workspace

	local Replication = require(game.ReplicatedStorage:WaitForChild("Wallstick"):WaitForChild("Replication"))
	Replication.listenServer()
end

initialize()
