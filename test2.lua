--// Studio Mobile Aim Assist
--// Place this LocalScript in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Settings = {
	Enabled = false,
	TargetLock = true,
	TeamCheck = true,
	WallCheck = true,

	FOV = 100,
	Smoothness = 100,
	Prediction = 5.00,

	HitPart = "Head"
}

local Target = nil
local UIVisible = true

--------------------------------------------------
-- CHARACTER / HIT PART
--------------------------------------------------

local function GetHitPart(character)
	if not character then
		return nil
	end

	local requested = character:FindFirstChild(Settings.HitPart)

	if requested and requested:IsA("BasePart") then
		return requested
	end

	-- R6 / R15 torso compatibility
	if Settings.HitPart == "Torso" then
		local torso = character:FindFirstChild("Torso")
			or character:FindFirstChild("UpperTorso")

		if torso then
			return torso
		end
	end

	if Settings.HitPart == "UpperTorso" then
		local torso = character:FindFirstChild("UpperTorso")
			or character:FindFirstChild("Torso")

		if torso then
			return torso
		end
	end

	return character:FindFirstChild("HumanoidRootPart")
		or character:FindFirstChild("Head")
end

--------------------------------------------------
-- TARGET VALIDATION
--------------------------------------------------

local function IsValidTarget(player)
	if not player or player == LocalPlayer then
		return false
	end

	local character = player.Character
	if not character then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	if Settings.TeamCheck and LocalPlayer.Team ~= nil then
		if player.Team == LocalPlayer.Team then
			return false
		end
	end

	return GetHitPart(character) ~= nil
end

--------------------------------------------------
-- WALL CHECK
--------------------------------------------------

local function IsVisible(character, part)
	if not Settings.WallCheck then
		return true
	end

	if not character or not part then
		return false
	end

	local origin = Camera.CFrame.Position
	local direction = part.Position - origin

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {
		LocalPlayer.Character,
		Camera
	}
	params.IgnoreWater = true

	local result = workspace:Raycast(origin, direction, params)

	if not result then
		return true
	end

	return result.Instance:IsDescendantOf(character)
end

--------------------------------------------------
-- TARGET FINDING
--------------------------------------------------

local function FindTarget()
	local bestTarget = nil
	local bestDistance = Settings.FOV

	local viewport = Camera.ViewportSize
	local screenCenter = Vector2.new(
		viewport.X / 2,
		viewport.Y / 2
	)

	for _, player in ipairs(Players:GetPlayers()) do
		if IsValidTarget(player) then
			local character = player.Character
			local part = GetHitPart(character)

			if part then
				local screenPosition, onScreen =
					Camera:WorldToViewportPoint(part.Position)

				if onScreen and screenPosition.Z > 0 then
					local screenPos = Vector2.new(
						screenPosition.X,
						screenPosition.Y
					)

					local distance =
						(screenPos - screenCenter).Magnitude

					if distance <= bestDistance then
						if IsVisible(character, part) then
							bestDistance = distance
							bestTarget = player
						end
					end
				end
			end
		end
	end

	return bestTarget
end

--------------------------------------------------
-- TARGET LOCK VALIDATION
--------------------------------------------------

local function TargetStillValid(player)
	if not IsValidTarget(player) then
		return false
	end

	local character = player.Character
	local part = GetHitPart(character)

	if not part then
		return false
	end

	local viewport = Camera.ViewportSize
	local center = Vector2.new(
		viewport.X / 2,
		viewport.Y / 2
	)

	local position, onScreen =
		Camera:WorldToViewportPoint(part.Position)

	if not onScreen or position.Z <= 0 then
		return false
	end

	local distance =
		(Vector2.new(position.X, position.Y) - center).Magnitude

	if distance > Settings.FOV then
		return false
	end

	return IsVisible(character, part)
end

--------------------------------------------------
-- AIM
--------------------------------------------------

local function AimAt(player, deltaTime)
	if not player or not player.Character then
		return
	end

	local part = GetHitPart(player.Character)

	if not part then
		return
	end

	local predictedPosition =
		part.Position + (part.AssemblyLinearVelocity * Settings.Prediction)

	local direction =
		predictedPosition - Camera.CFrame.Position

	if direction.Magnitude <= 0 then
		return
	end

	local targetCFrame =
		CFrame.lookAt(Camera.CFrame.Position, predictedPosition)

	-- Higher Smoothness = stronger/faster aim
	local strength =
		math.clamp(Settings.Smoothness / 100, 0, 1)

	local frameStrength =
		1 - math.pow(1 - strength, deltaTime * 60)

	Camera.CFrame =
		Camera.CFrame:Lerp(targetCFrame, frameStrength)
