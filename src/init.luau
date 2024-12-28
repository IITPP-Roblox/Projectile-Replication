--Handles replication of projectiles.
--!strict

local BYTES_PER_AIM_POSITION = 20 --8 bytes for user id + 3 * 4 bytes for position.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Projectile = require(script:WaitForChild("Projectile"))
local LocalAudio = require(script:WaitForChild("LocalAudio"))
local LocalTween = require(script:WaitForChild("LocalTween"))
local Appendage = require(script:WaitForChild("NexusAppendage"):WaitForChild("Appendage"))
local PlayerBufferedRemoteEventReceiver = require(script:WaitForChild("NexusBufferedReplication"):WaitForChild("Receiver"):WaitForChild("PlayerBufferedRemoteEventReceiver"))
local BufferedRemoteEventSender = require(script:WaitForChild("NexusBufferedReplication"):WaitForChild("Sender"):WaitForChild("BufferedRemoteEventSender"))
local Types = require(script:WaitForChild("Types"))
local LocalWeaponSetup = require(script:WaitForChild("Standard"):WaitForChild("LocalWeaponSetup"))
local Presets = ReplicatedStorage:WaitForChild("Data"):WaitForChild("ProjectilePresets")

local ProjectileReplication = {}
ProjectileReplication.QueuedProjectiles = {} :: {QueuedProjectileEntry}
ProjectileReplication.LastLocalAimPosition = nil :: Vector3?
ProjectileReplication.SetUpCalled = false
local UpdateAimFunctions = {}
setmetatable(UpdateAimFunctions, {__mode="k"})

type QueuedProjectileEntry = {
    SourcePlayer: Player?,
    StartCFrame: CFrame,
    Source: Model,
    FirePart: BasePart,
    PresetName: string
}
export type ProjectileReplication = typeof(ProjectileReplication)



--Create or get the RemoteEvent.
local FireProjectileEvent: RemoteEvent = nil
local ReloadEvent: RemoteEvent = nil
local UpdateAimEvent: UnreliableRemoteEvent = nil
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

    UpdateAimEvent = script:FindFirstChild("UpdateAim") or Instance.new("UnreliableRemoteEvent")
    UpdateAimEvent.Name = "UpdateAim"
    UpdateAimEvent.Parent = script
end



--[[
Fires a projectile.
--]]
function ProjectileReplication.Fire(self: ProjectileReplication, StartCFrame: CFrame, FirePart: BasePart, PresetName: string, Source: Model?, IgnoreReplication: boolean?): ()
    --Set the source.
    if RunService:IsClient() and not Source then
        Source = Players.LocalPlayer.Character
    end

    --Get the preset.
    local PresetModule = Presets:FindFirstChild(PresetName)
    if not PresetModule then return end
    local Preset = require(PresetModule) :: Types.ProjectilePreset

    --Create the projectile.
    local ProjectileObject = Projectile.new(RunService:IsClient() and Preset.Appearance or nil)
    ProjectileObject.Source = Source
    if RunService:IsClient() and Preset.OnHitClient then
        ProjectileObject.OnHit:Connect(Preset.OnHitClient)
    end
    if not RunService:IsClient() and Preset.OnHitServer then
        ProjectileObject.OnHit:Connect(Preset.OnHitServer)
    end
    local Configuration = nil
    if Source then
        local Tool = Source:FindFirstChildOfClass("Tool")
        Configuration = (Tool and Tool:FindFirstChild("Configuration") and require(Tool:FindFirstChild("Configuration")) :: any);
        (ProjectileObject :: any).Configuration = Configuration
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
            table.insert(self.QueuedProjectiles, {
                SourcePlayer = Players:GetPlayerFromCharacter(Source),
                StartCFrame = StartCFrame,
                Source = Source :: Model,
                FirePart = FirePart,
                PresetName = PresetName,
            })
        end
    end

    --Fire the projectile.
    if Configuration and Configuration.FireDelay then
        task.wait(Configuration.FireDelay)
    end
    ProjectileObject:Fire(StartCFrame, Preset.Speed, Preset.LifetimeSeconds, {Source or Players.LocalPlayer.Character})
    if RunService:IsClient() and Preset.OnFireClient then
        task.spawn(function()
            Preset.OnFireClient(ProjectileObject :: any)
        end)
    end
    if not RunService:IsClient() and Preset.OnFireServer then
        task.spawn(function()
            Preset.OnFireServer(ProjectileObject :: any)
        end)
    end
