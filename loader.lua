-- ==============================================================================
-- Index Loader - Ultimate Premium Edition (Optimized, Secure, V3)
-- ==============================================================================

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlaceId = tostring(game.PlaceId)
local StartTime = os.clock()

-- ==============================================================================
-- CONFIGURATION & CONSTANTS (URL & KEY AMAN)
-- ==============================================================================
local CONFIG = {
    LoaderUrl = "https://raw.githubusercontent.com/Its3rr0rsWRLD/Index/main/loader.json",
    RelayUrl = "https://mrnoodles--9c5c204036b411f19dfb42b51c65c3df.web.val.run",
    RelayKey = "sk&vUeSFi]3*z5$)&tgpJC_4c{@7PfAF",
    DiscordUrl = "https://discord.gg/RhdPCbZNUZ",
    DismissFile = "Index/discord_dismissed",
    MaxRetries = 2, -- Fitur Baru: Coba ulang jaringan jika gagal
    Theme = {
        Dialog             = Color3.fromRGB(45, 45, 45),
        DialogHolder       = Color3.fromRGB(35, 35, 35),
        DialogHolderLine   = Color3.fromRGB(30, 30, 30),
        DialogButton       = Color3.fromRGB(45, 45, 45),
        DialogButtonBorder = Color3.fromRGB(80, 80, 80),
        DialogBorder       = Color3.fromRGB(70, 70, 70),
        Text               = Color3.fromRGB(240, 240, 240),
        Hover              = Color3.fromRGB(120, 120, 120),
    },
    Fonts = {
        GothamFace     = Font.new("rbxasset://fonts/families/GothamSSm.json"),
        GothamSemiBold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold)
    }
}

-- ==============================================================================
-- ADVANCED UTILITIES & SECURITY
-- ==============================================================================
local Utils = {
    HttpRequest = (syn and syn.request) or (http and http.request) or http_request or request,
    
    -- [Fitur Baru] Safe Parent dengan `gethui` Bypass
    SafeParentGui = function(gui: ScreenGui)
        gui.ResetOnSpawn = false
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.IgnoreGuiInset = true
        local targetParent
        local success = pcall(function() targetParent = (gethui and gethui()) or CoreGui end)
        gui.Parent = (success and targetParent) or LocalPlayer:WaitForChild("PlayerGui")
    end,

    -- [Fitur Baru] Smooth Dragging System untuk UI
    MakeDraggable = function(guiElement: GuiObject)
        local dragging, dragInput, dragStart, startPos
        guiElement.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = guiElement.Position
            end
        end)
        guiElement.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                guiElement.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
    end,

    IsDiscordDismissed = function(): boolean
        if not (isfile and readfile) then return false end
        local ok, result = pcall(function() return isfile(CONFIG.DismissFile) end)
        return ok and result == true
    end,

    MarkDiscordDismissed = function()
        if not writefile then return end
        pcall(function()
            if makefolder and isfolder and not isfolder("Index") then makefolder("Index") end
            writefile(CONFIG.DismissFile, "1")
        end)
    end
}

-- ==============================================================================
-- RESILIENT NETWORK MANAGER
-- ==============================================================================
local Network = {
    DataStream = { Config = nil, ConfigErr = nil, Script = nil, ScriptErr = nil },

    BackgroundPrefetch = function()
        task.spawn(function()
            -- [Fitur Baru] Auto-Retry System
            local raw, parsed
            for attempt = 1, CONFIG.MaxRetries do
                local okRaw, r = pcall(game.HttpGet, game, CONFIG.LoaderUrl)
                if okRaw then 
                    local okJson, p = pcall(HttpService.JSONDecode, HttpService, r)
                    if okJson then
                        raw, parsed = r, p
                        break
                    end
                end
                task.wait(1) -- Jeda sebelum retry
            end

            if not parsed then Network.DataStream.ConfigErr = "Fetch Failed after retries" return end
            Network.DataStream.Config = parsed

            local gameData = parsed.games and parsed.games[PlaceId]
            if not gameData or not gameData.url then return end

            local okSrc, src = pcall(game.HttpGet, game, gameData.url)
            if okSrc then Network.DataStream.Script = src else Network.DataStream.ScriptErr = src end
        end)
    end,

    SendCrashReport = function(message: string, details: any)
        pcall(function()
            if not Utils.HttpRequest then return end
            Utils.HttpRequest({
                Url     = CONFIG.RelayUrl .. "/api/error",
                Method  = "POST",
                Headers = { ["Content-Type"] = "application/json", ["Authorization"] = "Bearer " .. CONFIG.RelayKey },
                Body    = HttpService:JSONEncode({
                    source  = "loader",
                    message = tostring(message),
                    details = details and tostring(details) or nil,
                    userId  = tostring(LocalPlayer.UserId),
                })
            })
        end)
    end
}

