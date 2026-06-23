--[[
    AbaudnoClient — Jump Power Boost Module
    Movement: увеличение силы прыжка.
]]

local lib = _G.AbaudnoClient or loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/modules/lib/shared.lua"))()

local Settings = lib.Settings

local M = {}

function M.toggle()
    Settings.JumpActive = not Settings.JumpActive
    return Settings.JumpActive
end

function M.renderStepped(hum)
    if not hum then return end
    if Settings.JumpActive then
        hum.JumpPower = Settings.BoostJump
        hum.UseJumpPower = true
    else
        hum.JumpPower = 50
    end
end

return M
