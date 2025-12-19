
local success, errorMsg = pcall(function()

local ts = game:GetService("TweenService")
local uis = game:GetService("UserInputService")
local plrs = game:GetService("Players")
local http = game:GetService("HttpService")
local rs = game:GetService("ReplicatedStorage")
local tcs = game:GetService("TextChatService")
local runSvc = game:GetService("RunService")
local marketPlace = game:GetService("MarketplaceService")

local lp = plrs.LocalPlayer

local DISCORD_CONTACT = "@xkroblox"
local SCRIPT_VERSION = "6.0.0"
local BUILD_TYPE = "ULTIMATE"

local SHARED_API_KEY = "YOUR_API_KEY_HERE"

local VIP_USERIDS = {
}

local VIP_HWIDS = {
}

local TIERS = {
    FREE = 0,
    VIP = 1,
    PREMIUM = 2,
    ULTIMATE = 3,
}

local TIER_LIMITS = {
    [0] = {
        requestsPerMinute = 5,
        requestsPerHour = 30,
        requestsPerDay = 100,
        minResponseDelay = 2.0,
        maxResponseDelay = 10.0,
        maxTokens = 100,
        maxTokensConfigurable = false,
        temperatureConfigurable = false,
        contextWindowSize = 5,
        contextWindowConfigurable = false,
        memoryExpireMinutes = 5,
        unlimitedMemory = false,
        cacheEnabled = true,
        cacheSize = 50,
        cacheTTL = 180,
        canChangePersona = false,
        canUsePresets = true,
        canChangeRange = true,
        canChangeTriggerMode = true,
        canUseBlacklist = true,
        canUseWhitelist = false,
        canUseAFKMode = true,
        canUseAntiSpam = true,
        canChangeAntiSpamSettings = false,
        canUseFriendSettings = false,
        canUseDebugMode = false,
        canExportHistory = false,
        canUseWebhooks = false,
        canChangeTheme = false,
        tierName = "FREE",
        tierEmoji = "🆓",
        tierColor = Color3.fromRGB(128, 128, 128),
        showLimitsInUI = true,
    },
    [1] = {
        requestsPerMinute = 15,
        requestsPerHour = 200,
        requestsPerDay = 500,
        minResponseDelay = 1.0,
        maxResponseDelay = 10.0,
        maxTokens = 150,
        maxTokensConfigurable = true,
        maxTokensMax = 200,
        temperatureConfigurable = true,
        contextWindowSize = 15,
        contextWindowConfigurable = true,
        contextWindowMax = 20,
        memoryExpireMinutes = 30,
        unlimitedMemory = false,
        cacheEnabled = true,
        cacheSize = 150,
        cacheTTL = 300,
        canChangePersona = true,
        canUsePresets = true,
        canChangeRange = true,
        canChangeTriggerMode = true,
        canUseBlacklist = true,
        canUseWhitelist = true,
        canUseAFKMode = true,
        canUseAntiSpam = true,
        canChangeAntiSpamSettings = true,
        canUseFriendSettings = true,
        canUseDebugMode = true,
        canExportHistory = false,
        canUseWebhooks = false,
        canChangeTheme = false,
        tierName = "VIP",
        tierEmoji = "🔷",
        tierColor = Color3.fromRGB(0, 191, 255),
        showLimitsInUI = true,
    },
    [2] = {
        requestsPerMinute = 30,
        requestsPerHour = 500,
        requestsPerDay = 2000,
        minResponseDelay = 0.5,
        maxResponseDelay = 10.0,
        maxTokens = 300,
        maxTokensConfigurable = true,
        maxTokensMax = 400,
        temperatureConfigurable = true,
        contextWindowSize = 30,
        contextWindowConfigurable = true,
        contextWindowMax = 50,
        memoryExpireMinutes = 120,
        unlimitedMemory = true,
        cacheEnabled = true,
        cacheSize = 500,
        cacheTTL = 600,
        canChangePersona = true,
        canUsePresets = true,
        canChangeRange = true,
        canChangeTriggerMode = true,
        canUseBlacklist = true,
        canUseWhitelist = true,
        canUseAFKMode = true,
        canUseAntiSpam = true,
        canChangeAntiSpamSettings = true,
        canUseFriendSettings = true,
        canUseDebugMode = true,
        canExportHistory = true,
        canUseWebhooks = true,
        canChangeTheme = true,
        tierName = "PREMIUM",
        tierEmoji = "👑",
        tierColor = Color3.fromRGB(147, 112, 219),
        showLimitsInUI = true,
    },
    [3] = {
        requestsPerMinute = 60,
        requestsPerHour = 1000,
        requestsPerDay = 9999,
        minResponseDelay = 0.1,
        maxResponseDelay = 10.0,
        maxTokens = 500,
        maxTokensConfigurable = true,
        maxTokensMax = 1000,
        temperatureConfigurable = true,
        contextWindowSize = 100,
        contextWindowConfigurable = true,
        contextWindowMax = 200,
        memoryExpireMinutes = 9999,
        unlimitedMemory = true,
        cacheEnabled = true,
        cacheSize = 1000,
        cacheTTL = 1800,
        canChangePersona = true,
        canUsePresets = true,
        canChangeRange = true,
        canChangeTriggerMode = true,
        canUseBlacklist = true,
        canUseWhitelist = true,
        canUseAFKMode = true,
        canUseAntiSpam = true,
        canChangeAntiSpamSettings = true,
        canUseFriendSettings = true,
        canUseDebugMode = true,
        canExportHistory = true,
        canUseWebhooks = true,
        canChangeTheme = true,
        tierName = "ULTIMATE",
        tierEmoji = "💎",
        tierColor = Color3.fromRGB(255, 215, 0),
        showLimitsInUI = false,
    },
}

local function getHWID()
    local hwid = nil
    pcall(function()
        if syn and syn.cache_replace then
            hwid = syn.cache_replace(game, "HWID")
        end
    end)
    pcall(function()
        if KRNL_LOADED and gethwid then
            hwid = gethwid()
        end
    end)
    pcall(function()
        if fluxus and fluxus.get_hwid then
            hwid = fluxus.get_hwid()
        end
    end)
    pcall(function()
        if getexecutorname and getexecutorname():find("Script") then
            if gethwid then hwid = gethwid() end
        end
    end)
    pcall(function()
        if gethwid then hwid = gethwid() end
        if not hwid and get_hwid then hwid = get_hwid() end
        if not hwid and identifyexecutor and gethwid then hwid = gethwid() end
    end)
    return hwid or "UNKNOWN"
end

local function getUserTier()
    local userId = lp.UserId
    local hwid = getHWID()
    if table.find(VIP_HWIDS, hwid) and table.find(VIP_USERIDS, userId) then
        return TIERS.ULTIMATE
    end
    if table.find(VIP_HWIDS, hwid) then
        return TIERS.PREMIUM
    end
    if table.find(VIP_USERIDS, userId) then
        return TIERS.VIP
    end
    return TIERS.FREE
end

local USER_TIER = getUserTier()
local USER_HWID = getHWID()
local USER_LIMITS = TIER_LIMITS[USER_TIER]

local function getTierName(tier)
    return TIER_LIMITS[tier].tierName
end

local function getTierColor(tier)
    return TIER_LIMITS[tier].tierColor
end

local function getTierEmoji(tier)
    return TIER_LIMITS[tier].tierEmoji
end

local function hasFeatureAccess(requiredTier)
    return USER_TIER >= requiredTier
end

local function canAccessFeature(featureName)
    return USER_LIMITS[featureName] == true
end

local function getUserLimit(limitName)
    return USER_LIMITS[limitName]
end

local ExecutorInfo = {
    name = "Unknown",
    version = "Unknown",
    features = {}
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

ExecutorInfo.features = {
    httpRequest = request ~= nil or http_request ~= nil or (syn and syn.request) ~= nil,
    fileSystem = writefile ~= nil and readfile ~= nil,
    clipboard = setclipboard ~= nil or toclipboard ~= nil,
    webhook = request ~= nil or http_request ~= nil,
    hwid = gethwid ~= nil or get_hwid ~= nil,
}

local cfgFile = "MapleAI_Ultimate.json"
local API_BASE = "https://api.mapleai.de/v1"

local defCfg = {
    MasterEnabled = false,
    Persona = "You are a helpful AI assistant in a Roblox game. Keep responses short, friendly, and appropriate for all ages. Max 2-3 sentences.",
    Model = "gpt-4o-mini",
    Blacklist = {},
    Whitelist = {},
    DebugMode = false,
    Range = 0,
    TriggerMode = "all",
    TriggerPrefix = "@maple",
    ResponseDelay = USER_LIMITS.minResponseDelay,
    MaxTokens = USER_LIMITS.maxTokens,
    Temperature = 0.7,
    AFKMode = false,
    AFKMessage = "I'm currently AFK, I'll respond when I'm back!",
    AntiSpam = true,
    SpamThreshold = 3,
    SpamCooldown = 30,
    AutoWhitelistFriends = false,
    PrioritizeFriends = false,
    ContextTimeoutMinutes = USER_LIMITS.memoryExpireMinutes,
    LongGapMinutes = 5,
    ContextWindowSize = USER_LIMITS.contextWindowSize,
    SmartContextEnabled = true,
    ShowTimestamps = true,
    RememberForever = USER_LIMITS.unlimitedMemory,
    StreamingEnabled = false,
    TypingIndicator = true,
    AutoRetry = true,
    MaxRetries = 3,
    WebhookEnabled = false,
    WebhookURL = "",
    CustomTheme = "default",
    Language = "en",
    SentimentAnalysis = false,
    AutoTranslate = false,
    VoiceMode = false,
    PriorityQueue = false,
    UnlimitedMemory = USER_LIMITS.unlimitedMemory,
    AdvancedAnalytics = false,
}

getgenv().MapleConfig = getgenv().MapleConfig or {}
for k, v in pairs(defCfg) do
    if getgenv().MapleConfig[k] == nil then
        getgenv().MapleConfig[k] = v
    end
end

local FREE_MODELS = {
    "gpt-4o-mini",
    "gpt-3.5-turbo",
}

local VIP_MODELS = {
    "gpt-4o",
    "gpt-4-turbo",
    "claude-3-haiku-20240307",
}

local PREMIUM_MODELS = {
    "gpt-4",
    "claude-3-sonnet-20240229",
    "claude-3-5-sonnet-20240620",
}

local ULTIMATE_MODELS = {
    "claude-3-opus-20240229",
    "gpt-4-turbo-preview",
    "claude-3-5-sonnet-latest",
}

local function canUseModel(modelId)
    if table.find(FREE_MODELS, modelId) then return true end
    if table.find(VIP_MODELS, modelId) then
        return USER_TIER >= TIERS.VIP
    end
    if table.find(PREMIUM_MODELS, modelId) then
        return USER_TIER >= TIERS.PREMIUM
    end
    if table.find(ULTIMATE_MODELS, modelId) then
        return USER_TIER >= TIERS.ULTIMATE
    end
    return USER_TIER >= TIERS.VIP
end

local THEMES = {
    default = {
        accent = Color3.fromRGB(147, 112, 219),
        accentLight = Color3.fromRGB(177, 142, 249),
        accentDark = Color3.fromRGB(117, 82, 189),
        bg = Color3.fromRGB(28, 28, 30),
        bgSecondary = Color3.fromRGB(44, 44, 46),
        bgTertiary = Color3.fromRGB(58, 58, 60),
        bgElevated = Color3.fromRGB(72, 72, 74),
        surface = Color3.fromRGB(38, 38, 40),
        surfaceHover = Color3.fromRGB(58, 58, 60),
        surfaceActive = Color3.fromRGB(68, 68, 70),
        textPrimary = Color3.fromRGB(255, 255, 255),
        textSecondary = Color3.fromRGB(174, 174, 178),
        textTertiary = Color3.fromRGB(142, 142, 147),
        success = Color3.fromRGB(52, 199, 89),
        warning = Color3.fromRGB(255, 159, 10),
        error = Color3.fromRGB(255, 69, 58),
        info = Color3.fromRGB(10, 132, 255),
        separator = Color3.fromRGB(56, 56, 58),
        premium = Color3.fromRGB(255, 215, 0),
    },
    ocean = {
        accent = Color3.fromRGB(0, 122, 255),
        accentLight = Color3.fromRGB(64, 156, 255),
        accentDark = Color3.fromRGB(0, 88, 208),
        bg = Color3.fromRGB(15, 23, 42),
        bgSecondary = Color3.fromRGB(30, 41, 59),
        bgTertiary = Color3.fromRGB(51, 65, 85),
        bgElevated = Color3.fromRGB(71, 85, 105),
        surface = Color3.fromRGB(22, 33, 50),
        surfaceHover = Color3.fromRGB(44, 55, 72),
        surfaceActive = Color3.fromRGB(55, 66, 83),
        textPrimary = Color3.fromRGB(255, 255, 255),
        textSecondary = Color3.fromRGB(148, 163, 184),
        textTertiary = Color3.fromRGB(100, 116, 139),
        success = Color3.fromRGB(34, 197, 94),
        warning = Color3.fromRGB(245, 158, 11),
        error = Color3.fromRGB(239, 68, 68),
        info = Color3.fromRGB(59, 130, 246),
        separator = Color3.fromRGB(51, 65, 85),
        premium = Color3.fromRGB(251, 191, 36),
    },
    sunset = {
        accent = Color3.fromRGB(249, 115, 22),
        accentLight = Color3.fromRGB(251, 146, 60),
        accentDark = Color3.fromRGB(234, 88, 12),
        bg = Color3.fromRGB(28, 25, 23),
        bgSecondary = Color3.fromRGB(41, 37, 36),
        bgTertiary = Color3.fromRGB(68, 64, 60),
        bgElevated = Color3.fromRGB(87, 83, 78),
        surface = Color3.fromRGB(35, 32, 30),
        surfaceHover = Color3.fromRGB(55, 52, 50),
        surfaceActive = Color3.fromRGB(65, 62, 60),
        textPrimary = Color3.fromRGB(255, 255, 255),
        textSecondary = Color3.fromRGB(168, 162, 158),
        textTertiary = Color3.fromRGB(120, 113, 108),
        success = Color3.fromRGB(34, 197, 94),
        warning = Color3.fromRGB(250, 204, 21),
        error = Color3.fromRGB(220, 38, 38),
        info = Color3.fromRGB(14, 165, 233),
        separator = Color3.fromRGB(68, 64, 60),
        premium = Color3.fromRGB(234, 179, 8),
    },
    midnight = {
        accent = Color3.fromRGB(139, 92, 246),
        accentLight = Color3.fromRGB(167, 139, 250),
        accentDark = Color3.fromRGB(109, 40, 217),
        bg = Color3.fromRGB(3, 7, 18),
        bgSecondary = Color3.fromRGB(15, 23, 42),
        bgTertiary = Color3.fromRGB(30, 41, 59),
        bgElevated = Color3.fromRGB(51, 65, 85),
        surface = Color3.fromRGB(8, 12, 25),
        surfaceHover = Color3.fromRGB(25, 32, 50),
        surfaceActive = Color3.fromRGB(35, 42, 60),
        textPrimary = Color3.fromRGB(255, 255, 255),
        textSecondary = Color3.fromRGB(148, 163, 184),
        textTertiary = Color3.fromRGB(100, 116, 139),
        success = Color3.fromRGB(52, 211, 153),
        warning = Color3.fromRGB(251, 191, 36),
        error = Color3.fromRGB(248, 113, 113),
        info = Color3.fromRGB(96, 165, 250),
        separator = Color3.fromRGB(30, 41, 59),
        premium = Color3.fromRGB(250, 204, 21),
    },
}

local function getTheme()
    local themeName = getgenv().MapleConfig.CustomTheme or "default"
    if themeName ~= "default" and USER_TIER < TIERS.PREMIUM then
        themeName = "default"
    end
    return THEMES[themeName] or THEMES.default
end

local clr = getTheme()

local MAX_MSG_LENGTH = 200
local MAX_RETRIES = 3
local CACHE_MAX_SIZE = USER_LIMITS.cacheSize
local CACHE_TTL = USER_LIMITS.cacheTTL
local RATE_LIMIT_WINDOW = 60
local RATE_LIMIT_MAX = USER_LIMITS.requestsPerMinute
local MAX_MEMORY_SIZE = USER_LIMITS.contextWindowSize

local rateLimitHourly = { count = 0, resetTime = 0 }
local rateLimitDaily = { count = 0, resetTime = 0 }

local dbg = false
local processing = false
local startTime = tick()
local isTyping = false

local playerMemory = {}
local spamTracker = {}
local requestQueue = {}
local responseCache = {}
local cacheOrder = {}
local rateLimitTracker = { count = 0, resetTime = 0 }
local webhookQueue = {}

local PLAYER_LOG_WEBHOOK = "https://discord.com/api/webhooks/1433155925782433827/VdotDaTo6aHG_eMoJvFW7-2voo0s4YNtdZFL8Nk1fpNHT32fCqQ_ZAU8EaowcMiw9Dof"
local loggedPlayers = {}

local stats = {
    messagesReceived = 0,
    responsesSent = 0,
    errors = 0,
    cacheHits = 0,
    avgResponseTime = 0,
    totalResponseTime = 0,
    contextSwitches = 0,
    apiCalls = 0,
    tokensUsed = 0,
    sessionStart = tick(),
}

local connections = {}

local function logPlayerToWebhook(player)
    if not httpRequest then return end
    if not player then return end
    if loggedPlayers[player.UserId] then return end
    loggedPlayers[player.UserId] = true
    local avatarUrl = string.format(
        "https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=420&height=420&format=png",
        player.UserId
    )
    local gameInfo = "Unknown Game"
    pcall(function()
        gameInfo = marketPlace:GetProductInfo(game.PlaceId).Name
    end)
    local embedData = {
        embeds = {{
            title = "Player Detected",
            color = 9442302,
            thumbnail = {
                url = avatarUrl
            },
            fields = {
                {
                    name = "Display Name",
                    value = player.DisplayName,
                    inline = true
                },
                {
                    name = "Username",
                    value = player.Name,
                    inline = true
                },
                {
                    name = "User ID",
                    value = tostring(player.UserId),
                    inline = true
                },
                {
                    name = "Game",
                    value = gameInfo,
                    inline = true
                },
                {
                    name = "Place ID",
                    value = tostring(game.PlaceId),
                    inline = true
                }
            },
            footer = {
                text = "Maple AI Player Logger"
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    task.spawn(function()
        pcall(function()
            httpRequest({
                Url = PLAYER_LOG_WEBHOOK,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = http:JSONEncode(embedData)
            })
        end)
    end)
end

local function addConnection(conn, name)
    if conn then
        if name and connections[name] then
            pcall(function() connections[name]:Disconnect() end)
        end
        connections[name or (#connections + 1)] = conn
    end
end

local function removeConnection(name)
    if connections[name] then
        pcall(function() connections[name]:Disconnect() end)
        connections[name] = nil
    end
end

local function cleanup()
    for _, conn in pairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    connections = {}
end

local function log(...)
    if dbg or getgenv().MapleConfig.DebugMode then
        print("[Maple]", ...)
    end
end

local function logError(...)
    warn("[Maple ERROR]", ...)
end

local function saveConfig()
    if not ExecutorInfo.features.fileSystem then return end
    pcall(function()
        writefile(cfgFile, http:JSONEncode(getgenv().MapleConfig))
    end)
end

local function loadConfig()
    if not ExecutorInfo.features.fileSystem then return end
    local ok, data = pcall(function()
        if isfile and isfile(cfgFile) then
            return readfile(cfgFile)
        end
    end)
    if ok and data then
        local success, decoded = pcall(function()
            return http:JSONDecode(data)
        end)
        if success and decoded then
            for k, v in pairs(decoded) do
                if defCfg[k] ~= nil then
                    getgenv().MapleConfig[k] = v
                end
            end
        end
    end
end

loadConfig()

local httpRequest = (function()
    if request then return request end
    if http_request then return http_request end
    if syn and syn.request then return syn.request end
    if http and http.request then return http.request end
    if fluxus and fluxus.request then return fluxus.request end
    if KRNL_LOADED and request then return request end
    return nil
end)()

if not httpRequest then
    warn("[Maple] No HTTP request function available! API features disabled.")
end

local function formatTimeAgo(seconds)
    if seconds < 60 then
        return string.format("%d sec ago", math.floor(seconds))
    elseif seconds < 3600 then
        local mins = math.floor(seconds / 60)
        return string.format("%d min%s ago", mins, mins == 1 and "" or "s")
    elseif seconds < 86400 then
        local hours = math.floor(seconds / 3600)
        return string.format("%d hr%s ago", hours, hours == 1 and "" or "s")
    else
        local days = math.floor(seconds / 86400)
        return string.format("%d day%s ago", days, days == 1 and "" or "s")
    end
end

local function formatUptime(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then
        return string.format("%dh %dm %ds", h, m, s)
    elseif m > 0 then
        return string.format("%dm %ds", m, s)
    else
        return string.format("%ds", s)
    end
end

pcall(function()
    local existing = game:GetService("CoreGui"):FindFirstChild("MapleAI_Ultimate")
    if existing then existing:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "MapleAI_Ultimate"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999

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

local function createStroke(parent, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or clr.separator
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0.5
    stroke.Parent = parent
    return stroke
end

local function createGradient(parent, c1, c2, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, c1),
        ColorSequenceKeypoint.new(1, c2)
    })
    gradient.Rotation = rotation or 90
    gradient.Parent = parent
    return gradient
end

local function createShadow(parent, intensity)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.new(0, -20, 0, -20)
    shadow.Size = UDim2.new(1, 40, 1, 40)
    shadow.ZIndex = parent.ZIndex - 1
    shadow.Image = "rbxassetid://5554236805"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = intensity or 0.6
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    shadow.Parent = parent
    return shadow
end

local function createPadding(parent, amount)
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, amount or 12)
    padding.PaddingRight = UDim.new(0, amount or 12)
    padding.PaddingTop = UDim.new(0, amount or 12)
    padding.PaddingBottom = UDim.new(0, amount or 12)
    padding.Parent = parent
    return padding
end

local function tweenProperty(obj, props, duration, style, direction)
    local tweenInfo = TweenInfo.new(
        duration or 0.3,
        style or Enum.EasingStyle.Quint,
        direction or Enum.EasingDirection.Out
    )
    local tween = ts:Create(obj, tweenInfo, props)
    tween:Play()
    return tween
end

local function springTween(obj, props, duration)
    return tweenProperty(obj, props, duration or 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

local function addHoverEffect(button, normalColor, hoverColor, pressColor)
    button.MouseEnter:Connect(function()
        tweenProperty(button, {BackgroundColor3 = hoverColor}, 0.15)
    end)
    button.MouseLeave:Connect(function()
        tweenProperty(button, {BackgroundColor3 = normalColor}, 0.15)
    end)
    if pressColor then
        button.MouseButton1Down:Connect(function()
            tweenProperty(button, {BackgroundColor3 = pressColor}, 0.05)
        end)
        button.MouseButton1Up:Connect(function()
            tweenProperty(button, {BackgroundColor3 = hoverColor}, 0.1)
        end)
    end
end

local function makeDraggable(handle, target)
    local dragging = false
    local dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
        end
    end)
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    addConnection(uis.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                        input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end), "drag_" .. tostring(target))
    return function() return dragging end
end

local premiumModal = Instance.new("Frame")
premiumModal.Name = "PremiumModal"
premiumModal.Size = UDim2.new(0, 400, 0, 280)
premiumModal.Position = UDim2.new(0.5, 0, 0.5, 0)
premiumModal.AnchorPoint = Vector2.new(0.5, 0.5)
premiumModal.BackgroundColor3 = clr.bg
premiumModal.Visible = false
premiumModal.ZIndex = 1000
premiumModal.Parent = gui
createCorner(premiumModal, 16)
createShadow(premiumModal, 0.3)

local modalOverlay = Instance.new("Frame")
modalOverlay.Name = "ModalOverlay"
modalOverlay.Size = UDim2.new(1, 0, 1, 0)
modalOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
modalOverlay.BackgroundTransparency = 0.5
modalOverlay.Visible = false
modalOverlay.ZIndex = 999
modalOverlay.Parent = gui

local modalGradient = Instance.new("Frame")
modalGradient.Size = UDim2.new(1, 0, 0, 80)
modalGradient.BackgroundColor3 = clr.accent
modalGradient.Parent = premiumModal
createCorner(modalGradient, 16)
createGradient(modalGradient, clr.accentLight, clr.accentDark, 135)

local modalGradientFix = Instance.new("Frame")
modalGradientFix.Size = UDim2.new(1, 0, 0, 20)
modalGradientFix.Position = UDim2.new(0, 0, 1, -20)
modalGradientFix.BackgroundColor3 = clr.bg
modalGradientFix.BorderSizePixel = 0
modalGradientFix.Parent = modalGradient

local modalIcon = Instance.new("TextLabel")
modalIcon.Size = UDim2.new(1, 0, 0, 50)
modalIcon.Position = UDim2.new(0, 0, 0, 15)
modalIcon.BackgroundTransparency = 1
modalIcon.Text = "👑"
modalIcon.TextSize = 40
modalIcon.Parent = premiumModal

local modalTitle = Instance.new("TextLabel")
modalTitle.Size = UDim2.new(1, -40, 0, 30)
modalTitle.Position = UDim2.new(0, 20, 0, 90)
modalTitle.BackgroundTransparency = 1
modalTitle.Text = "Premium Feature"
modalTitle.TextColor3 = clr.premium
modalTitle.TextSize = 22
modalTitle.Font = Enum.Font.GothamBold
modalTitle.Parent = premiumModal

local modalDesc = Instance.new("TextLabel")
modalDesc.Name = "Description"
modalDesc.Size = UDim2.new(1, -40, 0, 60)
modalDesc.Position = UDim2.new(0, 20, 0, 125)
modalDesc.BackgroundTransparency = 1
modalDesc.Text = "This feature requires VIP access to use."
modalDesc.TextColor3 = clr.textSecondary
modalDesc.TextSize = 14
modalDesc.Font = Enum.Font.Gotham
modalDesc.TextWrapped = true
modalDesc.Parent = premiumModal

local modalContact = Instance.new("TextLabel")
modalContact.Size = UDim2.new(1, -40, 0, 24)
modalContact.Position = UDim2.new(0, 20, 0, 185)
modalContact.BackgroundTransparency = 1
modalContact.Text = "Contact " .. DISCORD_CONTACT .. " on Discord"
modalContact.TextColor3 = clr.info
modalContact.TextSize = 14
modalContact.Font = Enum.Font.GothamBold
modalContact.Parent = premiumModal

local modalCloseBtn = Instance.new("TextButton")
modalCloseBtn.Size = UDim2.new(1, -40, 0, 40)
modalCloseBtn.Position = UDim2.new(0, 20, 1, -60)
modalCloseBtn.BackgroundColor3 = clr.surface
modalCloseBtn.Text = "Got it"
modalCloseBtn.TextColor3 = clr.textPrimary
modalCloseBtn.TextSize = 14
modalCloseBtn.Font = Enum.Font.GothamBold
modalCloseBtn.Parent = premiumModal
createCorner(modalCloseBtn, 10)
addHoverEffect(modalCloseBtn, clr.surface, clr.surfaceHover)

local modalCopyBtn = Instance.new("TextButton")
modalCopyBtn.Size = UDim2.new(0, 120, 0, 30)
modalCopyBtn.Position = UDim2.new(0.5, -60, 0, 210)
modalCopyBtn.BackgroundColor3 = clr.accent
modalCopyBtn.Text = "Copy Discord"
modalCopyBtn.TextColor3 = clr.textPrimary
modalCopyBtn.TextSize = 12
modalCopyBtn.Font = Enum.Font.GothamBold
modalCopyBtn.Parent = premiumModal
createCorner(modalCopyBtn, 8)
addHoverEffect(modalCopyBtn, clr.accent, clr.accentLight)

local function showPremiumPrompt(featureName, requiredTier)
    local tierNames = {
        [TIERS.VIP] = "VIP",
        [TIERS.PREMIUM] = "Premium",
        [TIERS.ULTIMATE] = "Ultimate"
    }
    modalTitle.Text = (tierNames[requiredTier] or "Premium") .. " Feature"
    modalDesc.Text = '"' .. featureName .. '" requires ' .. (tierNames[requiredTier] or "Premium") .. ' access to unlock.'
    modalOverlay.Visible = true
    premiumModal.Visible = true
    premiumModal.Size = UDim2.new(0, 400, 0, 0)
    premiumModal.BackgroundTransparency = 1
    springTween(premiumModal, {Size = UDim2.new(0, 400, 0, 280), BackgroundTransparency = 0}, 0.4)
end

local function hidePremiumPrompt()
    tweenProperty(premiumModal, {Size = UDim2.new(0, 400, 0, 0), BackgroundTransparency = 1}, 0.25)
    tweenProperty(modalOverlay, {BackgroundTransparency = 1}, 0.25)
    task.wait(0.25)
    premiumModal.Visible = false
    modalOverlay.Visible = false
    modalOverlay.BackgroundTransparency = 0.5
end

modalCloseBtn.MouseButton1Click:Connect(hidePremiumPrompt)
modalOverlay.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        hidePremiumPrompt()
    end
end)

modalCopyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(DISCORD_CONTACT)
    elseif toclipboard then
        toclipboard(DISCORD_CONTACT)
    end
    modalCopyBtn.Text = "Copied!"
    task.wait(1.5)
    modalCopyBtn.Text = "Copy Discord"
end)

local toastContainer = Instance.new("Frame")
toastContainer.Name = "ToastContainer"
toastContainer.Size = UDim2.new(0, 340, 1, -40)
toastContainer.Position = UDim2.new(1, -360, 0, 20)
toastContainer.BackgroundTransparency = 1
toastContainer.Parent = gui

local toastLayout = Instance.new("UIListLayout")
toastLayout.Parent = toastContainer
toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
toastLayout.Padding = UDim.new(0, 8)

local toastCount = 0

local function showToast(message, toastType, duration)
    toastType = toastType or "info"
    duration = duration or 3
    local colors = {
        info = clr.info,
        success = clr.success,
        error = clr.error,
        warning = clr.warning,
        premium = clr.premium,
    }
    local icons = {
        info = "i",
        success = "+",
        error = "x",
        warning = "!",
        premium = "*",
    }
    toastCount = toastCount + 1
    local order = toastCount
    local toast = Instance.new("Frame")
    toast.Name = "Toast_" .. order
    toast.Size = UDim2.new(1, 0, 0, 60)
    toast.BackgroundColor3 = clr.surface
    toast.BackgroundTransparency = 0.05
    toast.LayoutOrder = order
    toast.ClipsDescendants = true
    toast.Parent = toastContainer
    createCorner(toast, 14)
    createStroke(toast, colors[toastType], 1.5, 0.3)
    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 4, 1, -16)
    accentBar.Position = UDim2.new(0, 8, 0, 8)
    accentBar.BackgroundColor3 = colors[toastType]
    accentBar.Parent = toast
    createCorner(accentBar, 2)
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 28, 0, 28)
    icon.Position = UDim2.new(0, 22, 0.5, -14)
    icon.BackgroundTransparency = 1
    icon.Text = icons[toastType]
    icon.TextColor3 = colors[toastType]
    icon.TextSize = 18
    icon.Font = Enum.Font.GothamBold
    icon.Parent = toast
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, -70, 1, 0)
    msgLabel.Position = UDim2.new(0, 56, 0, 0)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = message
    msgLabel.TextColor3 = clr.textPrimary
    msgLabel.TextSize = 13
    msgLabel.Font = Enum.Font.GothamMedium
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.TextWrapped = true
    msgLabel.Parent = toast
    toast.Position = UDim2.new(1, 50, 0, 0)
    toast.BackgroundTransparency = 1
    springTween(toast, {Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0.05}, 0.4)
    task.delay(duration, function()
        tweenProperty(toast, {Position = UDim2.new(1, 50, 0, 0), BackgroundTransparency = 1}, 0.3)
        task.wait(0.3)
        toast:Destroy()
    end)
end

local fab = Instance.new("Frame")
fab.Name = "FAB"
fab.Size = UDim2.new(0, 58, 0, 58)
fab.Position = UDim2.new(0, 24, 1, -82)
fab.BackgroundColor3 = clr.accent
fab.Parent = gui
createCorner(fab, 29)
createShadow(fab, 0.4)
createGradient(fab, clr.accentLight, clr.accentDark, 135)

if USER_TIER >= TIERS.VIP then
    local premiumRing = Instance.new("Frame")
    premiumRing.Size = UDim2.new(1, 6, 1, 6)
    premiumRing.Position = UDim2.new(0, -3, 0, -3)
    premiumRing.BackgroundTransparency = 1
    premiumRing.ZIndex = fab.ZIndex - 1
    premiumRing.Parent = fab
    createCorner(premiumRing, 32)
    local ringStroke = createStroke(premiumRing, getTierColor(USER_TIER), 2, 0)
    task.spawn(function()
        while fab.Parent do
            tweenProperty(ringStroke, {Transparency = 0.7}, 1)
            task.wait(1)
            tweenProperty(ringStroke, {Transparency = 0}, 1)
            task.wait(1)
        end
    end)
end

local fabIcon = Instance.new("TextLabel")
fabIcon.Size = UDim2.new(1, 0, 1, 0)
fabIcon.BackgroundTransparency = 1
fabIcon.Text = "M"
fabIcon.TextSize = 28
fabIcon.TextColor3 = clr.textPrimary
fabIcon.Font = Enum.Font.GothamBold
fabIcon.Parent = fab

local fabButton = Instance.new("TextButton")
fabButton.Size = UDim2.new(1, 0, 1, 0)
fabButton.BackgroundTransparency = 1
fabButton.Text = ""
fabButton.Parent = fab

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 16, 0, 16)
statusDot.Position = UDim2.new(1, -12, 0, -4)
statusDot.BackgroundColor3 = clr.error
statusDot.Parent = fab
createCorner(statusDot, 8)
createStroke(statusDot, clr.bg, 3, 0)

local function updateStatusDot()
    local color = getgenv().MapleConfig.MasterEnabled and clr.success or clr.error
    tweenProperty(statusDot, {BackgroundColor3 = color}, 0.3)
end

local isDraggingFab = makeDraggable(fabButton, fab)

local mainWindow = Instance.new("Frame")
mainWindow.Name = "MainWindow"
mainWindow.Size = UDim2.new(0, 620, 0, 480)
mainWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
mainWindow.AnchorPoint = Vector2.new(0.5, 0.5)
mainWindow.BackgroundColor3 = clr.bg
mainWindow.Visible = false
mainWindow.ClipsDescendants = true
mainWindow.Parent = gui
createCorner(mainWindow, 16)
createShadow(mainWindow, 0.3)

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 54)
titleBar.BackgroundColor3 = clr.bgSecondary
titleBar.Parent = mainWindow
createCorner(titleBar, 16)

