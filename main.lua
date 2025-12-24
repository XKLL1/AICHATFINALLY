local success, errorMsg = pcall(function()

local ts = game:GetService("TweenService")
local uis = game:GetService("UserInputService")
local plrs = game:GetService("Players")
local http = game:GetService("HttpService")
local rs = game:GetService("ReplicatedStorage")
local tcs = game:GetService("TextChatService")

local lp = plrs.LocalPlayer

local SCRIPT_VERSION = "6.1.0"
local BUILD_TYPE = "MOBILE"

local SHARED_API_KEY = "sk-mapleai-1CgWDOBjGiMlKD9GEySEuStZDUs4EUgd17hAamhToNAe33aXTBhi7LyA7ZTeSVcW4P6k52aYkcbDt2BY"

local ExecutorInfo = {
    name = "Unknown",
    version = "Unknown",
}

pcall(function()
    if identifyexecutor then
        local name, version = identifyexecutor()
        ExecutorInfo.name = name or "Unknown"
        ExecutorInfo.version = version or "Unknown"
    elseif getexecutorname then
        ExecutorInfo.name = getexecutorname()
    end
end)

local cfgFile = "MapleAI_Mobile.json"
local API_BASE = "https://api.mapleai.de/v1"

local defCfg = {
    MasterEnabled = false,
    Persona = "You are a helpful AI assistant in a Roblox game. Keep responses short, friendly, and appropriate for all ages. Max 2 sentences.",
    Model = "gpt-4o-mini",
    Blacklist = {},
    DebugMode = false,
    Range = 0,
    TriggerMode = "all",
    TriggerPrefix = "@maple",
    ResponseDelay = 0.3,
    MaxTokens = 150,
    Temperature = 0.7,
    AFKMode = false,
    AFKMessage = "AFK rn",
    AntiSpam = true,
    SpamThreshold = 3,
    SpamCooldown = 30,
    ContextWindowSize = 10,
    SmartContextEnabled = false,
}

getgenv().MapleConfig = getgenv().MapleConfig or {}
for k, v in pairs(defCfg) do
    if getgenv().MapleConfig[k] == nil then
        getgenv().MapleConfig[k] = v
    end
end

local AVAILABLE_MODELS = {
    "gpt-4o-mini",
    "gpt-3.5-turbo",
    "gpt-4o",
    "claude-3-haiku-20240307",
}

local clr = {
    accent = Color3.fromRGB(147, 112, 219),
    bg = Color3.fromRGB(28, 28, 30),
    bgSecondary = Color3.fromRGB(44, 44, 46),
    surface = Color3.fromRGB(38, 38, 40),
    textPrimary = Color3.fromRGB(255, 255, 255),
    textSecondary = Color3.fromRGB(174, 174, 178),
    success = Color3.fromRGB(52, 199, 89),
    warning = Color3.fromRGB(255, 159, 10),
    error = Color3.fromRGB(255, 69, 58),
    info = Color3.fromRGB(10, 132, 255),
}

local MAX_MSG_LENGTH = 200
local CACHE_MAX_SIZE = 100
local CACHE_TTL = 300
local MAX_MEMORY_SIZE = 20

local processing = false
local startTime = tick()

local playerMemory = {}
local spamTracker = {}
local responseCache = {}
local cacheOrder = {}
local rateLimitTracker = { count = 0, resetTime = 0 }

local stats = {
    messagesReceived = 0,
    responsesSent = 0,
    errors = 0,
    cacheHits = 0,
    apiCalls = 0,
}

local connections = {}

local function addConnection(conn, name)
    if conn then
        if name and connections[name] then
            pcall(function() connections[name]:Disconnect() end)
        end
        connections[name or (#connections + 1)] = conn
    end
end

local function log(...)
    if getgenv().MapleConfig.DebugMode then
        print("[Maple]", ...)
    end
end

local function saveConfig()
    pcall(function()
        if writefile then
            writefile(cfgFile, http:JSONEncode(getgenv().MapleConfig))
        end
    end)
end

local function loadConfig()
    pcall(function()
        if isfile and isfile(cfgFile) and readfile then
            local data = readfile(cfgFile)
            local decoded = http:JSONDecode(data)
            for k, v in pairs(decoded) do
                if defCfg[k] ~= nil then
                    getgenv().MapleConfig[k] = v
                end
            end
        end
    end)
end

loadConfig()

local httpRequest = request or http_request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request)

if not httpRequest then
    warn("[Maple] No HTTP function!")
end

pcall(function()
    local existing = game:GetService("CoreGui"):FindFirstChild("MapleAI_Mobile")
    if existing then existing:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "MapleAI_Mobile"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true

pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(gui)
    elseif gethui then
        gui.Parent = gethui()
        return
    end
end)

gui.Parent = game:GetService("CoreGui")

local function createCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 12)
    corner.Parent = parent
    return corner
end

local function quickTween(obj, props, duration)
    local tween = ts:Create(obj, TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad), props)
    tween:Play()
    return tween
