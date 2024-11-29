--Weapon crosshair used with a mouse or other pointing devices.
--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local BaseCrosshair = require(script.Parent:WaitForChild("BaseCrosshair"))

local MouseCrosshair = {}
MouseCrosshair.__index = MouseCrosshair
setmetatable(MouseCrosshair, BaseCrosshair)

export type MouseCrosshair = {
    CrossFrame: Frame,
} & typeof(setmetatable({}, MouseCrosshair)) & BaseCrosshair.BaseCrosshair



--[[
Creates a mouse crosshair.
--]]
function MouseCrosshair.new(): MouseCrosshair
    local self = setmetatable(BaseCrosshair.new(), MouseCrosshair) :: MouseCrosshair
    UserInputService.MouseIconEnabled = false

    --Create the crosshair.
    local CrosshairGui = Instance.new("ScreenGui")
    CrosshairGui.Name = "CrossHairGui"
    CrosshairGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    self.CrosshairGui = CrosshairGui

    local CrossFrame = Instance.new("Frame")
    CrossFrame.Name = "Crosshair"
    CrossFrame.BackgroundTransparency = 1
    CrossFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    CrossFrame.Size = UDim2.new(0.075, 0, 0.075, 0)
    CrossFrame.SizeConstraint = Enum.SizeConstraint.RelativeYY
    CrossFrame.Parent = CrosshairGui
    self.CrossFrame = CrossFrame

    local CrosshairTop = Instance.new("Frame")
    CrosshairTop.Name = "CrosshairTop"
    CrosshairTop.BackgroundColor3 = Color3.new(1, 1, 1)
    CrosshairTop.BorderColor3 = Color3.new(0, 0, 0)
    CrosshairTop.Size = UDim2.new(0, 2, 0.3, 0)
    CrosshairTop.Position = UDim2.new(0.5, 0, 0, 0)
    CrosshairTop.AnchorPoint = Vector2.new(0.5, 0)
    CrosshairTop.Parent = CrossFrame

    local CrosshairBottom = Instance.new("Frame")
    CrosshairBottom.Name = "CrosshairBottom"
    CrosshairBottom.BackgroundColor3 = Color3.new(1, 1, 1)
    CrosshairBottom.BorderColor3 = Color3.new(0, 0, 0)
    CrosshairBottom.Size = UDim2.new(0, 2, 0.3, 0)
    CrosshairBottom.Position = UDim2.new(0.5, 0, 1, 0)
    CrosshairBottom.AnchorPoint = Vector2.new(0.5, 1)
    CrosshairBottom.Parent = CrossFrame

    local CrosshairLeft = Instance.new("Frame")
    CrosshairLeft.Name = "CrosshairLeft"
    CrosshairLeft.BackgroundColor3 = Color3.new(1, 1, 1)
    CrosshairLeft.BorderColor3 = Color3.new(0, 0, 0)
    CrosshairLeft.Size = UDim2.new(0.3, 0, 0, 2)
    CrosshairLeft.Position = UDim2.new(0, 0, 0.5, 0)
    CrosshairLeft.AnchorPoint = Vector2.new(0, 0.5)
    CrosshairLeft.Parent = CrossFrame

    local CrosshairRight = Instance.new("Frame")
    CrosshairRight.Name = "CrosshairRight"
    CrosshairRight.BackgroundColor3 = Color3.new(1, 1, 1)
    CrosshairRight.BorderColor3 = Color3.new(0, 0, 0)
    CrosshairRight.Size = UDim2.new(0.3, 0, 0, 2)
    CrosshairRight.Position = UDim2.new(1, 0, 0.5, 0)
    CrosshairRight.AnchorPoint = Vector2.new(1, 0.5)
    CrosshairRight.Parent = CrossFrame

    local AmmoText = Instance.new("TextLabel")
    AmmoText.Name = "AmmoText"
    AmmoText.BackgroundTransparency = 1
    AmmoText.Size = UDim2.new(5, 0, 0.4, 0)
    AmmoText.Position = UDim2.new(0.7, 2, 0.55, 2)
    AmmoText.Font = Enum.Font.SciFi
    AmmoText.TextColor3 = Color3.new(1, 1, 1)
    AmmoText.TextStrokeColor3 = Color3.new(0, 0, 0)
    AmmoText.TextStrokeTransparency = 0
    AmmoText.TextScaled = true
    AmmoText.Text = ""
    AmmoText.TextXAlignment = Enum.TextXAlignment.Left
    AmmoText.Parent = CrossFrame
    self.AmmoText = AmmoText

    local ReloadingText = Instance.new("TextLabel")
    ReloadingText.Name = "ReloadingText"
    ReloadingText.BackgroundTransparency = 1
    ReloadingText.Size = UDim2.new(5, 0, 0.3, 0)
    ReloadingText.Position = UDim2.new(0.8, 2, 0.9, 2)
    ReloadingText.Visible = false
    ReloadingText.Font = Enum.Font.SciFi
    ReloadingText.TextColor3 = Color3.new(1, 1, 1)
    ReloadingText.TextStrokeColor3 = Color3.new(0, 0, 0)
    ReloadingText.TextStrokeTransparency = 0
    ReloadingText.TextScaled = true
    ReloadingText.TextXAlignment = Enum.TextXAlignment.Left
    ReloadingText.Text = "Reloading"
    ReloadingText.Parent = CrossFrame
    self.ReloadingText = ReloadingText
    return self
end

--[[
Moves the crosshair to a given screen position.
--]]
function MouseCrosshair.MoveTo(self: MouseCrosshair, Positon: Vector2): ()
    self.CrossFrame.Position = UDim2.new(0, Positon.X, 0, Positon.Y)
end

--[[
Destroys the crosshair.
--]]
function MouseCrosshair.Destroy(self: MouseCrosshair): ()
    BaseCrosshair.Destroy(self)
    UserInputService.MouseIconEnabled = true
end



return MouseCrosshair