--Handles replication of projectiles.
--!strict

local BYTES_PER_AIM_POSITION = 20 --8 bytes for user id + 3 * 4 bytes for position.
local MAX_HIT_PART_DRIFT = 10 --How far a part can move on the server from where the shooter saw it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Projectile = require(script:WaitForChild("Projectile"))
local LocalAudio = require(script:WaitForChild("Packages"):WaitForChild("LocalAudio"))
local LocalTween = require(script:WaitForChild("Packages"):WaitForChild("LocalTween"))
local Appendage = require(script:WaitForChild("Packages"):WaitForChild("NexusAppendage")).Appendage
local NexusBufferedReplication = require(script:WaitForChild("Packages"):WaitForChild("NexusBufferedReplication"))
local Types = require(script:WaitForChild("Types"))
local LocalWeaponSetup = require(script:WaitForChild("Standard"):WaitForChild("LocalWeaponSetup"))
local Presets = ReplicatedStorage:WaitForChild("Data"):WaitForChild("ProjectilePresets")

local Event = require(script:WaitForChild("Standard"):WaitForChild("LocalWeaponSetup"):WaitForChild("Common"):WaitForChild("Event"))
local VibrationMotor = require(script:WaitForChild("Standard"):WaitForChild("LocalWeaponSetup"):WaitForChild("Common"):WaitForChild("VibrationMotor"))
local BaseInput = require(script:WaitForChild("Standard"):WaitForChild("LocalWeaponSetup"):WaitForChild("Input"):WaitForChild("BaseInput"))
local CombinedInput = require(script:WaitForChild("Standard"):WaitForChild("LocalWeaponSetup"):WaitForChild("Input"):WaitForChild("CombinedInput"))
local GamepadInput = require(script:WaitForChild("Standard"):WaitForChild("LocalWeaponSetup"):WaitForChild("Input"):WaitForChild("GamepadInput"))
local MouseInput = require(script:WaitForChild("Standard"):WaitForChild("LocalWeaponSetup"):WaitForChild("Input"):WaitForChild("MouseInput"))
local TouchInput = require(script:WaitForChild("Standard"):WaitForChild("LocalWeaponSetup"):WaitForChild("Input"):WaitForChild("TouchInput"))
local BaseCrosshair = require(script:WaitForChild("Standard"):WaitForChild("LocalWeaponSetup"):WaitForChild("UI"):WaitForChild("BaseCrosshair"))
local MouseCrosshair = require(script:WaitForChild("Standard"):WaitForChild("LocalWeaponSetup"):WaitForChild("UI"):WaitForChild("MouseCrosshair"))
local VRCrosshair = require(script:WaitForChild("Standard"):WaitForChild("LocalWeaponSetup"):WaitForChild("UI"):WaitForChild("VRCrosshair"))
local WeaponState = require(script:WaitForChild("Standard"):WaitForChild("LocalWeaponSetup"):WaitForChild("WeaponState"))
local Standard = require(script:WaitForChild("Standard"))

local PlayerBufferedRemoteEventReceiver = NexusBufferedReplication.Receiver.PlayerBufferedRemoteEventReceiver
local BufferedRemoteEventSender = NexusBufferedReplication.Sender.BufferedRemoteEventSender

local ProjectileReplication = {}
ProjectileReplication.StandardComponents = {
    Setup = Standard,
    Local = {
        Common = {
            Event = Event,
            VibrationMotor = VibrationMotor,
        },
        Input = {
            BaseInput = BaseInput,
            CombinedInput = CombinedInput,
            GamepadInput = GamepadInput,
            MouseInput = MouseInput,
            TouchInput = TouchInput,
        },
        UI = {
            BaseCrosshair = BaseCrosshair,
            MouseCrosshair = MouseCrosshair,
            VRCrosshair = VRCrosshair,
        },
        WeaponState = WeaponState,
    },
}
ProjectileReplication.QueuedProjectiles = {} :: {QueuedProjectileEntry}
ProjectileReplication.LastLocalAimPosition = nil :: Vector3?
ProjectileReplication.SetUpCalled = false
ProjectileReplication.ClientShots = {} :: {[Player]: {[number]: ClientShot}}
local NextShotId = 0
local UpdateAimFunctions = {}
setmetatable(UpdateAimFunctions, {__mode="k"})

type QueuedProjectileEntry = {
    SourcePlayer: Player?,
    StartCFrame: CFrame,
    Source: Model,
    FirePart: BasePart,
    PresetName: string
}
type ClientShot = {
    Projectile: Types.Projectile,
    StartCFrame: CFrame,
    Speed: number,
    FireTime: number,
}
export type ProjectileAppearance = Types.ProjectileAppearance
export type ProjectilePreset = Types.ProjectilePreset
export type Projectile = Types.Projectile
export type StandardConfiguration = Types.StandardConfiguration

