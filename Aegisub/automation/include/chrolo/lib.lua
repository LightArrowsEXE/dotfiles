--Realising I was going to create a tonne of reusable code and functions, I present this:
-- Chrolo's Library --
script_name = "Chrolo's Library."
script_description = "When you need something done, check everywhere else first, then here."
script_author = "Chrolo"
script_version = "1.1.4"
script_namespace = "chrolo.lib"

local util = require 'aegisub.util'

--exported tables:
local lib={} --These are the general functions of the library

--internal tables:
local tag_list={
--a table of all standard tags with information about values, etc.
-- possible values:
--	["type"]	- Data type for parameter
--	["style"]	- Translation of tag for use in styles line.
--	["desc"]	- Description of tag (though you probably know these)
--	["par_c"]	- (max) Param count : how many parameters are there? (eg, \pos has 2, \t can have up to 4)

-- [""]	={ ["type"] = "",	["style"] = "",	["par_c"] = ,	["desc"] = 		},


["fn"]	 ={ ["type"] = "text",	["style"] = "fontname",	["par_c"] = 1,	["desc"] = "Font name"		},
["fs"]	 ={ ["type"] = "float",	["style"] = "fontsize",	["par_c"] = 1,	["desc"] = "Font Size" 		},	--spec says "You can only specify integer font sizes." but I tried 50.6 and it worked, so i'm ignoring it.
["fsp"]	 ={ ["type"] = "float",	["style"] = "spacing",	["par_c"] = 1,	["desc"] = "Font spacing"		},
["an"]	 ={ ["type"] = "int",	["style"] = "align",	["par_c"] = 1,	["desc"] = "Text alignement"		},

["c"]	={ ["type"] = "color",	["style"] = "color1",	["par_c"] = 1,	["desc"] = "Primary text color"		},
["2c"]	={ ["type"] = "color",	["style"] = "color2",	["par_c"] = 1,	["desc"] = "Secondary text color"		},
["3c"]	={ ["type"] = "color",	["style"] = "color3",	["par_c"] = 1,	["desc"] = "Border color"		},
["4c"]	={ ["type"] = "color",	["style"] = "color4",	["par_c"] = 1,	["desc"] = "Shadow color"		},

["1a"]	={ ["type"] = "alpha",	["style"] = "color1",	["par_c"] = 1,	["desc"] = "Primary text Transparency"		},
["2a"]	={ ["type"] = "alpha",	["style"] = "color2",	["par_c"] = 1,	["desc"] = "Secondary text Transparency"		},
["3a"]	={ ["type"] = "alpha",	["style"] = "color3",	["par_c"] = 1,	["desc"] = "Border Transparency"		},
["4a"]	={ ["type"] = "alpha",	["style"] = "color4",	["par_c"] = 1,	["desc"] = "Shadow Transparency"		},

["frz"]		={ ["type"] = "float",	["style"] = "angle",	["par_c"] = 1,	["desc"] = "Z-rotation"		},
["fscx"]	={ ["type"] = "float",	["style"] = "scale_x",	["par_c"] = 1,	["desc"] = "Horizontal Scaling"		},
["fscy"]	={ ["type"] = "float",	["style"] = "scale_y",	["par_c"] = 1,	["desc"] = "Vertical Scaling"		},

["b"]	={ ["type"] = "bool",	["style"] = "bold",			["par_c"] = 1,	["desc"] = "Bold"		},
["u"]	={ ["type"] = "bool",	["style"] = "underline",	["par_c"] = 1,	["desc"] = "Underlined"		},
["i"]	={ ["type"] = "bool",	["style"] = "italic",		["par_c"] = 1,	["desc"] = "Italics"		},

["bord"]	={ ["type"] = "float",	["style"] = "outline",	["par_c"] = 1,	["desc"] = "Text outline"	},
["shad"]	={ ["type"] = "float",	["style"] = "shadow",	["par_c"] = 1 ,	["desc"] = 	"Text Shadow"	},

--Non Style tags:
--[""]	={ ["type"] = "",	["par_c"] = ,	["desc"] = ""},
["fad"]		={ ["type"] = "int",	["par_c"] = 2,	["desc"] = "Simple fade"},
["fade"]	={ ["type"] = "int",	["par_c"] = 7,	["desc"] = "Complex fade"},
["pos"]		={ ["type"] = "float",	["par_c"] = 2,	["desc"] = "Position of Line"		},
["move"]	={ ["type"] = "float",	["par_c"] = 6,	["desc"] = "Movement of line"		},

["clip"]	={ ["type"] = "text",	["par_c"] = 4,	["desc"] = "Clip"		},
["iclip"]	={ ["type"] = "text",	["par_c"] = 4,	["desc"] = "Inverse Clip"		},

["blur"]	={ ["type"] = "float",	["par_c"] = 1,	["desc"] = "Gaussian Edge Blur"},

["frx"]	={ ["type"] = "float",	["par_c"] = 1,	["desc"] = "X-Rotation"},
["fry"]	={ ["type"] = "float",	["par_c"] = 1,	["desc"] = "Y-Rotation"},
["fax"]	={ ["type"] = "float",	["par_c"] = 1,	["desc"] = "X-Shear"},
["fay"]	={ ["type"] = "float",	["par_c"] = 1,	["desc"] = "Y-Shear"},

--More needs to be added....
}

local style_translator={
-- [""]	={ ["param"] = ""	},
["fontname"]	={ ["param"] = "fn"	},
["fontsize"]	={ ["param"] = "fs"	},
["spacing"]		={ ["param"] = "fsp"	},

["align"]		={ ["param"] = "an"	},

["bold"]		={ ["param"] = "b"	},
["underline"]	={ ["param"] = "u"	},
["italic"]		={ ["param"] = "i"	},

["angle"]		={ ["param"] = "frz"	},
["scale_y"]		={ ["param"] = "fscy"	},
["scale_x"]		={ ["param"] = "fscx"	},

["outline"]		={ ["param"] = "bord"	},
["shadow"]		={ ["param"] = "shad"	},

--these colors have to be handled in a special way as they also contain alpha values
["color1"]		={ ["param"] = "c"	},
["color2"]		={ ["param"] = "2c"	},
["color3"]		={ ["param"] = "3c"	},
["color4"]		={ ["param"] = "4c"	},

--there's more to add here ...
}

