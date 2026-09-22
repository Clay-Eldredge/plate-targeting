local ShapeMath = require(script.Parent.ShapeMath)

local Shapes = {}


-- Shape Configurations


Shapes.Bullseye3 = {
	-- Outer ring
	{-3,  0, 1}, {-3,  1, 1}, {-3, -1, 1}, 
	{-2,  2, 1}, {-2, -2, 1}, 
	{-1,  3, 1}, {-1, -3, 1}, 
	{ 0,  3, 1}, { 0, -3, 1}, 
	{ 1,  3, 1}, { 1, -3, 1}, 
	{ 2,  2, 1}, { 2, -2, 1}, 
	{ 3,  0, 1}, { 3,  1, 1}, { 3, -1, 1},

	-- Center
	{ 0,  0, 1},
}

Shapes.Bullseye2 = {
	-- Outer ring (radius 2)
	{-2,  0, 1}, {-2,  1, 1}, {-2, -1, 1}, 
	{-1,  2, 1}, {-1, -2, 1}, 
	{ 0,  2, 1}, { 0, -2, 1}, 
	{ 1,  2, 1}, { 1, -2, 1}, 
	{ 2,  0, 1}, { 2,  1, 1}, { 2, -1, 1},

	-- Center
	{ 0,  0, 1},
}

Shapes.Wall3 = {
	{ 0,  0, 1},
	{ 0,  1, 1},
	{ 0, -1, 1},
}

Shapes.Wall5 = {
	{ 0,  0, 3},
	{ 0,  1, 4},
	{ 0,  2, 5},
	{ 0, -1, 2},
	{ 0, -2, 1},
}

Shapes.L3 = {
	{ 0,  0, 1},
	{ 0,  1, 1},
	{ 1,  0, 1},
}

return Shapes