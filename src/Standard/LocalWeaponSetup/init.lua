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
local GamepadInput = require(script:WaitForChild("Input"):WaitForChild("GamepadInput"))
local MouseInput = require(script:WaitForChild("Input"):WaitForChild("MouseInput"))
local TouchInput = require(script:WaitForChild("Input"):WaitForChild("TouchInput"))
local BaseCrosshair = require(script:WaitForChild("UI"):WaitForChild("BaseCrosshair"))
local MouseCrosshair = require(script:WaitForChild("UI"):WaitForChild("MouseCrosshair"))
local VRCrosshair = require(script:WaitForChild("UI"):WaitForChild("VRCrosshair"))

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
    local Input = CombinedInput.new(MouseInput.new(), TouchInput.new(), GamepadInput.new(Enum.KeyCode.ButtonR2))
    Input:ConnectReloadButton(Enum.KeyCode.ButtonY)

    local State = Tool:WaitForChild("State")
    local ChargedPercentValue = State:FindFirstChild("ChargedPercent") :: NumberValue
    local RemainingRounds = State:WaitForChild("RemainingRounds") :: IntValue
    local ReloadingValue = State:WaitForChild("Reloading") :: BoolValue

    local CurrentCrosshair: BaseCrosshair.BaseCrosshair? = nil
    local LastFireTime = 0
    local Equipped = false
    local Firing = false

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

        --Create the crosshair.
        local Crosshair = (UserInputService.VREnabled and VRCrosshair.new(StartAttachment) or MouseCrosshair.new())
        Crosshair:ConnectStandard(Tool)
        CurrentCrosshair = Crosshair

        --Update the aim if the user isn't in VR.
        if not UserInputService.VREnabled then
            local Character = Tool.Parent
            if not Character then return end

            local CrosshairAsMouse = (Crosshair :: MouseCrosshair.MouseCrosshair)
            while Equipped do
                local TargetPosition = Input:GetTargetScreenSpace()
                CrosshairAsMouse:MoveTo(TargetPosition)
                ProjectileReplication:Aim(Players.LocalPlayer, GetMousePosition())
                RunService.RenderStepped:Wait()
            end
        end
    end)
    Tool.Unequipped:Connect(function()
        Equipped = false
        Firing = false

        if CurrentCrosshair then
            CurrentCrosshair:Destroy()
            CurrentCrosshair = nil
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