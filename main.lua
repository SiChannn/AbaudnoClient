--=========================================================================
-- RdHelper v11.1 — Главный файл (Modular Architecture)
-- https://github.com/SiChannn/AbaudnoClient
--=========================================================================

if not game:IsLoaded() then game.Loaded:Wait() end

-- [0. Защита и изоляция]
pcall(function()
    if _G then _G.RdHelper = nil; _G.RdHelperActive = nil end
    if shared then shared.RdHelper = nil; shared.RdHelperActive = nil end

    if hookmetamethod and checkcaller and newcclosure then
        local gameMeta = getrawmetatable(game)
        if setreadonly then setreadonly(gameMeta, false) end

        local oldIndex; oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
            if not checkcaller() then
                local kStr = tostring(key):lower()
                if kStr:find("helper") or kStr:find("roblox_") or kStr:find("terrainchunk_") then
                    return nil
                end
            end
            return oldIndex(self, key)
        end))

        if setreadonly then setreadonly(gameMeta, true) end
    end
end)

-- [1. Сервисы]
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")

-- [2. Переменные]
local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do task.wait(0.1) LocalPlayer = Players.LocalPlayer end
local Camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")

local RandomGuiName = "Roblox_" .. string.gsub(HttpService:GenerateGUID(false), "-", ""):sub(1, 10)
local SafeParent = gethui and gethui() or (CoreGui or LocalPlayer:WaitForChild("PlayerGui", 5))

-- [3. Настройки]
local Settings = {
    GUIBind = Enum.KeyCode.RightControl,
    SilentAimActive = false, SilentAimBind = Enum.KeyCode.Unknown, AimMode = "Hold", AimType = "Bypass", AimFov = 140, TargetIndicator = true, TargetLock = true, WallCheck = true, HitPart = "Head",
    FollowActive = false, FollowBind = Enum.KeyCode.Unknown, FollowMode = "Run", FollowDistance = 5, FollowSpeed = 20,
    SpeedActive = false, SpeedBind = Enum.KeyCode.Unknown, BoostSpeed = 50,
    JumpActive = false, JumpBind = Enum.KeyCode.Unknown, BoostJump = 100,
    BhopActive = false, BhopBind = Enum.KeyCode.Unknown, BhopSpeed = 35,
    FlightActive = false, FlightBind = Enum.KeyCode.Unknown, FlightSpeed = 50,
    VflyActive = false, VflyBind = Enum.KeyCode.Unknown, VflySpeed = 60,
    BlinkBind = Enum.KeyCode.Unknown, BlinkDistance = 25, BlinkMode = "Normal",
    AirJumpActive = false, AirJumpBind = Enum.KeyCode.Unknown, AirJumpPower = 50, AirJumpMode = "Default",
    SpiderActive = false, SpiderBind = Enum.KeyCode.Unknown, SpiderSpeed = 25,
    AntiVoid = false, AntiVoidHeight = -200,
    EspActive = false, EspBind = Enum.KeyCode.Unknown, EspFillTransparency = 0.65, EspBoxes = false, EspTracers = false, EspNames = false,
    ShadersActive = false, ShadersBind = Enum.KeyCode.Unknown,
    FullbrightActive = false, FullbrightBind = Enum.KeyCode.Unknown, FullbrightPower = 5,
    NoFog = false, XrayActive = false, FovCircleVisible = true,
    NoPlayerCollision = false, NoclipActive = false, NoclipBind = Enum.KeyCode.Unknown,
    ClickTpActive = false, ClickTpBind = Enum.KeyCode.Unknown, ClickTpKey = Enum.KeyCode.LeftControl, ClickTpMode = "Click Required",
    FastTpBind = Enum.KeyCode.Unknown,
    TpManagerActive = false, TpManagerBind = Enum.KeyCode.Unknown, TpManagerInterval = 3,
    ChatSpam = false,
    SpinnerActive = false, SpinnerBind = Enum.KeyCode.Unknown, SpinnerSpeed = 30, SpinnerMoveSync = true
}

local FrameKeys = {
    SilentAimActive = "SilentAim", FollowActive = "Follow", SpeedActive = "SpeedBoost",
    JumpActive = "JumpBoost", BhopActive = "Bhop", FlightActive = "Flight", VflyActive = "Vfly",
    AirJumpActive = "AirJump", SpiderActive = "Spider", EspActive = "Esp", FullbrightActive = "Fullbright",
    NoPlayerCollision = "NoPlayerCollision", NoclipActive = "Noclip", ClickTpActive = "ClickTP", TpManagerActive = "TpManager",
    ShadersActive = "ShadersModule", SpinnerActive = "SpinnerFrame"
}

