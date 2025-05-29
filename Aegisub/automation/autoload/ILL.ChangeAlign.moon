export script_name        = "Change Alignment"
export script_description = "Changes the alignment of a text or shape without changing its original position"
export script_version     = "1.1.1"
export script_author      = "ILLTeam"
export script_namespace   = "ILL.ChangeAlign"

haveDepCtrl, DependencyControl = pcall require, "l0.DependencyControl"

local depctrl, Aegi, Ass, Line, Path
if haveDepCtrl
	depctrl = DependencyControl {
		feed: "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json",
		{
			{
				"ILL.ILL"
				version: "1.4.4"
				url: "https://github.com/TypesettingTools/ILL-Aegisub-Scripts/"
				feed: "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json"
			}
		}
	}
	{:Aegi, :Ass, :Line, :Path} = depctrl\requireModules!
else
	{:Aegi, :Ass, :Line, :Path} = require "ILL.ILL"

interface = ->
	gui = {}
	for y = 0, 2
		for x = 2, 0, -1 do
			z = x + (2 - y) * 3 + 1
			table.insert gui, {class: "checkbox", name: z, label: z, :x, :y, value: false}
	return gui

main = (sub, sel, activeLine) ->
	button, elements = aegisub.dialog.display interface!, {"Ok", "Cancel"}, {close: "Cancel"}
	if button == "Ok"
		local aln
		for k, v in pairs elements
			if v == true
				if aln
					Aegi.progressCancel "Expected only one selection"
				aln = tonumber k
		unless aln
			Aegi.progressCancel "Expected selection"
		ass = Ass sub, sel, activeLine
		for l, s, i, n in ass\iterSel!
			ass\progressLine s, i, n
			Line.extend ass, l
			Line.changeAlign l, aln
			ass\setLine l, s

if haveDepCtrl
	depctrl\registerMacro main
else
	aegisub.register_macro script_name, script_description, main