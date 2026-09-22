local Players = game.Players
local GuiService = game.GuiService
local UIS = game:GetService("UserInputService")


-- Private Helpers


-- Recursively identifies the master plate model ancestor
local function getPlateAncestor(part)
	local firstModel = part:FindFirstAncestorOfClass("Model")
	if string.sub(firstModel.Name, 1, 6) == "Plate_" then
		return firstModel
	else
		return getPlateAncestor(firstModel)
	end
end


-- Main Method


-- Calculates the 3D Plate target derived from current input or mouse position
local function GetTarget(input)
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local ml = UIS:GetMouseLocation()
	
	local mousePos
	if input then
		mousePos = input.Position
	else
		mousePos = Vector2.new(ml.X, ml.Y - GuiService:GetGuiInset().Y)
	end
	
	-- Verify unobstructed UI interaction
	local GUIsAtPos = playerGui:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)
	local overlapping = false
	for _, v in pairs(GUIsAtPos) do
		if v.Transparency and v.Transparency ~= 1 then
			overlapping = true
		end
	end

	-- Perform Raycast to find physical plate
	if not overlapping then
		local inset = GuiService:GetGuiInset()
		local screenToWorldRay = workspace.CurrentCamera:ViewportPointToRay(mousePos.X, mousePos.Y + inset.Y)
		local directionVector = screenToWorldRay.Direction * 10000
		
		local plates = workspace:WaitForChild("Plates"):GetChildren()
		local raycastParams = RaycastParams.new()
		raycastParams.RespectCanCollide = true
		raycastParams.FilterType = Enum.RaycastFilterType.Include
		raycastParams.FilterDescendantsInstances = plates

		local raycastResult = workspace:Raycast(screenToWorldRay.Origin, directionVector, raycastParams)
		if raycastResult then
			return getPlateAncestor(raycastResult.Instance)
		end
	end
end

return GetTarget