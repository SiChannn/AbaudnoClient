--[[
    AbaudnoClient — Shared Library
    Общие сервисы, настройки, тема и утилиты для всех модулей.
]]

if _G.AbaudnoClient and _G.AbaudnoClient.loaded then
    return _G.AbaudnoClient
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do task.wait(0.1) LocalPlayer = Players.LocalPlayer end
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")

local lib = {
    loaded = true,

    -- Сервисы
    Players = Players,
    UserInputService = UserInputService,
    RunService = RunService,
    TweenService = TweenService,
    Lighting = Lighting,
    Workspace = Workspace,
    HttpService = HttpService,
    ReplicatedStorage = ReplicatedStorage,
    CoreGui = CoreGui,
    LocalPlayer = LocalPlayer,
    Mouse = Mouse,
    Camera = Camera,

    -- Состояние
    LockedTarget = nil,
    ClickDebounce = false,
    TargetCache = nil,
    LastFlightState = false,
    OriginalGravity = Workspace.Gravity,
    OrigLighting = {
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        ClockTime = Lighting.ClockTime,
        Brightness = Lighting.Brightness,
        GlobalShadows = Lighting.GlobalShadows,
        FogEnd = Lighting.FogEnd,
    },
    CustomVisuals = { SunRays = nil, ColorCorr = nil },
    FastTpPos = nil,
    FastTpVisual = nil,
    TpPoints = {},
    TpVisuals = {},
    CurrentTpIndex = 1,
    LastTpTime = 0,
    SpinnerAngle = 0,
    XrayCache = {},
    VisualFolder = nil,
    MaxVisualDistance = 2000,

    -- Настройки
    Settings = {
        GUIBind = Enum.KeyCode.RightControl,

        -- Combat
        SilentAimActive = false, SilentAimBind = Enum.KeyCode.Unknown,
        AimMode = "Hold", AimType = "Bypass", AimFov = 140,
        TargetIndicator = true, TargetLock = true, WallCheck = true, HitPart = "Head",

        FollowActive = false, FollowBind = Enum.KeyCode.Unknown,
        FollowMode = "Run", FollowDistance = 5, FollowSpeed = 20,

        -- Movement
        SpeedActive = false, SpeedBind = Enum.KeyCode.Unknown, BoostSpeed = 50,
        JumpActive = false, JumpBind = Enum.KeyCode.Unknown, BoostJump = 100,
        BhopActive = false, BhopBind = Enum.KeyCode.Unknown, BhopSpeed = 35,
        FlightActive = false, FlightBind = Enum.KeyCode.Unknown, FlightSpeed = 50,
        VflyActive = false, VflyBind = Enum.KeyCode.Unknown, VflySpeed = 60,
        BlinkBind = Enum.KeyCode.Unknown, BlinkDistance = 25, BlinkMode = "Normal",
        AirJumpActive = false, AirJumpBind = Enum.KeyCode.Unknown, AirJumpPower = 50, AirJumpMode = "Default",
        SpiderActive = false, SpiderBind = Enum.KeyCode.Unknown, SpiderSpeed = 25,
        AntiVoid = false, AntiVoidBind = Enum.KeyCode.Unknown, AntiVoidHeight = -200,

        -- Visuals
        EspActive = false, EspBind = Enum.KeyCode.Unknown,
        EspFillTransparency = 0.65, EspBoxes = false, EspTracers = false, EspNames = false,
        ShadersActive = false, ShadersBind = Enum.KeyCode.Unknown,
        FullbrightActive = false, FullbrightBind = Enum.KeyCode.Unknown, FullbrightPower = 5,
        NoFog = false, XrayActive = false, FovCircleVisible = true,

        -- Misc
        NoPlayerCollision = false,
        NoclipActive = false, NoclipBind = Enum.KeyCode.Unknown,
        ClickTpActive = false, ClickTpBind = Enum.KeyCode.Unknown,
        ClickTpKey = Enum.KeyCode.LeftControl, ClickTpMode = "Click Required",
        FastTpBind = Enum.KeyCode.Unknown,
        TpManagerActive = false, TpManagerBind = Enum.KeyCode.Unknown, TpManagerInterval = 3,
        ChatSpam = false, ChatSpamBind = Enum.KeyCode.Unknown,
        SpinnerActive = false, SpinnerBind = Enum.KeyCode.Unknown,
        SpinnerSpeed = 30, SpinnerMoveSync = true,
    },

    -- Тема
    Theme = {
        Background = Color3.fromRGB(18, 18, 22),
        Sidebar = Color3.fromRGB(12, 12, 16),
        TitleBar = Color3.fromRGB(25, 25, 35),
        ModuleBg = Color3.fromRGB(22, 22, 28),
        ModuleActiveBg = Color3.fromRGB(29, 25, 38),
        ElementBg = Color3.fromRGB(38, 38, 48),
        Accent = Color3.fromRGB(160, 32, 240),
        AccentSecondary = Color3.fromRGB(255, 20, 147),
        Text = Color3.fromRGB(240, 240, 240),
        AimCircleColor = Color3.fromRGB(160, 32, 240),
    },
}

