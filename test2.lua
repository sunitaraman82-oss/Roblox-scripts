--// SIMPLE TARGET DETECTOR
--// Roblox Studio / your own training experience

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Enabled = true
local FOV = 400

--==================================================
-- UI
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "TargetDetector"
Gui.ResetOnSpawn = false
Gui.Parent = Player:WaitForChild("PlayerGui")

local Status = Instance.new("TextLabel")
Status.Size = UDim2.fromOffset(320, 50)
Status.Position = UDim2.new(0.5, -160, 0, 20)
Status.BackgroundTransparency = 0.2
Status.Text = "SEARCHING..."
Status.TextSize = 18
Status.Font = Enum.Font.GothamBold
Status.Parent = Gui

local Circle = Instance.new("Frame")
Circle.Size = UDim2.fromOffset(FOV * 2, FOV * 2)
Circle.Position = UDim2.fromScale(0.5, 0.5)
Circle.AnchorPoint = Vector2.new(0.5, 0.5)
Circle.BackgroundTransparency = 1
Circle.Parent = Gui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(1, 0)
Corner.Parent = Circle

local Stroke = Instance.new("UIStroke")
Stroke.Thickness = 2
Stroke.Parent = Circle

--==================================================
-- HIGHLIGHT
--==================================================

local Highlight = Instance.new("Highlight")
Highlight.Enabled = false
Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
Highlight.Parent = Gui

--==================================================
-- GET PART
--==================================================

local function GetPart(object)

	if object:IsA("BasePart") then
		return object
	end

	if object:IsA("Model") then

		return object:FindFirstChild("HumanoidRootPart")
			or object.PrimaryPart
			or object:FindFirstChildWhichIsA("BasePart")
	end

	return nil
end

--==================================================
-- FIND TARGETS
--==================================================

local function FindTarget()

	local center = Vector2.new(
		Camera.ViewportSize.X / 2,
		Camera.ViewportSize.Y / 2
	)

	local closest = nil
	local closestDistance = FOV

	for _, object in ipairs(workspace:GetDescendants()) do

		-- Ignore our own character
		if Player.Character
			and object:IsDescendantOf(Player.Character) then
			continue
		end

		if object:IsA("BasePart") then

			local position, visible =
				Camera:WorldToViewportPoint(object.Position)

			if visible and position.Z > 0 then

				local screenDistance =
					(
						Vector2.new(
							position.X,
							position.Y
						) - center
					).Magnitude

				if screenDistance < closestDistance then

					closestDistance = screenDistance
					closest = object
				end
			end
		end
	end

	return closest
end

--==================================================
-- UPDATE
--==================================================

RunService:BindToRenderStep(
	"TargetDetector",
	Enum.RenderPriority.Last.Value,
	function()

		if not Enabled then
			return
		end

		local target = FindTarget()

		if target then

			Status.Text =
				"TARGET: " .. target:GetFullName()

			Highlight.Adornee =
				target.Parent:IsA("Model")
				and target.Parent
				or target

			Highlight.Enabled = true

		else

			Status.Text =
				"NO TARGET FOUND"

			Highlight.Enabled = false
		end
	end
)