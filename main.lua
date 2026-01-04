local success, errorMsg = pcall(function()
local ts = game:GetService("TweenService")
local uis = game:GetService("UserInputService")
local plrs = game:GetService("Players")
local http = game:GetService("HttpService")
local rs = game:GetService("ReplicatedStorage")
local tcs = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local lp = plrs.LocalPlayer
local SCRIPT_VERSION = "8.0.0"
local API_KEY = "sk-mapleai-g9JF2sCNtm4WdiLdtJwLpA4rD4cLimI5fhiLXnvFJ210gAWH2eweqogs94ycvGDfwc9e4aTvKHNbcdNW"
local API_BASE = "https://api.mapleai.de/v1"
local ExecutorInfo = {name = "Unknown", version = "Unknown"}
pcall(function() if identifyexecutor then local n,v = identifyexecutor() ExecutorInfo.name = n or "Unknown" ExecutorInfo.version = v or "Unknown" elseif getexecutorname then ExecutorInfo.name = getexecutorname() end end)
local cfgFile = "MapleAI_Advanced.json"
local defCfg = {
    MasterEnabled = false,
    Persona = "Brief Roblox AI. Max 1-2 sentences.",
    Models = {
        Chat = "deepseek-r1-0528",
        Pathfinding = "gpt-4o-mini",
        Combat = "gpt-4o-mini",
        NPC = "deepseek-r1-0528",
        Supervisor = "gpt-4o",
        Fallback = "gpt-3.5-turbo"
    },
    Blacklist = {},
    Whitelist = {},
    DebugMode = false,
    Range = 0,
    TriggerMode = "smart",
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
    ResponseLength = "medium",
    IgnoreWords = {},
    AutoGreet = false,
    AutoGreetMessage = "Hey {player}! Welcome!",
    HumanTyping = false,
    TypingSpeed = 0.05,
    EnableSupervisor = false,
    RotationSpeed = 5,
    LogToChat = true,
}
getgenv().MapleConfig = getgenv().MapleConfig or {}
for k,v in pairs(defCfg) do if getgenv().MapleConfig[k] == nil then getgenv().MapleConfig[k] = v end end
local clr = {
    accent = Color3.fromRGB(147,112,219),
    bg = Color3.fromRGB(28,28,30),
    bgSecondary = Color3.fromRGB(44,44,46),
    surface = Color3.fromRGB(38,38,40),
    textPrimary = Color3.fromRGB(255,255,255),
    textSecondary = Color3.fromRGB(174,174,178),
    success = Color3.fromRGB(52,199,89),
    warning = Color3.fromRGB(255,159,10),
    error = Color3.fromRGB(255,69,58),
    info = Color3.fromRGB(10,132,255),
}
local MAX_MSG_LENGTH = 200
local CACHE_TTL = 300
local MAX_MEMORY_SIZE = 20
local MAX_CHAT_HISTORY = 50
local processing = false
local playerMemory = {}
local knownPlayers = {}
local spamTracker = {}
local responseCache = {}
local cacheOrder = {}
local recentlySent = {}
local lastSentTime = 0
local processedMessages = {}
local stats = {messagesReceived = 0, responsesSent = 0, errors = 0, cacheHits = 0, apiCalls = 0}
local connections = {}
local chatHistory = {}
local systemLogs = {}
local MAX_SYSTEM_LOGS = 100
local function displaySystemMessage(message)
    pcall(function()
        local starterGui = game:GetService("StarterGui")
        starterGui:SetCore("ChatMakeSystemMessage", {
            Text = message,
            Color = Color3.fromRGB(147, 112, 219),
            Font = Enum.Font.GothamBold,
            TextSize = 14
        })
    end)
end
local function aiLog(category, message)
    local prefix = "[AI ~ " .. category .. "]"
    local fullMsg = prefix .. " " .. message
    table.insert(systemLogs, {category = category, msg = message, full = fullMsg, time = tick()})
    while #systemLogs > MAX_SYSTEM_LOGS do table.remove(systemLogs, 1) end
    print(fullMsg)
    if getgenv().MapleConfig.LogToChat then
        displaySystemMessage(fullMsg)
    end
end
local function addConnection(conn, name)
    if conn then
        if name and connections[name] then pcall(function() connections[name]:Disconnect() end) end
        connections[name or (#connections + 1)] = conn
    end
end
local function saveConfig()
    pcall(function() if writefile then writefile(cfgFile, http:JSONEncode(getgenv().MapleConfig)) end end)
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
local function setSetting(key, value, category)
    getgenv().MapleConfig[key] = value
    saveConfig()
    local cat = category or "Settings"
    if type(value) == "boolean" then
        aiLog(cat, key .. " " .. (value and "Enabled" or "Disabled"))
    else
        aiLog(cat, "Changed " .. key .. " to \"" .. tostring(value) .. "\"")
    end
end
local function setModel(agentType, modelName)
    getgenv().MapleConfig.Models[agentType] = modelName
    saveConfig()
    aiLog("Model Settings", "Changed " .. agentType .. " Model to \"" .. modelName .. "\"")
end
local httpRequest = request or http_request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request)
if not httpRequest then warn("[Maple] No HTTP function!") end
local AIAgents = {}
local function createAgent(name, model, purpose)
    AIAgents[name] = {name = name, model = model, purpose = purpose, history = {}, lastUsed = 0}
    return AIAgents[name]
end
local function agentRequest(agentName, messages, callback)
    local agent = AIAgents[agentName]
    if not agent then
        aiLog("Error", "Agent not found: " .. agentName)
        if callback then callback(nil, "Agent not found") end
        return
    end
    local model = getgenv().MapleConfig.Models[agent.name] or agent.model
    stats.apiCalls = stats.apiCalls + 1
    agent.lastUsed = tick()
    local body = {
        model = model,
        messages = messages,
        max_tokens = getgenv().MapleConfig.MaxTokens or 80,
        temperature = getgenv().MapleConfig.Temperature or 0.5
    }
    task.spawn(function()
        local ok, result = pcall(function()
            return httpRequest({
                Url = API_BASE .. "/chat/completions",
                Method = "POST",
                Headers = {["Authorization"] = "Bearer " .. API_KEY, ["Content-Type"] = "application/json"},
                Body = http:JSONEncode(body)
            })
        end)
        if not ok or not result or not result.Body then
            stats.errors = stats.errors + 1
            aiLog("Error", agent.name .. " request failed")
            if callback then callback(nil, "Request failed") end
            return
        end
        local decodeOk, data = pcall(function() return http:JSONDecode(result.Body) end)
        if not decodeOk or not data then
            if callback then callback(nil, "Parse error") end
            return
        end
        if data.error then
            aiLog("Error", agent.name .. ": " .. (data.error.message or "API Error"))
            if callback then callback(nil, data.error.message) end
            return
        end
        if data.choices and data.choices[1] and data.choices[1].message then
            local response = data.choices[1].message.content
            if callback then callback(response, nil) end
        else
            if callback then callback(nil, "No response") end
        end
    end)
end
createAgent("Chat", "deepseek-r1-0528", "Main conversation")

-- Optional AI agents (can be disabled in config)
if getgenv().MapleConfig.EnablePathfinding ~= false then
    createAgent("Pathfinding", "gpt-4o-mini", "Navigation")
end
if getgenv().MapleConfig.EnableCombat ~= false then
    createAgent("Combat", "gpt-4o-mini", "Combat strategy")
end
if getgenv().MapleConfig.EnableNPC ~= false then
    createAgent("NPC", "deepseek-r1-0528", "NPC dialogue")
end
createAgent("Supervisor", "gpt-4o", "Content moderation")
local PathfindingAI = {currentPath = nil, isNavigating = false}
function PathfindingAI:createPath(character, targetPos, callback)
    if not character then aiLog("Pathfinding", "No character") return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then aiLog("Pathfinding", "No HumanoidRootPart") return end
    aiLog("Pathfinding", "Computing path...")
    local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 4})
    local ok, err = pcall(function() path:ComputeAsync(hrp.Position, targetPos) end)
    if not ok then
        aiLog("Pathfinding", "Error: " .. tostring(err))
        if callback then callback(nil, err) end
        return
    end
    if path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        self.currentPath = waypoints
        aiLog("Pathfinding", "Path created: " .. #waypoints .. " waypoints")
        if callback then callback(waypoints, nil) end
    else
        aiLog("Pathfinding", "No path found")
        if callback then callback(nil, "No path") end
    end
end
function PathfindingAI:followPath(character, waypoints, callback)
    if not waypoints or #waypoints == 0 then return end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    self.isNavigating = true
    aiLog("Pathfinding", "Following path...")
    task.spawn(function()
        for i, wp in ipairs(waypoints) do
            if not self.isNavigating then break end
            if wp.Action == Enum.PathWaypointAction.Jump then humanoid.Jump = true end
            humanoid:MoveTo(wp.Position)
            humanoid.MoveToFinished:Wait()
        end
        self.isNavigating = false
        aiLog("Pathfinding", "Navigation complete")
        if callback then callback(true) end
    end)
end
function PathfindingAI:stop()
    self.isNavigating = false
    self.currentPath = nil
    aiLog("Pathfinding", "Stopped")
end
function PathfindingAI:pathToPlayer(character, targetPlayer, callback)
    if not targetPlayer or not targetPlayer.Character then
        aiLog("Pathfinding", "Invalid target")
        return
    end
    local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end
    aiLog("Pathfinding", "Pathing to " .. targetPlayer.DisplayName)
    self:createPath(character, targetHRP.Position, function(waypoints, err)
        if waypoints then
            self:followPath(character, waypoints, callback)
        elseif callback then
            callback(nil, err)
        end
    end)
end
function PathfindingAI:rotateToFace(character, targetPos, instant)
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local dir = (targetPos - hrp.Position)
    dir = Vector3.new(dir.X, 0, dir.Z)
    if dir.Magnitude < 0.1 then return end
    dir = dir.Unit
    local targetCF = CFrame.lookAt(hrp.Position, hrp.Position + dir)
    if instant then
        hrp.CFrame = targetCF
        aiLog("Rotation", "Facing target (instant)")
    else
        aiLog("Rotation", "Rotating to target...")
        task.spawn(function()
            local startCF = hrp.CFrame
            local alpha = 0
            local speed = getgenv().MapleConfig.RotationSpeed or 5
            while alpha < 1 do
                alpha = math.min(1, alpha + speed * RunService.Heartbeat:Wait())
                hrp.CFrame = startCF:Lerp(targetCF, alpha)
            end
            aiLog("Rotation", "Complete")
        end)
    end
end
local CombatAI = {target = nil, threats = {}}
function CombatAI:findThreats(character, radius)
    radius = radius or 50
    self.threats = {}
    if not character then return self.threats end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return self.threats end
    for _, player in ipairs(plrs:GetPlayers()) do
        if player ~= lp and player.Character then
            local tHRP = player.Character:FindFirstChild("HumanoidRootPart")
            local tHum = player.Character:FindFirstChild("Humanoid")
            if tHRP and tHum and tHum.Health > 0 then
                local dist = (tHRP.Position - hrp.Position).Magnitude
                if dist <= radius then
                    table.insert(self.threats, {player = player, distance = dist, health = tHum.Health})
                end
            end
        end
    end
    table.sort(self.threats, function(a, b) return a.distance < b.distance end)
    aiLog("Combat", "Found " .. #self.threats .. " threats")
    return self.threats
end
function CombatAI:selectTarget()
    if #self.threats == 0 then
        self.target = nil
        aiLog("Combat", "No targets available")
        return nil
    end
    self.target = self.threats[1].player
    aiLog("Combat", "Target: " .. self.target.DisplayName .. " (" .. math.floor(self.threats[1].distance) .. " studs)")
    return self.threats[1]
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
local fabDragging, fabDragStart, fabStartPos, fabMoved = false, nil, nil, false
fabButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        fabDragging, fabMoved = true, false
        fabDragStart = input.Position
        fabStartPos = fab.Position
    end
end)
fabButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        fabDragging = false
    end
end)
addConnection(uis.InputChanged:Connect(function(input)
    if fabDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - fabDragStart
        if delta.Magnitude > 15 then fabMoved = true end
        fab.Position = UDim2.new(fabStartPos.X.Scale, fabStartPos.X.Offset + delta.X, fabStartPos.Y.Scale, fabStartPos.Y.Offset + delta.Y)
    end
end), "fabDrag")
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
fabButton.Activated:Connect(function()
    if not fabMoved then mainWindow.Visible = not mainWindow.Visible end
end)
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
titleText.Text = "Maple AI v" .. SCRIPT_VERSION
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
closeBtn.MouseButton1Click:Connect(function() mainWindow.Visible = false end)
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
local function createToggle(text, key, callback)
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
    local defaultValue = getgenv().MapleConfig[key]
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
        setSetting(key, isOn, "Settings")
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
local function createDropdown(labelText, options, key, callback)
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
    local defaultValue = getgenv().MapleConfig[key]
    local dropBtn = Instance.new("TextButton")
    dropBtn.Size = UDim2.new(1, -28, 0, 38)
    dropBtn.Position = UDim2.new(0, 14, 0, 32)
    dropBtn.BackgroundColor3 = clr.bgSecondary
    dropBtn.Text = "  " .. tostring(defaultValue) .. "  ▼"
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
        setSetting(key, v, "Settings")
        if callback then callback(v) end
    end)
    return frame, dropBtn
