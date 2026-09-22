local Plate = require(script.Parent.Plate)

local RS = game.ReplicatedStorage
local PLATE_LEN = RS.GameConstants.PlateLength.Value
local SPACING = RS.GameConstants.Spacing.Value

local STEP = PLATE_LEN + SPACING
local HALF = PLATE_LEN / 2

local Grid = {}
Grid.gridTable = {}


-- Grid Generation


-- Instantiates the full interactive grid
function Grid.createFullGrid(origin, rows)
	RS.GameConstants.Rows.Value = rows
	
	local g = {}
	for r = 1, rows do
		local curRow = {}
		for c = 1, rows do
			table.insert(curRow, Plate.new(origin, r, c, {cosmeticGroupName = "Scroom"}))
		end
		table.insert(g, curRow)
	end
	
	Grid.gridTable = g
end

-- Instantiates a grid and applies structural damage in a pattern
function Grid.createGridWithPattern(origin, rows, pattern)
	Grid.createFullGrid(origin, rows)
	
	-- Carve out pattern with damage
end

-- Deletes all plates in the current grid
function Grid.clearGrid()
	for r, row in pairs(Grid.gridTable) do
		for c, plate in pairs(row) do
			plate:delete()
		end
	end
end


-- Grid Lookups


-- Returns a specific plate by grid coordinates
function Grid.getPlate(row, col)
	return Grid.gridTable[row][col]
end

-- Returns a random plate from the active grid
function Grid.getRandomPlate()
	local row = math.random(1, #Grid.gridTable)
	local col = math.random(1, #Grid.gridTable[1])
	
	return Grid.getPlate(row, col)
end

-- Returns the plate object associated with a given model
function Grid.getPlateFromModel(model)
	if not model then return nil end
	if model.Parent.Name ~= "Plates" then return nil end
	
	local splits = string.split(model.Name, "_")
	local row, col = tonumber(splits[2]), tonumber(splits[3])
	
	return Grid.getPlate(row, col)
end

-- Calculates and returns the plate at a specific world position
function Grid.getPlateFromPosition(pos)
	local x = pos.X
	local z = pos.Z

	-- Compute row/col directly
	local row = math.floor(x / STEP) + 1
	local col = math.floor(z / STEP) + 1

	-- Enforce index bounds
	if row < 1 or col < 1 or row > #Grid.gridTable or col > #Grid.gridTable[1] then
		return nil
	end

	-- Enforce plate bounds (exclude spacing)
	local offsetX = x % STEP
	local offsetZ = z % STEP
	if offsetX > PLATE_LEN or offsetZ > PLATE_LEN then
		return nil
	end

	return Grid.gridTable[row][col]
end

-- Validates that a plate has active HP objects
function Grid.verifyPlate(plate)
	if plate.hp_objects then return plate end
	return nil
end

return Grid