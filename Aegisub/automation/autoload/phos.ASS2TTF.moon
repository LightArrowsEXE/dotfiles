export script_name = "ASS2TTF"
export script_description = "Convert shapes to a TTF font"
export script_version = "0.0.1"
export script_author = "PhosCity"
export script_namespace = "phos.ASSS2TTF"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
    feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
    {
        {"ILL.ILL", version: "1.7.7", url: "https://github.com/TypesettingTools/ILL-Aegisub-Scripts/"
            feed: "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json"},
    }
}
ILL = depctrl\requireModules!
{:Ass, :Line, :Path} = ILL

assShapeTosvgPath = (shape) ->
    path = {}
    for i = 1, #shape
        path[i] = {}
        j, contour = 2, shape[i]
        while j <= #contour
            prev = contour[j - 1]\round 3
            curr = contour[j]\round 3
            if curr.id == "b"
                c = contour[j + 1]\round 3
                d = contour[j + 2]\round 3
                table.insert path[i], "C #{curr.x} #{curr.y} #{c.x} #{c.y} #{d.x} #{d.y}"
                j += 2
            else
                table.insert path[i], "L #{curr.x} #{curr.y}"
            j += 1
        path[i] = "M #{contour[1].x} #{contour[1].y} " .. table.concat(path[i], " ") .. " Z"

    table.concat path, " "


checkFontForgeExists = ->
    handle = io.popen("fontforge --version")
    result = handle\read("*a")
    handle\close!

    if result and result != ""
        return

    aegisub.log "fontforge not found in path. Install it and try again."
    aegisub.cancel!


createFont = (xmlContent, fontFilePath) ->
    temp = aegisub.decode_path "?temp"
    pathsep = package.config\sub(1, 1)
    svgPath = temp .. pathsep .. "ASS2TTF.svg"
    ffScript = temp .. pathsep .. "fontforgeScript.pe"

    svgFile = io.open(svgPath, "w")
    if svgFile
        svgFile\write(xmlContent)
        svgFile\close!
    else
        aegisub.log "Error: Could not open svg svg file for writing."

    ffScriptContent = table.concat({
        'Open($1)',
        'Generate($2)',
        'Quit()',
    }, "\n")

    ffScriptFile = io.open(ffScript, "w")
    if ffScriptFile
        ffScriptFile\write(ffScriptContent)
        ffScriptFile\close!
    else
        aegisub.log "Error: Could not open svg file for writing."

    handle = io.popen("fontforge -script \"#{ffScript}\" \"#{svgPath}\" \"#{fontFilePath}\"")
    output = handle\read("*a")
    success, reason, exit = handle\close!
    unless success
        aegisub.log tostring(reason)


main = (sub, sel, act) ->
    checkFontForgeExists!

    pathsep = package.config\sub(1, 1)
    fontFilePath = aegisub.dialog.save("Enter font name", "", aegisub.decode_path("?script")..pathsep, "Truetype font files (.ttf)|*.ttf")
    if not fontFilePath
        aegisub.log "You did not provide the filename. Exiting."
        return

    -- Get filename (with extension)
    filename = fontFilePath\match("^.+[/\\](.+)$") or fontFilePath
    -- Remove extension
    filename = filename\match("(.+)%..+$") or filename

    ass = Ass sub, sel, act

    svgBoilerPlate = {
        '<?xml version="1.0" encoding="UTF-8" standalone="no"?>',
        '<svg',
        '   width="1000"',
        '   height="1000"',
        '   viewBox="0 0 1000 1000"',
        '   version="1.1"',
        '   id="svg1"',
        '   xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"',
        '   xmlns="http://www.w3.org/2000/svg"',
        '   xmlns:svg="http://www.w3.org/2000/svg">',
        '  <defs',
        '     id="defs1">',
        '    <font'
        '       horiz-adv-x="1024"',
        '       id="font1"',
        '       inkscape:label="font 1"',
        '       horiz-origin-x="0"',
        '       horiz-origin-y="0"',
        '       vert-origin-x="512"',
        '       vert-origin-y="768"',
        '       vert-adv-y="1024">',
        '      <font-face'
        '         units-per-em="1000"',
        '         ascent="750"',
        '         cap-height="600"',
        '         x-height="400"',
        '         descent="200"',
        '         id="font-face1"',
        "         font-family=\"#{filename}\" />",
        '      <missing-glyph'
        '         d="M0,0h1000v1000h-1000z"',
        '         id="missing-glyph1" />',
        '    </font>',
        '  </defs>',
        '</svg>',
    }


    glyph_name = {}
    for l, s in ass\iterSel!
        continue if l.comment
        Line.extend ass, l
        if l.isShape
            Line.callBackExpand ass, l, nil, (line) ->
                current_glyph = line.effect
                if #current_glyph != 1
                    ass\error s, "The line must have a single letter glyph in effect field."

                for glyph in *glyph_name
                    if glyph == current_glyph
                        ass\error s, "Glyph \"#{glyph}\" is repeated."

                table.insert glyph_name, current_glyph

                {x, y} = l.data.pos
                newPath = Path line.shape

				bbox = newPath\boundingBox!
                scale = (400 / bbox.height) * 100 -- 400 is the distance between baseline and x height
				newPath\scale scale, scale

                newPath\rotatefrz 180
				bbox = newPath\boundingBox!
                newPath\move 500 - bbox.center.x, 600 - bbox.center.y
                for item in *{
                        '      <glyph'
                        "         glyph-name=\"#{current_glyph}\"",
                        "         unicode=\"#{current_glyph}\"",
                        "         id=\"glyph#{#glyph_name}\"",
                        "         d=\"#{assShapeTosvgPath newPath.path}\" />",
                    }
                    table.insert(svgBoilerPlate, #svgBoilerPlate-2, item)
        else
            ass\error s, "Text/Empty line cannot be converted to font. Use shapes instead."
    createFont table.concat(svgBoilerPlate, "\n"), fontFilePath


depctrl\registerMacro main
