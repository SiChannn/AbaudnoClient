--[[
    AbaudnoClient — Vehicle Flight Module
    Movement: полёт на транспорте.
]]

local lib = _G.AbaudnoClient or loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/modules/lib/shared.lua"))()

local Settings = lib.Settings
local UserInputService = lib.UserInputService
local Workspace = lib.Workspace
local Camera = lib.Camera

local M = {}

function M.toggle()
    Settings.VflyActive = not Settings.VflyActive
    return Settings.VflyActive
end

function M.renderStepped(root, hum)
    if not Settings.VflyActive then return end
    if not root or not hum then return end

    local char = lib.LocalPlayer.Character
    if not char then return end

    local vehicle = lib.GetVehiclePart()
    if not vehicle then return end

    if not hum.Sit and vehicle:IsA("VehicleSeat") then
        pcall(function() vehicle:Sit(hum) end)
    end

    local model = vehicle:FindFirstAncestorOfClass("Model")
    if model then
        local mDesc = model:GetChildren()
        for i = 1, #mDesc do
            local part = mDesc[i]
            if part:IsA("BasePart") and part ~= vehicle then
                part.CanCollide = false
            end
        end
    end

    local cDesc = char:GetChildren()
    for i = 1, #cDesc do
        local part = cDesc[i]
        if part:IsA("BasePart") then part.CanCollide = false end
    end

    Camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
    lib.Camera = Camera

    local moveDir = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

    local camLook = Camera.CFrame.LookVector
    local targetRotation = CFrame.new(vehicle.Position, vehicle.Position + Vector3.new(camLook.X, camLook.Y, camLook.Z))

    pcall(function()
        vehicle.AssemblyLinearVelocity = Vector3.new(0, 0.01, 0)
        vehicle.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        if moveDir.Magnitude > 0 then
            vehicle.CFrame = targetRotation:Lerp(targetRotation + (moveDir.Unit * (Settings.VflySpeed / 60)), 0.85)
        else
            vehicle.CFrame = vehicle.CFrame:Lerp(targetRotation, 0.2)
        end
    end)
end

return M
