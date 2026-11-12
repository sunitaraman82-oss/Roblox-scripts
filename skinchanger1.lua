local v1 = unpack or table.unpack
game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ClientId = game:GetService("RbxAnalyticsService"):GetClientId()
local v9 = gethui and gethui()
if not v9 then
    v9 = CoreGui:FindFirstChild("HUI")
end
local u10 = v9
if not u10 then
    u10 = Instance.new("Folder", CoreGui)
    u10.Name = "HUI"
end
local t1 = {
	key = "EconRC/key.dat",
	keynew = "EconRC/key.txt",
	skins = "EconRC/misc/skins.txt",
	settings = "EconRC/misc/settings",
	version = "EconRC/misc/version.txt"
}
local v12 = isfolder("EconRC")
local n1 = 1
local v14 = v12
if v12 then
    v14 = isfile(t1.version)

    if v14 then
        v14 = tonumber(readfile(t1.version))
    end
end
local v15 = v14 or 0
if not RunService:IsStudio() then
    local s1 = "EconRC/misc/skins"

    if isfile(s1) then
        writefile("EconRC/misc/skins.txt", readfile(s1))
        delfile(s1)
    end

    if not v12 then
        local t2 = {}

        function t2.file(p1, p2)
            local _writefile = writefile
            local v97 = "EconRC" .. "/" .. p1

            if not p2 then
                p2 = ""
            end

            _writefile(v97, p2)

            return {
				folder = function(p3)
                return t2.folder(p3 .. "/" .. p1)
            end,
				file = function(p4, p5)
                local file = t2.file
                local v303 = p4 .. "/" .. p1

                if not p5 then
                    p5 = ""
                end

                return file(v303, p5)
            end
			}
        end
        function t2.folder(p6)
            makefolder("EconRC" .. "/" .. p6)

            return {
				folder = function(p7)
                return t2.folder(p6 .. "/" .. p7)
            end,
				file = function(p8, p9)
                local file = t2.file
                local v308 = p6 .. "/" .. p8

                if not p9 then
                    p9 = ""
                end

                return file(v308, p9)
            end
			}
        end

        makefolder("EconRC")

        local v18 = t2.folder("cfg")
        local v19 = t2.folder("misc")

        if isfolder("cone") then
            warn("Cleanup old files")

            for _, v in pairs(listfiles("./cone")) do
                local v22 = v
                local parts = v22:split("/")
                local v24 = parts[#parts]:split(".")[1]
                local success, result = pcall(function()
                    return readfile(v22)
                end)
                if success then
                    v18.file(v24 .. ".txt", result)
                end
            end
        end

        v19.file("settings")

        local file = v19.file
        local v28 = isfile("EconContainer")

        if v28 then
            v28 = readfile("EconContainer")
        end

        file("skins.txt", v28)

        local file2 = v19.file
        local v30 = isfile("EconConfig")

        if v30 then
            v30 = readfile("EconConfig")
        end

        file2("cfg", v30)
        v19.file("version.txt", (tostring(n1)))

        local file3 = t2.file
        local v32 = isfile("key.dat")

        if v32 then
            v32 = readfile("key.dat")
        end

        file3("key.txt", v32)
        task.spawn(function()
            if isfolder("cone") then
                delfolder("cone")
            end

            delfile("EconContainer")
            delfile("EconConfig")
            delfile("_econ_dat.dat")
        end)
    elseif not isfile(t1.keynew) then
        if isfile(t1.key) then
            local v33 = readfile(t1.key)

            if v33 then
                v33 = not v33:find(v1({ string.char(0) }))
            end

            if v33 then
                writefile(t1.keynew, readfile(t1.key))
            else
                writefile(t1.keynew, "")
                getgenv().corrupt_key = true
                warn("Last Econ key was corrupted and removed")
            end

            delfile(t1.key)
        else
            writefile(t1.keynew, "")
        end
    end
end
if not isfile(t1.version) or n1 ~= v15 then
    writefile(t1.version, (tostring(n1)))
end
local _setclipboard = setclipboard
if not _setclipboard then
    _setclipboard = syn

    if _setclipboard then
        _setclipboard = syn.write_clipboard
    end
end
local v35 = _setclipboard
local v36 = iswindowactive or isrbxactive
local _syn = syn
if _syn then
    _syn = syn.request
end
if not _syn then
    _syn = fluxus

    if _syn then
        _syn = fluxus.request
    end

    if not _syn then
        _syn = http

        if _syn then
            _syn = http.request
        end

        if not _syn then
            _syn = http_request or request
        end
    end
end
local v38 = _syn
local t4 = {
	["031FAFB0-20981D91E121-49F4-7490-CBE8"] = {
		604800,
		1769245344
	}
}
local t5 = {
	reasons = {{
		reason = nil,
		content = "Fuck You Owen Ge Krijgt Het ni"
	}}
}
local t6 = {
	reason = "Bypassing",
	content = "Key bypassing is not allowed"
}
local t7 = {
	mike = t5,
	econ_bypass_key = {
		reasons = { t6 },
		no_appeal = true
	}
}
local v44 = t7
local mike = t7.mike
local mike2 = t7.mike
local t8 = {
	[5678562424] = mike,
	[9920820296] = mike2
}
local v48 = RunService:IsStudio()
if v48 then
    v48 = script.Parent.Parent.Key:Clone()
end
if not v48 then
    v48 = game:GetObjects("rbxassetid://75930751132314")[1]
end
local v49 = v48
local Main = v49.Main
local LocalPlayer = Players.LocalPlayer
local t9 = {{
	img = "rbxassetid://116162688464457",
	name = "Linkvertise",
	api = "371b5300-1cc6-433a-9b9b-f36f6e600943",
	service = "Econ|Key",
	provider = "Econ|key"
}}
local u53
local u54 = RunService:IsStudio() and 0
local v55 = RunService:IsStudio()
if v55 then
    v55 = 1e999
end
local u56 = v55
local t10 = {}
local t11 = {}
local _sfx = v49._sfx
local _elements = v49._elements
local function v61(p10)
    if _sfx:FindFirstChild(p10) then
        SoundService:PlayLocalSound(_sfx[p10])
    end
end
local u62 = false
local function v63()
    v49.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Main.Parent = v49.Loading
    v49.Loading.Visible = true

    local v100 = TweenService
    local Loading = v49.Loading
    local new = TweenInfo.new
    local Create = v100.Create
    local v104 = new(1)
    local color3 = Color3.new(0.701961, 0.701961, 0.701961)
    local uDim2 = UDim2.fromScale(0, 0.015)

    Create(v100, Loading, v104, {
		GroupColor3 = color3,
		GroupTransparency = 0.3,
		Position = uDim2
	}):Play()
    u62 = true
    Main.Input.InputBox:ReleaseFocus()
    v49.Loading.Interactable = false

    return function()
        local v309 = TweenService
        local Loading2 = v49.Loading
        local _TweenInfo = TweenInfo
        local Create2 = v309.Create
        local v313 = _TweenInfo.new(0.6)
        local color3_2 = Color3.new(1, 1, 1)
        local uDim2_2 = UDim2.fromScale(0, 0)

        Create2(v309, Loading2, v313, {
			GroupColor3 = color3_2,
			GroupTransparency = 0,
			Position = uDim2_2
		}):Play()
        task.delay(0.6, function()
            u62 = false
            v49.Loading.Visible = false
            v49.Loading.Interactable = true
            v49.ZIndexBehavior = Enum.ZIndexBehavior.Global
            Main.Parent = v49
        end)
    end
end
local u64
local function v65(p11, p12)
    local clone = _elements.InputNotif:Clone()

    if u64 then
        local v110 = TweenService
        local v111 = u64
        local tweenInfo = TweenInfo.new(0.15)
        local yAxis = Vector2.yAxis
        local fromScale = UDim2.fromScale
        local Create = v110.Create
        local v116 = fromScale(0, -0.25)

        Create(v110, v111, tweenInfo, {
			AnchorPoint = yAxis,
			Position = v116,
			TextTransparency = 1
		}):Play()
        game.Debris:AddItem(u64, 2)
        u64 = nil
    end

    if p12 then
        clone.TextColor3 = p12
    end

    clone.Position = UDim2.fromScale(0, 0)
    clone.AnchorPoint = Vector2.yAxis * 0.5
    clone.TextTransparency = 1
    clone.Text = p11
    clone.Parent = Main.Input
    clone.Visible = true
    u64 = clone

    local v117 = TweenService
    local tweenInfo = TweenInfo.new(0.15)
    local uDim2 = UDim2.fromScale(0, -0.15)
    local _Vector2 = Vector2
    local Create = v117.Create
    local yAxis = _Vector2.yAxis

    Create(v117, clone, tweenInfo, {
		Position = uDim2,
		AnchorPoint = yAxis,
		TextTransparency = 0
	}):Play()
    task.delay(2, function()
        if clone and u64 == clone then
            local v316 = TweenService
            local v317 = clone
            local tweenInfo2 = TweenInfo.new(0.15)
            local yAxis2 = Vector2.yAxis
            local uDim2_3 = UDim2.fromScale(0, -0.25)

            v316:Create(v317, tweenInfo2, {
				AnchorPoint = yAxis2,
				Position = uDim2_3,
				TextTransparency = 1
			}):Play()
            game.Debris:AddItem(clone, 2)
            u64 = nil
        end
    end)
end
local t12 = {}
local t13 = {
	[0] = "0",
	"1",
	"2",
	"3",
	"4",
	"5",
	"6",
	"7",
	"8",
	"9",
	"a",
	"b",
	"c",
	"d",
	"e",
	"f",
	"g",
	"h",
	"i",
	"j",
	"k",
	"l",
	"m",
	"n",
	"o",
	"p",
	"q",
	"r",
	"s",
	"t",
	"u",
	"v",
	"w",
	"x",
	"y",
	"z",
	"A",
	"B",
	"C",
	"D",
	"E",
	"F",
	"G",
	"H",
	"I",
	"J",
	"K",
	"L",
	"M",
	"N",
	"O",
	"P",
	"Q",
	"R",
	"S",
	"T",
	"U",
	"V",
	"W",
	"X",
	"Y",
	"Z",
	"!",
	"#",
	"$",
	"%",
	"&",
	"'",
	"(",
	")",
	"*",
	"+",
	".",
	"/",
	":",
	";",
	"<",
	"=",
	">",
	"?",
	"@",
	"[",
	"]",
	"^",
	"_",
	"`",
	"{",
	"|",
	"}",
	"~"
}
local t14 = {
	["0"] = 0
}
for i, v in ipairs(t13) do
    t14[v] = i
end
local v71 = #t13 + 1
function t12.Encode(p13)
    local num = tonumber(p13)

    if num == 0 then
        return "0"
    end

    local s2 = ""

    if num < 1 then
        s2 = "-"
        num = -num
    end

    while num > 0 do
        s2 ..= t13[num % v71]
        num = math.floor(num / v71)
    end

    return s2
end
function t12.Decode(p14)
    local n2 = 0
    local n3 = 1

    for match in p14:gmatch(".") do
        local v130 = match

        if v130 == "-" then
            n3 = -n3
        else
            local v131 = t14[v130] * n3
            local v132 = v71

            n2 += v131
            n3 *= v132
        end
    end

    return n2
end
local function v72(p15)
    if p15 > 255 or p15 < 0 then
        writefile("EconRC/BUG_REPORT_TO_ECON_6.log", "Econ tried setting a character above 255, report this to Econ")
        warn("<< Econ Char >> 255 < [" .. p15 .. "]")
        LocalPlayer:Kick("REPORT THIS BUG TO ECON | ERR 6")

        return error("Return Char " .. p15, 2)
    end

    return string.char(p15)
end
local function v73(p16)
    local v135 = #{ p16:byte(1, -1) } > 1

    if v135 then
        v135 = utf8.codepoint(p16)
    end

    return v135 or p16:byte()
end
local function v74(p17)
    if not p17 then
        LocalPlayer:Kick("REPORT THIS BUG TO ECON | ERR 1")
        error("[1] REPORT TO ECON", 2)
    end
    local t15 = {}
    local parts = p17:split("")
    table.sort(parts, function(p18, p19)
        return p18:byte() + 25 < p19:byte() - 60
    end)
    for v141, v142 in pairs(parts) do

        if not table.find(t15, v142) then
            table.insert(t15, v142)
        end
    end
    local s3 = ""
    if not p17 then
        LocalPlayer:Kick("REPORT THIS BUG TO ECON | ERR 2")
        error("[2] REPORT TO ECON", 2)
    end
    for v146, v147 in ipairs(p17:split("")) do

        s3 ..= v72(table.find(t15, v147) + 33)
    end
    local v148 = s3:reverse() .. v72(33)
    for _, v in ipairs(t15) do
        v148 ..= v72(v73(v) + 33 + 1)
    end
    local s4 = ""
    for i = 1, #v148 do
        s4 ..= ("%03d"):format(v148:byte(i))
    end

    return s4
end
local function v75(p20)
    if not p20:find("!") then
        local s5 = ""
        local v155 = #p20 / 3

        if v155 ~= math.round(v155) then
            LocalPlayer:Kick("REPORT THIS BUG TO ECON | ERR 7 | Key not divisible by 3")
        end

        for i = 1, v155 do
            local _string = string
            local v158 = (i - 1) * 3 + 1

            s5 ..= _string.char(tonumber(p20:sub(v158, v158 + 2)))
        end

        p20 = s5
    end
    local t16 = {}
    local v160 = p20:reverse()
    if not v160 then
        LocalPlayer:Kick("REPORT THIS BUG TO ECON | ERR 3")
        error("[3] REPORT TO ECON", 2)
    end
    local t17 = { v72(33) }
    local parts = v160:split(v1(t17))
    local v163 = parts[1]:reverse()
    if not v163 then
        LocalPlayer:Kick("REPORT THIS BUG TO ECON | ERR 4")
        error("[4] REPORT TO ECON", 2)
    end
    for v166, v167 in ipairs(v163:split("")) do
        local success, result = pcall(v72, v73(v167) - 33 - 1)
        if not success then
            warn("<< Obfuscation: 377 > failed to convert " .. v167 .. " to char as " .. result)
            error("Deobfuscation stopped due to error", 2)
        end
        table.insert(t16, result)
    end
    local v170 = parts[2]
    local s6 = ""
    if not v170 then
        v35("ECON KEY >> " .. v160)
        LocalPlayer:Kick("ERR 5 | REPORT TO ECON | COPIED KEY, PASTE (CTRL+V) IN BUG REPORT")
        error("[5] REPORT TO ECON", 2)
    end
    for _, v in ipairs(v170:split("")) do
        local v174 = v73(v) - 33

        if not t16[v174] then
            warn("<< Obfuscation >> save index not found: " .. v174)

            return
        end

        s6 ..= t16[v174]
    end

    return s6
end
local function v76()
    local v175 = game:GetService("RbxAnalyticsService"):GetClientId():reverse()

    if not v175 then
        error("[6] REPORT TO ECON", 2)
    end

    local parts = v175:split("-")
    local s7 = ""

    table.sort(parts, function(p21, p22)
        return p21 < p22
    end)

    for _, v in pairs(parts) do
        s7 ..= v .. "-"
    end

    return (s7:sub(1, #s7 - 1))
end
local function v77(p23, p24)
    local _ = game:GetService("Players").LocalPlayer
    local ClientId2 = game:GetService("RbxAnalyticsService"):GetClientId()
    local Encode = t12.Encode

    if not p23 then
        p23 = os.time()
    end

    local v185 = Encode(p23)

    local function v186(p25, p26)
        return p25:sub(1, p26):reverse() .. p25:sub(p26 + 1, -1)
    end

    local v187 = v186(v185:reverse(), 4)
    local v188 = v74
    local v189 = v186(v185, 3)
    local v190 = v187:reverse()
    local v191 = v76():reverse()

    if p24 then
        p24 = p24:gsub("econ%-", ""):reverse()
    end

    return v188(v187 .. "," .. "mKx" .. ClientId2 .. "," .. v189 .. "," .. v190 .. "," .. v191 .. ("2rKl" .. p24 or "n"))
end
local num = tonumber(game:HttpGet("https://raw.githubusercontent.com/C0XNEcon/Econ3xC/refs/heads/main/LetsTakeItAway"))
local function v79(p27, p28, p29, p30)
    if not p27 then
        p27 = v77(p28, p30)
    end

    local v205 = readfile(t1.keynew) ~= ""
    local v206 = false

    if p27 ~= readfile(t1.keynew) then
    end

    repeat
        writefile(t1.keynew, p27)

        if v206 then
            task.wait(1)
        end

        v206 = true
    until p27 == readfile(t1.keynew)

    local v207 = v49
    local v208 = RunService:IsStudio()

    if v208 then
        v208 = LocalPlayer.PlayerGui
    end

    v207.Parent = v208 or u10
    getgenv().ECON_SUBSCRIPTION = p29 == "Key Access" and p27.time or p29

    if not getgenv().ECON_AUTOLOAD then
        getgenv().ECON_DO_UI_SHOWING = true
    end

    local function v209()
        local spawn = task.spawn
        local _loadstring = loadstring
        local v333 = getgenv()["econ.Main"]

        if not v333 then
            v333 = game:HttpGet("https://raw.githubusercontent.com/C0XNEcon/Econ3xC/refs/heads/main/" .. "Econ")
        end

        spawn(_loadstring(v333))
    end

    local _, result = pcall(function()
        return readfile(t1.settings)
    end)
    local v212 = result or "{}"
    local v213 = not v205

    if not v213 then
        v213 = v212:find("{")
    end

    if v213 then
        task.spawn(function()
            getgenv()._econ_domenuopennotif = true
            task.wait(0.7)

            local Prepare = v49.Prepare
            local Options = Prepare.Options

            v49.Loading.GroupTransparency = 0.3
            v49.Loading.Position = UDim2.fromScale(0, 0.015)
            v49.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            v49.Loading.Interactable = false
            v49.Loading.Visible = true
            Prepare.Parent = v49.Loading
            Prepare.Visible = true

            local function v336(p31, p32)
                return p32 <= 0 and p31 or math.round(p31 / p32) * p32
            end
            local function v337(p33, p34, p35, p36)
                local num2 = tonumber(p33.Text)

                p33.FocusLost:Connect(function()
                    num2 = math.clamp(v336(tonumber(p33.Text) or 1, p36), p34, p35)
                    p33.Text = num2
                end)

                return function()
                    return num2
                end
            end

            local v338 = v337(Options.sens.main, 0.05, 4, 0.05)
            local v339 = v337(Options.ads.main, 0.05, 2, 0.05)
            local v340 = TweenService
            local Loading = v49.Loading
            local tweenInfo = TweenInfo.new(0.3)
            local Create = v340.Create
            local uDim2 = UDim2.fromScale(0, 0)

            Create(v340, Loading, tweenInfo, {
				GroupTransparency = 0,
				Position = uDim2
			}):Play()
            task.delay(0.3, function()
                v49.Loading.Interactable = true
                Prepare.Parent = v49
                v49.Loading.Visible = false
                v49.ZIndexBehavior = Enum.ZIndexBehavior.Global
                Prepare.Ok.MouseButton1Click:Once(function()
                    getgenv().econ_sens = v338()
                    getgenv().econ_sens_ads = v339()
                    Prepare.Parent = v49.Loading
                    v49.Loading.Interactable = false
                    v49.Loading.Visible = true
                    v49.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

                    local v398 = TweenService
                    local Loading3 = v49.Loading
                    local tweenInfo3 = TweenInfo.new(0.3)
                    local fromScale = UDim2.fromScale
                    local Create3 = v398.Create
                    local v403 = fromScale(0, 0.015)

                    Create3(v398, Loading3, tweenInfo3, {
						GroupTransparency = 1,
						Position = v403
					}):Play()
                    task.delay(1, function()
                        v49:Destroy()
                    end)
                    v209()
                end)
            end)
        end)
    else
        v209()
    end

    return true
end
local function v80(p37)
    local Blocked = v49.Blocked
    if not p37 then
        p37 = t8[LocalPlayer.UserId]
    end
    local v222 = v49
    local v223 = RunService:IsStudio()
    if v223 then
        v223 = LocalPlayer.PlayerGui
    end
    v222.Parent = v223 or u10
    v49.Enabled = true
    Blocked.Size = UDim2.fromOffset(380, 180)
    Blocked.BackgroundTransparency = 1
    Blocked.Title.TextTransparency = 1
    Blocked.Ok.BackgroundTransparency = 1
    Blocked.Ok.TextTransparency = 1
    Blocked.Shadow.Image.ImageTransparency = 1
    Blocked.Appeal.TextTransparency = 1
    Blocked.Link.TextTransparency = 1
    Blocked.List.Transparency = 1
    Blocked.Visible = true
    v61("error")
    for v226, v227 in pairs(p37.reasons) do

        if v227.content then
            local clone = _elements.blockreason:Clone()

            clone.Content.Text = v227.content
            clone.Title.Text = v227.reason or "General"
            clone.Parent = Blocked.List
        end
    end
    for _, child in pairs(Blocked.List:GetChildren()) do
        for _, child2 in pairs(child:GetChildren()) do
            if child2:IsA("TextLabel") then
                child2.TextTransparency = 1
                task.delay(0.05, function()
                    TweenService:Create(child2, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {
						TextTransparency = 0
					}):Play()
                end)
            end
        end

        if child:IsA("Frame") then
            child.Visible = true
        end
    end
    local v233 = TweenService
    local tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Exponential)
    local uDim2 = UDim2.fromOffset(425, 250)
    v233:Create(Blocked, tweenInfo, {
		Transparency = 0.15,
		Size = uDim2
	}):Play()
    TweenService:Create(Blocked.Shadow.Image, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {
		ImageTransparency = 0.5
	}):Play()
    task.wait(0.05)
    TweenService:Create(Blocked.Title, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {
		TextTransparency = 0
	}):Play()
    TweenService:Create(Blocked.Ok, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {
		Transparency = 0,
		TextTransparency = 0
	}):Play()
    TweenService:Create(Blocked.Appeal, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {
		TextTransparency = 0.9
	}):Play()
    TweenService:Create(Blocked.Link, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {
		TextTransparency = 0.8
	}):Play()
    TweenService:Create(Blocked.List, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {
		Transparency = 0.1
	}):Play()
    local Link = Blocked.Link
    if not p37.no_appeal then
        Link.MouseEnter:Connect(function()
            Link.Text = "<u>Discord</u>"
        end)
        Link.MouseLeave:Connect(function()
            Link.Text = "Discord"
        end)
        Link.MouseButton1Click:Connect(function()
            if v35 then
                v35("KrVC64n3kK")
            end

            if v38 then
                local v347 = v38
                local t19 = {
					["Content-Type"] = "application/json",
					Origin = "https://discord.com"
				}
                local v349 = HttpService
                local JSONEncode = v349.JSONEncode
                local guid = HttpService:GenerateGUID(false)
                local t20 = {
					code = "KrVC64n3kK"
				}
                local v353 = JSONEncode(v349, {
					cmd = "INVITE_BROWSER",
					nonce = guid,
					args = t20
				})

                v347({
					Url = "http://127.0.0.1:6463/rpc?v=1",
					Method = "POST",
					Headers = t19,
					Body = v353
				})
            end
        end)
    else
        Link.Visible = false
        Blocked.Appeal.Text = "This ban cannot be appealed"
    end
    Blocked.Ok.MouseButton1Down:Once(function()
        for _, child in pairs(Blocked.List:GetChildren()) do
            local GetChildren = child.GetChildren

            for _, v in pairs(GetChildren(child)) do
                if v:IsA("TextLabel") then
                    TweenService:Create(v, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
						TextTransparency = 1
					}):Play()
                end
            end
        end

        v61("click")

        local v359 = TweenService
        local v360 = Blocked
        local new = TweenInfo.new
        local EasingStyle = Enum.EasingStyle
        local Create = v359.Create
        local v364 = new(0.6, EasingStyle.Exponential)
        local uDim2_4 = UDim2.fromOffset(395, 120)

        Create(v359, v360, v364, {
			BackgroundTransparency = 1,
			Size = uDim2_4
		}):Play()
        TweenService:Create(Blocked.Shadow.Image, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
			ImageTransparency = 1
		}):Play()
        TweenService:Create(Blocked.Title, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
			TextTransparency = 1
		}):Play()
        TweenService:Create(Blocked.Ok, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
			BackgroundTransparency = 1,
			TextTransparency = 1
		}):Play()
        TweenService:Create(Blocked.Appeal, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
			TextTransparency = 1
		}):Play()
        TweenService:Create(Blocked.Link, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
			TextTransparency = 1
		}):Play()
        TweenService:Create(Blocked.List, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
			Transparency = 1
		}):Play()
        task.wait(0.6)
        v49:Destroy()
    end)
