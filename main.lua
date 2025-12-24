local success, errorMsg = pcall(function()

local ts = game:GetService("TweenService")
local uis = game:GetService("UserInputService")
local plrs = game:GetService("Players")
local http = game:GetService("HttpService")
local rs = game:GetService("ReplicatedStorage")
local tcs = game:GetService("TextChatService")

local lp = plrs.LocalPlayer

local SCRIPT_VERSION = "6.2.0"
local BUILD_TYPE = "MOBILE"

local SHARED_API_KEY = "sk-mapleai-1CgWDOBjGiMlKD9GEySEuStZDUs4EUgd17hAamhToNAe33aXTBhi7LyA7ZTeSVcW4P6k52aYkcbDt2BY"

local ExecutorInfo = { name = "Unknown", version = "Unknown" }
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
    Persona = "Brief Roblox AI. Max 1-2 sentences.",
    Model = "gpt-4o-mini",
    Blacklist = {},
    DebugMode = false,
    Range = 0,
    TriggerMode = "all",
    TriggerPrefix = "@maple",
    ResponseDelay = 0.1,
    MaxTokens = 80,
    Temperature = 0.5,
    AFKMode = false,
    AFKMessage = "AFK",
    AntiSpam = true,
    SpamThreshold = 3,
    SpamCooldown = 30,
    ContextWindowSize = 3,
}

getgenv().MapleConfig = getgenv().MapleConfig or {}
for k, v in pairs(defCfg) do
    if getgenv().MapleConfig[k] == nil then
        getgenv().MapleConfig[k] = v
    end
end

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
local playerMemory = {}
local spamTracker = {}
local responseCache = {}
local cacheOrder = {}
local rateLimitTracker = { count = 0, resetTime = 0 }

local stats = { messagesReceived = 0, responsesSent = 0, errors = 0, cacheHits = 0, apiCalls = 0 }
local connections = {}

local function addConnection(conn, name)
    if conn then
        if name and connections[name] then pcall(function() connections[name]:Disconnect() end) end
        connections[name or (#connections + 1)] = conn
    end
end

local function log(...)
    if getgenv().MapleConfig.DebugMode then print("[Maple]", ...) end
end

local function saveConfig()
    pcall(function()
        if writefile then writefile(cfgFile, http:JSONEncode(getgenv().MapleConfig)) end
    end)
end

local function loadConfig()
    pcall(function()
        if isfile and isfile(cfgFile) and readfile then
            local data = readfile(cfgFile)
            local decoded = http:JSONDecode(data)
            for k, v in pairs(decoded) do
                if defCfg[k] ~= nil then getgenv().MapleConfig[k] = v end
            end
        end
    end)
end

loadConfig()

local httpRequest = request or http_request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request)
if not httpRequest then warn("[Maple] No HTTP function!") end

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
    if syn and syn.protect_gui then syn.protect_gui(gui)
    elseif gethui then gui.Parent = gethui() return end
end)
gui.Parent = game:GetService("CoreGui")

local function createCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 12)
    corner.Parent = parent
    return corner
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
mainWindow.Size = UDim2.new(0.92, 0, 0.75, 0)
mainWindow.Position = UDim2.new(0.04, 0, 0.12, 0)
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
contentLayout.Padding = UDim.new(0, 8)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder

local order = 0
local function nextOrder() order = order + 1 return order end

local function createSection(text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 28)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = clr.textSecondary
    label.TextSize = 11
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.LayoutOrder = nextOrder()
    label.Parent = contentScroll
    return label
end

