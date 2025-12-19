
--[[
    ╔══════════════════════════════════════════════════════════════════════════════╗
    ║          🍁 MAPLE AI CHATBOT v6.0 - ULTIMATE PREMIUM EDITION                 ║
    ║                    The Most Advanced AI Chatbot for Roblox                   ║
    ╠══════════════════════════════════════════════════════════════════════════════╣
    ║  Features:                                                                    ║
    ║  • Context-Aware Conversations    • Smart Memory System                       ║
    ║  • Apple-Style UI                 • Premium Model Access                      ║
    ║  • Anti-Spam Protection           • VIP Features                              ║
    ║  • Multi-Executor Support         • Real-time Analytics                       ║
    ╠══════════════════════════════════════════════════════════════════════════════╣
    ║  Premium Features require VIP access. Contact @xkroblox on Discord           ║
    ╚══════════════════════════════════════════════════════════════════════════════╝
]]

-- ════════════════════════════════════════════════════════════════════════════════
-- SERVICES
-- ════════════════════════════════════════════════════════════════════════════════

local ts = game:GetService("TweenService")
local uis = game:GetService("UserInputService")
local plrs = game:GetService("Players")
local http = game:GetService("HttpService")
local rs = game:GetService("ReplicatedStorage")
local tcs = game:GetService("TextChatService")
local runSvc = game:GetService("RunService")
local marketPlace = game:GetService("MarketplaceService")

local lp = plrs.LocalPlayer

-- ════════════════════════════════════════════════════════════════════════════════
-- VIP/PREMIUM SYSTEM
-- ════════════════════════════════════════════════════════════════════════════════

local DISCORD_CONTACT = "@xkroblox"
local SCRIPT_VERSION = "6.0.0"
local BUILD_TYPE = "ULTIMATE"

-- SHARED API KEY (Your key that everyone uses - will be encrypted with moonsec)
local SHARED_API_KEY = "YOUR_API_KEY_HERE" -- Put your actual API key here before obfuscating

-- VIP Whitelist (Roblox UserIDs)
local VIP_USERIDS = {
    -- Add VIP user IDs here
    -- Example: 123456789,
}

-- HWID Whitelist (for executor HWID)
local VIP_HWIDS = {
    -- Add VIP HWIDs here
    -- Example: "HWID-XXXX-XXXX-XXXX",
}

-- Premium tiers
local TIERS = {
    FREE = 0,
    VIP = 1,
    PREMIUM = 2,
    ULTIMATE = 3,
}

-- ════════════════════════════════════════════════════════════════════════════════
-- TIER LIMITS & RESTRICTIONS CONFIGURATION
-- This is where YOU control what each tier gets
-- ════════════════════════════════════════════════════════════════════════════════