end

local fab = Instance.new("Frame")
fab.Name = "FAB"
fab.Size = UDim2.new(0, 70, 0, 70)
fab.Position = UDim2.new(0, 20, 1, -100)
fab.BackgroundColor3 = clr.accent
fab.Parent = gui
createCorner(fab, 35)

local fabIcon = Instance.new("TextLabel")
fabIcon.Size = UDim2.new(1, 0, 1, 0)
fabIcon.BackgroundTransparency = 1
fabIcon.Text = "M"
fabIcon.TextSize = 32
fabIcon.TextColor3 = clr.textPrimary
fabIcon.Font = Enum.Font.GothamBold
fabIcon.Parent = fab

local fabButton = Instance.new("TextButton")
fabButton.Size = UDim2.new(1, 0, 1, 0)
fabButton.BackgroundTransparency = 1
fabButton.Text = ""
fabButton.Parent = fab

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 20, 0, 20)
statusDot.Position = UDim2.new(1, -16, 0, -4)
statusDot.BackgroundColor3 = clr.error
statusDot.Parent = fab
createCorner(statusDot, 10)

local function updateStatusDot()
    statusDot.BackgroundColor3 = getgenv().MapleConfig.MasterEnabled and clr.success or clr.error
end

local mainWindow = Instance.new("Frame")
mainWindow.Name = "MainWindow"
mainWindow.Size = UDim2.new(0.92, 0, 0.7, 0)
mainWindow.Position = UDim2.new(0.04, 0, 0.15, 0)
mainWindow.BackgroundColor3 = clr.bg
mainWindow.Visible = false
mainWindow.Parent = gui
createCorner(mainWindow, 16)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = clr.bgSecondary
titleBar.Parent = mainWindow
createCorner(titleBar, 16)

local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 16)
titleFix.Position = UDim2.new(0, 0, 1, -16)
titleFix.BackgroundColor3 = clr.bgSecondary
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -60, 1, 0)
titleText.Position = UDim2.new(0, 16, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "Maple AI"
titleText.TextColor3 = clr.textPrimary
titleText.TextSize = 18
titleText.Font = Enum.Font.GothamBold
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 44, 0, 44)
closeBtn.Position = UDim2.new(1, -50, 0.5, -22)
closeBtn.BackgroundColor3 = clr.error
closeBtn.Text = "X"
closeBtn.TextColor3 = clr.textPrimary
closeBtn.TextSize = 18
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar
createCorner(closeBtn, 10)

local contentScroll = Instance.new("ScrollingFrame")
contentScroll.Size = UDim2.new(1, -24, 1, -62)
contentScroll.Position = UDim2.new(0, 12, 0, 56)
contentScroll.BackgroundTransparency = 1
contentScroll.ScrollBarThickness = 4
contentScroll.ScrollBarImageColor3 = clr.accent
contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
contentScroll.Parent = mainWindow

local contentLayout = Instance.new("UIListLayout")
contentLayout.Parent = contentScroll
contentLayout.Padding = UDim.new(0, 10)

local layoutOrder = 0
local function nextOrder()
    layoutOrder = layoutOrder + 1
    return layoutOrder
end

local function createSection(text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 30)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = clr.textSecondary
    label.TextSize = 12
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.LayoutOrder = nextOrder()
    label.Parent = contentScroll
end