export type Event<T...> = Event.Event<T...>
export type VibrationMotor = VibrationMotor.VibrationMotor
export type BaseInput = BaseInput.BaseInput
export type CombinedInput = CombinedInput.CombinedInput
export type GamepadInput = GamepadInput.GamepadInput
export type MouseInput = MouseInput.MouseInput
export type TouchInput = TouchInput.TouchInput
export type BaseCrosshair = BaseCrosshair.BaseCrosshair
export type MouseCrosshair = MouseCrosshair.MouseCrosshair
export type VRCrosshair = VRCrosshair.VRCrosshair
export type WeaponState = WeaponState.WeaponState

export type ProjectileReplication = typeof(ProjectileReplication)



--Create or get the RemoteEvent.
local FireProjectileEvent: RemoteEvent = nil
local ReloadEvent: RemoteEvent = nil
local HitProjectileEvent: RemoteEvent = nil
local UpdateAimEvent: UnreliableRemoteEvent = nil
if RunService:IsClient() then
    FireProjectileEvent = script:WaitForChild("FireProjectile")
    HitProjectileEvent = script:WaitForChild("HitProjectile")
    ReloadEvent = script:WaitForChild("Reload")
    UpdateAimEvent = script:WaitForChild("UpdateAim")
else
    FireProjectileEvent = script:FindFirstChild("FireProjectile") or Instance.new("RemoteEvent")
    FireProjectileEvent.Name = "FireProjectile"
    FireProjectileEvent.Parent = script

    HitProjectileEvent = script:FindFirstChild("HitProjectile") or Instance.new("RemoteEvent")
    HitProjectileEvent.Name = "HitProjectile"
    HitProjectileEvent.Parent = script

    ReloadEvent = script:FindFirstChild("Reload") or Instance.new("RemoteEvent")
    ReloadEvent.Name = "Reload"
    ReloadEvent.Parent = script

    UpdateAimEvent = script:FindFirstChild("UpdateAim") or Instance.new("UnreliableRemoteEvent")
    UpdateAimEvent.Name = "UpdateAim"
    UpdateAimEvent.Parent = script
end



