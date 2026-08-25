export script_name = "Edit Tags"
export script_description = "Edit tags of current line."
export script_version = "1.1.0"
export script_author = "PhosCity"
export script_namespace = "phos.EditTags"

DependencyControl = require "l0.DependencyControl"
depctrl = DependencyControl{
    feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json",
    {
        {"a-mo.LineCollection", version: "1.3.0", url: "https: //github.com/TypesettingTools/Aegisub-Motion",
            feed: "https: //raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
        {"l0.ASSFoundation", version: "0.5.0", url: "https: //github.com/TypesettingTools/ASSFoundation",
            feed: "https: //raw.githubusercontent.com/TypesettingTools/ASSFoundation/master/DependencyControl.json"},
        {"phos.AegiGui", version: "0.0.3", url: "https://github.com/PhosCity/Aegisub-Scripts",
            feed: "https://raw.githubusercontent.com/PhosCity/Aegisub-Scripts/main/DependencyControl.json"},
        {"l0.Functional", version: "0.6.0", url: "https://github.com/TypesettingTools/Functional",
            feed: "https://raw.githubusercontent.com/TypesettingTools/Functional/master/DependencyControl.json"},
        "Yutils"
    }
}
LineCollection, ASS, AegiGUI, Functional, Yutils = depctrl\requireModules!
{:list, :table, :util, :math, :string} = Functional


-----------------
getGUIstring = ->
-----------------
    str = "
    | label,EDIT TAGS #{script_version} |                          | check,outline,\\bord  | float,outlinevalue    | check,outline_x,\\xbord | float,outline_xvalue | check,alpha,\\alpha | float,alphavalue    |
    | check,tagSection,SECTION          |                          | check,shadow,\\shad   | float,shadowvalue     | check,outline_y,\\ybord | float,outline_yvalue | check,alpha1,\\1a   | float,alpha1value   |
    | check,color1,Primary              | color,color1value        | check,fontsize,\\fs   | float,fontsizevalue   | check,shadow_x,\\xshad  | float,shadow_xvalue  | check,alpha3,\\3a   | float,alpha3value   |
    | check,color3,Border               | color,color3value        | check,spacing,\\fsp   | float,spacingvalue    | check,shadow_y,\\yshad  | float,shadow_yvalue  | check,alpha4,\\4a   | float,alpha4value   |
    | check,color4,Shadow               | color,color4value        | check,blur,\\blur     | float,blurvalue       | check,shear_x,\\fax     | float,shear_xvalue   | check,align,\\an    | drop,alignvalue     |
    | check,bold,Bold                   | float,boldvalue          | check,blur_edges,\\be | float,blur_edgesvalue | check,shear_y,\\fay     | float,shear_yvalue   | check,wrapstyle,\\q | drop,wrapstylevalue |
    | check,italic,Italic               | drop,italicvalue,0::1    | check,scale_x,\\fscx  | float,scale_xvalue    | check,angle_x,\\frx     | float,angle_xvalue   | check,drawing,\\p   | float,drawingvalue  |
    | check,underline,Underline         | drop,underlinevalue,0::1 | check,scale_y,\\fscy  | float,scale_yvalue    | check,angle_y,\\fry     | float,angle_yvalue   | null                |                     |
    | check,strikeout,Strike            | drop,strikeoutvalue,0::1 | check,scale,\\fsc     | float,scalevalue      | check,angle,\\frz       | float,anglevalue     | null                |                     |
    | check,fade_simple,\\fad           | float,fade_simple_x      | float,fade_simple_y   |                       | check,fontname,\\fn     | drop,fontnamevalue   |                     |                     |
    | check,position,\\pos              | float,position_x         | float,position_y      |                       | check,origin,\\org      | float,origin_x       | float,origin_y      |                     |
    "
    str


--------------------------------------------
parseTransformTags = (str, transformTags) ->
--------------------------------------------

    local scale_x, scale_y
    for tag in *transformTags
        tagName = tag.__tag.name
        str = str\gsub "(check,#{tagName},[^%s|]+)", "%1,true"

        switch tagName

            when "color1", "color2", "color3", "color4"
                b, g, r = tag\getTagParams!
                colorString = util.ass_color r, g, b
                str = str\gsub "#{tagName}value", "#{tagName}value,#{colorString}"

            when "alpha", "alpha1", "alpha2", "alpha3", "alpha4"
                tagValue = tag\getTagParams!
                tagValueinPercent = math.round (tagValue / 255) * 100
                str = str\gsub "#{tagName}value", "#{tagName}value,#{tagValueinPercent},0,100,,0 (Opaque) -> 100 (Transparent)"

            when "scale_x"
                scale_x = tag\getTagParams!
                str = str\gsub "#{tagName}value", "#{tagName}value,#{scale_x}"

            when "scale_y"
                scale_y = tag\getTagParams!
                str = str\gsub "#{tagName}value", "#{tagName}value,#{scale_y}"

            when "clip_rect", "iclip_rect"
                xTopLeft, yTopLeft, xBottomRight, yBottomRight = tag\getTagParams!
                str ..= "\n| check,#{tagName},\\#{tagName\gsub("_rect", "")},true | float,#{tagName}_x1,#{xTopLeft},,,,x1 | float,#{tagName}_y1,#{yTopLeft},,,,y1 | float,#{tagName}_x2,#{xBottomRight},,,,x2 | float,#{tagName}_y2,#{yBottomRight},,,,y2 ||"

            else
                tagValue = tag\getTagParams!
                str = str\gsub "#{tagName}value", "#{tagName}value,#{tagValue}"

    str = str\gsub "scalevalue", "scalevalue,#{scale_x == scale_y and scale_x or 100}"
    str


----------------------------------------------------------
applyTransformGUItoLine = (res, existingTags, transform)->
----------------------------------------------------------

    transformTagTable = {}
    for tag in *transform.tags\getTags!
        tagName = tag.__tag.name
        transformTagTable[tagName] = tag

    if res["scale"]
        res["scale_x"] = true
        res["scale_y"] = true
        res["scale_xvalue"] = res["scalevalue"]
        res["scale_yvalue"] = res["scalevalue"]

    for tagName in *ASS\getTagsNamesFromProps transformable: true
        tag = transformTagTable[tagName]

        unless res[tagName]
            if existingTags[tagName]
                transform.tags\removeTags tagName
            continue

        local paramTable
        switch tagName

            when "color1", "color2", "color3", "color4"
                r, g, b = util.extract_color res[tagName .. "value"]
                paramTable = existingTags[tagName] and {r, g, b} or {b, g, r}

            when "alpha", "alpha1", "alpha2", "alpha3", "alpha4"
                tagValueinPercent = res[tagName .. "value"]
                paramTable = {(tagValueinPercent * 255 ) / 100}

            when "clip_rect", "iclip_rect"
                xTopLeft, yTopLeft = res[tagName .. "_x1"], res[tagName .. "_y1"]
                xBottomRight, yBottomRight = res[tagName .. "_x2"], res[tagName .. "_y2"]
                paramTable = {xTopLeft, yTopLeft, xBottomRight, yBottomRight}

            else
                paramTable = {res[tagName.."value"]}

        if existingTags[tagName]
            tag\set table.unpack(paramTable)
        else
            transform.tags\insertTags {ASS\createTag tagName, table.unpack(paramTable)}

    transform.startTime\set res["startTime"]
    transform.endTime\set res["endTime"]
    transform.accel\set res["accel"]

----------------------------------------------------------------
generateTransformGUI = (transform, count, transformSelection) ->
----------------------------------------------------------------

    str = "
    | label,EDIT TAGS #{script_version} |                   | check,outline,\\bord  | float,outlinevalue    | check,outline_x,\\xbord | float,outline_xvalue |
    | check,transform,Transform Index:  |                   | check,shadow,\\shad   | float,shadowvalue     | check,outline_y,\\ybord | float,outline_yvalue |
    | check,color1,Primary              | color,color1value | check,fontsize,\\fs   | float,fontsizevalue   | check,shadow_x,\\xshad  | float,shadow_xvalue  |
    | check,color3,Border               | color,color3value | check,spacing,\\fsp   | float,spacingvalue    | check,shadow_y,\\yshad  | float,shadow_yvalue  |
    | check,color4,Shadow               | color,color4value | check,blur,\\blur     | float,blurvalue       | check,shear_x,\\fax     | float,shear_xvalue   |
    | check,alpha,\\alpha               | float,alphavalue  | check,blur_edges,\\be | float,blur_edgesvalue | check,shear_y,\\fay     | float,shear_yvalue   |
    | check,alpha1,\\1a                 | float,alpha1value | check,scale_x,\\fscx  | float,scale_xvalue    | check,angle_x,\\frx     | float,angle_xvalue   |
    | check,alpha3,\\3a                 | float,alpha3value | check,scale_y,\\fscy  | float,scale_yvalue    | check,angle_y,\\fry     | float,angle_yvalue   |
    | check,alpha4,\\4a                 | float,alpha4value | check,scale,\\fsc     | float,scalevalue      | check,angle,\\frz       | float,anglevalue     |
    "

    existingTags = transformSelection[count]["existingTags"] or {}
    startTime = transform.startTime\get!
    endTime = transform.endTime\get!
    accel = transform.accel\get!

    str = str\gsub "Transform Index:", "Transform Index: #{count}/#{#transformSelection},#{tostring(not transformSelection[count]["toRemove"])}"

    str = parseTransformTags str, transform.tags\getTags!

    str ..= "\n| label,t1 | float,startTime,#{startTime} | label,t2 | float,endTime,#{endTime} | label,accel | float,accel,#{accel} |"

    if #transformSelection > 1
        nextCount = count + 1 > #transformSelection and 1 or count + 1
        transformSelectionConcat = ["#{index}:#{#item.text > 57 and string.sub(item.text, 1, 54).." ..." or item.text}" for index, item in ipairs transformSelection]
        str ..= "\n| label,Transform | drop,transformSelection,[[#{table.concat transformSelectionConcat, "::"}]],[[#{transformSelectionConcat[nextCount]}]]|||||"

    btnString = "Apply"
    btnString ..= ",Switch" if #transformSelection > 1
    btnString ..= ",Cancel:cancel"

    pressed, res = AegiGUI.open str, btnString
    aegisub.cancel! unless pressed

    if res["transform"]
        transformSelection[count]["toRemove"] = false
        applyTransformGUItoLine res, existingTags, transform
    else
        transformSelection[count]["toRemove"] = true

    exitLoop = true
    if pressed == "Switch"
        count = res.transformSelection\gsub("^([^:]+):.*", "%1")
        count = tonumber(count)
        exitLoop = false

    count, exitLoop, transformSelection


---------------------------------
handleTransform = (transforms) ->
---------------------------------

    transformSelection = {}
    for tr in *transforms
        existingTags = {}
        for tag in *tr.tags\getTags!
            existingTags[tag.__tag.name] = true
        transformSelection[#transformSelection + 1] = text: tr\toString!, existingTags: existingTags, toRemove: false

    count = 1
    while true
        tr = transforms[count]
        count, exitLoop, transformSelection = generateTransformGUI tr, count, transformSelection
        break if exitLoop

    for index, item in pairs transformSelection
        if item["toRemove"]
            transforms[index].tags\removeTags!


-----------------------------------------------------
parseEffectiveTags = (str, tags, existingTagTable) ->
-----------------------------------------------------

    local scale_x, scale_y
    for tagName, value in pairs tags
        if existingTagTable[tagName]
            str = str\gsub "(check,#{tagName},[^%s|]+)", "%1,true"

        switch tagName

            when "italic", "underline", "strikeout"
                tagValue = value\getTagParams!
                str = str\gsub "#{tagName}value,0::1", "#{tagName}value,0::1,#{tagValue}"

            when "align"
                tagValue = value\getTagParams!
                str = str\gsub "alignvalue", "alignvalue,#{table.concat([j for j = 1, 9], "::")},#{tagValue}"

            when "wrapstyle"
                tagValue = value\getTagParams!
                str = str\gsub "wrapstylevalue", "wrapstylevalue,#{table.concat([j for j = 0, 3], "::")},#{tagValue}"

            when "position", "origin", "fade_simple"
                firstParam, secondParam = value\getTagParams!
                str = str\gsub("#{tagName}_x", "#{tagName}_x,#{firstParam}")\gsub("#{tagName}_y", "#{tagName}_y,#{secondParam}")

            when "color1", "color2", "color3", "color4"
                b, g, r = value\getTagParams!
                colorString = util.ass_color r, g, b
                str = str\gsub "#{tagName}value", "#{tagName}value,#{colorString}"

            when "alpha", "alpha1", "alpha2", "alpha3", "alpha4"
                tagValue = value\getTagParams!
                tagValueinPercent = math.round (tagValue / 255) * 100
                str = str\gsub "#{tagName}value", "#{tagName}value,#{tagValueinPercent},0,100,,0 (Opaque) -> 100 (Transparent)"

            when "scale_x"
                scale_x = value\getTagParams!
                str = str\gsub "#{tagName}value", "#{tagName}value,#{scale_x}"

            when "scale_y"
                scale_y = value\getTagParams!
                str = str\gsub "#{tagName}value", "#{tagName}value,#{scale_y}"

            when "fontname"
                font = value\getTagParams!
                fontTable = [family.name for family in *Yutils.decode.list_fonts!]
                index = 1
                while index <= #fontTable and fontTable[index] < font
                    index += 1

                if fontTable[index] ~= font
                    table.insert fontTable, index, font

                str = str\gsub "fontnamevalue", "fontnamevalue,#{table.concat(fontTable, "::")},#{font}"

            when "move"
                if existingTagTable[tagName]
                    x1, y1, x2, y2, t1, t2 = value\getTagParams!
                    str = str .. "| check,move,\\move,true | float,move_x1,#{x1},,,,x1 | float,move_y1,#{y1},,,,y1 | float,move_x2,#{x2},,,,x2 | float,move_y2,#{y2},,,,y2 || float,move_t1,#{t1},,,,t1 | float,move_t2,#{t2},,,,t2 |"

            when "fade"
                if existingTagTable[tagName]
                    a1, a2, a3, t1, t2, t3, t4 = value\getTagParams!
                    str = str .. "| check,fade,\\fade,true | float,fade_a1,#{a1},,,,a1 | float,fade_a2,#{a2},,,,a2 | float,fade_a3,#{a3},,,,a3 | float,fade_t1,#{t1},,,,t1 | float,fade_t2,#{t2},,,,t2 | float,fade_t3,#{t3},,,,t3 | float,fade_t4,#{t4},,,,t4 |"

            when "clip_rect", "iclip_rect"
                if existingTagTable[tagName]
                    xTopLeft, yTopLeft, xBottomRight, yBottomRight = value\getTagParams!
                    str = str .. "\n| check,#{tagName},\\#{tagName\gsub("_rect", "")},true | float,#{tagName}_x1,#{xTopLeft},,,,x1 | float,#{tagName}_y1,#{yTopLeft},,,,y1 || float,#{tagName}_x2,#{xBottomRight},,,,x2 || float,#{tagName}_y2,#{yBottomRight},,,,y2 ||"

            else
                tagValue = value\getTagParams!
                str = str\gsub "#{tagName}value", "#{tagName}value,#{tagValue}"

    str = str\gsub "scalevalue", "scalevalue,#{scale_x == scale_y and scale_x or 100}"
    str


------------------------------------------------------------------------------------------------------------
applyGUItoLine = (res, data, existingTagTable, sectionTable, count, tagSection, textSection, defaultTags) ->
------------------------------------------------------------------------------------------------------------

    if defaultTags or not textSection
        data\insertSections(ASS.Section.Text res["textvalue"])
    else
        if textSection.class == ASS.Section.Text
            textSection.value = res["textvalue"] if res["text"] or ""
        elseif textSection.class == ASS.Section.Drawing and res["textvalue"] != ""
            shape = ASS.Draw.DrawingBase {str: res["textvalue"]}
            textSection.contours = shape.contours

    if res["scale"]
        res["scale_x"] = true
        res["scale_y"] = true
        res["scale_xvalue"] = res["scalevalue"]
        res["scale_yvalue"] = res["scalevalue"]

    for tagName in *list.diff(ASS.tagNames.all, { "clip_vect", "iclip_vect", "k_bord", "k_fill", "k_sweep", "reset", "transform" })

        unless res[tagName]
            tagSection\removeTags tagName if existingTagTable[tagName]
            continue

        local paramTable
        switch tagName

            when "position", "origin", "fade_simple"
                firstParam = res[tagName.."_x"]
                secondParam = res[tagName.."_y"]
                paramTable = {firstParam, secondParam}

            when "color1", "color2", "color3", "color4"
                r, g, b = util.extract_color res[tagName .. "value"]
                paramTable = {b, g, r}

            when "alpha", "alpha1", "alpha2", "alpha3", "alpha4"
                tagValueinPercent = res[tagName .. "value"]
                paramTable = {(tagValueinPercent * 255 ) / 100}

            when "move"
                x1, y1 = res["move_x1"], res["move_y1"]
                x2, y2 = res["move_x2"], res["move_y2"]
                t1, t2 = res["move_t1"], res["move_t2"]
                if t1 == 0 and t2 == 0
                    t1 = nil
                    t2 = nil
                paramTable = {x1, y1, x2, y2, t1, t2}

            when "fade"
                a1, a2, a3 = res["fade_a1"], res["fade_a2"], res["fade_a3"]
                t1, t2, t3, t4 = res["fade_t1"], res["fade_t2"], res["fade_t3"], res["fade_t4"]
                paramTable = {t2, t4 - t3, t1, t3, a1, a2, a3}

            when "clip_rect", "iclip_rect"
                xTopLeft, yTopLeft = res[tagName .. "_x1"], res[tagName .. "_y1"]
                xBottomRight, yBottomRight = res[tagName .. "_x2"], res[tagName .. "_y2"]
                paramTable = {xTopLeft, yTopLeft, xBottomRight, yBottomRight}

            else
                paramTable = {res[tagName.."value"]}

        if defaultTags
            data\insertTags {ASS\createTag tagName, table.unpack(paramTable)}

        elseif textSection and not tagSection
            data\insertSections(ASS.Section.Tag!, 1)
            data\insertTags {ASS\createTag tagName, table.unpack(paramTable)}

            sectionTable[1]["tagIndex"] = 1
            sectionTable[1]["textIndex"] = 2
            for index, item in pairs sectionTable
                continue unless index > count
                item["tagIndex"] += 1
                item["textIndex"] += 1

        else
            data\replaceTags {ASS\createTag tagName, table.unpack(paramTable)}, count, count, true

    sectionTable

--------------------------------------------------------
generateGUI = (data, sectionTable, count, transforms) ->
--------------------------------------------------------
    str = getGUIstring!
    parseLine = false


    local tagSection, textSection, defaultTags
    sectionPair = sectionTable[count]
    if sectionPair
        tagIndex = sectionPair.tagIndex
        textIndex = sectionPair.textIndex
        tagSection = data.sections[tagIndex]
        textSection = data.sections[textIndex]
    else
        defaultTags = data\getDefaultTags!

    existingTagTable = {}
    if tagSection
        existingTagTable[key] = true for key in pairs (tagSection\getEffectiveTags false, false, true).tags

    local tags
    if defaultTags
        tags = defaultTags.tags
    elseif tagSection and textSection
        tags = (tagSection\getEffectiveTags true).tags
    else
        tags = (textSection\getEffectiveTags true, true, false).tags

    str = parseEffectiveTags str, tags, existingTagTable
    str = str\gsub "SECTION", "SECTION #{count}/#{#sectionTable},#{tostring(tagSection and not sectionPair["toRemove"] or true)}"

    text = ""
    if textSection
        text = "[[" .. sectionTable[count].text .. "]]"
    str ..= "\n| check,text,Text,#{text != "" and true} | text,textvalue,1,#{text} |||||||"

    if #sectionTable > 1
        nextCount = count + 1 > #sectionTable and 1 or count + 1
        sectionTableConcat = [index .. ": " ..item.text  for index, item in pairs sectionTable]
        str ..= "\n| label,Sections | drop,sectionDropdown,[[#{table.concat(sectionTableConcat, "::")}]],[[#{sectionTableConcat[nextCount]}]] |||||||"

    btnString = "Apply"
    btnString ..= ",Switch" if #sectionTable > 1
    btnString ..= ",Transform" if #transforms > 0
    btnString ..= ",Text Mode,Cancel:cancel"

    pressed, res = AegiGUI.open str, btnString
    aegisub.cancel! unless pressed

    if pressed == "Text Mode"
        return nil, true, nil, true, false

    if res["tagSection"]
        sectionTable[count]["toRemove"] = false if tagSection
        sectionTable = applyGUItoLine res, data, existingTagTable, sectionTable, count, tagSection, textSection, defaultTags
    else
        sectionTable[count]["toRemove"] = true if tagSection

    exitLoop = true
    if pressed == "Switch"
        count = res.sectionDropdown\gsub("^([^:]+):.*", "%1")
        count = tonumber(count)
        exitLoop = false

    if res["textvalue"]\match "{}"
        parseLine = true
        data\commit!
        exitLoop = false

    if pressed == "Transform"
        handleTransform transforms

    count, exitLoop, sectionTable, textMode, parseLine


-----------------------------------
textModeMain = (sub, sel, lines) ->
-----------------------------------

    -----------------------------------------------------
    collectTags = (tagName, tag, colorTable, tagTable) ->
    -----------------------------------------------------
        tagGroup = {blur: "Blur", blur_edges: "Blur",
            fade_simple: "Fade",  fade: "Fade",
            shear_x: "Shear",     shear_y: "Shear",
            clip_rect: "Clip",    iclip_rect: "Clip"
            position: "Position", origin: "Position",  move: "Position",
            outline: "Border",    outline_x: "Border", outline_y: "Border",
            shadow: "Shadow",     shadow_x: "Shadow",  shadow_y: "Shadow",
            angle: "Rotation",    angle_x: "Rotation", angle_y: "Rotation",
            fontsize: "Scale",    spacing: "Scale",    scale_x: "Scale",    scale_y: "Scale",
            alpha: "Alpha",       alpha1: "Alpha",     alpha2: "Alpha",     alpha3: "Alpha",  alpha4: "Alpha"
            clip_vect: "None",    iclip_vect: "None",  k_bord: "None",      k_fill: "None",   k_sweep: "None", junk: "None", unknown: "None"
        }
        switch tagName
            when "color1", "color2", "color3", "color4"
                colorTable[tagName] or= {}
                table.insert colorTable[tagName], tag\toString!
            else
                key = tagGroup[tagName]
                key or= "General"
                unless key == "None"
                    tagTable[key] or= {}
                    table.insert tagTable[key], tag\toString!
        colorTable, tagTable

    tagTable, colorTable = {}, {}
    lines\runCallback (lines, line, i) ->
        aegisub.cancel! if aegisub.progress.is_cancelled!
        data = ASS\parse line
        for tag in *data\getTags!
            tagName = tag.__tag.name
            switch tagName
                when "transform"
                    for trTags in *tag.tags\getTags!
                        colorTable, tagTable = collectTags trTags.__tag.name, trTags, colorTable, tagTable
                else
                    colorTable, tagTable = collectTags tagName, tag, colorTable, tagTable

    for item in *{tagTable, colorTable}
        for key, value in pairs item
            sorted = table.values value, true
            item[key] = list.uniq sorted

    totalTagGroups = table.length tagTable
    column = math.ceil math.sqrt totalTagGroups

    str = ""
    sectionHeader = [j for j in *{"Blur","Scale","Position","Alpha","Border","Shadow","Shear","Rotation","Fade","Clip","Transform","General"} when tagTable[j]]
    sectionHeader = list.chunk sectionHeader, column
    for tbl in *sectionHeader
        str ..= "|label,#{section}|pad,50|" for section in *tbl
        str ..= "|null||" for _ = 1, column - #tbl when #tbl < column
        str ..= "\n"

        str ..= "|text,#{section},9,[[#{table.concat tagTable[section], "\n"}]]||" for section in *tbl
        str ..= "|null||" for _ = 1, column - #tbl when #tbl < column
        str ..= "\n"

        str ..= "null\n" for _ = 1, 8

    str2 = ""
    maxLength = 0
    for color in *{"color1", "color3", "color4"}
        maxLength = math.max(#colorTable[color], maxLength) if colorTable[color]

    if maxLength > 0
        str2 ..= "|label, Primary Color |" if colorTable["color1"]
        str2 ..= "|label, Border Color |" if colorTable["color3"]
        str2 ..= "|label, Shadow Color |" if colorTable["color4"]
        str2 ..= "\n"

        for j = 1, maxLength
            for item in *{"color1", "color3", "color4"}
                continue unless colorTable[item]
                col = colorTable[item][j]
                if col
                    col = col\gsub "^\\[1234]?c", ""
                    str2 ..= "|color,#{item}_#{j},#{col},#{col}|"
                else
                    str2 ..= "|null|"
            str2 ..= "\n"
    str2 = str2\gsub "||", "|"

    if str == ""
        aegisub.log "There are no tags in the selected lines."
        aegisub.cancel!

    local pressed, res
    if str2 == ""
        pressed, res = AegiGUI.open str, "Modify, Cancel:cancel"
    else
        pressed, res = AegiGUI.merge str, str2, "Modify, Cancel:cancel", column + 7, 0, true
    aegisub.cancel! unless pressed

    change = {}
    for section in *{"Blur","Scale","Position","Alpha","Border","Shadow","Shear","Rotation","Fade","Clip","Transform","General"}
        continue unless res[section]
        original = tagTable[section]
        final = string.split res[section], "\n"
        for j = 1, #original
            originalValue = original[j]
            finalValue = final[j]
            if originalValue != finalValue
                table.insert change, {originalValue, finalValue}

    for j = 1, maxLength
        for item in *{"color1", "color3", "color4"}
            continue unless colorTable[item]
            originalValue = colorTable[item][j]
            continue unless originalValue
            colorType = originalValue\gsub "(\\[1234]?c).*", "%1"

            r,g,b=res["#{item}_#{j}"]\match "#(%x%x)(%x%x)(%x%x)"
            finalValue = "#{colorType}" .. "&H" ..b .. g .. r .. "&"

            if originalValue != finalValue
                table.insert change, {originalValue, finalValue}

    for line in *lines
        for item in *change
            line.text = line.text\gsub string.escLuaExp(item[1]), item[2]
    lines\replaceLines!


-------------------------------------
singleLineMain = (sub, sel, lines) ->
-------------------------------------
    local textMode, sectionTable, data, count, transforms
    parseLine = true

    while true
        if parseLine
            line = lines[1]
            data = ASS\parse line

            transforms = data\getTags "transform"

            data\cleanTags 0

            sectionTable = {}
            local tagIndex
            data\callback (section, _, j) ->
                return if section.class == ASS.Section.Comment
                if section.class == ASS.Section.Tag
                    tagIndex = j
                else
                    local text
                    if section.class == ASS.Section.Text
                        text = section\getString!
                    else
                        text = section\toString!
                    sectionTable[#sectionTable + 1] = tagIndex: tagIndex, textIndex: j, text: text, toRemove: false
                    tagIndex = nil

            count = 1
        count, exitLoop, sectionTable, textMode, parseLine = generateGUI data, sectionTable, count, transforms
        break if exitLoop

    if textMode
        textModeMain sub, sel, lines
        return

    for index, item in pairs sectionTable
        if item["toRemove"]
            tagIndex = item.tagIndex
            tagSection = data.sections[tagIndex]
            tagSection\remove!

    data\cleanTags!
    data\commit!

    lines\replaceLines!


---------------------------------------
multipleLineMain = (sub, sel, lines) ->
---------------------------------------

    str = getGUIstring!
    str ..= "
|check,clip_rect,\\clip|float,clip_x1,0,,,,x1|float,clip_y1,0,,,,y1|                     |float,clip_x2,0,,,,x2||float,clip_y2,0,,,,y2|                      |
|check,move,\\move     |float,move_x1,0,,,,x1|float,move_y1,0,,,,y1|float,move_x2,0,,,,x2|float,move_y2,0,,,,y2||float,move_t1,0,,,,t1| float,move_t2,0,,,,t2|
"

    str = str\gsub "0::1", "0::1,0"
    str = str\gsub "alignvalue", "alignvalue,#{table.concat([j for j = 1, 9], "::")},5"
    str = str\gsub "wrapstylevalue", "wrapstylevalue,#{table.concat([j for j = 0, 3], "::")},2"
    str = str\gsub "check,tagSection,SECTION", "label,Total Lines #{#lines.lines}"

    layer, style = {}, {}
    for line in *lines
        table.insert layer, line.layer
        table.insert style, line.style
    table.sort layer
    table.sort style
    table.insert layer, 1, "All Layers"
    table.insert style, 1, "All Styles"

    drop_layer = table.concat(layer, "::") ..",All Layers"
    drop_style = table.concat(style, "::") ..",All Styles"

    patternStart, patternEnd = str\find("|%s+null%s+|%s+|")
    str = str\sub(1, patternStart - 1) .. "| label,[[        Apply to]]|drop,layer,#{drop_layer}|" .. str\sub(patternEnd + 1)
    str = str\gsub "|%s+null%s+|%s+|", "| drop,applyTo,All Sections::Start Tags::Inline Tags,Start Tags | drop, style, #{drop_style} |"

    fontTable = [family.name for family in *Yutils.decode.list_fonts!]
    str = str\gsub "fontnamevalue", "fontnamevalue,#{table.concat(fontTable, "::")},#{fontTable[1]}"

    pressed, res = AegiGUI.open str, "Apply, Text Mode, Cancel:cancel"
    aegisub.cancel! unless pressed

    if pressed == "Text Mode"
        textModeMain sub, sel, lines
        return

    if res["scale"]
        res["scale_x"] = true
        res["scale_y"] = true
        res["scale_xvalue"] = res["scalevalue"]
        res["scale_yvalue"] = res["scalevalue"]

    layer = res.layer != "All Layers" and tonumber(res.layer) or nil
    style = res.style != "All Styles" and res.style or nil

    lines\runCallback (lines, line, i) ->
        if layer and line.layer != layer
            return
        if style and line.style != style
            return
        data = ASS\parse line

        local firstSectionIsTag
        for section in *data.sections
            continue if section.class == ASS.Section.Comment
            firstSectionIsTag = true if section.class == ASS.Section.Tag
            break

        for tagName in *ASS.tagNames.all
            continue unless res[tagName]

            local paramTable
            switch tagName

                when "color1", "color2", "color3", "color4"
                    r, g, b = util.extract_color res[tagName .. "value"]
                    paramTable = {b, g, r}

                when "alpha", "alpha1", "alpha2", "alpha3", "alpha4"
                    tagValueinPercent = res[tagName .. "value"]
                    paramTable = {(tagValueinPercent * 255 ) / 100}

                when "clip_rect", "iclip_rect"
                    name = tagName\gsub "_rect", ""
                    xTopLeft, yTopLeft = res[name .. "_x1"], res[name .. "_y1"]
                    xBottomRight, yBottomRight = res[name .. "_x2"], res[name .. "_y2"]
                    paramTable = {xTopLeft, yTopLeft, xBottomRight, yBottomRight}

                when "position", "origin", "fade_simple"
                    firstParam = res[tagName.."_x"]
                    secondParam = res[tagName.."_y"]
                    paramTable = {firstParam, secondParam}

                else
                    paramTable = {res[tagName.."value"]}

            startIndex = 1
            endIndex = #data.sections
            switch res["applyTo"]
                when "Start Tags"
                    data\insertSections(ASS.Section.Tag!, 1) unless firstSectionIsTag
                    endIndex = 1
                when "Inline Tags"
                    startIndex = firstSectionIsTag and 2 or 1

            data\replaceTags {ASS\createTag tagName, table.unpack(paramTable)}, startIndex, endIndex, true

        data\commit!
    lines\replaceLines!


--------------------
main = (sub, sel) ->
--------------------

    lines = LineCollection sub, sel
    if #lines.lines == 0
        return
    elseif #lines.lines == 1
        singleLineMain sub, sel, lines
    else
        multipleLineMain sub, sel, lines


depctrl\registerMacro main
