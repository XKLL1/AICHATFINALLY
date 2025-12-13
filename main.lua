-- maple ai chatbot thing v4 - Context-Aware Edition

local ts = game:GetService("TweenService")
local uis = game:GetService("UserInputService")
local plrs = game:GetService("Players")
local http = game:GetService("HttpService")
local rs = game:GetService("ReplicatedStorage")
local tcs = game:GetService("TextChatService")
local runSvc = game:GetService("RunService")

local lp = plrs.LocalPlayer

local cfgFile = "MapleConfig.json"
local defCfg = {
    MasterEnabled = false,
    APIKey = "",
    Persona = "You are a helpful AI assistant.",
    Model = "gpt-4",
    Blacklist = {},
    Whitelist = {},
    DebugMode = false,
    -- core settings
    Range = 0, -- 0 = unlimited, otherwise studs
    TriggerMode = "all", -- "all", "mention", "prefix"
    TriggerPrefix = "@maple",
    ResponseDelay = 0, -- seconds to wait before responding (typing sim)
    MaxTokens = 200,
    Temperature = 0.7,
    AFKMode = false,
    AFKMessage = "I'm currently AFK, I'll respond when I'm back!",
    AutoWhitelistFriends = false,
    AntiSpam = true,
    SpamThreshold = 3, -- same msg X times = spam
    PrioritizeFriends = false,
    -- context-aware settings
    ContextTimeoutMinutes = 5, -- after X minutes, AI considers it might be new topic
    LongGapMinutes = 15, -- after X minutes, almost certainly new conversation
    ContextWindowSize = 20, -- how many recent msgs to send to AI for context
    SmartContextEnabled = true, -- enable intelligent context analysis
    ShowTimestamps = true, -- include timestamps in context for AI
    RememberForever = true, -- unlimited memory (no limit on stored messages)
}

getgenv().MapleConfig = {}
for k,v in pairs(defCfg) do getgenv().MapleConfig[k] = v end

local dbg = false

local function log(...)
    if dbg or getgenv().MapleConfig.DebugMode then print("[maple]", ...) end
end

local function save()
    pcall(function()
        if writefile then writefile(cfgFile, http:JSONEncode(getgenv().MapleConfig)) end
    end)
end

local function load()
    local ok, d = pcall(function()
        if isfile and isfile(cfgFile) then return readfile(cfgFile) end
    end)
    if ok and d then
        local s, dec = pcall(function() return http:JSONDecode(d) end)
        if s and dec then
            for k,v in pairs(dec) do
                if defCfg[k] ~= nil then getgenv().MapleConfig[k] = v end
            end
        end
    end
end
load()

local conns = {}
local function addConn(c, n) if c then conns[n or #conns+1] = c end end
local function rmConn(n)
    local c = conns[n]
    if c then pcall(function() c:Disconnect() end) conns[n] = nil end
end
local function cleanup()
    for _,c in pairs(conns) do pcall(function() c:Disconnect() end) end
    conns = {}
end

local clr = {
    main = Color3.fromRGB(88,45,138),
    mainL = Color3.fromRGB(138,75,188),
    mainD = Color3.fromRGB(68,35,108),
    sec = Color3.fromRGB(55,35,85),
    bg = Color3.fromRGB(25,25,35),
    bgL = Color3.fromRGB(35,30,50),
    bgD = Color3.fromRGB(20,18,28),
    surf = Color3.fromRGB(35,32,48),
    surfL = Color3.fromRGB(45,42,58),
    surfH = Color3.fromRGB(55,50,75),
    txt = Color3.new(1,1,1),
    txtM = Color3.fromRGB(180,180,180),
    good = Color3.fromRGB(60,180,80),
    bad = Color3.fromRGB(180,60,60),
    warn = Color3.fromRGB(200,150,50),
    tabOff = Color3.fromRGB(50,45,70),
    togOff = Color3.fromRGB(60,60,70)
}

local maxMsg = 200
local retries = 3

-- performance tracking
local perfStats = {
    avgResponseTime = 0,
    totalRequests = 0,
    cachedResponses = 0,
    queuedMsgs = 0,
    contextSwitches = 0
}

-- response cache for similar messages
local respCache = {}
local cacheMaxSize = 50
local cacheHitWindow = 300 -- 5 min

-- per-player memory with full conversation history
-- Structure: playerMemory[plrId] = {
--   messages = {{role="user/assistant", content="...", timestamp=tick(), displayName="..."}},
--   lastTopic = "topic summary",
--   lastInteraction = tick(),
--   contextSummary = "ongoing context"
-- }
local playerMemory = {}

-- spam detection
local spamTracker = {}

-- request queue
local reqQueue = {}
local processing = false

-- friends cache
local friendsCache = {}
local friendsCacheTime = 0

-- context analysis helpers
local function formatTimeAgo(seconds)
    if seconds < 60 then
        return string.format("%d seconds ago", math.floor(seconds))
    elseif seconds < 3600 then
        local mins = math.floor(seconds / 60)
        return string.format("%d minute%s ago", mins, mins == 1 and "" or "s")
    elseif seconds < 86400 then
        local hours = math.floor(seconds / 3600)
        return string.format("%d hour%s ago", hours, hours == 1 and "" or "s")
    else
        local days = math.floor(seconds / 86400)
        return string.format("%d day%s ago", days, days == 1 and "" or "s")
    end
end

local function getTimeDiffMinutes(t1, t2)
    return math.abs(t2 - t1) / 60
end

local lib = {}
local gui = Instance.new("ScreenGui")
gui.Name = "MapleUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
gui.Parent = game:GetService("CoreGui")

local function grad(p, c1, c2, r)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,c1), ColorSequenceKeypoint.new(1,c2)})
    g.Rotation = r or 45
    g.Parent = p
    return g
end

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p
    return c
end

local function stroke(p, col, th)
    local s = Instance.new("UIStroke")
    s.Color = col or clr.main
    s.Thickness = th or 1
    s.Transparency = 0.5
    s.Parent = p
    return s
end

local function shadow(p)
    local s = Instance.new("ImageLabel")
    s.Name = "shd"
    s.BackgroundTransparency = 1
    s.Position = UDim2.new(0,-15,0,-15)
    s.Size = UDim2.new(1,30,1,30)
    s.ZIndex = p.ZIndex - 1
    s.Image = "rbxassetid://5554236805"
    s.ImageColor3 = Color3.new(0,0,0)
    s.ImageTransparency = 0.5
    s.ScaleType = Enum.ScaleType.Slice
    s.SliceCenter = Rect.new(23,23,277,277)
    s.Parent = p
    return s
end

local function pad(p, amt)
    local pd = Instance.new("UIPadding")
    pd.PaddingLeft = UDim.new(0, amt or 5)
    pd.PaddingRight = UDim.new(0, amt or 5)
    pd.PaddingTop = UDim.new(0, amt or 5)
    pd.PaddingBottom = UDim.new(0, amt or 5)
    pd.Parent = p
    return pd
end

local function tween(o, pr, t, st, di)
    local tw = ts:Create(o, TweenInfo.new(t or 0.3, st or Enum.EasingStyle.Quart, di or Enum.EasingDirection.Out), pr)
    tw:Play()
    return tw
end

local function hover(btn, n, h)
    btn.MouseEnter:Connect(function() tween(btn, {BackgroundColor3=h}, 0.15) end)
    btn.MouseLeave:Connect(function() tween(btn, {BackgroundColor3=n}, 0.15) end)
end

local toastBox = Instance.new("Frame")
toastBox.Name = "toasts"
toastBox.Size = UDim2.new(0,300,1,0)
toastBox.Position = UDim2.new(1,-320,0,0)
toastBox.BackgroundTransparency = 1
toastBox.Parent = gui

local toastLay = Instance.new("UIListLayout")
toastLay.Parent = toastBox
toastLay.SortOrder = Enum.SortOrder.LayoutOrder
toastLay.VerticalAlignment = Enum.VerticalAlignment.Bottom
toastLay.Padding = UDim.new(0,10)