end
local function v81()
    local Bypassed = v49.Bypassed

    Bypassed.Size = UDim2.fromOffset(395, 85)
    Bypassed.BackgroundTransparency = 1
    Bypassed.Title.TextTransparency = 1
    Bypassed.Ok.BackgroundTransparency = 1
    Bypassed.Ok.TextTransparency = 1
    Bypassed.Shadow.Image.ImageTransparency = 1
    Bypassed.Visible = true
    v61("error")

    for _, child in pairs(Bypassed.List:GetChildren()) do
        local GetChildren = child.GetChildren

        for _, v in pairs(GetChildren(child)) do
            local v243 = v

            if v243:IsA("TextLabel") then
                v243.TextTransparency = 1
                task.delay(0.05, function()
                    TweenService:Create(v243, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {
						TextTransparency = 0
					}):Play()
                end)
            end
        end
    end

    local v244 = TweenService
    local tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Exponential)
    local Create = v244.Create
    local uDim2 = UDim2.fromOffset(425, 100)

    Create(v244, Bypassed, tweenInfo, {
		BackgroundTransparency = 0,
		Size = uDim2
	}):Play()
    TweenService:Create(Bypassed.Shadow.Image, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {
		ImageTransparency = 0.5
	}):Play()
    task.wait(0.05)
    TweenService:Create(Bypassed.Title, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {
		TextTransparency = 0
	}):Play()
    TweenService:Create(Bypassed.Ok, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {
		BackgroundTransparency = 0,
		TextTransparency = 0
	}):Play()
    Bypassed.Ok.MouseButton1Down:Once(function()
        for _, child in pairs(Bypassed.List:GetChildren()) do
            for _, child3 in pairs(child:GetChildren()) do
                if child3:IsA("TextLabel") then
                    TweenService:Create(child3, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
						TextTransparency = 1
					}):Play()
                end
            end
        end

        v61("click")

        local v370 = TweenService
        local v371 = Bypassed
        local tweenInfo4 = TweenInfo.new(0.6, Enum.EasingStyle.Exponential)
        local Create4 = v370.Create
        local uDim2_5 = UDim2.fromOffset(395, 120)

        Create4(v370, v371, tweenInfo4, {
			BackgroundTransparency = 1,
			Size = uDim2_5
		}):Play()
        TweenService:Create(Bypassed.Shadow.Image, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
			ImageTransparency = 1
		}):Play()
        TweenService:Create(Bypassed.Title, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
			TextTransparency = 1
		}):Play()
        TweenService:Create(Bypassed.Ok, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
			BackgroundTransparency = 1,
			TextTransparency = 1
		}):Play()
        task.wait(0.6)
        v49:Destroy()
    end)