--DEBUG SETTINGS
local debug_level = 0



--ASS TS functions
function lib.getTextBound(subs, line)
--Purpose:	Get the Text boundary of a line (useful when adjusting alignements).
--Returns:	width and height of rendered text, array of lines and subcomponent widths+heights and their parameters.
	--
	local h, w = 0, 0

	local sub_parts={}
	local cur_overrides = {}
	--Make a local copy of the style used for this line.
	local this_style = lib.getStyle(subs, line.style)

	--Split lines at every '\N'
	local t_lines = lib.string_split(line.text,"\\N")

	-- Get rid of any blank lines at the end of the array
	i = #t_lines
	while t_lines[i] == "" do
		table.remove(t_lines,i)
		i = #t_lines
	end

	for i,i_line in ipairs(t_lines) do
		if debug_level > 0 then
				aegisub.debug.out(string.format("newline:%d\n",i))
		end

		local t_w, t_a, t_d = 0, 0, 0 --temp width, accent and decent are set to 0

		--Split lines at every tag instance.(incase there's a change there)
		local t_subText, t_subTags = split_at_override_tags(i_line)
			if debug_level > 0 then
				aegisub.debug.out(string.format("Line text is: `%s`\n",i_line))
				aegisub.debug.out(string.format("%s\n",print_r(t_subText,"t_subText")))
				aegisub.debug.out(string.format("%s\n",print_r(t_subTags,"t_subTags")))
			end

		--insert new array into sub_parts
		table.insert(sub_parts,i,{})

		if t_subText[1] == nil then	--check if t_subText is an empty array
			table.insert(t_subText,"")
			table.insert(t_subTags,"")
		end


		for j,_ in ipairs(t_subText) do
			if debug_level > 0 then
				aegisub.debug.out(string.format("\tlinepart:%d\n",j))
			end


			--insert new array into line array of sub_parts:
			table.insert(sub_parts[i],j,{["params"]={}})

			--customise style based on found tags
			local param_updates = getOverrideParamsFromTags(t_subTags[j])
			this_style = applyParamstoStyle(this_style, param_updates);

			--copy overrides in current overrides variable
			for tag, data in pairs(param_updates) do			--then update them for this time
				cur_overrides[tag] = data;
			end

			if debug_level > 0 then
				aegisub.debug.out(string.format("%s\n",print_r(cur_overrides,"Current Overrides")))
			end

			--put params for this line into array
			sub_parts[i][j]["params"] = util.deep_copy(cur_overrides) --copy in the params from last time

			--findbounding box
			local width, height, descent, ext_lead
			if (t_subText[j] == "" and j == 1 and t_subText[j+1] == nil) then --if this text line is blank
				width, height, descent, ext_lead = aegisub.text_extents(this_style, "|") --get height/accent decent using test text
				width = 0 	--overwrite to zero width
				height = height /2 --apparently a blank new line is only half the height of a newline with a character in.
			else
				width, height, descent, ext_lead = aegisub.text_extents(this_style, t_subText[j])
			end

				if debug_level >1 then
					aegisub.debug.out(string.format("%s\n",print_r(this_style,"this_style")))
				end
				if debug_level >0 then
					aegisub.debug.out(string.format("%s\n",print_r(t_subText[j],string.format("t_subText[%d]",j))))
					aegisub.debug.out(string.format("%s\n",print_r({width, height, descent, ext_lead},"text_extents")))
				end

			--adjust for unaccounted params: (\i, \fax, \frx, \fry, etc)
--[[
WORK TO DO
--]]
			--put line_component width and height into array
			sub_parts[i][j][1]= width
			sub_parts[i][j][2]= height


			--calculate outer bounds
			t_w = t_w + width 			-- increase width of line

			--height is slightly more involved. Fonts may have different lengths above/below the mid-line for a given size.
			--ie/	arial 60pt has descent: 11.375   and ascent: 48.625
			--	 arno pro 60pt has descent: 18.09375 and ascent: 41.90625
			-- if they're on the same line together, the line height is actually 48.625 + 18.09375 = 66.71875 (!= 60)
			local accent = height - descent
			t_a = math.max(t_a, accent)		-- figure out tallest accender
			t_d = math.max(t_d, descent)	-- figure out lowest descender


			if debug_level >0 then
				aegisub.debug.out(string.format("Line width is %g \t line height is %g\n",t_w, t_a + t_d))
			end

		end	--loop though sub components of lines

		--add total line height and width to the misc data:
		sub_parts[i]['height'] = (t_a + t_d)
		sub_parts[i]['width'] = t_w


		h = h + (t_a + t_d)		-- add on the height of the last line
		w = math.max(w, t_w)	-- use maximum line width found.

	end	--loop through vertical lines

	--adjust for \shad and other tags that only affect global bounds, not line bounds
--[[
WORK TO DO
--]]

	--return the width, height and sub components of bounding box
	return w, h, sub_parts

end
function lib.getTextBoundCoords(subs, line)
--Purpose:	Get the co-ordinates of a text's bounding box.
--returns:	{{x1,y1},{x2,y2},{x3,y3},{x4,y4}}, where co-ordinates are numbered clockwise from top-left

	local coords = {{nil,nil},{nil,nil},{nil,nil},{nil,nil}}
	--get text bounding box
	local w, h = lib.getTextBound(subs, line)


	--get params from style.
	local params = lib.getParamsFromStyle(lib.getStyle(subs, line.style))
	--Get basic line info:
	local info = lib.getLineInfo(subs, line)
	params["pos"] = info["pos"]
	params["frz"] = {info["frz"]}

	--get Override params out of the line
	local params_ov = getOverrideParamsFromTags(line.text)

	--combine them:
	for i,_ in pairs(params_ov) do
		params[i]=params_ov[i]	--could've used the _ variable, but I think this makes it more obvious what i'm doing.
	end

	--create inverted angle for calcs as vertical norm is invert.
	local w_angle = params['frz'][1] + 180
	local h_angle = params['frz'][1] + 90

	if debug_level > 1 then
		aegisub.debug.out(string.format("\n%s\n",print_r(params,"params")))
	end

	local d_x, d_y = 0 , 0
	local alignment = tonumber(params['an'][1])
	--Calculate difference between pos and coord[1]
	if		alignment == 1 then
		d_x, d_y =  lib.polar_to_cartesian(h, h_angle)
	elseif	alignment == 2 then
		d_x, d_y = unpack( lib.matrix_sum( { lib.polar_to_cartesian(w/2, w_angle)}, { lib.polar_to_cartesian(h, h_angle)})	)
	elseif	alignment == 3 then
		d_x, d_y = unpack( lib.matrix_sum( { lib.polar_to_cartesian(w, w_angle)}, { lib.polar_to_cartesian(h, h_angle)})	)
	elseif	alignment == 4 then
		d_x, d_y =  lib.polar_to_cartesian(h/2, h_angle)
	elseif	alignment == 5 then
		d_x, d_y = unpack( lib.matrix_sum( { lib.polar_to_cartesian(w/2, w_angle)}, { lib.polar_to_cartesian(h/2, h_angle)})	)
	elseif	alignment == 6 then
		d_x, d_y = unpack( lib.matrix_sum( { lib.polar_to_cartesian(w, w_angle)}, { lib.polar_to_cartesian(h/2, h_angle)})	)
	elseif	alignment == 7 then
		d_x, d_y = 0,0
	elseif	alignment == 8 then
		d_x, d_y =  lib.polar_to_cartesian(w/2, w_angle)
	elseif	alignment == 9 then
		d_x, d_y =  lib.polar_to_cartesian(w, w_angle)
	else
		aegisub.debug.out(string.format("[ChroloLib] Error, alignment '%s' not recongised.\n",params['an'][1]))
	end

	if debug_level > 0 then
		aegisub.debug.out(string.format("%s\n",print_r({d_x,d_y},"dx, dy")))
	end

	--generate coord[1]
	coords[1][1] = params['pos'][1] + d_x
	coords[1][2] = params['pos'][2] - d_y -- minus to account for backwards y axis in subs

	if debug_level > 1 then
		aegisub.debug.out(string.format("%s\n",print_r(coords[1],"coords[1]")))
	end


	--calc other co-ords based on this:
	local w_vector = { lib.polar_to_cartesian(w, params['frz'][1])}
	local h_vector = { lib.polar_to_cartesian(h, params['frz'][1] - 90 )}
	--invert the y of each
	w_vector[2] = - w_vector[2]
	h_vector[2] = - h_vector[2]

	coords[2] = lib.matrix_sum(coords[1], w_vector)
	coords[3] = lib.matrix_sum(coords[1], w_vector, h_vector)
	coords[4] = lib.matrix_sum(coords[1], h_vector)

	--Some slight adjustments may need to be made to the co-ords.
		-- \shad throws co-ordinates off...

	if debug_level > 0 then
		aegisub.debug.out(string.format("%s\n",print_r(coords,"All coords")))
	end

	return coords
end

function split_at_override_tags(str)
--Purpose:	Split line up into substrings at each override tag.
--return:	Arrays of text and tags with aligned indexes. so tags[2] are tags for text[2], even if text[1] had no tags
	local tags, text = {},{}
	local x = 1

	while str:len() > 0 do 	-- while there's still text in the string.

		--have to add new sub arrays to text and tags for each itteration
		table.insert(text,"")
		table.insert(tags,"")

		local start, stop = str:find("{(.-)}")			-- 'lazy' find of tag
		if not (start == nil) then
			if not (start == 0) then
				if x == 1 then --account for lines that start with text before first override tag
					x = x + 1
					table.insert(text,"") --have to add more lines
					table.insert(tags,"")
				end
				text[x-1] = str:sub( 0, start-1)	--put text into text array
			end
			--put tag into tag array
			tags[x] = str:sub(start, stop)
			--get rid of processed portion
			str = str:gsub(lib.escape_lua_pattern(str:sub( 0, stop)),"", 1)
		else --no more matches
			if x == 1 then --account for lines that start with text before first override tag
				x = x + 1
			end
			text[x-1] = str	--put remaining text into array
			--get rid of processed portion
			str = str:gsub(lib.escape_lua_pattern(str),"", 1)
		end

		x = x + 1
	end

	--cleanup any blank elements
	for x,y in ipairs(text) do
		if (text[x] == "" and tags[x] == "") then
			table.remove(text, x)
			table.remove(tags, x)
		end
	end

	return text, tags
end

function getOverrideParamsFromTags(tag_string)
--Purpose:	output array of override parameters in the given string
--output:	table of values indexed by tag id.
	local params = {}

	if tag_string==nil or tag_string == "" then --catch any blanks before we cause an index error
		return {}
	end

	-- 1) strip out \t transforms first as these will confuse the rest of the process
	tag_string, time_tags_array = filter_t_tags(tag_string)	--don't know if i'll do anything with time_tags_array yet...

	-- 2) get any text-param tags (eg/ '\fn', 'clip'(as they can be vectors))
	local tags_with_text_params = {'fn', 'clip', 'iclip'}
	local whole_cap
	for _,text_tag in ipairs(tags_with_text_params) do
		for whole_cap, tag_param in string.gmatch(tag_string, "(\\"..text_tag.."%(-([^%)%(\\}]+)%)*)") do

			params[text_tag] = lib.string_split(tag_param, ",")
			--remove from string
			tag_string = tag_string:gsub(lib.escape_lua_pattern(whole_cap),"")
		end
	end


	-- 3) Get colour based tags
	for tag, tag_param in string.gmatch(tag_string, "\\(%d-[ca])(&H[%d%a]-&)") do
		params[tag]=lib.string_split(tag_param, ",")
	end

	-- 4) get data from remaining tags
	for tag, tag_param in string.gmatch(tag_string, "\\(%a+)%(-([%-%d%.,]+)%)-") do
		params[tag]=lib.string_split(tag_param, ",")
			if debug_level > 2 then
				aegisub.debug.out(string.format("Splitting '%s' returns: %s\n",tag_param,print_r(params[tag]," ")))
			end
		--format the data:
		for i,data in pairs(params[tag]) do
			if not (tag_list[tag] == nil) then
				if tag_list[tag]["type"] == "float" or tag_list[tag]["type"] == "int" or tag_list[tag]["type"] == "bool" then
					params[tag][i] = tonumber(data)
				end
			else
				if debug_level > 0 then
					aegisub.debug.out(string.format("Parameter '%s' not specified in tag_list\n",tag))
				end
			end
		end
	end


	-- 5) Profit
	return params
