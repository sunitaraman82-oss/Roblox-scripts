-- Fair Mobile Aim Assist
-- Put this in a LocalScript inside StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local config = {
	enabled = true,

	-- mobile fire button / aim assist trigger
	fireActionName = "FireWeapon",
	aimAssistEnabled = true,

	maxRange = 220,
	maxAngle = math.rad(28),
	assistStrength = 0.18,
	smoothness = 0.15,
	aimOffsetY = 1.4,

	targetPartName = "HumanoidRootPart",
}

local isFiring = false
local currentTarget = nil
local currentTargetRoot = nil

local function getCharacter()
	return player.Character or player.CharacterAdded:Wait()
end

local function getEnemyModels()
	local myCharacter = getCharacter()
	local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
	local enemies = {}

	for _, model in ipairs(workspace:GetChildren()) do
		if model:IsA("Model") and model ~= myCharacter then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			local root = model:FindFirstChild(config.targetPartName)
			if humanoid and root and humanoid.Health > 0 then
				table.insert(enemies, model)
			end
		end
	end

	return enemies
end

local function getCameraForward()
	return camera.CFrame.LookVector
end

local function getNearestTarget()
	local myCharacter = getCharacter()
	if not myCharacter then
		return nil
	end

	local myRoot = myCharacter:FindFirstChild("HumanoidRootPart")
	if not myRoot then
		return nil
	end

	local origin = myRoot.Position
	local forward = getCameraForward()

	local bestModel = nil
	local bestScore = -math.huge

	for _, model in ipairs(getEnemyModels()) do
		local root = model:FindFirstChild(config.targetPartName)
		if root then
			local offset = root.Position - origin
			local distance = offset.Magnitude
			if distance <= config.maxRange then
				local dirToTarget = offset.Unit
				local dot = forward:Dot(dirToTarget)
				local angle = math.acos(math.clamp(dot, -1, 1))

				if angle <= config.maxAngle then
					local centerFactor = (1 - (angle / config.maxAngle))
					local distanceFactor = 1 - (distance / config.maxRange)
					local score = (centerFactor * 0.7) + (distanceFactor * 0.3)

					if score > bestScore then
						bestScore = score
						bestModel = model
					end
				end
			end
		end
	end

	return bestModel
end

local function updateTarget()
	if not config.enabled or not isFiring then
		currentTarget = nil
		currentTargetRoot = nil
		return
	end

	local target = getNearestTarget()
	currentTarget = target

	if target then
		currentTargetRoot = target:FindFirstChild(config.targetPartName)
	else
		currentTargetRoot = nil
	end
end

local function applyAimAssist()
	if not config.enabled or not isFiring or not currentTargetRoot then
		return
	end

	local playerRoot = getCharacter() and getCharacter():FindFirstChild("HumanoidRootPart")
	if not playerRoot then
		return
	end

	local origin = camera.CFrame.Position
	local targetPos = currentTargetRoot.Position + Vector3.new(0, config.aimOffsetY, 0)
	local targetDir = (targetPos - origin).Unit
	local currentDir = camera.CFrame.LookVector

	local blendedDir = currentDir:Lerp(targetDir, config.assistStrength)
	local lookAt = origin + blendedDir
	local targetCF = CFrame.lookAt(origin, lookAt)

	camera.CFrame = camera.CFrame:Lerp(targetCF, config.smoothness)
end

-- Mobile fire button handling
local function fireAction(actionName, inputState, inputObject)
	if actionName == config.fireActionName then
		if inputState == Enum.UserInputState.Begin then
			isFiring = true
			updateTarget()
		elseif inputState == Enum.UserInputState.End then
			isFiring = false
			currentTarget = nil
			currentTargetRoot = nil
		end
		return Enum.ContextActionResult.Sink
	end
end

ContextActionService:BindAction(config.fireActionName, fireAction, false, Enum.KeyCode.ButtonR2)

-- Optional: also support tap-to-fire on a mobile UI button
-- You can trigger the same action from a custom GUI button

RunService.RenderStepped:Connect(function()
	updateTarget()
	applyAimAssist()
end)