local function createToggle(text, defaultValue, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 52)
    frame.BackgroundColor3 = clr.surface
    frame.LayoutOrder = nextOrder()
    frame.Parent = contentScroll
    createCorner(frame, 10)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -80, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = clr.textPrimary
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local toggle = Instance.new("Frame")
    toggle.Size = UDim2.new(0, 52, 0, 30)
    toggle.Position = UDim2.new(1, -66, 0.5, -15)
    toggle.BackgroundColor3 = defaultValue and clr.accent or clr.bgSecondary
    toggle.Parent = frame
    createCorner(toggle, 15)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 26, 0, 26)
    knob.Position = defaultValue and UDim2.new(1, -28, 0.5, -13) or UDim2.new(0, 2, 0.5, -13)
    knob.BackgroundColor3 = clr.textPrimary
    knob.Parent = toggle
    createCorner(knob, 13)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = frame

    local isOn = defaultValue
    btn.MouseButton1Click:Connect(function()
        isOn = not isOn
        toggle.BackgroundColor3 = isOn and clr.accent or clr.bgSecondary
        knob.Position = isOn and UDim2.new(1, -28, 0.5, -13) or UDim2.new(0, 2, 0.5, -13)
        if callback then callback(isOn) end
    end)
    return frame
end

local function createButton(text, callback, isPrimary)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 46)
    btn.BackgroundColor3 = isPrimary and clr.accent or clr.surface
    btn.Text = text
    btn.TextColor3 = clr.textPrimary
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.LayoutOrder = nextOrder()
    btn.Parent = contentScroll
    createCorner(btn, 10)
    btn.MouseButton1Click:Connect(function() if callback then callback() end end)
    return btn
end

local function createDropdown(labelText, options, defaultValue, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 80)
    frame.BackgroundColor3 = clr.surface
    frame.LayoutOrder = nextOrder()
    frame.Parent = contentScroll
    createCorner(frame, 10)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -16, 0, 22)
    label.Position = UDim2.new(0, 14, 0, 6)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = clr.textPrimary
    label.TextSize = 12
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local dropBtn = Instance.new("TextButton")
    dropBtn.Size = UDim2.new(1, -28, 0, 38)
    dropBtn.Position = UDim2.new(0, 14, 0, 32)
    dropBtn.BackgroundColor3 = clr.bgSecondary
    dropBtn.Text = "  " .. defaultValue .. "  ▼"
    dropBtn.TextColor3 = clr.textPrimary
    dropBtn.TextSize = 12
    dropBtn.Font = Enum.Font.Gotham
    dropBtn.TextXAlignment = Enum.TextXAlignment.Left
    dropBtn.Parent = frame
    createCorner(dropBtn, 8)

    local idx = 1
    for i, opt in ipairs(options) do if opt == defaultValue then idx = i break end end
    dropBtn.MouseButton1Click:Connect(function()
        idx = idx % #options + 1
        local v = options[idx]
        dropBtn.Text = "  " .. v .. "  ▼"
        if callback then callback(v) end
    end)
    return frame, dropBtn
end

local function createInput(labelText, placeholder, defaultValue, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 80)
    frame.BackgroundColor3 = clr.surface
    frame.LayoutOrder = nextOrder()
    frame.Parent = contentScroll
    createCorner(frame, 10)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -16, 0, 22)
    label.Position = UDim2.new(0, 14, 0, 6)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = clr.textPrimary
    label.TextSize = 12
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -28, 0, 38)
    input.Position = UDim2.new(0, 14, 0, 32)
    input.BackgroundColor3 = clr.bgSecondary
    input.Text = defaultValue or ""
    input.PlaceholderText = placeholder or ""
    input.TextColor3 = clr.textPrimary
    input.PlaceholderColor3 = clr.textSecondary
    input.TextSize = 12
    input.Font = Enum.Font.Gotham
    input.ClearTextOnFocus = false
    input.Parent = frame
    createCorner(input, 8)

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.Parent = input

    input.FocusLost:Connect(function() if callback then callback(input.Text) end end)
    return frame, input
end

