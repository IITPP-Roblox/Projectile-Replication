--[[
TheNexusAvenger

Sets the weapon on the client.
LocalWeaponSetup is used to properly handle being abruptly cleared.
--]]
--!strict

local Tool = script.Parent
local ProjectileReplicationModule = Tool:WaitForChild("ProjectileReplicationReference").Value
while not ProjectileReplicationModule do
    ProjectileReplicationModule = Tool:WaitForChild("ProjectileReplicationReference").Value
    task.wait()
end
local LocalWeaponSetup = require(ProjectileReplicationModule:WaitForChild("Standard"):WaitForChild("LocalWeaponSetup")) :: any
LocalWeaponSetup:SetupTool(Tool)