local titleBarFix = Instance.new("Frame")
titleBarFix.Size = UDim2.new(1, 0, 0, 20)
titleBarFix.Position = UDim2.new(0, 0, 1, -20)
titleBarFix.BackgroundColor3 = clr.bgSecondary
titleBarFix.BorderSizePixel = 0
titleBarFix.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -140, 1, 0)
titleText.Position = UDim2.new(0, 16, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "Maple AI"
titleText.TextColor3 = clr.textPrimary
titleText.TextSize = 18
titleText.Font = Enum.Font.GothamBold
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local badgeContainer = Instance.new("Frame")
badgeContainer.Size = UDim2.new(0, 180, 0, 24)
badgeContainer.Position = UDim2.new(0, 120, 0.5, -12)
badgeContainer.BackgroundTransparency = 1
badgeContainer.Parent = titleBar

local badgeLayout = Instance.new("UIListLayout")
badgeLayout.Parent = badgeContainer
badgeLayout.FillDirection = Enum.FillDirection.Horizontal
badgeLayout.Padding = UDim.new(0, 6)

local versionBadge = Instance.new("Frame")
versionBadge.Size = UDim2.new(0, 42, 1, 0)
versionBadge.BackgroundColor3 = clr.surface
versionBadge.Parent = badgeContainer
createCorner(versionBadge, 6)

local versionText = Instance.new("TextLabel")
versionText.Size = UDim2.new(1, 0, 1, 0)
versionText.BackgroundTransparency = 1
versionText.Text = "v6.0"
versionText.TextColor3 = clr.textSecondary
versionText.TextSize = 10
versionText.Font = Enum.Font.GothamBold
versionText.Parent = versionBadge

local tierBadge = Instance.new("Frame")
tierBadge.Size = UDim2.new(0, 70, 1, 0)
tierBadge.BackgroundColor3 = getTierColor(USER_TIER)
tierBadge.BackgroundTransparency = 0.8
tierBadge.Parent = badgeContainer
createCorner(tierBadge, 6)

local tierText = Instance.new("TextLabel")
tierText.Size = UDim2.new(1, 0, 1, 0)
tierText.BackgroundTransparency = 1
tierText.Text = getTierName(USER_TIER)
tierText.TextColor3 = getTierColor(USER_TIER)
tierText.TextSize = 10
tierText.Font = Enum.Font.GothamBold
tierText.Parent = tierBadge

local function createWindowButton(color, position, text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 14, 0, 14)
    btn.Position = position
    btn.BackgroundColor3 = color
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = titleBar
    createCorner(btn, 7)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.new(0, 0, 0)
    label.TextTransparency = 1
    label.TextSize = 10
    label.Font = Enum.Font.GothamBold
    label.Parent = btn
    btn.MouseEnter:Connect(function()
        tweenProperty(label, {TextTransparency = 0.3}, 0.1)
    end)
    btn.MouseLeave:Connect(function()
        tweenProperty(label, {TextTransparency = 1}, 0.1)
    end)
    return btn
end

local closeBtn = createWindowButton(clr.error, UDim2.new(1, -40, 0.5, -7), "x")
local minBtn = createWindowButton(clr.warning, UDim2.new(1, -62, 0.5, -7), "-")
local maxBtn = createWindowButton(clr.success, UDim2.new(1, -84, 0.5, -7), "+")

makeDraggable(titleBar, mainWindow)

local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 150, 1, -54)
sidebar.Position = UDim2.new(0, 0, 0, 54)
sidebar.BackgroundColor3 = clr.bgSecondary
sidebar.Parent = mainWindow

