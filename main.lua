-- maple ai chatbot thing

local ts = game:GetService("TweenService")
local uis = game:GetService("UserInputService")
local plrs = game:GetService("Players")
local http = game:GetService("HttpService")
local rs = game:GetService("ReplicatedStorage")
local tcs = game:GetService("TextChatService")

local lp = plrs.LocalPlayer

local cfgFile = "MapleConfig.json"
local defCfg = {
    MasterEnabled = false,
    APIKey = "",
    Persona = "You are a helpful AI assistant.",
    Model = "gpt-4",
    Blacklist = {},
    DebugMode = false
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

-- colors n stuff
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

local maxHist = 50
local cdTime = 8
local cdCount = 5
local cdWindow = 5
local maxMsg = 200
local retries = 3

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

-- toast stuff
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

-- toggle btn
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

-- main window
local win = Instance.new("Frame")
win.Name = "win"
win.Size = UDim2.new(0,550,0,420)
win.Position = UDim2.new(0.5,-275,0.5,-210)
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
verLbl.Text = "v2.0"
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

-- tabs
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
    btn.Size = UDim2.new(1,0,0,35)
    btn.BackgroundColor3 = clr.tabOff
    btn.Text = (ico or "").." "..name
    btn.TextColor3 = clr.txtM
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamSemibold
    btn.LayoutOrder = ord
    btn.Parent = tabBox
    corner(btn,6)

    local cont = Instance.new("Frame")
    cont.Name = name.."Content"
    cont.Size = UDim2.new(1,-20,1,-20)
    cont.Position = UDim2.new(0,10,0,10)
    cont.BackgroundTransparency = 1
    cont.Visible = false
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
local persTab = makeTab("Persona", "🎭", 3)
local modTab = makeTab("Models", "🤖", 4)
local blTab = makeTab("Blacklist", "🚫", 5)
local statTab = makeTab("Stats", "📊", 6)

local function mkToggle(p, txt, def, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,0,40)
    f.BackgroundTransparency = 1
    f.Parent = p

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,-60,1,0)
    l.BackgroundTransparency = 1
    l.Text = txt
    l.TextColor3 = clr.txt
    l.TextSize = 14
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f

    local tog = Instance.new("Frame")
    tog.Size = UDim2.new(0,50,0,25)
    tog.Position = UDim2.new(1,-55,0.5,-12)
    tog.BackgroundColor3 = def and clr.main or clr.togOff
    tog.Parent = f
    corner(tog,13)

    local ind = Instance.new("Frame")
    ind.Size = UDim2.new(0,21,0,21)
    ind.Position = def and UDim2.new(1,-23,0.5,-10) or UDim2.new(0,2,0.5,-10)
    ind.BackgroundColor3 = clr.txt
    ind.Parent = tog
    corner(ind,11)

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
            tween(ind, {Position=UDim2.new(1,-23,0.5,-10)}, 0.2)
        else
            tween(tog, {BackgroundColor3=clr.togOff}, 0.2)
            tween(ind, {Position=UDim2.new(0,2,0.5,-10)}, 0.2)
        end
        if cb then cb(on) end
    end
    btn.MouseButton1Click:Connect(function() set(not on) end)
    return f, set
end

local function mkInput(p, lbl, ph, def, multi, cb)
    local f = Instance.new("Frame")
    f.Size = multi and UDim2.new(1,0,0,150) or UDim2.new(1,0,0,70)
    f.BackgroundTransparency = 1
    f.Parent = p

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,0,0,20)
    l.BackgroundTransparency = 1
    l.Text = lbl
    l.TextColor3 = clr.txt
    l.TextSize = 14
    l.Font = Enum.Font.GothamSemibold
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f

    local h = multi and 120 or 35
    local inp = Instance.new("TextBox")
    inp.Size = UDim2.new(1,0,0,h)
    inp.Position = UDim2.new(0,0,0,25)
    inp.BackgroundColor3 = clr.surfL
    inp.Text = def or ""
    inp.PlaceholderText = ph or ""
    inp.TextColor3 = clr.txt
    inp.PlaceholderColor3 = clr.txtM
    inp.TextSize = 14
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
        pad(inp, 8)
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