end

function lib.getFirstTagOverrides(line_text)
--Purpose:	get the parameters from the first tag set in a line.
--Inputs:	Full line text
--Returns:	Parameter array
	--Split line at override tags
	local text, tags = split_at_override_tags(line_text)
	--make sure we found tags:
	if tags[1]==nil then
		return {} --empty table
	else
	--get params from first tag
		return getOverrideParamsFromTags(tags[1])
	end
end

function lib.getParamsFromStyle(style)
--Purpose:	Gets styling from current style object and converts to parameters
	local params = {}

	if debug_level>1 then
		aegisub.debug.out(string.format("From style %s\n",print_r(style," ")))
	end

	for key,val in pairs(style) do


		if not (style_translator[key] == nil) then --make sure style is specified

			if not (style_translator[key]["param"] == nil) then --only process if style translation exists
				--colours need to be processed differently
				if key:find("color") then

					--what color param are we updating?
					local x = key:match("color(%d)")

					--get the colour
					if tonumber(x) == 1 then
						params["c"] = {util.color_from_style(val)}
					else
						params[x.."c"] = {util.color_from_style(val)}
					end
					--get the alpha
					params[x.."a"] = {util.alpha_from_style(val)}

				else	--default processing of style to param

					params[style_translator[key]["param"]] = style_val_to_param_val(key, val)

				end
			end
		else
			if debug_level>0 then
				aegisub.debug.out(string.format("\t Style translation not available for %s\n",key))
			end
		end
	end

	if debug_level>0 then
		aegisub.debug.out(string.format(" We got the %s\n",print_r(params,"params")))
	end

	return params
