--[[
TheNexusAvenger

Handles replication of projectiles.
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Projectile = require(script:WaitForChild("Projectile"))
local JointSolver = require(script:WaitForChild("JointSolver"))
local LocalAudio = require(script:WaitForChild("LocalAudio"))
local LocalTween = require(script:WaitForChild("LocalTween"))
local Presets = ReplicatedStorage:WaitForChild("Data"):WaitForChild("ProjectilePresets")

local ProjectileReplication = {}
local UpdateAimFunctions = {}
setmetatable(UpdateAimFunctions, {__mode="k"})



--Create or get the RemoteEvent.
local FireProjectileEvent: RemoteEvent? = nil
local ReloadEvent: RemoteEvent? = nil
local UpdateAimEvent: RemoteEvent? = nil
if RunService:IsClient() then
    FireProjectileEvent = script:WaitForChild("FireProjectile")
    ReloadEvent = script:WaitForChild("Reload")
    UpdateAimEvent = script:WaitForChild("UpdateAim")
else
    FireProjectileEvent = script:FindFirstChild("FireProjectile") or Instance.new("RemoteEvent")
    FireProjectileEvent.Name = "FireProjectile"
    FireProjectileEvent.Parent = script

    ReloadEvent = script:FindFirstChild("Reload") or Instance.new("RemoteEvent")
    ReloadEvent.Name = "Reload"
    ReloadEvent.Parent = script

    UpdateAimEvent = script:FindFirstChild("UpdateAim") or Instance.new("RemoteEvent")
    UpdateAimEvent.Name = "UpdateAim"
    UpdateAimEvent.Parent = script
end



--[[
Fires a projectile.
--]]
function ProjectileReplication:Fire(StartCFrame: CFrame, FirePart: BasePart, PresetName: string, Source: Model?, IgnoreReplication: boolean?): nil
    --Set the source.
    if RunService:IsClient() and not Source then
        Source = Players.LocalPlayer.Character
    end

    --Get the preset.
    local PresetModule = Presets:FindFirstChild(PresetName)
    if not PresetModule then return end
    local Preset = require(PresetModule)

    --Create the projectile.
    local ProjectileObject = Projectile.new(RunService:IsClient() and Preset.Appearance or nil)
    if RunService:IsClient() and Preset.OnHitClient then
        ProjectileObject.OnHit:Connect(Preset.OnHitClient)
    end
    if not RunService:IsClient() and Preset.OnServerHit then
        ProjectileObject.OnHit:Connect(Preset.OnServerHit)
    end
    local Configuration = nil
    if Source then
        local Tool = Source:FindFirstChildOfClass("Tool")
        Configuration = (Tool and Tool:FindFirstChild("Configuration") and require(Tool:FindFirstChild("Configuration")))
        ProjectileObject.Configuration = Configuration
    end

    --Show the fire animation.
    if RunService:IsClient() and FirePart then
        local StartAttachment = FirePart:FindFirstChild("StartAttachment")
        if StartAttachment then
            LocalAudio:PlayAudio((Configuration and Configuration.FireSound) or Preset.DefaultFireSound, StartAttachment)
        end
    end

    --Handle the replication.
    if IgnoreReplication ~= true then
        if RunService:IsClient() then
            FireProjectileEvent:FireServer(StartCFrame)
        else
            local FiringPlayer = Players:GetPlayerFromCharacter(Source)
            for _, Player in pairs(Players:GetPlayers()) do
                if FiringPlayer ~= Player then
                    FireProjectileEvent:FireClient(Player, StartCFrame, Source, FirePart, PresetName)
                end
            end
        end
    end

    --Fire the projectile.
    if Configuration and Configuration.FireDelay then
        task.wait(Configuration.FireDelay)
    end
    ProjectileObject:Fire(StartCFrame, Preset.Speed, Preset.LifetimeSeconds, {Source or Players.LocalPlayer.Character})
end

--[[
Reloads the current tool of the given player.
--]]
function ProjectileReplication:Reload(Player: Player?, Tool: Tool?): nil
    if RunService:IsClient() then
        ReloadEvent:FireServer(Tool)
    else
        --Get the tool parts.
        local Character = Player.Character
        if not Character then return end
        Tool = Character:FindFirstChildOfClass("Tool") or Tool
        if not Tool then return end
        local State = Tool:FindFirstChild("State")
        local Configuration = Tool:FindFirstChild("Configuration")
        local Handle = Tool:FindFirstChild("Handle")
        if not State or not Configuration or not Handle then return end
        Configuration = require(Configuration)
        local RemainingRoundsValue = State:FindFirstChild("RemainingRounds")
        local ReloadingValue = State:FindFirstChild("Reloading")
        if not RemainingRoundsValue or not ReloadingValue then return end

        --Play the reload sound.
        local StartAttachment = Handle:FindFirstChild("StartAttachment")
        if StartAttachment and Tool.Parent == Character then
            local PresetModule = Presets:FindFirstChild(Configuration.ProjectilePreset)
            LocalAudio:PlayAudio(Configuration and Configuration.ReloadSound or require(PresetModule).DefaultReloadSound, StartAttachment)
        end

        --Reload the weapon.
        ReloadingValue.Value = true
        task.wait(Configuration.ReloadTime)
        RemainingRoundsValue.Value = Configuration.TotalRounds
        ReloadingValue.Value = false
    end
end

--[[
Sets the aim of a player to a given CFrame.
--]]
function ProjectileReplication:Aim(Player: Player, AimPosition: Vector3): nil
    --Get or create the update function.
    local Character = Player.Character
    if not Character then return end
    if not UpdateAimFunctions[Character] then
        --Get the character and tool parts.
        local Tool = Character:FindFirstChildOfClass("Tool")
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        local Head = Character:FindFirstChild("Head")
        local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
        local LowerTorso = Character:FindFirstChild("LowerTorso")
        local UpperTorso = Character:FindFirstChild("UpperTorso")
        local LeftUpperArm = Character:FindFirstChild("LeftUpperArm")
        local RightUpperArm = Character:FindFirstChild("RightUpperArm")
        if not Tool or not Humanoid or not Head or not LowerTorso or not UpperTorso or not RightUpperArm or not HumanoidRootPart then return end
        local Handle = Tool:FindFirstChild("Handle")
        local RootRigAttachment = HumanoidRootPart:FindFirstChild("RootRigAttachment")
        local Root = LowerTorso:FindFirstChild("Root")
        local RightShoulderRigAttachment = UpperTorso:FindFirstChild("RightShoulderRigAttachment")
        local LeftShoulderRigAttachment = UpperTorso:FindFirstChild("LeftShoulderRigAttachment")
        local LeftShoulder = LeftUpperArm and LeftUpperArm:FindFirstChild("LeftShoulder")
        local RightShoulder = RightUpperArm:FindFirstChild("RightShoulder")
        if not Handle or not RootRigAttachment or not Root or not RightShoulderRigAttachment or not LeftShoulderRigAttachment or not RightShoulder then return end
        local LeftHandHold = Handle:FindFirstChild("LeftHandHold")

        --Get the left arm parts.
        local LeftUpperLimbStartAttachment, LeftUpperLimbJointAttachment = nil, nil
        local LeftLowerLimbJointAttachment, LeftLowerLimbEndAttachment = nil, nil
        local LeftLimbEndAttachment, LeftLimbHoldAttachment = nil, nil
        if LeftHandHold then
            local LeftLowerArm = Character:FindFirstChild("LeftLowerArm")
            local LeftHand = Character:FindFirstChild("LeftHand")
            LeftUpperLimbStartAttachment = LeftUpperArm and LeftUpperArm:FindFirstChild("LeftShoulderRigAttachment")
            LeftUpperLimbJointAttachment = LeftUpperArm and LeftUpperArm:FindFirstChild("LeftElbowRigAttachment")
            LeftLowerLimbJointAttachment = LeftLowerArm and LeftLowerArm:FindFirstChild("LeftElbowRigAttachment")
            LeftLowerLimbEndAttachment = LeftLowerArm and LeftLowerArm:FindFirstChild("LeftWristRigAttachment")
            LeftLimbEndAttachment = LeftHand and LeftHand:FindFirstChild("LeftWristRigAttachment")
            LeftLimbHoldAttachment = LeftHand and LeftHand:FindFirstChild("LeftGripAttachment")
        end

        --Get the configuration.
        local ToolConfiguration = Tool:FindFirstChild("Configuration")
        if ToolConfiguration then ToolConfiguration = require(ToolConfiguration) end
        local CharacterRotation = ToolConfiguration.AimRotationOffset or CFrame.new()

        --Create the BodyGyro if the player is the local player.
        local BodyGyro, HumanoidChangedEvent = nil, nil
        if Player == Players.LocalPlayer then
            BodyGyro = Instance.new("BodyGyro")
            BodyGyro.D = 100
            BodyGyro.P = 10000
            BodyGyro.MaxTorque = Vector3.new(0, Humanoid.Sit and 0 or math.huge, 0)
            BodyGyro.Parent = HumanoidRootPart

            HumanoidChangedEvent = Humanoid:GetPropertyChangedSignal("Sit"):Connect(function()
                BodyGyro.MaxTorque = Vector3.new(0, Humanoid.Sit and 0 or math.huge, 0)
            end)
        end

        --Set the root C0.
        Root.C0 = RootRigAttachment.CFrame * CharacterRotation

        --Store the update function.
        local AimPosition = nil
        UpdateAimFunctions[Character] = function(NewAimPosition: Vector3)
            if BodyGyro then
                BodyGyro.CFrame = CFrame.new(Head.Position, NewAimPosition)
            end
            AimPosition = NewAimPosition
        end

        --[[
        Updates a joint.
        --]]
        local function UpdateJoint(PartName: string, PartJoints: {[string]: CFrame})
            local Part = Character:FindFirstChild(PartName)
            if Part then
                for JointName, TransformCFrame in pairs(PartJoints) do
                    local Joint = Part:FindFirstChild(JointName)
                    if Joint then
                        Joint.Transform = TransformCFrame
                    end
                end
            end
        end

        --Connect overriding the animations.
        local UpdateAnimationsEvent = RunService.Stepped:Connect(function()
            --Update the aim.
            if AimPosition then
                local AttachmentGoal = CFrame.new(RightShoulderRigAttachment.WorldCFrame.Position) * CFrame.new(-Head.Position) * CFrame.new(Head.Position, AimPosition)
                local ShouldAimCFrame = RightShoulderRigAttachment.WorldCFrame:Inverse() * AttachmentGoal
                RightShoulder.C0 = RightShoulderRigAttachment.CFrame * ShouldAimCFrame * CharacterRotation
            end

            if LeftHandHold or ToolConfiguration.AnimationJoints then
                --Solve the left arm.
                local LeftArmJoints = {}
                if LeftHandHold and LeftUpperLimbStartAttachment and LeftUpperLimbJointAttachment and LeftLowerLimbJointAttachment and LeftLowerLimbEndAttachment and LeftLimbEndAttachment and LeftLimbHoldAttachment then
                    local LeftUpperArmCFrame, LeftLowerArmCFrame, LeftHandCFrame = JointSolver(LeftShoulderRigAttachment.WorldCFrame, LeftHandHold.WorldCFrame, LeftUpperLimbStartAttachment, LeftUpperLimbJointAttachment, LeftLowerLimbJointAttachment, LeftLowerLimbEndAttachment, LeftLimbEndAttachment, LeftLimbHoldAttachment)
                    LeftArmJoints = {
                        LeftUpperArm = {
                            LeftShoulder = LeftShoulderRigAttachment.WorldCFrame:Inverse() * (LeftUpperArmCFrame * LeftUpperLimbStartAttachment.CFrame),
                        },
                        LeftLowerArm = {
                            LeftElbow = (LeftUpperArmCFrame * LeftUpperLimbJointAttachment.CFrame):Inverse() * (LeftLowerArmCFrame * LeftLowerLimbJointAttachment.CFrame),
                        },
                        LeftHand = {
                            LeftWrist = (LeftLowerArmCFrame * LeftLowerLimbEndAttachment.CFrame):Inverse() * (LeftHandCFrame * LeftLimbEndAttachment.CFrame),
                        },
                    }
                end

                --Set the joints.
                if ToolConfiguration.AnimationJoints then
                    for PartName, PartJoints in pairs(ToolConfiguration.AnimationJoints) do
                        UpdateJoint(PartName, PartJoints)
                    end
                end
                for PartName, PartJoints in pairs(LeftArmJoints) do
                    UpdateJoint(PartName, PartJoints)
                end
            end
        end)

        --Connect resetting when the tool is removed.
        local CurrentUpdateFunction = UpdateAimFunctions[Character]
        local ToolChangedEvent = nil
        ToolChangedEvent = Tool.AncestryChanged:Connect(function()
            --Disconnect the events and remove the changed callback.
            ToolChangedEvent:Disconnect()
            ToolChangedEvent = nil
            UpdateAnimationsEvent:Disconnect()
            UpdateAnimationsEvent = nil
            if UpdateAimFunctions[Character] == CurrentUpdateFunction then
                UpdateAimFunctions[Character] = nil
            end

            --Reset the root and shoulder.
            RightShoulder.C0 = RightShoulderRigAttachment.CFrame
            Root.C0 = RootRigAttachment.CFrame

            --Clear the BodyGyro.
            if BodyGyro then
                BodyGyro:Destroy()
            end
            if HumanoidChangedEvent then
                HumanoidChangedEvent:Disconnect()
            end
        end)
    end

    --Update the aim.
    if not UpdateAimFunctions[Character] then return end
    UpdateAimFunctions[Character](AimPosition)

    --Replicate the aim.
    if Player ~= Players.LocalPlayer then return end
    UpdateAimEvent:FireServer(AimPosition)
end

--[[
Sets up the replication.
--]]
function ProjectileReplication:SetUp(): nil
    --Return if setup was called.
    if self.SetUpCalled then return end
    self.SetUpCalled = true

    if RunService:IsClient() then
        LocalAudio:SetUp()
        LocalTween:SetUp()

        --Connect projectiles being fired.
        FireProjectileEvent.OnClientEvent:Connect(function(StartCFrame: CFrame, Source: Model, FirePart: BasePart, PresetName: string)
            self:Fire(StartCFrame, FirePart, PresetName, Source, true)
        end)

        --Connect the aim updating.
        UpdateAimEvent.OnClientEvent:Connect(function(Player: Player, AimPosition: Vector3)
            self:Aim(Player, AimPosition)
        end)
    else
        --Connect requests for projectiles being fired.
        FireProjectileEvent.OnServerEvent:Connect(function(Player: Player, StartCFrame: CFrame)
            --Get the weapon that was fired.
            local Character = Player.Character
            if not Character then return end
            local Humnanoid = Character:FindFirstChildOfClass("Humanoid")
            local Tool = Character:FindFirstChildOfClass("Tool")
            if not Humnanoid or Humnanoid.Health <= 0 or not Tool then return end
            local Handle = Tool:FindFirstChild("Handle")
            local State = Tool:FindFirstChild("State")
            local Configuration = Tool:FindFirstChild("Configuration")
            if not Handle or not State or not Configuration then return end
            Configuration = require(Configuration)
            local RemainingRoundsValue = State:FindFirstChild("RemainingRounds")
            local ReloadingValue = State:FindFirstChild("Reloading")
            local LastFireTimeValue = State:FindFirstChild("LastFireTime")
            if not RemainingRoundsValue or not ReloadingValue then return end

            --Return if the firing is invalid.
            if ReloadingValue.Value then return end
            if RemainingRoundsValue.Value <= 0 then return end
            if (StartCFrame.Position - Handle.Position).Magnitude > 10 and not Humnanoid.Sit and not Humnanoid.SeatPart then return end --Local trams do not replicate to the server, so the projectiles shots will claim to be far away.
            --TODO: Security check below does not apply to shotgun. This is exploitable.
            if tick() - LastFireTimeValue.Value < Configuration.CooldownTime * 0.5 and (not Configuration.ProjectilesPerRound or Configuration.ProjectilesPerRound == 1) then return end

            --Fire the projectile.
            LastFireTimeValue.Value = tick()
            RemainingRoundsValue.Value = RemainingRoundsValue.Value - 1
            self:Fire(StartCFrame, Handle, Configuration.ProjectilePreset, Character)
        end)

        --Connect requests for reloading.
        ReloadEvent.OnServerEvent:Connect(function(Player: Player, Tool: Tool?)
            self:Reload(Player, Tool)
        end)

        --Connect requests for updating the aim of players.
        UpdateAimEvent.OnServerEvent:Connect(function(Player: Player, AimPosition: Vector3)
            --Determine if the player can aim.
            local Character = Player.Character
            if not Character then return end
            local Humnanoid = Character:FindFirstChildOfClass("Humanoid")
            local Tool = Character:FindFirstChildOfClass("Tool")
            if not Humnanoid or Humnanoid.Health <= 0 or not Tool then return end

            --Send the aim requests.
            for _, OtherPlayer in pairs(Players:GetPlayers()) do
                if Player ~= OtherPlayer then
                    UpdateAimEvent:FireClient(OtherPlayer, Player, AimPosition)
                end
            end
        end)
    end
end



return ProjectileReplication