local function createToggle(text, defaultValue, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 56)
    frame.BackgroundColor3 = clr.surface
    frame.LayoutOrder = nextOrder()
    frame.Parent = contentScroll
    createCorner(frame, 10)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -80, 1, 0)
    label.Position = UDim2.new(0, 16, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = clr.textPrimary
    label.TextSize = 14
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local toggle = Instance.new("Frame")
    toggle.Size = UDim2.new(0, 56, 0, 32)
    toggle.Position = UDim2.new(1, -70, 0.5, -16)
    toggle.BackgroundColor3 = defaultValue and clr.accent or clr.bgSecondary
    toggle.Parent = frame
    createCorner(toggle, 16)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 28, 0, 28)
    knob.Position = defaultValue and UDim2.new(1, -30, 0.5, -14) or UDim2.new(0, 2, 0.5, -14)
    knob.BackgroundColor3 = clr.textPrimary
    knob.Parent = toggle
    createCorner(knob, 14)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = frame

    local isOn = defaultValue
    btn.MouseButton1Click:Connect(function()
        isOn = not isOn
        toggle.BackgroundColor3 = isOn and clr.accent or clr.bgSecondary
        knob.Position = isOn and UDim2.new(1, -30, 0.5, -14) or UDim2.new(0, 2, 0.5, -14)
        if callback then callback(isOn) end
    end)

    return frame
end

local function createButton(text, callback, isPrimary)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 50)
    btn.BackgroundColor3 = isPrimary and clr.accent or clr.surface
    btn.Text = text
    btn.TextColor3 = clr.textPrimary
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.LayoutOrder = nextOrder()
    btn.Parent = contentScroll
    createCorner(btn, 10)

    btn.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)

    return btn
end

local function createDropdown(labelText, options, defaultValue, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 90)
    frame.BackgroundColor3 = clr.surface
    frame.LayoutOrder = nextOrder()
    frame.Parent = contentScroll
    createCorner(frame, 10)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 24)
    label.Position = UDim2.new(0, 16, 0, 8)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = clr.textPrimary
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local dropBtn = Instance.new("TextButton")
    dropBtn.Size = UDim2.new(1, -32, 0, 40)
    dropBtn.Position = UDim2.new(0, 16, 0, 38)
    dropBtn.BackgroundColor3 = clr.bgSecondary
    dropBtn.Text = "  " .. defaultValue .. "  ▼"
    dropBtn.TextColor3 = clr.textPrimary
    dropBtn.TextSize = 13
    dropBtn.Font = Enum.Font.Gotham
    dropBtn.TextXAlignment = Enum.TextXAlignment.Left
    dropBtn.Parent = frame
    createCorner(dropBtn, 8)

    local currentIdx = 1
    for i, opt in ipairs(options) do
        if opt == defaultValue then currentIdx = i break end
    end

    dropBtn.MouseButton1Click:Connect(function()
        currentIdx = currentIdx % #options + 1
        local newVal = options[currentIdx]
        dropBtn.Text = "  " .. newVal .. "  ▼"
        if callback then callback(newVal) end
    end)

    return frame
end

local function createInput(labelText, placeholder, defaultValue, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 90)
    frame.BackgroundColor3 = clr.surface
    frame.LayoutOrder = nextOrder()
    frame.Parent = contentScroll
    createCorner(frame, 10)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 24)
    label.Position = UDim2.new(0, 16, 0, 8)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = clr.textPrimary
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -32, 0, 40)
    input.Position = UDim2.new(0, 16, 0, 38)
    input.BackgroundColor3 = clr.bgSecondary
    input.Text = defaultValue or ""
    input.PlaceholderText = placeholder or ""
    input.TextColor3 = clr.textPrimary
    input.PlaceholderColor3 = clr.textSecondary
    input.TextSize = 13
    input.Font = Enum.Font.Gotham
    input.ClearTextOnFocus = false
    input.Parent = frame
    createCorner(input, 8)

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.Parent = input

    input.FocusLost:Connect(function()
        if callback then callback(input.Text) end
    end)

    return frame, input
end

