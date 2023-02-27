--[[
TheNexusAvenger

Sets up the demo weapon on the server.
--]]
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPack = game:GetService("StarterPack")

local ProjectileReplication = require(ReplicatedStorage:WaitForChild("ProjectileReplication"))
ProjectileReplication:SetUp()



--Create the demo tool.
local Tool = Instance.new("Tool")
Tool.Name = "DemoWeapon"
Tool.Grip = CFrame.new(0, -0.3, -1.5) * CFrame.Angles(0, math.pi, 0)
Tool.Parent = StarterPack

local Handle = Instance.new("Part")
Handle.Size = Vector3.new(0.4, 0.8, 5)
Handle.CanCollide = false
Handle.Name = "Handle"
Handle.Parent = Tool

local StartAttachment = Instance.new("Attachment")
StartAttachment.Name = "StartAttachment"
StartAttachment.CFrame = CFrame.new(0, 0.1, 2.5) * CFrame.Angles(0, math.pi, 0)
StartAttachment.Parent = Handle

local LeftHandHoldAttachment = Instance.new("Attachment")
LeftHandHoldAttachment.Name = "LeftHandHold"
LeftHandHoldAttachment.CFrame = CFrame.new(0, -0.3, -0.5) * CFrame.Angles(0, math.pi / 2, math.pi / 2)
LeftHandHoldAttachment.Parent = Handle

local Configuration = ServerScriptService:WaitForChild("DemoConfiguration")
Configuration.Name = "Configuration"
Configuration.Parent = Tool

require(ReplicatedStorage:WaitForChild("ProjectileReplication"):WaitForChild("Standard")).CreateStandardWeapon(Tool)