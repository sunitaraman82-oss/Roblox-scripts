--[[
	SettingsPanel (LocalScript)
	Put this in StarterPlayer > StarterPlayerScripts.

	Recreates the look of the screenshots: off-white rounded panel, big master
	toggle (red when OFF), grey "cycle" rows, blue "ON" toggle rows, and a
	grey footer line. Everything is driven by the CONFIG table below, so you
	can rename rows or add new ones without touching the UI code.
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer

--------------------------------------------------------------------------
-- CONFIG: edit labels / options here
--------------------------------------------------------------------------
local CONFIG = {
	master = { label = "SYSTEM", default = false },

	items = {
		-- type "cycle": click to step through options
		{ id = "mode",  type = "cycle",  label = "Mode", options = { "OPTION A", "OPTION B", "OPTION C" } },
		-- type "toggle": click to flip ON / OFF
		{ id = "music", type = "toggle", label = "Music", default = true },
		{ id = "fps",   type = "toggle", label = "Show FPS", default = true },
		{ id = "hints", type = "toggle", label = "Hints", default = true },
		{ id = "quick", type = "toggle", label = "Floating Quick Button", default = true },
		-- type "count": shows [ N Selected ]. Clicking fires onChanged so YOU
		-- can open your own picker and then call setCount("picked", n).
		{ id = "picked", type = "count", label = "Selected Items", default = 0 },
	},

	footer = "Target: [ AUTO ]", -- set to nil to hide
}

--------------------------------------------------------------------------
-- HOOK: your game logic goes here
--------------------------------------------------------------------------
local function onChanged(id, value)
	print(("[SettingsPanel] %s -> %s"):format(id, tostring(value)))
end

--------------------------------------------------------------------------
-- THEME (sampled from the screenshots)
--------------------------------------------------------------------------
local THEME = {
	panel     = Color3.fromRGB(250, 250, 250),
	rowGrey   = Color3.fromRGB(245, 245, 245),
	blue      = Color3.fromRGB(59, 130, 246),
	red       = Color3.fromRGB(220, 50, 50),
	green     = Color3.fromRGB(34, 197, 94), -- master ON (assumed; not in screenshot)
	textDark  = Color3.fromRGB(38, 38, 38),
	textLight = Color3.fromRGB(255, 255, 255),
	strokeGrey  = Color3.fromRGB(200, 200, 200),
	strokeWhite = Color3.fromRGB(215, 225, 245),
	footer    = Color3.fromRGB(110, 110, 110),

	corner = UDim.new(0, 12),
	panelCorner = UDim.new(0, 20),
	masterHeight = 50,
	rowHeight = 44,
	gap = 16,
	padding = 16,
	panelWidth = 400,
	panelHeight = 330,
}

local FONT_BOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
local FONT_REG  = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Regular)

--------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------
local state = { master = CONFIG.master.default }
local itemById = {}
for _, item in ipairs(CONFIG.items) do
	itemById[item.id] = item
	if item.type == "cycle" then
		state[item.id] = 1 -- index into options
	elseif item.type == "toggle" then
		state[item.id] = item.default == true
	elseif item.type == "count" then
		state[item.id] = item.default or 0
	end
end

--------------------------------------------------------------------------
-- UI BUILDING
--------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "SettingsPanel"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(THEME.panelWidth, THEME.panelHeight)
panel.BackgroundColor3 = THEME.panel
panel.BorderSizePixel = 0
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = THEME.panelCorner

local panelStroke = Instance.new("UIStroke", panel)
panelStroke.Color = Color3.fromRGB(215, 215, 215)
panelStroke.Thickness = 2

local scroller = Instance.new("ScrollingFrame")
scroller.Name = "Scroller"
scroller.Size = UDim2.fromScale(1, 1)
scroller.BackgroundTransparency = 1
scroller.BorderSizePixel = 0
scroller.ScrollBarThickness = 4
scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroller.CanvasSize = UDim2.new()
scroller.Parent = panel

local pad = Instance.new("UIPadding", scroller)
pad.PaddingTop = UDim.new(0, THEME.padding)
pad.PaddingBottom = UDim.new(0, THEME.padding)
pad.PaddingLeft = UDim.new(0, THEME.padding)
pad.PaddingRight = UDim.new(0, THEME.padding)

local list = Instance.new("UIListLayout", scroller)
list.Padding = UDim.new(0, THEME.gap)
list.SortOrder = Enum.SortOrder.LayoutOrder

local function makeButton(name, order, height)
	local b = Instance.new("TextButton")
	b.Name = name
	b.LayoutOrder = order
	b.Size = UDim2.new(1, 0, 0, height)
	b.AutoButtonColor = false
	b.BorderSizePixel = 0
	b.FontFace = FONT_BOLD
	b.TextSize = 18
	b.TextXAlignment = Enum.TextXAlignment.Left
	b.Parent = scroller
	Instance.new("UICorner", b).CornerRadius = THEME.corner

	local p = Instance.new("UIPadding", b)
	p.PaddingLeft = UDim.new(0, 14)
	return b
end

local function styleGrey(b)
	b.BackgroundColor3 = THEME.rowGrey
	b.TextColor3 = THEME.textDark
	b.TextStrokeColor3 = THEME.strokeGrey
	b.TextStrokeTransparency = 0.6
end

local function styleBlue(b)
	b.BackgroundColor3 = THEME.blue
	b.TextColor3 = THEME.textLight
	b.TextStrokeColor3 = THEME.strokeWhite
	b.TextStrokeTransparency = 0.35
end

-- Master button -----------------------------------------------------------
local master = makeButton("Master", 0, THEME.masterHeight)
master.TextXAlignment = Enum.TextXAlignment.Center
master.TextColor3 = THEME.textLight
master.TextSize = 20
master.TextStrokeTransparency = 1
master.TextStrokeColor3 = THEME.textLight

local function refreshMaster()
	master.BackgroundColor3 = state.master and THEME.green or THEME.red
	master.Text = ("%s: %s"):format(CONFIG.master.label, state.master and "ON" or "OFF")
end

master.Activated:Connect(function()
	state.master = not state.master
	refreshMaster()
	onChanged("master", state.master)
end)

-- Item rows ---------------------------------------------------------------
local refreshers = {}

for i, item in ipairs(CONFIG.items) do
	local b = makeButton(item.id, i, THEME.rowHeight)

	local function refresh()
		if item.type == "cycle" then
			styleGrey(b)
			b.Text = ("%s: [ %s ]"):format(item.label, item.options[state[item.id]])
		elseif item.type == "toggle" then
			if state[item.id] then
				styleBlue(b)
			else
				styleGrey(b)
			end
			b.Text = ("%s: %s"):format(item.label, state[item.id] and "ON" or "OFF")
		elseif item.type == "count" then
			styleGrey(b)
			b.Text = ("%s: [ %d Selected ]"):format(item.label, state[item.id])
		end
	end
	refreshers[item.id] = refresh
	refresh()

	b.Activated:Connect(function()
		if item.type == "cycle" then
			state[item.id] = (state[item.id] % #item.options) + 1
			refresh()
			onChanged(item.id, item.options[state[item.id]])
		elseif item.type == "toggle" then
			state[item.id] = not state[item.id]
			refresh()
			onChanged(item.id, state[item.id])
		elseif item.type == "count" then
			-- Open your own picker here, then call setCount(item.id, n)
			onChanged(item.id, state[item.id])
		end
	end)
end

-- Footer ------------------------------------------------------------------
if CONFIG.footer then
	local footer = Instance.new("TextLabel")
	footer.Name = "Footer"
	footer.LayoutOrder = #CONFIG.items + 1
	footer.Size = UDim2.new(1, 0, 0, 28)
	footer.BackgroundTransparency = 1
	footer.FontFace = FONT_REG
	footer.TextSize = 16
	footer.TextColor3 = THEME.footer
	footer.TextXAlignment = Enum.TextXAlignment.Left
	footer.Text = CONFIG.footer
	footer.Parent = scroller
	Instance.new("UIPadding", footer).PaddingLeft = UDim.new(0, 2)
end

refreshMaster()

--------------------------------------------------------------------------
-- Optional: update a "count" row from your own code
--------------------------------------------------------------------------
local function setCount(id, n)
	state[id] = n
	if refreshers[id] then refreshers[id]() end
end
_G.SettingsPanelSetCount = setCount -- or move this into a ModuleScript