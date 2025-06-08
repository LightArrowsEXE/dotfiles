-- Script information
script_name = "Wave"
script_description = "Make the string wavy"
script_author = "PhosCity"
script_version = "1.0.3"
script_namespace = "phos.wave"

local haveDepCtrl, DependencyControl, depRec = pcall(require, "l0.DependencyControl")
if haveDepCtrl then
	depRec = DependencyControl({
		feed = "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
		{ "karaskel" },
	})
	depRec:requireModules()
else
	require("karaskel")
end

local function stringToTable(text)
	local table = {}
	for i = 0, #text do
		table[i] = text:sub(i, i)
	end
	return table
end

local function wave(res, text, scale_x, scale_y, spacing, wave_time)
	local STING = stringToTable(text)
	local new_text = ""
	-- Credit for the original code below before modification: The0x539
	for j = 0, #STING do
		new_text = new_text
			.. string.format(
				"{\\fsp%.1f\\fscx%.1f\\fscy%.1f",
				spacing + 5 * math.sin(j),
				scale_x + 10 * math.sin(j),
				scale_y + 10 * math.sin(j)
			)
		for i = 0, wave_time, res.frequency do
			local i2 = i + res.frequency
			new_text = new_text
				.. string.format(
					"\\t(%d,%d,\\fsp%.1f\\fscx%.1f\\fscy%.1f)",
					math.floor(i * 1000),
					math.floor(i2 * 1000),
					spacing + 5 * math.sin(res.fsp * i2 + j),
					scale_x + 10 * math.sin(res.fscx * i2 + j),
					scale_y + 10 * math.sin(res.fscy * i2 + j)
				)
		end
		new_text = new_text .. string.format("}%s", STING[j])
	end
	return new_text
end

local function main(subs, sel, res)
	local meta, styles = karaskel.collect_head(subs, false)
	for _, i in ipairs(sel) do
		if subs[i].class == "dialogue" then
			--default values
			local scale_x = 100
			local scale_y = 100
			local spacing = 0

			local line = subs[i]
			local tags = line.text:match("{\\[^}]-}")
			local text = line.text:gsub("{\\[^}]-}", "")

			-- Time and frequency
			local line_duration = line.end_time - line.start_time
			local total_wave_time = (line_duration + 100) / 1000
			if res.frequency >= total_wave_time then
				aegisub.log(
					"The frequency you provided should be lesser than the line duration i.e. " .. total_wave_time
				)
				return
			end

			--get style data
			karaskel.preproc_line(subs, meta, styles, line)
			scale_x = line.styleref.scale_x
			scale_y = line.styleref.scale_y
			spacing = line.styleref.spacing

			if tags then
				-- get tags in line
				if line.text:match("\\fscx([^}\\]+)") then
					scale_x = line.text:match("\\fscx([^}\\]+)")
				end
				if line.text:match("\\fscy([^}\\]+)") then
					scale_y = line.text:match("\\fscy([^}\\]+)")
				end
				if line.text:match("\\fsp([^}\\]+)") then
					spacing = line.text:match("\\fsp([^}\\]+)")
				end
				line.text = tags .. wave(res, text, scale_x, scale_y, spacing, total_wave_time)
				line.text = line.text:gsub("}{", "")
			else
				line.text = wave(res, text, scale_x, scale_y, spacing, total_wave_time)
			end
			subs[i] = line
		end
	end
end

local function load_macro(subs, sel)
	--GUI
	local GUI = {
		{ x = 0, y = 0, class = "label", label = "fscx strength: ", hint = "fscx strength" },
		{ x = 1, y = 0, class = "floatedit", name = "fscx", value = "2", hint = "fscx strength" },
		{ x = 0, y = 1, class = "label", label = "fscy strength: ", hint = "fscy strength" },
		{ x = 1, y = 1, class = "floatedit", name = "fscy", value = "2", hint = "fscy strength" },
		{ x = 0, y = 2, class = "label", label = "fsp strength: ", hint = "fsp strength" },
		{ x = 1, y = 2, class = "floatedit", name = "fsp", value = "2", hint = "fsp strength" },
		{
			x = 0,
			y = 3,
			class = "label",
			label = "frequency should",
		},
		{
			x = 1,
			y = 3,
			class = "label",
			label = " be lesser than the line duration in seconds",
		},
		{ x = 0, y = 4, class = "label", label = "frequency: ", hint = "more is slower" },
		{ x = 1, y = 4, class = "floatedit", name = "frequency", value = "0.1", hint = "more is slower" },
	}

	local buttons = { "OK", "Cancel" }
	local pressed, res = aegisub.dialog.display(GUI, buttons)

	if pressed == "Cancel" then
		aegisub.cancel()
	end
	if pressed == "OK" then
		main(subs, sel, res)
	end

	aegisub.set_undo_point(script_name)
end

-- Register macro to Aegisub
if haveDepCtrl then
	depRec:registerMacro(load_macro)
else
	aegisub.register_macro(script_author .. "/" .. script_name, script_description, load_macro)
end
