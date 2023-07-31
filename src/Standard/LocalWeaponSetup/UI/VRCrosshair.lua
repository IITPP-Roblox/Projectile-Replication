--[[
TheNexusAvenger

Weapon crosshair (ammo display) used in VR.
--]]
--!strict

local BaseCrosshair = require(script.Parent:WaitForChild("BaseCrosshair"))

local VRCrosshair = {}
VRCrosshair.__index = VRCrosshair
setmetatable(VRCrosshair, BaseCrosshair)

export type VRCrosshair = {
    new: (Attachment: Attachment, Offset: Vector3?) -> (VRCrosshair),
} & BaseCrosshair.BaseCrosshair



--[[
Creates a VR crosshair.
--]]
function VRCrosshair.new(Attachment: Attachment, Offset: Vector3?): VRCrosshair
    local self = (setmetatable(BaseCrosshair.new(), VRCrosshair) :: any) :: VRCrosshair

    --Create the ammo display.
    local CrosshairGui = Instance.new("BillboardGui")
    CrosshairGui.Name = "WeaponCrosshair"
    CrosshairGui.StudsOffsetWorldSpace = Offset or Vector3.new(-1.2, 0, 0)
    CrosshairGui.Size = UDim2.new(3, 0, 0.75, 0)
    CrosshairGui.Adornee = Attachment
    CrosshairGui.Parent = Attachment
    self.CrosshairGui = CrosshairGui

    local AmmoText = Instance.new("TextLabel")
    AmmoText.Name = "AmmoText"
    AmmoText.BackgroundTransparency = 1
    AmmoText.Size = UDim2.new(1, 0, 0.7, 0)
    AmmoText.Position = UDim2.new(0, 0, 0, 0)
    AmmoText.Font = Enum.Font.SciFi
    AmmoText.TextColor3 = Color3.new(1, 1, 1)
    AmmoText.TextStrokeColor3 = Color3.new(0, 0, 0)
    AmmoText.TextStrokeTransparency = 0
    AmmoText.TextScaled = true
    AmmoText.TextXAlignment = Enum.TextXAlignment.Center
    AmmoText.Text = ""
    AmmoText.Parent = CrosshairGui
    self.AmmoText = AmmoText

    local ReloadingText = Instance.new("TextLabel")
    ReloadingText.Name = "ReloadingText"
    ReloadingText.BackgroundTransparency = 1
    ReloadingText.Size = UDim2.new(1, 0, 0.35, 0)
    ReloadingText.Position = UDim2.new(0, 0, 0.65, 0)
    ReloadingText.Visible = false
    ReloadingText.Font = Enum.Font.SciFi
    ReloadingText.TextColor3 = Color3.new(1, 1, 1)
    ReloadingText.TextStrokeColor3 = Color3.new(0, 0, 0)
    ReloadingText.TextStrokeTransparency = 0
    ReloadingText.TextScaled = true
    ReloadingText.TextXAlignment = Enum.TextXAlignment.Center
    ReloadingText.Text = "Reloading"
    ReloadingText.Parent = CrosshairGui
    self.ReloadingText = ReloadingText
    return self
end



return (VRCrosshair :: any) :: VRCrosshair