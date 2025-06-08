export script_name = "Auto Gradient"
export script_description = "Automatically color gradient the line."
export script_version = "0.0.6"
export script_author = "PhosCity"
export script_namespace = "phos.AutoGradient"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
    feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
    {
        {"a-mo.LineCollection", version: "1.3.0", url: "https: //github.com/TypesettingTools/Aegisub-Motion",
            feed: "https: //raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
        {"l0.ASSFoundation", version: "0.5.0", url: "https: //github.com/TypesettingTools/ASSFoundation",
            feed: "https: //raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json"},
        { "l0.Functional", version: "0.6.0", url: "https://github.com/TypesettingTools/Functional",
            feed: "https://raw.githubusercontent.com/TypesettingTools/Functional/master/DependencyControl.json" },
        {"phos.AssfPlus", version: "1.0.2", url: "https://github.com/PhosCity/Aegisub-Scripts",
            feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json"},
    },
}
LineCollection, ASS, Functional, AssfPlus = depctrl\requireModules!
-- logger = depctrl\getLogger!
{ :util, :math } = Functional
{ :lineData, :_tag } = AssfPlus


getPointsBetweenCoordinates = (startCoord, endCoord) ->
  x1, y1 = table.unpack startCoord
  x2, y2 = table.unpack endCoord
  dist = math.vector2.distance x1, y1, x2, y2
  points = {}
  for i = 1, dist
    m1 = i
    m2 = dist - i
    x = (m1 * x2 + m2 * x1)/(m1 + m2)
    y = (m1 * y2 + m2 * y1)/(m1 + m2)
    table.insert points, {x, y}
  points


getColor = (frame, x, y) ->
  color = frame\getPixelFormatted(x, y)
  color


colorsAreAlmostSame = (color1, color2) ->
    if color1 and color2
        deltaEValue = _tag.color.getDeltaE color1, color2
        return true if deltaEValue < 0.5
    return false


clipGradient = (data, lines, line, clipTable, mode, frame) ->
    -- Collect bounding box of the line
    x1, y1, x2, y2 = lineData.getBoundingBox data, true, _, true

    gradientTable = {}
    clipCnt = #clipTable

    -- Find colors for intermediate points
    local prevColor
    if mode == "vertical"
        for j = y1, y2
            currPercent = (j - y1) / (y2 - y1)
            index = math.floor(math.round(currPercent * clipCnt))
            index = math.max(index, 1)
            x, y = table.unpack clipTable[index]
            color = getColor frame, x, y

            if colorsAreAlmostSame(prevColor, color)
                gradientTable[#gradientTable][4] = j+1
            else
                table.insert gradientTable, {x1, j, x2, j+1, color}
            prevColor = color
    else
        for j = x1, x2
            currPercent = (j - x1) / (x2 - x1)
            index = math.floor(math.round(currPercent * clipCnt))
            index = math.max(index, 1)
            x, y = table.unpack clipTable[index]
            color = getColor frame, x, y

            if colorsAreAlmostSame(prevColor, color)
                gradientTable[#gradientTable][3] = j+1
            else
                table.insert gradientTable, {j, y1, j+1, y2, color}
            prevColor = color

    -- Finally create new lines
    for item in *gradientTable
        leftX, leftY, rightX, rightY, color = table.unpack item
        r, g, b = util.extract_color color
        data\replaceTags {ASS\createTag "clip_rect", leftX, leftY, rightX, rightY}
        data\replaceTags {ASS\createTag "color1", b, g, r}
        lines\addLine ASS\createLine {line}


gradientByCharacter = (data, clipTable, frame) ->
    clipCnt = #clipTable
    styleRef = data\getStyleRef!
    text = data\copy!\stripTags!\stripComments!\getString!

    charWidth = {}
    totalWidth = aegisub.text_extents styleRef, text
    currWidth = 0
    for char in text\gmatch "."
        width = aegisub.text_extents styleRef, char
        table.insert charWidth, currWidth / totalWidth
        currWidth += width

    processedChar = 0
    sections = {}
    data\callback (section) ->
        if section.class != ASS.Section.Text
            table.insert sections, section
        else
            text = section.value
            for char in text\gmatch "."
                processedChar += 1
                index = math.floor(math.round(charWidth[processedChar] * clipCnt))
                index = math.max(index, 1)

                x, y = table.unpack clipTable[index]
                color = getColor frame, x, y
                r, g, b = util.extract_color color

                table.insert sections, ASS.Section.Tag {ASS\createTag "color1", b, g, r}
                table.insert sections, ASS.Section.Text char

    data\removeSections 1 , #data.sections
    data\insertSections sections
    data\cleanTags 0
    data\commit!


main = (mode) ->
    (sub, sel) ->

        lines = LineCollection sub, sel
        return if #lines.lines == 0

        -- Initialize some variables
        to_delete = {}
        currentFrame = aegisub.project_properties!.video_position
        frame = aegisub.get_frame(currentFrame, false)

        lines\runCallback (lines, line, i) ->
            aegisub.cancel! if aegisub.progress.is_cancelled!
            table.insert to_delete, line

            data = ASS\parse line

            -- Collect vector clip
            clipTable = {}
            clip = data\removeTags "clip_vect"
            return if  #clip == 0

            for index, cnt in ipairs clip[1].contours[1].commands  -- Is this the best way to loop through co-ordinate?
                break if index == 3
                x, y = cnt\get!
                table.insert clipTable, {x, y}

            -- Find all the points between two points of clip
            clipTable = getPointsBetweenCoordinates(clipTable[1], clipTable[2])

            if mode == "gbc"
                gradientByCharacter data, clipTable, frame
            else
                clipGradient data, lines, line, clipTable, mode, frame

        frame = nil
        collectgarbage!

        if mode == "gbc"
            lines\replaceLines!
        else
            lines\insertLines!
            lines\deleteLines to_delete


depctrl\registerMacros({
  {"Horizontal", "Horizontal Gradient", main "horizontal"},
  {"Vertical", "Vertical Gradient", main "vertical"},
  {"Gradient by Character", "Gradient by Character", main "gbc"},
})