local function createSlider(text, minVal, maxVal, defaultValue, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 70)
    frame.BackgroundColor3 = clr.surface
    frame.LayoutOrder = nextOrder()
    frame.Parent = contentScroll
    createCorner(frame, 10)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 0, 24)
    label.Position = UDim2.new(0, 16, 0, 8)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = clr.textPrimary
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 50, 0, 24)
    valueLabel.Position = UDim2.new(1, -60, 0, 8)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(defaultValue)
    valueLabel.TextColor3 = clr.accent
    valueLabel.TextSize = 13
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Parent = frame

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -32, 0, 8)
    track.Position = UDim2.new(0, 16, 0, 48)
    track.BackgroundColor3 = clr.bgSecondary
    track.Parent = frame
    createCorner(track, 4)

    local percent = (defaultValue - minVal) / (maxVal - minVal)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(percent, 0, 1, 0)
    fill.BackgroundColor3 = clr.accent
    fill.Parent = track
    createCorner(fill, 4)

    local isDragging = false

    local function updateSlider(inputX)
        local rel = math.clamp((inputX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local value = minVal + rel * (maxVal - minVal)
        if maxVal <= 1 then
            value = math.floor(value * 100) / 100
        else
            value = math.floor(value)
        end
        valueLabel.Text = tostring(value)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        if callback then callback(value) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            updateSlider(input.Position.X)
        end
    end)

    track.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)

    addConnection(uis.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            updateSlider(input.Position.X)
        end
    end), "slider_" .. text:gsub("%s", "_"))

    return frame
end

local statusCard = Instance.new("Frame")
statusCard.Size = UDim2.new(1, 0, 0, 80)
statusCard.BackgroundColor3 = clr.surface
statusCard.LayoutOrder = nextOrder()
statusCard.Parent = contentScroll
createCorner(statusCard, 12)

local statusTitle = Instance.new("TextLabel")
statusTitle.Size = UDim2.new(1, -20, 0, 30)
statusTitle.Position = UDim2.new(0, 16, 0, 14)
statusTitle.BackgroundTransparency = 1
statusTitle.Text = "Status: Inactive"
statusTitle.TextColor3 = clr.textPrimary
statusTitle.TextSize = 16
statusTitle.Font = Enum.Font.GothamBold
statusTitle.TextXAlignment = Enum.TextXAlignment.Left
statusTitle.Parent = statusCard

local statusSub = Instance.new("TextLabel")
statusSub.Size = UDim2.new(1, -20, 0, 20)
statusSub.Position = UDim2.new(0, 16, 0, 44)
statusSub.BackgroundTransparency = 1
statusSub.Text = "Toggle to enable"
statusSub.TextColor3 = clr.textSecondary
statusSub.TextSize = 12
statusSub.Font = Enum.Font.Gotham
statusSub.TextXAlignment = Enum.TextXAlignment.Left
statusSub.Parent = statusCard

local statusDotBig = Instance.new("Frame")
statusDotBig.Size = UDim2.new(0, 16, 0, 16)
statusDotBig.Position = UDim2.new(1, -36, 0.5, -8)
statusDotBig.BackgroundColor3 = clr.error
statusDotBig.Parent = statusCard
createCorner(statusDotBig, 8)

local function updateStatus()
    local enabled = getgenv().MapleConfig.MasterEnabled
    local afk = getgenv().MapleConfig.AFKMode
    if enabled then
        if afk then
            statusTitle.Text = "Status: AFK"
            statusSub.Text = "Auto AFK response"
            statusDotBig.BackgroundColor3 = clr.warning
        else
            statusTitle.Text = "Status: Active"
            statusSub.Text = "Responding to chat"
            statusDotBig.BackgroundColor3 = clr.success
        end
    else
        statusTitle.Text = "Status: Inactive"
        statusSub.Text = "Toggle to enable"
        statusDotBig.BackgroundColor3 = clr.error
    end
    updateStatusDot()
end

createSection("CONTROLS")

createToggle("Enable AI", getgenv().MapleConfig.MasterEnabled, function(v)
    getgenv().MapleConfig.MasterEnabled = v
    saveConfig()
    updateStatus()
end)

createToggle("AFK Mode", getgenv().MapleConfig.AFKMode, function(v)
    getgenv().MapleConfig.AFKMode = v
    saveConfig()
    updateStatus()
end)

createSection("SETTINGS")

createDropdown("Trigger Mode", {"all", "mention", "prefix"}, getgenv().MapleConfig.TriggerMode, function(v)
    getgenv().MapleConfig.TriggerMode = v
    saveConfig()
end)

createSlider("Range (0=∞)", 0, 300, getgenv().MapleConfig.Range, function(v)
    getgenv().MapleConfig.Range = v
    saveConfig()
end)

createSlider("Response Delay", 0.1, 5, getgenv().MapleConfig.ResponseDelay, function(v)
    getgenv().MapleConfig.ResponseDelay = v
    saveConfig()
end)

createSection("AI MODEL")

createDropdown("Model", AVAILABLE_MODELS, getgenv().MapleConfig.Model, function(v)
    getgenv().MapleConfig.Model = v
    saveConfig()
end)

