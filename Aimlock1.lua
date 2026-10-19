-- LocalScript: StarterPlayer > StarterPlayerScripts
-- Local UI/control-flow test harness. Mock targets only.
-- Fake targets are UI dots on a ScreenGui. This script never reads other players,
-- characters or workspace parts, and never moves the camera or any input.
-- The camera is only read for ViewportSize to size the UI.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- ===== Config =====
local Config = {
	hotkeyToggle = Enum.KeyCode.F6,   -- keyboard only (Studio / PC). Touch uses the on-screen button.
	hotkeyCycle  = Enum.KeyCode.F7,
	hotkeyReset  = Enum.KeyCode.F8,
	debounceSeconds = 0.25,           -- shared by hotkeys AND touch buttons
	strengthMin = 0,
	strengthMax = 100,
	strengthDefault = 50,
	updateTargetingWhenUiClosed = true,  -- documented choice: debug info keeps updating when UI is closed
	overlayVisibleWhenUiClosed  = true,  -- set both to false for "UI open only" behavior
}

-- ===== Clock / logging =====
local Clock = { now = 0 }

local function log(msg)
	print(string.format("[AssistUITest t=%.1f] %s", Clock.now, msg))
end

-- ===== Mobile sizing =====
-- Min screen dimension is the same in portrait and landscape, so this survives rotation.
-- On a ~390pt phone the scale is 1, so the 48px base rows are the minimum touch size.
local camera = workspace.CurrentCamera or workspace:WaitForChild("Camera")
local viewport = camera.ViewportSize
local uiScale = math.clamp(math.min(viewport.X, viewport.Y) / 480, 1, 1.75)
local function S(n) return math.floor(n * uiScale + 0.5) end

-- ===== Constants / mock data =====
local TargetMode = { NEAREST = 1, FARTHEST = 2, MANUAL = 3 }
local TargetModeNames = { "Nearest to center", "Farthest from center", "Manual (cycle)" }

-- Fixed fake targets in normalized (0..1) screen coordinates, so they fit any device.
-- List order defines tie-breaking, so selection is deterministic.
local Targets = {
	{ id = 1, name = "T1", nx = 0.20, ny = 0.30 },
	{ id = 2, name = "T2", nx = 0.56, ny = 0.47 },
	{ id = 3, name = "T3", nx = 0.80, ny = 0.75 },
	{ id = 4, name = "T4", nx = 0.50, ny = 0.15 },
	{ id = 5, name = "T5", nx = 0.30, ny = 0.80 },
}

local Colors = {
	panel = Color3.fromRGB(28, 28, 34),
	row = Color3.fromRGB(46, 46, 56),
	accent = Color3.fromRGB(70, 130, 255),
	on = Color3.fromRGB(60, 190, 110),
	off = Color3.fromRGB(90, 90, 100),
	text = Color3.fromRGB(240, 240, 245),
	selected = Color3.fromRGB(255, 205, 60),
	dot = Color3.fromRGB(160, 160, 170),
	vector = Color3.fromRGB(255, 90, 90),
}

-- ===== State =====
local State = {}
local sliderDrag = nil      -- InputObject currently dragging the slider (nil when idle)
local endSliderDrag         -- forward declaration, assigned in the UI section

function State.reset()
	State.uiOpen = false
	State.enableTestAssist = false
	State.assistStrength = Config.strengthDefault
	State.targetMode = TargetMode.NEAREST
	State.cycleIndex = 1
	State.selectedIndex = nil
	State.lastSelectionTime = nil
	State.adjustment = nil
	if endSliderDrag then endSliderDrag() end
end

-- ===== Debounce =====
-- Roblox InputBegan does not auto-repeat for held keys, so debounce here also
-- guards double-taps and touch bounce. Each action has one gate shared by key and touch.
local function makeGate(seconds, label)
	local last = -math.huge
	return function()
		if Clock.now - last < seconds then
			log(label .. " blocked by debounce")
			return false
		end
		last = Clock.now
		return true
	end
end

local toggleGate = makeGate(Config.debounceSeconds, "toggle")
local cycleGate = makeGate(Config.debounceSeconds, "cycle")
local resetGate = makeGate(Config.debounceSeconds, "reset")