end

--[[
Reloads the current tool of the given player.
--]]
function ProjectileReplication.Reload(self: ProjectileReplication, Player: Player?, Tool: Tool?): ()
    if RunService:IsClient() then
        ReloadEvent:FireServer(Tool)
    elseif Player then
        --Get the tool parts.
        local Character = Player.Character :: Model
        if not Character then return end
        local NewTool = Character:FindFirstChildOfClass("Tool") or Tool :: Tool
        if not NewTool then return end
        local State = NewTool:FindFirstChild("State") :: Folder
        local Configuration = NewTool:FindFirstChild("Configuration") :: ModuleScript
        local Handle = NewTool:FindFirstChild("Handle") :: BasePart
        if not State or not Configuration or not Handle then return end
        local ConfigurationData = require(Configuration) :: Types.StandardConfiguration
        local RemainingRoundsValue = State:FindFirstChild("RemainingRounds") :: IntValue
        local ReloadingValue = State:FindFirstChild("Reloading") :: BoolValue
        if not RemainingRoundsValue or not ReloadingValue then return end

        --Play the reload sound.
        local StartAttachment = Handle:FindFirstChild("StartAttachment")
        if StartAttachment and NewTool.Parent == Character then
            local PresetModule = Presets:FindFirstChild(ConfigurationData.ProjectilePreset)
            local ReloadSound = Configuration and ConfigurationData.ReloadSound or (require(PresetModule) :: Types.ProjectilePreset).DefaultReloadSound
            if ReloadSound then
                LocalAudio:PlayAudio(ReloadSound, StartAttachment)
            end
        end

        --Reload the weapon.
        ReloadingValue.Value = true
        task.wait(ConfigurationData.ReloadTime)
        RemainingRoundsValue.Value = ConfigurationData.TotalRounds
        ReloadingValue.Value = false
    end
end

--[[
Sets the aim of a player to a given CFrame.
--]]
function ProjectileReplication.Aim(self: ProjectileReplication, Player: Player, AimPosition: Vector3): ()
    --Get or create the update function.
    local Character = Player.Character :: Model
    if not Character then return end
    if not UpdateAimFunctions[Character] then
        --Get the character and tool parts.
        local Tool = Character:FindFirstChildOfClass("Tool") :: Tool
        local Humanoid = Character:FindFirstChildOfClass("Humanoid") :: Humanoid
        local Head = Character:FindFirstChild("Head") :: BasePart
        local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart") :: BasePart
        local LowerTorso = Character:FindFirstChild("LowerTorso") :: BasePart
        local UpperTorso = Character:FindFirstChild("UpperTorso") :: BasePart
        local RightUpperArm = Character:FindFirstChild("RightUpperArm") :: BasePart
        if not Tool or not Humanoid or not Head or not LowerTorso or not UpperTorso or not RightUpperArm or not HumanoidRootPart then return end
        local Handle = Tool:FindFirstChild("Handle") :: BasePart
        local RootRigAttachment = HumanoidRootPart:FindFirstChild("RootRigAttachment") :: Attachment
        local Root = LowerTorso:FindFirstChild("Root") :: Motor6D
        local RightShoulderRigAttachment = UpperTorso:FindFirstChild("RightShoulderRigAttachment") :: Attachment
        local RightShoulder = RightUpperArm:FindFirstChild("RightShoulder") :: Motor6D
        if not Handle or not RootRigAttachment or not Root or not RightShoulderRigAttachment or not RightShoulder then return end

        --Get the configuration.
        local ToolConfigurationModule = Tool:FindFirstChild("Configuration")
        if not ToolConfigurationModule or not ToolConfigurationModule:IsA("ModuleScript") then return end
        local ToolConfiguration = require(ToolConfigurationModule) :: Types.StandardConfiguration
        local CharacterRotation = ToolConfiguration.AimRotationOffset or CFrame.new()

        --Get the left arm parts.
        local LeftHandHold = Handle:FindFirstChild("LeftHandHold") :: Attachment
        local LeftArmAppendage = nil
        if LeftHandHold then
            LeftArmAppendage = Appendage.FromPreset("LeftArm", Character)
            LeftArmAppendage:SetTargetAttachment(LeftHandHold)
        end

        --Create the BodyGyro if the player is the local player.
        local BodyGyro, HumanoidChangedEvent = nil, nil
        if Player == Players.LocalPlayer then
            BodyGyro = Instance.new("BodyGyro")
            BodyGyro.Name = "ProjectileReplicationAimGyro"
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
                for JointName, TransformCFrame in PartJoints do
                    local Joint = Part:FindFirstChild(JointName) :: Motor6D
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

            --Set the joints.
            if ToolConfiguration.AnimationJoints then
                for PartName, PartJoints in ToolConfiguration.AnimationJoints do
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
            ToolChangedEvent = nil :: any
            UpdateAnimationsEvent:Disconnect()
            UpdateAnimationsEvent = nil
            if UpdateAimFunctions[Character] == CurrentUpdateFunction then
                UpdateAimFunctions[Character] = nil
            end

            --Reset the root and shoulder.
            RightShoulder.C0 = RightShoulderRigAttachment.CFrame
            Root.C0 = RootRigAttachment.CFrame

            --Reset the left arm.
            if LeftArmAppendage then
                LeftArmAppendage:Destroy()
            end

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

    --Prepare to replicate the aim..
    if Player ~= Players.LocalPlayer then return end
    self.LastLocalAimPosition = AimPosition
