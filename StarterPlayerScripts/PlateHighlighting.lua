local RS = game.ReplicatedStorage

local ShapeMath = require(RS.ModuleScripts.PlateTargeting.ShapeMath)

local TARGET_COLOR_PALETTES = {
	-- 1: Red
	{
		Color3.fromRGB(255,   0,   0),
		Color3.fromRGB(255,  75,  75),
		Color3.fromRGB(255, 102, 102),
		Color3.fromRGB(255, 152, 152),
		Color3.fromRGB(255, 181, 181),
	},
	-- 2: Purple
	{
		Color3.fromRGB(200,   0, 255),
		Color3.fromRGB(231, 110, 255),
		Color3.fromRGB(226, 138, 255),
		Color3.fromRGB(233, 176, 255),
		Color3.fromRGB(241, 205, 255),
	},
	-- 3: Green
	{
		Color3.fromRGB(  0, 255, 115),
		Color3.fromRGB( 78, 255, 181),
		Color3.fromRGB(131, 255, 199),
		Color3.fromRGB(162, 255, 209),
		Color3.fromRGB(193, 255, 221),
	}
}

local PlateHighlighting = {}


-- Directional Overlay Utilities


local function showArrow(plate, direction)
	local arrow = plate.ArrowModel.ArrowUnion
	local weld = plate.ArrowModel.ArrowRootPart.ArrowUnion -- The weld

	arrow.Transparency = 0

	-- 1: Pick canonical world direction (+Z)
	local lookDir = Vector3.new(1, 0, 0)

	-- 2: Make a world CFrame facing that direction, upright
	local baseWorldCFrame = CFrame.lookAt(Vector3.zero, lookDir, Vector3.yAxis)

	-- 3: Apply rotation around Y based on direction (0, 90, 180, 270)
	local yaw = math.rad(-direction or 0)
	local rotatedWorldCFrame = baseWorldCFrame * CFrame.Angles(0, yaw, 0)

	-- 4: Convert world rotation to weld local space
	weld.C0 = weld.Part0.CFrame:Inverse() * (CFrame.new(weld.Part0.Position) * rotatedWorldCFrame)
end

local function hideArrow(plate)
	plate.ArrowModel.ArrowUnion.Transparency = 1
end


-- Visual State Updaters


-- Paints target shape logic onto adjacent geometry
local function HighlightShapeAt(targetPlate, shape, direction, isDirectional, step, saved)
	local plateStrengths = ShapeMath.getPlatesInShapeAtTargetPlate(targetPlate, shape)
	
	for _, PS in pairs(plateStrengths) do
		if PS.plate:GetAttribute("HP") <= 0 then
			continue -- Exclude destroyed geometry
		end
		
		PlateHighlighting.highlightPlateWithStrength(PS.plate, PS.strength, step)
		
		if saved then 
			PS.plate.Highlight.Saved.Value = true 
		end
		
		if PS.plate == targetPlate and isDirectional then
			showArrow(PS.plate, direction)
		end
	end
end


-- Public Highlighting API


-- Clears selection state for all plates across the workspace
function PlateHighlighting.deselectAll(step, deleteSaves)
	for _, plate in pairs(workspace.Plates:GetChildren()) do
		if plate.Highlight.Saved.Value == true and not (step == 1) and not deleteSaves then
			continue -- Skip if saved, unless step 1 or deleteSaves == true
		end
		
		plate.Highlight.Enabled = false
		plate.Highlight.Saved.Value = false
		hideArrow(plate)
	end
end

function PlateHighlighting.highlightPlateWithStrength(plate, strength, targetStep)
	local H = plate.Highlight
	H.FillColor = TARGET_COLOR_PALETTES[targetStep][strength]
	H.Enabled = true
end

-- Refreshes highlight displays based on current multi-targeting context
function PlateHighlighting.highlightTargeted(data)
	PlateHighlighting.deselectAll(data.targetStep, data.deleteSaves)
	if data.target == nil then return end
	
	-- Render First Save
	if data.targetStep > 1 then
		HighlightShapeAt(
			data.targetSaves[1], 
			data.shapeSaves[1], 
			data.directionSaves[1], 
			data.isDirectionalSaves[1],
			1, true
		)
	end
	
	-- Render Second Save
	if data.targetStep > 2 then
		HighlightShapeAt(
			data.targetSaves[2], 
			data.shapeSaves[2], 
			data.directionSaves[2], 
			data.isDirectionalSaves[2],
			2, true
		)
	end
	
	-- Render Active Pointer Context
	HighlightShapeAt(
		data.target, 
		data.shape, 
		data.direction, 
		data.isDirectional,
		data.targetStep,
		false
	)
end

return PlateHighlighting