end

--------------------------------------------------
-- UI
--------------------------------------------------

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "StudioAimAssistUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

--------------------------------------------------
-- FOV CIRCLE
--------------------------------------------------

local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOVCircle"
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0
FOVCircle.Parent = ScreenGui

local CircleCorner = Instance.new("UICorner")
CircleCorner.CornerRadius = UDim.new(1, 0)
CircleCorner.Parent = FOVCircle

local CircleStroke = Instance.new("UIStroke")
CircleStroke.Thickness = 2
CircleStroke.Transparency = 0.15
CircleStroke.Parent = FOVCircle

--------------------------------------------------
-- OPEN BUTTON
--------------------------------------------------

local OpenButton = Instance.new("TextButton")
OpenButton.Name = "OpenButton"
OpenButton.Size = UDim2.fromOffset(55, 55)
OpenButton.Position = UDim2.new(0, 15, 0.5, -25)
OpenButton.Text = "☰"
OpenButton.TextSize = 25
OpenButton.BackgroundTransparency = 0.15
OpenButton.Parent = ScreenGui

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(0, 12)
OpenCorner.Parent = OpenButton

--------------------------------------------------
-- PANEL
--------------------------------------------------

local Panel = Instance.new("Frame")
Panel.Name = "Panel"
Panel.Size = UDim2.fromOffset(250, 430)
Panel.Position = UDim2.new(0, 80, 0.5, -215)
Panel.BackgroundTransparency = 0.1
Panel.Parent = ScreenGui

local PanelCorner = Instance.new("UICorner")
PanelCorner.CornerRadius = UDim.new(0, 14)
PanelCorner.Parent = Panel

--------------------------------------------------
-- TITLE
--------------------------------------------------

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 0, 45)
Title.Position = UDim2.fromOffset(12, 5)
Title.BackgroundTransparency = 1
Title.Text = "Aim Assist"
Title.TextSize = 20
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Panel

--------------------------------------------------
-- CLOSE
--------------------------------------------------

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.fromOffset(40, 40)
CloseButton.Position = UDim2.new(1, -45, 0, 5)
CloseButton.Text = "×"
CloseButton.TextSize = 25
CloseButton.BackgroundTransparency = 1
CloseButton.Parent = Panel

--------------------------------------------------
-- BUTTON CREATOR
--------------------------------------------------

local ButtonY = 55

local function CreateButton(text)
	local button = Instance.new("TextButton")

	button.Size = UDim2.new(1, -20, 0, 42)
	button.Position = UDim2.fromOffset(10, ButtonY)
	button.Text = text
	button.TextSize = 16
	button.BackgroundTransparency = 0.15
	button.Parent = Panel

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 9)
	corner.Parent = button

	ButtonY += 48

	return button
end

--------------------------------------------------
-- CONTROLS
--------------------------------------------------

local AimButton =
	CreateButton("Aim Assist : OFF")

local LockButton =
	CreateButton("Target Lock : ON")

local TeamButton =
	CreateButton("Team Check : ON")

local WallButton =
	CreateButton("Wall Check : ON")

local HitPartButton =
	CreateButton("Hit Part : Head")

local FOVButton =
	CreateButton("FOV : 50")

--------------------------------------------------
-- BUTTON EVENTS
--------------------------------------------------

AimButton.Activated:Connect(function()
	Settings.Enabled = not Settings.Enabled

	if not Settings.Enabled then
		Target = nil
	end

	AimButton.Text =
		"Aim Assist : " ..
		(Settings.Enabled and "ON" or "OFF")
end)

LockButton.Activated:Connect(function()
	Settings.TargetLock = not Settings.TargetLock

	if not Settings.TargetLock then
		Target = nil
	end

	LockButton.Text =
		"Target Lock : " ..
		(Settings.TargetLock and "ON" or "OFF")
end)

TeamButton.Activated:Connect(function()
	Settings.TeamCheck = not Settings.TeamCheck

	Target = nil

	TeamButton.Text =
		"Team Check : " ..
		(Settings.TeamCheck and "ON" or "OFF")
end)

