--========================================================--
--  Maple AI - Full main.lua (UI + AI Logic Combined)
--========================================================--

--// SERVICES
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local LocalPlayer = Players.LocalPlayer

--========================================================--
-- CONFIG SYSTEM
--========================================================--

local CONFIG_FILE = "MapleConfig.json"
local DefaultConfig = {
    MasterEnabled = false,
    APIKey = "",
    Persona = "You are a helpful AI assistant.",
    Model = "gpt-4",
    Blacklist = {}
}

getgenv().MapleConfig = DefaultConfig

local function SaveConfig()
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(getgenv().MapleConfig))
    end)
end

local function LoadConfig()
    local ok, data = pcall(function()
        if isfile and isfile(CONFIG_FILE) then
            return readfile(CONFIG_FILE)
        end
        return nil
    end)

    if ok and data then
        local decoded = HttpService:JSONDecode(data)
        for k, v in pairs(decoded) do
            getgenv().MapleConfig[k] = v
        end
    end
end

LoadConfig()

--========================================================--
-- UI LIBRARY
--========================================================--

local Library = {}
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MapleUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end
ScreenGui.Parent = game:GetService("CoreGui")

local function CreateGradient(parent, c1, c2, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, c1),
        ColorSequenceKeypoint.new(1, c2)
    })
    g.Rotation = rot or 45
    g.Parent = parent
end

local function CreateCorner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = parent
end

local function CreateShadow(parent)
    local shadow = Instance.new("ImageLabel")
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.new(0, -15, 0, -15)
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.ZIndex = parent.ZIndex - 1
    shadow.Image = "rbxassetid://5554236805"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(23,23,277,277)
    shadow.Parent = parent
end

local function Tween(obj, props, t, style, dir)
    local tw = TweenService:Create(obj,
        TweenInfo.new(t or 0.3, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props
    )
    tw:Play()
    return tw
end

--========================================================--
-- WINDOW TOGGLE BUTTON
--========================================================--

local ToggleButton = Instance.new("Frame")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 50, 0, 50)
ToggleButton.Position = UDim2.new(0, 20, 1, -70)
ToggleButton.BackgroundColor3 = Color3.fromRGB(88,45,138)
ToggleButton.Parent = ScreenGui
CreateCorner(ToggleButton, 25)
CreateShadow(ToggleButton)
CreateGradient(ToggleButton, Color3.fromRGB(138,75,188), Color3.fromRGB(68,35,108), 45)

local ToggleIcon = Instance.new("TextLabel")
ToggleIcon.Size = UDim2.new(1,0,1,0)
ToggleIcon.BackgroundTransparency = 1
ToggleIcon.Text = "M"
ToggleIcon.Font = Enum.Font.GothamBold
ToggleIcon.TextSize = 24
ToggleIcon.TextColor3 = Color3.new(1,1,1)
ToggleIcon.Parent = ToggleButton

local ToggleButtonObj = Instance.new("TextButton")
ToggleButtonObj.Size = UDim2.new(1,0,1,0)
ToggleButtonObj.BackgroundTransparency = 1
ToggleButtonObj.Text = ""
ToggleButtonObj.Parent = ToggleButton

local dragging = false
local dragStart, startPos

ToggleButtonObj.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = ToggleButton.Position
    end
end)

ToggleButtonObj.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        ToggleButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
    end
end)

--========================================================--
-- MAIN WINDOW
--========================================================--

local MainWindow = Instance.new("Frame")
MainWindow.Name = "MainWindow"
MainWindow.Size = UDim2.new(0, 550, 0, 420)
MainWindow.Position = UDim2.new(0.5, -275, 0.5, -210)
MainWindow.BackgroundColor3 = Color3.fromRGB(25,25,35)
MainWindow.Visible = false
MainWindow.Parent = ScreenGui
CreateCorner(MainWindow, 12)
CreateShadow(MainWindow)
CreateGradient(MainWindow, Color3.fromRGB(35,30,50), Color3.fromRGB(20,18,28), 90)

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1,0,0,45)
TitleBar.BackgroundColor3 = Color3.fromRGB(45,40,65)
TitleBar.Parent = MainWindow
CreateCorner(TitleBar,12)
CreateGradient(TitleBar,Color3.fromRGB(88,45,138),Color3.fromRGB(55,35,85),90)

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1,-100,1,0)
TitleText.Position = UDim2.new(0,15,0,0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "Maple AI Assistant"
TitleText.TextColor3 = Color3.new(1,1,1)
TitleText.TextSize = 18
TitleText.Font = Enum.Font.GothamBold
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0,30,0,30)
CloseButton.Position = UDim2.new(1,-40,0.5,-15)
CloseButton.BackgroundColor3 = Color3.fromRGB(180,60,60)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Text = "×"
CloseButton.TextColor3 = Color3.new(1,1,1)
CloseButton.TextSize = 20
CloseButton.Parent = TitleBar
CreateCorner(CloseButton,6)

