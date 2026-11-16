-- Luau | Eclipse.lua | Roblox LocalScript / executor | Eclipse UI library (black & white)
-- API:
--   local win = Eclipse:CreateWindow({ Title = "Eclipse", Keybind = Enum.KeyCode.RightShift
--   local tab = win:AddTab({ Name = "General", Icon = "crosshair" })   -- crosshair|eye|steps
--   local sec = tab:AddSection({ Name = "Main", Side = "Left" })
--   sec:AddToggle / AddSlider / AddDropdown / AddButton / AddTextbox / AddKeybind / AddLabel
--   win:Notify({ Title = "", Text = "", Duration = 4 })


local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")


local Theme = {
          Background = Color3.fromRGB(8, 8, 8),
          Panel = Color3.fromRGB(17, 17, 17),
          Element = Color3.fromRGB(27, 27, 27),
          Hover = Color3.fromRGB(38, 38, 38),
          Stroke = Color3.fromRGB(40, 40, 40),
          Accent = Color3.fromRGB(255, 255, 255),
          Text = Color3.fromRGB(255, 255, 255),
          SubText = Color3.fromRGB(140, 140, 140),
          Dim = Color3.fromRGB(90, 90, 90),
}


local FONT = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold


-- helpers ---------------------------------------------------------------


local function create(class, props, children)
          local inst = Instance.new(class)
          local parent
          for k, v in pairs(props or {}) do
                  if k == "Parent" then
                          parent = v
                  else
                          inst[k] = v
                  end
          end
          for _, c in ipairs(children or {}) do
                c.Parent = inst
        end
        if parent then
                inst.Parent = parent
        end
        return inst
end


local function corner(r)
        return create("UICorner", { CornerRadius = UDim.new(0, r) })
end


local function stroke(color, thickness)
        return create("UIStroke", {
                Color = color or Theme.Stroke,
                Thickness = thickness or 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        })
end


local function pad(l, r, t, b)
        return create("UIPadding", {
                PaddingLeft = UDim.new(0, l or 0),
                PaddingRight = UDim.new(0, r or 0),
                PaddingTop = UDim.new(0, t or 0),
                PaddingBottom = UDim.new(0, b or 0),
        })
end


local function list(padding, dir)
        return create("UIListLayout", {
                Padding = UDim.new(0, padding or 0),
                FillDirection = dir or Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
        })
end


local function tween(inst, props, t)
        local tw = TweenService:Create(inst, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad,
        tw:Play()
        return tw
end


local function label(props)
        local p = {
                BackgroundTransparency = 1,
                Font = FONT,
                TextSize = 14,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = "",
        }
        for k, v in pairs(props) do
                p[k] = v
        end
        return create("TextLabel", p)
end


local function is_press(input)
        return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType
end


-- Follows ONE specific pointer. A touch is matched by its own InputObject, so a
-- second finger (walk stick, jump button, etc.) can never hijack the drag.
local function track_drag(input, on_move, on_end)
        local conns = {}
        local done = false
        local is_touch = input.UserInputType == Enum.UserInputType.Touch
        local function finish()
                if done then
                           return
                end
                done = true
                for _, c in ipairs(conns) do
                           c:Disconnect()
                end
                if on_end then
                           on_end()
                end
        end
        table.insert(conns, UserInputService.InputChanged:Connect(function(i)
                if is_touch then
                           if i == input then
                                      on_move(i)
                           end
                elseif i.UserInputType == Enum.UserInputType.MouseMovement then
                           on_move(i)
                end
        end))
        table.insert(conns, UserInputService.InputEnded:Connect(function(i)
                if i == input or (not is_touch and i.UserInputType == Enum.UserInputType.Mous
                           finish()
                end
        end))
        table.insert(conns, input.Changed:Connect(function()
                   if input.UserInputState == Enum.UserInputState.End then
                           finish()
                   end
        end))
        return finish
end


-- Vector tab icons built from Frames (no asset ids needed).
-- Each builder returns a list of { inst, kind } so the tab can recolor them.
local function icon_part(parent, props, kind, round)
        local f = create("Frame", props)
        f.BorderSizePixel = 0
        f.Parent = parent
        if round then
                   create("UICorner", { CornerRadius = UDim.new(round, 0), Parent = f })
        end
        if kind == "stroke" then
                   f.BackgroundTransparency = 1
                   local s = create("UIStroke", { Color = Theme.SubText, Thickness = 1.6, Parent
                   return { inst = s, kind = "stroke" }
        end
        f.BackgroundColor3 = Theme.SubText
        return { inst = f, kind = "fill" }
end


local Icons = {}


local function circle(parent, size, pos, kind)
        local p = icon_part(parent, {
                   AnchorPoint = Vector2.new(0.5, 0.5),
                   Position = pos,
                   Size = size,
        }, kind, 1)
        return p
end


function Icons.crosshair(root)
        local parts = {}
        table.insert(parts, circle(root, UDim2.fromOffset(16, 16), UDim2.fromScale(0.5, 0.5),
        table.insert(parts, circle(root, UDim2.fromOffset(3, 3), UDim2.fromScale(0.5, 0.5), "
        local function tick(x, y, w, h)
                   table.insert(parts, icon_part(root, {
                           AnchorPoint = Vector2.new(0.5, 0.5),
                           Position = UDim2.new(0, x, 0, y),
                           Size = UDim2.fromOffset(w, h),
                   }, "fill"))
        end
        tick(12, 1.5, 1.6, 5)
        tick(12, 22.5, 1.6, 5)
        tick(1.5, 12, 5, 1.6)
        tick(22.5, 12, 5, 1.6)
        return parts
end


function Icons.eye(root)
        local parts = {}
        table.insert(parts, circle(root, UDim2.fromOffset(22, 14), UDim2.fromScale(0.5, 0.5),
        table.insert(parts, circle(root, UDim2.fromOffset(7, 7), UDim2.fromScale(0.5, 0.5), "
        return parts
end


function Icons.steps(root)
        local parts = {}
        local function foot(x, y, w, h)
                table.insert(parts, icon_part(root, {
                           AnchorPoint = Vector2.new(0.5, 0.5),
                           Position = UDim2.new(0, x, 0, y),
                           Size = UDim2.fromOffset(w, h),
                }, "stroke", 1))
        end
        foot(8, 9, 7, 11)
        foot(17, 15, 7, 11)
        return parts
end


function Icons.person(root)
        local parts = {}
        table.insert(parts, circle(root, UDim2.fromOffset(9, 9), UDim2.new(0.5, 0, 0, 7), "st
        -- shoulders: oversized rounded box, bottom half clipped away
        local clip = create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, 15),
                Size = UDim2.fromOffset(18, 9),
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                Parent = root,
        })
        local body = circle(clip, UDim2.fromOffset(18, 18), UDim2.new(0.5, 0, 0, 9), "stroke"
        table.insert(parts, body)
        return parts
end


function Icons.wrench(root)
        local parts = {}
        local bar = icon_part(root, {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(4, 20),
                Rotation = 45,
        }, "fill", 1)
        table.insert(parts, bar)
        table.insert(parts, circle(root, UDim2.fromOffset(10, 10), UDim2.new(0, 17.5, 0, 6.5)
        return parts
end


function Icons.gear(root)
        local parts = {}
        for i = 0, 7 do
                local arm = create("Frame", {
                           AnchorPoint = Vector2.new(0.5, 0.5),
                           Position = UDim2.fromScale(0.5, 0.5),
                           Size = UDim2.fromOffset(24, 24),
                           BackgroundTransparency = 1,
                           Rotation = i * 45,
                           Parent = root,
                })
                table.insert(parts, icon_part(arm, {
                           AnchorPoint = Vector2.new(0.5, 0),
                           Position = UDim2.new(0.5, 0, 0, 0),
                           Size = UDim2.fromOffset(4, 5),
                }, "fill", 0.2))
        end
        table.insert(parts, circle(root, UDim2.fromOffset(15, 15), UDim2.fromScale(0.5, 0.5),
        table.insert(parts, circle(root, UDim2.fromOffset(6, 6), UDim2.fromScale(0.5, 0.5), "
        return parts
end


local function build_icon(parent, spec)
        local root = create("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 16, 0.5, 0),
                Size = UDim2.fromOffset(24, 24),
                BackgroundTransparency = 1,
                Parent = parent,
        })
        -- custom image asset: pass Icon = "rbxassetid://123"
        if type(spec) == "string" and spec:find("rbxassetid") then
                local img = create("ImageLabel", {
                           Size = UDim2.fromScale(1, 1),
                           BackgroundTransparency = 1,
                          Image = spec,
                          ImageColor3 = Theme.SubText,
                          Parent = root,
                })
                return { { inst = img, kind = "image" } }
        end
        local builder = Icons[spec]
        if builder then
                return builder(root)
        end
        return {}
end


local function tint_icon(parts, color)
        for _, p in ipairs(parts) do
                if p.kind == "stroke" then
                          tween(p.inst, { Color = color })
                elseif p.kind == "fill" then
                          tween(p.inst, { BackgroundColor3 = color })
                elseif p.kind == "image" then
                          tween(p.inst, { ImageColor3 = color })
                end
        end
end


local function get_gui_parent()
        local ok, ui = pcall(function()
                if gethui then
                          return gethui()
                end
        end)
        if ok and ui then
                return ui
        end
        local ok2, core = pcall(function()
                return game:GetService("CoreGui")
        end)
        if ok2 and core then
                -- CoreGui writes can be blocked outside executors; probe it.
                local probe = Instance.new("ScreenGui")
                local wrote = pcall(function()
                          probe.Parent = core
                end)
                probe:Destroy()
                if wrote then
                          return core
                end
        end
        return Players.LocalPlayer:WaitForChild("PlayerGui")
end


-- config storage helpers -------------------------------------------------


local has_fs = type(writefile) == "function"
        and type(readfile) == "function"
        and type(isfile) == "function"
        and type(isfolder) == "function"
        and type(makefolder) == "function"
        and type(listfiles) == "function"
        and type(delfile) == "function"


local function clean_name(s)
        s = tostring(s or "")
        s = s:gsub("[^%w%s_%-]", "")
        s = s:gsub("^%s+", "")
        s = s:gsub("%s+$", "")
        return s:sub(1, 40)
end


-- classes ---------------------------------------------------------------


local Eclipse = {}
local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab
local Section = {}
Section.__index = Section


-- Section elements ------------------------------------------------------


function Section:_row(height, name)
        local row = create("Frame", {
                 BackgroundTransparency = 1,
                 Size = UDim2.new(1, 0, 0, height),
                 LayoutOrder = self._order,
                 ClipsDescendants = true,
                 Parent = self._card,
        })
        if self._order > 1 then
                 create("Frame", {
                          BackgroundColor3 = Theme.Stroke,
                          BorderSizePixel = 0,
                          Size = UDim2.new(1, 0, 0, 1),
                            Parent = row,
                   })
        end
        self._order += 1
        table.insert(self._window._searchables, { tab = self._tab, row = row, name = name or
        return row
end


-- Elements created with a Flag are saved/loaded by the configuration system.
function Section:_register(opts, api, encode, decode)
        if not opts.Flag then
                   return
        end
        self._window._flags[opts.Flag] = {
                   get = function()
                            local v = api:Get()
                            if encode then
                                       return encode(v)
                            end
                            return v
                   end,
                   set = function(v)
                            if decode then
                                       v = decode(v)
                            end
                            api:Set(v)
                   end,
        }
end


function Section:AddLabel(text)
        local row = self:_row(32, text)
        local lbl = label({
                   Size = UDim2.fromScale(1, 1),
                   Text = text,
                   TextColor3 = Theme.SubText,
                   Parent = row,
        })
        return {
                   Set = function(_, t)
                            lbl.Text = t
                   end,
        }
end


function Section:AddToggle(opts)
        local state = opts.Default or false
local row = self:_row(42, opts.Name)


local box = create("Frame", {
        Size = UDim2.fromOffset(20, 20),
        Position = UDim2.new(0, 0, 0.5, -10),
        BackgroundColor3 = Theme.Element,
        Parent = row,
}, { corner(6), stroke(Theme.Stroke) })
local check = label({
        Size = UDim2.fromScale(1, 1),
        Text = "✓",
        Font = FONT_BOLD,
        TextSize = 14,
        TextColor3 = Theme.Background,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextTransparency = 1,
        Parent = box,
})
local name = label({
        Position = UDim2.new(0, 32, 0, 0),
        Size = UDim2.new(1, -32, 1, 0),
        Text = opts.Name,
        TextColor3 = Theme.SubText,
        Parent = row,
})
local btn = create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        Parent = row,
})


local api = {}
local function render()
        tween(box, { BackgroundColor3 = state and Theme.Accent or Theme.Element })
        tween(check, { TextTransparency = state and 0 or 1 })
        tween(name, { TextColor3 = state and Theme.Text or Theme.SubText })
end
function api:Set(v, silent)
        state = v and true or false
        render()
        if not silent and opts.Callback then
                   task.spawn(opts.Callback, state)
        end
end
function api:Get()
        return state
        end
        btn.MouseButton1Click:Connect(function()
                   api:Set(not state)
        end)
        render()
        self:_register(opts, api)
        return api
end


function Section:AddSlider(opts)
        local min, max = opts.Min or 0, opts.Max or 100
        local inc = opts.Increment or 1
        local suffix = opts.Suffix or ""
        local value = math.clamp(opts.Default or min, min, max)
        local row = self:_row(58, opts.Name)


        label({
                   Position = UDim2.new(0, 0, 0, 8),
                   Size = UDim2.new(0.6, 0, 0, 18),
                   Text = opts.Name,
                   TextColor3 = Theme.SubText,
                   Parent = row,
        })
        local val = label({
                   AnchorPoint = Vector2.new(1, 0),
                   Position = UDim2.new(1, 0, 0, 8),
                   Size = UDim2.new(0.4, 0, 0, 18),
                   TextXAlignment = Enum.TextXAlignment.Right,
                   Font = FONT_BOLD,
                   Parent = row,
        })
        local bar = create("Frame", {
                   Position = UDim2.new(0, 0, 0, 38),
                   Size = UDim2.new(1, 0, 0, 6),
                   BackgroundColor3 = Theme.Element,
                   Parent = row,
        }, { corner(3) })
        local fill = create("Frame", {
                   Size = UDim2.fromScale(0, 1),
                   BackgroundColor3 = Theme.Accent,
                   BorderSizePixel = 0,
                   Parent = bar,
        }, { corner(3) })
        local hit = create("TextButton", {
                   BackgroundTransparency = 1,
                   Position = UDim2.new(0, 0, 0, 28),
                   Size = UDim2.new(1, 0, 0, 26),
                   Text = "",
                   Parent = row,
        })


        local api = {}
        local function render()
                   local rel = (value - min) / math.max(max - min, 1e-9)
                   tween(fill, { Size = UDim2.fromScale(rel, 1) }, 0.08)
                   val.Text = tostring(value) .. suffix
        end
        function api:Set(v, silent)
                   v = math.clamp(math.round(v / inc) * inc, min, max)
                   -- keep float noise out of the display
                   value = tonumber(string.format("%.4f", v))
                   render()
                   if not silent and opts.Callback then
                              task.spawn(opts.Callback, value)
                   end
        end
        function api:Get()
                   return value
        end


        local function from_x(x)
                   local rel = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSi
                   api:Set(min + (max - min) * rel)
        end
        local active = false
        hit.InputBegan:Connect(function(input)
                   if active or not is_press(input) then
                              return
                   end
                   active = true
                   from_x(input.Position.X)
                   track_drag(input, function(i)
                              from_x(i.Position.X)
                   end, function()
                              active = false
                   end)
        end)
        render()
        self:_register(opts, api)
        return api
end


function Section:AddDropdown(opts)
        local options = opts.Options or {}
local allow_empty = opts.AllowEmpty
local placeholder = opts.Placeholder or "..."
local selected
if allow_empty then
          selected = opts.Default
else
          selected = opts.Default or options[1]
end
local open = false
local COLLAPSED = 70
local row = self:_row(COLLAPSED, opts.Name)


label({
          Position = UDim2.new(0, 0, 0, 8),
          Size = UDim2.new(1, 0, 0, 18),
          Text = opts.Name,
          TextColor3 = Theme.SubText,
          Parent = row,
})
local head = create("TextButton", {
          Position = UDim2.new(0, 0, 0, 32),
          Size = UDim2.new(1, 0, 0, 32),
          BackgroundColor3 = Theme.Element,
          AutoButtonColor = false,
          Text = "",
          Parent = row,
}, { corner(8) })
local cur = label({
          Position = UDim2.new(0, 12, 0, 0),
          Size = UDim2.new(1, -36, 1, 0),
          Parent = head,
})
local arrow = label({
          AnchorPoint = Vector2.new(1, 0),
          Position = UDim2.new(1, -10, 0, 0),
          Size = UDim2.fromOffset(16, 32),
          Text = "v",
          TextColor3 = Theme.SubText,
          TextXAlignment = Enum.TextXAlignment.Center,
          Parent = head,
})
local holder = create("Frame", {
          Position = UDim2.new(0, 0, 0, 68),
          Size = UDim2.new(1, 0, 0, #options * 28),
          BackgroundTransparency = 1,
          Parent = row,
}, { list(0) })
local api = {}
local buttons = {}
local function render()
        cur.Text = (selected ~= nil) and tostring(selected) or placeholder
        cur.TextColor3 = (selected ~= nil) and Theme.Text or Theme.Dim
        for o, b in pairs(buttons) do
                   b.TextColor3 = (o == selected) and Theme.Text or Theme.SubText
        end
end
local function set_open(v)
        open = v
        arrow.Text = open and "^" or "v"
        tween(row, { Size = UDim2.new(1, 0, 0, open and (COLLAPSED + #options * 28 +
end
function api:Set(v, silent)
        selected = v
        render()
        if not silent and opts.Callback then
                   task.spawn(opts.Callback, selected)
        end
end
function api:Get()
        return selected
end


local function build()
        for _, b in pairs(buttons) do
                   b:Destroy()
        end
        buttons = {}
        holder.Size = UDim2.new(1, 0, 0, #options * 28)
        for i, o in ipairs(options) do
                   local b = create("TextButton", {
                           Size = UDim2.new(1, 0, 0, 28),
                           BackgroundTransparency = 1,
                           Text = tostring(o),
                           Font = FONT,
                           TextSize = 13,
                           TextColor3 = Theme.SubText,
                           TextXAlignment = Enum.TextXAlignment.Left,
                           LayoutOrder = i,
                           Parent = holder,
                   }, { pad(12, 0, 0, 0) })
                   buttons[o] = b
                   b.MouseButton1Click:Connect(function()
                           api:Set(o)
                                     set_open(false)
                             end)
                  end
                  render()
        end


        -- replace the option list at runtime (used by the config list)
        function api:SetOptions(new_options)
                  options = new_options or {}
                  local found = false
                  for _, o in ipairs(options) do
                             if o == selected then
                                     found = true
                             end
                  end
                  if not found then
                             selected = (not allow_empty) and options[1] or nil
                  end
                  build()
                  if open then
                             set_open(true)
                  end
        end


        head.MouseButton1Click:Connect(function()
                  set_open(not open)
        end)
        head.MouseEnter:Connect(function()
                  tween(head, { BackgroundColor3 = Theme.Hover })
        end)
        head.MouseLeave:Connect(function()
                  tween(head, { BackgroundColor3 = Theme.Element })
        end)
        build()
        self:_register(opts, api)
        return api
end


function Section:AddButton(opts)
        local row = self:_row(48, opts.Name)
        local btn = create("TextButton", {
                  Position = UDim2.new(0, 0, 0, 8),
                  Size = UDim2.new(1, 0, 0, 34),
                  BackgroundColor3 = Theme.Element,
                  AutoButtonColor = false,
                  Text = opts.Name,
                  Font = FONT,
                TextSize = 14,
                TextColor3 = Theme.Text,
                Parent = row,
        }, { corner(8) })
        btn.MouseEnter:Connect(function()
                tween(btn, { BackgroundColor3 = Theme.Hover })
        end)
        btn.MouseLeave:Connect(function()
                tween(btn, { BackgroundColor3 = Theme.Element })
        end)
        btn.MouseButton1Click:Connect(function()
                tween(btn, { BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Background }
                task.delay(0.12, function()
                        tween(btn, { BackgroundColor3 = Theme.Element, TextColor3 = Theme.Tex
                end)
                if opts.Callback then
                        task.spawn(opts.Callback)
                end
        end)
end


function Section:AddButtonRow(buttons)
        local row = self:_row(48, (buttons[1] and buttons[1].Name) or "")
        for i, b in ipairs(buttons) do
                local btn = create("TextButton", {
                        Position = UDim2.new((i - 1) / #buttons, (i == 1) and 0 or 3, 0, 8),
                        Size = UDim2.new(1 / #buttons, -3, 0, 34),
                        BackgroundColor3 = Theme.Element,
                        AutoButtonColor = false,
                        Text = b.Name,
                        Font = FONT,
                        TextSize = 14,
                        TextColor3 = Theme.Text,
                        Parent = row,
                }, { corner(8) })
                table.insert(self._window._searchables, { tab = self._tab, row = row, name =
                btn.MouseEnter:Connect(function()
                        tween(btn, { BackgroundColor3 = Theme.Hover })
                end)
                btn.MouseLeave:Connect(function()
                        tween(btn, { BackgroundColor3 = Theme.Element })
                end)
                btn.MouseButton1Click:Connect(function()
                        tween(btn, { BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Back
                        task.delay(0.12, function()
                                 tween(btn, { BackgroundColor3 = Theme.Element, TextColor3 = T
                        end)
                          if b.Callback then
                                    task.spawn(b.Callback)
                          end
                  end)
        end
end


function Section:AddTextbox(opts)
        local row = self:_row(70, opts.Name)
        label({
                  Position = UDim2.new(0, 0, 0, 8),
                  Size = UDim2.new(1, 0, 0, 18),
                  Text = opts.Name,
                  TextColor3 = Theme.SubText,
                  Parent = row,
        })
        local box = create("TextBox", {
                  Position = UDim2.new(0, 0, 0, 32),
                  Size = UDim2.new(1, 0, 0, 32),
                  BackgroundColor3 = Theme.Element,
                  Text = opts.Default or "",
                  PlaceholderText = opts.Placeholder or "",
                  PlaceholderColor3 = Theme.Dim,
                  TextColor3 = Theme.Text,
                  Font = FONT,
                  TextSize = 14,
                  ClearTextOnFocus = false,
                  Parent = row,
        }, { corner(8), pad(12, 12, 0, 0) })
        box.FocusLost:Connect(function(enter)
                  if opts.Callback then
                          task.spawn(opts.Callback, box.Text, enter)
                  end
        end)
        local api = {}
        function api:Get()
                  return box.Text
        end
        function api:Set(t, silent)
                  box.Text = tostring(t or "")
                  if not silent and opts.Callback then
                          task.spawn(opts.Callback, box.Text, false)
                  end
        end
        self:_register(opts, api)
        return api
end
function Section:AddKeybind(opts)
        local key = opts.Default
        local listening = false
        local row = self:_row(42, opts.Name)
        label({
                  Size = UDim2.new(1, -90, 1, 0),
                  Text = opts.Name,
                  TextColor3 = Theme.SubText,
                  Parent = row,
        })
        local btn = create("TextButton", {
                  AnchorPoint = Vector2.new(1, 0.5),
                  Position = UDim2.new(1, 0, 0.5, 0),
                  Size = UDim2.fromOffset(80, 26),
                  BackgroundColor3 = Theme.Element,
                  AutoButtonColor = false,
                  Font = FONT,
                  TextSize = 13,
                  TextColor3 = Theme.Text,
                  Text = "",
                  Parent = row,
        }, { corner(6) })
        local api = {}
        local function render()
                  btn.Text = listening and "..." or (key and key.Name or "None")
        end
        function api:Get()
                  return key
        end
        function api:Set(k)
                  key = k
                  listening = false
                  render()
        end
        btn.MouseButton1Click:Connect(function()
                  listening = true
                  render()
        end)
        table.insert(self._window._connections, UserInputService.InputBegan:Connect(function(
                  if listening then
                             if input.UserInputType == Enum.UserInputType.Keyboard then
                                     if input.KeyCode == Enum.KeyCode.Escape then
                                             key = nil
                                     else
                                             key = input.KeyCode
                                     end
                                      listening = false
                                      render()
                                      if opts.OnChange then
                                                 task.spawn(opts.OnChange, key)
                                      end
                           end
                   elseif not gp and key and input.KeyCode == key and opts.Callback then
                           task.spawn(opts.Callback)
                   end
        end))
        render()
        self:_register(opts, api, function(k)
                   return k and k.Name or ""
        end, function(name)
                   local ok, k = pcall(function()
                           return Enum.KeyCode[name]
                   end)
                   return ok and k or nil
        end)
        return api
end


-- Tab -------------------------------------------------------------------


function Tab:AddSection(opts)
        local side = opts.Side
        if not side then
                   side = (self._count % 2 == 0) and "Left" or "Right"
        end
        self._count += 1
        local column = (side == "Right") and self._right or self._left


        local holder = create("Frame", {
                   BackgroundTransparency = 1,
                   AutomaticSize = Enum.AutomaticSize.Y,
                   Size = UDim2.fromScale(1, 0),
                   LayoutOrder = self._count,
                   Parent = column,
        }, { list(8) })
        label({
                   Size = UDim2.new(1, 0, 0, 20),
                   Text = opts.Name,
                   TextColor3 = Theme.SubText,
                   Font = FONT,
                   TextSize = 15,
                   LayoutOrder = 0,
                   Parent = holder,
        })
        local card = create("Frame", {
                BackgroundColor3 = Theme.Panel,
                AutomaticSize = Enum.AutomaticSize.Y,
                Size = UDim2.fromScale(1, 0),
                LayoutOrder = 1,
                Parent = holder,
        }, { corner(12), pad(14, 14, 0, 4), list(0) })


        return setmetatable({
                _window = self._window,
                _tab = self,
                _card = card,
                _order = 1,
        }, Section)
end


-- Window ----------------------------------------------------------------


function Window:AddTab(opts)
        local tab = setmetatable({ _window = self, _count = 0, Name = opts.Name }, Tab)


        local btn = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundColor3 = Theme.Panel,
                BackgroundTransparency = 1,
                AutoButtonColor = false,
                Text = "",
                LayoutOrder = #self._tabs + 1,
                Parent = self._tabList,
        }, { corner(8) })
        local bar = create("Frame", {
                Size = UDim2.new(0, 3, 0.6, 0),
                Position = UDim2.new(0, 0, 0.2, 0),
                BackgroundColor3 = Theme.Accent,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Parent = btn,
        }, { corner(2) })
        local icon_parts = build_icon(btn, opts.Icon)
        local txt = label({
                Position = UDim2.new(0, 52, 0, 0),
                Size = UDim2.new(1, -52, 1, 0),
                Text = opts.Name,
                TextColor3 = Theme.SubText,
                Parent = btn,
        })
local page = create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Dim,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = self._pages,
}, { pad(0, 4, 0, 16), list(14, Enum.FillDirection.Horizontal) })
local function column(order)
        return create("Frame", {
                   BackgroundTransparency = 1,
                   AutomaticSize = Enum.AutomaticSize.Y,
                   Size = UDim2.new(0.5, -7, 0, 0),
                   LayoutOrder = order,
                   Parent = page,
        }, { list(18) })
end
tab._left = column(1)
tab._right = column(2)
tab._page = page
tab._btn = btn
tab._bar = bar
tab._txt = txt
tab._icon = icon_parts


btn.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
end)
btn.MouseEnter:Connect(function()
        if self._active ~= tab then
                   tween(btn, { BackgroundTransparency = 0.6 })
        end
end)
btn.MouseLeave:Connect(function()
        if self._active ~= tab then
                   tween(btn, { BackgroundTransparency = 1 })
        end
end)


table.insert(self._tabs, tab)
if not self._active then
        self:SelectTab(tab)
end
        return tab
end


function Window:_applySearch()
        local q = string.lower(self._search.Text)
        for _, s in ipairs(self._searchables) do
                if s.tab == self._active then
                           s.row.Visible = (q == "") or (string.find(string.lower(s.name), q, 1,
                else
                           s.row.Visible = true
                end
        end
end


function Window:SelectTab(tab)
        self._active = tab
        for _, t in ipairs(self._tabs) do
                local on = (t == tab)
                t._page.Visible = on
                tween(t._btn, { BackgroundTransparency = on and 0 or 1 })
                tween(t._bar, { BackgroundTransparency = on and 0 or 1 })
                tween(t._txt, { TextColor3 = on and Theme.Text or Theme.SubText })
                tint_icon(t._icon, on and Theme.Text or Theme.SubText)
        end
        self._crumb.Text = tab.Name
        self:_applySearch()
end


function Window:SetVisible(v)
        self._visible = v
        self._main.Visible = v
end


function Window:Toggle()
        self:SetVisible(not self._visible)
end


function Window:Notify(opts)
        local n = create("Frame", {
                BackgroundColor3 = Theme.Panel,
                AutomaticSize = Enum.AutomaticSize.Y,
                Size = UDim2.new(1, 0, 0, 0),
                Parent = self._notifs,
        }, {
                corner(10),
                stroke(Theme.Stroke),
                pad(14, 14, 10, 10),
                  list(2),
        })
        label({
                  Size = UDim2.new(1, 0, 0, 18),
                  Text = opts.Title or "Eclipse",
                  Font = FONT_BOLD,
                  LayoutOrder = 1,
                  Parent = n,
        })
        label({
                  Size = UDim2.new(1, 0, 0, 16),
                  AutomaticSize = Enum.AutomaticSize.Y,
                  Text = opts.Text or "",
                  TextColor3 = Theme.SubText,
                  TextSize = 13,
                  TextWrapped = true,
                  LayoutOrder = 2,
                  Parent = n,
        })
        task.delay(opts.Duration or 4, function()
                  if n and n.Parent then
                             n:Destroy()
                  end
        end)
end


function Window:Destroy()
        for _, c in ipairs(self._connections) do
                  c:Disconnect()
        end
        self._gui:Destroy()
end


-- Configuration ----------------------------------------------------------


function Window:_ensure()
        if not has_fs then
                  return
        end
        if not isfolder(self._folder) then
                  makefolder(self._folder)
        end
        local dir = self._folder .. "/configs"
        if not isfolder(dir) then
                  makefolder(dir)
        end
end
function Window:_path(name)
        return self._folder .. "/configs/" .. name .. ".json"
end


function Window:_read(name)
        if has_fs then
                local p = self:_path(name)
                if isfile(p) then
                           local ok, data = pcall(readfile, p)
                           return ok and data or nil
                end
                return nil
        end
        return self._mem[name]
end


function Window:ConfigExists(name)
        return self:_read(name) ~= nil
end


function Window:ListConfigs()
        local out = {}
        if has_fs then
                self:_ensure()
                local ok, files = pcall(listfiles, self._folder .. "/configs")
                if ok then
                           for _, path in ipairs(files) do
                                   local n = tostring(path):match("([^/\\]+)%.json$")
                                   if n then
                                           table.insert(out, n)
                                   end
                           end
                end
        else
                for n in pairs(self._mem) do
                           table.insert(out, n)
                end
        end
        table.sort(out, function(a, b)
                return a:lower() < b:lower()
        end)
        return out
end


function Window:GetConfigJson()
        local flags = {}
        for flag, e in pairs(self._flags) do
                flags[flag] = e.get()
        end
        return HttpService:JSONEncode({ version = 1, flags = flags })
end


function Window:ApplyConfigJson(json)
        local ok, data = pcall(function()
                return HttpService:JSONDecode(json)
        end)
        if not ok or type(data) ~= "table" or type(data.flags) ~= "table" then
                return false
        end
        for flag, v in pairs(data.flags) do
                local e = self._flags[flag]
                if e then
                           pcall(e.set, v)
                end
        end
        return true
end


function Window:SaveConfig(name)
        name = clean_name(name)
        if name == "" then
                return false
        end
        local json = self:GetConfigJson()
        if has_fs then
                self:_ensure()
                writefile(self:_path(name), json)
        else
                self._mem[name] = json
        end
        return true
end


function Window:LoadConfig(name)
        local json = self:_read(name)
        if not json then
                return false
        end
        return self:ApplyConfigJson(json)
end


function Window:DeleteConfig(name)
        if has_fs then
                local p = self:_path(name)
                if isfile(p) then
                         delfile(p)
                         return true
                end
                return false
        end
        local had = self._mem[name] ~= nil
        self._mem[name] = nil
        return had
end


function Window:GetAutoload()
        if has_fs then
                local p = self._folder .. "/autoload.txt"
                if isfile(p) then
                         local ok, data = pcall(readfile, p)
                         if ok and data and data ~= "" then
                                 return data
                         end
                end
                return nil
        end
        return self._mem_autoload
end


function Window:SetAutoload(name)
        if has_fs then
                self:_ensure()
                writefile(self._folder .. "/autoload.txt", name or "")
        else
                self._mem_autoload = name
        end
end


-- call once after every element has been created
function Window:LoadAutoload()
        local n = self:GetAutoload()
        if n and self:LoadConfig(n) then
                self:Notify({ Title = "Configuration", Text = "Autoloaded " .. n, Duration =
        end
end


function Window:AddSettingsTab(opts)
        opts = opts or {}
        local tab = self:AddTab({ Name = opts.Name or "Settings", Icon = "gear" })
        local sec = tab:AddSection({ Name = "Configuration", Side = "Left" })
local function say(text)
        self:Notify({ Title = "Configuration", Text = text, Duration = 3 })
end


local name_box = sec:AddTextbox({ Name = "Config name", Placeholder = "Enter a name..
local list_dd = sec:AddDropdown({ Name = "Config list", Options = {}, AllowEmpty = tr
local autoload_label


local function refresh()
        list_dd:SetOptions(self:ListConfigs())
        autoload_label:Set("Current autoload config: " .. (self:GetAutoload() or "Non
end
local function selected_config()
        local sel = list_dd:Get()
        if not sel then
                 say("Select a config from the list first.")
        end
        return sel
end


sec:AddButtonRow({
        { Name = "Create config", Callback = function()
                 local n = clean_name(name_box:Get())
                 if n == "" then
                           say("Enter a config name first.")
                           return
                 end
                 if self:ConfigExists(n) then
                           say(n .. " already exists. Use Overwrite config.")
                           return
                 end
                 self:SaveConfig(n)
                 name_box:Set("", true)
                 refresh()
                 list_dd:Set(n, true)
                 say("Created " .. n)
        end },
        { Name = "Load config", Callback = function()
                 local n = selected_config()
                 if not n then
                           return
                 end
                 say(self:LoadConfig(n) and ("Loaded " .. n) or ("Could not load " ..
        end },
})
sec:AddButtonRow({
         { Name = "Overwrite config", Callback = function()
                   local n = selected_config()
                   if not n then
                           return
                   end
                   self:SaveConfig(n)
                   say("Overwrote " .. n)
         end },
         { Name = "Delete config", Callback = function()
                   local n = selected_config()
                   if not n then
                           return
                   end
                   self:DeleteConfig(n)
                   if self:GetAutoload() == n then
                           self:SetAutoload(nil)
                   end
                   refresh()
                   say("Deleted " .. n)
         end },
})
sec:AddButton({ Name = "Refresh list", Callback = function()
         refresh()
end })
sec:AddButtonRow({
         { Name = "Set autoload", Callback = function()
                   local n = selected_config()
                   if not n then
                           return
                   end
                   self:SetAutoload(n)
                   refresh()
                   say("Autoload set to " .. n)
         end },
         { Name = "Remove autoload", Callback = function()
                   self:SetAutoload(nil)
                   refresh()
                   say("Autoload removed.")
         end },
})
autoload_label = sec:AddLabel("Current autoload config: None")


local import_box
import_box = sec:AddTextbox({
         Name = "Import from clipboard",
         Placeholder = "Paste config here...",
         Callback = function(text)
                          if text == "" then
                                    return
                          end
                          say(self:ApplyConfigJson(text) and "Config imported." or "Invalid con
                          import_box:Set("", true)
                 end,
        })
        sec:AddButton({ Name = "Copy config to clipboard", Callback = function()
                 local clip = setclipboard or toclipboard
                 if clip then
                          clip(self:GetConfigJson())
                          say("Config copied.")
                 else
                          say("Clipboard is not supported here.")
                 end
        end })


        refresh()
        if not has_fs then
                 say("File API not found. Configs only last for this session.")
        end
        return tab
end


function Eclipse:CreateWindow(opts)
        opts = opts or {}
        local title = opts.Title or "Eclipse"
        local self = setmetatable({
                 _tabs = {},
                 _searchables = {},
                 _connections = {},
                 _visible = true,
                 _flags = {},
                 _mem = {},
                 _mem_autoload = nil,
                 _folder = opts.Folder or "Eclipse",
        }, Window)


        local gui = create("ScreenGui", {
                 Name = "Eclipse_" .. tostring(math.random(1000, 9999)),
                 ResetOnSpawn = false,
                 ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
                 IgnoreGuiInset = true,
        })
        gui.Parent = get_gui_parent()
        self._gui = gui
-- watermark
local wm = create("Frame", {
           AnchorPoint = Vector2.new(0.5, 0),
           Position = UDim2.new(0.5, 0, 0, 16),
           Size = UDim2.new(0, 0, 0, 38),
           AutomaticSize = Enum.AutomaticSize.X,
           BackgroundColor3 = Theme.Background,
           Parent = gui,
}, {
           corner(10),
           stroke(Theme.Stroke),
           pad(16, 16, 0, 0),
           create("UIListLayout", {
                      FillDirection = Enum.FillDirection.Horizontal,
                      VerticalAlignment = Enum.VerticalAlignment.Center,
                      Padding = UDim.new(0, 12),
                      SortOrder = Enum.SortOrder.LayoutOrder,
           }),
})
local order = 0
local function wm_seg(text, bold)
           order += 1
           local l = label({
                      Size = UDim2.new(0, 0, 0, 38),
                      AutomaticSize = Enum.AutomaticSize.X,
                      Text = text,
                      Font = bold and FONT_BOLD or FONT,
                      TextSize = bold and 18 or 13,
                      TextColor3 = bold and Theme.Text or Theme.SubText,
                      LayoutOrder = order,
                      Parent = wm,
           })
           return l
end
local function wm_sep()
           order += 1
           create("Frame", {
                      Size = UDim2.fromOffset(1, 16),
                      BackgroundColor3 = Theme.Stroke,
                      BorderSizePixel = 0,
                      LayoutOrder = order,
                      Parent = wm,
           })
end
wm_seg(title, true)
wm_sep()
local wm_game = wm_seg("...")
wm_sep()
local wm_fps = wm_seg("0 fps")
wm_sep()
local wm_ping = wm_seg("0 ms")
wm_sep()
local wm_time = wm_seg("00:00:00")


task.spawn(function()
           local ok, info = pcall(function()
                   return MarketplaceService:GetProductInfo(game.PlaceId)
           end)
           wm_game.Text = (ok and info and info.Name) or "Unknown"
end)
local frames, acc = 0, 0
table.insert(self._connections, RunService.RenderStepped:Connect(function(dt)
           frames += 1
           acc += dt
           if acc >= 0.5 then
                   wm_fps.Text = math.floor(frames / acc) .. " fps"
                   local ok, ping = pcall(function()
                            return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:
                   end)
                   wm_ping.Text = (ok and ping or 0) .. " ms"
                   wm_time.Text = os.date("%H:%M:%S")
                   frames, acc = 0, 0
           end
end))


-- main window
local main = create("Frame", {
           AnchorPoint = Vector2.new(0.5, 0.5),
           Position = UDim2.fromScale(0.5, 0.52),
           Size = UDim2.fromOffset(700, 460),
           BackgroundColor3 = Theme.Background,
           Parent = gui,
}, { corner(18), stroke(Theme.Stroke) })
self._main = main


-- sidebar
local sidebar = create("Frame", {
           Size = UDim2.new(0, 200, 1, 0),
           BackgroundTransparency = 1,
           Parent = main,
})
-- logo: white disc + black disc offset = crescent
local logo = create("Frame", {
           Position = UDim2.fromOffset(24, 26),
          Size = UDim2.fromOffset(28, 28),
          BackgroundColor3 = Theme.Accent,
          Parent = sidebar,
}, { corner(14) })
create("Frame", {
          Position = UDim2.fromOffset(9, -3),
          Size = UDim2.fromOffset(24, 24),
          BackgroundColor3 = Theme.Background,
          ZIndex = 2,
          Parent = logo,
}, { corner(12) })
logo.ClipsDescendants = true
label({
          Position = UDim2.fromOffset(64, 22),
          Size = UDim2.fromOffset(130, 36),
          Text = title,
          Font = FONT_BOLD,
          TextSize = 26,
          Parent = sidebar,
})


local search_wrap = create("Frame", {
          Position = UDim2.fromOffset(16, 76),
          Size = UDim2.new(1, -32, 0, 38),
          BackgroundColor3 = Theme.Panel,
          Parent = sidebar,
}, { corner(10) })
label({
          Position = UDim2.fromOffset(12, 0),
          Size = UDim2.fromOffset(18, 38),
          Text = "?",
          TextColor3 = Theme.Dim,
          Font = FONT_BOLD,
          TextXAlignment = Enum.TextXAlignment.Center,
          Parent = search_wrap,
})
local search = create("TextBox", {
          Position = UDim2.fromOffset(38, 0),
          Size = UDim2.new(1, -46, 1, 0),
          BackgroundTransparency = 1,
          Text = "",
          PlaceholderText = "Search",
          PlaceholderColor3 = Theme.Dim,
          TextColor3 = Theme.Text,
          Font = FONT,
          TextSize = 14,
          TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = search_wrap,
})
self._search = search
search:GetPropertyChangedSignal("Text"):Connect(function()
        self:_applySearch()
end)


create("Frame", {
        Position = UDim2.fromOffset(16, 128),
        Size = UDim2.new(1, -32, 0, 1),
        BackgroundColor3 = Theme.Stroke,
        BorderSizePixel = 0,
        Parent = sidebar,
})
self._tabList = create("Frame", {
        Position = UDim2.fromOffset(12, 142),
        Size = UDim2.new(1, -24, 1, -154),
        BackgroundTransparency = 1,
        Parent = sidebar,
}, { list(4) })


-- content
local content = create("Frame", {
        Position = UDim2.fromOffset(200, 0),
        Size = UDim2.new(1, -200, 1, 0),
        BackgroundTransparency = 1,
        Parent = main,
})
local drag = create("Frame", {
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundTransparency = 1,
        Active = true,
        Parent = content,
})
self._crumb = label({
        Position = UDim2.fromOffset(8, 18),
        Size = UDim2.new(1, -80, 0, 28),
        Text = "",
        TextSize = 18,
        Font = FONT_BOLD,
        Parent = content,
})
local close = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -20, 0, 16),
        Size = UDim2.fromOffset(32, 32),
        BackgroundColor3 = Theme.Panel,
        AutoButtonColor = false,
        Text = "X",
        Font = FONT_BOLD,
        TextSize = 14,
        TextColor3 = Theme.SubText,
        Parent = content,
}, { corner(8) })
close.MouseEnter:Connect(function()
        tween(close, { BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Background
end)
close.MouseLeave:Connect(function()
        tween(close, { BackgroundColor3 = Theme.Panel, TextColor3 = Theme.SubText })
end)
close.MouseButton1Click:Connect(function()
        self:SetVisible(false)
end)


self._pages = create("Frame", {
        Position = UDim2.fromOffset(8, 64),
        Size = UDim2.new(1, -24, 1, -72),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = content,
})


-- dragging
local win_dragging = false
drag.InputBegan:Connect(function(input)
        if win_dragging or not is_press(input) then
                return
        end
        win_dragging = true
        local start = input.Position
        local origin = main.Position
        track_drag(input, function(i)
                local d = i.Position - start
                main.Position = UDim2.new(origin.X.Scale, origin.X.Offset + d.X, orig
        end, function()
                win_dragging = false
        end)
end)


-- floating menu button: draggable, tap toggles the window.
-- Only the finger that grabbed the button can move it, so walking / jumping
-- with another finger never pulls it away.
local fab = create("TextButton", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, -50, 0.5, 0),
        Size = UDim2.fromOffset(52, 52),
        BackgroundColor3 = Theme.Background,
        AutoButtonColor = false,
        Text = "",
        Parent = gui,
}, { corner(26), stroke(Theme.Stroke) })
for i = 0, 2 do
        create("Frame", {
                  AnchorPoint = Vector2.new(0.5, 0.5),
                  Position = UDim2.new(0.5, 0, 0.5, (i - 1) * 7),
                  Size = UDim2.fromOffset(18, 2),
                  BackgroundColor3 = Theme.Accent,
                  BorderSizePixel = 0,
                  Parent = fab,
        })
end
local fab_busy = false
fab.Active = true
fab.InputBegan:Connect(function(input)
        if fab_busy or not is_press(input) then
                  return
        end
        fab_busy = true
        local start = input.Position
        local origin = fab.AbsolutePosition + fab.AbsoluteSize / 2
        local moved = false
        track_drag(input, function(i)
                  local d = i.Position - start
                  if not moved and d.Magnitude < 8 then
                           return
                  end
                  moved = true
                  local view = gui.AbsoluteSize
                  local half = fab.AbsoluteSize / 2
                  local x = math.clamp(origin.X + d.X, half.X, view.X - half.X)
                  local y = math.clamp(origin.Y + d.Y, half.Y, view.Y - half.Y)
                  fab.Position = UDim2.fromOffset(x, y)
        end, function()
                  fab_busy = false
                  if not moved then
                           self:Toggle()
                  end
        end)
end)
        -- notifications
        self._notifs = create("Frame", {
                   AnchorPoint = Vector2.new(1, 1),
                   Position = UDim2.new(1, -92, 1, -24),
                   Size = UDim2.new(0, 280, 1, -48),
                   BackgroundTransparency = 1,
                   Parent = gui,
        }, {
                   create("UIListLayout", {
                           Padding = UDim.new(0, 8),
                           VerticalAlignment = Enum.VerticalAlignment.Bottom,
                           SortOrder = Enum.SortOrder.LayoutOrder,
                   }),
        })


        -- toggle keybind
        local key = opts.Keybind or Enum.KeyCode.RightShift
        table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, g
                   if not gp and input.KeyCode == key then
                           self:Toggle()
                   end
        end))


        return self
end


-- demo -------------------------------------------------------------------


local RUN_DEMO = true

if RUN_DEMO then
    local win = Eclipse:CreateWindow({ Title = "Eclipse", Keybind = Enum.KeyCode.RightShift })
    
    -- Create the Tabs
    local SkinsTab = win:AddTab({ Name = "Skins", Icon = "person" })
    local CombatTab = win:AddTab({ Name = "Combat", Icon = "crosshair" })
    win:AddTab({ Name = "Visuals", Icon = "eye" })
    win:AddTab({ Name = "Player", Icon = "person" })
    win:AddSettingsTab()

    -- =========================================================
    -- WORKING SKIN CHANGER LOGIC
    -- =========================================================
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local lp = Players.LocalPlayer
    
    local function waitModule(root, names, timeout)
        timeout = timeout or 10
        local obj = root
        for _, n in ipairs(names) do
            if not obj then return nil end
            local ok, child = pcall(function() return obj:WaitForChild(n, timeout) end)
            obj = ok and child or nil
        end
        return obj
    end
    local function loadGameModule(root, names)
        local inst = waitModule(root, names)
        if not inst then return nil end
        local ok, mod = pcall(require, inst)
        return ok and mod or nil
    end

    local Rivals = {
        Cosmetics  = loadGameModule(ReplicatedStorage, {"Modules", "CosmeticLibrary"}),
        PlayerData = loadGameModule(lp.PlayerScripts, {"Controllers", "PlayerDataController"}),
    }

    local _eq = {}

    if Rivals.Cosmetics and Rivals.PlayerData then
        local origOwnsCosmetic = Rivals.Cosmetics.OwnsCosmetic
        Rivals.Cosmetics.OwnsCosmetic = function(self, inv, name, weapon)
            local cosmetic = Rivals.Cosmetics.Cosmetics[name]
            if cosmetic and (cosmetic.Type == "Skin" or cosmetic.Type == "Wrap" or cosmetic.Type == "Charm" or cosmetic.Type == "Finisher") then
                return true
            end
            return origOwnsCosmetic(self, inv, name, weapon)
        end

        local origGet = Rivals.PlayerData.Get
        Rivals.PlayerData.Get = function(self, key)
            local val = origGet(self, key)
            if key == "CosmeticInventory" then
                local proxy = {}
                if type(val) == "table" then
                    for k, v in pairs(val) do proxy[k] = v end
                end
                return setmetatable(proxy, {
                    __index = function(t, k)
                        local c = Rivals.Cosmetics.Cosmetics[k]
                        if c and (c.Type == "Skin" or c.Type == "Wrap" or c.Type == "Charm" or c.Type == "Finisher") then return true end
                        return nil
                    end
                })
            end
            return val
        end

        local origGetWeaponData = Rivals.PlayerData.GetWeaponData
        Rivals.PlayerData.GetWeaponData = function(self, weaponName)
            local data = origGetWeaponData(self, weaponName)
            if not data then return nil end
            local merged = {}
            for k, v in pairs(data) do merged[k] = v end
            merged.Name = weaponName
            if _eq[weaponName] then
                for ctype, cdata in pairs(_eq[weaponName]) do merged[ctype] = cdata end
            end
            return merged
        end

        local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local EquipRem = Remotes and Remotes.Data and Remotes.Data:FindFirstChild("EquipCosmetic")

        if EquipRem and hookmetamethod then
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                if getnamecallmethod() ~= "FireServer" then return oldNamecall(self, ...) end
                if self == EquipRem then
                    local args = {...}
                    local weapon, ctype, cname, opts = args[1], args[2], args[3], args[4] or {}
                    _eq[weapon] = _eq[weapon] or {}
                    if not cname or cname == "None" or cname == "" then
                        _eq[weapon][ctype] = nil
                    else
                        local base = Rivals.Cosmetics.Cosmetics[cname]
                        if base then
                            local cloned = {}
                            for k, v in pairs(base) do cloned[k] = v end
                            cloned.Name = cname
                            cloned.Type = cloned.Type or ctype
                            if opts.IsInverted then cloned.Inverted = true end
                            _eq[weapon][ctype] = cloned
                        end
                    end
                    task.defer(function() pcall(function() Rivals.PlayerData.CurrentData:Replicate("WeaponInventory") end) end)
                    return
                end
                return oldNamecall(self, ...)
            end)
        end
    end

    -- =========================================================
    -- CONNECT TO UI
    -- =========================================================
    local Sec = SkinsTab:AddSection({ Name = "Skin Swapper", Side = "Left" })

    local function getList(ctype)
        local list = {"None"}
        if Rivals.Cosmetics then
            for name, entry in pairs(Rivals.Cosmetics.Cosmetics) do
                if type(entry) == "table" and entry.Type == ctype then
                    table.insert(list, name)
                end
            end
        end
        table.sort(list)
        return list
    end

    local currentWep = "None"

    Sec:AddDropdown({ 
        Name = "Target Weapon", 
        Options = {"None", "Katana", "Gun", "Knife", "Bow", "Riot Shield"}, 
        Default = "None",
        Callback = function(v) currentWep = v end
    })

    Sec:AddDropdown({ Name = "Skin", Options = getList("Skin"), Callback = function(v) 
        if currentWep == "None" then win:Notify({Title="Error", Text="Select a weapon first!"}) return end
        Remotes.Data.EquipCosmetic:FireServer(currentWep, "Skin", v, {})
    end })

    Sec:AddDropdown({ Name = "Wrap", Options = getList("Wrap"), Callback = function(v) 
        if currentWep == "None" then win:Notify({Title="Error", Text="Select a weapon first!"}) return end
        Remotes.Data.EquipCosmetic:FireServer(currentWep, "Wrap", v, {})
    end })

    Sec:AddDropdown({ Name = "Charm", Options = getList("Charm"), Callback = function(v) 
        if currentWep == "None" then win:Notify({Title="Error", Text="Select a weapon first!"}) return end
        Remotes.Data.EquipCosmetic:FireServer(currentWep, "Charm", v, {})
    end })

    Sec:AddDropdown({ Name = "Finisher", Options = getList("Finisher"), Callback = function(v) 
        if currentWep == "None" then win:Notify({Title="Error", Text="Select a weapon first!"}) return end
        Remotes.Data.EquipCosmetic:FireServer(currentWep, "Finisher", v, {})
    end })

    win:LoadAutoload()
end

return Eclipse
