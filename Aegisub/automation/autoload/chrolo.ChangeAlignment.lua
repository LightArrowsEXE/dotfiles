---------------------------------------------------------------------------
----------------------    Change Alignment --------------------------------
---------------------------------------------------------------------------
-- Purpose: Switch a line's alignment parameter without changing it's 
-- 			current screen position.
--			Includes 2 macros: 
--				- "Change Alignments" sets lines to a given alignment.
--				- "Cycle Alignments" is designed to be hotkeyed and cycles
--					through alignment values
---------------------------------------------------------------------------

--global variables
local chroloLibLoad = require 'chrolo.lib'
local chLib = chroloLibLoad()

----------------
-- Macro Info --
----------------
script_name = "Change Alignment"
script_description = "Changes between Alignments, mantaining current position (where possible)"
script_author = "Chrolo"
script_version = "1.0.2"
script_namespace = "cholo.ChangeAlignment"

menu_embedding = "Chrolo/"	--if you don't like the menu being automation>Chrolo>Macro, just adjust this. Make it "" to have no menu embedding


function mid_point_coord( x, y )
--purpose: returns midpoint of two co-ords
return {((x[1]+y[1])/2), ((x[2]+y[2])/2)}

end

function new_pos(coords, align)
--purpose: Determine position values for a shape given shape co-ordinates and alignment tag
--inputs: width and height of shape (px), new alignment (1-9), co-ordinates of top-right corner (pos used for \an7)
--outputs: the new values for the \pos tag

	local pos = { coords[1][1], coords[1][2]} 	--default to top-left corner

	if align == 1 then
		pos=coords[4]
	elseif align == 3 then
		pos=coords[3]
	elseif align == 9 then
		pos=coords[2]
	elseif align == 7 then
		pos=coords[1]
	
	elseif align == 2 then
		pos = mid_point_coord(coords[3],coords[4])
	elseif align == 4 then
		pos = mid_point_coord(coords[1],coords[4])
	elseif align == 5 then
		pos = mid_point_coord(coords[1],coords[3])
	elseif align == 6 then
		pos = mid_point_coord(coords[2],coords[3])
	elseif align == 8 then
		pos = mid_point_coord(coords[1],coords[2])
	end
	
	return pos
end



function change_align(subs, sel, alignment)
--Purpose:	Change the \an and \pos tags of a line, without affecting line position
--Inputs:	<Subs> file, <sel>ection, <alignment> wanted.
	
	--make sure alignment has come in as a number:
	if tonumber(alignment) == nil then
		aegisub.debug.out(string.format("'%s' is not recognised as a valid alignment.\n",alignment))
	else
		alignment = tonumber(alignment)
	end
	
	--for each line:
	local sub_lines={}
	for _, i in ipairs(sel) do
		local line = subs[i]
		--get line info:
		local info = chLib.getLineInfo(subs, line)
		local ov_params = chLib.getFirstTagOverrides(line.text)
		
		--calculate the co-ordinates of the line
		coords = chLib.getTextBoundCoords(subs, line)
		
		local positions = new_pos(coords, alignment)
			--aegisub.debug.out(string.format("New tag is {\\an%d\\pos(%g,%g)}\n",alignment, positions[1], positions[2]))
		
		--set new params
		local params = {}
		params["an"] = {alignment}
		
		
		if ov_params["move"] ~= nil then
			params["move"] = {}
			params["move"][1] = positions[1]
			params["move"][2] = positions[2]
			params["move"][3] = positions[1]+info["move_xy"][1]
			params["move"][4] = positions[2]+info["move_xy"][2]
		else
			params["pos"] = {positions[1],positions[2]}
		end
		
		--new method to update tags:
		line.text = chLib.add_params_to_line(line.text,params);
		
		--write changes back to file:
		subs[i]= line
	end
	
	return sel
	
end


--------------------------
-- Macros to register:	--
--------------------------
function GUI_change_wrapper(subs, sel)
	--Choose an alignement:
		--setup initial dialog
	dialog = {
		--Line entrance choice:
		{class="label", label="Alignment		", x=0, y=0},
		{class="dropdown", name="alignment", items = {1,2,3,4,5,6,7,8,9}, x=0, y=1, value="None"}		
	}
	btn, dialog_result = aegisub.dialog.display(dialog,
		{"Switch up", "Calm Down"},
		{ok="Switch up", cancel="Calm Down"}
	)
	--check btn was "okay"
	if btn == "Switch up" then
		--Make sure !nil and call function
		if not (dialog_result.alignment == nil) then
			change_align(subs, sel, dialog_result.alignment)
		else
			aegisub.debug.out("You're going to have to choose your alignment.\n")
		end
	end
end
aegisub.register_macro(menu_embedding.."Change Alignment", "Changes between Alignements, mantaining current position (where possible)", GUI_change_wrapper)


function Cycle_Alignments(subs, sel)

	for _, i in ipairs(sel) do
		
		--get text's current alignment
		local info = chLib.getLineInfo(subs, subs[i])
		
		--get next alignment
		info["an"] = info["an"]+1
		if info["an"] > 9 then info["an"] = 1 end
		
		--call the function
		change_align(subs, {i}, info["an"])
	end
	
	
end
aegisub.register_macro(menu_embedding.."Cycle Alignment", "Cycles between Alignements, mantaining current position (where possible)", Cycle_Alignments)