-- ===== Helpers =====
local function new(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do inst[k] = v end
	inst.Parent = parent
	return inst
end

local function round(parent, radius)
	return new("UICorner", { CornerRadius = radius }, parent)
end

-- ===== UI construction =====
-- Default ScreenGui insets keep the UI out of the topbar and device notch areas.
local gui = new("ScreenGui", {
	Name = "AssistUITest",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 50,
}, playerGui)

-- Full-screen layer for fake targets + vector line. Not Active, so it never blocks touches.
local playfield = new("Frame", {
	Name = "Playfield",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ZIndex = 1,
}, gui)

local centerMarker = new("Frame", {
	Name = "CenterMarker",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.fromOffset(S(10), S(10)),
	BackgroundColor3 = Colors.text,
	ZIndex = 2,
}, playfield)
round(centerMarker, UDim.new(0.5, 0))

local adjLine = new("Frame", {
	Name = "AdjustmentVector",
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Colors.vector,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 2,
}, playfield)

local dots = {}
for i, t in ipairs(Targets) do
	local dot = new("Frame", {
		Name = "Target" .. t.id,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(S(22), S(22)),
		BackgroundColor3 = Colors.dot,
		Visible = false,
		ZIndex = 3,
	}, playfield)
	round(dot, UDim.new(0.5, 0))
	new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = t.name,
		TextColor3 = Color3.new(0, 0, 0),
		TextSize = S(11),
		Font = Enum.Font.GothamBold,
	}, dot)
	dots[i] = dot
end

-- Debug text overlay (bottom center, clear of the thumbstick and jump button)
local debugLabel = new("TextLabel", {
	Name = "DebugLabel",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -S(8)),
	Size = UDim2.fromOffset(S(300), 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.4,
	TextColor3 = Colors.text,
	TextSize = S(14),
	Font = Enum.Font.Code,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextWrapped = true,
	Text = "",
	ZIndex = 4,
}, gui)
round(debugLabel, UDim.new(0, S(8)))
new("UIPadding", {
	PaddingLeft = UDim.new(0, S(8)), PaddingRight = UDim.new(0, S(8)),
	PaddingTop = UDim.new(0, S(6)), PaddingBottom = UDim.new(0, S(6)),
}, debugLabel)

-- Settings panel: a ScrollingFrame so it still fits short landscape screens
local panel = new("ScrollingFrame", {
	Name = "Panel",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, S(12), 0.5, 0),
	Size = UDim2.fromScale(0.7, 0.92),
	BackgroundColor3 = Colors.panel,
	BackgroundTransparency = 0.05,
	BorderSizePixel = 0,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = S(4),
	Visible = false,
	ZIndex = 5,
}, gui)
round(panel, UDim.new(0, S(12)))
new("UISizeConstraint", { MinSize = Vector2.new(S(220), 0), MaxSize = Vector2.new(S(320), math.huge) }, panel)
new("UIPadding", {
	PaddingLeft = UDim.new(0, S(10)), PaddingRight = UDim.new(0, S(10)),
	PaddingTop = UDim.new(0, S(10)), PaddingBottom = UDim.new(0, S(10)),
}, panel)
new("UIListLayout", { Padding = UDim.new(0, S(8)), SortOrder = Enum.SortOrder.LayoutOrder }, panel)

new("TextLabel", {
	LayoutOrder = 1,
	Size = UDim2.new(1, 0, 0, S(28)),
	BackgroundTransparency = 1,
	Text = "Assist UI Test (mock)",
	TextColor3 = Colors.text,
	TextSize = S(18),
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left,
}, panel)

local function makeRowButton(order, height)
	local b = new("TextButton", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, S(height)),
		BackgroundColor3 = Colors.row,
		AutoButtonColor = true,
		Text = "",
	}, panel)
	round(b, UDim.new(0, S(8)))
	return b
end

-- Checkbox row (whole row is the touch target)
local cbRow = makeRowButton(2, 48)
local cbBox = new("Frame", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, S(10), 0.5, 0),
	Size = UDim2.fromOffset(S(28), S(28)),
	BackgroundColor3 = Colors.off,
}, cbRow)
round(cbBox, UDim.new(0, S(6)))
local cbLabel = new("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, S(48), 0, 0),
	Size = UDim2.new(1, -S(56), 1, 0),
	TextColor3 = Colors.text,
	TextSize = S(16),
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "",
}, cbRow)