end

function lib.getOverridesWithoutStyle(params, style)
--Purpose:	Returns only the parameters that aren't already covered by the style passed.
--Returns:	<cleaned param list>, <duplicates found>.
	local new_params={}
	local dupes = {}

	local style_params = lib.getParamsFromStyle(style)

	if debug_level>1 then
		aegisub.debug.out(string.format("%s\n%s\n",print_r(params,"Params"),print_r(style_params,"Style Params")))
	end


	--go through params
	for tag,data in pairs(params) do
		if not ( style_params[tag] == nil) then --make sure it's in the style_params list
			if not ( compare_tables(params[tag],style_params[tag]) ) then --if the parameter value is not same as value in style
				new_params[tag] = data

			else
				--make a note of the duplicate:
				table.insert(dupes,tag)
			end
		else -- if it's not in style, it definitely needs to be in new style
			new_params[tag] = data
		end

	end --end of loop

	if debug_level>1 then
		aegisub.debug.out(string.format("%s\n",print_r(new_params,"new_params")))
	end


	return new_params, dupes
end

function getDefaultPos(subs, style, ...)
--Purpose:	Calculate and return the default origin position for text
--Inputs:	Subs file, style object,< align, margin changes >
	local x, y = 0, 0
	local ad_args={...}

	require "karaskel"	--note: look for a way to get styles that isn't karaskel
	local meta = karaskel.collect_head(subs)

	--sort through ad_args
	for i,data in ipairs(ad_args) do
		if i == 1 then
			style["align"] = data
		end
	end

	if debug_level>0 then
		aegisub.debug.out(string.format("%s\n",print_r(ad_args,"ad_args")))
		aegisub.debug.out(string.format("%s\n",print_r(meta,"meta data")))
		aegisub.debug.out(string.format("%s\n",print_r(style,"style data")))
		aegisub.debug.out(string.format("Align is: %d\n",style["align"]))

	end

	--resolution is 'meta.res_x' and 'meta.res_y'

	--determine 0 margin alignment:
	if debug_level>1 then
		aegisub.debug.out(string.format("if values are: %d %d\n",style.align%3,math.floor((style.align-1)/3)))
	end

	--x value:
	if style.align%3 == 0 then		--\an 3, 6, 9 are right aligned
		x = meta.res_x
	elseif style.align%3 == 2 then	--\an 2, 5, 8 are center aligned
		x = meta.res_x/2
	elseif style.align%3 == 1 then	--\an 1, 4, 7 are left aligned
		x = 0
	end
		--y value:
	if math.floor((style.align-1)/3) == 0 then --\an 1, 2, 3 are bottom aligned
		y = meta.res_y
	elseif math.floor((style.align-1)/3) == 1 then	--\an 4, 5, 6 are middle aligned
		y = meta.res_y/2
	elseif math.floor((style.align-1)/3) == 2 then	--\an 7, 8, 9 are top aligned
		y = 0
	end

	--Adjust for margins:

		--left and right margins
	if style.align%3 == 0 then		--\an 3, 6, 9 need margin_r subtracted
		x = x - style.margin_r
	elseif style.align%3 == 2 then	--\an 2, 5, 8 are fine
		x = x
	elseif style.align%3 == 1 then	--\an 1, 4, 7 need margin_l added
		x = x + style.margin_l
	end

		--top and bottom margins
	if math.floor((style.align-1)/3) == 0 then --\an 1, 2, 3 need margin_b subtracted
		y = y - style.margin_b
	elseif math.floor((style.align-1)/3) == 1 then	--\an 4, 5, 6 are fine
		y = y
	elseif math.floor((style.align-1)/3) == 2 then	--\an 7, 8, 9 need margin_t added
		y = y + style.margin_t
	end


	if debug_level>0 then
		aegisub.debug.out(string.format("Default pos is: %d %d\n",x,y))
	end

	return x,y