createSlider("Max Tokens", 50, 300, getgenv().MapleConfig.MaxTokens, function(v)
    getgenv().MapleConfig.MaxTokens = v
    saveConfig()
end)

createSection("PERSONA")

local _, personaInput = createInput("AI Persona", "How should AI behave...", getgenv().MapleConfig.Persona, function(v)
    getgenv().MapleConfig.Persona = v
    saveConfig()
end)

createSection("PRESETS")

local presets = {
    {"Helpful", "You are a helpful AI in Roblox. Be friendly and brief. Max 2 sentences."},
    {"Casual", "You are a chill gamer. Use casual language and gaming slang. Keep it short!"},
    {"Sarcastic", "You are sarcastic but helpful. Use wit and humor. Still answer helpfully."},
}

for _, p in ipairs(presets) do
    createButton(p[1], function()
        personaInput.Text = p[2]
        getgenv().MapleConfig.Persona = p[2]
        saveConfig()
    end)
end

createSection("MEMORY")

createButton("Clear History", function()
    playerMemory = {}
    responseCache = {}
    cacheOrder = {}
end, true)

createSection("INFO")

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, 0, 0, 60)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = string.format("v%s | %s\nMsgs: 0 | Resp: 0 | Err: 0", SCRIPT_VERSION, ExecutorInfo.name)
infoLabel.TextColor3 = clr.textSecondary
infoLabel.TextSize = 11
infoLabel.Font = Enum.Font.Gotham
infoLabel.LayoutOrder = nextOrder()
infoLabel.Parent = contentScroll

task.spawn(function()
    while gui.Parent do
        task.wait(3)
        infoLabel.Text = string.format("v%s | %s\nMsgs: %d | Resp: %d | Err: %d", 
            SCRIPT_VERSION, ExecutorInfo.name, stats.messagesReceived, stats.responsesSent, stats.errors)
    end
end)

updateStatus()

fabButton.MouseButton1Click:Connect(function()
    mainWindow.Visible = not mainWindow.Visible
end)

closeBtn.MouseButton1Click:Connect(function()
    mainWindow.Visible = false
end)

local sayRemote = nil
pcall(function()
    local defaultChat = rs:FindFirstChild("DefaultChatSystemChatEvents")
    if defaultChat then
        sayRemote = defaultChat:FindFirstChild("SayMessageRequest")
    end
end)

local function sendMessage(message)
    if not message or message == "" then return false end
    if #message > MAX_MSG_LENGTH then
        message = message:sub(1, MAX_MSG_LENGTH - 3) .. "..."
    end
    local success = false
    pcall(function()
        if tcs and tcs.TextChannels then
            local channel = tcs.TextChannels:FindFirstChild("RBXGeneral")
            if channel then
                channel:SendAsync(message)
                success = true
            end
        end
    end)
    if not success and sayRemote then
        pcall(function()
            sayRemote:FireServer(message, "All")
            success = true
        end)
    end
    return success
end

local function getPlayerDistance(character)
    if not character then return 999999 end
    local myChar = lp.Character
    if not myChar then return 999999 end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    local theirRoot = character:FindFirstChild("HumanoidRootPart")
    if not myRoot or not theirRoot then return 999999 end
    return (theirRoot.Position - myRoot.Position).Magnitude
end

local function isSpamming(player, message)
    if not getgenv().MapleConfig.AntiSpam then return false end
    local uid = player.UserId
    if not spamTracker[uid] then spamTracker[uid] = {} end
    local now = tick()
    local cd = getgenv().MapleConfig.SpamCooldown or 30
    local cleaned = {}
    for _, e in ipairs(spamTracker[uid]) do
        if now - e.time < cd then table.insert(cleaned, e) end
    end
    spamTracker[uid] = cleaned
    local count = 0
    for _, e in ipairs(spamTracker[uid]) do
        if e.msg == message then count = count + 1 end
    end
    table.insert(spamTracker[uid], {msg = message, time = now})
    return count >= getgenv().MapleConfig.SpamThreshold
end