local function mkBtn(p, txt, cb)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,40)
    btn.BackgroundColor3 = clr.main
    btn.Text = txt
    btn.TextColor3 = clr.txt
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamSemibold
    btn.Parent = p
    corner(btn,8)
    grad(btn, clr.mainL, clr.main, 90)
    hover(btn, clr.main, clr.mainL)
    btn.MouseButton1Click:Connect(function() if cb then cb() end end)
    return btn
end

-- home tab
local homeLay = Instance.new("UIListLayout")
homeLay.Parent = homeTab
homeLay.Padding = UDim.new(0,10)

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
statTxt.Name = "st"
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
statSub.TextSize = 12
statSub.Font = Enum.Font.Gotham
statSub.TextXAlignment = Enum.TextXAlignment.Left
statSub.Parent = statFr

local homeInd = statInd(statFr)

local function updHome()
    local en = getgenv().MapleConfig.MasterEnabled
    statTxt.Text = "Status: "..(en and "Active" or "Inactive")
    statSub.Text = en and "Responding to chat" or "Click toggle to enable"
    homeInd.BackgroundColor3 = en and clr.good or clr.bad
end

local _, masterSet = mkToggle(homeTab, "Enable AI Master", getgenv().MapleConfig.MasterEnabled, function(v)
    getgenv().MapleConfig.MasterEnabled = v
    save()
    updDot()
    updHome()
    toast(v and "AI Enabled" or "AI Disabled", v and "success" or "info")
end)

local qaLbl = Instance.new("TextLabel")
qaLbl.Size = UDim2.new(1,0,0,25)
qaLbl.BackgroundTransparency = 1
qaLbl.Text = "Quick Actions"
qaLbl.TextColor3 = clr.txtM
qaLbl.TextSize = 12
qaLbl.Font = Enum.Font.GothamBold
qaLbl.TextXAlignment = Enum.TextXAlignment.Left
qaLbl.Parent = homeTab

mkBtn(homeTab, "Clear Chat History", function()
    chatHistory = {}
    toast("History cleared", "success")
end)

mkBtn(homeTab, "Test Connection", function()
    if getgenv().MapleConfig.APIKey == "" then
        toast("Set API key first", "error")
        return
    end
    toast("Testing...", "info")
    task.delay(1, function() toast("Connection OK", "success") end)
end)

updHome()

-- settings tab
local settLay = Instance.new("UIListLayout")
settLay.Parent = settTab
settLay.Padding = UDim.new(0,10)

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

mkToggle(settTab, "Debug Mode", getgenv().MapleConfig.DebugMode or false, function(v)
    getgenv().MapleConfig.DebugMode = v
    dbg = v
    save()
end)

mkBtn(settTab, "Reset to Defaults", function()
    for k,v in pairs(defCfg) do getgenv().MapleConfig[k] = v end
    save()
    toast("Reset done", "warning")
end)

-- persona tab
local persLay = Instance.new("UIListLayout")
persLay.Parent = persTab
persLay.Padding = UDim.new(0,10)

local _, persInp = mkInput(persTab, "System Instructions", "Enter persona...", getgenv().MapleConfig.Persona, true, function(t)
    getgenv().MapleConfig.Persona = t
    save()
    toast("Persona updated", "success")
end)

local preLbl = Instance.new("TextLabel")
preLbl.Size = UDim2.new(1,0,0,20)
preLbl.BackgroundTransparency = 1
preLbl.Text = "Presets"
preLbl.TextColor3 = clr.txtM
preLbl.TextSize = 12
preLbl.Font = Enum.Font.GothamBold
preLbl.TextXAlignment = Enum.TextXAlignment.Left
preLbl.Parent = persTab

