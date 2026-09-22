local ShapeMath = {}


-- Private Helper Methods


-- Extracts row and column integers from a plate instance's name
local function getRowColFromPlate(plate)
	local splits = string.split(plate.Name, "_")
	local row, col = tonumber(splits[2]), tonumber(splits[3])
	return row, col
end


-- Public Module API


-- Generates a square shape matrix of a given length
function ShapeMath.createSquareShape(length)
	assert(length > 0, "Length must be positive")
	
	local shape = {}
	local radius = math.floor(length / 2)
	
	for dr = -radius, radius do
		for dc = -radius, radius do
			table.insert(shape, { dr, dc, 1 })
		end
	end

	return shape
end

-- Generates a circular shape matrix of a given radius (To be implemented)
function ShapeMath.createCircleShape(radius)

end

-- Rotates a given shape matrix by the specified degrees
function ShapeMath.getRotatedShape(shape, rot)
	local newShape = {}
	if rot == 0 then return shape end
	
	for _, cell in ipairs(shape) do
		local dr, dc, strength = cell[1], cell[2], cell[3]
		
		if rot == 90 then
			table.insert(newShape, {-dc, dr, strength})
		elseif rot == 270 then
			table.insert(newShape, {dc, -dr, strength})
		elseif rot == 180 then
			table.insert(newShape, {-dr, -dc, strength})
		end
	end
	
	return newShape
end

-- Retrieves valid plates matching a shape relative to an origin point
function ShapeMath.getPlatesInShapeAtOrigin(origin, shape, includeDestroyed)
	local PlateStrengths = {}
	local originRow, originCol = origin[1], origin[2]

	for _, cell in ipairs(shape) do
		local dr, dc, strength = cell[1], cell[2], cell[3]
		local r = originRow + dr
		local c = originCol + dc

		local plate = workspace.Plates:FindFirstChild("Plate_" .. r .. "_" .. c)
		if plate then
			if plate:GetAttribute("HP") <= 0 and (not includeDestroyed) then
				continue
			end
			table.insert(PlateStrengths, {
				plate = plate,
				strength = strength
			})
		end
	end

	return PlateStrengths
end

-- Retrieves valid plates matching a shape relative to a target plate
function ShapeMath.getPlatesInShapeAtTargetPlate(targetPlate, shape, includeDestroyed)
	local row, col = getRowColFromPlate(targetPlate)
	local origin = {row, col}
	
	return ShapeMath.getPlatesInShapeAtOrigin(origin, shape, includeDestroyed)
end

return ShapeMath