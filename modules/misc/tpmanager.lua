--[[
    AbaudnoClient — Teleport Manager Module
    Misc: управление сохраненными точками телепортации.
]]

local lib = _G.AbaudnoClient or loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/modules/lib/shared.lua"))()

local Settings = lib.Settings
local RunService = lib.RunService

local M = {}

local TpPoints = {}
local TpVisuals = {}
local CurrentTpIndex = 1
local LastTpTime = 0

function M.toggle()
    Settings.TpManagerActive = not Settings.TpManagerActive
    return Settings.TpManagerActive
end

function M.addPoint()
    local char, root, hum = lib.GetCharParts()
    if not root then return end

    local point = root.CFrame
    table.insert(TpPoints, point)

    -- Visual indicator
    local part = Instance.new("Part")
    part.Shape = Enum.PartType.Ball
    part.Size = Vector3.new(2, 2, 2)
    part.Position = point.Position
    part.Anchored = true
    part.CanCollide = false
    part.Material = Enum.Material.Neon
    part.BrickColor = BrickColor.new("Bright purple")
    part.Parent = Workspace

    table.insert(TpVisuals, part)
end

function M.removePoint(index)
    if TpPoints[index] then
        table.remove(TpPoints, index)
    end
    if TpVisuals[index] then
        TpVisuals[index]:Destroy()
        table.remove(TpVisuals, index)
    end
end

function M.renderStepped()
    if not Settings.TpManagerActive then return end
    if #TpPoints == 0 then return end

    local char, root, hum = lib.GetCharParts()
    if not root then return end

    local now = tick()
    if now - LastTpTime < Settings.TpManagerInterval then return end

    local targetPoint = TpPoints[CurrentTpIndex]
    if targetPoint then
        root.CFrame = targetPoint
        CurrentTpIndex = CurrentTpIndex + 1
        if CurrentTpIndex > #TpPoints then
            CurrentTpIndex = 1
        end
        LastTpTime = now
    end
end

function M.clearPoints()
    for _, v in pairs(TpVisuals) do
        v:Destroy()
    end
    TpPoints = {}
    TpVisuals = {}
    CurrentTpIndex = 1
end

return M