local function shouldRespond(player, message)
    local mode = getgenv().MapleConfig.TriggerMode
    if mode == "all" then return true end
    if mode == "mention" then
        local lower = message:lower()
        return lower:find("maple") or lower:find(lp.Name:lower()) or lower:find(lp.DisplayName:lower())
    end
    if mode == "prefix" then
        local prefix = getgenv().MapleConfig.TriggerPrefix
        return message:sub(1, #prefix):lower() == prefix:lower()
    end
    return true
end

local function getCacheKey(msg)
    return msg:lower():gsub("%s+", " "):gsub("[^%w%s]", "")
end

local function checkCache(msg)
    local key = getCacheKey(msg)
    local entry = responseCache[key]
    if entry and tick() - entry.ts < CACHE_TTL then
        stats.cacheHits = stats.cacheHits + 1
        return entry.resp
    end
    return nil
end

local function addToCache(msg, resp)
    local key = getCacheKey(msg)
    while #cacheOrder >= CACHE_MAX_SIZE do
        local oldKey = table.remove(cacheOrder, 1)
        responseCache[oldKey] = nil
    end
    responseCache[key] = {resp = resp, ts = tick()}
    table.insert(cacheOrder, key)
end

local function getMemory(player)
    local uid = tostring(player.UserId)
    if not playerMemory[uid] then
        playerMemory[uid] = {name = player.DisplayName, msgs = {}, last = tick()}
    end
    return playerMemory[uid]
end

local function addToMemory(player, msg, role)
    local mem = getMemory(player)
    table.insert(mem.msgs, {role = role, content = msg, ts = tick()})
    mem.last = tick()
    while #mem.msgs > MAX_MEMORY_SIZE do
        table.remove(mem.msgs, 1)
    end
end

local function buildMessages(player, currentMsg)
    local cfg = getgenv().MapleConfig
    local mem = getMemory(player)
    local messages = {}
    
    local sys = cfg.Persona .. "\n"
    sys = sys .. "CONTEXT: Roblox game chat. Player: " .. player.DisplayName .. ". Keep responses under 200 chars. No markdown."
    
    table.insert(messages, {role = "system", content = sys})
    
    local windowSize = cfg.ContextWindowSize or 10
    local start = math.max(1, #mem.msgs - windowSize + 1)
    for i = start, #mem.msgs do
        table.insert(messages, {role = mem.msgs[i].role, content = mem.msgs[i].content})
    end
    
    table.insert(messages, {role = "user", content = currentMsg})
    return messages
end

local function makeRequest(messages, retry)
    retry = retry or 0
    local cfg = getgenv().MapleConfig
    
    if not httpRequest then return nil, "NO_HTTP", "No HTTP function available" end
    if SHARED_API_KEY == "" or SHARED_API_KEY == "YOUR_API_KEY_HERE" then
        return nil, "NO_KEY", "API key not configured"
    end
    
    if not messages or #messages == 0 then
        return nil, "INVALID_INPUT", "No messages provided"
    end
    
    local now = tick()
    if now > rateLimitTracker.resetTime then
        rateLimitTracker.count = 0
        rateLimitTracker.resetTime = now + 60
    end
    if rateLimitTracker.count >= 60 then
        local waitTime = math.ceil(rateLimitTracker.resetTime - now)
        return nil, "LOCAL_RATE_LIMIT", "Local rate limit, wait " .. waitTime .. "s"
    end
    rateLimitTracker.count = rateLimitTracker.count + 1
    stats.apiCalls = stats.apiCalls + 1
    
    local model = cfg.Model
    if not model or model == "" then
        model = "gpt-4o-mini"
    end
    
    local maxTokens = cfg.MaxTokens
    if not maxTokens or maxTokens < 1 then maxTokens = 150 end
    if maxTokens > 4096 then maxTokens = 4096 end
    
    local temp = cfg.Temperature
    if not temp then temp = 0.7 end
    if temp < 0 then temp = 0 end
    if temp > 2 then temp = 2 end
    
    local body = {
        model = model,
        messages = messages,
        max_tokens = maxTokens,
        temperature = temp,
    }
    
    local encodeOk, encodedBody = pcall(function()
        return http:JSONEncode(body)
    end)
    if not encodeOk or not encodedBody then
        return nil, "ENCODE_ERROR", "Failed to encode request body"
    end
    
    local ok, result = pcall(function()
        return httpRequest({
            Url = API_BASE .. "/chat/completions",
            Method = "POST",
            Headers = {
                ["Authorization"] = "Bearer " .. SHARED_API_KEY,
                ["Content-Type"] = "application/json",
                ["Accept"] = "application/json"
            },
            Body = encodedBody
        })
    end)
    
    if not ok then
        log("HTTP pcall failed:", tostring(result))
        if retry < 2 then
            task.wait(1 * (retry + 1))
            return makeRequest(messages, retry + 1)
        end
        return nil, "HTTP_ERROR", "HTTP request failed: " .. tostring(result)
    end
    
    if not result then
        if retry < 2 then
            task.wait(1 * (retry + 1))
            return makeRequest(messages, retry + 1)
        end
        return nil, "NO_RESPONSE", "No response from server"
    end
    
    local statusCode = result.StatusCode or 0
    local statusMsg = result.StatusMessage or ""
    
    if statusCode == 401 then
        return nil, "UNAUTHORIZED", "Invalid API key"
    end
    
    if statusCode == 403 then
        return nil, "FORBIDDEN", "Access denied to this resource"
    end
    
    if statusCode == 404 then
        return nil, "NOT_FOUND", "Model or endpoint not found"
    end
    
    if statusCode == 429 then
        local retryAfter = 5
        if result.Headers then
            local ra = result.Headers["retry-after"] or result.Headers["Retry-After"]
            if ra then retryAfter = tonumber(ra) or 5 end
        end
        if retry < 3 then
            log("Rate limited, waiting", retryAfter, "seconds")
            task.wait(retryAfter)
            return makeRequest(messages, retry + 1)
        end
        return nil, "RATE_LIMITED", "API rate limited, try again later"
    end
    
    if statusCode >= 500 then
        if retry < 2 then
            task.wait(2 * (retry + 1))
            return makeRequest(messages, retry + 1)
        end
        return nil, "SERVER_ERROR", "Server error (" .. statusCode .. "): " .. statusMsg
    end
    
    if statusCode >= 400 then
        return nil, "CLIENT_ERROR", "Client error (" .. statusCode .. "): " .. statusMsg
    end
    
    if not result.Body or result.Body == "" then
        if retry < 2 then
            task.wait(1)
            return makeRequest(messages, retry + 1)
        end
        return nil, "EMPTY_BODY", "Empty response body"
    end
    
    local decodeOk, data = pcall(function()
        return http:JSONDecode(result.Body)
    end)
    
    if not decodeOk or not data then
        log("JSON decode failed:", result.Body:sub(1, 100))
        return nil, "PARSE_ERROR", "Failed to parse response JSON"
    end
    
    if data.error then
        local errType = data.error.type or "unknown"
        local errMsg = data.error.message or "Unknown API error"
        local errCode = data.error.code
        
        if errType == "insufficient_quota" or errCode == "insufficient_quota" then
            return nil, "QUOTA_EXCEEDED", "API quota exceeded"
        end
        
        if errType == "invalid_request_error" then
            return nil, "INVALID_REQUEST", errMsg
        end
        
        if errType == "model_not_found" or errCode == "model_not_found" then
            return nil, "MODEL_NOT_FOUND", "Model '" .. model .. "' not available"
        end
        
        if errType == "context_length_exceeded" then
            return nil, "CONTEXT_TOO_LONG", "Message too long, reduce context"
        end
        
        return nil, "API_ERROR", errMsg
    end
    
    if not data.choices or #data.choices == 0 then
        return nil, "NO_CHOICES", "No response choices returned"
    end
    
    local choice = data.choices[1]
    if not choice.message or not choice.message.content then
        if choice.finish_reason == "length" then
            return nil, "MAX_TOKENS", "Response cut off due to max tokens"
        end
        if choice.finish_reason == "content_filter" then
            return nil, "FILTERED", "Response blocked by content filter"
        end
        return nil, "NO_CONTENT", "No message content in response"
    end
    
    return choice.message.content, nil, nil
end

local function processMsg(player, message)
    local cfg = getgenv().MapleConfig
    stats.messagesReceived = stats.messagesReceived + 1
    log("Processing:", player.Name, message)
    
    if cfg.AFKMode then
        task.wait(cfg.ResponseDelay or 0.3)
        sendMessage(cfg.AFKMessage)
        stats.responsesSent = stats.responsesSent + 1
        return
    end
    
    if not message or message == "" then
        log("Empty message, skipping")
        return
    end
    
    message = message:gsub("^%s+", ""):gsub("%s+$", "")
    if #message == 0 then
        log("Whitespace-only message, skipping")
        return
    end
    
    local cached = checkCache(message)
    if cached then
        addToMemory(player, message, "user")
        addToMemory(player, cached, "assistant")
        task.wait(cfg.ResponseDelay or 0.3)
        sendMessage(cached)
        stats.responsesSent = stats.responsesSent + 1
        log("Sent cached response")
        return
    end
    
    local msgs = buildMessages(player, message)
    local resp, errCode, errMsg = makeRequest(msgs)
    
    if errCode then
        log("API Error [" .. errCode .. "]:", errMsg or "Unknown")
        stats.errors = stats.errors + 1
        
        if errCode == "NO_HTTP" or errCode == "NO_KEY" then
            log("Critical config error, disabling AI")
            return
        end
        
        if errCode == "CONTEXT_TOO_LONG" then
            local mem = getMemory(player)
            if #mem.msgs > 2 then
                local keepCount = math.floor(#mem.msgs / 2)
                while #mem.msgs > keepCount do
                    table.remove(mem.msgs, 1)
                end
                log("Trimmed context, retrying...")
                local newMsgs = buildMessages(player, message)
                resp, errCode, errMsg = makeRequest(newMsgs)
            end
        end
        
        if errCode == "MODEL_NOT_FOUND" then
            log("Model not found, falling back to gpt-4o-mini")
            cfg.Model = "gpt-4o-mini"
            saveConfig()
            local newMsgs = buildMessages(player, message)
            resp, errCode, errMsg = makeRequest(newMsgs)
        end
        
        if errCode then
            return
        end
    end
    
    if resp then
        resp = tostring(resp)
        resp = resp:gsub("^%s+", ""):gsub("%s+$", "")
        resp = resp:gsub("\n+", " ")
        resp = resp:gsub("%s+", " ")
        
        resp = resp:gsub("^[%*#`]+", ""):gsub("[%*#`]+$", "")
        
        if #resp == 0 then
            log("Empty response after cleanup")
            return
        end
        
        if #resp > MAX_MSG_LENGTH then
            local cutoff = MAX_MSG_LENGTH - 3
            local lastSpace = resp:sub(1, cutoff):match(".*()%s")
            if lastSpace and lastSpace > cutoff * 0.7 then
                resp = resp:sub(1, lastSpace - 1) .. "..."
            else
                resp = resp:sub(1, cutoff) .. "..."
            end
        end
        
        addToMemory(player, message, "user")
        addToMemory(player, resp, "assistant")
        addToCache(message, resp)
        
        task.wait(cfg.ResponseDelay or 0.3)
        local sent = sendMessage(resp)
        if sent then
            stats.responsesSent = stats.responsesSent + 1
            log("Response sent successfully")
        else
            log("Failed to send message")
            stats.errors = stats.errors + 1
        end
    end
end

local function onChat(player, message)
    local cfg = getgenv().MapleConfig
    if not cfg.MasterEnabled then return end
    if player == lp then return end
    if table.find(cfg.Blacklist, player.Name) or table.find(cfg.Blacklist, player.DisplayName) then return end
    
    if cfg.Range > 0 then
        if getPlayerDistance(player.Character) > cfg.Range then return end
    end
    
    if not shouldRespond(player, message) then return end
    if isSpamming(player, message) then return end
    
    task.spawn(function()
        processing = true
        pcall(function() processMsg(player, message) end)
        processing = false
    end)
end

local function setupListeners()
    pcall(function()
        if tcs then
            addConnection(tcs.MessageReceived:Connect(function(msg)
                local src = msg.TextSource
                if src then
                    local player = plrs:GetPlayerByUserId(src.UserId)
                    if player then onChat(player, msg.Text) end
                end
            end), "TCS")
        end
    end)
    
    pcall(function()
        for _, player in ipairs(plrs:GetPlayers()) do
            if player ~= lp then
                addConnection(player.Chatted:Connect(function(m) onChat(player, m) end), "Chat_" .. player.UserId)
            end
        end
        addConnection(plrs.PlayerAdded:Connect(function(player)
            if player ~= lp then
                addConnection(player.Chatted:Connect(function(m) onChat(player, m) end), "Chat_" .. player.UserId)
            end
        end), "PlayerAdded")
    end)
end

setupListeners()

print("[Maple AI] v" .. SCRIPT_VERSION .. " Mobile loaded!")

end)

if not success then
    warn("[Maple AI] Error: " .. tostring(errorMsg))
end

return success
