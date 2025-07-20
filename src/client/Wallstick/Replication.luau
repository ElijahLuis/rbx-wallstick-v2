--!strict
--[[
	@module Replication

	Handles networked positional syncing of characters across clients and server.
	Used to replicate player positions relative to custom surfaces (e.g. walls, ceilings).

	Uses:
	- `TypedRemote` package to provide type-safe remote events/functions
	- Lerp smoothing to reduce jitter during character replication
	- `REPLICATE_DEBOUNCE_TIME` to throttle updates

	Client Responsibilities:
	- `send(part, offset)`: Sends replication data to server
	- `listenClient()`: Listens for updates from server and adds remote character positions

	Server Responsibilities:
	- `listenServer()`: Listens for client updates and broadcasts to all clients

	Types:
	- ReplicationFrame = { part: BasePart, offset: CFrame }
	- ClientReplicationFrame adds: fromOffset, lerpOffset, receivedAt

	Usage:
	- Client: call `Replication.send(...)` when position changes
	- Server: call `Replication.listenServer()` once on boot
	- Client: call `Replication.listenClient()` once on boot

	Note:
	- The actual replicated position is: `frame.part.CFrame * frame.lerpOffset`
	- Replication only happens if `Replication.ENABLED = true` (line 53)
]]

local Players = game:GetService("Players") :: Players
local RunService = game:GetService("RunService") :: RunService
local TweenService = game:GetService("TweenService") :: TweenService
local TypedRemote = require(game.ReplicatedStorage.SharedPackages.TypedRemote)
local Replication = {}

type ReplicationFrame = {
	part: BasePart,
	offset: CFrame,
}

type ClientReplicationFrame = ReplicationFrame & {
	fromOffset: CFrame,
	lerpOffset: CFrame,
	receivedAt: number,
}

local syncRemote = TypedRemote.func("SyncRemote", script) :: TypedRemote.Function<(), ({ [Player]: ReplicationFrame })>
local replicatorRemote = TypedRemote.event("ReplicatorRemote", script) :: TypedRemote.Event<BasePart?, CFrame?, Player?>
Replication.ENABLED = true
Replication.REPLICATE_DEBOUNCE_TIME = 0.2

function Replication.send(part: BasePart, offset: CFrame)
	assert(RunService:IsClient(), "This API can only be called from the client.")
	if Replication.ENABLED then
		replicatorRemote:FireServer(part, offset)
	end
end

function Replication.listenServer()
	assert(RunService:IsServer(), "This API can only be called from the server.")

	if not Replication.ENABLED then
		return
	end

	local framesByPlayer: { [Player]: ReplicationFrame } = {}

	Players.PlayerRemoving:Connect(function(player)
		framesByPlayer[player] = nil
		replicatorRemote:FireAllClients(nil, nil, player)
	end)

	replicatorRemote.OnServerEvent:Connect(function(player, part, offset)
		if part and offset then
			framesByPlayer[player] = {
				part = part,
				offset = offset,
			}
		else
			framesByPlayer[player] = nil
		end

		replicatorRemote:FireAllClients(part, offset, player)
	end)

	syncRemote.OnServerInvoke = function(_player)
		return framesByPlayer
	end
end

local function getReplicableParts(character: Model): { BasePart }
	local parts: { BasePart } = {}

	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.Name ~= "Head" then
			table.insert(parts, descendant)
		end
	end

	return parts
end

function Replication.listenClient()
	assert(RunService:IsClient(), "This API can only be called from the client.")

	if not Replication.ENABLED then
		return
	end

	task.spawn(function()
		local clientFrameByPlayer: { [Player]: ClientReplicationFrame } = {}
		local partCacheByPlayer: { [Player]: { BasePart } } = {}

		for player, frame in syncRemote:InvokeServer() do
			clientFrameByPlayer[player] = {
				part = frame.part,
				offset = frame.offset,
				fromOffset = frame.offset,
				lerpOffset = frame.offset,
				receivedAt = os.clock(),
			}
		end

		replicatorRemote.OnClientEvent:Connect(function(part, offset, sentPlayer)
			local player = sentPlayer :: Player

			if part and offset then
				local now = os.clock()
				local frame: ClientReplicationFrame = clientFrameByPlayer[player]
					or {
						part = part,
						offset = offset,
						fromOffset = offset,
						lerpOffset = offset,
						receivedAt = now,
					}

				local worldCF = frame.part.CFrame * frame.lerpOffset
				local fromOffset = part.CFrame:ToObjectSpace(worldCF)

				clientFrameByPlayer[player] = {
					part = part,
					offset = offset,
					fromOffset = fromOffset,
					lerpOffset = fromOffset,
					receivedAt = now,
				}
			else
				clientFrameByPlayer[player] = nil
				partCacheByPlayer[player] = nil
			end
		end)

		RunService.PreRender:Connect(function(_dt)
			local now = os.clock()
			for player, frame in clientFrameByPlayer do
				if player == Players.LocalPlayer then
					continue
				end

				local character = player.Character
				if not character or not frame.part then
					continue
				end

				local parts = partCacheByPlayer[player]
				if not parts then
					parts = getReplicableParts(character)
					partCacheByPlayer[player] = parts
				end

				local targetCF = frame.part.CFrame * frame.lerpOffset

				for _, part in parts do
					if part:IsDescendantOf(character) then
						part.CFrame = targetCF
						part.Anchored = true
					end
				end

				local dt = now - frame.receivedAt
				local alpha = TweenService:GetValue(
					math.min(1, dt / Replication.REPLICATE_DEBOUNCE_TIME),
					Enum.EasingStyle.Linear,
					Enum.EasingDirection.Out
				)

				frame.lerpOffset = frame.fromOffset:Lerp(frame.offset, alpha)
			end
		end)
	end)
end

return Replication
