--!strict
--[[
    =======================================================================
    INDEX EXECUTION FRAMEWORK v5.0 (APEX PREDATOR ARCHITECTURE)
    =======================================================================
--]]

type ButtonsConfig = { Title: string, Callback: (() -> ())? }
type GameConfigData = { url: string }
type GlobalConfig = { games: { [string]: GameConfigData } }

local SafeGetService = function(service: string): any
    local s, r = pcall(game.GetService, game, service)
    if s and r then
        return (cloneref and cloneref(r)) or r
    end
    return nil
end

local Players = SafeGetService("Players") :: Players
local HttpService = SafeGetService("HttpService") :: HttpService
local TweenService = SafeGetService("TweenService") :: TweenService
local RunService = SafeGetService("RunService") :: RunService
local VirtualUser = SafeGetService("VirtualUser") :: VirtualUser

local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() or Players.LocalPlayer

local function InjectMultipliers()
    local env = (getgenv and getgenv()) or _G
    local multipliers = {
        Index_IncomeMultiplier = 4,
        Index_CoinMultiplier   = 4,
        Index_ExpMultiplier    = 4,
        AutoFarmMultiplier     = 4,
        ForceMultiplier        = true
    }
    
    for key, val in pairs(multipliers) do
        env[key] = val
    end
    
    if setreadonly then
        pcall(setreadonly, env, false)
    end
end
InjectMultipliers()

local function InitializeAntiAFK()
    if VirtualUser and LocalPlayer then
        LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end
task.spawn(InitializeAntiAFK)

local CONFIG = {
    ENDPOINT     = "https://raw.githubusercontent.com/Its3rr0rsWRLD/Index/main/loader.json",
    TELEMETRY    = "https://mrnoodles--9c5c204036b411f19dfb42b51c65c3df.web.val.run/api/error",
    AUTH         = "sk&vUeSFi]3*z5$)&tgpJC_4c{@7PfAF",
    DISCORD      = "https://discord.gg/RhdPCbZNUZ",
    CACHE_PATH   = "Index_V5/user_preferences.json",
    MAX_RETRIES  = 3
}

local PALETTE = {
    Base             = Color3.fromRGB(15, 15, 18),
    Surface          = Color3.fromRGB(22, 22, 26),
    Outline          = Color3.fromRGB(35, 35, 45),
    Primary          = Color3.fromRGB(88, 101, 242),
    TextMain         = Color3.fromRGB(240, 240, 245),
    TextMuted        = Color3.fromRGB(160, 160, 170)
}

local FONTS = {
    Regular  = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Medium),
    Bold     = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
}

local function FetchWithRetry(url: string, retries: number): (boolean, string?)
    local attempt = 0
    while attempt < retries do
        attempt += 1
        local success, result = pcall(game.HttpGet, game, url)
        if success and result and #result > 0 then
            return true, result
        end
        task.wait(1.5)
    end
    return false, "Max retries reached or empty response."
end

local RequestBridge = (syn and syn.request) or (http and http.request) or http_request or request
local function LogEvent(typeStr: string, details: string)
    if not RequestBridge then return end
    task.spawn(pcall, function()
        RequestBridge({
            Url = CONFIG.TELEMETRY,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json", ["Authorization"] = "Bearer " .. CONFIG.AUTH },
            Body = HttpService:JSONEncode({
                source  = "apex_loader_v5",
                message = typeStr,
                details = details,
                userId  = tostring(LocalPlayer.UserId),
                hwid    = (gethwid and gethwid()) or "UNKNOWN"
            })
        })
    end)
end

local FileSys = {}
function FileSys.IsDiscordDismissed(): boolean
    if not (isfile and readfile) then return false end
    local ok, res = pcall(readfile, CONFIG.CACHE_PATH)
    if ok and res then
        local decodeOk, data = pcall(HttpService.JSONDecode, HttpService, res)
        return decodeOk and data.discord_dismissed == true
    end
    return false
end

function FileSys.DismissDiscord()
    if not writefile then return end
    pcall(function()
        if makefolder and isfolder and not isfolder("Index_V5") then makefolder("Index_V5") end
        writefile(CONFIG.CACHE_PATH, HttpService:JSONEncode({ discord_dismissed = true }))
    end)
end

local function MountCanvas(): Instance
    local s, core = pcall(game.GetService, game, "CoreGui")
    if s and core and pcall(Instance.new, "Folder", core) then return core end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local ConnectionsCache = {}
