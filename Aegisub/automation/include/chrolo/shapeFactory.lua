-- Chrolo's Library --
script_name = "Chrolo's Shape Factory."
script_description = "A bunch of functions to draw stuff."
script_author = "Chrolo"
script_version = "1.1.0"
script_namespace = "chrolo.shapeFactory"

local util = require 'aegisub.util'

--Exports:
local shapeLib = {}


---A standard Spacer block
function shapeLib.spacerBlock()
--Purpose: adds a default spacer block into a line, useful for creating non-linear movement
-- ouputs:	a 100x100px invisible block
	return "{\\p1}m 0 0 l 100 0 100 100 100 0{\\p0}"
end

function shapeLib.blindsClip(direction, spacing_1, spacing_2, x, y, width, height, offset)
	--[[
	Purpose:		Generates the drawing necessary to create shutter/blinds like clip
	outputs:		string to be placed in a "\clip()" or "\iclip()" tag
	Params:		direction	<string>	"h"orizontal or "v"ertical
						spacing_1	<px>		size of drawn line
						spacing_2	<px>		size of gap between lines
						x				<px>		x coordinate to begin drawing from
						y				<px>		y coordinate to begin drawing from
						width		<px>		width of drawing
						height		<px>		height of drawing
						offset		<px>		offset from start to begin the effect.
	--]]
	--Initialise the string:
	local retString = string.format("m %g %g l ", x, y)

	local vert = true
	--Calc the distance we are generating for:
	if direction == "h" or direction == "horizontal" then
		vert = false
	end

	local distance = width
	if vert then distance = height end

	while offset < distance do

		if vert then
			retString = string.format("%s %g %g %g %g %g %g %g %g",retString, x+width, y+offset,x+width, y+offset+spacing_1, x, y+offset+spacing_1, x, y+offset+(spacing_1+spacing_2))
		else
			retString = string.format("%s %g %g %g %g %g %g %g %g",retString, x+offset, y+height, x+offset+spacing_1, y+height, x+offset+spacing_1, y, x+offset+(spacing_1+spacing_2), y)
		end

		--increase offset by the spacing:
		offset = offset + spacing_1 + spacing_2
	end

	return retString

end

function shapeLib.circularPath(radius, origin_x, origin_y, direction)
	--[[
	Purpose: 	generates the string needed to draw a circle of a given radius at the given origin
	output:		aegisub path of the circle
	params:	direction <char> "a"nti-clockwise, defaults to "c"lockwise
	--]]
	--easy clockwise vs anti-clockwise:
	local inverter = 1
	if direction == "a" then
		inverter = -1
	end

	--calculate bezier points:
	local b = radius * 0.55		-- from experimentation, 55% of radius seemed like a good number for bezier point offsets


	--Split out to aid reading
	return string.format("m %d %d ", origin_x, origin_y - radius) ..
		string.format("b %d %d %d %d %d %d ", origin_x + (b *inverter), origin_y - radius, origin_x + (radius * inverter), origin_y - b, origin_x + (radius* inverter) , origin_y) ..
		string.format("b %d %d %d %d %d %d ", origin_x + (radius*inverter), origin_y + b , origin_x + (b * inverter) , origin_y + radius , origin_x, origin_y + radius) ..
		string.format("b %d %d %d %d %d %d ", origin_x - (b *inverter), origin_y + radius, origin_x - (radius * inverter), origin_y + b, origin_x - (radius* inverter) , origin_y) ..
		string.format("b %d %d %d %d %d %d ", origin_x - (radius*inverter), origin_y - b , origin_x - (b * inverter) , origin_y - radius , origin_x, origin_y - radius)

end

function shapeLib.pixelMap(pixelSize, pixelMargin, mapSizeX, mapSizeY)
	--[[
	Purpose: 	gives you a block of pixels for effects
	output:		aegisub path of the pixel map
	--]]

	--init current map size
	local curPos = {x=0, y=0};
	local blockSize = pixelSize + pixelMargin;
	local drawString = "";

	-- For each row:
	while curPos.x < mapSizeX do
		--for each collumn:
		while curPos.y < mapSizeY do
			--add a block
			drawString = drawString .. string.format("m %g %g l %g %g l %g %g l %g %g ", curPos.x, curPos.y, curPos.x + pixelSize, curPos.y, curPos.x + pixelSize, curPos.y + pixelSize, curPos.x, curPos.y + pixelSize);
			curPos.y = curPos.y + blockSize;
		end
		--reset the Y pos
		curPos.y = 0;
		curPos.x = curPos.x + blockSize;
	end


	--Retrn the pixel map
	return drawString;

end


----------------------------------------------------
---------[[END OF LIBRARY]]-------------------------
----------------------------------------------------

--return my functions to the includer
--Due to limitations, return a function that then returns all the modules to load.
local function load_lib(...)
	--return this library
	return shapeLib
end

return load_lib
