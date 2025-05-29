export script_name        = "Shapery"
export script_description = "Does several types of shape manipulations from the simplest to the most complex"
export script_version     = "2.6.0"
export script_author      = "ILLTeam"
export script_namespace   = "ILL.Shapery"

haveDepCtrl, DependencyControl = pcall require, "l0.DependencyControl"

local depctrl, Clipper, ILL
if haveDepCtrl
	depctrl = DependencyControl {
		feed: "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json",
		{
			{
				"clipper2.clipper2"
				version: "1.3.2"
				url: "https://github.com/TypesettingTools/ILL-Aegisub-Scripts/"
				feed: "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json"
			}
			{
				"ILL.ILL"
				version: "1.6.5"
				url: "https://github.com/TypesettingTools/ILL-Aegisub-Scripts/"
				feed: "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json"
			}
		}
	}
	Clipper, ILL = depctrl\requireModules!
else
	Clipper = require "clipper2.clipper2"
	ILL = require "ILL.ILL"

{:Aegi, :Ass, :Config, :Line, :Curve, :Path, :Point, :Util, :Math, :Table, :Util} = ILL
clipboard = require "aegisub.clipboard"

checkPathClockWise = (path) ->
	sum = 0
	for i = 1, #path
		currPoint = path[i]
		nextPoint = path[(i % #path) + 1]
		sum += (nextPoint.x - currPoint.x) * (nextPoint.y + currPoint.y)
	return sum < 0

interfaces = {
	config: -> {
		{class: "label", label: "Expand", x: 0, y: 0}
		{class: "floatedit", x: 0, y: 1, name: "cutBordShadow", min: 0.1, max: 2, step: 0.1, value: 1}
		{class: "checkbox", label: "Shape Expand Outline", x: 0, y: 2, name: "expandBordShadow", value: false}
		{class: "checkbox", label: "Comment Current Lines", x: 0, y: 3, name: "saveLines", value: false}
		{class: "label", label: "Reset Macro", x: 0, y: 5}
		{class: "dropdown", items: {"All", "Config", "Pathfinder", "Offsetting", "Manipulate", "Transform", "Utilities"}, x: 0, y: 6, name: "reset", value: "All"}
	}
	pathfinder: -> {
		{class: "label", label: "Operation:", x: 0, y: 0}
		{class: "dropdown", items: {"Unite", "Intersect", "Difference", "Exclude"}, x: 1, y: 0, name: "operation", value: "Unite"}
		{class: "checkbox", label: "Multiline", x: 0, y: 2, name: "multiline", value: false}
	}
	offsetting: -> {
		{class: "label", label: "Stroke Weight", x: 0, y: 0}
		{class: "floatedit", x: 1, y: 0, name: "strokeWeight", value: 0}
		{class: "checkbox", x: 1, y: 1, name: "cut", value: false}
		{class: "label", label: "Corner Style", x: 0, y: 2}
		{class: "dropdown", items: {"Miter", "Round", "Square"}, x: 1, y: 2, name: "cornerStyle", value: "Round"}
		{class: "label", label: "Align Stroke", x: 0, y: 3}
		{class: "dropdown", items: {"Outside", "Center", "Inside"}, x: 1, y: 3, name: "strokeAlign", value: "Outside"}
		{class: "label", label: "Miter Limit", x: 0, y: 5}
		{class: "floatedit", x: 0, y: 6, name: "miterLimit", value: 2}
		{class: "label", label: "Arc Precision", x: 1, y: 5}
		{class: "floatedit", x: 1, y: 6, name: "arcPrecision", value: 0.25}
	}
	manipulate: -> {
		{class: "label", label: "Fit Curves", x: 0, y: 0}
		{class: "checkbox", x: 3, y: 0, name: "recreateBezier", value: true}
		{class: "label", label: "Execute On \\clip", x: 0, y: 1}
		{class: "checkbox", x: 3, y: 1, name: "enableClip", value: false}
		{class: "label", label: "- Simplify -----", x: 0, y: 3}
		{class: "label", label: "Tolerance", x: 0, y: 4}
		{class: "floatedit", x: 3, y: 4, name: "tolerance", min: 0.1, max: 10, step: 0.01, value: 0.5}
		{class: "label", label: "Angle Threshold", x: 0, y: 5}
		{class: "floatedit", x: 3, y: 5, name: "angleThreshold", min: 0, max: 180, step: 0.1, value: 170}
		{class: "label", label: "- Flatten -----", x: 0, y: 7}
		{class: "label", label: "Distance", x: 0, y: 8}
		{class: "floatedit", x: 3, y: 8, name: "distance", min: 0.1, max: 100, step: 0.1, value: 1}
	}
	transform: -> {
		{class: "label", label: "- Move -----", x: 0, y: 0}
		{class: "label", label: "X axis", x: 0, y: 1}
		{class: "floatedit", x: 1, y: 1, name: "xAxis", value: 0}
		{class: "label", label: "Y axis", x: 0, y: 2}
		{class: "floatedit", x: 1, y: 2, name: "yAxis", value: 0}
		{class: "label", label: "- Rotate -----", x: 4, y: 0}
		{class: "label", label: "Angle", x: 4, y: 1}
		{class: "floatedit", x: 4, y: 2, name: "angle", value: 0}
		{class: "label", label: "- Scale -----", x: 8, y: 0}
		{class: "label", label: "Hor. %", x: 8, y: 1}
		{class: "floatedit", x: 9, y: 1, name: "horizontalScale", min: 1, max: 500, step: 0.1, value: 100}
		{class: "label", label: "Ver. %", x: 8, y: 2}
		{class: "floatedit", x: 9, y: 2, name: "verticalScale", min: 1, max: 500, step: 0.1, value: 100}
		{class: "label", label: "- Filter -----", x: 0, y: 3}
		{class: "textbox", x: 0, y: 4, width: 10, height: 8, name: "filter", value: ""}
		{class: "label", label: "- Global Variables --> ILL | left | right | top | botton | width | height | x | y", x: 0, y: 12}
	}
	utilities: -> {
		{class: "label", label: "Shadow Effect", x: 0, y: 0}
		{class: "dropdown", items: {"Inner shadow", "3D from shadow", "3D from shape"}, x: 0, y: 1, name: "shadow", value: "Inner shadow"}
		{class: "label", label: "Corner", x: 4, y: 0}
		{class: "dropdown", items: {"Rounded", "Inverted Round", "Chamfer", "Spike"}, x: 5, y: 0, name: "cornerStyle", value: "Rounded"}
		{class: "label", label: "Radius", x: 4, y: 1}
		{class: "floatedit", x: 5, y: 1, name: "radius", min: 0, max: 1e5, step: 0.1, value: 0}
		{class: "label", label: "Rounding", x: 4, y: 2}
		{class: "dropdown", items: {"Absolute", "Relative"}, x: 5, y: 2, name: "rounding", value: "Absolute"}
	}
	cutcontour: -> {
		{class: "label", label: "Input Shape:", x: 0, y: 0}
		{class: "textbox", x: 0, y: 1, width: 10, height: 5, name: "shape", value: ""}
		{class: "label", label: "Tolerance:", x: 0, y: 6}
		{class: "checkbox", label: "Mode Xor", x: 9, y: 6, name: "modeXor", value: false}
		{class: "floatedit", x: 0, y: 7, name: "tol", min: 1, value: 10}
	}
}

resetInterface = (name) ->
	if name != "All"
		cfg = Config interfaces[name\lower!]!
		cfg\setJsonPath script_namespace .. name
		cfg\reset!
	else
		interface = interfaces.config!
		for n in *interface[5].items
			if n != "All"
				resetInterface n

getConfigElements = ->
	cfg = Config interfaces.config!
	cfg\setJsonPath script_namespace .. "Config"
	return Config.getElements cfg\getInterface!

PathfinderDialog = (sub, sel, activeLine) ->
	button, elements = Aegi.display interfaces.pathfinder!, {"Ok", "Cancel"}, {close: "Cancel"}, "Pathfinder"
	if button != "Cancel"
		cfg = getConfigElements!
		ass = Ass sub, sel, activeLine, not cfg.saveLines
		info = {shapes: {}}
		{:multiline, :operation} = elements
		for l, s, i, n in ass\iterSel!
			ass\progressLine s, i, n
			ass\removeLine l, s
			Line.extend ass, l
			if multiline
				if n == 1
					Aegi.progressCancel "You must select 2 lines or more."
				clip = {}
				Line.callBackExpand ass, l, nil, (line, j) ->
					{x, y} = line.data.pos
					if i == 1 and j == 1
						info.pos = {x, y}
						info.line = Table.copy line
					table.insert clip, Path(line.shape)\move(x - info.pos[1], y - info.pos[2])\export!
				table.insert info.shapes, Path table.concat clip
				if i == n
					{:line, :shapes} = info
					shape = shapes[1]
					for j = 2, #shapes
						cut = shapes[j]
						switch operation
							when "Unite"      then shape\unite      cut
							when "Intersect"  then shape\intersect  cut
							when "Difference" then shape\difference cut
							when "Exclude"    then shape\exclude    cut
					line.shape = shape\export!
					if line.shape != ""
						ass\insertLine line, s
			else
				if clip = l.data.clip
					Line.callBackExpand ass, l, nil, (line) ->
						{px, py} = line.data.pos
						shape = Path line.shape
						cut = Path(clip)\move -px, -py
						switch operation
							when "Unite"      then shape\unite      cut
							when "Intersect"  then shape\intersect  cut
							when "Difference" then shape\difference cut
							when "Exclude"    then shape\exclude    cut
						line.shape = shape\export!
						if line.shape != ""
							line.tags\remove "clip", "iclip"
							ass\insertLine line, s
				else
					ass\error s, "Expected \\clip or \\iclip tag"
		return ass\getNewSelection!

OffsettingDialog = (sub, sel, activeLine) ->
	button, elements = Aegi.display interfaces.offsetting!, {"Ok", "Cancel"}, {close: "Cancel"}, "Offsetting"
	if button != "Cancel"
		cfg = getConfigElements!
		ass = Ass sub, sel, activeLine, not cfg.saveLines
		{:strokeWeight, :strokeAlign, :cornerStyle, :miterLimit, :arcPrecision, :cut} = elements
		if strokeWeight < 0
			strokeAlign = "Inside"
		cornerStyle = cornerStyle\lower!
		cutsOutside = cut and strokeAlign == "Outside"
		for l, s, i, n in ass\iterSel!
			ass\progressLine s, i, n
			ass\removeLine l, s
			Line.extend ass, l
			Line.callBackExpand ass, l, nil, (line) ->
				path, clip = Path line.shape
				if cutsOutside
					clip = path\clone!
				switch strokeAlign
					when "Outside" then path\offset strokeWeight, cornerStyle, "polygon", miterLimit, arcPrecision
					when "Center"  then path\offset strokeWeight, cornerStyle, "joined", miterLimit, arcPrecision
					when "Inside"  then path\offset -math.abs(strokeWeight), cornerStyle, "polygon", miterLimit, arcPrecision
				if cutsOutside
					path\difference clip
				line.shape = path\export!
				ass\insertLine line, s
		return ass\getNewSelection!

ManipulateDialog = (sub, sel, activeLine) ->
	button, elements = Aegi.display interfaces.manipulate!, {"Simplify", "Flatten", "Cancel"}, {close: "Cancel"}, "Manipulate"
	if button != "Cancel"
		cfg = getConfigElements!
		ass = Ass sub, sel, activeLine, not cfg.saveLines
		{:enableClip, :recreateBezier, :distance, :angleThreshold, :tolerance} = elements
		for l, s, i, n in ass\iterSel!
			ass\progressLine s, i, n
			Line.extend ass, l
			if enableClip
				{:clip, :isIclip} = l.data
				if clip
					if type(clip) != "table"
						if button == "Flatten"
							clip = Path(clip)\flatten(distance)\export!
						elseif button == "Simplify"
							clip = Path(clip)\simplify(tolerance, false, recreateBezier, angleThreshold)\export!
						if isIclip
							l.tags\insert {{"iclip", clip}}
						else
							l.tags\insert {{"clip", clip}}
						unless l.isShape
							l.text\modifyBlock l.tags
						ass\setLine l, s
				else
					ass\warning s, "Expected \\clip or \\iclip tag"
			else
				if l.isShape
					ass\removeLine l, s
					path = Path l.shape
					if button == "Flatten"
						path\flatten distance
					elseif button == "Simplify"
						path\simplify tolerance, false, recreateBezier, angleThreshold
					l.shape = path\export!
					ass\insertLine l, s
				else
					ass\warning s, "Expected a shape"
		return ass\getNewSelection!

TransformDialog = (sub, sel, activeLine) ->
	button, elements = Aegi.display interfaces.transform!, {"Ok", "Cancel"}, {close: "Cancel"}, "Transform"
	if button != "Cancel"
		cfg = getConfigElements!
		ass = Ass sub, sel, activeLine, not cfg.saveLines
		{:horizontalScale, :verticalScale, :angle, :xAxis, :yAxis, :filter} = elements
		for l, s, i, n in ass\iterSel!
			ass\progressLine s, i, n
			Line.extend ass, l
			if l.isShape
				ass\removeLine l, s
				path = Path l.shape
				if horizontalScale != 0 or verticalScale != 0
					path\scale horizontalScale, verticalScale
				if angle != 0
					path\rotatefrz angle
				if xAxis != 0 or yAxis != 0
					path\move xAxis, yAxis
				if filter != ""
					box = path\boundingBox!
					raw = [[
						local ILL = require "ILL.ILL"
						local s, i, n = %d, %d, %d
						local left, top, right, bottom = %s, %s, %s, %s
						local width, height = %s, %s
						return function(x, y)
							%s
							return x, y
						end
					]]
					path\map loadstring(raw\format(s, i, n, box.l, box.t, box.r, box.b, box.width, box.height, filter))!
				l.shape = path\export!
				ass\insertLine l, s
			else
				ass\warning s, "Expected a shape"
		return ass\getNewSelection!

UtilitiesDialog = (sub, sel, activeLine) ->
	button, elements = Aegi.display interfaces.utilities!, {"Shadow", "Corners", "Cancel"}, {close: "Cancel"}, "Utilities"
	if button != "Cancel"
		cfg = getConfigElements!
		ass = Ass sub, sel, activeLine, not cfg.saveLines
		{:shadow, :cornerStyle, :rounding, :radius} = elements
		switch button
			when "Shadow"
				local xshad, yshad
				for l, s, i, n in ass\iterSel!
					ass\progressLine s, i, n
					ass\removeLine l, s
					Line.extend ass, l
					Line.callBackExpand ass, l, nil, (line) ->
						{:data} = line
						switch shadow
							when "3D from shadow", "Inner shadow"
								xshad, yshad = Line.solveShadow line
								if shadow == "3D from shadow"
									line.shape = Path(line.shape)\shadow(xshad, yshad, "3D")\export!
								else
									-- adds the current line, removing unnecessary tags
									line.tags\remove "shadow", "4c"
									line.tags\insert "\\shad0"
									ass\insertLine line, s
									-- adds the shadow color to the first color and sets
									-- the new value for the shape
									line.tags\insert {{"c", data.color4}}

									line.shape = Path(line.shape)\shadow(xshad, yshad, "inner")\export!
							when "3D from shape"
								if n < 2 or n > 2
									Aegi.progressCancel "You must select 2 lines."
								if i == 1
									{xshad, yshad} = data.pos
									return
								else
									line.shape = Path(line.shape)\shadow(xshad - data.pos[1], yshad - data.pos[2], "3D")\export!
						line.tags\remove "shad", "xshad", "yshad", "4c"
						line.tags\insert "\\shad0"
						ass\insertLine line, s
			when "Corners"
				inverted = cornerStyle == "Inverted Round"
				for l, s, i, n in ass\iterSel!
					ass\progressLine s, i, n
					ass\removeLine l, s
					Line.extend ass, l
					Line.callBackExpand ass, l, nil, (line) ->
						line.shape = Path.RoundingPath(line.shape, radius, inverted, cornerStyle, rounding)\export!
						ass\insertLine line, s
		return ass\getNewSelection!

CutContourDialog = (sub, sel, activeLine) ->
	button, elements = Aegi.display interfaces.cutcontour!, {"Ok", "Cancel"}, {close: "Cancel"}, "CutContour"
	{:tol, :shape, :modeXor} = elements
	inputShape = elements.shape
	if button != "Cancel" and inputShape != ""
		inputShape = Path(inputShape)\toCenter!
		cfg = getConfigElements!
		ass = Ass sub, sel, activeLine, not cfg.saveLines
		pi2 = math.pi * 0.5
		tol = 1 / tol
		for l, s, i, n in ass\iterSel!
			ass\progressLine s, i, n
			ass\removeLine l, s
			Line.extend ass, l
			Line.callBackExpand ass, l, nil, (line) ->
				{:data} = line
				path = Path(line.shape)\closeContours!
				bbox = path\boundingBox!
				copy = path\clone!
				copy\toOrigin!
				pathLen = math.floor path\getLength! * tol
				for j = 0, pathLen - 1
					tan, p = copy\getNormalized j / pathLen
					ang = tan\angle! + pi2
					shp = inputShape\clone!
					shp = shp\rotate ang
					shp = shp\move bbox.l + p.x, bbox.t + p.y
					if elements.modeXor
						path = path\exclude shp
					else
						path = path\difference shp
				line.shape = path\export!
				ass\insertLine line, s
		return ass\getNewSelection!

ConfigDialog = (sub, sel, activeLine) ->
	button, elements = Aegi.display interfaces.config!, {"Ok", "Reset", "Cancel"}, {close: "Cancel"}, "Config"
	if button == "Reset"
		resetInterface elements.reset
		switch elements.reset
			when "Config"     then ConfigDialog sub, sel, activeLine
			when "Pathfinder" then PathfinderDialog sub, sel, activeLine
			when "Offsetting" then OffsettingDialog sub, sel, activeLine
			when "Manipulate" then ManipulateDialog sub, sel, activeLine
			when "Transform"  then TransformDialog sub, sel, activeLine
			when "Utilities"  then UtilitiesDialog sub, sel, activeLine

ShaperyMacrosDialog = (macro) ->
	(sub, sel, activeLine) ->
		cfg = getConfigElements!
		ass = Ass sub, sel, activeLine, not cfg.saveLines
		mergeShapesObj = {}
		lines = {}
		for l, s, i, n in ass\iterSel!
			ass\progressLine s, i, n
			Line.extend ass, l
			switch macro
				when "Shape expand"
					ass\removeLine l, s
					Line.callBackExpand ass, l, nil, (line) ->
						copy = Table.copy line
						if cfg.expandBordShadow
							xshad, yshad = Line.solveShadow line
							line.tags\remove "outline", "shadow", "3c", "4c"
							copy.tags\remove "outline", "shadow", "3c", "4c"
							line.tags\insert "\\shad0\\bord0"
							copy.tags\insert "\\shad0\\bord0"
							-- gets the required values
							{:outline, :color1, :color3, :color4} = line.data
							-- conditions to check if it needs to expand ouline, shadow or both
							passOutline = outline > 0
							passShadows = xshad != 0 or yshad != 0
							if passOutline or passShadows
								path, pathOutline, pathShadow, cutShadow = Path line.shape
								-- solves outline
								if passOutline
									pathOutline = path\clone!
									pathOutline\offset outline, "round"
									if passShadows
										cutShadow = pathOutline\clone!
								-- solves shadow
								if passShadows
									pathShadow = (pathOutline and pathOutline or path)\clone!
									pathShadow\move xshad, yshad
									if passOutline
										if color3 == color4
											pathShadow\unite pathOutline
											pathShadow\difference path
										else
											pathShadow\difference cutShadow\offset -cfg.cutBordShadow, "miter"
									else
										pathShadow\difference path
									line.shape = pathShadow\export!
									line.tags\insert {{"c", color4}}
									ass\insertLine line, s
								-- solves outline
								if passOutline and not (passShadows and color3 == color4)
									path\offset -cfg.cutBordShadow, "miter"
									pathOutline\difference path
									-- adds outline
									line.shape = pathOutline\export!
									line.tags\insert {{"c", color3}}
									ass\insertLine line, s
						ass\insertLine copy, s
				when "Shape clipper"
					{:clip, :isIclip} = l.data
					if clip
						ass\removeLine l, s
						Line.callBackExpand ass, l, nil, (line) ->
							shape = Path line.shape
							{px, py} = line.data.pos
							cut = Path(clip)\move -px, -py
							if isIclip
								shape\difference cut
							else
								shape\intersect cut
							line.shape = shape\export!
							if line.shape != ""
								line.tags\remove "clip", "iclip"
								ass\insertLine line, s
					else
						ass\warning s, "Expected \\clip or \\iclip tag"
				when "Shape to clip", "Shape to clip (clipboard)"
					clip = {}
					Line.callBackExpand ass, l, nil, (line) ->
						{px, py} = line.data.pos
						table.insert clip, Path(line.shape)\move(px, py)\export!
					clip = table.concat clip, " "
					if l.data.isIclip
						l.tags\insert {{"iclip", clip}}
					else
						l.tags\insert {{"clip", clip}}
					unless l.isShape
						l.text\modifyBlock l.tags
					if macro == "Shape to clip (clipboard)"
						clipboard.set "\\clip(#{clip})"
					else
						ass\setLine l, s
				when "Clip to shape"
					{:an, :pos, :clip} = l.data
					if clip
						{px, py} = pos
						l.shape = Path(clip)\reallocate(an, nil, true, px, py)\export!
						l.tags\remove "perspective", "clip", "iclip"
						unless l.isShape
							l.isShape = true
							l.tags\remove "font"
							l.tags\insert {{"pos", pos}, true}, {{"an", an}, true}, "\\fscx100\\fscy100\\frz0\\p1"
						ass\setLine l, s
					else
						ass\warning s, "Expected \\clip or \\iclip tag"
				when "Shape bounding box"
					if l.isShape
						l.shape = Path(l.shape)\boundingBox!["assDraw"]
						ass\setLine l, s
					else
						ass\warning s, "Expected a shape"
				when "Shape morph"
					if l.isShape
						if n < 2 or n > 2
							ass\error s, "Expected two selected lines"
						ass\removeLine l, s
						Line.callBackExpand ass, l, nil, (line) ->
							{px, py} = line.data.pos
							line.shape = Path(line.shape)\move(px, py)\export!
							table.insert lines, line
						if i == n
							a = Path lines[1].shape
							b = Path lines[2].shape
							Line.callBackFBF ass, lines[1], (line, frame_index, end_frame, j, n) ->
								line.shape = a\morph(b, (j - 1) / (n - 1))\export!
								ass\insertLine line, s
					else
						ass\warning s, "Expected a shape"
				when "Shape merge"
					if l.isShape
						{:color1, :color3, :color4, :alpha, :alpha1, :alpha2, :alpha3, :alpha4} = l.data
						code = (alpha .. color1 .. alpha1 .. color3 .. alpha3 .. color4 .. alpha4)\gsub "[&hH]*", ""
						if n < 2
							ass\error s, "Expected one or more selected lines"
						if info = mergeShapesObj[code]
							clip = {}
							Line.callBackExpand ass, l, nil, (line, j) ->
								{x, y} = line.data.pos
								table.insert clip, Path(line.shape)\move(x - info.pos[1], y - info.pos[2])\export!
							info.shape ..= " " .. table.concat clip, " "
							if i == n
								mergeShapesArray = {}
								for k, v in pairs mergeShapesObj
									table.insert mergeShapesArray, v
								table.sort mergeShapesArray, (a, b) -> a.i < b.i
								if #mergeShapesArray > 0
									ass\deleteLines l, sel
									for k = 1, #mergeShapesArray
										{:line, :shape} = mergeShapesArray[k]
										line.shape = shape
										ass\insertLine line, s
						else
							clip, lcopy = {}, nil
							Line.callBackExpand ass, l, nil, (line, j) ->
								if j == 1
									lcopy = Table.copy line
								table.insert clip, Path(line.shape)\export!
							mergeShapesObj[code] = {:i, pos: l.data.pos, line: lcopy, shape: table.concat clip}
					else
						ass\warning s, "Expected a shape"
				when "Shape blend"
					if l.isShape
						if n < 2
							ass\error s, "Expected one or more selected lines"
						Line.callBackExpand ass, l, nil, (line, j) ->
							{x, y} = l.data.pos
							newPath = Path line.shape
							newPath\move x, y
							line.tags\remove "move"
							line.tags\insert {{"pos", {0, 0}}, true}
							line.data.pos = {0, 0}
							table.insert mergeShapesObj, {tags: line.tags, path: newPath}
							if j == 1 and i == 1
								lines.line = Table.copy line
						if i == n
							ass\deleteLines l, sel
							prev = mergeShapesObj[1]
							preb = prev.path\boundingBox!
							sumw = preb.width
							maxh = preb.height
							buff = {}
							for j = 2, #mergeShapesObj
								buff[j] = mergeShapesObj[j].path\boundingBox!
								maxh = math.max maxh, buff[j].height
							text = prev.tags\get! .. prev.path\move(0, -maxh + preb.height)\export!
							for j = 2, #mergeShapesObj
								curr = mergeShapesObj[j]
								tags = Table.copy curr.tags
								tags\difference prev.tags
								tags\insert "\\p1"
								curr.path\move -sumw, -maxh + buff[j].height
								text ..= tags\get! .. curr.path\export!
								sumw += buff[j].width
								prev = curr
							lines.line.text = ILL.Text text
							lines.line.isShape = false
							ass\insertLine lines.line, s
					else
						ass\warning s, "Expected a shape"
				when "Shape without holes"
					if l.isShape
						newShape = Path!
						shapePath = Path l.shape
						shapePathFlattened = Path(shapePath)\flatten!
						for j = 1, #shapePath.path
							if checkPathClockWise shapePathFlattened.path[j]
								table.insert newShape.path, shapePath.path[j]
						l.shape = newShape\export!
						ass\setLine l, s
					else
						ass\warning s, "Expected a shape"
				when "Shape trim"
					if l.isShape
						Line.callBackExpand ass, l, nil, (line, j) ->
							{px, py} = line.data.pos
							line.shape = Path(line.shape)\move(px, py)\export!
							table.insert lines, line
						if i == n and n > 1
							for j = #lines, 1, -1
								cut = Path lines[j].shape
								for k = j - 1, 1, -1
									newShape = Path(lines[k].shape)\difference cut
									lines[k].shape = newShape\export!
							ass\deleteLines l, sel
							for line in *lines
								{px, py} = line.data.pos
								line.shape = Path(line.shape)\move(-px, -py)\export!
								ass\insertLine line, s
					else
						ass\warning s, "Expected a shape"
				when "Shape to 0,0"
					if l.isShape
						{x, y} = l.data.pos
						newPath = Path l.shape
						newPath\move x, y
						l.tags\remove "move"
						l.tags\insert {{"pos", {0, 0}}, true}
						l.shape = newPath\export!
						ass\setLine l, s
					else
						ass\warning s, "Expected a shape"
				when "Shape to pos"
					if l.isShape and l.tags\existsTag "clip"
						local cx, cy, fn
						fn = (x, y) ->
							cx = tonumber x
							cy = tonumber y
							return x, y
						l.tags\getTag("clip").value\gsub "(%d[%.%d]*)%s+(%d[%.%d]*)", fn, 1
						{x, y} = l.data.pos
						newPath = Path l.shape
						newPath\move x - cx, y - cy
						l.tags\remove "move", "clip"
						l.tags\insert {{"pos", {cx, cy}}, true}
						l.shape = newPath\export!
						ass\setLine l, s
					else
						ass\warning s, "Expected a shape"
				when "Shape to origin", "Shape to center"
					if l.isShape
						too = macro == "Shape to origin"
						newPath = Path l.shape
						{l: x, t: y, :width, :height} = newPath\boundingBox!
						if too
							newPath\toOrigin!
						else
							x += width / 2
							y += height / 2
							newPath\toCenter!
						l.shape = newPath\export!
						with l.data
							if l.tags\existsTag "move"
								.move[1] += x
								.move[2] += y
								.move[3] += x
								.move[4] += y
								l.tags\insert {{"move", .move}, true}
							else
								.pos[1] += x
								.pos[2] += y
								l.tags\insert {{"pos", .pos}, true}
						unless too
							Line.changeAlign l, 7
						ass\setLine l, s
					else
						ass\warning s, "Expected a shape"
		return ass\getNewSelection!

if haveDepCtrl
	depctrl\registerMacros {
		{"Pathfinder",    "", PathfinderDialog}
		{"Offsetting",    "", OffsettingDialog}
		{"Manipulate",    "", ManipulateDialog}
		{"Transform",     "", TransformDialog}
		{"Utilities",     "", UtilitiesDialog}
		{"Cut Contour",   "", CutContourDialog}
		{"Config",        "", ConfigDialog}
	}

	depctrl\registerMacros {
		{"Shape expand",              "", ShaperyMacrosDialog "Shape expand"}
		{"Shape clipper",             "", ShaperyMacrosDialog "Shape clipper"}
		{"Clip to shape",             "", ShaperyMacrosDialog "Clip to shape"}
		{"Shape to clip",             "", ShaperyMacrosDialog "Shape to clip"}
		{"Shape to clip (clipboard)", "", ShaperyMacrosDialog "Shape to clip (clipboard)"}
		{"Shape merge",               "", ShaperyMacrosDialog "Shape merge"}
		{"Shape blend",               "", ShaperyMacrosDialog "Shape blend"}
		{"Shape morph",               "", ShaperyMacrosDialog "Shape morph"}
		{"Shape trim",                "", ShaperyMacrosDialog "Shape trim"}
		{"Shape to 0,0",              "", ShaperyMacrosDialog "Shape to 0,0"}
		{"Shape to pos",              "", ShaperyMacrosDialog "Shape to pos"}
		{"Shape to origin",           "", ShaperyMacrosDialog "Shape to origin"}
		{"Shape to center",           "", ShaperyMacrosDialog "Shape to center"}
		{"Shape without holes",       "", ShaperyMacrosDialog "Shape without holes"}
		{"Shape bounding box",        "", ShaperyMacrosDialog "Shape bounding box"}
	}, ": Shapery macros :"
else
	aegisub.register_macro "#{script_name}/Pathfinder",    "", PathfinderDialog
	aegisub.register_macro "#{script_name}/Offsetting",    "", OffsettingDialog
	aegisub.register_macro "#{script_name}/Manipulate",    "", ManipulateDialog
	aegisub.register_macro "#{script_name}/Transform",     "", TransformDialog
	aegisub.register_macro "#{script_name}/Utilities",     "", UtilitiesDialog
	aegisub.register_macro "#{script_name}/Cut Contour",   "", CutContourDialog
	aegisub.register_macro "#{script_name}/Config",        "", ConfigDialog

	aegisub.register_macro ": Shapery macros :/Shape expand",              "", ShaperyMacrosDialog "Shape expand"
	aegisub.register_macro ": Shapery macros :/Shape clipper",             "", ShaperyMacrosDialog "Shape clipper"
	aegisub.register_macro ": Shapery macros :/Clip to shape",             "", ShaperyMacrosDialog "Clip to shape"
	aegisub.register_macro ": Shapery macros :/Shape to clip",             "", ShaperyMacrosDialog "Shape to clip"
	aegisub.register_macro ": Shapery macros :/Shape to clip (clipboard)", "", ShaperyMacrosDialog "Shape to clip (clipboard)"
	aegisub.register_macro ": Shapery macros :/Shape merge",               "", ShaperyMacrosDialog "Shape merge"
	aegisub.register_macro ": Shapery macros :/Shape blend",               "", ShaperyMacrosDialog "Shape blend"
	aegisub.register_macro ": Shapery macros :/Shape morph",               "", ShaperyMacrosDialog "Shape morph"
	aegisub.register_macro ": Shapery macros :/Shape trim",                "", ShaperyMacrosDialog "Shape trim"
	aegisub.register_macro ": Shapery macros :/Shape to 0,0",              "", ShaperyMacrosDialog "Shape to 0,0"
	aegisub.register_macro ": Shapery macros :/Shape to pos",              "", ShaperyMacrosDialog "Shape to pos"
	aegisub.register_macro ": Shapery macros :/Shape to origin",           "", ShaperyMacrosDialog "Shape to origin"
	aegisub.register_macro ": Shapery macros :/Shape to center",           "", ShaperyMacrosDialog "Shape to center"
	aegisub.register_macro ": Shapery macros :/Shape without holes",       "", ShaperyMacrosDialog "Shape without holes"
	aegisub.register_macro ": Shapery macros :/Shape bounding box",        "", ShaperyMacrosDialog "Shape bounding box"