module_version = "1.6.5"

haveDepCtrl, DependencyControl = pcall require, "l0.DependencyControl"

local depctrl
if haveDepCtrl
	depctrl = DependencyControl {
		name: "ILL"
		version: module_version
		description: "Module that eases the creation of macros with a focus on handling shapes."
		author: "ILLTeam"
		moduleName: "ILL.ILL"
		url: "https://github.com/TypesettingTools/ILL-Aegisub-Scripts/"
		feed: "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json"
		{
			{"ffi", "json"}
			{
				"clipper2.clipper2"
				version: "1.4.0"
				url: "https://github.com/TypesettingTools/ILL-Aegisub-Scripts/"
				feed: "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json"
			}
		}
	}

import Aegi    from require "ILL.ILL.Aegi"
import Config  from require "ILL.ILL.Config"
import Math    from require "ILL.ILL.Math"
import Table   from require "ILL.ILL.Table"
import Util    from require "ILL.ILL.Util"
import UTF8    from require "ILL.ILL.UTF8"
import Ass     from require "ILL.ILL.Ass.Ass"
import Curve   from require "ILL.ILL.Ass.Shape.Curve"
import Path    from require "ILL.ILL.Ass.Shape.Path"
import Point   from require "ILL.ILL.Ass.Shape.Point"
import Segment from require "ILL.ILL.Ass.Shape.Segment"
import Line    from require "ILL.ILL.Ass.Line"
import Tag     from require "ILL.ILL.Ass.Text.Tag"
import Tags    from require "ILL.ILL.Ass.Text.Tags"
import Text    from require "ILL.ILL.Ass.Text.Text"
import Font    from require "ILL.ILL.Font.Font"

modules = {
	:Aegi, :Config, :Math, :Table, :Util, :UTF8
	:Curve, :Path, :Point, :Segment
	:Tag, :Tags, :Text
	:Ass, :Line
	:Font
	version: module_version
}

if haveDepCtrl
	depctrl\register modules
else
	modules