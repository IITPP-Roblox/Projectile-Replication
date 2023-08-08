--[[
TheNexusAvenger

Handles inputs for touch displays.
--]]
--!strict

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local BaseInput = require(script.Parent:WaitForChild("BaseInput"))

local TouchInput = {}
TouchInput.__index = TouchInput
setmetatable(TouchInput, BaseInput)

export type TouchInputDisplay = {
    FireButtons: {GuiButton},
    ReloadButtons: {GuiButton},
    Destroy: (self: TouchInputDisplay) -> (),
}
export type TouchInput = {
    CreateDisplay: () -> (TouchInputDisplay),

    Display: TouchInputDisplay?,
    new: () -> (TouchInput)
} & BaseInput.BaseInput



--[[
Creates the button display.
--]]
function TouchInput.CreateDisplay(): TouchInputDisplay
    --Create the buttons.
    --TODO: Add icons
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "StandardWeaponMobileInput"
    ScreenGui.DisplayOrder = 100
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

    local LeftFireButton = Instance.new("ImageButton")
    LeftFireButton.BackgroundTransparency = 1
    LeftFireButton.AnchorPoint = Vector2.new(0, 1)
    LeftFireButton.SizeConstraint = Enum.SizeConstraint.RelativeYY
    LeftFireButton.Image = "rbxasset://textures/ui/Input/TouchControlsSheetV2.png"
    LeftFireButton.ImageColor3 = Color3.fromRGB(0, 0, 0)
    LeftFireButton.ImageRectOffset = Vector2.new(1, 1)
    LeftFireButton.ImageRectSize = Vector2.new(144, 144)
    LeftFireButton.Parent = ScreenGui

    local RightFireButton = Instance.new("ImageButton")
    RightFireButton.BackgroundTransparency = 1
    RightFireButton.AnchorPoint = Vector2.new(1, 1)
    RightFireButton.SizeConstraint = Enum.SizeConstraint.RelativeYY
    RightFireButton.Image = "rbxasset://textures/ui/Input/TouchControlsSheetV2.png"
    RightFireButton.ImageColor3 = Color3.fromRGB(0, 0, 0)
    RightFireButton.ImageRectOffset = Vector2.new(1, 1)
    RightFireButton.ImageRectSize = Vector2.new(144, 144)
    RightFireButton.Parent = ScreenGui

    local RightReloadButton = Instance.new("ImageButton")
    RightReloadButton.BackgroundTransparency = 1
    RightReloadButton.AnchorPoint = Vector2.new(1, 1)
    RightReloadButton.SizeConstraint = Enum.SizeConstraint.RelativeYY
    RightReloadButton.Image = "rbxasset://textures/ui/Input/TouchControlsSheetV2.png"
    RightReloadButton.ImageColor3 = Color3.fromRGB(0, 0, 0)
    RightReloadButton.ImageRectOffset = Vector2.new(1, 1)
    RightReloadButton.ImageRectSize = Vector2.new(144, 144)
    RightReloadButton.Parent = ScreenGui

    --Set up the button effects.
    for _, Button in {LeftFireButton, RightFireButton, RightReloadButton} do
        Button.MouseButton1Down:Connect(function()
            Button.ImageColor3 = Color3.fromRGB(128, 128, 128)
        end)
        Button.MouseButton1Up:Connect(function()
            Button.ImageColor3 = Color3.fromRGB(0, 0, 0)
        end)
        Button.MouseLeave:Connect(function()
            Button.ImageColor3 = Color3.fromRGB(0, 0, 0)
        end)
    end

    --[[
    Updates the buttons.
    --]]
    local function UpdateButtons(): ()
        local ViewSize = ScreenGui.AbsoluteSize
        local IsSmallScreen = (math.min(ViewSize.X, ViewSize.Y) <= 500)

        --Update the button sizes.
        local FireButtonSize = (IsSmallScreen and 70 or 120)
        LeftFireButton.Size = UDim2.new(0, FireButtonSize, 0, FireButtonSize)
        RightFireButton.Size = UDim2.new(0, FireButtonSize, 0, FireButtonSize)
        RightReloadButton.Size = UDim2.new(0, FireButtonSize * 0.8, 0, FireButtonSize * 0.8)

        --Update the button positions.
        if ViewSize.X > ViewSize.Y then
            local FireButtonBottomOffset = (IsSmallScreen and -10 or (-FireButtonSize * 0.5))
            LeftFireButton.Position = UDim2.new(0, FireButtonSize * 2, 1, FireButtonBottomOffset)
            RightFireButton.Position = UDim2.new(1, (-FireButtonSize * 1.5) - 10, 1, FireButtonBottomOffset)
            RightReloadButton.Position = UDim2.new(1, -(FireButtonSize * 0.4), 1, (IsSmallScreen and -((FireButtonSize * 1.5) + 10) or -FireButtonSize * 1.85))
            LeftFireButton.Visible = true
        else
            local FireButtonSideOffset = -(FireButtonSize * 0.3)
            local FireButtonBottomOffset = (IsSmallScreen and -20 or (-FireButtonSize * 0.75)) - (1.1 * FireButtonSize)
            RightFireButton.Position = UDim2.new(1, FireButtonSideOffset, 1, FireButtonBottomOffset)
            RightReloadButton.Position = UDim2.new(1, FireButtonSideOffset, 1, FireButtonBottomOffset - (1.1 * FireButtonSize))
            LeftFireButton.Visible = false
        end
    end
    
    --Update the buttons.
    UpdateButtons()
    ScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateButtons)

    --Return the object.
    return {
        FireButtons = {LeftFireButton, RightFireButton},
        ReloadButtons = {RightReloadButton},
        Destroy = function(self)
            ScreenGui:Destroy()
        end,
    }