local function createSlider(text, minVal, maxVal, defaultValue, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 65)
    frame.BackgroundColor3 = clr.surface
    frame.LayoutOrder = nextOrder()
    frame.Parent = contentScroll
    createCorner(frame, 10)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -55, 0, 22)
    label.Position = UDim2.new(0, 14, 0, 6)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = clr.textPrimary
    label.TextSize = 12
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 45, 0, 22)
    valueLabel.Position = UDim2.new(1, -55, 0, 6)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(defaultValue)
    valueLabel.TextColor3 = clr.accent
    valueLabel.TextSize = 12
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Parent = frame

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -28, 0, 8)
    track.Position = UDim2.new(0, 14, 0, 44)
    track.BackgroundColor3 = clr.bgSecondary
    track.Parent = frame
    createCorner(track, 4)

    local pct = (defaultValue - minVal) / (maxVal - minVal)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = clr.accent
    fill.Parent = track
    createCorner(fill, 4)

    local dragging = false
    local function update(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = minVal + rel * (maxVal - minVal)
        if maxVal <= 1 then val = math.floor(val * 100) / 100 else val = math.floor(val) end
        valueLabel.Text = tostring(val)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        if callback then callback(val) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true update(input.Position.X)
        end
    end)
    track.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    addConnection(uis.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then update(input.Position.X) end
    end), "slider_" .. text:gsub("%s", "_"))
    return frame
end

local statusTitle, statusSub, statusDotBig

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

local statusCard = Instance.new("Frame")
statusCard.Size = UDim2.new(1, 0, 0, 70)
statusCard.BackgroundColor3 = clr.surface
statusCard.LayoutOrder = nextOrder()
statusCard.Parent = contentScroll
createCorner(statusCard, 10)

statusTitle = Instance.new("TextLabel")
statusTitle.Size = UDim2.new(1, -50, 0, 26)
statusTitle.Position = UDim2.new(0, 14, 0, 12)
statusTitle.BackgroundTransparency = 1
statusTitle.Text = "Status: Inactive"
statusTitle.TextColor3 = clr.textPrimary
statusTitle.TextSize = 15
statusTitle.Font = Enum.Font.GothamBold
statusTitle.TextXAlignment = Enum.TextXAlignment.Left
statusTitle.Parent = statusCard

statusSub = Instance.new("TextLabel")
statusSub.Size = UDim2.new(1, -50, 0, 18)
statusSub.Position = UDim2.new(0, 14, 0, 38)
statusSub.BackgroundTransparency = 1
statusSub.Text = "Toggle to enable"
statusSub.TextColor3 = clr.textSecondary
statusSub.TextSize = 11
statusSub.Font = Enum.Font.Gotham
statusSub.TextXAlignment = Enum.TextXAlignment.Left
statusSub.Parent = statusCard

statusDotBig = Instance.new("Frame")
statusDotBig.Size = UDim2.new(0, 14, 0, 14)
statusDotBig.Position = UDim2.new(1, -32, 0.5, -7)
statusDotBig.BackgroundColor3 = clr.error
statusDotBig.Parent = statusCard
createCorner(statusDotBig, 7)

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

local modelResultLabel

local _, modelInput = createInput("Custom Model", "e.g. gpt-4o-mini, claude-3-haiku...", getgenv().MapleConfig.Model, function(v)
    getgenv().MapleConfig.Model = v
    saveConfig()
end)

local function testModel(modelName)
    if not httpRequest then return false, "NO_HTTP", 0 end
    if SHARED_API_KEY == "" or SHARED_API_KEY == "YOUR_API_KEY_HERE" then return false, "NO_KEY", 0 end
    
    local startTime = tick()
    local body = {
        model = modelName,
        messages = {{role = "user", content = "Hi"}},
        max_tokens = 5,
    }
    
    local ok, result = pcall(function()
        return httpRequest({
            Url = API_BASE .. "/chat/completions",
            Method = "POST",
            Headers = {
                ["Authorization"] = "Bearer " .. SHARED_API_KEY,
                ["Content-Type"] = "application/json"
            },
            Body = http:JSONEncode(body)
        })
    end)
    
    local elapsed = tick() - startTime
    
    if not ok or not result then return false, "REQUEST_FAILED", elapsed end
    
    local statusCode = result.StatusCode or 0
    if statusCode == 401 then return false, "INVALID_KEY", elapsed end
    if statusCode == 404 then return false, "MODEL_NOT_FOUND", elapsed end
    if statusCode == 429 then return false, "RATE_LIMITED", elapsed end
    if statusCode >= 400 then return false, "ERROR_" .. statusCode, elapsed end
    
    if result.Body then
        local decodeOk, data = pcall(function() return http:JSONDecode(result.Body) end)
        if decodeOk and data then
            if data.error then return false, data.error.message or "API_ERROR", elapsed end
            if data.choices and #data.choices > 0 then return true, "OK", elapsed end
        end
    end
    
    return false, "UNKNOWN", elapsed
