--[[
TheNexusAvenger

Handles inputs for touch displays.
TODO: Not a great design, but does allow for holding down.
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
    --TODO: Improve default design
    --Create the buttons.
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "StandardWeaponMobileInput"
    ScreenGui.DisplayOrder = 100
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

    local LeftFireButton = Instance.new("TextButton")
    LeftFireButton.BackgroundTransparency = 0.5
    LeftFireButton.AnchorPoint = Vector2.new(0, 1)
    LeftFireButton.Size = UDim2.new(0.2, 0, 0.2, 0)
    LeftFireButton.Position = UDim2.new(0.2, 0, 0.95, 0)
    LeftFireButton.SizeConstraint = Enum.SizeConstraint.RelativeYY
    LeftFireButton.Text = "Fire"
    LeftFireButton.TextScaled = true
    LeftFireButton.Parent = ScreenGui

    local RightFireButton = Instance.new("TextButton")
    RightFireButton.BackgroundTransparency = 0.5
    RightFireButton.AnchorPoint = Vector2.new(1, 1)
    RightFireButton.Size = UDim2.new(0.2, 0, 0.2, 0)
    RightFireButton.Position = UDim2.new(0.8, 0, 0.95, 0)
    RightFireButton.SizeConstraint = Enum.SizeConstraint.RelativeYY
    RightFireButton.Text = "Fire"
    RightFireButton.TextScaled = true
    RightFireButton.Parent = ScreenGui

    local RightReloadButton = Instance.new("TextButton")
    RightReloadButton.BackgroundTransparency = 0.5
    RightReloadButton.AnchorPoint = Vector2.new(1, 1)
    RightReloadButton.Size = UDim2.new(0.2, 0, 0.2, 0)
    RightReloadButton.Position = UDim2.new(0.9, 0, 0.65, 0)
    RightReloadButton.SizeConstraint = Enum.SizeConstraint.RelativeYY
    RightReloadButton.Text = "Reload"
    RightReloadButton.TextScaled = true
    RightReloadButton.Parent = ScreenGui

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