--[[
Fires a projectile.
On the server, a ShotId means hits are reported by the client that fired it.
--]]
function ProjectileReplication.Fire(self: ProjectileReplication, StartCFrame: CFrame, FirePart: BasePart, PresetName: string, Source: Model?, IgnoreReplication: boolean?, ShotId: number?): ()
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
            --Hits are reported from the client so they match what the player saw.
            NextShotId += 1
            local CurrentShotId = NextShotId
            FireProjectileEvent:FireServer(StartCFrame, CurrentShotId)
            ProjectileObject.OnHit:Connect(function(HitPart: BasePart, HitPosition: Vector3)
                HitProjectileEvent:FireServer(CurrentShotId, HitPart, HitPosition)
            end)
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

    --Store the shot for client-reported hits
    local FireDelay = (Configuration and Configuration.FireDelay) or 0
    local SourcePlayer = Players:GetPlayerFromCharacter(Source)
    local Shots = SourcePlayer and self.ClientShots[SourcePlayer]
    local HitsReportedByClient = (ShotId ~= nil and Shots ~= nil)
    if ShotId and Shots then
        --Hits are reported by the client, so the server does not simulate the projectile
        Shots[ShotId] = {
            Projectile = ProjectileObject :: any,
            StartCFrame = StartCFrame,
            Speed = Preset.Speed,
            FireTime = tick() + FireDelay,
        }
        task.delay(FireDelay + Preset.LifetimeSeconds + 1, function()
            Shots[ShotId] = nil
            ProjectileObject:Destroy()
        end)
    end

    --Fire the projectile.
    if FireDelay > 0 then
        task.wait(FireDelay)
    end
    if not HitsReportedByClient then
        ProjectileObject:Fire(StartCFrame, Preset.Speed, Preset.LifetimeSeconds, {Source or Players.LocalPlayer.Character})
    end
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
        if NewTool:GetAttribute("ReloadStartTime") then return end
        local State = NewTool:FindFirstChild("State") :: Folder
        local Configuration = NewTool:FindFirstChild("Configuration") :: ModuleScript
        local Handle = NewTool:FindFirstChild("Handle") :: BasePart
        if not State or not Configuration or not Handle then return end
        local ConfigurationData = require(Configuration) :: Types.StandardConfiguration
        local RemainingRoundsValue = State:FindFirstChild("RemainingRounds") :: IntValue
        if not RemainingRoundsValue then return end

        --Return if the tool is not equipped, unless unequipped reloads are allowed.
        local AllowUnequippedReload = (ConfigurationData.AllowUnequippedReload == true)
        if not AllowUnequippedReload then
            if NewTool.Parent ~= Character then return end
            if Tool and Tool ~= NewTool then return end
        end

        --Play the reload sound.
        local StartAttachment = Handle:FindFirstChild("StartAttachment")
        local ReloadSound = nil
        if StartAttachment and NewTool.Parent == Character then
            local PresetModule = Presets:FindFirstChild(ConfigurationData.ProjectilePreset)
            ReloadSound = ConfigurationData.ReloadSound or (PresetModule and (require(PresetModule) :: Types.ProjectilePreset).DefaultReloadSound)
            if ReloadSound then
                LocalAudio:PlayAudio(ReloadSound, StartAttachment)
            end
        end

        --Reload the weapon.
        --Unequipping clears the start time, which cancels the reload.
        local ReloadStartTime = tick()
        NewTool:SetAttribute("ReloadStartTime", ReloadStartTime)
        local UnequippedEvent = nil
        if not AllowUnequippedReload then
            UnequippedEvent = NewTool.Unequipped:Once(function()
                NewTool:SetAttribute("ReloadStartTime", nil)
                if ReloadSound and StartAttachment then
                    LocalAudio:StopAudio(ReloadSound, StartAttachment)
                end
            end)
        end
        task.wait(ConfigurationData.ReloadTime)
        if UnequippedEvent then
            UnequippedEvent:Disconnect()
        end
        if NewTool:GetAttribute("ReloadStartTime") ~= ReloadStartTime then return end
        RemainingRoundsValue.Value = ConfigurationData.TotalRounds
        NewTool:SetAttribute("ReloadStartTime", nil)
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
        FireProjectileEvent.OnServerEvent:Connect(function(Player: Player, StartCFrame: CFrame, ShotId: number?)
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
            local LastFireTimeValue = State:FindFirstChild("LastFireTime") :: NumberValue
            local LastFireRemainingRoundsValue = State:FindFirstChild("LastFireRemainingRounds") :: NumberValue
            if not RemainingRoundsValue then return end

            --Return if the firing is invalid.
            if Tool:GetAttribute("ReloadStartTime") then return end
            if RemainingRoundsValue.Value <= 0 then return end
            if (StartCFrame.Position - Handle.Position).Magnitude > 10 and not Humnanoid.Sit and not Humnanoid.SeatPart then return end --Local trams do not replicate to the server, so the projectiles shots will claim to be far away.
            local IsCloseToLastFire = (tick() - LastFireTimeValue.Value < ConfigurationData.CooldownTime * 0.5)
            if IsCloseToLastFire and LastFireRemainingRoundsValue.Value <= 0 then return end

            --Fire the projectile.
            LastFireTimeValue.Value = tick()
            LastFireRemainingRoundsValue.Value = (IsCloseToLastFire and LastFireRemainingRoundsValue.Value - 1 or (ConfigurationData.ProjectilesPerRound or 1) - 1)
            RemainingRoundsValue.Value = RemainingRoundsValue.Value - 1
            self:Fire(StartCFrame, Handle, ConfigurationData.ProjectilePreset, Character, nil, typeof(ShotId) == "number" and ShotId or nil)
        end)

        --Connect hits reported by the client that fired the projectile.
        Players.PlayerAdded:Connect(function(Player)
            self.ClientShots[Player] = {}
        end)
        for _, Player in Players:GetPlayers() do
            self.ClientShots[Player] = {}
        end
        Players.PlayerRemoving:Connect(function(Player)
            self.ClientShots[Player] = nil
        end)
        HitProjectileEvent.OnServerEvent:Connect(function(Player: Player, ShotId: number, HitPart: BasePart, HitPosition: Vector3)
            local Shots = self.ClientShots[Player]
            local Shot = Shots and Shots[ShotId]
            if not Shot then return end
            if typeof(HitPart) ~= "Instance" or not HitPart:IsA("BasePart") or typeof(HitPosition) ~= "Vector3" then return end
            Shots[ShotId] = nil

            -- Reject hits that are off the projectile path, farther than it could travel, or too far from the part
            local Offset = Shot.StartCFrame:PointToObjectSpace(HitPosition)
            if Vector2.new(Offset.X, Offset.Y).Magnitude > 1 or Offset.Z > 1 then return end
            if -Offset.Z > Shot.Speed * (tick() - Shot.FireTime + 1) then return end
            if (HitPart.Position - HitPosition).Magnitude > (HitPart.Size.Magnitude / 2) + MAX_HIT_PART_DRIFT then return end

            --Reject hits blocked by the world
            local StartPosition = Shot.StartCFrame.Position
            local HitDistance = (HitPosition - StartPosition).Magnitude
            if HitDistance > 0.5 then
                local EndPosition = StartPosition + ((HitPosition - StartPosition).Unit * (HitDistance - 0.5))
                local IgnoreList: {Instance} = {HitPart}
                if Shot.Projectile.Source then
                    table.insert(IgnoreList, Shot.Projectile.Source)
                end
                while true do
                    local BlockingPart = Projectile.RayCast(StartPosition, EndPosition, IgnoreList)
                    if not BlockingPart then break end
                    local BlockingModel = BlockingPart.Parent
                    if not BlockingModel or not BlockingModel:FindFirstChildOfClass("Humanoid") then return end
                    table.insert(IgnoreList, BlockingModel)
                end
            end
            Shot.Projectile.OnHitEvent:Fire(HitPart, HitPosition, Shot.Projectile)
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