end
local function v82(p38, p39)
    TweenService:Create(p38:FindFirstChild("Button") or p38, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
		BackgroundTransparency = p39
	}):Play()
    TweenService:Create(p38.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
		Transparency = p39
	}):Play()

    if p38:FindFirstChild("InputBox") then
        TweenService:Create(p38.InputBox, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
			TextTransparency = p39
		}):Play()
    end

    if p38:FindFirstChild("Copy") then
        TweenService:Create(p38.Copy, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
			ImageTransparency = p39
		}):Play()
    end
end
local function v83()
    (nil):Disconnect()
    for v252, v253 in pairs(t10) do

        v253:Disconnect()
    end
    if u64 then
        local v254 = TweenService
        local v255 = u64
        local tweenInfo = TweenInfo.new(0.15)
        local yAxis = Vector2.yAxis
        local Create = v254.Create
        local uDim2 = UDim2.fromScale(0, -0.25)

        Create(v254, v255, tweenInfo, {
			AnchorPoint = yAxis,
			Position = uDim2,
			TextTransparency = 1
		}):Play()
    end
    local v260 = TweenService
    local v261 = Main
    local tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Exponential)
    local uDim2 = UDim2.fromOffset(467, 175)
    v260:Create(v261, tweenInfo, {
		BackgroundTransparency = 1,
		Size = uDim2
	}):Play()
    TweenService:Create(Main.Logo, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {
		ImageTransparency = 1
	}):Play()
    TweenService:Create(Main.Shadow.Image, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
		ImageTransparency = 1
	}):Play()
    TweenService:Create(Main.Title, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
		TextTransparency = 1
	}):Play()
    TweenService:Create(Main.Subtitle, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
		TextTransparency = 1
	}):Play()
    TweenService:Create(Main.Logo.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
		Transparency = 1
	}):Play()
    TweenService:Create(Main.EconID.ID, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
		TextTransparency = 1
	}):Play()
    TweenService:Create(Main.EconID.Get, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
		TextTransparency = 1
	}):Play()
    TweenService:Create(Main.Frame, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
		ImageTransparency = 1
	}):Play()
    TweenService:Create(Main.manual, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {
		BackgroundTransparency = 1
	}):Play()
    TweenService:Create(Main.manual, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
		TextTransparency = 1
	}):Play()
    if u53 then
        TweenService:Create(u53.button.Copy, TweenInfo.new(0.3), {
			ImageTransparency = 0
		}):Play()
        TweenService:Create(u53.button.Selected, TweenInfo.new(0.3), {
			Transparency = 1
		}):Play()
        TweenService:Create(u53.button.Selected.ImageLabel, TweenInfo.new(0.3), {
			ImageTransparency = 1
		}):Play()
    end
    v82(Main.Input, 1)
    for _, child in pairs(Main.Services:GetChildren()) do
        if child:IsA("Frame") then
            v82(child, 1)
        end
    end
    TweenService:Create(Main.Hide, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
		ImageTransparency = 1
	}):Play()
