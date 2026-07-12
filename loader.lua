local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")

local loadstring, pcall, tostring, task = loadstring, pcall, tostring, task

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "IndexLoader"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true

local ok = pcall(function()
	screenGui.Parent = game:GetService("CoreGui")
end)
if not ok then
	screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleText"
titleLabel.Size = UDim2.new(1, 0, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "[ Kairiz ]"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 54
titleLabel.Font = Enum.Font.GothamMedium
titleLabel.TextTransparency = 1
titleLabel.MaxVisibleGraphemes = 0
titleLabel.Parent = screenGui

local LOADER_URL = "https://raw.githubusercontent.com/Its3rr0rsWRLD/Index/main/loader.json"
local prefetchConfig, prefetchConfigErr
local prefetchScript, prefetchScriptErr
local prefetchDone = false

task.spawn(function()
	local raw
	for i = 1, 3 do
		local okRaw, res = pcall(function() return game:HttpGet(LOADER_URL) end)
		if okRaw then raw = res break end
		task.wait(1)
	end
	
	if not raw then prefetchConfigErr = "Network Timeout/Error" prefetchDone = true return end
	local okJson, parsed = pcall(function() return HttpService:JSONDecode(raw) end)
	if not okJson then prefetchConfigErr = "Invalid JSON Config" prefetchDone = true return end
	prefetchConfig = parsed

	local placeId = tostring(game.PlaceId)
	local gameData = parsed.games and parsed.games[placeId]
	if gameData and gameData.url then
		local okSrc, src = pcall(function() return game:HttpGet(gameData.url) end)
		if okSrc then prefetchScript = src else prefetchScriptErr = src end
	end
	prefetchDone = true
end)

local fadeIn = TweenService:Create(titleLabel, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
	TextTransparency = 0,
})
fadeIn:Play()
fadeIn.Completed:Wait()
task.wait(0.2)

local totalChars = #titleLabel.Text
for i = 1, totalChars do
	titleLabel.MaxVisibleGraphemes = i
	task.wait(0.08)
end

task.wait(1.2)

local Theme = {
	Dialog              = Color3.fromRGB(30, 30, 30),
	DialogHolder        = Color3.fromRGB(22, 22, 22),
	DialogHolderLine    = Color3.fromRGB(40, 40, 40),
	DialogButton        = Color3.fromRGB(35, 35, 35),
	DialogButtonBorder  = Color3.fromRGB(65, 65, 65),
	DialogBorder        = Color3.fromRGB(55, 55, 55),
	Text                = Color3.fromRGB(245, 245, 245),
	Hover               = Color3.fromRGB(255, 255, 255),
}

local GothamFace     = Font.new("rbxasset://fonts/families/GothamSSm.json")
local GothamSemiBold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold)