-- Slider row (large hit area, thin visual track, big handle)
local sliderRow = new("Frame", {
	LayoutOrder = 3,
	Size = UDim2.new(1, 0, 0, S(76)),
	BackgroundColor3 = Colors.row,
}, panel)
round(sliderRow, UDim.new(0, S(8)))
local sliderLabel = new("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, S(10), 0, S(4)),
	Size = UDim2.new(1, -S(20), 0, S(24)),
	TextColor3 = Colors.text,
	TextSize = S(16),
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "",
}, sliderRow)
local sliderHit = new("Frame", {
	Position = UDim2.new(0, S(24), 0, S(30)),
	Size = UDim2.new(1, -S(48), 0, S(40)),
	BackgroundTransparency = 1,
	Active = true,          -- sinks input so the ScrollingFrame doesn't steal the drag
}, sliderRow)
local sliderTrack = new("Frame", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 0, 0.5, 0),
	Size = UDim2.new(1, 0, 0, S(8)),
	BackgroundColor3 = Colors.off,
}, sliderHit)
round(sliderTrack, UDim.new(0.5, 0))
local sliderHandle = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0, 0, 0.5, 0),
	Size = UDim2.fromOffset(S(28), S(28)),
	BackgroundColor3 = Colors.accent,
	ZIndex = 2,
}, sliderHit)
round(sliderHandle, UDim.new(0.5, 0))

-- Dropdown row (stub: tap to advance; swap for a real popup list if you need one)
local ddRow = makeRowButton(4, 56)
local ddLabel = new("TextLabel", {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, S(10), 0, 0),
	Size = UDim2.new(1, -S(20), 1, 0),
	TextColor3 = Colors.text,
	TextSize = S(14),
	Font = Enum.Font.GothamMedium,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextWrapped = true,
	Text = "",
}, ddRow)

-- Cycle Target / Reset buttons
local function makeActionButton(order, text)
	local b = new("TextButton", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, S(48)),
		BackgroundColor3 = Colors.accent,
		AutoButtonColor = true,
		Text = text,
		TextColor3 = Colors.text,
		TextSize = S(16),
		Font = Enum.Font.GothamBold,
	}, panel)
	round(b, UDim.new(0, S(8)))
	return b
end
local cycleButton = makeActionButton(5, "Cycle Target")
local resetButton = makeActionButton(6, "Reset")
resetButton.BackgroundColor3 = Colors.off

local statusLabel = new("TextLabel", {
	LayoutOrder = 7,
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	TextColor3 = Colors.text,
	TextSize = S(14),
	Font = Enum.Font.Code,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextWrapped = true,
	Text = "",
}, panel)

-- Floating action buttons (touch replacement for hotkeys; work with UI open or closed)
local function makeFab(yOffset, text)
	local b = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -S(12), 0.35, yOffset),
		Size = UDim2.fromOffset(S(56), S(56)),
		BackgroundColor3 = Colors.accent,
		Text = text,
		TextColor3 = Colors.text,
		TextSize = S(14),
		Font = Enum.Font.GothamBold,
		ZIndex = 10,
	}, gui)
	round(b, UDim.new(0.5, 0))
	return b
end
local toggleFab = makeFab(0, "Open")
local cycleFab = makeFab(S(64), "Cycle")

-- ===== Mock targeting (debug math only) =====
local Targeting = {}

local function targetPixel(t)
	local size = playfield.AbsoluteSize
	return Vector2.new(t.nx * size.X, t.ny * size.Y)
end