end
local u84
local function v85(p40, p41)
    local n4 = 0

    p41.button = p40
    t11[p40.Name] = {}
    t10[p40.Name] = p40.Button.MouseButton1Down:Connect(function()
        if u62 then
            return
        end

        n4 += 1

        if not u54 then
            t10.backgroundStep = RunService.Stepped:Connect(function()
                local v395
                if v36 then
                    v395 = v36()
                end
                if not v395 then
                    u56 = os.clock()

                    if not u54 then
                        u54 = os.clock()
                    end
                end
                local v396 = u54
                if v396 then

                    v396 = u56 - u54 > 10
                end
                if v396 then
                    t10.backgroundStep:Disconnect()
                end
            end)
        end

        p40.Button.UIGradient.Offset = Vector2.xAxis * 1.3
        TweenService:Create(p40.Button.UIGradient, TweenInfo.new(0.25), {
			Offset = Vector2.xAxis * -1.3
		}):Play()
        v61("click")

        for _, v in pairs(t11[p40.Name]) do
            v:Cancel()
        end

        table.clear(t11[p40.Name])
        u53 = p41

        local v377 = tick() - -10000000000
        local n5 = 5

        if v377 < n5 then
            v65("Wait " .. math.ceil(n5 - v377) .. "s")

            if v35 then
                v35("")
            end

            return
        end

        tick()
        u84.provider = p41.provider
        u84.service = p41.service

        local v379 = v63()
        local ok, result = pcall(function()
            return u84.get_key_link()
        end)

        if not result or not ok then
            v65("An error occurred: " .. result)
            warn("<< Econ JunkieKeySystem Error >> " .. result)
            v379()

            return
        end

        v379()
        Main.manual.Text = result
        Main.manual.Visible = true

        if ok and (v35 and result) then
            v65("Copied URL", Color3.new(0.541176, 0.917647, 0.435294))
            v35(result)

            return
        end

        v65("An error occurred")
    end)