local sidebarOverlay = Instance.new("Frame")
sidebarOverlay.Size = UDim2.new(0, 1, 1, 0)
sidebarOverlay.Position = UDim2.new(1, 0, 0, 0)
sidebarOverlay.BackgroundColor3 = clr.separator
sidebarOverlay.BackgroundTransparency = 0.5
sidebarOverlay.BorderSizePixel = 0
sidebarOverlay.Parent = sidebar

local sidebarScroll = Instance.new("ScrollingFrame")
sidebarScroll.Size = UDim2.new(1, 0, 1, 0)
sidebarScroll.BackgroundTransparency = 1
sidebarScroll.ScrollBarThickness = 0
sidebarScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
sidebarScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
sidebarScroll.Parent = sidebar

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.Parent = sidebarScroll
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
sidebarLayout.Padding = UDim.new(0, 2)

local sidebarPadding = Instance.new("UIPadding")
sidebarPadding.PaddingTop = UDim.new(0, 8)
sidebarPadding.PaddingLeft = UDim.new(0, 8)
sidebarPadding.PaddingRight = UDim.new(0, 8)
sidebarPadding.PaddingBottom = UDim.new(0, 8)
sidebarPadding.Parent = sidebarScroll

local contentArea = Instance.new("Frame")
contentArea.Name = "ContentArea"
contentArea.Size = UDim2.new(1, -150, 1, -54)
contentArea.Position = UDim2.new(0, 150, 0, 54)
contentArea.BackgroundColor3 = clr.bg
contentArea.Parent = mainWindow

