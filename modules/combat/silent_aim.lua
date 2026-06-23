--[[
    AbaudnoClient — Silent Aim Module
    Combat: автоматическое наведение на ближайшего игрока в FOV.
]]

local lib = _G.AbaudnoClient or loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/modules/lib/shared.lua"))()

local Settings = lib.Settings
local RunService = lib.RunService
local UserInputService = lib.UserInputService
local Workspace = lib.Workspace
local Camera = lib.Camera

local M = {}

function M.toggle()
    Settings.SilentAimActive = not Settings.SilentAimActive
    lib.LockedTarget = nil
    return Settings.SilentAimActive
end

function M.updateTargetCache()
    if Settings.SilentAimActive then
        lib.TargetCache = lib.GetClosestPlayerInFov()
    end
end

function M.renderStepped()
    if not Settings.SilentAimActive then
        lib.LockedTarget = nil
        lib.ClickDebounce = false
        return
    end

    Camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
    lib.Camera = Camera

    local char, root, hum = lib.GetCharParts()
    if not root then return end

    local isAimKeyPressed = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    local currentTarget = lib.TargetCache

    if currentTarget and lib.IsValid(currentTarget) and Settings.TargetIndicator then
        local adornee = currentTarget.Character:FindFirstChild(Settings.HitPart) or currentTarget.Character.Head
        if lib.AimTargetGui then
            lib.AimTargetGui.Adornee = adornee
            lib.AimTargetGui.Enabled = true
        end
    else
        if lib.AimTargetGui then lib.AimTargetGui.Enabled = false end
    end

    if Settings.AimMode == "Toggle" then
        if isAimKeyPressed then
            if not lib.ClickDebounce then
                lib.ClickDebounce = true
                if lib.LockedTarget then
                    lib.LockedTarget = nil
                else
                    lib.LockedTarget = currentTarget
                end
            end
        else
            lib.ClickDebounce = false
        end
    else
        if isAimKeyPressed then
            if not (Settings.TargetLock and lib.LockedTarget and lib.IsValid(lib.LockedTarget)) then
                lib.LockedTarget = currentTarget
            end
        else
            lib.LockedTarget = nil
        end
    end

    local activeTarget = lib.LockedTarget
    if Settings.AimMode == "Hold" and not activeTarget then
        activeTarget = currentTarget
    end

    if activeTarget and lib.IsValid(activeTarget) then
        local targetPart = activeTarget.Character:FindFirstChild(Settings.HitPart) or activeTarget.Character.Head
        if Settings.AimMode == "Toggle" or isAimKeyPressed then
            if Settings.AimType == "Bypass" or Settings.AimType == "Classic" then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
            end
            root.CFrame = CFrame.new(
                root.Position,
                Vector3.new(targetPart.Position.X, root.Position.Y, targetPart.Position.Z)
            )
        end
    else
        if Settings.AimMode == "Toggle" then
            lib.LockedTarget = nil
        end
    end
end

return M