local Theme = {
    Background = Color3.fromRGB(18, 18, 22), Sidebar = Color3.fromRGB(12, 12, 16), TitleBar = Color3.fromRGB(25, 25, 35), ModuleBg = Color3.fromRGB(22, 22, 28), ModuleActiveBg = Color3.fromRGB(29, 25, 38),
    ElementBg = Color3.fromRGB(38, 38, 48), Accent = Color3.fromRGB(160, 32, 240), AccentSecondary = Color3.fromRGB(255, 20, 147), Text = Color3.fromRGB(240, 240, 240), AimCircleColor = Color3.fromRGB(160, 32, 240)
}

-- [4. Создание интерфейса]
local ScreenGui = Instance.new("ScreenGui"); ScreenGui.Name = RandomGuiName; ScreenGui.ResetOnSpawn = false; ScreenGui.Parent = SafeParent

local MainFrame = Instance.new("Frame", ScreenGui); MainFrame.Position = UDim2.new(0.5, -225, 0.5, -175); MainFrame.Size = UDim2.new(0, 470, 0, 360); MainFrame.BackgroundColor3 = Theme.Background
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 6)
local MainStroke = Instance.new("UIStroke", MainFrame); MainStroke.Color = Theme.Accent; MainStroke.Thickness = 1.5

local TitleBar = Instance.new("Frame", MainFrame); TitleBar.Size = UDim2.new(1, 0, 0, 35); TitleBar.BackgroundColor3 = Theme.TitleBar
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 6)
local Title = Instance.new("TextLabel", TitleBar); Title.Size = UDim2.new(1, -20, 1, 0); Title.Position = UDim2.new(0, 15, 0, 0); Title.BackgroundTransparency = 1; Title.Font = Enum.Font.GothamBold; Title.Text = "RdHelper v11.1"; Title.TextSize = 13; Title.TextColor3 = Theme.Accent; Title.TextXAlignment = Enum.TextXAlignment.Left

-- Перетаскивание окна
local dragToggle, dragStart, startPos
TitleBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragToggle = true; dragStart = input.Position; startPos = MainFrame.Position end end)
UserInputService.InputChanged:Connect(function(input) if dragToggle and input.UserInputType == Enum.UserInputType.MouseMovement then local delta = input.Position - dragStart; MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragToggle = false end end)

-- Боковое меню
local Sidebar = Instance.new("Frame", MainFrame); Sidebar.Position = UDim2.new(0, 0, 0, 35); Sidebar.Size = UDim2.new(0, 120, 1, -35); Sidebar.BackgroundColor3 = Theme.Sidebar

-- Вкладки
local function CreateTab(text, y)
    local b = Instance.new("TextButton", Sidebar); b.Position = UDim2.new(0, 5, 0, y); b.Size = UDim2.new(1, -10, 0, 28); b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.Text = text; b.BackgroundColor3 = Theme.Sidebar; b.TextColor3 = Theme.Text; b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    return b
end

local TabCombat = CreateTab("Combat", 10)
local TabMovement = CreateTab("Movement", 44)
local TabVisuals = CreateTab("Visuals", 78)
local TabMisc = CreateTab("Misc", 112)
local TabSettings = CreateTab("Settings", 146)

-- Скролл-фреймы для контента
local function CreateScroll()
    local s = Instance.new("ScrollingFrame", MainFrame); s.Position = UDim2.new(0, 130, 0, 45); s.Size = UDim2.new(1, -140, 1, -55); s.BackgroundTransparency = 1; s.BorderSizePixel = 0; s.ScrollBarThickness = 4; s.ScrollBarImageColor3 = Theme.Accent; s.Visible = false
    local l = Instance.new("UIListLayout", s); l.SortOrder = Enum.SortOrder.LayoutOrder; l.Padding = UDim.new(0, 6)
    l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() s.CanvasSize = UDim2.new(0, 0, 0, l.AbsoluteContentSize.Y + 15) end)
    return s
end

local ScrollCombat = CreateScroll(); ScrollCombat.Visible = true
local ScrollMovement = CreateScroll()
local ScrollVisuals = CreateScroll()
local ScrollMisc = CreateScroll()
local ScrollSettings = CreateScroll()

