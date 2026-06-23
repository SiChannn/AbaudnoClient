--[[
    AbaudnoClient — Spinner Module
    Misc: вращение камеры вокруг персонажа.
]]

local lib = _G.AbaudnoClient or loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/modules/lib/shared.lua"))()

local Settings = lib.Settings
local RunService = lib.RunService

local M = {}

local Spinning = false
local Angle = 0

function M.toggle()
    Settings.SpinnerActive = not Settings.SpinnerActive
    Spinning = Settings.SpinnerActive
    return Settings.SpinnerActive
end

function M.renderStepped()
    if not Settings.SpinnerActive then
        Spinning = false
        return
    end

    if not Spinning then return end

    local char, root, hum = lib.GetCharParts()
    if not char then return end

    Angle = Angle + Settings.SpinnerSpeed * RunService.RenderStepped:Wait()
    if Angle >= 360 then Angle = Angle - 360 end

    local camera = Workspace.CurrentCamera
    local distance = 10
    local height = 5
    local angleRad = math.rad(Angle)

    local offset = Vector3.new(
        math.cos(angleRad) * distance,
        height,
        math.sin(angleRad) * distance
    )

    camera.CFrame = CFrame.new(root.Position + offset, root.Position)
end

return M