end

local testBtn = createButton("Test Model", function()
    local model = modelInput.Text:gsub("^%s+", ""):gsub("%s+$", "")
    if model == "" then
        modelResultLabel.Text = "Enter a model name first"
        modelResultLabel.TextColor3 = clr.warning
        return
    end
    
    modelResultLabel.Text = "Testing..."
    modelResultLabel.TextColor3 = clr.textSecondary
    
    task.spawn(function()
        local valid, reason, elapsed = testModel(model)
        local timeStr = string.format("%.2fs", elapsed)
        
        if valid then
            modelResultLabel.Text = "✓ Model works! (" .. timeStr .. ")"
            modelResultLabel.TextColor3 = clr.success
            getgenv().MapleConfig.Model = model
            saveConfig()
        else
            modelResultLabel.Text = "✗ Failed: " .. reason .. " (" .. timeStr .. ")"
            modelResultLabel.TextColor3 = clr.error
        end
    end)
end, true)

modelResultLabel = Instance.new("TextLabel")
modelResultLabel.Size = UDim2.new(1, 0, 0, 24)
modelResultLabel.BackgroundTransparency = 1
modelResultLabel.Text = "Type a model name and tap Test"
modelResultLabel.TextColor3 = clr.textSecondary
modelResultLabel.TextSize = 11
modelResultLabel.Font = Enum.Font.Gotham
modelResultLabel.LayoutOrder = nextOrder()
modelResultLabel.Parent = contentScroll

