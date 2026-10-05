-- LocalScript
-- Place in StarterPlayerScripts
-- Intended for a game you control.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local MAX_DISTANCE = 250
local SMOOTHNESS = 0.15

local function getClosestTarget()
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return nil
	end

	local closest
	local closestDistance = MAX_DISTANCE

	for _, other in Players:GetPlayers() do
		if other ~= player and other.Character then
			local humanoid = other.Character:FindFirstChildOfClass("Humanoid")
			local root = other.Character:FindFirstChild("HumanoidRootPart")

			if humanoid and root and humanoid.Health > 0 then
				local distance =
					(root.Position - character.HumanoidRootPart.Position).Magnitude

				if distance < closestDistance then
					closest = root
					closestDistance = distance
				end
			end
		end
	end

	return closest
end

RunService.RenderStepped:Connect(function()
	local target = getClosestTarget()
	if not target then
		return
	end

	local desired = CFrame.lookAt(
		camera.CFrame.Position,
		target.Position
	)

	camera.CFrame = camera.CFrame:Lerp(desired, SMOOTHNESS)
end)