-- Переключение вкладок
local function switch(activeBtn)
    local btns = {TabCombat, TabMovement, TabVisuals, TabMisc, TabSettings}
    local scrals = {ScrollCombat, ScrollMovement, ScrollVisuals, ScrollMisc, ScrollSettings}
    for i, v in ipairs(btns) do
        local act = (v == activeBtn); v.BackgroundColor3 = act and Theme.TitleBar or Theme.Sidebar; v.TextColor3 = act and Theme.Accent or Theme.Text; scrals[i].Visible = act
    end
end

TabCombat.MouseButton1Click:Connect(function() switch(TabCombat) end)
TabMovement.MouseButton1Click:Connect(function() switch(TabMovement) end)
TabVisuals.MouseButton1Click:Connect(function() switch(TabVisuals) end)
TabMisc.MouseButton1Click:Connect(function() switch(TabMisc) end)
TabSettings.MouseButton1Click:Connect(function() switch(TabSettings) end

-- UI Helper функции
local isBindingProcess = false
local ModuleFrames = {}

local function SetModuleGlow(key, active)
    if not key then return end
    local frameName = FrameKeys[key] or key; local m = ModuleFrames[frameName]
    if not m then return end
    m.BackgroundColor3 = active and Theme.ModuleActiveBg or Theme.ModuleBg
end

local function AddModule(key, name, parent, onClick, hValue)
    local m = Instance.new("Frame", parent); m.Size = UDim2.new(1, 0, 0, 32); m.BackgroundColor3 = Theme.ModuleBg; m.ClipsDescendants = true; m.Name = key
    Instance.new("UICorner", m).CornerRadius = UDim.new(0, 4)
    local glow = Instance.new("Frame", m); glow.Name = "GlowIndicator"; glow.Size = UDim2.new(0, 4, 1, 0); glow.BackgroundTransparency = 1; glow.BackgroundColor3 = Theme.Accent
    local trigger = Instance.new("TextButton", m); trigger.Size = UDim2.new(1, -80, 0, 32); trigger.BackgroundTransparency = 1; trigger.Font = Enum.Font.GothamBold; trigger.Text = "  " .. name; trigger.TextColor3 = Theme.Text; trigger.TextSize = 12; trigger.TextXAlignment = Enum.TextXAlignment.Left
    local bBtn = Instance.new("TextButton", m); bBtn.Name = "BindButton"; bBtn.Position = UDim2.new(1, -72, 0, 5); bBtn.Size = UDim2.new(0, 65, 0, 22); bBtn.BackgroundColor3 = Theme.ElementBg; bBtn.Font = Enum.Font.GothamBold; bBtn.Text = "Bind"; bBtn.TextColor3 = Theme.Accent; bBtn.TextSize = 11; Instance.new("UICorner", bBtn).CornerRadius = UDim.new(0, 4)

    trigger.MouseEnter:Connect(function() if m.BackgroundColor3 ~= Theme.ModuleActiveBg then TweenService:Create(m, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(26, 26, 34)}):Play() end end)
    trigger.MouseLeave:Connect(function() if m.BackgroundColor3 ~= Theme.ModuleActiveBg then TweenService:Create(m, TweenInfo.new(0.1), {BackgroundColor3 = Theme.ModuleBg}):Play() end end)

    trigger.MouseButton1Click:Connect(function() if not isBindingProcess and onClick then onClick() end end)
    trigger.MouseButton2Click:Connect(function()
        if isBindingProcess then return end
        local open = (m.Size.Y.Offset == 32)
        TweenService:Create(m, TweenInfo.new(0.15), {Size = open and UDim2.new(1, 0, 0, hValue or 140) or UDim2.new(1, 0, 0, 32)}):Play()
    end)
    ModuleFrames[key] = m
    return m, trigger, bBtn
end

local function addLabel(txt, p, y)
    local l = Instance.new("TextLabel", p); l.Position = UDim2.new(0, 12, 0, y); l.Size = UDim2.new(0, 130, 0, 18); l.BackgroundTransparency = 1; l.Font = Enum.Font.GothamBold; l.Text = txt; l.TextColor3 = Theme.Text; l.TextSize = 11; l.TextXAlignment = Enum.TextXAlignment.Left
    return l
end

local function addTextBox(p, y, def, cb)
    local box = Instance.new("TextBox", p); box.Position = UDim2.new(1, -72, 0, y); box.Size = UDim2.new(0, 65, 0, 20); box.BackgroundColor3 = Theme.ElementBg; box.Font = Enum.Font.GothamBold; box.Text = tostring(def); box.TextColor3 = Theme.AccentSecondary; box.TextSize = 11; box.ClearTextOnFocus = false
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    box.FocusLost:Connect(function()
        local val = tonumber(box.Text)
        if val then cb(val) else box.Text = tostring(def) end
    end)
