--[[
    AbaudnoClient — NoClip Module
    Misc: отключение коллизий игрока для прохода сквозь стены.
]]

local lib = _G.AbaudnoClient or loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/modules/lib/shared.lua"))()

local Settings = lib.Settings
local RunService = lib.RunService

local M = {}

function M.toggle()
    Settings.NoClipActive = not Settings.NoClipActive
    return Settings.NoClipActive
end

function M.renderStepped()
    if not Settings.NoClipActive then return end

    local char, root, hum = lib.GetCharParts()
    if not char then return end

    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

return M