end
local function v86(p42, p43)
    (p42:FindFirstChild("Button") or p42).BackgroundTransparency = p43
    p42.UIStroke.Transparency = p43

    if p42:FindFirstChild("InputBox") then
        p42.InputBox.TextTransparency = p43
    end

    if p42:FindFirstChild("Copy") then
        p42.Copy.ImageTransparency = p43
    end
end
if t8[LocalPlayer.UserId] or ({})[ClientId] then
    v80()

    return
end
if isfile("security_lock") then
    v80(v44.econ_bypass_key)

    return
end
if v79(nil, os.time() + 86400, "Free Reward") then
    return
end
local v87 = t4[LocalPlayer.UserId] or t4[v76()]
if v87 then
    v87 = os.time() - v87[2] <= v87[1]
end
if not v87 then
    v87 = table.find({}, LocalPlayer.UserId)

    if not v87 then
        v87 = table.find({
			"40A8-4D5D-7BEE80723672-82E3F713-9294",
			"361A-3CCD60517A53-63E3-BA24-EBD420E1",
			"044B-306FFCC3-8ABA5FF2244F-9BB4-AB3D",
			"25A4-283D3E9F1AB5-46D0F3FE-61A8-B41B",
			"041B-1E5BEB80EA91-2EA4-3529C5CA-F4F2",
			"2AC7-3154-3C76C09E62F7-B82B5E0C-CF2B",
			"442D4F08-5E1BFDCC65E6-6744-6894-B8A8",
			"1A1A41BC2F33-9D94-D2DF-D5BA-E985455A",
			"3980-42B4-7472534D0E50-906A-C4050F72",
			"07A4-2208-2C19-61EF0DB364AD-E518B1E9",
			"2a669a07dc58-37fb036b-5703-a6b4-c49a",
			"28C3454E-3CF6-6625F75FA045-F514-FA4A",
			"5190CCF2-AFD0-DC6B-DE50E1CFC7E0-FDF4",
			"15756FBCB7F7-346F-5839-5A14-94972311",
			"5599F471-57E9-B819-CE04-FA775D41F86D",
			"029B-2CFCC6E62B59-39735989-6899-6C34",
			"1828FBE9-253A-6908-951DD3FD722F-A394"
		}, (v76()))
    end
