--[[
TheNexusAvenger

Manages the weapon state for firing and reloading.
--]]
--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local VibrationMotor = require(script.Parent:WaitForChild("Common"):WaitForChild("VibrationMotor"))
local BaseInput = require(script.Parent:WaitForChild("Input"):WaitForChild("BaseInput"))
local Types = require(script.Parent.Parent.Parent:WaitForChild("Types"))

local WeaponState = {}
WeaponState.__index = WeaponState

export type WeaponState = {
    Firing: boolean,
    LastFireTime: number,
    Input: BaseInput.BaseInput,
    Motors: {VibrationMotor.VibrationMotor},
    Configuration: Types.StandardConfiguration,
    Tool: Instance,
    Handle: BasePart,
    StartAttachment: Attachment,
    ReloadingValue: BoolValue,
    RemainingRoundsValue: IntValue,
    ChargedPercentValue: NumberValue?,
    ProjectileReplication: any,

    new: (Tool: Instance, Input: BaseInput.BaseInput) -> (WeaponState),
    GetAim: (self: WeaponState) -> (Vector3),
    AddVibrationMotor: (self: WeaponState, Motor: VibrationMotor.VibrationMotor) -> (),
    Reload: (self: WeaponState) -> (),
    TryFire: (self: WeaponState) -> (),
    Fire: (self: WeaponState) -> (),
    StopFiring: (self: WeaponState) -> (),
}



--[[
Creates a weapon state.
--]]
function WeaponState.new(Tool: Instance, Input: BaseInput.BaseInput): WeaponState
    local Handle = Tool:WaitForChild("Handle") :: BasePart
    local State = Tool:WaitForChild("State")
    return (setmetatable({
        Firing = false,
        LastFireTime = 0,
        Input = Input,
        Motors = {},
        Configuration = require(Tool:WaitForChild("Configuration")),
        Tool = Tool,
        Handle = Handle,
        StartAttachment = Handle:WaitForChild("StartAttachment") :: Attachment,
        ReloadingValue = State:WaitForChild("Reloading"),
        RemainingRoundsValue = State:WaitForChild("RemainingRounds"),
        ChargedPercentValue = State:FindFirstChild("ChargedPercent") :: NumberValue,
        --ProjectileReplication is stored internally to prevent a cyclic require.
        ProjectileReplication = require(script.Parent.Parent.Parent) :: any,
    }, WeaponState) :: any) :: WeaponState
end

--[[
Returns the current aim position.
--]]
function WeaponState:GetAim(): Vector3
    if UserInputService.VREnabled then
        return ((self.StartAttachment :: Attachment).WorldCFrame * CFrame.new(0, 0, -10000)).Position
    end
    return self.Input:GetTargetWorldSpace()
end

--[[
Adds a vibration motor to the state.
--]]
function WeaponState:AddVibrationMotor(Motor: VibrationMotor.VibrationMotor): ()
    table.insert(self.Motors, Motor)
end

--[[
Tries to reload the weapon.
--]]
function WeaponState:Reload(): ()
    if self.ReloadingValue.Value then return end
    self.ReloadingValue.Value = true
    self.ProjectileReplication:Reload(Players.LocalPlayer, self.Tool)
end

--[[
Tries to fire the weapon once.
--]]
function WeaponState:TryFire(): ()
    --Return if there are no rounds or the last fire was too recent.
    if self.ReloadingValue.Value then return end
    if self.RemainingRoundsValue.Value <= 0 then
        self:Reload()
        return
    end
    if tick() - self.LastFireTime < self.Configuration.CooldownTime then return end

    --Fire the weapon.
    self.LastFireTime = tick()
    self.RemainingRoundsValue.Value = self.RemainingRoundsValue.Value - 1
    for _ = 1, self.Configuration.ProjectilesPerRound or 1 do
        self.ProjectileReplication:Fire(CFrame.new(self.StartAttachment.WorldPosition, self:GetAim()) * CFrame.Angles(0, 0, math.random() * math.pi * 2) * CFrame.Angles(math.random() * self.Configuration.ProjectileSpread, 0, 0), self.Handle, self.Configuration.ProjectilePreset)
    end
    for _, Motor in self.Motors do
        Motor:Activate(self.Configuration.GamepadVibrationMotorDuration or 1, self.Configuration.GamepadVibrationMotorIntesity or 1)
    end
end

--[[
Fires the weapon.
For automatic weapons, this method will run until the firing is stopped.
--]]
function WeaponState:Fire(): ()
    self.Firing = true
    if self.Configuration.FullAutomatic then
        if self.ChargedPercentValue then
            while self.ChargedPercentValue.Value < 1 do
                task.wait()
            end
        end
        while self.Firing and (not self.ChargedPercentValue or self.ChargedPercentValue.Value >= 1) do
            self:TryFire()
            task.wait(self.Configuration.CooldownTime)
        end
    else
        self:TryFire()
    end
    self.Firing = false
end

--[[
Stops firing the weapon, if it is being fired.
--]]
function WeaponState:StopFiring(): ()
    self.Firing = false
end



return (WeaponState :: any) :: WeaponState