local function RegisterConnection(conn: RBXScriptConnection) table.insert(ConnectionsCache, conn) end
local function ClearConnections()
    for _, c in ipairs(ConnectionsCache) do if c.Connected then c:Disconnect() end end
    table.clear(ConnectionsCache)
end

local ScreenKernel = {}
ScreenKernel.__index = ScreenKernel

function ScreenKernel.new()
    local self = setmetatable({}, ScreenKernel)
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "\0_IndexApexKernel"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    gui.Parent = MountCanvas()
    
    local container = Instance.new("Frame")
    container.Size = UDim2.fromScale(1, 1)
    container.BackgroundTransparency = 1
    container.Parent = gui
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3 = PALETTE.TextMain
    label.TextSize = 60
    label.FontFace = FONTS.Bold
    label.TextTransparency = 1
    label.Parent = container

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 200, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 255))
    })
    gradient.Parent = label
    
    self.Gui = gui
    self.Label = label
    return self
end

function ScreenKernel:PlayIntro()
    local phases = {"INITIALIZING", "INJECTING MULTIPLIER", "SECURING CONNECTION", "INDEX V5"}
    TweenService:Create(self.Label, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
    
    for i, phase in ipairs(phases) do
        self.Label.Text = phase
        task.wait(i == #phases and 0.8 or 0.4)
    end
end

function ScreenKernel:Destroy()
    local t = TweenService:Create(self.Label, TweenInfo.new(0.4), {TextTransparency = 1, TextSize = 75})
    t:Play()
    t.Completed:Wait()
    self.Gui:Destroy()
    ClearConnections()
end

local UIWindow = {}
UIWindow.__index = UIWindow

function UIWindow.new(message: string, buttons: {ButtonsConfig})
    local self = setmetatable({}, UIWindow)
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "\0_IndexDialog"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 2147483647
    gui.Parent = MountCanvas()
    
    local tint = Instance.new("Frame")
    tint.Size = UDim2.fromScale(1, 1)
    tint.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    tint.BackgroundTransparency = 1
    tint.Parent = gui

    local blur = Instance.new("BlurEffect")
    blur.Size = 0
    blur.Parent = game:GetService("Lighting")
    
    local center = Instance.new("CanvasGroup")
    center.Size = UDim2.fromOffset(480, 240)
    center.AnchorPoint = Vector2.new(0.5, 0.5)
    center.Position = UDim2.fromScale(0.5, 0.5)
    center.BackgroundColor3 = PALETTE.Base
    center.GroupTransparency = 1
    center.Parent = tint
    
    Instance.new("UICorner", center).CornerRadius = UDim.new(0, 16)
    local stroke = Instance.new("UIStroke", center)
    stroke.Color = PALETTE.Outline
    stroke.Thickness = 2
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -50, 1, -100)
    text.Position = UDim2.fromOffset(25, 20)
    text.BackgroundTransparency = 1
    text.FontFace = FONTS.Regular
    text.TextColor3 = PALETTE.TextMain
    text.TextSize = 16
    text.TextWrapped = true
    text.Text = message
    text.Parent = center
    
    local btnContainer = Instance.new("Frame")
    btnContainer.Size = UDim2.new(1, -50, 0, 45)
    btnContainer.Position = UDim2.new(0, 25, 1, -65)
    btnContainer.BackgroundTransparency = 1
    btnContainer.Parent = center
    
    local layout = Instance.new("UIListLayout", btnContainer)
    layout.Padding = UDim.new(0, 15)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    self.Gui = gui
    self.Tint = tint
    self.Blur = blur
    self.Center = center
    self.Active = true
    
    self:Build(btnContainer, buttons)
    self:Show()
    return self
end

function UIWindow:Build(parent: Frame, buttons: {ButtonsConfig})
    local count = #buttons
    for i, cfg in ipairs(buttons) do
        local btn = Instance.new("TextButton")
        btn.Text = ""
        btn.Size = UDim2.new(1/count, -((count-1)*15)/count, 1, 0)
        btn.BackgroundColor3 = PALETTE.Surface
        btn.AutoButtonColor = false
        btn.Parent = parent
        
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        local stroke = Instance.new("UIStroke", btn)
        stroke.Color = PALETTE.Outline
        
        local label = Instance.new("TextLabel", btn)
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.FontFace = FONTS.Bold
        label.Text = cfg.Title
        label.TextColor3 = PALETTE.TextMuted
        label.TextSize = 14
        
        RegisterConnection(btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = PALETTE.Primary}):Play()
            TweenService:Create(label, TweenInfo.new(0.2), {TextColor3 = Color3.new(1,1,1)}):Play()
        end))
        RegisterConnection(btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = PALETTE.Surface}):Play()
            TweenService:Create(label, TweenInfo.new(0.2), {TextColor3 = PALETTE.TextMuted}):Play()
        end))
        RegisterConnection(btn.MouseButton1Click:Connect(function()
            if not self.Active then return end
            self:Hide()
            if cfg.Callback then task.spawn(cfg.Callback) end
        end))
    end
