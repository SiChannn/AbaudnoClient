--[[
    AbaudnoClient — Bhop Module
    Movement: bunny hop — ускорение при движении.
]]

local lib = _G.AbaudnoClient or loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/modules/lib/shared.lua"))()

local Settings = lib.Settings

local M = {}

function M.toggle()
    Settings.BhopActive = not Settings.BhopActive
    return Settings.BhopActive
end

function M.renderStepped(root, hum)
    if not root or not hum then return end
    if Settings.BhopActive and hum.MoveDirection.Magnitude > 0 and hum.FloorMaterial ~= Enum.Material.Air then
        root.Velocity = Vector3.new(
            hum.MoveDirection.X * Settings.BhopSpeed,
            35,
            hum.MoveDirection.Z * Settings.BhopSpeed
        )
    end
end

return M