local windowDragging = false
local wDragStart, wStartPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        windowDragging = true
        wDragStart = input.Position
        wStartPos = MainWindow.Position
    end
end)

TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        windowDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if windowDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - wDragStart
        MainWindow.Position = UDim2.new(wStartPos.X.Scale, wStartPos.X.Offset+delta.X, wStartPos.Y.Scale, wStartPos.Y.Offset+delta.Y)
    end
end)

--========================================================--
-- TAB SYSTEM
--========================================================--

local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(0,120,1,-55)
TabContainer.Position = UDim2.new(0,10,0,50)
TabContainer.BackgroundColor3 = Color3.fromRGB(35,32,48)
TabContainer.Parent = MainWindow
CreateCorner(TabContainer,8)

local TabList = Instance.new("UIListLayout")
TabList.Parent = TabContainer
TabList.SortOrder = Enum.SortOrder.LayoutOrder
TabList.Padding = UDim.new(0,5)

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1,-145,1,-55)
ContentContainer.Position = UDim2.new(0,135,0,50)
ContentContainer.BackgroundColor3 = Color3.fromRGB(35,32,48)
ContentContainer.Parent = MainWindow
CreateCorner(ContentContainer,8)

local Tabs = {}
local TabButtons = {}
local CurrentTab = nil

local function CreateTab(name, order)
    local btn = Instance.new("TextButton")
    btn.Name = name .. "Tab"
    btn.Size = UDim2.new(1,-10,0,35)
    btn.BackgroundColor3 = Color3.fromRGB(50,45,70)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(180,180,180)
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamSemibold
    btn.LayoutOrder = order
    btn.Parent = TabContainer
    CreateCorner(btn,6)

    local content = Instance.new("Frame")
    content.Name = name .. "Content"
    content.Size = UDim2.new(1,-20,1,-20)
    content.Position = UDim2.new(0,10,0,10)
    content.BackgroundTransparency = 1
    content.Visible = false
    content.Parent = ContentContainer

    Tabs[name] = content
    TabButtons[name] = btn

    btn.MouseButton1Click:Connect(function()
        Library:SelectTab(name)
    end)

    return content
end

function Library:SelectTab(name)
    if CurrentTab then
        Tabs[CurrentTab].Visible = false
        Tween(TabButtons[CurrentTab], {BackgroundColor3 = Color3.fromRGB(50,45,70)}, 0.2)
        TabButtons[CurrentTab].TextColor3 = Color3.fromRGB(180,180,180)
    end

    CurrentTab = name
    Tabs[name].Visible = true
    Tween(TabButtons[name], {BackgroundColor3 = Color3.fromRGB(88,45,138)}, 0.2)
    TabButtons[name].TextColor3 = Color3.new(1,1,1)
end

--========================================================--
-- Create Tabs
--========================================================--

local HomeTab = CreateTab("Home",1)
local SettingsTab = CreateTab("Settings",2)
local PersonaTab = CreateTab("Persona",3)
local ModelsTab = CreateTab("Models",4)
local BlacklistTab = CreateTab("Blacklist",5)

--========================================================--
-- TOGGLES + SETTINGS UI
--========================================================--

local function CreateToggle(parent, text, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,0,40)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,-60,1,0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.new(1,1,1)
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local toggle = Instance.new("Frame")
    toggle.Size = UDim2.new(0,50,0,25)
    toggle.Position = UDim2.new(1,-55,0.5,-12)
    toggle.BackgroundColor3 = default and Color3.fromRGB(88,45,138) or Color3.fromRGB(60,60,70)
    toggle.Parent = frame
    CreateCorner(toggle,13)

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0,21,0,21)
    indicator.Position = default and UDim2.new(1,-23,0.5,-10) or UDim2.new(0,2,0.5,-10)
    indicator.BackgroundColor3 = Color3.new(1,1,1)
    indicator.Parent = toggle
    CreateCorner(indicator,11)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = toggle

    local toggled = default
    btn.MouseButton1Click:Connect(function()
        toggled = not toggled

        if toggled then
            Tween(toggle, {BackgroundColor3=Color3.fromRGB(88,45,138)},0.2)
            Tween(indicator, {Position=UDim2.new(1,-23,0.5,-10)},0.2)
        else
            Tween(toggle, {BackgroundColor3=Color3.fromRGB(60,60,70)},0.2)
            Tween(indicator, {Position=UDim2.new(0,2,0.5,-10)},0.2)
        end

        if callback then callback(toggled) end
    end)

    return frame
