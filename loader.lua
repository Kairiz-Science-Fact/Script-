local game = game
local pcall, type, tostring, ipairs, pairs = pcall, type, tostring, ipairs, pairs
local task_spawn, task_wait, task_delay = task.spawn, task.wait, task.delay
local os_time = os.time

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

local get_hidden_ui = gethui or function()
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    return ok and core or LocalPlayer:WaitForChild("PlayerGui")
end

local function universal_request(url)
    local req_func = (type(syn) == "table" and syn.request) or request or http_request or (type(fluxus) == "table" and fluxus.request)
    if req_func then
        local ok, res = pcall(req_func, { Url = url, Method = "GET", Timeout = 7 })
        if ok and res and res.Body then return res.Body end
    end
    local ok, res = pcall(function() return game:HttpGet(url) end)
    return ok and res or nil
end

local function create_instance(class_name, properties)
    local inst = Instance.new(class_name)
    for prop, val in pairs(properties) do inst[prop] = val end
    return inst
end

local function play_safe_tween(object, tween_info, properties)
    if not object or not object.Parent then return end
    local tween = TweenService:Create(object, tween_info, properties)
    tween:Play()
    task_spawn(function()
        tween.Completed:Wait()
        pcall(function() tween:Destroy() end)
    end)
    return tween
end

local screen_gui = create_instance("ScreenGui", {
    Name = HttpService:GenerateGUID(false),
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true,
    Parent = get_hidden_ui()
})

local title_label = create_instance("TextLabel", {
    Name = "TitleText",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "[ Kairiz ]",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 54,
    Font = Enum.Font.GothamMedium,
    TextTransparency = 1,
    MaxVisibleGraphemes = 0,
    Parent = screen_gui
})

local LOADER_URL = "https://raw.githubusercontent.com/Its3rr0rsWRLD/Index/main/loader.json"
local fetch_data = { config = nil, script = nil, err = nil, status = "operational", done = false }

task_spawn(function()
    local raw_json
    for _ = 1, 3 do
        raw_json = universal_request(LOADER_URL)
        if raw_json then break end
        task_wait(1)
    end
    
    if not raw_json then fetch_data.err = "Koneksi ke server gagal/Timeout."; fetch_data.done = true; return end
    
    local ok_json, parsed = pcall(function() return HttpService:JSONDecode(raw_json) end)
    if not ok_json or not parsed then fetch_data.err = "Format konfigurasi rusak."; fetch_data.done = true; return end
    
    fetch_data.config = parsed

    if parsed.blacklist and type(parsed.blacklist) == "table" then
        for _, id in ipairs(parsed.blacklist) do
            if id == LocalPlayer.UserId then
                fetch_data.err = "Akses ditolak. Akun Anda masuk daftar hitam."
                fetch_data.done = true
                return
            end
        end
    end

    local p_id, g_id = tostring(game.PlaceId), tostring(game.GameId)
    local game_data = parsed.games and (parsed.games[p_id] or parsed.games[g_id])
    
    if game_data then
        if game_data.status then fetch_data.status = string.lower(game_data.status) end
        if game_data.url and fetch_data.status == "operational" then
            fetch_data.script = universal_request(game_data.url)
        end
    end
    fetch_data.done = true
end)

play_safe_tween(title_label, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 })
task_wait(0.6)
for i = 1, #title_label.Text do
    title_label.MaxVisibleGraphemes = i
    task_wait(0.06)
end
task_wait(1)

local Theme = {
    Dialog = Color3.fromRGB(30, 30, 30),
    Holder = Color3.fromRGB(22, 22, 22),
    Line = Color3.fromRGB(40, 40, 40),
    Button = Color3.fromRGB(35, 35, 35),
    Border = Color3.fromRGB(55, 55, 55),
    Text = Color3.fromRGB(245, 245, 245),
    Hover = Color3.fromRGB(255, 255, 255)
}

local FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)