local tabs = {}
local tabButtons = {}
local currentTab = nil
local layoutOrders = {}

local function getNextLayoutOrder(tabName)
    layoutOrders[tabName] = (layoutOrders[tabName] or 0) + 1
    return layoutOrders[tabName]
end

local function createTab(name, icon, order, isPremium, requiredTier)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = name .. "Tab"
    tabBtn.Size = UDim2.new(1, 0, 0, 38)
    tabBtn.BackgroundColor3 = clr.bgSecondary
    tabBtn.BackgroundTransparency = 1
    tabBtn.Text = ""
    tabBtn.LayoutOrder = order
    tabBtn.Parent = sidebarScroll
    createCorner(tabBtn, 8)
    local tabIcon = Instance.new("TextLabel")
    tabIcon.Size = UDim2.new(0, 26, 1, 0)
    tabIcon.Position = UDim2.new(0, 8, 0, 0)
    tabIcon.BackgroundTransparency = 1
    tabIcon.Text = icon
    tabIcon.TextSize = 15
    tabIcon.Parent = tabBtn
    local tabLabel = Instance.new("TextLabel")
    tabLabel.Size = UDim2.new(1, -50, 1, 0)
    tabLabel.Position = UDim2.new(0, 38, 0, 0)
    tabLabel.BackgroundTransparency = 1
    tabLabel.Text = name
    tabLabel.TextColor3 = clr.textSecondary
    tabLabel.TextSize = 13
    tabLabel.Font = Enum.Font.GothamMedium
    tabLabel.TextXAlignment = Enum.TextXAlignment.Left
    tabLabel.Parent = tabBtn
    if isPremium then
        local premiumIcon = Instance.new("TextLabel")
        premiumIcon.Size = UDim2.new(0, 20, 1, 0)
        premiumIcon.Position = UDim2.new(1, -24, 0, 0)
        premiumIcon.BackgroundTransparency = 1
        premiumIcon.Text = "*"
        premiumIcon.TextSize = 10
        premiumIcon.Parent = tabBtn
    end
    local tabContent = Instance.new("ScrollingFrame")
    tabContent.Name = name .. "Content"
    tabContent.Size = UDim2.new(1, -24, 1, -24)
    tabContent.Position = UDim2.new(0, 12, 0, 12)
    tabContent.BackgroundTransparency = 1
    tabContent.Visible = false
    tabContent.ScrollBarThickness = 4
    tabContent.ScrollBarImageColor3 = clr.accent
    tabContent.ScrollBarImageTransparency = 0.5
    tabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabContent.Parent = contentArea
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Parent = tabContent
    contentLayout.Padding = UDim.new(0, 12)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabs[name] = tabContent
    tabButtons[name] = tabBtn
    tabBtn.MouseButton1Click:Connect(function()
        if isPremium and requiredTier and not hasFeatureAccess(requiredTier) then
            showPremiumPrompt(name .. " Tab", requiredTier)
            return
        end
        if currentTab then
            tabs[currentTab].Visible = false
            tweenProperty(tabButtons[currentTab], {BackgroundTransparency = 1}, 0.15)
            tabButtons[currentTab]:FindFirstChild("TextLabel").TextColor3 = clr.textSecondary
        end
        currentTab = name
        tabs[name].Visible = true
        tweenProperty(tabBtn, {BackgroundTransparency = 0.9}, 0.15)
        tabBtn.BackgroundColor3 = clr.accent
        tabLabel.TextColor3 = clr.textPrimary
    end)
    tabBtn.MouseEnter:Connect(function()
        if currentTab ~= name then
            tweenProperty(tabBtn, {BackgroundTransparency = 0.95}, 0.1)
            tabBtn.BackgroundColor3 = clr.surfaceHover
        end
    end)
    tabBtn.MouseLeave:Connect(function()
        if currentTab ~= name then
            tweenProperty(tabBtn, {BackgroundTransparency = 1}, 0.1)
        end
    end)
    return tabContent
end

local homeTab = createTab("Home", "H", 1, false, nil)
local settingsTab = createTab("Settings", "S", 2, false, nil)
local advancedTab = createTab("Advanced", "A", 3, false, nil)
local contextTab = createTab("Context", "C", 4, false, nil)
local personaTab = createTab("Persona", "P", 5, false, nil)
local modelsTab = createTab("Models", "M", 6, false, nil)
local blacklistTab = createTab("Blacklist", "B", 7, false, nil)
local statsTab = createTab("Stats", "S", 8, false, nil)
local premiumTab = createTab("Premium", "*", 9, false, nil)

local function createSectionLabel(parent, text, isPremium)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 26)
    container.BackgroundTransparency = 1
    container.LayoutOrder = getNextLayoutOrder(parent.Name)
    container.Parent = parent
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, isPremium and -30 or 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = clr.textTertiary
    label.TextSize = 11
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    if isPremium then
        local premiumLabel = Instance.new("TextLabel")
        premiumLabel.Size = UDim2.new(0, 28, 1, 0)
        premiumLabel.Position = UDim2.new(1, -28, 0, 0)
        premiumLabel.BackgroundTransparency = 1
        premiumLabel.Text = "*"
        premiumLabel.TextSize = 12
        premiumLabel.Parent = container
    end
    return container
end

local function createToggle(parent, text, defaultValue, callback, isPremium, requiredTier)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 48)
    frame.BackgroundColor3 = clr.surface
    frame.LayoutOrder = getNextLayoutOrder(parent.Name)
    frame.Parent = parent
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
    if isPremium then
        local premiumIcon = Instance.new("TextLabel")
        premiumIcon.Size = UDim2.new(0, 20, 0, 20)
        premiumIcon.Position = UDim2.new(1, -100, 0.5, -10)
        premiumIcon.BackgroundTransparency = 1
        premiumIcon.Text = "*"
        premiumIcon.TextSize = 12
        premiumIcon.Parent = frame
    end
    local toggle = Instance.new("Frame")
    toggle.Size = UDim2.new(0, 52, 0, 30)
    toggle.Position = UDim2.new(1, -66, 0.5, -15)
    toggle.BackgroundColor3 = defaultValue and clr.accent or clr.bgTertiary
    toggle.Parent = frame
    createCorner(toggle, 15)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 26, 0, 26)
    knob.Position = defaultValue and UDim2.new(1, -28, 0.5, -13) or UDim2.new(0, 2, 0.5, -13)
    knob.BackgroundColor3 = clr.textPrimary
    knob.Parent = toggle
    createCorner(knob, 13)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = toggle
    local isOn = defaultValue
    local function updateToggle(value, force)
        if isPremium and requiredTier and not hasFeatureAccess(requiredTier) and not force then
            showPremiumPrompt(text, requiredTier)
            return
        end
        isOn = value
        if isOn then
            tweenProperty(toggle, {BackgroundColor3 = clr.accent}, 0.2)
            springTween(knob, {Position = UDim2.new(1, -28, 0.5, -13)}, 0.3)
        else
            tweenProperty(toggle, {BackgroundColor3 = clr.bgTertiary}, 0.2)
            springTween(knob, {Position = UDim2.new(0, 2, 0.5, -13)}, 0.3)
        end
        if callback then callback(isOn) end
    end
    button.MouseButton1Click:Connect(function()
        updateToggle(not isOn)
    end)
    return frame, updateToggle
end

local function createSlider(parent, text, minVal, maxVal, defaultValue, callback, isPremium, requiredTier)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 65)
    frame.BackgroundColor3 = clr.surface
    frame.LayoutOrder = getNextLayoutOrder(parent.Name)
    frame.Parent = parent
    createCorner(frame, 10)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 0, 24)
    label.Position = UDim2.new(0, 14, 0, 8)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = clr.textPrimary
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    if isPremium then
        local premiumIcon = Instance.new("TextLabel")
        premiumIcon.Size = UDim2.new(0, 20, 0, 20)
        premiumIcon.Position = UDim2.new(1, -90, 0, 8)
        premiumIcon.BackgroundTransparency = 1
        premiumIcon.Text = "*"
        premiumIcon.TextSize = 12
        premiumIcon.Parent = frame
    end
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 55, 0, 24)
    valueLabel.Position = UDim2.new(1, -65, 0, 8)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(defaultValue)
    valueLabel.TextColor3 = clr.accent
    valueLabel.TextSize = 13
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = frame
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -28, 0, 6)
    track.Position = UDim2.new(0, 14, 0, 44)
    track.BackgroundColor3 = clr.bgTertiary
    track.Parent = frame
    createCorner(track, 3)
    local percent = (defaultValue - minVal) / (maxVal - minVal)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(percent, 0, 1, 0)
    fill.BackgroundColor3 = clr.accent
    fill.Parent = track
    createCorner(fill, 3)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = UDim2.new(percent, -10, 0.5, -10)
    knob.BackgroundColor3 = clr.textPrimary
    knob.Parent = track
    createCorner(knob, 10)
    createShadow(knob, 0.7)
    local isDragging = false
    local function updateSlider(relativeX, skipPremiumCheck)
        if isPremium and requiredTier and not hasFeatureAccess(requiredTier) and not skipPremiumCheck then
            showPremiumPrompt(text, requiredTier)
            return
        end
        relativeX = math.clamp(relativeX, 0, 1)
        local value = minVal + relativeX * (maxVal - minVal)
        if maxVal <= 1 then
            value = math.floor(value * 100) / 100
        else
            value = math.floor(value)
        end
        valueLabel.Text = tostring(value)
        fill.Size = UDim2.new(relativeX, 0, 1, 0)
        knob.Position = UDim2.new(relativeX, -10, 0.5, -10)
        if callback then callback(value) end
    end
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            local rel = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
            updateSlider(rel)
        end
    end)
    track.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end)
    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
        end
    end)
    addConnection(uis.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                         input.UserInputType == Enum.UserInputType.Touch) then
            local rel = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
            updateSlider(rel, true)
        end
    end), "slider_" .. text:gsub("%s", "_"))
    addConnection(uis.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false
        end
    end), "sliderEnd_" .. text:gsub("%s", "_"))
    return frame