local tCnt = 0

local function toast(msg, typ, dur)
    typ = typ or "info"
    dur = dur or 3
    local cols = {info=clr.main, success=clr.good, error=clr.bad, warning=clr.warn}
    tCnt = tCnt + 1
    local t = Instance.new("Frame")
    t.Name = "t"..tCnt
    t.Size = UDim2.new(1,0,0,50)
    t.BackgroundColor3 = clr.surf
    t.LayoutOrder = tCnt
    t.Parent = toastBox
    corner(t,8)
    stroke(t, cols[typ], 2)
    
    local ico = Instance.new("Frame")
    ico.Size = UDim2.new(0,4,1,-10)
    ico.Position = UDim2.new(0,5,0,5)
    ico.BackgroundColor3 = cols[typ]
    ico.Parent = t
    corner(ico,2)
    
    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1,-25,1,0)
    txt.Position = UDim2.new(0,20,0,0)
    txt.BackgroundTransparency = 1
    txt.Text = msg
    txt.TextColor3 = clr.txt
    txt.TextSize = 14
    txt.Font = Enum.Font.Gotham
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.TextWrapped = true
    txt.Parent = t
    
    t.Position = UDim2.new(1,50,0,0)
    tween(t, {Position=UDim2.new(0,0,0,0)}, 0.3, Enum.EasingStyle.Back)
    
    task.delay(dur, function()
        tween(t, {Position=UDim2.new(1,50,0,0)}, 0.3)
        task.wait(0.3)
        t:Destroy()
    end)
end

local function statInd(p)
    local ind = Instance.new("Frame")
    ind.Name = "stat"
    ind.Size = UDim2.new(0,12,0,12)
    ind.Position = UDim2.new(1,-25,0.5,-6)
    ind.BackgroundColor3 = clr.bad
    ind.Parent = p
    corner(ind,6)
    return ind
end

local togBtn = Instance.new("Frame")
togBtn.Name = "tog"
togBtn.Size = UDim2.new(0,50,0,50)
togBtn.Position = UDim2.new(0,20,1,-70)
togBtn.BackgroundColor3 = clr.main
togBtn.Parent = gui
corner(togBtn,25)
shadow(togBtn)
grad(togBtn, clr.mainL, clr.mainD, 45)

local togIco = Instance.new("TextLabel")
togIco.Size = UDim2.new(1,0,1,0)
togIco.BackgroundTransparency = 1
togIco.Text = "🍁"
togIco.Font = Enum.Font.GothamBold
togIco.TextSize = 24
togIco.TextColor3 = clr.txt
togIco.Parent = togBtn

local togBtnObj = Instance.new("TextButton")
togBtnObj.Size = UDim2.new(1,0,1,0)
togBtnObj.BackgroundTransparency = 1
togBtnObj.Text = ""
togBtnObj.Parent = togBtn

local togDot = Instance.new("Frame")
togDot.Size = UDim2.new(0,14,0,14)
togDot.Position = UDim2.new(1,-10,0,-4)
togDot.BackgroundColor3 = clr.bad
togDot.Parent = togBtn
corner(togDot,7)
stroke(togDot, clr.bg, 2)

local function updDot()
    local c = getgenv().MapleConfig.MasterEnabled and clr.good or clr.bad
    tween(togDot, {BackgroundColor3=c}, 0.3)
end

local drag = false
local dragSt, stPos
local dragMv = false

togBtnObj.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drag = true
        dragMv = false
        dragSt = i.Position
        stPos = togBtn.Position
    end
end)

togBtnObj.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drag = false
    end
end)

addConn(uis.InputChanged:Connect(function(i)
    if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - dragSt
        if d.Magnitude > 5 then dragMv = true end
        togBtn.Position = UDim2.new(stPos.X.Scale, stPos.X.Offset+d.X, stPos.Y.Scale, stPos.Y.Offset+d.Y)
    end
end), "togDrag")

local win = Instance.new("Frame")
win.Name = "win"
win.Size = UDim2.new(0,600,0,480)
win.Position = UDim2.new(0.5,-300,0.5,-240)
win.BackgroundColor3 = clr.bg
win.Visible = false
win.ClipsDescendants = true
win.Parent = gui
corner(win,12)
shadow(win)
grad(win, clr.bgL, clr.bgD, 90)

local title = Instance.new("Frame")
title.Name = "title"
title.Size = UDim2.new(1,0,0,45)
title.BackgroundColor3 = clr.sec
title.Parent = win
corner(title,12)
grad(title, clr.main, clr.sec, 90)

local titleTxt = Instance.new("TextLabel")
titleTxt.Size = UDim2.new(1,-100,1,0)
titleTxt.Position = UDim2.new(0,15,0,0)
titleTxt.BackgroundTransparency = 1
titleTxt.Text = "🍁 Maple AI"
titleTxt.TextColor3 = clr.txt
titleTxt.TextSize = 18
titleTxt.Font = Enum.Font.GothamBold
titleTxt.TextXAlignment = Enum.TextXAlignment.Left
titleTxt.Parent = title

local verLbl = Instance.new("TextLabel")
verLbl.Size = UDim2.new(0,50,0,20)
verLbl.Position = UDim2.new(0,130,0.5,-10)
verLbl.BackgroundTransparency = 1
verLbl.Text = "v4.0"
verLbl.TextColor3 = clr.txtM
verLbl.TextSize = 12
verLbl.Font = Enum.Font.Gotham
verLbl.Parent = title

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0,30,0,30)
minBtn.Position = UDim2.new(1,-75,0.5,-15)
minBtn.BackgroundColor3 = clr.warn
minBtn.Font = Enum.Font.GothamBold
minBtn.Text = "−"
minBtn.TextColor3 = clr.txt
minBtn.TextSize = 20
minBtn.Parent = title
corner(minBtn,6)
hover(minBtn, clr.warn, clr.warn:Lerp(Color3.new(1,1,1),0.2))

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,30,0,30)
closeBtn.Position = UDim2.new(1,-40,0.5,-15)
closeBtn.BackgroundColor3 = clr.bad
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "×"
closeBtn.TextColor3 = clr.txt
closeBtn.TextSize = 20
closeBtn.Parent = title
corner(closeBtn,6)
hover(closeBtn, clr.bad, clr.bad:Lerp(Color3.new(1,1,1),0.2))

local wDrag = false
local wDragSt, wStPos

title.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        wDrag = true
        wDragSt = i.Position
        wStPos = win.Position
    end
end)

title.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        wDrag = false
    end
end)

addConn(uis.InputChanged:Connect(function(i)
    if wDrag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - wDragSt
        win.Position = UDim2.new(wStPos.X.Scale, wStPos.X.Offset+d.X, wStPos.Y.Scale, wStPos.Y.Offset+d.Y)
    end
end), "winDrag")

local tabBox = Instance.new("Frame")
tabBox.Name = "tabs"
tabBox.Size = UDim2.new(0,120,1,-55)
tabBox.Position = UDim2.new(0,10,0,50)
tabBox.BackgroundColor3 = clr.surf
tabBox.Parent = win
corner(tabBox,8)

local tabPad = Instance.new("UIPadding")
tabPad.PaddingTop = UDim.new(0,5)
tabPad.PaddingLeft = UDim.new(0,5)
tabPad.PaddingRight = UDim.new(0,5)
tabPad.Parent = tabBox

local tabLay = Instance.new("UIListLayout")
tabLay.Parent = tabBox
tabLay.SortOrder = Enum.SortOrder.LayoutOrder
tabLay.Padding = UDim.new(0,5)

local content = Instance.new("Frame")
content.Name = "content"
content.Size = UDim2.new(1,-145,1,-55)
content.Position = UDim2.new(0,135,0,50)
content.BackgroundColor3 = clr.surf
content.Parent = win
corner(content,8)

