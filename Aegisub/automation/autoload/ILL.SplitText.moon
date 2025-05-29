export script_name        = "ILL - Split Text"
export script_description = "Splits the text in several ways"
export script_version     = "2.1.2"
export script_author      = "ILLTeam"
export script_namespace   = "ILL.SplitText"

haveDepCtrl, DependencyControl = pcall require, "l0.DependencyControl"

local depctrl, ILL
if haveDepCtrl
	depctrl = DependencyControl {
		feed: "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json",
		{
			{
				"ILL.ILL"
				version: "1.6.4"
				url: "https://github.com/TypesettingTools/ILL-Aegisub-Scripts/"
				feed: "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json"
			}
		}
	}
	ILL = depctrl\requireModules!
else
	ILL = require "ILL.ILL"

{:Ass, :Line} = ILL

main = (mode) ->
    (sub, sel, activeLine) ->
        ass = Ass sub, sel, activeLine, false
        for l, s, i, n in ass\iterSel!
            ass\progressLine s, i, n
            unless l.isShape
                ass\removeLine l, s
                Line.extend ass, l, false
                for line in *switch mode
                        when "chars" then Line.chars ass, l, true
                        when "words" then Line.words ass, l, true
                        when "breaks" then Line.breaks ass, l, true
                        when "tags" then Line.tags ass, l, true
                    fr = line.data.angle != 0
                    if fr or line.text\existsTagOr "frx", "fry", "frz"
                        line.tags\insert {{"org", line.data.org}, true}
					unless line.tags\existsTag "move"
						line.tags\insert {{"pos", Line.reallocate l, line}, true}
					else
						line.tags\insert {{"move", Line.reallocate l, line, true}, true}
                    line.text\modifyBlock line.tags
                    ass\insertLine line, s
            else
                ass\warning s, "Only divite text not shapes"
        return ass\getNewSelection!

if haveDepCtrl
    depctrl\registerMacros {
        {"By Chars", "", main "chars"}
        {"By Words", "", main "words"}
        {"By Tags Blocks", "", main "tags"}
        {"By Line Breaks", "", main "breaks"}
    }
else
    aegisub.register_macro "#{script_name}/By Chars", "", main "chars"
    aegisub.register_macro "#{script_name}/By Words", "", main "words"
    aegisub.register_macro "#{script_name}/By Tags Blocks", "", main "tags"
    aegisub.register_macro "#{script_name}/By Line Breaks", "", main "breaks"