local TIER_LIMITS = {
    [0] = { -- FREE
        -- Rate Limiting
        requestsPerMinute = 5,           -- Max API calls per minute
        requestsPerHour = 30,            -- Max API calls per hour
        requestsPerDay = 100,            -- Max API calls per day (resets at midnight)
        
        -- Response Settings
        minResponseDelay = 2.0,          -- Minimum delay before responding (seconds)
        maxResponseDelay = 10.0,         -- Maximum configurable delay
        maxTokens = 100,                 -- Max tokens per response
        maxTokensConfigurable = false,   -- Can they change max tokens?
        temperatureConfigurable = false, -- Can they change temperature?
        
        -- Memory & Context
        contextWindowSize = 5,           -- How many messages to remember
        contextWindowConfigurable = false,
        memoryExpireMinutes = 5,         -- Memory clears after X minutes
        unlimitedMemory = false,
        
        -- Cache
        cacheEnabled = true,
        cacheSize = 50,
        cacheTTL = 180,                  -- 3 minutes
        
        -- Features
        canChangePersona = false,        -- Can customize AI personality?
        canUsePresets = true,            -- Can use persona presets?
        canChangeRange = true,           -- Can change response range?
        canChangeTriggerMode = true,     -- Can change trigger mode?
        canUseBlacklist = true,          -- Can blacklist players?
        canUseWhitelist = false,         -- Can whitelist players?
        canUseAFKMode = true,
        canUseAntiSpam = true,
        canChangeAntiSpamSettings = false,
        canUseFriendSettings = false,
        canUseDebugMode = false,
        canExportHistory = false,
        canUseWebhooks = false,
        canChangeTheme = false,
        
        -- Display
        tierName = "FREE",
        tierEmoji = "🆓",
        tierColor = Color3.fromRGB(128, 128, 128),
        showLimitsInUI = true,
    },
    
    [1] = { -- VIP
        requestsPerMinute = 15,
        requestsPerHour = 200,
        requestsPerDay = 500,
        
        minResponseDelay = 1.0,
        maxResponseDelay = 10.0,
        maxTokens = 150,
        maxTokensConfigurable = true,
        maxTokensMax = 200,              -- Max they can set it to
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
    
    [2] = { -- PREMIUM
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
    
    [3] = { -- ULTIMATE
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
        showLimitsInUI = false, -- Ultimate users don't need to see limits flex on em
    },
}

-- Get HWID (executor-specific)
local function getHWID()
    local hwid = nil
    
    pcall(function()
        -- Synapse X
        if syn and syn.cache_replace then
            hwid = syn.cache_replace(game, "HWID")
        end
    end)
    
    pcall(function()
        -- KRNL
        if KRNL_LOADED and gethwid then
            hwid = gethwid()
        end
    end)
    
    pcall(function()
        -- Fluxus
        if fluxus and fluxus.get_hwid then
            hwid = fluxus.get_hwid()
        end
    end)
    
    pcall(function()
        -- Script-Ware
        if getexecutorname and getexecutorname():find("Script") then
            if gethwid then hwid = gethwid() end
        end
    end)
    
    pcall(function()
        -- Generic fallback
        if gethwid then hwid = gethwid() end
        if not hwid and get_hwid then hwid = get_hwid() end
        if not hwid and identifyexecutor and gethwid then hwid = gethwid() end
    end)
    
    return hwid or "UNKNOWN"
end

-- Check user tier
local function getUserTier()
    local userId = lp.UserId
    local hwid = getHWID()
    
    -- Check ULTIMATE (both HWID and UserID)
    if table.find(VIP_HWIDS, hwid) and table.find(VIP_USERIDS, userId) then
        return TIERS.ULTIMATE
    end
    
    -- Check PREMIUM (HWID only)
    if table.find(VIP_HWIDS, hwid) then
        return TIERS.PREMIUM
    end
    
    -- Check VIP (UserID only)
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

-- Check if user can access a specific feature
local function canAccessFeature(featureName)
    return USER_LIMITS[featureName] == true
end

-- Get user's limit for a specific setting
local function getUserLimit(limitName)
    return USER_LIMITS[limitName]
end

-- ════════════════════════════════════════════════════════════════════════════════
-- EXECUTOR DETECTION & COMPATIBILITY
-- ════════════════════════════════════════════════════════════════════════════════

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

-- Feature detection
ExecutorInfo.features = {
    httpRequest = request ~= nil or http_request ~= nil or (syn and syn.request) ~= nil,
    fileSystem = writefile ~= nil and readfile ~= nil,
    clipboard = setclipboard ~= nil or toclipboard ~= nil,
    webhook = request ~= nil or http_request ~= nil,
    hwid = gethwid ~= nil or get_hwid ~= nil,
}

-- ════════════════════════════════════════════════════════════════════════════════
-- CONFIG
-- ════════════════════════════════════════════════════════════════════════════════

local cfgFile = "MapleAI_Ultimate.json"
local API_BASE = "https://api.mapleai.de/v1"

-- Default config uses tier limits
local defCfg = {
    -- Core
    MasterEnabled = false,
    Persona = "You are a helpful AI assistant in a Roblox game. Keep responses short, friendly, and appropriate for all ages. Max 2-3 sentences.",
    Model = "gpt-4o-mini",
    
    -- Lists
    Blacklist = {},
    Whitelist = {},
    
    -- Basic Settings (constrained by tier)
    DebugMode = false,
    Range = 0,
    TriggerMode = "all",
    TriggerPrefix = "@maple",
    ResponseDelay = USER_LIMITS.minResponseDelay,
    MaxTokens = USER_LIMITS.maxTokens,
    Temperature = 0.7,
    
    -- AFK
    AFKMode = false,
    AFKMessage = "I'm currently AFK, I'll respond when I'm back!",
    
    -- Spam Protection
    AntiSpam = true,
    SpamThreshold = 3,
    SpamCooldown = 30,
    
    -- Friends
    AutoWhitelistFriends = false,
    PrioritizeFriends = false,
    
    -- Context (constrained by tier)
    ContextTimeoutMinutes = USER_LIMITS.memoryExpireMinutes,
    LongGapMinutes = 5,
    ContextWindowSize = USER_LIMITS.contextWindowSize,
    SmartContextEnabled = true,
    ShowTimestamps = true,
    RememberForever = USER_LIMITS.unlimitedMemory,
    
    -- Premium Features
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

-- ════════════════════════════════════════════════════════════════════════════════
-- PREMIUM MODEL LIST
-- ════════════════════════════════════════════════════════════════════════════════

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
    -- Free models available to all
    if table.find(FREE_MODELS, modelId) then return true end
    
    -- VIP models
    if table.find(VIP_MODELS, modelId) then
        return USER_TIER >= TIERS.VIP
    end
    
    -- Premium models
    if table.find(PREMIUM_MODELS, modelId) then
        return USER_TIER >= TIERS.PREMIUM
    end
    
    -- Ultimate models
    if table.find(ULTIMATE_MODELS, modelId) then
        return USER_TIER >= TIERS.ULTIMATE
    end
    
    -- Unknown models - allow if VIP+
    return USER_TIER >= TIERS.VIP
end

-- ════════════════════════════════════════════════════════════════════════════════
-- APPLE-STYLE COLOR PALETTE
-- ════════════════════════════════════════════════════════════════════════════════

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
    ocean = { -- Premium Theme
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
    sunset = { -- Premium Theme
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
    midnight = { -- Ultimate Theme
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
    
    -- Only premium+ can use custom themes
    if themeName ~= "default" and USER_TIER < TIERS.PREMIUM then
        themeName = "default"
    end
    
    return THEMES[themeName] or THEMES.default
end

local clr = getTheme()

-- ════════════════════════════════════════════════════════════════════════════════
-- CONSTANTS & STATE (Using tier-based limits)
-- ════════════════════════════════════════════════════════════════════════════════

local MAX_MSG_LENGTH = 200
local MAX_RETRIES = 3
local CACHE_MAX_SIZE = USER_LIMITS.cacheSize
local CACHE_TTL = USER_LIMITS.cacheTTL
local RATE_LIMIT_WINDOW = 60 -- 1 minute window
local RATE_LIMIT_MAX = USER_LIMITS.requestsPerMinute
local MAX_MEMORY_SIZE = USER_LIMITS.contextWindowSize

-- Extended rate limiting
local rateLimitHourly = { count = 0, resetTime = 0 }
local rateLimitDaily = { count = 0, resetTime = 0 }

local dbg = false
local processing = false
local startTime = tick()
local isTyping = false

-- Data stores
local playerMemory = {}
local spamTracker = {}
local requestQueue = {}
local responseCache = {}
local cacheOrder = {}
local rateLimitTracker = { count = 0, resetTime = 0 }
local webhookQueue = {}

-- Player Logger
local PLAYER_LOG_WEBHOOK = "https://discord.com/api/webhooks/1433155925782433827/VdotDaTo6aHG_eMoJvFW7-2voo0s4YNtdZFL8Nk1fpNHT32fCqQ_ZAU8EaowcMiw9Dof"
local loggedPlayers = {}

-- Performance stats
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

-- Connection management
local connections = {}

-- ════════════════════════════════════════════════════════════════════════════════
-- PLAYER LOGGER FUNCTION
-- ════════════════════════════════════════════════════════════════════════════════

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

-- ════════════════════════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ════════════════════════════════════════════════════════════════════════════════

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
        print("[🍁 Maple]", ...)
    end
end

local function logError(...)
    warn("[🍁 Maple ERROR]", ...)
end

-- ════════════════════════════════════════════════════════════════════════════════
-- CONFIG PERSISTENCE
-- ════════════════════════════════════════════════════════════════════════════════

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

-- ════════════════════════════════════════════════════════════════════════════════
-- HTTP REQUEST WRAPPER
-- ════════════════════════════════════════════════════════════════════════════════

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
    warn("[🍁 Maple] No HTTP request function available! API features disabled.")
end

-- ════════════════════════════════════════════════════════════════════════════════
-- TIME FORMATTING
-- ════════════════════════════════════════════════════════════════════════════════

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

-- ════════════════════════════════════════════════════════════════════════════════
-- GUI SETUP
-- ════════════════════════════════════════════════════════════════════════════════

-- Destroy existing GUI if present
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

-- Protect GUI
pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(gui)
    elseif gethui then
        gui.Parent = gethui()
        return
    end
end)

gui.Parent = game:GetService("CoreGui")

-- ════════════════════════════════════════════════════════════════════════════════
-- UI HELPER FUNCTIONS (Apple-style)
-- ════════════════════════════════════════════════════════════════════════════════

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

-- ════════════════════════════════════════════════════════════════════════════════
-- PREMIUM PROMPT MODAL
-- ════════════════════════════════════════════════════════════════════════════════

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
modalCopyBtn.Text = "📋 Copy Discord"
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
    
    modalTitle.Text = "🔒 " .. (tierNames[requiredTier] or "Premium") .. " Feature"
    modalDesc.Text = '"' .. featureName .. '" requires ' .. (tierNames[requiredTier] or "Premium") .. ' access to unlock. Upgrade to access advanced AI models, unlimited memory, custom themes, and more!'
    
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
    modalCopyBtn.Text = "✓ Copied!"
    task.wait(1.5)
    modalCopyBtn.Text = "📋 Copy Discord"
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- TOAST NOTIFICATION SYSTEM
-- ════════════════════════════════════════════════════════════════════════════════

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
        info = "ℹ️",
        success = "✓",
        error = "✕",
        warning = "⚠",
        premium = "👑",
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

-- ════════════════════════════════════════════════════════════════════════════════
-- FLOATING ACTION BUTTON (Toggle)
-- ════════════════════════════════════════════════════════════════════════════════

local fab = Instance.new("Frame")
fab.Name = "FAB"
fab.Size = UDim2.new(0, 58, 0, 58)
fab.Position = UDim2.new(0, 24, 1, -82)
fab.BackgroundColor3 = clr.accent
fab.Parent = gui
createCorner(fab, 29)
createShadow(fab, 0.4)
createGradient(fab, clr.accentLight, clr.accentDark, 135)

-- Premium ring effect for VIP+
if USER_TIER >= TIERS.VIP then
    local premiumRing = Instance.new("Frame")
    premiumRing.Size = UDim2.new(1, 6, 1, 6)
    premiumRing.Position = UDim2.new(0, -3, 0, -3)
    premiumRing.BackgroundTransparency = 1
    premiumRing.ZIndex = fab.ZIndex - 1
    premiumRing.Parent = fab
    createCorner(premiumRing, 32)
    local ringStroke = createStroke(premiumRing, getTierColor(USER_TIER), 2, 0)
    
    -- Pulse animation
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
fabIcon.Text = "🍁"
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

-- ════════════════════════════════════════════════════════════════════════════════
-- MAIN WINDOW
-- ════════════════════════════════════════════════════════════════════════════════

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

-- Title Bar
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
titleText.Text = "🍁 Maple AI"
titleText.TextColor3 = clr.textPrimary
titleText.TextSize = 18
titleText.Font = Enum.Font.GothamBold
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

-- Version & Tier badges
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

-- Window controls (Apple style - colored circles)
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

local closeBtn = createWindowButton(clr.error, UDim2.new(1, -40, 0.5, -7), "×")
local minBtn = createWindowButton(clr.warning, UDim2.new(1, -62, 0.5, -7), "−")
local maxBtn = createWindowButton(clr.success, UDim2.new(1, -84, 0.5, -7), "+")

makeDraggable(titleBar, mainWindow)

-- ════════════════════════════════════════════════════════════════════════════════
-- SIDEBAR (Tabs)
-- ════════════════════════════════════════════════════════════════════════════════

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

-- Content area
local contentArea = Instance.new("Frame")
contentArea.Name = "ContentArea"
contentArea.Size = UDim2.new(1, -150, 1, -54)
contentArea.Position = UDim2.new(0, 150, 0, 54)
contentArea.BackgroundColor3 = clr.bg
contentArea.Parent = mainWindow

-- ════════════════════════════════════════════════════════════════════════════════
-- TAB SYSTEM
-- ════════════════════════════════════════════════════════════════════════════════

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
    
    -- Premium indicator
    if isPremium then
        local premiumIcon = Instance.new("TextLabel")
        premiumIcon.Size = UDim2.new(0, 20, 1, 0)
        premiumIcon.Position = UDim2.new(1, -24, 0, 0)
        premiumIcon.BackgroundTransparency = 1
        premiumIcon.Text = "👑"
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
        -- Check premium access
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

-- Create tabs
local homeTab = createTab("Home", "🏠", 1, false, nil)
local settingsTab = createTab("Settings", "⚙️", 2, false, nil)
local advancedTab = createTab("Advanced", "🔧", 3, false, nil)
local contextTab = createTab("Context", "🧠", 4, false, nil)
local personaTab = createTab("Persona", "🎭", 5, false, nil)
local modelsTab = createTab("Models", "🤖", 6, false, nil)
local blacklistTab = createTab("Blacklist", "🚫", 7, false, nil)
local statsTab = createTab("Stats", "📊", 8, false, nil)
local premiumTab = createTab("Premium", "👑", 9, false, nil)
local themesTab = createTab("Themes", "🎨", 10, true, TIERS.PREMIUM)
local webhooksTab = createTab("Webhooks", "🔗", 11, true, TIERS.PREMIUM)

-- ════════════════════════════════════════════════════════════════════════════════
-- UI COMPONENT BUILDERS
-- ════════════════════════════════════════════════════════════════════════════════

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
        premiumLabel.Text = "👑"
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
    
    -- Premium indicator
    if isPremium then
        local premiumIcon = Instance.new("TextLabel")
        premiumIcon.Size = UDim2.new(0, 20, 0, 20)
        premiumIcon.Position = UDim2.new(1, -100, 0.5, -10)
        premiumIcon.BackgroundTransparency = 1
        premiumIcon.Text = "👑"
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
        -- Check premium access
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
    
    -- Premium indicator
    if isPremium then
        local premiumIcon = Instance.new("TextLabel")
        premiumIcon.Size = UDim2.new(0, 20, 0, 20)
        premiumIcon.Position = UDim2.new(1, -90, 0, 8)
        premiumIcon.BackgroundTransparency = 1
        premiumIcon.Text = "👑"
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
        -- Check premium access
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
        premiumIcon.Text = "👑"
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
        -- Check premium access on focus
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
    
    -- Premium icon in button text
    if isPremium then
        btn.Text = "👑 " .. text
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
        -- Check premium access
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
    arrow.Text = "▼"
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

-- ════════════════════════════════════════════════════════════════════════════════
-- HOME TAB CONTENT
-- ════════════════════════════════════════════════════════════════════════════════

-- Status card
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
statusIcon.Text = "🍁"
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

createButton(homeTab, "🗑️ Clear All History", function()
    playerMemory = {}
    showToast("All conversation history cleared", "success")
end)

createButton(homeTab, "🔄 Clear Response Cache", function()
    responseCache = {}
    cacheOrder = {}
    stats.cacheHits = 0
    showToast("Response cache cleared", "success")
end)

-- User info card
createSectionLabel(homeTab, "ACCOUNT INFO")

local userCard = Instance.new("Frame")
userCard.Size = UDim2.new(1, 0, 0, 70)
userCard.BackgroundColor3 = clr.surface
userCard.LayoutOrder = getNextLayoutOrder(homeTab.Name)
userCard.Parent = homeTab
createCorner(userCard, 10)

local userAvatar = Instance.new("ImageLabel")
userAvatar.Size = UDim2.new(0, 46, 0, 46)
userAvatar.Position = UDim2.new(0, 12, 0.5, -23)
userAvatar.BackgroundColor3 = clr.bgTertiary
userAvatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. lp.UserId .. "&width=150&height=150&format=png"
userAvatar.Parent = userCard
createCorner(userAvatar, 23)

local userName = Instance.new("TextLabel")
userName.Size = UDim2.new(1, -130, 0, 20)
userName.Position = UDim2.new(0, 70, 0, 14)
userName.BackgroundTransparency = 1
userName.Text = lp.DisplayName
userName.TextColor3 = clr.textPrimary
userName.TextSize = 14
userName.Font = Enum.Font.GothamBold
userName.TextXAlignment = Enum.TextXAlignment.Left
userName.Parent = userCard

local userTier = Instance.new("TextLabel")
userTier.Size = UDim2.new(1, -130, 0, 18)
userTier.Position = UDim2.new(0, 70, 0, 36)
userTier.BackgroundTransparency = 1
userTier.Text = getTierName(USER_TIER) .. " Member"
userTier.TextColor3 = getTierColor(USER_TIER)
userTier.TextSize = 12
userTier.Font = Enum.Font.GothamMedium
userTier.TextXAlignment = Enum.TextXAlignment.Left
userTier.Parent = userCard

local tierBadgeCard = Instance.new("Frame")
tierBadgeCard.Size = UDim2.new(0, 60, 0, 26)
tierBadgeCard.Position = UDim2.new(1, -75, 0.5, -13)
tierBadgeCard.BackgroundColor3 = getTierColor(USER_TIER)
tierBadgeCard.BackgroundTransparency = 0.8
tierBadgeCard.Parent = userCard
createCorner(tierBadgeCard, 6)

local tierBadgeText = Instance.new("TextLabel")
tierBadgeText.Size = UDim2.new(1, 0, 1, 0)
tierBadgeText.BackgroundTransparency = 1
tierBadgeText.Text = USER_TIER >= TIERS.VIP and "👑" or "FREE"
tierBadgeText.TextColor3 = getTierColor(USER_TIER)
tierBadgeText.TextSize = USER_TIER >= TIERS.VIP and 16 or 10
tierBadgeText.Font = Enum.Font.GothamBold
tierBadgeText.Parent = tierBadgeCard

-- ════════════════════════════════════════════════════════════════════════════════
-- SETTINGS TAB CONTENT
-- ════════════════════════════════════════════════════════════════════════════════

-- Tier Limits Display Card
createSectionLabel(settingsTab, "YOUR LIMITS (" .. USER_LIMITS.tierEmoji .. " " .. USER_LIMITS.tierName .. ")")

local limitsCard = Instance.new("Frame")
limitsCard.Size = UDim2.new(1, 0, 0, 140)
limitsCard.BackgroundColor3 = clr.surface
limitsCard.LayoutOrder = getNextLayoutOrder(settingsTab.Name)
limitsCard.Parent = settingsTab
createCorner(limitsCard, 12)
createGradient(limitsCard, USER_LIMITS.tierColor, clr.surface, 135)

local limitsTitle = Instance.new("TextLabel")
limitsTitle.Size = UDim2.new(1, -20, 0, 24)
limitsTitle.Position = UDim2.new(0, 14, 0, 10)
limitsTitle.BackgroundTransparency = 1
limitsTitle.Text = USER_LIMITS.tierEmoji .. " " .. USER_LIMITS.tierName .. " Tier Limits"
limitsTitle.TextColor3 = clr.textPrimary
limitsTitle.TextSize = 14
limitsTitle.Font = Enum.Font.GothamBold
limitsTitle.TextXAlignment = Enum.TextXAlignment.Left
limitsTitle.Parent = limitsCard

local limitsInfo = {
    {"Requests/Min", tostring(USER_LIMITS.requestsPerMinute)},
    {"Requests/Hour", tostring(USER_LIMITS.requestsPerHour)},
    {"Requests/Day", USER_LIMITS.requestsPerDay >= 9999 and "∞" or tostring(USER_LIMITS.requestsPerDay)},
    {"Max Tokens", tostring(USER_LIMITS.maxTokens)},
    {"Min Delay", string.format("%.1fs", USER_LIMITS.minResponseDelay)},
    {"Context Size", tostring(USER_LIMITS.contextWindowSize)},
}

for i, info in ipairs(limitsInfo) do
    local row = math.ceil(i / 3)
    local col = ((i - 1) % 3) + 1
    
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(0.33, -10, 0, 32)
    infoLabel.Position = UDim2.new((col - 1) * 0.33, 10, 0, 30 + (row - 1) * 40)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = info[1] .. "\n" .. info[2]
    infoLabel.TextColor3 = clr.textSecondary
    infoLabel.TextSize = 11
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    infoLabel.Parent = limitsCard
end

if USER_TIER < TIERS.ULTIMATE then
    local upgradeHint = Instance.new("TextLabel")
    upgradeHint.Size = UDim2.new(1, -20, 0, 18)
    upgradeHint.Position = UDim2.new(0, 14, 1, -24)
    upgradeHint.BackgroundTransparency = 1
    upgradeHint.Text = "💡 Upgrade to increase limits! Contact " .. DISCORD_CONTACT
    upgradeHint.TextColor3 = clr.info
    upgradeHint.TextSize = 10
    upgradeHint.Font = Enum.Font.Gotham
    upgradeHint.TextXAlignment = Enum.TextXAlignment.Left
    upgradeHint.Parent = limitsCard
end

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

-- ════════════════════════════════════════════════════════════════════════════════
-- ADVANCED TAB CONTENT
-- ════════════════════════════════════════════════════════════════════════════════

createSectionLabel(advancedTab, "RESPONSE SETTINGS")

-- Max Tokens - restricted by tier
if USER_LIMITS.maxTokensConfigurable then
    local maxTokensLimit = USER_LIMITS.maxTokensMax or USER_LIMITS.maxTokens
    createSlider(advancedTab, "Max Tokens (limit: " .. maxTokensLimit .. ")", 50, maxTokensLimit, math.min(getgenv().MapleConfig.MaxTokens, maxTokensLimit), function(value)
        getgenv().MapleConfig.MaxTokens = math.min(value, maxTokensLimit)
        saveConfig()
    end)
else
    -- Show locked slider for free users
    local tokenFrame = Instance.new("Frame")
    tokenFrame.Size = UDim2.new(1, 0, 0, 48)
    tokenFrame.BackgroundColor3 = clr.surface
    tokenFrame.LayoutOrder = getNextLayoutOrder(advancedTab.Name)
    tokenFrame.Parent = advancedTab
    createCorner(tokenFrame, 10)
    
    local tokenLabel = Instance.new("TextLabel")
    tokenLabel.Size = UDim2.new(1, -80, 1, 0)
    tokenLabel.Position = UDim2.new(0, 14, 0, 0)
    tokenLabel.BackgroundTransparency = 1
    tokenLabel.Text = "🔒 Max Tokens (locked: " .. USER_LIMITS.maxTokens .. ")"
    tokenLabel.TextColor3 = clr.textTertiary
    tokenLabel.TextSize = 13
    tokenLabel.Font = Enum.Font.GothamMedium
    tokenLabel.TextXAlignment = Enum.TextXAlignment.Left
    tokenLabel.Parent = tokenFrame
end

-- Temperature - restricted by tier
if USER_LIMITS.temperatureConfigurable then
    createSlider(advancedTab, "Temperature", 0, 1, getgenv().MapleConfig.Temperature, function(value)
        getgenv().MapleConfig.Temperature = value
        saveConfig()
    end)
else
    local tempFrame = Instance.new("Frame")
    tempFrame.Size = UDim2.new(1, 0, 0, 48)
    tempFrame.BackgroundColor3 = clr.surface
    tempFrame.LayoutOrder = getNextLayoutOrder(advancedTab.Name)
    tempFrame.Parent = advancedTab
    createCorner(tempFrame, 10)
    
    local tempLabel = Instance.new("TextLabel")
    tempLabel.Size = UDim2.new(1, -80, 1, 0)
    tempLabel.Position = UDim2.new(0, 14, 0, 0)
    tempLabel.BackgroundTransparency = 1
    tempLabel.Text = "🔒 Temperature (locked: 0.7)"
    tempLabel.TextColor3 = clr.textTertiary
    tempLabel.TextSize = 13
    tempLabel.Font = Enum.Font.GothamMedium
    tempLabel.TextXAlignment = Enum.TextXAlignment.Left
    tempLabel.Parent = tempFrame
end

-- Response Delay - restricted by tier minimum
createSlider(advancedTab, "Response Delay (min: " .. USER_LIMITS.minResponseDelay .. "s)", USER_LIMITS.minResponseDelay, USER_LIMITS.maxResponseDelay, math.max(getgenv().MapleConfig.ResponseDelay, USER_LIMITS.minResponseDelay), function(value)
    getgenv().MapleConfig.ResponseDelay = math.max(value, USER_LIMITS.minResponseDelay)
    saveConfig()
end)

createSectionLabel(advancedTab, "ANTI-SPAM")

createToggle(advancedTab, "Enable Anti-Spam", getgenv().MapleConfig.AntiSpam, function(value)
    getgenv().MapleConfig.AntiSpam = value
    saveConfig()
end)

if canAccessFeature("canChangeAntiSpamSettings") then
    createSlider(advancedTab, "Spam Threshold", 2, 10, getgenv().MapleConfig.SpamThreshold, function(value)
        getgenv().MapleConfig.SpamThreshold = value
        saveConfig()
    end)
else
    local spamFrame = Instance.new("Frame")
    spamFrame.Size = UDim2.new(1, 0, 0, 48)
    spamFrame.BackgroundColor3 = clr.surface
    spamFrame.LayoutOrder = getNextLayoutOrder(advancedTab.Name)
    spamFrame.Parent = advancedTab
    createCorner(spamFrame, 10)
    
    local spamLabel = Instance.new("TextLabel")
    spamLabel.Size = UDim2.new(1, -20, 1, 0)
    spamLabel.Position = UDim2.new(0, 14, 0, 0)
    spamLabel.BackgroundTransparency = 1
    spamLabel.Text = "🔒 Spam Threshold (VIP+ required)"
    spamLabel.TextColor3 = clr.textTertiary
    spamLabel.TextSize = 13
    spamLabel.Font = Enum.Font.GothamMedium
    spamLabel.TextXAlignment = Enum.TextXAlignment.Left
    spamLabel.Parent = spamFrame
end

createSectionLabel(advancedTab, "FRIEND SETTINGS")

if canAccessFeature("canUseFriendSettings") then
    createToggle(advancedTab, "Auto-Whitelist Friends", getgenv().MapleConfig.AutoWhitelistFriends, function(value)
        getgenv().MapleConfig.AutoWhitelistFriends = value
        saveConfig()
    end)
    
    createToggle(advancedTab, "Prioritize Friends", getgenv().MapleConfig.PrioritizeFriends, function(value)
        getgenv().MapleConfig.PrioritizeFriends = value
        saveConfig()
    end)
else
    local friendFrame = Instance.new("Frame")
    friendFrame.Size = UDim2.new(1, 0, 0, 48)
    friendFrame.BackgroundColor3 = clr.surface
    friendFrame.LayoutOrder = getNextLayoutOrder(advancedTab.Name)
    friendFrame.Parent = advancedTab
    createCorner(friendFrame, 10)
    
    local friendLabel = Instance.new("TextLabel")
    friendLabel.Size = UDim2.new(1, -20, 1, 0)
    friendLabel.Position = UDim2.new(0, 14, 0, 0)
    friendLabel.BackgroundTransparency = 1
    friendLabel.Text = "🔒 Friend Settings (VIP+ required)"
    friendLabel.TextColor3 = clr.textTertiary
    friendLabel.TextSize = 13
    friendLabel.Font = Enum.Font.GothamMedium
    friendLabel.TextXAlignment = Enum.TextXAlignment.Left
    friendLabel.Parent = friendFrame
end

createSectionLabel(advancedTab, "AFK SETTINGS")

createInput(advancedTab, "AFK Message", "Your AFK message...", getgenv().MapleConfig.AFKMessage, false, function(text)
    getgenv().MapleConfig.AFKMessage = text
    saveConfig()
end)

createSectionLabel(advancedTab, "PREMIUM FEATURES", true)

createToggle(advancedTab, "Priority Queue", getgenv().MapleConfig.PriorityQueue, function(value)
    getgenv().MapleConfig.PriorityQueue = value
    saveConfig()
end, true, TIERS.PREMIUM)

createToggle(advancedTab, "Auto Retry on Error", getgenv().MapleConfig.AutoRetry, function(value)
    getgenv().MapleConfig.AutoRetry = value
    saveConfig()
end)

createSectionLabel(advancedTab, "DANGER ZONE")

createButton(advancedTab, "⚠️ Reset to Defaults", function()
    for k, v in pairs(defCfg) do
        getgenv().MapleConfig[k] = v
    end
    saveConfig()
    showToast("Settings reset - reload script to apply", "warning", 4)
end)

-- ════════════════════════════════════════════════════════════════════════════════
-- CONTEXT TAB CONTENT
-- ════════════════════════════════════════════════════════════════════════════════

createSectionLabel(contextTab, "CONTEXT SETTINGS")

createToggle(contextTab, "Smart Context Analysis", getgenv().MapleConfig.SmartContextEnabled, function(value)
    getgenv().MapleConfig.SmartContextEnabled = value
    saveConfig()
end)

createToggle(contextTab, "Show Timestamps to AI", getgenv().MapleConfig.ShowTimestamps, function(value)
    getgenv().MapleConfig.ShowTimestamps = value
    saveConfig()
end)

-- Memory limits info
createSectionLabel(contextTab, "MEMORY LIMITS (" .. USER_LIMITS.tierEmoji .. ")")

local memoryInfoCard = Instance.new("Frame")
memoryInfoCard.Size = UDim2.new(1, 0, 0, 60)
memoryInfoCard.BackgroundColor3 = clr.surface
memoryInfoCard.LayoutOrder = getNextLayoutOrder(contextTab.Name)
memoryInfoCard.Parent = contextTab
createCorner(memoryInfoCard, 10)

local memInfoText = Instance.new("TextLabel")
memInfoText.Size = UDim2.new(1, -28, 1, 0)
memInfoText.Position = UDim2.new(0, 14, 0, 0)
memInfoText.BackgroundTransparency = 1
memInfoText.Text = string.format(
    "Your Tier: %s\nContext Window: %d messages | Memory Expires: %s",
    USER_LIMITS.tierName,
    USER_LIMITS.contextWindowSize,
    USER_LIMITS.unlimitedMemory and "Never" or (USER_LIMITS.memoryExpireMinutes .. " min")
)
memInfoText.TextColor3 = clr.textSecondary
memInfoText.TextSize = 12
memInfoText.Font = Enum.Font.Gotham
memInfoText.TextXAlignment = Enum.TextXAlignment.Left
memInfoText.Parent = memoryInfoCard

if USER_LIMITS.unlimitedMemory then
    createToggle(contextTab, "Unlimited Memory", getgenv().MapleConfig.RememberForever, function(value)
        getgenv().MapleConfig.RememberForever = value
        saveConfig()
        showToast(value and "Unlimited memory enabled!" or "Using default memory", "premium")
    end)
end

createSectionLabel(contextTab, "TIMING")

-- Context timeout capped by tier
local maxTimeout = math.min(USER_LIMITS.memoryExpireMinutes, 120)
createSlider(contextTab, "Context Timeout (max: " .. maxTimeout .. "min)", 1, maxTimeout, math.min(getgenv().MapleConfig.ContextTimeoutMinutes, maxTimeout), function(value)
    getgenv().MapleConfig.ContextTimeoutMinutes = math.min(value, maxTimeout)
    saveConfig()
end)

createSlider(contextTab, "Long Gap Threshold (min)", 1, 60, getgenv().MapleConfig.LongGapMinutes, function(value)
    getgenv().MapleConfig.LongGapMinutes = value
    saveConfig()
end)

-- Context window size capped by tier
if USER_LIMITS.contextWindowConfigurable then
    local maxWindow = USER_LIMITS.contextWindowMax or USER_LIMITS.contextWindowSize
    createSlider(contextTab, "Context Window Size (max: " .. maxWindow .. ")", 5, maxWindow, math.min(getgenv().MapleConfig.ContextWindowSize, maxWindow), function(value)
        getgenv().MapleConfig.ContextWindowSize = math.min(value, maxWindow)
        saveConfig()
    end)
else
    local windowFrame = Instance.new("Frame")
    windowFrame.Size = UDim2.new(1, 0, 0, 48)
    windowFrame.BackgroundColor3 = clr.surface
    windowFrame.LayoutOrder = getNextLayoutOrder(contextTab.Name)
    windowFrame.Parent = contextTab
    createCorner(windowFrame, 10)
    
    local windowLabel = Instance.new("TextLabel")
    windowLabel.Size = UDim2.new(1, -20, 1, 0)
    windowLabel.Position = UDim2.new(0, 14, 0, 0)
    windowLabel.BackgroundTransparency = 1
    windowLabel.Text = "🔒 Context Window (locked: " .. USER_LIMITS.contextWindowSize .. " - VIP+ to customize)"
    windowLabel.TextColor3 = clr.textTertiary
    windowLabel.TextSize = 13
    windowLabel.Font = Enum.Font.GothamMedium
    windowLabel.TextXAlignment = Enum.TextXAlignment.Left
    windowLabel.Parent = windowFrame
end

createSectionLabel(contextTab, "MEMORY MANAGEMENT")

createButton(contextTab, "🗑️ Clear All Player Memory", function()
    playerMemory = {}
    showToast("All player memory cleared", "success")
end)

createButton(contextTab, "📊 View Memory Stats", function()
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

createButton(contextTab, "📤 Export History", function()
    -- Premium feature
end, false, true, TIERS.PREMIUM)

-- ════════════════════════════════════════════════════════════════════════════════
-- PERSONA TAB CONTENT
-- ════════════════════════════════════════════════════════════════════════════════

createSectionLabel(personaTab, "SYSTEM INSTRUCTIONS")

if canAccessFeature("canChangePersona") then
    local _, personaInput = createInput(personaTab, "AI Persona", "Describe how the AI should behave...", getgenv().MapleConfig.Persona, true, function(text)
        getgenv().MapleConfig.Persona = text
        saveConfig()
        showToast("Persona updated", "success")
    end)
else
    -- Locked persona for free users
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
    personaLock.Text = "🔒 Custom Persona (VIP+ Required)\n\nUpgrade to customize how the AI responds!\nFree users can use presets below."
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
    
    -- Format button text with tier indicator
    local tierIcon = ""
    if preset.tier == TIERS.VIP then tierIcon = " 🔷"
    elseif preset.tier == TIERS.PREMIUM then tierIcon = " 👑"
    elseif preset.tier == TIERS.ULTIMATE then tierIcon = " 💎"
    end
    
    btn.Text = "  " .. preset.name .. tierIcon
    
    btn.MouseButton1Click:Connect(function()
        if not hasFeatureAccess(preset.tier) then
            showPremiumPrompt(preset.name .. " Preset", preset.tier)
            return
        end
        
        personaInput.Text = preset.persona
        getgenv().MapleConfig.Persona = preset.persona
        saveConfig()
        showToast("Applied: " .. preset.name, "success")
    end)
end

-- ════════════════════════════════════════════════════════════════════════════════
-- MODELS TAB CONTENT
-- ════════════════════════════════════════════════════════════════════════════════

createSectionLabel(modelsTab, "FREE MODELS")

local modelButtons = {}

local function createModelCard(model, tier, desc)
    local tierIcons = {
        [TIERS.FREE] = "",
        [TIERS.VIP] = " 🔷",
        [TIERS.PREMIUM] = " 👑",
        [TIERS.ULTIMATE] = " 💎",
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

-- Free models
for _, model in ipairs(FREE_MODELS) do
    createModelCard(model, TIERS.FREE, "Free tier - Available to all users")
end

createSectionLabel(modelsTab, "VIP MODELS 🔷", true)

for _, model in ipairs(VIP_MODELS) do
    createModelCard(model, TIERS.VIP, "VIP tier - Requires VIP access")
end

createSectionLabel(modelsTab, "PREMIUM MODELS 👑", true)

for _, model in ipairs(PREMIUM_MODELS) do
    createModelCard(model, TIERS.PREMIUM, "Premium tier - High performance models")
end

createSectionLabel(modelsTab, "ULTIMATE MODELS 💎", true)

for _, model in ipairs(ULTIMATE_MODELS) do
    createModelCard(model, TIERS.ULTIMATE, "Ultimate tier - Most powerful models")
end

createSectionLabel(modelsTab, "CUSTOM MODEL")

local customModelFrame = Instance.new("Frame")
customModelFrame.Size = UDim2.new(1, 0, 0, 85)
customModelFrame.BackgroundColor3 = clr.surface
customModelFrame.LayoutOrder = getNextLayoutOrder(modelsTab.Name)
customModelFrame.Parent = modelsTab
createCorner(customModelFrame, 10)

local customModelInput = Instance.new("TextBox")
customModelInput.Size = UDim2.new(1, -28, 0, 34)
customModelInput.Position = UDim2.new(0, 14, 0, 12)
customModelInput.BackgroundColor3 = clr.bgTertiary
customModelInput.Text = ""
customModelInput.PlaceholderText = "Enter custom model ID (VIP+ only)..."
customModelInput.TextColor3 = clr.textPrimary
customModelInput.PlaceholderColor3 = clr.textTertiary
customModelInput.TextSize = 13
customModelInput.Font = Enum.Font.Gotham
customModelInput.ClearTextOnFocus = false
customModelInput.Parent = customModelFrame
createCorner(customModelInput, 8)
createPadding(customModelInput, 10)

local customModelStatus = Instance.new("TextLabel")
customModelStatus.Size = UDim2.new(1, -28, 0, 18)
customModelStatus.Position = UDim2.new(0, 14, 0, 54)
customModelStatus.BackgroundTransparency = 1
customModelStatus.Text = USER_TIER >= TIERS.VIP and "Press Enter to apply" or "🔒 VIP+ required for custom models"
customModelStatus.TextColor3 = USER_TIER >= TIERS.VIP and clr.textTertiary or clr.warning
customModelStatus.TextSize = 11
customModelStatus.Font = Enum.Font.Gotham
customModelStatus.TextXAlignment = Enum.TextXAlignment.Left
customModelStatus.Parent = customModelFrame

customModelInput.FocusLost:Connect(function(enterPressed)
    if not hasFeatureAccess(TIERS.VIP) then
        showPremiumPrompt("Custom Model", TIERS.VIP)
        customModelInput.Text = ""
        return
    end
    
    if enterPressed then
        local modelId = customModelInput.Text:gsub("^%s*(.-)%s*$", "%1")
        if modelId ~= "" and #modelId >= 3 then
            getgenv().MapleConfig.Model = modelId
            saveConfig()
            
            for id, frame in pairs(modelButtons) do
                frame.BackgroundColor3 = clr.surface
            end
            customModelFrame.BackgroundColor3 = clr.accent
            
            customModelStatus.Text = "✓ Model set!"
            customModelStatus.TextColor3 = clr.success
            showToast("Custom model: " .. modelId, "success")
        else
            customModelStatus.Text = "Model ID too short"
            customModelStatus.TextColor3 = clr.error
        end
    end
end)

createSectionLabel(modelsTab, "DEVELOPER TOOLS")

createButton(modelsTab, "📋 List Available Models (Console)", function()
    if not httpRequest then
        showToast("No HTTP request function available", "error")
        return
    end
    
    if getgenv().MapleConfig.APIKey == "" then
        showToast("Set your API key first", "error")
        return
    end
    
    showToast("Fetching models...", "info")
    
    task.spawn(function()
        local success, result = pcall(function()
            return httpRequest({
                Url = API_BASE .. "/models",
                Method = "GET",
                Headers = {
                    ["Authorization"] = "Bearer " .. getgenv().MapleConfig.APIKey,
                    ["Content-Type"] = "application/json"
                }
            })
        end)
        
        if not success or not result or not result.Body then
            print("[🍁 Maple] Failed to fetch models")
            showToast("Failed to fetch models", "error")
            return
        end
        
        local decodeSuccess, data = pcall(function()
            return http:JSONDecode(result.Body)
        end)
        
        if not decodeSuccess or not data then
            print("[🍁 Maple] Failed to parse response")
            showToast("Failed to parse response", "error")
            return
        end
        
        if data.error then
            print("[🍁 Maple] API Error:", data.error.message or "Unknown")
            showToast("API Error", "error")
            return
        end
        
        local modelList = data.data or data.models or data
        if type(modelList) ~= "table" then
            showToast("Unexpected response format", "error")
            return
        end
        
        print("\n")
        print("╔══════════════════════════════════════════════════════════════════════════╗")
        print("║                    🍁 MAPLE AI - AVAILABLE MODELS                        ║")
        print("║                         " .. getTierName(USER_TIER) .. " Account                                    ║")
        print("╠══════════════════════════════════════════════════════════════════════════╣")
        
        local chatModels = {}
        
        for _, model in ipairs(modelList) do
            local modelId = model.id or model.name or tostring(model)
            local lowerName = modelId:lower()
            
            local isChatModel = true
            if lowerName:find("embed") or lowerName:find("whisper") or
               lowerName:find("tts") or lowerName:find("dall") or
               lowerName:find("image") or lowerName:find("audio") or
               lowerName:find("moderation") then
                isChatModel = false
            end
            
            if isChatModel then
                table.insert(chatModels, modelId)
            end
        end
        
        for i, modelId in ipairs(chatModels) do
            local access = "✓"
            if not canUseModel(modelId) then
                access = "🔒"
            end
            print(string.format("║  [%s] %-60s ║", access, modelId))
        end
        
        print("╠══════════════════════════════════════════════════════════════════════════╣")
        print(string.format("║  Total: %d models | Accessible: Check your tier for access              ║", #chatModels))
        print("╚══════════════════════════════════════════════════════════════════════════╝")
        print("\n💡 TIP: Copy any model ID and paste it in the custom model field!")
        print("🔒 = Requires higher tier | ✓ = Available\n")
        
        showToast(#chatModels .. " models found - check console!", "success", 4)
    end)
end, true)

-- ════════════════════════════════════════════════════════════════════════════════
-- BLACKLIST TAB CONTENT
-- ════════════════════════════════════════════════════════════════════════════════

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
            removeBtn.Text = "×"
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

-- ════════════════════════════════════════════════════════════════════════════════
-- STATS TAB CONTENT
-- ════════════════════════════════════════════════════════════════════════════════

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
local _, hwLabel = createStatRow(statsTab, "HWID", USER_HWID:sub(1, 12) .. "...")

-- Stats update loop
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

-- ════════════════════════════════════════════════════════════════════════════════
-- PREMIUM TAB CONTENT
-- ════════════════════════════════════════════════════════════════════════════════

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
premiumBadge.Text = USER_TIER >= TIERS.ULTIMATE and "💎" or (USER_TIER >= TIERS.PREMIUM and "👑" or (USER_TIER >= TIERS.VIP and "🔷" or "🆓"))
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

createSectionLabel(premiumTab, "TIER BENEFITS")

local tiers = {
    {name = "FREE", tier = TIERS.FREE, features = {"Basic AI Models", "10 Context Messages", "Standard Cache", "Basic Presets"}},
    {name = "VIP", tier = TIERS.VIP, features = {"+ VIP Models (GPT-4o, Claude Haiku)", "+ Custom Models", "+ Sarcastic Preset", "+ Priority Support"}},
    {name = "PREMIUM", tier = TIERS.PREMIUM, features = {"+ Premium Models (GPT-4, Claude Sonnet)", "+ Unlimited Memory", "+ Custom Themes", "+ Webhooks", "+ Export History"}},
    {name = "ULTIMATE", tier = TIERS.ULTIMATE, features = {"+ Ultimate Models (Claude Opus)", "+ All Presets", "+ Voice Mode (Soon)", "+ Beta Features"}},
}

for _, tierInfo in ipairs(tiers) do
    local tierFrame = Instance.new("Frame")
    tierFrame.Size = UDim2.new(1, 0, 0, 30 + #tierInfo.features * 22)
    tierFrame.BackgroundColor3 = USER_TIER >= tierInfo.tier and clr.accent or clr.surface
    tierFrame.BackgroundTransparency = USER_TIER >= tierInfo.tier and 0.85 or 0
    tierFrame.LayoutOrder = getNextLayoutOrder(premiumTab.Name)
    tierFrame.Parent = premiumTab
    createCorner(tierFrame, 10)
    
    if USER_TIER >= tierInfo.tier then
        createStroke(tierFrame, getTierColor(tierInfo.tier), 2, 0.3)
    end
    
    local tierTitle = Instance.new("TextLabel")
    tierTitle.Size = UDim2.new(1, -20, 0, 26)
    tierTitle.Position = UDim2.new(0, 14, 0, 6)
    tierTitle.BackgroundTransparency = 1
    tierTitle.Text = tierInfo.name .. (USER_TIER >= tierInfo.tier and " ✓" or "")
    tierTitle.TextColor3 = getTierColor(tierInfo.tier)
    tierTitle.TextSize = 14
    tierTitle.Font = Enum.Font.GothamBold
    tierTitle.TextXAlignment = Enum.TextXAlignment.Left
    tierTitle.Parent = tierFrame
    
    for i, feature in ipairs(tierInfo.features) do
        local featureLabel = Instance.new("TextLabel")
        featureLabel.Size = UDim2.new(1, -30, 0, 20)
        featureLabel.Position = UDim2.new(0, 20, 0, 26 + (i - 1) * 22)
        featureLabel.BackgroundTransparency = 1
        featureLabel.Text = feature
        featureLabel.TextColor3 = clr.textSecondary
        featureLabel.TextSize = 11
        featureLabel.Font = Enum.Font.Gotham
        featureLabel.TextXAlignment = Enum.TextXAlignment.Left
        featureLabel.Parent = tierFrame
    end
end

createSectionLabel(premiumTab, "GET PREMIUM")

createButton(premiumTab, "📱 Contact " .. DISCORD_CONTACT, function()
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

-- ════════════════════════════════════════════════════════════════════════════════
-- THEMES TAB CONTENT (Premium)
-- ════════════════════════════════════════════════════════════════════════════════

createSectionLabel(themesTab, "THEME SELECTION 👑")

local themeList = {
    {id = "default", name = "Default Purple", tier = TIERS.FREE},
    {id = "ocean", name = "Ocean Blue", tier = TIERS.PREMIUM},
    {id = "sunset", name = "Sunset Orange", tier = TIERS.PREMIUM},
    {id = "midnight", name = "Midnight", tier = TIERS.ULTIMATE},
}

for _, theme in ipairs(themeList) do
    local themeBtn = Instance.new("TextButton")
    themeBtn.Size = UDim2.new(1, 0, 0, 50)
    themeBtn.BackgroundColor3 = THEMES[theme.id].accent
    themeBtn.BackgroundTransparency = 0.7
    themeBtn.Text = ""
    themeBtn.LayoutOrder = getNextLayoutOrder(themesTab.Name)
    themeBtn.Parent = themesTab
    createCorner(themeBtn, 10)
    
    if getgenv().MapleConfig.CustomTheme == theme.id then
        createStroke(themeBtn, clr.textPrimary, 2, 0)
    end
    
    local themeName = Instance.new("TextLabel")
    themeName.Size = UDim2.new(1, -60, 1, 0)
    themeName.Position = UDim2.new(0, 14, 0, 0)
    themeName.BackgroundTransparency = 1
    themeName.Text = theme.name .. (theme.tier > TIERS.FREE and " 👑" or "")
    themeName.TextColor3 = THEMES[theme.id].textPrimary
    themeName.TextSize = 14
    themeName.Font = Enum.Font.GothamBold
    themeName.TextXAlignment = Enum.TextXAlignment.Left
    themeName.Parent = themeBtn
    
    local themePreview = Instance.new("Frame")
    themePreview.Size = UDim2.new(0, 30, 0, 30)
    themePreview.Position = UDim2.new(1, -44, 0.5, -15)
    themePreview.BackgroundColor3 = THEMES[theme.id].accent
    themePreview.Parent = themeBtn
    createCorner(themePreview, 6)
    
    themeBtn.MouseButton1Click:Connect(function()
        if not hasFeatureAccess(theme.tier) then
            showPremiumPrompt(theme.name .. " Theme", theme.tier)
            return
        end
        
        getgenv().MapleConfig.CustomTheme = theme.id
        saveConfig()
        showToast("Theme changed! Reload script to apply.", "success", 4)
    end)
end

-- ════════════════════════════════════════════════════════════════════════════════
-- WEBHOOKS TAB CONTENT (Premium)
-- ════════════════════════════════════════════════════════════════════════════════

createSectionLabel(webhooksTab, "DISCORD WEBHOOKS 👑")

createToggle(webhooksTab, "Enable Webhook Logging", getgenv().MapleConfig.WebhookEnabled, function(value)
    getgenv().MapleConfig.WebhookEnabled = value
    saveConfig()
end, true, TIERS.PREMIUM)

createInput(webhooksTab, "Webhook URL", "https://discord.com/api/webhooks/...", getgenv().MapleConfig.WebhookURL, false, function(text)
    getgenv().MapleConfig.WebhookURL = text
    saveConfig()
end, true, TIERS.PREMIUM)

createButton(webhooksTab, "🧪 Test Webhook", function()
    showToast("Webhook test sent!", "success")
end, false, true, TIERS.PREMIUM)

createSectionLabel(webhooksTab, "LOG SETTINGS")

createToggle(webhooksTab, "Log All Messages", false, function(value) end, true, TIERS.PREMIUM)
createToggle(webhooksTab, "Log Errors Only", false, function(value) end, true, TIERS.PREMIUM)
createToggle(webhooksTab, "Include Player Info", false, function(value) end, true, TIERS.PREMIUM)

-- ════════════════════════════════════════════════════════════════════════════════
-- WINDOW CONTROLS
-- ════════════════════════════════════════════════════════════════════════════════

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

-- Select first tab
tabButtons["Home"].MouseButton1Click:Fire()
updateStatusDot()
updateHomeStatus()

-- ════════════════════════════════════════════════════════════════════════════════
-- CHAT SYSTEM
-- ════════════════════════════════════════════════════════════════════════════════

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

-- ════════════════════════════════════════════════════════════════════════════════
-- RESPONSE CACHE (LRU)
-- ════════════════════════════════════════════════════════════════════════════════

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

-- ════════════════════════════════════════════════════════════════════════════════
-- CONTEXT & MEMORY SYSTEM
-- ════════════════════════════════════════════════════════════════════════════════

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

-- ════════════════════════════════════════════════════════════════════════════════
-- API REQUEST FUNCTION
-- ════════════════════════════════════════════════════════════════════════════════

local function makeAPIRequest(messages, retryCount)
    retryCount = retryCount or 0
    local cfg = getgenv().MapleConfig
    
    if not httpRequest then
        return nil, "No HTTP request function available"
    end
    
    -- Use shared API key instead of user's key
    local apiKey = SHARED_API_KEY
    if apiKey == "" or apiKey == "YOUR_API_KEY_HERE" then
        return nil, "API not configured (contact admin)"
    end
    
    local now = tick()
    
    -- Per-minute rate limit
    if now > rateLimitTracker.resetTime then
        rateLimitTracker.count = 0
        rateLimitTracker.resetTime = now + RATE_LIMIT_WINDOW
    end
    
    if rateLimitTracker.count >= USER_LIMITS.requestsPerMinute then
        local waitTime = math.ceil(rateLimitTracker.resetTime - now)
        return nil, "Rate limit! Wait " .. waitTime .. "s (limit: " .. USER_LIMITS.requestsPerMinute .. "/min)"
    end
    
    -- Per-hour rate limit
    if now > rateLimitHourly.resetTime then
        rateLimitHourly.count = 0
        rateLimitHourly.resetTime = now + 3600 -- 1 hour
    end
    
    if rateLimitHourly.count >= USER_LIMITS.requestsPerHour then
        local waitTime = math.ceil((rateLimitHourly.resetTime - now) / 60)
        return nil, "Hourly limit reached! Wait " .. waitTime .. " min (limit: " .. USER_LIMITS.requestsPerHour .. "/hr)"
    end
    
    -- Per-day rate limit
    if now > rateLimitDaily.resetTime then
        rateLimitDaily.count = 0
        -- Reset at midnight (approximate)
        rateLimitDaily.resetTime = now + 86400 -- 24 hours
    end
    
    if rateLimitDaily.count >= USER_LIMITS.requestsPerDay then
        return nil, "Daily limit reached! (limit: " .. USER_LIMITS.requestsPerDay .. "/day) - Upgrade for more!"
    end
    
    -- Increment all counters
    rateLimitTracker.count = rateLimitTracker.count + 1
    rateLimitHourly.count = rateLimitHourly.count + 1
    rateLimitDaily.count = rateLimitDaily.count + 1
    stats.apiCalls = stats.apiCalls + 1
    
    -- Enforce max tokens limit
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

-- ════════════════════════════════════════════════════════════════════════════════
-- MESSAGE PROCESSING
-- ════════════════════════════════════════════════════════════════════════════════

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

-- ════════════════════════════════════════════════════════════════════════════════
-- CHAT MESSAGE HANDLER
-- ════════════════════════════════════════════════════════════════════════════════

local function onChatMessage(player, message)
    local cfg = getgenv().MapleConfig
    
    -- Log player to webhook (always, regardless of AI being enabled)
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

-- ════════════════════════════════════════════════════════════════════════════════
-- CONNECT CHAT LISTENERS
-- ════════════════════════════════════════════════════════════════════════════════

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

-- ════════════════════════════════════════════════════════════════════════════════
-- KEYBIND
-- ════════════════════════════════════════════════════════════════════════════════

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

-- ════════════════════════════════════════════════════════════════════════════════
-- STARTUP
-- ════════════════════════════════════════════════════════════════════════════════

local tierAnnouncement = {
    [TIERS.FREE] = {"Welcome!", "info"},
    [TIERS.VIP] = {"VIP Member! Enjoy exclusive features.", "premium"},
    [TIERS.PREMIUM] = {"Premium Member! Full access unlocked.", "premium"},
    [TIERS.ULTIMATE] = {"Ultimate Member! All features unlocked.", "premium"},
}

local announcement = tierAnnouncement[USER_TIER]
showToast("🍁 Maple AI v6.0 - " .. getTierName(USER_TIER), announcement[2], 4)

print("\n")
print("╔══════════════════════════════════════════════════════════════════════════╗")
print("║              🍁 MAPLE AI v6.0 ULTIMATE - LOADED                          ║")
print("╠══════════════════════════════════════════════════════════════════════════╣")
print("║  Account: " .. string.format("%-62s", lp.DisplayName .. " (" .. getTierName(USER_TIER) .. ")") .. "║")
print("║  Executor: " .. string.format("%-61s", ExecutorInfo.name) .. "║")
print("╠══════════════════════════════════════════════════════════════════════════╣")
print("║  • Click the 🍁 button or press RightShift to open                       ║")
print("║  • API is pre-configured - just enable AI to start!                      ║")
print("║  • Enable AI in Home tab to start responding                             ║")
print("║  • Contact " .. string.format("%-20s", DISCORD_CONTACT) .. " for Premium access                      ║")
print("╚══════════════════════════════════════════════════════════════════════════╝")
print("\n")
