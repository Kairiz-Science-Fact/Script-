--!strict
type ButtonsConfig = { Title: string, Callback: (() -> ())? }
type GameConfigData = { url: string }
type GlobalConfig = { games: { [string]: GameConfigData } }

local Players: Players = cloneref and cloneref(game:GetService("Players")) or game:GetService("Players")
local HttpService: HttpService = cloneref and cloneref(game:GetService("HttpService")) or game:GetService("HttpService")
local TweenService: TweenService = cloneref and cloneref(game:GetService("TweenService")) or game:GetService("TweenService")

local LocalPlayer: Player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() or Players.LocalPlayer

local ENDPOINT_GATEWAY: string = "https://raw.githubusercontent.com/Its3rr0rsWRLD/Index/main/loader.json"
local TELEMETRY_URL: string    = "https://mrnoodles--9c5c204036b411f19dfb42b51c65c3df.web.val.run/api/error"
local TELEMETRY_AUTH: string   = "sk&vUeSFi]3*z5$)&tgpJC_4c{@7PfAF"
local DISCORD_INVITE: string   = "https://discord.gg/RhdPCbZNUZ"
local STORAGE_PATH: string     = "Index/discord_dismissed"

local PALETTE = {
    Background       = Color3.fromRGB(32, 32, 32),
    AccentHolder     = Color3.fromRGB(24, 24, 24),
    BorderLine       = Color3.fromRGB(18, 18, 18),
    InteractiveElement = Color3.fromRGB(44, 44, 44),
    StrokeBorder     = Color3.fromRGB(75, 75, 75),
    ForegroundText   = Color3.fromRGB(245, 245, 245),
    HighlightEffect  = Color3.fromRGB(255, 255, 255)
}

local FONTS = {
    Regular  = Font.new("rbxasset://fonts/families/GothamSSm.json"),
    SemiBold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold)
}

local ThreadState = {
    ActiveConfig = nil :: GlobalConfig?,
    ConfigLoadException = nil :: string?,
    PreloadedSource = nil :: string?,
    PreloadException = nil :: string?,
    CurrentPlaceId = tostring(game.PlaceId)
}

local RequestBridge: any = (syn and syn.request) or (http and http.request) or http_request or request

local function DispatchTelemetry(errType: string, errMessage: string): ()
    if not RequestBridge then return end
    task.spawn(pcall, function()
        RequestBridge({
            Url     = TELEMETRY_URL,
            Method  = "POST",
            Headers = { ["Content-Type"] = "application/json", ["Authorization"] = "Bearer " .. TELEMETRY_AUTH },
            Body    = HttpService:JSONEncode({
                source  = "kernel_loader_v3",
                message = errType,
                details = errMessage,
                userId  = tostring(LocalPlayer.UserId),
            })
        })
    end)
end

local FileSystem = {}
function FileSystem.HasClearedPrompt(): boolean
    if not (isfile and readfile) then return false end
    local ok, exist = pcall(isfile, STORAGE_PATH)
    return ok and exist == true
end

function FileSystem.WriteClearanceToken(): ()
    if not writefile then return end
    pcall(function()
        if makefolder and isfolder and not isfolder("Index") then
            makefolder("Index")
        end
        writefile(STORAGE_PATH, "1")
    end)
end

local function MountCanvas(): Instance
    local success, coreGui = pcall(game.GetService, game, "CoreGui")
    if success and coreGui then
        local valid, _ = pcall(Instance.new, "Folder", coreGui)
        if valid then return coreGui end
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local AsyncBootstrapper = {}
AsyncBootstrapper.__index = AsyncBootstrapper

function AsyncBootstrapper.new()
    local self = setmetatable({}, AsyncBootstrapper)
    
    local rootCanvas = Instance.new("ScreenGui")
    rootCanvas.Name = "\0_IndexKernelBoot"
    rootCanvas.ResetOnSpawn = false
    rootCanvas.IgnoreGuiInset = true
    rootCanvas.Parent = MountCanvas()
    
    local textStream = Instance.new("TextLabel")
    textStream.Size = UDim2.new(1, 0, 1, -40)
    textStream.BackgroundTransparency = 1
    textStream.TextColor3 = Color3.fromRGB(255, 255, 255)
    textStream.TextSize = 64
    textStream.Font = Enum.Font.Gotham
    textStream.TextTransparency = 1
    textStream.Parent = rootCanvas
    
    self.Canvas = rootCanvas
    self.Label = textStream
    return self
