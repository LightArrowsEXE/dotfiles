---------------------------------------------------------------------------
-------------------------    ReStyler   -----------------------------------
---------------------------------------------------------------------------
-- Purpose: Switch the base style of a line without actually changing the
-- 			line's current formatting.
--
--
---------------------------------------------------------------------------

--global variables
local chroloLibLoad = require 'chrolo.lib'
local chLib = chroloLibLoad()
require "karaskel"

----------------
-- Macro Info --
----------------
script_name = "Restyler"
script_description = "Change a line to a new style, but keep it looking the same."
script_author = "Chrolo"
script_version = "1.0.0"
script_namespace = "cholo.Restyler"

menu_embedding = "Chrolo/"	--if you don't like the menu being Chrolo>Macro, just adjust this.




---------------
-- functions --
---------------


--------------------------
-- Macros to register:	--
--------------------------
function StyleSwitcher(subs, sel)

	--get a list of current style names present in the subtitles:
	local meta, styles = karaskel.collect_head(subs)
	local style_list = {}
		
	for i= 1 ,styles["n"] do 
		table.insert(style_list,styles[i]["name"])
	end
	
	--Open dialog with choices:
		--we need: newStyle
		
		--setup initial dialog
	local dialog = {
		--Line entrance choice:
		{class="label", label="Select new style:", x=0, y=0},
		{class="dropdown", name="style", items = style_list, x=0, y=1, value="None"}		
	}
	btn, dialog_result = aegisub.dialog.display(dialog,
		{"Get Stylish", "Stay in the Closet"},
		{ok = "Get Stylish", cancel = "Stay in the Closet"}
	)
	--if they cancelled / exited
	if not (btn == "Get Stylish") then
		return
	end
	
	--Make sure !nil
	if dialog_result.style == nil then
		aegisub.debug.out("You can't go naked, choose a style!\n")
		return
	end
	
	--make local link to style to change to:
	local newStyle = styles[dialog_result.style]
	
	--process the lines:
	for _, i in ipairs(sel) do
		local line = subs[i]
		
		--get the line's style params:
		local old_style = chLib.getStyle(subs,line.style)
		local params = chLib.getParamsFromStyle(old_style)
		--update with any overrides at the beginning of the line:
		local ov_params = chLib.getFirstTagOverrides(line.text)
		for key, val in pairs(ov_params) do
			params[key] = ov_params[key]
		end

		--get params to remove from tags:
		local _, rem_params = chLib.getOverridesWithoutStyle(ov_params, newStyle)
		if not(rem_params==nil) then
			--remove them:
			line.text = chLib.rem_params_from_tags(line.text,rem_params)
		end
		
		--get rid of excess params:
		params = chLib.getOverridesWithoutStyle(params, newStyle)
		
		--write the new params to the line:
		line.text = chLib.add_params_to_line(line.text,params);
		--change the line style:
		line.style = dialog_result.style
		
		--write changes back to file:
		subs[i]= line
	end
	return sel
end

aegisub.register_macro(menu_embedding..script_name, script_description, StyleSwitcher)