-- Deterministic: ties keep the lower list index.
function Targeting.chooseIndex()
	if State.targetMode == TargetMode.MANUAL then
		return math.clamp(State.cycleIndex, 1, #Targets)
	end
	local center = playfield.AbsoluteSize / 2
	local bestIdx, bestDist
	for i, t in ipairs(Targets) do
		local d = (targetPixel(t) - center).Magnitude
		local better
		if bestIdx == nil then
			better = true
		elseif State.targetMode == TargetMode.NEAREST then
			better = d < bestDist
		else
			better = d > bestDist
		end
		if better then bestIdx, bestDist = i, d end
	end
	return bestIdx
end

-- DEBUG ONLY: arithmetic on fake points. The result is drawn, never applied anywhere.
function Targeting.computeAdjustment(t, strength)
	local center = playfield.AbsoluteSize / 2
	local v = (targetPixel(t) - center) * (strength / 100)
	return {
		dx = v.X,
		dy = v.Y,
		magnitude = v.Magnitude,
		angleDeg = math.deg(math.atan2(v.Y, v.X)),  -- screen space: +y is down
	}
end

function Targeting.update()
	if not State.enableTestAssist then
		if State.selectedIndex ~= nil then log("test assist off: selection cleared") end
		State.selectedIndex = nil
		State.adjustment = nil
		return
	end
	local idx = Targeting.chooseIndex()
	if idx ~= State.selectedIndex then
		State.selectedIndex = idx
		State.lastSelectionTime = Clock.now
		log(string.format("selected target id=%d (%s)", Targets[idx].id, Targets[idx].name))
	end
	State.adjustment = Targeting.computeAdjustment(Targets[idx], State.assistStrength)
end

-- ===== Actions =====
local function toggleUI()
	State.uiOpen = not State.uiOpen
	if endSliderDrag then endSliderDrag() end   -- never leave a drag active across open/close
	log("uiOpen = " .. tostring(State.uiOpen))
end

-- In MANUAL mode advance the index. In any other mode switch to MANUAL starting at the
-- target after the current selection, so the button always visibly advances.
local function cycleTarget()
	local n = #Targets
	if State.targetMode ~= TargetMode.MANUAL then
		State.targetMode = TargetMode.MANUAL
		log("TargetMode = " .. TargetModeNames[TargetMode.MANUAL])
		State.cycleIndex = ((State.selectedIndex or 0) % n) + 1
	else
		State.cycleIndex = State.cycleIndex % n + 1
	end
	log("cycle target -> index " .. State.cycleIndex)
end

-- Debounced entry points shared by hotkeys and touch buttons
local function requestToggle() if toggleGate() then toggleUI() end end
local function requestCycle() if cycleGate() then cycleTarget() end end
local function requestReset()
	if resetGate() then
		State.reset()
		log("state reset")
	end
end

-- ===== Input wiring =====
-- Touch / click: Activated fires for taps and mouse clicks.
toggleFab.Activated:Connect(requestToggle)
cycleFab.Activated:Connect(requestCycle)
cycleButton.Activated:Connect(requestCycle)
resetButton.Activated:Connect(requestReset)

cbRow.Activated:Connect(function()
	State.enableTestAssist = not State.enableTestAssist
	log("EnableTestAssist = " .. tostring(State.enableTestAssist))
end)

ddRow.Activated:Connect(function()
	State.targetMode = State.targetMode % #TargetModeNames + 1
	log("TargetMode = " .. TargetModeNames[State.targetMode])
end)

-- Slider drag (touch and mouse). The ScrollingFrame is locked while dragging.
local function setStrengthFromX(x)
	local width = math.max(sliderHit.AbsoluteSize.X, 1)
	local t = math.clamp((x - sliderHit.AbsolutePosition.X) / width, 0, 1)
	local v = math.floor(Config.strengthMin + t * (Config.strengthMax - Config.strengthMin) + 0.5)
	if v ~= State.assistStrength then
		State.assistStrength = v
		log("AssistStrength = " .. v)
	end
end

endSliderDrag = function()
	sliderDrag = nil
	panel.ScrollingEnabled = true
end

sliderHit.InputBegan:Connect(function(input)
	local ut = input.UserInputType
	if ut == Enum.UserInputType.Touch or ut == Enum.UserInputType.MouseButton1 then
		sliderDrag = input
		panel.ScrollingEnabled = false
		setStrengthFromX(input.Position.X)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not sliderDrag then return end
	local isSameTouch = (input == sliderDrag)
	local isMouseMove = (sliderDrag.UserInputType == Enum.UserInputType.MouseButton1
		and input.UserInputType == Enum.UserInputType.MouseMovement)
	if isSameTouch or isMouseMove then
		setStrengthFromX(input.Position.X)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if not sliderDrag then return end
	local sameTouch = (input == sliderDrag)
	local mouseUp = (sliderDrag.UserInputType == Enum.UserInputType.MouseButton1
		and input.UserInputType == Enum.UserInputType.MouseButton1)
	if sameTouch or mouseUp then endSliderDrag() end
end)

-- Keyboard hotkeys (optional; useful in Studio and on desktop)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
	if input.KeyCode == Config.hotkeyToggle then
		requestToggle()
	elseif input.KeyCode == Config.hotkeyCycle then
		requestCycle()
	elseif input.KeyCode == Config.hotkeyReset then
		requestReset()
	end
end)