end

CreateToggle(HomeTab,"Enable AI Master",getgenv().MapleConfig.MasterEnabled,function(val)
    getgenv().MapleConfig.MasterEnabled = val
    SaveConfig()
end)

-- API Key
local apiKeyFrame = Instance.new("Frame")
apiKeyFrame.Size = UDim2.new(1,0,0,70)
apiKeyFrame.BackgroundTransparency = 1
apiKeyFrame.Parent = SettingsTab

local apiKeyLabel = Instance.new("TextLabel")
apiKeyLabel.Size = UDim2.new(1,0,0,20)
apiKeyLabel.BackgroundTransparency = 1
apiKeyLabel.Text = "API Key"
apiKeyLabel.TextColor3 = Color3.new(1,1,1)
apiKeyLabel.TextSize = 14
apiKeyLabel.Font = Enum.Font.GothamSemibold
apiKeyLabel.TextXAlignment = Enum.TextXAlignment.Left
apiKeyLabel.Parent = apiKeyFrame

local apiKeyInput = Instance.new("TextBox")
apiKeyInput.Size = UDim2.new(1,0,0,35)
apiKeyInput.Position = UDim2.new(0,0,0,25)
apiKeyInput.BackgroundColor3 = Color3.fromRGB(45,42,58)
apiKeyInput.Text = string.rep("*",#getgenv().MapleConfig.APIKey)
apiKeyInput.PlaceholderText = "Enter API Key..."
apiKeyInput.TextColor3 = Color3.new(1,1,1)
apiKeyInput.TextSize = 14
apiKeyInput.Font = Enum.Font.Gotham
apiKeyInput.Parent = apiKeyFrame
CreateCorner(apiKeyInput,6)

apiKeyInput.FocusLost:Connect(function()
    local text = apiKeyInput.Text
    if not text:match("^%*+$") then
        getgenv().MapleConfig.APIKey = text
        SaveConfig()
        apiKeyInput.Text = string.rep("*",#text)
    end
end)

-- Persona
local personaFrame = Instance.new("Frame")
personaFrame.Size = UDim2.new(1,0,1,-10)
personaFrame.BackgroundTransparency = 1
personaFrame.Parent = PersonaTab

local personaLabel = Instance.new("TextLabel")
personaLabel.Size = UDim2.new(1,0,0,20)
personaLabel.BackgroundTransparency = 1
personaLabel.Text = "System Instructions"
personaLabel.TextColor3 = Color3.new(1,1,1)
personaLabel.TextSize = 14
personaLabel.Font = Enum.Font.GothamSemibold
personaLabel.TextXAlignment = Enum.TextXAlignment.Left
personaLabel.Parent = personaFrame

local personaInput = Instance.new("TextBox")
personaInput.Size = UDim2.new(1,0,1,-30)
personaInput.Position = UDim2.new(0,0,0,25)
personaInput.BackgroundColor3 = Color3.fromRGB(45,42,58)
personaInput.Text = getgenv().MapleConfig.Persona
personaInput.TextColor3 = Color3.new(1,1,1)
personaInput.Font = Enum.Font.Gotham
personaInput.TextYAlignment = Enum.TextYAlignment.Top
personaInput.MultiLine = true
personaInput.Parent = personaFrame
CreateCorner(personaInput,6)

personaInput.FocusLost:Connect(function()
    getgenv().MapleConfig.Persona = personaInput.Text
    SaveConfig()
end)

-- Models
local modelFrame = Instance.new("Frame")
modelFrame.Size = UDim2.new(1,0,0,70)
modelFrame.BackgroundTransparency = 1
modelFrame.Parent = ModelsTab

local modelLabel = Instance.new("TextLabel")
modelLabel.Size = UDim2.new(1,0,0,20)
modelLabel.BackgroundTransparency = 1
modelLabel.Text = "Model Selection"
modelLabel.TextColor3 = Color3.new(1,1,1)
modelLabel.Font = Enum.Font.GothamSemibold
modelLabel.TextSize = 14
modelLabel.TextXAlignment = Enum.TextXAlignment.Left
modelLabel.Parent = modelFrame

local modelDropdown = Instance.new("TextButton")
modelDropdown.Size = UDim2.new(1,0,0,35)
modelDropdown.Position = UDim2.new(0,0,0,25)
modelDropdown.BackgroundColor3 = Color3.fromRGB(45,42,58)
modelDropdown.Text = getgenv().MapleConfig.Model
modelDropdown.TextColor3 = Color3.new(1,1,1)
modelDropdown.TextSize = 14
modelDropdown.Font = Enum.Font.Gotham
modelDropdown.Parent = modelFrame
CreateCorner(modelDropdown,6)

local modelOptions = {"gpt-4","maple-light","claude-v1"}

local dropdownFrame = Instance.new("Frame")
dropdownFrame.Size = UDim2.new(1,0,0,#modelOptions*35)
dropdownFrame.Position = UDim2.new(0,0,0,65)
dropdownFrame.BackgroundColor3 = Color3.fromRGB(45,42,58)
dropdownFrame.Visible = false
dropdownFrame.Parent = modelFrame
CreateCorner(dropdownFrame,6)

for i, option in ipairs(modelOptions) do
    local opt = Instance.new("TextButton")
    opt.Size = UDim2.new(1,0,0,35)
    opt.Position = UDim2.new(0,0,0,(i-1)*35)
    opt.BackgroundTransparency = 1
    opt.Text = option
    opt.TextColor3 = Color3.new(1,1,1)
    opt.TextSize = 14
    opt.Font = Enum.Font.Gotham
    opt.Parent = dropdownFrame

    opt.MouseButton1Click:Connect(function()
        modelDropdown.Text = option
        getgenv().MapleConfig.Model = option
        SaveConfig()
        dropdownFrame.Visible = false
    end)
end

modelDropdown.MouseButton1Click:Connect(function()
    dropdownFrame.Visible = not dropdownFrame.Visible
end)

--========================================================--
-- BLACKLIST UI
--========================================================--

local blacklistFrame = Instance.new("ScrollingFrame")
blacklistFrame.Size = UDim2.new(1,0,1,-45)
blacklistFrame.Position = UDim2.new(0,0,0,45)
blacklistFrame.BackgroundTransparency = 1
blacklistFrame.ScrollBarThickness = 4
blacklistFrame.CanvasSize = UDim2.new(0,0,0,0)
blacklistFrame.Parent = BlacklistTab

local blLayout = Instance.new("UIListLayout")
blLayout.Parent = blacklistFrame
blLayout.Padding = UDim.new(0,5)

local addPlayerFrame = Instance.new("Frame")
addPlayerFrame.Size = UDim2.new(1,0,0,35)
addPlayerFrame.BackgroundTransparency = 1
addPlayerFrame.Parent = BlacklistTab

local playerInput = Instance.new("TextBox")
playerInput.Size = UDim2.new(1,-45,1,0)
playerInput.BackgroundColor3 = Color3.fromRGB(45,42,58)
playerInput.PlaceholderText = "Enter player name..."
playerInput.TextColor3 = Color3.new(1,1,1)
playerInput.TextSize = 14
playerInput.Font = Enum.Font.Gotham
playerInput.Parent = addPlayerFrame
CreateCorner(playerInput,6)

local addButton = Instance.new("TextButton")
addButton.Size = UDim2.new(0,35,1,0)
addButton.Position = UDim2.new(1,-35,0,0)
addButton.BackgroundColor3 = Color3.fromRGB(88,45,138)
addButton.Text = "+"
addButton.TextColor3 = Color3.new(1,1,1)
addButton.Font = Enum.Font.GothamBold
addButton.TextSize = 20
addButton.Parent = addPlayerFrame
CreateCorner(addButton,6)

local function RefreshBlacklist()
    for _, child in ipairs(blacklistFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    for _, name in ipairs(getgenv().MapleConfig.Blacklist) do
        local item = Instance.new("Frame")
        item.Size = UDim2.new(1,0,0,30)
        item.BackgroundColor3 = Color3.fromRGB(45,42,58)
        item.Parent = blacklistFrame
        CreateCorner(item,6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1,-35,1,0)
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.Font = Enum.Font.Gotham
        lbl.TextColor3 = Color3.new(1,1,1)
        lbl.TextSize = 14
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = item

        local rm = Instance.new("TextButton")
        rm.Size = UDim2.new(0,30,1,0)
        rm.Position = UDim2.new(1,-30,0,0)
        rm.BackgroundTransparency = 1
        rm.Text = "×"
        rm.Font = Enum.Font.GothamBold
        rm.TextSize = 18
        rm.TextColor3 = Color3.fromRGB(255,100,100)
        rm.Parent = item

        rm.MouseButton1Click:Connect(function()
            for i,v in ipairs(getgenv().MapleConfig.Blacklist) do
                if v == name then table.remove(getgenv().MapleConfig.Blacklist,i) end
            end
            SaveConfig()
            RefreshBlacklist()
        end)
    end

    blacklistFrame.CanvasSize = UDim2.new(0,0,0,blLayout.AbsoluteContentSize.Y)
end

addButton.MouseButton1Click:Connect(function()
    local name = playerInput.Text
    if name ~= "" and not table.find(getgenv().MapleConfig.Blacklist,name) then
        table.insert(getgenv().MapleConfig.Blacklist,name)
        SaveConfig()
        RefreshBlacklist()
        playerInput.Text = ""
    end
end)

RefreshBlacklist()

--========================================================--
-- WINDOW OPEN/CLOSE
--========================================================--

ToggleButtonObj.MouseButton1Click:Connect(function()
    MainWindow.Visible = not MainWindow.Visible
    if MainWindow.Visible then
        Tween(MainWindow,{Size=UDim2.new(0,550,0,420)},0.3,Enum.EasingStyle.Back)
    end
end)

CloseButton.MouseButton1Click:Connect(function()
    MainWindow.Visible = false
end)

Library:SelectTab("Home")

--========================================================--
-- AI CHATBOT LOGIC (MAIN FUNCTIONALITY)
--========================================================--

local request = request or http_request or syn.request

local sayRemote = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    and ReplicatedStorage.DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest")

local function Say(msg)
    if TextChatService and TextChatService.TextChannels then
        local channel = TextChatService.TextChannels.RBXGeneral
        if channel then channel:SendAsync(msg) return end
    end
    if sayRemote then sayRemote:FireServer(msg,"All") end
end

-- Rotate to face speaker
local function FaceTarget(character)
    if not character then return end
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end

    local hrp = myChar.HumanoidRootPart
    local theirRoot = character:FindFirstChild("HumanoidRootPart")
    if not theirRoot then return end

    local dir = (theirRoot.Position - hrp.Position).Unit
    local look = CFrame.lookAt(hrp.Position, hrp.Position + dir)

    TweenService:Create(
        hrp,
        TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
        {CFrame = look}
    ):Play()
end

-- Cooldown Logic
local recentTriggers = {}
local inCooldown = false

local function ActivateCooldown()
    inCooldown = true
    local start = tick()
    while tick() - start < 8 do
        Say("Cooldown...")
        task.wait(2.5)
    end
    inCooldown = false
end

local function RegisterTrigger()
    local now = tick()
    table.insert(recentTriggers, now)

    local newList = {}
    for _, t in ipairs(recentTriggers) do
        if now - t <= 5 then table.insert(newList, t) end
    end
    recentTriggers = newList

    if #recentTriggers >= 5 and not inCooldown then
        ActivateCooldown()
    end
end

-- AI Chat Handling
local chatHistory = {}

local function HandleAI(message)
    local cfg = getgenv().MapleConfig
    if not cfg.MasterEnabled then return end
    if inCooldown then return end

    RegisterTrigger()

    table.insert(chatHistory, {role="user", content=message})

    local payload = {
        model = cfg.Model,
        system_prompt = cfg.Persona,
        messages = chatHistory
    }

    local result = request({
        Url = "https://api.mapleai.de/v1/chat/completions",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bearer " .. cfg.APIKey
        },
        Body = HttpService:JSONEncode(payload)
    })

    if not result or not result.Body then return end

    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(result.Body)
    end)

    if not ok or not decoded or not decoded.choices then return end

    local reply = decoded.choices[1].message.content
    if not reply then return end

    table.insert(chatHistory, {role="assistant", content=reply})

    Say(reply)
end

local function OnPlayerChatted(player, msg)
    if player == LocalPlayer then return end
    local cfg = getgenv().MapleConfig
    if not cfg.MasterEnabled then return end

    if table.find(cfg.Blacklist, player.Name) then return end

    if player.Character then FaceTarget(player.Character) end

    task.spawn(function()
        HandleAI(msg)
    end)
end

-- Connect chat events
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        plr.Chatted:Connect(function(msg)
            OnPlayerChatted(plr,msg)
        end)
    end
end

Players.PlayerAdded:Connect(function(plr)
    if plr ~= LocalPlayer then
        plr.Chatted:Connect(function(msg)
            OnPlayerChatted(plr,msg)
        end)
    end
end)

--========================================================--
-- END OF FULL main.lua
--========================================================--