end


-------------------
-- Style editors --
-------------------
function applyParamstoStyle(style, params)
--Purpose:	Applied the supplied parameters to the supplied style object
	if debug_level > 0 then
		require 'print_r'
		aegisub.debug.out(string.format("%s\n",print_r(params, "Applying")))
	end


	for tag, data in pairs(params) do
		if not (tag_list[tag] == nil) then
			if not (tag_list[tag]["style"] == nil) then --only process if tag translation exists
				if debug_level > 0 then
					aegisub.debug.out(string.format("Param %s is applied to style %s\n",tag,tag_list[tag]["style"]))
				end
				--check for colour tags:
				local c = tag_list[tag]["style"]:match("color(%d)")
				if c then
					--detected a colour tag, which needs to be handled differently

				else
					style[tag_list[tag]["style"]] = param_val_to_style_val(tag, data)
				end
			end
		else -- parameter not specified in tag_list
			if debug_level > 0 then
				aegisub.debug.out(string.format("Parameter '%s' not specified in tag_list\n",tag))
			end
		end
	end

	return style

end

function param_val_to_style_val(tag, data)
--Purpose:	Converts override tag data to style value (where necessary)
	local ret = ""

	if tag_list[tag] == nil then
		aegisub.debug.out(string.format("[Chololib] Tag '%s' data conversion not supported.\n",tag))
		return data[1]
	end

	if tag_list[tag]["type"] == "bool" then
		if data[1] == 1 then
			return true
		else
			return false
		end
	elseif tag_list[tag]["type"] == "color" then
		return string.sub(data[1],3,8); -- return the middle of &H------&

	-- elseif tag_list[tag]["type"] == "<type>" then
--[[
WORK TO DO
	- add section to handle colour changes.
--]]

	else
		--generate var list:
		for i = 1, tag_list[tag]["par_c"] do
			if not ( data[i] == nil ) then
				if i > 1 then
				 ret = ret..","
				end
				ret = ret..data[i]
			end
		end
		return ret
	end
end

function style_val_to_param_val(key,val)
--Purpose:	Take a value from a style parameter and return a value (or values) for the asociated param
	local ret = {}

	if style_translator[key]["param"] == nil then
		aegisub.debug.out(string.format("[Chololib] style '%s' data conversion not supported.\n",key))
		return val
	end

	if tag_list[style_translator[key]["param"]]["type"] == "bool" then
		if val == true then
			table.insert(ret, 1)
		else
			table.insert(ret, 0)
		end
	else
		table.insert(ret, val)
	end

	return ret
end

function params_to_tags(params)
--Purpose:	Take in a set of params and output a tag string
--returns:	tag string (ie/ '\frz-5\fscx120' )
	local str=""

	for tag, data in pairs(params) do
		--add tag to string
		str=str.."\\"..tag;
		--check if multiple params:
		if not(tag_list[tag] == nil) then
			if(tag_list[tag]['par_c']>1) then
				--prepend brackets:
				str=str.."(";
				for i,x in ipairs(data) do
					--prepend comma apart from first data set
					if not (i==1) then str=str..","; end
					--add data
					str=str..x;
				end
				--close brackets
				str=str..")";
			else
				--only one parameter:
				str=str..data[1];
			end
		else --tag not known
			if debug_level>0 then
				aegisub.debug.out(string.format("tag_list['%s'] not found\n",tag));
			end
			--default to '\<tag><data[1]>'
			str=str..data[1];
		end

	end

	return str
end


---------------------
-- Data collectors
---------------------
function getStyles(subs)
--Purpose:	get the styles present in the subtitle file:

	--Acquire styles:
	require "karaskel"	--note: look for a way to get styles that isn't karaskel
	local meta, styles = karaskel.collect_head(subs)

	return styles
end

function lib.getStyle(subs, style_name)
--Purpose:	get a specific style file
	local s = getStyles(subs)
	return s[style_name]
end

function lib.getLineInfo(subs, line)
--Purpose:	Return some standard information about a line.
--Inputs:	Subtitle file, line object
--Returns: array of {["an"],["pos"],["style"],["frz"],["move_xy"]}
	local ret={}

	--Get style object
	ret["style"] = lib.getStyle(subs, line.style)

	--get the params from the style:
	local params = lib.getParamsFromStyle(ret["style"])

	--get alignment:
		--get style default:
	ret["an"] = unpack(params["an"])
		--check for override in line:
	if line.text:find("\\an%d") then
		ret["an"] = tonumber(line.text:match("\\an(%d)"))
	end

	--get line position
		--get style default:
	ret["pos"] = {getDefaultPos(subs, ret["style"] ,ret["an"])}
	ret["move_xy"] = nil 	--There is no move data unless we find it
		--check for override in line:
	if line.text:find("\\pos%([^%)]+%)") then
		ret["pos"] = {line.text:match("\\pos%(([%d.-]+),([%d.-]+)%)")}
	end
	if line.text:find("\\move%([^%)]+%)") then --check for \move, which also gives us start position
		temp = {line.text:match("\\move%(([%d.-]+),([%d.-]+),([%d.-]+),([%d.-]+)")}
		ret["pos"] = {temp[1],temp[2]} --start 2 values are position
		ret["move_xy"] = {temp[3]-temp[1], temp[4]-temp[2]}		--move distances
	end

	--get rotation
		--get style default:
	ret["frz"] = unpack(params["frz"])
		--check for override
	if line.text:find("\\frz([%d-.]+)") then
		ret["frz"] = tonumber(line.text:match("\\frz([%d-.]+)"));
	end


	if debug_level>1 then
		aegisub.debug.out(string.format("%s\n",print_r(ret,"LineInfo:")));
	end

	return ret