-- ===================== УТИЛИТЫ =====================

function lib.GetScreenCenter()
    local cam = lib.Camera
    return Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
end

function lib.GetVehiclePart()
    local char = lib.LocalPlayer.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.SeatPart then return hum.SeatPart end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        local parts = lib.Workspace:GetPartBoundsInRadius(root.Position, 6)
        for i = 1, #parts do
            local part = parts[i]
            if part.Name:lower():find("seat") or part:IsA("VehicleSeat") or part:IsA("Seat") then
                return part
            end
        end
    end
    return nil
end

function lib.IsVisibleBehindWalls(targetPart)
    if not lib.Settings.WallCheck then return true end
    local char = lib.LocalPlayer.Character
    if not char then return false end
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = { char, targetPart.Parent }
    raycastParams.IgnoreWater = true
    local result = lib.Workspace:Raycast(
        lib.Camera.CFrame.Position,
        targetPart.Position - lib.Camera.CFrame.Position,
        raycastParams
    )
    return result == nil
end

function lib.IsValid(player)
    return player
        and player ~= lib.LocalPlayer
        and player.Character
        and player.Character:FindFirstChild("Head")
        and player.Character:FindFirstChild("HumanoidRootPart")
        and player.Character:FindFirstChildOfClass("Humanoid")
        and player.Character.Humanoid.Health > 0
end

function lib.GetClosestPlayerInFov()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local center = lib.GetScreenCenter()
    local root = lib.LocalPlayer.Character and lib.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local playersList = lib.Players:GetPlayers()
    for i = 1, #playersList do
        local player = playersList[i]
        if lib.IsValid(player) then
            local targetPart = player.Character:FindFirstChild(lib.Settings.HitPart) or player.Character.Head
            local targetRoot = player.Character.HumanoidRootPart
            local distanceToPlayer = (root.Position - targetRoot.Position).Magnitude

            if distanceToPlayer <= lib.MaxVisualDistance then
                local screenPos, onScreen = lib.Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local distFromMouse = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if distFromMouse <= lib.Settings.AimFov and distFromMouse < shortestDistance then
                        if not lib.Settings.WallCheck or lib.IsVisibleBehindWalls(targetPart) then
                            closestPlayer = player
                            shortestDistance = distFromMouse
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

function lib.GetClosestPlayerForFollow()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local root = lib.LocalPlayer.Character and lib.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local playersList = lib.Players:GetPlayers()
    for i = 1, #playersList do
        local player = playersList[i]
        if lib.IsValid(player) then
            local targetRoot = player.Character.HumanoidRootPart
            local dist = (root.Position - targetRoot.Position).Magnitude
            if dist <= lib.MaxVisualDistance and dist < shortestDistance then
                closestPlayer = player
                shortestDistance = dist
            end
        end
    end
    return closestPlayer
end

function lib.GetCharParts()
    local char = lib.LocalPlayer.Character
    if not char then return nil, nil, nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    return char, root, hum
end

function lib.ApplyXrayToPart(part)
    if part:IsA("BasePart")
        and not part:IsDescendantOf(lib.LocalPlayer.Character or lib.Workspace)
        and not part:IsA("Terrain")
    then
        if not part:GetAttribute("OldTrans") then
            part:SetAttribute("OldTrans", part.Transparency)
        end
        part.Transparency = lib.Settings.XrayActive and 0.65 or part:GetAttribute("OldTrans")
        if not lib.Settings.XrayActive then
            part:SetAttribute("OldTrans", nil)
        end
    end
end

_G.AbaudnoClient = lib
return lib