end
if v87 then
    v87 = v79(nil, os.time() + 604800, "Unlimited")
end
if v87 then
    return
end
local u88
if isfile(t1.keynew) then
    local v89 = readfile(t1.keynew)
    local v90 = v89:byte() ~= 32

    if v89 ~= "" and v90 then
        u88 = (function(p44)
            local v193 = v75(p44)

            if not v193 then
                error("[7] REPORT TO ECON", 2)
            end

            local parts = v193:split(",")
            local v195 = v76():reverse() .. "2rKl"
            local v196 = parts[2]:sub(4, -1)
            local Decode = t12.Decode
            local v198 = parts[1]
            local v199 = Decode((v198:sub(1, 4):reverse() .. v198:sub(5, -1)):reverse())
            local v200 = "econ-" .. parts[5]:sub(#v195 + 1, -1):reverse()

            return {
				id = v196,
				time = v199,
				all = parts,
				key = v200
			}
        end)(v89)

        local v91 = (function(p45)
            if not game:GetService("Players").LocalPlayer then
            end

            local all = p45.all

            if #all ~= 5 then
                warn("KEY BYPASSED [0]")

                return
            end

            if all[2]:sub(1, 3) ~= "mKx" then
                warn("KEY BYPASSED [A]")

                return
            end

            local v216 = all[3]

            if v216:sub(1, 3):reverse() .. v216:sub(4, -1) ~= t12.Encode(p45.time) then
                warn("KEY BYPASSED [B]")

                return
            end

            if all[4] ~= all[1]:reverse() then
                warn("KEY BYPASSED [D]")

                return
            end

            local v217 = v76():reverse() .. "2rKl"
            local v218 = all[5]:sub(#v217 + 1, -1)

            if v217 ~= all[5]:sub(1, #v217) then
                warn("KEY BYPASSED [E]")

                return
            end

            local v219 = #v218 < 15

            if v219 then
                v219 = v218 ~= "" and v218 ~= "n"
            end

            if v219 then
                warn("KEY BYPASSED [F]")

                return
            end

            if num > 48 then
                warn("KEY BYPASSED [G]")

                return
            end

            if p45 then
                p45 = p45.id == game:GetService("RbxAnalyticsService"):GetClientId() and os.time() - p45.time <= num * 3600
            end

            return p45
        end)(u88)
        local v92 = v91

        if v91 then
            v92 = v79(v89, nil, "Key Access")
        end

        if v92 then
            return
        end

        if not v91 then
            LocalPlayer:Kick("not VLAID man")
        end
    end

    local delay = task.delay

    if v90 then
        v90 = "Key corrupted [" .. v90 .. "]"
    end

    delay(0.5, v65, v90 or "Key expired")
end
task.spawn(function()
    local v283 = v63()
    local u284
    local u285
    local u286 = false
    task.spawn(function()
        local ok, result = pcall(function()
            return game:HttpGet("https://jnkie.com/sdk/library.lua")
        end)

        u284 = ok
        u285 = result

        if u286 then
            return
        end

        u286 = true

        local v384 = not u284

        if not v384 then
            v384 = not u285 or #u285 < 100
        end

        if v384 then
            warn("<< Econ >> JunkieKeySystem is currently down")
            warn(u285)
            v49.Bypassed.Title.Text = "JD — " .. tostring(u285)
            v81()
            v83()

            return
        end

        local ok2, result2 = pcall(function()
            return loadstring(u285)()
        end)
        local v387 = true

        if typeof(result2) ~= "string" then
            v387 = not ok2
        end

        if v387 then
            warn("<< Econ >> JunkieKeySystem is currently down")
            warn(u285)
            v49.Bypassed.Title.Text = "JD — " .. tostring(u285)
            v81()
            v83()

            return
        end

        result2.identifier = "7959"
        u84 = result2
        v283()
    end)
    task.delay(15, function()
        if u286 then
            return
        end

        warn("<< Econ >> JunkieKeySystem took too long")
        warn(u285)
        v49.Bypassed.Title.Text = "JD — Response taking too long"
        v81()
        v83()
    end)
end);
(function()
    local v271 = v49
    local v272 = RunService:IsStudio()

    if v272 then
        v272 = LocalPlayer.PlayerGui
    end

    v271.Parent = v272 or u10
    Main.Shadow.Image.ImageTransparency = 1
    Main.Subtitle.TextTransparency = 1
    Main.BackgroundTransparency = 1
    Main.Title.TextTransparency = 1
    Main.Hide.ImageTransparency = 1
    Main.Logo.ImageTransparency = 1
    Main.Logo.UIStroke.Transparency = 1
    Main.Frame.ImageTransparency = 1
    Main.Size = UDim2.fromOffset(467, 190)
    Main.Visible = true
    Main.EconID.ID.TextTransparency = 1
    Main.EconID.Get.TextTransparency = 1
    v49.Loading.SelectionImageObject = nil
    v49.Enabled = true
    v86(Main.Input, 1)

    local ID = Main.EconID.ID

    ID.MouseEnter:Connect(function()
        ID.Text = "<u>Econ ID</u>"
    end)
    ID.MouseLeave:Connect(function()
        ID.Text = "Econ ID"
    end)
    ID.MouseButton1Click:Connect(function()
        if v35 then
            v35((v76()))
        end
    end)

    local v274 = TweenService
    local v275 = Main
    local tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Exponential)
    local _UDim2 = UDim2
    local Create = v274.Create
    local v279 = _UDim2.new(0, 500, 0, 205)

    Create(v274, v275, tweenInfo, {
		BackgroundTransparency = 0.15,
		Size = v279
	}):Play()
    TweenService:Create(Main.Logo, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {
		ImageTransparency = 0
	}):Play()
    TweenService:Create(Main.Logo.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
		Transparency = 0.3
	}):Play()
    TweenService:Create(Main.Frame, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
		ImageTransparency = 0.6
	}):Play()
    TweenService:Create(Main.Shadow.Image, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
		ImageTransparency = 0.5
	}):Play()
    task.wait(0.05)
    TweenService:Create(Main.Title, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
		TextTransparency = 0
	}):Play()
    TweenService:Create(Main.Subtitle, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
		TextTransparency = 0
	}):Play()
    TweenService:Create(Main.EconID.ID, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
		TextTransparency = 0.8
	}):Play()
    TweenService:Create(Main.EconID.Get, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
		TextTransparency = 0.9
	}):Play()
    task.wait(0.05)
    v82(Main.Input, 0)

    for _, v in pairs(t9) do
        local clone = _elements.service:Clone()

        clone.Copy.Image = v.img
        clone.Parent = Main.Services
        v86(clone, 1)
        clone.Visible = true
        v82(clone, 0)
        v85(clone, v)
    end

    task.wait(0.2)
    TweenService:Create(Main.Hide, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
		ImageTransparency = 0.3
	}):Play()
