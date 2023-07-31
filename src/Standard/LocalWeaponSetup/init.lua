--[[
TheNexusAvenger

Sets up a weapon on the client.
Moved out of LocalWeapon to make it safe for destroying.
--]]
--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local CombinedInput = require(script:WaitForChild("Input"):WaitForChild("CombinedInput"))
local MouseInput = require(script:WaitForChild("Input"):WaitForChild("MouseInput"))
local TouchInput = require(script:WaitForChild("Input"):WaitForChild("TouchInput"))

local LocalWeaponSetup = {}



--[[
Sets up a tool.
--]]
function LocalWeaponSetup:SetupTool(Tool: Tool): ()
    local ProjectileReplicationModule = script.Parent.Parent
    local ProjectileReplication = require(ProjectileReplicationModule) :: any
    
    local Handle = Tool:WaitForChild("Handle")
    local StartAttachment = Handle:WaitForChild("StartAttachment") :: Attachment
    local Configuration = require(Tool:WaitForChild("Configuration")) :: any
    local Input = CombinedInput.new(MouseInput.new(), TouchInput.new())

    local State = Tool:WaitForChild("State")
    local ChargedPercentValue = State:FindFirstChild("ChargedPercent") :: NumberValue
    local RemainingRounds = State:WaitForChild("RemainingRounds") :: IntValue
    local ReloadingValue = State:WaitForChild("Reloading") :: BoolValue

    local CurrentVRAmmoGui: BillboardGui? = nil
    local LastFireTime = 0
    local Equipped = false
    local Firing = false

    --[[
    Converts a number of projectiles to a display number.
    --]]
    local function GetDisplayProjectiles(Projectiles: number): string
        return tostring(math.floor(Projectiles / (Configuration.ProjectilesPerRound or 1)))
    end

    --[[
    Returns the current mouse position using the same raycasting
    logic used by the projectiles.
    --]]
    local function GetMousePosition(): Vector3
        if UserInputService.VREnabled then
            return (StartAttachment.WorldCFrame * CFrame.new(0, 0, -10000)).Position
        end
        return Input:GetTargetWorldSpace()
    end

    --[[
    Fires the weapon.
    --]]
    local function Fire(): ()
        if not Equipped then return end
        for _ = 1, Configuration.ProjectilesPerRound or 1 do
            ProjectileReplication:Fire(CFrame.new(StartAttachment.WorldPosition, GetMousePosition()) * CFrame.Angles(0, 0, math.random() * math.pi * 2) * CFrame.Angles(math.random() * Configuration.ProjectileSpread, 0, 0), Handle, Configuration.ProjectilePreset)
        end
    end

    --[[
    Tries to reload the weapon.
    --]]
    local function TryReload(): ()
        if ReloadingValue.Value then return end
        ReloadingValue.Value = true
        ProjectileReplication:Reload(Players.LocalPlayer, Tool)
    end

    --[[
    Tries to fire the weapon.
    --]]
    local function TryFire(): ()
        --Return if there are no rounds or the last fire was too recent.
        if ReloadingValue.Value then return end
        if RemainingRounds.Value <= 0 then
            TryReload()
            return
        end
        if tick() - LastFireTime < Configuration.CooldownTime then return end

        --Fire the weapon.
        LastFireTime = tick()
        RemainingRounds.Value = RemainingRounds.Value - 1
        Fire()
    end



    --Connect equipping and unequipping the tool.
    Tool.Equipped:Connect(function()
        Equipped = true

        --Handle VR and non-VR players.
        --The crosshair is not supported for VR users and animating the arms is not recommended.
        local CrosshairGui, CrossFrame, AmmoText, ReloadingText = nil, nil, nil, nil
        if UserInputService.VREnabled then
            --Create the ammo display.
            local NewVRAmmoGui = Instance.new("BillboardGui")
            NewVRAmmoGui.Name = "WeaponCrosshair"
            NewVRAmmoGui.StudsOffsetWorldSpace = Vector3.new(-1.2, 0, 0)
            NewVRAmmoGui.Size = UDim2.new(3, 0, 0.75, 0)
            NewVRAmmoGui.Adornee = StartAttachment
            NewVRAmmoGui.Parent = StartAttachment
            CurrentVRAmmoGui = NewVRAmmoGui

            AmmoText = Instance.new("TextLabel")
            AmmoText.Name = "AmmoText"
            AmmoText.BackgroundTransparency = 1
            AmmoText.Size = UDim2.new(1, 0, 0.7, 0)
            AmmoText.Position = UDim2.new(0, 0, 0, 0)
            AmmoText.Font = Enum.Font.SciFi
            AmmoText.TextColor3 = Color3.new(1, 1, 1)
            AmmoText.TextStrokeColor3 = Color3.new(0, 0, 0)
            AmmoText.TextStrokeTransparency = 0
            AmmoText.TextScaled = true
            AmmoText.TextXAlignment = Enum.TextXAlignment.Center
            AmmoText.Text = GetDisplayProjectiles(RemainingRounds.Value).." / "..GetDisplayProjectiles(Configuration.TotalRounds)
            AmmoText.Parent = NewVRAmmoGui

            ReloadingText = Instance.new("TextLabel")
            ReloadingText.Name = "ReloadingText"
            ReloadingText.BackgroundTransparency = 1
            ReloadingText.Size = UDim2.new(1, 0, 0.35, 0)
            ReloadingText.Position = UDim2.new(0, 0, 0.65, 0)
            ReloadingText.Visible = ReloadingValue.Value
            ReloadingText.Font = Enum.Font.SciFi
            ReloadingText.TextColor3 = Color3.new(1, 1, 1)
            ReloadingText.TextStrokeColor3 = Color3.new(0, 0, 0)
            ReloadingText.TextStrokeTransparency = 0
            ReloadingText.TextScaled = true
            ReloadingText.TextXAlignment = Enum.TextXAlignment.Center
            ReloadingText.Text = "Reloading"
            ReloadingText.Parent = NewVRAmmoGui
        else
            --Create the crosshair.
            UserInputService.MouseIconEnabled = false
            CrosshairGui = Instance.new("ScreenGui")
            CrosshairGui.Name = "CrossHairGui"
            CrosshairGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

            CrossFrame = Instance.new("Frame")
            CrossFrame.Name = "Crosshair"
            CrossFrame.BackgroundTransparency = 1
            CrossFrame.AnchorPoint = Vector2.new(0.5, 0.5)
            CrossFrame.Size = UDim2.new(0.075, 0, 0.075, 0)
            CrossFrame.SizeConstraint = Enum.SizeConstraint.RelativeYY
            CrossFrame.Parent = CrosshairGui

            local CrosshairTop = Instance.new("Frame")
            CrosshairTop.Name = "CrosshairTop"
            CrosshairTop.BackgroundColor3 = Color3.new(1, 1, 1)
            CrosshairTop.BorderColor3 = Color3.new(0, 0, 0)
            CrosshairTop.Size = UDim2.new(0, 2, 0.3, 0)
            CrosshairTop.Position = UDim2.new(0.5, 0, 0, 0)
            CrosshairTop.AnchorPoint = Vector2.new(0.5, 0)
            CrosshairTop.Parent = CrossFrame

            local CrosshairBottom = Instance.new("Frame")
            CrosshairBottom.Name = "CrosshairBottom"
            CrosshairBottom.BackgroundColor3 = Color3.new(1, 1, 1)
            CrosshairBottom.BorderColor3 = Color3.new(0, 0, 0)
            CrosshairBottom.Size = UDim2.new(0, 2, 0.3, 0)
            CrosshairBottom.Position = UDim2.new(0.5, 0, 1, 0)
            CrosshairBottom.AnchorPoint = Vector2.new(0.5, 1)
            CrosshairBottom.Parent = CrossFrame

            local CrosshairLeft = Instance.new("Frame")
            CrosshairLeft.Name = "CrosshairLeft"
            CrosshairLeft.BackgroundColor3 = Color3.new(1, 1, 1)
            CrosshairLeft.BorderColor3 = Color3.new(0, 0, 0)
            CrosshairLeft.Size = UDim2.new(0.3, 0, 0, 2)
            CrosshairLeft.Position = UDim2.new(0, 0, 0.5, 0)
            CrosshairLeft.AnchorPoint = Vector2.new(0, 0.5)
            CrosshairLeft.Parent = CrossFrame

            local CrosshairRight = Instance.new("Frame")
            CrosshairRight.Name = "CrosshairRight"
            CrosshairRight.BackgroundColor3 = Color3.new(1, 1, 1)
            CrosshairRight.BorderColor3 = Color3.new(0, 0, 0)
            CrosshairRight.Size = UDim2.new(0.3, 0, 0, 2)
            CrosshairRight.Position = UDim2.new(1, 0, 0.5, 0)
            CrosshairRight.AnchorPoint = Vector2.new(1, 0.5)
            CrosshairRight.Parent = CrossFrame

            AmmoText = Instance.new("TextLabel")
            AmmoText.Name = "AmmoText"
            AmmoText.BackgroundTransparency = 1
            AmmoText.Size = UDim2.new(5, 0, 0.4, 0)
            AmmoText.Position = UDim2.new(0.7, 2, 0.55, 2)
            AmmoText.Font = Enum.Font.SciFi
            AmmoText.TextColor3 = Color3.new(1, 1, 1)
            AmmoText.TextStrokeColor3 = Color3.new(0, 0, 0)
            AmmoText.TextStrokeTransparency = 0
            AmmoText.TextScaled = true
            AmmoText.TextXAlignment = Enum.TextXAlignment.Left
            AmmoText.Text = GetDisplayProjectiles(RemainingRounds.Value).." / "..GetDisplayProjectiles(Configuration.TotalRounds)
            AmmoText.Parent = CrossFrame

            ReloadingText = Instance.new("TextLabel")
            ReloadingText.Name = "ReloadingText"
            ReloadingText.BackgroundTransparency = 1
            ReloadingText.Size = UDim2.new(5, 0, 0.3, 0)
            ReloadingText.Position = UDim2.new(0.8, 2, 0.9, 2)
            ReloadingText.Visible = ReloadingValue.Value
            ReloadingText.Font = Enum.Font.SciFi
            ReloadingText.TextColor3 = Color3.new(1, 1, 1)
            ReloadingText.TextStrokeColor3 = Color3.new(0, 0, 0)
            ReloadingText.TextStrokeTransparency = 0
            ReloadingText.TextScaled = true
            ReloadingText.TextXAlignment = Enum.TextXAlignment.Left
            ReloadingText.Text = "Reloading"
            ReloadingText.Parent = CrossFrame
        end

        --Connect the ammo changing.
        if AmmoText then
            RemainingRounds.Changed:Connect(function()
                AmmoText.Text = GetDisplayProjectiles(RemainingRounds.Value).." / "..GetDisplayProjectiles(Configuration.TotalRounds)
            end)
        end
        if ReloadingText then
            ReloadingValue.Changed:Connect(function()
                ReloadingText.Visible = ReloadingValue.Value
            end)
        end

        --Update the aim if the user isn't in VR.
        if CrossFrame then
            local Character = Tool.Parent
            if not Character then return end
            while Equipped do
                --Update the crosshair in a pcall. If the mouse becomes inactive, it throws an error.
                local CrosshairUpdated, _ = pcall(function()
                    local TargetPosition = Input:GetTargetScreenSpace()
                    CrossFrame.Position = UDim2.new(0, TargetPosition.X, 0, TargetPosition.Y)
                    ProjectileReplication:Aim(Players.LocalPlayer, GetMousePosition())
                end)
                if not CrosshairUpdated then
                    break
                end
                RunService.RenderStepped:Wait()
            end

            --Destroy the crosshair.
            CrosshairGui:Destroy()
        end
    end)

    Tool.Unequipped:Connect(function()
        Equipped = false
        Firing = false
        UserInputService.MouseIconEnabled = true

        if CurrentVRAmmoGui then
            CurrentVRAmmoGui:Destroy()
            CurrentVRAmmoGui = nil
        end
    end)

    --Connect using the tool.
    Input.StartFire:Connect(function()
        if not Equipped then return end
        if Configuration.FullAutomatic then
            Firing = true
            if ChargedPercentValue then
                while ChargedPercentValue.Value < 1 do
                    task.wait()
                end
            end
            while Firing and (not ChargedPercentValue or ChargedPercentValue.Value >= 1) do
                TryFire()
                task.wait(Configuration.CooldownTime)
            end
        else
            TryFire()
        end
    end)
    Input.EndFire:Connect(function()
        Firing = false
    end)
    Input.Reload:Connect(TryReload)
end

--[[
Binds the tool setup to a different script.
Calls to SetupTool will not properly clear when destroyed. This ensures that SetupTool
is actually called in a different script that can perform the cleanup.
--]]
function LocalWeaponSetup:Bind(): ()
    local OriginalSetupTool = self.SetupTool
    local BindableFunction = Instance.new("BindableFunction")
    BindableFunction.OnInvoke = function(...)
        OriginalSetupTool(self, ...)
    end
    self.SetupTool = function(_, ...)
        BindableFunction:Invoke(...)
    end
end



return LocalWeaponSetup