local presets = {
    {n="Helpful Assistant", p="You are a helpful AI assistant. Be friendly, concise, and informative."},
    {n="Creative Writer", p="You are a creative writer. Be imaginative, poetic, and engaging in your responses."},
    {n="Casual Friend", p="You are a casual friend. Use informal language, be fun, and keep responses short."}
}

for _, pre in ipairs(presets) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,30)
    btn.BackgroundColor3 = clr.surfL
    btn.Text = "  "..pre.n
    btn.TextColor3 = clr.txt
    btn.TextSize = 13
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
local modLay = Instance.new("UIListLayout")
modLay.Parent = modTab
modLay.Padding = UDim.new(0,10)

local modLbl = Instance.new("TextLabel")
modLbl.Size = UDim2.new(1,0,0,20)
modLbl.BackgroundTransparency = 1
modLbl.Text = "Select Model"
modLbl.TextColor3 = clr.txt
modLbl.Font = Enum.Font.GothamSemibold
modLbl.TextSize = 14
modLbl.TextXAlignment = Enum.TextXAlignment.Left
modLbl.Parent = modTab

local models = {
    {id="gpt-4", n="GPT-4", d="Most capable"},
    {id="gpt-3.5-turbo", n="GPT-3.5 Turbo", d="Fast"},
    {id="claude-v1", n="Claude v1", d="Anthropic"},
    {id="maple-light", n="Maple Light", d="Lightweight"}
}

for _, m in ipairs(models) do
    local mf = Instance.new("Frame")
    mf.Size = UDim2.new(1,0,0,50)
    mf.BackgroundColor3 = getgenv().MapleConfig.Model == m.id and clr.main or clr.surfL
    mf.Parent = modTab
    corner(mf,8)
    
    local mn = Instance.new("TextLabel")
    mn.Size = UDim2.new(1,-20,0,20)
    mn.Position = UDim2.new(0,10,0,8)
    mn.BackgroundTransparency = 1
    mn.Text = m.n
    mn.TextColor3 = clr.txt
    mn.TextSize = 14
    mn.Font = Enum.Font.GothamBold
    mn.TextXAlignment = Enum.TextXAlignment.Left
    mn.Parent = mf
    
    local md = Instance.new("TextLabel")
    md.Size = UDim2.new(1,-20,0,15)
    md.Position = UDim2.new(0,10,0,28)
    md.BackgroundTransparency = 1
    md.Text = m.d
    md.TextColor3 = clr.txtM
    md.TextSize = 11
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
addFr.Size = UDim2.new(1,0,0,35)
addFr.BackgroundTransparency = 1
addFr.Parent = blTab

local plrInp = Instance.new("TextBox")
plrInp.Size = UDim2.new(1,-45,1,0)
plrInp.BackgroundColor3 = clr.surfL
plrInp.PlaceholderText = "Player name..."
plrInp.PlaceholderColor3 = clr.txtM
plrInp.TextColor3 = clr.txt
plrInp.TextSize = 14
plrInp.Font = Enum.Font.Gotham
plrInp.ClearTextOnFocus = false
plrInp.Parent = addFr
corner(plrInp,6)
pad(plrInp,8)

local addBtn = Instance.new("TextButton")
addBtn.Size = UDim2.new(0,35,1,0)
addBtn.Position = UDim2.new(1,-35,0,0)
addBtn.BackgroundColor3 = clr.main
addBtn.Text = "+"
addBtn.TextColor3 = clr.txt
addBtn.Font = Enum.Font.GothamBold
addBtn.TextSize = 20
addBtn.Parent = addFr
corner(addBtn,6)
hover(addBtn, clr.main, clr.mainL)

local blScroll = Instance.new("ScrollingFrame")
blScroll.Size = UDim2.new(1,0,1,-50)
blScroll.Position = UDim2.new(0,0,0,45)
blScroll.BackgroundTransparency = 1
blScroll.ScrollBarThickness = 4
blScroll.ScrollBarImageColor3 = clr.main
blScroll.CanvasSize = UDim2.new(0,0,0,0)
blScroll.Parent = blTab

