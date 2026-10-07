--// Studio Aim Assist
--// Based on the target-selection / camera-aim behavior in
--// KiciaHook_Source_Runnable.lua (1).txt
--// For your own Roblox experience / Studio testing

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--==================================================
-- SETTINGS
--==================================================

local Settings = {
	Enabled = true,

	-- Source-style target selection
	IgnoreFOV = false,
	FOVRadius = 282,
	MaxDistance = 1000,

	-- Aim part
	-- "Auto"   = prefer Head
	-- "Head"   = Head
	-- "Random" = Head / HumanoidRootPart
	AimPart = "Auto",

	-- Target validation
	TeamCheck = true,
	WallCheck = true,
	RequireAlive = true,

	-- Camera aiming
	AimSpeed = 35,
	Prediction = 0.08,

	-- Target lock
	TargetLock = true,

	-- Mobile behavior
	MobileCenterAim = true,

	-- FOV display
	ShowFOV = true,
}

--==================================================
-- STATE
--==================================================

local CurrentTarget = nil
local CurrentPart = nil
local RandomPartCache = nil
local RandomTargetCache = nil

--==================================================
-- CHARACTER
--==================================================

local function GetCharacter(player)
	if not player then
		return nil
	end

	return player.Character
end

local function GetHumanoid(player)
	local character = GetCharacter(player)

	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function IsAlive(player)
	if not player then
		return false
	end

	local humanoid = GetHumanoid(player)

	return humanoid
		and humanoid.Health > 0
end

--==================================================
-- TEAM CHECK
--==================================================

local function IsValidTeamTarget(player)
	if player == LocalPlayer then
		return false
	end

	if Settings.TeamCheck then
		if LocalPlayer.Team ~= nil and player.Team ~= nil then
			if LocalPlayer.Team == player.Team then
				return false
			end
		end
	end

	return true
end

--==================================================
-- AIM PART
--==================================================

local function GetHead(character)
	return character:FindFirstChild("Head")
end

local function GetRoot(character)
	return character:FindFirstChild("HumanoidRootPart")
end