-- ==============================================================================
-- PREMIUM UI ENGINE
-- ==============================================================================
local UI = {
    ActiveLoader = nil,
    TitleLabel = nil,
    HasFaded = false,

    AnimateLoader = function()
        UI.ActiveLoader = Instance.new("ScreenGui")
        UI.ActiveLoader.Name = "IndexLoader"
        Utils.SafeParentGui(UI.ActiveLoader)

        UI.TitleLabel = Instance.new("TextLabel")
        UI.TitleLabel.Size, UI.TitleLabel.BackgroundTransparency = UDim2.new(1, 0, 1, -40), 1
        UI.TitleLabel.TextColor3, UI.TitleLabel.TextSize, UI.TitleLabel.Font = Color3.fromRGB(255, 255, 255), 68, Enum.Font.Gotham
        UI.TitleLabel.TextTransparency, UI.TitleLabel.Parent = 1, UI.ActiveLoader

        local word = "Index"
        local frames = { "[ ]" }
        for i = 1, #word do table.insert(frames, "[ " .. word:sub(1, i) .. " ]") end

        UI.TitleLabel.Text = frames[1]
        TweenService:Create(UI.TitleLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
        task.wait(0.8)

        for i = 2, #frames do
            UI.TitleLabel.Text = frames[i]
            task.wait(0.2)
        end
    end,

    KillLoader = function()
        if UI.HasFaded then return end
        UI.HasFaded = true
        if UI.TitleLabel and UI.ActiveLoader then
            local fadeOut = TweenService:Create(UI.TitleLabel, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { TextTransparency = 1 })
            fadeOut:Play()
            fadeOut.Completed:Wait()
            UI.ActiveLoader:Destroy()
        end
    end,

    RenderModal = function(message: string, buttons: table)
        local dialogGui = Instance.new("ScreenGui")
        dialogGui.Name = "IndexDialog"
        dialogGui.DisplayOrder = 10
        Utils.SafeParentGui(dialogGui)

        -- [Fitur Baru] Cinematic Blur Background
        local ScreenBlur = Instance.new("BlurEffect", Lighting)
        ScreenBlur.Size = 0

        local TintFrame = Instance.new("TextButton", dialogGui)
        TintFrame.Size, TintFrame.BackgroundColor3, TintFrame.BackgroundTransparency, TintFrame.Text, TintFrame.AutoButtonColor = UDim2.fromScale(1, 1), Color3.new(0, 0, 0), 1, "", false
        
        local Root = Instance.new("CanvasGroup", TintFrame)
        Root.Size, Root.AnchorPoint, Root.Position, Root.BackgroundColor3, Root.GroupTransparency = UDim2.fromOffset(420, 200), Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), CONFIG.Theme.Dialog, 1
        Instance.new("UICorner", Root).CornerRadius = UDim.new(0, 8)
        
        -- Jadikan Dialog bisa digeser
        Utils.MakeDraggable(Root)
        
        local RootStroke = Instance.new("UIStroke", Root)
        RootStroke.Color, RootStroke.Transparency = CONFIG.Theme.DialogBorder, 0.5
        local Scale = Instance.new("UIScale", Root); Scale.Scale = 1.1

        local Body = Instance.new("TextLabel", Root)
        Body.Size, Body.Position, Body.BackgroundTransparency = UDim2.new(1, -40, 1, -90), UDim2.fromOffset(20, 10), 1
        Body.FontFace, Body.TextColor3, Body.TextSize, Body.TextWrapped, Body.TextXAlignment = CONFIG.Theme.Fonts.GothamSemiBold, CONFIG.Theme.Text, 16, true, Enum.TextXAlignment.Center
        Body.Text = message

        local HolderFrame = Instance.new("Frame", Root)
        HolderFrame.Size, HolderFrame.Position, HolderFrame.BackgroundColor3, HolderFrame.BorderSizePixel = UDim2.new(1, 0, 0, 70), UDim2.new(0, 0, 1, -70), CONFIG.Theme.DialogHolder, 0
        
        local Line = Instance.new("Frame", HolderFrame)
        Line.Size, Line.BackgroundColor3, Line.BorderSizePixel = UDim2.new(1, 0, 0, 1), CONFIG.Theme.DialogHolderLine, 0

        local BtnHolder = Instance.new("Frame", HolderFrame)
        BtnHolder.Size, BtnHolder.AnchorPoint, BtnHolder.Position, BtnHolder.BackgroundTransparency = UDim2.new(1, -40, 1, -40), Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), 1
        
        local Layout = Instance.new("UIListLayout", BtnHolder)
        Layout.Padding, Layout.FillDirection, Layout.HorizontalAlignment = UDim.new(0, 10), Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center

        local activeSignals = {}
        local isOpen = true

        local function purgeAndClose()
            if not isOpen then return end
            isOpen = false
            for _, signal in ipairs(activeSignals) do signal:Disconnect() end

            TweenService:Create(Root, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { GroupTransparency = 1 }):Play()
            TweenService:Create(Scale, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Scale = 1.1 }):Play()
            TweenService:Create(TintFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
            
            local blurOut = TweenService:Create(ScreenBlur, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Size = 0 })
            blurOut:Play()
            
            task.delay(0.22, function() 
                dialogGui:Destroy() 
                ScreenBlur:Destroy() 
            end)
        end

        local totalButtons = #buttons
        for index, buttonData in ipairs(buttons) do
            local Btn = Instance.new("TextButton", BtnHolder)
            Btn.Size = UDim2.new(1 / totalButtons, -(((totalButtons - 1) * 10) / totalButtons), 0, 32)
            Btn.BackgroundColor3, Btn.AutoButtonColor, Btn.Text, Btn.LayoutOrder = CONFIG.Theme.DialogButton, false, "", index
            Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
            
            local Stroke = Instance.new("UIStroke", Btn)
            Stroke.ApplyStrokeMode, Stroke.Color, Stroke.Transparency = Enum.ApplyStrokeMode.Border, CONFIG.Theme.DialogButtonBorder, 0.65

            local Hover = Instance.new("Frame", Btn)
            Hover.Size, Hover.BackgroundColor3, Hover.BackgroundTransparency = UDim2.fromScale(1, 1), CONFIG.Theme.Hover, 1
            Instance.new("UICorner", Hover).CornerRadius = UDim.new(0, 4)

            local Label = Instance.new("TextLabel", Btn)
            Label.Size, Label.BackgroundTransparency, Label.FontFace, Label.TextColor3, Label.TextSize = UDim2.fromScale(1, 1), 1, CONFIG.Theme.Fonts.GothamFace, CONFIG.Theme.Text, 14
            Label.Text = buttonData.Title

            local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad)
            table.insert(activeSignals, Btn.MouseEnter:Connect(function() TweenService:Create(Hover, tweenInfo, { BackgroundTransparency = 0.97 }):Play() end))
            table.insert(activeSignals, Btn.MouseLeave:Connect(function() TweenService:Create(Hover, tweenInfo, { BackgroundTransparency = 1 }):Play() end))
            table.insert(activeSignals, Btn.MouseButton1Click:Connect(function()
                if buttonData.Callback then pcall(buttonData.Callback) end
                purgeAndClose()
            end))
        end

        TweenService:Create(ScreenBlur, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { Size = 15 }):Play()
        TweenService:Create(TintFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { BackgroundTransparency = 0.75 }):Play()
        TweenService:Create(Root, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { GroupTransparency = 0 }):Play()
        TweenService:Create(Scale, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { Scale = 1 }):Play()
    end,

    PromptAction = function(message: string, onAccept: any)
        UI.RenderModal(message, {
            { Title = "Okay", Callback = function() if onAccept then task.spawn(onAccept) end end },
            { Title = "Copy Discord", Callback = function()
                if setclipboard then setclipboard(CONFIG.DiscordUrl) end
                if onAccept then task.spawn(onAccept) end
            end }
        })
    end
}

