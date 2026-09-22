local RS = game.ReplicatedStorage

local CosmeticVariants = require(script.CosmeticVariants)
local PlateObject = require(script.PlateObject)

local SPACING = RS.GameConstants.Spacing.Value
local PLATE_LEN = RS.GameConstants.PlateLength.Value

local DEFAULT_COSMETIC_GROUP_NAME = "Scroom"
	
local Plate = {}
Plate.__index = Plate


-- Private Helper Methods


-- Calculates exact world space coordinates based on grid row/col
local function determineWorldPos(origin, row, col)
	local half = PLATE_LEN / 2
	
	local x = origin.X + ((row - 1) * (PLATE_LEN + SPACING)) + half
	local y = origin.Y
	local z = origin.Z + ((col - 1) * (PLATE_LEN + SPACING)) + half
	
	return Vector3.new(x, y, z)
end

-- Determines cosmetic model loadout based on variant weight pools
local function selectCosmeticModels(cosmeticGroupName)
	local pool = CosmeticVariants[cosmeticGroupName]
	assert(pool, "Invalid cosmetic group: " .. tostring(cosmeticGroupName))

	-- 1. Sum weights
	local totalWeight = 0
	for _, variant in ipairs(pool) do
		totalWeight += variant.probabilityMult
	end

	-- 2. Roll
	local roll = math.random() * totalWeight
	local cumulative = 0

	-- 3. Find bucket
	for _, variant in ipairs(pool) do
		cumulative += variant.probabilityMult
		if roll <= cumulative then
			return variant.modelNames
		end
	end
end

-- Maps numerical HP values to corresponding damage level tiers
local function convertDmgToDmgLevel(dmg)
	if dmg > 75 then
		return 1
	elseif dmg > 50 then
		return 2
	elseif dmg > 25 then
		return 3
	else 
		return 4
	end
end


-- Constructor & Init


function Plate.new(origin, row, col, params)
	local self = setmetatable({}, Plate)
	
	self:create(origin, row, col, params)
	self:initializeHP(params)
	
	return self
end

-- Handles physical model instancing and placement
function Plate:create(origin, row, col, params)
	self.cosmeticModels = selectCosmeticModels(params.cosmeticGroupName or DEFAULT_COSMETIC_GROUP_NAME)

	local plate = RS.Models.PlateModels.Plate:Clone()
	plate.RootPart.Anchored = true
	plate.Parent = workspace.Plates
	
	local worldPos = determineWorldPos(origin, row, col)
	local randInt = math.random(0, 3)
	plate:PivotTo(
		CFrame.new(worldPos) * CFrame.Angles(0, math.rad(randInt * 90), 0)
	)

	plate.Name = "Plate_" .. row .. "_" .. col
	self.model = plate
	
	self:changeCosmeticModelTo(self.cosmeticModels[1])
end

-- Sets initial health parameters and attributes
function Plate:initializeHP(params)
	local hp = params.hp or 100
	self.hp = hp
	self.maxhp = hp
	
	self.model:SetAttribute("MaxHP", self.maxhp)
	self.model:SetAttribute("HP", self.hp)
	self.model:SetAttribute("TotalMaxStructureHP", 0)
	self.model:SetAttribute("TotalStructureHP", 0)
	
	self.hp_objects = {}
end

function Plate:delete()
	self.model:Destroy()
end


-- Visual & Highlight Methods


function Plate:highlight(fillColor, fillTransparency, outlineColor, outlineTransparency)
	local h = self.model.Highlight
	
	h.FillColor = fillColor
	h.FillTransparency = fillTransparency
	h.OutlineColor = outlineColor
	h.OutlineTransparency = outlineTransparency
	h.Enabled = true
end

function Plate:removeHighlight()
	self.model.Highlight.Enabled = false
end

function Plate:changeCosmeticModelTo(modelName)
	if #self.model:WaitForChild("CosmeticParts"):GetChildren() > 0 then
		self.model.CosmeticParts:GetChildren()[1]:Destroy()
	end
	
	local cosModel = RS.Models.PlateModels[modelName]:Clone()
	cosModel.Parent = self.model.CosmeticParts
	self.model.RootPart.CosmeticRootPart.Part1 = cosModel.CosmeticRootPart
end


-- Health & Damage Operations