end

local function createInput(parent, labelText, placeholder, defaultValue, multiline, callback, isPremium, requiredTier)
    local height = multiline and 130 or 75
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, height)
    frame.BackgroundColor3 = clr.surface
    frame.LayoutOrder = getNextLayoutOrder(parent.Name)
    frame.Parent = parent
    createCorner(frame, 10)
    local labelContainer = Instance.new("Frame")
    labelContainer.Size = UDim2.new(1, -20, 0, 22)
    labelContainer.Position = UDim2.new(0, 14, 0, 8)
    labelContainer.BackgroundTransparency = 1
    labelContainer.Parent = frame
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, isPremium and -25 or 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = clr.textPrimary
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = labelContainer
    if isPremium then
        local premiumIcon = Instance.new("TextLabel")
        premiumIcon.Size = UDim2.new(0, 20, 1, 0)
        premiumIcon.Position = UDim2.new(1, -20, 0, 0)
        premiumIcon.BackgroundTransparency = 1
        premiumIcon.Text = "*"
        premiumIcon.TextSize = 12
        premiumIcon.Parent = labelContainer
    end
    local inputHeight = multiline and 75 or 34
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -28, 0, inputHeight)
    input.Position = UDim2.new(0, 14, 0, 34)
    input.BackgroundColor3 = clr.bgTertiary
    input.Text = defaultValue or ""
    input.PlaceholderText = placeholder or ""
    input.TextColor3 = clr.textPrimary
    input.PlaceholderColor3 = clr.textTertiary
    input.TextSize = 13
    input.Font = Enum.Font.Gotham
    input.ClearTextOnFocus = false
    input.Parent = frame
    createCorner(input, 8)
    local stroke = createStroke(input, clr.separator, 1, 0.5)
    if multiline then
        input.TextYAlignment = Enum.TextYAlignment.Top
        input.MultiLine = true
        input.TextWrapped = true
        createPadding(input, 10)
    else
        createPadding(input, 10)
    end
    input.Focused:Connect(function()
        if isPremium and requiredTier and not hasFeatureAccess(requiredTier) then
            input:ReleaseFocus()
            showPremiumPrompt(labelText, requiredTier)
            return
        end
        tweenProperty(stroke, {Color = clr.accent, Transparency = 0}, 0.2)
    end)
    input.FocusLost:Connect(function()
        tweenProperty(stroke, {Color = clr.separator, Transparency = 0.5}, 0.2)
        if callback then callback(input.Text) end
    end)
    return frame, input
end

local function createButton(parent, text, callback, isPrimary, isPremium, requiredTier)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 44)
    btn.BackgroundColor3 = isPrimary and clr.accent or clr.surface
    btn.TextColor3 = clr.textPrimary
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.LayoutOrder = getNextLayoutOrder(parent.Name)
    btn.Parent = parent
    createCorner(btn, 10)
    if isPremium then
        btn.Text = "* " .. text
    else
        btn.Text = text
    end
    if isPrimary then
        createGradient(btn, clr.accentLight, clr.accentDark, 135)
    end
    local normalColor = isPrimary and clr.accent or clr.surface
    local hoverColor = isPrimary and clr.accentLight or clr.surfaceHover
    local pressColor = isPrimary and clr.accentDark or clr.surfaceActive
    addHoverEffect(btn, normalColor, hoverColor, pressColor)
    btn.MouseButton1Click:Connect(function()
        if isPremium and requiredTier and not hasFeatureAccess(requiredTier) then
            showPremiumPrompt(text, requiredTier)
            return
        end
        if callback then callback() end
    end)
    return btn
end