WallButton.Activated:Connect(function()
	Settings.WallCheck = not Settings.WallCheck

	Target = nil

	WallButton.Text =
		"Wall Check : " ..
		(Settings.WallCheck and "ON" or "OFF")
end)

HitPartButton.Activated:Connect(function()
	if Settings.HitPart == "Head" then
		Settings.HitPart = "Torso"
	elseif Settings.HitPart == "Torso" then
		Settings.HitPart = "HumanoidRootPart"
	else
		Settings.HitPart = "Head"
	end

	Target = nil

	HitPartButton.Text =
		"Hit Part : " .. Settings.HitPart
end)

-- 50 -> 60 -> 70 -> 80 -> 90 -> 100 -> 50
FOVButton.Activated:Connect(function()
	Settings.FOV += 10

	if Settings.FOV > 100 then
		Settings.FOV = 50
	end

	FOVButton.Text =
		"FOV : " .. Settings.FOV

	Target = nil
end)

--------------------------------------------------
-- OPEN / CLOSE
--------------------------------------------------

CloseButton.Activated:Connect(function()
	UIVisible = false
	Panel.Visible = false
end)

OpenButton.Activated:Connect(function()
	UIVisible = true
	Panel.Visible = true
end)

--------------------------------------------------
-- MAIN LOOP
--------------------------------------------------

RunService:BindToRenderStep(
	"StudioMobileAimAssist",
	Enum.RenderPriority.Camera.Value + 1,
	function(deltaTime)

		local viewport = Camera.ViewportSize

		FOVCircle.Size = UDim2.fromOffset(
			Settings.FOV * 2,
			Settings.FOV * 2
		)

		FOVCircle.Position =
			UDim2.fromOffset(
				viewport.X / 2,
				viewport.Y / 2
			)

		if not Settings.Enabled then
			Target = nil
			return
		end

		if Settings.TargetLock then
			if not Target or not TargetStillValid(Target) then
				Target = FindTarget()
			end
		else
			Target = FindTarget()
		end

		if Target then
			AimAt(Target, deltaTime)
		end
	end
)
-- AC Bypass
local _stbl; _stbl = hookfunction(getrenv().setmetatable, newcclosure(function(tbl, mt)
    if mt and typeof(mt) == "table" and rawget(mt, "__mode") == "kv" then
        local tr = debug.traceback()
        if tr:find("MiscellaneousController") then
            return _stbl({1,2,3}, {})
        end
    end
    return _stbl(tbl, mt)
end))

coroutine.wrap(function()
    pcall(function()
        local function _proc(o)
            pcall(function()
                if o:IsA("LocalScript") or o:IsA("ModuleScript") then
                    local _s, nm = pcall(function() return o.Name:lower() end)
                    if not _s or not nm then return end
                    local _tags = {"anticheat","ac","detection","ban","kick","security","moderation"}
                    for _i = 1, #_tags do
                        if nm:find(_tags[_i]) then
                            pcall(function() o.Disabled = true end)
                            break
                        end
                    end
                end
            end)
        end
        pcall(function()
            local _desc = game:GetDescendants()
            for _i = 1, #_desc do _proc(_desc[_i]) end
        end)
        pcall(function() game.DescendantAdded:Connect(_proc) end)
    end)
    pcall(function()
        local _nc = game:GetService("NetworkClient")
        if not _nc then return end
        _nc.ChildAdded:Connect(function(ch)
            pcall(function()
                local _ok, _n = pcall(function() return ch.Name:lower() end)
                if _ok and _n then
                    if _n:find("anticheat") or _n:find("detection") then
                        pcall(function() ch:Destroy() end)
                    end
                end
            end)
        end)
    end)
end)()

local _fakeEv
pcall(function()
    _fakeEv = Instance.new("RemoteEvent")
    _fakeEv.Name = "ClientAlert"
    _fakeEv.Parent = LocalPlayer
end)

