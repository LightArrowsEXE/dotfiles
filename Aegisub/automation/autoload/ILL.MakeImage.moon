export script_name        = "Make Image"
export script_description = "Does several procedures for converting images to the .ass"
export script_version     = "2.1.1"
export script_author      = "ILLTeam"
export script_namespace   = "ILL.MakeImage"

haveDepCtrl, DependencyControl = pcall require, "l0.DependencyControl"

local depctrl, IMG, ILL, Aegi, Ass, Math, Table
if haveDepCtrl
	depctrl = DependencyControl {
		feed: "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json",
		{
			{
				"ILL.IMG"
				version: "1.0.1"
				url: "https://github.com/TypesettingTools/ILL-Aegisub-Scripts"
				feed: "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json"
			}
			{
				"ILL.ILL"
				version: "1.4.4"
				url: "https://github.com/TypesettingTools/ILL-Aegisub-Scripts"
				feed: "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json"
			}
		}
	}
	IMG, ILL = depctrl\requireModules!
	{:Aegi, :Ass, :Math, :Table} = ILL
else
	IMG = require "ILL.IMG"
	ILL = require "ILL.ILL"
	{:Aegi, :Ass, :Math, :Table} = ILL

getData = ->
	exts = "*.png;*.jpeg;*.jpe;*.jpg;*.jfif;*.jfi;*.bmp;"
	filename = aegisub.dialog.open "Open Image", "", "", "Extents (#{exts})|#{exts};", false, true
	unless filename
		Aegi.progressCancel!
	Aegi.progressTask "Decoding image..."
	img = IMG.IMG filename
	img\setInfos!
	return img

imageTracer = (sub, sel, activeLine) ->
	presets = {
		"Custom", "Default", "Curvy"
		"Sharp", "Detailed", "Smoothed", "Grayscale"
		"Fixed Palette", "Random Sampling 1", "Random Sampling 2"
		"Artistic 1", "Artistic 2", "Artistic 3", "Artistic 4"
		"Posterized 1", "Posterized 2", "Posterized 3"
	}
	interface = {
		-- Tracing
		{class: "label", label: "#{("-")\rep 15} Tracing #{("-")\rep 15}", x: 0, y: 0}
		{class: "label", label: "Preset:", x: 0, y: 2}
		{class: "dropdown", name: "preset", items: presets, x: 0, y: 3, value: "Custom"}
		{class: "label", label: "Treshold Straight Lines:", x: 0, y: 4}
		{class: "floatedit", name: "ltres", x: 0, y: 5, min: 1e-4, value: 1.0}
		{class: "label", label: "Treshold Quadratic Splines:", x: 0, y: 6}
		{class: "floatedit", name: "qtres", x: 0, y: 7, min: 1e-4, value: 1.0}
		{class: "label", label: "Edge Node Until:", x: 0, y: 8}
		{class: "intedit", name: "pathomit", x: 0, y: 9, min: 0, value: 8}
		{class: "checkbox", label: "Enhance right angle corners?", name: "rightangleenhance", x: 0, y: 10, value: true}
		-- Color quantization
		{class: "label", label: "#{("-")\rep 10} Color Quantization #{("-")\rep 10}", x: 4, y: 0}
		{class: "label", label: "Color Palette:", x: 4, y: 2}
		{class: "dropdown", name: "colorsampling", items: {"Disable", "Random", "Deterministic"}, x: 4, y: 3, value: "Deterministic"}
		{class: "label", label: "Number Of Colors:", x: 4, y: 4}
		{class: "intedit", name: "numberofcolors", x: 4, y: 5, min: 1, value: 16}
		{class: "label", label: "Ratio:", x: 4, y: 6}
		{class: "floatedit", name: "mincolorratio", x: 4, y: 7, min: 0.0, value: 0.0}
		{class: "label", label: "Cycles:", x: 4, y: 8}
		{class: "intedit", name: "colorquantcycles", x: 4, y: 9, min: 1, value: 3}
		{class: "checkbox", label: "Layering Sequential", name: "layering", x: 4, y: 10, value: true}
		-- SVG rendering
		{class: "label", label: "#{("-")\rep 11} Shape Render #{("-")\rep 11}", x: 0, y: 12}
		{class: "label", label: "Stroke Width:", x: 0, y: 14}
		{class: "floatedit", name: "strokewidth", x: 0, y: 15, min: 0.0, value: 1.0}
		{class: "label", label: "Scale Path:", x: 0, y: 16}
		{class: "floatedit", name: "scale", x: 0, y: 17, min: 0.0, value: 100.0}
		{class: "label", label: "Round Path:", x: 0, y: 18}
		{class: "intedit", name: "roundcoords", x: 0, y: 19, min: 0, max: 3, value: 1}
		-- Blur
		{class: "label", label: "#{("-")\rep 18} Blur #{("-")\rep 18}", x: 4, y: 12}
		{class: "label", label: "Blur Radius:", x: 4, y: 14}
		{class: "floatedit", name: "blurradius", x: 4, y: 15, min: 0, max: 5, value: 0.0}
		{class: "label", label: "Blur Delta:", x: 4, y: 16}
		{class: "floatedit", name: "blurdelta", x: 4, y: 17, min: 0, value: 20.0}
	}
	img = getData!
	button, elements = Aegi.display interface, {"Ok", "Cancel"}, {close: "Cancel"}, "Tracer"
	if button == "Ok"
		local preset
		if elements.preset != "Custom"
			preset = Table.copy IMG.Tracer.optionpresets[elements.preset\gsub("%s", "")\lower!]
		else
			preset = Table.copy IMG.Tracer.optionpresets.default
			preset.ltres = elements.ltres
			preset.qtres = elements.qtres
			preset.rightangleenhance = elements.rightangleenhance
			preset.pathomit = elements.pathomit
			preset.colorsampling = switch elements.colorsampling
				when "Disable" then 0
				when "Random" then 1
				when "Deterministic" then 2
			preset.numberofcolors = elements.numberofcolors
			preset.mincolorratio = elements.mincolorratio
			preset.colorquantcycles = elements.colorquantcycles
			preset.layering = elements.layering and 0 or 1
			preset.strokewidth = elements.strokewidth
			preset.scale = elements.scale / 100
			preset.roundcoords = elements.roundcoords
			preset.blurradius = elements.blurradius
			preset.blurdelta = elements.blurdelta
		Aegi.progressTask "Tracing image..."
		tracedata = IMG.Tracer.imagedataToTracedata img, preset
		Aegi.progressTask "Simplifying tracing..."
		asslines = IMG.Tracer.getAssLines tracedata, preset
		asslineslen = #asslines
		ass = Ass sub, sel, activeLine
		line = Table.copy sub[activeLine]
		line.isShape = true
		Aegi.progressTask "Adding new lines..."
		for key, trace in ipairs asslines
			Aegi.progressSet key, asslineslen
			line.shape = trace
			ass\insertLine line, activeLine
		return ass\getNewSelection!