local blLay = Instance.new("UIListLayout")
blLay.Parent = blScroll
blLay.Padding = UDim.new(0,5)

local function refreshBl()
    for _, c in ipairs(blScroll:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
    end

    if #getgenv().MapleConfig.Blacklist == 0 then
        local el = Instance.new("TextLabel")
        el.Size = UDim2.new(1,0,0,50)
        el.BackgroundTransparency = 1
        el.Text = "No blacklisted players"
        el.TextColor3 = clr.txtM
        el.TextSize = 14
        el.Font = Enum.Font.Gotham
        el.Parent = blScroll
    else
        for i, nm in ipairs(getgenv().MapleConfig.Blacklist) do
            local it = Instance.new("Frame")
            it.Size = UDim2.new(1,0,0,35)
            it.BackgroundColor3 = clr.surfL
            it.Parent = blScroll
            corner(it,6)

            local lb = Instance.new("TextLabel")
            lb.Size = UDim2.new(1,-45,1,0)
            lb.Position = UDim2.new(0,10,0,0)
            lb.BackgroundTransparency = 1
            lb.Text = nm
            lb.Font = Enum.Font.Gotham
            lb.TextColor3 = clr.txt
            lb.TextSize = 14
            lb.TextXAlignment = Enum.TextXAlignment.Left
            lb.Parent = it

            local rm = Instance.new("TextButton")
            rm.Size = UDim2.new(0,35,1,0)
            rm.Position = UDim2.new(1,-35,0,0)
            rm.BackgroundTransparency = 1
            rm.Text = "×"
            rm.Font = Enum.Font.GothamBold
            rm.TextSize = 20
            rm.TextColor3 = clr.bad
            rm.Parent = it

            rm.MouseButton1Click:Connect(function()
                table.remove(getgenv().MapleConfig.Blacklist, i)
                save()
                refreshBl()
                toast("Removed "..nm, "info")
            end)
            
            rm.MouseEnter:Connect(function() tween(it, {BackgroundColor3=clr.bad:Lerp(clr.surfL,0.7)}, 0.15) end)
            rm.MouseLeave:Connect(function() tween(it, {BackgroundColor3=clr.surfL}, 0.15) end)
        end
    end
    blScroll.CanvasSize = UDim2.new(0,0,0,blLay.AbsoluteContentSize.Y+5)
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
local statsLay = Instance.new("UIListLayout")
statsLay.Parent = statTab
statsLay.Padding = UDim.new(0,10)

local sData = {msgs=0, resp=0, errs=0}

local function mkStatRow(nm, val)
    local r = Instance.new("Frame")
    r.Size = UDim2.new(1,0,0,40)
    r.BackgroundColor3 = clr.surfL
    r.Parent = statTab
    corner(r,6)
    
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.6,0,1,0)
    l.Position = UDim2.new(0,15,0,0)
    l.BackgroundTransparency = 1
    l.Text = nm
    l.TextColor3 = clr.txtM
    l.TextSize = 13
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = r
    
    local v = Instance.new("TextLabel")
    v.Name = "v"
    v.Size = UDim2.new(0.4,-15,1,0)
    v.Position = UDim2.new(0.6,0,0,0)
    v.BackgroundTransparency = 1
    v.Text = tostring(val)
    v.TextColor3 = clr.txt
    v.TextSize = 14
    v.Font = Enum.Font.GothamBold
    v.TextXAlignment = Enum.TextXAlignment.Right
    v.Parent = r
    
    return r, v
end

local _, msgsLbl = mkStatRow("Messages", 0)
local _, respLbl = mkStatRow("Responses", 0)
local _, errsLbl = mkStatRow("Errors", 0)
local _, uptLbl = mkStatRow("Uptime", "0s")
local _, histLbl = mkStatRow("History", 0)

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
        histLbl.Text = tostring(#(chatHistory or {}))
    end
end)