end

function AsyncBootstrapper:RunSequence(): ()
    local glyphArray: {string} = {"[ ]", "[ I ]", "[ In ]", "[ Ind ]", "[ Inde ]", "[ Index ]"}
    self.Label.Text = glyphArray[1]
    
    TweenService:Create(self.Label, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()
    task.wait(0.4)
    
    for pointer = 2, #glyphArray do
        self.Label.Text = glyphArray[pointer]
        task.wait(0.12)
    end
end

function AsyncBootstrapper:Terminate(): ()
    local closingTween = TweenService:Create(self.Label, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {TextTransparency = 1})
    closingTween:Play()
    closingTween.Completed:Wait()
    self.Canvas:Destroy()
end

local PipelineWindow = {}
PipelineWindow.__index = PipelineWindow

function PipelineWindow.new(displayMsg: string, controlMatrix: {ButtonsConfig})
    local self = setmetatable({}, PipelineWindow)
    
    local baseScreen = Instance.new("ScreenGui")
    baseScreen.Name = "\0_IndexPipelineFrame"
    baseScreen.ResetOnSpawn = false
    baseScreen.IgnoreGuiInset = true
    baseScreen.DisplayOrder = 999999
    baseScreen.Parent = MountCanvas()
    
    local shield = Instance.new("TextButton")
    shield.Text = ""
    shield.AutoButtonColor = false
    shield.Size = UDim2.fromScale(1, 1)
    shield.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shield.BackgroundTransparency = 1
    shield.BorderSizePixel = 0
    shield.Parent = baseScreen
    
    local bodyGroup = Instance.new("CanvasGroup")
    bodyGroup.Size = UDim2.fromOffset(450, 220)
    bodyGroup.AnchorPoint = Vector2.new(0.5, 0.5)
    bodyGroup.Position = UDim2.fromScale(0.5, 0.5)
    bodyGroup.BackgroundColor3 = PALETTE.Background
    bodyGroup.GroupTransparency = 1
    bodyGroup.Parent = shield
    
    Instance.new("UICorner", bodyGroup).CornerRadius = UDim.new(0, 12)
    local frameStroke = Instance.new("UIStroke", bodyGroup)
    frameStroke.Color = PALETTE.StrokeBorder
    frameStroke.Transparency = 0.35
    
    local transformNode = Instance.new("UIScale", bodyGroup)
    transformNode.Scale = 1.2
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -40, 1, -95)
    messageLabel.Position = UDim2.fromOffset(20, 15)
    messageLabel.BackgroundTransparency = 1
    messageLabel.FontFace = FONTS.SemiBold
    messageLabel.TextColor3 = PALETTE.ForegroundText
    messageLabel.TextSize = 15
    messageLabel.TextWrapped = true
    messageLabel.Text = displayMsg
    messageLabel.Parent = bodyGroup
    
    local controlDeck = Instance.new("Frame")
    controlDeck.Size = UDim2.new(1, 0, 0, 75)
    controlDeck.Position = UDim2.new(0, 0, 1, -75)
    controlDeck.BackgroundColor3 = PALETTE.AccentHolder
    controlDeck.BorderSizePixel = 0
    controlDeck.Parent = bodyGroup
    
    local borderline = Instance.new("Frame", controlDeck)
    borderline.Size = UDim2.new(1, 0, 0, 1)
    borderline.BackgroundColor3 = PALETTE.BorderLine
    borderline.BorderSizePixel = 0
    
    local subLayoutFrame = Instance.new("Frame")
    subLayoutFrame.Size = UDim2.new(1, -40, 1, -32)
    subLayoutFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    subLayoutFrame.Position = UDim2.fromScale(0.5, 0.5)
    subLayoutFrame.BackgroundTransparency = 1
    subLayoutFrame.Parent = controlDeck
    
    local flexLayout = Instance.new("UIListLayout", subLayoutFrame)
    flexLayout.Padding = UDim.new(0, 14)
    flexLayout.FillDirection = Enum.FillDirection.Horizontal
    flexLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    flexLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    self.WindowInstance = baseScreen
    self.Shield = shield
    self.ViewGroup = bodyGroup
    self.MatrixScale = transformNode
    self.ExecutionState = true
    
    self:PopulateControls(subLayoutFrame, controlMatrix)
    self:TriggerEntranceAnimation()
    
    return self