-- ===== Rendering =====
local function syncPanel()
	panel.Visible = State.uiOpen
	toggleFab.Text = State.uiOpen and "Close" or "Open"
	if not State.uiOpen then return end

	cbBox.BackgroundColor3 = State.enableTestAssist and Colors.on or Colors.off
	cbLabel.Text = "EnableTestAssist: " .. (State.enableTestAssist and "ON" or "OFF")

	local range = Config.strengthMax - Config.strengthMin
	local t = (State.assistStrength - Config.strengthMin) / range
	sliderHandle.Position = UDim2.new(t, 0, 0.5, 0)
	sliderLabel.Text = string.format("AssistStrength: %d", State.assistStrength)

	ddLabel.Text = "TargetMode (tap to change)\n" .. TargetModeNames[State.targetMode]

	local selId = State.selectedIndex and Targets[State.selectedIndex].id or "none"
	statusLabel.Text = string.format(
		"uiOpen=%s\nEnableTestAssist=%s\nAssistStrength=%d\nTargetMode=%s\nSelectedId=%s",
		tostring(State.uiOpen), tostring(State.enableTestAssist), State.assistStrength,
		TargetModeNames[State.targetMode], tostring(selId))
end

local function drawOverlay()
	local show = State.uiOpen or Config.overlayVisibleWhenUiClosed
	playfield.Visible = show
	debugLabel.Visible = show
	if not show then return end

	local size = playfield.AbsoluteSize
	local center = size / 2
	centerMarker.Position = UDim2.fromOffset(center.X, center.Y)

	local active = State.enableTestAssist and State.selectedIndex ~= nil
	for i, t in ipairs(Targets) do
		local dot = dots[i]
		dot.Visible = active
		dot.Position = UDim2.fromOffset(t.nx * size.X, t.ny * size.Y)
		dot.BackgroundColor3 = (i == State.selectedIndex) and Colors.selected or Colors.dot
	end

	if not active then
		adjLine.Visible = false
		debugLabel.Text = "TEST ASSIST DEBUG: OFF"
		return
	end

	local sel, adj = Targets[State.selectedIndex], State.adjustment

	-- Line from screen center along the would-be adjustment vector (drawn via midpoint + rotation)
	if adj.magnitude >= 1 then
		adjLine.Visible = true
		adjLine.Size = UDim2.fromOffset(adj.magnitude, S(3))
		adjLine.Position = UDim2.fromOffset(center.X + adj.dx / 2, center.Y + adj.dy / 2)
		adjLine.Rotation = adj.angleDeg
	else
		adjLine.Visible = false
	end

	debugLabel.Text = string.format(
		"TEST ASSIST DEBUG (mock only)\n" ..
		"Selected target id: %d (%s)\n" ..
		"Assist strength: %d\n" ..
		"Would-be adjustment vector: (%.2f, %.2f)\n" ..
		"|v| = %.2f  angle = %.2f deg\n" ..
		"Last selection: t=%.2fs",
		sel.id, sel.name, State.assistStrength, adj.dx, adj.dy,
		adj.magnitude, adj.angleDeg, State.lastSelectionTime)
end

-- ===== Main loop =====
-- Order: clock -> targeting -> panel sync -> overlay. Input is event-driven above.
local function update(dt)
	Clock.now += dt
	if State.uiOpen or Config.updateTargetingWhenUiClosed then
		Targeting.update()
	end
	syncPanel()
	drawOverlay()
end

local function start()
	State.reset()
	RunService.RenderStepped:Connect(update)
	log("start: state reset, UI ready")
end

start()