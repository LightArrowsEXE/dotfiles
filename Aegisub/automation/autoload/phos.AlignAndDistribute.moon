export script_name = "Align and Distribute"
export script_description = "Align and distribute lines relative to something"
export script_version = "0.0.2"
export script_author = "PhosCity"
export script_namespace = "phos.AlignAndDistribute"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
    feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
    {
        {"a-mo.LineCollection", version: "1.3.0", url: "https: //github.com/TypesettingTools/Aegisub-Motion",
            feed: "https: //raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
        {"l0.ASSFoundation", version: "0.5.0", url: "https: //github.com/TypesettingTools/ASSFoundation",
            feed: "https: //raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json"},
        {"phos.AegiGui", version: "1.0.0", url: "https://github.com/PhosCity/Aegisub-Scripts",
            feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json"},
        {"phos.AssfPlus", version: "1.0.5", url: "https://github.com/PhosCity/Aegisub-Scripts",
            feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json"},
    },
}
LineCollection, ASS, AegiGui, AssfPlus = depctrl\requireModules!


createGUI = (lines, hasClip, playRes, layoutRes) ->
    relativeToTable = {}

    if #lines > 1
        relativeToTable = {"First Line", "Last Line", "Custom Line"}

    relativeToTable[#relativeToTable + 1] = "Video"

    if hasClip
        relativeToTable[#relativeToTable + 1] = "Clip"

    if #playRes > 1
        relativeToTable[#relativeToTable + 1] = "PlayRes"

    if #layoutRes > 1
        relativeToTable[#relativeToTable + 1] = "LayoutRes"

    relativeTo = table.concat(relativeToTable, "::") .. "," .. relativeToTable[1]
    customLine = table.concat(lines, "::") .. "," .. lines[1]
    horizontalOptions = table.concat({"Center", "Right edge", "Left Edge"}, "::") .. ",Center"
    verticalOptions = table.concat({"Center", "Top edge", "Bottom Edge"}, "::") .. ",Center"

    dialog_str = "
    | label, Relative to | drop, relativeTo, #{relativeTo} |
    | label, Custom Line | drop, customLine, #{customLine} |
    | check, vertical, Vertical, false | drop, verticalOptions, #{verticalOptions} |
    | check, horizontal, Horizontal, false | drop, horizontalOptions, #{horizontalOptions} |
    "

    dialog, button, buttonID = AegiGui.create dialog_str, "Align, Distribute, Cancel:cancel"
    btn, res = aegisub.dialog.display(dialog, button, buttonID)
    aegisub.cancel! if btn == "Cancel"
    return res, btn


calculate_deltas = (tbl) ->
    n = #tbl
    return {} if n < 2

    first_reference = tbl[1]
    last_reference = tbl[n]
    step = (last_reference - first_reference) / (n - 1)

    deltas = {}

    for i = 1, n
        equidistant = first_reference + (i - 1) * step
        deltas[i] = equidistant - tbl[i]

    deltas


main = (sub, sel) ->

    AssfPlus._util.windowAssertError AssfPlus._util.checkVideoIsOpen!, "You must have video open to use this script."

    lines = LineCollection sub, sel
    return if #lines.lines == 0

    naturalLines = {}
    boundingBox = {}
    hasClip = false
    playRes = {} --x,y
    layoutRes = {} --x,y

    lines\runCallback ((lines, line, i) ->
        data = ASS\parse line
        if i == 1
            scriptInfo = data["scriptInfo"]
            playRes = {scriptInfo["PlayResX"], scriptInfo["PlayResY"]}
            layoutRes = {scriptInfo["LayoutResX"], scriptInfo["LayoutResY"]}

        line_clip = data\getTags {"clip_rect"}
        hasClip = true if #line_clip > 0

        table.insert naturalLines, line.humanizedNumber
        x1, y1, x2, y2 = AssfPlus.lineData.getBoundingBox data, false, true, true
        table.insert boundingBox, {x1, y1, x2, y2}
    ), true

    playRes = [tonumber(item) for item in *playRes]
    layoutRes = [tonumber(item) for item in *layoutRes]
    res, btn = createGUI naturalLines, hasClip, playRes, layoutRes

    if btn == "Align"
        lines\runCallback ((lines, line, i) ->
            data = ASS\parse line
            currentBoundingBox = boundingBox[i]

            targets =
                "First Line": -> boundingBox[1]

                "Last Line": -> boundingBox[#boundingBox]

                "Custom Line": -> boundingBox[tonumber res.customLine]

                "PlayRes": -> {0, 0, playRes[1], playRes[2]}

                "LayoutRes": -> {0, 0, layoutRes[1], layoutRes[2]}

                "Video": ->
                    xres, yres = aegisub.video_size!
                    {0, 0, xres, yres}

                "Clip": ->
                    line_clip = data\getTags {"clip_rect"}
                    return false if #line_clip == 0

                    x1, y1, x2, y2 = line_clip[1]\getTagParams!
                    data\removeTags "clip_rect"
                    {x1, y1, x2, y2}

            target = targets[res.relativeTo]!

            if target
                dx, dy = 0, 0
                vertical_delta =
                    "Center": (t, c) -> (t[2] + t[4] - c[2] - c[4]) / 2

                    "Top edge": (t, c) -> t[2] - c[2]

                    "Bottom Edge": (t, c) -> t[4] - c[4]

                horizontal_delta =
                    "Center": (t, c) -> (t[1] + t[3] - c[1] - c[3]) / 2

                    "Left Edge": (t, c) -> t[1] - c[1]

                    "Right edge": (t, c) -> t[3] - c[3]

                if res.vertical
                    dy = vertical_delta[res.verticalOptions](target, currentBoundingBox)

                if res.horizontal
                    dx = horizontal_delta[res.horizontalOptions](target, currentBoundingBox)

                position = data\getTags {"position"}
                if #position == 0
                    effective_tags = (data\getEffectiveTags -1, true, true, false).tags
                    data\insertTags effective_tags.position

                data\modTags {"position", "origin", "clip_vect", "iclip_vect", "clip_rect", "iclip_rect", "move"},
                    (tg) -> tg\add dx, dy
                data\commit!
        ), true

    elseif btn == "Distribute"

        AssfPlus._util.windowAssertError #lines.lines > 2, "Three or more lines is required for distribution. Got #{#lines.lines}"

        verticalSelectors =
            "Center": (item) -> (item[2] + item[4]) / 2
            "Top edge": (item) -> item[2]
            "Bottom Edge": (item) -> item[4]

        horizontalSelectors =
            "Center": (item) -> (item[1] + item[3]) / 2
            "Left Edge": (item) -> item[1]
            "Right edge": (item) -> item[3]

        local verticalDelta, horizontalDelta
        if res.vertical
            selector = verticalSelectors[res.verticalOptions]
            verticalDelta = calculate_deltas([selector(item) for item in *boundingBox])

        if res.horizontal
            selector = horizontalSelectors[res.horizontalOptions]
            horizontalDelta = calculate_deltas([selector(item) for item in *boundingBox])


        lines\runCallback ((lines, line, i) ->
            data = ASS\parse line
            currentBoundingBox = boundingBox[i]

            dx = horizontalDelta and horizontalDelta[i] or 0
            dy = verticalDelta and verticalDelta[i] or 0

            if dx != 0 or dy != 0
                position = data\getTags {"position"}
                if #position == 0
                    effective_tags = (data\getEffectiveTags -1, true, true, false).tags
                    data\insertTags effective_tags.position

                data\modTags {"position", "origin", "clip_vect", "iclip_vect", "clip_rect", "iclip_rect", "move"},
                    (tg) -> tg\add dx, dy
                data\commit!
        ), true

    lines\replaceLines!

depctrl\registerMacro main