end

--[[
Creates a touch input.
--]]
function TouchInput.new(): TouchInput
    local self = (BaseInput.new() :: any) :: TouchInput
    setmetatable(self, TouchInput)

    --Create the user interface for mobile.
    if UserInputService.TouchEnabled then
        --Create the display.
        local Display = TouchInput.CreateDisplay()
        self.Display = Display

        --Connect the fire buttons.
        local TotalInputsDown = 0
        for _, FireButton in Display.FireButtons do
            local ButtonDown = false
            FireButton.MouseButton1Down:Connect(function()
                if ButtonDown then return end
                ButtonDown = true
                TotalInputsDown += 1

                if TotalInputsDown ~= 1 then return end
                self.StartFire:Fire()
            end)
            FireButton.MouseButton1Up:Connect(function()
                if not ButtonDown then return end
                ButtonDown = false
                TotalInputsDown += -1
                
                if TotalInputsDown ~= 0 then return end
                self.EndFire:Fire()
            end)
            FireButton.MouseLeave:Connect(function()
                if not ButtonDown then return end
                ButtonDown = false
                TotalInputsDown += -1
                
                if TotalInputsDown ~= 0 then return end
                self.EndFire:Fire()
            end)
        end

        --Connect the reload buttons.
        for _, ReloadButton in Display.ReloadButtons do
            ReloadButton.MouseButton1Down:Connect(function()
                self.Reload:Fire()
            end)
        end
    end

    return self
end

--[[
Returns if the input is a priority for the combined input.
--]]
function TouchInput:IsPriority(): boolean
    return UserInputService:GetLastInputType() == Enum.UserInputType.Touch
end

--[[
Returns the aiming location for the input in screen space.
--]]
function TouchInput:GetTargetScreenSpace(): Vector2
    local Camera = Workspace.CurrentCamera
    local ScreenSize = Camera.ViewportSize - GuiService:GetGuiInset()
    local Character = Players.LocalPlayer.Character :: Model
    if Character then
        local Head = Character:FindFirstChild("Head") :: BasePart
        if Head and (Head.Position - Camera.CFrame.Position).Magnitude < 2 then
            return Vector2.new(ScreenSize.X / 2, ScreenSize.Y / 2)
        end
    end
    return Vector2.new((ScreenSize.X / 2) + (0.1 * math.min(ScreenSize.X, ScreenSize.Y)), ScreenSize.Y / 2)
end

--[[
Destroys the input.
--]]
function TouchInput:Destroy(): ()
    BaseInput.Destroy(self)

    local Display = (self :: TouchInput).Display
    if Display then
        Display:Destroy()
    end
end



return (TouchInput :: any) :: TouchInput