end
--------------------
-- Line modifiers --
--------------------
function lib.add_tags_to_line(line_text, tags)
--Purpose:	Wrapper for "add_params_to_line" that accepts tag list ("\pos(x,y)\frz80", etc) instead.
local params = getOverrideParamsFromTags(tags);
return lib.add_params_to_line(line_text,params)

end

function lib.add_params_to_line(line_text,params)
--Purpose:	Add the given parameters to the beginning of the given line_text. Process is addative: no tags are removed, existing tags are updated and new tags are added.
--input:	Line text, Parameters (as array of with named indeces)

	local texts, tags = split_at_override_tags(line_text)
	--check we found tags
	if (tags[1] == nil) then
		return line_text
	end

	local t_tag_str = "" --used later to store t_tags

	if(debug_level >0) then
		aegisub.debug.out(string.format("Splits: %s\n",print_r({["texts"]=texts, ["tags"]=tags},"")))
	end

	--check for \t tags:
	if tags[1]:find("\\t") then
		local t_tags
		tags[1] , t_tags = filter_t_tags(tags[1])
		for _, t in ipairs(t_tags) do
			t_tag_str = t_tag_str..t
		end
	end

	--we only add params to first tag
	tags[1]="{"..add_replace_tags(tags[1]:sub(2,-2),params)..t_tag_str.."}"; --strip curly brackets for funciton, but replace afterward

	--rejoin up the line.
	local new_line_text="";
	for i,x in ipairs(texts) do
		new_line_text = new_line_text..tags[i]..texts[i];
	end

	return new_line_text;
end

function lib.rem_params_from_tags(line_text, param_list)
--Purpose:	Remove the parameters from the first tag block of a line
--input:	Line text, Parameter names

	local texts, tags = split_at_override_tags(line_text)

	--check we found tags
	if (tags[1] == nil) then
		return line_text
	end

	local t_tag_str = "" --used later to store t_tags

	if(debug_level >0) then
		aegisub.debug.out(string.format("Splits: %s\n",print_r({["texts"]=texts, ["tags"]=tags},"")))
	end

	--check for \t tags:
	if tags[1]:find("\\t") then
		local t_tags
		tags[1] , t_tags = filter_t_tags(tags[1])
		for _, t in ipairs(t_tags) do
			t_tag_str = t_tag_str..t
		end
	end

	--we only add params to first tag
	tags[1]="{"..rem_tags(tags[1]:sub(2,-2),param_list)..t_tag_str.."}"; --strip curly brackets for funciton, but replace afterward

	--rejoin up the line.
	local new_line_text="";
	for i,x in ipairs(texts) do
		new_line_text = new_line_text..tags[i]..texts[i];
	end

	return new_line_text;


end

function rem_tags(tag_string, params)
--Purpose:	Remove the given parameters from the tag block
--Input:	tag string, array of parameter names

	--foreach parameter in array:
	for i, tag in ipairs(params) do
		--look for a match
		if(debug_level >0) then
			aegisub.debug.out(string.format("Looking for '%s'\n",tag))
		end

		if string.find(tag_string, get_param_pattern_str(tag)) then
			--get the match data
			local x, y = string.find(tag_string, get_param_pattern_str(tag))
			if(debug_level >0) then
				aegisub.debug.out(string.format("\tFound '%s' @ %d,%d.\n",tag_string:sub(x,y),x,y))
			end
			--replace that text with blank
			tag_string = str_replace_by_position(tag_string,"",x,y)
		else
			if(debug_level >0) then
				aegisub.debug.out("\t Not found");
			end
		end
	end

	return tag_string
end

function add_replace_tags(tag_string,params)
--Purpose:	Scan through given tags text, updating/adding values present in the 'params' array
--return:	updated string

	--foreach parameter in array:
	for tag, data in pairs(params) do
		--look for a match in the text:
		if string.find(tag_string, get_param_pattern_str(tag)) then

			--replace the occurence with new values:
			local x,y = string.find(tag_string, get_param_pattern_str(tag));
				--debug output:
				if(debug_level >0) then
					aegisub.debug.out(string.format("Tag '%s' found at position %d,%d\n",tag,x,y));
					aegisub.debug.out(string.format("Replacing `%s` with `%s`\n",tag_string:sub(x,y),params_to_tags({[tag]=data})));
				end
			tag_string = tag_string:gsub(lib.escape_lua_pattern(tag_string:sub(x,y)),params_to_tags({[tag]=data}));

		else
			--tag not found: append to tag string
			if(debug_level >0) then
				aegisub.debug.out(string.format("Appending `%s` to line \n",params_to_tags({[tag]=data})));
			end
			tag_string = tag_string..params_to_tags({[tag]=data});
		end

	end

	if(debug_level >1) then
		aegisub.debug.out(string.format("New Tag_line is: %s\n",tag_string));
	end

	return tag_string;
end


--------------------
-- Misc Functions --
--------------------
function lib.string_split(str, delim)
--Purpose: Split string by delimiter. Delimiter can be multi-character (such as "\\N") and can also be a pattern if you want.

	local ret={}
	if(debug_level >2) then
		aegisub.debug.out(string.format("Splitting `%s`  at instances of `%s`\n",str,delim))
	end

	while str:len() > 0 do 	-- while there's still text in the string.
		local start, stop = str:find(delim)			-- look for delimi

			if(debug_level >2) then
				if start == nil then
					aegisub.debug.out("No more split positions found\n")
				else
					aegisub.debug.out(string.format("Splitting at %d - %d ()\n",start, stop))
				end
			end

		if start == nil then -- no more delims in string.
			table.insert(ret, str)		-- add the last chunk of the string
			str = str:gsub(lib.escape_lua_pattern(str),"")		-- clear string to exit loop
		else
			table.insert(ret, str:sub( 0, start-1))		-- get the string up until deliminator
			str = str_replace_by_position(str,"", 0, stop)		-- delete the substring from main string.
		end

		if(debug_level >2) then
			aegisub.debug.out(string.format("\tString is now `%s` \n",str))
		end

	end


	return ret