end

--[[
Sets up the replication.
--]]
function ProjectileReplication.SetUp(self: ProjectileReplication): ()
    --Return if setup was called.
    if self.SetUpCalled then return end
    self.SetUpCalled = true

    if RunService:IsClient() then
        LocalAudio:SetUp()
        LocalTween:SetUp()
        LocalWeaponSetup:Bind()

        --Connect projectiles being fired.
        FireProjectileEvent.OnClientEvent:Connect(function(QueuedProjectiles: {QueuedProjectileEntry})
            for _, QueuedProjectile in QueuedProjectiles do
                if QueuedProjectile.SourcePlayer == Players.LocalPlayer then continue end
                self:Fire(QueuedProjectile.StartCFrame, QueuedProjectile.FirePart, QueuedProjectile.PresetName, QueuedProjectile.Source, true)
            end
        end)

        --Connect the aim updating.
        local UpdateAimBufferedReceiver = PlayerBufferedRemoteEventReceiver.new(UpdateAimEvent, function(AimPositionsBuffer: buffer): {[number]: Vector3}
            local AimPositions = {}
            for i = 1, buffer.len(AimPositionsBuffer) / BYTES_PER_AIM_POSITION do
                local StartOffset = (i - 1) * BYTES_PER_AIM_POSITION
                AimPositions[buffer.readf64(AimPositionsBuffer, StartOffset)] = Vector3.new(buffer.readf32(AimPositionsBuffer, StartOffset + 8), buffer.readf32(AimPositionsBuffer, StartOffset + 12), buffer.readf32(AimPositionsBuffer, StartOffset + 16))
            end
            return AimPositions
        end)
        UpdateAimBufferedReceiver:OnDataReceived(function(Player: Player, AimPosition: Vector3)
            if Player == Players.LocalPlayer then return end
            self:Aim(Player, AimPosition)
        end)

        --Replicate aiming every 30hz.
        task.spawn(function()
            while true do
                if self.LastLocalAimPosition then
                    UpdateAimEvent:FireServer(self.LastLocalAimPosition)
                    self.LastLocalAimPosition = nil
                end
                task.wait(1 / 30)
            end
        end)
    else
        --Connect requests for projectiles being fired.
        FireProjectileEvent.OnServerEvent:Connect(function(Player: Player, StartCFrame: CFrame)
            --Get the weapon that was fired.
            local Character = Player.Character :: Model
            if not Character then return end
            local Humnanoid = Character:FindFirstChildOfClass("Humanoid") :: Humanoid
            local Tool = Character:FindFirstChildOfClass("Tool") :: Tool
            if not Humnanoid or Humnanoid.Health <= 0 or not Tool then return end
            local Handle = Tool:FindFirstChild("Handle") :: BasePart
            local State = Tool:FindFirstChild("State") :: Folder
            local Configuration = Tool:FindFirstChild("Configuration") :: Model
            if not Handle or not State or not Configuration then return end
            local ConfigurationData = require(Configuration) :: Types.StandardConfiguration
            local RemainingRoundsValue = State:FindFirstChild("RemainingRounds") :: IntValue
            local ReloadingValue = State:FindFirstChild("Reloading") :: BoolValue
            local LastFireTimeValue = State:FindFirstChild("LastFireTime") :: NumberValue
            local LastFireRemainingRoundsValue = State:FindFirstChild("LastFireRemainingRounds") :: NumberValue
            if not RemainingRoundsValue or not ReloadingValue then return end

            --Return if the firing is invalid.
            if ReloadingValue.Value then return end
            if RemainingRoundsValue.Value <= 0 then return end
            if (StartCFrame.Position - Handle.Position).Magnitude > 10 and not Humnanoid.Sit and not Humnanoid.SeatPart then return end --Local trams do not replicate to the server, so the projectiles shots will claim to be far away.
            local IsCloseToLastFire = (tick() - LastFireTimeValue.Value < ConfigurationData.CooldownTime * 0.5)
            if IsCloseToLastFire and LastFireRemainingRoundsValue.Value <= 0 then return end

            --Fire the projectile.
            LastFireTimeValue.Value = tick()
            LastFireRemainingRoundsValue.Value = (IsCloseToLastFire and LastFireRemainingRoundsValue.Value - 1 or (ConfigurationData.ProjectilesPerRound or 1) - 1)
            RemainingRoundsValue.Value = RemainingRoundsValue.Value - 1
            self:Fire(StartCFrame, Handle, ConfigurationData.ProjectilePreset, Character)
        end)

        --Connect requests for reloading.
        ReloadEvent.OnServerEvent:Connect(function(Player: Player, Tool: Tool?)
            self:Reload(Player, Tool)
        end)

        --Connect requests for updating the aim of players.
        --To reduce network load, aim positions are sent in bulk at 30hz.
        local UpdateAimBufferedSender = BufferedRemoteEventSender.WithPlayerKeys(UpdateAimEvent, function(AimPosition: Vector3)
            local AimPositionBuffer = buffer.create(3 * 4)
            buffer.writef32(AimPositionBuffer, 0, AimPosition.X)
            buffer.writef32(AimPositionBuffer, 4, AimPosition.Y)
            buffer.writef32(AimPositionBuffer, 8, AimPosition.Z)
            return AimPositionBuffer
        end)
        UpdateAimBufferedSender:StartDataSendingWithDelay(1 / 30)

        UpdateAimEvent.OnServerEvent:Connect(function(Player: Player, AimPosition: Vector3)
            --Determine if the player can aim.
            local Character = Player.Character :: Model
            if not Character then return end
            local Humnanoid = Character:FindFirstChildOfClass("Humanoid") :: Humanoid
            local Tool = Character:FindFirstChildOfClass("Tool") :: Tool
            if not Humnanoid or Humnanoid.Health <= 0 or not Tool then return end

            --Store the aim position to be repliaced later.
            UpdateAimBufferedSender:QueueData(Player, AimPosition)
        end)

        --Replicate the projectiles.
        --To reduce network load, projectiles are sent in bulk, but done more frequently then aiming.
        RunService.Heartbeat:Connect(function()
            local CurrentQueuedProjectiles = self.QueuedProjectiles
            if #CurrentQueuedProjectiles == 0 then return end
            self.QueuedProjectiles = {}
            FireProjectileEvent:FireAllClients(CurrentQueuedProjectiles)
        end)
    end
end



return ProjectileReplication