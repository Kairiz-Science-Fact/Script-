--!strict
--[[
    ███╗   ███╗ █████╗ ████████╗██████╗ ██╗██╗  ██╗    ██╗   ██╗ █████╗ 
    ████╗ ████║██╔══██╗╚══██╔══╝██╔══██╗██║╚██╗██╔╝    ██║   ██║██╔══██╗
    ██╔████╔██║███████║   ██║   ██████╔╝██║ ╚███╔╝     ██║   ██║╚██████║
    ██║╚██╔╝██║██╔══██║   ██║   ██╔══██╗██║ ██╔██╗     ╚██╗ ██╔╝ ╚═══██║
    ██║ ╚═╝ ██║██║  ██║   ██║   ██║  ██║██║██╔╝ ██╗     ╚████╔╝  █████╔╝
    ╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝      ╚═══╝   ╚════╝ 
    ========================================================================================
    [ M A T R I X   O M N I - K E R N E L   P R O T O C O L ]
    VERSION: 9.0.0-OMNI (CYBERPUNK HIGH-LEVEL ARCHITECTURE)
    AUTHOR: [SYSTEM_ROOT_UNKNOWN]
    CLASSIFICATION: CLASSIFIED // UNDETECTED
    ========================================================================================
]]

-----------------------------------------------------------------------------------------
-- [1] KERNEL TYPES, GLOBALS & CONFIGURATION
-----------------------------------------------------------------------------------------
type Dictionary<T> = { [string]: T }
type Array<T> = { [number]: T }
type Vector2 = typeof(Vector2.new(0, 0))
type Vector3 = typeof(Vector3.new(0, 0, 0))
type CFrame = typeof(CFrame.new())
type Color3 = typeof(Color3.new())

local KERNEL_CFG = {
    ENDPOINT          = "https://raw.githubusercontent.com/Its3rr0rsWRLD/Index/main/loader.json",
    TELEMETRY         = "https://mrnoodles--9c5c204036b411f19dfb42b51c65c3df.web.val.run/api/error",
    AUTH_KEY          = "sk&vUeSFi]3*z5$)&tgpJC_4c{@7PfAF",
    DISCORD_URL       = "https://discord.gg/RhdPCbZNUZ",
    CACHE_DIR         = "MATRIX_V9_OMNI",
    CACHE_FILE        = "MATRIX_V9_OMNI/config.json",
    LOG_FILE          = "MATRIX_V9_OMNI/kernel.log",
    MAX_RETRIES       = 5,
    TIMEOUT_SEC       = 15,
    DEBUG_MODE        = false,
    BYPASS_ENABLED    = true,
    MEMORY_SPOOF      = true
}

local PALETTE = {
    Background        = Color3.fromRGB(8, 8, 12),
    Surface           = Color3.fromRGB(15, 17, 23),
    SurfaceLight      = Color3.fromRGB(22, 25, 32),
    GridLines         = Color3.fromRGB(20, 30, 20),
    PrimaryNeon       = Color3.fromRGB(0, 255, 128),
    SecondaryNeon     = Color3.fromRGB(0, 200, 255),
    AccentPurple      = Color3.fromRGB(180, 0, 255),
    AlertRed          = Color3.fromRGB(255, 50, 50),
    SuccessGreen      = Color3.fromRGB(0, 255, 65),
    DarkGreen         = Color3.fromRGB(0, 80, 40),
    TextMain          = Color3.fromRGB(220, 230, 220),
    TextMuted         = Color3.fromRGB(120, 130, 120),
    Warning           = Color3.fromRGB(255, 180, 0),
    Black             = Color3.new(0, 0, 0)
}

local FONTS = {
    Code              = Font.new("rbxasset://fonts/families/Inconsolata.json", Enum.FontWeight.Bold),
    UI                = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.SemiBold),
    Regular           = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular)
}

-----------------------------------------------------------------------------------------
-- [2] SERVICE PROVIDER (SAFE INJECTION)
-----------------------------------------------------------------------------------------
local function RequestService(serviceName: string): any
    local success, result = pcall(game.GetService, game, serviceName)
    if success and result then
        if typeof(cloneref) == "function" then
            local cloneSuccess, cloned = pcall(cloneref, result)
            if cloneSuccess and cloned then return cloned end
        end
        return result
    end
    return nil
end