end

function str_replace_by_position(str, replacement, start, stop)
--Purpose:	Allow you to replace a specific part of text in a string.
--input:	String, what will be added, the start position of replacement and the end position of the replacement

	if start < 1 then 	--if start was specified as as less than first character
		return replacement..str:sub(stop+1,str:len())
	elseif not (stop < str:len()) then	--if stop was specified longer than end character.
		return str:sub(0, start-1)..replacement
	else
		return str:sub(0, start-1)..replacement..str:sub(stop+1,str:len())
	end
end

function filter_t_tags(tag_str)
--Purpose:	removes \t tags from given tag string.
--Returns:	cleaned tag string, array of \t params found.

	local X_LIMIT = 150		--this limits the amount of \t tags that can ever be found. It's here to prevent infinite loops incase something goes wrong
	local Y_LIMIT = 150		--this limits the string length of \t tags that can ever be found. It's here to prevent infinite loops incase something goes wrong

	local t_tags_found = {}

	local bracket_count
	local t_start, t_end = string.find(tag_str,"\\t%(")

	local x = 0
	while t_start and x<100 do
		--\t found, now to select the whole thing:
		bracket_count = 0

		t_end = t_end + 1	--shift this by one to ignore the opening bracket found
		local y = 0
		--look for closing bracket, accounting for bracket nesting
		while not ( ( (tag_str:sub(t_end,t_end) == ")"  and bracket_count == 0) or tag_str:sub(t_end,t_end) == "") or y > Y_LIMIT) do

				if debug_level > 1 then
					aegisub.debug.out(string.format("Pos %d is | %s |\n\ty is %d\n",t_end, tag_str:sub(t_end,t_end),y))
				end

			if tag_str:sub(t_end,t_end) == "(" then
				bracket_count = bracket_count + 1
			elseif tag_str:sub(t_end,t_end) == ")" then
				bracket_count = bracket_count - 1
			end
			t_end = t_end + 1
			y = y + 1
		end

		if debug_level > 1 then
			if tag_str:sub(t_end,t_end) == ")"  and bracket_count == 0	then aegisub.debug.out("Exit due to ) and bracket_count ==0 \n") end
			if tag_str:sub(t_end,t_end) == "" 							then aegisub.debug.out("Exit due to empty string \n") end
			if y >= 200 												then aegisub.debug.out("Exit due to overflow \n") end
		end

		if tag_str:sub(t_end,t_end) == "" then -- over-ran the string
			if debug_level > 1 then
				aegisub.debug.out(string.format("Old tag_str is %s \n",tag_str))
			end
			--change '\t' to '\*t' so we don't try match it again (plus it helps you find it in your lines)
			tag_str = tag_str:sub(0, t_start-1).."\\*t"..tag_str:sub(t_start+2,tag_str:len())
			if debug_level > 1 then
				aegisub.debug.out(string.format("New tag_str is %s \n",tag_str))
			end
			--print message to user
			aegisub.debug.out("[ChroloLib] It appears a \\t tag is not properly encapsulated.\n\tTag has been marked as \\*t\n")

		elseif y > Y_LIMIT then --tag looked huge, assumming error.
			aegisub.debug.out(string.format("[ChroloLib] The tag looked like it was >%d chars in length. Assuming error, Exitted to prevent infinite loop.\n",Y_LIMIT))
			return tag_str, t_tags_found


		else --didn't overrun

			--store the \t string
				--should probably process this and split it out into it's params
			table.insert(t_tags_found,tag_str:sub(t_start,t_end))
			if debug_level > 1 then
				aegisub.debug.out("\tfound %s \n",tag_str:sub(t_start,t_end))
			end

			--delete the string from tag_string
			tag_str = tag_str:gsub(lib.escape_lua_pattern(tag_str:sub(t_start,t_end)),"", 1)
		end

		--find next match
		t_start, t_end = string.find(tag_str,"\\t%(")

		if debug_level > 1 then
			aegisub.debug.out("t_start is %s \n",t_start)
		end

		x=x+1


	end

	if x > X_LIMIT then	--too many tags seen, assumming error.
		aegisub.debug.out(string.format("[ChroloLib] There appeared to be >%d \\t tags. Assuming error, finishing processing now to prevent infinite loop.\n",X_LIMIT))
	end

	return tag_str, t_tags_found
end

function lib.escape_lua_pattern(str)
--Purpose:	escape a string so find/gsub/gmatch doesn't treat it like a pattern. (Necessary if your string contains brackets or dots or lots of things really)
--Returns:	escaped string
  local matches =
  {	--table of characters requiring escapes and their escape patterns
    ["^"] = "%^";
    ["$"] = "%$";
    ["("] = "%(";
    [")"] = "%)";
    ["%"] = "%%";
    ["."] = "%.";
    ["["] = "%[";
    ["]"] = "%]";
    ["*"] = "%*";
    ["+"] = "%+";
    ["-"] = "%-";
    ["?"] = "%?";
    ["\0"] = "%z";
  }
    return (str:gsub(".", matches))
end