end

function PipelineWindow:PopulateControls(targetFrame: Frame, matrix: {ButtonsConfig}): ()
    local matrixSize = #matrix
    for layoutIndex, element in ipairs(matrix) do
        local pushButton = Instance.new("TextButton")
        pushButton.Text = ""
        pushButton.AutoButtonColor = false
        pushButton.Size = UDim2.new(1 / matrixSize, -(((matrixSize - 1) * 14) / matrixSize), 1, 0)
        pushButton.BackgroundColor3 = PALETTE.InteractiveElement
        pushButton.LayoutOrder = layoutIndex
        pushButton.Parent = targetFrame
        
        Instance.new("UICorner", pushButton).CornerRadius = UDim.new(0, 6)
        local btnStroke = Instance.new("UIStroke", pushButton)
        btnStroke.Color = PALETTE.StrokeBorder
        btnStroke.Transparency = 0.55
        
        local activeHoverNode = Instance.new("Frame", pushButton)
        activeHoverNode.Size = UDim2.fromScale(1, 1)
        activeHoverNode.BackgroundColor3 = PALETTE.HighlightEffect
        activeHoverNode.BackgroundTransparency = 1
        Instance.new("UICorner", activeHoverNode).CornerRadius = UDim.new(0, 6)
        
        local buttonLabel = Instance.new("TextLabel", pushButton)
        buttonLabel.Size = UDim2.fromScale(1, 1)
        buttonLabel.BackgroundTransparency = 1
        buttonLabel.FontFace = FONTS.Regular
        buttonLabel.Text = element.Title
        buttonLabel.TextColor3 = PALETTE.ForegroundText
        buttonLabel.TextSize = 14
        
        pushButton.MouseEnter:Connect(function()
            TweenService:Create(activeHoverNode, TweenInfo.new(0.12), {BackgroundTransparency = 0.94}):Play()
        end)
        pushButton.MouseLeave:Connect(function()
            TweenService:Create(activeHoverNode, TweenInfo.new(0.12), {BackgroundTransparency = 1}):Play()
        end)
        pushButton.MouseButton1Click:Connect(function()
            if self.ExecutionState then
                self:TriggerExitAnimation()
                if element.Callback then
                    task.spawn(element.Callback)
                end
            end
        end)
    end
end

function PipelineWindow:TriggerEntranceAnimation(): ()
    TweenService:Create(self.Shield, TweenInfo.new(0.2), {BackgroundTransparency = 0.65}):Play()
    TweenService:Create(self.ViewGroup, TweenInfo.new(0.2), {GroupTransparency = 0}):Play()
    TweenService:Create(self.MatrixScale, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Scale = 1}):Play()
end

function PipelineWindow:TriggerExitAnimation(): ()
    self.ExecutionState = false
    TweenService:Create(self.ViewGroup, TweenInfo.new(0.18), {GroupTransparency = 1}):Play()
    TweenService:Create(self.MatrixScale, TweenInfo.new(0.18), {Scale = 1.15}):Play()
    TweenService:Create(self.Shield, TweenInfo.new(0.18), {BackgroundTransparency = 1}):Play()
    task.delay(0.2, self.WindowInstance.Destroy, self.WindowInstance)
end

local function SpawnGatewayAlert(promptText: string, confirmationHandler: (() -> ())?): ()
    PipelineWindow.new(promptText, {
        { Title = "Okay", Callback = confirmationHandler },
        {
            Title = "Copy Discord",
            Callback = function()
                if setclipboard then setclipboard(DISCORD_INVITE) end
                if confirmationHandler then confirmationHandler() end
            end
        }
    })
end

task.spawn(function()
    local cNetSuccess, cNetOutput = pcall(game.HttpGet, game, ENDPOINT_GATEWAY)
    if not cNetSuccess then ThreadState.ConfigLoadException = cNetOutput return end
    
    local jParseSuccess, jParseOutput = pcall(HttpService.JSONDecode, HttpService, cNetOutput)
    if not jParseSuccess then ThreadState.ConfigLoadException = jParseOutput return end
    
    local structuredConfig = jParseOutput :: GlobalConfig
    ThreadState.ActiveConfig = structuredConfig
    
    local matchGame = structuredConfig.games and structuredConfig.games[ThreadState.CurrentPlaceId]
    if matchGame and matchGame.url then
        local sNetSuccess, sNetOutput = pcall(game.HttpGet, game, matchGame.url)
        if sNetSuccess then
            ThreadState.PreloadedSource = sNetOutput
        else
            ThreadState.PreloadException = sNetOutput
        end
    end
end)

