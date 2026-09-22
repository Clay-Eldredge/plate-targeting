local RS = game.ReplicatedStorage
local UIS = game.UserInputService
local GuiService = game.GuiService
local Players = game.Players

local GetTarget = require(script.GetTarget)
local TargetingData = require(script.TargetingData)


-- Pointer Detection Hooks


local function MouseMove(input)
	local targetPlate = GetTarget(input)
	TargetingData.setCurrentTarget(targetPlate, "raycast")
end

script.MouseTargetUpdate.Event:Connect(function()
	local targetPlate = GetTarget()
	TargetingData.setCurrentTarget(targetPlate, "raycast")
end)


-- Global Input Processing


UIS.InputChanged:Connect(function(input)
	local inputType = input.UserInputType
	local selectionMode = Players.LocalPlayer:GetAttribute("SelectionMode")
	
	-- Handle Dynamic Hovering
	if inputType == Enum.UserInputType.MouseMovement and selectionMode ~= "Off" then
		task.spawn(function() MouseMove(input) end)
	end
	
	if inputType == Enum.UserInputType.Touch then
		task.spawn(function() MouseMove(input) end)
	end
end)

UIS.InputBegan:Connect(function(input)
	local inputType = input.UserInputType
	local selectionMode = Players.LocalPlayer:GetAttribute("SelectionMode")
	
	if selectionMode == "Off" then return end
	
	-- Handle Confirmation and Interaction Actions
	if selectionMode == "SingleSelect" 
		or selectionMode == "DualSelect" 
		or selectionMode == "TripleSelect" then
		
		-- Rotation
		if input.KeyCode == Enum.KeyCode.R then
			task.spawn(function() TargetingData.rotate() end)
		end
		
		-- Selection
		if inputType == Enum.UserInputType.MouseButton1 then
			task.spawn(function() TargetingData.PlateClicked() end)
		end
	end
end)