local compare_tables_rec_limit = 0
function compare_tables(table_1, table_2)
--Purpose:	Look through 2 tables and return true if they're the same

	--make sure they're tables
	if not (type(table_1)== "table") then return false end
	if not (type(table_2)== "table") then return false end


	for i, data in pairs(table_1) do
		if type(table_1[i]) == "table" then

			if debug_level > 2 then
					aegisub.debug.out(string.format("%s\n",print_r(table_1[i],"table_1[i] is:")))
					aegisub.debug.out(string.format("%s\n",print_r(table_2[i],"table_2[i] is:")))
			end

			if compare_tables_rec_limit < 5 then
				compare_tables_rec_limit = compare_tables_rec_limit + 1
				local res = compare_tables(table_1[i], table_2[i])
				compare_tables_rec_limit = compare_tables_rec_limit - 1
				return res
			else
				return false
			end
		else
			if not(table_1[i] == table_2[i]) then --should probably check for table references and add some recursion
				if debug_level > 2 then
					aegisub.debug.out(string.format("\t`%s`(%s) != `%s`(%s)\n",table_1[i], type(table_1[i]), table_2[i], type(table_2[i])))
				end
				return false
			end
		end
	end
	if debug_level > 1 then
		aegisub.debug.out("Supplied tables were equal\n")
	end
	if debug_level > 2 then
		aegisub.debug.out(string.format("%s\n",print_r(table_1,"table_1 is:")))
		aegisub.debug.out(string.format("%s\n",print_r(table_2,"table_2 is:")))
	end

	return true
end

function get_param_pattern_str(param_tag)
--Purpose:	Parameter pattern strings are a pain. This function generates them.
--inputs:	Parameter tag to generate pattern for
--Returns:	pattern used to search for the tag and return it's parameters

	--Begin pattern with tag search pattern
	local pattern = "\\"..param_tag

	--add the param search pattern
	if tag_list[param_tag] == nil then
		pattern = pattern.."([^\\}]+)"	--default pattern just captures all data between '\tag' and next occurence of '\' or '}'
	else
		if tag_list[param_tag]["par_c"]>1 then
			pattern = pattern.."%(([^%(%)]+)%)"
		else
			if tag_list[param_tag]["type"] == "float" then
				pattern = pattern.."([%d%-%.]+)"
			elseif tag_list[param_tag]["type"] == "int" or tag_list[param_tag]["type"] == "bool" then
				pattern = pattern.."(%d+)"
			elseif tag_list[param_tag]["type"] == "color" or tag_list[param_tag]["type"] == "alpha" then
				pattern = pattern.."(&H[%x]+&)"
			else
				pattern = pattern.."([^\\}]+)"
			end
		end

	end
	return pattern

end
--------------
--Misc Math --
--------------
function  lib.polar_to_cartesian(r, angle)
--purpose:	convert vector in form <distance><angle(degrees)> to form <dx><dy>
	local x,y

	if(debug_level >2) then
		aegisub.debug.out(string.format("Length %g at angle %d produces vector:",r, angle))
	end
	--convert the angle from degrees to radians:
	angle = math.rad(angle)

	x = r*math.cos(angle)
	y = r*math.sin(angle)

	--because of the degree -> radian transformation, these calcs have floating point inaccuaracies
	-- ie/ at 90 degrees we still get some x > 0 (around 1e-15)
	-- still, it fucks around with some calcs, so let get rid of it:
	local precision = 6 --6 places is double the precision used in standard pos tags, should be alright
	x = roundDecimal(x,precision)
	y = roundDecimal(y,precision)

	if(debug_level >0) then
		aegisub.debug.out(string.format("(%g, %g)\n",x,y))
	end

	return x, y
end

function lib.matrix_sum(...)
--Purpose:	Sums entries from two (or more) tables and outputs result
	local arrays={...}
	local sum={}

	for i, x in pairs(arrays[1]) do
		sum[i]=0
		for j= 1, table.getn(arrays) do
			sum[i] = sum[i] + arrays[j][i]
		end
	end

	return sum
end

function roundDecimal(num,places)
--Purpose: Round a number to a given amount of decimal places:
	local mult = 10^places
	return math.floor(num * mult + 0.5) / mult
end
----------------------
--QuickTestFunciton---
----------------------

--So I can test local functions without making them global:
function lib.test(subs, sel)
require 'print_r'

	--test data:
	local line = "This is \\N Test data\\N\\N\\N"
	--Split lines at every '\N'
	local t_lines = lib.string_split(line,"\\N")

	-- Get rid of any blank lines at the end of the array
	---[[
	i = #t_lines
	while t_lines[i] == "" do
		table.remove(t_lines,i)
		i = #t_lines
	end
	aegisub.debug.out(string.format("%s\n",print_r(t_lines,"SplitLines")))

	--test data:
	local line = "This is \\N Test data\\N"
	--Split lines at every '\N'
	local t_lines = lib.string_split(line,"\\N")

	-- Get rid of any blank lines at the end of the array
	---[[
	i = #t_lines
	while t_lines[i] == "" do
		table.remove(t_lines,i)
		i = #t_lines
	end
	aegisub.debug.out(string.format("%s\n",print_r(t_lines,"SplitLines")))


	--test data:
	local line = "This is \\N Test data\\N\\N\\NLine"
	--Split lines at every '\N'
	local t_lines = lib.string_split(line,"\\N")

	-- Get rid of any blank lines at the end of the array
	---[[
	i = #t_lines
	while t_lines[i] == "" do
		table.remove(t_lines,i)
		i = #t_lines
	end
	aegisub.debug.out(string.format("%s\n",print_r(t_lines,"SplitLines")))
end
--------------


----------------------------------------------------
---------[[END OF LIBRARY]]-------------------------
----------------------------------------------------

--return my functions to the includer
--Due to limitations, return a function that then returns all the modules to load.
local function load_lib(...)

	local arg={...}

	--sort through arguments
	for i = 1, table.getn(arg) do
		if arg[i] == "debug_level" then
			if not (aegisub.debug == nil) then
				aegisub.debug.out(string.format("Setting Debug level to %d\n", arg[i+1]))
			end
			debug_level = arg[i+1]
			i = i + 1
		end
	end

	--Initialise globals:
	if debug_level > 0 then
		require 'print_r'
	end

	--randomise the seed
	math.randomseed( os.time() )


	--return this library
	return lib
end

return load_lib