local tabs = {}
local tabBtns = {}
local curTab = nil

local function makeTab(name, ico, ord)
    local btn = Instance.new("TextButton")
    btn.Name = name.."Tab"
    btn.Size = UDim2.new(1,0,0,32)
    btn.BackgroundColor3 = clr.tabOff
    btn.Text = (ico or "").." "..name
    btn.TextColor3 = clr.txtM
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamSemibold
    btn.LayoutOrder = ord
    btn.Parent = tabBox
    corner(btn,6)

    local cont = Instance.new("ScrollingFrame")
    cont.Name = name.."Content"
    cont.Size = UDim2.new(1,-20,1,-20)
    cont.Position = UDim2.new(0,10,0,10)
    cont.BackgroundTransparency = 1
    cont.Visible = false
    cont.ScrollBarThickness = 4
    cont.ScrollBarImageColor3 = clr.main
    cont.CanvasSize = UDim2.new(0,0,0,0)
    cont.AutomaticCanvasSize = Enum.AutomaticSize.Y
    cont.Parent = content

    tabs[name] = cont
    tabBtns[name] = btn

    btn.MouseButton1Click:Connect(function() lib:SelectTab(name) end)
    btn.MouseEnter:Connect(function()
        if curTab ~= name then tween(btn, {BackgroundColor3=clr.surfH}, 0.15) end
    end)
    btn.MouseLeave:Connect(function()
        if curTab ~= name then tween(btn, {BackgroundColor3=clr.tabOff}, 0.15) end
    end)

    local lay = Instance.new("UIListLayout")
    lay.Parent = cont
    lay.Padding = UDim.new(0,8)

    return cont
end

function lib:SelectTab(name)
    if curTab then
        tabs[curTab].Visible = false
        tween(tabBtns[curTab], {BackgroundColor3=clr.tabOff}, 0.2)
        tabBtns[curTab].TextColor3 = clr.txtM
    end
    curTab = name
    tabs[name].Visible = true
    tween(tabBtns[name], {BackgroundColor3=clr.main}, 0.2)
    tabBtns[name].TextColor3 = clr.txt
end

local homeTab = makeTab("Home", "🏠", 1)
local settTab = makeTab("Settings", "⚙️", 2)
local advTab = makeTab("Advanced", "🔧", 3)
local ctxTab = makeTab("Context", "🧠", 4)
local persTab = makeTab("Persona", "🎭", 5)
local modTab = makeTab("Models", "🤖", 6)
local blTab = makeTab("Blacklist", "🚫", 7)
local statTab = makeTab("Stats", "📊", 8)

local function mkToggle(p, txt, def, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,0,36)
    f.BackgroundTransparency = 1
    f.Parent = p

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,-60,1,0)
    l.BackgroundTransparency = 1
    l.Text = txt
    l.TextColor3 = clr.txt
    l.TextSize = 13
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f

    local tog = Instance.new("Frame")
    tog.Size = UDim2.new(0,44,0,22)
    tog.Position = UDim2.new(1,-48,0.5,-11)
    tog.BackgroundColor3 = def and clr.main or clr.togOff
    tog.Parent = f
    corner(tog,11)

    local ind = Instance.new("Frame")
    ind.Size = UDim2.new(0,18,0,18)
    ind.Position = def and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)
    ind.BackgroundColor3 = clr.txt
    ind.Parent = tog
    corner(ind,9)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = tog

    local on = def
    local function set(v)
        on = v
        if on then
            tween(tog, {BackgroundColor3=clr.main}, 0.2)
            tween(ind, {Position=UDim2.new(1,-20,0.5,-9)}, 0.2)
        else
            tween(tog, {BackgroundColor3=clr.togOff}, 0.2)
            tween(ind, {Position=UDim2.new(0,2,0.5,-9)}, 0.2)
        end
        if cb then cb(on) end
    end
    btn.MouseButton1Click:Connect(function() set(not on) end)
    return f, set
end

local function mkSlider(p, txt, min, max, def, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,0,50)
    f.BackgroundTransparency = 1
    f.Parent = p

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,-50,0,20)
    l.BackgroundTransparency = 1
    l.Text = txt
    l.TextColor3 = clr.txt
    l.TextSize = 13
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0,45,0,20)
    valLbl.Position = UDim2.new(1,-45,0,0)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(def)
    valLbl.TextColor3 = clr.txtM
    valLbl.TextSize = 12
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = f

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1,0,0,6)
    track.Position = UDim2.new(0,0,0,30)
    track.BackgroundColor3 = clr.surfL
    track.Parent = f
    corner(track,3)

    local fill = Instance.new("Frame")
    local pct = (def-min)/(max-min)
    fill.Size = UDim2.new(pct,0,1,0)
    fill.BackgroundColor3 = clr.main
    fill.Parent = track
    corner(fill,3)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0,14,0,14)
    knob.Position = UDim2.new(pct,-7,0.5,-7)
    knob.BackgroundColor3 = clr.txt
    knob.Parent = track
    corner(knob,7)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,20)
    btn.Position = UDim2.new(0,0,0,22)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = f

    local dragging = false
    btn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    btn.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    addConn(uis.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = (i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
            rel = math.clamp(rel, 0, 1)
            local val = min + rel * (max - min)
            if max <= 1 then val = math.floor(val * 100) / 100
            else val = math.floor(val) end
            valLbl.Text = tostring(val)
            fill.Size = UDim2.new(rel,0,1,0)
            knob.Position = UDim2.new(rel,-7,0.5,-7)
            if cb then cb(val) end
        end
    end), "slider_"..txt)

    return f
end

local function mkInput(p, lbl, ph, def, multi, cb)
    local f = Instance.new("Frame")
    f.Size = multi and UDim2.new(1,0,0,130) or UDim2.new(1,0,0,60)
    f.BackgroundTransparency = 1
    f.Parent = p

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,0,0,18)
    l.BackgroundTransparency = 1
    l.Text = lbl
    l.TextColor3 = clr.txt
    l.TextSize = 13
    l.Font = Enum.Font.GothamSemibold
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f

    local h = multi and 100 or 32
    local inp = Instance.new("TextBox")
    inp.Size = UDim2.new(1,0,0,h)
    inp.Position = UDim2.new(0,0,0,22)
    inp.BackgroundColor3 = clr.surfL
    inp.Text = def or ""
    inp.PlaceholderText = ph or ""
    inp.TextColor3 = clr.txt
    inp.PlaceholderColor3 = clr.txtM
    inp.TextSize = 13
    inp.Font = Enum.Font.Gotham
    inp.ClearTextOnFocus = false
    inp.Parent = f
    corner(inp,6)
    local st = stroke(inp, clr.main, 1)
    st.Transparency = 0.8
    
    if multi then
        inp.TextYAlignment = Enum.TextYAlignment.Top
        inp.MultiLine = true
        inp.TextWrapped = true
        pad(inp, 6)
    end

    inp.FocusLost:Connect(function() if cb then cb(inp.Text) end end)
    inp.Focused:Connect(function()
        local s = inp:FindFirstChildOfClass("UIStroke")
        if s then tween(s, {Transparency=0}, 0.2) end
    end)
    inp.FocusLost:Connect(function()
        local s = inp:FindFirstChildOfClass("UIStroke")
        if s then tween(s, {Transparency=0.8}, 0.2) end
    end)

    return f, inp
end