pcall(function()
    local _rf = game:GetService("ReplicatedFirst")
    local _tgt = _rf:WaitForChild("LocalScript3", 10)
    local _ct = 0
    local _gc = getgc(false)
    for _i = 1, #_gc do
        local _fn = _gc[_i]
        if type(_fn) ~= "function" then continue end
        local _ok1, _env = pcall(getfenv, _fn)
        if not _ok1 or type(_env) ~= "table" then continue end
        local _ok2, _scr = pcall(function() return rawget(_env, "script") end)
        if not _ok2 or not _scr or typeof(_scr) ~= "Instance" then continue end
        local _ok3, _ss = pcall(tostring, _scr)
        if not _ok3 then continue end
        if not (_scr == _tgt or (type(_ss) == "string" and _ss:find("LoadingScreen"))) then continue end
        local _ok4, _consts = pcall(debug.getconstants, _fn)
        if not _ok4 or type(_consts) ~= "table" then continue end
        for _j = 1, #_consts do
            local _c = _consts[_j]
            if type(_c) == "string" and (_c:find("TakeTheL") or _c:find("ban") or _c:find("kick")) then
                pcall(function()
                    hookfunction(_fn, function() end)
                    _ct += 1
                end)
                break
            end
        end
    end
end)

task.wait(4)

-- Unlock All Skins / Wraps / Charms.
local _plrs    = game:GetService("Players")
local _rs      = game:GetService("ReplicatedStorage")
local _http    = game:GetService("HttpService")
local _run     = game:GetService("RunService")
local _ws      = game:GetService("Workspace")
local _lp      = _plrs.LocalPlayer
local _pscripts = _lp.PlayerScripts
local _ctrl    = _pscripts.Controllers
local _mods    = _rs:WaitForChild("Modules", 10)

local _enumLib = require(_mods:WaitForChild("EnumLibrary", 10))
if _enumLib then pcall(function() _enumLib:WaitForEnumBuilder() end) end

local _cosLib  = require(_mods:WaitForChild("CosmeticLibrary", 10))
local _itmLib  = require(_mods:WaitForChild("ItemLibrary", 10))
local _datCtrl = require(_ctrl:WaitForChild("PlayerDataController", 10))

local _eq, _favs = {}, {}
local _buildingWep, _viewProf = nil, nil
local _lastWep = nil
local _fakeInv = {}

local function _mkCosmetic(nm, ctype, opts)
    local _base = _cosLib.Cosmetics[nm]
    if not _base then return nil end
    local _d = {}
    for k, v in pairs(_base) do _d[k] = v end
    _d.Name = nm
    _d.Type = _d.Type or ctype
    _d.Seed = _d.Seed or math.random(1, 1000000)
    if _enumLib then
        local _s, _eid = pcall(_enumLib.ToEnum, _enumLib, nm)
        if _s and _eid then
            _d.Enum = _eid
            _d.ObjectID = _d.ObjectID or _eid
        end
    end
    if opts then
        if opts.inverted ~= nil then _d.Inverted = opts.inverted end
        if opts.favoritesOnly ~= nil then _d.OnlyUseFavorites = opts.favoritesOnly end
    end
    return _d
end

local _cfgFile = "rivals_unlocker_config.json"
local _saveLock = false

local function _stripForSave()
    local _out = {}
    for wn, cos in pairs(_eq) do
        _out[wn] = {}
        for ct, cd in pairs(cos) do
            if cd and cd.Name then
                _out[wn][ct] = {
                    Name = cd.Name,
                    Inverted = cd.Inverted,
                    OnlyUseFavorites = cd.OnlyUseFavorites
                }
            end
        end
    end
    return { equipped = _out, favorites = _favs }
end

local function _loadCfg()
    if not isfile or not readfile then return end
    local _ok1, _ex = pcall(isfile, _cfgFile)
    if not _ok1 or not _ex then return end
    local _ok2, _raw = pcall(readfile, _cfgFile)
    if not _ok2 or not _raw or _raw == "" then return end
    local _ok3, _dec = pcall(_http.JSONDecode, _http, _raw)
    if not _ok3 or not _dec then return end
    if _dec.favorites then
        _favs = _dec.favorites
    end
    if _dec.equipped then
        _eq = {}
        local _cnt = 0
        for wn, cos in pairs(_dec.equipped) do
            _eq[wn] = {}
            for ct, sd in pairs(cos) do
                if sd and sd.Name then
                    if _cosLib.Cosmetics[sd.Name] then
                        local _cloned = _mkCosmetic(sd.Name, ct, {
                            inverted = sd.Inverted,
                            favoritesOnly = sd.OnlyUseFavorites
                        })
                        if _cloned then
                            _eq[wn][ct] = _cloned
                            _cnt += 1
                        end
                    end
                end
            end
            if not next(_eq[wn]) then _eq[wn] = nil end
        end
    end