-- Modifies plate HP and updates its physical cosmetic damage tier
function Plate:editHp(amount)
	local oldHpLvl = convertDmgToDmgLevel(self.hp)
	local oldHp = self.hp
		
	self.hp = math.min(math.max(self.hp + amount, 0), self.maxhp)
	self.model:SetAttribute("HP", self.hp)

	local newHpLvl = convertDmgToDmgLevel(self.hp)

	if oldHpLvl ~= newHpLvl then
		local modelName = self.cosmeticModels[newHpLvl]
		self:changeCosmeticModelTo(modelName)
	end
	
	return oldHpLvl, newHpLvl, oldHp, self.hp
end

-- Applies damage routing through structural layers
function Plate:damage(amount, sourcePlayer)
	local hpTarget, index = self:getHpTarget()
	if hpTarget then
		local destroyed, hpLost, maxStructureHp = hpTarget:editHp(-amount)
		self:editTotalStructureHp(-hpLost)
		if destroyed then
			self:editTotalMaxStructureHp(-maxStructureHp)
			table.remove(self.hp_objects, index)
		end
		return -- END FUNCTION
	end
	
	local oldHpLevel, newHpLvl, oldHp, newHp = self:editHp(-amount)
	-- Damage particle effect here

	if oldHp > 0 and newHp <= 0 then
		self:destroyByDamage(sourcePlayer)
	end
end

-- Handles health recovery and potential plate restoration
function Plate:heal(amount, sourcePlayer)
	local hpTarget, index = self:getHpTarget()
	if hpTarget then
		local destroyed, hpLost, maxStructureHp = hpTarget:editHp(-amount)
		self:editTotalStructureHp(-hpLost)
		if destroyed then
			self:editTotalMaxStructureHp(-maxStructureHp)
			table.remove(self.hp_objects, index)
		end
		return -- END FUNCTION
	end
	
	local oldHpLevel, newHpLvl, oldHp, newHp = self:editHp(amount)
	-- Heal particle effect here
	
	if oldHp <= 0 and newHp > 0 then
		self:restoreByHealing(sourcePlayer)
	end
end

function Plate:destroyByDamage(sourcePlayer)
	if #self.model:WaitForChild("CosmeticParts"):GetChildren() > 0 then
		self.model.CosmeticParts:GetChildren()[1]:Destroy()
	end
	self.model.RootPart.CanCollide = false
end

function Plate:restoreByHealing(sourcePlayer)
	self.model.RootPart.CanCollide = true
end


-- Entity Attachment Methods


function Plate:addHpObject(name, hp, model, destroyFunction, createFunction, statusEffect, TouchResultsOnOther, TouchResultsOnSelf, TouchResultFunctions, InherentTypes)
	if not hp then hp = 100 end
	
	local PO = PlateObject.new(
		self.model, name, hp, model, 
		destroyFunction, createFunction, statusEffect,
		TouchResultsOnOther, TouchResultsOnSelf, 
		TouchResultFunctions, InherentTypes
	)
	
	table.insert(self.hp_objects, PO)
	
	self:editTotalMaxStructureHp(hp)
	self:editTotalStructureHp(hp)
end

function Plate:getHpTarget()
	if #self.hp_objects <= 0 then
		return nil, nil
	else
		return self.hp_objects[1], 1 -- Return top of stack
	end
end

function Plate:editTotalMaxStructureHp(amount)
	local newAmount = self.model:GetAttribute("TotalMaxStructureHP") + amount
	self.model:SetAttribute("TotalMaxStructureHP", newAmount)
end

function Plate:editTotalStructureHp(amount)
	local newAmount = self.model:GetAttribute("TotalStructureHP") + amount
	self.model:SetAttribute("TotalStructureHP", newAmount)
end


-- Status & Interaction Logic


function Plate:giveStatus()
	
end

function Plate:removeStatus()
	
end

function Plate:touchHpObjects(touchingTypes)
	for _, hpObject in ipairs(self.hp_objects) do
		hpObject:touch(touchingTypes)
	end
end

function Plate:touchLastingEffects(touchingTypes)
	warn("DONT FORGET TO IMPLEMENT LASTING EFFECT TOUCHING")
end

function Plate:touch(touchingTypes)
	self:touchHpObjects(touchingTypes)
	self:touchLastingEffects(touchingTypes)
end

-- Retrieves all types associated with bound structures
function Plate:getTypes()
	local typesList = {}
	for _, structure in ipairs(self.hp_objects) do
		for _, t in ipairs(structure:getTypes()) do
			table.insert(typesList, t)
		end
	end
	return typesList
end
	
return Plate