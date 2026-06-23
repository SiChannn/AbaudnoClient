--[[
    AbaudnoClient — Chat Spam Module
    Misc: отправка массовых сообщений.
]]

local lib = _G.AbaudnoClient or loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/modules/lib/shared.lua"))()

local Settings = lib.Settings
local UserInputService = lib.UserInputService
local StarterGui = lib.StarterGui

local M = {}

function M.toggle()
    Settings.ChatSpam = not Settings.ChatSpam
    return Settings.ChatSpam
end

function M.sendMessage(msg)
    if not msg then return end
    StarterGui:SetCore("SendNotification", {Title = "Spam", Text = msg, Duration = 2})
end

return M