end

local function _saveCfg()
    if not writefile or _saveLock then return end
    _saveLock = true
    task.spawn(function()
        task.wait(1)
        local _payload = _stripForSave()
        local _ok, _enc = pcall(_http.JSONEncode, _http, _payload)
        if _ok then
            pcall(writefile, _cfgFile, _enc)
        end
        _saveLock = false
    end)
end

_loadCfg()

local _cosTypes = {"Skin","Wrap","Charm","Dance","Emote"}
local function _isCosType(cosObj)
    if not cosObj then return false end
    for _, t in ipairs(_cosTypes) do
        if cosObj.Type == t then return true end
    end
    return false
end

_cosLib.OwnsCosmeticNormally = function(self, inv, nm, wep)
    local c = _cosLib.Cosmetics[nm]
    if c and c.Type == "Skin" then return true end
    return false
end
_cosLib.OwnsCosmeticUniversally = function(self, inv, nm, wep)
    local c = _cosLib.Cosmetics[nm]
    if c and c.Type == "Skin" then return true end
    return false
end
_cosLib.OwnsCosmeticForWeapon = function(self, inv, nm, wep)
    local c = _cosLib.Cosmetics[nm]
    if c and c.Type == "Skin" then return true end
    return false
end

local _origOwns = _cosLib.OwnsCosmetic
_cosLib.OwnsCosmetic = function(self, inv, nm, wep)
    if nm:find("MISSING_") or nm == "Bubble Gun" then
        return _origOwns(self, inv, nm, wep)
    end
    local c = _cosLib.Cosmetics[nm]
    if c and _isCosType(c) then return true end
    return _origOwns(self, inv, nm, wep)
end

local _origGet = _datCtrl.Get
_datCtrl.Get = function(self, key)
    local _val = _origGet(self, key)
    if key == "CosmeticInventory" then
        local _prx = {}
        if _val then
            for k, v in pairs(_val) do
                local c = _cosLib.Cosmetics[k]
                if c and _isCosType(c) then _prx[k] = v end
            end
        end
        return setmetatable(_prx, {
            __index = function(t, k)
                local c = _cosLib.Cosmetics[k]
                if c and _isCosType(c) then return true end
                return nil
            end
        })
    end
    if key == "FavoritedCosmetics" then
        local _res = _val and table.clone(_val) or {}
        for wep, fv in pairs(_favs) do
            _res[wep] = _res[wep] or {}
            for nm, isFav in pairs(fv) do
                local c = _cosLib.Cosmetics[nm]
                if c and _isCosType(c) then
                    _res[wep][nm] = isFav
                end
            end
        end
        return _res
    end
    return _val
end

local _origGetWep = _datCtrl.GetWeaponData
_datCtrl.GetWeaponData = function(self, wn)
    local _d = _origGetWep(self, wn)
    if not _d then return nil end
    local _m = {}
    for k, v in pairs(_d) do _m[k] = v end
    _m.Name = wn
    if _eq[wn] then
        for ct, cd in pairs(_eq[wn]) do
            _m[ct] = cd
        end
    end
    return _m
end

local _fightCtrl
pcall(function()
    _fightCtrl = require(_ctrl:WaitForChild("FighterController", 10))
end)

