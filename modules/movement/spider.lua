--[[
    AbaudnoClient — Spider Module
    Movement: лазание по стенам.
]]

local lib = _G.AbaudnoClient or loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/modules/lib/shared.lua"))()

local Settings = lib.Settings
local Workspace = lib.Workspace

local M = {}

function M.toggle()
    Settings.SpiderActive = not Settings.SpiderActive
    return Settings.SpiderActive
end

function M.renderStepped(char, root, hum)
    if not Settings.SpiderActive then return end
    if not char or not root or not hum then return end

    if hum.MoveDirection.Magnitude > 0 then
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = { char }
        local wallRay = Workspace:Raycast(root.Position, hum.MoveDirection * 2.5, raycastParams)
        if wallRay and math.abs(wallRay.Normal.Y) < 0.1 then
            root.AssemblyLinearVelocity = Vector3.new(
                root.AssemblyLinearVelocity.X,
                Settings.SpiderSpeed,
                root.AssemblyLinearVelocity.Z
            )
        end
    end
end

return M