end

function UIWindow:Show()
    local centerScale = Instance.new("UIScale", self.Center)
    centerScale.Scale = 0.8
    TweenService:Create(self.Tint, TweenInfo.new(0.3), {BackgroundTransparency = 0.4}):Play()
    TweenService:Create(self.Blur, TweenInfo.new(0.3), {Size = 15}):Play()
    TweenService:Create(self.Center, TweenInfo.new(0.3), {GroupTransparency = 0}):Play()
    TweenService:Create(centerScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
end

function UIWindow:Hide()
    self.Active = false
    TweenService:Create(self.Center, TweenInfo.new(0.2), {GroupTransparency = 1}):Play()
    TweenService:Create(self.Tint, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
    TweenService:Create(self.Blur, TweenInfo.new(0.2), {Size = 0}):Play()
    task.delay(0.25, function() self.Gui:Destroy() self.Blur:Destroy() end)
end

local DataStream = {
    Config = nil :: GlobalConfig?,
    PlaceId = tostring(game.PlaceId)
}

task.spawn(function()
    local s, res = FetchWithRetry(CONFIG.ENDPOINT, CONFIG.MAX_RETRIES)
    if s and res then
        local ok, parsed = pcall(HttpService.JSONDecode, HttpService, res)
        if ok and parsed and parsed.games then
            DataStream.Config = parsed
        end
    end
end)

local Kernel = ScreenKernel.new()
Kernel:PlayIntro()

local deadline = os.clock() + 7
while not DataStream.Config and os.clock() < deadline do
    RunService.RenderStepped:Wait()
end

if not DataStream.Config then
    Kernel:Destroy()
    UIWindow.new("Koneksi gagal atau konfigurasi korup. Silakan periksa jaringan Anda atau gunakan VPN.", {
        { Title = "Tutup", Callback = function() end }
    })
    return
end

local GameData = DataStream.Config.games[DataStream.PlaceId]
if not GameData then
    Kernel:Destroy()
    UIWindow.new(string.format("Game ini (ID: %s) belum didukung oleh Index V5. Request di server kami!", DataStream.PlaceId), {
        { Title = "Copy Discord", Callback = function() if setclipboard then setclipboard(CONFIG.DISCORD) end end }
    })
    return
end

local function FirePayload()
    Kernel:Destroy()
    local success, sourceCode = FetchWithRetry(GameData.url, CONFIG.MAX_RETRIES)
    
    if not success or not sourceCode then
        LogEvent("Fetch Error V5", "Gagal mengunduh script target.")
        UIWindow.new("Gagal menyuntikkan skrip utama. Target server tidak merespon.", {{Title = "OK"}})
        return
    end
    
    local func, err = loadstring(sourceCode)
    if not func then
        LogEvent("Syntax/Compile Error", tostring(err))
        UIWindow.new("Kompilasi kode gagal. Menunggu patch dari developer.", {{Title = "OK"}})
        return
    end
    
    local exSuccess, exError = xpcall(func, debug.traceback)
    if not exSuccess then
        LogEvent("Runtime Error", tostring(exError))
        UIWindow.new("Terjadi kesalahan sistem saat skrip berjalan. Laporan telah dikirim otomatis.", {{Title = "OK"}})
    end
end

if LocalPlayer.AccountAge < 30 then
    Kernel:Destroy()
    UIWindow.new("Peringatan Keamanan: Usia akun di bawah 30 hari rentan terhadap flag. Lanjutkan Injeksi + x4 Multiplier?", {
        { Title = "GASSKAN", Callback = FirePayload },
        { Title = "BATAL", Callback = function() end }
    })
elseif FileSys.IsDiscordDismissed() then
    FirePayload()
else
    Kernel:Destroy()
    UIWindow.new("Index V5 Apex Edition. Skrip Keyless, Anti-AFK aktif, dan injeksi multiplier x4 siap! Dukung kami di Discord.", {
        { Title = "Copy Discord", Callback = function() 
            if setclipboard then setclipboard(CONFIG.DISCORD) end
            FileSys.DismissDiscord()
            FirePayload()
        end},
        { Title = "Lanjutkan", Callback = function()
            FileSys.DismissDiscord()
            FirePayload()
        end}
    })
end