end)()
Main.Input.InputBox.FocusLost:Connect(function(enterPressed)
    if #Main.Input.InputBox.Text == 0 or not enterPressed then
        return
    end
    if u62 then
        return
    end
    local v288 = v63()
    local InputBoxText = Main.Input.InputBox.Text
    local u290 = InputBoxText
    local ok, result = pcall(function()
        return (u84.check_key(u290))
    end)
    local v293 = not result
    if not v293 then
        v293 = not result.valid or not ok
    end
    if v293 then
        for _, v in pairs(t9) do
            local name = v.name
            local v297 = u53

            if v297 then
                v297 = u53.name
            end

            if name ~= (v297 or "...") then
                u84.provider = v.provider
                u84.service = v.service
                ok, result = pcall(function()
                    return (u84.check_key(u290))
                end)

                if result and result.valid then
                    break
                end
            end
        end
    end
    v288()
    if ok then
        ok = typeof(result) == "table" and result.valid
    end
    if ok then
        local v298 = u88

        if v298 then
            v298 = u88.key == u290
        end

        if v298 then
            v83()
            task.delay(0.3, function()
                v80(v44.econ_bypass_key)
            end)
            writefile("security_lock", "")

            return
        end

        task.spawn(v79, nil, nil, "Key Access", u290)
        v83()
        task.wait(0.51)
        Main.Visible = false
    else
        v61("error")
        v65("Invalid key")
        Main.Input.InputBox.Text = ""
        TweenService:Create(Main, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {
			Size = UDim2.new(0, 467, 0, 175)
		}):Play()
        TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Elastic), {
			Position = UDim2.new(0.495, 0, 0.5, 0)
		}):Play()
        task.wait(0.1)
        TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Elastic), {
			Position = UDim2.new(0.505, 0, 0.5, 0)
		}):Play()
        task.wait(0.1)
        TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
			Position = UDim2.new(0.5, 0, 0.5, 0)
		}):Play()
        TweenService:Create(Main, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {
			Size = UDim2.new(0, 500, 0, 205)
		}):Play()
    end
end)
Main.Hide.MouseButton1Click:Once(function()
    v83()
    task.wait(0.51)
    v49:Destroy()
end)