-- ==============================================================================
-- CORE EXECUTION ARCHITECTURE
-- ==============================================================================
local Core = {
    EvaluateMainAccountRisk = function(): boolean
        local score = 0
        local age = LocalPlayer.AccountAge or 0
        
        if age > 1095 then score += 3 elseif age > 365 then score += 2 elseif age > 30 then score += 1 end
        if LocalPlayer.MembershipType == Enum.MembershipType.Premium then score += 3 end

        pcall(function()
            local raw = game:HttpGet("https://friends.roblox.com/v1/users/" .. tostring(LocalPlayer.UserId) .. "/friends/count")
            local data = HttpService:JSONDecode(raw)
            if data and data.count then
                if data.count > 50 then score += 2 elseif data.count > 10 then score += 1 end
            end
        end)
        return score >= 4
    end,

    InitializeScriptRuntime = function()
        UI.KillLoader()
        task.wait(0.1)
        _G.IndexShowDiscord = true

        local source = Network.DataStream.Script
        local fetchErr = Network.DataStream.ScriptErr

        if not source then
            local gameData = Network.DataStream.Config.games[PlaceId]
            local fetchOk = pcall(function() source = game:HttpGet(gameData.url) end)
            if not fetchOk or not source then
                local msg = "Failed to fetch the game script.\n\n" .. tostring(fetchErr or "Network error")
                warn("[Index] " .. msg)
                Network.SendCrashReport("Fetch failed", fetchErr)
                UI.PromptAction(msg, nil)
                return
            end
        end

        local compiledFunc, compileErr = loadstring(source)
        if not compiledFunc then
            local msg = "Failed to compile the game script.\n\n" .. tostring(compileErr)
            warn("[Index] " .. msg)
            Network.SendCrashReport("Compile error: " .. tostring(compileErr))
            UI.PromptAction(msg, nil)
            return
        end

        -- [Fitur Baru] Execution Profiler & Profiling Print
        local execTime = os.clock()
        local runOk, runErr = pcall(compiledFunc)
        if not runOk then
            local msg = "Failed to run the game script.\n\n" .. tostring(runErr)
            warn("[Index] " .. msg)
            Network.SendCrashReport("Runtime error: " .. tostring(runErr))
            UI.PromptAction(msg, nil)
        else
            print(string.format("[Index] Script successfully executed in %.2f ms", (os.clock() - StartTime) * 1000))
        end
    end,

    Boot = function()
        Network.BackgroundPrefetch()
        UI.AnimateLoader()
        task.wait(1)

        local timeout = os.clock() + 12 -- Dinaikkan menjadi 12s karena ada sistem Auto-Retry
        while Network.DataStream.Config == nil and Network.DataStream.ConfigErr == nil and os.clock() < timeout do
            task.wait(0.05)
        end

        if not Network.DataStream.Config then
            UI.PromptAction("Failed to fetch the Index game list.\n\nJoin our Discord for support:\n" .. CONFIG.DiscordUrl, UI.KillLoader)
            return
        end

        if not Network.DataStream.Config.games or not Network.DataStream.Config.games[PlaceId] then
            UI.PromptAction("This game is not yet supported.\nPlace ID: " .. PlaceId .. "\n\nRequest it on our Discord:\n" .. CONFIG.DiscordUrl, UI.KillLoader)
            return
        end

        task.wait(0.6)

        if Core.EvaluateMainAccountRisk() then
            UI.RenderModal("Hey, we detected you may be on a main account. We recommend NOT using this on your main to avoid risking your account.", {
                { Title = "Continue Anyway", Callback = function() task.spawn(Core.InitializeScriptRuntime) end },
                { Title = "Stop Script", Callback = function() UI.KillLoader() end }
            })
        elseif Utils.IsDiscordDismissed() then
            task.spawn(Core.InitializeScriptRuntime)
        else
            UI.PromptAction(
                "Our scripts are keyless, but we ask that you join the Discord to support us and get updates on new scripts!\n\n" .. CONFIG.DiscordUrl,
                function() Utils.MarkDiscordDismissed(); Core.InitializeScriptRuntime() end
            )
        end
    end
}

-- ==============================================================================
-- RUNTIME ENTRY POINT
-- ==============================================================================
Core.Boot()
