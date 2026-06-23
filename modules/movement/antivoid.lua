--[[
    AbaudnoClient — Anti-Void Security Module
    Movement: защита от падения в бездну.
]]

local lib = _G.AbaudnoClient or loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/modules/lib/shared.lua"))()

local Settings = lib.Settings

local M = {}

function M.toggle()
    Settings.AntiVoid = not Settings.AntiVoid
    return Settings.AntiVoid
end

function M.renderStepped(root)
    if not Settings.AntiVoid then return end
    if not root then return end

    if root.Position.Y < Settings.AntiVoidHeight then
        root.Velocity = Vector3.new(root.Velocity.X, 65, root.Velocity.Z)
    end
end

return M