end

local function addToggle(p, y, def, cb)
    local b = Instance.new("TextButton", p); b.Position = UDim2.new(1, -72, 0, y); b.Size = UDim2.new(0, 65, 0, 20); b.BackgroundColor3 = Theme.ElementBg; b.Font = Enum.Font.GothamBold; b.Text = def and "ON" or "OFF"; b.TextColor3 = def and Theme.Accent or Theme.Text; b.TextSize = 11; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    b.MouseButton1Click:Connect(function() local s = (b.Text == "OFF") b.Text = s and "ON" or "OFF" b.TextColor3 = s and Theme.Accent or Theme.Text cb(s) end)
end

local function addModeBtn(p, y, currentMode, modesTable, cb)
    local b = Instance.new("TextButton", p); b.Position = UDim2.new(1, -72, 0, y); b.Size = UDim2.new(0, 65, 0, 20); b.BackgroundColor3 = Theme.ElementBg; b.Font = Enum.Font.GothamBold; b.Text = currentMode; b.TextColor3 = Theme.AccentSecondary; b.TextSize = 11; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
    b.MouseButton1Click:Connect(function() local idx = table.find(modesTable, b.Text) or 1 idx = (idx % #modesTable) + 1 b.Text = modesTable[idx] cb(modesTable[idx]) end)
end

local function setupCustomKeybind(btn, settingKey)
    if not btn then return end
    btn.MouseButton1Click:Connect(function()
        if isBindingProcess then return end
        isBindingProcess = true; btn.Text = "..."
        local conn; conn = UserInputService.InputBegan:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.Escape or input.UserInputType == Enum.UserInputType.MouseButton2 then
                conn:Disconnect(); Settings[settingKey] = Enum.KeyCode.Unknown; btn.Text = "Bind"; task.wait(0.1); isBindingProcess = false; return
            end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                conn:Disconnect(); Settings[settingKey] = input.KeyCode; btn.Text = tostring(input.KeyCode.Name); isBindingProcess = false
            end
        end)
    end)
end

-- [5. COMBAT MODULES]
local fCombat, _, bCombat = AddModule("SilentAim", "Silent Aim", ScrollCombat, function() Settings.SilentAimActive = not Settings.SilentAimActive; SetModuleGlow("SilentAimActive", Settings.SilentAimActive) end, 190)
addLabel("Aim Target:", fCombat, 35); addModeBtn(fCombat, 35, Settings.AimType, {"Bypass", "Classic"}, function(m) Settings.AimType = m end)
addLabel("Activation:", fCombat, 60); addModeBtn(fCombat, 60, Settings.AimMode, {"Hold", "Toggle"}, function(m) Settings.AimMode = m end)
addLabel("FOV Size:", fCombat, 85); addTextBox(fCombat, 85, Settings.AimFov, function(v) Settings.AimFov = v end)
addLabel("HitPart:", fCombat, 110); addModeBtn(fCombat, 110, Settings.HitPart, {"Head", "HumanoidRootPart"}, function(m) Settings.HitPart = m end)
addLabel("Lock Target:", fCombat, 135); addToggle(fCombat, 135, Settings.TargetLock, function(v) Settings.TargetLock = v end)
addLabel("Wall Check:", fCombat, 160); addToggle(fCombat, 160, Settings.WallCheck, function(v) Settings.WallCheck = v end)
setupCustomKeybind(bCombat, "SilentAimBind")

local fFollow, _, bFollow = AddModule("Follow", "Follow Player", ScrollCombat, function() Settings.FollowActive = not Settings.FollowActive; SetModuleGlow("FollowActive", Settings.FollowActive) end, 115)
addLabel("Movement:", fFollow, 35); addModeBtn(fFollow, 35, Settings.FollowMode, {"Run", "Fly"}, function(m) Settings.FollowMode = m end)
addLabel("Distance:", fFollow, 60); addTextBox(fFollow, 60, Settings.FollowDistance, function(v) Settings.FollowDistance = v end)
addLabel("Follow Speed:", fFollow, 85); addTextBox(fFollow, 85, Settings.FollowSpeed, function(v) Settings.FollowSpeed = v end)
setupCustomKeybind(bFollow, "FollowBind")

-- [6. MOVEMENT MODULES]
local fSpeed, _, bSpeed = AddModule("SpeedBoost", "Walk Speed Boost", ScrollMovement, function() Settings.SpeedActive = not Settings.SpeedActive; SetModuleGlow("SpeedActive", Settings.SpeedActive) end, 65)
addLabel("Speed Value:", fSpeed, 35); addTextBox(fSpeed, 35, Settings.BoostSpeed, function(v) Settings.BoostSpeed = v end); setupCustomKeybind(bSpeed, "SpeedBind")

local fJump, _, bJump = AddModule("JumpBoost", "Jump Power Boost", ScrollMovement, function() Settings.JumpActive = not Settings.JumpActive; SetModuleGlow("JumpActive", Settings.JumpActive) end, 65)
addLabel("Jump Power:", fJump, 35); addTextBox(fJump, 35, Settings.BoostJump, function(v) Settings.BoostJump = v end); setupCustomKeybind(bJump, "JumpBind")

local fBhop, _, bBhop = AddModule("Bhop", "Bhop", ScrollMovement, function() Settings.BhopActive = not Settings.BhopActive; SetModuleGlow("BhopActive", Settings.BhopActive) end, 65)
addLabel("Forward Force:", fBhop, 35); addTextBox(fBhop, 35, Settings.BhopSpeed, function(v) Settings.BhopSpeed = v end); setupCustomKeybind(bBhop, "BhopBind")

local fFly, _, bFly = AddModule("Flight", "Character Flight", ScrollMovement, function() Settings.FlightActive = not Settings.FlightActive; SetModuleGlow("FlightActive", Settings.FlightActive) end, 65)
addLabel("Flight Speed:", fFly, 35); addTextBox(fFly, 35, Settings.FlightSpeed, function(v) Settings.FlightSpeed = v end); setupCustomKeybind(bFly, "FlightBind")

local fVfly, _, bVfly = AddModule("Vfly", "Vehicle Flight", ScrollMovement, function() Settings.VflyActive = not Settings.VflyActive; SetModuleGlow("VflyActive", Settings.VflyActive) end, 65)
addLabel("Vfly Speed:", fVfly, 35); addTextBox(fVfly, 35, Settings.VflySpeed, function(v) Settings.VflySpeed = v end); setupCustomKeybind(bVfly, "VflyBind")

-- [7. VISUALS MODULES]
local fEsp, _, bEsp = AddModule("Esp", "Player ESP", ScrollVisuals, function() Settings.EspActive = not Settings.EspActive; SetModuleGlow("EspActive", Settings.EspActive) end, 115)
addLabel("Fill Trans:", fEsp, 35); addTextBox(fEsp, 35, Settings.EspFillTransparency, function(v) Settings.EspFillTransparency = v end)
addLabel("Boxes:", fEsp, 60); addToggle(fEsp, 60, Settings.EspBoxes, function(v) Settings.EspBoxes = v end)
addLabel("Tracers:", fEsp, 85); addToggle(fEsp, 85, Settings.EspTracers, function(v) Settings.EspTracers = v end)
addLabel("Names:", fEsp, 110); addToggle(fEsp, 110, Settings.EspNames, function(v) Settings.EspNames = v end)
setupCustomKeybind(bEsp, "EspBind")

local fFullbright, _, bFullbright = AddModule("Fullbright", "Full Brightness", ScrollVisuals, function() Settings.FullbrightActive = not Settings.FullbrightActive; SetModuleGlow("FullbrightActive", Settings.FullbrightActive) end, 65)
addLabel("Brightness:", fFullbright, 35); addTextBox(fFullbright, 35, Settings.FullbrightPower, function(v) Settings.FullbrightPower = v end)
setupCustomKeybind(bFullbright, "FullbrightBind")

-- [8. MISC MODULES]
local fNoclip, _, bNoclip = AddModule("Noclip", "No Clip", ScrollMisc, function() Settings.NoclipActive = not Settings.NoclipActive; SetModuleGlow("NoclipActive", Settings.NoclipActive) end, 65)
setupCustomKeybind(bNoclip, "NoclipBind")

local fClickTp, _, bClickTp = AddModule("ClickTP", "Click Teleport", ScrollMisc, function() Settings.ClickTpActive = not Settings.ClickTpActive; SetModuleGlow("ClickTpActive", Settings.ClickTpActive) end, 65)
addLabel("Mode:", fClickTp, 35); addModeBtn(fClickTp, 35, Settings.ClickTpMode, {"Click Required", "Always"}, function(m) Settings.ClickTpMode = m end)
setupCustomKeybind(bClickTp, "ClickTpBind")

local fSpinner, _, bSpinner = AddModule("Spinner", "Camera Spinner", ScrollMisc, function() Settings.SpinnerActive = not Settings.SpinnerActive; SetModuleGlow("SpinnerActive", Settings.SpinnerActive) end, 65)
addLabel("Speed:", fSpinner, 35); addTextBox(fSpinner, 35, Settings.SpinnerSpeed, function(v) Settings.SpinnerSpeed = v end)
setupCustomKeybind(bSpinner, "SpinnerBind")

-- [9. Инициализация модулей]
local Modules = {}

-- Загрузка модулей из папок
local function loadModules()
    local success, msg
    success, Modules.SilentAim = pcall(function() return require(game:GetService("ReplicatedStorage").modules.combat.silent_aim) end)
    if not success then Modules.SilentAim = nil end
    success, Modules.Follow = pcall(function() return require(game:GetService("ReplicatedStorage").modules.combat.follow) end)
    if not success then Modules.Follow = nil end
    success, Modules.Noclip = pcall(function() return require(game:GetService("ReplicatedStorage").modules.misc.noclip) end)
    if not success then Modules.Noclip = nil end
    success, Modules.ClickTp = pcall(function() return require(game:GetService("ReplicatedStorage").modules.misc.clicktp) end)
    if not success then Modules.ClickTp = nil end
    success, Modules.Spinner = pcall(function() return require(game:GetService("ReplicatedStorage").modules.misc.spinner) end)
    if not success then Modules.Spinner = nil end
end

-- [10. Горячие клавиши]
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Settings.SilentAimBind then
        Settings.SilentAimActive = not Settings.SilentAimActive
        SetModuleGlow("SilentAimActive", Settings.SilentAimActive)
    elseif input.KeyCode == Settings.FollowBind then
        Settings.FollowActive = not Settings.FollowActive
        SetModuleGlow("FollowActive", Settings.FollowActive)
    elseif input.KeyCode == Settings.SpeedBind then
        Settings.SpeedActive = not Settings.SpeedActive
        SetModuleGlow("SpeedActive", Settings.SpeedActive)
    elseif input.KeyCode == Settings.JumpBind then
        Settings.JumpActive = not Settings.JumpActive
        SetModuleGlow("JumpActive", Settings.JumpActive)
    elseif input.KeyCode == Settings.BhopBind then
        Settings.BhopActive = not Settings.BhopActive
        SetModuleGlow("BhopActive", Settings.BhopActive)
    elseif input.KeyCode == Settings.FlightBind then
        Settings.FlightActive = not Settings.FlightActive
        SetModuleGlow("FlightActive", Settings.FlightActive)
    elseif input.KeyCode == Settings.VflyBind then
        Settings.VflyActive = not Settings.VflyActive
        SetModuleGlow("VflyActive", Settings.VflyActive)
    elseif input.KeyCode == Settings.EspBind then
        Settings.EspActive = not Settings.EspActive
        SetModuleGlow("EspActive", Settings.EspActive)
    elseif input.KeyCode == Settings.FullbrightBind then
        Settings.FullbrightActive = not Settings.FullbrightActive
        SetModuleGlow("FullbrightActive", Settings.FullbrightActive)
    elseif input.KeyCode == Settings.NoclipBind then
        Settings.NoclipActive = not Settings.NoclipActive
        SetModuleGlow("NoclipActive", Settings.NoclipActive)
    elseif input.KeyCode == Settings.ClickTpBind then
        Settings.ClickTpActive = not Settings.ClickTpActive
        SetModuleGlow("ClickTpActive", Settings.ClickTpActive)
    elseif input.KeyCode == Settings.SpinnerBind then
        Settings.SpinnerActive = not Settings.SpinnerActive
        SetModuleGlow("SpinnerActive", Settings.SpinnerActive)
    elseif input.KeyCode == Settings.GUIBind then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- [11. RenderStepped цикл]
RunService.RenderStepped:Connect(function()
    -- Silent Aim
    if Modules.SilentAim then Modules.SilentAim.renderStepped() end
    -- Follow
    if Modules.Follow then Modules.Follow.renderStepped() end
    -- Noclip
    if Modules.Noclip then Modules.Noclip.renderStepped() end
    -- Spinner
    if Modules.Spinner then Modules.Spinner.renderStepped() end
end)

print("RdHelper modular UI loaded.")