createSlider("Max Tokens", 50, 500, getgenv().MapleConfig.MaxTokens, function(v)
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
infoLabel.Size = UDim2.new(1, 0, 0, 50)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = string.format("v%s | %s\nMsgs: 0 | API: 0 | Err: 0", SCRIPT_VERSION, ExecutorInfo.name)
infoLabel.TextColor3 = clr.textSecondary
infoLabel.TextSize = 10
infoLabel.Font = Enum.Font.Gotham
infoLabel.LayoutOrder = nextOrder()
infoLabel.Parent = contentScroll

task.spawn(function()
    while gui.Parent do
        task.wait(2)
        infoLabel.Text = string.format("v%s | %s\nMsgs: %d | API: %d | Err: %d", 
            SCRIPT_VERSION, ExecutorInfo.name, stats.messagesReceived, stats.apiCalls, stats.errors)
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
    if defaultChat then sayRemote = defaultChat:FindFirstChild("SayMessageRequest") end
end)

local function sendMessage(message)
    if not message or message == "" then return false end
    if #message > MAX_MSG_LENGTH then message = message:sub(1, MAX_MSG_LENGTH - 3) .. "..." end
    local success = false
    pcall(function()
        if tcs and tcs.TextChannels then
            local channel = tcs.TextChannels:FindFirstChild("RBXGeneral")
            if channel then channel:SendAsync(message) success = true end
        end
    end)
    if not success and sayRemote then
        pcall(function() sayRemote:FireServer(message, "All") success = true end)
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
    for _, e in ipairs(spamTracker[uid]) do if e.msg == message then count = count + 1 end end
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
    while #mem.msgs > MAX_MEMORY_SIZE do table.remove(mem.msgs, 1) end
end

local function buildMessages(player, currentMsg)
    local cfg = getgenv().MapleConfig
    local mem = getMemory(player)
    local messages = {}
    
    local sys = cfg.Persona .. " Player:" .. player.DisplayName .. " <200chars no markdown"
    table.insert(messages, {role = "system", content = sys})
    
    local windowSize = math.min(cfg.ContextWindowSize or 3, 5)
    local start = math.max(1, #mem.msgs - windowSize + 1)
    for i = start, #mem.msgs do
        local m = mem.msgs[i]
        local content = m.content
        if #content > 100 then content = content:sub(1, 97) .. "..." end
        table.insert(messages, {role = m.role, content = content})
    end
    
    if #currentMsg > 150 then currentMsg = currentMsg:sub(1, 147) .. "..." end
    table.insert(messages, {role = "user", content = currentMsg})
    return messages
end

local function makeRequest(messages)
    local cfg = getgenv().MapleConfig
    
    if not httpRequest then return nil, "NO_HTTP" end
    if SHARED_API_KEY == "" or SHARED_API_KEY == "YOUR_API_KEY_HERE" then return nil, "NO_KEY" end
    if not messages or #messages == 0 then return nil, "NO_MESSAGES" end
    
    local now = tick()
    if now > rateLimitTracker.resetTime then
        rateLimitTracker.count = 0
        rateLimitTracker.resetTime = now + 60
    end
    if rateLimitTracker.count >= 30 then return nil, "LOCAL_RATE_LIMIT" end
    rateLimitTracker.count = rateLimitTracker.count + 1
    stats.apiCalls = stats.apiCalls + 1
    
    local maxTok = cfg.MaxTokens or 80
    
    local body = {
        model = cfg.Model or "gpt-4o-mini",
        messages = messages,
        max_tokens = maxTok,
        temperature = cfg.Temperature or 0.5,
    }
    
    local ok, result = pcall(function()
        return httpRequest({
            Url = API_BASE .. "/chat/completions",
            Method = "POST",
            Headers = {
                ["Authorization"] = "Bearer " .. SHARED_API_KEY,
                ["Content-Type"] = "application/json"
            },
            Body = http:JSONEncode(body)
        })
    end)
    
    if not ok or not result or not result.Body then return nil, "REQUEST_FAILED" end
    
    local decodeOk, data = pcall(function() return http:JSONDecode(result.Body) end)
    if not decodeOk or not data then return nil, "PARSE_ERROR" end
    if data.error then return nil, data.error.message or "API_ERROR" end
    if data.choices and data.choices[1] and data.choices[1].message then
        return data.choices[1].message.content, nil
    end
    return nil, "NO_RESPONSE"
end

local function processMsg(player, message)
    local cfg = getgenv().MapleConfig
    stats.messagesReceived = stats.messagesReceived + 1
    
    if cfg.AFKMode then
        task.wait(cfg.ResponseDelay or 0.1)
        sendMessage(cfg.AFKMessage)
        stats.responsesSent = stats.responsesSent + 1
        return
    end
    
    if not message or message == "" then return end
    message = message:gsub("^%s+", ""):gsub("%s+$", "")
    if #message == 0 then return end
    
    local cached = checkCache(message)
    if cached then
        addToMemory(player, message, "user")
        addToMemory(player, cached, "assistant")
        task.wait(cfg.ResponseDelay or 0.1)
        sendMessage(cached)
        stats.responsesSent = stats.responsesSent + 1
        return
    end
    
    local msgs = buildMessages(player, message)
    local resp, err = makeRequest(msgs)
    
    if err then
        stats.errors = stats.errors + 1
        return
    end
    
    if resp then
        resp = tostring(resp):gsub("^%s+", ""):gsub("%s+$", ""):gsub("\n+", " "):gsub("%s+", " ")
        resp = resp:gsub("[%*#`]", "")
        if #resp == 0 then return end
        if #resp > MAX_MSG_LENGTH then resp = resp:sub(1, MAX_MSG_LENGTH - 3) .. "..." end
        
        addToMemory(player, message, "user")
        addToMemory(player, resp, "assistant")
        addToCache(message, resp)
        
        task.wait(cfg.ResponseDelay or 0.1)
        if sendMessage(resp) then stats.responsesSent = stats.responsesSent + 1
        else stats.errors = stats.errors + 1 end
    end
end

local function onChat(player, message)
    local cfg = getgenv().MapleConfig
    if not cfg.MasterEnabled then return end
    if player == lp then return end
    if table.find(cfg.Blacklist, player.Name) or table.find(cfg.Blacklist, player.DisplayName) then return end
    if cfg.Range > 0 and getPlayerDistance(player.Character) > cfg.Range then return end
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

if not success then warn("[Maple AI] Error: " .. tostring(errorMsg)) end
return success
