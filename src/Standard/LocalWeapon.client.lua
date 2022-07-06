--[[
TheNexusAvenger

Runs the weapon on the client.
--]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Tool = script.Parent
local ProjectileReplicationModule = Tool:WaitForChild("ProjectileReplicationReference").Value
while not ProjectileReplicationModule do ProjectileReplicationModule = Tool:WaitForChild("ProjectileReplicationReference").Value task.wait() end
local Projectile = require(ProjectileReplicationModule:WaitForChild("Projectile"))
local ProjectileReplication = require(ProjectileReplicationModule)

local Camera = Workspace.CurrentCamera
local Handle = Tool:WaitForChild("Handle")
local StartAttachment = Handle:WaitForChild("StartAttachment")
local Configuration = require(Tool:WaitForChild("Configuration"))

local State = Tool:WaitForChild("State")
local ChargedPercentValue = State:FindFirstChild("ChargedPercent")
local RemainingRounds = State:WaitForChild("RemainingRounds")
local ReloadingValue = State:WaitForChild("Reloading")


local CurrentMouse: Mouse? = nil
local LastFireTime = 0
local Equipped = false
local Firing = false



--[[
Converts a number of projectiles to a display number.
--]]
local function GetDisplayProjectiles(Projectiles: number): string
    return tostring(math.floor(Projectiles / (Configuration.ProjectilesPerRound or 1)))
end

--[[
Returns the current mouse position using the same raycasting
logic used by the projectiles.
--]]
local function GetMousePosition(): Vector3
    local CameraRay = Camera:ScreenPointToRay(CurrentMouse.X, CurrentMouse.Y, 10000)
    local _, EndPosition = Projectile.RayCast(Camera.CFrame.Position, CameraRay.Origin + CameraRay.Direction, {Players.LocalPlayer.Character, Camera})
    return EndPosition
end

--[[
Fires the weapon.
--]]
local function Fire(): nil
    if not Equipped or not CurrentMouse then return end
    for _ = 1, Configuration.ProjectilesPerRound or 1 do
        ProjectileReplication:Fire(CFrame.new(StartAttachment.WorldPosition, GetMousePosition()) * CFrame.Angles(0, 0, math.random() * math.pi * 2) * CFrame.Angles(math.random() * Configuration.ProjectileSpread, 0, 0), Handle, Configuration.ProjectilePreset)
    end
end

--[[
Tries to reload the weapon.
--]]
local function TryReload(): nil
    if ReloadingValue.Value then return end
    ReloadingValue.Value = true
    ProjectileReplication:Reload(Players.LocalPlayer, Tool)
end

--[[
Tries to fire the weapon.
--]]
local function TryFire(): nil
    --Return if there are no rounds or the last fire was too recent.
    if ReloadingValue.Value then return end
    if RemainingRounds.Value <= 0 then TryReload() return end
    if tick() - LastFireTime < Configuration.CooldownTime then return end

    --Fire the weapon.
    LastFireTime = tick()
    RemainingRounds.Value = RemainingRounds.Value - 1
    Fire()
end



--Connect equipping and unequipping the tool.
Tool.Equipped:Connect(function(Mouse: Mouse)
    Equipped = true
    CurrentMouse = Mouse
    UserInputService.MouseIconEnabled = false

    --Create the crosshair.
    local CrosshairGui = Instance.new("ScreenGui")
    CrosshairGui.Name = "CrossHairGui"
    CrosshairGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

    local CrossFrame = Instance.new("Frame")
    CrossFrame.BackgroundTransparency = 1
    CrossFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    CrossFrame.Size = UDim2.new(0.075, 0, 0.075, 0)
    CrossFrame.SizeConstraint = Enum.SizeConstraint.RelativeYY
    CrossFrame.Parent = CrosshairGui

    local CrosshairTop = Instance.new("Frame")
    CrosshairTop.BackgroundColor3 = Color3.new(1, 1, 1)
    CrosshairTop.BorderColor3 = Color3.new(0, 0, 0)
    CrosshairTop.Size = UDim2.new(0, 2, 0.3, 0)
    CrosshairTop.Position = UDim2.new(0.5, 0, 0, 0)
    CrosshairTop.AnchorPoint = Vector2.new(0.5, 0)
    CrosshairTop.Parent = CrossFrame

    local CrosshairBottom = Instance.new("Frame")
    CrosshairBottom.BackgroundColor3 = Color3.new(1, 1, 1)
    CrosshairBottom.BorderColor3 = Color3.new(0, 0, 0)
    CrosshairBottom.Size = UDim2.new(0, 2, 0.3, 0)
    CrosshairBottom.Position = UDim2.new(0.5, 0, 1, 0)
    CrosshairBottom.AnchorPoint = Vector2.new(0.5, 1)
    CrosshairBottom.Parent = CrossFrame

    local CrosshairLeft = Instance.new("Frame")
    CrosshairLeft.BackgroundColor3 = Color3.new(1, 1, 1)
    CrosshairLeft.BorderColor3 = Color3.new(0, 0, 0)
    CrosshairLeft.Size = UDim2.new(0.3, 0, 0, 2)
    CrosshairLeft.Position = UDim2.new(0, 0, 0.5, 0)
    CrosshairLeft.AnchorPoint = Vector2.new(0, 0.5)
    CrosshairLeft.Parent = CrossFrame

    local CrosshairRight = Instance.new("Frame")
    CrosshairRight.BackgroundColor3 = Color3.new(1, 1, 1)
    CrosshairRight.BorderColor3 = Color3.new(0, 0, 0)
    CrosshairRight.Size = UDim2.new(0.3, 0, 0, 2)
    CrosshairRight.Position = UDim2.new(1, 0, 0.5, 0)
    CrosshairRight.AnchorPoint = Vector2.new(1, 0.5)
    CrosshairRight.Parent = CrossFrame

    local AmmoText = Instance.new("TextLabel")
    AmmoText.BackgroundTransparency = 1
    AmmoText.Size = UDim2.new(5, 0, 0.4, 0)
    AmmoText.Position = UDim2.new(0.7, 2, 0.55, 2)
    AmmoText.Font = Enum.Font.SciFi
    AmmoText.TextColor3 = Color3.new(1, 1, 1)
    AmmoText.TextStrokeColor3 = Color3.new(0, 0, 0)
    AmmoText.TextStrokeTransparency = 0
    AmmoText.TextScaled = true
    AmmoText.TextXAlignment = Enum.TextXAlignment.Left
    AmmoText.Text = GetDisplayProjectiles(RemainingRounds.Value).." / "..GetDisplayProjectiles(Configuration.TotalRounds)
    AmmoText.Parent = CrossFrame

    local ReloadingText = Instance.new("TextLabel")
    ReloadingText.BackgroundTransparency = 1
    ReloadingText.Size = UDim2.new(5, 0, 0.3, 0)
    ReloadingText.Position = UDim2.new(0.8, 2, 0.9, 2)
    ReloadingText.Visible = ReloadingValue.Value
    ReloadingText.Font = Enum.Font.SciFi
    ReloadingText.TextColor3 = Color3.new(1, 1, 1)
    ReloadingText.TextStrokeColor3 = Color3.new(0, 0, 0)
    ReloadingText.TextStrokeTransparency = 0
    ReloadingText.TextScaled = true
    ReloadingText.TextXAlignment = Enum.TextXAlignment.Left
    ReloadingText.Text = "Reloading"
    ReloadingText.Parent = CrossFrame

    RemainingRounds.Changed:Connect(function()
        AmmoText.Text = GetDisplayProjectiles(RemainingRounds.Value).." / "..GetDisplayProjectiles(Configuration.TotalRounds)
    end)
    ReloadingValue.Changed:Connect(function()
        ReloadingText.Visible = ReloadingValue.Value
    end)

    --Update the aim.
    local Character = Tool.Parent
    if not Character then return end
    while Equipped do
        --Update the crosshair in a pcall. If the mouse becomes inactive, it throws an error.
        local CrosshairUpdated, _ = pcall(function()
            CrossFrame.Position = UDim2.new(0, Mouse.X, 0, Mouse.Y)
            ProjectileReplication:Aim(Players.LocalPlayer, GetMousePosition())
        end)
        if not CrosshairUpdated then
            break
        end
        RunService.RenderStepped:Wait()
    end

    --Destroy the crosshair.
    CrossFrame:Destroy()
end)

Tool.Unequipped:Connect(function()
    Equipped = false
    Firing = false
    UserInputService.MouseIconEnabled = true
end)

--Connect using the tool.
Tool.Activated:Connect(function()
    if not Equipped then return end
    if Configuration.FullAutomatic then
        Firing = true
        if ChargedPercentValue then
            while ChargedPercentValue.Value < 1 do
                task.wait()
            end
        end
        while Firing and (not ChargedPercentValue or ChargedPercentValue.Value >= 1) do
            TryFire()
            task.wait(Configuration.CooldownTime)
        end
    else
        TryFire()
    end
end)

Tool.Deactivated:Connect(function()
    Firing = false
end)

UserInputService.InputBegan:Connect(function(Input: InputObject, Processed: boolean)
    if Processed then return end
    if not Equipped then return end
    if Input.KeyCode ~= Enum.KeyCode.R then return end
    TryReload()
end)