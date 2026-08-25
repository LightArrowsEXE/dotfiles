export script_name = "ASS2SVG"
export script_description = "Export ass shapes to svg path"
export script_version = "1.0.2"
export script_author = "PhosCity"
export script_namespace = "phos.ASS2SVG"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
    feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
    {
        {"ILL.ILL", version: "1.5.1", url: "https://github.com/TypesettingTools/ILL-Aegisub-Scripts/"
            feed: "https://raw.githubusercontent.com/TypesettingTools/ILL-Aegisub-Scripts/main/DependencyControl.json"},
    }
}
ILL = depctrl\requireModules!
{:Ass, :Line, :Path} = ILL


bgrTorgb = (bgrHex) ->
    blue, green, red = bgrHex\match "&H(%x%x)(%x%x)(%x%x)&"
    "#" .. red .. green .. blue


alphaToOpacity = (hexAlpha) ->
    hexAlpha = hexAlpha\gsub "[H#&]", ""
    alphaDecimal = tonumber hexAlpha, 16
    1 - (alphaDecimal / 255)


assShapeTosvgPath = (shape, lineData) ->
    path = {}
    for i = 1, #shape
        path[i] = {}
        j, contour, cmd = 2, shape[i], nil
        while j <= #contour
            prev = contour[j - 1]\round 3
            curr = contour[j]\round 3
            if curr.id == "b"
                c = contour[j + 1]\round decimal
                d = contour[j + 2]\round decimal
                table.insert path[i], "C #{curr.x} #{curr.y} #{c.x} #{c.y} #{d.x} #{d.y}"
                j += 2
            else
                table.insert path[i], "L #{curr.x} #{curr.y}"
            j += 1
        path[i] = "M #{contour[1].x} #{contour[1].y} " .. table.concat(path[i], " ") .. " Z"

    path = table.concat path, " "

    {:outline, :color1, :color3, :alpha, :alpha1, :alpha3} = lineData
    "<path d=\"#{path}\" fill=\"#{bgrTorgb(color1)}\" stroke=\"#{bgrTorgb(color3)}\" fill-opacity=\"#{alphaToOpacity(alpha1)}\" stroke-opacity=\"#{alphaToOpacity(alpha3)}\" opacity=\"#{alphaToOpacity(alpha)}\" stroke-width=\"#{outline}\"/>"


saveToFile = (xmlContent) ->
    pathsep = package.config\sub(1, 1)
    filename = aegisub.dialog.save("Select SVG file", "", aegisub.decode_path("?script")..pathsep, "Svg files (.svg)|*.svg")
    if not filename
        aegisub.log "You did not provide the filename. Exiting."
        return

    file = io.open(filename, "w")
    if file
        file\write(xmlContent)
        file\close!
    else
        aegisub.log "Error: Could not open file for writing."


main = (sub, sel, act) ->
    ass = Ass sub, sel, act

    xmlContent = "<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\"  width=\"#{ass.meta.res_x}\" height=\"#{ass.meta.res_y}\">"

    for l, s in ass\iterSel!
        continue if l.comment
        Line.extend ass, l
        if l.isShape
            Line.callBackExpand ass, l, nil, (line) ->
                {x, y} = l.data.pos
                newPath = Path line.shape
                newPath\move x, y
                svgPath = assShapeTosvgPath newPath.path, line.data
                xmlContent ..= "\n    #{svgPath}"
        else
            ass\warning s, "Text/Empty line is not exported to svg."
    xmlContent ..= "\n</svg>"
    saveToFile xmlContent


depctrl\registerMacro main