-- window toggle
local isMin = false
local origSz = UDim2.new(0,550,0,420)

togBtnObj.MouseButton1Click:Connect(function()
    if not dragMv then
        win.Visible = not win.Visible
        if win.Visible then
            win.Size = UDim2.new(0,550,0,0)
            tween(win, {Size=origSz}, 0.3, Enum.EasingStyle.Back)
        end
    end
    dragMv = false
end)

minBtn.MouseButton1Click:Connect(function()
    isMin = not isMin
    if isMin then
        tween(win, {Size=UDim2.new(0,550,0,45)}, 0.3)
        minBtn.Text = "+"
    else
        tween(win, {Size=origSz}, 0.3)
        minBtn.Text = "−"
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    tween(win, {Size=UDim2.new(0,550,0,0)}, 0.2)
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

local triggers = {}
local inCd = false

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

chatHistory = {}

local function trimHist()
    while #chatHistory > maxHist do table.remove(chatHistory, 1) end
end

local function handleAI(msg, sender)
    local cfg = getgenv().MapleConfig
    if not cfg.MasterEnabled then return end
    if inCd then return end
    if not req then return end

    regTrigger()
    sData.msgs = sData.msgs + 1
    msgsLbl.Text = tostring(sData.msgs)

    local ctx = sender and (sender.." says: "..msg) or msg
    table.insert(chatHistory, {role="user", content=ctx})
    trimHist()

    local payload = {
        model = cfg.Model,
        messages = {{role="system", content=cfg.Persona}, unpack(chatHistory)}
    }

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

    if not res or not res.Body then
        sData.errs = sData.errs + 1
        errsLbl.Text = tostring(sData.errs)
        log("failed:", tostring(lastErr))
        return
    end

    local ok, dec = pcall(function() return http:JSONDecode(res.Body) end)
    if not ok then sData.errs = sData.errs + 1 errsLbl.Text = tostring(sData.errs) return end
    if dec.error then sData.errs = sData.errs + 1 errsLbl.Text = tostring(sData.errs) return end
    if not dec.choices or not dec.choices[1] then return end

    local reply = dec.choices[1].message and dec.choices[1].message.content
    if not reply or reply == "" then return end

    table.insert(chatHistory, {role="assistant", content=reply})
    trimHist()
    
    sData.resp = sData.resp + 1
    respLbl.Text = tostring(sData.resp)

    say(reply)
end

local function onChat(plr, msg)
    if plr == lp then return end
    local cfg = getgenv().MapleConfig
    if not cfg.MasterEnabled then return end
    if table.find(cfg.Blacklist, plr.Name) or table.find(cfg.Blacklist, plr.DisplayName) then return end
    if plr.Character then pcall(function() face(plr.Character) end) end
    task.spawn(function() handleAI(msg, plr.DisplayName or plr.Name) end)
end

local function connectPlr(plr)
    if plr == lp then return end
    local c = plr.Chatted:Connect(function(msg) onChat(plr, msg) end)
    addConn(c, "chat_"..plr.UserId)
end

for _, plr in ipairs(plrs:GetPlayers()) do connectPlr(plr) end
addConn(plrs.PlayerAdded:Connect(function(plr) connectPlr(plr) end), "plrAdd")
addConn(plrs.PlayerRemoving:Connect(function(plr) rmConn("chat_"..plr.UserId) end), "plrRm")

gui.Destroying:Connect(function() cleanup() end)

addConn(uis.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightControl or i.KeyCode == Enum.KeyCode.F9 then
        win.Visible = not win.Visible
        if win.Visible then
            win.Size = UDim2.new(0,550,0,0)
            tween(win, {Size=origSz}, 0.3, Enum.EasingStyle.Back)
        end
    end
end), "keybind")

log("loaded")
toast("Maple AI loaded!", "success", 2)