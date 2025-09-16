--Passthrough of LocalTween for Wally distribution.
--!strict

local LocalTween = require(script.Parent.Parent.Parent:WaitForChild("LocalTween"))

export type LocalTween = LocalTween.LocalTween

return LocalTween