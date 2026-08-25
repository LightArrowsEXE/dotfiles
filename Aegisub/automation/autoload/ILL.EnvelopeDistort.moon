export script_name        = "Envelope Distort"
export script_description = "Allows you to warp and manipulate shapes within a customizable envelope"
export script_version     = "1.1.7"
export script_author      = "ILLTeam"
export script_namespace   = "ILL.EnvelopeDistort"

haveDepCtrl, DependencyControl = pcall require, "l0.DependencyControl"

local depctrl, ILL
if haveDepCtrl
	depctrl = DependencyControl {
		feed: "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json",
		{
			{
				"ILL.ILL"
				version: "1.8.4"
				url: "https://github.com/TypesettingTools/ILL-Aegisub-Scripts/"
				feed: "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json"
			}
		}
	}
	ILL = depctrl\requireModules!
else
	ILL = require "ILL.ILL"

{:Aegi, :Ass, :Line, :Path, :Util} = ILL

interface = -> {
	{class: "label", label: " - Mesh options -----", x: 0, y: 0}
	{class: "label", label: "Line type", x: 0, y: 1}
	{class: "dropdown", items: {"Straight", "Bezier", "Mix"}, x: 1, y: 1, name: "lineType", value: "Straight"}
	{class: "label", label: "Rows", x: 0, y: 2}
	{class: "intedit", min: 1, x: 1, y: 2, name: "rows", value: 1}
	{class: "label", label: "Columns", x: 0, y: 3}
	{class: "intedit", min: 1, x: 1, y: 3, name: "cols", value: 1}
	{class: "label", label: "Tolerance", x: 0, y: 4}
	{class: "floatedit", min: 0, x: 1, y: 4, name: "tolerance", value: 1}
	{class: "checkbox", label: "Perspective", x: 0, y: 7, name: "perspective", value: false}
	{class: "checkbox", label: "Keep Mesh", x: 1, y: 7, name: "keepMesh", value: false}
}

performToMix = (mclips) ->
	res = {}
	for mclip in *mclips
		npath = Path!
		mpath = Path mclip
		mpath\callBackPath (id, seg, j, i) ->
			if npath.path[1] == nil
				a = seg.a\clone!
				a.id = "l"
				npath.path[1] = {seg.a}
			if i % 2 == 0 and id == "b"
				d = seg.d\clone!
				d.id = "l"
				table.insert npath.path[1], d
			elseif id == "b"
				table.insert npath.path[1], seg.b\clone!
				table.insert npath.path[1], seg.c\clone!
				table.insert npath.path[1], seg.d\clone!
			elseif id == "l"
				table.insert npath.path[1], seg.b\clone!
		table.remove npath.path[1]
		table.insert res, npath\export!
	return res

getExpandedMesh = (line, rows, cols, isBezier) ->
	mclips, colDistance, rowDistance = {}, nil, nil
	Line.callBackExpand ass, line, {rows, cols, isBezier}, (l) ->
		{:colDistance, :rowDistance} = l.grid
		table.insert mclips, l.grid.path\export!
	return mclips, colDistance, rowDistance

makeWithMesh = (sub, sel, activeLine) ->
	button, elements, config = Aegi.display interface!, {"Warp", "Mesh", "Reset", "Cancel"}, {close: "Cancel"}, "Mesh"
	if button == "Reset"
		config\reset!
		makeWithMesh sub, sel, activeLine
	elseif button == "Cancel"
		return
	ass = Ass sub, sel, activeLine
	{:lineType, :rows, :cols, :tolerance, :perspective, :keepMesh} = elements
	isBezier = lineType == "Bezier" or lineType == "Mix"
	for l, s, i, n in ass\iterSel!
		ass\progressLine s, i, n
		Line.extend ass, l
		if button == "Mesh"
			ass\removeLine l, s
			xr, yr = aegisub.video_size!
			screen = "m 0 0 l #{xr} 0 #{xr} #{yr} 0 #{yr} "
			local mclips
			if lineType == "Mix"
				mclips = performToMix getExpandedMesh l, 1, 1, isBezier
			else
				mclips = getExpandedMesh l, rows, cols, isBezier
			l.tags\remove "clip", "iclip"
			if l.isShape
				l.tags\insert {{"clip", screen .. table.concat mclips}}
				ass\insertLine l, s
			else
				{:org} = l.data
				Line.callBackTags ass, l, (line, j) ->
					line.text\callBack (tags, text) ->
						line.tags\insert {{"clip", screen .. mclips[j]}}
						if line.data.angle != 0 or line.tags\existsTagOr "frx", "fry", "frz"
							line.tags\insert {{"org", org}, true}
						return line.tags, text
					ass\insertLine line, s
		else
			ass\removeLine l, s
			{:clip, :pos} = l.data
			if clip
				mesh = Path clip
				table.remove mesh.path, 1
				if perspective and (isBezier or #mesh.path != 1)
					ass\error s, "Expected an quadrilateral"
				local mclips, colDistance, rowDistance
				if lineType == "Mix"
					mclips, colDistance, rowDistance = getExpandedMesh l, 1, 1, isBezier
					mclips = performToMix mclips
				else
					mclips, colDistance, rowDistance = getExpandedMesh l, rows, cols, isBezier
				local area
				if isBezier
					dist = colDistance > rowDistance and colDistance or rowDistance
					area = (colDistance * rowDistance) / dist
					mesh\flatten 1, nil, area
				Line.callBackExpand ass, l, {rows, cols, isBezier}, (line, j) ->
					{x, y} = line.data.pos
					real = Path mclips[j]
					if isBezier
						real = real\flatten 1, nil, area
					path = Path(line.shape)\move x, y
					if perspective
						path\perspective mesh.path[1], real.path[1]
					else
						path\closeContours!
						path\allCurve!
						path\envelopeDistort mesh, real, tolerance
					unless keepMesh
						line.tags\remove "clip", "iclip"
					line.shape = path\move(-x, -y)\export!
					ass\insertLine line, s
			else
				ass\error s, "The grid was not found"
	return ass\getNewSelection!

if haveDepCtrl
	depctrl\registerMacros {
		{"Make with Mesh", script_name, makeWithMesh}
	}
else
	aegisub.register_macro "#{script_name} / Make with Mesh", script_description, makeWithMesh