local function showDialog(message, buttons)
	local dialogGui = Instance.new("ScreenGui")
	dialogGui.Name = "IndexDialog"
	dialogGui.ResetOnSpawn = false
	dialogGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	dialogGui.IgnoreGuiInset = true
	dialogGui.DisplayOrder = 10
	
	local parented = pcall(function() dialogGui.Parent = game:GetService("CoreGui") end)
	if not parented then dialogGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

	local TintFrame = Instance.new("TextButton")
	TintFrame.Name = "TintFrame"
	TintFrame.Text = ""
	TintFrame.AutoButtonColor = false
	TintFrame.Size = UDim2.fromScale(1, 1)
	TintFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	TintFrame.BackgroundTransparency = 1
	TintFrame.BorderSizePixel = 0
	TintFrame.Parent = dialogGui

	local Root = Instance.new("CanvasGroup")
	Root.Name = "Root"
	Root.Size = UDim2.new(0, 400, 0, 210)
	Root.AnchorPoint = Vector2.new(0.5, 0.5)
	Root.Position = UDim2.fromScale(0.5, 0.5)
	Root.BackgroundColor3 = Theme.Dialog
	Root.BorderSizePixel = 0
	Root.GroupTransparency = 1
	Root.Parent = TintFrame

	local RootCorner = Instance.new("UICorner")
	RootCorner.CornerRadius = UDim.new(0, 10)
	RootCorner.Parent = Root

	local RootStroke = Instance.new("UIStroke")
	RootStroke.Color = Theme.DialogBorder
	RootStroke.Transparency = 0.4
	RootStroke.Parent = Root

	local Scale = Instance.new("UIScale")
	Scale.Scale = 1.05
	Scale.Parent = Root

	local AspectConstraint = Instance.new("UIAspectRatioConstraint")
	AspectConstraint.AspectRatio = 400 / 210
	AspectConstraint.DominantAxis = Enum.DominantAxis.Width
	AspectConstraint.Parent = Root

	local Body = Instance.new("TextLabel")
	Body.Name = "Body"
	Body.BackgroundTransparency = 1
	Body.Size = UDim2.new(1, -40, 1, -95)
	Body.Position = UDim2.fromOffset(20, 15)
	Body.FontFace = GothamSemiBold
	Body.TextColor3 = Theme.Text
	Body.TextSize = 15
	Body.TextWrapped = true
	Body.TextXAlignment = Enum.TextXAlignment.Center
	Body.TextYAlignment = Enum.TextYAlignment.Center
	Body.Text = message
	Body.Parent = Root

	local ButtonHolderFrame = Instance.new("Frame")
	ButtonHolderFrame.Name = "ButtonHolderFrame"
	ButtonHolderFrame.Size = UDim2.new(1, 0, 0, 65)
	ButtonHolderFrame.Position = UDim2.new(0, 0, 1, -65)
	ButtonHolderFrame.BackgroundColor3 = Theme.DialogHolder
	ButtonHolderFrame.BorderSizePixel = 0
	ButtonHolderFrame.Parent = Root

	local SeparatorLine = Instance.new("Frame")
	SeparatorLine.Size = UDim2.new(1, 0, 0, 1)
	SeparatorLine.BackgroundColor3 = Theme.DialogHolderLine
	SeparatorLine.BorderSizePixel = 0
	SeparatorLine.Parent = ButtonHolderFrame

	local ButtonHolder = Instance.new("Frame")
	ButtonHolder.Size = UDim2.new(1, -30, 1, -25)
	ButtonHolder.AnchorPoint = Vector2.new(0.5, 0.5)
	ButtonHolder.Position = UDim2.fromScale(0.5, 0.5)
	ButtonHolder.BackgroundTransparency = 1
	ButtonHolder.Parent = ButtonHolderFrame

	local ListLayout = Instance.new("UIListLayout")
	ListLayout.Padding = UDim.new(0, 12)
	ListLayout.FillDirection = Enum.FillDirection.Horizontal
	ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	ListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ListLayout.Parent = ButtonHolder

	local isOpen = true
	local connections = {}

	local function close()
		if not isOpen then return end
		isOpen = false

		for _, conn in ipairs(connections) do
			if conn then conn:Disconnect() end
		end

		TweenService:Create(Root, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { GroupTransparency = 1 }):Play()
		TweenService:Create(Scale, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { Scale = 1.05 }):Play()
		TweenService:Create(TintFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()

		task.delay(0.25, function() dialogGui:Destroy() end)
	end

	local function createButton(title, layoutOrder, callback)
		local Frame = Instance.new("TextButton")
		Frame.Name = title
		Frame.Text = ""
		Frame.AutoButtonColor = false
		Frame.Size = UDim2.new(0, 0, 1, 0)
		Frame.BackgroundColor3 = Theme.DialogButton
		Frame.BorderSizePixel = 0
		Frame.LayoutOrder = layoutOrder
		Frame.Parent = ButtonHolder

		local Corner = Instance.new("UICorner")
		Corner.CornerRadius = UDim.new(0, 6)
		Corner.Parent = Frame

		local Stroke = Instance.new("UIStroke")
		Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		Stroke.Color = Theme.DialogButtonBorder
		Stroke.Transparency = 0.5
		Stroke.Parent = Frame

		local Hover = Instance.new("Frame")
		Hover.Size = UDim2.fromScale(1, 1)
		Hover.BackgroundColor3 = Theme.Hover
		Hover.BackgroundTransparency = 1
		Hover.BorderSizePixel = 0
		Hover.Parent = Frame

		local HoverCorner = Instance.new("UICorner")
		HoverCorner.CornerRadius = UDim.new(0, 6)
		HoverCorner.Parent = Hover

		local Label = Instance.new("TextLabel")
		Label.BackgroundTransparency = 1
		Label.Size = UDim2.fromScale(1, 1)
		Label.FontFace = GothamFace
		Label.Text = title
		Label.TextColor3 = Theme.Text
		Label.TextSize = 13
		Label.TextXAlignment = Enum.TextXAlignment.Center
		Label.TextYAlignment = Enum.TextYAlignment.Center
		Label.Parent = Frame

		local hoverTween = TweenInfo.new(0.15, Enum.EasingStyle.Quad)
		table.insert(connections, Frame.MouseEnter:Connect(function()
			TweenService:Create(Hover, hoverTween, { BackgroundTransparency = 0.94 }):Play()
		end))
		table.insert(connections, Frame.MouseLeave:Connect(function()
			TweenService:Create(Hover, hoverTween, { BackgroundTransparency = 1 }):Play()
		end))
		table.insert(connections, Frame.MouseButton1Click:Connect(function()
			if callback then pcall(callback) end
			close()
		end))

		return Frame
	end

	for i, btn in ipairs(buttons) do createButton(btn.Title, i, btn.Callback) end
	local n = #buttons
	for _, child in ipairs(ButtonHolder:GetChildren()) do
		if child:IsA("TextButton") then
			child.Size = UDim2.new(1 / n, -(((n - 1) * 12) / n), 1, 0)
		end
	end

	TweenService:Create(TintFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { BackgroundTransparency = 0.6 }):Play()
	TweenService:Create(Root, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { GroupTransparency = 0 }):Play()
	TweenService:Create(Scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

local loaderFaded = false
local function fadeOutLoader()
	if loaderFaded then return end
	loaderFaded = true
	local fadeOut = TweenService:Create(titleLabel, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { TextTransparency = 1 })
	fadeOut:Play()
	fadeOut.Completed:Wait()
	if screenGui then screenGui:Destroy() end
end

local DISCORD_DISMISSED_FILE = "Index/discord_dismissed"

local function isDiscordDismissed()
	if not (isfile and readfile) then return false end
	local ok, result = pcall(function() return isfile(DISCORD_DISMISSED_FILE) end)
	if ok and result then
		local content = readfile(DISCORD_DISMISSED_FILE)
		return content == "1"
	end
	return false
end

local function markDiscordDismissed()
	if not writefile then return end
	pcall(function()
		if makefolder and isfolder and not isfolder("Index") then makefolder("Index") end
		writefile(DISCORD_DISMISSED_FILE, "1")
	end)
end

local function showActionDialog(message, onAccept)
	showDialog(message, {
		{
			Title = "Okay",
			Callback = function()
				if onAccept then task.spawn(onAccept) end
			end,
		},
		{
			Title = "Copy Discord",
			Callback = function()
				if setclipboard then
					setclipboard("https://discord.gg/RhdPCbZNUZ")
					task.spawn(function()
						local originalText = titleLabel.Text
						titleLabel.Text = "Discord Link Copied!"
						task.wait(1.5)
						titleLabel.Text = originalText
					end)
				end
				if onAccept then task.spawn(onAccept) end
			end,
		},
	})
end

local startTime = os.time()
while not prefetchDone and (os.time() - startTime) < 10 do
	task.wait(0.1)
end

local success = prefetchConfig ~= nil
local config = prefetchConfig

if not success or not config then
	showActionDialog("Failed to fetch the Index game list.\n\nJoin our Discord for support:\ndiscord.gg/RhdPCbZNUZ", fadeOutLoader)
	return
end

local placeId = tostring(game.PlaceId)
local gameData = config.games and config.games[placeId]

if not gameData then
	showActionDialog("This game is not yet supported.\nPlace ID: " .. placeId .. "\n\nRequest it on our Discord:\ndiscord.gg/RhdPCbZNUZ", fadeOutLoader)
	return
end

task.wait(0.4)

local function loadGameScript()
	fadeOutLoader()
	task.wait(0.1)
	_G.IndexShowDiscord = true

	local source = prefetchScript
	if not source then
		local fetchOk, res = pcall(function() return game:HttpGet(gameData.url) end)
		if fetchOk then source = res end
	end

	if not source then
		showActionDialog("Failed to fetch the game script.\n\nPlease check your connection.", nil)
		return
	end

	local fn, compileErr = loadstring(source)
	if not fn then
		showActionDialog("Failed to compile the game script.\n\n" .. tostring(compileErr), nil)
		return
	end

	setfenv(fn, getfenv())
	local runOk, runErr = pcall(fn)
	if not runOk then
		showActionDialog("Failed to run the game script.\n\n" .. tostring(runErr), nil)
	end
end

local function detectMainAccount()
	local score = 0
	local age = LocalPlayer.AccountAge or 0
	
	if age > 1095 then score = score + 3
	elseif age > 365 then score = score + 2
	elseif age > 30 then score = score + 1 end

	if LocalPlayer.MembershipType == Enum.MembershipType.Premium then
		score = score + 3
	end

	pcall(function()
		local url = "https://friends.roproxy.com/v1/users/" .. tostring(LocalPlayer.UserId) .. "/friends/count"
		local raw = game:HttpGet(url)
		local data = HttpService:JSONDecode(raw)
		local count = data and data.count or 0
		if count > 50 then score = score + 2
		elseif count > 10 then score = score + 1 end
	end)

	return score >= 4
end

pcall(function()
	TeleportService.LocalPlayerLeftGame:Connect(function()
		if screenGui then screenGui:Destroy() end
	end)
end)

if detectMainAccount() then
	showDialog("Hey, we detected you may be on a main account. We recommend NOT using this on your main to avoid risking your account.", {
		{ Title = "Continue Anyway", Callback = function() task.spawn(loadGameScript) end },
		{ Title = "Stop Script", Callback = function() fadeOutLoader() end }
	})
elseif isDiscordDismissed() then
	task.spawn(loadGameScript)
else
	showActionDialog("Our scripts are keyless, but we ask that you join the Discord to support us and get updates on new scripts!\n\ndiscord.gg/RhdPCbZNUZ", function()
		markDiscordDismissed()
		loadGameScript()
	end)
end