end
local function createModelDropdown(labelText, agentType, options)
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
    local defaultValue = getgenv().MapleConfig.Models[agentType]
    local dropBtn = Instance.new("TextButton")
    dropBtn.Size = UDim2.new(1, -28, 0, 38)
    dropBtn.Position = UDim2.new(0, 14, 0, 32)
    dropBtn.BackgroundColor3 = clr.bgSecondary
    dropBtn.Text = "  " .. tostring(defaultValue) .. "  ▼"
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
        setModel(agentType, v)
    end)
    return frame
end
local function createInput(labelText, placeholder, key, callback)
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
    local defaultValue = key and getgenv().MapleConfig[key] or ""
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -28, 0, 38)
    input.Position = UDim2.new(0, 14, 0, 32)
    input.BackgroundColor3 = clr.bgSecondary
    input.Text = tostring(defaultValue or "")
    input.PlaceholderText = placeholder or ""
    input.TextColor3 = clr.textPrimary
    input.PlaceholderColor3 = clr.textSecondary
    input.TextSize = 12
    input.Font = Enum.Font.Gotham
    input.ClearTextOnFocus = false
    input.Parent = frame
    createCorner(input, 8)
    input.FocusLost:Connect(function()
        if key then setSetting(key, input.Text, "Settings") end
        if callback then callback(input.Text) end
    end)
    return frame, input