local function mkDropdown(p, lbl, opts, def, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,0,60)
    f.BackgroundTransparency = 1
    f.ClipsDescendants = false
    f.Parent = p

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,0,0,18)
    l.BackgroundTransparency = 1
    l.Text = lbl
    l.TextColor3 = clr.txt
    l.TextSize = 13
    l.Font = Enum.Font.GothamSemibold
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,32)
    btn.Position = UDim2.new(0,0,0,22)
    btn.BackgroundColor3 = clr.surfL
    btn.Text = "  "..def
    btn.TextColor3 = clr.txt
    btn.TextSize = 13
    btn.Font = Enum.Font.Gotham
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = f
    corner(btn,6)

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0,20,1,0)
    arrow.Position = UDim2.new(1,-25,0,0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = clr.txtM
    arrow.TextSize = 10
    arrow.Parent = btn

    local list = Instance.new("Frame")
    list.Size = UDim2.new(1,0,0,#opts*30)
    list.Position = UDim2.new(0,0,0,56)
    list.BackgroundColor3 = clr.surfL
    list.Visible = false
    list.ZIndex = 10
    list.Parent = f
    corner(list,6)

    for i, opt in ipairs(opts) do
        local ob = Instance.new("TextButton")
        ob.Size = UDim2.new(1,0,0,30)
        ob.Position = UDim2.new(0,0,0,(i-1)*30)
        ob.BackgroundTransparency = 1
        ob.Text = "  "..opt
        ob.TextColor3 = clr.txt
        ob.TextSize = 13
        ob.Font = Enum.Font.Gotham
        ob.TextXAlignment = Enum.TextXAlignment.Left
        ob.ZIndex = 11
        ob.Parent = list

        ob.MouseButton1Click:Connect(function()
            btn.Text = "  "..opt
            list.Visible = false
            if cb then cb(opt) end
        end)
    end

    btn.MouseButton1Click:Connect(function() list.Visible = not list.Visible end)

    return f
end

local function mkBtn(p, txt, cb)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,36)
    btn.BackgroundColor3 = clr.main
    btn.Text = txt
    btn.TextColor3 = clr.txt
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamSemibold
    btn.Parent = p
    corner(btn,6)
    grad(btn, clr.mainL, clr.main, 90)
    hover(btn, clr.main, clr.mainL)
    btn.MouseButton1Click:Connect(function() if cb then cb() end end)
    return btn
end

local function mkLabel(p, txt, muted)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,0,0,20)
    l.BackgroundTransparency = 1
    l.Text = txt
    l.TextColor3 = muted and clr.txtM or clr.txt
    l.TextSize = 12
    l.Font = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = p
    return l
end

-- home tab
local statFr = Instance.new("Frame")
statFr.Size = UDim2.new(1,0,0,60)
statFr.BackgroundColor3 = clr.surfL
statFr.Parent = homeTab
corner(statFr,8)

local statIco = Instance.new("TextLabel")
statIco.Size = UDim2.new(0,40,0,40)
statIco.Position = UDim2.new(0,10,0.5,-20)
statIco.BackgroundTransparency = 1
statIco.Text = "🍁"
statIco.TextSize = 30
statIco.Parent = statFr

local statTxt = Instance.new("TextLabel")
statTxt.Size = UDim2.new(1,-60,0,20)
statTxt.Position = UDim2.new(0,55,0,10)
statTxt.BackgroundTransparency = 1
statTxt.Text = "Status: "..(getgenv().MapleConfig.MasterEnabled and "Active" or "Inactive")
statTxt.TextColor3 = clr.txt
statTxt.TextSize = 14
statTxt.Font = Enum.Font.GothamBold
statTxt.TextXAlignment = Enum.TextXAlignment.Left
statTxt.Parent = statFr

local statSub = Instance.new("TextLabel")
statSub.Size = UDim2.new(1,-60,0,15)
statSub.Position = UDim2.new(0,55,0,32)
statSub.BackgroundTransparency = 1
statSub.Text = "Ready"
statSub.TextColor3 = clr.txtM
statSub.TextSize = 11
statSub.Font = Enum.Font.Gotham
statSub.TextXAlignment = Enum.TextXAlignment.Left
statSub.Parent = statFr

local homeInd = statInd(statFr)

local function updHome()
    local en = getgenv().MapleConfig.MasterEnabled
    local afk = getgenv().MapleConfig.AFKMode
    statTxt.Text = "Status: "..(en and (afk and "AFK" or "Active") or "Inactive")
    statSub.Text = en and (afk and "Auto-responding with AFK message" or "Responding to chat") or "Click toggle to enable"
    homeInd.BackgroundColor3 = en and (afk and clr.warn or clr.good) or clr.bad
end

local _, masterSet = mkToggle(homeTab, "Enable AI", getgenv().MapleConfig.MasterEnabled, function(v)
    getgenv().MapleConfig.MasterEnabled = v
    save()
    updDot()
    updHome()
    toast(v and "AI Enabled" or "AI Disabled", v and "success" or "info")
end)

mkToggle(homeTab, "AFK Mode", getgenv().MapleConfig.AFKMode, function(v)
    getgenv().MapleConfig.AFKMode = v
    save()
    updHome()
    toast(v and "AFK Mode On" or "AFK Mode Off", "info")
end)

mkLabel(homeTab, "Quick Actions", true)

mkBtn(homeTab, "Clear All History", function()
    chatHistory = {}
    playerMemory = {}
    toast("History cleared", "success")
end)

mkBtn(homeTab, "Clear Response Cache", function()
    respCache = {}
    perfStats.cachedResponses = 0
    toast("Cache cleared", "success")
end)

updHome()