local bootstrapperKernel = AsyncBootstrapper.new()
bootstrapperKernel:RunSequence()

local expirationTimestamp = os.clock() + 8
while not ThreadState.ActiveConfig and not ThreadState.ConfigLoadException and os.clock() < expirationTimestamp do
    task.wait(0.02)
end

if ThreadState.ConfigLoadException or not ThreadState.ActiveConfig then
    bootstrapperKernel:Terminate()
    SpawnGatewayAlert("Gagal memproses konfigurasi awan runtime Index.\nSilakan verifikasi koneksi Anda atau hubungi Discord.", nil)
    return
end

local targetResolvableGame = ThreadState.ActiveConfig.games and ThreadState.ActiveConfig.games[ThreadState.CurrentPlaceId]
if not targetResolvableGame then
    bootstrapperKernel:Terminate()
    SpawnGatewayAlert("ID Tempat ini (" .. ThreadState.CurrentPlaceId .. ") belum terdaftar di arsitektur Index.", nil)
    return
end

local function ExecuteKernelSource(): ()
    bootstrapperKernel:Terminate()
    _G.IndexShowDiscord = true
    
    if not ThreadState.PreloadedSource and not ThreadState.PreloadException then
        local streamLockTimeout = os.clock() + 5
        while not ThreadState.PreloadedSource and not ThreadState.PreloadException and os.clock() < streamLockTimeout do
            task.wait(0.02)
        end
    end
    
    local activeSourceBuffer = ThreadState.PreloadedSource
    if not activeSourceBuffer then
        local emergencyFetchSuccess, emergencyFetchOutput = pcall(game.HttpGet, game, targetResolvableGame.url)
        if emergencyFetchSuccess then 
            activeSourceBuffer = emergencyFetchOutput 
        else 
            ThreadState.PreloadException = emergencyFetchOutput 
        end
    end
    
    if not activeSourceBuffer then
        local logError = tostring(ThreadState.PreloadException or "Network Buffer Timeout")
        DispatchTelemetry("Stream Fetch Exception", logError)
        SpawnGatewayAlert("Kegagalan kritis pengunduhan komponen visual skrip:\n" .. logError, nil)
        return
    end
    
    local loadedClosure, compilationError = loadstring(activeSourceBuffer)
    if not loadedClosure then
        DispatchTelemetry("Bytecode Compilation Failure", tostring(compilationError))
        SpawnGatewayAlert("Kompilator mengalami disfungsi kegagalan pembuatan instruksi skrip:\n" .. tostring(compilationError), nil)
        return
    end
    
    local runtimeExecutionSuccess, runtimeExecutionError = xpcall(loadedClosure, debug.traceback)
    if not runtimeExecutionSuccess then
        DispatchTelemetry("Runtime Dynamic Link Error", tostring(runtimeExecutionError))
        warn("[Index Kernel Crash Log]: " .. tostring(runtimeExecutionError))
        SpawnGatewayAlert("Sistem mendeteksi kegagalan fungsional tidak dikenal pada sub-rutin skrip.", nil)
    end
end

local function EvaluateIdentityRisk(): boolean
    return (LocalPlayer.AccountAge < 30) or (LocalPlayer.MembershipType == Enum.MembershipType.Premium)
end

if EvaluateIdentityRisk() then
    bootstrapperKernel:Terminate()
    PipelineWindow.new("Sistem mendeteksi bahwa akun yang Anda gunakan dikategorikan berisiko tinggi. Kami menyarankan pemakaian akun alternatif (Alt). Apakah ingin melanjutkan?", {
        { Title = "Lanjutkan", Callback = ExecuteKernelSource },
        { Title = "Batalkan", Callback = function() print("[Index] Operasi dihentikan demi privasi aman.") end }
    })
elseif FileSystem.HasClearedPrompt() then
    ExecuteKernelSource()
else
    bootstrapperKernel:Terminate()
    SpawnGatewayAlert("Skrip ini didistribusikan gratis tanpa sistem kunci (Keyless). Dukung pengembangan berkelanjutan dengan bergabung ke komunitas Discord!", function()
        FileSystem.WriteClearanceToken()
        ExecuteKernelSource()
    end)
end
