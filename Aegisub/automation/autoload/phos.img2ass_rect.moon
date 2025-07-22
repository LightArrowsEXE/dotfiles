export script_name        = "img2ass rect clip"
export script_description = "img2ass rect clip"
export script_version     = "0.0.1"
export script_author      = "PhosCity"
export script_namespace   = "phos.img2assrect"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl {
	feed: "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json",
	{
		{"ILL.IMG", version: "1.0.2", url: "https://github.com/TypesettingTools/ILL-Aegisub-Scripts"
			feed: "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json" },
		{"ILL.ILL", version: "1.6.6", url: "https://github.com/TypesettingTools/ILL-Aegisub-Scripts"
			feed: "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json" }
	}
}
IMG, ILL = depctrl\requireModules!
{:Aegi, :Ass, :Table} = ILL
logger = depctrl\getLogger!

getData = ->
    exts = "*.png;*.jpeg;*.jpe;*.jpg;*.jfif;*.jfi;*.bmp;"
    pathsep = package.config\sub(1, 1)
    filename = aegisub.dialog.open "Open Image", "", aegisub.decode_path("?script")..pathsep, "Extents (#{exts})|#{exts};", false, true
    unless filename
        Aegi.progressCancel!
    Aegi.progressTask "Decoding image..."
    img = IMG.IMG filename
    img\setInfos!
    return img

data2ass = (data) ->
    return unless data
    {:b, :g, :r, :a} = data
    color = ("\\cH%02X%02X%02X")\format b, g, r
    alpha = ("\\alphaH%02X")\format 255 - a
    return color, alpha

imagePixels = (sub, sel, activeLine) ->
    img = getData!
    width = img.infos.width
    height = img.infos.height
    data = img.infos\getData!

    shapeTable = {}
    box = {l: math.huge, r: -math.huge, b: -math.huge, t: math.huge}

    for y = 0, height - 1
        for x = 0, width - 1
            color, alpha = data2ass data[y * width + x]
            continue if alpha == "\\alphaHFF"

            box.l = math.min box.l, x
            box.t = math.min box.t, y
            box.r = math.max box.r, x
            box.b = math.max box.b, y

            table.insert shapeTable, {color, alpha, "\\clip(#{x},#{y},#{x + 1},#{y + 1})"}
	
    Aegi.progressTask "Generating base shape..."
    fullShape = "m #{box.l} #{box.t} l #{box.r} #{box.t} #{box.r} #{box.b} #{box.l} #{box.b}"

    Aegi.progressTask "Inserting lines..."
    ass = Ass sub, sel, activeLine
    line = Table.copy sub[activeLine]
    line.isShape = true
    line.comment = false
    for pixel in *shapeTable
        {color, alpha, clip} = pixel
        line.shape = "{\\an7\\pos(0,0)\\bord0\\shad0\\fscx100\\fscy100\\fr0\\p1#{clip}#{color}#{alpha}}#{fullShape}"
        ass\insertLine line, activeLine

depctrl\registerMacro imagePixels 
