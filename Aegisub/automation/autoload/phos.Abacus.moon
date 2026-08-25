export script_name = "Abacus"
export script_description = "Recalculates values of tags."
export script_version = "1.1.0"
export script_author = "PhosCity"
export script_namespace = "phos.Abacus"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
    feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
    {
        {"a-mo.LineCollection", version: "1.3.0", url: "https: //github.com/TypesettingTools/Aegisub-Motion",
            feed: "https: //raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
        {"l0.ASSFoundation", version: "0.5.0", url: "https: //github.com/TypesettingTools/ASSFoundation",
            feed: "https: //raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json"},
        {"l0.Functional", version: "0.6.0", url: "https://github.com/TypesettingTools/Functional",
            feed: "https://raw.githubusercontent.com/TypesettingTools/Functional/master/DependencyControl.json"},
        {"phos.AssfPlus", version: "1.0.5", url: "https://github.com/PhosCity/Aegisub-Scripts",
            feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json"},
        {"phos.AegiGui", version: "1.0.0", url: "https://github.com/PhosCity/Aegisub-Scripts",
            feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json"},
    }
}
LineCollection, ASS, Functional, AssfPlus, AegiGui = depctrl\requireModules!
{:list, :util, :math, :string} = Functional


globalGUIResult = {}

execute_command = (expr, operation) ->

    if num = tonumber expr
        return num / (operation == "mul" and 100 or 1)

    if expr\match "^%-?%d:%d%d:%d%d%.%d%d$"
        sign, timeString = expr\match "^(%-?)(%d:%d%d:%d%d%.%d%d)$"
        expr = util.assTimecode2ms timeString
        expr = -1 * expr if sign == "-"
        return expr

    elseif ms = expr\match("^([%d%-%.]+)ms$")
        return tonumber ms

    elseif cs = expr\match("^([%d%-%.]+)cs$")
        return tonumber(cs) * 10

    elseif s = expr\match("^([%d%-%.]+)s$")
        return tonumber(s) * 1000

    elseif m = expr\match("^([%d%-%.]+)m$")
        return tonumber(m) * 60 * 1000

    elseif h = expr\match("^([%d%-%.]+)h$")
        return tonumber(h) * 3600 * 1000

    elseif f = expr\match("^([%d%-%.]+)f$")
        AssfPlus._util.windowAssertError AssfPlus._util.checkVideoIsOpen!, "Shifting time by frame only makes sense in the context of video. Could not find any loaded video."
        return expr

    if expr\match "^[%d%-,%s]+$"
        split = string.split expr, ","
        result = {}
        for item in *split
            item = string.trim item
            result[#result+1] = tonumber(item) / (operation == "mul" and 100 or 1)
        return result

    for item in expr\gmatch "math%.randomfloat%([^)]+%)"
        min, max = item\match "([%d%.%-]+)%s-,%s-([%d%.%-]+)"
        if not min or not max
            AssfPlus._util.windowError "Invalid randomfloat syntax: #{expr}"
        expr = expr\gsub string.escLuaExp(item), math.randomFloat(min,max)

    func, err = loadstring("return " .. expr)
    AssfPlus._util.windowAssertError func, "Invalid lua math expression: #{err}"

    success, result = pcall(func)
    AssfPlus._util.windowAssertError success, "Could not calculate the expression: #{err}"

    AssfPlus._util.windowAssertError result, "Invalid input: #{expr}. Could not calculate the expression."
    result / (operation == "mul" and 100 or 1)


assertType = (val, _type, tag) ->
    AssfPlus._util.windowAssertError type(val) == _type, "Invalid type: #{_type} expected for tag #{tag}, got #{type val}."


main = (sub, sel) ->

    lines = LineCollection sub, sel
    return if #lines.lines == 0

    str = "
    | label, Change value by          | edit, changeValueX, 0              | edit, changeValueY, 0                   |
    | check, time, Time               | check, preserveTime, Preserve Time | check, layer, Layer                     |
    | check, margin_left, Left Margin | check, margin_right, Right Margin  | check, margin_vertical, Vertical Margin |
    |                                 |                                    |                                         |
    | check, position, pos            | check, teleport, pos/org/move/clip | null                                    |
    | check, scale, fsc               | check, scale_x, fscx               | check, scale_y, fscy                    |
    | check, fontsize, fs             | check, angle, frz                  | check, spacing, fsp                     |
    | check, color1, c                | check, color3, 3c                  | check, color4, 4c                       |
    | check, outline, bord            | check, shadow, shad                |                                         |
    "

    collection = AssfPlus.lineCollection.collectTags lines, _, true

    coreTags = {"position", "scale_x", "scale_y", "fontsize", "angle", "spacing", "color1", "color3", "color4", "outline", "shadow"}
    collection.tagList  = list.diff collection.tagList, coreTags, {"junk", "unknown", "reset", "italic", "bold", "underline", "strikeout", "wrapstyle", "align", "fontname"}

    tagList = {}
    for tagName in *collection.tagList
        switch tagName

            when "move"
                for item in *{"move", "[[move (x1, y1)]]", "[[move (x2, y2)]]", "[[move (t1, t2)]]"}
                    tagList[#tagList + 1] = item

            when "clip_rect"
                for item in *{"clip_rect", "[[clip_rect (x1, y1)]]", "[[clip_rect (x2, y2)]]"}
                    tagList[#tagList + 1] = item

            when "iclip_rect"
                for item in *{"iclip_rect", "[[iclip_rect (x1, y1)]]", "[[iclip_rect (x2, y2)]]"}
                    tagList[#tagList + 1] = item

            when "transform"
                for item in *{"[[transform (t1, t2)]]", "transform accel"}
                    tagList[#tagList + 1] = item

            when "drawing"
                tagList[#tagList + 1] = "shape"

            else
                tagList[#tagList + 1] = tagName

    if #tagList > 0
        str ..= "||||\n"
        for ln in *(list.chunk tagList, 3)
            str ..= "| check, #{ln[1]}, #{(ASS.toFriendlyName[ln[1]] or ln[1])\gsub("\\", "")}"
            str ..= ln[2] and "| check, #{ln[2]}, #{(ASS.toFriendlyName[ln[2]] or ln[2])\gsub("\\", "")} " or "|"
            str ..= ln[3] and "| check, #{ln[3]}, #{(ASS.toFriendlyName[ln[3]] or ln[3])\gsub("\\", "")} |\n" or "||\n"

    if #lines.lines > 1
        str ..= "||||\n| check, lineIncrement, Increase with each line |||"

    dialog, button, buttonID = AegiGui.create str, "Add, Multiply, Reset GUI, Cancel:cancel"
    for index, item in pairs dialog
        continue unless item.name
        continue unless globalGUIResult[item.name]
        if item.text
            item.text = globalGUIResult[item.name]
        else
            item.value = globalGUIResult[item.name]
    btn, res = aegisub.dialog.display(dialog, button, buttonID)
    globalGUIResult = res
    aegisub.cancel! unless btn

    if btn == "Reset GUI"
        dialog, button, buttonID = AegiGui.create str, "Add, Multiply, Cancel:cancel"
        btn, res = aegisub.dialog.display(dialog, button, buttonID)
        globalGUIResult = res
        aegisub.cancel! unless btn

    for index, item in ipairs tagList
        tagList[index] = item\gsub "[%[%]]", ""

    operation = btn == "Add" and "add" or "mul"

    if res["scale"]
        res["scale_x"] = true
        res["scale_y"] = true

    if res["teleport"]
        for item in *{"position", "origin", "clip_vect", "iclip_vect", "clip_rect", "iclip_rect", "move"}
            res[item] = true

    if res["changeValueX"]\match "random" or res["changeValueY"]\match "random"
        math.randomseed os.time!

    x = execute_command res["changeValueX"], operation
    y = execute_command res["changeValueY"], operation
    originalX = x
    originalY = y

    lines\runCallback ((lines, line, i) ->

        AssfPlus._util.checkCancellation!
        AssfPlus._util.progress "Recalculating", i, #lines.lines

        data = ASS\parse line

        for tag in *coreTags
            continue unless res[tag]
            data\insertDefaultTags tag if #data\getTags(tag) == 0

        for tag in *(list.join tagList, coreTags, {"time", "end_time", "layer", "margin_left", "margin_right", "margin_vertical"})
            continue unless res[tag]
            switch tag

                when "time"
                    local startDelta, endDelta
                    if type(x) == "number"
                        startDelta = x
                    elseif f = x\match "^([%d%-%.]+)f$"
                        startDelta = aegisub.ms_from_frame(line.startFrame + f) - line.start_time
                    if type(y) == "number"
                        endDelta = y
                    elseif f = y\match "^([%d%-%.]+)f$"
                        endDelta = aegisub.ms_from_frame(line.endFrame + f) - line.end_time

                    line.start_time += startDelta
                    line.end_time += endDelta

                    AssfPlus._util.windowAssertError line.end_time > line.start_time, "Recalculation of line's time pushed the end time before the start time."

                    if res["preserveTime"]

                        ktags = data\getTags {'k_fill', 'k_sweep', 'k_bord'}
                        unless #ktags == 0
                            ktags[1].value -= startDelta
                            AssfPlus._util.windowAssertError ktags[1].value >= 0, "Recalculation of line's time pushed the first syl before the line start."

                            ktags[#ktags].value += endDelta
                            AssfPlus._util.windowAssertError ktags[#ktags].value >= 0, "Recalculation of line's time pushed the last syl after the line end."

                        for tag in *data\getTags {"fade_simple"}
                            tag.inDuration -= startDelta
                            tag.outDuration += endDelta

                        for tag in *data\getTags {"transform", "move"}
                            if tag.startTime.value == 0 and tag.endTime.value == 0
                                tag.endTime += line.duration
                            tag.startTime -= startDelta
                            tag.endTime -= startDelta

                when "layer"
                    assertType x, "number", tag
                    line.layer = math.max(line.layer + x, 0)

                when "margin_left"
                    assertType x, "number", tag
                    line.margin_l = math.max(line.margin_l + x, 0)

                when "margin_right"
                    assertType x, "number", tag
                    line.margin_r = math.max(line.margin_r + x, 0)

                when "margin_vertical"
                    assertType x, "number", tag
                    line.margin_t = math.max(line.margin_t + x, 0)

                when "position", "origin", "clip_vect", "iclip_vect", "move (x1, y1)", "clip_rect (x1, y1)", "iclip_rect (x1, y1)"
                    tag = tag\gsub " %(x1, y1%)", ""

                    assertType x, "number", tag
                    assertType y, "number", tag
                    data\modTags tag, (tg) -> tg[operation] tg, x, y

                when "move (x2, y2)", "clip_rect (x2, y2)", "iclip_rect (x2, y2)"
                    tag = tag\gsub " %(x2, y2%)", ""
                    assertType x, "number", tag
                    assertType y, "number", tag
                    data\modTags tag, (tg) -> tg[operation] tg, _, _, x, y

                when "move", "clip_rect", "iclip_rect"
                    assertType x, "number", tag
                    assertType y, "number", tag
                    data\modTags tag, (tg) -> tg[operation] tg, x, y, x, y

                when "move (t1, t2)"
                    assertType x, "number", tag
                    assertType y, "number", tag
                    data\modTags "move", (tg) -> tg[operation] tg, _, _, _, _, x, y

                when "transform (t1, t2)"
                    assertType x, "number", tag
                    assertType y, "number", tag
                    transforms = data\getTags "transform"
                    for tr in *transforms
                        tr.startTime\add x
                        tr.endTime\add y

                when "transform accel"
                    assertType x, "number", tag
                    transforms = data\getTags "transform"
                    for tr in *transforms
                        tr.accel\add x

                when "fade"
                    assertType x, "table"
                    a1, a2, a3, t1, t2, t3, t4 = table.unpack x
                    data\modTags tag, (tg) -> tg[operation] tg, t2, t4 - t3, t1, t3, a1, a2, a3

                when "k_fill", "k_sweep", "k_bord"
                    assertType x, "number", tag
                    data\modTags tag, (tg) -> tg[operation] tg, x
                    ktags = data\getTags tag
                    totalKaraokeDuration = 0
                    for index, item in ipairs ktags
                        if index == 1 and item.value < 0
                            AssfPlus._util.windowError "The recalculation shifted the tag #{ASS.toFriendlyName[tag]} before the line start."
                        totalKaraokeDuration += item.value
                    if totalKaraokeDuration > line.duration
                        AssfPlus._util.windowError "The recalculation shifted the tag #{ASS.toFriendlyName[tag]} past the line end or it was already past the line end. In any case, it's not correct."

                when "shape"
                    assertType x, "number", tag
                    assertType y, "number", tag
                    data\callback ((section) ->
                        section[operation] section, x, y
                    ), ASS.Section.Drawing

                when "fade_simple"
                    assertType x, "number", tag
                    assertType y, "number", tag
                    data\modTags tag, (tg) ->
                        xOrigValue, yOrigValue = tg\getTagParams!
                        if operation == "add"
                            AssfPlus._util.windowAssertError xOrigValue + x >= 0, "Recalculation of tag #{ASS.toFriendlyName[tag]} would result in a negative value."
                            AssfPlus._util.windowAssertError yOrigValue + y >= 0, "Recalculation of tag #{ASS.toFriendlyName[tag]} would result in a negative value."
                            tg\add x, y
                        elseif operation == "mul"
                            AssfPlus._util.windowAssertError xOrigValue * x >= 0, "Recalculation of tag #{ASS.toFriendlyName[tag]} would result in a negative value."
                            AssfPlus._util.windowAssertError yOrigValue * y >= 0, "Recalculation of tag #{ASS.toFriendlyName[tag]} would result in a negative value."
                            tg\mul x, y

                when "alpha", "alpha1", "alpha2", "alpha3", "alpha4"
                    assertType x, "number", tag
                    data\modTags tag, (tg) ->
                        origValue = tg.value
                        local newValue
                        if operation == "add"
                            newValue = util.clamp(origValue + x, 0, 255)
                        elseif operation == "mul"
                            newValue = util.clamp(origValue * x, 0, 255)
                        tg\set newValue

                when "color1", "color2", "color3", "color4"
                    assertType x, "table", tag
                    AssfPlus._util.windowAssertError #x == 3, "Invalid color input: #{res["changeValueX"]}\nExpected input in r,g,b format."
                    r, g, b  = table.unpack x
                    data\modTags tag, (tg) ->
                        bOG, gOG, rOG = tg\getTagParams!
                        if operation == "add"
                            r, g, b = util.clamp(r + rOG, 0, 255), util.clamp(g + gOG, 0, 255), util.clamp(b + bOG, 0, 255)
                        elseif operation == "mul"
                            r, g, b = r/100, g/100, b/100
                            r, g, b = util.clamp(r * rOG, 0, 255), util.clamp(g * gOG, 0, 255), util.clamp(b * bOG, 0, 255)
                        tg\set r, g, b

                when "outline", "outline_x", "outline_y", "blur_edges", "blur", "fontsize", "shadow", "shadow_x", "shadow_y"
                    assertType x, "number", tag
                    data\modTags tag, (tg) ->
                        origValue = tg.value
                        if operation == "add"
                            AssfPlus._util.windowAssertError origValue + x >= 0, "Recalculation of tag #{ASS.toFriendlyName[tag]} would result in a negative value."
                            tg\add x
                        elseif operation == "mul"
                            AssfPlus._util.windowAssertError origValue * x >= 0, "Recalculation of tag #{ASS.toFriendlyName[tag]} would result in a negative value."
                            tg\mul x

                else
                    assertType x, "number", tag
                    data\modTags tag, (tg) -> tg[operation] tg, x

        if res["changeValueX"]\match "random" or res["changeValueY"]\match "random"
            x = execute_command res["changeValueX"], operation
            y = execute_command res["changeValueY"], operation

        if res["lineIncrement"]
            if type(originalX) == "number"
                x += originalX
            elseif type(originalX) == "table"
                x = [item + x[index] for index, item in ipairs originalX]
            elseif f = res["changeValueX"]\match "^([%d%-%.]+)f$"
                x = x\gsub "^([%d%-%.]+)f$", (arg) -> tostring(math.floor(arg+f)).."f"

            if type(originalY) == "number"
                y += originalY
            elseif type(originalY) == "table"
                y = [item + y[index] for index, item in ipairs originalY]
            elseif f = res["changeValueY"]\match "^([%d%-%.]+)f$"
                y = y\gsub "^([%d%-%.]+)f$", (arg) -> tostring(math.floor(arg+f)).."f"

        data\commit!

    ), true

    lines\replaceLines!

depctrl\registerMacro main