local function show_dialog(message, buttons)
    local dialog_gui = create_instance("ScreenGui", {
        Name = HttpService:GenerateGUID(false),
        ResetOnSpawn = false,
        DisplayOrder = 10,
        IgnoreGuiInset = true,
        Parent = get_hidden_ui()
    })

    local tint = create_instance("TextButton", {
        Text = "", AutoButtonColor = false,
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        Parent = dialog_gui
    })

    local root = create_instance("CanvasGroup", {
        Size = UDim2.fromScale(0.9, 0.3),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundColor3 = Theme.Dialog,
        GroupTransparency = 1,
        Parent = tint
    })

    create_instance("UISizeConstraint", { MaxSize = Vector2.new(420, 220), MinSize = Vector2.new(280, 180), Parent = root })
    create_instance("UICorner", { CornerRadius = UDim.new(0, 10), Parent = root })
    create_instance("UIStroke", { Color = Theme.Border, Transparency = 0.4, Parent = root })
    local scale_fx = create_instance("UIScale", { Scale = 1.05, Parent = root })

    create_instance("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -40, 1, -95),
        Position = UDim2.fromOffset(20, 15),
        FontFace = FontFace, TextColor3 = Theme.Text, TextSize = 14,
        TextWrapped = true, Text = message, Parent = root
    })

    local btn_frame = create_instance("Frame", {
        Size = UDim2.new(1, 0, 0, 65), Position = UDim2.new(0, 0, 1, -65),
        BackgroundColor3 = Theme.Holder, BorderSizePixel = 0, Parent = root
    })
    create_instance("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Line, BorderSizePixel = 0, Parent = btn_frame })

    local btn_holder = create_instance("Frame", {
        Size = UDim2.new(1, -30, 1, -25), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Parent = btn_frame
    })
    create_instance("UIListLayout", {
        Padding = UDim.new(0, 12), FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Parent = btn_holder
    })

    local is_open = true
    local connections = {}

    local function close_dialog()
        if not is_open then return end
        is_open = false
        for _, conn in ipairs(connections) do pcall(function() conn:Disconnect() end) end
        play_safe_tween(root, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { GroupTransparency = 1 })
        play_safe_tween(scale_fx, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { Scale = 1.05 })
        play_safe_tween(tint, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 })
        task_delay(0.25, function() pcall(function() dialog_gui:Destroy() end) end)
    end

    for i, btn in ipairs(buttons) do
        local frame = create_instance("TextButton", {
            Text = "", AutoButtonColor = false,
            Size = UDim2.new(1 / #buttons, -(((#buttons - 1) * 12) / #buttons), 1, 0),
            BackgroundColor3 = Theme.Button, LayoutOrder = i, Parent = btn_holder
        })
        create_instance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = frame })
        create_instance("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = Theme.Border, Transparency = 0.5, Parent = frame })
        
        local hover = create_instance("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Hover, BackgroundTransparency = 1, Parent = frame })
        create_instance("UICorner", { CornerRadius = UDim.new(0, 6), Parent = hover })
        
        create_instance("TextLabel", {
            BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
            FontFace = FontFace, Text = btn.Title, TextColor3 = Theme.Text, TextSize = 13, Parent = frame
        })

        table.insert(connections, frame.MouseEnter:Connect(function() play_safe_tween(hover, TweenInfo.new(0.15), { BackgroundTransparency = 0.94 }) end))
        table.insert(connections, frame.MouseLeave:Connect(function() play_safe_tween(hover, TweenInfo.new(0.15), { BackgroundTransparency = 1 }) end))
        table.insert(connections, frame.MouseButton1Click:Connect(function()
            if btn.Callback then task_spawn(btn.Callback) end
            close_dialog()
        end))
    end

    play_safe_tween(tint, TweenInfo.new(0.2), { BackgroundTransparency = 0.6 })
    play_safe_tween(root, TweenInfo.new(0.2), { GroupTransparency = 0 })
    play_safe_tween(scale_fx, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
end

local loader_faded = false
local function fade_out_loader()
    if loader_faded then return end
    loader_faded = true
    if title_label and title_label.Parent then
        local fade = TweenService:Create(title_label, TweenInfo.new(0.4), { TextTransparency = 1 })
        fade:Play()
        fade.Completed:Wait()
        pcall(function() fade:Destroy() end)
    end
    if screen_gui then pcall(function() screen_gui:Destroy() end) end
end

local function is_discord_dismissed()
    if not (isfile and readfile) then return false end
    local ok, res = pcall(function() return isfile("Index/dismissed.txt") and readfile("Index/dismissed.txt") == "1" end)
    return ok and res
end

local function mark_discord_dismissed()
    if writefile then
        pcall(function()
            if makefolder and isfolder and not isfolder("Index") then makefolder("Index") end
            writefile("Index/dismissed.txt", "1")
        end)
    end
end

local start_time = os_time()
while not fetch_data.done and (os_time() - start_time) < 10 do task_wait(0.1) end

if fetch_data.err then
    show_dialog("Error: " .. fetch_data.err .. "\n\nDiscord: discord.gg/RhdPCbZNUZ", {{ Title = "Tutup", Callback = fade_out_loader }})
    return
end

if not fetch_data.config or not fetch_data.config.games then
    show_dialog("Gagal menyinkronisasi data server.\n\nDiscord: discord.gg/RhdPCbZNUZ", {{ Title = "Tutup", Callback = fade_out_loader }})
    return
end

if not (fetch_data.config.games[tostring(game.PlaceId)] or fetch_data.config.games[tostring(game.GameId)]) then
    show_dialog("Game belum didukung.\nID: " .. game.PlaceId .. "\n\nDiscord: discord.gg/RhdPCbZNUZ", {{ Title = "Tutup", Callback = fade_out_loader }})
    return
end

if fetch_data.status == "patching" or fetch_data.status == "maintenance" then
    show_dialog("Script sedang dalam perbaikan (Patching/Maintenance).\n\nMohon tunggu pembaruan di Discord.", {{ Title = "Mengerti", Callback = fade_out_loader }})
    return
end

task_wait(0.4)

local function execute_main_script()
    fade_out_loader()
    if type(loadstring) ~= "function" then
        show_dialog("Executor Anda tidak didukung (Tidak memiliki loadstring).", {{ Title = "Tutup" }})
        return
    end

    if not fetch_data.script or fetch_data.script == "" then
        show_dialog("Gagal mengambil source script.", {{ Title = "Tutup" }})
        return
    end

    local func, err = loadstring(fetch_data.script)
    if not func then
        show_dialog("Kompilasi gagal:\n" .. tostring(err), {{ Title = "Tutup" }})
        return
    end

    local success, run_err = pcall(func)
    if not success then
        show_dialog("Runtime Error:\n" .. tostring(run_err), {{ Title = "Tutup" }})
    end
end

local function safe_account_check()
    local score = 0
    if (LocalPlayer.AccountAge or 0) > 365 then score = score + 2 end
    if LocalPlayer.MembershipType == Enum.MembershipType.Premium then score = score + 3 end
    
    pcall(function()
        local raw = universal_request("https://friends.roproxy.com/v1/users/" .. LocalPlayer.UserId .. "/friends/count")
        if raw and not raw:find("<html>") then
            local data = HttpService:JSONDecode(raw)
            if data and type(data.count) == "number" and data.count > 30 then score = score + 2 end
        end
    end)
    return score >= 4
end

pcall(function() TeleportService.LocalPlayerLeftGame:Connect(function() pcall(function() screen_gui:Destroy() end) end) end)

if safe_account_check() then
    show_dialog("PERINGATAN!\nKami mendeteksi Anda menggunakan Akun Utama. Gunakan akun alternatif untuk mencegah resiko pemblokiran.", {
        { Title = "Tetap Eksekusi", Callback = execute_main_script },
        { Title = "Batalkan", Callback = fade_out_loader }
    })
elseif not is_discord_dismissed() then
    show_dialog("Script ini gratis!\nDukung kami dengan bergabung ke server Discord.\n\ndiscord.gg/RhdPCbZNUZ", {
        { Title = "Lanjutkan", Callback = function() mark_discord_dismissed(); execute_main_script() end },
        { Title = "Salin Link", Callback = function()
            if setclipboard then setclipboard("https://discord.gg/RhdPCbZNUZ") end
            mark_discord_dismissed()
            execute_main_script()
        end}
    })
else
    task_spawn(execute_main_script)
end