local Services = {
    Players           = RequestService("Players"),
    HttpService       = RequestService("HttpService"),
    TweenService      = RequestService("TweenService"),
    RunService        = RequestService("RunService"),
    VirtualUser       = RequestService("VirtualUser"),
    UserInputService  = RequestService("UserInputService"),
    CoreGui           = RequestService("CoreGui"),
    Lighting          = RequestService("Lighting"),
    Stats             = RequestService("Stats"),
    LogService        = RequestService("LogService"),
    Workspace         = RequestService("Workspace"),
    TeleportService   = RequestService("TeleportService"),
    Debris            = RequestService("Debris"),
    ReplicatedStorage = RequestService("ReplicatedStorage"),
    ContextAction     = RequestService("ContextActionService")
}

local LocalPlayer = Services.Players.LocalPlayer
while not LocalPlayer do
    Services.Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Services.Players.LocalPlayer
end
local Camera = Services.Workspace.CurrentCamera

-----------------------------------------------------------------------------------------
-- [3] CRYPTOGRAPHY & ENCRYPTION ENGINE
-----------------------------------------------------------------------------------------
local Crypto = {}
do
    local B64_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    
    function Crypto.Base64Encode(data: string): string
        return ((data:gsub('.', function(x) 
            local r,b='',x:byte()
            for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
            return r;
        end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
            if (#x < 6) then return '' end
            local c=0
            for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
            return B64_CHARS:sub(c+1,c+1)
        end)..({ '', '==', '=' })[#data%3+1])
    end

    function Crypto.Base64Decode(data: string): string
        data = string.gsub(data, '[^'..B64_CHARS..'=]', '')
        return (data:gsub('.', function(x)
            if (x == '=') then return '' end
            local r,f='',(B64_CHARS:find(x)-1)
            for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
            return r;
        end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
            if (#x ~= 8) then return '' end
            local c=0
            for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
            return string.char(c)
        end))
    end

    function Crypto.XOR(data: string, key: string): string
        local res = {}
        local keyLen = #key
        for i = 1, #data do
            local d = data:byte(i)
            local k = key:byte((i % keyLen) + 1)
            local x = bit32.bxor(d, k)
            table.insert(res, string.char(x))
        end
        return table.concat(res)
    end

    function Crypto.SHA256Mock(str: string): string
        local hash = 0x811c9dc5
        for i = 1, #str do
            hash = bit32.bxor(hash, str:byte(i))
            hash = bit32.band(hash * 0x01000193, 0xFFFFFFFF)
        end
        return string.format("%08x", hash)
    end
end

-----------------------------------------------------------------------------------------
-- [4] SYSTEM UTILITIES & FILE MANAGEMENT
-----------------------------------------------------------------------------------------
local SysUtils = {}
do
    function SysUtils.GetHWID(): string
        local hwid = "MATRIX_UNKNOWN_SYS"
        if gethwid then pcall(function() hwid = gethwid() end) end
        return Crypto.SHA256Mock(hwid)
    end
    
    function SysUtils.RandomString(length: number): string
        local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
        local res = ""
        for _ = 1, length do
            local rand = math.random(1, #chars)
            res = res .. string.sub(chars, rand, rand)
        end
        return res
    end

    function SysUtils.ProtectInstance(instance: Instance)
        if syn and syn.protect_gui then
            pcall(syn.protect_gui, instance)
        elseif gethui then
            instance.Parent = gethui()
        else
            instance.Parent = Services.CoreGui or LocalPlayer:WaitForChild("PlayerGui")
        end
    end

    function SysUtils.EnsureDirectory()
        if makefolder and isfolder and not isfolder(KERNEL_CFG.CACHE_DIR) then
            pcall(makefolder, KERNEL_CFG.CACHE_DIR)
        end
    end
    
    function SysUtils.WriteLog(msg: string)
        if writefile and appendfile then
            pcall(function()
                SysUtils.EnsureDirectory()
                local timestamp = os.date("[%Y-%m-%d %H:%M:%S] ")
                local formatted = timestamp .. msg .. "\n"
                if isfile(KERNEL_CFG.LOG_FILE) then
                    appendfile(KERNEL_CFG.LOG_FILE, formatted)
                else
                    writefile(KERNEL_CFG.LOG_FILE, formatted)
                end
            end)
        end
    end
end
SysUtils.EnsureDirectory()
SysUtils.WriteLog("KERNEL BOOT INITIALIZED")

-----------------------------------------------------------------------------------------
-- [5] CONFIGURATION AUTO-SAVE SYSTEM
-----------------------------------------------------------------------------------------
local ConfigSystem = { Settings = {} }
do
    function ConfigSystem.Save()
        if writefile then
            pcall(function()
                SysUtils.EnsureDirectory()
                local json = Services.HttpService:JSONEncode(ConfigSystem.Settings)
                writefile(KERNEL_CFG.CACHE_FILE, json)
                SysUtils.WriteLog("Configuration Saved.")
            end)
        end
    end

    function ConfigSystem.Load()
        if readfile and isfile and isfile(KERNEL_CFG.CACHE_FILE) then
            pcall(function()
                local json = readfile(KERNEL_CFG.CACHE_FILE)
                local data = Services.HttpService:JSONDecode(json)
                if data then
                    for k, v in pairs(data) do
                        ConfigSystem.Settings[k] = v
                    end
                end
                SysUtils.WriteLog("Configuration Loaded.")
            end)
        end
    end
end
ConfigSystem.Load()

-----------------------------------------------------------------------------------------
-- [6] MATH & PHYSICS CORE (PREDICTION)
-----------------------------------------------------------------------------------------
local Physics = {}
do
    function Physics.CalculateTrajectory(origin: Vector3, target: Vector3, velocity: number, gravity: number): Vector3
        local dist = (target - origin).Magnitude
        local timeToTarget = dist / (velocity > 0 and velocity or 1)
        return target + Vector3.new(0, 0.5 * gravity * (timeToTarget ^ 2), 0)
    end
    
    function Physics.GetClosestPlayerToMouse(fov: number): (Player?, number)
        local closestDist = fov or math.huge
        local closestTarget = nil
        for _, plr in ipairs(Services.Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = plr.Character.HumanoidRootPart
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local mousePos = Services.UserInputService:GetMouseLocation()
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestTarget = plr
                    end
                end
            end
        end
        return closestTarget, closestDist
    end

    function Physics.RaycastVisibility(origin: Vector3, target: Vector3, ignoreList: Array<Instance>): boolean
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = ignoreList
        params.IgnoreWater = true
        
        local direction = (target - origin)
        local result = Services.Workspace:Raycast(origin, direction.Unit * direction.Magnitude, params)
        return result == nil
    end
end

-----------------------------------------------------------------------------------------
-- [7] MEMORY SPOOFING, BYPASS, & MULTIPLIERS
-----------------------------------------------------------------------------------------
local BypassCore = {}
do
    function BypassCore.InjectMultipliers()
        local env = (getgenv and getgenv()) or _G
        local flags = {
            "Index_IncomeMultiplier", "Index_CoinMultiplier", "Index_ExpMultiplier", 
            "AutoFarmMultiplier", "Damage_Multiplier", "Speed_Multiplier",
            "Jump_Multiplier", "Matrix_Overdrive", "GodMode_Bypass",
            "Infinite_Stamina", "Cooldown_Reduction", "Bypass_AC"
        }
        
        for _, flag in ipairs(flags) do 
            env[flag] = 9999999 
        end
        env.ForceMultiplier = true
        env.Matrix_Bypass_Active = true
        
        if setreadonly then pcall(setreadonly, env, false) end
        SysUtils.WriteLog("Multipliers & Envs Injected Successfully")
    end
    
    function BypassCore.HookMetatable()
        if not KERNEL_CFG.BYPASS_ENABLED then return end
        if getrawmetatable and hookmetamethod then
            local gm = getrawmetatable(game)
            local env = (getgenv and getgenv()) or _G
            
            if gm and not env.MatrixHooked then
                env.MatrixHooked = true
                if setreadonly then setreadonly(gm, false) end
                
                -- Anti-Kick Hook
                local oldNamecall = gm.__namecall
                if oldNamecall then
                    hookmetamethod(game, "__namecall", function(self, ...)
                        local method = getnamecallmethod()
                        if not checkcaller() then
                            if method == "Kick" or method == "kick" then
                                SysUtils.WriteLog("Blocked Kick attempt.")
                                return nil
                            end
                            if method == "FireServer" and tostring(self):lower():match("ban") then
                                return nil
                            end
                        end
                        return oldNamecall(self, ...)
                    end)
                end
                
                -- Anti-Cheat Memory Spoof Hook
                local oldIndex = gm.__index
                if oldIndex then
                    hookmetamethod(game, "__index", function(self, key)
                        if not checkcaller() then
                            if key == "WalkSpeed" and self:IsA("Humanoid") then return 16 end
                            if key == "JumpPower" and self:IsA("Humanoid") then return 50 end
                        end
                        return oldIndex(self, key)
                    end)
                end
                
                if setreadonly then setreadonly(gm, true) end
                SysUtils.WriteLog("Metatables Hooked Securely")
            end
        end
    end
end

-----------------------------------------------------------------------------------------
-- [8] ANTI-AFK DAEMON
-----------------------------------------------------------------------------------------
local AntiAFK = {}
do
    function AntiAFK.Initialize()
        if Services.VirtualUser and LocalPlayer then
            LocalPlayer.Idled:Connect(function()
                Services.VirtualUser:CaptureController()
                Services.VirtualUser:ClickButton2(Vector2.new())
                Services.VirtualUser:SetKeyDown("w")
                task.wait(0.1)
                Services.VirtualUser:SetKeyUp("w")
                SysUtils.WriteLog("Anti-AFK Triggered.")
            end)
        end
        Services.LogService.MessageOut:Connect(function(message, type)
            if type == Enum.MessageType.MessageError then
                if message:match("Index") or message:match("Matrix") then
                    -- Suppressed internally
                end
            end
        end)
    end
end
task.spawn(AntiAFK.Initialize)

-----------------------------------------------------------------------------------------
-- [9] OMNI-VISUALS ENGINE (ESP, CHAMS, TRACERS, SKELETON)
-----------------------------------------------------------------------------------------
local RenderEngine = { 
    Enabled = false, 
    BoxEnabled = true, 
    NameEnabled = true, 
    HealthEnabled = true,
    TracerEnabled = false,
    SkeletonEnabled = false,
    Objects = {} 
}
do
    function RenderEngine.CreateESP(player: Player)
        if player == LocalPlayer then return end
        
        local espContainer = Instance.new("Folder")
        espContainer.Name = "MatrixESP_" .. player.Name
        SysUtils.ProtectInstance(espContainer)
        
        -- Highlight (Chams)
        local highlight = Instance.new("Highlight")
        highlight.FillColor = PALETTE.AlertRed
        highlight.OutlineColor = PALETTE.PrimaryNeon
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = espContainer
        
        -- Billboard Tag
        local tag = Instance.new("BillboardGui")
        tag.Size = UDim2.new(0, 200, 0, 50)
        tag.StudsOffset = Vector3.new(0, 3.5, 0)
        tag.AlwaysOnTop = true
        tag.Parent = espContainer
        
        local nameText = Instance.new("TextLabel", tag)
        nameText.Size = UDim2.new(1, 0, 0.5, 0)
        nameText.BackgroundTransparency = 1
        nameText.Text = player.Name
        nameText.TextColor3 = PALETTE.PrimaryNeon
        nameText.Font = Enum.Font.Code
        nameText.TextSize = 13
        nameText.TextStrokeTransparency = 0
        
        local hpText = Instance.new("TextLabel", tag)
        hpText.Size = UDim2.new(1, 0, 0.5, 0)
        hpText.Position = UDim2.fromScale(0, 0.5)
        hpText.BackgroundTransparency = 1
        hpText.Text = "HP: 100/100"
        hpText.TextColor3 = PALETTE.SuccessGreen
        hpText.Font = Enum.Font.Code
        hpText.TextSize = 11
        hpText.TextStrokeTransparency = 0
        
        -- Tracer Line (Drawing API)
        local tracer = Drawing and Drawing.new("Line") or nil
        if tracer then
            tracer.Visible = false
            tracer.Color = PALETTE.PrimaryNeon
            tracer.Thickness = 1
            tracer.Transparency = 0.8
        end
        
        RenderEngine.Objects[player] = { 
            container = espContainer, 
            highlight = highlight, 
            tag = tag,
            nameText = nameText,
            hpText = hpText,
            tracer = tracer
        }
        
        local function Update()
            if not RenderEngine.Enabled then
                highlight.Adornee = nil
                tag.Adornee = nil
                if tracer then tracer.Visible = false end
                return
            end
            
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
                local hum = player.Character.Humanoid
                local hrp = player.Character.HumanoidRootPart
                
                if hum.Health > 0 then
                    highlight.Adornee = player.Character
                    highlight.Enabled = RenderEngine.BoxEnabled
                    tag.Adornee = player.Character:FindFirstChild("Head") or hrp
                    
                    local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local dist = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude)
                        nameText.Text = string.format("[%s] %d", player.Name, dist)
                        nameText.Visible = RenderEngine.NameEnabled
                        
                        hpText.Text = string.format("%d HP", math.f
