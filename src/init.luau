--Handles replication of projectiles.
--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Projectile = require(script:WaitForChild("Projectile"))
local LocalAudio = require(script:WaitForChild("LocalAudio"))
local LocalTween = require(script:WaitForChild("LocalTween"))
local Appendage = require(script:WaitForChild("NexusAppendage"):WaitForChild("Appendage"))
local Types = require(script:WaitForChild("Types"))
local LocalWeaponSetup = require(script:WaitForChild("Standard"):WaitForChild("LocalWeaponSetup"))
local Presets = ReplicatedStorage:WaitForChild("Data"):WaitForChild("ProjectilePresets")

local ProjectileReplication = {}
ProjectileReplication.SetUpCalled = false
local UpdateAimFunctions = {}
setmetatable(UpdateAimFunctions, {__mode="k"})
local LastAimUpdateTimes = {}
setmetatable(LastAimUpdateTimes, {__mode="k"})

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
            local FiringPlayer = Players:GetPlayerFromCharacter(Source)
            for _, Player in Players:GetPlayers() do
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
function ProjectileReplication.Aim(self: ProjectileReplication, Player: Player, AimPosition: Vector3, SendTime: number?): ()
    SendTime = SendTime or tick()

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
        if not ToolConfigurationModule then return end
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
            LastAimUpdateTimes[Character] = nil

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

    --Drop the update if the last update time is after the previous one.
    --UnreliableRemoteEvents do not guarentee ordering. It is better to drop old packets instead of showing out of order updates.
    if LastAimUpdateTimes[Character] and LastAimUpdateTimes[Character] > SendTime then return end
    LastAimUpdateTimes[Character] = SendTime

    --Update the aim.
    if not UpdateAimFunctions[Character] then return end
    UpdateAimFunctions[Character](AimPosition)

    --Replicate the aim.
    if Player ~= Players.LocalPlayer then return end
    UpdateAimEvent:FireServer(AimPosition, SendTime)
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
        FireProjectileEvent.OnClientEvent:Connect(function(StartCFrame: CFrame, Source: Model, FirePart: BasePart, PresetName: string)
            self:Fire(StartCFrame, FirePart, PresetName, Source, true)
        end)

        --Connect the aim updating.
        UpdateAimEvent.OnClientEvent:Connect(function(Player: Player, AimPosition: Vector3, SendTime: number)
            self:Aim(Player, AimPosition, SendTime)
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
            (self :: any):Fire(StartCFrame, Handle, ConfigurationData.ProjectilePreset, Character)
        end)

        --Connect requests for reloading.
        ReloadEvent.OnServerEvent:Connect(function(Player: Player, Tool: Tool?)
            self:Reload(Player, Tool)
        end)

        --Connect requests for updating the aim of players.
        UpdateAimEvent.OnServerEvent:Connect(function(Player: Player, AimPosition: Vector3, SendTime: number)
            --Determine if the player can aim.
            local Character = Player.Character :: Model
            if not Character then return end
            local Humnanoid = Character:FindFirstChildOfClass("Humanoid") :: Humanoid
            local Tool = Character:FindFirstChildOfClass("Tool") :: Tool
            if not Humnanoid or Humnanoid.Health <= 0 or not Tool then return end

            --Send the aim requests.
            for _, OtherPlayer in Players:GetPlayers() do
                if Player ~= OtherPlayer then
                    UpdateAimEvent:FireClient(OtherPlayer, Player, AimPosition, SendTime)
                end
            end
        end)
    end
end



return ProjectileReplication