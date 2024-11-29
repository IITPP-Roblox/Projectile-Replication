--Creates a part in Workspace that destroys tools.
--!strict

local DestroyPart = Instance.new("Part")
DestroyPart.BrickColor = BrickColor.new("Really red")
DestroyPart.Size = Vector3.new(10, 1, 10)
DestroyPart.CFrame = CFrame.new(0, 0, -15)
DestroyPart.Anchored = true
DestroyPart.Parent = game:GetService("Workspace")

DestroyPart.Touched:Connect(function(TouchPart)
    local Tool = (TouchPart.Parent :: Model):FindFirstChildOfClass("Tool") :: Tool
    if not Tool then return end
    Tool:Destroy()
end)