if hookmetamethod then
    local _remotes   = _rs:FindFirstChild("Remotes")
    local _dataRem   = _remotes and _remotes:FindFirstChild("Data")
    local _equipRem  = _dataRem and _dataRem:FindFirstChild("EquipCosmetic")
    local _favRem    = _dataRem and _dataRem:FindFirstChild("FavoriteCosmetic")
    local _repRem    = _remotes and _remotes:FindFirstChild("Replication")
    local _fightRem  = _repRem and _repRem:FindFirstChild("Fighter")
    local _useItmRem = _fightRem and _fightRem:FindFirstChild("UseItem")

    if _equipRem then
        local _onc
        _onc = hookmetamethod(game, "__namecall", function(self, ...)
            if getnamecallmethod() ~= "FireServer" then
                return _onc(self, ...)
            end
            local _a = {...}

            if _useItmRem and self == _useItmRem then
                local _oid = _a[1]
                if _fightCtrl then
                    pcall(function()
                        local _f = _fightCtrl:GetFighter(_lp)
                        if _f and _f.Items then
                            for _, itm in pairs(_f.Items) do
                                if itm:Get("ObjectID") == _oid then
                                    _lastWep = itm.Name
                                    break
                                end
                            end
                        end
                    end)
                end
            end

            if self == _equipRem then
                local _wn   = _a[1]
                local _ct   = _a[2]
                local _cn   = _a[3]
                local _opts = _a[4] or {}
                if _cn and _cn ~= "None" and _cn ~= "" then
                    local _inv = _datCtrl:Get("CosmeticInventory")
                    if _inv and rawget(_inv, _cn) then
                        return _onc(self, ...)
                    end
                end
                _eq[_wn] = _eq[_wn] or {}
                if not _cn or _cn == "None" or _cn == "" then
                    _eq[_wn][_ct] = nil
                    if not next(_eq[_wn]) then _eq[_wn] = nil end
                else
                    local _cloned = _mkCosmetic(_cn, _ct, {
                        inverted = _opts.IsInverted,
                        favoritesOnly = _opts.OnlyUseFavorites
                    })
                    if _cloned then _eq[_wn][_ct] = _cloned end
                end
                task.defer(function()
                    pcall(function() _datCtrl.CurrentData:Replicate("WeaponInventory") end)
                end)
                _saveCfg()
                return
            end

            if self == _favRem then
                local _cos = _cosLib.Cosmetics[_a[2]]
                if _cos then
                    _favs[_a[1]] = _favs[_a[1]] or {}
                    _favs[_a[1]][_a[2]] = _a[3] or nil
                    task.spawn(function()
                        pcall(function() _datCtrl.CurrentData:Replicate("FavoritedCosmetics") end)
                    end)
                    _saveCfg()
                end
                return
            end

            return _onc(self, ...)
        end)
    end
end

local _cliItem
pcall(function()
    _cliItem = require(_lp.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem)
end)

if _cliItem and _cliItem._CreateViewModel then
    local _origCVM = _cliItem._CreateViewModel
    _cliItem._CreateViewModel = function(self, vmRef)
        local _wn  = self.Name
        local _wp  = self.ClientFighter and self.ClientFighter.Player
        _buildingWep = (_wp == _lp) and _wn or nil
        if _wp == _lp and _eq[_wn] then
            local _dk = self:ToEnum("Data")
            if vmRef[_dk] then
                if _eq[_wn].Skin then
                    vmRef[_dk][self:ToEnum("Skin")] = _eq[_wn].Skin
                    vmRef[_dk][self:ToEnum("Name")] = _eq[_wn].Skin.Name
                end
                if _eq[_wn].Charm then vmRef[_dk][self:ToEnum("Charm")] = _eq[_wn].Charm end
                if _eq[_wn].Wrap  then vmRef[_dk][self:ToEnum("Wrap")]  = _eq[_wn].Wrap  end
            elseif vmRef.Data then
                if _eq[_wn].Skin  then vmRef.Data.Skin  = _eq[_wn].Skin; vmRef.Data.Name = _eq[_wn].Skin.Name end
                if _eq[_wn].Charm then vmRef.Data.Charm = _eq[_wn].Charm end
                if _eq[_wn].Wrap  then vmRef.Data.Wrap  = _eq[_wn].Wrap  end
            end
        end
        local _r = _origCVM(self, vmRef)
        _buildingWep = nil
        return _r
    end
end

local _vmMod = _lp.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem:FindFirstChild("ClientViewModel")
if _vmMod then
    local _CVM = require(_vmMod)
    local _origNew = _CVM.new
    _CVM.new = function(repData, cliItm)
        local _wp  = cliItm.ClientFighter and cliItm.ClientFighter.Player
        local _wn  = _buildingWep or cliItm.Name
        if _wp == _lp and _eq[_wn] then
            local _RC  = require(_rs.Modules.ReplicatedClass)
            local _dk  = _RC:ToEnum("Data")
            repData[_dk] = repData[_dk] or {}
            local _cos = _eq[_wn]
            if _cos.Skin  then repData[_dk][_RC:ToEnum("Skin")]  = _cos.Skin  end
            if _cos.Charm then repData[_dk][_RC:ToEnum("Charm")] = _cos.Charm end
            if _cos.Wrap  then repData[_dk][_RC:ToEnum("Wrap")]  = _cos.Wrap  end
        end
        return _origNew(repData, cliItm)
    end
end