imagePixels = (sub, sel, activeLine) ->
	items = {"All in one line", "On several lines - \"Rec\"", "Pixel by Pixel"}
	interface = {
		{class: "label", label: "Output Type:", x: 0, y: 0}
		{class: "dropdown", name: "outputtype", :items , x: 0, y: 1, value: items[2]}
	}
	img = getData!
	button, elements = Aegi.display interface, {"Ok", "Cancel"}, {close: "Cancel"}, "Pixels"
	if button == "Ok"
		typer = switch elements.outputtype
			when "All in one line" then "oneLine"
			when "On several lines - \"Rec\"" then true
		asslines = img\toAss typer
		asslineslen = #asslines
		ass = Ass sub, sel, activeLine
		line = Table.copy sub[activeLine]
		line.isShape = true
		Aegi.progressTask "Adding new lines..."
		for key, pixel in ipairs asslines
			Aegi.progressSet key, asslineslen
			line.shape = pixel\gsub "}{", ""
			ass\insertLine line, activeLine
		return ass\getNewSelection!

imagePotrace = (sub, sel, activeLine) ->
	x, items = 0, {"right", "black", "white", "majority", "minority"}
	interface = {
		{class: "label", label: "Turnpolicy: #{(" ")\rep 30}", :x, y: 0}
		{class: "dropdown", name: "tpy", :items, :x, y: 1, value: "minority"}
		{class: "label", label: "Corner threshold:", :x, y: 2}
		{class: "intedit", name: "apm", :x, y: 3, min: 0, value: 1}
		{class: "label", label: "Delete until:", :x, y: 4}
		{class: "floatedit", name: "tdz", :x, y: 5, value: 2}
		{class: "label", label: "Tolerance:", :x, y: 6}
		{class: "floatedit", name: "opt", :x, y: 7, min: 0, value: 0.2}
		{class: "checkbox", label: "Curve optimization?", name: "opc", :x, y: 8, value: true}
	}
	img = getData!
	button, elements = Aegi.display interface, {"Ok", "Cancel"}, {close: "Cancel"}, "Potrace"
	if button == "Ok"
		Aegi.progressTask "Tracing image..."
		pot = IMG.Potrace img, nil, elements.tpy, elements.tdz, elements.opc, elements.apm, elements.opt
		pot\process!
		ass = Ass sub, sel, activeLine
		line = Table.copy sub[activeLine]
		line.isShape = true
		Aegi.progressTask "Adding new lines..."
		line.shape = "{\\an7\\pos(0,0)\\bord0\\shad0\\fscx100\\fscy100\\fr0\\p1}#{pot\getShape!}"
		ass\insertLine line, activeLine
		return ass\getNewSelection!

if haveDepCtrl
	depctrl\registerMacros {
		{"Image Tracer", script_description, imageTracer}
		{"Pixels", script_description, imagePixels}
		{"Potrace", script_description, imagePotrace}
	}
else
	aegisub.register_macro "#{script_name} / Image Tracer", script_description, imageTracer
	aegisub.register_macro "#{script_name} / Pixels", script_description, imagePixels
	aegisub.register_macro "#{script_name} / Potrace", script_description, imagePotrace