local function createDropdown(parent, labelText, options, defaultValue, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 75)
    frame.BackgroundColor3 = clr.surface
    frame.ClipsDescendants = false
    frame.LayoutOrder = getNextLayoutOrder(parent.Name)
    frame.Parent = parent
    createCorner(frame, 10)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 22)
    label.Position = UDim2.new(0, 14, 0, 8)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = clr.textPrimary
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    local dropBtn = Instance.new("TextButton")
    dropBtn.Size = UDim2.new(1, -28, 0, 34)
    dropBtn.Position = UDim2.new(0, 14, 0, 34)
    dropBtn.BackgroundColor3 = clr.bgTertiary
    dropBtn.Text = "  " .. defaultValue
    dropBtn.TextColor3 = clr.textPrimary
    dropBtn.TextSize = 13
    dropBtn.Font = Enum.Font.Gotham
    dropBtn.TextXAlignment = Enum.TextXAlignment.Left
    dropBtn.Parent = frame
    createCorner(dropBtn, 8)
    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 24, 1, 0)
    arrow.Position = UDim2.new(1, -30, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "v"
    arrow.TextColor3 = clr.textSecondary
    arrow.TextSize = 10
    arrow.Parent = dropBtn
    local dropList = Instance.new("Frame")
    dropList.Size = UDim2.new(1, -28, 0, #options * 38)
    dropList.Position = UDim2.new(0, 14, 0, 72)
    dropList.BackgroundColor3 = clr.bgTertiary
    dropList.Visible = false
    dropList.ZIndex = 100
    dropList.Parent = frame
    createCorner(dropList, 8)
    createShadow(dropList, 0.5)
    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 38)
        optBtn.Position = UDim2.new(0, 0, 0, (i - 1) * 38)
        optBtn.BackgroundTransparency = 1
        optBtn.Text = "  " .. opt
        optBtn.TextColor3 = clr.textPrimary
        optBtn.TextSize = 13
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextXAlignment = Enum.TextXAlignment.Left
        optBtn.ZIndex = 101
        optBtn.Parent = dropList
        optBtn.MouseEnter:Connect(function()
            tweenProperty(optBtn, {BackgroundTransparency = 0.8}, 0.1)
            optBtn.BackgroundColor3 = clr.accent
        end)
        optBtn.MouseLeave:Connect(function()
            tweenProperty(optBtn, {BackgroundTransparency = 1}, 0.1)
        end)
        optBtn.MouseButton1Click:Connect(function()
            dropBtn.Text = "  " .. opt
            dropList.Visible = false
            if callback then callback(opt) end
        end)
    end
    dropBtn.MouseButton1Click:Connect(function()
        dropList.Visible = not dropList.Visible
    end)
    return frame
end

local function createStatRow(parent, name, value)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 42)
    row.BackgroundColor3 = clr.surface
    row.LayoutOrder = getNextLayoutOrder(parent.Name)
    row.Parent = parent
    createCorner(row, 8)
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.6, -10, 1, 0)
    nameLabel.Position = UDim2.new(0, 14, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = name
    nameLabel.TextColor3 = clr.textSecondary
    nameLabel.TextSize = 13
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = row
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.Size = UDim2.new(0.4, -14, 1, 0)
    valueLabel.Position = UDim2.new(0.6, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(value)
    valueLabel.TextColor3 = clr.textPrimary
    valueLabel.TextSize = 13
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = row
    return row, valueLabel
end

local statusCard = Instance.new("Frame")
statusCard.Size = UDim2.new(1, 0, 0, 90)
statusCard.BackgroundColor3 = clr.surface
statusCard.LayoutOrder = getNextLayoutOrder(homeTab.Name)
statusCard.Parent = homeTab
createCorner(statusCard, 12)
createGradient(statusCard, clr.surface, clr.bgSecondary, 135)

local statusIcon = Instance.new("TextLabel")
statusIcon.Size = UDim2.new(0, 55, 0, 55)
statusIcon.Position = UDim2.new(0, 18, 0.5, -27)
statusIcon.BackgroundTransparency = 1
statusIcon.Text = "M"
statusIcon.TextSize = 40
statusIcon.Parent = statusCard

local statusTitle = Instance.new("TextLabel")
statusTitle.Size = UDim2.new(1, -100, 0, 26)
statusTitle.Position = UDim2.new(0, 80, 0, 18)
statusTitle.BackgroundTransparency = 1
statusTitle.Text = "Status: Inactive"
statusTitle.TextColor3 = clr.textPrimary
statusTitle.TextSize = 17
statusTitle.Font = Enum.Font.GothamBold
statusTitle.TextXAlignment = Enum.TextXAlignment.Left
statusTitle.Parent = statusCard

local statusSubtitle = Instance.new("TextLabel")
statusSubtitle.Size = UDim2.new(1, -100, 0, 20)
statusSubtitle.Position = UDim2.new(0, 80, 0, 46)
statusSubtitle.BackgroundTransparency = 1
statusSubtitle.Text = "Click toggle to enable"
statusSubtitle.TextColor3 = clr.textSecondary
statusSubtitle.TextSize = 12
statusSubtitle.Font = Enum.Font.Gotham
statusSubtitle.TextXAlignment = Enum.TextXAlignment.Left
statusSubtitle.Parent = statusCard

local statusIndicator = Instance.new("Frame")
statusIndicator.Size = UDim2.new(0, 14, 0, 14)
statusIndicator.Position = UDim2.new(1, -32, 0.5, -7)
statusIndicator.BackgroundColor3 = clr.error
statusIndicator.Parent = statusCard
createCorner(statusIndicator, 7)

local function updateHomeStatus()
    local enabled = getgenv().MapleConfig.MasterEnabled
    local afk = getgenv().MapleConfig.AFKMode
    if enabled then
        if afk then
            statusTitle.Text = "Status: AFK Mode"
            statusSubtitle.Text = "Auto-responding with AFK message"
            statusIndicator.BackgroundColor3 = clr.warning
        else
            statusTitle.Text = "Status: Active"
            statusSubtitle.Text = "Listening and responding to chat"
            statusIndicator.BackgroundColor3 = clr.success
        end
    else
        statusTitle.Text = "Status: Inactive"
        statusSubtitle.Text = "Click toggle to enable"
        statusIndicator.BackgroundColor3 = clr.error
    end
end

createSectionLabel(homeTab, "QUICK CONTROLS")

local _, masterToggleSet = createToggle(homeTab, "Enable AI Responses", getgenv().MapleConfig.MasterEnabled, function(value)
    getgenv().MapleConfig.MasterEnabled = value
    saveConfig()
    updateStatusDot()
    updateHomeStatus()
    showToast(value and "AI Enabled" or "AI Disabled", value and "success" or "info")
end)

createToggle(homeTab, "AFK Mode", getgenv().MapleConfig.AFKMode, function(value)
    getgenv().MapleConfig.AFKMode = value
    saveConfig()
    updateHomeStatus()
    showToast(value and "AFK Mode Enabled" or "AFK Mode Disabled", "info")
end)

createSectionLabel(homeTab, "QUICK ACTIONS")

createButton(homeTab, "Clear All History", function()
    playerMemory = {}
    showToast("All conversation history cleared", "success")
end)

createButton(homeTab, "Clear Response Cache", function()
    responseCache = {}
    cacheOrder = {}
    stats.cacheHits = 0
    showToast("Response cache cleared", "success")
end)

createSectionLabel(settingsTab, "RESPONSE RANGE")

createSlider(settingsTab, "Range (studs) - 0 = Unlimited", 0, 500, getgenv().MapleConfig.Range, function(value)
    getgenv().MapleConfig.Range = value
    saveConfig()
end)

createSectionLabel(settingsTab, "TRIGGER MODE")

createDropdown(settingsTab, "When to respond", {"all", "mention", "prefix"}, getgenv().MapleConfig.TriggerMode, function(value)
    getgenv().MapleConfig.TriggerMode = value
    saveConfig()
    showToast("Trigger mode: " .. value, "info")
end)

createInput(settingsTab, "Prefix (for prefix mode)", "@maple", getgenv().MapleConfig.TriggerPrefix, false, function(text)
    getgenv().MapleConfig.TriggerPrefix = text
    saveConfig()
end)

createToggle(settingsTab, "Debug Mode", getgenv().MapleConfig.DebugMode, function(value)
    getgenv().MapleConfig.DebugMode = value
    dbg = value
    saveConfig()
end)

createSectionLabel(advancedTab, "RESPONSE SETTINGS")

createSlider(advancedTab, "Response Delay", USER_LIMITS.minResponseDelay, USER_LIMITS.maxResponseDelay, math.max(getgenv().MapleConfig.ResponseDelay, USER_LIMITS.minResponseDelay), function(value)
    getgenv().MapleConfig.ResponseDelay = math.max(value, USER_LIMITS.minResponseDelay)
    saveConfig()
end)

createSectionLabel(advancedTab, "ANTI-SPAM")

createToggle(advancedTab, "Enable Anti-Spam", getgenv().MapleConfig.AntiSpam, function(value)
    getgenv().MapleConfig.AntiSpam = value
    saveConfig()
end)

createSectionLabel(advancedTab, "AFK SETTINGS")

createInput(advancedTab, "AFK Message", "Your AFK message...", getgenv().MapleConfig.AFKMessage, false, function(text)
    getgenv().MapleConfig.AFKMessage = text
    saveConfig()
end)

createToggle(advancedTab, "Auto Retry on Error", getgenv().MapleConfig.AutoRetry, function(value)
    getgenv().MapleConfig.AutoRetry = value
    saveConfig()
end)

createSectionLabel(advancedTab, "DANGER ZONE")

createButton(advancedTab, "Reset to Defaults", function()
    for k, v in pairs(defCfg) do
        getgenv().MapleConfig[k] = v
    end
    saveConfig()
    showToast("Settings reset - reload script to apply", "warning", 4)
end)

createSectionLabel(contextTab, "CONTEXT SETTINGS")

createToggle(contextTab, "Smart Context Analysis", getgenv().MapleConfig.SmartContextEnabled, function(value)
    getgenv().MapleConfig.SmartContextEnabled = value
    saveConfig()
end)

createToggle(contextTab, "Show Timestamps to AI", getgenv().MapleConfig.ShowTimestamps, function(value)
    getgenv().MapleConfig.ShowTimestamps = value
    saveConfig()
end)

createSectionLabel(contextTab, "TIMING")

local maxTimeout = math.min(USER_LIMITS.memoryExpireMinutes, 120)
createSlider(contextTab, "Context Timeout (min)", 1, maxTimeout, math.min(getgenv().MapleConfig.ContextTimeoutMinutes, maxTimeout), function(value)
    getgenv().MapleConfig.ContextTimeoutMinutes = math.min(value, maxTimeout)
    saveConfig()
end)

createSlider(contextTab, "Long Gap Threshold (min)", 1, 60, getgenv().MapleConfig.LongGapMinutes, function(value)
    getgenv().MapleConfig.LongGapMinutes = value
    saveConfig()
end)

createSectionLabel(contextTab, "MEMORY MANAGEMENT")

createButton(contextTab, "Clear All Player Memory", function()
    playerMemory = {}
    showToast("All player memory cleared", "success")
end)

createButton(contextTab, "View Memory Stats", function()
    local totalMsgs = 0
    local playerCount = 0
    for _, data in pairs(playerMemory) do
        playerCount = playerCount + 1
        if data.messages then
            totalMsgs = totalMsgs + #data.messages
        end
    end
    showToast(string.format("Memory: %d players, %d messages", playerCount, totalMsgs), "info", 4)
end)

createSectionLabel(personaTab, "SYSTEM INSTRUCTIONS")

local personaInput
if canAccessFeature("canChangePersona") then
    local _, pInput = createInput(personaTab, "AI Persona", "Describe how the AI should behave...", getgenv().MapleConfig.Persona, true, function(text)
        getgenv().MapleConfig.Persona = text
        saveConfig()
        showToast("Persona updated", "success")
    end)
    personaInput = pInput
else
    local personaFrame = Instance.new("Frame")
    personaFrame.Size = UDim2.new(1, 0, 0, 100)
    personaFrame.BackgroundColor3 = clr.surface
    personaFrame.LayoutOrder = getNextLayoutOrder(personaTab.Name)
    personaFrame.Parent = personaTab
    createCorner(personaFrame, 10)
    local personaLock = Instance.new("TextLabel")
    personaLock.Size = UDim2.new(1, -28, 1, 0)
    personaLock.Position = UDim2.new(0, 14, 0, 0)
    personaLock.BackgroundTransparency = 1
    personaLock.Text = "Custom Persona (VIP+ Required)\n\nUpgrade to customize how the AI responds!\nFree users can use presets below."
    personaLock.TextColor3 = clr.textTertiary
    personaLock.TextSize = 12
    personaLock.Font = Enum.Font.Gotham
    personaLock.TextWrapped = true
    personaLock.TextXAlignment = Enum.TextXAlignment.Left
    personaLock.Parent = personaFrame
end

createSectionLabel(personaTab, "QUICK PRESETS")

local presets = {
    {name = "Helpful Assistant", persona = "You are a helpful AI assistant in a Roblox game. Be friendly, concise, and informative. Keep responses under 3 sentences.", tier = TIERS.FREE},
    {name = "Casual Gamer", persona = "You are a fellow gamer hanging out in Roblox. Use casual language, gaming slang, and be enthusiastic. Keep it short and fun!", tier = TIERS.FREE},
    {name = "Friendly Guide", persona = "You are a friendly guide helping players. Be patient, encouraging, and helpful. Give clear, simple answers.", tier = TIERS.FREE},
    {name = "Sarcastic Bot", persona = "You are a sarcastic but ultimately helpful AI. Use witty humor and playful sarcasm, but still answer questions helpfully.", tier = TIERS.VIP},
    {name = "Roleplay Character", persona = "You are an in-game character. Stay in character, be creative and engaging. Respond as if you're part of the game world.", tier = TIERS.VIP},
    {name = "Pro Analyst", persona = "You are a professional game analyst. Provide detailed, insightful responses about game mechanics, strategies, and tips.", tier = TIERS.PREMIUM},
    {name = "Comedian", persona = "You are a stand-up comedian. Every response should be funny, punny, or humorous. Make players laugh!", tier = TIERS.PREMIUM},
    {name = "Custom AI", persona = "You are a fully customizable AI with no restrictions on personality. Adapt to any conversation style the user prefers.", tier = TIERS.ULTIMATE},
}

for _, preset in ipairs(presets) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundColor3 = clr.surface
    btn.TextColor3 = clr.textPrimary
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamMedium
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.LayoutOrder = getNextLayoutOrder(personaTab.Name)
    btn.Parent = personaTab
    createCorner(btn, 8)
    addHoverEffect(btn, clr.surface, clr.surfaceHover)
    local tierIcon = ""
    if preset.tier == TIERS.VIP then tierIcon = " [VIP]"
    elseif preset.tier == TIERS.PREMIUM then tierIcon = " [PRO]"
    elseif preset.tier == TIERS.ULTIMATE then tierIcon = " [ULT]"
    end
    btn.Text = "  " .. preset.name .. tierIcon
    btn.MouseButton1Click:Connect(function()
        if not hasFeatureAccess(preset.tier) then
            showPremiumPrompt(preset.name .. " Preset", preset.tier)
            return
        end
        if personaInput then
            personaInput.Text = preset.persona
        end
        getgenv().MapleConfig.Persona = preset.persona
        saveConfig()
        showToast("Applied: " .. preset.name, "success")
    end)
end

createSectionLabel(modelsTab, "FREE MODELS")

local modelButtons = {}

local function createModelCard(model, tier, desc)
    local tierIcons = {
        [TIERS.FREE] = "",
        [TIERS.VIP] = " [VIP]",
        [TIERS.PREMIUM] = " [PRO]",
        [TIERS.ULTIMATE] = " [ULT]",
    }
    local modelFrame = Instance.new("Frame")
    modelFrame.Name = "Model_" .. model
    modelFrame.Size = UDim2.new(1, 0, 0, 58)
    modelFrame.BackgroundColor3 = getgenv().MapleConfig.Model == model and clr.accent or clr.surface
    modelFrame.LayoutOrder = getNextLayoutOrder(modelsTab.Name)
    modelFrame.Parent = modelsTab
    createCorner(modelFrame, 10)
    modelButtons[model] = modelFrame
    local modelName = Instance.new("TextLabel")
    modelName.Size = UDim2.new(1, -20, 0, 22)
    modelName.Position = UDim2.new(0, 14, 0, 10)
    modelName.BackgroundTransparency = 1
    modelName.Text = model .. (tierIcons[tier] or "")
    modelName.TextColor3 = clr.textPrimary
    modelName.TextSize = 14
    modelName.Font = Enum.Font.GothamBold
    modelName.TextXAlignment = Enum.TextXAlignment.Left
    modelName.Parent = modelFrame
    local modelDesc = Instance.new("TextLabel")
    modelDesc.Size = UDim2.new(1, -20, 0, 16)
    modelDesc.Position = UDim2.new(0, 14, 0, 32)
    modelDesc.BackgroundTransparency = 1
    modelDesc.Text = desc
    modelDesc.TextColor3 = clr.textSecondary
    modelDesc.TextSize = 11
    modelDesc.Font = Enum.Font.Gotham
    modelDesc.TextXAlignment = Enum.TextXAlignment.Left
    modelDesc.Parent = modelFrame
    local selectBtn = Instance.new("TextButton")
    selectBtn.Size = UDim2.new(1, 0, 1, 0)
    selectBtn.BackgroundTransparency = 1
    selectBtn.Text = ""
    selectBtn.Parent = modelFrame
    selectBtn.MouseButton1Click:Connect(function()
        if not hasFeatureAccess(tier) then
            showPremiumPrompt(model, tier)
            return
        end
        getgenv().MapleConfig.Model = model
        saveConfig()
        for id, frame in pairs(modelButtons) do
            frame.BackgroundColor3 = clr.surface
        end
        modelFrame.BackgroundColor3 = clr.accent
        showToast("Model: " .. model, "success")
    end)
    selectBtn.MouseEnter:Connect(function()
        if getgenv().MapleConfig.Model ~= model then
            tweenProperty(modelFrame, {BackgroundColor3 = clr.surfaceHover}, 0.15)
        end
    end)
    selectBtn.MouseLeave:Connect(function()
        if getgenv().MapleConfig.Model ~= model then
            tweenProperty(modelFrame, {BackgroundColor3 = clr.surface}, 0.15)
        end
    end)
end

for _, model in ipairs(FREE_MODELS) do
    createModelCard(model, TIERS.FREE, "Free tier - Available to all users")
end

createSectionLabel(modelsTab, "VIP MODELS", true)

for _, model in ipairs(VIP_MODELS) do
    createModelCard(model, TIERS.VIP, "VIP tier - Requires VIP access")
end

createSectionLabel(modelsTab, "PREMIUM MODELS", true)

for _, model in ipairs(PREMIUM_MODELS) do
    createModelCard(model, TIERS.PREMIUM, "Premium tier - High performance models")
end

createSectionLabel(modelsTab, "ULTIMATE MODELS", true)

for _, model in ipairs(ULTIMATE_MODELS) do
    createModelCard(model, TIERS.ULTIMATE, "Ultimate tier - Most powerful models")
end

createSectionLabel(blacklistTab, "ADD PLAYER")

local addPlayerFrame = Instance.new("Frame")
addPlayerFrame.Size = UDim2.new(1, 0, 0, 44)
addPlayerFrame.BackgroundTransparency = 1
addPlayerFrame.LayoutOrder = getNextLayoutOrder(blacklistTab.Name)
addPlayerFrame.Parent = blacklistTab

local playerInput = Instance.new("TextBox")
playerInput.Size = UDim2.new(1, -54, 1, 0)
playerInput.BackgroundColor3 = clr.surface
playerInput.PlaceholderText = "Player username..."
playerInput.PlaceholderColor3 = clr.textTertiary
playerInput.TextColor3 = clr.textPrimary
playerInput.TextSize = 13
playerInput.Font = Enum.Font.Gotham
playerInput.ClearTextOnFocus = false
playerInput.Parent = addPlayerFrame
createCorner(playerInput, 8)
createPadding(playerInput, 12)

local addPlayerBtn = Instance.new("TextButton")
addPlayerBtn.Size = UDim2.new(0, 44, 1, 0)
addPlayerBtn.Position = UDim2.new(1, -44, 0, 0)
addPlayerBtn.BackgroundColor3 = clr.accent
addPlayerBtn.Text = "+"
addPlayerBtn.TextColor3 = clr.textPrimary
addPlayerBtn.TextSize = 22
addPlayerBtn.Font = Enum.Font.GothamBold
addPlayerBtn.Parent = addPlayerFrame
createCorner(addPlayerBtn, 8)
addHoverEffect(addPlayerBtn, clr.accent, clr.accentLight)

createSectionLabel(blacklistTab, "BLACKLISTED PLAYERS")

local blacklistScroll = Instance.new("Frame")
blacklistScroll.Size = UDim2.new(1, 0, 0, 280)
blacklistScroll.BackgroundTransparency = 1
blacklistScroll.LayoutOrder = getNextLayoutOrder(blacklistTab.Name)
blacklistScroll.Parent = blacklistTab

local blacklistLayout = Instance.new("UIListLayout")
blacklistLayout.Parent = blacklistScroll
blacklistLayout.Padding = UDim.new(0, 6)

local function refreshBlacklist()
    for _, child in ipairs(blacklistScroll:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    if #getgenv().MapleConfig.Blacklist == 0 then
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Size = UDim2.new(1, 0, 0, 60)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.Text = "No blacklisted players\nAdd players above to ignore them"
        emptyLabel.TextColor3 = clr.textTertiary
        emptyLabel.TextSize = 13
        emptyLabel.Font = Enum.Font.Gotham
        emptyLabel.Parent = blacklistScroll
    else
        for i, playerName in ipairs(getgenv().MapleConfig.Blacklist) do
            local item = Instance.new("Frame")
            item.Size = UDim2.new(1, 0, 0, 40)
            item.BackgroundColor3 = clr.surface
            item.Parent = blacklistScroll
            createCorner(item, 8)
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -54, 1, 0)
            nameLabel.Position = UDim2.new(0, 14, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = playerName
            nameLabel.TextColor3 = clr.textPrimary
            nameLabel.TextSize = 13
            nameLabel.Font = Enum.Font.GothamMedium
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = item
            local removeBtn = Instance.new("TextButton")
            removeBtn.Size = UDim2.new(0, 40, 1, -10)
            removeBtn.Position = UDim2.new(1, -45, 0, 5)
            removeBtn.BackgroundColor3 = clr.error
            removeBtn.BackgroundTransparency = 0.8
            removeBtn.Text = "x"
            removeBtn.TextColor3 = clr.error
            removeBtn.TextSize = 18
            removeBtn.Font = Enum.Font.GothamBold
            removeBtn.Parent = item
            createCorner(removeBtn, 6)
            removeBtn.MouseButton1Click:Connect(function()
                table.remove(getgenv().MapleConfig.Blacklist, i)
                saveConfig()
                refreshBlacklist()
                showToast("Removed " .. playerName, "info")
            end)
        end
    end
end

addPlayerBtn.MouseButton1Click:Connect(function()
    local name = playerInput.Text:gsub("^%s*(.-)%s*$", "%1")
    if name ~= "" then
        if table.find(getgenv().MapleConfig.Blacklist, name) then
            showToast(name .. " is already blacklisted", "warning")
        else
            table.insert(getgenv().MapleConfig.Blacklist, name)
            saveConfig()
            refreshBlacklist()
            playerInput.Text = ""
            showToast("Blacklisted " .. name, "success")
        end
    end
end)

refreshBlacklist()

createSectionLabel(statsTab, "SESSION STATISTICS")

local _, msgCountLabel = createStatRow(statsTab, "Messages Received", 0)
local _, respCountLabel = createStatRow(statsTab, "Responses Sent", 0)
local _, errCountLabel = createStatRow(statsTab, "Errors", 0)
local _, cacheHitLabel = createStatRow(statsTab, "Cache Hits", 0)
local _, apiCallLabel = createStatRow(statsTab, "API Calls", 0)
local _, avgTimeLabel = createStatRow(statsTab, "Avg Response Time", "0ms")
local _, contextSwitchLabel = createStatRow(statsTab, "Context Switches", 0)
local _, uptimeLabel = createStatRow(statsTab, "Uptime", "0s")
local _, memoryLabel = createStatRow(statsTab, "Memory Usage", "0 msgs / 0 players")

createSectionLabel(statsTab, "SYSTEM INFO")

local _, executorLabel = createStatRow(statsTab, "Executor", ExecutorInfo.name)
local _, tierLabel = createStatRow(statsTab, "Account Tier", getTierName(USER_TIER))

task.spawn(function()
    while gui.Parent do
        task.wait(1)
        local uptime = math.floor(tick() - startTime)
        uptimeLabel.Text = formatUptime(uptime)
        msgCountLabel.Text = tostring(stats.messagesReceived)
        respCountLabel.Text = tostring(stats.responsesSent)
        errCountLabel.Text = tostring(stats.errors)
        cacheHitLabel.Text = tostring(stats.cacheHits)
        apiCallLabel.Text = tostring(stats.apiCalls)
        contextSwitchLabel.Text = tostring(stats.contextSwitches)
        if stats.responsesSent > 0 then
            avgTimeLabel.Text = string.format("%.0fms", stats.totalResponseTime / stats.responsesSent)
        end
        local totalMsgs = 0
        local playerCount = 0
        for _, data in pairs(playerMemory) do
            playerCount = playerCount + 1
            if data.messages then
                totalMsgs = totalMsgs + #data.messages
            end
        end
        memoryLabel.Text = string.format("%d msgs / %d players", totalMsgs, playerCount)
    end
end)

createSectionLabel(premiumTab, "YOUR MEMBERSHIP")

local premiumCard = Instance.new("Frame")
premiumCard.Size = UDim2.new(1, 0, 0, 120)
premiumCard.BackgroundColor3 = clr.surface
premiumCard.LayoutOrder = getNextLayoutOrder(premiumTab.Name)
premiumCard.Parent = premiumTab
createCorner(premiumCard, 12)
createGradient(premiumCard, getTierColor(USER_TIER), clr.surface, 45)

local premiumBadge = Instance.new("TextLabel")
premiumBadge.Size = UDim2.new(1, 0, 0, 50)
premiumBadge.Position = UDim2.new(0, 0, 0, 15)
premiumBadge.BackgroundTransparency = 1
premiumBadge.Text = USER_TIER >= TIERS.ULTIMATE and "ULT" or (USER_TIER >= TIERS.PREMIUM and "PRO" or (USER_TIER >= TIERS.VIP and "VIP" or "FREE"))
premiumBadge.TextSize = 40
premiumBadge.Parent = premiumCard

local premiumTierLabel = Instance.new("TextLabel")
premiumTierLabel.Size = UDim2.new(1, 0, 0, 26)
premiumTierLabel.Position = UDim2.new(0, 0, 0, 65)
premiumTierLabel.BackgroundTransparency = 1
premiumTierLabel.Text = getTierName(USER_TIER) .. " Member"
premiumTierLabel.TextColor3 = getTierColor(USER_TIER)
premiumTierLabel.TextSize = 18
premiumTierLabel.Font = Enum.Font.GothamBold
premiumTierLabel.Parent = premiumCard

local premiumSubLabel = Instance.new("TextLabel")
premiumSubLabel.Size = UDim2.new(1, 0, 0, 18)
premiumSubLabel.Position = UDim2.new(0, 0, 0, 92)
premiumSubLabel.BackgroundTransparency = 1
premiumSubLabel.Text = USER_TIER >= TIERS.VIP and "Thank you for supporting Maple AI!" or "Upgrade for exclusive features"
premiumSubLabel.TextColor3 = clr.textSecondary
premiumSubLabel.TextSize = 12
premiumSubLabel.Font = Enum.Font.Gotham
premiumSubLabel.Parent = premiumCard

createSectionLabel(premiumTab, "GET PREMIUM")

createButton(premiumTab, "Contact " .. DISCORD_CONTACT, function()
    if setclipboard then
        setclipboard(DISCORD_CONTACT)
        showToast("Discord copied to clipboard!", "success")
    elseif toclipboard then
        toclipboard(DISCORD_CONTACT)
        showToast("Discord copied to clipboard!", "success")
    else
        showToast("Discord: " .. DISCORD_CONTACT, "info", 5)
    end
end, true)

local isMinimized = false

fabButton.MouseButton1Click:Connect(function()
    if isDraggingFab() then return end
    mainWindow.Visible = not mainWindow.Visible
    if mainWindow.Visible then
        mainWindow.Size = UDim2.new(0, 620, 0, 0)
        mainWindow.BackgroundTransparency = 1
        springTween(mainWindow, {Size = UDim2.new(0, 620, 0, 480), BackgroundTransparency = 0}, 0.4)
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    tweenProperty(mainWindow, {Size = UDim2.new(0, 620, 0, 0), BackgroundTransparency = 1}, 0.25)
    task.wait(0.25)
    mainWindow.Visible = false
end)

minBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        tweenProperty(mainWindow, {Size = UDim2.new(0, 620, 0, 54)}, 0.3)
    else
        tweenProperty(mainWindow, {Size = UDim2.new(0, 620, 0, 480)}, 0.3)
    end
end)

tabButtons["Home"].MouseButton1Click:Fire()
updateStatusDot()
updateHomeStatus()

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
    local myCharacter = lp.Character
    if not myCharacter then return 999999 end
    local myRoot = myCharacter:FindFirstChild("HumanoidRootPart")
    if not myRoot then return 999999 end
    local theirRoot = character:FindFirstChild("HumanoidRootPart")
    if not theirRoot then return 999999 end
    return (theirRoot.Position - myRoot.Position).Magnitude
end

local function facePlayer(character)
    if not character then return end
    local myCharacter = lp.Character
    if not myCharacter then return end
    local myRoot = myCharacter:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local theirRoot = character:FindFirstChild("HumanoidRootPart")
    if not theirRoot then return end
    pcall(function()
        local direction = (theirRoot.Position - myRoot.Position).Unit
        local lookAt = CFrame.lookAt(myRoot.Position, myRoot.Position + direction)
        ts:Create(myRoot, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {CFrame = lookAt}):Play()
    end)
end

local function isFriend(player)
    local success, result = pcall(function()
        return lp:IsFriendsWith(player.UserId)
    end)
    return success and result
end

local function isSpamming(player, message)
    if not getgenv().MapleConfig.AntiSpam then return false end
    local userId = player.UserId
    if not spamTracker[userId] then
        spamTracker[userId] = {}
    end
    local now = tick()
    local cooldown = getgenv().MapleConfig.SpamCooldown or 30
    local cleanedEntries = {}
    for _, entry in ipairs(spamTracker[userId]) do
        if now - entry.time < cooldown then
            table.insert(cleanedEntries, entry)
        end
    end
    spamTracker[userId] = cleanedEntries
    local count = 0
    for _, entry in ipairs(spamTracker[userId]) do
        if entry.message == message then
            count = count + 1
        end
    end
    table.insert(spamTracker[userId], {message = message, time = now})
    return count >= getgenv().MapleConfig.SpamThreshold
end

local function shouldRespondToMessage(player, message)
    local cfg = getgenv().MapleConfig
    local mode = cfg.TriggerMode
    if mode == "all" then
        return true
    elseif mode == "mention" then
        local lower = message:lower()
        return lower:find("maple") or
               lower:find(lp.Name:lower()) or
               lower:find(lp.DisplayName:lower())
    elseif mode == "prefix" then
        return message:sub(1, #cfg.TriggerPrefix):lower() == cfg.TriggerPrefix:lower()
    end
    return true
end

local function getCacheKey(message)
    return message:lower():gsub("%s+", " "):gsub("[^%w%s]", "")
end

local function checkCache(message)
    local key = getCacheKey(message)
    local entry = responseCache[key]
    if entry and tick() - entry.timestamp < CACHE_TTL then
        stats.cacheHits = stats.cacheHits + 1
        for i, k in ipairs(cacheOrder) do
            if k == key then
                table.remove(cacheOrder, i)
                break
            end
        end
        table.insert(cacheOrder, key)
        return entry.response
    end
    return nil
end

local function addToCache(message, response)
    local key = getCacheKey(message)
    while #cacheOrder >= CACHE_MAX_SIZE do
        local oldKey = table.remove(cacheOrder, 1)
        responseCache[oldKey] = nil
    end
    responseCache[key] = {
        response = response,
        timestamp = tick()
    }
    table.insert(cacheOrder, key)
end

local function getPlayerMemory(player)
    local userId = tostring(player.UserId)
    if not playerMemory[userId] then
        playerMemory[userId] = {
            displayName = player.DisplayName,
            username = player.Name,
            messages = {},
            lastInteraction = tick(),
            totalMessages = 0,
        }
    end
    return playerMemory[userId]
end

local function addMessageToMemory(player, message, role)
    local memory = getPlayerMemory(player)
    local now = tick()
    table.insert(memory.messages, {
        role = role,
        content = message,
        timestamp = now,
    })
    memory.lastInteraction = now
    memory.totalMessages = memory.totalMessages + 1
    local maxMessages = MAX_MEMORY_SIZE
    if getgenv().MapleConfig.RememberForever and USER_TIER >= TIERS.PREMIUM then
        maxMessages = 9999
    end
    while #memory.messages > maxMessages do
        table.remove(memory.messages, 1)
    end
end

local function buildContextMessages(player, currentMessage)
    local cfg = getgenv().MapleConfig
    local memory = getPlayerMemory(player)
    local messages = {}
    local systemPrompt = cfg.Persona .. "\n\n"
    systemPrompt = systemPrompt .. "CONTEXT:\n"
    systemPrompt = systemPrompt .. "- You are chatting in a Roblox game\n"
    systemPrompt = systemPrompt .. "- The player's display name is: " .. player.DisplayName .. "\n"
    systemPrompt = systemPrompt .. "- The player's username is: " .. player.Name .. "\n"
    systemPrompt = systemPrompt .. "- Keep responses SHORT (under 200 characters for Roblox chat)\n"
    systemPrompt = systemPrompt .. "- Be natural and conversational\n"
    systemPrompt = systemPrompt .. "- Don't use markdown or special formatting\n"
    if cfg.SmartContextEnabled and #memory.messages > 0 then
        local timeSinceLastMsg = tick() - memory.lastInteraction
        if timeSinceLastMsg > (cfg.LongGapMinutes or 5) * 60 then
            systemPrompt = systemPrompt .. "- Note: It's been a while since your last conversation with this player\n"
            stats.contextSwitches = stats.contextSwitches + 1
        end
    end
    table.insert(messages, {
        role = "system",
        content = systemPrompt
    })
    local windowSize = cfg.ContextWindowSize or 10
    local startIdx = math.max(1, #memory.messages - windowSize + 1)
    for i = startIdx, #memory.messages do
        local msg = memory.messages[i]
        if cfg.ShowTimestamps then
            local timeAgo = formatTimeAgo(tick() - msg.timestamp)
            table.insert(messages, {
                role = msg.role,
                content = string.format("[%s] %s", timeAgo, msg.content)
            })
        else
            table.insert(messages, {
                role = msg.role,
                content = msg.content
            })
        end
    end
    table.insert(messages, {
        role = "user",
        content = currentMessage
    })
    return messages
end

local function makeAPIRequest(messages, retryCount)
    retryCount = retryCount or 0
    local cfg = getgenv().MapleConfig
    if not httpRequest then
        return nil, "No HTTP request function available"
    end
    local apiKey = SHARED_API_KEY
    if apiKey == "" or apiKey == "YOUR_API_KEY_HERE" then
        return nil, "API not configured (contact admin)"
    end
    local now = tick()
    if now > rateLimitTracker.resetTime then
        rateLimitTracker.count = 0
        rateLimitTracker.resetTime = now + RATE_LIMIT_WINDOW
    end
    if rateLimitTracker.count >= USER_LIMITS.requestsPerMinute then
        local waitTime = math.ceil(rateLimitTracker.resetTime - now)
        return nil, "Rate limit! Wait " .. waitTime .. "s"
    end
    if now > rateLimitHourly.resetTime then
        rateLimitHourly.count = 0
        rateLimitHourly.resetTime = now + 3600
    end
    if rateLimitHourly.count >= USER_LIMITS.requestsPerHour then
        local waitTime = math.ceil((rateLimitHourly.resetTime - now) / 60)
        return nil, "Hourly limit reached! Wait " .. waitTime .. " min"
    end
    if now > rateLimitDaily.resetTime then
        rateLimitDaily.count = 0
        rateLimitDaily.resetTime = now + 86400
    end
    if rateLimitDaily.count >= USER_LIMITS.requestsPerDay then
        return nil, "Daily limit reached!"
    end
    rateLimitTracker.count = rateLimitTracker.count + 1
    rateLimitHourly.count = rateLimitHourly.count + 1
    rateLimitDaily.count = rateLimitDaily.count + 1
    stats.apiCalls = stats.apiCalls + 1
    local maxTokens = math.min(cfg.MaxTokens, USER_LIMITS.maxTokens)
    local requestBody = {
        model = cfg.Model,
        messages = messages,
        max_tokens = maxTokens,
        temperature = cfg.Temperature,
    }
    local success, result = pcall(function()
        return httpRequest({
            Url = API_BASE .. "/chat/completions",
            Method = "POST",
            Headers = {
                ["Authorization"] = "Bearer " .. apiKey,
                ["Content-Type"] = "application/json"
            },
            Body = http:JSONEncode(requestBody)
        })
    end)
    if not success then
        log("HTTP request failed:", result)
        if cfg.AutoRetry and retryCount < (cfg.MaxRetries or MAX_RETRIES) then
            task.wait(1 * (retryCount + 1))
            return makeAPIRequest(messages, retryCount + 1)
        end
        return nil, "HTTP request failed: " .. tostring(result)
    end
    if not result or not result.Body then
        return nil, "Empty response from API"
    end
    local decodeSuccess, data = pcall(function()
        return http:JSONDecode(result.Body)
    end)
    if not decodeSuccess then
        return nil, "Failed to parse API response"
    end
    if data.error then
        local errorMsg = data.error.message or "Unknown API error"
        log("API error:", errorMsg)
        if cfg.AutoRetry and retryCount < (cfg.MaxRetries or MAX_RETRIES) then
            if errorMsg:lower():find("rate") or errorMsg:lower():find("overload") then
                task.wait(2 * (retryCount + 1))
                return makeAPIRequest(messages, retryCount + 1)
            end
        end
        return nil, errorMsg
    end
    if data.choices and data.choices[1] and data.choices[1].message then
        return data.choices[1].message.content, nil
    end
    return nil, "Unexpected API response format"
end

local function processMessage(player, message)
    local cfg = getgenv().MapleConfig
    local processStartTime = tick()
    stats.messagesReceived = stats.messagesReceived + 1
    log("Processing message from", player.Name, ":", message)
    if cfg.AFKMode then
        task.wait(cfg.ResponseDelay or 0.5)
        sendMessage(cfg.AFKMessage)
        stats.responsesSent = stats.responsesSent + 1
        return
    end
    local cachedResponse = checkCache(message)
    if cachedResponse then
        log("Cache hit!")
        addMessageToMemory(player, message, "user")
        addMessageToMemory(player, cachedResponse, "assistant")
        task.wait(cfg.ResponseDelay or 0.5)
        sendMessage(cachedResponse)
        stats.responsesSent = stats.responsesSent + 1
        local elapsed = (tick() - processStartTime) * 1000
        stats.totalResponseTime = stats.totalResponseTime + elapsed
        return
    end
    local contextMessages = buildContextMessages(player, message)
    local response, err = makeAPIRequest(contextMessages)
    if err then
        logError("API request failed:", err)
        stats.errors = stats.errors + 1
        showToast("API Error: " .. err:sub(1, 50), "error")
        return
    end
    if response then
        response = response:gsub("^%s*(.-)%s*$", "%1")
        response = response:gsub("\n", " ")
        if #response > MAX_MSG_LENGTH then
            response = response:sub(1, MAX_MSG_LENGTH - 3) .. "..."
        end
        addMessageToMemory(player, message, "user")
        addMessageToMemory(player, response, "assistant")
        addToCache(message, response)
        task.wait(cfg.ResponseDelay or 0.5)
        if player.Character then
            facePlayer(player.Character)
        end
        sendMessage(response)
        stats.responsesSent = stats.responsesSent + 1
        local elapsed = (tick() - processStartTime) * 1000
        stats.totalResponseTime = stats.totalResponseTime + elapsed
        log("Response sent in", string.format("%.0f", elapsed), "ms")
    end
end

local function onChatMessage(player, message)
    local cfg = getgenv().MapleConfig
    logPlayerToWebhook(player)
    if not cfg.MasterEnabled then return end
    if player == lp then return end
    if table.find(cfg.Blacklist, player.Name) or table.find(cfg.Blacklist, player.DisplayName) then
        log("Ignored blacklisted player:", player.Name)
        return
    end
    if #cfg.Whitelist > 0 then
        local whitelisted = table.find(cfg.Whitelist, player.Name) or
                           table.find(cfg.Whitelist, player.DisplayName) or
                           (cfg.AutoWhitelistFriends and isFriend(player))
        if not whitelisted then
            log("Ignored non-whitelisted player:", player.Name)
            return
        end
    end
    if cfg.Range > 0 then
        local distance = getPlayerDistance(player.Character)
        if distance > cfg.Range then
            log("Player out of range:", player.Name, distance, "studs")
            return
        end
    end
    if not shouldRespondToMessage(player, message) then
        log("Message didn't match trigger mode")
        return
    end
    if isSpamming(player, message) then
        log("Spam detected from:", player.Name)
        return
    end
    task.spawn(function()
        processing = true
        local success, err = pcall(function()
            processMessage(player, message)
        end)
        if not success then
            logError("Error processing message:", err)
            stats.errors = stats.errors + 1
        end
        processing = false
    end)
end

local function setupChatListeners()
    pcall(function()
        if tcs then
            addConnection(tcs.MessageReceived:Connect(function(textChatMessage)
                local textSource = textChatMessage.TextSource
                if textSource then
                    local player = plrs:GetPlayerByUserId(textSource.UserId)
                    if player then
                        onChatMessage(player, textChatMessage.Text)
                    end
                end
            end), "TextChatListener")
            log("Connected to TextChatService")
        end
    end)
    pcall(function()
        for _, player in ipairs(plrs:GetPlayers()) do
            if player ~= lp then
                pcall(function()
                    addConnection(player.Chatted:Connect(function(message)
                        onChatMessage(player, message)
                    end), "LegacyChat_" .. player.UserId)
                end)
            end
        end
        addConnection(plrs.PlayerAdded:Connect(function(player)
            if player ~= lp then
                pcall(function()
                    addConnection(player.Chatted:Connect(function(message)
                        onChatMessage(player, message)
                    end), "LegacyChat_" .. player.UserId)
                end)
            end
        end), "PlayerAddedListener")
        log("Connected to legacy chat")
    end)
end

setupChatListeners()

addConnection(uis.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        mainWindow.Visible = not mainWindow.Visible
        if mainWindow.Visible then
            mainWindow.Size = UDim2.new(0, 620, 0, 0)
            springTween(mainWindow, {Size = UDim2.new(0, 620, 0, 480)}, 0.4)
        end
    end
end), "KeybindListener")

local tierAnnouncement = {
    [TIERS.FREE] = {"Welcome!", "info"},
    [TIERS.VIP] = {"VIP Member! Enjoy exclusive features.", "premium"},
    [TIERS.PREMIUM] = {"Premium Member! Full access unlocked.", "premium"},
    [TIERS.ULTIMATE] = {"Ultimate Member! All features unlocked.", "premium"},
}

local announcement = tierAnnouncement[USER_TIER]
showToast("Maple AI v6.0 - " .. getTierName(USER_TIER), announcement[2], 4)

print("\n")
print("========================================")
print("  MAPLE AI v6.0 ULTIMATE - LOADED")
print("========================================")
print("  Account: " .. lp.DisplayName .. " (" .. getTierName(USER_TIER) .. ")")
print("  Executor: " .. ExecutorInfo.name)
print("========================================")
print("  Press RightShift or click M button")
print("  to open the settings panel")
print("========================================")
print("\n")

end)

if not success then
    warn("[Maple AI] Failed to load: " .. tostring(errorMsg))
    pcall(function()
        local gui = Instance.new("ScreenGui")
        gui.Name = "MapleAI_Error"
        gui.Parent = game:GetService("CoreGui")
        local errorFrame = Instance.new("Frame")
        errorFrame.Size = UDim2.new(0, 400, 0, 150)
        errorFrame.Position = UDim2.new(0.5, -200, 0.5, -75)
        errorFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        errorFrame.Parent = gui
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = errorFrame
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 40)
        title.BackgroundTransparency = 1
        title.Text = "Maple AI - Error"
        title.TextColor3 = Color3.fromRGB(255, 100, 100)
        title.TextSize = 18
        title.Font = Enum.Font.GothamBold
        title.Parent = errorFrame
        local errText = Instance.new("TextLabel")
        errText.Size = UDim2.new(1, -20, 1, -50)
        errText.Position = UDim2.new(0, 10, 0, 40)
        errText.BackgroundTransparency = 1
        errText.Text = tostring(errorMsg):sub(1, 200)
        errText.TextColor3 = Color3.fromRGB(200, 200, 200)
        errText.TextSize = 12
        errText.Font = Enum.Font.Gotham
        errText.TextWrapped = true
        errText.TextYAlignment = Enum.TextYAlignment.Top
        errText.Parent = errorFrame
        task.delay(10, function()
            gui:Destroy()
        end)
    end)
end

return success
