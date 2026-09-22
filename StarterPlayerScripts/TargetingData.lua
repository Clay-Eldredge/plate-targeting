local Players = game.Players
local RS = game.ReplicatedStorage

local PlateHighlighting = require(script.Parent.PlateHighlighting)
local ShapeMath = require(RS.ModuleScripts.PlateTargeting.ShapeMath)
local Shapes = require(RS.ModuleScripts.PlateTargeting.Shapes)
local Cards = require(RS.ModuleScripts.Cards)

local TargetingData = {}


-- Core State Variables


TargetingData.CurrentCardID = nil
TargetingData.TargetShape = nil
TargetingData.CurrentTarget = nil
TargetingData.TargetStep = 1
TargetingData.Rotation = 0
TargetingData.IsDirectional = false

-- Device specific overrides
TargetingData.RayTarget = nil
TargetingData.MiniMapTarget = nil

-- Sequential targeting context buffers
TargetingData.TargetSaves = {nil, nil, nil}
TargetingData.DirectionSaves = {nil, nil, nil}
TargetingData.ShapeSaves = {nil, nil, nil}
TargetingData.IsDirectionalSaves = {nil, nil, nil}



-- Context Update Routines


function TargetingData.UpdateTargetShape(shapes)
	TargetingData.TargetShape = shapes[TargetingData.TargetStep]
end

function TargetingData.UpdateIsDirectional(directions)
	TargetingData.IsDirectional = directions[TargetingData.TargetStep]
end

function TargetingData.UpdateHighlightAndMapHighlight()
	local shape = TargetingData.TargetShape
	local rotatedShape = ShapeMath.getRotatedShape(shape, TargetingData.Rotation)
	
	local sendData = {
		target = TargetingData.CurrentTarget, 
		shape = rotatedShape,
		direction = TargetingData.Rotation,
		isDirectional = TargetingData.IsDirectional,
		targetStep = TargetingData.TargetStep,
		targetSaves = TargetingData.TargetSaves,
		directionSaves = TargetingData.DirectionSaves,
		isDirectionalSaves = TargetingData.IsDirectionalSaves,
		shapeSaves = TargetingData.ShapeSaves, -- already rotated
	}
		
	-- Dispatch synchronization logic
	PlateHighlighting.highlightTargeted(sendData)
	Players.LocalPlayer.PlayerGui.MainHUD.GridMapFrame.HighlightTargeted:Fire(sendData)
end


-- Getters & Setters


function TargetingData.getShape()
	return TargetingData.TargetShape
end

function TargetingData.setShape(newShape)
	TargetingData.TargetShape = newShape
end

function TargetingData.getCurrentTarget()
	return TargetingData.CurrentTarget
end

-- Syncs input source resolution with global targeting focus
function TargetingData.setCurrentTarget(newTarget, source)
	local previousTarget = TargetingData.CurrentTarget
	
	if source == "raycast" then
		TargetingData.RayTarget = newTarget
		if newTarget ~= nil then
			TargetingData.CurrentTarget = newTarget
		end
	end
	
	if source == "minimap" then
		TargetingData.MiniMapTarget = newTarget
		if newTarget ~= nil then
			TargetingData.CurrentTarget = newTarget
		end
	end
	
	if TargetingData.RayTarget == nil and TargetingData.MiniMapTarget == nil then
		TargetingData.CurrentTarget = nil
	end
	
	if previousTarget ~= TargetingData.CurrentTarget then
		TargetingData.UpdateHighlightAndMapHighlight()
	end
end


-- Action & Dispatch Handlers


-- Dispatches the finalized multi-target execution over the network boundary
function TargetingData.SubmitTargets()
	RS.RemoteEvents.SubmitTargets:FireServer(
		TargetingData.CurrentCardID, 
		TargetingData.TargetSaves, 
		TargetingData.DirectionSaves, 
		TargetingData.sel
	)
end

-- Processes interaction requests, managing sequence tracking logic
function TargetingData.PlateClicked(plate)
	if not plate then
		-- Deny double triggering when clicking through UI overlay
		if TargetingData.RayTarget then 
			plate = TargetingData.CurrentTarget 
		end
	end
	if not plate then return end
	
	-- Identify operational scope
	local selectionMode = Players.LocalPlayer:GetAttribute("SelectionMode")
	local maxSelections = 0
	if selectionMode == "SingleSelect" then
		maxSelections = 1
	elseif selectionMode == "DualSelect" then
		maxSelections = 2 
	elseif selectionMode == "TripleSelect" then
		maxSelections = 3
	end
	
	local currentStep = TargetingData.TargetStep
	local isLastStep = (currentStep == maxSelections)
	
	-- Cache sequence data
	TargetingData.TargetSaves[currentStep] = plate
	TargetingData.DirectionSaves[currentStep] = TargetingData.Rotation
	TargetingData.ShapeSaves[currentStep] = ShapeMath.getRotatedShape(
		TargetingData.TargetShape,
		TargetingData.Rotation
	)
	TargetingData.IsDirectionalSaves[currentStep] = TargetingData.IsDirectional
	
	TargetingData.TargetStep += 1
	
	if isLastStep then
		TargetingData.SubmitTargets()
		TargetingData.TargetStep = 1
	else
		-- Dispatch updates for sequential steps
		Players.LocalPlayer.PlayerGui.MainHUD.HandFrame.Parent.CardInfoFrame.UpdateText:Fire(
			Cards[TargetingData.CurrentCardID].Tooltips[TargetingData.TargetStep]
		)

		TargetingData.UpdateTargetShape(
			Cards[TargetingData.CurrentCardID].Shapes
		)
	end
end

-- Re-orients the targeted pattern overlay
function TargetingData.rotate()
	local newNum = TargetingData.Rotation + 90
	if newNum > 270 then newNum = 0 end
	TargetingData.Rotation = newNum
	
	if TargetingData.CurrentTarget then
		TargetingData.UpdateHighlightAndMapHighlight()
	end
end

-- Resets the environment from targeting mode gracefully
function TargetingData.TargetingOff()
	TargetingData.TargetSaves = {nil, nil, nil}
	TargetingData.DirectionSaves = {nil, nil, nil}
	TargetingData.ShapeSaves = {nil, nil, nil}
	TargetingData.IsDirectionalSaves = {nil, nil, nil}
	
	local sendData = {
		target = nil, 
		deleteSaves = true,
	}
	
	PlateHighlighting.highlightTargeted(sendData)
	Players.LocalPlayer.PlayerGui.MainHUD.GridMapFrame.HighlightTargeted:Fire(sendData)
	
	TargetingData.TargetStep = 1
end

return TargetingData