local function ResolveAimPart(player)
	local character = GetCharacter(player)

	if not character then
		return nil
	end

	local head = GetHead(character)
	local root = GetRoot(character)

	if Settings.AimPart == "Head" then
		return head or root
	end

	if Settings.AimPart == "Random" then
		-- Keep the random part stable while the same
		-- target remains locked, matching the source's
		-- stable Random target behavior.

		if RandomTargetCache == player
			and RandomPartCache
			and RandomPartCache.Parent == character then

			return RandomPartCache
		end

		local candidates = {}

		if head then
			table.insert(candidates, head)
		end

		if root then
			table.insert(candidates, root)
		end

		if #candidates == 0 then
			return nil
		end

		local selected = candidates[math.random(1, #candidates)]

		RandomTargetCache = player
		RandomPartCache = selected

		return selected
	end

	-- Auto
	-- The source prefers head-style hitboxes when available.
	return head or root
end

--==================================================
-- VISIBILITY / WALL CHECK
--==================================================

local function IsVisible(player, part)
	if not Settings.WallCheck then
		return true
	end

	local character = GetCharacter(player)

	if not character or not part then
		return false
	end

	local origin = Camera.CFrame.Position
	local direction = part.Position - origin

	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Exclude
	parameters.FilterDescendantsInstances = {
		LocalPlayer.Character,
		Camera
	}

	parameters.IgnoreWater = true

	local result = Workspace:Raycast(
		origin,
		direction,
		parameters
	)

	if not result then
		return true
	end

	return result.Instance:IsDescendantOf(character)
end

--==================================================
-- POINTER POSITION
--==================================================

local function GetAimPointer()
	-- Mobile:
	-- Use the center of the screen, similar to a
	-- center-based aim mode.

	if Settings.MobileCenterAim then
		local viewport = Camera.ViewportSize

		return Vector2.new(
			viewport.X / 2,
			viewport.Y / 2
		)
	end

	-- Desktop:
	return UserInputService:GetMouseLocation()
end

--==================================================
-- FOV CIRCLE
--==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "StudioAimAssist"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOVCircle"
FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.Size = UDim2.fromOffset(
	Settings.FOVRadius * 2,
	Settings.FOVRadius * 2
)
FOVCircle.Parent = ScreenGui

local CircleCorner = Instance.new("UICorner")
CircleCorner.CornerRadius = UDim.new(1, 0)
CircleCorner.Parent = FOVCircle

local CircleStroke = Instance.new("UIStroke")
CircleStroke.Thickness = 1
CircleStroke.Transparency = 0.15
CircleStroke.Parent = FOVCircle

local function UpdateFOVCircle()
	local pointer = GetAimPointer()

	FOVCircle.Position = UDim2.fromOffset(
		pointer.X,
		pointer.Y
	)

	FOVCircle.Size = UDim2.fromOffset(
		Settings.FOVRadius * 2,
		Settings.FOVRadius * 2
	)

	FOVCircle.Visible = Settings.ShowFOV
end

--==================================================
-- TARGET INFO
--==================================================

local function BuildTargetInfo(player)
	if not player then
		return nil
	end

	if player == LocalPlayer then
		return nil
	end

	if Settings.RequireAlive and not IsAlive(player) then
		return nil
	end

	if not IsValidTeamTarget(player) then
		return nil
	end

	local character = GetCharacter(player)

	if not character then
		return nil
	end

	local part = ResolveAimPart(player)

	if not part or not part.Parent then
		return nil
	end

	local worldPosition = part.Position

	-- Prediction
	local velocity = part.AssemblyLinearVelocity

	if Settings.Prediction > 0 then
		worldPosition += velocity * Settings.Prediction
	end

	local screenPosition, onScreen =
		Camera:WorldToViewportPoint(worldPosition)

	if not onScreen and not Settings.IgnoreFOV then
		return nil
	end

	if screenPosition.Z <= 0 then
		if not Settings.IgnoreFOV then
			return nil
		end
	end

	local pointer = GetAimPointer()

	local screenDistance = math.huge

	if screenPosition.Z > 0 then
		screenDistance = (
			Vector2.new(
				screenPosition.X,
				screenPosition.Y
			) - pointer
		).Magnitude
	end

	-- Source behavior:
	-- on-screen targets are ranked by screen distance.
	-- off-screen targets are penalized heavily when
	-- Ignore FOV is enabled.

	local selectionDistance

	if onScreen then
		selectionDistance = screenDistance

		if not Settings.IgnoreFOV
			and screenDistance > Settings.FOVRadius then
			return nil
		end
	else
		selectionDistance = 1000000 +
			(Camera.CFrame.Position - worldPosition).Magnitude
	end

	-- World distance
	local worldDistance = (
		Camera.CFrame.Position - worldPosition
	).Magnitude

	if worldDistance > Settings.MaxDistance then
		return nil
	end

	-- Visibility
	if not IsVisible(player, part) then
		return nil
	end

	return {
		Player = player,
		Character = character,
		Part = part,
		WorldPosition = worldPosition,
		WorldDistance = worldDistance,
		ScreenDistance = screenDistance,
		SelectionDistance = selectionDistance,
	}
end

--==================================================
-- FIND BEST TARGET
--==================================================

local function GetBestTarget()
	local bestInfo = nil

	for _, player in ipairs(Players:GetPlayers()) do
		local info = BuildTargetInfo(player)

		if info then
			if not bestInfo
				or info.SelectionDistance <
				bestInfo.SelectionDistance then

				bestInfo = info
			end
		end
	end

	return bestInfo
end

--==================================================
-- REFRESH LOCKED TARGET
--==================================================

local function RefreshLockedTarget()
	if not CurrentTarget then
		return nil
	end

	local info = BuildTargetInfo(CurrentTarget)

	if not info then
		CurrentTarget = nil
		CurrentPart = nil
		RandomPartCache = nil
		RandomTargetCache = nil

		return nil
	end

	CurrentPart = info.Part

	return info
end

--==================================================
-- TARGET ACQUISITION
--==================================================

local function GetTarget()
	-- Source-style target locking:
	-- keep the existing target while it remains valid.

	if Settings.TargetLock and CurrentTarget then
		local locked = RefreshLockedTarget()

		if locked then
			return locked
		end
	end

	local best = GetBestTarget()

	if best then
		CurrentTarget = best.Player
		CurrentPart = best.Part

		if RandomTargetCache ~= best.Player then
			RandomTargetCache = nil
			RandomPartCache = nil
		end

		return best
	end

	CurrentTarget = nil
	CurrentPart = nil
	RandomTargetCache = nil
	RandomPartCache = nil

	return nil
end

--==================================================
-- CAMERA AIM
--==================================================

local function AimCamera(targetInfo, deltaTime)
	if not targetInfo then
		return
	end

	local part = targetInfo.Part

	if not part or not part.Parent then
		return
	end

	local targetPosition = targetInfo.WorldPosition

	local cameraPosition = Camera.CFrame.Position

	local desiredCFrame = CFrame.lookAt(
		cameraPosition,
		targetPosition
	)

	-- Same general exponential smoothing approach
	-- used by the source's camera aim implementation.

	local frameDelta = math.clamp(
		typeof(deltaTime) == "number"
			and deltaTime
			or (1 / 60),
		0,
		0.1
	)

	local blendAlpha = math.clamp(
		1 - math.exp(
			-frameDelta *
			(2 + (Settings.AimSpeed * 0.58))
		),
		0,
		1
	)

	Camera.CFrame = Camera.CFrame:Lerp(
		desiredCFrame,
		blendAlpha
	)
end

--==================================================
-- ENABLE / DISABLE
--==================================================

local function ResetTarget()
	CurrentTarget = nil
	CurrentPart = nil
	RandomTargetCache = nil
	RandomPartCache = nil
end

--==================================================
-- MAIN LOOP
--==================================================

RunService:BindToRenderStep(
	"StudioAimAssist",
	Enum.RenderPriority.Camera.Value + 1,
	function(deltaTime)

		Camera = Workspace.CurrentCamera

		if not Camera then
			ResetTarget()
			return
		end

		UpdateFOVCircle()

		if not Settings.Enabled then
			ResetTarget()
			return
		end

		local targetInfo = GetTarget()

		if targetInfo then
			AimCamera(
				targetInfo,
				deltaTime
			)
		end
	end
)

--==================================================
-- CLEANUP
--==================================================

Players.PlayerRemoving:Connect(function(player)
	if player == CurrentTarget then
		ResetTarget()
	end
end)

LocalPlayer.CharacterRemoving:Connect(function()
	ResetTarget()
end)