-- settings tab
local _, apiInp = mkInput(settTab, "API Key", "Enter API key...", "", false, function(t)
    if t ~= "" and not t:match("^%*+$") then
        getgenv().MapleConfig.APIKey = t
        save()
        apiInp.Text = string.rep("*", math.min(#t, 32))
        toast("API Key saved", "success")
    end
end)

if getgenv().MapleConfig.APIKey ~= "" then
    apiInp.Text = string.rep("*", math.min(#getgenv().MapleConfig.APIKey, 32))
end

mkLabel(settTab, "Range Settings", true)

mkSlider(settTab, "Response Range (0=unlimited)", 0, 200, getgenv().MapleConfig.Range, function(v)
    getgenv().MapleConfig.Range = v
    save()
end)

mkLabel(settTab, "Trigger Mode", true)

mkDropdown(settTab, "When to respond", {"all", "mention", "prefix"}, getgenv().MapleConfig.TriggerMode, function(v)
    getgenv().MapleConfig.TriggerMode = v
    save()
    toast("Trigger: "..v, "info")
end)

local _, prefInp = mkInput(settTab, "Prefix (if prefix mode)", "@maple", getgenv().MapleConfig.TriggerPrefix, false, function(t)
    getgenv().MapleConfig.TriggerPrefix = t
    save()
end)

mkToggle(settTab, "Debug Mode", getgenv().MapleConfig.DebugMode or false, function(v)
    getgenv().MapleConfig.DebugMode = v
    dbg = v
    save()
end)

-- advanced tab
mkLabel(advTab, "Response Settings", true)

mkSlider(advTab, "Max Tokens", 50, 500, getgenv().MapleConfig.MaxTokens, function(v)
    getgenv().MapleConfig.MaxTokens = v
    save()
end)

mkSlider(advTab, "Temperature", 0, 1, getgenv().MapleConfig.Temperature, function(v)
    getgenv().MapleConfig.Temperature = v
    save()
end)

mkSlider(advTab, "Response Delay (sec)", 0, 5, getgenv().MapleConfig.ResponseDelay, function(v)
    getgenv().MapleConfig.ResponseDelay = v
    save()
end)

mkLabel(advTab, "Anti-Spam", true)

mkToggle(advTab, "Enable Anti-Spam", getgenv().MapleConfig.AntiSpam, function(v)
    getgenv().MapleConfig.AntiSpam = v
    save()
end)

mkSlider(advTab, "Spam Threshold", 2, 10, getgenv().MapleConfig.SpamThreshold, function(v)
    getgenv().MapleConfig.SpamThreshold = v
    save()
end)

mkLabel(advTab, "Friends", true)

mkToggle(advTab, "Auto-Whitelist Friends", getgenv().MapleConfig.AutoWhitelistFriends, function(v)
    getgenv().MapleConfig.AutoWhitelistFriends = v
    save()
end)

mkToggle(advTab, "Prioritize Friends", getgenv().MapleConfig.PrioritizeFriends, function(v)
    getgenv().MapleConfig.PrioritizeFriends = v
    save()
end)

mkLabel(advTab, "AFK Settings", true)

local _, afkInp = mkInput(advTab, "AFK Message", "AFK message...", getgenv().MapleConfig.AFKMessage, false, function(t)
    getgenv().MapleConfig.AFKMessage = t
    save()
end)

mkBtn(advTab, "Reset to Defaults", function()
    for k,v in pairs(defCfg) do getgenv().MapleConfig[k] = v end
    save()
    toast("Reset done", "warning")
end)

-- context tab (new)
mkLabel(ctxTab, "Context-Aware AI Settings", true)

mkToggle(ctxTab, "Smart Context Analysis", getgenv().MapleConfig.SmartContextEnabled, function(v)
    getgenv().MapleConfig.SmartContextEnabled = v
    save()
    toast(v and "Smart context ON" or "Smart context OFF", "info")
end)

mkToggle(ctxTab, "Show Timestamps to AI", getgenv().MapleConfig.ShowTimestamps, function(v)
    getgenv().MapleConfig.ShowTimestamps = v
    save()
end)

mkToggle(ctxTab, "Unlimited Memory", getgenv().MapleConfig.RememberForever, function(v)
    getgenv().MapleConfig.RememberForever = v
    save()
    toast(v and "Unlimited memory ON" or "Limited memory", "info")
end)

mkLabel(ctxTab, "Timing Thresholds", true)

mkSlider(ctxTab, "Context Timeout (min)", 1, 30, getgenv().MapleConfig.ContextTimeoutMinutes, function(v)
    getgenv().MapleConfig.ContextTimeoutMinutes = v
    save()
end)

mkSlider(ctxTab, "Long Gap (min)", 5, 60, getgenv().MapleConfig.LongGapMinutes, function(v)
    getgenv().MapleConfig.LongGapMinutes = v
    save()
end)

mkSlider(ctxTab, "Context Window Size", 5, 50, getgenv().MapleConfig.ContextWindowSize, function(v)
    getgenv().MapleConfig.ContextWindowSize = v
    save()
end)

mkLabel(ctxTab, "Memory Management", true)

mkBtn(ctxTab, "Clear All Player Memory", function()
    playerMemory = {}
    toast("All player memory cleared", "success")
end)

mkBtn(ctxTab, "View Memory Stats", function()
    local totalMsgs = 0
    local playerCount = 0
    for plrId, data in pairs(playerMemory) do
        playerCount = playerCount + 1
        if data.messages then
            totalMsgs = totalMsgs + #data.messages
        end
    end
    toast(string.format("%d players, %d total messages", playerCount, totalMsgs), "info", 4)
end)

-- persona tab
local _, persInp = mkInput(persTab, "System Instructions", "Enter persona...", getgenv().MapleConfig.Persona, true, function(t)
    getgenv().MapleConfig.Persona = t
    save()
    toast("Persona updated", "success")
end)

mkLabel(persTab, "Presets", true)

local presets = {
    {n="Helpful Assistant", p="You are a helpful AI assistant. Be friendly, concise, and informative."},
    {n="Creative Writer", p="You are a creative writer. Be imaginative, poetic, and engaging."},
    {n="Casual Friend", p="You are a casual friend. Use informal language, be fun, keep it short."},
    {n="Gamer", p="You are a fellow gamer. Use gaming slang, be enthusiastic about games."},
    {n="Sarcastic", p="You are sarcastic and witty. Use humor and irony in responses."}
}

for _, pre in ipairs(presets) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,28)
    btn.BackgroundColor3 = clr.surfL
    btn.Text = "  "..pre.n
    btn.TextColor3 = clr.txt
    btn.TextSize = 12
    btn.Font = Enum.Font.Gotham
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = persTab
    corner(btn,6)
    hover(btn, clr.surfL, clr.surfH)
    btn.MouseButton1Click:Connect(function()
        persInp.Text = pre.p
        getgenv().MapleConfig.Persona = pre.p
        save()
        toast("Applied: "..pre.n, "success")
    end)
end

-- models tab
mkLabel(modTab, "Select Model", true)

local models = {
    {id="gpt-4", n="GPT-4", d="Most capable"},
    {id="gpt-3.5-turbo", n="GPT-3.5 Turbo", d="Fast"},
    {id="claude-v1", n="Claude v1", d="Anthropic"},
    {id="maple-light", n="Maple Light", d="Lightweight"}
}

for _, m in ipairs(models) do
    local mf = Instance.new("Frame")
    mf.Size = UDim2.new(1,0,0,45)
    mf.BackgroundColor3 = getgenv().MapleConfig.Model == m.id and clr.main or clr.surfL
    mf.Parent = modTab
    corner(mf,6)
    
    local mn = Instance.new("TextLabel")
    mn.Size = UDim2.new(1,-15,0,18)
    mn.Position = UDim2.new(0,10,0,6)
    mn.BackgroundTransparency = 1
    mn.Text = m.n
    mn.TextColor3 = clr.txt
    mn.TextSize = 13
    mn.Font = Enum.Font.GothamBold
    mn.TextXAlignment = Enum.TextXAlignment.Left
    mn.Parent = mf
    
    local md = Instance.new("TextLabel")
    md.Size = UDim2.new(1,-15,0,14)
    md.Position = UDim2.new(0,10,0,24)
    md.BackgroundTransparency = 1
    md.Text = m.d
    md.TextColor3 = clr.txtM
    md.TextSize = 10
    md.Font = Enum.Font.Gotham
    md.TextXAlignment = Enum.TextXAlignment.Left
    md.Parent = mf
    
    local sb = Instance.new("TextButton")
    sb.Size = UDim2.new(1,0,1,0)
    sb.BackgroundTransparency = 1
    sb.Text = ""
    sb.Parent = mf
    
    sb.MouseButton1Click:Connect(function()
        getgenv().MapleConfig.Model = m.id
        save()
        toast("Model: "..m.n, "success")
        for _, c in ipairs(modTab:GetChildren()) do
            if c:IsA("Frame") then c.BackgroundColor3 = clr.surfL end
        end
        mf.BackgroundColor3 = clr.main
    end)
    
    sb.MouseEnter:Connect(function()
        if getgenv().MapleConfig.Model ~= m.id then tween(mf, {BackgroundColor3=clr.surfH}, 0.15) end
    end)
    sb.MouseLeave:Connect(function()
        if getgenv().MapleConfig.Model ~= m.id then tween(mf, {BackgroundColor3=clr.surfL}, 0.15) end
    end)
end

-- blacklist tab
local addFr = Instance.new("Frame")
addFr.Size = UDim2.new(1,0,0,32)
addFr.BackgroundTransparency = 1
addFr.Parent = blTab

local plrInp = Instance.new("TextBox")
plrInp.Size = UDim2.new(1,-40,1,0)
plrInp.BackgroundColor3 = clr.surfL
plrInp.PlaceholderText = "Player name..."
plrInp.PlaceholderColor3 = clr.txtM
plrInp.TextColor3 = clr.txt
plrInp.TextSize = 13
plrInp.Font = Enum.Font.Gotham
plrInp.ClearTextOnFocus = false
plrInp.Parent = addFr
corner(plrInp,6)
pad(plrInp,6)

local addBtn = Instance.new("TextButton")
addBtn.Size = UDim2.new(0,32,1,0)
addBtn.Position = UDim2.new(1,-32,0,0)
addBtn.BackgroundColor3 = clr.main
addBtn.Text = "+"
addBtn.TextColor3 = clr.txt
addBtn.Font = Enum.Font.GothamBold
addBtn.TextSize = 18
addBtn.Parent = addFr
corner(addBtn,6)
hover(addBtn, clr.main, clr.mainL)

local blScroll = Instance.new("Frame")
blScroll.Size = UDim2.new(1,0,0,200)
blScroll.BackgroundTransparency = 1
blScroll.Parent = blTab

local blLay = Instance.new("UIListLayout")
blLay.Parent = blScroll
blLay.Padding = UDim.new(0,4)

local function refreshBl()
    for _, c in ipairs(blScroll:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
    end

    if #getgenv().MapleConfig.Blacklist == 0 then
        local el = Instance.new("TextLabel")
        el.Size = UDim2.new(1,0,0,40)
        el.BackgroundTransparency = 1
        el.Text = "No blacklisted players"
        el.TextColor3 = clr.txtM
        el.TextSize = 13
        el.Font = Enum.Font.Gotham
        el.Parent = blScroll
    else
        for i, nm in ipairs(getgenv().MapleConfig.Blacklist) do
            local it = Instance.new("Frame")
            it.Size = UDim2.new(1,0,0,30)
            it.BackgroundColor3 = clr.surfL
            it.Parent = blScroll
            corner(it,6)

            local lb = Instance.new("TextLabel")
            lb.Size = UDim2.new(1,-40,1,0)
            lb.Position = UDim2.new(0,8,0,0)
            lb.BackgroundTransparency = 1
            lb.Text = nm
            lb.Font = Enum.Font.Gotham
            lb.TextColor3 = clr.txt
            lb.TextSize = 13
            lb.TextXAlignment = Enum.TextXAlignment.Left
            lb.Parent = it

            local rm = Instance.new("TextButton")
            rm.Size = UDim2.new(0,30,1,0)
            rm.Position = UDim2.new(1,-30,0,0)
            rm.BackgroundTransparency = 1
            rm.Text = "×"
            rm.Font = Enum.Font.GothamBold
            rm.TextSize = 18
            rm.TextColor3 = clr.bad
            rm.Parent = it

            rm.MouseButton1Click:Connect(function()
                table.remove(getgenv().MapleConfig.Blacklist, i)
                save()
                refreshBl()
                toast("Removed "..nm, "info")
            end)
        end
    end
end

addBtn.MouseButton1Click:Connect(function()
    local nm = plrInp.Text:gsub("^%s*(.-)%s*$", "%1")
    if nm ~= "" then
        if table.find(getgenv().MapleConfig.Blacklist, nm) then
            toast(nm.." already blacklisted", "warning")
        else
            table.insert(getgenv().MapleConfig.Blacklist, nm)
            save()
            refreshBl()
            plrInp.Text = ""
            toast("Added "..nm, "success")
        end
    end
end)
refreshBl()

-- stats tab
local sData = {msgs=0, resp=0, errs=0}

local function mkStatRow(nm, val)
    local r = Instance.new("Frame")
    r.Size = UDim2.new(1,0,0,35)
    r.BackgroundColor3 = clr.surfL
    r.Parent = statTab
    corner(r,6)
    
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.6,0,1,0)
    l.Position = UDim2.new(0,12,0,0)
    l.BackgroundTransparency = 1
    l.Text = nm
    l.TextColor3 = clr.txtM
    l.TextSize = 12
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = r
    
    local v = Instance.new("TextLabel")
    v.Name = "v"
    v.Size = UDim2.new(0.4,-12,1,0)
    v.Position = UDim2.new(0.6,0,0,0)
    v.BackgroundTransparency = 1
    v.Text = tostring(val)
    v.TextColor3 = clr.txt
    v.TextSize = 13
    v.Font = Enum.Font.GothamBold
    v.TextXAlignment = Enum.TextXAlignment.Right
    v.Parent = r
    
    return r, v
end

local _, msgsLbl = mkStatRow("Messages", 0)
local _, respLbl = mkStatRow("Responses", 0)
local _, errsLbl = mkStatRow("Errors", 0)
local _, cacheLbl = mkStatRow("Cache Hits", 0)
local _, queueLbl = mkStatRow("Queue Size", 0)
local _, avgTimeLbl = mkStatRow("Avg Response Time", "0ms")
local _, ctxSwitchLbl = mkStatRow("Context Switches", 0)
local _, uptLbl = mkStatRow("Uptime", "0s")
local _, histLbl = mkStatRow("Memory Usage", 0)

local stTime = tick()

task.spawn(function()
    while true do
        task.wait(1)
        local up = math.floor(tick() - stTime)
        local h = math.floor(up/3600)
        local m = math.floor((up%3600)/60)
        local s = up%60
        if h > 0 then uptLbl.Text = string.format("%dh %dm", h, m)
        elseif m > 0 then uptLbl.Text = string.format("%dm %ds", m, s)
        else uptLbl.Text = string.format("%ds", s) end
        
        local totalMem = 0
        local playerCount = 0
        for _, data in pairs(playerMemory) do
            playerCount = playerCount + 1
            if data.messages then
                totalMem = totalMem + #data.messages
            end
        end
        histLbl.Text = string.format("%d msgs / %d players", totalMem, playerCount)
        ctxSwitchLbl.Text = tostring(perfStats.contextSwitches)
        
        queueLbl.Text = tostring(#reqQueue)
        cacheLbl.Text = tostring(perfStats.cachedResponses)
        if perfStats.totalRequests > 0 then
            avgTimeLbl.Text = string.format("%.0fms", perfStats.avgResponseTime)
        end
    end
end)

-- window toggle
local isMin = false
local origSz = UDim2.new(0,600,0,480)

togBtnObj.MouseButton1Click:Connect(function()
    if not dragMv then
        win.Visible = not win.Visible
        if win.Visible then
            win.Size = UDim2.new(0,600,0,0)
            tween(win, {Size=origSz}, 0.3, Enum.EasingStyle.Back)
        end
    end
    dragMv = false
end)

minBtn.MouseButton1Click:Connect(function()
    isMin = not isMin
    if isMin then
        tween(win, {Size=UDim2.new(0,600,0,45)}, 0.3)
        minBtn.Text = "+"
    else
        tween(win, {Size=origSz}, 0.3)
        minBtn.Text = "−"
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    tween(win, {Size=UDim2.new(0,600,0,0)}, 0.2)
    task.wait(0.2)
    win.Visible = false
end)

lib:SelectTab("Home")
updDot()

-- ai stuff
local req = (function()
    if request then return request end
    if http_request then return http_request end
    if syn and syn.request then return syn.request end
    if http and http.request then return http.request end
    return nil
end)()

if not req then warn("[maple] no http") end

local sayRem = nil
pcall(function()
    sayRem = rs:FindFirstChild("DefaultChatSystemChatEvents") and rs.DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest")
end)

local function say(msg)
    if not msg or msg == "" then return end
    if #msg > maxMsg then msg = msg:sub(1,maxMsg-3).."..." end
    
    local ok = false
    pcall(function()
        if tcs and tcs.TextChannels then
            local ch = tcs.TextChannels:FindFirstChild("RBXGeneral")
            if ch then ch:SendAsync(msg) ok = true end
        end
    end)
    if not ok and sayRem then
        pcall(function() sayRem:FireServer(msg, "All") ok = true end)
    end
    return ok
end

-- No streaming - send single message to avoid spam
local function sendResponse(msg)
    if not msg or msg == "" then return end
    -- Truncate if too long, no streaming to prevent spam
    if #msg > maxMsg then
        msg = msg:sub(1, maxMsg - 3) .. "..."
    end
    say(msg)
end

local function face(char)
    if not char then return end
    local myC = lp.Character
    if not myC then return end
    local hrp = myC:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local theirR = char:FindFirstChild("HumanoidRootPart")
    if not theirR then return end
    pcall(function()
        local dir = (theirR.Position - hrp.Position).Unit
        local look = CFrame.lookAt(hrp.Position, hrp.Position + dir)
        ts:Create(hrp, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame=look}):Play()
    end)
end

local function getDist(char)
    if not char then return 999999 end
    local myC = lp.Character
    if not myC then return 999999 end
    local hrp = myC:FindFirstChild("HumanoidRootPart")
    if not hrp then return 999999 end
    local theirR = char:FindFirstChild("HumanoidRootPart")
    if not theirR then return 999999 end
    return (theirR.Position - hrp.Position).Magnitude
end

local function isFriend(plr)
    if tick() - friendsCacheTime > 60 then
        friendsCache = {}
        pcall(function()
            local friends = lp:GetFriendsOnline()
            for _, f in ipairs(friends) do
                friendsCache[f.VisitorId] = true
            end
        end)
        friendsCacheTime = tick()
    end
    return friendsCache[plr.UserId] or false
end

local function isSpam(plr, msg)
    if not getgenv().MapleConfig.AntiSpam then return false end
    
    local id = plr.UserId
    if not spamTracker[id] then spamTracker[id] = {} end
    
    local now = tick()
    local clean = {}
    for _, entry in ipairs(spamTracker[id]) do
        if now - entry.t < 30 then table.insert(clean, entry) end
    end
    spamTracker[id] = clean
    
    local count = 0
    for _, entry in ipairs(spamTracker[id]) do
        if entry.m == msg then count = count + 1 end
    end
    
    table.insert(spamTracker[id], {m=msg, t=now})
    
    return count >= getgenv().MapleConfig.SpamThreshold
end

local function shouldRespond(plr, msg)
    local cfg = getgenv().MapleConfig
    local mode = cfg.TriggerMode
    
    if mode == "all" then return true end
    
    if mode == "mention" then
        local lower = msg:lower()
        return lower:find("maple") or lower:find(lp.Name:lower()) or lower:find(lp.DisplayName:lower())
    end
    
    if mode == "prefix" then
        return msg:sub(1, #cfg.TriggerPrefix):lower() == cfg.TriggerPrefix:lower()
    end
    
    return true
end

local function getCacheKey(msg)
    return msg:lower():gsub("%s+", " "):gsub("[^%w%s]", "")
end

local function checkCache(msg)
    local key = getCacheKey(msg)
    local entry = respCache[key]
    if entry and tick() - entry.t < cacheHitWindow then
        perfStats.cachedResponses = perfStats.cachedResponses + 1
        return entry.r
    end
    return nil
end

local function addToCache(msg, resp)
    local key = getCacheKey(msg)
    respCache[key] = {r=resp, t=tick()}
    
    local count = 0
    for _ in pairs(respCache) do count = count + 1 end
    if count > cacheMaxSize then
        local oldest, oldestKey = math.huge, nil
        for k, v in pairs(respCache) do
            if v.t < oldest then oldest, oldestKey = v.t, k end
        end
        if oldestKey then respCache[oldestKey] = nil end
    end
end

local triggers = {}
local inCd = false
local cdTime = 8
local cdCount = 5
local cdWindow = 5

local function activateCd()
    if inCd then return end
    inCd = true
    toast("Rate limit - cooling down", "warning")
    local st = tick()
    while tick() - st < cdTime do task.wait(1) end
    inCd = false
    triggers = {}
    toast("Ready", "success")
end

local function regTrigger()
    local now = tick()
    table.insert(triggers, now)
    local new = {}
    for _, t in ipairs(triggers) do
        if now - t <= cdWindow then table.insert(new, t) end
    end
    triggers = new
    if #triggers >= cdCount and not inCd then task.spawn(activateCd) end
end

-- Initialize player memory structure
local function initPlayerMemory(plrId, displayName)
    if not playerMemory[plrId] then
        playerMemory[plrId] = {
            messages = {},
            lastTopic = nil,
            lastInteraction = 0,
            contextSummary = nil,
            displayName = displayName or "Unknown"
        }
    end
    return playerMemory[plrId]
end

-- Get context-aware memory for a player
local function getPlayerContext(plrId, displayName)
    local cfg = getgenv().MapleConfig
    local mem = initPlayerMemory(plrId, displayName)
    local now = tick()
    
    -- Calculate time since last interaction
    local timeSinceLast = mem.lastInteraction > 0 and (now - mem.lastInteraction) or 0
    local timeSinceMinutes = timeSinceLast / 60
    
    -- Determine context state
    local contextState = "continuing" -- default: same conversation
    if mem.lastInteraction == 0 then
        contextState = "new_player" -- first time talking
    elseif timeSinceMinutes > cfg.LongGapMinutes then
        contextState = "long_gap" -- very likely new topic
        perfStats.contextSwitches = perfStats.contextSwitches + 1
    elseif timeSinceMinutes > cfg.ContextTimeoutMinutes then
        contextState = "possible_new_topic" -- might be new topic
    end
    
    return mem, contextState, timeSinceLast, timeSinceMinutes
end

-- Build context-aware message history for AI
local function buildContextMessages(plrId, displayName, newUserMsg)
    local cfg = getgenv().MapleConfig
    local mem, contextState, timeSinceLast, timeSinceMinutes = getPlayerContext(plrId, displayName)
    local now = tick()
    
    -- Prepare context window
    local contextWindow = {}
    local messages = mem.messages or {}
    local windowSize = cfg.ContextWindowSize
    
    -- Get recent messages for context (within window size)
    local startIdx = math.max(1, #messages - windowSize + 1)
    for i = startIdx, #messages do
        local msg = messages[i]
        if msg then
            local entry = {
                role = msg.role,
                content = msg.content
            }
            -- Add timestamp info if enabled
            if cfg.ShowTimestamps and msg.timestamp then
                local timeAgo = formatTimeAgo(now - msg.timestamp)
                if msg.role == "user" then
                    entry.content = string.format("[%s, %s]: %s", msg.displayName or displayName, timeAgo, msg.content)
                else
                    entry.content = string.format("[You replied %s]: %s", timeAgo, msg.content)
                end
            end
            table.insert(contextWindow, entry)
        end
    end
    
    return contextWindow, contextState, timeSinceMinutes, mem
end

-- Build enhanced system prompt with context awareness
local function buildSystemPrompt(displayName, contextState, timeSinceMinutes, playerMemData)
    local cfg = getgenv().MapleConfig
    local basePersona = cfg.Persona
    
    local contextInstructions = [[

=== CONTEXT AWARENESS INSTRUCTIONS ===
You are having a conversation in a Roblox game chat. You must be context-aware:

1. TIMING ANALYSIS: Pay attention to timestamps in messages. If someone hasn't talked for a while and comes back:
   - Short gap (< 5 min): Probably continuing same topic
   - Medium gap (5-15 min): Might be same topic or new one - use judgment based on message content
   - Long gap (15+ min): Likely starting fresh topic unless they reference previous conversation

2. CONTEXT CONTINUITY:
   - If their new message clearly relates to previous discussion, continue that context
   - If their message seems unrelated or starts fresh, treat it as new conversation
   - If unsure, you can briefly acknowledge the gap ("Oh hey, back again!")

3. REASONING ABOUT CONTEXT:
   - Consider: Does this message make sense as a continuation?
   - Consider: Are they referencing something we discussed before?
   - Consider: Does the tone/topic suggest they're starting fresh?

4. RESPONSE GUIDELINES:
   - Keep responses concise (Roblox chat has limits)
   - Be natural and conversational
   - Don't explicitly mention "context switching" to the user
   - Just naturally adapt to whether it's a continuation or new topic

]]

    local currentContextInfo = ""
    if cfg.SmartContextEnabled then
        if contextState == "new_player" then
            currentContextInfo = string.format("\n[CONTEXT: This is %s's first message to you. Start fresh.]\n", displayName)
        elseif contextState == "long_gap" then
            currentContextInfo = string.format("\n[CONTEXT: %s last spoke %.1f minutes ago. Very likely a new topic unless they reference previous conversation.]\n", displayName, timeSinceMinutes)
        elseif contextState == "possible_new_topic" then
            currentContextInfo = string.format("\n[CONTEXT: %s last spoke %.1f minutes ago. They might be continuing or starting new topic - analyze their message to determine.]\n", displayName, timeSinceMinutes)
        else
            currentContextInfo = string.format("\n[CONTEXT: %s is continuing the conversation (%.1f min since last message).]\n", displayName, timeSinceMinutes)
        end
        
        -- Add previous topic hint if available
        if playerMemData and playerMemData.lastTopic then
            currentContextInfo = currentContextInfo .. string.format("[Previous topic: %s]\n", playerMemData.lastTopic)
        end
    end
    
    return basePersona .. contextInstructions .. currentContextInfo
end

-- Store message in player memory with timestamp
local function storeMessage(plrId, displayName, role, content)
    local mem = initPlayerMemory(plrId, displayName)
    local now = tick()
    
    table.insert(mem.messages, {
        role = role,
        content = content,
        timestamp = now,
        displayName = displayName
    })
    
    -- Update last interaction time
    mem.lastInteraction = now
    mem.displayName = displayName
    
    -- Note: No limit on messages when RememberForever is true
    -- Messages are stored indefinitely per player
end

local function processQueue()
    if processing or #reqQueue == 0 then return end
    processing = true
    
    while #reqQueue > 0 do
        local item = table.remove(reqQueue, 1)
        handleAIInternal(item.msg, item.sender, item.plrId, item.char)
        task.wait(0.1)
    end
    
    processing = false
end

function handleAIInternal(msg, sender, plrId, char)
    local cfg = getgenv().MapleConfig
    if not cfg.MasterEnabled then return end
    if inCd then return end
    if not req then return end

    if cfg.AFKMode then
        if cfg.ResponseDelay > 0 then task.wait(cfg.ResponseDelay) end
        say(cfg.AFKMessage)
        return
    end

    -- Note: Cache disabled for context-aware mode as responses depend on timing
    -- Can re-enable for non-context-aware simple queries if needed
    
    regTrigger()
    sData.msgs = sData.msgs + 1
    msgsLbl.Text = tostring(sData.msgs)

    -- Build context-aware messages
    local contextMessages, contextState, timeSinceMinutes, playerMemData = buildContextMessages(plrId, sender, msg)
    
    -- Store user message in memory
    storeMessage(plrId, sender, "user", msg)
    
    -- Build enhanced system prompt with context awareness
    local systemPrompt = buildSystemPrompt(sender, contextState, timeSinceMinutes, playerMemData)
    
    -- Prepare the message array for API
    local apiMessages = {{role = "system", content = systemPrompt}}
    
    -- Add context window messages
    for _, ctxMsg in ipairs(contextMessages) do
        table.insert(apiMessages, ctxMsg)
    end
    
    -- Add the new user message
    table.insert(apiMessages, {role = "user", content = string.format("[%s, just now]: %s", sender, msg)})

    local payload = {
        model = cfg.Model,
        max_tokens = cfg.MaxTokens,
        temperature = cfg.Temperature,
        messages = apiMessages
    }

    log("Context state:", contextState, "| Time since last:", string.format("%.1f min", timeSinceMinutes))
    log("Sending", #apiMessages, "messages to API")

    local startT = tick()
    local res = nil
    local lastErr = nil
    
    for att = 1, retries do
        local s, r = pcall(function()
            return req({
                Url = "https://api.mapleai.de/v1/chat/completions",
                Method = "POST",
                Headers = {["Content-Type"]="application/json", ["Authorization"]="Bearer "..cfg.APIKey},
                Body = http:JSONEncode(payload)
            })
        end)
        if s and r and r.Body then res = r break
        else lastErr = r log("attempt", att, "failed") if att < retries then task.wait(1) end end
    end

    local elapsed = (tick() - startT) * 1000
    perfStats.totalRequests = perfStats.totalRequests + 1
    perfStats.avgResponseTime = (perfStats.avgResponseTime * (perfStats.totalRequests-1) + elapsed) / perfStats.totalRequests

    if not res or not res.Body then
        sData.errs = sData.errs + 1
        errsLbl.Text = tostring(sData.errs)
        log("failed:", tostring(lastErr))
        return
    end

    local ok, dec = pcall(function() return http:JSONDecode(res.Body) end)
    if not ok then sData.errs = sData.errs + 1 errsLbl.Text = tostring(sData.errs) return end
    if dec.error then
        sData.errs = sData.errs + 1
        errsLbl.Text = tostring(sData.errs)
        log("API error:", dec.error.message or "unknown")
        return
    end
    if not dec.choices or not dec.choices[1] then return end

    local reply = dec.choices[1].message and dec.choices[1].message.content
    if not reply or reply == "" then return end

    -- Store assistant reply in memory
    storeMessage(plrId, sender, "assistant", reply)
    
    -- Try to extract topic hint from response for future context
    -- (Simple heuristic - could be made smarter)
    if #reply > 20 then
        local mem = playerMemory[plrId]
        if mem then
            -- Store first part of reply as topic hint
            mem.lastTopic = reply:sub(1, 50):gsub("\n", " ")
        end
    end
    
    sData.resp = sData.resp + 1
    respLbl.Text = tostring(sData.resp)

    if cfg.ResponseDelay > 0 then task.wait(cfg.ResponseDelay) end
    
    -- Send single response (no streaming to prevent spam)
    sendResponse(reply)
end

local function handleAI(msg, sender, plrId, char, priority)
    local cfg = getgenv().MapleConfig
    
    if priority or cfg.PrioritizeFriends then
        table.insert(reqQueue, 1, {msg=msg, sender=sender, plrId=plrId, char=char})
    else
        table.insert(reqQueue, {msg=msg, sender=sender, plrId=plrId, char=char})
    end
    
    perfStats.queuedMsgs = #reqQueue
    task.spawn(processQueue)
end

local function onChat(plr, msg)
    if plr == lp then return end
    local cfg = getgenv().MapleConfig
    if not cfg.MasterEnabled then return end
    
    if table.find(cfg.Blacklist, plr.Name) or table.find(cfg.Blacklist, plr.DisplayName) then return end
    
    if cfg.Range > 0 then
        local dist = getDist(plr.Character)
        if dist > cfg.Range then
            log("Out of range:", dist)
            return
        end
    end
    
    if not shouldRespond(plr, msg) then
        log("Trigger not matched")
        return
    end
    
    if isSpam(plr, msg) then
        log("Spam detected from", plr.Name)
        return
    end
    
    local friend = isFriend(plr)
    if cfg.AutoWhitelistFriends and friend then
        log("Friend auto-whitelisted")
    end
    
    if plr.Character then pcall(function() face(plr.Character) end) end
    
    local msgClean = msg
    if cfg.TriggerMode == "prefix" then
        msgClean = msg:sub(#cfg.TriggerPrefix + 1):gsub("^%s+", "")
    end
    
    handleAI(msgClean, plr.DisplayName or plr.Name, plr.UserId, plr.Character, friend and cfg.PrioritizeFriends)
end

local function connectPlr(plr)
    if plr == lp then return end
    local c = plr.Chatted:Connect(function(msg) onChat(plr, msg) end)
    addConn(c, "chat_"..plr.UserId)
end

for _, plr in ipairs(plrs:GetPlayers()) do connectPlr(plr) end
addConn(plrs.PlayerAdded:Connect(function(plr) connectPlr(plr) end), "plrAdd")
addConn(plrs.PlayerRemoving:Connect(function(plr) rmConn("chat_"..plr.UserId) spamTracker[plr.UserId] = nil end), "plrRm")

gui.Destroying:Connect(function() cleanup() end)

addConn(uis.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightControl or i.KeyCode == Enum.KeyCode.F9 then
        win.Visible = not win.Visible
        if win.Visible then
            win.Size = UDim2.new(0,600,0,0)
            tween(win, {Size=origSz}, 0.3, Enum.EasingStyle.Back)
        end
    end
end), "keybind")

log("loaded v4 - context-aware")
toast("Maple AI v4 loaded! Context-aware mode enabled.", "success", 3)