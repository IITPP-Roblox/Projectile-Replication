--[[
TheNexusAvenger

Prepares standard weapons.
--]]

local LocalWeaponScript = script:WaitForChild("LocalWeapon")
local ServerWeaponScript = script:WaitForChild("ServerWeapon")

local Standard = {}



--[[
Prepares a standard weapon.
--]]
function Standard.CreateStandardWeapon(WeaponModel: Tool): nil
    --Ignore the tool if it is not valid.
    if not WeaponModel:IsA("Tool") then return end
    local Configuration = WeaponModel:FindFirstChild("Configuration")
    if not Configuration or not Configuration:IsA("ModuleScript") then return end
    Configuration = require(Configuration)

    --Add the state folder.
    local StateFolder = Instance.new("Folder")
    StateFolder.Name = "State"
    StateFolder.Parent = WeaponModel

    local LastFireTimeValue = Instance.new("NumberValue")
    LastFireTimeValue.Name = "LastFireTime"
    LastFireTimeValue.Value = StateFolder
    LastFireTimeValue.Parent = StateFolder

    local RemainingRoundsValue = Instance.new("IntValue")
    RemainingRoundsValue.Name = "RemainingRounds"
    RemainingRoundsValue.Value = Configuration.TotalRounds
    RemainingRoundsValue.Parent = StateFolder

    local ReloadingValue = Instance.new("BoolValue")
    ReloadingValue.Name = "Reloading"
    ReloadingValue.Value = false
    ReloadingValue.Parent = StateFolder

    --Clone the standard scripts.
    local ProjectileReplicationReferenceValue = Instance.new("ObjectValue")
    ProjectileReplicationReferenceValue.Name = "ProjectileReplicationReference"
    ProjectileReplicationReferenceValue.Value = script.Parent
    ProjectileReplicationReferenceValue.Parent = WeaponModel

    local NewLocalWeaponScript = LocalWeaponScript:Clone()
    NewLocalWeaponScript.Disabled = false
    NewLocalWeaponScript.Parent = WeaponModel

    if Configuration.ChargeUpTime and Configuration.ChargeDownTime then
        local ChargedPercentValue = Instance.new("NumberValue")
        ChargedPercentValue.Name = "ChargedPercent"
        ChargedPercentValue.Value = StateFolder
        ChargedPercentValue.Parent = StateFolder

        local NewServerWeaponScript = ServerWeaponScript:Clone()
        NewServerWeaponScript.Disabled = false
        NewServerWeaponScript.Parent = WeaponModel
    end
end



return Standard