end
local function createSlider(text, minVal, maxVal, key, callback)
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
    local defaultValue = getgenv().MapleConfig[key] or minVal
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
    local lastVal = defaultValue
    local function update(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = minVal + rel * (maxVal - minVal)
        if maxVal <= 1 then val = math.floor(val * 100) / 100 else val = math.floor(val) end
        valueLabel.Text = tostring(val)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        getgenv().MapleConfig[key] = val
        lastVal = val
        if callback then callback(val) end
    end
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(input.Position.X)
        end
    end)
    track.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            saveConfig()
            aiLog("Settings", "Changed " .. key .. " to \"" .. tostring(lastVal) .. "\"")
        end
    end)
    addConnection(uis.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            update(input.Position.X)
        end
    end), "slider_" .. key)
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
createToggle("Enable AI", "MasterEnabled", updateStatus)
createToggle("AFK Mode", "AFKMode", updateStatus)
createToggle("Log to Chat", "LogToChat")
createToggle("Debug Mode", "DebugMode")
createSection("AI MODELS (Per Agent)")
local modelOptions = {"deepseek-r1-0528", "deepseek-r1", "gpt-4o", "gpt-4o-mini", "gpt-4", "gpt-3.5-turbo", "claude-3-opus", "claude-3-sonnet", "claude-3-haiku"}
createModelDropdown("💬 Chat Agent", "Chat", modelOptions)
createToggle("Enable Pathfinding AI", "EnablePathfinding")
createModelDropdown("🗺️ Pathfinding Agent", "Pathfinding", modelOptions)
createToggle("Enable Combat AI", "EnableCombat")
createModelDropdown("⚔️ Combat Agent", "Combat", modelOptions)
createToggle("Enable NPC AI", "EnableNPC")
createModelDropdown("🎭 NPC Agent", "NPC", modelOptions)
createModelDropdown("🛡️ Supervisor Agent", "Supervisor", modelOptions)
createSection("PATHFINDING")
createButton("Path to Nearest Player", function()
    local char = lp.Character
    if not char then aiLog("Pathfinding", "No character") return end
    local nearest, nearDist = nil, math.huge
    for _, p in ipairs(plrs:GetPlayers()) do
        if p ~= lp and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local myHrp = char:FindFirstChild("HumanoidRootPart")
            if hrp and myHrp then
                local dist = (hrp.Position - myHrp.Position).Magnitude
                if dist < nearDist then nearDist = dist nearest = p end
            end
        end
    end
    if nearest then
        PathfindingAI:pathToPlayer(char, nearest)
    else
        aiLog("Pathfinding", "No players found")
    end
end, true)
createButton("Stop Navigation", function() PathfindingAI:stop() end)
createButton("Face Nearest Player", function()
    local char = lp.Character
    if not char then return end
    local nearest, nearDist = nil, math.huge
    for _, p in ipairs(plrs:GetPlayers()) do
        if p ~= lp and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local myHrp = char:FindFirstChild("HumanoidRootPart")
            if hrp and myHrp then
                local dist = (hrp.Position - myHrp.Position).Magnitude
                if dist < nearDist then nearDist = dist nearest = p end
            end
        end
    end
    if nearest and nearest.Character then
        local targetHrp = nearest.Character:FindFirstChild("HumanoidRootPart")
        if targetHrp then PathfindingAI:rotateToFace(char, targetHrp.Position, false) end
    end
end)
createSlider("Rotation Speed", 1, 20, "RotationSpeed")
createSection("COMBAT")
createButton("Scan Threats", function()
    local char = lp.Character
    if char then CombatAI:findThreats(char, 100) end
end)
createButton("Select Target", function()
    local char = lp.Character
    if char then
        CombatAI:findThreats(char, 100)
        CombatAI:selectTarget()
    end
end)
createSection("CHAT SETTINGS")
createDropdown("Trigger Mode", {"smart", "all", "mention", "prefix", "whitelist"}, "TriggerMode")
createDropdown("Response Length", {"short", "medium", "long"}, "ResponseLength")
createSlider("Range (0=∞)", 0, 500, "Range")
createSlider("Response Delay", 0.1, 5, "ResponseDelay")
createSlider("Max Tokens", 50, 500, "MaxTokens")
createSlider("Temperature", 0, 1, "Temperature")
createSection("BEHAVIOR")
createToggle("Human Typing", "HumanTyping")
createSlider("Typing Speed", 0.01, 0.15, "TypingSpeed")
createToggle("Auto Greet", "AutoGreet")
createInput("Greet Message", "{player} = name", "AutoGreetMessage")
createSection("PERSONA")
createInput("AI Persona", "How AI behaves...", "Persona")
createButton("Preset: Helpful", function() setSetting("Persona", "You are a helpful AI in Roblox. Be friendly and brief. Max 2 sentences.", "Persona") end)
createButton("Preset: Casual", function() setSetting("Persona", "You are a chill gamer. Use casual language and gaming slang. Keep it short!", "Persona") end)
createButton("Preset: Sarcastic", function() setSetting("Persona", "You are sarcastic but helpful. Use wit and humor. Still answer helpfully.", "Persona") end)
createSection("MEMORY")
createButton("Clear All Memory", function()
    playerMemory = {}
    responseCache = {}
    cacheOrder = {}
    aiLog("Memory", "All memory cleared")
end, true)
createSection("INFO")
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, 0, 0, 60)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = string.format("v%s | %s", SCRIPT_VERSION, ExecutorInfo.name)
infoLabel.TextColor3 = clr.textSecondary
infoLabel.TextSize = 10
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextWrapped = true
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
local sayRemote = nil
pcall(function()
    local defaultChat = rs:FindFirstChild("DefaultChatSystemChatEvents")
    if defaultChat then sayRemote = defaultChat:FindFirstChild("SayMessageRequest") end
end)
local function sendMessageRaw(message)
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
local function sendMessage(message)
    if not message or message == "" then return false end
    if #message > MAX_MSG_LENGTH then message = message:sub(1, MAX_MSG_LENGTH - 3) .. "..." end
    table.insert(recentlySent, {msg = message:lower(), time = tick()})
    while #recentlySent > 20 do table.remove(recentlySent, 1) end
    lastSentTime = tick()
    table.insert(chatHistory, {player = "You", msg = message, isMe = true, time = tick()})
    while #chatHistory > MAX_CHAT_HISTORY do table.remove(chatHistory, 1) end
    if getgenv().MapleConfig.HumanTyping then
        local totalDelay = math.min(#message * (getgenv().MapleConfig.TypingSpeed or 0.05), 3)
        task.wait(totalDelay)
    end
    return sendMessageRaw(message)
end
local function getPlayerDistance(character)
    if not character then return 999999 end
    local myChar = lp.Character
    if not myChar then return 999999 end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    local theirRoot = character:FindFirstChild("HumanoidRootPart")
    if not myRoot or not theirRoot then return 999999 end
    local dx = theirRoot.Position.X - myRoot.Position.X
    local dz = theirRoot.Position.Z - myRoot.Position.Z
    return math.sqrt(dx * dx + dz * dz)
end
local function isPlayerLookingAtMe(player)
    local myChar = lp.Character
    local theirChar = player.Character
    if not myChar or not theirChar then return false, 0 end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    local theirRoot = theirChar:FindFirstChild("HumanoidRootPart")
    if not myRoot or not theirRoot then return false, 0 end
    local toMe = (myRoot.Position - theirRoot.Position).Unit
    local theirLook = theirRoot.CFrame.LookVector
    local dot = toMe:Dot(theirLook)
    return dot > 0.5, dot
end
local function updateKnownPlayers()
    knownPlayers = {}
    for _, player in ipairs(plrs:GetPlayers()) do
        knownPlayers[tostring(player.UserId)] = {name = player.Name, displayName = player.DisplayName, isLocal = (player == lp)}
    end
end
local function getKnownPlayersList()
    local list = {}
    for uid, info in pairs(knownPlayers) do
        if not info.isLocal then table.insert(list, info.displayName) end
    end
    return list
end
updateKnownPlayers()
addConnection(plrs.PlayerAdded:Connect(function(player)
    knownPlayers[tostring(player.UserId)] = {name = player.Name, displayName = player.DisplayName, isLocal = false}
end), "KnownPlayersAdd")
addConnection(plrs.PlayerRemoving:Connect(function(player)
    knownPlayers[tostring(player.UserId)] = nil
end), "KnownPlayersRemove")
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
local function containsIgnoreWord(message)
    local lower = message:lower()
    for _, word in ipairs(getgenv().MapleConfig.IgnoreWords or {}) do
        if lower:find(word, 1, true) then return true end
    end
    return false
end
local function shouldRespond(player, message)
    local cfg = getgenv().MapleConfig
    local mode = cfg.TriggerMode
    if containsIgnoreWord(message) then return false end
    if mode == "all" then return true end
    if mode == "mention" then
        local lower = message:lower()
        return lower:find("maple") or lower:find(lp.Name:lower()) or lower:find(lp.DisplayName:lower())
    end
    if mode == "prefix" then
        return message:sub(1, #cfg.TriggerPrefix):lower() == cfg.TriggerPrefix:lower()
    end
    if mode == "whitelist" then
        return table.find(cfg.Whitelist, player.Name) or table.find(cfg.Whitelist, player.DisplayName)
    end
    return true
end
local function getCacheKey(msg) return msg:lower():gsub("%s+", " "):gsub("[^%w%s]", "") end
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
    while #cacheOrder >= 100 do
        local oldKey = table.remove(cacheOrder, 1)
        responseCache[oldKey] = nil
    end
    responseCache[key] = {resp = resp, ts = tick()}
    table.insert(cacheOrder, key)
end
local function getMemory(player)
    local uid = tostring(player.UserId)
    if not playerMemory[uid] then
        playerMemory[uid] = {name = player.DisplayName, username = player.Name, msgs = {}, last = tick()}
    end
    return playerMemory[uid]
end
local function addToMemory(player, msg, role)
    local mem = getMemory(player)
    table.insert(mem.msgs, {role = role, content = msg, ts = tick()})
    mem.last = tick()
    while #mem.msgs > MAX_MEMORY_SIZE do table.remove(mem.msgs, 1) end
end
local function buildContextualInfo(player, message)
    local info = {}
    local distance = getPlayerDistance(player.Character)
    local isLooking = isPlayerLookingAtMe(player)
    table.insert(info, "Distance: " .. math.floor(distance))
    table.insert(info, "Looking: " .. (isLooking and "YES" or "no"))
    local msgLower = message:lower()
    if msgLower:find("?") then table.insert(info, "question") end
    if msgLower:find(lp.DisplayName:lower()) then table.insert(info, "name") end
    return table.concat(info, "; ")
end
local function buildMessages(player, currentMsg, smartMode)
    local cfg = getgenv().MapleConfig
    local mem = getMemory(player)
    local messages = {}
    local playerList = getKnownPlayersList()
    local playersStr = #playerList > 0 and table.concat(playerList, ", ") or "none"
    local lengthInstruction = cfg.ResponseLength == "short" and " Under 50 chars." or (cfg.ResponseLength == "long" and " 2-3 sentences ok." or " 1-2 sentences.")
    local smartInstruction = smartMode and (" [SITUATION] " .. buildContextualInfo(player, currentMsg) .. " If not for you, say [IGNORE].") or ""
    local sys = cfg.Persona .. " You are " .. lp.DisplayName .. ". Speaker: " .. player.DisplayName .. ". Players: " .. playersStr .. "." .. smartInstruction .. lengthInstruction .. " No markdown"
    table.insert(messages, {role = "system", content = sys})
    local windowSize = math.min(cfg.ContextWindowSize or 3, 5)
    local start = math.max(1, #mem.msgs - windowSize + 1)
    for i = start, #mem.msgs do
        table.insert(messages, {role = mem.msgs[i].role, content = mem.msgs[i].content:sub(1, 100)})
    end
    table.insert(messages, {role = "user", content = currentMsg:sub(1, 150)})
    return messages
end
local function processMsg(player, message, smartMode)
    local cfg = getgenv().MapleConfig
    stats.messagesReceived = stats.messagesReceived + 1
    aiLog("Chat", "Message from " .. player.DisplayName .. ": " .. message:sub(1, 50))
    if cfg.AFKMode then
        task.wait(cfg.ResponseDelay or 0.1)
        sendMessage(cfg.AFKMessage)
        stats.responsesSent = stats.responsesSent + 1
        return
    end
    if not message or message == "" then return end
    message = message:gsub("^%s+", ""):gsub("%s+$", "")
    if #message == 0 then return end
    if not smartMode then
        local cached = checkCache(message)
        if cached then
            aiLog("Cache", "Using cached response")
            addToMemory(player, message, "user")
            addToMemory(player, cached, "assistant")
            task.wait(cfg.ResponseDelay or 0.1)
            sendMessage(cached)
            stats.responsesSent = stats.responsesSent + 1
            return
        end
    end
    local msgs = buildMessages(player, message, smartMode)
    aiLog("API", "Requesting from Chat agent...")
    agentRequest("Chat", msgs, function(resp, err)
        if err then
            stats.errors = stats.errors + 1
            aiLog("Error", "Chat request failed: " .. tostring(err))
            return
        end
        if resp then
            resp = tostring(resp):gsub("^%s+", ""):gsub("%s+$", ""):gsub("\n+", " "):gsub("%s+", " "):gsub("[%*#`]", "")
            if resp:upper():find("%[IGNORE%]") or resp:upper() == "IGNORE" then
                aiLog("Chat", "Ignored (not directed at me)")
                return
            end
            if #resp == 0 then return end
            if #resp > MAX_MSG_LENGTH then resp = resp:sub(1, MAX_MSG_LENGTH - 3) .. "..." end
            addToMemory(player, message, "user")
            addToMemory(player, resp, "assistant")
            if not smartMode then addToCache(message, resp) end
            task.wait(cfg.ResponseDelay or 0.1)
            if sendMessage(resp) then
                stats.responsesSent = stats.responsesSent + 1
                aiLog("Chat", "Replied: " .. resp:sub(1, 50))
            else
                stats.errors = stats.errors + 1
            end
        end
    end)
end
local function isSelfMessage(message)
    if tick() - lastSentTime < 2 then return true end
    local msgLower = message:lower()
    for i = #recentlySent, 1, -1 do
        local entry = recentlySent[i]
        if tick() - entry.time > 30 then break end
        if entry.msg == msgLower then return true end
        if msgLower:find(entry.msg:sub(1, 30), 1, true) then return true end
    end
    return false
end
local function onChat(player, message)
    local cfg = getgenv().MapleConfig
    if not cfg.MasterEnabled then return end
    if player == lp then return end
    table.insert(chatHistory, {player = player.DisplayName, msg = message, isMe = false, time = tick()})
    while #chatHistory > MAX_CHAT_HISTORY do table.remove(chatHistory, 1) end
    local msgKey = player.UserId .. "_" .. message:sub(1, 50)
    local now = tick()
    if processedMessages[msgKey] and now - processedMessages[msgKey] < 5 then return end
    processedMessages[msgKey] = now
    for key, time in pairs(processedMessages) do
        if now - time > 10 then processedMessages[key] = nil end
    end
    if isSelfMessage(message) then return end
    if table.find(cfg.Blacklist, player.Name) or table.find(cfg.Blacklist, player.DisplayName) then return end
    if cfg.Range > 0 and getPlayerDistance(player.Character) > cfg.Range then return end
    if isSpamming(player, message) then return end
    local smartMode = cfg.TriggerMode == "smart"
    if not smartMode and not shouldRespond(player, message) then return end
    task.spawn(function()
        processing = true
        pcall(function() processMsg(player, message, smartMode) end)
        processing = false
    end)
end
local function greetPlayer(player)
    if not getgenv().MapleConfig.AutoGreet or not getgenv().MapleConfig.MasterEnabled then return end
    if player == lp then return end
    task.delay(2, function()
        local greetMsg = (getgenv().MapleConfig.AutoGreetMessage or "Hey {player}!"):gsub("{player}", player.DisplayName)
        sendMessage(greetMsg)
        aiLog("Chat", "Greeted " .. player.DisplayName)
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
                greetPlayer(player)
            end
        end), "PlayerAdded")
    end)
end
setupListeners()
aiLog("System", "Maple AI v" .. SCRIPT_VERSION .. " loaded!")
aiLog("System", "Agents: Chat, Pathfinding, Combat, NPC, Supervisor")
end)
if not success then warn("[Maple AI] Error: " .. tostring(errorMsg)) end
return success
