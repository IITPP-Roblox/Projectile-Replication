--[[
TheNexusAvenger

Handles the weapon on the server.
--]]

local TweenService = game:GetService("TweenService")

local Tool = script.Parent
local Handle = Tool:WaitForChild("Handle")
local ChargeMotor = Handle:WaitForChild("ChargeMotor")
local ChargeAttachment = Handle:WaitForChild("ChargeAttachment")
local ChargeDownSound = ChargeAttachment:WaitForChild("ChargeDown")
local ChargeUpSound = ChargeAttachment:WaitForChild("ChargeUp")
local ChargeLoopSound = ChargeAttachment:WaitForChild("ChargeLoop")
local Configuration = require(Tool:WaitForChild("Configuration"))

local ProjectileReplicationModule = Tool:WaitForChild("ProjectileReplicationReference").Value
while not ProjectileReplicationModule do ProjectileReplicationModule = Tool:WaitForChild("ProjectileReplicationReference").Value task.wait() end
local LocalTween = require(ProjectileReplicationModule:WaitForChild("LocalTween"))

local State = Tool:WaitForChild("State")
local ChargedPercentValue = State:WaitForChild("ChargedPercent")
local ReloadingValue = State:WaitForChild("Reloading")

local Equipped = false
local CurrentTween = nil



--[[
Starts charging up the weapon.
--]]
local function ChargeUp(): ()
    --Calculate the times.
    local ChargeElapsedTime = ChargedPercentValue.Value * Configuration.ChargeUpTime
    local ChargeRemainingTime = Configuration.ChargeUpTime - ChargeElapsedTime

    --Change the values.
    local Tween = TweenInfo.new(ChargeRemainingTime, Enum.EasingStyle.Linear)
    CurrentTween = TweenService:Create(ChargedPercentValue, Tween, {
        Value = 1,
    })
    CurrentTween:Play()
    LocalTween:Play(ChargeMotor, Tween, {
        MaxVelocity = Configuration.ChargeMaxMotorSpeed,
    })
    ChargeUpSound.TimePosition = ChargeElapsedTime
    ChargeUpSound:Play()
    ChargeDownSound:Stop()
end

--[[
Starts charging down the weapon.
--]]
local function ChargeDown(): ()
    --Calculate the times.
    local ChargeRemainingTime = ChargedPercentValue.Value * Configuration.ChargeDownTime
    local ChargeElapsedTime = Configuration.ChargeDownTime - ChargeRemainingTime

    --Change the values.
    local Tween = TweenInfo.new(ChargeRemainingTime, Enum.EasingStyle.Linear)
    CurrentTween = TweenService:Create(ChargedPercentValue, Tween, {
        Value = 0,
    })
    CurrentTween:Play()
    LocalTween:Play(ChargeMotor, Tween, {
        MaxVelocity = 0,
    })
    ChargeDownSound.TimePosition = ChargeElapsedTime
    ChargeUpSound:Stop()
    ChargeDownSound:Play()
end



--Connect the events.
Tool.Equipped:Connect(function()
    Equipped = true
end)

Tool.Unequipped:Connect(function()
    Equipped = false
    if CurrentTween then
        --Workaround for tweens continueing on client.
        LocalTween:Play(ChargeMotor, TweenInfo.new(0), {
            MaxVelocity = 0,
        })
        CurrentTween:Cancel()
    end
    ChargedPercentValue.Value = 0
    ChargeMotor.MaxVelocity = 0
    ChargeUpSound:Stop()
    ChargeDownSound:Stop()
end)

ReloadingValue.Changed:Connect(function()
    if not ReloadingValue.Value then return end
    ChargeDown()
end)

ChargedPercentValue.Changed:Connect(function()
    if ChargedPercentValue.Value >= 1 then
        if not ChargeLoopSound.Playing then
            ChargeLoopSound:Play()
        end
    else
        if ChargeLoopSound.Playing then
            ChargeLoopSound:Stop()
        end
    end
end)

Tool.Activated:Connect(function()
    if not Equipped then return end
    ChargeUp()
end)
Tool.Deactivated:Connect(ChargeDown)