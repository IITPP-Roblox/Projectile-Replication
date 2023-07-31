--[[
TheNexusAvenger

Base class for a crosshair.
--]]
--!strict

local BaseCrosshair = {}
BaseCrosshair.__index = BaseCrosshair

export type BaseCrosshair = {
    CrosshairGui: Instance,
    AmmoText: TextLabel,
    ReloadingText: TextLabel,

    new: () -> (BaseCrosshair),
    SetAmmo: (self: BaseCrosshair, CurrentAmmo: number, MaxAmmo: number) -> (),
    SetReloading: (self: BaseCrosshair, Reloading: boolean) -> (),
    ConnectStandard: (self: BaseCrosshair, Tool: Tool) -> (),
    Destroy: (self: BaseCrosshair) -> (),
}



--[[
Creates a mouse crosshair.
--]]
function BaseCrosshair.new(): BaseCrosshair
    return (setmetatable({}, BaseCrosshair) :: any) :: BaseCrosshair
end

--[[
Sets the ammo to display.
--]]
function BaseCrosshair:SetAmmo(CurrentAmmo: number, MaxAmmo: number): ()
    self.AmmoText.Text = tostring(CurrentAmmo).." / "..tostring(MaxAmmo)
end

--[[
Sets the reloading text visibility.
--]]
function BaseCrosshair:SetReloading(Reloading: boolean): ()
    self.ReloadingText.Visible = Reloading
end

--[[
Connects a standard weapon.
--]]
function BaseCrosshair:ConnectStandard(Tool: Tool): ()
    local Configuration = require(Tool:WaitForChild("Configuration")) :: any
    local State = Tool:WaitForChild("State")
    local RemainingRounds = State:WaitForChild("RemainingRounds") :: IntValue
    local ReloadingValue = State:WaitForChild("Reloading") :: BoolValue

    --[[
    Converts a number of projectiles to a display number.
    --]]
    local function GetDisplayProjectiles(Projectiles: number): number
        return math.floor(Projectiles / (Configuration.ProjectilesPerRound or 1))
    end

    --Connect reloading.
    self:SetReloading(ReloadingValue.Value)
    ReloadingValue:GetPropertyChangedSignal("Value"):Connect(function()
        self:SetReloading(ReloadingValue.Value)
    end)

    --Connect ammo.
    self:SetAmmo(GetDisplayProjectiles(RemainingRounds.Value), GetDisplayProjectiles(Configuration.TotalRounds))
    RemainingRounds:GetPropertyChangedSignal("Value"):Connect(function()
        self:SetAmmo(GetDisplayProjectiles(RemainingRounds.Value), GetDisplayProjectiles(Configuration.TotalRounds))
    end)
end

--[[
Destroys the crosshair.
--]]
function BaseCrosshair:Destroy(): ()
    self.CrosshairGui:Destroy()
end



return (BaseCrosshair :: any) :: BaseCrosshair